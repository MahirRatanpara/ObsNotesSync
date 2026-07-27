## How to use this

- Topics are in **descending order of interview frequency**, not descending order of difficulty.
- If you run out of time, stop where you are. Tier 1 alone covers roughly 60% of what gets asked. Tier 1 + 2 covers ~85%.
- Do not read this passively. For each bullet, say the answer out loud in one or two sentences. If you cannot, mark it and come back.
- **Budget for 11-12 effective hours, not 15.** You have a job, and the last 2 hours before the interview should be sleep, not cramming.

---

## Time allocation — THEORY + SPRING ROUND (revised)

Spring is promoted to Tier 1. Coding practice is cut to a sketch-and-explain exercise, not full implementations.

| Topic | Hours | Note |
|---|---|---|
| Concurrency | 2.5 | Deepest "why" chains land here |
| Spring / Spring Boot | 2.5 | Promoted from Tier 3 |
| Collections internals | 1.5 | Highest single-topic frequency |
| JVM / GC / memory | 1.5 | Tie to your production debugging |
| OOP contracts, exceptions, generics | 1.5 | |
| Java 8 functional | 1.0 | |
| Design patterns + Java 9–21 | 0.75 | Awareness depth only |
| Rapid-fire sweep + story prep | 1.0 | Do not skip the story hour |
| **Total** | **12.25** | |

**Coding practice in a theory round:** you won't write code, but you will be asked "how would you implement X." Be able to *describe* the LRU cache, the bounded blocking queue, and the thread-safe singleton out loud in 60 seconds each. Don't write them out — narrate them.

---

# TIER 1 — Non-negotiable (5 hours)

## 1.1 Collections internals (~1.5h)

**HashMap — the single most asked topic in Java interviews.**
- Bucket array of `Node<K,V>`; index = `(n-1) & hash`
- Hash spreading: `h ^ (h >>> 16)` — why? To mix high bits into low bits, since the index only uses low bits.
- Default capacity 16, load factor 0.75, resize doubles capacity and rehashes.
- Collision handling: linked list → **red-black tree** when a bin has 8+ nodes **and** table capacity ≥ 64. Untreeifies at 6.
- Java 7 vs 8: Java 7 used head insertion on resize → infinite loop under concurrent access. Java 8 preserves order.
- Why 0.75? Space/time tradeoff — Poisson distribution makes 8-node bins extremely rare at that load.

**equals / hashCode contract — know this cold.**
- Equal objects must have equal hash codes. Unequal objects *may* share a hash code.
- Break it → object goes into the map and can never be retrieved.
- Mutating a key field after insertion → same failure. Be ready to explain this.

**ConcurrentHashMap**
- Java 7: segment-based lock striping (16 segments by default).
- Java 8: no segments. CAS for empty-bin insert, `synchronized` on the bin head node for collisions. Much finer granularity.
- `size()` is an estimate — uses a `baseCount` plus `CounterCell` array (same idea as `LongAdder`).
- Null keys/values not allowed — because `get()` returning null would be ambiguous under concurrency.
- `computeIfAbsent` is atomic; `get`-then-`put` is not. Common real-world bug.

**Comparisons you'll be asked to make**
- `HashMap` vs `Hashtable` vs `Collections.synchronizedMap` vs `ConcurrentHashMap` — locking granularity is the answer.
- `ArrayList` vs `LinkedList` — the honest answer: LinkedList almost never wins in practice due to cache locality and per-node overhead, even for mid-list inserts. Saying this shows real experience.
- `ArrayList` growth: 1.5x (`oldCap + (oldCap >> 1)`).
- Fail-fast (`modCount`, throws `ConcurrentModificationException`) vs fail-safe (`CopyOnWriteArrayList`, iterates a snapshot).

**Others worth 10 minutes each**
- `TreeMap`/`TreeSet`: red-black tree, O(log n), `NavigableMap` methods (`floorKey`, `ceilingKey`, `subMap`).
- `LinkedHashMap`: insertion vs **access order** mode + override `removeEldestEntry` = LRU cache in 5 lines. Extremely common ask.
- `HashSet` is a `HashMap` with a dummy value object.
- `PriorityQueue`: binary heap. **Iteration order is not sorted** — a classic trap.
- `ArrayDeque` vs `Stack` — `Stack` extends `Vector`, legacy, synchronized, avoid.
- `Comparable` vs `Comparator`; `Comparator.comparing().thenComparing().reversed()`.

