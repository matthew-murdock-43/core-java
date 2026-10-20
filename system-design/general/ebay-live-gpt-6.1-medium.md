# System Design Interview: Design eBay Live

Senior Software Engineer / Staff Engineer | 45–60 minute interview

Designing a platform like eBay Live is an excellent system design problem because it combines several challenging areas of distributed systems:

- Real-time live video streaming to thousands of viewers.
- Concurrent bidding, where thousands of users might bid on the same item.
- Strong consistency to ensure the correct bidder wins.
- Real-time event delivery using WebSockets.
- Auction countdown timers, payments, and inventory management.
- Scalability during sudden traffic spikes.

The most important architectural decision: Separate the video streaming infrastructure from the auction and bidding infrastructure. Video delivery can tolerate some delay; determining the winning bid cannot tolerate inconsistent ordering.

## 1. Clarify the requirements

In an interview, I would start by asking the interviewer:

"Are we designing the entire live shopping experience, or should we focus on real-time auctions and bidding?"

For this walkthrough, we'll design the complete platform, but spend most of our time on the bidding subsystem.

### Functional requirements

| Feature          | Requirement                                                  |
| ---------------- | ------------------------------------------------------------ |
| Live streaming   | Sellers can start and stop broadcasts.                       |
| Discovery        | Buyers can browse and join live shows.                       |
| Live auctions    | Sellers can auction individual products.                     |
| Bidding          | Buyers can submit bids and see the highest bid in real time. |
| Auction timer    | Each auction has a countdown and ends automatically.         |
| Winner selection | The highest valid bid wins.                                  |
| Payments         | The winning buyer can complete the purchase.                 |
| Live chat        | Buyers can interact with sellers during the stream.          |

### Non-functional requirements

| Area                  | Target                         |
| --------------------- | ------------------------------ |
| Bid acknowledgment    | p99 under 200 ms               |
| Real-time bid updates | Under 500 ms for most viewers  |
| Video latency         | Approximately 2–5 seconds      |
| Availability          | 99.99% for bidding services    |
| Consistency           | Strong consistency per auction |
| Durability            | No loss of accepted bids       |
| Scalability           | Millions of concurrent viewers |

These are proposed interview targets, not eBay's published internal performance guarantees.

## 2. Capacity estimation

Let's establish reasonable hypothetical scale.

Concurrent viewers

# 1M

Concurrent live streams

# 10K

Peak incoming bids/sec

# 50K

Average video bitrate

# 2 Mbps

At 1 million simultaneous viewers consuming 2 Mbps each, video delivery requires approximately 2 Tbps of CDN egress capacity. That immediately tells us we should not serve video directly from application servers.

For bidding, 50,000 bids per second is substantial, but the distribution matters more than the total. One auction with 10,000 simultaneous bidders creates a different concurrency problem from 10,000 auctions each receiving one bid.

## 3. High-level architecture

<img width="650" height="650" alt="image" src="https://github.com/user-attachments/assets/58c3b140-444a-4bb7-a677-243c10a15a35" />

Conceptual architecture. The actual streaming and bidding data paths are separate; this diagram combines them for discussion.

We can divide the system into three independently scalable layers:

**1. Video plane**: Ingest streams, transcode into adaptive bitrates, and deliver via CDN using HLS or low-latency HLS.

**2. Auction control plane**: Create auctions, validate bids, determine winners, manage timers, and trigger settlement.

**3. Real-time communication plane**: _Maintain WebSocket connections_, _deliver bid updates_, _synchronize countdowns_, and _handle live chat_.

The next step is designing the most important path: placing a bid correctly under heavy concurrency.

## 4. API design

I would keep HTTP APIs for auction management and bid submission, and WebSockets for server-to-client updates.

| API                           | Purpose                          |
| ----------------------------- | -------------------------------- |
| `POST /v1/streams`            | Create a live broadcast          |
| `GET /v1/streams/{id}`        | Retrieve stream details          |
| `POST /v1/auctions`           | Create an auction                |
| `GET /v1/auctions/{id}`       | Get current state                |
| `POST /v1/auctions/{id}/bids` | Submit a bid                     |
| `GET /v1/auctions/{id}/bids`  | Paginated bid history            |
| `WS /v1/live`                 | Subscribe to live auction events |

Example bid request:

```
POST /v1/auctions/123/bids
Idempotency-Key: 74bd2...

{
  "amount": 150,
  "currency": "USD"
}
```

The authenticated identity determines the bidder ID; we shouldn't trust a bidder ID provided in the request body.

The response might look like:

```
{
  "bidId": "bid-987",
  "auctionId": "123",
  "status": "ACCEPTED",
  "amount": 150,
  "version": 42,
  "endsAt": "2026-10-20T15:00:30Z"
}
```

