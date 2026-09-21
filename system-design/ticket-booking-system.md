Yes — I’d approach this as a classic **high-contention system design interview**, because the hardest part is not search or payment; it’s making sure **the same seat is never sold twice**, especially during traffic spikes.

# 1. Clarify the requirements

I’d begin with:

> We need to design a ticket-booking platform for movies, concerts, and sports where users can discover events, view seat availability, temporarily hold seats, pay, and receive confirmed tickets.

### Functional requirements

Users should be able to:

- Search/browse events
- View event details
- View venue and seat map
- Check real-time seat availability
- Select one or more seats
- Temporarily hold seats
- Pay
- Receive a confirmed booking/ticket
- View booking history
- Cancel/refund where permitted

Event organizers should be able to:

- Create events
- Configure venue/seating
- Configure ticket prices
- View bookings

The key distinction I'd establish early is:

```text
Venue
  └── Seats

Event
  └── EventSeat
```

The physical seat belongs to the venue, but **availability and price belong to the event**.

For example:

```text
Venue: Wembley Stadium
Seat: Section A, Row 10, Seat 25

Concert A:
    Price: $120
    Status: AVAILABLE

Concert B:
    Price: $160
    Status: BOOKED
```

---

# 2. Non-functional requirements

The important requirements are:

- Very high read traffic
- Extremely bursty traffic
- Low latency for browsing
- Strong consistency for seat allocation
- No double booking
- Payment operations must be idempotent
- Temporary reservations should expire automatically
- Search can be eventually consistent
- Booking/payment state must be durable

The most important invariant is:

```text
For one event:

(event_id, seat_id)

can belong to at most ONE active booking.
```

---

# 3. Scale assumptions

For an interview, I'd make rough assumptions rather than overdo capacity calculations.

For example:

```text
50M users

1M events/year

Popular event:
100,000 seats

Normal traffic:
50K reads/sec

Popular ticket release:
1M+ users arriving within seconds
```

The important observation is:

```text
Normal traffic != peak traffic
```

Ticketing systems have extreme **flash-crowd behavior**.

Taylor Swift tickets going on sale at 10 AM could take us from:

```text
10K requests/sec
```

to:

```text
1M requests/sec
```

within seconds.

So admission control matters a lot.

---

# 4. Core data model

## Venue

```text
Venue
------
venue_id
name
location
```

## Seat

```text
Seat
----
seat_id
venue_id
section
row
seat_number
seat_type
```

## Event

```text
Event
-----
event_id
venue_id
name
start_time
status
```

## EventSeat

This is one of the most important tables.

```text
EventSeat
---------
event_id
seat_id
price
status
version
```

Status:

```text
AVAILABLE
HELD
BOOKED
```

Potentially:

```text
(event_id, seat_id)
```

is the primary/unique key.

---

# 5. Seat hold

When someone chooses a seat:

```text
SeatHold
--------
hold_id
user_id
event_id
seat_id
expires_at
status
```

Statuses:

```text
ACTIVE
EXPIRED
CONSUMED
RELEASED
```

---

# 6. Booking

```text
Booking
-------
booking_id
user_id
event_id
status
total_amount
created_at
```

Possible status:

```text
PENDING_PAYMENT
CONFIRMED
PAYMENT_FAILED
CANCELLED
REFUNDED
```

And:

```text
BookingSeat
-----------
booking_id
seat_id
price_paid
```

Again, store the **price snapshot**.

If the organizer later changes:

```text
$100 → $150
```

an old booking still needs to show `$100`.

---

# 7. High-level APIs

Search:

```http
GET /events?query=coldplay&city=london
```

Event:

```http
GET /events/{eventId}
```

Seats:

```http
GET /events/{eventId}/seats
```

Reserve:

```http
POST /events/{eventId}/holds

{
  "seatIds": ["A-10-24", "A-10-25"]
}
```

Response:

```json
{
  "holdId": "H123",
  "expiresAt": "2026-09-21T10:10:00Z"
}
```

Checkout:

```http
POST /bookings
Idempotency-Key: abc-123

{
  "holdId": "H123",
  "paymentMethodId": "PM456"
}
```

Booking:

```http
GET /bookings/{bookingId}
```

---

# 8. High-level architecture

I'd draw something like this:

```text
                         ┌──────────────────┐
                         │   Web / Mobile   │
                         └────────┬─────────┘
                                  │
                           CDN / WAF / CDN
                                  │
                           API Gateway
                                  │
       ┌──────────────────────────┼────────────────────────────┐
       │                          │                            │
       ▼                          ▼                            ▼
┌─────────────┐            ┌─────────────┐              ┌─────────────┐
│ Event       │            │ Search      │              │ Seat        │
│ Service     │            │ Service     │              │ Availability│
└──────┬──────┘            └──────┬──────┘              │ Service     │
       │                          │                      └──────┬──────┘
       ▼                          ▼                             │
 Event DB                    OpenSearch                         ▼
                                                     Seat Inventory DB
                                                             │
                                                             ▼
                                                       Reservation
                                                          Service
                                                             │
                                                             ▼
                                                        Hold Store
                                                             │

                            ┌────────────────────┐
                            │ Booking / Checkout│
                            │      Service      │
                            └─────────┬──────────┘
                                      │
                        ┌─────────────┼─────────────┐
                        │             │             │
                        ▼             ▼             ▼
                 Reservation       Payment        Booking
                   Service         Service        Service
                                      │             │
                                      ▼             ▼
                                Payment Provider  Booking DB
                                                    │
                                                    ▼
                                                   Kafka
                                                    │
                         ┌──────────────────────────┼───────────────┐
                         ▼                          ▼               ▼
                  Ticket Service             Notifications     Analytics
                         │
                         ▼
                      QR Code
```

For large onsales I'd put another component before booking:

```text
                         USERS
                           │
                           ▼
                    CDN / WAF / Bot Filter
                           │
                           ▼
                     Waiting Room
                           │
                           ▼
                     Admission Gate
                           │
                           ▼
                      API Gateway
```

That becomes extremely important for popular events.

---

# 9. How do we prevent two users booking the same seat?

This is the main interview question.

Suppose:

```text
Seat A1 = AVAILABLE
```

Two users hit reserve simultaneously.

A naive implementation would be:

```text
User A reads AVAILABLE
User B reads AVAILABLE

User A → HELD
User B → HELD
```

Double reservation.

So we need an **atomic state transition**.

For example:

```sql
UPDATE event_seat
SET status = 'HELD',
    hold_id = :holdId,
    hold_expires_at = :expiresAt
WHERE event_id = :eventId
  AND seat_id = :seatId
  AND status = 'AVAILABLE';
```

Then examine:

```text
rows_updated = 1
    → reservation succeeded

rows_updated = 0
    → another user already got it
```

This is effectively:

```text
AVAILABLE → HELD
```

as one atomic operation.

No:

```text
SELECT
then
UPDATE
```

without locking.

---

# 10. Pessimistic vs optimistic locking

The interviewer may ask which strategy to use.

### Pessimistic locking

Something like:

```sql
SELECT *
FROM event_seat
WHERE event_id = ?
AND seat_id = ?
FOR UPDATE;
```

Pros:

- Simple correctness model

Cons:

- Locks held under contention
- Poorer performance during huge spikes
- Can cause lock waits/deadlocks

---

### Optimistic concurrency

Have:

```text
version = 5
```

Then:

```sql
UPDATE event_seat
SET status = 'HELD',
    version = version + 1
WHERE event_id = ?
AND seat_id = ?
AND version = 5
AND status = 'AVAILABLE';
```

If another user gets there first:

```text
rows_updated = 0
```

For high-scale systems I'd generally prefer a **conditional atomic update / compare-and-set style** operation rather than long-lived DB locks.

---

# 11. Multiple seats must be atomic

Suppose someone selects:

```text
A1
A2
A3
```

We don't want:

```text
A1 reserved
A2 reserved
A3 failed
```

and leave the user with a partial set unintentionally.

So for a small number of seats, execute the reservation in one database transaction:

```text
BEGIN

Reserve A1
Reserve A2
Reserve A3

If all succeed:
    COMMIT

Otherwise:
    ROLLBACK
```

Then return:

```text
Seats no longer available.
```

---

# 12. Temporary seat hold

Unlike the marketplace example, **ticketing normally should reserve seats before payment**.

Flow:

```text
User selects seat
       │
       ▼
AVAILABLE
       │
       ▼
HELD
       │
       │ payment completed
       ▼
BOOKED
```

Or:

```text
HELD
 │
 │ timeout
 ▼
AVAILABLE
```

---

# 13. How long should a hold last?

I'd usually propose:

```text
5–10 minutes
```

for a normal ticket checkout.

For example:

```text
Hold created: 10:00:00
Expires:      10:08:00
```

Why not 30 minutes?

Because during a popular event:

```text
100,000 seats
```

could effectively disappear while users sit idle.

Too short is also bad:

```text
2 minutes
```

may not give customers enough time to:

- Enter billing data
- Complete 3DS
- Handle payment provider redirects

So I would say:

> I'd start around 5–10 minutes and tune based on payment latency and abandonment data.

---

