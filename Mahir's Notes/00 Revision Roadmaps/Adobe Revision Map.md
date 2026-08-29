# Adobe CS1 — 4-Day Preparation Plan

**Target:** Computer Scientist 1, Adobe Noida (virtual drive, Sept 4) **Profile:** Java/backend, ~4 YOE, Deutsche Bank (CREST) + ShivAgri **Resources:** LeetCode Premium, HelloInterview Premium **Format:** ~14 productive hours/day across 4 days (~56 hours total)

---

## Read this before you start

**Three things about this plan that differ from the source document you pasted:**

1. **DSA is deliberately down-weighted to ~20% of the hours.** You already did a full Google L4 loop prep — 100 Hard frequency-ranked problems, graph frameworks, KMP, digit DP. Your DSA _knowledge_ is not the gap. Your DSA _speed and first-attempt correctness_ is. Those need drills, not new learning.
2. **LLD gets the largest share of new hours.** It's your self-identified weakest area, and it is a full standalone round at Adobe with equal weight to DSA and HLD. This is the highest-expected-value place to spend time.
3. **Concurrency is retrieval practice, not study.** You already did seven concurrency mock drills. You don't re-read; you re-code from a blank file.

**The 15-hour figure:** the plan schedules 14 hours of work and 7 hours of sleep. Cutting sleep below 7 hours to hit 15 hours is a net loss — you'd be trading the exact faculties (working memory, recall speed, verbal fluency under pressure) that these interviews test. Do 14 focused hours and sleep, not 15 degraded ones.

**"Cover as much as I can" is the wrong objective.** Adobe rejection reports cluster around _depth_ failures — a working solution that wasn't optimized, a design the candidate couldn't defend, a resume claim that fell apart under three follow-up questions. Nobody gets rejected for not having seen a 12th LLD problem. Depth on fewer things beats coverage.

---

## Rules of engagement (apply to every block)

- [x] **Every block produces an artifact.** Code that compiles, a diagram you drew, or a written one-pager. Reading without output does not count as done.
- [x] **Talk out loud.** Every problem, every design. If you can't narrate it, you can't interview it.
- [x] **No autocomplete, no AI, no IDE hints** during timed work. Adobe's posting bars AI tools in live interviews — train the way you'll perform.
- [x] **Timer on every problem.** Overrunning is data. Note it.
- [x] **After every wrong/slow attempt, write one line:** what specifically went wrong. Review that list on Day 4.
- [x] **Never stop at the first working solution.** Ask "can this be better?" before the interviewer does. This is the single most reported Adobe rejection reason.

---

## Daily schedule template

|Block|Time|Length|
|---|---|---|
|A|06:30 – 09:00|2.5h|
|_break_|09:00 – 09:30|—|
|B|09:30 – 12:30|3h|
|_lunch + walk_|12:30 – 13:15|—|
|C|13:15 – 16:15|3h|
|_break_|16:15 – 16:45|—|
|D|16:45 – 19:45|3h|
|_dinner_|19:45 – 20:30|—|
|E|20:30 – 23:00|2.5h|

Shift the whole window if you're not a morning person, but keep the block lengths and the breaks.

---

# DAY 1 — LLD foundation + DSA speed calibration

**Goal by end of day:** you can take any LLD prompt and produce requirements → entities → class diagram → interfaces → working core code in 45 minutes without freezing.

## Block A (2.5h) — Design principles and patterns, written from scratch

Do not read pattern articles. Open a blank Java file and implement each one, then write two lines on when you'd _reject_ it.

