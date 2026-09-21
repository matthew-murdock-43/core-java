# 1. E-commerce market place

Yes. In a system design interview, I would answer this much more like a structured conversation than by jumping directly into services.

A strong flow would be:

1. Clarify requirements
2. Define scale and assumptions
3. Identify core entities
4. Define APIs
5. Draw high-level architecture
6. Deep dive into inventory and checkout
7. Discuss search and ranking
8. Handle failures, refunds, cancellations
9. Discuss scalability, consistency, and tradeoffs

Here is how I would walk through it.

---

# 1. Clarify the requirements

I would start with something like:

> We need to design an e-commerce marketplace where multiple sellers can list products, buyers can search and browse them, add listings to a cart, purchase them, and track orders.

Then clarify the functional requirements.

### Functional

Buyers should be able to:

- Search products
- View product details
- View seller listings and availability
- Add/remove items from cart
- Checkout
- Pay
- View order history
- Track an order
- Cancel an order where allowed
- Request a refund

Sellers should be able to:

- Create/update listings
- Update price
- Update inventory
- View orders

I would explicitly call out that this is a **marketplace**, so:

```text
Product != Listing
```

For example:

```text
Product
Sony WH-1000XM6 Headphones

Listings:
Seller A: $449, stock 10
Seller B: $439, stock 3
Seller C: $460, stock 25
```

That distinction becomes very important in the data model.

---

# 2. Non-functional requirements

I would say:

- High availability for browsing and search
- Low latency for product pages and search
- Strong consistency for inventory updates
- Strong consistency around order/payment state transitions
- Eventual consistency is acceptable for search indexing
- System should survive partial failures
- Checkout operations must be idempotent
- No overselling

That last point is likely one of the biggest discussion areas in this interview.

---

# 3. Scale assumptions

I wouldn't spend too much time calculating unless the interviewer asks, but I'd make assumptions.

For example:

```text
100M registered users
10M daily active users

50M products
200M seller listings

Peak:
100K product/search reads/sec
10K cart operations/sec
2K checkouts/sec
```

This immediately tells us:

```text
Reads >> writes
```

So the architecture should optimize heavily for product discovery and browsing.

---

# 4. Core domain model

I would then define the important objects.

## Product

Represents the generic product.

```text
Product
-------
product_id
name
description
brand
category
attributes
images
```

## Seller

```text
Seller
------
seller_id
name
rating
status
```

## Listing

Represents a seller offering a product.

```text
Listing
-------
listing_id
product_id
seller_id
price
currency
status
```

## Inventory

```text
Inventory
---------
listing_id
available_quantity
reserved_quantity
version
```

I'd separate inventory because it has very different consistency and concurrency requirements from product metadata.

## Cart

```text
Cart
----
cart_id
user_id
items[]
```

With:

```text
CartItem
--------
listing_id
quantity
```

## Order

```text
Order
-----
order_id
user_id
status
total
shipping_address
payment_status
created_at
```

and:

```text
OrderItem
---------
order_item_id
order_id
listing_id
product_id
seller_id
product_name
unit_price
quantity
```

I would highlight this detail:

> OrderItem should contain a snapshot of product name, price, seller, etc. We shouldn't dynamically look up the current listing when showing historical orders.

Otherwise:

```text
Price when purchased = $100
Seller changes listing to $130

Old order must still show $100
```

---

# 5. APIs

Then I'd define a few high-level APIs.

### Search

```http
GET /search?q=headphones&category=electronics&page=1
```

### Product

```http
GET /products/{productId}
```

### Listings

```http
GET /products/{productId}/listings
```

### Cart

```http
POST /cart/items
{
  "listingId": "L123",
  "quantity": 2
}
```

```http
DELETE /cart/items/{listingId}
```

### Checkout

```http
POST /checkout
{
  "cartId": "C123",
  "paymentMethodId": "PM456",
  "shippingAddressId": "A789"
}
```

I'd probably require an idempotency key:

```http
Idempotency-Key: checkout-abc-123
```

That protects us against:

```text
Client times out
    ↓
Client retries
    ↓
Two orders accidentally created
```

---

# 6. High-level architecture

At this point I would draw this.

```text
                         ┌─────────────────────┐
                         │    Web / Mobile     │
                         └──────────┬──────────┘
                                    │
                            CDN / API Gateway
                                    │
             ┌──────────────────────┼───────────────────────┐
             │                      │                       │
             ▼                      ▼                       ▼
       ┌────────────┐         ┌────────────┐          ┌────────────┐
       │ Catalog    │         │ Search     │          │ Cart       │
       │ Service    │         │ Service    │          │ Service    │
       └─────┬──────┘         └─────┬──────┘          └─────┬──────┘
             │                      │                       │
             ▼                      ▼                       ▼
       Product DB              OpenSearch                Redis
             │
             │
             ▼
          Kafka
             │
             ▼
       Search Indexer
```

And for the transactional side:

```text
                           ┌─────────────────┐
                           │ Checkout Service│
                           └────────┬────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
      ┌──────────────┐      ┌──────────────┐      ┌────────────┐
      │ Inventory    │      │ Payment      │      │ Order      │
      │ Service      │      │ Service      │      │ Service    │
      └──────┬───────┘      └──────┬───────┘      └─────┬──────┘
             │                     │                     │
             ▼                     ▼                     ▼
       Inventory DB          Payment Provider          Order DB
                                                         │
                                                         ▼
                                                       Kafka
                                                         │
                          ┌──────────────────────────────┼──────────┐
                          ▼                              ▼          ▼
                    Fulfillment                  Notifications   Analytics
```

---

# 7. Product search design

Search is read-heavy, so I wouldn't query the primary database for search.

I would use:

```text
Catalog DB
    │
 ProductChanged event
    │
    ▼
 Kafka
    │
    ▼
 Search Indexer
    │
    ▼
 OpenSearch / Elasticsearch
```

The search document could contain denormalized information:

```json
{
  "productId": "P123",
  "name": "Wireless Headphones",
  "brand": "Sony",
  "category": "Electronics",
  "minPrice": 399,
  "rating": 4.7,
  "salesCount": 15000,
  "inStock": true
}
```

Search can support:

- Full-text search
- Typo tolerance
- Facets
- Categories
- Price filters
- Brands
- Ratings
- Sorting

---

# 8. Search ranking

The prompt specifically asks about ranking.

I would separate:

```text
Retrieval
    +
Ranking
```

For example:

```text
Final score =
    text relevance
  + popularity
  + conversion rate
  + rating
  + freshness
  + availability
```

Possibly later:

```text
Search query
     │
     ▼
Candidate retrieval
     │
     ▼
1000 matching products
     │
     ▼
ML ranking
     │
     ▼
Top 50 products
```

We can eventually personalize ranking using:

- Search history
- Purchase history
- Category preferences
- Geography

But I wouldn't make personalization mandatory in the initial design.

---

# 9. Cart design

I would use Redis for carts.

```text
cart:{user_id}

{
    listing123: 2,
    listing456: 1
}
```

Why?

Carts are:

- Frequently read/written
- Temporary
- User-specific
- Latency sensitive

We can persist important carts asynchronously if required.

---

# 10. Should adding to cart reserve inventory?

This is an important interview question.

My default answer:

> No, adding to cart should generally not reserve inventory.

Suppose only one PlayStation is left.

User A:

```text
Adds item to cart
```

Then closes the browser for 3 days.

If that reserved inventory:

```text
Available stock = 0
```

Nobody else could buy it.

So:

```text
Add to cart
    ↓
No reservation
```

Instead:

```text
Checkout starts
    ↓
Reserve inventory temporarily
```

There are exceptions.

For things like:

- Concert tickets
- Airline seats
- Extremely scarce flash-sale items

reservation at cart-selection time might make sense.

---

# 11. Preventing overselling

This is one of the most important parts of the design.

Imagine:

```text
Inventory = 1
```

Two requests arrive:

```text
Buyer A reads stock = 1
Buyer B reads stock = 1

A buys
B buys
```

