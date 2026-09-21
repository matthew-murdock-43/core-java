For this one, I’d frame the interview around a **durable distributed log**, similar conceptually to Kafka, with a platform layer around it for **schemas, governance, retries, replay, observability, and tenant isolation**.

The key idea I'd establish early is:

> Producers append immutable business events to partitioned topics. Each consumer group maintains its own progress independently, so consumers can process, fail, scale, or replay events without affecting other consumers.

# 1. Clarify the requirements

Assume internal services publish events such as:

```text
OrderCreated
PaymentAuthorized
InventoryReserved
UserRegistered
ShipmentDelivered
```

and many independent systems consume them:

```text
OrderCreated
     │
     ├──► Fulfillment
     ├──► Notifications
     ├──► Analytics
     ├──► Fraud Detection
     └──► Recommendations
```

We need:

- Durable event storage
- Multiple independent consumers
- Ordering where required
- At-least-once processing by default
- Replay
- Schema evolution
- Retry/DLQ support
- Producer/consumer isolation
- Access control
- Monitoring

I would explicitly separate **business events** from commands.

```text
OrderCreated
```

describes something that happened.

```text
CreateOrder
```

is requesting that something happen.

That distinction is useful for event-bus governance.

---

# 2. Scale assumptions

For discussion, assume:

```text
5,000 services

100K–1M events/sec peak

Average event size:
1–10 KB

Thousands of topics

Hundreds/thousands of consumer groups
```

Retention might range from:

```text
7 days
30 days
90 days
```

depending on topic.

Some important topics may have longer archival retention.

---

# 3. Core event model

I would standardize an event envelope:

```json
{
  "eventId": "evt-123",
  "eventType": "OrderCreated",
  "schemaVersion": 3,
  "producer": "order-service",
  "timestamp": "...",
  "correlationId": "cid-456",
  "traceId": "trace-789",
  "partitionKey": "order-123",
  "payload": {
    "orderId": "order-123"
  }
}
```

Important fields include:

```text
event_id
event_type
schema_version
producer
timestamp
correlation_id
trace_id
partition_key
payload
```

`eventId` becomes particularly important for deduplication.

---

# 4. High-level architecture

I'd draw:

```text
                          PRODUCERS
                              │
                              ▼
                       Producer SDK
                              │
                              ▼
                       Event Gateway
                              │
                     Auth / Validation
                              │
                              ▼
                    Schema Validation
                              │
                              ▼
                    ┌─────────────────┐
                    │ Event Bus       │
                    │ Kafka/Pulsar    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       Consumer Group A Consumer Group B Consumer Group C
              │              │              │
              ▼              ▼              ▼
         Fulfillment      Analytics      Notification
```

Platform services around it:

```text
                    Event Platform
                          │
       ┌──────────────────┼──────────────────┐
       ▼                  ▼                  ▼
 Schema Registry      Topic Catalog      Observability
       │                                     │
       ▼                                     ▼
Compatibility                            Lag / DLQ /
Validation                               Throughput
```

---

# 5. Topics and partitions

Events live in topics:

```text
orders.events
payments.events
inventory.events
```

Each topic is split into partitions:

```text
orders.events

Partition 0
Partition 1
Partition 2
Partition 3
```

Partitions provide parallelism.

If an event has:

```text
partition_key = order_id
```

then all events for the same order go to the same partition.

Example:

```text
Order 123

OrderCreated
PaymentAuthorized
OrderConfirmed
OrderShipped
```

all land in order:

```text
Partition 7

offset 100  OrderCreated
offset 101  PaymentAuthorized
offset 102  OrderConfirmed
offset 103  OrderShipped
```

---

# 6. Ordering

I would explicitly say:

> I would not provide global ordering across the entire event bus. I would provide ordering within a partition.

Global ordering creates an enormous scalability bottleneck.

So choose a partition key based on the ordering domain:

```text
order_id
customer_id
account_id
aggregate_id
```

For example:

```text
partitionKey = account_id
```

if transactions for one account must remain ordered.

Different accounts can be processed concurrently.

---

# 7. Consumer groups

This is fundamental.

Suppose three different applications want `OrderCreated`.

