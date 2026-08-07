# Database Comparison Reference

> Lookup table. Use alongside [Choosing the Right Database](Choosing%20the%20Right%20Database.md), which has the decision procedure.

## At A Glance

| Database | Engine | Model | Consistency | Scale | Best for |
|---|---|---|---|---|---|
| **PostgreSQL** | B-tree | Relational | **ACID, linearizable** | Vertical + replicas | **Default choice** |
| MySQL | B-tree | Relational | ACID | Vertical + replicas | Similar; simpler replication |
| **Cassandra** | **LSM** | Wide column | **Tunable** (R+W>N) | **Linear horizontal** | Write-heavy, multi-region |
| **DynamoDB** | LSM | KV / document | Eventual or strong | **Automatic** | Managed KV on AWS |
| MongoDB | B-tree | Document | Tunable | Sharding | Nested documents |
| **Redis** | In-memory | KV + structures | **Not durable** | Cluster | Cache, ephemeral state |
| **Elasticsearch** | Inverted index | Document | Near-real-time | Sharding | **Full-text search** |
| ClickHouse | Columnar | Relational | Eventual | Horizontal | **Analytical scans** |
| Druid / Pinot | Columnar | Time series | Eventual | Horizontal | Real-time dashboards |
| TimescaleDB | B-tree + compression | Time series | ACID | Vertical + Postgres | Metrics with SQL |
| Neo4j | Native graph | Graph | ACID | Limited | **Multi-hop traversal** |
| **Spanner / CockroachDB** | LSM + Raft | Relational | **Global ACID** | **Horizontal** | Global consistency |
| S3 / object storage | — | Blobs | Strong (since 2020) | Unlimited | Files, media, archives |

---

## Capacity Reference

| Store | Sustained throughput | Notes |
|---|---|---|
| PostgreSQL (1 node) | 5–20K writes/s, ~50K reads/s | Further than most assume |
| MySQL (1 node) | Similar | |
| Cassandra (per node) | 10–50K writes/s | Scales linearly with nodes |
| MongoDB (1 node) | 10–30K writes/s | |
| Redis (1 node) | ~100K ops/s | Single-threaded commands |
| Elasticsearch (per node) | 10–50K docs/s indexing | |
| ClickHouse | Millions of rows/s scanned | Analytical, not OLTP |
| DynamoDB | Effectively unlimited | You pay per request |

---

## Consistency Comparison

| Database | Default | Strong available? | Conflict resolution |
|---|---|---|---|
| PostgreSQL | Read Committed | Yes (Serializable, SSI) | MVCC + locks — no conflicts by design |
| MySQL InnoDB | **Repeatable Read** | Yes | MVCC + locks |
| Cassandra | Tunable, often ONE | Yes (QUORUM R+W>N) | **Last-write-wins — silent loss** |
| DynamoDB | Eventual | Yes (per read) | LWW in global tables |
| MongoDB | Primary reads | Yes (majority, causal) | Single primary avoids conflicts |
| Redis | Single node strong | — | N/A; async replication loses on failover |
| Spanner | **Linearizable** | Yes | TrueTime + commit-wait |

**The Postgres/MySQL default difference matters:** code correct on one can be subtly wrong on the other. See [Transactions and Isolation Levels](Transactions%20and%20Isolation%20Levels.md).

---

## What Each Cannot Do

| Database | Cannot |
|---|---|
| **PostgreSQL** | Scale writes beyond one node without Citus or app sharding |
| **Cassandra** | Joins, aggregation, ad-hoc `WHERE`, ordering on arbitrary columns |
| **DynamoDB** | Query without the partition key; `Scan` is a design failure |
| MongoDB | Joins across shards efficiently |
| **Redis** | Durability guarantees; be a source of truth |
| **Elasticsearch** | Be a source of truth; transactions; efficient updates |
| ClickHouse | OLTP — no efficient single-row updates or deletes |
| Neo4j | Scale horizontally like a KV store |
| Spanner | Avoid latency cost (~7 ms commit-wait) or expense |

---

## Anti-Patterns Per Database

