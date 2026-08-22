# Build Status

## Summary

- **212 notes**
- **Every link resolves** — 0 links point to a non-existent file
- Cloud (12) and Miscellaneous (16) skipped by request

**On link format:** Obsidian rewrote many links to its default "shortest path" form (just the filename). Because every note filename in this vault is unique, those resolve correctly **in Obsidian**. A plain-markdown checker flags them; that is a checker artefact, not a fault. If you want portable relative links, change Obsidian's *New link format* setting to "Relative path to file".

## Coverage

| Section | Notes | State |
|---|---|---|
| 00 Revision Roadmaps | 2 | 1-day, 7-day |
| **01 DSA** | 33 | **Complete** |
| **02 Java** | **51** | **Complete — zero to mastery** |
| **03 Low Level Design** | 28 | **Complete** — all 23 GoF patterns |
| **04 High Level Design** | 31 | **Complete** — 7 worked designs |
| **05 Databases** | 13 | **Complete** — full selection procedure |
| **06 Caching and Redis** | 7 | **Complete** |
| **07 Messaging and Kafka** | 6 | **Complete** |
| **08 Microservices** | 7 | **Complete** |
| **09 Distributed Systems** | 8 | **Complete** |
| 10 Operating Systems | 4 | Processes, memory, scheduling, preemption/migration mechanics |
| 11 Networking | 2 | Essentials, HTTP/TLS |
| 12 Cloud | — | **Skipped by request** |
| 13 Kubernetes | 1 | Core concepts |
| **14 Spring Boot** | 4 | **Complete** |
| 15 Company Prep | 3 | STAR, Amazon LPs, question bank |
| 16 Miscellaneous | — | Skipped |
| Cheat Sheets | 5 | DSA, Java concurrency, HLD, LLD, patterns |
| Flash Cards | 3 | DSA, system design, Java |
| Interview Checklists | 3 | DSA, system design, LLD |
| Top 100 Questions | 1 | Cross-domain self-test |

## Java — The Twelve Blocks (51 notes)

Start at **[Java Topic Map and Revision Plan](../02%20Java/00%20Learning%20Path/Java%20Topic%20Map%20and%20Revision%20Plan.md)** — full checklist plus a 24-hour plan.

| Block | Notes | Contents |
|---|---|---|
| 00 Learning Path | 1 | Topic map, complete checklist, 24-hour plan |
| **Language Core** | 7 | Types/autoboxing, strings, pattern matching, date/time, equals/hashCode, exceptions+generics (legacy), modern features |
| **OOP** | 6 | Inheritance/polymorphism, abstract vs interface, nested/inner classes, immutability, Object contract, records/enums/sealed |
| **Generics** | 1 | Erasure, variance, PECS, bridge methods, type tokens |
| **Exceptions** | 1 | Hierarchy, try-with-resources, suppression, design |
| **Collections** | 6 | Overview, ArrayList internals, HashMap internals, TreeMap/sorted, Comparable/Comparator, specialised |
| **Streams and Functional** | 5 | Lambdas/invokedynamic, streams, collectors, Optional, parallel/Spliterators |
| **Concurrency** | 10 | Threads, locks, atomics/CAS, executors, CompletableFuture, concurrent collections, synchronizers, fork/join, **virtual threads + structured concurrency**, problem patterns |
| **JVM and Memory** | 7 | Architecture, memory model, class loading, JIT/escape analysis, reference types/Cleaner, bytecode/reflection/method handles, memory leaks |
| **Garbage Collection** | 1 | Collectors, tuning, container accounting |
| **IO and Serialization** | 2 | java.io/NIO/zero-copy, serialization security |
| **Modern Java** | 2 | Version guide 8→25, JPMS modules |
| **Performance** | 1 | Profiling, JMH, leak diagnosis |
| **Interview Questions** | 1 | Question bank across all blocks |

## What Remains

Nothing that would change an interview outcome.

| Gap | Note |
|---|---|
| Cloud (12), Miscellaneous (16) | Skipped by request |
| Kubernetes beyond core concepts | Platform roles only |
| DSA string algorithms, math, problem lists | Marginal |

## Provenance — Read Before Revising

| Built on your notes | Written from scratch |
|---|---|
| DSA, LLD, most of HLD, Databases, Caching, Messaging, Distributed Systems | **Java (this expansion)**, OS, Networking, Kubernetes, Spring Boot, parts of Microservices |

The Java expansion was written independently, as requested — not derived from your existing notes. **Revising it is first-time learning, not recall**, which is slower and less durable. Budget accordingly.

## How To Use This

Reading creates recognition, not recall. The material is built for retrieval practice:

1. **Quick Recall** at the foot of each note — if every bullet reconstructs into a spoken explanation, move on
2. **Question banks and flash cards** — cover the answers, answer aloud, mark misses
3. **Design deep dives** — whiteboard one cold, timed, *before* rereading
4. **Checklists** — during mocks, not after

Anything missed twice is a genuine weak area. Everything else is noise.
