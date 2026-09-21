For this one, I’d treat it as a **YouTube-like video platform** and structure the interview around four major subsystems:

1. **Upload and processing**
2. **Video delivery**
3. **Metadata/search/recommendations**
4. **Analytics such as view counting**

The hardest parts are usually **transcoding at scale**, **global delivery**, and **accurate event processing**.

# 1. Clarify requirements

Users should be able to:

- Upload videos
- Edit title, description, tags
- Search videos
- Stream videos
- Like/comment
- Subscribe to creators
- See recommendations
- Resume playback
- View counts

Creators should be able to:

- Upload large videos
- See processing status
- Publish/unpublish videos
- See analytics

I’d initially exclude live streaming unless the interviewer asks, because live video has a different ingestion pipeline.

---

# 2. Non-functional requirements

Important requirements:

- Very high read throughput
- Large storage requirements
- Globally low playback latency
- Extremely high bandwidth
- Highly durable video storage
- Uploads should be resumable
- Video processing should be asynchronous
- Search can be eventually consistent
- View counts can be eventually consistent
- Video metadata needs stronger consistency

A key observation:

```text
Video streaming traffic >> metadata/API traffic
```

So the architecture should keep actual video bytes away from normal application servers.

---

# 3. Scale assumptions

For example:

```text
1B users
200M DAU

500 hours uploaded/minute

Millions of videos
Millions of concurrent viewers
```

Suppose an average stream is:

```text
5 Mbps
```

and we have:

```text
5M concurrent viewers
```

Bandwidth would be roughly:

```text
25 Tbps
```

So serving videos directly from one data center is impossible.

A CDN is fundamental to the design.

---

# 4. Core entities

## Video

```text
Video
-----
video_id
owner_id
title
description
status
visibility
duration
created_at
published_at
```

Status:

```text
UPLOADING
PROCESSING
READY
FAILED
```

## VideoAsset

Represents a processed rendition:

```text
VideoAsset
----------
asset_id
video_id
resolution
bitrate
codec
format
storage_path
```

For example:

```text
1080p / 8 Mbps / H.264
720p  / 4 Mbps / H.264
480p  / 2 Mbps / H.264
360p  / 800 Kbps / H.264
```

## Channel/User

```text
User
----
user_id
channel_name
```

## Playback event

```text
PlaybackEvent
-------------
event_id
video_id
user_id/device_id
session_id
event_type
position
timestamp
```

---

# 5. APIs

Create upload:

```http
POST /videos/uploads
```

Response:

```json
{
  "videoId": "V123",
  "uploadId": "U123",
  "uploadUrl": "..."
}
```

Get video metadata:

```http
GET /videos/{videoId}
```

Search:

```http
GET /search?q=system+design
```

Playback:

```http
GET /videos/{videoId}/playback
```

Response could contain:

```json
{
  "manifestUrl": ".../master.m3u8"
}
```

---

# 6. High-level architecture

I’d draw this:

```text
                         Clients
                 Web / Mobile / Smart TV
                           |
                     API Gateway
                           |
       +-------------------+----------------------+
       |                   |                      |
       v                   v                      v
 Video Metadata        Search Service       Recommendation
    Service                                      Service
       |                   |                      |
       v                   v                      v
 Metadata DB          Search Index           Feature Store


                     UPLOAD PATH

Client
  |
  v
Upload Service
  |
  | signed upload URL
  v
Object Storage
  |
  v
Processing Queue
  |
  v
Transcoding Workers
  |
  +--> 1080p
  +--> 720p
  +--> 480p
  +--> 360p
  |
  v
Processed Video Storage
  |
  v
CDN


                     PLAYBACK PATH

Client
  |
  v
Playback API
  |
  v
Manifest URL
  |
  v
CDN
  |
  v
Video Segments
```

---

# 7. Upload flow

Suppose a creator uploads a 20 GB video.

I would not do:

```text
Client -> Application server -> Storage
```

because the application tier would become a bandwidth bottleneck.

