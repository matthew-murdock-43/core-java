For this one, I’d frame the interview around **time-series ingestion, cardinality control, reliable alert evaluation, SLO-based alerting, and noise reduction**.

The core design principle is:

> Metrics are optimized for aggregated numerical signals over time, not arbitrary high-cardinality event data. The platform should make common reliability questions cheap to answer, while preventing poorly designed labels or alert rules from overwhelming the system or the on-call engineer.

A strong interview flow is:

1. Clarify requirements
2. Define metric model
3. Design collection and ingestion
4. Design time-series storage
5. Handle cardinality
6. Design query/dashboard path
7. Design alert evaluation
8. Reduce alert fatigue
9. Add SLO/error-budget alerting
10. Handle delayed or missing data

# 1. Clarify requirements

We need a platform where teams can publish metrics such as:

```text
http_requests_total
http_request_duration_seconds
cpu_usage
memory_usage
queue_depth
payment_success_rate
orders_created_total
```

Teams should be able to:

- Build dashboards
- Query historical metrics
- Aggregate by dimensions
- Define alerts
- Define SLIs/SLOs
- Route alerts to Slack/PagerDuty/email
- Silence or acknowledge alerts
- Monitor business and infrastructure health

I’d support standard metric types:

```text
Counter
Gauge
Histogram
Summary
```

For example:

```text
http_requests_total → Counter
active_connections   → Gauge
request_duration     → Histogram
```

---

# 2. Metric data model

A metric is not just:

```text
cpu = 70
```

It is a time series:

```text
metric_name
+
labels
+
timestamp
+
value
```

Example:

```text
http_requests_total{
  service="checkout",
  env="prod",
  status="500",
  region="us-west"
}
```

Each unique combination of labels creates a distinct time series.

That becomes extremely important for cardinality.

---

# 3. Scale assumptions

For discussion:

```text
5,000 services

100 metrics/service

10 instances/service average

15-second scrape interval
```

That alone can produce millions of active time series.

Suppose:

```text
10M active series
```

sampled every 15 seconds:

```text
~666K samples/sec
```

And that is before business metrics.

So the design needs:

- compression
- sharding
- aggregation
- cardinality limits
- retention tiers

---

# 4. High-level architecture

I’d draw this first:

```text
                         APPLICATIONS
                              │
                              ▼
                       Metrics SDK /
                     Prometheus Exporter
                              │
                              ▼
                    Collector / Scraper
                              │
                              ▼
                       Ingestion Layer
                              │
                              ▼
                       Time-Series DB
                              │
                 ┌────────────┴────────────┐
                 ▼                         ▼
           Query Service              Rule Engine
                 │                         │
                 ▼                         ▼
             Dashboards               Alert Manager
                                           │
                                  ┌────────┼────────┐
                                  ▼        ▼        ▼
                                Slack  PagerDuty  Email
```

At large scale:

```text
Collectors
    │
    ▼
Remote Write Gateway
    │
    ▼
Sharded Ingesters
    │
    ▼
Distributed TSDB
    │
    ├── Hot blocks
    └── Object storage
```

---

# 5. Pull vs push

I’d discuss both.

### Pull

Prometheus-style:

```text
Collector
   │
   │ GET /metrics
   ▼
Service
```

Advantages:

- Collector controls scrape interval
- Easy target health detection
- Natural service discovery
- Simple backpressure model

### Push

Useful for:

```text
short-lived batch jobs
serverless
business-event aggregation
```

via:

```text
SDK → metrics gateway
```

For an internal platform, I’d likely support both but standardize on pull or OTLP for normal services.

---

# 6. Collection

Collectors discover targets through:

```text
Kubernetes
service registry
VM inventory
cloud APIs
```

Example:

```text
payment-service
  pod A
  pod B
  pod C
```

Scrape every:

```text
15 seconds
```

Collectors attach infrastructure metadata:

```text
cluster
namespace
region
environment
service
```

But we need to carefully control labels.

---

# 7. Time-series storage

Metrics are append-heavy.

Typical access:

```text
service=checkout
last 1 hour
aggregate by status
```

So storage is optimized around:

```text
series identifier
+
time range
```

Conceptually:

```text
Series:
http_requests_total{service=checkout,status=500}

10:00  100
10:01  130
10:02  180
...
```

Use a TSDB architecture similar to:

```text
Prometheus
Mimir
Thanos
VictoriaMetrics
Cortex
```

---

