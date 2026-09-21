For this one, I’d frame the interview around **fanout, delivery guarantees, channel abstraction, retries, preferences, and provider isolation**.

The core design principle is:

> Treat a notification as a durable intent, then independently resolve user preferences, render the right channel template, route to a provider, and track delivery outcomes. The sending path should be asynchronous so provider slowness or outages do not block the application that triggered the notification.

A good interview flow is:

1. Clarify requirements
2. Model notifications, templates, preferences
3. Separate notification creation from delivery
4. Design fanout and queues
5. Handle retries/provider failover
6. Prevent duplicates
7. Support priority levels
8. Track delivery/open/failure events
9. Handle rate limits and noisy tenants
10. Cover security, observability, and cost

# 1. Clarify requirements

We need to support:

- Email
- Push
- SMS
- Slack
- In-app
- Potentially webhooks later

Typical use cases:

```text
Password reset
Order shipped
Payment failed
Marketing campaign
Security alert
System incident
Weekly digest
```

I’d distinguish:

```text
Transactional notifications
vs
Promotional notifications
```

because they have different rules around:

- priority
- retries
- user opt-out
- rate limits
- compliance

---

# 2. Non-functional requirements

Important requirements:

- High availability
- Asynchronous delivery
- At-least-once processing
- Low latency for urgent notifications
- User preference enforcement
- Provider failover
- Rate limiting
- Deduplication
- Auditable delivery status
- Multi-tenant isolation
- Scalability for large fanout

A key distinction:

```text
Notification accepted
!=
Notification delivered
```

The originating service only needs to know:

```text
notification request durably accepted
```

not whether the downstream SMS/email provider has completed delivery.

---

# 3. Core entities

## NotificationRequest

```text
NotificationRequest
-------------------
notification_id
tenant_id
event_type
recipient_id
template_id
priority
payload
idempotency_key
created_at
status
```

## NotificationDelivery

One notification may produce multiple channel deliveries:

```text
NotificationDelivery
--------------------
delivery_id
notification_id
channel
destination
provider
status
attempt_count
next_retry_at
provider_message_id
```

## Template

```text
Template
--------
template_id
event_type
channel
locale
version
subject
body
```

## UserPreference

```text
UserPreference
--------------
user_id
notification_type
channel
enabled
quiet_hours
frequency
```

---

# 4. High-level architecture

I’d draw this first:

```text
                       PRODUCER SERVICES
                              │
                              ▼
                       Notification API
                              │
                              ▼
                      Notification Store
                              │
                              ▼
                         Event Queue
                              │
                              ▼
                    Notification Orchestrator
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
      Preference Service  Template Service  User/Profile
             │                │                │
             └────────────────┼────────────────┘
                              ▼
                       Channel Router
                              │
          ┌───────────────────┼────────────────────┐
          ▼                   ▼                    ▼
       Email Queue          SMS Queue          Push Queue
          │                   │                    │
          ▼                   ▼                    ▼
      Email Worker         SMS Worker          Push Worker
          │                   │                    │
          ▼                   ▼                    ▼
       SendGrid            Twilio             FCM / APNs
```

And additionally:

```text
 Slack Queue ─► Slack Worker ─► Slack API
 In-App Queue ─► In-App Store / WebSocket
```

Provider callbacks:

```text
Providers
   │
   ▼
Webhook Receiver
   │
   ▼
Delivery Event Processor
   │
   ▼
Notification Status Store
```

---

# 5. Why asynchronous?

Bad:

```text
Order Service
    │
    ▼
Notification Service
    │
    ▼
Twilio
```

inside the user request.

If Twilio takes 8 seconds:

```text
order request waits 8 seconds
```

Bad coupling.

Better:

```text
Order Service
    │
    ▼
Notification API
    │
    ▼
durable queue
    │
    ▼
return 202 Accepted
```

Delivery happens independently.

---

# 6. API

For example:

```http
POST /notifications
```

```json
{
  "recipientId": "U123",
  "type": "ORDER_SHIPPED",
  "templateId": "order-shipped",
  "data": {
    "orderId": "O123",
    "trackingId": "T456"
  },
  "priority": "NORMAL",
  "idempotencyKey": "order-O123-shipped"
}
```

Response:

```json
{
  "notificationId": "N123",
  "status": "ACCEPTED"
}
```

---