```text
orders.events
      │
      ├── group=fulfillment
      ├── group=analytics
      └── group=notifications
```

Each has an independent offset.

Example:

```text
fulfillment   offset 15,300
analytics     offset 14,500
notification  offset 15,280
```

Analytics being slow does not stop fulfillment.

That's one of the biggest benefits of the architecture.

---

# 8. Scaling consumers

Within a consumer group:

```text
Topic:
P0 P1 P2 P3
```

could be assigned:

```text
Consumer A → P0
Consumer B → P1
Consumer C → P2
Consumer D → P3
```

If one consumer crashes, partitions are reassigned.

The maximum effective parallelism for that group is roughly bounded by partition count.

So partition sizing matters.

---

# 9. Producer reliability

A producer shouldn't do:

```text
INSERT business row

then

publish event
```

naively.

Suppose:

```text
DB commit succeeds
      │
      ▼
service crashes
      │
      ▼
event never published
```

We now have inconsistent state.

This is the **dual-write problem**.

---

# 10. Transactional outbox

I'd solve this using an outbox.

```text
BEGIN

INSERT INTO orders ...
INSERT INTO outbox_events ...

COMMIT
```

Same DB transaction.

Then:

```text
Outbox Publisher
      │
      ▼
Event Bus
```

If publishing fails:

```text
event remains in outbox
```

and retries.

So:

```text
Order DB state
+
event creation
```

are atomic.

A CDC system like Debezium could alternatively publish the outbox records.

---

# 11. At-least-once processing

This should be the platform default.

Flow:

```text
Consumer
   │
   │ receive event E
   ▼
Process event
   │
   ▼
Commit offset
```

Suppose:

```text
Process succeeds
     │
     ▼
consumer crashes
     │
     X offset not committed
```

After restart:

```text
Event E delivered again
```

So:

```text
at-least-once
=
messages may be duplicated
but should not be lost
```

Consumers therefore need idempotency.

---

# 12. Consumer idempotency

Example:

```text
event_id = E123
```

Consumer keeps:

```text
processed_events

E123
E124
E125
```

On receiving E123 again:

```text
already processed
→ skip
```

Or design the downstream mutation itself idempotently.

For example:

```sql
INSERT INTO processed_event(event_id)
VALUES ('E123')
ON CONFLICT DO NOTHING;
```

Ideally the idempotency record and business mutation occur in the same DB transaction.

---

# 13. Exactly-once

This is where I would be careful in the interview.

I wouldn't promise magical exactly-once execution across arbitrary systems.

I'd say:

> Exactly-once delivery is different from exactly-once business effects.

Kafka-like systems can provide transactional semantics within their ecosystem.

For example:

```text
consume event
     │
     ▼
transform
     │
     ▼
produce another Kafka event
```

can potentially be atomic using transactions.

```text
Kafka input
  │
  ▼
Processor
  │
  ▼
Kafka output
```

This can provide effectively/exactly-once stream-processing semantics.

---

# 14. External side effects

But suppose consumer does:

```text
Kafka event
   │
   ▼
Charge credit card
```

The event bus cannot automatically make the external payment provider participate in its transaction.

So I would use:

```text
at-least-once
+
idempotency key
```

Example:

```text
payment_request_id = event_id
```

Retrying E123 doesn't charge twice.

That's generally the more realistic answer.

---

# 15. Schema registry

Next big follow-up:

> How do you evolve schemas?

Introduce:

```text
Schema Registry
```

Event producers register:

```text
OrderCreated v1
OrderCreated v2
OrderCreated v3
```

Possible serialization:

```text
Avro
Protobuf
JSON Schema
```

I would probably use Protobuf or Avro for strongly governed internal events.

---

# 16. Compatibility rules

The registry enforces compatibility.

Suppose v1:

```json
{
  "orderId": "...",
  "amount": 100
}
```

v2 adds:

```json
{
  "currency": "USD"
}
```

If it's optional/defaulted:

```text
old consumers can still process event
```

Good evolution.

But removing:

```text
orderId
```

would probably be rejected.

---

# 17. Backward compatibility

Example:

```text
Producer v2
   │
   ▼
Consumer v1
```

The new event should remain understandable by the older consumer.

