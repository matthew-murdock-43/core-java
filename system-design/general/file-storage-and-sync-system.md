Yes. For a **File Storage and Sync System**, I’d frame the interview around four hard problems:

1. Efficiently storing very large files
2. Resumable and incremental uploads
3. Keeping multiple devices synchronized
4. Resolving concurrent edits safely

A good interview structure would be:

1. Clarify requirements
2. Define scale
3. Model metadata vs file content
4. Design upload/download path
5. Design chunking and deduplication
6. Design sync protocol
7. Handle offline edits and conflicts
8. Permissions/sharing
9. Reliability, consistency, and scaling

---

# 1. Clarify the requirements

We need a Dropbox-like system where users can:

- Upload files
- Download files
- Create folders
- Rename/move/delete files
- Sync changes across devices
- Share files/folders
- Support offline edits
- Resume interrupted uploads
- Maintain version history

Optional, depending on interviewer scope:

- File previews
- Search
- Trash/recovery
- Deduplication
- Collaborative editing

I would explicitly separate:

```text
Metadata
vs
File content
```

For example:

```text
File metadata:
    name
    owner
    folder
    size
    permissions
    current version

File content:
    large binary data
```

These should not live in the same storage system.

---

# 2. Non-functional requirements

The important ones are:

- High durability
- High availability
- Large file support
- Efficient bandwidth usage
- Resumable uploads
- Low-latency metadata operations
- Sync correctness
- Version history
- No silent data loss

Consistency requirements differ.

Strong consistency is useful for:

```text
file metadata
permissions
version transitions
rename/move
```

Eventual consistency is usually acceptable for:

```text
device sync notifications
search indexing
previews
analytics
```

---

# 3. Scale assumptions

Suppose:

```text
500M users
100M daily active users

10B files

Average file size:
10 MB

Large files:
up to several GB or TB
```

If users upload:

```text
100M files/day
```

and average size is:

```text
10 MB
```

that's about:

```text
1 PB/day of incoming raw data
```

So we absolutely do not want file data flowing through application servers unnecessarily.

---

# 4. Core entities

## User

```text
User
----
user_id
quota
used_storage
```

## Folder

```text
Folder
------
folder_id
owner_id
parent_folder_id
name
created_at
```

## File

```text
File
----
file_id
owner_id
parent_folder_id
name
current_version_id
size
mime_type
created_at
updated_at
deleted
```

## FileVersion

```text
FileVersion
-----------
version_id
file_id
version_number
size
content_hash
created_by
created_at
```

## Chunk

```text
Chunk
-----
chunk_id
content_hash
size
storage_key
```

## FileChunkMap

```text
FileChunkMap
------------
version_id
chunk_index
chunk_id
offset
length
```

That lets one file version reference multiple chunks.

---

# 5. Why separate file data from metadata?

Metadata is small and highly transactional.

File content is:

- Huge
- Append/write once
- Read often
- Best suited for object storage

So:

```text
Metadata DB
    PostgreSQL / MySQL / distributed SQL

File blobs
    Object Storage
```

Conceptually:

```text
File Service
    │
    ├── Metadata DB
    │
    └── Object Storage
```

---

# 6. High-level architecture

I’d draw this:

```text
                         ┌──────────────────┐
                         │ Web / Desktop /  │
                         │ Mobile Clients   │
                         └────────┬─────────┘
                                  │
                           API Gateway
                                  │
          ┌───────────────────────┼────────────────────────┐
          │                       │                        │
          ▼                       ▼                        ▼
   Metadata Service        Upload Service           Sync Service
          │                       │                        │
          ▼                       ▼                        ▼
    Metadata DB            Object Storage            Change Log
          │                       │                        │
          │                       │                        ▼
          │                       │                  Notification
          │                       │                    Service
          │                       │                        │
          │                       │                        ▼
          │                       │                  WebSocket/Push
          │
          ▼
     Sharing / ACL
       Service
```

For actual binary upload/download, I would avoid proxying every byte through our backend:

```text
Client
  │
  │ request upload
  ▼
Upload Service
  │
  │ pre-signed URL
  ▼
Client ───────────────────────► Object Storage
```

That is a key design choice.

---

# 7. Upload flow

Suppose the user uploads:

```text
video.mp4
5 GB
```