Now we've sold two units.

So you cannot implement inventory as:

```text
READ quantity
IF quantity > 0
    WRITE quantity - 1
```

because that has a race condition.

Instead, use an atomic update.

For example:

```sql
UPDATE inventory
SET available_quantity = available_quantity - 1
WHERE listing_id = ?
AND available_quantity >= 1;
```

Then:

```text
rows affected = 1
    → success

rows affected = 0
    → out of stock
```

For quantity `N`:

```sql
UPDATE inventory
SET available_quantity = available_quantity - :qty
WHERE listing_id = :listing
AND available_quantity >= :qty;
```

This protects against concurrent purchases.

---

# 12. Inventory reservation model

I'd model inventory as:

```text
physical_stock = 100

available = 95
reserved = 5
```

During checkout:

```text
Reserve 2 units

Before:
available = 95
reserved  = 5

After:
available = 93
reserved  = 7
```

Create:

```text
InventoryReservation

reservation_id
listing_id
order_id
quantity
expires_at
status
```

Example:

```text
expires_at = now + 10 minutes
```

If checkout succeeds:

```text
RESERVED → CONFIRMED
```

If it fails:

```text
RESERVED → RELEASED
```

If the customer disappears:

```text
reservation expires
    ↓
Inventory returned
```

---

# 13. Checkout flow

Now I'd spend time on the core workflow.

```text
Client
  │
  │ POST /checkout
  ▼
Checkout Service
  │
  ├── Validate cart
  │
  ├── Fetch latest prices
  │
  ├── Reserve inventory
  │
  ├── Create pending order
  │
  ├── Authorize payment
  │
  ├── Confirm inventory
  │
  └── Confirm order
```

A possible sequence:

```text
1. Customer clicks Buy

2. Checkout Service validates cart

3. Inventory Service
      reserve(listings)

4. Order Service
      create PENDING order

5. Payment Service
      authorize payment

6. Order Service
      order → CONFIRMED

7. Inventory
      reservation → COMMITTED

8. Publish OrderConfirmed

9. Fulfillment starts
```

---

# 14. Why not use one distributed DB transaction?

Because these services may have separate databases and an external payment provider.

We cannot realistically do:

```text
BEGIN

Inventory DB
Order DB
Payment provider
Shipping provider

COMMIT
```

So I would use a **Saga**.

---

# 15. Saga / compensation

Example:

```text
Reserve Inventory
      │
      ▼
Create Order
      │
      ▼
Authorize Payment
      │
      ▼
Confirm Order
```

Suppose payment fails.

Compensating actions:

```text
Payment failed
      │
      ├── Order → PAYMENT_FAILED
      │
      └── Release inventory
```

Suppose inventory reservation worked but the order DB fails:

```text
Release inventory
```

Suppose payment succeeds but order confirmation fails:

```text
Retry confirmation
```

And if unrecoverable:

```text
Void / refund payment
Release inventory
```

---

# 16. Payment design

I would keep payment state separate from order state.

For example:

```text
Payment
-------
payment_id
order_id
provider
provider_payment_id
amount
status
```

Possible states:

```text
INITIATED
AUTHORIZED
CAPTURED
FAILED
VOIDED
REFUNDED
PARTIALLY_REFUNDED
```

Why separate authorization and capture?

Because some businesses prefer:

```text
Checkout
    ↓
Authorize $100

Shipment starts
    ↓
Capture $100
```

instead of taking the money immediately.

---

# 17. Payment failures

Suppose Stripe/Adyen/etc. responds:

```text
Declined
```

Then:

```text
Order → PAYMENT_FAILED
Inventory reservation → RELEASED
```

But there's a more difficult case:

```text
Payment provider processes payment
    ↓
Our service times out
```

We don't know whether payment succeeded.

So payment requests must use an idempotency key:

```text
payment attempt ID
```

Then retries don't double-charge.

Also consume payment-provider webhooks:

```text
Payment provider
      │
      ▼
PaymentSucceeded webhook
      │
      ▼
Payment Service
```

This reconciles ambiguous states.

