# eBay Live: System design and architecture

Let's approach eBay Live as a system design interview question: Design a live shopping platform where sellers stream products, buyers interact in real time, and customers can bid on or purchase items without the system losing bids or creating duplicate orders.

The important thing is to separate the problem into two systems:

1. Media delivery — getting live video to thousands of viewers with low latency.
2. Commerce and real-time interactions — handling bids, inventory, orders, chat, and payments correctly.

These systems have very different requirements. Video can tolerate a little delay or occasional frame loss. An accepted winning bid or a completed payment cannot be handled casually.

One clarification: the architecture below is a reference design for an eBay Live-like platform, not a claim about eBay's exact internal service topology.

## 1. High-level architecture

Buyer and seller applications

Web / mobile · Live video · Chat · Bidding · Checkout

HTTPS · WebSocket · WebRTC where needed

Edge and API layer

CDN · API Gateway · Authentication · Rate limiting · WebSocket gateway

Media plane

Ingest → Transcoding → Packaging → CDN → Viewers

Commerce plane

Live sessions · Auctions · Inventory · Orders · Payments

Events and asynchronous workflows

Event backbone — Kafka or equivalent

Bid events · Session events · Order events · Notifications · Analytics

Operational storage

Relational DB · Redis · Durable event log

Background processing

Outbox publishers · Workers · Reconciliation · Monitoring

Think of this as a logical architecture. The actual deployment might split or combine services differently depending on scale and existing marketplace infrastructure.

## 2. What each service is responsible for

Imagine you're building the backend using Java and Spring Boot, with Kafka, Redis, and a relational database.

| Service                  | Responsibility                                                               |
| ------------------------ | ---------------------------------------------------------------------------- |
| Live Session Service     | Creates events, manages event state, and tracks which listings are featured. |
| Stream Ingest Service    | Receives the seller's live video feed.                                       |
| Media Processing Service | Transcodes video into multiple resolutions and packages it for playback.     |
| CDN                      | Delivers video efficiently to viewers around the world.                      |
| Chat Service             | Receives messages, moderates them, and distributes them to viewers.          |
| Auction Service          | Validates bids, determines the leading bid, and closes auctions.             |
| Inventory Service        | Tracks available, reserved, and sold quantities.                             |
| Order Service            | Creates and manages purchase orders.                                         |
| Payment Service          | Coordinates payment authorization, capture, and failure handling.            |
| Notification Service     | Sends outbid, auction-won, order, and event-reminder notifications.          |
| Analytics Service        | Calculates viewers, bidding activity, sales, and conversion metrics.         |

eBay's public documentation confirms that sellers can manage events, control their item lineup, moderate chat, run auctions, and process purchases through the Live experience. The services above are a proposed decomposition of those responsibilities, not eBay's published internal service map.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.ebay.com\&sz=32)

eBay

+1



### Why not build one giant microservice?

Suppose the video feed experiences a traffic spike. You need more media delivery capacity, but you don't necessarily need more order-processing capacity.

Likewise, a popular auction might receive hundreds of bids per second while the rest of the live session remains relatively quiet.

Separating these responsibilities allows independent scaling, deployment, and failure isolation. However, don't create a separate microservice for every small operation; each service introduces network calls, operational overhead, and distributed failure modes.

## 3. How live video reaches thousands of viewers

Seller's camera / OBS

Video and audio capture

Ingestion endpoint

Authenticates and receives the stream

Transcoding and packaging

Creates multiple quality levels and stream segments

Origin storage / origin server

Provides stream segments and manifests

CDN edge locations

Caches and serves video near viewers

Thousands of buyer devices

Adaptive-quality playback

### Why use a CDN instead of sending video from the backend?

Suppose 10,000 viewers each receive a 3 Mbps stream.

\\[ 10{,}000 \times 3\text{ Mbps}=30\text{ Gbps} \\]

That is the approximate aggregate video delivery bandwidth, before protocol overhead and other traffic.

If every viewer's video passed through your Java application servers, the backend would become an expensive bottleneck. A CDN distributes this delivery load across its edge infrastructure.

### HLS or WebRTC?

- HLS / Low-Latency HLS: A good fit for broadcast-style shopping with many viewers. It can scale well through a CDN, but viewers may see the stream a few seconds behind the seller.
- WebRTC: Useful when very low latency and interactive audio/video are important. It typically requires more specialized real-time media infrastructure.
- Hybrid approach: Deliver the main broadcast through a CDN and use WebSockets for chat and bidding. This avoids requiring every viewer to maintain a direct real-time video connection.

The key principle: the video stream is not the source of truth for the auction. A viewer might see a bid arrive before or after another viewer does. The Auction Service decides which bids are accepted and who wins.

