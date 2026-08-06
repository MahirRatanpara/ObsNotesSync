# Concurrency Problem Patterns

> Problem → tool lookup. When an interviewer describes a concurrency scenario, this maps it to the right primitive in seconds.

## The Decision Table

| The problem sounds like | Use |
|---|---|
| Shared counter | `AtomicInteger` / `AtomicLong` |
| **High-contention counter or metric** | **`LongAdder`** |
| Shared map | `ConcurrentHashMap` + `merge` / `computeIfAbsent` |
| Compute a value once, share it | `ConcurrentHashMap.computeIfAbsent` |
| Read-mostly list (listeners) | `CopyOnWriteArrayList` |
| **Producer–consumer** | **`ArrayBlockingQueue`** + `put` / `take` |
| Limit concurrent access to N | **`Semaphore`** |
| Wait for N tasks to finish | **`CountDownLatch`** |
| N threads meet repeatedly | `CyclicBarrier` |
| One-time lazy initialisation | Holder idiom, or `computeIfAbsent` |
| Invariant across several fields | `ReentrantLock` or `synchronized` |
| Read-heavy shared state | `ReadWriteLock` / `StampedLock` |
| Compose async operations | `CompletableFuture` |
| Fan-out to many I/O calls | `CompletableFuture` + dedicated executor, or virtual threads |
| Per-request context | `ThreadLocal` (+ `remove()`) |
| Rate limiting | `Semaphore`, or a token bucket |
| Deduplicate concurrent identical work | `ConcurrentHashMap<K, CompletableFuture<V>>` |

## The Classic Problems

### Producer–Consumer

```java
BlockingQueue<Task> q = new ArrayBlockingQueue<>(1000);   // BOUNDED

// producer
q.put(task);            // blocks when full → natural backpressure

// consumer
Task t = q.take();      // blocks when empty → no busy-wait
```

**Bounded is the whole point.** An unbounded queue converts a throughput problem into an `OutOfMemoryError`.

**Shutdown via poison pill:** push one sentinel per consumer; each exits on receiving it.

### Bounded Resource Pool

```java
Semaphore permits = new Semaphore(10);
permits.acquire();
try { useConnection(); }
finally { permits.release(); }        // release in finally, always
```

A `release()` outside `finally` permanently leaks a permit on exception, and the pool silently shrinks to zero over time.

### Wait For N Parallel Tasks

```java
CountDownLatch latch = new CountDownLatch(n);
for (var task : tasks) executor.submit(() -> {
    try { task.run(); } finally { latch.countDown(); }   // countDown in finally
});
latch.await(30, TimeUnit.SECONDS);                        // ALWAYS use the timeout
```

**`countDown()` must be in a `finally`** — an exception otherwise leaves the latch waiting forever.
**Always use the timeout variant** — an untimed `await()` can hang forever.

### Deduplicate Concurrent Identical Work (Request Coalescing)

Ten threads request the same uncached key; you want **one** database call.

```java
ConcurrentHashMap<String, CompletableFuture<Value>> inFlight = new ConcurrentHashMap<>();

CompletableFuture<Value> get(String key) {
    return inFlight.computeIfAbsent(key, k -> 
        CompletableFuture.supplyAsync(() -> load(k), executor)
            .whenComplete((v, e) -> inFlight.remove(k)));    // clean up
}
```

**This is the in-process fix for a [cache stampede](../../04%20High%20Level%20Design/Core%20Concepts/Caching.md)**, and a strong thing to produce unprompted.

**Warning:** `computeIfAbsent`'s mapping function runs while holding the bin lock, so it must not block or touch the same map. Here it only *starts* an async task, which is safe.

### Read-Heavy Shared State

```java
private final ReadWriteLock rw = new ReentrantReadWriteLock();

rw.readLock().lock();
try { return cache.get(key); } finally { rw.readLock().unlock(); }
```

Only worth it with a **high read:write ratio and non-trivial critical sections**. With frequent writes it's slower than a plain lock due to bookkeeping overhead.