# 8. Recent vs historical storage

Recent metrics:

```text
last hours/days
```

need fast local access.

Older blocks can move to object storage.

```text
Ingesters
   │
   ▼
Hot TSDB
   │
   ▼
Compaction
   │
   ▼
Object Storage
```

This reduces cost.

Example:

```text
Hot:
2 days local SSD

Historical:
13 months object storage
```

---

# 9. Compression

Time-series data compresses well.

Timestamps are regular:

```text
10:00:00
10:00:15
10:00:30
```

and values often change gradually.

Use:

```text
delta encoding
delta-of-delta timestamps
XOR floating-point compression
```

This can drastically reduce storage footprint.

---

# 10. High cardinality

This is probably the biggest follow-up.

Suppose someone creates:

```text
http_request_duration{
  request_id="UUID"
}
```

Every request creates a new series.

If:

```text
1M requests/min
```

then:

```text
1M new time series/min
```

This can destroy the TSDB.

So:

> Labels must represent bounded dimensions, not individual events.

---

# 11. Good labels vs bad labels

Good:

```text
service
environment
region
status
method
endpoint
```

Bounded cardinality.

Bad:

```text
request_id
user_id
session_id
email
timestamp
full URL
```

Those belong in:

```text
logs/traces
```

not metrics.

This distinction is critical.

---

# 12. Metric cardinality formula

Cardinality multiplies.

Suppose:

```text
service       = 100
region        = 5
endpoint      = 100
status        = 10
pod           = 50
```

Potential series:

```text
100 × 5 × 100 × 10 × 50
= 25M
```

So even individually reasonable labels can create huge cardinality when combined.

---

# 13. Cardinality controls

I’d implement controls at several layers:

```text
SDK linting
collector limits
ingestion limits
per-tenant quotas
```

Examples:

```text
max active series/team
max labels/metric
max label value length
max new series/sec
```

If Team A suddenly creates millions of series, it should not impact Team B.

---

# 14. Cardinality analysis

Provide dashboards showing:

```text
Top metrics by series count
Top labels by cardinality
Fastest-growing metrics
```

Example:

```text
metric                    series
http_requests_total       200K
business_event_total      4.2M
```

Then drill down:

```text
user_id caused 3.8M series
```

This makes cardinality problems discoverable.

---

# 15. Aggregation

Instead of:

```text
user_id
```

aggregate at source:

```text
orders_total{country="US"}
```

instead of:

```text
orders_total{user_id="123"}
```

If per-user debugging is needed:

```text
logs/traces
```

are a better fit.

---

# 16. Histograms

Latency should generally use histograms.

Example:

```text
http_request_duration_seconds_bucket{
  le="0.1"
}

le="0.5"
le="1"
le="5"
```

Then compute:

```text
p50
p95
p99
```

without storing every individual request latency.

That is a key scalability technique.

---

# 17. Query architecture

Query path:

```text
Grafana / UI
     │
     ▼
Query Frontend
     │
     ▼
Query Planner
     │
  ┌──┴──────────┐
  ▼             ▼
Hot Store   Historical Store
```

Large queries can be split by:

```text
time range
shard
tenant
```

and results merged.

---

# 18. Query caching

Common dashboards repeatedly execute:

```text
same query
every 30 sec
```

So cache results where possible.

For example:

```text
service error rate
last 1h
```

Older parts of that window are immutable.

Cache them.

This reduces backend load.

---

# 19. Recording rules

Some queries are expensive.

Example:

```text
sum(rate(http_requests_total[5m]))
by (service, region, status)
```

used by 50 dashboards.

Precompute:

```text
service:http_request_rate:5m
```

using recording rules.

This converts expensive repeated computation into a precomputed series.

---

# 20. Dashboards vs alerts

This is an explicit follow-up.

I’d say:

> Dashboards are for exploration and diagnosis. Alerts are for actionable conditions that require someone to do something.

Dashboard:

```text
CPU
latency
traffic
error rate
queue depth
```

Engineers look at it during investigation.

Alert:

```text
Checkout success rate < 99%
for 10 minutes
```

should mean:

> Someone needs to respond.

Not every interesting chart should have an alert.

---

# 21. Alert rule model

Example:

```text
AlertRule
---------
rule_id
tenant_id
expression
threshold
duration
severity
labels
annotations
routing_policy
```

Example:

```text
rate(http_requests_total{
  service="checkout",
  status=~"5.."
}[5m])
/
rate(http_requests_total{
  service="checkout"
}[5m])
> 0.05
```