## 4. The most critical component: Auction Service

This is where the design becomes interesting from a distributed systems perspective.

Imagine one collectible item with a current leading bid of $100. Three buyers submit bids at almost the same time:

- Buyer A: $110
- Buyer B: $120
- Buyer C: $115

If three application instances independently read the current bid, they might all observe $100. Each could incorrectly believe its bid is valid based on that stale value.

You need a single authoritative ordering of bids for each auction.

### Recommended design: partitioned ownership

Buyer clients → API Gateway → Auction Service instances

Route by `auctionId`

All bids for the same auction reach the same logical owner

Auction state transition

Validate → Order → Accept/reject → Persist

Durable database + event publication

WebSocket gateways → All interested buyers

This logical owner could be implemented with a partitioned actor, a partitioned command stream, or database transactions and concurrency controls. It does not have to mean a permanently dedicated server per auction.

### How a bid should be processed

1. Authenticate the buyer and verify eligibility to bid.
2. Check the auction's state, end time, bid increment, and current leading bid.
3. Deduplicate the request using an idempotency key.
4. Serialize competing bid commands for the same auction, or use an atomic conditional database update.
5. Persist the accepted bid and new auction state durably.
6. Publish the resulting event and notify interested buyers.

For a relational database, a simplified conditional update might look like this:

```
UPDATE auction
SET current_bid = :new_bid,
    leader_id = :bidder_id,
    version = version + 1
WHERE auction_id = :auction_id
  AND status = 'OPEN'
  AND current_bid < :new_bid
  AND version = :expected_version;
```

If the update affects zero rows, the bid lost a race or the auction state changed. The service must reload the state and decide whether to retry or reject the bid. A production implementation must also enforce bid increments, auction deadlines, and the required tie-breaking policy.

Important: This SQL is illustrative, not a complete auction implementation. The auction's state and all bid rules must be enforced atomically. If accepted bids need a durable history, persist the bid record in the same transaction as the state change.

### Where does Kafka fit?

Kafka is excellent for distributing events such as:

- `BidAccepted`
- `BidRejected`
- `AuctionExtended`
- `AuctionEnded`
- `OrderCreated`

Partitioning events by `auctionId` helps preserve event order within a partition.

However, simply sending bids to Kafka does not automatically guarantee correct bidding. You still need a well-defined authoritative state machine, durable acceptance rules, idempotency, and safe handling of consumer failures.

## 5. What happens when two buyers bid simultaneously?

Let's walk through a concrete example.

Assume the auction currently has a leading bid of $100 and the minimum valid next bid is $105.

Buyer A

## $110

Buyer B

## $120

Both requests arrive close together

Auction state before processing

Current leading bid

### $100

Auction status

OPEN

Request A is processed first

- $110 exceeds $100, so it is accepted.
- The leading bid becomes $110.

Request B is processed second

- The service reads the updated $110 state.
- $120 exceeds $110, so it is accepted.
- The leading bid becomes $120.

Final state

# $120

Buyer B leads; the accepted bid history remains durable.

The order might be reversed in reality. If Buyer B's request is processed first, Buyer A's $110 bid would no longer exceed the leading bid. The system must follow a defined ordering rule rather than relying on timestamps from different client devices.

### What if the bids have the same amount?

Define an explicit policy for equal bids, such as accepting the first valid bid in the authoritative processing order. Don't depend on whichever application server happens to finish first.

### What if a buyer retries after a timeout?

Use an idempotency key, such as `bidRequestId`.

If the server accepted the bid but the response was lost, the retry should return the original result rather than creating a second accepted bid.

This is a general distributed-systems principle: a network timeout does not prove that the operation failed.

## 6. How an auction ends

An auction ending is a state transition, not merely a countdown reaching zero in the browser.

The client-side timer is only a display. The server determines whether the auction is open, extended, or closed.

A robust auction state machine might look like this:

SCHEDULED

Auction configured but not started

OPEN

Accept valid bids

CLOSING / EXTENDED

Apply the configured closing and extension rules

CLOSED

Persist the winner and final price

ORDER PENDING

Create the purchase and initiate payment

For example, eBay documents an optional extended-auction behavior in which a bid during the final five seconds adds another five seconds to the auction. Your system would need to implement the precise configured rule and make the closing transition atomic.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.ebay.com\&sz=32)

eBay

+1



For reliability, the system should:

- Use server-controlled deadlines rather than client clocks.
- Run scheduled closing jobs that can be retried safely.
- Make closing idempotent so multiple workers cannot create different winners.
- Reject bids that arrive after the authoritative deadline, subject to the platform's explicitly defined deadline policy.
- Recover unfinished auctions after a process crash.

