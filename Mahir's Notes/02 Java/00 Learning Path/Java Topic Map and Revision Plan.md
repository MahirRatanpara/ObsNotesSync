# Java Topic Map and Revision Plan

> The complete map of what "knowing Java" means for interviews, and how to cover it in 24 hours.

## The Twelve Blocks

Dependency-ordered. Each is revisable independently; read in order if learning from zero.

| # | Block | Covers | Why it matters |
|---|---|---|---|
| **1** | Language Core | Types, strings, operators, arrays, dates | The substrate everything sits on |
| **2** | OOP | Inheritance, interfaces, nested classes, immutability | Design and LLD rounds |
| **3** | Generics | Erasure, wildcards, PECS | API design; a common depth probe |
| **4** | Exceptions | Hierarchy, try-with-resources, design | Correctness |
| **5** | **Collections** | Internals, sorting, specialised maps | **Most-asked area** |
| **6** | Functional and Streams | Lambdas, streams, collectors, Optional | Modern fluency |
| **7** | **Concurrency** | Threads, locks, executors, virtual threads | **The senior differentiator** |
| **8** | JVM and Memory | Class loading, JIT, memory model, reflection | Depth questions |
| **9** | Garbage Collection | Collectors, tuning, leaks | Production credibility |
| **10** | IO and Serialization | Streams, NIO, serialization risks | Occasionally probed |
| **11** | Modern Java | Java 8 → 25, modules | Currency signal |
| **12** | Performance | Profiling, benchmarking | Senior roles |

**Blocks 5 and 7 carry most of the weight.** If you must cut, cut elsewhere.

---

## The Complete Checklist

Tick only what you can explain **aloud, without notes**. Unticked items are your revision list.

### 1 — Language Core

- [x] Primitives, sizes, ranges; `char` is the only unsigned type
- [x] **Autoboxing, the Integer cache (−128..127), unboxing NPEs**
- [x] Numeric promotion; integer overflow; `Math.abs(MIN_VALUE)` is negative
- [x] **Why `0.1 + 0.2 != 0.3`; `NaN != NaN`; money as integer minor units**
- [x] `BigDecimal`: String constructor, and `equals` vs `compareTo`
- [ ] **String immutability, the pool, `intern()`, compact strings**
- [ ] `String` vs `StringBuilder` vs `StringBuffer`
- [ ] Text blocks, `formatted`, `strip` vs `trim`
- [ ] `switch` expressions; exhaustiveness; arrow labels
- [ ] **Pattern matching for `instanceof`, `switch`, and records**
- [ ] Arrays: covariance, `ArrayStoreException`, `System.arraycopy`
- [ ] Varargs, heap pollution, `@SafeVarargs`
- [ ] **`java.time`: `Instant` vs `LocalDateTime` vs `ZonedDateTime`**
- [ ] `var` — where it's allowed and where it isn't

### 2 — OOP

- [ ] Abstraction vs encapsulation
- [ ] **Overloading is static dispatch; overriding is dynamic**
- [ ] **Fields, `static` and `private` methods are not polymorphic**
- [ ] Covariant return types; why `@Override` matters
- [ ] **Initialisation order: static → instance block → constructor**
- [ ] `this()` / `super()` rules; never call an overridable method from a constructor
- [ ] Abstract class vs interface; `default`, `static`, `private` methods
- [ ] **Diamond problem and explicit resolution**
- [ ] Static nested vs inner vs local vs anonymous
- [ ] **Why inner classes leak; lambdas are not anonymous classes**
- [ ] Building a genuinely immutable class; defensive copying
- [ ] `Object` contract: `equals`, `hashCode`, `toString`, `clone`, `Cleaner`
- [ ] Records; sealed types; enums with behaviour; `EnumMap`/`EnumSet`

### 3 — Generics

- [ ] **Type erasure** and everything it forbids
- [ ] Bounded and multiple bounds
- [ ] **Wildcards and PECS**
- [ ] Why `List<String>` is not `List<Object>`; arrays covariant vs generics invariant
- [ ] Heap pollution; `@SafeVarargs`
- [ ] Generic methods; inference; the diamond
- [ ] Recursive generics; type tokens; bridge methods

### 4 — Exceptions

- [ ] Hierarchy and the checked/unchecked debate
- [ ] **try-with-resources; suppressed exceptions**
- [ ] Never `return` from `finally`
- [ ] Chaining; multi-catch; precise rethrow
- [ ] Custom exception design; stack trace cost

### 5 — Collections

- [ ] Hierarchy; **`Map` is not a `Collection`**
- [ ] **`ArrayList` growth, `System.arraycopy`, `modCount`**
- [ ] `LinkedList` — and why it's almost never right
- [ ] **`HashMap`: buckets, treeify at 8/64, resize split, hash spreading**
- [ ] `LinkedHashMap` access order → LRU
- [ ] **`TreeMap`: red-black tree, `NavigableMap`, `floorKey`/`ceilingKey`**
- [ ] `ArrayDeque` over `Stack` and `LinkedList`; `PriorityQueue` internals
- [ ] `EnumMap`, `WeakHashMap`, `IdentityHashMap`, `Hashtable`
- [ ] **`Comparable` vs `Comparator`; contract violations**
- [ ] Fail-fast vs fail-safe
- [ ] `List.of` vs `Arrays.asList` vs `unmodifiableList`
- [ ] `SequencedCollection` (21); TimSort vs dual-pivot quicksort

