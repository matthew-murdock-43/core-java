# System Design Interview: Design a Real-Time Live Viewer Counter for 100 Million Users

Level: Senior Software Engineer / Staff Engineer | Difficulty: Hard | Interview duration: 45–60 minutes

Imagine you're interviewing at Netflix, YouTube, or Twitch, and the interviewer asks:

> Design a system that displays the number of people currently watching a live stream. The system must support 100 million concurrent viewers globally, with the counter updating in near real time.

I would approach this as a system design interview, rather than jumping directly into Redis, Kafka, or HyperLogLog.

The interviewer is primarily evaluating whether you can clarify ambiguous requirements, estimate scale, choose appropriate data structures, identify bottlenecks, and explain trade-offs.

## 1. Requirement gathering (5 minutes)

Before designing anything, I'd ask the interviewer a few questions.

| Question                                | Assumption for our design                                  |
| --------------------------------------- | ---------------------------------------------------------- |
| What does "active viewer" mean?         | Unique user who watched within the last 60 seconds         |
| Is the count per stream or global?      | Per stream, including a global aggregate if needed         |
| Do we need exact counts?                | Approximate, within ±1% under normal conditions            |
| How frequently should the count update? | Every 2 seconds                                            |
| What's the expected scale?              | 100M concurrent viewers globally                           |
| Can a user watch on multiple devices?   | Count once per stream                                      |
| Is the system globally distributed?     | Yes, multiple regions                                      |
| What happens during failures?           | Display the last reliable count with a freshness indicator |

I'd also clarify whether 100 million means viewers across the entire platform or on a single live stream. The latter introduces a much more severe hot-key and fan-out problem.

### Functional requirements

1. Register viewer activity through periodic heartbeats.
2. Count distinct active viewers per live stream.
3. Automatically exclude inactive viewers.
4. Return and broadcast the latest viewer count.
5. Support viewers connecting from different geographical regions.

### Non-functional requirements

- Scale to 100 million concurrent viewers.
- Publish a refreshed count every 2 seconds.
- Target ±1% counting error during healthy operation.
- Avoid a single point of failure.
- Support regional failures and traffic spikes.
- Keep ingestion latency low and operating costs reasonable.

One important distinction: A 2-second refresh interval does not imply that the count is accurate to within 2 seconds. With a 60-second activity window, a disconnected user may remain counted for nearly a minute.

That distinction is worth explaining to the interviewer.

## 2. Back-of-the-envelope estimation (5 minutes)

Let's assume:

<img width="754" height="484" alt="image" src="https://github.com/user-attachments/assets/551cd30c-ec97-4208-a5ba-1665ed311998" />

At our baseline assumptions, we need to handle approximately 3.33 million heartbeat requests per second and 50 million counter deliveries per second.

These numbers immediately reveal two independent scaling challenges: ingestion and broadcast fan-out.

We should design those paths separately.

## 3. Start with a simple design (5 minutes)

In an interview, I'd first propose the simplest possible solution.

<img width="756" height="372" alt="image" src="https://github.com/user-attachments/assets/16e1e819-90bf-40ed-a076-88e184ca49a4" />

Each heartbeat updates the user's last-seen timestamp. A background process counts users whose last heartbeat is within the activity window.

For example, Redis sorted sets could store user IDs scored by last-seen timestamp.

Why won't this scale?

A single popular stream creates a hot key. Maintaining and counting millions of exact identities becomes expensive. Expiring users, memory management, and concurrent updates also complicate the design.

I'd explain these limitations before introducing a more distributed architecture.

## 4. High-level design (10 minutes)

My next step would be to separate the system into three paths: ingestion, counting, and distribution.

<img width="603" height="728" alt="image" src="https://github.com/user-attachments/assets/b1a2e13c-cca7-453e-a571-dd6014bdfecc" />

This is a possible architecture, not the only valid one. In particular, Kafka and stateful stream processing are justified when we need durable ingestion, replay, and recovery. A simpler Redis-based design could also meet the requirements.

## 5. Deep dive: How do we count distinct active viewers? (10 minutes)

This is the most important part of the interview.

There are three main options.

| Approach                | Accuracy                      | Memory            | Main trade-off                     |
| ----------------------- | ----------------------------- | ----------------- | ---------------------------------- |
| Redis Set / exact state | Exact                         | High              | Expensive for 100M users           |
| Bitmap                  | Exact with stable integer IDs | Low for dense IDs | Requires an appropriate ID mapping |
| HyperLogLog             | Approximate                   | Very low          | Cannot delete individual users     |

For an approximate viewer counter, I would initially choose HyperLogLog with time buckets.

### How the sliding window works

Assume:

- Heartbeats every 30 seconds.
- Active-user window of 90 seconds.
- Each bucket represents 10 seconds.
- A new count is calculated every 2 seconds.

<img width="747" height="221" alt="image" src="https://github.com/user-attachments/assets/5cac1def-aca4-4ffa-b3d1-e61106bcd10a" />

For each heartbeat:

```
streamId = 123
userId   = 456
bucket   = floor(timestamp / 10)
shard    = hash(userId) % 1000

PFADD stream:{123:shard}:bucket userId
```

The actual Redis key must ensure that the bucket keys being merged are colocated in the same Redis Cluster hash slot.

Every 2 seconds, an aggregator calculates the distinct count over the recent buckets. With 10-second buckets, this is an approximate time window with up to one bucket of boundary imprecision. We can use smaller buckets if that matters.