The client first asks:

```http
POST /files/upload-sessions
```

Request:

```json
{
  "name": "video.mp4",
  "parentFolderId": "F123",
  "size": 5368709120
}
```

Server responds:

```json
{
  "uploadSessionId": "U123",
  "chunkSize": 8388608
}
```

For example:

```text
chunk size = 8 MB
```

Then the client uploads chunks.

---

# 8. Large files: split into chunks

Do not treat a 5 GB file as one giant request.

Split:

```text
5 GB file

Chunk 1  8 MB
Chunk 2  8 MB
Chunk 3  8 MB
...
```

Advantages:

- Retry only failed pieces
- Parallel uploads
- Resume interrupted uploads
- Deduplication
- Incremental sync
- Better memory usage

---

# 9. Multipart upload

The backend can initiate an object-store multipart upload.

Example:

```text
Client
   │
   ▼
Upload Service
   │
   ▼
Create multipart upload
   │
   ▼
Object Store
```

Then return pre-signed part URLs.

Client:

```text
PUT chunk 1
PUT chunk 2
PUT chunk 3
...
```

directly to storage.

Finally:

```http
POST /upload-sessions/U123/complete
```

The backend validates all parts and commits the version.

---

# 10. Why direct-to-object-storage?

Bad design:

```text
Client
  │
  ▼
App Server
  │
  ▼
Object Storage
```

For every 10 GB upload, the app server handles 10 GB twice:

```text
client → app
app → storage
```

That wastes:

- CPU
- bandwidth
- memory
- connection capacity

Better:

```text
Client ─────────► Object Storage
      signed URL
```

The backend controls authorization but stays off the bulk data path.

---

# 11. Resumable uploads

This is one of the core follow-ups.

Maintain an upload session:

```text
UploadSession
-------------
upload_session_id
user_id
file_id
expected_size
chunk_size
status
expires_at
```

And track uploaded chunks:

```text
UploadedPart
------------
upload_session_id
part_number
checksum
size
```

Suppose a 1 GB file has 128 chunks.

The client uploads:

```text
1-72
```

then disconnects.

On reconnect:

```http
GET /upload-sessions/U123
```

Response:

```json
{
  "uploadedParts": [1,2,3,...72]
}
```

Then it resumes from:

```text
73
```

not from zero.

---

# 12. Checksums

Every chunk should have a checksum.

For example:

```text
SHA-256(chunk)
```

Client calculates:

```text
chunk 17 hash = abc123...
```

Server/object store validates it.

Why?

Because we want to detect:

- network corruption
- bad retries
- incorrect chunks

Final file can also have:

```text
full file hash
```

---

# 13. Only sync changed chunks

Suppose a 2 GB file changes slightly.

Without chunk-based sync:

```text
edit 4 KB
→ upload entire 2 GB again
```

Wasteful.

Instead:

```text
File
 ├── chunk A
 ├── chunk B
 ├── chunk C
 ├── chunk D
 └── chunk E
```

New version:

```text
A same
B same
C changed
D same
E same
```

Upload only:

```text
C'
```

New version metadata becomes:

```text
A
B
C'
D
E
```

---

# 14. How does the client know which chunks changed?

Two common approaches.

### Fixed-size chunking

Example:

```text
8 MB chunks
```

Simple and fast.

But insert 1 byte near the beginning:

```text
all following chunk boundaries shift
```

and many chunks appear changed.

---

### Content-defined chunking

Use rolling hashes, such as Rabin fingerprinting.

Instead of fixed boundaries:

```text
boundary determined by content
```

So inserting a small amount of data doesn't shift the entire file.

Example:

```text
Original:
[A][B][C][D][E]

Insert data inside C:

[A][B][C'][D][E]
```

Only C changes.

This is much more bandwidth-efficient for sync systems.

I'd mention:

> For an initial implementation I'd probably start with fixed-size chunks for simplicity, then move to content-defined chunking if delta-sync efficiency is important.

---

# 15. Chunk hashes and deduplication

Each chunk has:

```text
chunk_hash
```

Before upload:

```http
POST /chunks/check
```

Client sends hashes:

```text
H1
H2
H3
H4
```

Server responds:

```text
already have:
H1
H3

missing:
H2
H4
```

Client uploads only:

```text
H2
H4
```