### Parallel Fan-Out With Timeout

```java
List<CompletableFuture<R>> futures = ids.stream()
    .map(id -> CompletableFuture.supplyAsync(() -> fetch(id), executor))
    .collect(toList());                                    // MATERIALISE

CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
    .orTimeout(3, TimeUnit.SECONDS)
    .exceptionally(e -> null)
    .join();

List<R> results = futures.stream()
    .filter(f -> f.isDone() && !f.isCompletedExceptionally())
    .map(CompletableFuture::join).collect(toList());
```

**The `.collect()` before `allOf` is mandatory** — streams are lazy, and without it the futures are created one at a time and execute **sequentially**.

## Debugging Checklist

| Symptom | Cause | Tool |
|---|---|---|
| Hangs forever | Deadlock, or untimed `await`/`get` | `jstack` — reports Java-level deadlocks explicitly |
| Wrong results intermittently | Race condition, or missing visibility | Code review; add stress tests |
| Works locally, fails in production | Timing- and JIT-dependent visibility bug | Check for missing `volatile` |
| Threads pile up in BLOCKED | Lock contention | Thread dump — count threads on the same monitor |
| High CPU, low throughput | CAS retry storm, or busy-wait | Profiler |
| Gradual slowdown | Pool exhaustion, or `ThreadLocal` leak | Pool metrics, heap dump |
| `IllegalMonitorStateException` | `wait`/`notify` without holding the monitor | Read the code |

**`jstack` explicitly prints "Found one Java-level deadlock"** with the cycle — the first thing to run on a hung JVM.

## The Rules That Prevent Most Bugs

1. **Prefer immutability.** No shared mutable state, no problem.
2. **Prefer `java.util.concurrent` over hand-rolled locking.** The library is correct; your code probably isn't.
3. **`unlock()` in `finally`**, always.
4. **`while`, not `if`, around `wait()`.**
5. **Consistent global lock ordering** to prevent deadlock.
6. **Never hold a lock across I/O or an unknown callback.**
7. **Bound every queue and pool.**
8. **`ThreadLocal.remove()` in a `finally`** when using pooled threads.
9. **Always use timeout variants** of `await`, `get`, `tryLock`.
10. **Document thread safety** — say whether a class is safe, and under what conditions.

## Interview Framing

When given a concurrency scenario:

1. **Name the shared mutable state** — "the seat map is shared"
2. **State the invariant** — "a seat must be held by at most one user"
3. **Pick the narrowest tool** — "per-seat atomic update, not a global lock"
4. **Justify granularity** — "locking the whole theatre would serialise every user"
5. **Mention failure** — "if the holder crashes, the hold expires by timestamp"

**Step 4 is what interviewers listen for.** Correct-but-global locking is a weak answer; correct-and-scoped is a strong one.

## Related Topics

- [Synchronisation and Locks](Synchronisation%20and%20Locks.md)
- [Concurrent Collections](Concurrent%20Collections.md)
- [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md)
- [Concurrency in LLD](../../03%20Low%20Level%20Design/Concurrency%20in%20LLD/Concurrency%20in%20LLD.md)

## Revision Summary

Map the scenario to a library primitive rather than hand-rolling locks. Bound every queue and pool, release in `finally`, use timeout variants everywhere, and lock the narrowest unit that preserves the invariant. Immutability removes the problem entirely.

## Quick Recall

- Counter → `AtomicInteger`; contended → `LongAdder`
- Producer–consumer → **bounded** `BlockingQueue`, `put`/`take`
- Limit concurrency → `Semaphore`, release in `finally`
- Wait for N → `CountDownLatch`, `countDown` in `finally`, **timed `await`**
- Coalesce duplicate work → `ConcurrentHashMap<K, CompletableFuture<V>>`
- Fan-out → **`.collect()` before `allOf`** or it's sequential
- Hung JVM → `jstack`
- Name the state, the invariant, then lock the smallest unit
