# SQL vs NoSQL

## Why It Matters

Asked in every system design interview. The weak answer recites "structured vs unstructured". The strong answer reasons from access patterns and internal storage engines.

## The Real Distinction

Not "structured vs unstructured" — that's marketing. The genuine differences:

| Axis | SQL | NoSQL |
|---|---|---|
| **Storage engine** | Usually **B-tree** (read-optimised) | Often **LSM tree** (write-optimised) |
| **Schema** | Enforced on write | Enforced on read (by the application) |
| **Joins** | First-class | Absent — denormalise instead |
| **Transactions** | Multi-row ACID | Single-row/partition, or limited |
| **Scaling** | Vertical, then hard sharding | **Horizontal by design** |
| **Query flexibility** | Ad-hoc — the schema doesn't constrain queries | **Access patterns must be known up front** |

**The last row is the one that actually decides the choice.** Relational databases let you ask questions you didn't anticipate. NoSQL stores make you design the schema *around* the queries — which is fast when you know them, and painful when they change.

## B-tree vs LSM Tree

The internal difference that produces the performance characteristics:

| | B-tree | LSM tree |
|---|---|---|
| Writes | In-place update, random I/O | **Append to memtable, flush sequentially** |
| Write throughput | Moderate | **High** |
| Write amplification | Higher per write | Lower per write, but compaction rewrites data |
| Reads | **One tree traversal** | May check memtable + several SSTables |
| Read helper | — | **Bloom filters** skip SSTables that can't contain the key |
| Space | Compact | Higher until compaction |
| Used by | Postgres, MySQL InnoDB | **Cassandra, RocksDB, ScyllaDB, LevelDB** |

**"Choosing Cassandra for a write-heavy workload is really choosing an LSM tree"** — saying this shows you understand the mechanism, not just the label.

**Compaction is the LSM cost to name:** background merging of SSTables consumes I/O and can cause latency spikes. It's the trade for cheap writes.

## The NoSQL Families

| Family | Model | Examples | Best for |
|---|---|---|---|
| **Key-value** | Opaque value by key | Redis, DynamoDB | Caching, sessions, simple lookups |
| **Wide-column** | Rows with dynamic columns, partitioned | Cassandra, HBase, ScyllaDB | Time series, huge write volume |
| **Document** | Nested JSON documents | MongoDB, DocumentDB | Varied shapes, aggregate-oriented data |
| **Graph** | Nodes and edges | Neo4j, Neptune | Multi-hop relationship traversal |
| **Search** | Inverted index | Elasticsearch, OpenSearch | Full-text, faceted search |
| **Time series** | Time-partitioned, compressed | TimescaleDB, InfluxDB | Metrics, IoT |

**"NoSQL" is not one thing.** Naming the specific family and why is far stronger than saying "I'd use NoSQL".

## Choosing — Start From Access Patterns

Ask, in order:

1. **What are the queries?** Write them down before choosing.
2. **Is there a dominant access pattern?** A single point lookup → any KV store.
3. **Do you need multi-entity transactions?** → relational, or a database with them.
4. **Do you need ad-hoc queries?** → relational. NoSQL punishes unanticipated queries.
5. **What's the write volume?** > ~10K/sec sustained → LSM-based.
6. **Do relationships need traversal?** Two hops → joins are fine. Many hops → graph.

| Need | Choice |
|---|---|
| Transactions, joins, unpredictable queries | **PostgreSQL** |
| Massive writes, known access pattern | **Cassandra** |
| Managed KV, predictable latency, autoscaling | **DynamoDB** |
| Nested documents, evolving shape | MongoDB |
| Full-text search | Elasticsearch **alongside** a source of truth |
| Metrics and time series | TimescaleDB / InfluxDB |
| Multi-hop relationships | Neo4j |
| Global strong consistency | Spanner / CockroachDB |
| Cache and ephemeral state | Redis |

## The Default Answer

**Start with PostgreSQL unless you have a specific reason not to.**

A single modern Postgres node handles tens of thousands of TPS, has JSONB for schemaless columns, full-text search, geospatial support via PostGIS, and genuine ACID transactions. Most systems never outgrow it.

**Saying this is a strong signal**, not a weak one — it shows you weigh operational cost. Candidates who reach for Cassandra on a 1,000 QPS system are demonstrating pattern-matching, not judgement.

## Modern Convergence

The boundary has blurred, and knowing this prevents outdated answers:

- **Postgres has JSONB** with GIN indexes — schemaless columns with real query support
- **MongoDB has multi-document ACID transactions** (since 4.0)
- **DynamoDB has transactions** (up to 100 items)
- **CockroachDB and Spanner** offer horizontal scale *with* ACID and SQL — "NewSQL"
- **Cassandra has lightweight transactions** via Paxos (expensive; don't rely on them)

**"NoSQL means no transactions" is out of date.** So is "SQL can't scale horizontally."

## Cassandra Modelling — Query-First

If you choose Cassandra, model backwards from queries:

```
-- WRONG: normalised, needs a join Cassandra doesn't have
-- RIGHT: one table per query pattern, duplicated data

messages_by_conversation
  PARTITION KEY: conversation_id
  CLUSTERING KEY: message_id DESC
```

Rules:
- **One table per query.** Duplication is expected, not a smell.
- The partition key must distribute evenly and appear in every query
- Avoid unbounded partitions — add a time bucket (`conversation_id, month`) if a partition grows without limit
- No joins, no ad-hoc `WHERE`, no aggregation

**Unbounded partition growth is the classic Cassandra failure** and worth naming.

## Polyglot Persistence

Real systems use several stores:

```
Postgres      → orders, users (transactional source of truth)
Elasticsearch → product search (fed by CDC)
Redis         → sessions, cache
Cassandra     → event/activity log
S3            → media
```

**Have one source of truth and derive the rest**, ideally via change data capture. Dual writes without an outbox will drift.

## Common Mistakes

- "NoSQL is for unstructured data" — the shallow answer
- Choosing Cassandra without knowing the access patterns
- Assuming NoSQL means no transactions
- Normalising in Cassandra
- Ignoring unbounded partitions
- Reaching for a distributed database at a scale one Postgres node handles
- Not naming *which* NoSQL family and why

## Related Topics

- [Database Indexing](../Indexing/Database%20Indexing.md)
- [Partitioning and Sharding](../Partitioning%20and%20Sharding/Partitioning%20and%20Sharding.md)
- [CAP and PACELC](../../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md)
- [Database Replication](../Replication%20and%20Failover/Database%20Replication.md)

## Revision Summary

The real axes are storage engine (B-tree vs LSM), query flexibility, transaction scope, and horizontal scalability — not "structured vs unstructured". Choose from access patterns; default to PostgreSQL and justify anything else. Name the specific NoSQL family. The categories have converged significantly.

## Quick Recall

- B-tree = read-optimised; LSM = write-optimised (Cassandra, RocksDB)
- SQL allows unanticipated queries; NoSQL requires known access patterns
- Model Cassandra **one table per query**; duplication is fine
- Watch for unbounded partitions
- Default to Postgres; justify deviations
- "NoSQL has no transactions" is outdated
- Polyglot: one source of truth, derive the rest via CDC
