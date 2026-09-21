For this one, I’d frame the interview around a classic **two-stage recommender architecture**:

> **Candidate generation** narrows millions of items to hundreds, then **ranking** scores those candidates using richer user, item, and context features.

The important thing to show is that you would **not score every item for every request**.

A good interview flow is:

1. Clarify requirements
2. Define signals/events
3. Build the feature pipeline
4. Generate candidates
5. Rank candidates
6. Re-rank for diversity/freshness/business constraints
7. Handle cold start
8. Evaluate offline and online
9. Discuss feedback loops, scale, and reliability

---

# 1. Clarify requirements

We need a system that recommends things such as:

- Products
- Listings
- Videos
- Articles
- Music
- Posts

Typical surfaces:

```text
Home feed
"Recommended for you"
"Because you viewed..."
"Similar products"
"You may also like"
"Continue watching"
```

I’d ask whether the main objective is:

```text
clicks
purchases
watch time
revenue
retention
engagement
```

because the ranking target changes depending on the product.

For an e-commerce example, maybe we care about:

```text
CTR
+
purchase probability
+
expected revenue
```

---

# 2. Non-functional requirements

Important requirements:

- Low recommendation latency
- Personalized results
- High availability
- Support millions/billions of items
- Fresh recommendations
- Avoid stale inventory/content
- Ability to incorporate real-time behavior
- Explainability/debuggability
- Experimentation/A-B testing
- Cost efficiency

Typical serving latency target might be:

```text
<100–200 ms
```

depending on the surface.

---

# 3. Scale assumptions

For example:

```text
100M users

10M active users/day

100M products/items

100K recommendation requests/sec peak

1B behavioral events/day
```

You immediately get:

```text
100M users × 100M items
```

so scoring all items online is impossible.

Hence:

```text
Candidate generation
        ↓
Ranking
```

---

# 4. High-level architecture

I’d draw something like this:

```text
                         CLIENT
                           │
                           ▼
                    Recommendation API
                           │
                           ▼
                    Candidate Generator
                           │
          ┌────────────────┼───────────────────┐
          │                │                   │
          ▼                ▼                   ▼
 Collaborative         Content-based         Trending /
 Filtering              Retrieval             Popular
          │                │                   │
          └────────────────┴───────────────────┘
                           │
                           ▼
                    Candidate Merge
                           │
                           ▼
                    Ranking Service
                           │
                           ▼
                      Re-ranker
                           │
                 ┌─────────┼─────────┐
                 │         │         │
                 ▼         ▼         ▼
             Diversity  Freshness  Business
                                   Constraints
                           │
                           ▼
                      Final Results
```

Offline side:

```text
User Events
   │
   ▼
 Kafka / Event Stream
   │
   ├── Real-time Features
   │
   └── Data Lake / Warehouse
              │
              ▼
        Feature Engineering
              │
              ▼
         Model Training
              │
              ▼
        Model Registry
              │
              ▼
        Serving Models
```

---

# 5. What signals do we collect?

This is the first big follow-up.

I’d divide them into:

## User signals

Explicit:

```text
likes
ratings
favorites
follows
subscriptions
```

Implicit:

```text
views
clicks
searches
watch time
dwell time
cart additions
purchases
skips
scroll behavior
```

Negative signals matter too:

```text
not interested
hide
unfollow
return/refund
quick bounce
```

---

# 6. User history

Recent behavior often matters more than behavior from six months ago.

Example:

```text
Long-term:
mostly electronics

Last 30 minutes:
viewing hiking shoes
```

The session intent could dominate.

So features might include:

```text
last 10 viewed items
categories viewed in last hour
30-day purchase history
lifetime preferences
average price range
preferred brands
```

---

# 7. Contextual signals

Recommendation depends on context too:

```text
time of day
day of week
device
location/region
current page
session
referrer
language
```

Example:

```text
User on product page:
Sony Headphones
```

Candidate generation should heavily weight related audio products.

Whereas on home page:

```text
broader personalization
```

makes sense.

---

# 8. Item signals

For products:

```text
category
brand
price
description
attributes
seller
rating
popularity
inventory
discount
age/freshness
```

