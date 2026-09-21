For this one, I’d frame the interview around separating **identity**, **user management**, and **authorization**, because they have different consistency and latency requirements.

The key design principle is:

> User/profile writes and role changes are relatively infrequent, while authorization checks are extremely read-heavy. So I would keep role assignment strongly consistent at the source of truth, propagate changes through events, and make authorization checks fast through carefully invalidated caches and short-lived tokens.

A good interview flow is:

1. Clarify requirements
2. Define the data model
3. Draw the high-level architecture
4. Design authentication/token issuance
5. Design role assignment
6. Design authorization checks
7. Handle cache invalidation and role changes
8. Design multi-region consistency
9. Handle deletion/suspension/revocation
10. Add audit/security/failure handling

---

# 1. Clarify the requirements

We have predefined:

```text
Roles
  └── Permissions
```

and need to support:

```text
Users
  └── one or more Roles
```

For example:

```text
ADMIN
  ├── user:read
  ├── user:write
  └── user:delete

SUPPORT
  ├── user:read
  └── ticket:write

VIEWER
  └── user:read
```

The system needs:

- Create/update/delete users
- Active/inactive/suspended state
- Assign/remove roles
- Authenticate users
- Issue sessions/tokens
- Authorize requests across many services
- Notify downstream systems about user/role changes
- Audit all security-sensitive changes

The critical invariant is:

```text
A service must never grant access
based on a role the user no longer has,
beyond the explicitly accepted propagation window.
```

---

# 2. Functional decomposition

I would split responsibilities into:

```text
Identity Service
    authentication

User Service
    user profile/lifecycle

RBAC Service
    role assignment + permission lookup

Authorization Service
    runtime access checks

Token Service
    token/session issuance and refresh

Audit Service
    immutable security trail
```

That avoids one enormous "UserService" doing everything.

---

# 3. Core data model

## User

```text
User
----
user_id
username
email
status
created_at
updated_at
version
```

Status:

```text
ACTIVE
INACTIVE
SUSPENDED
DELETED
```

I would normally use soft deletion/tombstones initially rather than physically deleting security history immediately.

---

# 4. Role

Roles already exist:

```text
Role
----
role_id
name
description
version
```

Example:

```text
R1 ADMIN
R2 SUPPORT
R3 VIEWER
```

---

# 5. Permission

```text
Permission
----------
permission_id
resource
action
```

For example:

```text
user:read
user:update
order:refund
report:view
```

---

# 6. RolePermission

```text
RolePermission
--------------
role_id
permission_id
```

Since roles are predefined, these change rarely.

---

# 7. UserRole

This is one of the most important tables.

```text
UserRole
--------
user_id
role_id
assigned_at
assigned_by
version
```

Unique:

```text
(user_id, role_id)
```

A user may have:

```text
User 123
  ├── SUPPORT
  └── REPORT_VIEWER
```

---

# 8. High-level architecture

I’d draw this:

```text
                             CLIENTS
                                │
                                ▼
                         API Gateway / LB
                                │
                  ┌─────────────┴─────────────┐
                  │                           │
                  ▼                           ▼
           Identity Service              User Service
                  │                           │
                  ▼                           ▼
             Token Service                User DB
                  │
                  │
                  ▼
               JWT /
             Session Token


                         RBAC / AUTHORIZATION

       Internal Service
              │
              ▼
       Authorization SDK
              │
       ┌──────┴─────────┐
       │                │
       ▼                ▼
 Local/Auth Cache    Authorization Service
                         │
                         ▼
                     RBAC Cache
                         │
                         ▼
                      RBAC DB


                     CHANGE PROPAGATION

 User Service / RBAC Service
              │
              ▼
       Transactional Outbox
              │
              ▼
            Kafka
              │
       ┌──────┼───────────────┐
       ▼      ▼               ▼
 Auth Cache  Audit      Notification /
 Invalidate  Service     Downstream Sync
```

---

# 9. Database choice

For users and role assignments, I’d start with a relational database:

```text
PostgreSQL / MySQL
```

Why?

Because we care about:

- Transactions
- Unique constraints
- Referential integrity
- Auditing
- Consistent role changes

Typical operations are:

```text
get user
update user
assign role
remove role
list user roles
```

This is a good relational fit.

---

# 10. User creation flow

Example:

```http
POST /users
```