## 1.2 Concurrency (~2.5h)

This is where SDE-2 candidates get separated from SDE-1. Spend the time here.

**Memory model fundamentals**
- `volatile`: guarantees **visibility** and prevents reordering. Does **not** give atomicity. `count++` on a volatile is still broken.
- `synchronized`: gives mutual exclusion **and** visibility (release/acquire semantics).
- Happens-before relationships: program order, monitor lock, volatile write→read, thread start/join, final field freeze.
- Why double-checked locking needs `volatile`: without it, another thread can see a non-null but partially constructed object due to reordering of allocation/construction/assignment.

**Atomics and CAS**
- `AtomicInteger`, `AtomicReference`, `compareAndSet`, spin loops.
- ABA problem → `AtomicStampedReference`.
- `LongAdder` vs `AtomicLong`: under high contention, LongAdder strips across cells and sums on read. Faster writes, slower reads.

**Thread pools — know the parameter interaction precisely**
- `ThreadPoolExecutor(corePoolSize, maxPoolSize, keepAlive, timeUnit, workQueue, threadFactory, rejectionHandler)`
- Order of operations: fill to **core** → then **queue** → then grow to **max** → then **reject**.
- This means with an unbounded queue, `maxPoolSize` is never reached. This trips up most candidates.
- `newFixedThreadPool` → unbounded `LinkedBlockingQueue` → OOM risk.
- `newCachedThreadPool` → unbounded thread creation → thread exhaustion risk.
- Rejection policies: `AbortPolicy` (default), `CallerRunsPolicy` (backpressure), `DiscardPolicy`, `DiscardOldestPolicy`.
- Sizing: CPU-bound ≈ cores + 1; IO-bound ≈ cores × (1 + wait/compute).

**Locks**
- `ReentrantLock` vs `synchronized`: tryLock with timeout, interruptible acquisition, fairness option, multiple `Condition` objects.
- `ReadWriteLock` — many readers or one writer. Write starvation risk under read-heavy load.
- `StampedLock` — optimistic reads, not reentrant.

**Coordination primitives — know when to use which**
- `CountDownLatch`: one-shot, wait for N events.
- `CyclicBarrier`: reusable, N threads wait for each other.
- `Semaphore`: permit-based resource limiting.
- `Exchanger`, `Phaser` — mention awareness only.

**CompletableFuture**
- `thenApply` (sync transform) vs `thenCompose` (flatMap, returns another future) vs `thenCombine` (join two futures).
- `*Async` variants and which executor they run on (default: common ForkJoinPool — dangerous for blocking work).
- `exceptionally` vs `handle` vs `whenComplete`.
- `allOf` / `anyOf`, and how to collect results from `allOf`.
- `orTimeout` / `completeOnTimeout` (Java 9+).

**Failure modes**
- Deadlock: 4 Coffman conditions; prevention via global lock ordering; detection via `jstack`.
- Livelock, starvation, priority inversion.
- `ThreadLocal` memory leak in pooled threads — the entry survives because the thread does. Always `remove()` in a finally.

**Virtual threads (Java 21)** — cover only if you can speak honestly
- Solve thread-per-request scalability for **blocking IO**, not CPU-bound work.
- Pinning: a virtual thread blocked inside `synchronized` pins the carrier thread. Use `ReentrantLock` instead.
- If you have never used them, say "I've read about them, not used them in production." Do not bluff.

## 1.3 Java 8 functional (~1h)

- Stream pipeline: source → intermediate (lazy) → terminal (triggers execution). Short-circuiting ops: `limit`, `findFirst`, `anyMatch`.
- `map` vs `flatMap` — flatten nested structures.
- Collectors: `groupingBy` (incl. downstream collectors), `partitioningBy`, `toMap` (**throws on duplicate keys unless you pass a merge function** — very common trap), `joining`, `counting`, `summarizingInt`, `mapping`, `teeing` (Java 12).
- `Optional`: `orElse` evaluates its argument **eagerly**; `orElseGet` is lazy. Classic gotcha. Never call `get()` unguarded. Don't use Optional as a field or parameter.
- Core functional interfaces: `Function`, `BiFunction`, `Predicate`, `Supplier`, `Consumer`, `UnaryOperator`, `BinaryOperator`.
- Method references: static, instance, arbitrary-object, constructor.
- `parallelStream`: uses common ForkJoinPool, hurts on small data / IO-bound work / stateful lambdas. Be able to say when *not* to use it.
- Default and static methods in interfaces; diamond conflict resolution rules.

