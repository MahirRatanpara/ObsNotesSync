# DynamoDB

## Why It Matters

The managed key-value store that appears in most AWS-oriented designs. Interviewers probe partition-key choice and index types, because both are irreversible mistakes at scale.

## Core Model

| Concept | Meaning |
|---|---|
| **Partition key (PK)** | Hashed to select a partition — **required in every query** |
| **Sort key (SK)** | Orders items within a partition; enables range queries |
| Item | A row — max **400 KB** |
| Attribute | A field; schemaless beyond the key attributes |

**PK alone = simple primary key. PK + SK = composite primary key.**

The composite key is what makes DynamoDB more than a hash map: within a partition you get sorted range access.

```
PK=USER#123  SK=ORDER#2026-01-15   → all orders for a user, in date order
PK=USER#123  SK=PROFILE            → the user's profile
```

## Single-Table Design

The idiomatic DynamoDB pattern: put multiple entity types in **one table**, using generic key names and prefixes.

```
PK              SK                    Attributes
USER#123        PROFILE               name, email
USER#123        ORDER#2026-01-15      total, status
USER#123        ORDER#2026-02-03      total, status
ORDER#456       ITEM#1                sku, qty
```

**Why:** one query with `PK = USER#123 AND begins_with(SK, "ORDER#")` retrieves a user's orders without a join. Multiple entity types are fetched in one request.

**The cost:** the design is opaque, hard to change, and only works if you know the access patterns up front. **Single-table design is powerful and frequently over-applied** — for simple cases, separate tables are clearer and adequate.

## Indexes

| | **LSI (Local Secondary)** | **GSI (Global Secondary)** |
|---|---|---|
| Partition key | **Same as base table** | **Different** |
| Sort key | Alternative | Any |
| Created | **Only at table creation** | **Any time** |
| Consistency | Strongly consistent option | **Eventually consistent only** |
| Capacity | Shares the table's | **Its own** |
| Limit | 5 per table | 20 per table |

**Two things to remember:** LSIs cannot be added later, and GSIs are **always eventually consistent** — a write may not appear in a GSI query for a short window. Designing a read-after-write flow through a GSI is a real bug.

## Capacity Modes

| Mode | Behaviour | Use |
|---|---|---|
| **On-demand** | Pay per request, scales instantly | Unpredictable or spiky traffic; new applications |
| **Provisioned** | Pay for RCU/WCU per second | Steady, predictable traffic — significantly cheaper |

**Capacity units:**
- 1 **WCU** = one 1 KB write per second
- 1 **RCU** = one 4 KB *strongly consistent* read, or **two** eventually consistent reads per second

Eventually consistent reads are half the cost — worth stating.

## The Hot Partition Problem

Throughput is distributed across partitions. A partition key with poor cardinality concentrates traffic and gets throttled, even when total table capacity is far from exhausted.

| Bad PK | Problem |
|---|---|
| `status` | Cardinality of 3 |
| Date (`2026-08-06`) | All of today's writes hit one partition |
| Sequential ID | Same |

**Fixes:**
- **Write sharding** — append a random suffix (`PK = DATE#2026-08-06#{0..9}`), write to one, read all ten in parallel
- Choose a naturally high-cardinality key (`user_id`, `tenant_id`)

**Adaptive capacity** now isolates hot partitions and borrows unused capacity automatically, which mitigates but doesn't eliminate the problem.

## Consistency

| Read type | Guarantee | Cost |
|---|---|---|
| **Eventually consistent** (default) | May be stale by ~1 second | 0.5 RCU |
| **Strongly consistent** | Latest committed write | 1 RCU |
| Transactional | ACID across up to 100 items | 2× |

Writes are replicated across three availability zones and acknowledged after a quorum. **Strongly consistent reads are not available on GSIs.**

## Useful Features

| Feature | Use |
|---|---|
| **DynamoDB Streams** | Change data capture — feeds Lambda, Elasticsearch, aggregations |
| **TTL** | Automatic expiry; free deletes (no WCU consumed) |
| **Transactions** | ACID across up to 100 items, or 4 MB |
| **Conditional writes** | `attribute_not_exists(PK)` — optimistic concurrency and idempotency |
| **Global tables** | Multi-region active-active, **last-write-wins** |
| DAX | In-memory cache, microsecond reads |

**Conditional writes are the idempotency mechanism** — `PutItem` with `attribute_not_exists(idempotency_key)` fails if the key exists, giving you exactly-once semantics for retried requests without a separate lock.

**TTL deletes consume no write capacity**, which makes it the correct way to expire data rather than scanning and deleting.

## Query vs Scan

| | Query | Scan |
|---|---|---|
| Requires | **Partition key** | Nothing |
| Reads | One partition | **The entire table** |
| Cost | Proportional to results | Proportional to **table size** |

**Never `Scan` in a production request path.** If you find yourself needing one, the access pattern doesn't match the key design — add a GSI instead.

## DynamoDB vs Cassandra

| | DynamoDB | Cassandra |
|---|---|---|
| Operations | **Fully managed** | Self-managed |
| Scaling | Automatic | Add nodes manually |
| Cost | Per request — **can get expensive at scale** | Infrastructure |
| Consistency | Per-read choice | Per-query tunable levels |
| Lock-in | AWS only | Portable |
| Multi-region | Global tables (LWW) | Native symmetric |

**DynamoDB at very high sustained throughput can cost far more than self-managed Cassandra** — the trade is operational burden against bill. That's the honest comparison.

## When Not To Use It

- Access patterns unknown or changing frequently
- Ad-hoc queries or analytics needed
- Complex joins or aggregations
- Items larger than 400 KB (store in S3, keep a pointer)
- Cost-sensitive at very high sustained throughput

## Common Mistakes

- Low-cardinality partition key → hot partition throttling
- Expecting read-after-write consistency from a GSI
- Assuming an LSI can be added later
- `Scan` in a request path
- Single-table design applied to a simple problem
- Not using conditional writes for idempotency
- Ignoring the 400 KB item limit

## Related Topics

- [Cassandra](Cassandra.md)
- [SQL vs NoSQL](SQL%20vs%20NoSQL.md)
- [Partitioning and Sharding](Partitioning%20and%20Sharding.md)
- [Idempotent Consumers](Idempotent%20Consumers.md)

## Revision Summary

Managed key-value store where the partition key must appear in every query and determines throughput distribution. GSIs are eventually consistent and addable; LSIs are strongly consistent but creation-time only. Avoid hot partitions with high-cardinality or sharded keys, use conditional writes for idempotency, and never scan in production.

## Quick Recall

- PK required in every query; PK + SK enables range access
- **GSI: eventually consistent, addable. LSI: strong, creation-time only.**
- 1 WCU = 1 KB write; 1 RCU = 4 KB strong read or 8 KB eventual
- Hot partition → write sharding with a random suffix
- Conditional write = idempotency + optimistic locking
- TTL deletes are free
- **Never `Scan` in a request path**
- 400 KB item limit
