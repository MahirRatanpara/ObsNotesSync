# Virtual Threads and Structured Concurrency

## Why It Matters

The largest change to Java concurrency since Java 5. Virtual threads (final in 21) make thread-per-request viable again and remove most of the reason to adopt reactive frameworks. Expect this in any modern Java interview.

## The Problem They Solve

A platform thread is an OS thread: **~1 MB of reserved stack** plus kernel structures. That caps you at roughly 10,000 threads.

```
Thread-per-request:  simple code, blocks freely  →  ~10K concurrent requests
Event loop / reactive: 100K+ concurrent, but callback-based, hard to debug
```

**You had to choose between readable code and scalability.** Virtual threads remove the choice.

## How They Work

A virtual thread is a **JVM-managed continuation** scheduled onto a small pool of **carrier** platform threads (by default, a `ForkJoinPool` sized to the core count).

```
Virtual thread blocks on I/O
   → JVM UNMOUNTS it from the carrier, parking its stack on the heap
   → carrier immediately runs another virtual thread
   → I/O completes → virtual thread is remounted (possibly on a different carrier)
```

**The key sentence: blocking a virtual thread does not block an OS thread.** The stack moves to the heap and the carrier is freed.

**Virtual threads do not make I/O faster.** They stop blocking I/O from consuming an expensive OS thread. Saying that precisely is the interview answer.

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (var task : tasks) executor.submit(task);
}   // close() waits for all tasks

Thread.startVirtualThread(() -> doWork());
Thread.ofVirtual().name("worker-", 0).start(runnable);
```

## Platform vs Virtual

| | Platform thread | Virtual thread |
|---|---|---|
| Backed by | OS thread | **JVM continuation on the heap** |
| Stack | ~1 MB reserved | **Grows/shrinks, a few hundred bytes initially** |
| Creation cost | ~1 ms | **~1 µs** |
| Practical count | ~10,000 | **Millions** |
| Scheduled by | OS | **JVM (ForkJoinPool carriers)** |
| Pooling | **Essential** | **Harmful** |
| Best for | CPU-bound | **I/O-bound** |

## The Four Rules

### 1. Do not pool them

```java
// WRONG — pooling defeats the purpose
ExecutorService pool = Executors.newFixedThreadPool(200, virtualThreadFactory);

// RIGHT — one virtual thread per task
Executors.newVirtualThreadPerTaskExecutor();
```

Pooling exists to amortise expensive creation. Virtual threads are cheap, so a pool only reintroduces the concurrency limit you were trying to remove.

**Use a `Semaphore` if you need to limit concurrency** — that expresses the actual constraint (usually a downstream service's capacity) rather than conflating it with thread count.

### 2. I/O-bound only

No benefit for CPU-bound work — you still have N cores. A million virtual threads doing computation just adds scheduling overhead.

### 3. Beware pinning

A virtual thread **pinned** to its carrier cannot unmount, so the carrier blocks — reintroducing the platform-thread limit.

| Pins | Fix |
|---|---|
| **`synchronized` block that blocks** | **Use `ReentrantLock`** |
| Native method / JNI frame | Unavoidable |

```java
// PINS the carrier while blocking
synchronized (lock) { database.query(); }

// Does NOT pin
lock.lock();
try { database.query(); } finally { lock.unlock(); }
```

**This was the single biggest adoption blocker in Java 21**, since library code was full of `synchronized`. **JDK 24 (JEP 491) largely eliminated `synchronized` pinning**, so on modern JDKs this is far less of a concern — but `ReentrantLock` remains the safer choice, and knowing the history is worth a sentence.

Detect with `-Djdk.tracePinnedThreads=full`.

### 4. Avoid ThreadLocal

A million virtual threads × a `ThreadLocal` value is a million objects. Virtual threads support it, but the memory model doesn't scale. **Use scoped values instead.**

## Structured Concurrency

The problem: unstructured concurrency leaks.

```java
// UNSTRUCTURED — if this method throws, the tasks keep running
var f1 = executor.submit(this::fetchUser);
var f2 = executor.submit(this::fetchOrders);
return combine(f1.get(), f2.get());
```

If `f1.get()` throws, `f2` is orphaned — still running, still consuming resources, with nobody waiting for it.

**Structured concurrency binds task lifetime to a lexical scope**, exactly as a `try` block binds a resource:

```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    Subtask<User>        user   = scope.fork(this::fetchUser);
    Subtask<List<Order>> orders = scope.fork(this::fetchOrders);

    scope.join();              // wait for all
    scope.throwIfFailed();     // propagate the first failure

    return combine(user.get(), orders.get());
}   // close() guarantees ALL subtasks are done or cancelled
```

**Guarantees:**

| Property | Meaning |
|---|---|
| **No leaks** | Every subtask finishes or is cancelled before the block exits |
| **Error propagation** | A subtask failure cancels its siblings |
| **Cancellation propagates** | Cancelling the scope cancels children |
| **Observability** | Thread dumps show the parent-child tree |

**Two built-in policies:**
- `ShutdownOnFailure` — all must succeed; first failure cancels the rest
- `ShutdownOnSuccess` — first success wins, cancel the rest (hedged requests)

**Status:** structured concurrency has been in preview across several releases and the API has changed between them. **Verify the exact API against your JDK's release notes** — the concept is stable, the surface is not.

## Scoped Values

The replacement for `ThreadLocal` in a virtual-thread world.

```java
private static final ScopedValue<User> CURRENT_USER = ScopedValue.newInstance();