Important distinction: `ACCEPTED` means the bid was valid and committed, not necessarily that the buyer will ultimately win.

## 5. Database design

A relational database such as PostgreSQL makes sense for the critical auction state because we need transactions and reliable constraints.

```
AUCTIONS (
    auction_id       BIGINT PRIMARY KEY,
    seller_id        BIGINT,
    product_id       BIGINT,
    status           VARCHAR(20),
    current_bid      DECIMAL(12,2),
    highest_bidder   BIGINT,
    ends_at          TIMESTAMP,
    version          BIGINT
);

BIDS (
    bid_id           UUID PRIMARY KEY,
    auction_id       BIGINT,
    bidder_id        BIGINT,
    amount           DECIMAL(12,2),
    created_at       TIMESTAMP,
    sequence_number  BIGINT,
    idempotency_key  UUID
);

ORDERS (
    order_id         BIGINT PRIMARY KEY,
    auction_id       BIGINT UNIQUE,
    buyer_id         BIGINT,
    amount           DECIMAL(12,2),
    status           VARCHAR(20)
);
```

For a production implementation, I'd add appropriate foreign keys, a uniqueness constraint on the bid idempotency key scoped to the bidder, money precision, indexes, and an outbox table.

The `AUCTIONS` table is the authoritative representation of the latest winning bid and auction status.

# 6. Deep dive: How do we handle concurrent bids?

This is the centerpiece of the interview.

Imagine two users bidding at almost the same time:

Concurrent bid simulation

Incoming bidsSerialized result

User A

# $150

12:00:00.010

User B

# $160

12:00:00.011

Current bid: $100

Both requests arrive concurrently. Without coordination, each could read $100 and attempt to update the same auction.

Illustrative sequence numbers; acceptance also depends on increment rules and auction eligibility.

### The race condition

A naive implementation might do this:

```
Auction auction = repository.findById(auctionId);

if (bidAmount > auction.getCurrentBid()) {
    auction.setCurrentBid(bidAmount);
    repository.save(auction);
}
```

This is unsafe because multiple service instances can read the same old state. Both requests can pass validation and overwrite each other's changes.

### Approach A: Pessimistic locking

One robust initial solution is a database transaction with a row-level lock.

```
BEGIN;

SELECT *
FROM auctions
WHERE auction_id = 123
FOR UPDATE;

-- Validate bidder, auction status,
-- bid increment and server-side deadline.

INSERT INTO bids (...);

UPDATE auctions
SET current_bid = 160,
    highest_bidder = 456,
    version = version + 1
WHERE auction_id = 123;

-- Insert AuctionBidAccepted into outbox.

COMMIT;
```

The `FOR UPDATE` lock ensures only one transaction modifies that auction at a time.

Advantages: simple correctness model, ACID transactions, and easy recovery.

Disadvantages: a very popular auction becomes a hot row. Lock contention may raise bid latency significantly.

### Approach B: Optimistic concurrency control

Another option is to update only if the auction's version matches the version that the bidder read.

```
UPDATE auctions
SET current_bid = 160,
    highest_bidder = 456,
    version = version + 1
WHERE auction_id = 123
  AND version = 41
  AND status = 'ACTIVE';
```

If no row was updated, the request must reload the auction state, revalidate the bid, and potentially retry.

This works well with relatively low contention, but a hot auction can cause many retries. The bid record and state update must still be part of one transaction.

### Approach C: Single-writer bid engine per auction

<img width="723" height="411" alt="image" src="https://github.com/user-attachments/assets/b4f545dd-4219-4633-bc67-e176bdbdc9fa" />

For higher scale, I would explore a logical single-writer model.

We route requests for the same `auctionId` to the same logical processor. This allows us to serialize bids without requiring distributed locks for every request.

A possible implementation uses a Kafka partition key of `auctionId`, but there is an important tradeoff: asynchronous Kafka submission cannot automatically provide a synchronous, durable bid acceptance response.

We need a clearly defined acknowledgment protocol, committed results, and recovery behavior.

My preferred interview evolution:

Start with PostgreSQL row locking because it's easy to reason about and correct. Introduce auction-keyed single-writer processing when actual contention and traffic justify its complexity.

Even with a single writer, keep database-level fencing or version checks to protect against two processors temporarily believing they own the same auction.

## 7. Real-time updates: WebSocket + Kafka

Once a bid is committed, everyone watching the live auction needs to see the updated price.

The core flow is:

1. Buyer submits a bid using the API.
2. Bid Engine validates and commits the bid and an outbox event in one database transaction.
3. Outbox publisher publishes the event to Kafka, keyed by `auctionId`.
4. Real-time fanout consumers distribute the event to WebSocket gateways with subscribed viewers.
5. Connected buyers immediately see the new highest bid.