A scheduler can trigger a closing attempt, but the database transaction or authoritative auction owner must decide whether closing is actually allowed.

## 7. How the winning bid becomes an order

This is where microservices design patterns become especially important.

Suppose Buyer B wins at $120. The platform needs to record the winning bid, create the order, reserve or allocate the item, and collect payment.

These operations may span multiple services and databases. A single local database transaction cannot atomically commit all of them.

A typical workflow is:

### 1

### Auction Service

Persist final winner and close auction

### 2

### Order Service

Create order using an idempotency key

### 3

### Inventory Service

Confirm the item is allocated to this order

### 4

### Payment Service

Authorize or charge through the payment provider

### 5

### Order Service

Mark paid, pending payment, or failed

### Use the transactional outbox pattern

Imagine the Auction Service commits the winning bid to its database but crashes before publishing `AuctionEnded` to Kafka.

The auction is closed, but the Order Service never hears about it.

The transactional outbox solves this dual-write problem:

1. In one database transaction, save the final auction state and an outbox event.
2. A background publisher reads unpublished outbox events and sends them to Kafka.
3. After publication, mark the event as published.
4. If publication is retried, downstream consumers deduplicate using a stable event ID.

This avoids losing an event merely because the process crashed between the database commit and Kafka publication. Duplicate delivery is still possible, so consumers must be idempotent.

### What if payment fails?

Don't reopen the auction automatically just because payment failed.

Instead, persist a payment-pending or payment-failed state and apply a clearly defined recovery policy. That might involve retrying payment, prompting checkout, or allowing cancellation according to business rules.

eBay's public buyer guidance says winning-auction payments are processed automatically, with further checkout steps if the payment fails.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.ebay.com\&sz=32)

eBay

+1



Pattern to remember: this workflow is a strong candidate for the Saga pattern, with explicit state transitions, retries, and compensating actions where appropriate.

## 8. Where Redis, databases, and Kafka fit

A common mistake in system design is choosing a technology before deciding what guarantee the data requires.

| Technology         | Use it for                                                            | Why                                                 |
| ------------------ | --------------------------------------------------------------------- | --------------------------------------------------- |
| PostgreSQL / MySQL | Orders, auction state, bid records, inventory                         | Durable transactions and constraints                |
| Redis              | Session metadata, cached listings, viewer presence, rate limits       | Low-latency reads and ephemeral state               |
| Kafka              | Accepted-bid events, order events, notifications, analytics pipelines | Durable event streaming and asynchronous processing |
| Object storage     | Video archives, thumbnails, video receipts                            | Cost-effective storage of large media objects       |
| CDN                | Live video and static content delivery                                | Reduces origin load and geographic latency          |
| WebSocket gateways | Chat, bid updates, auction countdown updates                          | Persistent connections for server-to-client updates |

These are possible choices, not mandatory technologies.

### Should the current bid be stored in Redis?

Redis can help serve the current leading bid quickly, but I would not use an ordinary cache entry as the only authoritative record of a financially meaningful auction.

A safer approach is:

- Store authoritative bid acceptance and auction state in a transactional store or a durable, correctly partitioned auction engine.
- Use Redis to serve frequently requested snapshots and other ephemeral information.
- Publish accepted-bid events to distribute updates.
- Reconcile projections against the authoritative state when recovering from failures.

Redis itself can support atomic operations, but durability, failover, and consistency depend on the chosen configuration. The design must explicitly state what happens if a write is acknowledged and then lost during failover.

## 9. Real-time updates without overloading the backend

When a bid is accepted, the system needs to update thousands of viewers quickly.

For example:

1. Auction Service accepts a bid.
2. It persists the new state.
3. An event is published to Kafka.
4. A real-time fan-out service consumes the event.
5. WebSocket gateways send the update to connected buyers.
6. Clients update the displayed leading bid and bidder status.

Auction Service

Bid accepted: $120

Kafka

BidAccepted event

Fan-out service

Find gateways serving this auction

Gateway A

Gateway B

Gateway C

Each gateway updates the buyers connected to it.

### Why not send the event directly to every buyer?

Suppose 20,000 viewers are connected to 40 WebSocket gateway instances. A single bid event should not require the Auction Service to make 20,000 individual network calls.

Instead, use a fan-out layer that identifies the gateways with interested subscribers. Each gateway manages its own local connections.

Also, don't broadcast every event to every connection. Partition subscribers by `auctionId` or `sessionId`, and enforce limits on chat and other high-volume events.

### What happens when a viewer reconnects?

WebSocket messages are not a durable history by themselves.

On reconnect, the client should fetch the latest authoritative or versioned auction snapshot. It can then resume receiving updates from that version onward, where supported.

