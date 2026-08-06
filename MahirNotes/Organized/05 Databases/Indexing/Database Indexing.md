# Database Indexing

## Why It Matters

The most common cause of production slowness, and a guaranteed follow-up in any system design round involving a relational database.

## Core Idea

An index is a separate sorted structure mapping column values to row locations. It trades **write speed and disk space** for **read speed**.

Databases read and write in fixed-size **pages** (typically 8 KB in Postgres, 16 KB in InnoDB), never individual rows. A page is the smallest unit of I/O. Without an index, finding one row means a full table scan — reading every page.

## B+ Tree — Why This Structure

Almost all relational indexes are B+ trees, not binary trees or hash tables:

| Property | Consequence |
|---|---|
| High fan-out (hundreds of keys per node) | Depth 3–4 even for billions of rows → 3–4 disk seeks |
| **All data in leaf nodes** | Internal nodes hold only keys, so more fit per page |
| **Leaves linked** | Range scans are sequential, no tree re-traversal |
| Balanced | Guaranteed O(log n) |

A binary tree with a billion rows would be 30 levels deep — 30 random disk seeks. A B+ tree is 3–4. **That gap is the whole reason B+ trees exist.**

Hash indexes give O(1) point lookups but **cannot do range queries or ordering** — which is why they're rarely the default.

## Clustered vs Non-Clustered

| | Clustered | Non-clustered (secondary) |
|---|---|---|
| Contains | **The actual row data**, in key order | Key + pointer to the row |
| Count per table | **One** | Many |
| Lookup | One traversal | Two: index, then the row |
| InnoDB | Primary key | Points to the **primary key** |
| Postgres | None (heap tables) | Points to a physical tuple id (ctid) |

**InnoDB secondary indexes store the primary key, not a physical address.** This is why a large primary key (e.g. a UUID string) bloats every secondary index. It also means row movement doesn't invalidate secondary indexes.

**Postgres has no clustered index** — tables are heaps and every index is secondary. This is a good detail to know if asked to compare.

## The Second Lookup (Bookmark Lookup)

```sql
SELECT name, email FROM users WHERE email = 'x@y.com';
-- 1. traverse the email index → find the primary key
-- 2. traverse the clustered index → fetch the row for `name`
```

**Covering index** eliminates step 2 by including every column the query needs:

```sql
CREATE INDEX idx_email_name ON users(email) INCLUDE (name);
```

The query is then answered entirely from the index — an "index-only scan". This is one of the highest-value optimisations to mention.

## Composite Indexes — The Leftmost Prefix Rule

`INDEX (a, b, c)` can serve queries filtering on:

- `a`
- `a, b`
- `a, b, c`

But **not** `b`, `c`, or `b, c` — the index is sorted by `a` first, so without `a` there's no usable ordering.

**Column order rules:**
1. Equality columns before range columns
2. Highest selectivity first among equality columns
3. Columns used for `ORDER BY` last, matching the sort direction

```sql
-- Query: WHERE status = 'active' AND created_at > '2024-01-01' ORDER BY created_at
CREATE INDEX idx ON orders(status, created_at);   -- equality, then range
```

**A range column stops the index from being used for anything after it.** With `INDEX(a, b, c)` and `WHERE a = 1 AND b > 5 AND c = 3`, the `c` condition can't use the index.

## When Indexes Are Not Used

| Cause | Example | Fix |
|---|---|---|
| Function on the column | `WHERE YEAR(created) = 2024` | Expression index, or rewrite as a range |
| Implicit type cast | `WHERE varchar_col = 123` | Match types |
| Leading wildcard | `LIKE '%abc'` | Full-text index or a reversed column |
| Low selectivity | `WHERE gender = 'M'` | A scan genuinely is cheaper |
| Stale statistics | — | `ANALYZE` |
| `OR` across columns | `WHERE a = 1 OR b = 2` | `UNION` of two indexed queries |

**Rewriting `WHERE YEAR(created) = 2024` as `WHERE created >= '2024-01-01' AND created < '2025-01-01'` is a classic interview answer.**

## Cost of Indexes

Every index must be updated on every `INSERT`, `UPDATE` of an indexed column, and `DELETE`. Ten indexes means ten B+ tree updates per write. Indexes also consume disk and buffer-pool memory, competing with data pages.

**Rule of thumb:** index for your actual query patterns; drop indexes with no recorded usage (`pg_stat_user_indexes`).

## Reading a Query Plan

```sql
EXPLAIN ANALYZE SELECT ...;
```

| Node | Meaning |
|---|---|
| Seq Scan | Full table scan — fine for small tables, a red flag for large ones |
| Index Scan | Index traversal, then row fetch |
| **Index Only Scan** | Answered entirely from the index — best case |
| Bitmap Heap Scan | Many matches; collect row ids, then fetch in physical order |
| Nested Loop | Good when one side is small |
| Hash Join | Good for large unsorted inputs |
| Merge Join | Good when both inputs are already sorted |

**Compare estimated vs actual row counts.** A large discrepancy means stale statistics and a bad plan.

## Other Index Types

| Type | Use |
|---|---|
| B-tree | Default: equality, range, ordering |
| Hash | Equality only |
| **GIN** | Full-text search, JSONB, array containment |
| GiST | Geometric and nearest-neighbour |
| **BRIN** | Huge tables with naturally ordered data (time-series); tiny footprint |
| Partial | `WHERE deleted_at IS NULL` — index only the rows you query |

**Partial indexes** are underused and worth mentioning: indexing only active rows can shrink an index by 90%.

## Common Mistakes

- Indexing every column
- Wrong composite column order
- Wrapping the indexed column in a function
- Using a UUID primary key in InnoDB — random insert order fragments the clustered index (use ULID or a sequential UUID variant)
- Never checking `EXPLAIN`
- Ignoring write amplification from too many indexes

## Related Topics

- [Database Partitioning and Sharding](../Partitioning%20and%20Sharding/Partitioning%20and%20Sharding.md)
- SQL vs NoSQL *(not yet written)*
- [Scaling Reads](../../04%20High%20Level%20Design/Patterns/Scaling%20Reads.md)

## Revision Summary

B+ trees give depth 3–4 and linked leaves for range scans. One clustered index holds the data; secondary indexes need a second lookup unless covering. Composite indexes obey the leftmost prefix rule. Every index taxes writes.

## Quick Recall

- B+ tree: high fan-out, data in leaves, leaves linked
- InnoDB secondary → primary key; Postgres has no clustered index
- Covering index → index-only scan
- Leftmost prefix; equality before range
- Function on a column kills the index
- `EXPLAIN ANALYZE`: compare estimated vs actual rows