ScopedValue.where(CURRENT_USER, user)
           .run(() -> handleRequest());   // visible to this call tree only

// deep inside
User u = CURRENT_USER.get();
```

| | `ThreadLocal` | `ScopedValue` |
|---|---|---|
| Mutable | **Yes** | **No — immutable** |
| Lifetime | Until `remove()` | **Bounded by the scope** |
| Leaks in pools | **Yes** | **Impossible** |
| Inherited by children | Only with `InheritableThreadLocal` (copies) | **Yes, shared not copied** |
| Memory with 1M threads | 1M objects | **One, shared** |

**The immutability and bounded lifetime are what make it safe.** There is no `remove()` to forget, because the binding ends when the scope does.

**Scoped values were finalised in Java 25.**

## What This Means Architecturally

**Virtual threads largely remove the case for reactive frameworks.**

| | Reactive (WebFlux) | Virtual threads |
|---|---|---|
| Code style | Callback/operator chains | **Plain blocking** |
| Stack traces | Fragmented, hard to read | **Normal and complete** |
| Debugging | Difficult | **Standard** |
| Scalability | High | **Comparable** |
| Ecosystem | Needs reactive drivers throughout | **Existing blocking libraries work** |

```properties
spring.threads.virtual.enabled=true
```

**For most services, Spring MVC with virtual threads is now the right default** — you get the scalability without reactive complexity. Reactive still wins for genuine streaming and backpressure semantics.

**Saying this demonstrates current knowledge** rather than reciting a 2019 comparison. See [Spring Web and Boot Internals](../../14%20Spring%20Boot/Spring%20Web%20and%20Boot%20Internals.md).

## What Doesn't Change

- **Shared mutable state still needs synchronisation.** Virtual threads are still threads.
- **Race conditions are unchanged**, and are now *more* likely to surface because you have far more concurrency.
- The [Java Memory Model](../JVM%20and%20Memory/Java%20Memory%20Model.md) applies identically.
- **Downstream capacity is still finite** — a million virtual threads hitting a 20-connection database pool just queues. Bound concurrency deliberately with a `Semaphore`.

**That last point is the one people miss.** Removing the thread limit exposes whatever limit is next.

## Common Mistakes

- Pooling virtual threads
- Using them for CPU-bound work
- `synchronized` around blocking calls (on pre-24 JDKs)
- `ThreadLocal` at scale instead of scoped values
- Assuming they fix race conditions
- Forgetting downstream limits — unbounded fan-out to a bounded resource
- Treating structured concurrency's API as stable across releases

## Related Topics

- [Threads and Lifecycle](Threads%20and%20Lifecycle.md)
- [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md)
- [CompletableFuture](CompletableFuture.md)
- [Processes and Threads](../../10%20Operating%20Systems/Processes%20and%20Threads/Processes%20and%20Threads.md)

## Revision Summary

Virtual threads are JVM continuations mounted on carrier threads; blocking unmounts rather than blocking an OS thread, making thread-per-request scale to millions. Don't pool them, use them for I/O, prefer `ReentrantLock` over `synchronized`, and replace `ThreadLocal` with scoped values. Structured concurrency binds subtask lifetime to a scope so nothing leaks.

## Quick Recall

- **Blocking unmounts the virtual thread; the carrier is freed**
- They don't speed up I/O — they stop it wasting an OS thread
- **Never pool**; bound concurrency with a `Semaphore` instead
- I/O-bound only
- **`synchronized` pinned carriers pre-JDK 24** → prefer `ReentrantLock`
- `ThreadLocal` → **scoped values** (immutable, scope-bounded, shared)
- Structured concurrency: `fork` → `join` → `throwIfFailed`, **no leaks**
- **MVC + virtual threads is the modern default** over reactive
- Race conditions and downstream limits are unchanged
