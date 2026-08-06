# PostgreSQL

## Why It Matters

The correct default for most systems, and the one people abandon too early. Knowing what it can actually do prevents unnecessary architecture.

## What One Node Handles

| Metric | Realistic |
|---|---|
| Writes | 5,000–20,000 TPS |
| Reads | 50,000+ QPS (cached working set) |
| Data | Comfortably into single-digit TB |
| Connections | Hundreds (thousands with PgBouncer) |

**Most systems in an interview never exceed this.** Saying "a single Postgres node handles this; I wouldn't distribute" is a strong signal, not a weak one.

## MVCC

Each write creates a **new row version** rather than updating in place. Each transaction sees a snapshot consistent as of its start.

**Consequences:**

| Effect | Detail |
|---|---|
| Readers never block writers | And vice versa — the main concurrency benefit |
| **Dead tuples accumulate** | Old versions remain until vacuumed |
| **VACUUM is required** | Reclaims dead tuples; autovacuum usually handles it |
| **Long transactions cause bloat** | Old versions can't be removed while any transaction might still need them |
| Transaction ID wraparound | A real operational hazard if vacuum falls behind |

**"A long-running analytics query blocks VACUUM and bloats the table" is the practical failure to know.** It's a common production incident and directly explains why you shouldn't run reporting queries against the primary.

Postgres has **no clustered index** — tables are heaps, and every index points at a physical tuple location.

**HOT updates** (heap-only tuples) avoid rewriting every index when the updated column isn't indexed and the new version fits on the same page — one reason not to over-index frequently-updated tables.

## Index Types

| Type | Use |
|---|---|
| **B-tree** | Default — equality, range, ordering |
| Hash | Equality only; rarely worth it |
| **GIN** | Full-text search, **JSONB**, arrays — "which rows contain this element" |
| GiST | Geometric, nearest-neighbour, ranges |
| **BRIN** | Very large naturally-ordered tables (time series) — tiny index, block-range summaries |
| **Partial** | `WHERE deleted_at IS NULL` — index only relevant rows |
| Expression | `ON users (lower(email))` — index a computed value |

**Partial and expression indexes are underused.** A partial index on active rows can be a fraction of the size of a full one; an expression index makes `WHERE lower(email) = ?` sargable instead of triggering a sequential scan.

**BRIN** on an append-only time-series table can be thousands of times smaller than a B-tree while still pruning most blocks.

## JSONB

```sql
CREATE INDEX idx ON events USING GIN (payload);
SELECT * FROM events WHERE payload @> '{"type": "click"}';
```

Binary JSON with full indexing support. **This is why "we need a document database" is often not true** — Postgres gives you schemaless columns *and* relational integrity in one system.

Use `jsonb_path_ops` for a smaller, faster containment-only index.

## Extensions — The Real Differentiator

| Extension | Adds |
|---|---|
| **PostGIS** | Best-in-class geospatial — proximity, polygons, routing |
| **pg_trgm** | Trigram similarity — fuzzy matching, `LIKE '%x%'` acceleration |
| **TimescaleDB** | Time-series hypertables, compression, continuous aggregates |
| **pgvector** | Vector similarity for embeddings and semantic search |
| pg_stat_statements | Query performance statistics — the first thing to enable |
| pg_partman | Partition management |
| Citus | Distributed Postgres — horizontal sharding |

**The extension ecosystem is the strongest argument for Postgres**: geospatial, time-series, vector search, and full-text search without adding a separate system to operate.

## Replication

| Type | Mechanism |
|---|---|
| **Streaming (physical)** | Ships WAL records; byte-identical replica |
| **Logical** | Ships row changes; selective, cross-version, enables CDC |
| Synchronous | `synchronous_commit = on` with `synchronous_standby_names` |

**Logical replication is what powers CDC** — Debezium reads the logical replication slot to stream changes into Kafka, which is the correct way to feed Elasticsearch or a cache invalidator.

**Replication slot warning:** a slot with no consumer prevents WAL cleanup and will eventually fill the disk. A stale slot is a classic outage cause.

## Connection Management

Postgres uses a **process per connection** (~5–10 MB each). Thousands of direct connections is not viable.

**PgBouncer** multiplexes:

| Pool mode | Behaviour |
|---|---|
| Session | Connection held for the client session |
| **Transaction** | Connection returned after each transaction — **highest efficiency** |
| Statement | Per statement; breaks multi-statement transactions |

**Transaction pooling breaks session-level features** — prepared statements, advisory locks, `SET` variables, and `LISTEN/NOTIFY`. Know this before enabling it.

## Partitioning

Declarative native partitioning by range, list, or hash:

```sql
CREATE TABLE events (id bigint, created_at timestamptz) PARTITION BY RANGE (created_at);
```

**Benefits:** query pruning, and — most valuably — **`DROP TABLE` on an old partition instead of a mass `DELETE`**. Dropping a partition is instant; deleting millions of rows generates dead tuples and vacuum load.

Partitioning is **within one node**. For horizontal distribution, use Citus.

## Scaling Path

1. Indexes and query optimisation
2. Connection pooling (PgBouncer)
3. Read replicas
4. Caching
5. Partitioning large tables
6. Vertical scaling — often further than people expect
7. Citus, or application-level sharding
8. Migrate specific workloads elsewhere (search → Elasticsearch, events → Kafka)

**Exhaust steps 1–6 before distributing.**

## When To Choose Something Else

- Sustained writes far beyond one node → Cassandra (LSM)
- Petabyte analytics → a columnar warehouse
- Genuinely unknown, rapidly-changing access patterns at scale → DynamoDB
- Multi-region active-active with local writes → CockroachDB, Spanner, Cassandra

## Common Mistakes

- Abandoning it before measuring
- Ignoring vacuum and long transactions
- Thousands of direct connections
- `DELETE` for bulk cleanup instead of partition drop
- Assuming JSONB can't be indexed
- Leaving an unused replication slot
- Not enabling `pg_stat_statements`

## Related Topics

- [Database Indexing](../../05%20Databases/Indexing/Database%20Indexing.md)
- [Transactions and Isolation Levels](../../05%20Databases/Consistency%20and%20Transactions/Transactions%20and%20Isolation%20Levels.md)
- [Database Replication](../../05%20Databases/Replication%20and%20Failover/Database%20Replication.md)
- [SQL vs NoSQL](../../05%20Databases/SQL%20vs%20NoSQL/SQL%20vs%20NoSQL.md)

## Revision Summary

MVCC gives non-blocking reads at the cost of dead tuples and vacuum dependency. Rich index types — GIN for JSONB, BRIN for time series, partial and expression indexes — plus extensions for geospatial, vector, and time-series work make it the right default. Pool connections, partition for cheap deletes, and scale it hard before distributing.

## Quick Recall

- One node: 5–20K TPS, TB of data — further than most assume
- MVCC → readers don't block writers, but **VACUUM is mandatory**
- Long transactions cause bloat and block vacuum
- GIN for JSONB and full-text; BRIN for time series; partial indexes for filtered queries
- PostGIS, pgvector, TimescaleDB, pg_trgm — one system, many capabilities
- Process per connection → PgBouncer transaction pooling
- Partition to `DROP` instead of `DELETE`
- Logical replication → CDC → Debezium
