# Fork/Join and Parallel Execution

## Why It Matters

The engine behind parallel streams and `CompletableFuture`'s default executor. Work stealing is a genuinely elegant idea, and knowing that the common pool is shared JVM-wide explains a class of production problem.

## The Model

Fork/Join targets **divide-and-conquer** problems: split recursively until small enough, solve, combine.

```java
class SumTask extends RecursiveTask<Long> {
    private static final int THRESHOLD = 10_000;
    private final long[] array; private final int lo, hi;

    protected Long compute() {
        if (hi - lo <= THRESHOLD) {              // small enough — solve directly
            long sum = 0;
            for (int i = lo; i < hi; i++) sum += array[i];
            return sum;
        }
        int mid = lo + (hi - lo) / 2;
        SumTask left  = new SumTask(array, lo, mid);
        SumTask right = new SumTask(array, mid, hi);
        left.fork();                    // schedule left asynchronously
        long rightResult = right.compute();   // compute right on THIS thread
        return rightResult + left.join();     // wait for left
    }
}
```

**The idiom `fork()` one half, `compute()` the other, then `join()`** is deliberate. Forking both halves and joining both wastes a thread — the current one would sit idle. Computing one inline keeps it busy.

| Class | Returns |
|---|---|
| `RecursiveTask<V>` | A value |
| `RecursiveAction` | Void |
| `CountedCompleter` | Completion-based, avoids blocking joins |

## Work Stealing

The core idea, and what makes Fork/Join different from a normal thread pool.

**Each worker thread has its own double-ended queue (deque):**

```
Worker pushes and pops its OWN tasks from the HEAD  (LIFO — no contention)
Idle workers STEAL from the TAIL of another queue   (FIFO — least contention)
```

**Why LIFO for your own tasks:** the most recently forked task is likely still in cache, and it's the smallest sub-problem — so locality is good.

**Why FIFO for stealing:** the oldest task at the tail is the *largest* remaining sub-problem, so one steal transfers a big chunk of work. It also minimises contention with the owner, who is working at the opposite end.

**Result:** near-zero synchronisation in the common case, automatic load balancing, and good cache behaviour. That combination is why it scales.

## The Common Pool — And Its Problem

```java
ForkJoinPool.commonPool();          // shared JVM-wide
```

**Default parallelism = `availableProcessors() - 1`**, because the submitting thread also participates.

**Who uses it:**
- Every `parallelStream()`
- `CompletableFuture.supplyAsync(...)` **without an explicit executor**
- Any `ForkJoinTask` submitted without a pool

**The problem: it is shared across the entire JVM, including libraries you don't control.**

```java
// This BLOCKS a common-pool thread for 5 seconds
CompletableFuture.supplyAsync(() -> slowHttpCall());
```

On an 8-core machine the pool has 7 threads. **Eight such calls starve every parallel stream and every other library using the pool.**

**Rules:**

| Rule | Reason |
|---|---|
| **Never block on the common pool** | It starves everything else |
| **Always pass an explicit executor to `CompletableFuture`** | |
| **Never do I/O in a parallel stream** | Same reason |
| Use a dedicated `ForkJoinPool` for CPU-bound custom work | Isolation |

```java
ForkJoinPool pool = new ForkJoinPool(4);
pool.submit(() -> list.parallelStream().map(...).toList()).join();
```

**Submitting a parallel stream into a custom pool works** because the stream uses the pool of the calling thread — a useful and slightly obscure trick.

## ManagedBlocker — The Escape Hatch

If you genuinely must block inside Fork/Join, tell the pool so it can compensate by starting another thread:

```java
ForkJoinPool.managedBlock(new ForkJoinPool.ManagedBlocker() {
    public boolean block() throws InterruptedException { result = queue.take(); return true; }
    public boolean isReleasable() { return result != null; }
});
```

Rarely needed directly — but it's how `CompletableFuture.join()` avoids deadlocking the pool, and knowing that is a good depth signal.

## Parallel Streams

```java
list.parallelStream().filter(...).map(...).collect(...);
```

The stream is split by a **`Spliterator`**, processed in parallel on the common pool, and results are merged.

### When parallelism helps

**All of these must hold:**

| Condition | Why |
|---|---|
| **Large dataset** | Rule of thumb: 10,000+ elements |
| **CPU-bound work per element** | Otherwise overhead dominates |
| **Splittable source** | `ArrayList`, arrays, `IntStream.range` split well |
| **Stateless, associative operations** | Required for correctness |
| **No I/O or blocking** | Would starve the common pool |
| Merging is cheap | Expensive combine kills the gain |