Example Kafka event:

```
{
  "eventType": "BID_ACCEPTED",
  "auctionId": "123",
  "bidId": "bid-987",
  "currentBid": 160,
  "highestBidder": "user-456",
  "version": 42,
  "endsAt": "2026-10-20T15:00:30Z"
}
```

Why use Kafka?

We might have one auction with 100,000 viewers. We don't want the Bid Engine to manage 100,000 socket connections or perform that many network operations after accepting a bid.

Kafka decouples bid processing from broadcasting.

However, Kafka partitions alone do not solve fanout to multiple WebSocket servers. Every gateway hosting viewers of an auction needs the update. I would add a subscription-aware fanout layer that delivers updates to the relevant gateways, with each gateway broadcasting locally.

### What if updates arrive out of order?

Every auction state change includes a monotonically increasing `version`.

For example:

- Client receives version 43.
- Network delays version 42.
- Client ignores version 42 because it is stale.

On reconnection or when detecting a gap, the client fetches an authoritative snapshot using `GET /auctions/{id}`.

This lets us use at-least-once event delivery while keeping the UI eventually consistent.

## 8. Auction timers and winner selection

This is another excellent interview deep dive.

eBay Live supports short auctions and optional extended bidding. Its published US FAQ describes a five-second extension triggered by late bids, although exact rules can vary by market and auction format.&#x20;

Our system needs to handle this without trusting client-side countdown timers.

Auction countdown demo

<img width="726" height="303" alt="image" src="https://github.com/user-attachments/assets/5aa2f91a-4396-452c-92ee-016aa180cb07" />
<img width="723" height="304" alt="image" src="https://github.com/user-attachments/assets/080b8399-acfc-4d1e-8005-d46cb4555873" />

The demo illustrates the countdown behavior, but a production system must use server-side deadlines and a durable state transition.

### How I'd implement it

Store `ends_at` in the database and allow the auction processor to extend it atomically within the same transaction that accepts a late bid.

When the deadline arrives, a scheduler attempts to close the auction:

```
UPDATE auctions
SET status = 'CLOSED',
    version = version + 1
WHERE auction_id = 123
  AND status = 'ACTIVE'
  AND ends_at <= CURRENT_TIMESTAMP;
```

In the real implementation, the closing transaction also determines the winner and emits an event.

The key is that bid acceptance and auction closure participate in the same serialization mechanism. Otherwise, we risk closing an auction while another transaction is accepting a bid.

I'd use delayed events or a scheduler as a wake-up mechanism, not as the authority on whether an auction has ended.

## 9. Video streaming architecture

Video is fundamentally different from bidding.

I would choose:

- RTMP or SRT for seller video ingest.
- A transcoding service to generate multiple resolutions.
- Low-Latency HLS for large-scale video distribution.
- CDN edge caching to handle millions of viewers.
- WebSockets for bidding, auction state, and chat.

An important distinction: the WebSocket-based bid updates might arrive before the corresponding action appears in the video because video delivery is delayed.

We should never delay authoritative bid processing to synchronize it with video. Instead, the client can display live auction state independently and include clear timing indicators.

For very interactive, smaller rooms, WebRTC could be considered. However, I wouldn't default to WebRTC for millions of passive viewers because its distribution architecture is more expensive and operationally complex.

## 10. Payments and order creation

When an auction closes, the highest eligible bidder should win.

According to eBay's documentation, eBay Live can automatically charge the winning bidder after the auction concludes.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.ebay.com\&sz=32)

eBay



We shouldn't call a payment provider while holding the auction's database lock.

Instead, use an asynchronous settlement workflow:

1. Commit the auction's `CLOSED` state and winner transactionally.
2. Create one order per auction using a unique `auction_id` constraint.
3. Process payment using an idempotency key based on the order.
4. Persist `PAID` or `PAYMENT_FAILED` and notify the buyer and seller.
5. Retry transient payment errors safely, and use a recovery workflow for definitive failures.

This is a good use case for the Saga pattern, since auction completion, order creation, and payment processing span multiple services.

The goal isn't a distributed ACID transaction across everything. The goal is durable state, idempotent operations, and recoverable business transitions.

## 11. Failure scenarios and tradeoffs

A senior-level interviewer will likely ask what happens when parts of the system fail.

