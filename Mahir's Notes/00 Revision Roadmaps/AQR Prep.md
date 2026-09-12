# AQR Capital Management — Preparation Plan

---

## Part 0 — Get these five answers first (Day 0, 20 minutes)

Your plan changes materially depending on these. Ask the recruiter.

- [x] **Which team?** Research & Portfolio Management Engineering (Python-first) vs Portfolio Analytics / Portfolio Implementation (Java-first). This decides your language and whether probability matters.
- [x] **Which office?** Bengaluru is the realistic one for you; it's also the Java/Portfolio Analytics side.
- [x] **What stage am I at?** Is there an online assessment (HackerRank/CodeSignal) first, or does it start with a screen?
- [x] **Format of the coding rounds** — shared editor, own IDE, whiteboard? Language allowed?
- [x] **Date.** Everything below scales to this.

**Working assumption until told otherwise:** Bengaluru, Portfolio Analytics / Implementation, **Java**, with an online assessment before any live round.

---

## Part 1 — Your strategic position (read this before anything else)

### The asset you're underusing: CREST

AQR's engineering work is described as: ingesting and validating large financial datasets, versioning them, running computations and historical simulations, and producing portfolio/order outputs — with heavy emphasis on correctness, reproducibility and testing.

**CREST is a regulatory stress-testing platform.** That means: large financial datasets, scenario runs, reproducible results, auditability, correctness under regulatory scrutiny, distributed compute. The vocabulary differs; the engineering problem is nearly identical.

- [ ] Rewrite your CREST story in AQR's language: data ingestion → validation → versioned inputs → distributed computation → reproducible outputs → audit trail.
- [ ] Be ready to say explicitly: _"Stress testing and backtesting are the same shape of problem — run a model over historical or hypothetical scenarios, and be able to prove later exactly what produced a given number."_
- [ ] This is your answer to "why finance" and "why AQR" at the same time. It is specific and falsifiable, which the culture rewards.

### What carries over from your Adobe fundamentals work (already done)

- OS: memory, virtual memory, paging, processes/threads, deadlock theory
- CPU/memory hierarchy, caches
- JVM internals, GC, Java concurrency
- Networking: TCP, TLS, HTTP, the URL trace
- Databases: ACID, isolation, indexing, CAP
- Distributed patterns: idempotency, retries/backoff, backpressure, circuit breakers

**Do not re-study these from scratch.** Keep a 15-minute daily review only.

### What is genuinely new for AQR

|New work|Why|
|---|---|
|**Live DSA under a clock**|Adobe's DSA rounds are behind you. AQR likely starts with an OA and has coding rounds. This is the biggest gap.|
|**Hands-on SQL**|Explicitly reported in an AQR assessment and named in current role descriptions. You didn't prep this for Adobe.|
|**Writing concurrent code**, not describing it|A reported AQR round asked for _working_ deadlock-resolution code. Describing the four Coffman conditions is not enough.|
|**OOP implementation under time**|A transaction/transfer object model was specifically reported.|
|**Probability + finance vocabulary**|Tiered — see Part 3G. Mostly matters if you land on the research side.|
|**"Why finance / why AQR"**|Adobe's version won't transfer.|

---

## Part 2 — Effort allocation

|Area|Share|Note|
|---|---|---|
|Coding / DSA|**35%**|The rustiest thing. Timed, not leisurely.|
|OOP + concurrency implementation + Java depth|**20%**|Write real code, including the transfer service.|
|System design + CREST architecture story|**20%**|Your strongest area; polish rather than build.|
|SQL + CS fundamentals review|**10%**|SQL is hands-on; fundamentals is review only.|
|Probability / finance / behavioural / AQR fit|**15%**|Tier by team.|

---

## Part 3 — The work

### A. Lock your language (Day 1, 30 min)

