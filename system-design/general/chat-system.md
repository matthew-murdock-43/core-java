Absolutely. For a **Chat System**, I’d frame the interview around one central challenge:

> How do we reliably deliver ordered messages in real time to users who may have multiple devices, may disconnect at any time, and may belong to very large groups?

A good interview flow is:

1. Clarify requirements
2. Estimate scale
3. Define entities and APIs
4. Design the real-time connection layer
5. Design message persistence and delivery
6. Handle offline users
7. Guarantee ordering
8. Handle large groups
9. Presence, typing, read receipts
10. Notification fanout
11. Reliability and scaling

---

# 1. Requirements

We need:

- One-to-one chat
- Group chat
- Online/offline presence
- Message history
- Read receipts
- Typing indicators
- Push notifications
- Multi-device support

I would initially exclude:

- Voice/video
- End-to-end encryption
- Message search
- Threads/reactions

unless the interviewer asks.

### Non-functional requirements

The key ones are:

- Very low message-delivery latency
- High availability
- Durable messages
- Correct ordering within a conversation
- At-least-once delivery with deduplication
- Horizontal scalability
- Eventual consistency is acceptable for presence/read indicators

The important distinction is:

```text
Message:
    must not be lost

Typing indicator:
    okay to lose
```

That distinction drives a lot of the architecture.

---

# 2. Scale assumptions

Suppose:

```text
500M users
100M DAU

10B messages/day
```

Average:

```text
10B / 86400
≈ 116K messages/sec
```

Peak could easily be:

```text
500K - 1M messages/sec
```

And potentially tens of millions of simultaneously connected WebSocket sessions.

So the system needs both:

```text
high write throughput
+
large number of persistent connections
```

---

# 3. Core data model

## User

```text
User
----
user_id
profile
```

## Conversation

```text
Conversation
------------
conversation_id
type        // DIRECT or GROUP
created_at
```

## ConversationMember

```text
ConversationMember
------------------
conversation_id
user_id
role
joined_at
last_read_sequence
```

## Message

```text
Message
-------
message_id
conversation_id
sender_id
sequence_number
content
created_at
```

The interesting field here is:

```text
sequence_number
```

We'll use it to maintain ordering within a conversation.

---

# 4. APIs

Message history:

```http
GET /conversations/{conversationId}/messages?before=12345&limit=50
```

Send a message:

```http
POST /conversations/{conversationId}/messages

{
  "clientMessageId": "abc-123",
  "text": "Hello"
}
```

The `clientMessageId` is important for idempotency.

If the user's network retries:

```text
send()
timeout
send() again
```

we shouldn't store the same message twice.

---

# 5. Real-time communication

For chat, normal request/response HTTP isn't enough.

I'd use:

```text
WebSocket
```

for connected users.

The client creates a persistent connection:

```text
Mobile/Web Client
       │
       │ WebSocket
       ▼
WebSocket Gateway
```

This connection carries:

- New messages
- Read receipts
- Typing events
- Presence updates

HTTP/REST can still be used for:

- Login
- Conversation lists
- Message history
- Uploading attachments
- Profile operations

---

# 6. High-level architecture

I would draw this first:

```text
                            Clients
                     Web / iOS / Android
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  HTTPS              WebSocket
                    │                   │
                    ▼                   ▼
              API Gateway        WebSocket Gateway
                    │                   │
        ┌───────────┼──────────┐        │
        │           │          │        │
        ▼           ▼          ▼        ▼
   Conversation   Message    Presence   Connection
     Service      Service     Service    Registry
                     │
                     ▼
                  Kafka
                     │
           ┌─────────┴───────────┐
           │                     │
           ▼                     ▼
     Message Delivery      Notification
        Service              Service
           │                     │
           ▼                     ▼
     WebSocket Gateway     APNs / FCM
```

Storage:

```text
Message Service
      │
      ▼
Message Store

Conversation Service
      │
      ▼
Metadata DB

Presence Service
      │
      ▼
Redis
```

---

# 7. Message send flow

Suppose Alice sends Bob:

```text
"Hello"
```

The flow might be:

```text
Alice
  │
  │ message
  ▼
WebSocket Gateway
  │
  ▼
Message Service
  │
  ├── validate conversation membership
  │
  ├── assign message ID
  │
  ├── assign conversation sequence
  │
  └── persist message
  │
  ▼
Kafka
  │
  ▼
Delivery Service
  │
  ▼
Is Bob online?
```

Then:

```text
YES
 │
 ▼
Find Bob's WebSocket connection
 │
 ▼
Push message
```

or:

```text
NO
 │
 ▼
Message remains persisted
 │
 ▼
Send push notification
```

---

# 8. Persist before delivery

I would specifically mention this.

Don't do:

```text
send to Bob
   ↓
save message
```

because:

```text
Bob receives message
server crashes
message never persisted
```

Instead:

```text
persist
   ↓
ack sender
   ↓
deliver
```

So durability comes first.

---

# 9. Message acknowledgements

There are several useful states.

```text
SENT
DELIVERED
READ
```

For example:

```text
Alice sends
   │
   ▼
Server persists
   │
   ▼
SENT

Bob's device receives
   │
   ▼
DELIVERED

Bob opens conversation
   │
   ▼
READ
```

You could represent this UI as:

```text
✓   sent
✓✓  delivered
blue ✓✓ read
```

depending on the product.

---

# 10. Online users

Suppose Bob is online.

Presence/connection infrastructure knows something like:

```text
user_id = Bob

connections:
    gateway-17 / connection-ABC
    gateway-32 / connection-XYZ
```

Why multiple?

Bob might have:

```text
Phone
Laptop
Tablet
```

So the connection registry could live in Redis:

```text
user:123
   → gateway-17:socket-83
   → gateway-22:socket-91
```

Delivery service looks this up and routes the message to the correct gateway.

---

# 11. Offline users

The message is already persisted.

When Bob reconnects:

```text
Bob
 │
 ▼
WebSocket Gateway
 │
 ▼
Sync Service
 │
 │ last_received_sequence = 1050
 │
 ▼
Message Store
 │
 ▼
return messages 1051+
```

So we don't need to keep undelivered messages in memory forever.

The client keeps something like:

```text
last_synced_sequence
```

per conversation or globally.

---

# 12. Push notifications

If Bob isn't connected:

```text
MessageCreated
      │
      ▼
Notification Service
      │
      ├── iOS → APNs
      └── Android → FCM
```

The push notification is only a wake-up mechanism.

I wouldn't put the full authoritative message state into push infrastructure.

When the app wakes:

```text
App
 │
 ▼
Chat backend
 │
 ▼
Fetch missing messages
```

---

# 13. Ordering

This is one of the biggest interview questions.

Imagine:

```text
Alice → "A"
Bob   → "B"
Alice → "C"
```

Different application servers could process them.

Timestamps aren't enough.

Two servers might produce:

```text
10:00:00.001
10:00:00.001
```

and clocks aren't perfectly synchronized.

So we want a monotonically increasing sequence per conversation:

```text
conversation_id = C123

seq=101 "Hello"
seq=102 "How are you?"
seq=103 "Good"
```

Clients sort by:

```text
sequence_number
```

not wall-clock time.

---

# 14. How do we generate sequence numbers?

One approach:

```text
route all messages for the same conversation
to the same logical partition
```

For Kafka:

```text
partition key = conversation_id
```

Kafka then maintains order within that partition.

Conceptually:

```text
Conversation A ──► Partition 1
Conversation B ──► Partition 4
Conversation C ──► Partition 2
```

Messages for conversation A remain ordered.

---

# 15. Conversation ownership

Another model is to have a logical:

```text
Conversation Sequencer
```

For example:

```text
hash(conversation_id)
        │
        ▼
Conversation shard
        │
        ▼
sequence generator
```

Then:

```text
C123
seq 101
seq 102
seq 103
```

The important thing isn't global ordering.

We don't care whether:

```text
Conversation A message
```

occurred before a message in:

```text
Conversation B
```

We only require:

> ordering within one conversation.

That makes the problem much easier to scale.

---

# 16. Why not use a global sequence?

Don't do:

```text
global message sequence
1
2
3
4
...
```

for every message in the entire system.

That creates:

```text
one enormous coordination bottleneck
```

Instead:

```text
sequence per conversation
```

provides the semantics users actually need.