# 14. How do expired holds get released?

Don't rely purely on a timer for every seat.

You could store:

```text
expires_at
```

with the reservation.

When reading a seat:

```text
if status = HELD
AND expires_at < now
    treat as expired
```

And asynchronously clean them up.

For example:

```text
Hold Service
     │
     ▼
Delay queue / expiry worker
     │
     ▼
Release seat
```

Possible technologies:

```text
Redis TTL
Delay queue
Scheduled workers
Kafka delayed workflow
```

But the source of truth should remain durable.

---

# 15. Seat availability reads

We don't want every user refreshing a seat map to hammer the authoritative database.

Could use:

```text
Authoritative Seat DB
        │
        ▼
Availability events
        │
        ▼
Redis
```

Reads:

```text
Client
  │
  ▼
Seat Availability Service
  │
  ▼
Redis
```

But:

```text
Redis seat map
```

is only a **view**.

The final reservation still goes through the authoritative seat inventory operation.

So:

```text
Displayed:
Seat A1 = available

User clicks:
Reserve A1

Authoritative DB:
Sorry, someone got it 100 ms earlier.
```

That is okay.

---

# 16. Real-time seat map updates

For good UX, use:

```text
WebSocket / Server-Sent Events
```

For example:

```text
User A reserves A25
       │
       ▼
SeatHeld event
       │
       ▼
Kafka / pub-sub
       │
       ▼
WebSocket service
       │
       ▼
Other users see A25 turn unavailable
```

But again, the UI isn't authoritative.

---

# 17. Checkout flow

I'd draw the critical path like:

```text
User
 │
 │ select seats
 ▼
Reservation Service
 │
 │ atomic reservation
 ▼
HELD
 │
 ▼
Booking Service
 │
 │ create PENDING booking
 ▼
Payment Service
 │
 ▼
Payment Provider
 │
 │ authorized/captured
 ▼
Booking Service
 │
 ├── booking → CONFIRMED
 │
 └── seats → BOOKED
 │
 ▼
Ticket Service
 │
 ▼
Ticket / QR code
```

---

# 18. Payment + booking is a distributed transaction

The difficult question:

> Payment succeeds but order creation fails. What happens?

We cannot do:

```text
BEGIN TRANSACTION

Booking DB
Seat DB
Stripe

COMMIT
```

because Stripe/Adyen/etc. doesn't participate in our database transaction.

So use:

- Saga
- Idempotency
- Retries
- Compensation
- Reconciliation

---

# 19. Better payment order

I'd ideally create a durable booking record before payment:

```text
Reserve seats
     │
     ▼
Create booking:
PENDING_PAYMENT
     │
     ▼
Charge / authorize payment
     │
     ▼
Confirm booking
```

That way we always have a durable internal entity corresponding to a payment attempt.

---

# 20. What if payment succeeds but confirmation fails?

Example:

```text
Payment provider
      │
      ├── payment succeeds
      │
      ▼
Our service crashes
```

The customer might think:

```text
"Did I just lose $500?"
```

We need idempotency and reconciliation.

Payment request:

```text
payment_id = P123
idempotency_key = booking-B123
```

Retries:

```text
POST payment
POST payment
POST payment
```

must result in:

```text
ONE charge
```

not three.

Then provider webhook:

```text
PaymentSucceeded
       │
       ▼
Payment Service
       │
       ▼
Booking B123
       │
       ▼
CONFIRMED
```

---

# 21. What if booking ultimately cannot be created?

Then perform compensation:

```text
Payment succeeded
       │
       ▼
Booking cannot be completed
       │
       ├── refund / void payment
       │
       └── release seat
```

This is a Saga.

---

# 22. What if booking exists but payment failed?

Simple:

```text
Booking:
PENDING_PAYMENT
       │
       ▼
Payment failed
       │
       ├── Booking → PAYMENT_FAILED
       │
       └── Seat hold → RELEASED
```

---

# 23. Prefer authorization + capture where possible

A cleaner flow can be:

```text
Hold seats
     │
     ▼
Authorize payment
     │
     ▼
Confirm booking
     │
     ▼
Capture payment
```

Then if booking fails after authorization:

```text
void authorization
```

rather than refunding captured money.

Payment provider capabilities determine whether this is possible.

---

# 24. Booking state machine

I'd explicitly model states.

```text
                    ┌────────────────┐
                    │ PENDING_PAYMENT│
                    └───────┬────────┘
                            │
                 ┌──────────┴──────────┐
                 │                     │
            payment succeeds       payment fails
                 │                     │
                 ▼                     ▼
           ┌───────────┐        ┌──────────────┐
           │ CONFIRMED │        │PAYMENT_FAILED│
           └─────┬─────┘        └──────────────┘
                 │
              cancelled
                 │
                 ▼
           ┌───────────┐
           │ CANCELLED │
           └─────┬─────┘
                 │
                 ▼
            ┌─────────┐
            │REFUNDED │
            └─────────┘
```

