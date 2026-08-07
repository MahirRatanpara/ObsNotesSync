# Data Modelling and Schema Design

> How you shape the data. In HLD interviews this is the phase between choosing a database and drawing boxes — and it's where the design becomes concrete.

## Why It Matters

A good schema makes the hard queries easy and the invariants enforceable. A bad one forces application-level workarounds forever, because schema changes at scale are expensive and slow.

## The Two Philosophies

| | **Relational (schema-first)** | **NoSQL (query-first)** |
|---|---|---|
| Start from | Entities and relationships | **The queries you must serve** |
| Normalise | Yes, then denormalise selectively | **No — denormalise by default** |
| Duplication | Avoided | **Expected** |
| New query | Write a new SQL statement | May need a **new table** |
| Enforces invariants | Constraints, foreign keys | Application code |

**Modelling a wide-column store relationally is the single most common NoSQL mistake.** Cassandra has no joins, so a normalised schema means the application does the joining — badly, over the network, N times.

## Normalisation

| Form | Rule | Removes |
|---|---|---|
| **1NF** | Atomic values, no repeating groups | Arrays in columns |
| **2NF** | 1NF + no partial dependency on a composite key | Redundancy from partial keys |
| **3NF** | 2NF + no transitive dependency | Non-key → non-key dependency |
| BCNF | Stricter 3NF | Remaining anomalies |

**In practice, aim for 3NF and stop.** Beyond that the returns are theoretical.

**What normalisation buys you:**

| Benefit | Detail |
|---|---|
| **No update anomalies** | Change a customer's name in one place |
| Storage efficiency | No duplication |
| **Integrity enforced by the database** | Foreign keys, not application code |

**What it costs:** joins on every read, which becomes the bottleneck at scale.

## Denormalisation — Deliberate, Not Accidental

**Denormalise when a specific read path is demonstrably too slow**, not preemptively.

| Technique | Use |
|---|---|
| **Duplicate a column** | Store `customer_name` on `orders` to avoid a join |
| **Precomputed aggregate** | `comment_count` on `posts` instead of `COUNT(*)` |
| **Materialised view** | Precomputed join, refreshed on schedule or via triggers |
| **Summary table** | Daily rollups for reporting |
| Array/JSONB column | Small bounded collections inline |

**The cost is write complexity and drift risk.** If `comment_count` and the actual comments diverge, you have a bug that's invisible until someone counts.

**Two safeguards worth naming:**
1. **Update both in one transaction**, or derive via CDC — never dual-write across systems
2. **A reconciliation job** that recomputes and corrects drift

**The snapshot argument:** duplicating `customer_name` onto an order is often *more* correct than joining. The order should show the name as it was at order time, not the current name. Denormalisation here captures a historical fact, not a cache.

## Relational Modelling Essentials

### Relationships

| Type | Implementation |
|---|---|
| One-to-one | Foreign key with a unique constraint, or shared primary key |
| **One-to-many** | Foreign key on the "many" side |
| **Many-to-many** | **Junction table** with a composite primary key |
| Self-referencing | Foreign key to the same table (org charts, categories) |

### Primary Key Choice

| Type | Pros | Cons |
|---|---|---|
| **Auto-increment `bigint`** | Compact, sequential, index-friendly | Leaks volume; a bottleneck when sharding |
| **UUID v4** | Globally unique, generated client-side | **Random order fragments clustered indexes**; 16 bytes |
| **UUID v7 / ULID** | Unique **and** time-sortable | Slightly newer, less universal support |
| Natural key (email) | Meaningful | **Changes** — never use a mutable value |

**UUID v4 as a primary key in InnoDB is a real performance bug.** Because InnoDB clusters rows by primary key, random UUIDs cause page splits and fragmentation on every insert. **UUID v7 or ULID fixes it** by making the leading bits a timestamp — sequential insert order with global uniqueness.

**Never use a mutable natural key.** Email addresses change; the foreign keys referencing them then cascade or break.

### Constraints Are Not Optional

```sql
CREATE TABLE orders (
  id          bigint PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers(id),
  status      text NOT NULL CHECK (status IN ('PENDING','PAID','SHIPPED')),
  total_cents bigint NOT NULL CHECK (total_cents >= 0),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (customer_id, idempotency_key)
);
```

**The database is the last line of defence.** Application code has bugs, migrations run outside the app, and multiple services may write. A `CHECK` constraint holds regardless.

**The `UNIQUE (customer_id, idempotency_key)` line is doing real work** — it makes duplicate submission impossible at the storage layer, not just in the happy path.

### Types That Matter

| Concern | Correct |
|---|---|
| **Money** | **`bigint` in minor units** (cents) — never `float` |
| Timestamps | **`timestamptz`** — always with a timezone |
| Enums | Text with a `CHECK`, or a native enum type |
| Booleans | `boolean`, not `char(1)` or `int` |
| Large text/blobs | Separate table or object storage |

**Floating-point money is a genuine correctness bug** — `0.1 + 0.2 != 0.3`. Stating this unprompted signals production experience.

## NoSQL Modelling — Query-First

### Cassandra: one table per query