---

# 18. Cancellations

Cancellation rules depend on order state.

For example:

```text
PENDING
    → cancel immediately

CONFIRMED but not shipped
    → cancel
    → refund
    → release inventory

SHIPPED
    → cannot cancel
    → initiate return instead
```

I'd implement this as an order state machine.

```text
PENDING
   │
   ▼
CONFIRMED
   │
   ▼
PROCESSING
   │
   ▼
SHIPPED
   │
   ▼
DELIVERED
```

Failure paths:

```text
PENDING → PAYMENT_FAILED
CONFIRMED → CANCELLED
DELIVERED → RETURN_REQUESTED
```

---

# 19. Refunds

Refund should be asynchronous.

```text
User requests refund
        │
        ▼
Order Service
        │
        ▼
RefundRequested event
        │
        ▼
Payment Service
        │
        ▼
Payment Provider
        │
        ▼
RefundCompleted
        │
        ▼
Order updated
```

Why asynchronous?

Because payment providers can be slow or temporarily unavailable.

---

# 20. Event-driven architecture

Kafka would be useful for events such as:

```text
ProductUpdated
ListingUpdated
InventoryChanged
OrderCreated
OrderConfirmed
PaymentSucceeded
PaymentFailed
OrderShipped
OrderDelivered
RefundCompleted
```

Consumers include:

```text
Search Indexer
Notifications
Analytics
Recommendations
Fulfillment
Fraud Detection
```

For example:

```text
OrderConfirmed
      │
      ├── Fulfillment
      ├── Email notification
      ├── Analytics
      └── Seller dashboard
```

The checkout request doesn't need to wait for all of those.

---

# 21. Reliable event publishing

Then I'd mention the **transactional outbox pattern**.

Imagine:

```text
Order DB commit succeeds
        │
        ▼
App crashes
        │
        ▼
Kafka event never sent
```

Now the order exists, but downstream systems don't know.

Instead:

```text
DB transaction:

INSERT order
INSERT outbox_event

COMMIT
```

Then:

```text
Outbox worker
      │
      ▼
Kafka
```

This makes event publication reliable.

---

# 22. Database choices

I wouldn't force one technology everywhere.

### Catalog

Could be:

```text
PostgreSQL/MySQL
```

or a scalable NoSQL store depending on scale.

### Search

```text
OpenSearch / Elasticsearch
```

### Cart

```text
Redis
```

### Order

```text
Relational database
```

because:

- Transactions
- Strong consistency
- Queryability
- State transitions

### Inventory

I'd favor a strongly consistent transactional store.

```text
Postgres / MySQL
```

Sharded if necessary.

---

# 23. Caching

For product browsing:

```text
Client
 │
 ▼
CDN
 │
 ▼
API
 │
 ▼
Redis
 │
 ▼
Product DB
```

We can cache:

- Product details
- Categories
- Seller metadata
- Popular listings

But I would avoid treating cached inventory as authoritative.

This is important:

```text
Product stock display:
    cache acceptable

Final checkout:
    authoritative Inventory Service
```

The page may say:

```text
3 left
```

but checkout must revalidate.

---

# 24. Availability vs consistency

I would explicitly say different parts of the system have different consistency requirements.

### Eventual consistency is okay

```text
Search results
Product recommendations
Analytics
Seller dashboards
```

### Strong consistency is important

```text
Inventory reservation
Order creation
Payment state
Refund state
```

That shows you're not trying to make the whole architecture globally strongly consistent.

---

# 25. Order tracking

Fulfillment consumes:

```text
OrderConfirmed
```

and talks to carriers.

```text
Fulfillment Service
        │
        ▼
FedEx / UPS / DHL / etc.
```

Carrier events:

```text
ShipmentCreated
PickedUp
InTransit
OutForDelivery
Delivered
```

can update:

```text
Order Tracking Service
```

The client calls:

```http
GET /orders/{orderId}/tracking
```

---

# 26. Marketplace-specific complexity

Since this is a marketplace, one customer checkout may contain multiple sellers.

For example:

```text
Cart

Seller A
  Item 1
  Item 2

Seller B
  Item 3
```

You could model:

```text
CustomerOrder
   │
   ├── SellerOrder A
   │     ├── item 1
   │     └── item 2
   │
   └── SellerOrder B
         └── item 3
```

This helps because fulfillment may happen independently.

```text
Overall order
   ├── Seller A → SHIPPED
   └── Seller B → PROCESSING
```

The user-facing order can aggregate those states.

---

# 27. Partitioning at scale

If the interviewer pushes scale:

### Product/catalog

Partition by:

```text
product_id
```

### Listings

Potentially:

```text
product_id
```

or:

```text
listing_id
```

depending on access pattern.

### Inventory

Partition by:

```text
listing_id
```

### Orders

Partition by:

```text
user_id
```

if order history is a primary access pattern, or by `order_id` with a secondary user index.

---

# 28. Hot inventory / flash sales

A likely follow-up is:

> What if 1 million users try to buy 100 PS5s?

A normal database may become a hotspot.

I'd first say the atomic DB design remains correct, but for extreme hot-key scenarios we could introduce:

```text
Request queue
     │
     ▼
Inventory partition
     │
     ▼
Serialized reservation workers
```

Or controlled admission:

```text
API
 │
 ▼
Rate limiter
 │
 ▼
Queue
 │
 ▼
Inventory worker
```

The goal is to protect the database from a million concurrent writes against the same row.

But I would only introduce this when needed.

---

# 29. Observability

I'd mention:

- Distributed tracing
- Metrics
- Logs
- Business metrics

Important metrics:

```text
checkout_success_rate
payment_failure_rate
inventory_reservation_failure_rate
oversell_count
order_creation_latency
search_latency
cart_abandonment
```

`oversell_count` should ideally remain:

```text
0
```

---

# 30. Final architecture

I would finish with something like this:

```text
                               USERS
                                 │
                          Web / Mobile Apps
                                 │
                           CDN / API Gateway
                                 │
     ┌───────────────────────────┼───────────────────────────────┐
     │                           │                               │
     ▼                           ▼                               ▼
┌─────────┐                 ┌─────────┐                    ┌─────────┐
│ Catalog │                 │ Search  │                    │  Cart   │
└────┬────┘                 └────┬────┘                    └────┬────┘
     │                           │                               │
 Product DB                  OpenSearch                        Redis
     │
     └──────────────► Kafka ◄──────────────────────────────────────┐
                           │                                      │
                           │                                      │
                           ▼                                      │
                    Search Indexer                                │
                                                                  │
                      ┌────────────────┐                           │
                      │    Checkout    │                           │
                      └───────┬────────┘                           │
                              │                                    │
             ┌────────────────┼────────────────┐                   │
             │                │                │                   │
             ▼                ▼                ▼                   │
      ┌────────────┐    ┌────────────┐    ┌────────────┐          │
      │ Inventory  │    │  Payment   │    │   Order    │          │
      └─────┬──────┘    └─────┬──────┘    └─────┬──────┘          │
            │                 │                 │                  │
      Inventory DB      Payment Provider      Order DB             │
                                                │                  │
                                                └────► Kafka ──────┘
                                                        │
                                      ┌─────────────────┼───────────────┐
                                      ▼                 ▼               ▼
                                Fulfillment       Notifications      Analytics
                                      │
                                      ▼
                                  Carriers
```

And I'd summarize the key design choices in the interview as:

> The architecture separates the read-heavy product-discovery path from the strongly consistent transaction path. Search is backed by OpenSearch and asynchronously updated from catalog events. Carts live in Redis and don't reserve inventory. At checkout we atomically reserve inventory, create an order, and coordinate payment using a Saga with idempotent operations and compensating actions. Kafka decouples fulfillment, notifications, search indexing, and analytics. Inventory and payment remain the critical strongly consistent boundaries.

That is the kind of answer that would comfortably fill a **40–45 minute system design interview**, with the interviewer choosing which areas—inventory, checkout, search, payments, or scaling—to drill into.