for:

```text
10 minutes
```

---

# 22. Why `for` duration matters

Bad:

```text
CPU > 80%
→ PAGE
```

CPU briefly hits:

```text
81%
```

for 10 seconds.

Pager fires.

Then CPU returns to normal.

That's noisy.

Better:

```text
CPU > 90%
for 15 minutes
```

if sustained CPU actually matters.

The alert engine tracks:

```text
INACTIVE
PENDING
FIRING
```

---

# 23. Alert state machine

```text
NORMAL
   │
condition true
   ▼
PENDING
   │
   │ true for required duration
   ▼
FIRING
   │
condition clears
   ▼
RESOLVED
```

This prevents transient spikes from triggering pages.

---

# 24. Alert fatigue

Another major follow-up.

Use several techniques:

```text
actionability
deduplication
grouping
inhibition
silencing
severity
minimum duration
```

Golden rule:

> If no one would take action when an alert fires, it should probably not page.

---

# 25. Grouping

Suppose 200 pods fail because a database is down.

Bad:

```text
200 pages
```

Better:

```text
1 incident:
Database unavailable

Affected:
200 pods
```

Alert manager groups based on:

```text
service
cluster
root-cause dimension
alert type
```

---

# 26. Deduplication

Repeated evaluations:

```text
10:00 alert firing
10:01 alert firing
10:02 alert firing
```

should not create three incidents.

Use:

```text
alert fingerprint
```

based on:

```text
rule + relevant labels
```

Then maintain one alert lifecycle.

---

# 27. Inhibition

If:

```text
cluster_down
```

is firing, suppress lower-level alerts like:

```text
pod_unreachable
service_unreachable
node_metrics_missing
```

because they're consequences.

This dramatically reduces incident noise.

---

# 28. Silences

Users need:

```text
maintenance window
```

support.

Example:

```text
Silence:
service=payments
cluster=d1
until 04:00
```

Metrics are still collected.

Alerts are evaluated but notification delivery is suppressed.

Important for planned maintenance.

---

# 29. Severity levels

Example:

```text
SEV1 → Page immediately
SEV2 → Page during support hours
SEV3 → Slack
INFO → Dashboard only
```

Do not send every anomaly to PagerDuty.

Routing is part of the alert definition.

---

# 30. Static threshold vs symptom alert

Infrastructure threshold:

```text
CPU > 90%
```

may not mean customers are affected.

A stronger alert could be:

```text
checkout success rate < SLO
```

or:

```text
p99 latency > customer threshold
```

I’d prioritize alerts around **user-visible symptoms** where possible.

---

# 31. SLI

An SLI is the measured reliability indicator.

Example:

```text
successful requests
/
total requests
```

Suppose:

```text
SLI = 99.95%
```

for API availability.

Or latency SLI:

```text
requests under 500ms
/
total requests
```

---

# 32. SLO

An SLO defines the target.

Example:

```text
99.9% successful requests
over 30 days
```

Allowed error budget:

```text
100% - 99.9%
= 0.1%
```

For:

```text
1,000,000 requests
```

allowed failures:

```text
1,000
```

---

# 33. Error budget

Instead of paging on every tiny error spike, ask:

> Are we consuming the error budget too quickly?

Example:

```text
30-day SLO = 99.9%
```

Budget:

```text
43.2 minutes of unavailability/month
```

depending on definition.

If the service burns that budget rapidly, page.

---

# 34. Burn rate

Suppose allowed failure rate:

```text
0.1%
```

Actual failure rate:

```text
1%
```

Then burn rate:

```text
1% / 0.1% = 10×
```

We're consuming the monthly error budget ten times faster than sustainable.

This becomes a much more meaningful alert signal.

---

# 35. Multi-window burn-rate alerting

A good design uses multiple windows.

For example conceptually:

```text
Fast burn:
14× budget over 5m
AND
14× over 1h

Slow burn:
2× over 6h
AND
2× over 3d
```

The exact numbers should be tuned, but the concept is:

```text
fast severe outage
+
slow persistent degradation
```

both need detection.

---

# 36. Why multiple windows?

A 5-minute spike alone may be noise.

A 1-hour window alone may react too slowly.

Requiring both:

```text
short window
+
longer confirmation window
```

balances sensitivity and stability.

This is a strong interview answer.

---

# 37. SLO service

I might model:

```text
SLO
---
slo_id
service
sli_expression
target
window
owner
```

Example:

```text
service = checkout

SLI =
successful requests / all requests

target =
99.95%

window =
30 days
```

The platform periodically computes:

```text
current SLI
remaining budget
burn rate
```

---

# 38. Alert evaluation architecture

At moderate scale:

```text
Rule Scheduler
     │
     ▼
Rule Evaluators
     │
     ▼
TSDB Query
     │
     ▼
Alert State Store
     │
     ▼
Alert Manager
```

But thousands of rules every 15 seconds can create huge query load.

So shard rule evaluation by:

```text
tenant
rule group
```

and use recording rules for expensive calculations.

---

# 39. Rule groups

Rules with the same interval can be grouped.

Example:

```text
checkout.rules

evaluate every 30 sec
```

Containing:

```text
error rate
latency
availability
```

One scheduler assigns groups across evaluator instances.

Use leases/ownership to avoid duplicate evaluation.

---

# 40. High availability

Suppose one evaluator crashes.

Another instance takes ownership.

Alert state is persisted or reconstructible.

But duplicate evaluation can happen during failover.

So notification system should deduplicate using:

```text
alert fingerprint
```

rather than assuming evaluator exactly-once execution.

---

# 41. Alert Manager

The rule engine determines:

```text
ALERT FIRING
```

Alert Manager handles:

```text
dedupe
grouping
silencing
inhibition
routing
```

Architecture:

```text
Rule Engine
    │
    ▼
Alert Manager
    │
    ├── PagerDuty
    ├── Slack
    ├── Email
    └── Webhook
```

Keep those concerns separate.

---

# 42. Delayed metrics

Another explicit follow-up.

Suppose alert evaluates at:

```text
10:00
```

but some metrics from:

```text
09:59
```

arrive at:

```text
10:01
```

If we immediately evaluate, we might falsely alert.

Possible solution:

```text
evaluation_delay = 30–60 seconds
```

Evaluate slightly behind real time.

Tradeoff:

```text
more complete data
vs
slightly slower alert detection
```

---

# 43. Late samples

TSDB should accept samples within a reasonable out-of-order window where possible.

For example:

```text
timestamp = 10:00
arrives = 10:02
```

Could still be inserted.

But very old out-of-order data may be rejected or handled separately.

Important to bound complexity.

---

# 44. Missing metrics

A missing metric can mean:

```text
service is down
collector is down
network issue
metric removed
no traffic
```

Do not automatically treat missing as zero.

These are semantically different.

---

# 45. `absent()` alerts

For expected telemetry, define explicit missing-data alerts.

Example:

```text
absent(up{service="checkout"})
```

for:

```text
5 minutes
```

Then alert:

```text
No telemetry received from checkout
```

But distinguish this from:

```text
checkout error rate = 0
```

---

# 46. No-data state

Alert rules should support:

```text
OK
ALERTING
NO_DATA
ERROR
```

rather than collapsing everything into boolean.

For some rules:

```text
NO_DATA → alert
```

For others:

```text
NO_DATA → ignore
```

Policy depends on metric semantics.

---

# 47. Counter resets

Counters reset when processes restart.

Example:

```text
1000
1100
1200
10   <- restart
20
```

Query functions like:

```text
rate()
increase()
```

must detect resets.

Don't calculate raw subtraction naïvely.

---

# 48. Staleness

Suppose a pod disappears.

Its previous series must not remain active forever.

Mark time series stale after a period of no samples.

Otherwise dashboards might continue showing:

```text
cpu=40%
```

for a pod that no longer exists.

---

# 49. Business metrics

The platform shouldn't only collect infrastructure metrics.

Examples:

```text
orders_completed_total
payments_failed_total
active_subscriptions
checkout_conversion_rate
```

These can be some of the most useful alerts.

Example:

```text
Orders normally:
1000/min

Now:
5/min

Infrastructure:
all green
```

Business alert catches what CPU metrics won't.

---

# 50. Golden signals

For service reliability I’d encourage:

```text
Latency
Traffic
Errors
Saturation
```

Examples:

```text
request rate
5xx rate
p95/p99 latency
CPU/memory/thread pool saturation
```

These give teams sensible defaults.

---

# 51. RED method

For request-driven services:

```text
Rate
Errors
Duration
```

Very useful standard dashboard and alerts.

For resources, USE:

```text
Utilization
Saturation
Errors
```

This standardization makes platform adoption easier.

