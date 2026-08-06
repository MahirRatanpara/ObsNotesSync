# Java Interview Question Bank

> Cover the answer column. Answer aloud, then check. Links go to the depth behind each answer.

## Memory Model and Concurrency

| Question | Answer |
|---|---|
| Does `volatile` make `count++` thread-safe? | No — read-modify-write is three operations |
| What does `volatile` guarantee? | Visibility, ordering, and atomicity of 64-bit reads/writes |
| `volatile` vs `synchronized`? | volatile = visibility + ordering; synchronized adds mutual exclusion and atomicity |
| Why does double-checked locking need `volatile`? | Reordering can publish a partially constructed object |
| Best lazy singleton? | Bill Pugh holder idiom, or an enum |
| BLOCKED vs WAITING? | Monitor contention vs voluntary suspension (`wait`/`join`/`park`) |
| `start()` vs `run()`? | `start()` spawns a thread; `run()` executes on the caller |
| What happens when you catch `InterruptedException`? | The interrupt flag is **cleared** — restore it |
| Why must you call `ThreadLocal.remove()`? | Pooled threads outlive requests; the value leaks and can cross requests |
| `wait()` in `if` or `while`? | `while` — spurious wakeups and stolen conditions |
| `notify()` or `notifyAll()`? | `notifyAll()`, or a `Condition` with targeted `signal()` |
| Four deadlock conditions? | Mutual exclusion, hold-and-wait, no preemption, circular wait |
| Most practical deadlock prevention? | Consistent global lock ordering |
| What is CAS? | Atomic compare-and-set, retried in a loop |
| What is ABA and the fix? | A value returns to its original; `AtomicStampedReference` |
| `AtomicLong` vs `LongAdder`? | LongAdder spreads writes across cells — better under contention |
| Replacement for `sun.misc.Unsafe`? | `VarHandle` |
| Is `synchronized` slow? | Uncontended is nearly free (CAS on the header); only real contention escalates |

→ [Java Memory Model](../JVM%20and%20Memory/Java%20Memory%20Model.md) · [Synchronisation and Locks](../Concurrency/Synchronisation%20and%20Locks.md) · [Atomics and CAS](../Concurrency/Atomics%20and%20CAS.md)

## Thread Pools and Async

| Question | Answer |
|---|---|
| Thread pool submission order? | Core threads → **queue** → extra threads → rejection |
| Effect of an unbounded queue? | `maximumPoolSize` is never reached; OOM risk |
| Why avoid `Executors.newFixedThreadPool`? | Unbounded `LinkedBlockingQueue` |
| Which rejection policy gives backpressure? | `CallerRunsPolicy` |
| CPU-bound pool size? | `N + 1` |
| I/O-bound pool size? | `N × (1 + wait/service)` |
| What happens to exceptions in `submit()`? | Captured in the `Future` — silent unless inspected |
| `thenApply` vs `thenCompose`? | map vs flatMap |
| Why not use the default `CompletableFuture` executor? | It's the shared `ForkJoinPool.commonPool()` |
| Why must you `.collect()` before `allOf`? | Streams are lazy — otherwise the fan-out is sequential |
| Does `orTimeout` cancel the task? | No — it keeps running |
| What are virtual threads for? | I/O-bound work; blocking unmounts instead of consuming an OS thread |
| Should you pool virtual threads? | No — they're cheap; pooling defeats the purpose |

→ [Executors and Thread Pools](../Concurrency/Executors%20and%20Thread%20Pools.md) · [CompletableFuture](../Concurrency/CompletableFuture.md)

## Collections

| Question | Answer |
|---|---|
| HashMap default capacity and load factor? | 16 and 0.75 |
| When does a bucket treeify? | 8 entries **and** capacity ≥ 64 |
| Why untreeify at 6? | Hysteresis — prevents thrashing at the boundary |
| How is the index computed? | `(n - 1) & hash` |
| Why XOR the high bits into the hash? | The mask keeps only low bits, so high bits must be mixed down |
| Why power-of-two capacity? | Enables the bitmask instead of modulo |
| What does resizing avoid? | Rehashing — one bit test decides `i` or `i + oldCap` |
| Override `equals` but not `hashCode`? | Hash lookups fail — equal objects land in different buckets |
| Mutable key in a HashMap? | The entry becomes unreachable and unremovable |
| How does ConcurrentHashMap lock? | CAS on empty bins; `synchronized` on the first node otherwise |
| Why does ConcurrentHashMap forbid nulls? | `get() == null` would be ambiguous |
| ArrayList or LinkedList in practice? | ArrayList — cache locality dominates |
| How does fail-fast work? | `modCount` comparison — best-effort only |
| Safe removal during iteration? | `Iterator.remove()` or `removeIf` |
| `Arrays.asList().add()`? | Throws — fixed-size view |
| `List.of()` vs `new ArrayList<>()`? | Immutable and null-hostile vs mutable |

→ [HashMap Internals](../Collections/HashMap%20Internals.md) · [Collections Overview](../Collections/Collections%20Overview.md)

## JVM, Memory, GC