Adding an optional field is usually safe.

```text
v1:
orderId
amount

v2:
orderId
amount
currency(optional)
```

---

# 18. Breaking changes

If semantics fundamentally change, don't keep twisting one schema forever.

Instead introduce:

```text
OrderCreatedV2
```

or a new topic/event contract where appropriate.

For example:

```text
orders.events.v2
```

Then migrate consumers.

Eventually retire v1.

---

# 19. Schema ownership

Every event should have an owner.

Catalog:

```text
Event:
OrderCreated

Owner:
Order Platform

Schema:
v3

Classification:
INTERNAL

Retention:
30 days
```

Consumers should be discoverable too:

```text
Consumers:
Fulfillment
Analytics
Fraud
```

This helps understand blast radius before changing schemas.

---

# 20. Contract testing

In CI:

```text
Producer PR
    │
    ▼
New schema
    │
    ▼
Schema compatibility check
```

If breaking:

```text
CI FAIL
```

before deployment.

Potentially maintain consumer contracts too.

This catches incompatibilities much earlier than production.

---

# 21. Replay

This is one of the main reasons to use a durable log rather than a transient queue.

Suppose analytics deployed a bug yesterday.

Fix deployed today.

We want:

```text
replay yesterday's events
```

Consumer simply resets its offset.

Example:

```text
current offset:
10,000,000

reset to:
8,000,000
```

and processes again.

---

# 22. Replay by timestamp

More convenient API:

```text
Replay:
topic = orders.events
from = 2026-09-20T00:00
to   = 2026-09-20T23:59
```

Platform maps timestamps to offsets.

Could create:

```text
analytics-replay-20260920
```

as a temporary consumer group rather than disturbing the production group's offsets.

That's safer.

---

# 23. Replay isolation

Don't let historical replay overload production systems.

Suppose someone replays:

```text
2 billion events
```

at full speed.

Could crush:

```text
database
downstream APIs
```

So replay service should support:

```text
rate limit
concurrency limit
separate consumer group
separate worker pool
```

Example:

```text
Replay rate:
5,000 events/sec
```

instead of 500K/sec.

---

# 24. Long-term replay

Kafka may retain only:

```text
30 days
```

but business may need:

```text
1 year replay
```

Archive events to object storage:

```text
Kafka
  │
  ▼
Archive Sink
  │
  ▼
Object Storage
```

For example partitioned by:

```text
topic/date/hour
```

Then a replay job can:

```text
Object Storage
       │
       ▼
Replay Producer
       │
       ▼
Replay Topic
```

This is cheaper than retaining everything on brokers indefinitely.

---

# 25. Consumer retries

Suppose event processing fails.

Don't immediately retry indefinitely on the main partition.

Because one poison message can block:

```text
offset 100
```

and prevent:

```text
101
102
103
...
```

from progressing.

Use retry strategy.

---

# 26. Retry topics

For example:

```text
orders.events
     │
     │ failure
     ▼
orders.events.retry.1m
     │
     │ failure
     ▼
orders.events.retry.10m
     │
     │ failure
     ▼
orders.events.dlq
```

This gives exponential/delayed retry behavior.

---

# 27. Poison messages

Examples:

```text
malformed payload
unexpected enum
missing required data
business invariant violation
```

If retrying won't help:

```text
send directly to DLQ
```

rather than retry 100 times.

Failure classification:

```text
TRANSIENT
PERMANENT
```

is useful.

---

# 28. Dead-letter queue

DLQ event should contain:

```text
original event
topic
partition
offset
consumer group
error
attempt count
first failure
last failure
```

Users need tools to:

```text
inspect
fix
reprocess
discard
```

Never make DLQ a black hole.

---

# 29. Bad consumer isolation

This follow-up is straightforward if consumer groups are designed correctly.

Suppose:

```text
Analytics crashes
```

Fulfillment shouldn't care.

```text
orders.events
     │
     ├── fulfillment group → healthy
     │
     ├── notification group → healthy
     │
     └── analytics group → lagging
```

Offsets are independent.

So one consumer group cannot block another group's progress.

---

# 30. Resource isolation

But a bad consumer could still overload brokers with:

```text
aggressive polling
replay traffic
bad fetch sizes
```

So add:

```text
client quotas
bandwidth quotas
connection limits
request-rate limits
```

potentially per:

```text
tenant
team
consumer group
```

---

# 31. Tenant isolation

For critical systems, perhaps:

```text
Shared Event Cluster
  ├── normal business events
  └── low-risk workloads

Dedicated Cluster
  └── high-volume/critical tenant
```

Or at least:

```text
topic quotas
partition quotas
storage quotas
```

A single service publishing millions of unexpected events shouldn't bring down the entire platform.

---

# 32. Backpressure

If consumer processing rate:

```text
1K/sec
```

and producer rate:

```text
10K/sec
```

consumer lag grows:

```text
0
9K
18K
27K...
```

That's okay temporarily because the durable log buffers it.

But the platform needs to alert before:

```text
lag > retention window
```

because then events could expire before consumption.

---

# 33. Consumer lag

One of the most important metrics.

For each partition:

```text
latest_offset - committed_offset
```

Example:

```text
latest = 500,000
consumer = 480,000

lag = 20,000
```

But raw count isn't always enough.

Also calculate:

```text
time lag
```

For example:

```text
consumer is 18 minutes behind.
```

That's easier operationally.

---

# 34. Monitoring

I'd monitor producer side:

```text
publish rate
publish failures
publish latency
event size
schema failures
```

Broker side:

```text
throughput
partition skew
disk usage
replication lag
under-replicated partitions
```

Consumer side:

```text
consumer lag
processing latency
failure rate
retry rate
DLQ depth
rebalance rate
```

---

# 35. SLOs

Example platform SLOs:

```text
99.99% publish availability

p99 publish latency < 100 ms

99.9% of events available to
consumers within 5 seconds
```

Consumer SLOs are owned separately.

Example:

```text
fulfillment:
event processing lag < 30 sec
```

---

# 36. Alerting

Alerts might include:

```text
Consumer lag > 10 min
DLQ count > 0
Producer error rate > 1%
Partition under-replicated
Schema validation failures spike
```

Route alert to the owning team based on service catalog metadata.

---

# 37. Event tracing

Every event carries:

```text
correlation_id
trace_id
```

Suppose:

```text
HTTP request
   │
   ▼
OrderCreated
   │
   ▼
Fulfillment
```

The trace can continue across the asynchronous boundary.

Example:

```text
trace_id=T123

API request
Order service
Kafka publish
Kafka consume
Fulfillment
```

Very helpful for debugging distributed systems.

---

# 38. Security

Topics shouldn't all be globally accessible.

Use:

```text
producer ACL
consumer ACL
```

Example:

```text
order-service:
WRITE orders.events

fulfillment-service:
READ orders.events

random-service:
DENIED
```

Integrate with service identities rather than static passwords when possible.

---

# 39. Sensitive events

Schemas should declare classifications:

```text
PUBLIC
INTERNAL
CONFIDENTIAL
RESTRICTED
```

Potential sensitive fields:

```text
email
account_id
financial data
PII
```

Policies may control:

```text
which consumers
which regions
how long retained
whether archived
```

---

# 40. Encryption

Use:

```text
TLS in transit
encryption at rest
```

Potentially stronger key isolation for restricted topics.

Secrets/auth tokens should not be placed into event payloads.

---

# 41. Topic governance

Without governance, after a few years you get:

```text
order-topic
orders-v2
orders-new
order-events-final
order-events-final2
```

So the platform needs:

```text
naming standards
ownership
schema registration
retention policies
topic lifecycle
documentation
```

Provide a self-service portal:

```text
Create topic
Register schema
Request access
View consumers
View lag
Replay
Inspect DLQ
```

---

# 42. Event catalog

A useful internal catalog:

```text
OrderCreated

Owner:
checkout-platform

Produced by:
order-service

Consumed by:
fulfillment
fraud
analytics

Schema:
v4

RPS:
12K

Retention:
30d
```

This also helps dependency discovery.

---

# 43. Topic retention

Not every topic needs identical retention.

For example:

```text
telemetry events:
3 days

business events:
30 days

financial audit events:
1 year/archive
```