---

# TIER 2 — High value (3 hours)

## 2.1 JVM, memory, GC (~1.5h)

You have real production debugging experience here. Lead with it — that's your differentiator over a candidate who only read about it.

- **Memory areas**: Heap (Young = Eden + 2 Survivor spaces; Old gen), Metaspace (native memory, replaced PermGen in Java 8), per-thread Stack, PC register, native method stack.
- **Object lifecycle**: allocated in Eden → survives minor GC → copied between survivor spaces → promoted to Old after tenuring threshold.
- **GC types**: minor (young), major (old), full (whole heap + metaspace).
- **Collectors**: Serial, Parallel (throughput), CMS (removed in 14), **G1 (default since Java 9)** — region-based, pause-target driven; ZGC / Shenandoah — sub-millisecond pauses, large heaps.
- **GC roots and reachability**: local vars, static fields, JNI refs, active threads.
- **Reference types**: strong, soft (cleared under memory pressure — caches), weak (`WeakHashMap`), phantom (cleanup).
- **OOM flavours**: `Java heap space`, `GC overhead limit exceeded`, `Metaspace`, `unable to create new native thread`, `Direct buffer memory`. Each has a different root cause — be able to distinguish.
- **Common leak causes**: static collections that only grow, unclosed resources, ThreadLocal in pools, unremoved listeners, custom classloaders.
- **Class loading**: Bootstrap → Platform → Application; parent delegation model; loading → linking (verify/prepare/resolve) → initialization.
- **Initialization order**: static fields/blocks (once, at class init) → instance blocks → constructor. Parent before child.
- **Tools**: `jstack` (thread dumps, deadlock detection), `jmap` (heap dump), `jstat` (GC stats), Eclipse MAT, JFR, async-profiler.

## 2.2 OOP and language contracts (~1h)

- **SOLID** — with one concrete example each from your own codebase, not textbook shapes.
- Abstract class vs interface after Java 8 (state, constructors, multiple inheritance).
- Composition over inheritance — and *why* (fragile base class, encapsulation leak).
- **Building a truly immutable class**: final class, private final fields, no setters, defensive copy in constructor **and** in getters for mutable fields.
- **String**: immutability rationale (caching, security, thread safety, hashcode caching), string pool, `intern()`, `==` vs `equals`, `String` vs `StringBuilder` vs `StringBuffer`, compact strings (Java 9).
- Overloading resolved at **compile time**, overriding at **runtime**. Covariant return types. You cannot override static or private methods.
- `final` on class/method/variable; `static` nested vs inner class (inner holds implicit outer reference → leak source).
- **`clone()`** — shallow by default; prefer copy constructors or factories.

## 2.3 Exceptions and Generics (~0.5h)

**Exceptions**
- Checked vs unchecked; `Error` vs `Exception`.
- try-with-resources, `AutoCloseable`, suppressed exceptions.
- `finally` with `return` — the finally's return wins and silently swallows exceptions. Know this.
- Multi-catch, rethrow, exception chaining (`cause`).
- Never catch `Throwable` blindly; never swallow silently.

**Generics**
- **Type erasure** — generics are compile-time only; no runtime type info. That's why you can't do `new T[]` or `instanceof List<String>`.
- Bounded types: `<T extends Comparable<T>>`.
- **PECS**: Producer `extends`, Consumer `super`. Be ready to explain why you can't add to a `List<? extends Number>`.
- Unbounded wildcard `<?>` vs raw types.
- Bridge methods (awareness only).

---

# TIER 3 — Round-dependent (2.5 hours)

## 3.1 Spring / Spring Boot (~1.5h) — only if it's a backend round

