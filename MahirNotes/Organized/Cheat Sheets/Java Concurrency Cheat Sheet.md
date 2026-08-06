# Java Concurrency Cheat Sheet

## The Three Guarantees

| Mechanism | Atomic | Visible | Ordered |
|---|---|---|---|
| plain field | ✗ | ✗ | ✗ |
| `volatile` | ✗ | ✓ | ✓ |
| `synchronized` | ✓ | ✓ | ✓ |
| `Atomic*` | ✓ | ✓ | ✓ |
| `final` (post-construction) | — | ✓ | ✓ |

**`volatile` does not make `count++` safe.**

## Choose Your Tool

| Problem | Solution |
|---|---|
| Shared counter | `AtomicInteger` / `LongAdder` (high contention) |
| Shared map | `ConcurrentHashMap` + `merge` / `computeIfAbsent` |
| Read-mostly list | `CopyOnWriteArrayList` |
| Producer-consumer | `ArrayBlockingQueue` + `put` / `take` |
| Limit concurrency to N | `Semaphore` |
| Wait for N tasks | `CountDownLatch` |
| N threads meet repeatedly | `CyclicBarrier` |
| Compound invariant | `ReentrantLock` or `synchronized` |
| Read-heavy shared state | `ReadWriteLock` / `StampedLock` |
| Async composition | `CompletableFuture` |
| Per-request context | `ThreadLocal` (+ `remove()`) |

## Thread States

NEW → RUNNABLE → {BLOCKED (monitor), WAITING (wait/join/park), TIMED_WAITING} → TERMINATED

**BLOCKED** = contending for a monitor. **WAITING** = voluntarily suspended.

## Locks

```java
lock.lock();
try { ... } finally { lock.unlock(); }     // finally is mandatory

synchronized (privateLock) { while (!cond) privateLock.wait(); }   // while, not if
```

| | `synchronized` | `ReentrantLock` |
|---|---|---|
| Auto-release | ✓ | ✗ |
| tryLock / timeout | ✗ | ✓ |
| Interruptible | ✗ | ✓ |
| Fairness | ✗ | ✓ |
| Multiple conditions | ✗ | ✓ |

**Default to `synchronized`.**

## Thread Pools

```java
new ThreadPoolExecutor(core, max, keepAlive, unit,
    new ArrayBlockingQueue<>(1000),          // BOUNDED
    namedThreadFactory,
    new CallerRunsPolicy());                 // backpressure
```

- Core threads → **queue** → extra threads → rejection
- Unbounded queue ⟹ `max` never reached ⟹ OOM
- CPU-bound: `N + 1`; I/O-bound: `N × (1 + wait/service)`
- `submit()` **swallows exceptions** into the Future

Never use `Executors.newFixedThreadPool` / `newCachedThreadPool` in production.

## CompletableFuture

```java
List<CompletableFuture<T>> fs = ids.stream()
    .map(id -> supplyAsync(() -> fetch(id), executor))
    .collect(toList());                       // MATERIALISE or it's sequential
allOf(fs.toArray(new CompletableFuture[0]))
    .thenApply(v -> fs.stream().map(CompletableFuture::join).collect(toList()))
    .orTimeout(3, SECONDS)
    .exceptionally(ex -> fallback());
```

- `thenApply` = map; `thenCompose` = flatMap
- Always pass your own executor
- `orTimeout` does **not** cancel the work

## Deadlock

Four conditions: mutual exclusion, hold-and-wait, no preemption, circular wait.

**Prevent with a global lock ordering.** Detect with `jstack`.

## CAS and ABA

```java
do { prev = ref.get(); next = f(prev); } while (!ref.compareAndSet(prev, next));
```

ABA → `AtomicStampedReference`. High contention → `LongAdder`.

## Traps

| Trap | Fix |
|---|---|
| `volatile` counter | `AtomicInteger` |
| DCL without `volatile` | Add it, or use the holder idiom |
| `if` around `wait()` | `while` |
| `notify()` | `notifyAll()` or `Condition.signal()` |
| Synchronising on `this` / String / Integer | Private final lock object |
| Swallowed `InterruptedException` | Restore the flag |
| `ThreadLocal` in a pool | `remove()` in `finally` |
| `Executors.newFixedThreadPool` | Explicit `ThreadPoolExecutor` |
| Ignoring `submit()`'s Future | Inspect it or wrap in try/catch |

## Related

- [Java Memory Model](../02%20Java/JVM%20and%20Memory/Java%20Memory%20Model.md)
- [Synchronisation and Locks](../02%20Java/Concurrency/Synchronisation%20and%20Locks.md)
- [Executors and Thread Pools](../02%20Java/Concurrency/Executors%20and%20Thread%20Pools.md)