```json
{
  "email": "user@example.com",
  "name": "Alice"
}
```

Flow:

```text
Client
  │
  ▼
User Service
  │
  ▼
BEGIN
  INSERT user
  INSERT audit/outbox event
COMMIT
  │
  ▼
UserCreated event
```

The user becomes authoritative once the DB transaction commits.

---

# 11. Role assignment flow

Example:

```http
PUT /users/{userId}/roles/{roleId}
```

Flow:

```text
Admin
  │
  ▼
RBAC Service
  │
  ├── authenticate caller
  ├── authorize caller has role:assign
  ├── validate user
  ├── validate role
  │
  ▼
BEGIN TRANSACTION
  INSERT UserRole
  increment user_auth_version
  INSERT outbox event
COMMIT
  │
  ▼
RoleAssigned event
```

This should be idempotent.

If the role already exists:

```text
PUT same role again
→ success
```

not duplicate assignment.

---

# 12. Why increment an authorization version?

This is very useful.

User record can maintain:

```text
authz_version = 17
```

Token issued:

```json
{
  "sub": "U123",
  "authz_version": 17
}
```

Then role changes:

```text
SUPPORT removed
```

RBAC service updates:

```text
authz_version = 18
```

Now old authorization state can be detected as stale.

We'll use this later for revocation/cache invalidation.

---

# 13. Authentication

I would not store passwords directly in User Service.

Use an Identity Service / IdP.

Authentication:

```text
Client
  │
  ▼
Identity Service
  │
  ├── password / passkey / MFA / federation
  │
  ▼
authenticated principal
```

Password storage, if managed internally:

```text
salted adaptive hash
Argon2 / bcrypt / scrypt
```

not encryption and never plaintext.

---

# 14. Token strategy

After authentication:

```text
Identity Service
      │
      ▼
Token Service
      │
      ▼
Access Token
```

I would generally use:

```text
short-lived JWT access token
+
long-lived refresh token/session
```

Example:

```text
Access token:
5–15 minutes

Refresh token:
hours/days depending on policy
```

---

# 15. What goes in the JWT?

Possible claims:

```json
{
  "sub": "U123",
  "iss": "identity-service",
  "aud": "internal-platform",
  "exp": 123456789,
  "authz_version": 17
}
```

Would I put every permission inside it?

Not necessarily.

That is an important design tradeoff.

---

# 16. Option A: roles in JWT

Example:

```json
{
  "roles": ["SUPPORT", "VIEWER"]
}
```

Advantages:

```text
Authorization is local and very fast
No central call per request
```

But downside:

```text
Role removed
     │
     ▼
existing JWT still says SUPPORT
```

until token expires.

So revocation latency equals token lifetime unless we add additional checks.

---

# 17. Option B: centralized authorization

Token contains identity only.

Service asks:

```text
Can U123 perform order:refund?
```

to Authorization Service.

Advantages:

- Latest permissions
- Immediate role changes

Disadvantages:

- Network call
- Higher latency
- Authorization service becomes critical dependency

---

# 18. Practical hybrid design

I would usually use a hybrid:

```text
JWT
  └── identity + version

Authorization SDK
  │
  ├── local/cache
  │
  └── Authorization Service fallback
```

Flow:

```text
Request
   │
   ▼
Service
   │
   ▼
Validate JWT signature locally
   │
   ▼
Check cached permissions/version
   │
   ├── cache hit/current → decide
   │
   └── stale/miss → Authorization Service
```

That gives:

```text
low latency
+
rapid revocation
```

without a central RPC on every request.

---

# 19. Authorization check

Application code should say:

```text
authorize(
    user = U123,
    permission = "order:refund"
)
```

rather than:

```text
if role == ADMIN
```

everywhere.

Why?

Services should depend on:

```text
permissions
```

rather than the internal definition of roles.

Then roles can evolve without changing all applications.

---

# 20. Permission evaluation

Authorization Service gets:

```text
user_id
permission
resource/context
```

For pure RBAC:

```text
User
  │
  ▼
Roles
  │
  ▼
Permissions
```

Example:

```text
U123
  ↓
SUPPORT
  ↓
user:read
ticket:update
```

If requested permission is present:

```text
ALLOW
```

otherwise:

```text
DENY
```

Default should be:

```text
DENY
```

---

# 21. Authorization response

Potential response:

```json
{
  "allowed": true,
  "decisionId": "D123",
  "authzVersion": 18,
  "expiresAt": "..."
}
```

This makes decisions auditable.

---

# 22. Authorization SDK

I would provide an internal SDK.

Instead of every microservice implementing:

```text
JWT validation
cache logic
RBAC calls
retry
metrics
```

independently:

```text
Service
  │
  ▼
Authorization SDK
```

SDK handles:

- Token signature verification
- Permission checks
- Cache
- Fail-closed behavior
- Metrics
- Trace propagation

This dramatically reduces inconsistent implementations.

---

# 23. Read-heavy scaling

Authorization checks can be enormous.

Example:

```text
50K services requests/sec
```

could imply hundreds of thousands or millions of checks/sec.

Don't hit the primary DB for every request.

Use:

```text
L1 cache
+
L2 distributed cache
+
DB
```

---

# 24. Caching architecture

```text
Application
    │
    ▼
L1 local cache
    │
    │ miss
    ▼
Authorization Service
    │
    ▼
L2 Redis
    │
    │ miss
    ▼
RBAC DB
```

Cache value:

```text
user_id
roles
permissions
authz_version
```

---

# 25. Cache key

For example:

```text
authz:U123:v18
```

Containing:

```text
permissions:
  user:read
  ticket:update
```

Version in the key helps avoid serving stale role data.

---

# 26. Role-change cache invalidation

Suppose:

```text
U123 loses ADMIN
```

Flow:

```text
RBAC DB commit
     │
     ▼
RoleRemoved event
     │
     ▼
Kafka
     │
     ├── invalidate Redis
     ├── invalidate service L1 caches
     └── update audit pipeline
```

The event contains:

```text
user_id=U123
authz_version=19
```

Services seeing older:

```text
v18
```

know it is stale.

---

# 27. Why TTL alone isn't enough

Suppose cache TTL:

```text
10 minutes
```

User loses a critical permission.

If we wait 10 minutes:

```text
user may retain access for 10 minutes
```

which may be unacceptable.

So combine:

```text
event-driven invalidation
+
short TTL
+
version checks
```

TTL becomes the safety net rather than primary revocation mechanism.

---

# 28. Token revocation

Another tricky issue.

Suppose user is:

```text
SUSPENDED
```

at 10:00.

Their access token expires at:

```text
10:15
```

We shouldn't necessarily allow access for 15 more minutes.

Options:

```text
short token lifetime
session revocation store
authz/user version check
```

A practical design uses:

```text
JWT status/version
+
fast revocation/status cache
```

for sensitive requests.

---

# 29. User status check

Authorization should include:

```text
user.status == ACTIVE
```

If:

```text
SUSPENDED
DELETED
INACTIVE
```

then:

```text
DENY
```

regardless of role.

So effective authorization:

```text
authenticated
AND user active
AND required permission exists
```

---

# 30. Audit role changes

Every sensitive mutation should create:

```text
AuditEvent
----------
event_id
actor_id
action
target_user_id
old_value
new_value
timestamp
request_id
source_ip
```

Example:

```text
Actor: Admin42
Action: REMOVE_ROLE
Target: User123
Role: ADMIN
Time: 10:32
```

---

# 31. Audit authorization decisions

Do we log every check?

At huge scale, logging every successful check may be expensive.

I would distinguish:

```text
all administrative mutations
    → always audit

denied access
    → audit

sensitive access
    → audit

ordinary low-risk ALLOW
    → metrics/sample depending on compliance
```

If requirements demand every decision, use a high-throughput asynchronous audit pipeline.

---

# 32. Audit architecture

```text
Services
   │
   ▼
Audit Events
   │
   ▼
Kafka
   │
   ├── Security Analytics
   └── Immutable Audit Store
```

Don't synchronously block every user request on long-term audit storage.

But for sensitive state changes, ensure audit event creation is atomic with the transaction using an outbox.

---

# 33. Transactional outbox

Suppose:

```text
role removed in DB
```

then service crashes before publishing:

```text
RoleRemoved
```

Caches would remain stale.

Use:

```text
BEGIN

DELETE UserRole
UPDATE authz_version
INSERT OutboxEvent

COMMIT
```

Then:

```text
Outbox Publisher
    │
    ▼
Kafka
```

This keeps role state and change propagation consistent.

