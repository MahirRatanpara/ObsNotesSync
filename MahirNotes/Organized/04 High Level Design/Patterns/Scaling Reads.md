# Scaling Reads

## Why It Matters

Most systems are read-heavy, often 100:1 or worse. Read scaling is usually the first bottleneck you hit and the easiest to solve well.

## The Progression — Apply In Order

Each step is cheaper and less disruptive than the next. **Don't skip ahead.**

### 1. Query and Index Optimisation (free)
Find the slow queries (`pg_stat_statements`), run `EXPLAIN ANALYZE`, add covering indexes, eliminate N+1 queries. Often yields 10–100× with no architecture change. Candidates who jump straight to "add Redis" miss this.

### 2. Connection Pooling
Databases handle a few hundred connections well, not thousands. PgBouncer or HikariCP multiplex many application connections onto few database ones. Cheap, high impact.

### 3. Read Replicas
Route reads to followers, writes to the primary.

- Scales reads roughly linearly with replica count
- **Does not scale writes** — every replica applies every write
- Introduces **replication lag** → read-after-write anomalies
- Route a user's reads to the primary for a few seconds after their write

### 4. Caching
See [Caching](../Core%20Concepts/Caching.md). Cache-aside with delete-on-write. Biggest single win for hot data, and it removes load rather than adding capacity.

### 5. CDN
For anything static or cacheable. A CDN hit never touches your infrastructure at all — the cheapest possible read.

### 6. Denormalisation and Materialised Views
Precompute expensive joins and aggregates. Trades write cost and storage for read speed. Refresh synchronously, on a schedule, or via CDC.

### 7. Read-Optimised Replicas
A separate store shaped for a specific query type: Elasticsearch for search, a columnar store for analytics, a graph DB for traversals. Kept in sync via CDC or dual writes.

## Decision Table

| Symptom | Fix |
|---|---|
| A few slow queries | Indexes, query rewrite |
| Connection exhaustion | Pooling |
| High read QPS, uniform | Read replicas |
| High read QPS, skewed to hot keys | Cache |
| Static assets | CDN |
| Expensive joins/aggregates | Materialised views |
| Full-text search | Elasticsearch |
| Analytics on the OLTP database | Separate OLAP store |

## Fan-Out: The Classic Read-Scaling Problem

For a feed or timeline:

| Approach | Write cost | Read cost | Good for |
|---|---|---|---|
| **Fan-out on write (push)** | O(followers) | O(1) | Most users |
| **Fan-out on read (pull)** | O(1) | O(following) | Celebrities |
| **Hybrid** | Mixed | Mixed | **Production answer** |

**Hybrid:** push to followers for ordinary users; for accounts above a follower threshold, don't push — pull their posts at read time and merge. This avoids writing to 100 million inboxes when a celebrity posts.

**This is the single most common HLD deep dive.** Know it cold.

## Replication Lag Handling

| Technique | Trade-off |
|---|---|
| Read from primary after write | Extra primary load |
| Sticky session to one replica | Uneven replica load |
| Wait for a version/LSN | Added latency |
| Accept staleness | Simplest; often fine |

## Monitoring

| Metric | Watch for |
|---|---|
| Cache hit rate | Below ~80% suggests poor key choice or TTL |
| Replication lag | Remove lagging replicas from the pool |
| p99 read latency | Not the average — averages hide the problem |
| Connection pool saturation | Precedes visible failures |

## Common Mistakes

- Adding a cache before fixing an obviously missing index
- Reading from a replica immediately after a write
- Treating read replicas as a write-scaling solution
- Caching without measuring the hit rate
- Making the cache a hard dependency — a cache outage should degrade, not fail
- Pure fan-out-on-write with no celebrity handling

## Related Topics

- [Scaling Writes](Scaling%20Writes.md)
- [Caching](../Core%20Concepts/Caching.md)
- [Database Indexing](../../05%20Databases/Indexing/Database%20Indexing.md)
- [Database Replication](../../05%20Databases/Replication%20and%20Failover/Database%20Replication.md)

## Revision Summary

Optimise queries, pool connections, add replicas, cache, push to a CDN, then denormalise. Replicas scale reads not writes and introduce lag. Feed fan-out should be hybrid.

## Quick Recall

- Index before cache
- Replicas scale reads only
- Cache-aside + delete on write
- CDN hits never reach you
- Hybrid fan-out: push for normal users, pull for celebrities
- Watch p99, not the average
