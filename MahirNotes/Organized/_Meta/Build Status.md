# Build Status

## Summary

- **147 notes**, 1,079 internal links, **0 broken**
- **Originals untouched** — 196 source markdown files, none created, modified, renamed, or deleted
- Cloud (12) deliberately skipped at your request

## Coverage

| Section | Notes | State |
|---|---|---|
| 00 Revision Roadmaps | 2 | 1-day emergency, 7-day plan |
| **01 DSA** | 33 | Near-complete |
| **02 Java** | 16 | Near-complete |
| **03 Low Level Design** | 28 | **Complete** — framework, SOLID, OOP, concurrency, all 23 GoF patterns |
| **04 High Level Design** | **27** | **Substantially complete** — see below |
| 05 Databases | 5 | Indexing, replication, sharding, SQL vs NoSQL, transactions |
| 06 Caching and Redis | 3 | Strategies, Redis structures, CDN |
| 07 Messaging and Kafka | 3 | Fundamentals, Kafka, idempotent consumers |
| 08 Microservices | 3 | Circuit breaker, API gateway, service mesh |
| 09 Distributed Systems | 4 | Two Generals, consensus, consistency, clocks |
| 10 Operating Systems | 3 | Processes/threads, memory, scheduling |
| 11 Networking | 2 | Essentials, HTTP and TLS |
| 12 Cloud | — | **Skipped by request** |
| 13 Kubernetes | 1 | Core concepts |
| 14 Spring Boot | 2 | Core/DI, transactions and AOP |
| 15 Company Prep | 3 | STAR, Amazon LPs, question bank |
| Cheat Sheets | 5 | DSA, Java concurrency, HLD, LLD, design patterns |
| Flash Cards | 3 | DSA, system design, Java |
| Interview Checklists | 3 | DSA, system design, LLD |
| Top 100 Questions | 1 | Self-test set |

## HLD Breakdown (27 notes)

| Group | Notes |
|---|---|
| **Interview Framework** | Delivery framework, back-of-the-envelope estimation |
| **Core Concepts** | CAP/PACELC, caching, consistent hashing, API design |
| **Patterns** | Scaling reads, scaling writes, rate limiting, real-time updates, saga/multi-step, large blobs, long-running tasks |
| **Key Technologies** | Redis, Elasticsearch, Cassandra, DynamoDB, PostgreSQL, ZooKeeper, stream processing/Flink |
| **Advanced Topics** | Event-driven architecture, data structures for big data, proximity/geospatial, time series and analytics |
| **Design Deep Dives** | URL shortener, chat system, news feed |

This covers the HelloInterview Core Concepts, Patterns, Key Technologies, and Advanced Topics syllabus (their sidebar was enumerated and used to scope coverage; notes were written from combined sources rather than transcribed).

## What Remains In HLD

| Gap | Priority |
|---|---|
| More worked designs — rate limiter, ticket booking, ad click aggregator, web crawler, payment system | **High** — designs are where levels get decided |
| Data modelling as a standalone core concept | Medium |
| Vector databases | Low — only for ML-adjacent roles |
| Search/recommendation deep dives | Low |

## Elsewhere

| Gap | Priority |
|---|---|
| Microservices — service discovery, observability, deployment patterns | Medium |
| Spring Boot — JPA/Hibernate pitfalls (N+1, lazy loading, fetch strategies) | Medium |
| Databases — specific database comparisons, fundamentals | Medium |
| DSA — string algorithms, math, problem lists | Low |
| Java — performance tuning, interview question bank | Low |
| Cloud | **Skipped** |

## The PDF Situation

Tesseract returns unusable noise — these are photographed **handwritten** pages. All 63 pages were rendered and inspected visually.

Ten of the sixteen cover topics now written in `Organized/` in more depth than the PDFs contain. **The six with no equivalent** — Chat System, Key-Value Database, URL Shortener, Back-of-Envelope, Load Balancer, Proxy Server — have since been partly superseded too: Chat System, URL Shortener, and Back-of-Envelope now have written notes.

**Genuinely uncovered: `9. Design Key-Value Database.pdf` (6 pages), `Load Balancer.pdf` (4 pages), `Proxy Server.pdf` (3 pages).**

Re-render with: `pdftoppm -r 50 -png -scale-to-x 1100 "<file>.pdf" out`

## Note On Provenance

DSA, Java, LLD, and much of HLD are built on your existing material — revising from them is recall.

OS, Networking, Kubernetes, and Spring Boot were written from scratch because no source existed. Those are good generic prep content, but revising from them is *learning*, which is slower and less reliable. Budget accordingly.

## Verification

- 1,079 internal links, 0 broken
- Breadcrumbs correct at every nesting depth
- Every populated folder indexed; empty folders marked planned
- Consistent template throughout
- Originals confirmed unmodified