- IoC container, DI types (constructor preferred — immutability, testability, circular-dep detection at startup).
- `@Component` vs `@Bean`; component scanning; `@Qualifier` / `@Primary`.
- Bean scopes: singleton (default), prototype, request, session. **Prototype bean injected into a singleton is created once** — a classic trap. Fix with `ObjectProvider` or `@Lookup`.
- Bean lifecycle: instantiate → populate → `Aware` interfaces → `BeanPostProcessor` before → `@PostConstruct` / `afterPropertiesSet` → post-processor after → ready → `@PreDestroy`.
- **`@Transactional`**:
  - Propagation: `REQUIRED` (default), `REQUIRES_NEW`, `NESTED`, `SUPPORTS`, `MANDATORY`, `NEVER`, `NOT_SUPPORTED`.
  - Isolation levels and the anomalies each prevents (dirty read, non-repeatable read, phantom read).
  - **Rolls back on unchecked exceptions only by default.** Checked exceptions need `rollbackFor`.
  - **Self-invocation does not go through the proxy** → annotation silently does nothing. Highest-frequency Spring trap question.
- AOP: JDK dynamic proxy (interface-based) vs CGLIB (subclass-based, Boot default). Advice types.
- Auto-configuration mechanism: `@EnableAutoConfiguration` → `AutoConfiguration.imports` → `@ConditionalOnClass` / `OnMissingBean` / `OnProperty`.
- Config precedence: command line > env vars > profile-specific yml > application.yml > defaults.
- Filter vs Interceptor vs `@ControllerAdvice` — where each sits in the request path.
- REST design: idempotency, correct status codes, versioning, pagination, `@ExceptionHandler`.
- Spring Data JPA: **N+1 problem** and its fixes (`JOIN FETCH`, `@EntityGraph`, batch size), lazy vs eager, persistence context / first-level cache, `save()` vs `saveAndFlush()`.
- Testing: `@SpringBootTest` vs `@WebMvcTest` vs `@DataJpaTest`, `MockMvc`, `@MockBean`, Testcontainers.
- Actuator: health, metrics, readiness vs liveness probes.

## 3.2 Design patterns (~0.5h)

- **Singleton** — all variants: eager, lazy, synchronized, double-checked locking with `volatile`, holder idiom, enum. Know why enum is safest (serialization + reflection safe).
- Factory / Abstract Factory, Builder, Strategy, Observer, Decorator, Adapter, Template Method, Proxy.
- Where they live in the JDK/Spring: `Runtime` (singleton), `Calendar.getInstance()` (factory), `StringBuilder` (builder), `InputStream` wrappers (decorator), Spring AOP (proxy), `JdbcTemplate` (template method).

## 3.3 Modern Java, 9 → 21 (~0.5h)

- 9: modules (awareness), `List.of` / `Map.of` (immutable), private interface methods
- 10/11: `var`, new `String` methods, `HttpClient`, single-file source execution
- 14/16: **records** (immutable data carriers — know the generated members), pattern matching for `instanceof`
- 17 (LTS): **sealed classes/interfaces**, switch expressions with `yield`, text blocks
- 21 (LTS): **virtual threads**, pattern matching for switch, sequenced collections, record patterns
- Know which LTS the target company runs — worth asking in the interview.

---

# TIER 4 — Hands-on practice (2 hours)

Write these out. Typing them beats reading about them by a wide margin.

**Concurrency (do at least 4)**
1. Thread-safe LRU cache — both the `LinkedHashMap` one-liner and the manual `HashMap` + doubly linked list version.
2. Bounded blocking queue using `wait`/`notifyAll` (and note why `notifyAll` over `notify`).
3. Print 1..N alternately with 2 threads, then generalize to N threads.
4. Producer-consumer with `BlockingQueue`.
5. Token-bucket rate limiter, thread-safe.
6. Deadlock demo, then fix it with lock ordering.
7. Parallel API calls with `CompletableFuture`, with timeout and fallback.

**Core Java**
8. Implement a simplified `HashMap` (put/get with chaining, resize).
9. Immutable class holding a `List` and a `Date` — get the defensive copies right.
10. Custom exception hierarchy with proper chaining.

**Streams**
11. Group employees by department, find max salary per department.
12. Second-highest salary, without sorting the whole list.
13. Word frequency count from a sentence, sorted by count descending.
14. Flatten `List<List<String>>` and deduplicate.
15. Write a custom `Collector`.

---

# Rapid-fire trap questions (final 30 min sweep)

Answer each in one sentence.

