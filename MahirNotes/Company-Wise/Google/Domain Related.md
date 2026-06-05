
### Generic Research:

- distributed-systems mastery (consistency, consensus, replication, partitioning, fault tolerance, leader election, exactly-once)
- rehearse it as a structured "why X over Y / failure modes / scaling limits / what I'd do differently" narrative.
- AI Tools Fluency
- The practical implication: even in a domain round, _how you reason_ matters as much as _what you already know_ — so think out loud and reason from first principles rather than reciting memorized facts
- a basis for a deeper conversation about correctness, synchronization, scalability, performance, and resource usage.
- intuitively understand the trade-offs described in the CAP theorem, who have practical experience with consensus algorithms like Paxos or Raft, and who have built systems that can survive network partitions, machine failures, and datacenter-level outages.
- So expect resume depth to be probed in more than one round.

### Possible breakdown:

Given your profile (3.5 YoE, distributed backend, Cloud profile, recruiter-named domain round), prepare for a **hybrid** structured roughly as:

- **~10–15 min: Past-project deep dive.** Almost certainly your stress-testing orchestration engine. Expect "walk me through the architecture," then relentless "why" follow-ups.
- **~15–25 min: A distributed-systems design or scenario problem.** Likely an archetype adjacent to your experience: design a distributed job/task scheduler, a rate limiter, a distributed cache, a message queue, an object/blob store, or a monitoring/metrics system. At L4 the bar is "clean, maintainable, scalable services," not planet-scale. Clarify requirements, define APIs, sketch components (client → service → queue → workers → storage), pick storage with justification tied to access patterns, then discuss bottlenecks, failure modes, and trade-offs. Do NOT over-engineer or name-drop — L4 candidates who "try to sound senior" with unjustified complexity hurt themselves.
- **~10–20 min: A scoped coding/implementation problem** (if coding is included), often connected to the discussion — e.g., implement an LRU cache, a token-bucket rate limiter, a thread-safe bounded queue, or a dependency/topological-sort problem (one 2025 India Cloud round was a "disks and snapshots" dependency-graph problem that was really topological sort in disguise).

### Distributed-systems concepts to have crisp

Prioritised for a Cloud backend role:

- **Consistency models:** strong vs eventual, linearizability (the "recency guarantee" / single-copy illusion), causal consistency, read-your-writes, monotonic reads. Be able to say which replication scheme gives which guarantee.
- **Replication:** single-leader (potentially linearizable), multi-leader (conflict resolution), leaderless/quorum (w + r > n, sloppy quorums, hinted handoff), synchronous vs async vs semi-sync, replication lag, failover and its risks.
- **Partitioning/sharding:** by key range vs hash, consistent hashing, hot spots/hot partitions, rebalancing, partitioning secondary indexes (by document vs term).
- **Consensus & coordination:** Paxos vs Raft (Raft = terms, leader election, log replication, dedup by request ID), total order broadcast, ZooKeeper/etcd/Chubby as coordination services, fencing tokens, FLP impossibility, split-brain avoidance.
- **CAP / PACELC:** the actual trade-off (during a partition, choose C or A; else latency vs consistency).
- **Fault tolerance & delivery semantics:** at-most-once vs at-least-once vs effectively-once; why exactly-once delivery is impossible at the network level and how idempotency + dedup achieve its effect; heartbeats, timeouts, retries, idempotency keys, dead-letter queues, the Two Generals problem. [Algoroq](https://www.algoroq.io/interview-questions/distributed-systems/)
- **Leader election:** distributed locks with TTL (e.g., Redis SET NX EX) as a best-effort dedup, consensus-based election for correctness, why wall-clock validity is unsafe (clock skew).

### Topics, prioritized for backend/distributed roles:

- graphs (BFS/DFS, topological sort, shortest path), heaps/priority queues, hashing, intervals/sweep line, tries, binary search, plus design-heavy problems: LRU/LFU cache, rate limiter (token bucket / sliding window), thread-safe data structures, producer-consumer/bounded buffer, and class-design problems (implement a class with several methods). Concurrency problems are plausible given your async/actor background.
- - **Design Patterns & Architecture:** Microservices, service mesh, event-driven architecture (pub/sub, event sourcing), circuit breakers, bulkheads, retry/backoff policies. Domain-Driven Design (DDD) for API boundaries. Use cases: e.g. caching pattern (Cache-Aside), CQRS, database transaction log (like Kafka). Architectural patterns like multi-tier web, lambda architecture (for analytics), and Polyglot persistence.
- Java is fully supported and is your strongest — use it. Know its concurrency primitives (ConcurrentHashMap, BlockingQueue, locks, atomics) cold in case a concurrency problem appears.

**Given a short runway (next few days), allocate roughly:**

- **~40% — Past-project deep-dive rehearsal.** Write and say aloud the orchestration-engine narrative with all the "why X over Y," failure-mode, and scaling-limit answers above. Prepare 2–3 projects total (add the farm-management full-stack platform as a secondary story for breadth/ownership/solo-delivery). Practice going three levels deep on each major decision.
- **~30% — Distributed-systems concepts.** Drill the consistency/replication/partitioning/consensus/CAP/delivery-semantics list. The fastest high-quality source for your timeline is the relevant chapters of _Designing Data-Intensive Applications_ (Kleppmann): Ch. 5 (Replication), Ch. 6 (Partitioning), Ch. 8 ("The Trouble with Distributed Systems" — unreliable networks/clocks/partial failures, directly relevant to your orchestration deep-dive), and Ch. 9 (Consistency & Consensus), plus skim Ch. 1 and 3. (These chapter numbers are for the 1st edition, O'Reilly 2017; a 2nd edition published in 2025, so confirm the edition if numbering differs.) Supplement with a distributed-job-scheduler design walkthrough since it maps directly to your work. [System Design Space](https://system-design.space/en/chapter/ddia-book/)
- **~20% — Coding warm-up in Java.** ~20–30 recent Google-tagged Mediums plus a few Hards, biased to graphs, heaps, intervals, and design problems (LRU cache, rate limiter). Practice in a plain doc, no IDE. Use LeetCode Discuss candidate-reported questions over the generic "Google" premium tag.
- **~10% — Google infra context + Googliness.** Skim GFS/Spanner/Chubby/Borg summaries; prepare 6–8 STAR stories (leadership, conflict, ambiguity, failure, impact) for the inevitable behavioral/Googleyness elements.