For videos:

```text
title
description
creator
topic
duration
language
embedding
```

We can create an:

```text
item embedding
```

from these features.

---

# 9. Interaction events

All behavioral events go through an event pipeline.

Example:

```text
User
 │
 ├── VIEW
 ├── CLICK
 ├── CART
 ├── PURCHASE
 └── LIKE
       │
       ▼
  Event Collector
       │
       ▼
      Kafka
       │
   ┌───┴───────────┐
   ▼               ▼
Real-time        Data Lake
Features           │
                   ▼
             Model Training
```

Each event:

```text
user_id
item_id
event_type
timestamp
session_id
context
```

---

# 10. Candidate generation

This is the next major follow-up.

Suppose we have:

```text
100M items
```

Ranking model cannot score all of them.

Candidate generation might reduce:

```text
100M
 ↓
2,000 candidates
```

using several strategies.

---

# 11. Collaborative filtering

Core intuition:

> Users who behaved similarly may like similar items.

Example:

```text
User A:
Laptop
Keyboard
Mouse

User B:
Laptop
Keyboard
???
```

Recommend:

```text
Mouse
```

Classic approaches include:

```text
matrix factorization
user-user similarity
item-item similarity
```

Modern systems often learn:

```text
user embedding
item embedding
```

and retrieve nearby items.

---

# 12. Two-tower model

A very common architecture.

```text
User Features
      │
      ▼
  User Tower
      │
      ▼
 User Vector

Item Features
      │
      ▼
  Item Tower
      │
      ▼
 Item Vector
```

Train so that:

```text
purchased/clicked items
```

are close to the user embedding.

At serving time:

```text
User embedding
      │
      ▼
ANN Vector Search
      │
      ▼
Top 500 items
```

Use something like an approximate nearest-neighbor index.

This is extremely scalable.

---

# 13. Content-based retrieval

Useful especially for:

```text
new items
similar-items recommendations
```

If user likes:

```text
Sony noise-cancelling headphones
```

retrieve items whose embeddings/metadata are similar.

Signals:

```text
category
brand
description
image embedding
price
attributes
```

This also helps cold start.

---

# 14. Multiple candidate sources

Production systems usually don't have just one candidate generator.

Example:

```text
Collaborative filtering       500
Content similarity            300
Recent session interests      300
Trending                      200
Previously viewed             100
New items                     100
```

Merge:

```text
~1500 candidates
```

then deduplicate.

Different sources provide different types of relevance.

---

# 15. Candidate generation architecture

```text
                   Candidate Service
                         │
        ┌────────────────┼─────────────────┐
        │                │                 │
        ▼                ▼                 ▼
   User-Item ANN     Similar Item      Trending
        │                │                 │
        ▼                ▼                 ▼
      500              500               200
        │                │                 │
        └────────────────┴─────────────────┘
                         │
                         ▼
                   Merge / Dedup
                         │
                         ▼
                    1K–2K items
```

---

# 16. Ranking

Candidate generation is optimized for:

```text
recall
```

Ranking is optimized for:

```text
precision
```

For every candidate, construct features.

Example:

```text
User features
Item features
User-item features
Context
```

Then:

```text
score = ranking_model(features)
```

---

# 17. User-item interaction features

Some particularly useful features:

```text
user category affinity
user brand affinity
user price preference
similarity(user_embedding, item_embedding)
time since user last saw item
number of similar items purchased
```

Example:

```text
User prefers:
Nike
running shoes
$100–150

Candidate:
Nike running shoe
$120
```

strong match.

---

# 18. Ranking model

Could start with:

```text
logistic regression
gradient boosted trees
```

and later move to:

```text
deep ranking model
learning-to-rank
transformer-based model
```

The output might predict:

```text
P(click)
P(add_to_cart)
P(purchase)
```

Then combine:

```text
score =
0.2 * P(click)
+ 0.3 * P(cart)
+ 0.5 * P(purchase)
```

Weights depend on business objective.

---

# 19. Multi-objective ranking

A more commercial objective may be:

```text
expected_value =
P(purchase)
× item_margin
```

But ranking only by margin would damage user relevance.

So usually:

```text
relevance
+
business value
+
user experience constraints
```

are balanced.

---

# 20. Re-ranking

After the ML ranking model, I would add a separate re-ranking stage.

Why?

The highest-scoring list might look like:

```text
Nike shoe
Nike shoe
Nike shoe
Nike shoe
Nike shoe
```

Relevant, but boring.

So:

```text
Ranker
  │
  ▼
Top 100
  │
  ▼
Re-ranker
```

applies:

- Diversity
- Freshness
- Inventory
- Policy
- Deduplication
- Business constraints

---

# 21. Diversity

You don't want the entire page to consist of nearly identical items.

Possible strategy:

```text
penalize similarity to already selected items
```

For example:

```text
Select item 1

For item 2:
score =
relevance
-
λ × similarity(item1,item2)
```

This resembles Maximum Marginal Relevance.

Could diversify across:

```text
brand
category
creator
price
topic
```

depending on domain.

---

# 22. Freshness

If recommendations only optimize historical engagement:

```text
old popular items
```

can dominate indefinitely.

Add freshness.

For example:

```text
final_score =
ranking_score
+
α × freshness_score
```

or guarantee:

```text
at least N fresh items
```

in top results.

Again, domain dependent.

---

# 23. Business constraints

For e-commerce:

```text
out of stock
→ remove
```

Other examples:

```text
seller blocked
restricted region
age restricted
price unavailable
policy violation
```

These are hard filters.

Then softer constraints:

```text
sponsored products
promotions
high-margin products
```

should be blended carefully.

---

# 24. Hard vs soft constraints

I’d distinguish:

### Hard

```text
out of stock
not available in country
blocked item
user already purchased and doesn't need repeat
```

Remove candidate.

### Soft

```text
freshness
margin
seller fairness
inventory pressure
```

Adjust score.

This makes architecture cleaner.

---

# 25. Cold-start users

Another major follow-up.

A brand-new user has no history.

Use:

```text
popular items
trending items
region
language
device
time
```

Then ask for preferences if product supports onboarding:

```text
What categories interest you?
```

As soon as behavior appears:

```text
first clicks
first searches
first views
```

switch toward session-based personalization.

---

# 26. Session-based recommendations

A new user may already produce useful signals within seconds.

Example:

```text
search: running shoes
view: Nike Pegasus
view: Adidas Ultraboost
```

Even with no account history, the session embedding tells us:

```text
running / sports footwear
```

So session personalization reduces cold-start significantly.

---

# 27. Cold-start items

New items have:

```text
no clicks
no purchases
```

So collaborative filtering can't help much.

Use content features:

```text
title
description
category
image
brand
creator
```

Generate item embeddings and recommend them to relevant users.

Also reserve controlled exploration:

```text
1–5% slots
```

for new items.

Otherwise:

```text
new item has no engagement
→ never recommended
→ never gains engagement
```

a self-reinforcing problem.

---

# 28. Exploration vs exploitation

Another useful point.

### Exploitation

Recommend items we're confident the user likes.

### Exploration

Try less-certain/new items to learn preferences.

Can use:

```text
multi-armed bandits
epsilon-greedy
Thompson sampling
UCB
```

depending on sophistication.

Conceptually:

```text
95% known good
5% exploration
```

Exact numbers are product-specific.

---

# 29. Feedback loops

Recommendations influence what data we collect.

If the system keeps recommending only brand A:

```text
user clicks brand A
```

because that's all we showed.

Then model concludes:

```text
user loves brand A
```

This creates feedback loops.

Mitigations:

- Exploration
- Randomized experiments
- Propensity logging
- Diversity constraints
- Offline counterfactual evaluation

---

# 30. Online feature store

The ranking service needs features quickly.

Examples:

```text
recent clicks
recent searches
session categories
current cart
last viewed item
```

Keep real-time features in:

```text
Online Feature Store
```

Maybe backed by:

```text
Redis
Cassandra
DynamoDB
```

depending on scale.

Latency should be low.

---

# 31. Offline feature store

Training needs the same feature definitions.

Store historical:

```text
purchase history
category affinity
90-day engagement
item popularity
```

in an offline feature store/data lake.