1. Can you override a static method? *(No — it's hidden, not overridden.)*
2. Can a constructor be `final`/`static`/`abstract`? *(No to all.)*
3. What happens if `hashCode` is constant for all objects? *(Map degrades to O(n), or O(log n) after treeification.)*
4. `String s = new String("a")` — how many objects? *(Two, if "a" isn't already in the pool.)*
5. Is `volatile` enough for a counter? *(No — no atomicity.)*
6. Difference between `wait()` and `sleep()`? *(`wait` releases the monitor; `sleep` doesn't.)*
7. Why must `wait()` be inside a loop? *(Spurious wakeups and stale conditions.)*
8. `finally` not executing — when? *(`System.exit`, JVM crash, infinite loop, daemon thread killed.)*
9. Can you catch `OutOfMemoryError`? *(Technically yes, practically pointless.)*
10. `Iterator.remove()` vs `list.remove()` inside a loop? *(Former is safe, latter throws CME.)*
11. Why can't you have a static method in an interface before Java 8? *(No implementation allowed pre-8.)*
12. `orElse` vs `orElseGet` — eager vs lazy.
13. `toMap` on duplicate keys? *(`IllegalStateException` without a merge function.)*
14. What does `ThreadLocal` leak in a thread pool?
15. `@Transactional` on a private method? *(Silently does nothing — proxy can't intercept.)*
16. Prototype bean in a singleton? *(Injected once, not per-use.)*
17. `List<? extends Number>` — can you `add(1)`? *(No. Only `null`.)*
18. Two threads calling `computeIfAbsent` vs `get`-then-`put`? *(First is atomic, second isn't.)*
19. `equals` without `hashCode` in a `HashSet`? *(Duplicates get stored.)*
20. `int` overflow in `(low + high) / 2`? *(Use `low + (high - low) / 2`.)*

---

# Resources — in descending order of value for a 2-day window

1. **Your own past notes and mock-interview material.** Already personalized, already in your vocabulary. Highest ROI by a wide margin. Start here.
2. **Baeldung** — targeted articles only. Search the exact topic. Best signal-to-noise for Java specifics.
3. **Effective Java (Bloch)** — do **not** read cover to cover. Read Items 10–17 only (equals, hashCode, toString, Comparable, immutability, composition over inheritance). That's about 40 pages and covers most contract questions.
4. **Jakob Jenkov's concurrency tutorials** (jenkov.com) — clearest short-form explanations of locks, JMM, and thread coordination.
5. **Defog Tech (YouTube, Deepak)** — Java concurrency and Spring internals in 8–15 min videos. Best time-to-understanding ratio available.
6. **Java Brains (YouTube)** — Spring/Spring Boot core, if you have a Spring round.
7. **Java Concurrency in Practice (Goetz)** — the reference, but too long for 2 days. Skim chapters 2, 3, 5, and 8 only if you have spare time.
8. **Official OpenJDK GC tuning guide** — only if you're specifically expecting JVM tuning questions.
9. **GeeksforGeeks** — use for trap-question drilling only. Quality is uneven; don't learn concepts here.
10. **JavaGuide (GitHub, CS-Guide)** — good consolidated checklists for last-hour scanning.

---

# What not to do with your 15 hours

- Don't start *Java Concurrency in Practice* from page 1. You won't finish, and the partial coverage isn't useful.
- Don't memorize GC flags you've never tuned. One follow-up question and it collapses.
- Don't over-prepare virtual threads or Project Loom if you've never used them. Awareness-level is fine and honest.
- Don't grind LeetCode in this window unless you've confirmed it's a DSA round. It's the highest-time, lowest-certainty use of the hours.
- Don't skip sleep the night before. Recall degrades faster than knowledge accumulates.

---

# The thing that actually differentiates a 4-YOE candidate

Textbook answers get you a "meets bar." What moves you up is connecting internals to production experience you actually had.

Weak: "ConcurrentHashMap uses CAS and bin-level locking."

Strong: "We were seeing lock contention in a high-throughput ingester path where a synchronized map was the bottleneck. Moving to ConcurrentHashMap dropped contention because writes only lock the bin head instead of the whole map."

**Before the interview, prepare 4–5 short stories** where a Java-level decision had a measurable production consequence:
- A concurrency bug you diagnosed (race, deadlock, thread pool exhaustion)
- A memory/GC issue you debugged with a heap dump or thread dump
- A data structure choice that mattered under load
- A refactor where the language feature choice (streams, immutability, generics) reduced defects

Each in 90 seconds: situation → what you found → what you changed → what improved.