---

# 52. Tenant isolation

A large company needs quotas.

Per team:

```text
active series limit
samples/sec limit
query concurrency
rule count
retention
```

Example:

```text
Team A creates 20M accidental series
```

should be throttled without taking down Team B.

---

# 53. Query isolation

One user runs:

```text
sum(...)
over 13 months
across every service
```

That shouldn't slow production alert evaluation.

Separate:

```text
interactive dashboard queries
alert queries
batch/reporting queries
```

with different resource pools or priorities.

Alerting queries should get predictable capacity.

---

# 54. Retention

Different resolutions for different ages.

Example:

```text
0–7 days:
15-second resolution

7–30 days:
1-minute rollup

30–365 days:
5-minute rollup
```

Downsampling reduces cost dramatically.

For long-term capacity trends, 15-second granularity usually isn't needed.

---

# 55. Downsampling

Raw:

```text
15-second samples
```

can roll into:

```text
1-minute:
min
max
avg
sum
count
```

For histograms, preserve enough information to calculate needed quantiles correctly rather than averaging p99 values naïvely.

---

# 56. Observability for the metrics platform

The monitoring system needs monitoring too.

Track:

```text
samples ingested/sec
samples rejected
active series
cardinality growth
collector scrape failures
ingestion latency
query latency
rule evaluation latency
alert delivery latency
TSDB disk usage
compaction failures
```

Critical metric:

```text
metric freshness
```

How far behind real time is the platform?

---

# 57. Failure handling

If TSDB ingestion is temporarily unavailable:

```text
Collector
   │
   ▼
local buffer / queue
```

within limits.

For larger distributed architecture:

```text
Collectors
   │
   ▼
Kafka / durable remote-write buffer
   │
   ▼
Ingesters
```

could absorb temporary outages.

But metrics have different loss tolerance than business events, so complexity depends on requirements.

---

# 58. Final architecture

I’d finish with:

```text
                           SERVICES
                              │
                    Metrics SDK / Exporter
                              │
                              ▼
                      Collector / Scraper
                              │
                              ▼
                     Remote Write Gateway
                              │
                              ▼
                    Distributed Ingesters
                              │
                              ▼
                     Time-Series Storage
                              │
                ┌─────────────┴──────────────┐
                │                            │
                ▼                            ▼
          Query Frontend               Rule Evaluators
                │                            │
        ┌───────┴───────┐                    ▼
        ▼               ▼              Alert State Store
      Hot TSDB      Object Storage             │
        │                                      ▼
        ▼                                 Alert Manager
    Dashboards                                  │
                                   ┌───────────┼──────────┐
                                   ▼           ▼          ▼
                                PagerDuty    Slack       Email


                         SLO LAYER

                    Service / SLI Definition
                              │
                              ▼
                     Error Budget Engine
                              │
                              ▼
                       Burn-rate Rules
                              │
                              ▼
                         Alert Manager
```

# How I’d summarize it in the interview

> I would build the system around a distributed time-series store optimized for append-heavy metrics and time-range queries. Services expose or push structured metrics, collectors add bounded infrastructure metadata, and a horizontally scalable ingestion tier writes samples into the TSDB. The platform strictly controls label cardinality because every unique label combination creates a separate series; request IDs, user IDs, and other unbounded dimensions belong in logs or traces instead. Recent high-resolution data stays in hot storage, while older data is compacted, downsampled, and moved to object storage. Dashboards are intended for exploration and diagnosis, while alerts should represent actionable conditions. Alert evaluation is separated from notification routing, with stateful `PENDING/FIRING/RESOLVED` semantics, deduplication, grouping, inhibition, and silences to reduce alert fatigue. For reliability, I would support SLI/SLO definitions and multi-window burn-rate alerts so teams page on rapid error-budget consumption rather than arbitrary infrastructure thresholds. Missing or delayed metrics are treated explicitly as `NO_DATA` rather than silently interpreted as zero.

The areas I’d expect the interviewer to drill into most are **high-cardinality labels, time-series storage and retention, alert fatigue, SLO/error-budget alerting, missing data semantics, and alert evaluator scaling**.

The architectural idea I’d emphasize most is:

```text
Bounded metrics
     ↓
Time-series storage
     ↓
Fast aggregation/query
     ↓
Stateful rule evaluation
     ↓
Dedup / group / route alerts
```

with a strict rule that **high-cardinality event-level data belongs in logs or traces, not metric labels**.