Instead:

```text
Client
   |
   | request upload
   v
Upload Service
   |
   | presigned URL
   v
Client ------------------> Object Storage
```

The backend authorizes the upload, but the file goes directly to object storage.

---

# 8. Large and resumable uploads

For large files, use multipart uploads.

Example:

```text
20 GB video

part 1
part 2
part 3
...
part N
```

Maybe:

```text
8 MB - 64 MB per part
```

depending on storage technology.

If upload fails at 80%:

```text
resume missing parts
```

rather than reuploading the entire file.

Maintain:

```text
UploadSession
-------------
upload_id
video_id
user_id
parts_uploaded
expires_at
status
```

---

# 9. Upload completion

After upload completes:

```text
Object Storage
      |
      v
UploadCompleted event
      |
      v
Processing Queue
```

Then:

```text
Video status:
UPLOADING -> PROCESSING
```

Transcoding should be completely asynchronous.

The user doesn't wait on an HTTP request while encoding occurs.

---

# 10. Transcoding

Users upload all kinds of files:

```text
4K
1080p
MOV
MP4
HEVC
H.264
AV1
different frame rates
different audio codecs
```

We need standardized outputs.

Transcoding workers generate multiple renditions.

Example input:

```text
4K source
```

Output:

```text
2160p 15 Mbps
1440p 9 Mbps
1080p 6 Mbps
720p  3 Mbps
480p  1.5 Mbps
360p  700 Kbps
```

---

# 11. Transcoding pipeline

I’d model this as a job DAG.

```text
Uploaded Video
      |
      v
Metadata Extraction
      |
      +--> Thumbnail generation
      |
      +--> Audio extraction
      |
      +--> Content moderation
      |
      v
Transcoding
      |
      +--> 1080p
      +--> 720p
      +--> 480p
      +--> 360p
      |
      v
Packaging
      |
      v
Publish
```

The jobs can run in parallel.

---

# 12. Transcoding workers

Use a queue.

```text
Processing Queue
      |
      +--> worker
      +--> worker
      +--> worker
      +--> worker
```

Workers can be autoscaled depending on queue depth.

Potentially separate queues:

```text
high priority
normal
long videos
short videos
4K
```

so one huge file doesn't block everything else.

---

# 13. Failure handling

Transcoding jobs should be idempotent.

If:

```text
720p job crashes
```

we retry only:

```text
720p
```

rather than restarting every rendition.

Each asset has status:

```text
PENDING
PROCESSING
READY
FAILED
```

Once required outputs exist:

```text
Video -> READY
```

---

# 14. Multiple bitrates

Now the next follow-up:

> How do you support multiple bitrates and devices?

Use **Adaptive Bitrate Streaming**.

Typical protocols:

```text
HLS
MPEG-DASH
```

Instead of sending one large MP4, split video into small segments.

Example:

```text
1080p
  seg1
  seg2
  seg3

720p
  seg1
  seg2
  seg3

480p
  seg1
  seg2
  seg3
```

Each segment may represent something like:

```text
2-6 seconds
```

of video.

---

# 15. Manifest

Create a master manifest.

Conceptually:

```text
master.m3u8

1080p -> playlist
720p  -> playlist
480p  -> playlist
360p  -> playlist
```

Client downloads it and dynamically chooses bitrate.

---

# 16. Adaptive bitrate example

User starts on Wi-Fi:

```text
10 Mbps connection
      |
      v
1080p
```

Network drops:

```text
3 Mbps
      |
      v
720p
```

Then:

```text
1 Mbps
      |
      v
360p
```

The player switches between segments without restarting the video.

This minimizes buffering.

---

# 17. Device formats

Different devices may support different codecs.

For example:

```text
H.264
HEVC
VP9
AV1
```

We don't necessarily generate every codec for every video.

Could use a strategy based on:

- Popularity
- Source quality
- Device distribution
- Encoding cost

For a very popular video:

```text
H.264 + AV1
```

might make sense.

For a rarely watched video:

```text
only H.264
```

could be enough.

---

# 18. Why AV1 can be useful

AV1 can reduce bandwidth at similar quality compared with older codecs, but encoding is expensive.

So there's a tradeoff:

```text
more CPU during encoding
vs
less CDN bandwidth later
```

For highly popular videos, the bandwidth savings may outweigh encoding cost.

---

# 19. Global video delivery

This is the biggest infrastructure piece.

We don't want:

```text
Viewer in Singapore
      |
      v
Origin in Virginia
```

for every segment.

Use a CDN:

```text
                   Origin Storage
                         |
                +--------+--------+
                |        |        |
                v        v        v
             CDN US   CDN EU   CDN Asia
                |        |        |
                v        v        v
              Users    Users    Users
```

Viewers fetch from nearby edge servers.

---

# 20. CDN caching

When the first viewer requests:

```text
segment123.ts
```

the CDN may miss:

```text
CDN -> Origin
```

Then caches it.

Future viewers:

```text
Viewer -> CDN edge
```

No origin request required.

This drastically reduces:

- Origin bandwidth
- latency
- storage load

---

# 21. Popular vs unpopular content

Popular videos naturally have a high CDN cache hit rate.

For example:

```text
viral video
```

might be cached across hundreds of edges.

Old/unpopular video:

```text
cache miss
```

may be served from origin.

We could prewarm CDN caches for expected high-demand content.

---

# 22. Origin storage

Processed videos should live in highly durable object storage.

Potential logical layout:

```text
videos/
  V123/
    source/
    1080p/
    720p/
    480p/
    manifests/
    thumbnails/
```

But storage keys should really use opaque IDs rather than user filenames.

---

# 23. Multi-region storage

For very large global systems:

```text
Primary origin
     |
     +--> replica US
     +--> replica Europe
     +--> replica Asia
```

Then regional CDN edges fetch from the closest origin.

This reduces long-haul traffic.

---

# 24. Playback path

The actual streaming request should look like:

```text
Client
  |
  v
Playback Service
  |
  | authorization / geo / age / entitlement
  v
Manifest URL
  |
  v
CDN
  |
  v
Segments
```

The application server is only involved in authorizing playback, not transmitting every video byte.

---

# 25. View counting

Now the interesting question:

> How do you accurately track views without overcounting?

A naive implementation:

```text
GET /video
UPDATE view_count = view_count + 1
```

is bad.

Problems:

- refresh spam
- bots
- retries
- users watching 1 second
- database hotspot for viral videos

Instead track playback events asynchronously.

---

# 26. Playback event stream

Client sends events:

```text
PLAY
HEARTBEAT
PAUSE
SEEK
COMPLETE
```

Example:

```json
{
  "videoId": "V123",
  "sessionId": "S456",
  "userId": "U789",
  "position": 32,
  "event": "HEARTBEAT"
}
```

Events go to:

```text
Client
   |
   v
Event Collector
   |
   v
Kafka
```

---

# 27. Define what counts as a view

This is a product decision.

For example:

```text
A view counts when:
user watches >= 30 seconds
```

or:

```text
>= X% for short videos
```

The architecture should support whatever rule product chooses.

Important point:

```text
page load != view
```

---

# 28. Deduplicate views

We can create a logical key:

```text
video_id
viewer_id/device_id
session_id
time_window
```

Then the aggregation processor determines whether the session qualifies.

For logged-in user:

```text
user_id
```

For anonymous user:

```text
device/session cookie
```

perhaps combined with anti-abuse signals.

---

# 29. Don't synchronously update the counter

For a viral video:

```text
10M viewers
```

doing:

```sql
UPDATE video
SET views = views + 1;
```

10 million times against one row creates a hotspot.

Instead:

```text
Playback events
      |
      v
Kafka
      |
      v
Stream processor
      |
      v
Aggregated counts
```

Maybe workers compute:

```text
V123 +1256 views
```

and periodically flush deltas.

---

# 30. View count pipeline