| Failure scenario          | How I'd handle it                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------------- |
| Bid Engine crashes        | Retry using the idempotency key; verify the committed DB state.                               |
| Kafka unavailable         | Keep committed events in a transactional outbox and publish after recovery.                   |
| WebSocket disconnects     | Reconnect and retrieve an authoritative auction snapshot.                                     |
| Duplicate bid submission  | Return the original committed result for the same idempotency key.                            |
| Two bid processors active | Use fencing tokens or DB version checks to reject stale processors.                           |
| Auction scheduler crashes | Another worker scans overdue active auctions and safely closes them.                          |
| Payment times out         | Reconcile with the provider before retrying to prevent double charging.                       |
| Region outage             | Route to a designated failover region only after safely establishing single-writer ownership. |

One particularly important policy: If the bidding system cannot safely establish the authoritative state, fail closed for bids rather than acknowledging bids that might disappear.

This means temporarily rejecting or pausing bidding rather than sacrificing correctness during a network partition.

## 12. How I'd scale this system

I would scale the independent components according to their bottlenecks rather than indiscriminately adding replicas.

Bid Engine: Partition processing by `auctionId`. Each auction has a single logical serialization point. Hot auctions can be isolated onto dedicated processors, but individual auction state cannot simply be split across independent writers without a new coordination mechanism.

WebSocket Gateway: Horizontally scale persistent connections. Maintain a registry of which gateways serve which auctions, and batch fanout where appropriate.

Kafka: Partition by auction ID for ordered auction events. Partition-count planning should account for hot keys; adding partitions doesn't increase the parallelism of one auction's ordered event stream.

Database: Partition large bid-history datasets, index current auction state, route historical reads to replicas where safe, and keep winner-selection reads on the authoritative primary.

Video: Use CDN edge distribution and adaptive bitrate streaming so viewer growth doesn't translate directly into load on the video origin.

## 13. Monitoring and observability

I'd prioritize metrics tied to correctness and user experience.

| Metric                         | Why it matters                                                 |
| ------------------------------ | -------------------------------------------------------------- |
| Bid acceptance latency p95/p99 | Measures bidding responsiveness                                |
| Bid rejection rate by reason   | Identifies stale prices, expirations, and eligibility failures |
| Auction lock wait duration     | Detects hot-auction contention                                 |
| Auction close delay            | Detects slow timers or scheduler issues                        |
| Outbox age and Kafka lag       | Detects delayed real-time updates                              |
| WebSocket delivery lag         | Measures how quickly viewers see changes                       |
| Payment reconciliation backlog | Detects incomplete settlement                                  |
| Video rebuffering rate         | Measures streaming quality                                     |

For tracing, I'd propagate correlation IDs from bid submission through transaction commit, outbox publication, and fanout. The `auctionId`, `bidId`, and event version are particularly useful for reconstructing an auction's history.

# 14. What would I present in a 45-minute interview?

0–5 min

Clarify requirements

Auction flow, scale, deadlines and correctness guarantees.

5–12 min

API and data model

Live shows, auctions, bids, versioning, idempotency.

12–20 min

High-level architecture

Video, bidding and real-time communication planes.

20–35 min

Deep dive into bidding

Concurrency, bid ordering, auction timers, failover.

35–42 min

Scale and reliability

Kafka fanout, hot auctions, durable outbox, payments.

42–45 min

Tradeoffs and recap

Highlight consistency boundaries and why each technology was chosen.

### The five follow-up questions I'd be ready for

How do you guarantee two simultaneous bids don't produce the wrong winner?Serialize bid acceptance per auction using database row locking or a fenced single-writer processor. Validate and commit the bid and auction state atomically.

How do you handle 100,000 viewers on one auction?Keep bid commits independent of the number of viewers. Publish committed events asynchronously to a subscription-aware fanout layer, then let WebSocket gateways broadcast to their local connections.

What if a bid arrives at exactly the auction deadline?Use a defined server-side linearization point and compare against the authoritative deadline in the same serialized transaction. Client timestamps aren't sufficient.

What happens if Kafka is down?The database transaction can still commit the accepted bid and outbox event. An outbox publisher retries once Kafka recovers; clients can recover missing state through snapshots.

Would you use Redis to store the highest bid?Not as an ordinary disposable cache. The simplest design keeps SQL as the authority, with Redis for read acceleration. A Redis-authoritative design requires a much stronger durability and recovery protocol.

## My final architecture choice

For a first production version, I'd choose Java/Spring Boot for auction and bidding services, PostgreSQL for transactional state, Kafka for event distribution, Redis for caching and presence, WebSocket gateways for live updates, and CDN-based video streaming.

I would only introduce a dedicated single-writer bid engine once measurements showed that database contention was a real bottleneck.

The key design principle I'd emphasize to the interviewer is:

Bid acceptance needs strong consistency. Viewer updates need scalability. Video needs high-throughput distribution. Payments need recoverable, idempotent workflows.

Keeping those guarantees separate is what makes the architecture both correct and scalable.