| Question | Answer |
|---|---|
| What replaced PermGen and where does it live? | Metaspace, in **native** memory (Java 8) |
| Where is the string pool since Java 7? | The heap |
| Default GC since Java 9? | G1 |
| Why are minor GCs cheap? | Cost scales with **survivors**, not garbage |
| How do ZGC/Shenandoah get sub-ms pauses? | Concurrent marking and relocation with barriers |
| Does GC collect reference cycles? | Yes — tracing from roots, not reference counting |
| What is a memory leak in Java? | An unintended strong reference keeping objects reachable |
| Preparation vs initialization? | Defaults (`0`, `null`) vs actual values and static blocks |
| Why is the holder singleton thread-safe? | Class initialization is JVM-synchronised and lazy |
| Class identity is determined by? | Fully-qualified name **+ classloader** |
| `ClassNotFoundException` vs `NoClassDefFoundError`? | Dynamic load failed vs present at compile time, missing/failed at runtime |
| Are all objects on the heap? | Escape analysis + scalar replacement can eliminate the allocation |
| Which JIT optimisation enables the others? | Method inlining |
| Why warm up benchmarks? | C2 compiles speculatively; cold code measures the interpreter |
| Exit code 137 vs Java OOM? | Kernel killed the container vs JVM heap exhaustion |

→ [JVM Architecture](../JVM%20and%20Memory/JVM%20Architecture%20and%20Memory%20Areas.md) · [Garbage Collection](../Garbage%20Collection/Garbage%20Collection.md) · [JIT and Escape Analysis](../JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md)

## Language

| Question | Answer |
|---|---|
| `equals` signature must take? | `Object` — otherwise it's an overload, not an override |
| Why 31 in `hashCode`? | Odd prime; `31*i` compiles to `(i << 5) - i` |
| Why is `List<String>` not a `List<Object>`? | It would permit heap pollution |
| What is PECS? | Producer `extends` (read), Consumer `super` (write) |
| Why can't you write `new T()`? | Type erasure — no runtime type |
| Arrays vs generics variance? | Arrays covariant (runtime check); generics invariant (compile-time) |
| Do checked exceptions roll back a transaction? | **No** — Spring rolls back on unchecked only, unless `rollbackFor` is set |
| Why try-with-resources over `finally`? | Close failures are suppressed, not substituted for the real exception |
| Can you return from `finally`? | You can, but it discards a pending exception — never do it |
| Are streams lazy? | Intermediate ops yes; terminal ops trigger execution |
| `Collectors.toMap` on duplicate keys? | Throws — supply a merge function |
| `map` vs `flatMap`? | One-to-one vs one-to-many with flattening |
| When are parallel streams appropriate? | Large, CPU-bound, splittable, stateless, no I/O |
| `orElse` vs `orElseGet`? | `orElse` evaluates eagerly — expensive arguments run every time |
| Where should `Optional` be used? | Return types only — never fields or parameters |
| What do records generate? | `equals`, `hashCode`, `toString`, accessors, canonical constructor |
| Do records replace Builder? | No — they can't express optional parameters |
| What do sealed types enable? | Exhaustive `switch` checked by the compiler |
| Which sort does Java use? | Dual-pivot quicksort for primitives; TimSort for objects (stability) |

→ [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md) · [Exceptions and Generics](../Language%20Core/Exceptions%20and%20Generics.md) · [Modern Java Features](../Language%20Core/Modern%20Java%20Features.md) · [Streams](../Streams%20and%20Functional/Streams.md)

## Spring

| Question | Answer |
|---|---|
| Why constructor injection? | Immutability, fail-fast, testability, visible over-dependency |
| Are singleton beans thread-safe? | One instance guaranteed — **not** thread safety. Keep them stateless. |
| Prototype injected into a singleton? | Injected once; use `ObjectProvider` for a fresh instance |
| `@Configuration` vs `@Component` for `@Bean` methods? | CGLIB proxying vs none — the latter creates duplicate instances |
| Why doesn't `@Transactional` work on an internal call? | The call never passes through the proxy |
| Does a checked exception roll back? | No, unless `rollbackFor` is set |
| REQUIRED vs REQUIRES_NEW? | Join the existing transaction vs suspend and run independently |
| Why does catching an inner exception still fail the commit? | The transaction is marked rollback-only |
| JDK proxy vs CGLIB? | Interface-based vs subclass-based; `final` breaks CGLIB |
| What is N+1 and how do you fix it? | One query per row; `JOIN FETCH`, `@EntityGraph`, `@BatchSize`, or projections |
| Why doesn't `save()` need calling? | Dirty checking on a managed entity |
| What causes `LazyInitializationException`? | Touching a proxy on a detached entity |
| How does Boot know not to configure something? | `@ConditionalOnMissingBean` |
| Should liveness probes check dependencies? | **No** — one dependency failing would restart every pod |

→ [Spring Core and DI](../../14%20Spring%20Boot/Spring%20Core%20and%20Dependency%20Injection.md) · [Spring Transactions and AOP](../../14%20Spring%20Boot/Spring%20Transactions%20and%20AOP.md) · [JPA and Hibernate](../../14%20Spring%20Boot/JPA%20and%20Hibernate.md)

## How To Use This

1. **First pass** — cover the answers, work through, mark every miss
2. **Second pass** — read only the notes behind your misses
3. **Third pass** — retest only the misses

Anything missed twice is a genuine weak area. Everything else is noise.

## Related

- [Java Flash Cards](../../Flash%20Cards/Java%20Flash%20Cards.md)
- [Java Concurrency Cheat Sheet](../../Cheat%20Sheets/Java%20Concurrency%20Cheat%20Sheet.md)
- [Top 100 Interview Questions](../../Top%20100%20Interview%20Questions/Top%20100%20Interview%20Questions.md)