# 7. Templates

This is one of the explicit follow-ups.

I would separate logical notification type from channel-specific rendering.

Example:

```text
ORDER_SHIPPED
```

may have:

```text
Email template
Push template
SMS template
Slack template
In-app template
```

Because channel constraints differ.

Example email:

```text
Subject:
Your order has shipped

Body:
Order {{orderId}} has shipped.
Track it here: {{trackingUrl}}
```

SMS:

```text
Order {{orderId}} shipped.
Track: {{shortUrl}}
```

Push:

```text
Title:
Order shipped

Body:
Tap to track order {{orderId}}
```

---

# 8. Template versioning

Templates should be versioned.

```text
order-shipped-email-v1
order-shipped-email-v2
```

Store which version produced each notification.

That helps answer:

```text
Why did this user receive this message?
```

Also enables:

- rollback
- A/B testing
- auditing

---

# 9. Localization

Templates can vary by:

```text
channel
locale
region
```

Example:

```text
template_id = password-reset
channel = EMAIL
locale = en-US
```

Fallback:

```text
fr-CA
  ↓
fr
  ↓
en-US
```

if appropriate.

---

# 10. User preferences

Model preferences at both global and notification-type level.

Example:

```text
User 123

Marketing:
  email = false
  SMS   = false
  push  = true

Security:
  email = true
  SMS   = true

Order updates:
  email = true
  push  = true
```

Important:

> Some mandatory transactional/security messages may override normal marketing preferences, subject to product/legal rules.

---

# 11. Preference resolution

The orchestrator receives:

```text
ORDER_SHIPPED
```

and resolves:

```text
User profile:
email = x@example.com
phone = ...
devices = [...]

Preferences:
email enabled
push enabled
SMS disabled
```

So create:

```text
Delivery 1 → Email
Delivery 2 → Push
```

No SMS delivery is created.

---

# 12. Quiet hours

Preferences may contain:

```text
quiet_hours:
22:00–07:00
```

For normal notification:

```text
schedule for 07:00
```

But high-priority security alert:

```text
bypass quiet hours
```

if policy allows.

So notification policy includes:

```text
can_bypass_quiet_hours
```

---

# 13. Frequency controls / digests

Suppose:

```text
20 comments arrive in 2 minutes
```

Don't necessarily send 20 emails.

Policy might say:

```text
COMMENT notification:
batch window = 5 minutes
```

Then send:

```text
"You have 20 new comments"
```

This reduces spam and provider cost.

---

# 14. Fanout

For one user, simple.

But suppose:

```text
Company announcement → 5M users
```

Don't create/send 5M notifications synchronously in one transaction.

Use fanout workers:

```text
Announcement
     │
     ▼
Audience Service
     │
     ▼
User IDs
     │
     ▼
Fanout Queue
     │
   workers
     │
     ▼
individual NotificationRequests
```

---

# 15. Large fanout architecture

```text
Campaign / Event
      │
      ▼
Audience Resolver
      │
      ▼
Partition recipients
      │
      ├── batch 1
      ├── batch 2
      ├── batch 3
      └── ...
             │
             ▼
       Fanout Workers
             │
             ▼
      Channel Queues
```

This gives horizontal scalability.

---

# 16. Per-channel queues

I would strongly separate them.

```text
email.queue
sms.queue
push.queue
slack.queue
inapp.queue
```

Why?

If SMS provider is down:

```text
SMS backlog increases
```

but:

```text
email/push still flow normally
```

This gives failure isolation.

---

# 17. Provider abstraction

For email:

```text
Email Provider Adapter
    ├── SendGrid
    ├── SES
    └── Mailgun
```

For SMS:

```text
SMS Adapter
    ├── Twilio
    └── Provider B
```

Workers call a provider interface:

```text
send(message)
```

rather than provider-specific code everywhere.

---

# 18. Retry handling

If provider returns:

```text
HTTP 503
timeout
connection error
```

retry.

Use exponential backoff + jitter.

Example:

```text
10s
30s
2m
10m
30m
```

with randomized jitter.

Do not immediately hammer the failed provider.

---

# 19. Retry classification

Not every error should retry.

Retryable:

```text
429 rate limited
503 unavailable
network timeout
```

Non-retryable:

```text
invalid phone number
invalid email syntax
recipient permanently unsubscribed
invalid template payload
```