---

# 17. Message storage

Chat history is a very large, append-heavy workload.

Something like Cassandra/DynamoDB can work well.

Example partitioning:

```text
Partition key:
conversation_id + time_bucket

Sort key:
sequence_number
```

For example:

```text
C123#2026-09

10001 | message A
10002 | message B
10003 | message C
```

Why add a time bucket?

Without it:

```text
conversation_id
```

could become one enormous partition for a chat that has existed for ten years.

So:

```text
conversation_id + month
```

or another bucket strategy helps bound partition size.

---

# 18. Pagination

Don't do:

```http
?page=15780
```

with large offset queries.

Use cursor pagination:

```http
GET /messages?before_sequence=10000&limit=50
```

Then:

```text
9951 ... 10000
```

This works naturally with sequence numbers.

---

# 19. Group chats

Small groups are similar to one-to-one chat.

Example:

```text
Message
   │
   ▼
Conversation C123
   │
   ├── User A
   ├── User B
   ├── User C
   └── User D
```

The challenging question is:

> What if the group has 100,000 members?

---

# 20. Fanout

There are two basic approaches.

### Fanout on write

When a message arrives:

```text
message
  │
  ├── user 1 inbox
  ├── user 2 inbox
  ├── user 3 inbox
  ...
  └── user 100,000 inbox
```

Great for reading.

Expensive for writing.

---

### Fanout on read

Store:

```text
ONE message
```

and users fetch it from the conversation stream.

Writes are cheap.

Reads require querying the shared conversation.

---

# 21. Hybrid approach

This is usually a better answer.

For normal groups:

```text
fanout on write
```

For huge groups:

```text
fanout on read
```

For example:

```text
Group < 1000 members
    → push/fanout normally

Group > 1000 members
    → shared conversation stream
```

Exact threshold would be tuned operationally.

---

# 22. Online group delivery

For a 100K-member group, suppose:

```text
20K members are currently online.
```

We don't want the message-producing service synchronously pushing 20K WebSocket writes.

Instead:

```text
Message
   │
   ▼
Kafka
   │
   ▼
Fanout Workers
   │
   ├── Gateway A
   ├── Gateway B
   ├── Gateway C
   └── Gateway D
```

Workers group recipients by WebSocket gateway.

Instead of:

```text
20,000 individual backend routes
```

you can do:

```text
Gateway A → deliver to its 4,500 connected users
Gateway B → deliver to its 5,000
...
```

---

# 23. Presence

Presence should not live in the primary relational database.

Presence changes frequently:

```text
online
offline
online
offline
```

Use an ephemeral store such as Redis.

For example:

```text
presence:user123

status = ONLINE
last_seen = ...
gateway = gateway-12
```

With TTL:

```text
heartbeat every 20 sec
TTL = 60 sec
```

If the server stops receiving heartbeats:

```text
ONLINE
  ↓
OFFLINE
```

automatically.

---

# 24. Presence is eventually consistent

This is important.

Suppose:

```text
Bob disconnects at 10:00:00
```

and Alice sees Bob online until:

```text
10:00:20
```

That's usually acceptable.

So we don't need expensive distributed transactions around presence.

---

# 25. Last seen

When a user's final connection disappears:

```text
last_seen = timestamp
```

We can persist that separately.

So:

```text
Presence:
fast ephemeral state

Last seen:
durable profile state
```

---

# 26. Typing indicators

Typing indicators should be lightweight and ephemeral.

Alice types:

```text
typing_started
```

Client sends:

```text
{
  conversationId: C123,
  userId: Alice,
  typing: true
}
```

Server routes it to the other participants.

Don't write this into the message database.

There is no reason to persist:

```text
Alice was typing at 10:03:47
```

---

# 27. Typing expiration

What if Alice closes the app without sending:

```text
typing=false
```

?

Use TTL.

For example:

```text
typing=true
expires in 5 seconds
```

Client periodically refreshes it while typing.

If updates stop:

```text
typing indicator disappears automatically.
```

---

# 28. Read receipts

A naive implementation could store:

```text
User read message 1
User read message 2
User read message 3
...
```

That's unnecessarily expensive.

Instead store a high-watermark:

```text
user_id
conversation_id
last_read_sequence
```