Include a monotonically increasing version or sequence number in updates. If the client receives version 25 followed by version 23, it can ignore the stale event and refresh if necessary.

## 10. Scaling and handling failures

A strong system design should explain not only how the happy path works, but also what happens when components fail.

| Problem                                     | Design response                                                                           |
| ------------------------------------------- | ----------------------------------------------------------------------------------------- |
| A stream becomes popular suddenly           | Scale CDN delivery independently of commerce services.                                    |
| Thousands of buyers join one auction        | Partition WebSocket fan-out and apply backpressure.                                       |
| A bid request times out                     | Retry with the same idempotency key and return the original outcome if already processed. |
| Kafka consumer is unavailable               | Retain events durably and resume consumption; monitor consumer lag.                       |
| An auction worker crashes                   | Recover from persisted state and resume processing without creating a second winner.      |
| Payment provider is unavailable             | Keep the order in a pending state and retry safely.                                       |
| Duplicate order-creation event              | Deduplicate by event ID or unique auction/order business key.                             |
| Two buyers purchase the last available item | Use an atomic inventory reservation or conditional update.                                |
| Cache contains stale auction data           | Refresh from the authoritative state; never trust the cache to decide the winner.         |
| WebSocket connection drops                  | Reconnect, fetch a fresh snapshot, and resume updates.                                    |

### A subtle issue: inventory races

Suppose the same item is available both as a live Buy It Now listing and through another marketplace purchase path.

Both requests might see quantity `1`.

If both independently read the quantity and then decrement it, the system could sell an item twice.

A transactional conditional update can prevent that:

```
UPDATE inventory
SET available_quantity = available_quantity - 1
WHERE item_id = :item_id
  AND available_quantity >= 1;
```

If exactly one request updates the row, that request successfully allocates the item. The other receives zero affected rows and must be rejected or handled through the platform's defined reservation policy.

This becomes especially important when live events use listings that also exist in the broader marketplace. eBay's seller documentation explicitly notes that event listings are not automatically exclusive to an event.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.ebay.com\&sz=32)

eBay



## 11. Observability and operational requirements

For a production platform, I would monitor separate service-level objectives for video, real-time interactions, and commerce.

- Media: stream startup time, playback latency, rebuffering rate, dropped frames, and ingest failures.
- Auctions: bid acceptance latency, rejected-bid rate, auction-close accuracy, and duplicate bid attempts.
- Real-time messaging: WebSocket connection count, fan-out latency, disconnections, and consumer lag.
- Commerce: order creation success rate, payment success rate, inventory conflicts, and reconciliation failures.
- Reliability: error rates, availability, database saturation, queue depth, and recovery time.

I would also propagate a correlation ID across the request, bid processing, event publication, order creation, and payment workflow. That makes it much easier to trace a failure across multiple services.

## 12. Putting it together: an example technology stack

For a Java backend engineer, one reasonable implementation could be:

### Application services

Java · Spring Boot

Session, auction, inventory, order, and payment orchestration

### Real-time communication

WebSockets · Redis Pub/Sub or Kafka

Chat and updates, with a suitable durable event path for critical events

### Event streaming

Apache Kafka

Partitioned event processing, retries, and asynchronous consumers

### Transactional persistence

PostgreSQL

Auction state, accepted bids, order records, and transactional outbox

### Caching

Redis

Read-heavy metadata, rate limits, presence, and cached snapshots

### Media infrastructure

Managed video ingest · Transcoding · HLS · CDN

Video delivery without routing media through application servers

### Observability

OpenTelemetry · Metrics · Logs · Tracing

End-to-end latency, error analysis, and operational alerting

I would start with a modular, well-defined service architecture and split services according to scaling, ownership, and consistency requirements. I would not introduce every possible infrastructure component on day one.

## 13. The five most important system-design decisions

If this were an interview, these are the decisions I would emphasize:

1. Separate the media plane from the commerce plane. Video delivery and transactional correctness have different scaling and latency requirements.
2. Serialize state changes per auction. Every accepted bid must have one authoritative outcome.
3. Use durable events and idempotent consumers. Kafka, retries, and the transactional outbox help prevent lost work, but they do not eliminate duplicates.
4. Treat checkout as a distributed workflow. Orders, inventory, and payments require explicit state transitions and recovery logic.
5. Scale real-time fan-out independently. WebSocket gateways distribute updates, while the auction engine remains responsible for deciding which bids are valid.

The biggest takeaway is that eBay Live is not simply a video-streaming system with a shopping cart attached. It is a combination of a large-scale media delivery platform, a real-time messaging system, and a transactional marketplace. The engineering challenge is making those parts work together while preserving correctness when requests race, services fail, and traffic spikes.