- [ ] SOLID — write one concrete violation and its fix for each of the five (from real code you've written, not textbook examples)
- [ ] Composition vs inheritance — write the same feature both ways, argue for one
- [ ] Interface vs abstract class — when each, with an example
- [ ] **Strategy** — implement, then answer: why this instead of subclassing?
- [ ] **Factory + Abstract Factory** — implement, note the difference in one sentence
- [ ] **Observer** — implement, note the failure mode (listener leak, ordering)
- [ ] **Builder** — implement with validation in `build()`
- [ ] **Singleton, thread-safe** — implement three ways (eager, double-checked with `volatile`, enum). Be able to explain why DCL needs `volatile`.
- [ ] **Decorator** — implement
- [ ] **State** — implement (this shows up in vending machine / elevator / order flows)
- [ ] **Command** — implement (shows up in undo, job scheduling)

**Checkpoint:** close everything, write the class skeleton for Strategy and Observer from memory.

## Block B (3h) — LLD problems 1 and 2

Method for every LLD problem, timed:

```
5 min   clarify requirements + explicit out-of-scope list
5 min   identify entities and responsibilities
10 min  class diagram: relationships, interfaces, enums
20 min  code the core classes (real Java, compiles)
5 min   concurrency + edge cases + extension question
```

- [ ] **Parking Lot** (45 min timed, then 30 min review)
    - [ ] Multiple floors, vehicle types, pricing strategy pluggable
    - [ ] Answer: how do two threads not book the same spot?
    - [ ] Answer: how do you add a new pricing model without touching existing code?
- [ ] **Vending Machine** (45 min timed, then 30 min review)
    - [ ] State pattern, coin/change handling, inventory
    - [ ] Answer: what happens on payment success but dispense failure?

## Block C (3h) — LLD problems 3 and 4

- [ ] **Splitwise** (45 min + review)
    - [ ] Expense splitting strategies (equal/exact/percent), balance simplification
    - [ ] Answer: how do you settle debts minimally? (this turns into a small algorithm — be ready)
- [ ] **Rate Limiter** (45 min + review)
    - [ ] Implement token bucket AND sliding window log AND sliding window counter in Java
    - [ ] Make it thread-safe. Explain the lock granularity you chose.
    - [ ] Answer: how does this change when it's distributed? (bridges into Day 2 HLD)

## Block D (3h) — DSA speed drill

Use **LeetCode Premium → Company tag: Adobe → sort by frequency → last 6 months → Medium.**

- [ ] 6 problems, **25-minute hard cap each**
- [ ] Rule: state brute force + complexity out loud BEFORE writing any code
- [ ] Rule: after the optimal solution works, spend 3 minutes on "can space be reduced?"
- [ ] Log for each: time taken, whether it ran correctly first attempt, what broke

**Adobe-specific:** interviewers reportedly expect code that works on the first run. Track your first-attempt-correct rate today. If it's below 4/6, that's your real weakness and you drill it again Day 3 Block E.

## Block E (2.5h) — Consolidation

- [ ] Redraw the Parking Lot and Rate Limiter class diagrams from memory, no notes
- [ ] Write a one-page "LLD interview script" — the exact sentences you'll open with, ask with, and close with
- [ ] Review the day's error log; write the pattern you see
- [ ] Bed by midnight

---

# DAY 2 — HLD / System Design

**Goal by end of day:** you have one framework you execute automatically, and you can defend every component choice with a trade-off, not an adjective.

## Block A (2.5h) — Framework + core concepts

Use **HelloInterview → Core Concepts** and their delivery framework.

- [ ] Internalize the framework: Requirements (functional + non-functional) → Core Entities → API → High-Level Design → Deep Dives
- [ ] Write it on paper 3 times until it's automatic under stress
- [ ] Core concepts pass: scaling, CAP/consistency models, partitioning, replication, caching strategies, networking basics, load balancing
- [ ] For each concept write the **one question an interviewer would use to expose shallow knowledge**, and answer it

**The trap to kill today:** "Kafka because it's scalable" and "Redis because it's fast." For every technology, prepare the sentence: _"I'd pick X here because of [specific property], and I'd give up [specific cost]. If [condition changed], I'd use Y instead."_

## Block B (3h) — HLD problems 1 and 2

Timed 45 min each, then 30 min review against the HelloInterview writeup.

- [ ] **URL Shortener / Bitly** — key generation, collision, read-heavy caching, redirect analytics
    - [ ] Do the actual number estimation. Write QPS, storage/year, cache size.
- [ ] **Distributed Rate Limiter** — Redis-based, sync across nodes, clock skew, failure mode when Redis is down
    - [ ] Connect it back to yesterday's LLD version explicitly

## Block C (3h) — HLD problems 3 and 4 (Adobe-flavored)

- [ ] **File Storage / Dropbox** — chunking, dedup, multipart upload, metadata vs blob split, sync
- [ ] **Document Processing Service** — this appeared in a 2025 CS1 loop
    - [ ] Upload → queue → workers → result store
    - [ ] Versioning, access control, soft vs hard delete
    - [ ] Large files (what breaks at 5 GB?)
    - [ ] Long-running processing: how does the client learn it's done? (polling vs webhook vs websocket — pick one, defend it)
    - [ ] Idempotency on retry

## Block D (3h) — Key technologies, one page each

Use **HelloInterview → Key Technologies.** Format for each: what it is, the one thing it's genuinely good at, when I'd reject it, one failure mode.

- [ ] **Kafka** — partitions, consumer groups, ordering guarantees, at-least-once vs exactly-once, DLQ, consumer lag, rebalancing. Answer: _why Kafka and not RabbitMQ / SQS here?_
- [ ] **Redis** — cache-aside vs write-through, TTL, eviction policies, distributed lock (and why Redlock is contested), hot keys, cache stampede, invalidation
- [ ] **PostgreSQL** — indexes, B-tree, transactions, isolation levels, when it stops being enough
- [ ] **Cassandra / DynamoDB** — partition key design, when wide-column beats relational
- [ ] **S3 / object store** — when metadata goes in a DB and bytes go in a blob store
- [ ] **Elasticsearch** — inverted index, when you actually need it vs a LIKE query

**You have real Kafka/Redis/distributed experience from CREST. This is your edge in the HLD round — but only if you can articulate the decisions, not just the components.**

## Block E (2.5h) — HLD problem 5

- [ ] **Near real-time analytics** (views / likes / comments) — reported in a recent CS1 loop
    - [ ] Ingestion → stream aggregation → serving layer
    - [ ] Exactly-once vs approximate counting, late events, windowing
    - [ ] Query optimization for the read path, fault tolerance, backfill
- [ ] Redraw two of today's architectures from memory
- [ ] Update error log

---

# DAY 3 — Java internals, concurrency, CS fundamentals

**Goal by end of day:** the fundamentals you flagged as weak (OS/DBMS/networking) are no longer a round-killer, and you can code any concurrency primitive from a blank file.

## Block A (2.5h) — Java internals

- [ ] `HashMap` internals: buckets, hashing, collision, treeification at 8, resize, why average O(1)
- [ ] `ConcurrentHashMap`: how it differs, why it's not just a synchronized map, when it's still not enough
- [ ] `equals()` / `hashCode()` contract — and what breaks if you violate it (be able to demo it)
- [ ] `ArrayList` vs `LinkedList` — and why LinkedList is almost always wrong in practice
- [ ] `String` immutability, string pool, `StringBuilder`
- [ ] `final` / `finally` / `finalize`, checked vs unchecked exceptions
- [ ] Generics: type erasure, wildcards, `? extends` vs `? super`
- [ ] JVM memory: heap, stack, metaspace; young vs old gen; minor vs full GC; what causes a full GC
- [ ] `volatile` vs `synchronized` vs `Atomic*` — the memory-visibility explanation, not the surface one

## Block B (3h) — Concurrency, coded from blank files

You've drilled this before. Today is retrieval, not reading. Blank file, no notes, then compare.

- [ ] Thread-safe **LRU cache** (and: why is `synchronized` on every method a bad answer?)
- [ ] **Bounded blocking queue** with `wait`/`notifyAll` — then again with `ReentrantLock` + `Condition`
- [ ] **Producer-consumer** end to end
- [ ] **Thread pool** — a minimal one, from scratch
- [ ] **`CompletableFuture` pipeline** — chaining, combining, exception handling, timeouts
- [ ] **`ReadWriteLock`** use case — where it actually wins and where it doesn't
- [ ] Deadlock: write one, then fix it two different ways
- [ ] Explain out loud: race condition, critical section, mutex vs semaphore, starvation, livelock

## Block C (3h) — OS, DBMS, Networking (your flagged weak area)

Rapid coverage, but write answers — don't just read.

**Operating Systems**

- [ ] Process vs thread, context switching cost
- [ ] Virtual memory, paging, page faults, TLB
- [ ] Scheduling algorithms (know 3, know their trade-offs)
- [ ] Deadlock: four conditions + prevention/avoidance/detection
- [ ] Mutex vs semaphore vs monitor

**Databases**

- [ ] Indexes: B-tree structure, clustered vs non-clustered, composite index column order, when an index hurts
- [ ] ACID, isolation levels, and the anomaly each one prevents
- [ ] Optimistic vs pessimistic locking — pick one for a concrete scenario and defend it
- [ ] Replication (sync vs async), sharding strategies, resharding pain
- [ ] Query plan basics: what makes a query slow

**Networking**

- [ ] TCP vs UDP, handshake, why TCP head-of-line blocking matters
- [ ] HTTP/1.1 vs HTTP/2, keep-alive, connection pooling
- [ ] TLS handshake at a high level
- [ ] REST vs WebSocket vs SSE vs long polling — when each
- [ ] DNS resolution path, load balancer types (L4 vs L7)

**Self-test:** close notes, answer 20 of these out loud in 30 minutes. Mark the ones you fumbled.

## Block D (3h) — LLD problems 5 and 6

- [ ] **Logger** (levels, appenders, async writes, thread safety) — 45 min + review
- [ ] **Job / Task Scheduler** (recurring jobs, priority, retries, failure handling, distributed variant) — 45 min + review
- [ ] Extra if time: **Elevator** or **Chess** — both reported in Adobe loops

## Block E (2.5h) — DSA: the Adobe-specific patterns

Adobe reports show two recurring shapes. Drill exactly those.

- [ ] **DP progression drill:** take 4 DP problems and solve each _four ways_ — recursive → memoized → tabulated → space-optimized. Adobe interviewers explicitly walk candidates up this ladder.
- [ ] **Tree traversal set:** zigzag/level-order, views, LCA, path sums, serialize/deserialize — 5 problems, 20 min each
- [ ] **Monotonic stack:** next greater element + 2 variants
- [ ] Re-attempt the 2 problems you failed or overran on Day 1

---

# DAY 4 — Project depth, behavioral, integration mocks

**Goal by end of day:** you can survive 15 minutes of drilling on any single resume line, and you've run each round type once under real conditions.

## Block A (2.5h) — Resume interrogation

Take **every bullet** on your resume. For each, answer in writing:

- [ ] What exactly did _I_ build vs the team?
- [ ] What was the state before? What number? How was it measured?
- [ ] What was the actual bottleneck, and how did I find it?
- [ ] What alternatives did I consider and why did I reject them?
- [ ] What trade-off did I accept?
- [ ] What would I do differently now?
- [ ] **If I can't answer these, I reword or remove the bullet before Sept 4.**

**CREST (Deutsche Bank) — the round where you can win**

- [ ] Draw the full architecture from memory. Every box, every arrow, every data store.
- [ ] Know: throughput numbers, data volumes, latency, SLAs, failure modes
- [ ] Prepare the drill-down chain for each technology choice. Example for Redis: why Redis → what was cached → TTL → what on Redis down → what on stale data → how measured → why not an in-process cache?
- [ ] Prepare one story about a **production incident** you handled
- [ ] Prepare one story about a **technical decision you got wrong**

**ShivAgri**

- [ ] Same treatment, shorter. This one demonstrates end-to-end ownership — lead with that framing.
- [ ] Be ready for: "why did you build this?" and "what would break at 100x users?"

## Block B (3h) — Mock: DSA round

Real conditions: no notes, no autocomplete, camera on, narrating throughout.

- [ ] Problem 1: 30 min, out loud, plain editor
- [ ] Problem 2: 30 min, out loud, plain editor
- [ ] Then for each: did you state brute force first? complexity before coding? dry run after? edge cases?
- [ ] Repeat with 2 more if the first pair went badly

## Block C (3h) — Mocks: LLD + HLD

- [ ] **LLD mock, 60 min** — pick a problem you have NOT done this week (ATM, Notification System, Connection Pool, or Cache). Full loop, out loud.
- [ ] **HLD mock, 60 min** — same rule, unseen problem. Use HelloInterview's mock feature if available, otherwise self-run with a timer.
- [ ] 30 min: score yourself against the framework. Where did you skip a step under time pressure? That step is what you'll skip on Sept 4 too — fix it now.

## Block D (3h) — Behavioral, Adobe-specific

You already have a STAR story bank from Google prep. This is re-mapping, not rebuilding.

- [ ] Re-tag your existing STAR stories against Adobe's stated values: Genuine, Exceptional, Innovative, Involved
- [ ] **"Tell me about yourself"** — 90 seconds, rehearsed to fluency, not memorized word-for-word
- [ ] **"Why Adobe?"** — this is the one people fail. Requirements for a passing answer:
    - [ ] Names a specific Adobe product or technical domain
    - [ ] Connects it to something you have actually built
    - [ ] Says something about the _engineering problem_, not the brand
    - [ ] Contains zero of: "reputed company", "great culture", "career growth"
- [ ] **"Why are you leaving Deutsche Bank?"** — honest, forward-looking, no employer-bashing
- [ ] Rehearse out loud, 60–90 seconds each:
    - [ ] Biggest technical challenge
    - [ ] Biggest failure / mistake
    - [ ] Conflict with a teammate
    - [ ] Difficult stakeholder
    - [ ] Production incident
    - [ ] Decision you disagreed with
    - [ ] How you handle ambiguity
    - [ ] Where you want to be in 3–5 years
- [ ] Prepare **3 questions to ask the interviewer** — specific to the team and the work, not to perks

## Block E (2.5h) — Consolidation and patch

- [ ] Read your full error log from Days 1–3. List the top 5 recurring failures.
- [ ] Spend 60 min patching only those 5.
- [ ] Build three one-page cheat sheets (for your own review, not for the interview): LLD checklist, HLD framework, Java/concurrency quick recall
- [ ] Logistics: test camera, mic, internet, backup hotspot, the coding environment, a quiet room
- [ ] Stop by 22:30. Sleep.

---

# The gap between Day 4 and Sept 4

If your 4 days end before Sept 3, do **not** add new material in the gap. Do this instead, 3–4 hours a day maximum:

- [ ] 2 DSA problems per day, timed, to keep speed warm
- [ ] Redraw one LLD and one HLD from memory per day
- [ ] Rehearse "tell me about yourself" and "why Adobe" once daily
- [ ] Re-read your CREST architecture notes once daily
- [ ] **Sept 3: light day. No new problems. Sleep properly.** Cramming the night before costs more in recall speed than it adds in knowledge.

---

# Progress tracker

| Day | LLD        | HLD        | DSA          | Java/Conc | Fundamentals | Project/Behavioral |
| --- | ---------- | ---------- | ------------ | --------- | ------------ | ------------------ |
| 1   | 4 problems | —          | 6 timed      | —         | —            | —                  |
| 2   | —          | 5 problems | —            | —         | —            | —                  |
| 3   | 2 problems | —          | 10 problems  | Full pass | Full pass    | —                  |
| 4   | 1 mock     | 1 mock     | 1 mock round | —         | —            | Full pass          |

**First-attempt-correct rate (DSA):**

- Day 1: ___ / 6
- Day 3: ___ / 10
- Day 4 mock: ___ / 2

If this number isn't improving, the problem isn't knowledge — it's process. Slow down before coding.

---

# Things not to do

- Don't memorize LLD class diagrams. You'll get a variant and freeze.
- Don't start drawing an HLD before finishing requirements. It's the most common visible failure.
- Don't stop at the first working solution. Ever.
- Don't add a 5th day of new material because you feel behind. Depth on what you've done beats one more unseen problem.
- Don't overclaim on your projects. Adobe drills. An inflated claim collapses in three follow-ups and costs more than the claim was worth.
- Don't argue with a hint. Take it, build on it, move.
- Don't cut sleep to hit an hours target. The hours are a proxy; the interview tests recall speed and verbal reasoning, both of which sleep debt destroys first.

---

# One honest note on scope

56 hours cannot make you strong in five areas from a standing start. What it can do — given that you already have Google-level DSA prep, seven concurrency drills, and a STAR bank — is close the LLD gap, build real HLD fluency, patch the fundamentals, and make your project story bulletproof.

That's the realistic win condition. Aim at it, not at coverage.