---

# 34. Change events

Useful events:

```text
UserCreated
UserUpdated
UserSuspended
UserDeleted
RoleAssigned
RoleRemoved
```

Event example:

```json
{
  "eventType": "RoleRemoved",
  "userId": "U123",
  "roleId": "ADMIN",
  "authzVersion": 19
}
```

Consumers include:

```text
Authorization cache
Audit
Notification
Search/index
Downstream systems
```

---

# 35. Notification on role changes

The requirement mentions notification.

Could mean:

```text
notify affected user/admin
```

or:

```text
notify downstream systems
```

I’d support both.

Business event:

```text
RoleChanged
```

goes to the event bus.

Consumers:

```text
Email/Notification Service
Authorization cache invalidator
Audit Service
Security monitoring
```

So role assignment isn't tightly coupled to notification availability.

---

# 36. Multi-region architecture

Now the distributed part.

Example:

```text
US
EU
APAC
```

Requirements:

- Local low-latency reads
- Region failure tolerance
- Consistent security state

I'd separate:

```text
writes
vs
authorization reads
```

---

# 37. Single-writer/home-region approach

Simpler model:

```text
User mutations
      │
      ▼
Primary/home region DB
      │
      ▼
replicate
      │
   ┌──┴────┐
   ▼       ▼
EU read   APAC read
```

Benefits:

- Strong write ordering
- Simpler conflict model

Authorization reads served locally from replicated cache/data.

Tradeoff:

```text
cross-region write latency
```

Usually acceptable because role changes are low-frequency.

---

# 38. Why not multi-master immediately?

Suppose:

```text
US assigns ADMIN
```

at same time:

```text
EU removes ADMIN
```

Multi-primary writes now require conflict resolution.

For security state, "last writer wins" is risky.

So I would prefer:

```text
single logical owner for role mutations
```

unless scale/availability genuinely requires multi-writer.

RBAC writes are generally far lower volume than authorization reads.

---

# 39. Strong writes, eventually consistent caches

I’d describe the consistency model as:

```text
Role assignment DB:
strongly consistent

Regional auth caches:
eventually consistent
with bounded staleness

Security-sensitive requests:
can force authoritative/version validation
```

That's a realistic tradeoff.

---

# 40. Bounded staleness

Suppose cache propagation SLO:

```text
99.99% of role revocations visible globally < 5 seconds
```

Then design and measure that explicitly.

Important metric:

```text
role_change_propagation_lag
```

Security consistency shouldn't just be "eventually consistent" with no bound.

---

# 41. Security-sensitive permissions

Not all permission checks need identical consistency.

Example:

```text
view public report
```

could tolerate cached state.

But:

```text
delete user
grant admin
transfer money
```

may require:

```text
authoritative authorization
```

or:

```text
freshness <= 1 second
```

This is a useful design tradeoff.

---

# 42. Failure mode: Authorization Service unavailable

What should application do?

For sensitive operations:

```text
FAIL CLOSED
```

No authorization response:

```text
DENY / 503
```

Never:

```text
authorization service unavailable
→ allow everyone
```

For non-sensitive cached reads, valid local policy/cache may continue within defined TTL.

---

# 43. Failure mode: Redis unavailable

Fall back:

```text
Authorization Service
    │
    ▼
DB / regional read replica
```

at reduced capacity.

Use:

- circuit breaker
- DB protection
- rate limiting

Don't allow millions of cache misses to overwhelm the database.

---

# 44. Failure mode: event bus delayed

Role change committed, but cache invalidation event is delayed.

Safety nets:

```text
short TTL
authz version
token lifetime
authoritative checks for sensitive actions
```

And alert on:

```text
event propagation lag
```

---

# 45. Concurrent role updates

Suppose two admins update U123.

Use optimistic locking/versioning.

Example:

```text
authz_version = 18
```

Admin A removes SUPPORT:

```text
WHERE version = 18
→ version 19
```

Admin B's stale update:

```text
WHERE version = 18
→ 0 rows
```

Return conflict:

```text
409
```

and reload current state.

---

# 46. Idempotency

Admin UI retries:

```text
Assign SUPPORT
```

because network response was lost.

Use:

```text
UNIQUE(user_id, role_id)
```

and idempotent PUT semantics.

Likewise role removal:

```text
DELETE existing
or already absent
→ success
```