```text
Players
   |
   v
Event Collector
   |
   v
Kafka
   |
   v
Dedup / Fraud Detection
   |
   v
View Aggregator
   |
   v
Counter Store
```

Then:

```text
Metadata Service
```

reads the precomputed count.

A small delay is acceptable.

---

# 31. Exactly-once vs effectively-once

Kafka consumers can retry.

So the same event might arrive twice.

Use:

```text
event_id
```

or session-based idempotency.

We generally aim for:

```text
at-least-once event delivery
+
deduplication
=
effectively-once view counting
```

rather than requiring an expensive global exactly-once system.

---

# 32. Search

Search metadata such as:

```text
title
description
tags
creator
captions
category
```

can be indexed in OpenSearch/Elasticsearch.

Pipeline:

```text
Metadata DB
    |
    | VideoPublished / Updated
    v
Kafka
    |
    v
Search Indexer
    |
    v
Search Engine
```

Search is eventually consistent.

That's fine if a new title takes a few seconds to appear.

---

# 33. Search ranking

Candidate retrieval can use:

```text
text relevance
title match
description match
captions
tags
```

Then rank using signals such as:

- Watch time
- Click-through rate
- Engagement
- Freshness
- Channel relevance
- Quality
- Language/location

Conceptually:

```text
Query
  |
  v
Retrieve 1000 candidates
  |
  v
Ranking model
  |
  v
Top 20 results
```

---

# 34. Recommendations

Recommendations are different from search because the user didn't provide a query.

Signals:

```text
Watch history
Likes
Subscriptions
Watch duration
Skips
Similar users
Video similarity
Language
Freshness
```

Architecture:

```text
Playback Events
      |
      v
Kafka
      |
      v
Feature Pipeline
      |
      v
Feature Store
      |
      +------------------+
      |                  |
      v                  v
Candidate Generation   Ranking Model
      |                  |
      +---------> Recommendations
```

---

# 35. Candidate generation

You don't rank every video in the system.

First reduce billions of videos to a few hundred/thousand candidates.

Sources could include:

```text
Subscribed channels
Similar videos
Trending videos
Collaborative filtering
Recently popular
Topic/category matches
```

Then ML ranking scores those candidates.

---

# 36. Watch history

Maintain:

```text
user_id
video_id
last_position
watch_time
updated_at
```

This enables:

```text
Continue watching
```

For playback position updates, don't synchronously write every second.

Send heartbeats periodically and batch updates.

---

# 37. Thumbnails

During processing:

```text
video
  |
  v
Thumbnail Generator
```

extract frames.

Store thumbnails in object storage and distribute through CDN.

They may actually generate significant traffic because users load many thumbnails while browsing.

---

# 38. Content moderation

An upload pipeline would likely include:

```text
virus scanning
copyright detection
nudity/violence detection
policy moderation
```

Architecturally these are asynchronous workers:

```text
UploadCompleted
     |
     +--> transcoding
     +--> moderation
     +--> copyright scan
```

Only publish when required checks succeed.

---

# 39. Metadata consistency

Video metadata could live in a relational or distributed key-value database.

Access patterns:

```text
get video by video_id
list creator videos
update title
change privacy
```

At large scale, shard by:

```text
video_id
```

or creator/namespace depending on query patterns.

---

# 40. Video ID generation

Generate globally unique IDs without central database contention.

Options:

```text
UUID
Snowflake-style IDs
random URL-safe IDs
```

YouTube-like opaque IDs are useful because they don't expose sequential internal identifiers.

---

# 41. Likes/comments

These can be separate services:

```text
Like Service
Comment Service
Subscription Service
```

They don't need to be in the core upload/streaming critical path.

Events can later feed:

```text
recommendation features
analytics
ranking
```

---

# 42. Hot videos

A newly viral video could receive millions of requests.

The CDN absorbs most of that.

Metadata itself could also become hot:

```text
GET /videos/V123
```

So cache video metadata in:

```text
Redis
```

or edge/API caches.

Thus:

```text
Client
  |
  v
CDN/API Cache
  |
  v
Metadata Service
  |
  v
DB
```

---

# 43. Cache invalidation

Metadata like:

```text
title
thumbnail
privacy
```

changes occasionally.

On update:

```text
MetadataUpdated
      |
      v
cache invalidation
```

For non-critical metadata, short TTLs are also acceptable.

Privacy changes are more sensitive and should propagate rapidly.

---

# 44. Private/unlisted videos

For private videos, CDN can still be used.

Playback API performs authorization:

```text
Can user U view video V?
```

If yes:

```text
return short-lived signed CDN URL/token
```

Then the client downloads segments.

This prevents permanent public object URLs.

---

# 45. Failure scenarios

### Upload succeeds, processing event fails

Use transactional state/outbox or object-storage event retry.

The system should periodically reconcile:

```text
uploaded videos stuck in UPLOADING/PROCESSING
```

---

### One rendition fails

```text
1080p succeeds
720p succeeds
480p fails
```

Retry only the failed processing job.

Maybe publish available renditions while lower-priority renditions finish.

---

### CDN failure

Use:

```text
multi-CDN
```

at very large scale.

Traffic manager can shift users:

```text
CDN A -> unhealthy
        |
        v
CDN B
```

---

# 46. Storage lifecycle

Original source files are expensive.

Possible policy:

```text
source -> hot storage initially
processed renditions -> hot storage
old source -> colder storage
```

Rarely watched videos can also have certain renditions moved to cheaper storage, depending on business requirements.

---

# 47. Observability

I’d monitor:

```text
upload success rate
transcoding latency
processing queue depth
playback startup latency
buffering ratio
CDN cache hit rate
video error rate
average bitrate
view-event lag
search latency
```

Playback QoE metrics are particularly important.

A stream can technically be "up" while users are constantly buffering.

---

# 48. Final architecture

I’d finish with something like:

```text
                             CLIENTS
                    Web / Mobile / Smart TV
                              |
                    +---------+---------+
                    |                   |
                  APIs                Video
                    |                Streaming
                    v                   |
              API Gateway              v
                    |                  CDN
        +-----------+-----------+       |
        |           |           |       v
        v           v           v   Video Segments
    Metadata      Search   Recommendation
    Service       Service     Service
        |           |           |
        v           v           v
  Metadata DB   Search Index Feature Store


                    UPLOAD / PROCESSING

Uploader
   |
   v
Upload Service
   |
   | Presigned URL
   v
Object Storage
   |
   v
UploadCompleted Event
   |
   v
Processing Queue
   |
   +-------------------+
   |                   |
   v                   v
Transcoding        Moderation
Workers                |
   |                    |
   +--------------------+
              |
              v
        Packaging Service
              |
              v
       Rendition Storage
              |
              v
             CDN


                     ANALYTICS

Player Events
     |
     v
Event Collector
     |
     v
Kafka
     |
 +---+-------------+
 |                 |
 v                 v
View Counter   Recommendation
Pipeline        Feature Pipeline
```

# Interview summary

I’d summarize it like this:

> I would separate the control plane from the video data plane. The application services manage metadata, authorization, search, and recommendations, while users upload directly to durable object storage using resumable multipart uploads. Once the upload finishes, an asynchronous processing pipeline generates multiple codec and bitrate renditions, packages them into HLS or DASH segments, and distributes them through a global CDN. Clients use adaptive bitrate streaming to select the appropriate rendition based on network conditions and device capability. Playback events are collected asynchronously through Kafka and deduplicated before updating view counters, avoiding hot database rows and overcounting. Search uses a dedicated inverted index, while recommendations use event-driven feature pipelines, candidate generation, and ranking.

The areas I’d expect the interviewer to drill into most are:

```text
1. Upload + transcoding pipeline
2. Adaptive bitrate streaming
3. CDN/global delivery
4. Accurate view counting
5. Search/recommendation architecture
```

Those five essentially cover the whole prompt.