- [x] **Choose Java.** It's where you write correct code fastest and it matches the likely team. Do not switch to Python for this loop.
- [ ] Refresh the Java specifics AQR reports touch: `equals`/`hashCode`, `Comparable` vs `Comparator`, collection complexities, `PriorityQueue`, generics, immutability, `synchronized` vs `volatile` vs locks vs atomics, `ConcurrentHashMap`, `ExecutorService`/`Future`, interface vs abstract class.
- [ ] You already covered JVM/GC internals Saturday — review notes only, don't re-read.

### B. DSA — timed practice (the bulk of the work)

Do these **timed, in Java, without an IDE's autocomplete crutch.** Target: medium in 25–30 minutes including tests.

**Core pattern coverage — do all of these:**

- [ ] Hashing: Two Sum, Group Anagrams, Subarray Sum Equals K
- [ ] Two pointers / sliding window: 3Sum, Longest Substring Without Repeating Characters
- [ ] Heaps / top-k: Kth Largest Element, Find Median from Data Stream
- [ ] Binary search: standard + Search in Rotated Sorted Array
- [ ] Trees: Validate BST, Lowest Common Ancestor
- [ ] Graphs: Number of Islands, Course Schedule (topological sort), Network Delay Time
- [ ] DP: Coin Change, House Robber, **Longest Common Subsequence**
- [ ] Bit manipulation: **Single Number II** (reported pattern — be able to _explain_ each bit operation, not recite a trick)
- [ ] Intervals: Merge Intervals
- [ ] Design: LRU Cache
- [ ] Range queries: Range Sum Query — Mutable (understand segment tree structure; don't memorise)

**Interview pacing drill — rehearse this rhythm on at least 5 problems:**

- 0–4 min: clarify inputs, constraints, edge cases
- 4–8: state the brute force out loud
- 8–13: derive the better approach + complexity
- 13–30: code
- 30–37: walk through test cases aloud
- 37–42: complexity and alternatives
- [ ] Practise the stuck protocol: if blocked >5 min, say _"Here's my invariant, here's the bottleneck, I think the missing observation is X."_ Silent struggling is the failure mode.

**For every problem solved, state one extension:** streaming input, memory constraint, concurrency, malformed input, or 100x data.

### C. SQL (2–3 hours total, hands-on)

- [ ] Joins (inner/left/self), `GROUP BY` + `HAVING`
- [ ] **Window functions** — `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`/`LEAD`, `PARTITION BY`. Most likely to trip you up.
- [ ] Practice: Second Highest Salary, Consecutive Numbers, Rank Scores, Department Top Three Salaries
- [ ] Explain: index/B-tree intuition, when an index doesn't help, transactions and isolation levels, optimistic vs pessimistic concurrency, reading a query plan
- [ ] Be ready for MCQ-style SQL/OOP questions in an online assessment

### D. OOP + concurrency — write the code (3–4 hours)

**The transaction/transfer service** — build this once, properly. It combines two separately reported AQR themes.

- [ ] Implement `transfer(fromAccount, toAccount, amount)` in Java
- [ ] Validate inputs; reject invalid amounts and identical accounts
- [ ] State the invariants explicitly (no negative balance, total value conserved)
- [ ] Make it **idempotent** — a transaction/request ID so a retry after an ambiguous failure doesn't double-apply
- [ ] Show the naive two-lock version **deadlocking**, then repair it with **consistent lock ordering by account ID**
- [ ] Mention `tryLock` with timeout as an alternative, and its trade-off
- [ ] Write the sentence that earns the round: _"Consistent total lock ordering removes circular wait in-process — but for real correctness across nodes I'd push this into a database transaction with an idempotency key rather than assume in-memory locks solve a distributed problem."_
- [ ] Write unit tests, including a concurrent test

**OOP design, separately:**

- [ ] SOLID at an intuitive level; composition over inheritance
- [ ] Strategy, Factory, Observer — **and each one's drawbacks**. A reported AQR round asked specifically about design-pattern weaknesses.
- [ ] Practise one object-modelling exercise aloud (e.g. Minesweeper or a parking lot): classes, responsibilities, invariants, error handling, testability

**Concurrency you must be able to discuss:**

- [ ] Race conditions, critical sections, mutex vs monitor
- [ ] Producer–consumer with a bounded queue (and why bounded = backpressure)
- [ ] Thread pools, futures, atomics/CAS
- [ ] Deadlock's four conditions, lock ordering, timeouts, starvation, livelock

### E. System design (3 hours)

**The one prompt to rehearse:** _"Design a platform that ingests large market datasets, validates and versions them, runs research computations and backtests, and produces portfolio or order candidates."_

- [ ] Walk the checklist in order: **scope → scale → API → data model → consistency → partitioning → computation → caching → messaging → failures → observability → testing → cost**
- [ ] Cover specifically: immutable versioned raw data, schema + semantic validation with a quarantine path, job orchestration, distributed compute workers, versioned result store, audit and replay
- [ ] **Answer challenges in this priority order: correctness → recoverability → throughput/latency → cost.** This ordering matches the stated culture and is a differentiator.
- [ ] Never open with product names. Requirements first, Kafka/Redis/S3 later.
- [ ] For a finance-adjacent system, _ask_: is duplicate processing acceptable? does ordering matter? must historical results be reproducible exactly? what latency actually matters?

**Finance-engineering concepts worth knowing (cheap, high signal):**

- [ ] Deterministic replay; sequence numbers and gap detection
- [ ] **Point-in-time data** and **look-ahead bias** — using information that wasn't available at the simulated moment
- [ ] **Survivorship bias** — testing only on entities that still exist
- [ ] Reproducible backtests; random seeds; timestamps and time zones
- [ ] Floating-point precision in money calculations
- [ ] "Exactly-once _business effect_" via idempotency, versus exactly-once message delivery (which isn't real)

### F. Project architecture deep-dive (2 hours)

One report describes ~80 minutes spent drilling a previous application's architecture. Assume this happens.

- [ ] **CREST, 2-minute version** and **10-minute version**
- [ ] Architecture diagram you can draw from memory
- [ ] Scale numbers: data volume, run frequency, compute footprint, latency or runtime
- [ ] Specific technology versions you used — they reportedly probe stack details
- [ ] **Three trade-offs you made and why**
- [ ] **One thing that failed** and what you learned
- [ ] **What you'd redesign today**
- [ ] How you tested it, and how you know the output is correct
- [ ] The AQR translation: stress testing ≈ backtesting (see Part 1)
- [ ] ShivAgri as the secondary story: full ownership, real users, shipped solo

### G. Probability, statistics and finance — tier by team

**If Portfolio Analytics / Implementation (Java): 60–90 minutes total. Do not over-invest.**

- [ ] Conditional probability and Bayes' theorem
- [ ] Expectation, variance, covariance, correlation
- [ ] Normal distribution intuition; correlation ≠ causation
- [ ] Floating-point error, numerical stability, reproducibility

**If Research & Portfolio Management Engineering / QRD: double it, and add:**

- [ ] Regression / least-squares intuition
- [ ] Simple vs log returns, compounding, volatility
- [ ] Signal / alpha, position, P&L, turnover
- [ ] Portfolio weights, constraints, rebalancing, transaction costs
- [ ] Convexity and constrained optimisation at a conceptual level

**Vocabulary floor for everyone** — you must not go blank on these words:

- [ ] signal, backtest, portfolio construction, rebalance, order generation, risk, slippage, transaction costs

### H. Behavioural and AQR fit (2 hours)

The stated culture is intellectual honesty, truth-seeking, questioning assumptions, rigorous testing, collaboration. Build answers around **evidence changing your mind**, not around being right.

**Use STAR + Evidence:** Situation → Task → Action → Result → **what observation or data changed your belief.** That last clause is the differentiator here.

Prepare these:

- [ ] A time evidence forced you to abandon your preferred technical approach
- [ ] A disagreement with a colleague, and how you established what was actually true
- [ ] A subtle data-quality or correctness bug you caught before production _(CREST is ideal — regulatory data correctness)_
- [ ] A time you challenged an assumption everyone accepted
- [ ] A performance vs maintainability trade-off
- [ ] A production incident you owned end to end
- [ ] How you make an ambiguous requirement testable

**"Why AQR?"** — structure it:

1. Systematic, research-driven investing interests you _because [specific reason]_
2. Engineering there directly enables research and portfolio implementation, not generic IT
3. Your CREST work is already this shape of problem: large financial datasets, scenario computation, reproducibility, audit
4. One concrete AQR responsibility that matches what you've built

- [ ] **Do not manufacture quant passion.** Vague enthusiasm reads as false in a truth-seeking culture. Specific and modest beats broad and keen.
- [ ] Prepare 5 questions for the interviewers.

### I. Mock rounds

- [ ] **One 45-minute DSA mock** on an unseen medium, timed, spoken aloud
- [ ] **One 45-minute OOP + concurrency mock** — the transfer service, from a blank file
- [ ] **One 45-minute system design mock** — the data/backtest pipeline
- [ ] **One 15-minute résumé/fit mock** — CREST in 2 minutes, then follow-ups
- [ ] Grade each separately: correctness, communication, design, fundamentals, fit. Fix the weakest two only.

---

## Part 4 — Two schedules

### If you have ~2 weeks (likely, and preferred)

|Days|Focus|
|---|---|
|**1–4**|DSA daily: 3 timed problems/day across the pattern list. 30 min SQL/day.|
|**5–6**|OOP + concurrency: build the transfer service end to end, with tests. Java specifics.|
|**7–8**|System design + the CREST architecture rewrite in AQR language.|
|**9**|Probability, finance vocabulary, behavioural stories.|
|**10**|Full mock loop (all four rounds above), then debrief.|
|**11–12**|Repair the two weakest areas only. Light DSA to stay sharp.|
|**13**|Recall, not acquisition. Cheat sheet, logistics, sleep.|

### If you get short notice (~2 days)

Compress hard and cut deliberately:

- **Day 1:** DSA morning (patterns, ★ list), SQL + CS review afternoon, transfer service + deadlock repair evening.
- **Day 2:** CREST architecture morning, system design mid-day, probability + behavioural early afternoon, full mock, then stop.
- **Cut entirely:** deep probability, exotic data structures, low-latency/lock-free material, anything beyond Tier 1.

---

## Part 5 — What not to do

- [ ] **Don't start before Wednesday.** Adobe first.
- [ ] **Don't switch languages.** Java, unless the recruiter says the team is Python-first — and even then, only if there's real time.
- [ ] **Don't chase "leaked AQR question lists."** The evidence for them is thin. Patterns beat memorised sets.
- [ ] **Don't over-prepare low-latency / lock-free / HFT engine material.** The role descriptions are broader than that. It's a low-return rabbit hole.
- [ ] **Don't assume probability is in every loop.** Evidence for it is campus/research-specific.
- [ ] **Don't optimise for a supposed score cutoff.** There's no credible public evidence for one, and candidates have been rejected after rounds they felt went well. Consistency across all areas beats one heroic solve.
- [ ] **Don't fake finance enthusiasm.** Say what genuinely interests you and stop.

---

## Part 6 — Final-night recall list

By the last evening you should be able to reproduce from memory, without notes:

- [ ] Your Java templates: binary search, BFS, DFS, top-k heap, prefix-sum map
- [ ] Deadlock prevention by lock ordering — and the distributed caveat
- [ ] Idempotency and why retries need it
- [ ] The system-design checklist, in order
- [ ] Bayes, variance, covariance
- [ ] CREST architecture, 2-minute version
- [ ] Six behavioural stories
- [ ] A crisp, specific "why AQR"