This gives:

```text
network deduplication
```

and potentially:

```text
storage deduplication
```

---

# 16. Deduplication tradeoff

Global deduplication means:

```text
User A uploads chunk X
User B uploads identical chunk X
```

store once.

But global dedup can have security/privacy implications, such as revealing whether a particular file already exists.

Safer options include:

```text
dedupe within same account
```

or:

```text
dedupe within tenant
```

instead of globally.

I'd mention this if interviewer goes deeper.

---

# 17. File versioning

Every update creates a new version:

```text
file_id = F123

v1
v2
v3
v4
```

Do not overwrite the previous version immediately.

Metadata:

```text
File.current_version_id = v4
```

This gives us:

- rollback
- conflict handling
- trash/recovery
- auditability

Old versions can be garbage-collected later based on retention policy.

---

# 18. Sync across devices

Suppose the user has:

```text
Laptop
Phone
Tablet
```

Laptop changes file A.

How do the others know?

Use a per-user change log.

Example:

```text
change_seq=100
change_seq=101
change_seq=102
```

Each device stores:

```text
last_sync_cursor
```

For example:

```text
Phone last_sync_cursor = 100
```

It asks:

```http
GET /sync/changes?cursor=100
```

Response:

```json
{
  "changes": [
    { "seq": 101, "type": "FILE_UPDATED", "fileId": "F1" },
    { "seq": 102, "type": "FILE_CREATED", "fileId": "F2" }
  ],
  "nextCursor": 102
}
```

---

# 19. Why use a change log?

Without it, a device might repeatedly scan:

```text
all 500,000 files
```

to ask:

```text
"what changed?"
```

Very expensive.

With a change log:

```text
give me changes since cursor 123456
```

is cheap and incremental.

---

# 20. Real-time sync notification

The change log is authoritative.

But to reduce latency, use:

```text
WebSocket / push notification
```

Flow:

```text
Laptop updates file
      │
      ▼
Metadata commit
      │
      ▼
Change event
      │
      ▼
Notification Service
      │
      ├── Phone
      └── Tablet
```

Those devices then call:

```text
sync since cursor
```

So push says:

```text
"something changed"
```

rather than being the source of truth.

---

# 21. Sync architecture

Conceptually:

```text
Device A
   │
   │ update file
   ▼
Metadata Service
   │
   ├── Metadata DB
   │
   └── Change Log
           │
           ▼
         Kafka
           │
           ▼
   Notification Service
        │       │
        ▼       ▼
    Device B  Device C
```

Devices pull missing changes using their cursors.

---

# 22. Offline edits

This is another major follow-up.

Suppose:

```text
Laptop starts from version 10
Phone starts from version 10
```

Both go offline.

Laptop edits:

```text
v10 → local A
```

Phone edits:

```text
v10 → local B
```

Laptop reconnects first:

```text
server:
v10 → v11
```

Phone reconnects later and says:

```text
my base version = v10
```

but current server version is:

```text
v11
```

That's a conflict.

---

# 23. Optimistic concurrency

Each update includes:

```text
base_version_id
```

For example:

```http
POST /files/F123/versions
```

```json
{
  "baseVersionId": "v10",
  "newContent": "..."
}
```

Server checks:

```text
current version == base version?
```

If:

```text
yes
```

commit normally.

If:

```text
no
```

conflict.

This is optimistic concurrency control.

---

# 24. Conflict resolution

For generic binary files, automatic merge is usually unsafe.

So create a conflict copy.

Example:

```text
report.docx
report (John's conflicted copy).docx
```

The system preserves both versions.

That's better than silently overwriting someone's work.

---

# 25. Text files

For text-like documents, we may attempt merge.

If changes touch independent lines:

```text
Device A modifies line 10
Device B modifies line 50
```

we could perform a three-way merge:

```text
base
device A
device B
```

But for generic Dropbox-like storage, I would keep conflict handling simple:

> detect conflicts reliably and preserve both copies.

Collaborative editing with OT/CRDT is a different system design.

---

# 26. Rename/move conflicts

Not all conflicts are content conflicts.

Example:

Device A:

```text
rename report.txt → final.txt
```

Device B:

```text
delete report.txt
```

while offline.

We need operation/version metadata.

The sync engine should treat filesystem operations as versioned changes too:

```text
CREATE
UPDATE
RENAME
MOVE
DELETE
RESTORE
```

---

# 27. Tombstones for deletes

Suppose Device A deletes a file.

If we simply remove metadata, Device B reconnecting later might think:

```text
"server doesn't have it, maybe I should upload my local copy"
```

and accidentally resurrect the file.

Instead create a tombstone:

```text
file_id = F123
deleted = true
delete_version = 42
```

Then all clients can sync the deletion.

Tombstones can be retained for a fixed period before garbage collection.

---

# 28. Sharing model

Now permissions.

For files/folders, use ACL-style permissions.

Example:

```text
ResourcePermission
------------------
resource_id
principal_type
principal_id
permission
```

Where:

```text
principal_type:
USER
GROUP
LINK
```

And:

```text
permission:
OWNER
EDITOR
VIEWER
```

---

# 29. Folder permission inheritance

Suppose:

```text
Shared Folder
    ├── A.txt
    ├── B.jpg
    └── Subfolder
          └── C.pdf
```

If Bob gets:

```text
EDITOR
```

on the folder, should it apply to everything below?

Usually yes.

So effective permission can come from:

```text
direct ACL
+
ancestor folder ACL
```

But computing the full folder tree for every request would be expensive.

Possible solutions:

- Cache effective permissions
- Materialize sharing relationships
- Invalidate when ACL changes

---

# 30. Shared links

Support:

```text
https://files.example.com/s/abc123
```

The link maps to:

```text
resource_id
permission = VIEW
expires_at
password_optional
```

Never expose:

```text
internal storage object key
```

directly.

The sharing service validates the link and produces a short-lived signed download URL.

---

# 31. Download flow

Client asks:

```http
GET /files/F123/download
```

Backend checks:

```text
user permission
```

Then returns:

```text
pre-signed object-storage URL
```

Flow:

```text
Client
  │
  ▼
File API
  │
  ├── ACL check
  │
  └── signed URL
  ▼
Client ───────────────► Object Storage / CDN
```

Again, application servers stay off the large-data path.

---

# 32. CDN

Frequently downloaded shared files can go through CDN:

```text
Object Storage
      │
      ▼
     CDN
      │
      ▼
   Clients
```

This reduces:

- origin bandwidth
- latency
- storage read load

Private resources still require signed URLs/tokens.

---

# 33. Metadata DB design

Metadata access patterns:

```text
list folder
get file by id
rename file
move file
get current version
get permissions
```

A relational DB works well initially.

Example:

```text
PostgreSQL
```

At large scale, shard by:

```text
owner_id
```

or logical namespace.

Why owner/user?

Most operations happen within a user's file tree.

---

# 34. Directory listing

Don't store entire folder contents as one huge blob.

Instead:

```text
File
parent_folder_id = FOLDER123
```

Query:

```sql
SELECT *
FROM file
WHERE parent_folder_id = ?
```

with appropriate indexing.

Could shard by:

```text
namespace_id
```

for shared folders/team spaces.

---

# 35. Object naming

Never use filename as the physical object key.

Bad:

```text
/photos/vacation.jpg
```

because rename would require moving blob data.

Instead:

```text
chunk/<hash>
```

or:

```text
object/<uuid>
```

Metadata controls the logical name.

So rename:

```text
vacation.jpg → italy.jpg
```

updates only metadata.

No binary copy required.

---

# 36. Atomic metadata update

Suppose upload succeeds but metadata update fails.

You don't want a user-visible file pointing to incomplete content.

Use a two-phase logical workflow:

```text
upload chunks
     │
     ▼
verify chunks
     │
     ▼
commit metadata version
```

Until metadata commit:

```text
new version invisible
```

Once committed:

```text
current_version_id = new version
```

atomically.

---

# 37. Orphaned uploads

What if:

```text
user uploads all chunks
```

but never calls complete?

Those chunks become temporary/orphaned data.

Use:

```text
upload session TTL
```

and a cleanup process.

Example:

```text
incomplete upload older than 24h
→ garbage collect
```

---

# 38. Garbage collection

Chunk deduplication means a chunk may be referenced by many versions.

So don't delete a chunk immediately when one file version disappears.

Maintain:

```text
reference count
```

or periodically compute reachability.

Example:

```text
Chunk X
refs = 3
```

Delete one version:

```text
refs = 2
```

Only delete chunk when:

```text
refs = 0
```

plus retention/grace period.

---

# 39. Reliable event publishing

Suppose metadata update commits but sync event publishing fails.

Then other devices may not learn about the change.

Use transactional outbox:

```text
BEGIN

UPDATE file_version
INSERT sync_change
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

That keeps metadata and sync event creation consistent.

---

# 40. Change log ordering

For each user or namespace:

```text
change sequence:
1001
1002
1003
1004
```

A device with cursor:

```text
1002
```

asks:

```text
give me >1002
```

and gets:

```text
1003
1004
```

You don't need a global sequence across all users.

That would be unnecessary coordination.

---

# 41. Shared folder sync

A subtle issue: shared folders don't belong to just one device/user namespace.

So I'd introduce:

```text
namespace_id
```

For example:

```text
Personal namespace:
N-user-123

Shared project folder:
N-team-456
```

Change log is then per namespace:

```text
namespace_id + sequence
```

Every member subscribes to that namespace.

This scales better than duplicating the entire change stream for every member.

---

# 42. Storage durability

Actual blobs should be replicated by the object store.

For example:

```text
multiple AZ replicas
```

or:

```text
erasure coding
```

depending on the storage layer.

Metadata DB should also have:

- replication
- backups
- point-in-time recovery

Because losing metadata can be just as bad as losing bytes.

---

# 43. Quotas

Each user has:

```text
storage_quota
storage_used
```

Before committing an upload:

```text
current usage + new logical size <= quota
```

But dedup complicates this.

User-facing quota should usually be based on:

```text
logical file size
```

not physical deduplicated storage.

Otherwise users could get unpredictable quota behavior.

---

# 44. Security

Need:

- TLS in transit
- Encryption at rest
- ACL validation
- Signed upload/download URLs
- Short-lived credentials
- Malware scanning if required
- Audit logs for shared/business accounts

For pre-signed URLs:

```text
expires in a few minutes
```

and scope to one object/upload part.

---

# 45. Final architecture

I’d end with something like this:

```text
                               CLIENTS
                    Desktop / Mobile / Web
                               │
                               ▼
                          API Gateway
                               │
        ┌──────────────────────┼────────────────────────┐
        │                      │                        │
        ▼                      ▼                        ▼
 Metadata Service         Upload Service           Sync Service
        │                      │                        │
        ▼                      │                        ▼
   Metadata DB                 │                  Change Log DB
        │                      │                        │
        │                      ▼                        ▼
        │                Upload Session DB            Kafka
        │                      │                        │
        │                      │                        ▼
        │                      │                Notification Service
        │                      │                        │
        │                      │                  WebSocket / Push
        │                      │
        │                      ▼
        │               Pre-signed URLs
        │                      │
        │                      ▼
        │                Object Storage
        │                      │
        │                      ▼
        │                     CDN
        │
        ▼
 Permission / Sharing
      Service
```

And the file representation:

```text
File
  │
  ▼
FileVersion v12
  │
  ├── Chunk A
  ├── Chunk B
  ├── Chunk C
  └── Chunk D
```

New version:

```text
FileVersion v13
  │
  ├── Chunk A
  ├── Chunk B
  ├── Chunk C'
  └── Chunk D
```

Only:

```text
Chunk C'
```

needs to be uploaded.

---

# How I would summarize it in the interview

> I would separate file metadata from binary content. Metadata and permissions live in a transactional metadata service, while large file content is split into chunks and stored in durable object storage. Clients upload chunks directly using pre-signed URLs, which supports parallel and resumable uploads without sending large files through application servers. Each file update creates a new immutable version referencing chunk hashes, allowing us to upload only changed chunks and deduplicate content where appropriate. Device synchronization is based on an ordered per-user or per-namespace change log and a cursor, with push notifications used only to wake clients. Offline edits use optimistic concurrency: if the client's base version is stale, we detect a conflict and preserve both versions instead of silently overwriting data. Shared files and folders use ACL-based permissions with folder inheritance and short-lived signed download URLs.

For this problem, the areas I would expect the interviewer to drill into most are **chunking/resumable uploads, delta sync, offline conflict resolution, and shared-folder permissions**.
