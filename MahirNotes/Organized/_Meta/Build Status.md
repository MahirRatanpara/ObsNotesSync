# Build Status

## Summary

- **180 notes**, 1,351 internal links, **0 broken**
- **Originals untouched** — 196 source markdown files, none created, modified, renamed, or deleted
- Cloud (12) and Miscellaneous (16) skipped by request

## Coverage

| Section                    | Notes | State                                                       |
| -------------------------- | ----- | ----------------------------------------------------------- |
| 00 Revision Roadmaps       | 2     | 1-day emergency, 7-day plan                                 |
| **01 DSA**                 | 33    | **Complete**                                                |
| **02 Java**                | 20    | **Complete**                                                |
| **03 Low Level Design**    | 28    | **Complete** — all 23 GoF patterns                          |
| **04 High Level Design**   | 31    | **Complete** — 7 worked designs                             |
| **05 Databases** | 13 | **Complete** — full selection procedure, storage engines, modelling, query tuning, migrations, locking, pooling |
| **06 Caching and Redis**   | 7     | **Complete**                                                |
| **07 Messaging and Kafka** | 6     | **Complete**                                                |
| **08 Microservices**       | 7     | **Complete**                                                |
| **09 Distributed Systems** | 8     | **Complete**                                                |
| 10 Operating Systems       | 3     | Processes/threads, memory, scheduling                       |
| 11 Networking              | 2     | Essentials, HTTP and TLS                                    |
| 12 Cloud                   | —     | **Skipped by request**                                      |
| 13 Kubernetes              | 1     | Core concepts                                               |
| **14 Spring Boot**         | 4     | **Complete**                                                |
| 15 Company Prep            | 3     | STAR, Amazon LPs, question bank                             |
| 16 Miscellaneous           | —     | Skipped                                                     |
| Cheat Sheets               | 5     | DSA, Java concurrency, HLD, LLD, design patterns            |
| Flash Cards                | 3     | DSA, system design, Java                                    |
| Interview Checklists       | 3     | DSA, system design, LLD                                     |
| Top 100 Questions          | 1     | Cross-domain self-test                                      |

## Section Detail

**06 Caching and Redis (7)** — caching strategies, **eviction policies** (LRU/LFU/W-TinyLFU), **invalidation** (ordering, CDC, version namespacing), **distributed caching** (partitioning, hot keys, failure behaviour), Redis data structures, **Redis persistence and HA** (RDB/AOF, Sentinel, Cluster), CDN.

**07 Messaging and Kafka (6)** — messaging fundamentals, Kafka deep dive, **Kafka vs SQS vs RabbitMQ**, idempotent consumers, **retries and dead letter queues**, **transactional outbox**.

**05 Databases (13)** — **Choosing the Right Database** (the 9-step selection procedure for HLD problems), **Storage Engines** (B-tree vs LSM, row vs column, the three amplifications), **Data Modelling and Schema Design** (normalisation, denormalisation, query-first NoSQL modelling, key choice), **Query Optimisation** (EXPLAIN, plan reading, sargability, rewrites), **Schema Migrations and Evolution** (expand–contract, locking, backfills), **Connection Management and Pooling**, **Locking and Concurrency Control**, **Database Comparison Reference**, indexing, replication/failover, partitioning/sharding, SQL vs NoSQL, transactions and isolation.

**09 Distributed Systems (8)** — Two Generals, **fallacies and failure modes** (gray failure, cascading, metastable), consensus algorithms, consistency models, **CRDTs and conflict resolution**, clocks and ordering, **failure detection and recovery** (Phi Accrual, gossip, fencing), **distributed transactions** (2PC/3PC vs saga).

## What Remains

Nothing that would change an interview outcome.

| Gap | Note |
|---|---|
| Cloud (12), Miscellaneous (16) | Skipped by request |
| DSA string algorithms, math, problem lists | Marginal — pattern coverage is complete |
| Kubernetes beyond core concepts | Only for platform-focused roles |
| Networking beyond the two notes | Covers what backend loops ask |

## The PDF Situation

Tesseract returns unusable noise — these are photographed **handwritten** pages. All 63 pages were rendered and inspected visually.

Thirteen of the sixteen cover topics now written in `Organized/` in more depth. **Genuinely uncovered: `9. Design Key-Value Database.pdf` (6 pages), `Load Balancer.pdf` (4 pages), `Proxy Server.pdf` (3 pages).**

Re-render with: `pdftoppm -r 50 -png -scale-to-x 1100 "<file>.pdf" out`

## Provenance — Read This Before Revising

| Built on your notes | Written from scratch |
|---|---|
| DSA, Java, LLD, most of HLD, Databases, Caching, Messaging, Distributed Systems | OS, Networking, Kubernetes, Spring Boot, parts of Microservices |

**Revising the first group is recall — fast and durable. The second is first-time learning — slower and less reliable.** Don't mistake fluency in the second group for competence in it.

## How To Use This

Reading creates familiarity that feels like knowledge. It isn't. The material is structured for retrieval practice:

1. **Quick Recall** at the foot of each note — if every bullet reconstructs into a spoken explanation, move on
2. **Flash Cards** and **question banks** — cover the answers, answer aloud, mark misses
3. **Design Deep Dives** — whiteboard one cold with a 45-minute timer *before* rereading; the gap is your real signal
4. **Interview Checklists** — use during mocks, not after

Anything missed twice is a genuine weak area. Everything else is noise.

## Verification

- 1,351 internal links, 0 broken
- Breadcrumbs correct at every nesting depth
- Every populated folder indexed; skipped folders marked
- Consistent template throughout
- Originals confirmed unmodified