Kafka handles recent replay.

Object storage handles cheap long-term archive.

---

# 44. Compaction

Some topics represent the latest state rather than a full immutable history.

For example:

```text
customer-profile-updated
```

with key:

```text
customer_id
```

A compacted topic can retain the latest value per key.

Conceptually:

```text
C123 v1
C123 v2
C123 v3

compaction →

C123 v3
```

Useful for rebuilding caches/materialized views.

---

# 45. Multi-region

For a global company:

```text
US Cluster
EU Cluster
APAC Cluster
```

Producers publish regionally.

Then replicate required topics:

```text
US ─────► EU
   ◄─────
```

using async replication.

Important to avoid claiming global strong ordering across regions.

---

# 46. Regional ownership

Could assign:

```text
topic home region
```

For example:

```text
customer-eu-events
```

remains within EU for residency reasons.

Cross-region consumers get only allowed replicated events.

---

# 47. Failure scenario: broker node dies

Topics use replication:

```text
Partition P0

Broker A → leader
Broker B → replica
Broker C → replica
```

If A dies:

```text
Broker B becomes leader
```

and producers/consumers continue.

Use appropriate:

```text
replication factor
acks
min in-sync replicas
```

for durability.

---

# 48. Producer acknowledgements

For important business events:

```text
acks = all
```

meaning enough replicas acknowledge before success.

This increases durability at some latency cost.

For critical business events, that's generally worthwhile.

---

# 49. Event immutability

Events should generally be immutable.

If something changes, produce another event:

```text
OrderCreated
OrderUpdated
OrderCancelled
```

Don't mutate historical `OrderCreated`.

This is what makes replay meaningful.

---

# 50. Final architecture

I’d finish with:

```text
                          PRODUCERS
                              │
                    ┌─────────┴─────────┐
                    │ Producer SDK      │
                    │ Outbox / CDC      │
                    └─────────┬─────────┘
                              │
                              ▼
                        Event Gateway
                              │
                  ┌───────────┼───────────┐
                  ▼           ▼           ▼
                Auth       Quotas      Schema
                                       Registry
                              │
                              ▼
                  ┌──────────────────────┐
                  │   Event Bus Cluster  │
                  │ Kafka / Pulsar       │
                  └──────────┬───────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
 Consumer Group A      Consumer Group B      Archive Sink
        │                    │                    │
        ▼                    ▼                    ▼
  Fulfillment           Analytics          Object Storage
        │                    │
        │ failure            │
        ▼                    ▼
   Retry Topics         Independent
        │                Offset/Lag
        ▼
       DLQ


               PLATFORM CONTROL PLANE

        ┌─────────────────────────────┐
        │ Schema Registry             │
        │ Event / Topic Catalog       │
        │ ACL / Identity              │
        │ Replay Service              │
        │ DLQ Management              │
        │ Monitoring / Alerting       │
        └─────────────────────────────┘
```

# How I’d summarize it in the interview

> I would build the event bus on a durable partitioned log. Producers publish immutable events using stable partition keys, giving us ordering within a business entity such as an order or account while allowing different entities to process in parallel. Independent consumer groups maintain their own offsets, which isolates consumers and naturally supports replay. The default processing guarantee is at-least-once, with event IDs and idempotent consumers preventing duplicate business effects. Transactional stream processing can provide exactly-once semantics within the messaging system, but external side effects still require idempotency rather than assuming global exactly-once execution. A schema registry enforces backward-compatible evolution, and breaking contracts are versioned explicitly. Retry topics and DLQs prevent poison events from blocking partitions. Kafka provides short-to-medium-term replay, while object storage provides cheaper long-term history. Consumer lag, retry rate, DLQ depth, broker health, and producer failures are continuously monitored.

The areas I’d expect the interviewer to drill into most are **at-least-once vs exactly-once semantics, partitioning/ordering, transactional outbox, schema evolution, replay, consumer isolation, and retry/DLQ behavior**.

The backbone of the design is:

```text
Durable append-only log
          │
     partitions
          │
          ▼
independent consumer groups
          │
          ▼
offsets + replay + isolation
```

Once that model is clear, most of the follow-up questions become much easier to reason about.