Because each user maps to exactly one shard, we can sum the distinct estimates across shards without double-counting users across those shards.

### Interviewer follow-up: Why not use `INCR`?

Because the same user sends multiple heartbeats. `INCR` counts events, not distinct users.

### Interviewer follow-up: Why not use Redis Sets?

We can, but maintaining exact membership and expiry for 100 million users requires substantially more memory and state management. Exact sets are worth considering when accuracy is a hard requirement.

### Interviewer follow-up: Why not maintain one HLL?

Because HLL cannot remove individual identities. If a user disconnects, their contribution remains. Time buckets allow old activity to expire.

## 6. Deep dive: How do we avoid hot keys?

For a single extremely popular stream, writing all heartbeats into one Redis key would create contention.

We can distribute the traffic across 1,000 logical shards.

```
int shardId = Math.floorMod(userId.hashCode(), 1000);
```

Each logical shard maintains its own time-bucket HLLs.

At 3.33M heartbeats/second:

<img width="161" height="70" alt="image" src="https://github.com/user-attachments/assets/31e58dc8-5abe-4c29-9152-8a3d9c258e51" />

That's approximately 3,330 updates per logical shard per second on average.

But I'd immediately tell the interviewer that 1,000 logical shards do not mean 1,000 physical Redis nodes. We need to size the physical cluster based on benchmarked CPU, memory, network, and failover capacity.

Also, logical shards must have stable ownership. If shard assignment changes during rescaling, the same user could temporarily appear in two shards, causing overcounting. I'd use a stable logical-shard count and separately map those shards to physical nodes.

## 7. Deep dive: How do we broadcast to 100M viewers? (5 minutes)

This is a separate scaling problem.

We shouldn't make every viewer poll Redis or the counting service.

Instead:

1. The aggregator publishes a count snapshot.
2. Regional fan-out gateways subscribe to those snapshots.
3. Each gateway broadcasts the latest count to its connected clients.
4. Slow clients can skip intermediate updates and receive only the newest count.

For the interview, I'd compare WebSockets and Server-Sent Events.

| WebSockets                                     | SSE                                               |
| ---------------------------------------------- | ------------------------------------------------- |
| Bidirectional                                  | Server-to-client                                  |
| Useful for chat and other interactive features | Well suited for a counter-only stream             |
| Requires persistent connection management      | Also requires persistent connection management    |
| Can reuse existing WebSocket infrastructure    | Simpler application semantics for one-way updates |

If the video platform already has a persistent control connection, I'd strongly consider reusing it.

I'd also introduce jitter so all gateways don't flush to clients at exactly the same instant.

## 8. Failure handling and trade-offs (5 minutes)

A strong interview answer should cover failure behavior, not just the happy path.

| Failure                   | Expected behavior                                          |
| ------------------------- | ---------------------------------------------------------- |
| Redis shard unavailable   | Use a last-known-good partial count, mark snapshot stale   |
| Kafka backlog increases   | Publish older counts with a freshness timestamp            |
| Aggregator crashes        | Standby takes over using leader election/fencing           |
| WebSocket gateway crashes | Clients reconnect with exponential backoff and jitter      |
| Regional outage           | Surviving regions continue; global count may be incomplete |
| Traffic spikes            | Autoscale ingestion and use admission control/backpressure |

I would track metrics such as heartbeat ingestion rate, processing lag, aggregation duration, missing shards, counter freshness, HLL estimate stability, and gateway connection count.

For correctness, I'd also periodically compare the approximate count against an independently computed exact count on a manageable sample.

## 9. The interviewer's hardest follow-up questions

What happens if the same user watches from two devices?

Use the same canonical user ID for both devices and deterministic shard assignment. HLL deduplicates that user within the merged activity window. If anonymous users are supported, define an identity strategy explicitly.

What happens when a user closes the browser?

What happens if heartbeats arrive out of order?

Can the counter decrease?

How would you support multiple streams?

What if the interviewer demands exact counts?

## 10. How I would conclude the interview

I'd summarize the architecture like this:

> We designed a globally distributed live viewer counter supporting 100 million concurrent viewers. We separated ingestion, aggregation, and fan-out to scale each independently. We use deterministic user sharding to avoid hot keys, time-bucketed HyperLogLog for approximate distinct counting, and regional gateways to distribute count snapshots. The system prioritizes availability and bounded staleness over strict consistency, with explicit handling for partial failures.

Then I'd proactively mention two remaining trade-offs: HLL's approximate nature and the cost of maintaining a global count across regions.

## My evaluation of the original article as an interview answer

The article covers several of the right ideas, including sharding, HLL, sliding windows, and WebSocket fan-out.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://medium.com\&sz=32)

Medium



However, as an interviewer, I'd expect a candidate to justify the data structures, explain the accuracy model, distinguish logical shards from physical nodes, and reason about Redis Cluster restrictions and failure scenarios.

Architecture fundamentals

Strong

Scalability reasoning

Good

Correctness and trade-offs

Needs depth

Failure handling

Needs depth

Qualitative interview assessment, not measured performance scores.

The most valuable next step is to practice this interactively. I'll act as the interviewer, challenge your assumptions, and introduce constraints as you progress.

Interview question 1

You've proposed using HyperLogLog with a sliding window. Suppose a user sends a heartbeat at 12:00:00 and disconnects immediately afterward. Another user sends heartbeats continuously every 30 seconds.

How does your system distinguish between these two users, and when will the disconnected user stop being counted?

Start mock interview&#x20;