For example:

```text
Bob:
conversation C123
last_read_sequence = 500
```

That implies:

```text
messages <= 500 are read
```

One tiny state update represents hundreds of messages.

---

# 29. Group read receipts

For small groups, we can show:

```text
Read by Alice
Read by Bob
Read by Charlie
```

But imagine:

```text
100,000-person group
```

Tracking/displaying every receipt per message becomes expensive.

For large groups, use reduced semantics such as:

```text
read_count = 48,392
```

or don't expose individual read receipts at all.

That's a product/scale tradeoff I'd explicitly mention.

---

# 30. Delivered receipts

Same high-watermark idea can apply.

For example:

```text
last_delivered_sequence = 510
last_read_sequence      = 500
```

Then:

```text
<=500 READ
501-510 DELIVERED
>510 NOT DELIVERED
```

Very compact.

---

# 31. Notification fanout

The follow-up asks:

> How do you handle notification fanout?

I would separate:

```text
real-time message delivery
```

from:

```text
mobile push notifications
```

Flow:

```text
MessageCreated
      │
      ▼
Kafka
      │
      ▼
Notification Fanout Service
      │
      ▼
Determine recipients
      │
      ├── online + active conversation
      │       → don't notify
      │
      └── offline/background
              │
              ▼
         notification queue
              │
              ▼
            APNs/FCM
```

---

# 32. Why use a queue for notifications?

Don't make:

```text
send message
```

wait for APNs.

APNs could be slow/unavailable.

Instead:

```text
Message persisted
      │
      ▼
MessageCreated event
      │
      ▼
Notification queue
```

Workers retry independently.

Chat delivery should continue even if push notification infrastructure is having trouble.

---

# 33. Notification storm control

Imagine a group has:

```text
50,000 users
```

and people send:

```text
100 messages in 10 seconds
```

You don't want:

```text
5 million push notifications.
```

Use batching/coalescing.

Instead of:

```text
Alice: hello
Bob: hi
Charlie: hey
Dave: hello
```

send:

```text
"12 new messages in Engineering Chat"
```

Also respect:

- Muted chats
- Mention-only settings
- Do-not-disturb
- Notification preferences

---

# 34. Multi-device behavior

Suppose Alice has:

```text
iPhone
Laptop
Tablet
```

A message should reach all connected devices.

```text
Alice
 │
 ├── device 1 connection
 ├── device 2 connection
 └── device 3 connection
```

But read state usually belongs to:

```text
user + conversation
```

rather than an individual device.

So if Alice reads on her phone:

```text
last_read_seq = 500
```

the laptop should synchronize that state.

---

# 35. At-least-once delivery

Exactly-once message delivery across distributed systems is very expensive and often unnecessary.

I would use:

```text
at-least-once delivery
+
idempotency
```

Suppose Bob receives:

```text
message_id = M123
```

twice.

The client stores IDs and simply ignores duplicate `M123`.

Likewise, sending:

```text
client_message_id = abc
```

twice should result in one stored message.

---

# 36. Retry example

Alice sends:

```text
M1
```

Server stores it.

Response to Alice gets lost.

Alice retries.

Without idempotency:

```text
Hello
Hello
```

With:

```text
(sender_id, client_message_id)
```

uniquely identifying a client operation:

```text
retry
    ↓
existing message returned
```

No duplicate.

---

# 37. Kafka role

Kafka is useful for internal asynchronous processing.

For example:

```text
MessageCreated
     │
     ├── Delivery Service
     ├── Notification Service
     ├── Analytics
     ├── Moderation
     └── Search indexing
```

And using:

```text
conversation_id
```

as the partition key helps preserve ordering.

---

# 38. Database partitioning

Message DB:

```text
partition by:
hash(conversation_id)
```

potentially combined with a time bucket.

Conversation membership:

```text
conversation_id
```

User conversation list:

```text
user_id
```

Notice that we may maintain denormalized views because we have two important queries:

```text
Who is in conversation C?
```

and:

```text
What conversations belong to user U?
```

At scale, trying to serve both from one relational join can become expensive.

---

# 39. Conversation inbox

For the UI:

```text
Chats

Alice               "Hey..."          2
Engineering          "Build passed"   19
Family               "Photo..."        3
```

