# Java Flash Cards

> Cover the answer column. Say the answer out loud before revealing it.

## Memory Model and Concurrency

| Prompt | Answer |
|---|---|
| Does `volatile` make `count++` thread-safe? | **No** — it's read-modify-write |
| What does `volatile` guarantee? | Visibility and ordering; atomicity only for 64-bit reads/writes |
| Why does double-checked locking need `volatile`? | Reordering can publish a partially constructed object |
| Preferred lazy singleton | Bill Pugh holder idiom, or an enum |
| BLOCKED vs WAITING | Contending for a monitor vs voluntarily suspended (wait/join/park) |
| `start()` vs `run()` | `start()` creates a thread; `run()` executes on the caller |
| What does catching `InterruptedException` do to the flag? | **Clears it** — you must restore it |
| ThreadLocal in a thread pool | Must call `remove()`, or it leaks across requests |
| `wait()` — `if` or `while`? | **`while`** — spurious wakeups and stolen conditions |
| `notify()` or `notifyAll()`? | `notifyAll()`, or a `Condition` with `signal()` |
| Deadlock prevention, most practical | Consistent global lock ordering |
| What is ABA? | A value changes to B and back to A; CAS succeeds wrongly |
| ABA fix | `AtomicStampedReference` |
| High-contention counter | `LongAdder`, not `AtomicLong` |
| Replacement for `sun.misc.Unsafe` | `VarHandle` |

## Thread Pools

| Prompt | Answer |
|---|---|
| Order of the submission algorithm | Core threads → **queue** → extra threads → rejection |
| Effect of an unbounded queue | `maximumPoolSize` is never reached; risk of OOM |
| Why avoid `Executors.newFixedThreadPool`? | Unbounded `LinkedBlockingQueue` |
| Rejection policy giving backpressure | `CallerRunsPolicy` |
| CPU-bound pool size | `N + 1` |
| I/O-bound pool size | `N × (1 + wait/service)` |
| What happens to an exception in `submit()`? | Captured in the `Future` — silent unless you inspect it |
| `scheduleAtFixedRate` risk | Executions can overlap or pile up |
| A scheduled task that throws | All future executions are silently cancelled |

## CompletableFuture

| Prompt | Answer |
|---|---|
| `thenApply` vs `thenCompose` | map vs flatMap |
| Default executor and why it's a problem | `ForkJoinPool.commonPool()` — shared JVM-wide |
| Why must you `.collect()` before `allOf`? | Streams are lazy — otherwise the fan-out runs sequentially |
| Does `orTimeout` cancel the work? | **No** — the task keeps running |
| `join()` vs `get()` | Unchecked `CompletionException` vs checked `ExecutionException` |

## Collections

| Prompt | Answer |
|---|---|
| HashMap default capacity and load factor | 16 and 0.75 |
| Treeify threshold, and the capacity condition | 8 entries, but only if capacity ≥ 64 |
| Untreeify threshold, and why different | 6 — hysteresis prevents thrashing |
| Index computation | `(n - 1) & hash` |
| Why XOR the high bits into the hash? | The mask keeps only low bits, so high bits must be mixed down |
| Why must capacity be a power of two? | Enables the bitmask instead of modulo |
| What does resizing avoid recomputing? | Rehashing — one bit test decides `i` or `i + oldCap` |
| ConcurrentHashMap locking (Java 8+) | CAS on an empty bin; `synchronized` on the first node otherwise |
| Why does ConcurrentHashMap reject nulls? | `get() == null` would be ambiguous |
| ArrayList vs LinkedList in practice | ArrayList — cache locality beats theoretical insertion cost |
| Stack and Vector | Legacy, synchronised — use `ArrayDeque` |
| Fail-fast mechanism | `modCount` comparison — best-effort only |
| Safe removal during iteration | `Iterator.remove()` or `removeIf` |
| `Arrays.asList().add()` | Throws `UnsupportedOperationException` — fixed size |

## JVM

| Prompt | Answer |
|---|---|
| What replaced PermGen, and where does it live? | Metaspace, in **native** memory (Java 8) |
| Where does the string pool live since Java 7? | The heap |
| Default GC since Java 9 | G1 |
| Why are minor GCs cheap? | Cost scales with **survivors**, not garbage |
| How do ZGC/Shenandoah get sub-ms pauses? | Concurrent marking and relocation with barriers |
| Does GC collect reference cycles? | Yes — tracing from roots, not reference counting |
| Preparation vs initialization | Defaults (`0`, `null`) vs actual values and static blocks |
| Why is the holder singleton thread-safe? | Class initialization is JVM-synchronised and lazy |
| Class identity is determined by | Fully-qualified name **+ classloader** |
| ClassNotFoundException vs NoClassDefFoundError | Dynamic load failed vs present at compile time but missing/failed at runtime |
| Are all objects heap-allocated? | Logically yes, but escape analysis + scalar replacement can eliminate the allocation |
| Which optimisation enables the others? | Method inlining |
| Why warm up benchmarks? | C2 compiles speculatively; cold code measures the interpreter |

## Language

| Prompt | Answer |
|---|---|
| Overriding `equals` without `hashCode` | Hash lookups fail — equal objects land in different buckets |
| `equals` signature must take | `Object` — otherwise it's an overload |
| Mutable key in a HashMap | The entry becomes unreachable and unremovable |
| Why 31 in hashCode? | Odd prime; `31*i` compiles to `(i << 5) - i` |
| Why is `List<String>` not a `List<Object>`? | It would allow heap pollution |
| PECS | Producer `extends` (read), Consumer `super` (write) |
| Why can't you write `new T()`? | Type erasure — no runtime type |
| Arrays vs generics variance | Arrays covariant (runtime check), generics invariant (compile-time) |
| Why try-with-resources over `finally`? | Close failures are suppressed, not substituted for the real exception |
| Are streams lazy? | Intermediate ops yes; terminal ops trigger execution |
| `Collectors.toMap` on duplicate keys | Throws — supply a merge function |
| Sort used for primitives vs objects | Dual-pivot quicksort vs TimSort (objects need stability) |

## Related

- [Java Concurrency Cheat Sheet](../Cheat%20Sheets/Java%20Concurrency%20Cheat%20Sheet.md)
- [Java Memory Model](../02%20Java/JVM%20and%20Memory/Java%20Memory%20Model.md)
- [HashMap Internals](../02%20Java/Collections/HashMap%20Internals.md)
