# Java Thread Executors — Mock Interview Notes

> Source: codeWithAryan article on Thread Executors Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets

---

## Table of Contents

1. [Why Thread Executors?](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-why-thread-executors)
2. [Core Interfaces and Classes](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-core-interfaces-and-classes)
3. [execute() vs submit()](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-execute-vs-submit)
4. [Future — Mechanics and Exception Handling](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-future--mechanics-and-exception-handling)
5. [invokeAll()](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-invokeall)
6. [Scheduled Executor — scheduleAtFixedRate vs scheduleWithFixedDelay](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-scheduled-executor--scheduleatfixedrate-vs-schedulewithfixeddelay)
7. [Executor Lifecycle — Shutdown and Daemon Threads](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-executor-lifecycle--shutdown-and-daemon-threads)
8. [ThreadPoolExecutor — Full Constructor](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-threadpoolexecutor--full-constructor)
9. [Executors Factory Methods](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-executors-factory-methods)
10. [Exception Handling Strategies](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#10-exception-handling-strategies)
11. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#11-session-scorecard)
12. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#12-revision-targets)

---

## 1. Why Thread Executors?

Thread Executors provide structured, task-based concurrency on top of raw thread pools. Key advantages:

|Advantage|What It Gives You|
|---|---|
|Task/execution separation|Submit tasks without managing thread creation|
|Built-in thread pooling|Threads reused across tasks — no per-task overhead|
|Scheduling|Delay or repeat tasks via `ScheduledExecutorService`|
|Lifecycle control|Graceful shutdown via `shutdown()` / `shutdownNow()`|
|Monitoring|`getActiveCount()`, `getQueue().size()` on `ThreadPoolExecutor`|

---

## 2. Core Interfaces and Classes

### Hierarchy

```
Executor (base interface)
    └── ExecutorService (adds lifecycle + Future-based submission)
            └── ScheduledExecutorService (adds scheduling)

ThreadPoolExecutor        implements ExecutorService
ScheduledThreadPoolExecutor  implements ScheduledExecutorService
Executors                 factory class (not an interface)
```

### Interface Responsibilities

**`Executor`**

- Base interface with single method: `execute(Runnable command)`
- Decouples task submission from execution mechanism

**`ExecutorService`**

- Extends `Executor`
- Adds: `submit()`, `invokeAll()`, `shutdown()`, `shutdownNow()`, `awaitTermination()`

**`ScheduledExecutorService`**

- Extends `ExecutorService`
- Adds: `schedule()`, `scheduleAtFixedRate()`, `scheduleWithFixedDelay()`

**`ThreadPoolExecutor`**

- Primary concrete implementation of `ExecutorService`
- Full control over all pool parameters

**`ScheduledThreadPoolExecutor`**

- Concrete implementation of `ScheduledExecutorService`
- Combines thread pool tuning with scheduling capabilities

**`Executors`**

- Utility/factory class — not an interface, not an executor
- Provides static factory methods to create ready-to-use executors

---

## 3. execute() vs submit()

### The Comparison Table

|Aspect|`execute()`|`submit()`|
|---|---|---|
|Accepts|`Runnable` only|`Runnable` **and** `Callable`|
|Returns|`void`|`Future<?>` or `Future<T>`|
|Exception handling|Exception lost silently in worker thread|Exception stored in `Future`, thrown on `get()`|
|Result tracking|Not possible|Possible via `future.get()`|

### The Key Point on Exceptions

With `execute()` — if the task throws, the exception dies in the worker thread. No record, no propagation, no way to know it failed.

With `submit()` — exception is **captured and stored** inside the `Future`. It only surfaces when you call `future.get()`, which throws `ExecutionException` wrapping the original.

```java
// execute — exception is silently lost
executor.execute(() -> { throw new RuntimeException("Lost!"); });

// submit — exception is captured
Future<?> f = executor.submit(() -> { throw new RuntimeException("Captured!"); });
try {
    f.get(); // throws ExecutionException
} catch (ExecutionException e) {
    e.getCause(); // original RuntimeException
}
```

### Q&A Recap

**Q:** What does `submit()` give you that `execute()` doesn't? **A:** Returns a `Future`, allows result retrieval and exception capture ✅ **Note:** Input type difference (Callable support) needed prompting ⚠️

### ⚠️ GAP IDENTIFIED

Always state **both** differences proactively:

1. `submit()` accepts `Callable`; `execute()` only accepts `Runnable`
2. `submit()` returns `Future<T>`; `execute()` returns `void`

---

## 4. Future — Mechanics and Exception Handling

### What Is a Future?

A `Future<T>` represents the result of an asynchronous computation. It is a handle to a task that may not have completed yet.

### Key Methods

|Method|Returns|Meaning|
|---|---|---|
|`future.get()`|`T`|Blocks until result is available. Throws if task failed or interrupted.|
|`future.isDone()`|`boolean`|`true` if task reached any terminal state (success, exception, or cancellation)|
|`future.isCancelled()`|`boolean`|`true` if task was cancelled before completion|

### isDone() — The Trap

`isDone()` returns `true` for **any** terminal state — not just successful completion.

```java
Future<Integer> future = executor.submit(() -> {
    throw new RuntimeException("Boom!");
});

future.isDone();  // true — task completed (via exception)
future.get();     // throws ExecutionException
```

> isDone() = "is the task no longer running?" NOT = "did the task succeed?"

### Checked Exceptions from future.get()

`future.get()` throws two checked exceptions:

1. **`ExecutionException`** — the submitted task itself threw an exception during execution. Access the original via `e.getCause()`.
    
2. **`InterruptedException`** — the thread calling `get()` was interrupted while waiting. Always restore the interrupt flag: `Thread.currentThread().interrupt()`.
    

```java
try {
    String result = future.get();
} catch (ExecutionException e) {
    Throwable cause = e.getCause(); // original exception from task
    System.out.println("Task failed: " + cause.getMessage());
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // restore interrupt flag
}
```

### Q&A Recap

**Q:** What two checked exceptions does `future.get()` throw? **A:** `ExecutionException` and `InterruptedException` ✅

**Q:** `future.isDone()` when task threw exception — true or false? **A:** true ✅ — with correct reasoning (any terminal state, not just success)

---

## 5. invokeAll()

### What It Does

Submits a collection of `Callable` tasks, waits for **all** to complete, and returns a `List<Future<T>>`.

```java
List<Callable<String>> tasks = Arrays.asList(
    () -> "Task 1",
    () -> "Task 2",
    () -> { throw new RuntimeException("Task 3 failed"); }
);

List<Future<String>> results = executor.invokeAll(tasks);
```

### Key Behaviors

**Blocking:** `invokeAll()` blocks the calling thread until every single task finishes — success or failure.

**Partial failure:** If one task fails, its `Future` stores the exception. Other tasks continue running unaffected.

**Result inspection:**

```java
for (int i = 0; i < results.size(); i++) {
    try {
        System.out.println("Task " + (i+1) + ": " + results.get(i).get());
    } catch (ExecutionException e) {
        System.out.println("Task " + (i+1) + " failed: " + e.getCause().getMessage());
    }
}
```

### Overloaded Version with Timeout

```java
// Cancels any tasks not completed within the timeout
List<Future<String>> results = executor.invokeAll(tasks, 1, TimeUnit.SECONDS);
```

### Return Type

`List<Future<T>>` — always. One `Future` per submitted task, in the same order.

### Q&A Recap

**Q:** Task 3 of 5 throws. What happens to tasks 1, 2, 4, 5? **A:** They continue running independently. Each future holds its own result or exception. ✅

---

## 6. Scheduled Executor — scheduleAtFixedRate vs scheduleWithFixedDelay

### Creating a Scheduled Executor

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
```

### One-Shot Scheduling

```java
scheduler.schedule(() -> System.out.println("Run once"), 2, TimeUnit.SECONDS);
```

Runs once after a 2-second delay. If the task throws, it won't retry.

### scheduleAtFixedRate

```java
scheduler.scheduleAtFixedRate(task, initialDelay, period, TimeUnit.SECONDS);
```

- Period is measured from **task start** to **next task start**
- Tries to maintain consistent rate regardless of task duration
- If task takes **longer** than the period:
    - With multiple threads → overlap is possible
    - With single thread → next run starts **immediately** after current finishes (no overlap, no catch-up)
- If task throws an exception → **all future executions are silently cancelled**

### scheduleWithFixedDelay

```java
scheduler.scheduleWithFixedDelay(task, initialDelay, delay, TimeUnit.SECONDS);
```

- Delay is measured from **task completion** to **next task start**
- Overlap is **impossible by design** — next run never starts until previous one finishes
- Safer for tasks with unpredictable or variable execution times
- If task throws an exception → future executions also cancelled

### Side-by-Side Example

Task takes 3 seconds. Period/delay = 2 seconds.

|Method|Next execution starts at...|
|---|---|
|`scheduleAtFixedRate`|T=2s (if threads available) or immediately after T=3s finishes (single thread)|
|`scheduleWithFixedDelay`|T = 3s (task completes) + 2s (delay) = T=5s after start|

### Missed Executions in scheduleAtFixedRate

If the task takes longer than the period, **missed executions are not queued**. The scheduler fires the next execution immediately after the current finishes — it does not try to catch up with multiple back-to-back runs.

### Q&A Recap

**Q:** Task takes 3s, period=2s. Walk through both methods. **A:** `scheduleWithFixedDelay` = 5s total ✅. `scheduleAtFixedRate` said new thread spawns at 2s mark ❌ — corrected to: depends on thread pool size; single thread = no overlap.

### ⚠️ GAP IDENTIFIED

`scheduleAtFixedRate` with a single-threaded pool and a long task: no new thread is spawned. The scheduler is constrained by available threads. Next run starts immediately after current finishes — rate is best-effort, not guaranteed.

---

## 7. Executor Lifecycle — Shutdown and Daemon Threads

### Why You Must Shut Down

Executor threads are **non-daemon by default**. The JVM waits for all non-daemon threads to finish before exiting. If you never call `shutdown()`, the executor threads stay alive indefinitely — keeping the JVM up, leaking memory, exhausting resources.

### Daemon vs Non-Daemon

|Type|JVM exits when...|
|---|---|
|Non-daemon (default)|All non-daemon threads finish|
|Daemon|Automatically killed when all non-daemon threads finish|

> It's not the main thread specifically that triggers JVM exit — it's when **all non-daemon threads** are done. If other non-daemon threads exist, daemon threads stay alive.

### Shutdown Methods (from previous article — referenced here)

|Method|Queue|Running tasks|Returns|
|---|---|---|---|
|`shutdown()`|Drains completely|Completes normally|`void`|
|`shutdownNow()`|Abandons|Interrupted|`List<Runnable>`|

### Q&A Recap

**Q:** Why doesn't the JVM shut down if you forget `shutdown()`? **A:** Non-daemon threads keep JVM alive ✅. Correctly distinguished daemon vs non-daemon behavior ✅. **Correction added:** JVM exits when all non-daemon threads finish — not specifically when main thread finishes.

---

## 8. ThreadPoolExecutor — Full Constructor

### 5-Parameter Constructor (Basic)

```java
new ThreadPoolExecutor(
    int corePoolSize,           // 1: min threads always alive
    int maximumPoolSize,        // 2: max threads ever
    long keepAliveTime,         // 3: idle time before non-core thread terminates
    TimeUnit unit,              // 4: unit for keepAliveTime
    BlockingQueue<Runnable> workQueue  // 5: queue for waiting tasks
);
```

### 7-Parameter Constructor (Full)

```java
new ThreadPoolExecutor(
    int corePoolSize,           // 1
    int maximumPoolSize,        // 2
    long keepAliveTime,         // 3
    TimeUnit unit,              // 4
    BlockingQueue<Runnable> workQueue,  // 5
    ThreadFactory threadFactory,        // 6 ← naming, daemon config
    RejectedExecutionHandler handler    // 7 ← what to do when queue + max full
);
```

### Parameter 6 — ThreadFactory

Controls how new threads are created. Use to:

- Set thread names (for debugging)
- Set daemon status
- Set thread priority

```java
Executors.newFixedThreadPool(2, runnable -> {
    Thread t = new Thread(runnable);
    t.setName("CustomThread-" + t.getId());
    t.setDaemon(true); // JVM can exit even if these threads are running
    return t;
});
```

### Parameter 7 — RejectedExecutionHandler

Applied when queue is full AND maximumPoolSize threads are all busy.

|Policy|Behavior|
|---|---|
|`AbortPolicy` (default)|Throws `RejectedExecutionException`|
|`CallerRunsPolicy`|Calling thread runs the task itself|
|`DiscardPolicy`|Silently discards the task|
|`DiscardOldestPolicy`|Discards oldest queued task, retries|

### Q&A Recap

**Q:** How many parameters in the full constructor? **A:** 5 ⚠️ — missed `threadFactory` (6) and `rejectionHandler` (7)

### ⚠️ GAP IDENTIFIED

The 5-parameter constructor is what you'll use most, but the **full constructor has 7**. In an interview asking about "full configuration," always include `threadFactory` and `rejectionHandler`. The 5-param version just uses defaults for those two.

---

## 9. Executors Factory Methods

### ⚠️ CRITICAL DISTINCTION

**Factory methods** are static methods on the `Executors` **class** that _create_ executor instances. **Scheduling methods** (`scheduleAtFixedRate`, `scheduleWithFixedDelay`) are called _on_ the executor after creation.

These are two completely different layers. Do not confuse them.

### The Four Factory Methods (from article)

```java
// 1. Fixed number of threads — reused across tasks
ExecutorService fixedPool = Executors.newFixedThreadPool(int nThreads);

// 2. Dynamic thread creation — threads created as needed, reclaimed after 60s idle
ExecutorService cachedPool = Executors.newCachedThreadPool();

// 3. Single thread — tasks execute sequentially, one at a time
ExecutorService singleThread = Executors.newSingleThreadExecutor();

// 4. Scheduled pool — supports delayed and periodic task execution
ScheduledExecutorService scheduledPool = Executors.newScheduledThreadPool(int corePoolSize);
```

### When to Use Which

|Factory Method|Best For|
|---|---|
|`newFixedThreadPool(n)`|CPU-bound tasks; predictable load|
|`newCachedThreadPool()`|I/O-bound, short-lived tasks; variable load|
|`newSingleThreadExecutor()`|Sequential task processing; ordering guarantee|
|`newScheduledThreadPool(n)`|Delayed or recurring tasks|

### Q&A Recap

**Q:** Name the four factory methods on `Executors`. **A:** Named scheduling methods instead ❌

### ⚠️ GAP IDENTIFIED

`scheduleAtFixedRate` and `scheduleWithFixedDelay` are **not** factory methods. They are methods called on a `ScheduledExecutorService` instance. Factory methods are the `Executors.newXxx()` static methods that return executor instances.

---

## 10. Exception Handling Strategies

### Strategy 1 — Catch at Call Site (future.get())

```java
Future<Integer> future = executor.submit(() -> riskyOperation());
try {
    Integer result = future.get();
} catch (ExecutionException e) {
    log.error("Task failed: " + e.getCause());
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
}
```

**Use when:** The caller needs to know success/failure to make decisions (retry, compensation, reporting).

### Strategy 2 — Catch Inside the Task

```java
executor.submit(() -> {
    try {
        riskyOperation();
    } catch (Exception e) {
        log.error("Handled inside task: " + e.getMessage());
        // recover, retry, or record locally
    }
});
```

**Use when:** Tasks are fire-and-forget; errors are self-contained; you don't need the caller to react.

### Production Recommendation

For thousands of tasks — handle **inside the task**. Wrapping every `future.get()` call in try-catch across thousands of submissions is verbose, error-prone, and couples the caller to task internals.

Reserve call-site handling for workflows where task outcome drives further logic.

### What Happens with execute() — The Silent Failure

```java
executor.execute(() -> { throw new RuntimeException("Lost!"); });
// No Future, no catch, no record — exception is gone
```

Never use `execute()` for tasks where failure matters and you have no internal error handling.

### Q&A Recap

**Q:** Which exception handling strategy is safer for thousands of tasks in production? **A:** Inside the task ✅ — good reasoning on verbosity and error localization.

---

## 11. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|`execute()` vs `submit()` return type|✅|Clean|
|`execute()` vs `submit()` input types|⚠️|Needed prompting for Callable distinction|
|Exception capture mechanism in `Future`|✅|Clean|
|`future.get()` checked exceptions|✅|Both named correctly|
|`isDone()` semantics|✅|Correct — any terminal state, not just success|
|`invokeAll()` partial failure behavior|✅|Clean|
|`invokeAll()` return type|✅|Clean|
|`scheduleAtFixedRate` vs `scheduleWithFixedDelay`|✅|Good|
|`scheduleAtFixedRate` single thread + long task|❌ → ✅|Said new thread spawns — corrected|
|Non-daemon threads keeping JVM alive|✅|Clean|
|Daemon thread nuance (all non-daemon, not just main)|⚠️|Correction added|
|Exception handling inside task vs call site|✅|Good production reasoning|
|`scheduleAtFixedRate` exception → cancels future runs|✅|Clean|
|`Executors` factory methods (naming)|❌|Confused with scheduling methods|
|Full `ThreadPoolExecutor` constructor (7 params)|⚠️|Knew 5, missed threadFactory + rejectionHandler|

---

## 12. Revision Targets

### 🔴 Priority 1 — Must Be Instinct Before the Interview

**1. Executors factory methods vs scheduling methods — never confuse these**

```
FACTORY METHODS (on Executors class — create executors):
  Executors.newFixedThreadPool(n)
  Executors.newCachedThreadPool()
  Executors.newSingleThreadExecutor()
  Executors.newScheduledThreadPool(n)

SCHEDULING METHODS (on ScheduledExecutorService instance — schedule tasks):
  scheduler.schedule(task, delay, unit)
  scheduler.scheduleAtFixedRate(task, initialDelay, period, unit)
  scheduler.scheduleWithFixedDelay(task, initialDelay, delay, unit)
```

These are different layers. Factory methods create executors. Scheduling methods use them.

---

**2. Full ThreadPoolExecutor constructor — 7 parameters**

```java
new ThreadPoolExecutor(
    corePoolSize,       // 1 — min always-alive threads
    maximumPoolSize,    // 2 — absolute thread ceiling
    keepAliveTime,      // 3 — idle timeout for non-core threads
    timeUnit,           // 4 — unit for above
    workQueue,          // 5 — task queue
    threadFactory,      // 6 — how to create threads (name, daemon, priority)
    rejectionHandler    // 7 — what to do when queue + max full
)
```

The 5-param version uses defaults for 6 and 7. The full version gives complete control.

---

### 🟡 Priority 2 — High Probability Interview Topics

**3. execute() — always state BOTH differences from submit()**

- Input: `execute()` → `Runnable` only. `submit()` → `Runnable` + `Callable`
- Output: `execute()` → `void`. `submit()` → `Future<T>`
- Exception: `execute()` → silently lost. `submit()` → stored in `Future`

**4. scheduleAtFixedRate with single-threaded pool + long task** No new thread is spawned. The rate is best-effort. With one thread busy, the next execution waits and fires immediately after the current finishes. No overlap, no catch-up.

**5. JVM shutdown trigger** It's when **all non-daemon threads finish** — not specifically when the main thread finishes. If other non-daemon threads are alive, the JVM stays up.

---

### 🟢 Already Solid — Just Review

- `future.get()` throws `ExecutionException` + `InterruptedException` — know both cold
- `isDone()` = any terminal state (success, failure, cancellation)
- `invokeAll()` blocks until all tasks complete; returns `List<Future<T>>`
- Exception handling inside task vs at call site — tradeoffs clear
- `scheduleAtFixedRate` exception → silent cancellation of future runs
- Daemon threads killed when all non-daemon threads finish

---

## Quick Reference Cheatsheet

```
EXECUTOR HIERARCHY:
Executor → ExecutorService → ScheduledExecutorService
              ↑                        ↑
    ThreadPoolExecutor      ScheduledThreadPoolExecutor

FACTORY METHODS (Executors class):
  newFixedThreadPool(n)       → fixed n threads
  newCachedThreadPool()       → dynamic, reclaim after 60s idle
  newSingleThreadExecutor()   → sequential, 1 thread
  newScheduledThreadPool(n)   → for delayed/periodic tasks

SUBMIT vs EXECUTE:
  execute(Runnable)           → void, exception lost
  submit(Runnable/Callable)   → Future<T>, exception in Future

FUTURE:
  future.get()                → blocks; throws ExecutionException / InterruptedException
  future.isDone()             → true for ANY terminal state
  e.getCause()                → original exception from ExecutionException

SCHEDULING:
  scheduleAtFixedRate         → period from START; overlap possible; rate is best-effort
  scheduleWithFixedDelay      → delay from COMPLETION; no overlap by design

THREADPOOLEXECUTOR (7 params):
  core, max, keepAlive, unit, queue, threadFactory, rejectionHandler

FULL TASK SUBMISSION ORDER:
  core threads → queue → non-core threads → rejection policy
```