Important:

```text
training features
≈
serving features
```

to avoid training-serving skew.

---

# 32. Real-time vs batch

Some features update daily:

```text
lifetime purchases
long-term interests
```

Some update within seconds:

```text
user just searched "PS5"
```

So combine:

```text
batch features
+
streaming features
```

Architecture:

```text
Kafka
 │
 ▼
Stream Processing
 │
 ▼
Online Feature Store
```

while:

```text
Data Lake
 │
 ▼
Batch Pipeline
 │
 ▼
Offline Feature Store
```

---

# 33. Model training pipeline

```text
Events + Catalog
      │
      ▼
 Data Lake
      │
      ▼
Feature Engineering
      │
      ▼
Training Dataset
      │
      ▼
Candidate Model
      +
Ranking Model
      │
      ▼
Offline Evaluation
      │
      ▼
Model Registry
      │
      ▼
Canary / A-B test
```

Models should be versioned.

---

# 34. Negative examples

Training needs both positive and negative examples.

Positive:

```text
clicked
purchased
watched
liked
```

Negative might be:

```text
shown but ignored
quick bounce
explicit dislike
```

Be careful:

```text
not clicked
```

is not always equivalent to dislike.

Maybe the user simply didn't scroll far enough.

So impression logging matters.

---

# 35. Impression logging

Every recommendation response should log:

```text
request_id
user_id
items_shown
position
model_version
scores
candidate_source
```

Then downstream:

```text
click
purchase
watch
```

can be attributed to what was actually shown.

Without impression logs, evaluation is weak.

---

# 36. Offline evaluation

For candidate generation:

```text
Recall@K
HitRate@K
```

Question:

> Did the purchased/liked item appear among the candidates?

For ranking:

```text
Precision@K
Recall@K
NDCG@K
MAP
MRR
```

depending on use case.

NDCG is useful because position matters.

---

# 37. Ranking example

Suppose ground truth:

```text
user eventually purchased item X
```

If X appears:

```text
rank 1
```

great.

At:

```text
rank 200
```

not useful if UI only shows 20 items.

Hence ranking metrics.

---

# 38. Online evaluation

Offline metrics aren't enough.

Ultimately A/B test.

Example:

```text
Control:
ranking-model-v12

Treatment:
ranking-model-v13
```

Measure:

```text
CTR
conversion
revenue/session
watch time
retention
add-to-cart
```

plus guardrails:

```text
latency
returns
complaints
diversity
user hides
```

---

# 39. Don't optimize only CTR

Clickbait can maximize CTR.

For video:

```text
high CTR
low watch time
```

is bad.

For e-commerce:

```text
high clicks
low conversion
high returns
```

also bad.

So success metric should match actual product value.

Maybe:

```text
expected purchase probability
```

rather than click.

---

# 40. Long-term metrics

Short-term recommendation gains can hurt retention.

Monitor:

```text
7-day retention
30-day retention
repeat purchases
session frequency
content diversity
```

A recommender that gets one extra click today but makes the feed repetitive may hurt long-term engagement.

---

# 41. Freshness of models

Retrain models periodically:

```text
daily
hourly
weekly
```

depending on scale.

Item embeddings may update when metadata changes.

User embeddings may update more frequently.

Could also maintain:

```text
real-time session embeddings
```

independently of full retraining.

---

# 42. Popularity bias

Collaborative filtering tends to favor already popular items.

Possible mitigation:

```text
down-weight popularity
exploration budget
category quotas
new-item boosts
```

Otherwise niche items rarely get exposure.

---

# 43. Inventory awareness

For e-commerce, ranking must use real-time inventory.

Bad:

```text
model recommends product
user clicks
OUT OF STOCK
```

So final filtering:

```text
Recommendation
       │
       ▼
Inventory check
       │
       ├── in stock → keep
       └── no stock → remove
```

Could use cached inventory for performance with careful TTLs.

---

# 44. Price/promotion changes

Likewise, catalog features can become stale.

Product updates:

```text
PriceChanged
InventoryChanged
ProductUpdated
```

flow through Kafka:

```text
Catalog
  │
  ▼
Kafka
  │
  ├── Feature Store
  └── Recommendation Index
```