This simplifies retries.

---

# 47. User deletion

I would be careful with actual deletion.

Security requirements often need historical auditability.

Flow:

```text
ACTIVE
   │
   ▼
DELETED
```

Then:

- Revoke sessions
- Remove role assignments
- Increment authz version
- Emit UserDeleted
- Remove/anonymize PII according to retention policy
- Keep necessary immutable audit records

Don't accidentally delete audit evidence.

---

# 48. Session/refresh token storage

Access JWT:

```text
stateless
short-lived
```

Refresh/session token:

```text
stateful
revocable
```

Store only secure token hashes where possible.

On suspension:

```text
revoke all refresh sessions
```

so no new access tokens can be minted.

---

# 49. Authentication HA

Identity service instances:

```text
stateless
```

behind a load balancer.

JWT signing keys managed in:

```text
KMS/HSM
```

and rotated.

Services verify via:

```text
JWKS/public keys
```

locally.

Avoid calling identity server merely to validate every JWT.

---

# 50. Key rotation

Token header:

```text
kid = key-42
```

Services cache:

```text
JWKS
```

Identity platform can:

```text
publish new key
start signing
retain old public key
wait for old tokens to expire
remove old key
```

This allows rotation without downtime.

---

# 51. Service-to-service authentication

Authorization isn't just for end users.

Internal service calls should also have workload identity:

```text
mTLS
SPIFFE/SPIRE
service JWT
cloud workload identity
```

Then authorization context might include:

```text
user principal
+
calling service principal
```

Example:

```text
User U123 via checkout-service
```

This prevents an arbitrary service from impersonating trusted callers.

---

# 52. Authorization request

Could look like:

```json
{
  "subject": "U123",
  "caller": "order-service",
  "permission": "order:refund",
  "resource": {
    "orderId": "O123"
  }
}
```

Even though core model is RBAC, carrying resource/caller context makes future evolution easier.

---

# 53. Why not hardcode authorization in API Gateway?

The gateway can handle coarse checks:

```text
authenticated?
basic scope?
```

But business authorization often belongs closer to the service.

Example:

```text
Can U123 refund this order?
```

The gateway may not know enough.

So:

```text
Gateway:
coarse enforcement

Service:
fine-grained authorization
```

using a shared SDK/policy service.

---

# 54. Query patterns

Common APIs:

```http
GET /users/{id}
POST /users
PATCH /users/{id}
DELETE /users/{id}

GET /users/{id}/roles
PUT /users/{id}/roles/{roleId}
DELETE /users/{id}/roles/{roleId}
```

Authorization:

```http
POST /authorize
```

```json
{
  "userId": "U123",
  "permission": "order:refund"
}
```

Response:

```json
{
  "allowed": true
}
```

---

# 55. Read scalability

User reads can use:

```text
primary
   │
   ▼
read replicas
```

plus cache.

Role definitions:

```text
very static
```

can be cached aggressively.

User-role assignments:

```text
cached with versioning/invalidation
```

Authorization path should not rely on expensive multi-table joins every request.

Precompute effective permissions.

---

# 56. Precomputed permission set

Instead of repeatedly:

```text
UserRole
JOIN RolePermission
JOIN Permission
```

for every authorization request, maintain:

```text
EffectivePermissionSet
```

Example cache:

```text
U123:v19

{
  user:read,
  ticket:update,
  report:view
}
```

Update when roles change.

This makes checks effectively:

```text
set.contains(permission)
```

---

# 57. Audit storage

Audit events are append-only.

Could use:

```text
Kafka
  │
  ▼
Immutable Object Storage / WORM
```

plus a searchable index for recent investigations.

Requirements:

- Tamper resistance
- Retention policy
- Encryption
- Restricted access

---

# 58. Security

I’d explicitly cover:

```text
TLS everywhere
encryption at rest
password hashing
KMS/HSM signing keys
RBAC admin separation
MFA for privileged accounts
rate limiting
credential stuffing protection
audit logs
least privilege
```

Administrative actions such as:

```text
grant ADMIN
```

may require stronger controls:

```text
MFA / step-up authentication
approval
```

depending on policy.

---

# 59. Sensitive user data

Separate:

```text
PII
```

from commonly accessed authorization data where possible.

For example:

```text
User Profile Store
    email / name / phone

Authorization Store
    user_id / status / roles
```