we might maintain a per-user conversation summary:

```text
UserConversation
----------------
user_id
conversation_id
last_message
last_message_time
unread_count
```

This is essentially a materialized view optimized for:

```text
GET /users/{id}/conversations
```

---

# 40. Handling failures

Suppose:

```text
Message DB succeeds
Kafka publishing fails
```

We don't want the message permanently stored but never delivered.

Use transactional outbox:

```text
BEGIN

INSERT message
INSERT outbox_event

COMMIT
```

Then:

```text
Outbox Publisher
      │
      ▼
Kafka
```

If Kafka is unavailable:

```text
outbox remains
```

and gets retried.

---

# 41. WebSocket gateway failure

Suppose:

```text
Gateway 17 crashes
```

and has 100K connected users.

Those clients detect the broken connection and reconnect through the load balancer:

```text
Gateway 17 ✕
      │
      ▼
Gateway 42
```

Then synchronize:

```text
last_received_seq = 530

server sends:
531+
```

This is why the WebSocket layer shouldn't be the durable source of truth.

---

# 42. Backpressure

What if a user has a very slow network and we're producing messages faster than their device can consume them?

Don't keep an unlimited in-memory queue.

Have limits:

```text
Socket send buffer
     │
     │ too large
     ▼
disconnect slow client
```

On reconnect:

```text
fetch missed messages from durable history.
```

Durable storage becomes the safety net.

---

# 43. Attachments

For images/videos:

Don't push the binary through the message service.

Instead:

```text
Client
  │
  │ upload
  ▼
Object Storage
  │
  ▼
CDN
```

Then message:

```json
{
  "type": "IMAGE",
  "mediaId": "M123"
}
```

Architecture:

```text
Client → pre-signed upload → S3/Object Storage
                              │
                              ▼
                             CDN
```

---

# 44. Security

Messages and connections should use:

```text
TLS
```

WebSocket connection authenticated via token/session.

Every message send must verify:

```text
sender belongs to conversation
```

For group membership changes:

```text
joined_at
left_at
```

matter for history permissions.

For example, a new member may or may not be allowed to see old messages depending on product semantics.

---

# 45. Final architecture

The final diagram I'd draw would look like this:

```text
                              USERS
                                │
                  ┌─────────────┴──────────────┐
                  │                            │
                HTTPS                      WebSocket
                  │                            │
                  ▼                            ▼
            API Gateway               WebSocket Gateway
                                              │
                                              ▼
                                      Connection Registry
                                            Redis
                                              │
         ┌────────────────────────────────────┼─────────────────────┐
         │                                    │                     │
         ▼                                    ▼                     ▼
 Conversation Service                   Message Service       Presence Service
         │                                    │                     │
         ▼                                    ▼                     ▼
 Metadata DB                           Message Store               Redis
                                              │
                                              ▼
                                           Kafka
                                              │
                ┌─────────────────────────────┼────────────────────────┐
                │                             │                        │
                ▼                             ▼                        ▼
        Delivery Service             Notification Service         Analytics
                │                             │
                ▼                             ▼
        WebSocket Gateway              APNs / FCM
                │
                ▼
             Clients
```

For attachments:

```text
Client
   │
   ▼
Object Storage
   │
   ▼
CDN
```

---

# How I'd summarize it to the interviewer

> I would maintain persistent WebSocket connections for real-time communication while using durable message storage as the source of truth. Messages are persisted before acknowledgement and asynchronously distributed through a message bus. Ordering is guaranteed per conversation using a conversation sequence number and partitioning all messages for a conversation onto the same logical ordering path. Online users receive messages immediately through their WebSocket gateway, while offline users recover messages from durable history and receive push notifications through APNs or FCM. Presence and typing indicators are ephemeral and can live in Redis with TTLs, while read receipts can be efficiently represented using a per-user `last_read_sequence`. For very large groups, I would avoid eagerly duplicating every message for every member and use a hybrid fanout-on-write/fanout-on-read model.

The **four areas I'd expect the interviewer to drill into** are:

```text
1. Ordering
2. Online/offline delivery
3. Large-group fanout
4. Presence/read receipts
```

Those are where I would spend most of the interview time.