| Database | Anti-pattern | Consequence |
|---|---|---|
| **Cassandra** | Unbounded partitions | Timeouts, heap pressure |
| **Cassandra** | Delete-heavy / queue workloads | **Tombstone accumulation** |
| Cassandra | Secondary indexes on high-cardinality columns | Scatter-gather across all nodes |
| **DynamoDB** | Low-cardinality partition key | **Hot partition throttling** |
| DynamoDB | Read-after-write via a GSI | GSIs are eventually consistent |
| **PostgreSQL** | Long-running transactions | Blocks vacuum → table bloat |
| PostgreSQL | UUID v4 primary key in InnoDB-style clustering | Random insert order fragments the index |
| **Elasticsearch** | Deep `from`/`size` pagination | Memory blowup; use `search_after` |
| Elasticsearch | Mismatched index/query analysers | Search silently returns nothing |
| **Redis** | `KEYS *` | Blocks the single thread |
| Redis | `noeviction` on a cache | Writes fail at memory limit |
| MongoDB | Unbounded array growth in a document | 16 MB document limit |

---

## Cost Shape

| Store | Cost driver |
|---|---|
| PostgreSQL / MySQL | Instance size, storage, replicas |
| **Cassandra** | Node count — **infrastructure + ops staffing** |
| **DynamoDB** | **Per request or provisioned capacity** — can exceed self-managed at high sustained load |
| Redis | Memory — the expensive resource |
| Elasticsearch | Nodes + storage; indexes are large |
| Snowflake / BigQuery | **Data scanned per query** — a bad query is expensive |
| S3 | Storage + requests + **egress** |

**DynamoDB versus Cassandra is genuinely a bill-versus-headcount trade.** At very high sustained throughput, self-managed Cassandra is often cheaper — if you have the operations capability. Say that trade-off explicitly rather than declaring one "better".

---

## Multi-Region Behaviour

| Database | Multi-region writes | Mechanism |
|---|---|---|
| PostgreSQL | **No** (single primary) | Async replicas; failover for DR |
| **Cassandra** | **Yes, symmetric** | LOCAL_QUORUM per DC; LWW conflicts |
| DynamoDB | Yes (global tables) | LWW conflicts |
| MongoDB | Configurable | Zone sharding |
| **Spanner / CockroachDB** | **Yes, consistent** | Consensus + synchronised clocks |
| Redis Enterprise | Yes (active-active) | **CRDTs** |

**If a design needs low-latency writes in several regions with consistency, the honest options are Spanner, CockroachDB, or accepting LWW.** There is no free version of this.

---

## Quick Decision Prompts

| If the question mentions… | Consider |
|---|---|
| "transactions", "consistency", "joins" | **PostgreSQL** |
| "millions of writes per second" | **Cassandra / ScyllaDB** |
| "on AWS", "don't want to manage it" | **DynamoDB** |
| "search", "full-text", "faceted" | **Elasticsearch** |
| "dashboard", "analytics", "aggregations" | **ClickHouse / Druid** |
| "metrics", "IoT", "time series" | **TimescaleDB / Prometheus** |
| "cache", "session", "leaderboard", "rate limit" | **Redis** |
| "friends of friends", "fraud ring" | **Neo4j** |
| "global", "strongly consistent", "multi-region writes" | **Spanner / CockroachDB** |
| "images", "video", "documents" | **S3 + CDN** |
| "flexible schema", "nested documents" | **Postgres JSONB** first, then MongoDB |

**Note the last row.** Postgres JSONB with GIN indexing covers most "we need a document database" cases without giving up relational capability — and asking "why not JSONB?" is a strong response to a MongoDB suggestion.

---

## Common Mistakes

- Treating "NoSQL" as one category
- Choosing Cassandra without knowing the access patterns
- Elasticsearch or Redis as the source of truth
- Ignoring operational cost when adding a store
- Assuming managed always beats self-managed on cost
- Not naming what the choice gives up

## Related Topics

- [Choosing the Right Database](Choosing%20the%20Right%20Database.md)
- [Storage Engines](Storage%20Engines.md)
- [SQL vs NoSQL](SQL%20vs%20NoSQL.md)
- [PostgreSQL](PostgreSQL.md) · [Cassandra](Cassandra.md) · [DynamoDB](DynamoDB.md)

## Revision Summary

A lookup table of engines, consistency models, capacity, limitations, anti-patterns, and cost shapes. Use it to check a candidate choice against what that database cannot do and what it will cost, after the decision procedure has narrowed the options.

## Quick Recall

- Postgres 5–20K writes/s on one node — further than assumed
- Cassandra: no joins, no ad-hoc queries, tombstone-hostile to deletes
- DynamoDB: partition key mandatory; GSIs eventually consistent
- Redis and Elasticsearch are **never** sources of truth
- Multi-region consistent writes → Spanner/CockroachDB, or accept LWW
- DynamoDB vs Cassandra = bill vs headcount
- Postgres JSONB before MongoDB