Authorization shouldn't need to fetch an email address merely to decide access.

This minimizes exposure.

---

# 60. Observability

Important metrics:

```text
authorization_requests/sec
allow_rate
deny_rate
authorization_latency
cache_hit_rate
cache_invalidation_lag
role_change_rate
token_refresh_failures
DB replication lag
event-bus lag
```

Security metrics:

```text
failed logins
suspensions
admin-role grants
unusual denied accesses
```

---

# 61. Authorization latency

Target might be:

```text
p99 < 20 ms
```

for remote authorization, while cached/local checks may be:

```text
<1 ms
```

This is why authorization caching matters so much.

---

# 62. Multi-region failure

Suppose:

```text
US region unavailable
```

EU/APAC should still perform authorization using:

```text
regional replicas
cached policy
JWT verification
```

But role mutation behavior needs a defined policy.

Options:

```text
Temporarily read-only for role mutations
```

or promote a standby writer using consensus/failover.

I’d prefer correctness over accepting conflicting privilege changes.

---

# 63. CAP-style tradeoff

During a network partition:

```text
Region A
   X
Region B
```

for authorization data we need to choose carefully.

For privileged mutations:

```text
favor consistency
```

Do not permit both sides to independently mutate security state if they cannot reconcile safely.

For cached authorization reads:

```text
favor availability within bounded freshness
```

depending on operation sensitivity.

This is a nuanced answer the interviewer will usually appreciate.

---

# 64. Final architecture

I’d finish with:

```text
                              CLIENTS
                                 │
                                 ▼
                          API Gateway
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
             Identity Service           User Service
                    │                         │
                    ▼                         ▼
               Token Service               User DB
                    │
                    ▼
             JWT / Refresh Token


                       AUTHORIZATION PATH

 Internal Service
       │
       ▼
 Authorization SDK
       │
       ├────────────► Local Cache
       │
       │ miss/stale
       ▼
 Authorization Service
       │
       ▼
 Distributed RBAC Cache
       │
       │ miss
       ▼
 RBAC DB
       │
       ├── Users/status
       ├── UserRole
       ├── Role
       └── RolePermission


                       CHANGE PROPAGATION

       RBAC Service
            │
            ▼
        DB Transaction
            │
            ├── Role change
            ├── Authz version++
            └── Outbox event
                    │
                    ▼
                  Kafka
                    │
          ┌─────────┼───────────────┐
          ▼         ▼               ▼
     Cache       Audit          Notification
   Invalidation  Service          Service
          │
          ▼
   Regional Caches
```

For multi-region:

```text
                       PRIMARY SECURITY STORE
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
              US Read         EU Read         APAC Read
              Replica         Replica          Replica
                │               │               │
                ▼               ▼               ▼
           US Auth Cache   EU Auth Cache   APAC Auth Cache
```

---

# How I’d summarize it in the interview

> I would separate authentication, user lifecycle, role management, and runtime authorization. User and role-assignment mutations are stored transactionally in a relational source of truth, while authorization is optimized for extremely high read volume using precomputed effective permission sets and regional caches. Services authenticate JWTs locally and use an authorization SDK to perform permission-based checks rather than hardcoding role names. Every security-state change increments an authorization version and publishes a durable event using the transactional outbox pattern. Those events invalidate regional caches, update audits, and trigger notifications. Short-lived access tokens, revocable refresh sessions, user-status checks, versioning, and cache invalidation limit stale authorization after role removal or suspension. In multi-region deployments, I would favor strongly ordered role mutations with replicated regional reads rather than casually allowing multi-master privilege updates. Sensitive operations can force fresh authorization while less sensitive reads can use bounded-staleness caches.

The areas I’d expect the interviewer to drill into most are:

```text
1. JWT roles vs centralized authorization
2. Cache invalidation after role removal
3. Token/session revocation
4. Multi-region consistency
5. Read-heavy authorization scaling
6. Transactional outbox / change propagation
7. Auditability
8. Fail-open vs fail-closed behavior
```

The architectural idea I’d emphasize most is:

```text
Strong source of truth for role changes
              ↓
Versioned change event
              ↓
Fast regional authorization caches
              ↓
Permission checks close to services
```

That gives you the balance this problem is really testing: **security correctness for writes and revocations, but very low latency and high availability for authorization reads.**
