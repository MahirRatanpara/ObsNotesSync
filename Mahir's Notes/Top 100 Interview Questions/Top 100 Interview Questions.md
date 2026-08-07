# Top 100 Interview Questions

> The questions that actually recur, with the one-line answer and a link to depth.
> **Use as a self-test:** cover the answer column, answer aloud, then check.

## Java — Memory Model and Concurrency (1–20)

| # | Question | Short answer |
|---|---|---|
| 1 | Does `volatile` make `count++` thread-safe? | No — read-modify-write needs an atomic or a lock |
| 2 | What does `volatile` actually guarantee? | Visibility, ordering, and atomicity of 64-bit reads/writes |
| 3 | Why does double-checked locking need `volatile`? | Reordering can publish a partially constructed object |
| 4 | Best lazy singleton in Java? | Bill Pugh holder idiom, or an enum |
| 5 | BLOCKED vs WAITING? | Monitor contention vs voluntary suspension |
| 6 | `start()` vs `run()`? | `start()` spawns a thread; `run()` executes inline |
| 7 | What happens when you catch `InterruptedException`? | The interrupt flag is cleared — restore it |
| 8 | Why must you call `ThreadLocal.remove()`? | Pooled threads outlive requests; the value leaks |
| 9 | `wait()` in `if` or `while`? | `while` — spurious wakeups and stolen conditions |
| 10 | `notify()` or `notifyAll()`? | `notifyAll()`, or a `Condition` with targeted `signal()` |
| 11 | How do you prevent deadlock? | Consistent global lock ordering |
| 12 | What is CAS? | Atomic compare-and-set, retried in a loop |
| 13 | What is the ABA problem and the fix? | Value returns to original; `AtomicStampedReference` |
| 14 | `AtomicLong` vs `LongAdder`? | LongAdder spreads writes across cells — better under contention |
| 15 | Explain the thread pool submission algorithm | Core threads → queue → extra threads → rejection |
| 16 | Why avoid `Executors.newFixedThreadPool`? | Unbounded queue → OOM |
| 17 | Which rejection policy gives backpressure? | `CallerRunsPolicy` |
| 18 | What happens to an exception inside `submit()`? | Captured in the `Future`, silent unless inspected |
| 19 | `thenApply` vs `thenCompose`? | map vs flatMap |
| 20 | Why is the default `CompletableFuture` executor risky? | It's the shared `ForkJoinPool.commonPool()` |

→ [Java Memory Model](Java%20Memory%20Model.md) · [Synchronisation and Locks](Synchronisation%20and%20Locks.md) · [Executors](Executors%20and%20Thread%20Pools.md)

## Java — Collections and JVM (21–40)

| # | Question | Short answer |
|---|---|---|
| 21 | HashMap default capacity and load factor? | 16 and 0.75 |
| 22 | When does a bucket treeify? | 8 entries **and** capacity ≥ 64 |
| 23 | Why untreeify at 6 rather than 8? | Hysteresis — avoids thrashing at the boundary |
| 24 | How is the bucket index computed? | `(n - 1) & hash` |
| 25 | Why XOR the high bits into the hash? | The mask keeps only low bits |
| 26 | Why must capacity be a power of two? | Enables the bitmask instead of modulo |
| 27 | What happens if you override `equals` but not `hashCode`? | Hash lookups fail — different buckets |
| 28 | What breaks with a mutable HashMap key? | The entry becomes unreachable and unremovable |
| 29 | How does ConcurrentHashMap lock (Java 8+)? | CAS on empty bins; `synchronized` on the first node otherwise |
| 30 | Why does ConcurrentHashMap forbid nulls? | `get() == null` would be ambiguous |
| 31 | ArrayList or LinkedList in practice? | ArrayList — cache locality dominates |
| 32 | How does a fail-fast iterator work? | `modCount` comparison — best-effort only |
| 33 | How do you remove safely during iteration? | `Iterator.remove()` or `removeIf` |
| 34 | What replaced PermGen and where does it live? | Metaspace, in native memory |
| 35 | Why are minor GCs cheap? | Cost scales with survivors, not garbage |
| 36 | How do ZGC/Shenandoah get sub-ms pauses? | Concurrent marking and relocation with barriers |
| 37 | Does Java GC collect reference cycles? | Yes — tracing from roots, not reference counting |
| 38 | Class loading: preparation vs initialization? | Defaults vs actual values and static blocks |
| 39 | Are all Java objects on the heap? | Escape analysis + scalar replacement can eliminate the allocation |
| 40 | Which sort does Java use, and why two? | Dual-pivot quicksort for primitives, TimSort for objects (stability) |

→ [HashMap Internals](HashMap%20Internals.md) · [Garbage Collection](Garbage%20Collection.md) · [JIT and Escape Analysis](JIT%20and%20Escape%20Analysis.md)

## DSA (41–60)