State transitions should themselves be idempotent.

---

# 25. Massive traffic spike

This is probably the second-biggest part of the interview.

Suppose:

```text
100,000 seats

2,000,000 users
```

all arrive at `10:00:00`.

Simply autoscaling 500 application instances doesn't solve it.

The database is still finite.

The most important control is a **virtual waiting room**.

```text
2M users
   │
   ▼
Waiting Room
   │
   │ admit 5K/sec
   ▼
Booking system
```

You're deliberately limiting concurrency.

---

# 26. Waiting room architecture

```text
                           Internet
                              │
                              ▼
                         CDN / WAF
                              │
                              ▼
                     Virtual Waiting Room
                              │
                 ┌────────────┴────────────┐
                 │                         │
             waiting                   admitted
                 │                         │
                 ▼                         ▼
          Queue position               Signed token
                                           │
                                           ▼
                                      API Gateway
                                           │
                                           ▼
                                    Booking system
```

An admitted user receives a short-lived signed token:

```text
event_id
user_id
expires_at
nonce
signature
```

Requests without a valid admission token are rejected.

---

# 27. Why not just use Kafka as the waiting room?

This is a good subtle distinction.

You don't necessarily want to place every HTTP user into Kafka.

The waiting room is an **admission control mechanism**.

The goal is:

```text
Control how many users may interact with seat inventory simultaneously.
```

Kafka may still be used internally for:

- Booking events
- Notifications
- Analytics
- Search indexing

But the waiting room can be implemented at the edge / dedicated queue service.

---

# 28. Rate limiting

I'd have rate limits at multiple levels:

```text
IP
User
Account
Device
Event
Endpoint
```

For example:

```text
Search:
100 req/min

Seat refresh:
20 req/min

Hold attempts:
5/sec

Checkout:
much stricter
```

The goal isn't only security — it also protects the inventory database.

---

# 29. Hot partition problem

All requests for one popular concert may hit:

```text
event_id = E123
```

If we partition inventory only by `event_id`, one partition gets hammered.

Better shard within an event.

For example:

```text
hash(event_id, section_id)
```

or:

```text
event_id + seat_bucket
```

Example:

```text
Section A → shard 1
Section B → shard 2
Section C → shard 3
```

This lets reservation traffic spread across database partitions.

---

# 30. What about "best available" seats?

If the user doesn't select exact seats:

```text
Give me 4 adjacent seats
```

This is harder.

We can maintain structures like:

```text
Section A

Row 1:
[1][2][3][4][5][6][7]

available runs:
1–7
```

Then find a contiguous block.

Potentially maintain an optimized seat-allocation index/cache.

But once candidates are found:

```text
final reservation
```

must still be atomic against the authoritative inventory store.

---

# 31. Search

Search is straightforward compared with booking.

```text
Event DB
   │
   │ EventCreated / EventUpdated
   ▼
 Kafka
   │
   ▼
Search Indexer
   │
   ▼
OpenSearch / Elasticsearch
```

Search by:

- Artist/team/movie
- City
- Venue
- Date
- Event type

Event search can be eventually consistent.

---

# 32. Caching

Good things to cache:

```text
Event metadata
Venue information
Seat map geometry
Artist images
Static event pages
```

Use CDN aggressively.

For example:

```text
90% of event page content
```

can come from CDN/cache.

Seat availability is dynamic, so:

```text
short TTL / streaming updates
```

rather than long-lived caching.

---

# 33. Bot prevention

Another major follow-up.

There isn't a single solution; use multiple signals.

At the edge:

```text
WAF
Rate limiting
Bot detection
CAPTCHA / challenges
```

Account controls:

```text
Verified email
Verified phone
Account age
Purchase history
```

Purchase rules:

```text
Max 4 tickets per account
Max 4 per payment instrument
Max N per phone number
```

Device/risk analysis:

```text
IP reputation
Device fingerprint
Request behavior
Automation patterns
Datacenter/VPN detection
```

---

# 34. Don't put CAPTCHA everywhere

A CAPTCHA for every normal user creates poor UX.

Better:

```text
Risk scoring
     │
     ├── low risk → continue
     │
     └── suspicious → challenge
```

For example:

```text
100 seat requests/sec
Headless browser signature
Multiple accounts
Same card
Same device

        ↓

Challenge / block
```

---

# 35. Signed reservation tokens

