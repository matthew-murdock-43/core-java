For this e-commerce design, I’d treat **product media upload as a separate subsystem from the core Product/Listing service**. The Product service stores metadata; images/videos themselves live in object storage.

A good interview framing is:

```text
Seller
  |
  v
API Gateway
  |
  v
Media Service ------------------> Metadata DB
  |
  | 1. generate pre-signed URL
  v
Object Storage (S3/GCS)
  |
  | ObjectCreated event
  v
Queue / Event Bus
  |
  +--> Validation / malware scan
  +--> Image resize/compression
  +--> Video transcoding
  +--> Thumbnail generation
  |
  v
Processed Media Storage
  |
  v
CDN
  |
  v
Customer
```

### 1. What items would I allow sellers to upload?

For a marketplace listing, typically:

- Product images: JPEG, PNG, WebP, maybe AVIF
- Product videos: MP4/MOV as input
- Documents where applicable: manuals, size charts, PDFs
- Bulk catalog files: CSV/JSON, although I'd handle these through a separate bulk-import pipeline

I wouldn't put the binary media inside the `Product` table.

Instead:

```text
Product
--------
product_id
title
description
category_id
...

Listing
-------
listing_id
product_id
seller_id
price
...

Media
-----
media_id
listing_id
type            IMAGE / VIDEO
original_key
processed_key
status
content_type
size_bytes
checksum
width
height
duration
created_at
```

So a listing could have:

```text
Listing 123
 ├── image-1
 ├── image-2
 ├── image-3
 └── video-1
```

The database stores the **reference and metadata**, not the actual 200 MB video.

---

## 2. How would I upload files?

I would avoid this:

```text
Seller -> Application Server -> S3
```

because a 1 GB video would consume application-server bandwidth, memory/connections, and potentially cause timeouts.

Instead:

```text
1. Seller -> POST /media/uploads

2. Media Service:
      validates file metadata
      creates upload record
      returns pre-signed object-storage URL

3. Seller -----------------------> S3
             uploads directly

4. S3 -> event -> processing pipeline
```

For example:

```http
POST /v1/media/uploads

{
    "listingId": "L123",
    "fileName": "shoe-demo.mp4",
    "contentType": "video/mp4",
    "size": 450000000
}
```

Response:

```json
{
  "mediaId": "M789",
  "uploadUrl": "...pre-signed-url...",
  "expiresIn": 900
}
```

Then the client uploads directly to object storage.

This keeps the API servers lightweight.

---

# 3. How do I store the items?

Use **object storage** such as S3 rather than relational databases or local server disks.

Something like:

```text
s3://marketplace-media/

    original/
        seller-123/
            media-789.mp4

    processed/
        media-789/
            thumbnail.jpg
            360p.mp4
            720p.mp4
            1080p.mp4

    images/
        media-456/
            original.jpg
            200x200.webp
            800x800.webp
            1600x1600.webp
```

Reasons object storage fits:

- practically unlimited scale
- much cheaper than DB storage
- durability
- multipart upload
- lifecycle policies
- CDN integration
- versioning support

The Product DB might just contain:

```text
media_id = M789
media_url = cdn.example.com/media/M789/720p.mp4
```

Although I'd usually store an **object key**, not a hardcoded CDN URL:

```text
processed_key = media/M789/720p.mp4
```

Then construct the public URL at serving time.

---

# 4. How do you handle heavy videos?

This is an important follow-up.

For large videos, use **multipart/resumable uploads**.

Instead of uploading:

```text
1 GB
--------------------------> one HTTP request
```

break it into chunks:

```text
Part 1: 10 MB
Part 2: 10 MB
Part 3: 10 MB
...
Part 100
```

If part 73 fails:

```text
retry part 73
```

rather than uploading the entire video again.

S3 Multipart Upload supports exactly this pattern.

The flow becomes:

```text
Client
  |
  | request upload session
  v
Media Service
  |
  | multipart URLs
  v
Client
  |
  +--> Part 1 ----\
  +--> Part 2 -----\
  +--> Part 3 ------> Object Storage
  +--> Part N -----/
  |
  | complete upload
  v
Media Service
```

For very large media I'd also support:

- parallel chunk uploads
- resumable uploads
- upload timeout/session expiration
- maximum video size
- maximum duration/resolution
- rate limits per seller

---

# 5. Don't serve the original video directly

After upload, I'd asynchronously transcode it.

For example:

```text
seller uploads:
4K / 1 GB MOV
       |
       v
Transcoding pipeline
       |
       +--> 1080p
       +--> 720p
       +--> 480p
       +--> thumbnail
       +--> preview clip
```

Potential technologies:

```text
FFmpeg workers
AWS MediaConvert
GCP Transcoder API
```

For large scale I'd typically use:

```text
S3
 |
 v
Kafka / SQS
 |
 v
Transcoding workers
 |
 v
processed S3 bucket
```

The listing could initially show:

```text
VIDEO_PROCESSING
```

and once processing succeeds:

```text
ACTIVE
```

---

# 6. How do you avoid corrupt files?

There are several layers.

### Layer 1 — Validate before upload

When requesting the upload:

```text
Allowed type:
image/jpeg
image/png
video/mp4

Max image:
20 MB

Max video:
2 GB
```

But don't trust the filename:

```text
shoe.jpg
```

could actually contain something else.

So server-side processing validates the actual file signature / MIME type.

---

### Layer 2 — Checksum

The client calculates something like:

```text
SHA-256(file)
```

Suppose:

```text
original checksum
abc123...
```

After S3 receives the object, the backend computes/verifies:

```text
uploaded checksum
abc123...
```

If:

```text
original != uploaded
```

mark the upload:

```text
CORRUPTED
```

and discard/quarantine it.

For multipart uploads, individual parts can also be checksummed.

---

### Layer 3 — Decode the file

A file being successfully uploaded does **not** mean it's valid.

For an image:

```text
try decoding with image processor
```

For a video:

```text
ffprobe / media parser
```

Check:

```text
container
codec
duration
resolution
frame structure
```

If the media decoder cannot read it:

```text
status = INVALID_MEDIA
```

---

### Layer 4 — Malware scanning

New uploads go into a quarantine location:

```text
incoming/
```

Not:

```text
public/
```

Pipeline:

```text
incoming bucket
     |
     v
Checksum validation
     |
     v
Content-type validation
     |
     v
Virus / malware scan
     |
     v
Media decoding
     |
     v
Transcoding
     |
     v
approved/processed bucket
```

Only approved media gets exposed through the CDN.

---

# 7. Upload state machine

This makes the design much cleaner.

I would model media as:

```text
CREATED
   |
   v
UPLOADING
   |
   v
UPLOADED
   |
   v
VALIDATING
   |
   +------------+
   |            |
   v            v
PROCESSING    REJECTED
   |
   v
READY
```

Potential DB row:

```text
media_id       M789
listing_id     L123
status         PROCESSING
size           450MB
checksum       abc...
original_key   incoming/M789
processed_key  null
```

After processing:

```text
status         READY
processed_key  video/M789/master.m3u8
```

This is valuable because product creation doesn't have to synchronously wait for a 10-minute video transcoding job.

---

# 8. Serving images and videos

Customers shouldn't normally fetch media through the application servers either.

Use:

```text
Customer
   |
   v
CDN
   |
   v
Object Storage
```

For example:

```text
cdn.marketplace.com/products/123/image-1.webp
```

Benefits:

- low latency
- fewer requests hitting backend
- global distribution
- edge caching
- cheaper origin traffic

For video, I'd likely generate HLS/DASH:

```text
master.m3u8

1080p
720p
480p
```

Then adaptive streaming chooses quality based on customer bandwidth.

---

# 9. What if processing fails?

Don't delete immediately.

For example:

```text
PROCESSING_FAILED
```

Keep the original temporarily:

```text
incoming/M789.mp4
```

Then retry:

```text
attempt 1
attempt 2
attempt 3
```

After max retries:

```text
Dead Letter Queue
```

Operations can investigate, or seller can re-upload.

Set a lifecycle rule:

```text
failed/raw uploads -> delete after 7 days
abandoned multipart uploads -> delete after 24 hours
```

This prevents storage from filling with unfinished uploads.

---

# 10. One subtle issue: user says upload succeeded but backend didn't know

Suppose:

```text
Client -> S3
             upload succeeded

Client -> Media Service
             network failure
```

Don't depend solely on the client saying:

```text
"upload finished"
```

Object storage should emit an event:

```text
ObjectCreated
```

which triggers processing.

So:

```text
S3
 |
 | ObjectCreated
 v
SQS/Kafka
 |
 v
Media Processor
```

This makes the workflow much more reliable.

I'd also make processing idempotent because object-storage/event systems can redeliver events:

```text
if media M789 already processed:
    ignore duplicate
```

---

# How I'd explain the whole thing in an interview

I'd sketch this:

```text
                     +----------------+
                     | Product Service|
                     +-------+--------+
                             |
                             | metadata
                             v
                            DB


Seller
  |
  | request upload
  v
Media Service
  |
  | pre-signed URL
  v
Seller -----------------------> Object Storage
                                    |
                                    | ObjectCreated
                                    v
                               Queue / Kafka
                                    |
                                    v
                            Media Processing
                           /       |        \
                      checksum   malware   decode
                                    |
                                    v
                              Transcoding
                                    |
                                    v
                           Processed Storage
                                    |
                                    v
                                   CDN
                                    |
                                    v
                                 Customer
```

And then summarize the main decisions:

| Problem | Design |
|---|---|
| Where to store media? | Object storage |
| Where to store metadata? | Product/Media DB |
| Large uploads? | Direct + multipart/resumable upload |
| Avoid backend bandwidth? | Pre-signed URLs |
| Heavy video processing? | Async queue + transcoding workers |
| Corrupt upload? | SHA-256/checksum validation |
| Invalid fake files? | MIME/signature + decode validation |
| Malware? | Quarantine + virus scanning |
| Video delivery? | HLS/DASH + CDN |
| Failed processing? | Retry + DLQ |
| Duplicate events? | Idempotent processing |
| Abandoned uploads? | Object-storage lifecycle cleanup |

One interview distinction I'd explicitly call out is: **uploading media is not part of the synchronous "create product" transaction**. Create the product/listing and media metadata first, upload media independently, process it asynchronously, and transition the media from `UPLOADING → PROCESSING → READY`. That separation makes the overall marketplace design much easier to scale.