| # | Question | Short answer |
|---|---|---|
| 41 | n ≤ 20 in constraints suggests what? | Bitmask DP or backtracking |
| 42 | "Contiguous subarray" suggests? | Sliding window or prefix sum |
| 43 | "Minimize the maximum" suggests? | Binary search on answer |
| 44 | Why is a monotonic stack O(n)? | Each element pushed and popped once — amortised |
| 45 | K largest — which heap and what size? | **Min** heap of size k |
| 46 | When does greedy fail for Coin Change? | `coins=[1,3,4]`, amount 6 → greedy 3, optimal 2 |
| 47 | Activity selection: sort by start or end? | **End** — finishing earliest leaves the most room |
| 48 | Container With Most Water: which pointer moves? | The shorter line |
| 49 | 0/1 knapsack: inner loop direction? | Backward |
| 50 | Coin Change combinations vs permutations? | Coin loop outside vs amount loop outside |
| 51 | How do you find the start of a linked-list cycle? | Reset one pointer to head, advance both by one |
| 52 | Why does the cycle-start trick work? | `a ≡ c` modulo cycle length; derive from `2(a+b) = a+b+k(b+c)` |
| 53 | Union-Find complexity and why? | O(α(n)) with path compression + union by rank |
| 54 | How does Union-Find detect a cycle? | `union` returns false |
| 55 | How does Kahn's algorithm detect a cycle? | Output size < n |
| 56 | Why can't Fenwick trees do min/max? | Not invertible — subtraction can't undo |
| 57 | Segment tree array size and why? | `4n` — the tree isn't perfectly balanced |
| 58 | LPS (subsequence) reduces to what? | `LCS(s, reverse(s))` |
| 59 | Interval DP iteration order? | By increasing length |
| 60 | LRU cache structure? | Hash map + doubly linked list, sentinels, key in node |

→ [Pattern Recognition Framework](Pattern%20Recognition%20Framework.md) · [Pattern Confusion Matrix](Pattern%20Confusion%20Matrix.md) · [LRU Cache](LRU%20Cache.md)

## System Design — Theory (61–75)

| # | Question | Short answer |
|---|---|---|
| 61 | Why is "CA" not a valid CAP choice? | Partitions are inevitable — P is mandatory |
| 62 | What does CAP's C mean? | Linearizability, not ACID's C |
| 63 | State PACELC | If Partition → A or C; Else → Latency or Consistency |
| 64 | Quorum condition for strong consistency? | `R + W > N` |
| 65 | Nodes needed to tolerate f crash failures? | `2f + 1` — always odd |
| 66 | Why does Raft randomise election timeouts? | Prevents perpetual split votes |
| 67 | When is a Raft entry committed? | Once a majority has persisted it |
| 68 | What does a timeout tell you? | Nothing — Two Generals; success and failure are indistinguishable |
| 69 | Practical response to Two Generals? | Idempotency keys make retries safe |
| 70 | Why do distributed locks need fencing tokens? | A GC pause can outlive the lease |
| 71 | Which consistency guarantee do users actually notice? | Read-your-writes |
| 72 | Risk of last-write-wins? | Silent loss of concurrent writes |
| 73 | Why is consensus kept off the data path? | Every write costs a majority round trip |
| 74 | Does Raft handle malicious nodes? | No — crash faults only; Byzantine needs `3f+1` |
| 75 | Replication vs backup? | Replication faithfully copies your `DROP TABLE` |

→ [CAP and PACELC](CAP%20and%20PACELC.md) · [Consensus Algorithms](Consensus%20Algorithms.md) · [Two Generals Problem](Two%20Generals%20Problem.md)

## System Design — Practice (76–95)

| # | Question | Short answer |
|---|---|---|
| 76 | Default caching pattern? | Cache-aside |
| 77 | On write, update or delete the cache? | **Delete** — updating races |
| 78 | Correct order on write? | DB first, then invalidate |
| 79 | How do you prevent a cache stampede? | Request coalescing or probabilistic early expiry |
| 80 | Cache penetration fix? | Bloom filter or negative caching |
| 81 | Cache avalanche fix? | TTL jitter |
| 82 | Why B+ trees for indexes? | High fan-out → 3–4 seeks instead of 30 |
| 83 | What does a covering index avoid? | The second lookup — index-only scan |
| 84 | Leftmost prefix rule? | `(a,b,c)` can't serve queries without `a` |
| 85 | What silently disables an index? | A function on the indexed column |
| 86 | Bad shard keys? | Timestamp, auto-increment id, low cardinality |
| 87 | Why virtual nodes in consistent hashing? | Even distribution; failure load spreads |
| 88 | Kafka ordering guarantee? | Per partition — key by entity id |
| 89 | Max useful consumers in a group? | The partition count |
| 90 | Durable Kafka configuration? | `acks=all` + `min.insync.replicas=2` + RF=3 |
| 91 | Does Kafka exactly-once cover your DB? | No — only within Kafka |
| 92 | How do you make a consumer idempotent? | Dedup key insert in the **same transaction** as the side effect |
| 93 | Circuit breaker states? | CLOSED → OPEN → HALF_OPEN |
| 94 | Why also trip on slow calls? | A dependency returning 200s is failing without throwing |
| 95 | Rate limiter allowing bursts? | Token bucket |

→ [Caching](Caching.md) · [Database Indexing](Database%20Indexing.md) · [Kafka Deep Dive](Kafka%20Deep%20Dive.md) · [Circuit Breaker](Circuit%20Breaker.md)

## Design Patterns and LLD (96–100)

| # | Question | Short answer |
|---|---|---|
| 96 | Strategy vs State? | Client selects vs object transitions itself |
| 97 | Decorator vs Proxy? | Adds behaviour vs controls access |
| 98 | Why does `@Transactional` fail on a self-invoked method? | The call never passes through the proxy |
| 99 | What is double dispatch, and which pattern uses it? | Two virtual calls resolving two runtime types — Visitor |
| 100 | Why prefer composition over inheritance? | Fragile base class, no combinatorial explosion, runtime flexibility, testability |

→ [Design Pattern Selection](Design%20Pattern%20Selection.md) · [Design Patterns Cheat Sheet](Design%20Patterns%20Cheat%20Sheet.md) · [SOLID Principles](SOLID%20Principles.md)

## How To Use This

1. **First pass** — cover the answers, work top to bottom, mark every miss
2. **Second pass** — read only the notes behind your missed questions
3. **Third pass** — re-test only the misses
4. The night before: read the answer column straight through, no self-testing

Questions you miss twice are your actual weak areas. Everything else is noise.