When someone holds seats, I might return a token like:

```text
hold_id
event_id
seat_ids
user_id
expires_at
```

signed by the server.

Checkout then requires:

```text
hold token + authenticated user
```

This makes it harder to manipulate:

```text
seat IDs
price
expiry
```

on the client side.

But again, always revalidate server-side.

---

# 36. Event-driven components

Kafka/events could handle:

```text
SeatHeld
SeatReleased
BookingCreated
BookingConfirmed
PaymentSucceeded
PaymentFailed
TicketIssued
BookingCancelled
RefundCompleted
```

Consumers:

```text
Notifications
Analytics
Ticket generation
Fraud detection
Seat-map updater
Organizer reporting
```

---

# 37. Reliable event publishing

Use the transactional outbox pattern.

Without it:

```text
Booking DB commits
       │
       ▼
Service crashes
       │
       ▼
BookingConfirmed event never published
```

Instead:

```text
BEGIN

INSERT booking
INSERT outbox_event

COMMIT
```

Then:

```text
Outbox publisher
      │
      ▼
Kafka
```

---

# 38. Ticket generation

Once booking is confirmed:

```text
BookingConfirmed
       │
       ▼
Ticket Service
       │
       ▼
Generate ticket
       │
       ▼
QR / barcode
```

Ticket should contain something like:

```text
ticket_id
booking_id
event_id
seat_id
signed payload
```

At venue entry:

```text
Scanner
   │
   ▼
Validation Service
```

and enforce:

```text
unused → admitted
```

atomically so the same ticket can't be scanned twice.

---

# 39. Database choices

I'd use different systems for different workloads.

### Event metadata

```text
PostgreSQL / MySQL
```

### Seat inventory

Strongly consistent transactional database.

For example:

```text
PostgreSQL / MySQL
```

partitioned/sharded at large scale.

### Booking

```text
Relational DB
```

because we care about transactions and state transitions.

### Holds / fast seat-view cache

```text
Redis
```

But I would **not make Redis alone the final authority for booked seats** unless the system has been specifically engineered around that consistency model.

### Search

```text
OpenSearch / Elasticsearch
```

---

# 40. Strong vs eventual consistency

I'd explicitly call this out in the interview.

### Strong consistency

```text
Seat reservation
Seat booking
Booking state
Payment state
Ticket redemption
```

### Eventual consistency

```text
Search
Recommendations
Analytics
Seat-map display
Organizer dashboards
Notifications
```

This is an important architectural distinction.

---

# 41. Final architecture

This is roughly the diagram I'd finish with:

```text
                               USERS
                                 │
                                 ▼
                           CDN / WAF
                                 │
                                 ▼
                         Bot Protection
                                 │
                                 ▼
                        Virtual Waiting Room
                                 │
                                 ▼
                           API Gateway
                                 │
       ┌─────────────────────────┼────────────────────────────┐
       │                         │                            │
       ▼                         ▼                            ▼
┌──────────────┐          ┌────────────┐              ┌──────────────┐
│ Event Service│          │   Search   │              │ Seat View    │
└──────┬───────┘          │  Service   │              │ Service      │
       │                  └─────┬──────┘              └──────┬───────┘
       ▼                        ▼                             ▼
   Event DB                 OpenSearch                      Redis
       │
       ▼
     Kafka


                        ┌─────────────────┐
                        │ Reservation     │
                        │ Service         │
                        └────────┬────────┘
                                 │
                                 ▼
                         Seat Inventory DB
                                 │
                                 ▼
                            Seat Hold
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ Booking Service │
                        └────────┬────────┘
                                 │
                  ┌──────────────┼──────────────┐
                  │              │              │
                  ▼              ▼              ▼
             Booking DB     Payment Service   Kafka
                                  │              │
                                  ▼              ├── Ticket Service
                           Payment Provider      ├── Notification
                                                 ├── Analytics
                                                 └── Fraud Detection
```

## The interview summary I'd give

> The design separates read-heavy event discovery from the strongly consistent booking path. Event metadata and search can be cached and eventually consistent, while seat allocation requires atomic state transitions to guarantee that a seat cannot be held or booked by two users simultaneously. Selecting a seat creates a short-lived hold, typically around 5–10 minutes. Checkout is coordinated using a Saga with durable booking state, idempotent payment operations, retries and compensation. For popular events, a virtual waiting room and admission control protect the reservation database from millions of concurrent users, while rate limiting, risk scoring, purchase limits and bot detection reduce automated ticket grabbing.

The three areas I would expect an interviewer to drill into most are **seat locking/holds**, **payment consistency**, and **traffic spikes/waiting-room design**.