Classify provider responses:

```text
TRANSIENT
PERMANENT
```

---

# 20. Provider failover

Another main follow-up.

Suppose:

```text
Twilio unhealthy
```

The SMS router can use:

```text
Provider A → primary
Provider B → secondary
```

Flow:

```text
SMS Worker
   │
   ▼
Provider Router
   │
   ├── healthy A → use A
   └── unhealthy A → B
```

Use:

- health checks
- circuit breakers
- error-rate thresholds
- latency thresholds

---

# 21. Circuit breaker

If provider starts failing:

```text
50 failures
51 failures
52 failures
```

don't keep sending all traffic.

State:

```text
CLOSED
  ↓
OPEN
  ↓
HALF_OPEN
```

While OPEN:

```text
route to secondary provider
```

This prevents cascading latency.

---

# 22. Provider selection

Could consider:

```text
availability
cost
region
latency
delivery success rate
channel support
```

Example:

```text
SMS India → Provider A
SMS US    → Provider B
```

This can optimize both reliability and cost.

---

# 23. Preventing duplicate notifications

This is another explicit follow-up.

Suppose Order Service times out after:

```text
POST /notifications
```

and retries.

Without protection:

```text
2 emails
```

Use idempotency key.

For example:

```text
order-O123-shipped-user-U123
```

DB unique constraint:

```text
UNIQUE(tenant_id, idempotency_key)
```

Second request returns existing notification instead of creating another.

---

# 24. Duplicate delivery is harder

Suppose:

```text
Worker sends SMS
Provider accepts it
Worker crashes before marking success
```

Queue redelivers.

Worker sends again.

Potential duplicate.

So use provider idempotency if available:

```text
provider_request_id = delivery_id
```

If provider supports deduplication, great.

If not, delivery is fundamentally at-least-once and duplicates are possible in rare ambiguous cases.

I would be explicit:

> Exactly-once external delivery cannot generally be guaranteed unless the downstream provider participates in idempotency.

---

# 25. Delivery state machine

I'd model delivery states explicitly.

```text
PENDING
   │
   ▼
QUEUED
   │
   ▼
SENDING
   │
   ├──► SENT
   │        │
   │        ▼
   │    DELIVERED
   │
   └──► FAILED
            │
            ▼
        RETRY_WAIT
```

Terminal states:

```text
DELIVERED
FAILED_PERMANENT
CANCELLED
```

---

# 26. Sent vs delivered

Important distinction.

```text
SENT
```

means:

```text
provider accepted request
```

Not necessarily recipient received it.

Example:

```text
SMS provider accepted
```

later callback:

```text
DELIVERED
```

or:

```text
UNDELIVERABLE
```

---

# 27. Tracking provider callbacks

Providers often send webhooks.

Example:

```text
Twilio
   │
   ▼
POST /provider-events/twilio
```

Webhook might say:

```text
message_id = abc
status = delivered
```

Map:

```text
provider_message_id
    ↓
delivery_id
```

Then update status.

---

# 28. Email events

Email providers may provide:

```text
accepted
delivered
bounced
opened
clicked
spam complaint
```

Pipeline:

```text
Provider Webhook
      │
      ▼
Webhook Receiver
      │
      ▼
Event Queue
      │
      ▼
Delivery Event Processor
      │
      ▼
Status / Analytics Store
```

---

# 29. Open tracking

Email open tracking usually uses a tracking pixel.

```text
<img src="/track/open/{deliveryId}">
```

When requested:

```text
OPENED
```

But I would mention:

> Open metrics are not perfectly reliable because mail clients can block or pre-fetch tracking pixels.

So treat:

```text
OPENED
```

as an approximate engagement signal.

---

# 30. Click tracking

Links can route through:

```text
tracking.example.com/c/{token}
```

Then:

```text
Click Service
    │
    ├── record click
    └── redirect user
```

Useful for:

- engagement analytics
- campaign metrics

But for security-sensitive links like password reset, tracking behavior must be designed carefully.

---

# 31. Push notifications

Push path:

```text
Push Worker
   │
   ├── APNs
   └── FCM
```

A user may have:

```text
iPhone
Android tablet
```

So:

```text
User → multiple device tokens
```

Potentially one logical notification fans out to multiple device deliveries.

---

# 32. Invalid device tokens

APNs/FCM can say:

```text
token invalid
```

Then:

```text
mark device token inactive
```

Otherwise we waste resources retrying permanently invalid endpoints.

---

# 33. In-app notifications

This is different because we control storage.

Write to:

```text
InAppNotification
-----------------
user_id
notification_id
read
created_at
```

Then:

```text
GET /notifications
```

returns user's notification center.

For live updates:

```text
WebSocket / SSE
```

can immediately push new notifications.

---

# 34. Priority levels

Another explicit follow-up.

Define:

```text
CRITICAL
HIGH
NORMAL
LOW
```

Examples:

```text
CRITICAL → suspicious login / security incident
HIGH     → payment failure
NORMAL   → order shipped
LOW      → weekly recommendations
```

---

# 35. Priority queues

Could use:

```text
critical.queue
high.queue
normal.queue
low.queue
```

Workers consume with weighted priority.

For example:

```text
10 critical
5 high
3 normal
1 low
```

rather than strict priority starvation.

Otherwise continuous CRITICAL traffic might prevent LOW messages forever.

---

# 36. Priority also affects retry policy

Example:

```text
CRITICAL:
retry aggressively
provider failover immediately

LOW:
retry less aggressively
expire after a few hours
```

And maybe:

```text
CRITICAL
```

can bypass quiet hours.

---

# 37. Expiration / TTL

Some notifications become useless.

Example:

```text
OTP code:
TTL = 5 minutes
```

No point retrying after 20 minutes.

Notification request should include:

```text
expires_at
```

Workers check:

```text
now > expires_at
→ discard as EXPIRED
```

Very important for time-sensitive messages.

---

# 38. Scheduled notifications

Support:

```text
send_at
```

Example:

```text
send weekly report Monday 9 AM
```

Use:

```text
Scheduled Notification Store
       │
       ▼
Scheduler
       │
       ▼
Queue
```

Do not keep delayed jobs in application memory.

---

# 39. Rate limiting

Need multiple limits:

```text
per tenant
per user
per channel
per provider
```

Examples:

```text
Max 3 marketing SMS/day/user
Max 100 emails/sec/tenant
Provider max 10K SMS/sec
```

This protects:

- users
- providers
- costs
- system stability

---

# 40. Noisy tenant isolation

Suppose Team A launches:

```text
10M email campaign
```

Team B's password resets should still go immediately.

Use:

```text
tenant quotas
priority queues
separate channel workers
weighted scheduling
```

Potentially separate pools for:

```text
transactional
bulk/promotional
```

---

# 41. Transactional vs bulk pipelines

This is a useful design improvement.

```text
Transactional Queue
   │
   ▼
fast/high-priority workers
```

and:

```text
Bulk Campaign Queue
   │
   ▼
rate-controlled workers
```

Then a huge campaign doesn't delay:

```text
password reset
```

---

# 42. Backpressure

Suppose provider handles:

```text
5K messages/sec
```

but queue receives:

```text
20K/sec
```

Backlog grows.

We should:

- queue
- autoscale workers
- respect provider quotas
- monitor queue age
- reject/throttle bulk producers if needed

Important metric:

```text
oldest_message_age
```

Often more useful than queue depth alone.

---

# 43. Dead-letter queue

After retries exhausted:

```text
email.delivery.dlq
sms.delivery.dlq
```

Store:

```text
notification ID
delivery ID
channel
provider
attempt count
last error
payload reference
```

Operators can:

```text
inspect
retry
discard
```

---

# 44. Monitoring

Platform metrics:

```text
notifications accepted/sec
deliveries/sec
queue depth
queue age
success rate
retry rate
DLQ count
provider latency
provider error rate
```

By:

```text
channel
provider
tenant
notification type
priority
```

---

# 45. Delivery metrics

Useful metrics:

```text
accepted
sent
delivered
bounced
failed
opened
clicked
```

For example:

```text
Email:
sent       1M
delivered  980K
opened     410K
clicked    75K
```

Again, open rate is approximate.

---

# 46. Provider dashboards

Track per provider:

```text
success rate
p95 latency
429 rate
5xx rate
cost/message
```

This feeds provider routing decisions.

---

# 47. Observability per notification

For notification `N123`, engineer should see:

```text
N123
Type: PAYMENT_FAILED
User: U42

Email:
  queued 10:00:00
  provider SendGrid
  sent 10:00:01
  delivered 10:00:03

Push:
  provider FCM
  sent 10:00:01
  failed INVALID_TOKEN
```

This is crucial for debugging.

---

# 48. Correlation IDs

Notification request should carry:

```text
event_id
correlation_id
trace_id
```

Suppose:

```text
OrderCreated
    │
    ▼
Notification
```

engineer can trace:

```text
business event
→ notification request
→ channel delivery
→ provider response
```

---

# 49. Security

Destinations are sensitive:

```text
email
phone
push token
Slack webhook
```

Protect with:

- encryption at rest
- strict RBAC
- secret management
- masking in logs

Don't log:

```text
full phone number
auth tokens
private webhook URLs
```

---

# 50. Template security

Templates are effectively user-facing code/config.

Require:

- validation
- versioning
- approvals for sensitive notifications
- escaping of injected variables

For HTML email:

```text
{{userInput}}
```

must be escaped to prevent injection.

---

# 51. Provider credentials

Use secret manager.

Workers obtain:

```text
provider API credential
```

through workload identity / secure secret injection.

Never hardcode provider credentials in config or source code.

---

# 52. Data retention

Different records have different retention needs.

Example:

```text
delivery history:
90 days

audit/security notifications:
1 year

raw provider webhook payload:
7 days
```

Avoid storing full rendered message body indefinitely if it contains sensitive data.

---

# 53. Failure scenario

Suppose notification persisted, but publishing to queue fails.

Use transactional outbox:

```text
BEGIN

INSERT notification
INSERT outbox_event

COMMIT
```

Then:

```text
Outbox Publisher
      │
      ▼
Queue
```

Prevents:

```text
DB says notification exists
but nobody ever delivers it
```

---

# 54. Final architecture

I’d finish with something like this:

```text
                       PRODUCER SERVICES
                              │
                              ▼
                       Notification API
                              │
                              ▼
                    Notification Metadata DB
                              │
                              ▼
                       Transactional Outbox
                              │
                              ▼
                         Event Queue
                              │
                              ▼
                    Notification Orchestrator
                              │
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
       Preference Service Template Service  User/Profile
             │                │                │
             └────────────────┼────────────────┘
                              ▼
                         Channel Router
                              │
      ┌───────────────┬───────┼────────┬─────────────┐
      ▼               ▼       ▼        ▼             ▼
   Email Q          SMS Q   Push Q   Slack Q       In-App Q
      │               │       │        │             │
      ▼               ▼       ▼        ▼             ▼
 Email Worker      SMS Worker Push W  Slack W       InApp W
      │               │       │        │             │
      ▼               ▼       ▼        ▼             ▼
 Provider Router Provider    APNs/   Slack API   Notification DB
      │           Router      FCM
  ┌───┴───┐
  ▼       ▼
SendGrid SES


                   DELIVERY EVENTS

Providers
   │
   ▼
Webhook Receiver
   │
   ▼
Delivery Event Queue
   │
   ▼
Status Processor
   │
   ├── Notification DB
   ├── Analytics
   └── Metrics
```

# How I’d summarize it in the interview

> I would model a notification as a durable intent and separate it from per-channel delivery attempts. Producer services submit a notification request with an idempotency key, priority, payload, and logical notification type. The platform persists it, then asynchronously resolves user preferences, templates, locale, and available destinations before creating channel-specific delivery records. Email, SMS, push, Slack, and in-app each have isolated queues and workers so a provider outage in one channel does not affect the others. Delivery uses at-least-once processing with stable delivery IDs and provider idempotency where supported. Transient failures use exponential backoff with jitter, while permanent failures stop immediately and exhausted retries go to a DLQ. Provider routing uses health, quotas, region, and cost, with circuit breakers and failover. Priority queues separate urgent transactional messages from bulk traffic, and provider callbacks feed delivery, bounce, open, and click events into the status pipeline.

The areas I’d expect the interviewer to drill into most are **user preferences and templates, idempotency/deduplication, provider retries/failover, priority isolation, fanout, and delivery-event tracking**.

The backbone of the design is:

```text
Durable notification intent
          ↓
Preference + template resolution
          ↓
Channel-specific queues
          ↓
Provider adapters
          ↓
Delivery callbacks / status
```

That separation is what makes the system reliable, scalable, and easy to extend with new channels.