```sql
-- Query: last 50 messages in a conversation
CREATE TABLE messages_by_conversation (
    conversation_id uuid,
    message_id      timeuuid,
    sender_id       uuid,
    content         text,
    PRIMARY KEY ((conversation_id), message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

-- Query: a user's conversations, most recent first
CREATE TABLE conversations_by_user (
    user_id           uuid,
    last_message_at   timestamp,
    conversation_id   uuid,
    PRIMARY KEY ((user_id), last_message_at)
) WITH CLUSTERING ORDER BY (last_message_at DESC);
```

**Same data, two tables, two queries.** Writing to both on every message is expected and correct.

| Rule | Reason |
|---|---|
| **Partition key in every query** | It routes to the node |
| **Clustering key defines on-disk order** | Enables range scans within a partition |
| **Bound partition size** | Add a time bucket if unbounded; target <100 MB |
| No joins, no ad-hoc `WHERE` | Model the query, not the entity |

**Unbounded partitions are the classic Cassandra failure.** `((conversation_id), message_id)` grows forever for a busy conversation — use `((conversation_id, month), message_id)`.

### DynamoDB: single-table design

```
PK              SK                    Attributes
USER#123        PROFILE               name, email
USER#123        ORDER#2026-01-15      total, status
USER#123        ORDER#2026-02-03      total, status
```

One query with `PK = USER#123 AND begins_with(SK, "ORDER#")` fetches a user's orders — no join.

**Powerful and frequently over-applied.** It only works when access patterns are known up front, and it makes the schema opaque. For simple cases, separate tables are clearer.

### Document stores

**Embed** when data is accessed together and bounded:
```json
{ "_id": "order1", "items": [ {...}, {...} ] }
```

**Reference** when data is shared, unbounded, or independently updated:
```json
{ "_id": "order1", "customer_id": "cust99" }
```

**The bounded-growth rule:** embedding an array that grows without limit hits MongoDB's 16 MB document limit and makes every read progressively more expensive. Comments on a viral post must be referenced, not embedded.

## Modelling Time-Varying Data

Frequently needed, rarely taught.

| Pattern | Use |
|---|---|
| **Audit table** | Separate `orders_history` with every version |
| **Temporal columns** | `valid_from`, `valid_to` on each row |
| **Event sourcing** | The events *are* the data |
| **Soft delete** | `deleted_at` instead of removing rows |

**Soft delete's hidden cost:** every query must filter `WHERE deleted_at IS NULL`, and forgetting it once is a data leak. **Use a partial index** (`WHERE deleted_at IS NULL`) so the index stays small, and consider a view that applies the filter automatically.

## Multi-Tenancy

| Model | Isolation | Cost |
|---|---|---|
| **Shared schema, `tenant_id` column** | Weakest — a missing `WHERE` leaks data | **Cheapest** |
| Schema per tenant | Better | Migration complexity × tenants |
| **Database per tenant** | **Strongest** | Most expensive |

**Shared schema is the usual choice**, with `tenant_id` as the **leading column in every index** and row-level security as a backstop. The leading-column detail matters — an index on `(created_at, tenant_id)` won't prune by tenant.

## The Schema Design Checklist

- [ ] Every access pattern has an index or a table that serves it
- [ ] Primary keys are stable and immutable
- [ ] Sequential-ish IDs if the store clusters by primary key
- [ ] Money in integer minor units; timestamps with timezone
- [ ] Constraints encode the invariants
- [ ] Denormalisation is deliberate, with a drift safeguard
- [ ] No unbounded partitions or unbounded embedded arrays
- [ ] `tenant_id` leads every index in a multi-tenant schema
- [ ] Soft-delete filters are enforced by index or view

## Common Mistakes

- Modelling relationally in Cassandra or DynamoDB
- Denormalising preemptively, before measuring
- UUID v4 primary keys in a clustered-index store
- Floats for money
- Naive timestamps without a timezone
- Mutable natural keys
- No constraints — "the application validates it"
- Unbounded partitions and embedded arrays
- Forgetting the soft-delete filter

## Related Topics

- [Choosing the Right Database](Choosing%20the%20Right%20Database.md)
- [Database Indexing](../Indexing/Database%20Indexing.md)
- [Partitioning and Sharding](../Partitioning%20and%20Sharding/Partitioning%20and%20Sharding.md)
- [Schema Migrations and Evolution](Schema%20Migrations%20and%20Evolution.md)

## Revision Summary

Relational modelling starts from entities and normalises to 3NF, denormalising only where a read path is provably slow. NoSQL modelling starts from queries — one table per query in Cassandra, single-table design in DynamoDB. Choose stable sequential primary keys, encode invariants as constraints, and never let a partition or embedded array grow unbounded.

## Quick Recall

- **Relational = schema-first; NoSQL = query-first**
- 3NF then stop; denormalise only when measured
- Duplicated `customer_name` is a **snapshot**, not a cache
- **UUID v4 fragments clustered indexes → use v7/ULID**
- Money in integer minor units; `timestamptz` always
- Constraints are the last line of defence
- Cassandra: **one table per query**, bounded partitions
- Multi-tenant: `tenant_id` **leads** every index