This keeps serving reasonably fresh.

---

# 45. ANN serving

For candidate generation, store item vectors in an approximate-nearest-neighbor index.

Flow:

```text
User features
     │
     ▼
User embedding
     │
     ▼
ANN Search
     │
     ▼
Top 500 item IDs
```

This is much faster than calculating similarity with every item.

---

# 46. Caching

Recommendations can be partially precomputed.

For users with stable preferences:

```text
user_id -> top 500 candidates
```

cached.

At request time:

```text
cached candidates
+
real-time session candidates
```

then rerank.

This hybrid approach reduces latency.

---

# 47. Precompute vs online

### Offline

Good for:

```text
long-term user interests
item-item similarity
popular lists
base user embeddings
```

### Online

Good for:

```text
session behavior
inventory
current context
freshness
```

So use both.

---

# 48. Failure handling

If personalization model is down:

```text
fallback → trending/popular
```

If feature store is unavailable:

```text
fallback → cached user recommendations
```

If user has no profile:

```text
fallback → regional/category popularity
```

Recommendations should degrade gracefully.

---

# 49. Observability

For each recommendation request:

```text
request_id
user_id
candidate sources
candidate counts
model version
ranking scores
filters applied
latency
final item IDs
```

Metrics:

```text
candidate latency
ranking latency
feature-store latency
CTR
conversion
diversity
freshness
fallback rate
```

This lets us answer:

> Why did user U see item X?

---

# 50. Final architecture

I’d finish with this diagram:

```text
                         USER
                          │
                          ▼
                  Recommendation API
                          │
                          ▼
                   Feature Service
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
         Online Features       User Embedding
                │                   │
                │                   ▼
                │              ANN Retrieval
                │                   │
                │         ┌─────────┴──────────┐
                │         │                    │
                │         ▼                    ▼
                │   Collaborative        Content-Based
                │      Candidates          Candidates
                │         │                    │
                │         └─────────┬──────────┘
                │                   ▼
                │             Candidate Merge
                │                   │
                └───────────────────┤
                                    ▼
                              Ranking Model
                                    │
                                    ▼
                                Re-ranker
                                    │
                         ┌──────────┼──────────┐
                         ▼          ▼          ▼
                     Diversity  Freshness  Business
                                           Rules
                                    │
                                    ▼
                             Recommendations
```

Training/data path:

```text
Clicks / Views / Purchases / Likes
                 │
                 ▼
              Kafka
                 │
        ┌────────┴────────┐
        ▼                 ▼
Stream Processing      Data Lake
        │                 │
        ▼                 ▼
Online Features     Offline Features
                          │
                          ▼
                    Model Training
                          │
                          ▼
                    Model Registry
                          │
                          ▼
                    Serving Models
```

---

# How I’d summarize it in the interview

> I would design the recommender as a multi-stage system. Behavioral events and item metadata feed both real-time and offline feature pipelines. Candidate generation uses several complementary sources—such as collaborative filtering, two-tower embedding retrieval, content similarity, trending items, and recent session behavior—to reduce millions of items to roughly hundreds or a few thousand. A richer ranking model then predicts outcomes such as click or purchase probability using user, item, interaction, and context features. A final re-ranking stage applies hard constraints like inventory and policy, and soft objectives such as diversity, freshness, exploration, and business value. Cold-start users rely initially on contextual, popular, and session signals, while cold-start items rely on metadata/content embeddings and controlled exploration. Quality is measured through offline recall/ranking metrics and ultimately through A/B tests using business outcomes and long-term guardrails.

The areas I’d expect the interviewer to drill into most are:

```text
1. Candidate generation
2. Ranking features/model
3. Cold start
4. Offline vs real-time features
5. Recommendation evaluation
6. Diversity/freshness/exploration
7. Feedback loops and bias
```

The architectural point I’d emphasize most is:

```text
Millions of items
       ↓
Candidate generation
       ↓
Hundreds/thousands
       ↓
Expensive ranking
       ↓
Re-ranking / constraints
       ↓
Top N recommendations
```

That pipeline is the backbone of most large-scale recommendation systems.
