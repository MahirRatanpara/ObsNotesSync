# Elasticsearch

## Why It Matters

The default answer for full-text search, and increasingly for log analytics and faceted filtering. Interviewers check whether you understand *why* a search engine is a separate system rather than a database index.

## Core Idea

An **inverted index**: rather than mapping document → words, map word → documents containing it.

```
"quick" → [doc1, doc7, doc9]
"brown" → [doc1, doc3]
"fox"   → [doc1, doc7]
```

Searching "quick fox" intersects two small posting lists instead of scanning every document. **This is why a `LIKE '%term%'` query in Postgres is O(n) and Elasticsearch is effectively O(1) in the corpus size.**

## Analysis — Where Search Quality Comes From

Text passes through an analysis pipeline at both index and query time:

```
"The Quick Brown Foxes"
 → character filters (strip HTML)
 → tokenizer        → ["The","Quick","Brown","Foxes"]
 → token filters    → lowercase → stop-word removal → stemming
 → ["quick","brown","fox"]
```

**The index-time and query-time analysers must match**, or a query for "foxes" won't find a document indexed as "fox". Mismatched analysers are the most common cause of "search doesn't work".

## Document Model and Sharding

| Term | Meaning |
|---|---|
| **Index** | A collection of documents (roughly a table) |
| **Shard** | A Lucene index — the unit of distribution |
| **Replica** | A copy of a shard, serving reads and providing failover |
| Segment | An immutable Lucene file within a shard |

**Primary shard count is fixed at index creation.** Changing it requires reindexing. This is the single biggest operational constraint — over-shard and you pay per-shard overhead on every query; under-shard and you can't scale.

**Rule of thumb:** aim for 10–50 GB per shard.

## Near Real-Time, Not Real-Time

A document isn't searchable the moment it's indexed.

```
index → in-memory buffer → refresh (default 1s) → new segment → searchable
                         → translog (durability) → flush → Lucene commit
```

**Default refresh interval is 1 second**, so there's up to a second of lag. Setting it lower hurts throughput; setting it higher (30s) dramatically improves bulk indexing performance.

**Elasticsearch is not a source of truth.** No ACID transactions across documents, no joins, and it can lose data in edge cases. **Always keep a primary datastore and feed Elasticsearch from it** — via CDC (Debezium), a dual-write with an outbox, or a batch reindex. Saying this unprompted is a strong signal.

## Relevance Scoring

**BM25** (the default since ES 5) improves on TF-IDF:

| Component | Effect |
|---|---|
| **Term frequency** | More occurrences → higher score, **with saturation** |
| **Inverse document frequency** | Rare terms weigh more than common ones |
| **Field length normalisation** | A match in a short title beats one in a long body |

BM25's saturation is the key improvement — a document mentioning "java" 100 times isn't 100× more relevant than one mentioning it twice.

Tune with field boosts (`title^3`), function scores (recency, popularity), and `rescore` for expensive re-ranking of the top N only.

## Query Types

| Query | Behaviour |
|---|---|
| `match` | **Analysed** — full-text |
| `term` | **Not analysed** — exact value; use on `keyword` fields |
| `bool` (must / should / filter / must_not) | Boolean composition |
| `range` | Numeric and date ranges |
| `multi_match` | Across several fields |
| `nested` | Query nested objects independently |

**`filter` vs `must` is the performance question:** `filter` clauses don't compute a relevance score and are **cached**, so use `filter` for anything binary (status, date range, category) and `must` only where scoring matters.

**`text` vs `keyword` mapping** is the corresponding modelling question: `text` is analysed for search; `keyword` is exact and enables aggregation and sorting. Most string fields want both via a multi-field mapping.

## Aggregations

Faceted navigation, analytics, and dashboards:

```json
"aggs": { "by_brand": { "terms": { "field": "brand.keyword" },
          "aggs": { "avg_price": { "avg": { "field": "price" } } } } }
```

**Aggregations only work on `keyword`, numeric, and date fields**, not analysed `text` — a common modelling mistake.

At scale, `terms` aggregations return **approximate** counts, because each shard returns its own top N and they're merged. Exact counts require `shard_size` tuning or a different approach.

## Deep Pagination — The Classic Trap

`from: 10000, size: 10` forces **every shard** to return 10,010 documents to the coordinating node, which sorts 10,010 × shard_count results to discard almost all of them. Memory and CPU grow linearly with the offset.

Elasticsearch caps this at 10,000 by default.

| Need | Use |
|---|---|
| User-facing "next page" | **`search_after`** — cursor-based, uses the last sort value |
| Exporting the whole index | `scroll` (legacy) or **point-in-time + `search_after`** |

**This is the same offset-versus-cursor lesson as SQL pagination**, and it's asked frequently.

## When To Use It

**Good fit:** full-text search, log and event analytics, faceted product search, geospatial queries, autocomplete.

**Poor fit:** as a primary datastore, for transactional workloads, for frequently-updated documents (updates are delete + reindex), or for simple key lookups (Redis or a KV store is better).

## Alternatives

| Option | When |
|---|---|
| **Postgres full-text search** (`tsvector` + GIN) | Modest corpus, one fewer system to run — often the right call |
| OpenSearch | AWS fork, API-compatible |
| Typesense / Meilisearch | Simpler, lower-latency, smaller scale |
| Vector databases | Semantic rather than lexical search |

**"Would Postgres full-text search be enough?" is a legitimate and often-correct question.** Running Elasticsearch is real operational cost.

## Common Mistakes

- Using it as the source of truth
- Mismatched index-time and query-time analysers
- `must` where `filter` belongs — no caching, wasted scoring
- Deep pagination with `from`/`size`
- Aggregating on an analysed `text` field
- Too many shards for the data volume
- Assuming writes are immediately searchable

## Related Topics

- [Database Indexing](../../05%20Databases/Indexing/Database%20Indexing.md)
- [Scaling Reads](../Patterns/Scaling%20Reads.md)
- [Event Driven Architecture](../Advanced%20Topics/Event%20Driven%20Architecture.md)
- [Data Structures for Big Data](../Advanced%20Topics/Data%20Structures%20for%20Big%20Data.md)

## Revision Summary

An inverted index over analysed tokens, distributed across fixed-count shards, near-real-time with a 1-second refresh. Not a source of truth — feed it from a primary store via CDC. Use `filter` for non-scoring clauses and `search_after` instead of deep `from`/`size` pagination.

## Quick Recall

- Inverted index: term → document list
- Index-time and query-time analysers **must match**
- Shard count is fixed at creation; 10–50 GB per shard
- 1-second refresh → near real-time, not real-time
- **Never the source of truth** — sync via CDC
- `filter` is cached and unscored; `must` scores
- `text` for search, `keyword` for aggregation and sorting
- Deep pagination → `search_after`
