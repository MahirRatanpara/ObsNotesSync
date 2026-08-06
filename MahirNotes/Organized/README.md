# Interview Revision Knowledge Base

A revision-oriented rebuild of the notes in this repository, organised for fast recall rather than first-time learning.

**Your original folders are untouched.** Everything here is new and additive.

## Start Here

- **[Master Index](Master%20Index.md)** — every note, grouped by section
- **[Build Status](_Meta/Build%20Status.md)** — what is written, what is still planned, and what to do next

| Situation | Go to |
|---|---|
| Interview tomorrow | [1 Day Emergency Revision](00%20Revision%20Roadmaps/1%20Day%20Emergency%20Revision.md) |
| Interview in a week | [7 Day Revision Plan](00%20Revision%20Roadmaps/7%20Day%20Revision%20Plan.md) |
| Coding round in 15 min | [DSA Cheat Sheet](Cheat%20Sheets/DSA%20Cheat%20Sheet.md) |
| System design round in 15 min | [HLD Cheat Sheet](Cheat%20Sheets/HLD%20Cheat%20Sheet.md) |
| LLD round in 15 min | [LLD Cheat Sheet](Cheat%20Sheets/LLD%20Cheat%20Sheet.md) |
| Java round in 15 min | [Java Concurrency Cheat Sheet](Cheat%20Sheets/Java%20Concurrency%20Cheat%20Sheet.md) |

## How Notes Are Structured

Every note follows the same shape, so you always know where to look:

| Section | Purpose |
|---|---|
| **Why It Matters** | Why an interviewer cares |
| **Core Idea** | The one thing to understand |
| Templates / tables / Mermaid diagrams | The reusable mechanics |
| **Interview Explanation** | Wording you can say out loud |
| **Common Questions** | What gets asked as a follow-up |
| **Common Mistakes** | Where candidates lose points |
| **Related Topics** | Cross-links into the rest of the base |
| **Revision Summary** | A paragraph that reconstructs the note |
| **Quick Recall** | 4–6 bullets for the last five minutes |

**How to revise:** read Quick Recall first. If every bullet reconstructs into an explanation you could say aloud, move on. If any bullet is opaque, read that section of the note. This makes a full-topic pass take 10–15 minutes.

## Sections

| # | Section | Focus |
|---|---|---|
| 00 | Revision Roadmaps | Time-boxed study plans |
| 01 | DSA | Patterns, templates, complexity |
| 02 | Java | JVM, memory, collections, concurrency |
| 03 | Low Level Design | SOLID, patterns, OOP, LLD concurrency |
| 04 | High Level Design | Framework, core concepts, patterns, technologies |
| 05 | Databases | Indexing, replication, sharding |
| 06–08 | Caching, Messaging, Microservices | Redis, Kafka, resilience |
| 09 | Distributed Systems | CAP, consensus, consistency |
| 10–14 | OS, Networking, Cloud, K8s, Spring | Platform breadth |
| 15–16 | Company Prep, Miscellaneous | Behavioural and company-specific |
| — | Cheat Sheets | One-page rapid references |

Sections marked **planned** in the [Master Index](Master%20Index.md) are reserved in the structure but not yet written.

## Conventions

- Filenames are descriptive and searchable ("Cache Eviction", not "About Cache")
- Notes are short and single-topic — long files are split
- Every folder has an `Index.md`
- Links use relative paths, so the base works in Obsidian, VS Code, or GitHub
- Diagrams are Mermaid, used only where they add clarity

## Relationship to Your Original Notes

| Original | Where it went |
|---|---|
| `DSA/Pattern Recognition.md`, `Quick_Pattern_Revision_Guide.md` | Split into `01 DSA/Foundations/` and per-pattern notes |
| `Java/` (18 concurrency files, heavily overlapping) | Consolidated into `02 Java/Concurrency/` |
| `LLD/SOLID`, `LLD/Patterns/` (23 folders) | `03 Low Level Design/` |
| `HLD/Patterns/`, `HLD/Databases/`, `HLD/MQ/` | Split across sections 04–09 |
| 16 handwritten PDFs | **Not transcribed** — see [Build Status](_Meta/Build%20Status.md) |

Nothing was deleted or modified in the original folders.