### 6 — Functional and Streams

- [ ] **Lambdas compile via `invokedynamic`, not anonymous classes**
- [ ] Effectively final capture; `this` semantics differ
- [ ] Functional interface families; the four method-reference kinds
- [ ] **Laziness; element-at-a-time pipelining; short-circuiting**
- [ ] **Collectors: `groupingBy`, `toMap` duplicate trap, `teeing`, custom**
- [ ] `reduce`: identity, associativity, statelessness
- [ ] **Parallel streams: common pool, when they help and hurt; `Spliterator`**
- [ ] **`Optional`: return types only; `orElse` vs `orElseGet`**

### 7 — Concurrency

- [ ] **BLOCKED vs WAITING**; interruption is cooperative
- [ ] `synchronized`: monitors, lock objects, escalation
- [ ] `ReentrantLock`, `ReadWriteLock`, `StampedLock` optimistic reads
- [ ] **`wait`/`notify` always in a `while`**
- [ ] **JMM happens-before; `volatile`; safe publication**
- [ ] **DCL needs `volatile`; the holder idiom**
- [ ] **CAS, ABA, `LongAdder`, `VarHandle`**
- [ ] `ConcurrentHashMap` internals; atomic compound operations
- [ ] **`ThreadPoolExecutor` submission algorithm; rejection policies**
- [ ] `CompletableFuture` composition and pitfalls
- [ ] Synchronizers: latch, barrier, semaphore, phaser, exchanger
- [ ] **Fork/Join and work stealing**
- [ ] **Virtual threads: mounting, pinning, when to use**
- [ ] **Structured concurrency; scoped values**
- [ ] Deadlock, livelock, starvation; lock ordering
- [ ] `ThreadLocal` and the pooled-thread leak

### 8 — JVM and Memory

- [ ] Memory areas; heap vs stack vs metaspace
- [ ] **Class loading: load/link/initialise; delegation; identity = name + loader**
- [ ] `ClassNotFoundException` vs `NoClassDefFoundError`
- [ ] Bytecode basics; the five `invoke*` instructions
- [ ] **JIT tiers; inlining; escape analysis; deoptimisation**
- [ ] **Reference types: strong, soft, weak, phantom; `Cleaner`**
- [ ] Reflection cost; `MethodHandle`; dynamic proxies
- [ ] **Common memory leak patterns**

### 9 — Garbage Collection

- [ ] GC roots; tracing; why cycles are collected
- [ ] Generational hypothesis; why minor GC is cheap
- [ ] **Serial, Parallel, G1, ZGC, Shenandoah, Epsilon**; generational ZGC
- [ ] Region-based collection; humongous objects
- [ ] Tuning; why `MaxGCPauseMillis` set too low backfires
- [ ] **Container accounting; exit 137 vs `OutOfMemoryError`**

### 10 — IO and Serialization

- [ ] `java.io` decorator streams; byte vs character; encoding
- [ ] **NIO buffers, channels, selectors; blocking vs non-blocking**
- [ ] `Files`/`Path`; streaming large files
- [ ] Memory-mapped files
- [ ] **Why Java serialization is dangerous; gadget chains**
- [ ] `serialVersionUID`; `transient`; alternatives

### 11 — Modern Java

- [ ] LTS timeline: **8, 11, 17, 21, 25**
- [ ] Records, sealed, pattern matching, text blocks
- [ ] Virtual threads, structured concurrency, scoped values
- [ ] **JPMS modules**; FFM API; Vector API

### 12 — Performance

- [ ] Measure → find the bottleneck → fix one thing → measure again
- [ ] async-profiler, JFR, flame graphs, MAT
- [ ] **JMH — why hand-rolled benchmarks lie**

---

## The 24-Hour Plan

| Hours | Focus |
|---|---|
| **1–3** | Collections and Language Core — highest yield |
| **4–8** | **Concurrency** — the largest block; do not compress |
| **9–12** | JVM, memory, GC, leaks |
| **13–16** | OOP, generics, exceptions |
| **17–20** | Lambdas, streams, collectors, Optional, parallelism |

| **21–22** | Modern Java, IO, serialization |
| **23–24** | **Retrieval practice only** — question bank and flash cards |

**The last two hours are worth more than any four hours of reading.** Recognition is not recall; only the question banks distinguish them.

## If You Have Less Time

| Time | Cover |
|---|---|
| 2 h | Java Concurrency Cheat Sheet + Question Bank |
| 6 h | Collections + Concurrency + Question Bank |
| 12 h | Above + JVM/GC + Streams |
| 24 h | Full plan |

## Learning From Zero

Ignore the hour plan. Read blocks 1 → 12 in order, writing code for every concept. Collections assumes Generics; Streams assumes Lambdas; Concurrency assumes the Memory Model.

**Skip nothing in blocks 1, 2, 5 and 7.**

## Related Topics

- [Java Interview Question Bank](../Interview%20Questions/Java%20Interview%20Question%20Bank.md)
- [Java Concurrency Cheat Sheet](../../Cheat%20Sheets/Java%20Concurrency%20Cheat%20Sheet.md)
- [Java Flash Cards](../../Flash%20Cards/Java%20Flash%20Cards.md)
