# Partitioning and Sharding

## Why It Matters

The answer to write scaling once a single node is saturated, and the decision with the longest-lasting consequences in a design — a bad shard key is extremely expensive to change.

## Partitioning vs Sharding

- **Partitioning** — splitting a table within one database instance (Postgres declarative partitioning). Helps query pruning and maintenance, not capacity.
- **Sharding** — splitting data across **separate machines**. Adds write capacity and storage, at the cost of cross-shard operations.

**Vertical partitioning** splits *columns* (rarely-used blobs into a separate table). **Horizontal partitioning** splits *rows* — this is what sharding means.

## Sharding Strategies

| Strategy | How | Pros | Cons |
|---|---|---|---|
| **Range** | Shard by key range (A–F, G–M) | Efficient range scans | **Hotspots** — sequential keys all hit one shard |
| **Hash** | `hash(key) % N` | Even distribution | No range scans; resharding moves everything |
| **Consistent hashing** | Hash onto a ring | **Only K/N keys move** when a node is added | More complex |
| **Directory** | Explicit lookup table | Maximum flexibility | Lookup service is a bottleneck and SPOF |
| **Geographic** | By region | Locality, data residency | Uneven load |

## Consistent Hashing

Plain `hash(key) % N` remaps **almost every key** when N changes — catastrophic for a cache or a database.

Consistent hashing maps both nodes and keys onto a ring; a key belongs to the first node clockwise. Adding a node only steals keys from its immediate successor — roughly **K/N keys move** instead of nearly all.

**Virtual nodes** are essential: each physical node gets 100–200 positions on the ring. Without them, distribution is uneven (variance is high with few points), and removing a node dumps its entire load onto one neighbour instead of spreading it across all.

**Replication on the ring:** walk clockwise from the key's position and place replicas on the next N *distinct physical* nodes — skipping virtual nodes belonging to a node already chosen. Rack- and datacentre-awareness further constrain the walk.

## Choosing the Shard Key — The Decision That Matters

Requirements, in order:

1. **High cardinality** — enough distinct values to spread across shards
2. **Even distribution** — no single value dominating
3. **Matches the query pattern** — most queries should hit **one** shard
4. **Stable** — the value should never change (changing it means moving the row)

| Bad key | Why |
|---|---|
| Timestamp | All current writes hit one shard |
| Auto-increment id | Same — sequential hotspot |
| Country | Massive skew |
| Boolean / status | Cardinality of 2 |

| Good key | Why |
|---|---|
| `user_id` | High cardinality, most queries are per-user |
| `tenant_id` | Natural isolation in multi-tenant systems |
| Composite `(user_id, timestamp)` | Distributes by user, orders within |

**Say this in interviews:** "I'd shard by `user_id` because the dominant access pattern is 'fetch this user's data', which keeps those queries single-shard."

## What Sharding Costs You

| Lost capability | Workaround |
|---|---|
| Cross-shard joins | Denormalise, or join in the application |
| Global unique auto-increment | Snowflake IDs, UUID, or per-shard ranges |
| Cross-shard transactions | Saga with compensating actions, or 2PC |
| Global secondary indexes | A separate index shard, or scatter-gather |
| Global aggregates | Scatter-gather, or a pre-computed rollup |
| Simple rebalancing | Consistent hashing, or over-provisioned logical shards |

**Scatter-gather queries are as slow as the slowest shard** and their tail latency degrades as shard count grows. Design so that the common query hits one shard.

## Hotspots

Even with a good key, one value can dominate — a celebrity user, a viral item.

**Fixes:**
- **Salting** — append a random suffix (`celebrity_id#0..9`), write to a random one, read all ten
- Dedicated shard for known-hot entities
- Cache the hot entity aggressively in front of the database

## Resharding

The hardest operation. Options:

1. **Consistent hashing** — minimises movement by design
2. **Logical shards** — create 1024 logical shards up front and map many to each physical node; "resharding" is just remapping, no data movement within a logical shard
3. **Double-write and backfill** — write to both old and new, backfill historical data, verify, cut over reads, stop old writes

**Pre-splitting into many logical shards is the practical answer** and worth volunteering.

## Common Mistakes

- Sharding before it's necessary — a single Postgres node handles far more than most people assume
- Choosing a timestamp or auto-increment id as the shard key
- Not planning for resharding
- Ignoring hotspots
- Assuming cross-shard transactions work
- Sharding when the actual problem is reads (use replicas and caching instead)

## Related Topics

- [Database Replication](../Replication%20and%20Failover/Database%20Replication.md)
- [Scaling Writes](../../04%20High%20Level%20Design/Patterns/Scaling%20Writes.md)
- [Database Indexing](../Indexing/Database%20Indexing.md)

## Revision Summary

Shard for write capacity, not reads. The shard key must have high cardinality, distribute evenly, match the dominant query, and never change. Consistent hashing with virtual nodes minimises movement. Sharding costs joins, transactions, and global indexes.

## Quick Recall

- Vertical = columns; horizontal = rows = sharding
- `hash % N` remaps everything; consistent hashing moves K/N
- Virtual nodes are mandatory for even distribution
- Never shard by timestamp or auto-increment id
- Hotspot → salting or a dedicated shard
- Pre-split into many logical shards to make resharding cheap