### Sources split badly

| Source | Splitting |
|---|---|
| `ArrayList`, arrays, `IntStream.range` | **Excellent** — O(1), known size |
| `HashSet`, `HashMap` | Decent |
| **`LinkedList`** | **Terrible** — must traverse to split |
| `Stream.iterate` | **Terrible** — inherently sequential |
| `BufferedReader.lines` | Poor — unknown size |

**`LinkedList.parallelStream()` is almost always slower than sequential**, because splitting requires walking the list.

### Correctness traps

```java
// WRONG — race condition
List<String> out = new ArrayList<>();
list.parallelStream().forEach(out::add);       // ArrayList is not thread-safe

// RIGHT
List<String> out = list.parallelStream().collect(toList());
```

**`forEach` gives no ordering guarantee in parallel.** Use `forEachOrdered` if order matters — but that serialises the terminal operation and usually erases the benefit.

**Non-associative reduction breaks silently:**
```java
stream.reduce(0, (a, b) -> a - b);    // subtraction is NOT associative
// sequential and parallel give DIFFERENT answers
```

**Ordered operations cost more in parallel:** `findFirst` must respect encounter order, so it's more expensive than `findAny`. `sorted` and `distinct` on an ordered parallel stream require buffering.

**The honest summary: parallel streams are frequently slower than sequential for realistic workloads.** Measure. The overhead of splitting, scheduling, and merging is real, and most collections in real applications are small.

## Fork/Join vs ThreadPoolExecutor

| | `ForkJoinPool` | `ThreadPoolExecutor` |
|---|---|---|
| Queue | **Per-worker deques, work stealing** | **One shared queue** |
| Best for | **Recursive divide-and-conquer, CPU-bound** | Independent tasks, **I/O-bound** |
| Tasks spawn subtasks | **Yes, designed for it** | No |
| Blocking tasks | **Harmful** | Fine — size the pool for it |
| Contention | Low (own deque) | Higher (shared queue) |

**Use `ThreadPoolExecutor` for independent I/O-bound tasks; Fork/Join for recursive CPU-bound decomposition.** Using the wrong one is a common mistake.

**With virtual threads (Java 21+), most I/O-bound work should use `newVirtualThreadPerTaskExecutor` instead of either.** See [Virtual Threads and Structured Concurrency](Virtual%20Threads%20and%20Structured%20Concurrency.md).

## Choosing the Threshold

Too small → scheduling overhead dominates. Too large → poor load balancing.

**Rule of thumb: the sequential threshold should represent 10–100 µs of work**, and you should aim for roughly 10× more tasks than cores so stealing can balance them.

**There is no universal number — measure with JMH.**

## Common Mistakes

- Blocking on the common pool
- `CompletableFuture.supplyAsync` without an executor
- I/O in a parallel stream
- `parallelStream` on small collections or `LinkedList`
- Mutating shared state in `forEach`
- Non-associative reduce or combiner
- Forking both halves instead of forking one and computing the other
- Assuming parallel is faster without measuring

## Related Topics

- [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md)
- [CompletableFuture](CompletableFuture.md)
- [Virtual Threads and Structured Concurrency](Virtual%20Threads%20and%20Structured%20Concurrency.md)
- [Parallel Streams and Spliterators](../Streams%20and%20Functional/Parallel%20Streams%20and%20Spliterators.md)

## Revision Summary

Fork/Join uses per-worker deques with work stealing — LIFO locally for cache locality, FIFO when stealing to grab the largest chunk. The common pool is shared JVM-wide with `cores − 1` threads, so blocking on it starves parallel streams and other libraries. Parallel streams help only for large, CPU-bound, splittable, stateless work.

## Quick Recall

- **Fork one half, compute the other, then join** — don't fork both
- **Work stealing: LIFO own deque, FIFO steal from the tail**
- Common pool = **`cores − 1`, shared JVM-wide**
- **Never block on the common pool**; always pass an executor to `CompletableFuture`
- Parallel needs: large, CPU-bound, splittable, stateless, no I/O
- `LinkedList` and `Stream.iterate` split terribly
- Non-associative reduce breaks silently in parallel
- Fork/Join = recursive CPU work; `ThreadPoolExecutor` = independent I/O
- **Measure — parallel is often slower**
