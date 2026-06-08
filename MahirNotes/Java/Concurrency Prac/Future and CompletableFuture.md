> Source: codeWithAryan article on Future and CompletableFuture Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets

---

## Table of Contents

1. [Future Interface — Core Mechanics](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-future-interface--core-mechanics)
2. [Four Limitations of Future](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-four-limitations-of-future)
3. [Future Cancellation — Cooperative Model](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-future-cancellation--cooperative-model)
4. [CompletableFuture — Overview](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-completablefuture--overview)
5. [get() vs join() — Exception Type Difference](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-get-vs-join--exception-type-difference)
6. [Creating CompletableFutures](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-creating-completablefutures)
7. [Chaining — thenApply vs thenApplyAsync](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-chaining--thenapply-vs-thenapplyasync)
8. [Combining — thenCombine, allOf, anyOf](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-combining--thencombine-allof-anyof)
9. [Exception Handling — exceptionally vs handle](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-exception-handling--exceptionally-vs-handle)
10. [Timeouts — orTimeout vs completeOnTimeout](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#10-timeouts--ortimeout-vs-completeontimeout)
11. [Future vs CompletableFuture — Full Comparison](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#11-future-vs-completablefuture--full-comparison)
12. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#12-session-scorecard)
13. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#13-revision-targets)

---

## 1. Future Interface — Core Mechanics

### What Is a Future?

A `Future<T>` is a placeholder for the result of an asynchronous computation that may not be available yet. Obtained from `ExecutorService.submit()`.

### Key Methods

|Method|Behavior|
|---|---|
|`get()`|Blocks indefinitely until result is available. Throws `InterruptedException` or `ExecutionException`|
|`get(timeout, unit)`|Blocks up to timeout. Throws `TimeoutException` if not ready. Task keeps running.|
|`isDone()`|Returns `true` for any terminal state (success, exception, cancellation)|
|`isCancelled()`|Returns `true` if cancelled before completion|
|`cancel(true)`|Sends interrupt signal to running task — cooperative, not forceful|

### get() vs get(timeout, unit)

```java
// Blocks forever — risky if task hangs
String result = future.get();

// Blocks for 2 seconds max — safe
try {
    String result = future.get(2, TimeUnit.SECONDS);
} catch (TimeoutException e) {
    // Task still running in background — cancel if needed
    future.cancel(true);
}
```

**Critical:** `get(timeout, unit)` throwing `TimeoutException` does NOT cancel the task. The underlying thread keeps running. Explicit `future.cancel(true)` is needed to stop it.

### Basic Usage Pattern

```java
ExecutorService executor = Executors.newSingleThreadExecutor();
Future<String> future = executor.submit(() -> {
    Thread.sleep(2000);
    return "Task completed!";
});

System.out.println("Is done? " + future.isDone()); // false — still running
String result = future.get();                       // blocks ~2 seconds
System.out.println("Is done? " + future.isDone()); // true
executor.shutdown();
```

### Q&A Recap

**Q:** Difference between get() and get(timeout)? **A:** get() blocks indefinitely; get(timeout) throws TimeoutException if not ready; task keeps running ✅

---

## 2. Four Limitations of Future

### The Four — Know These Cold

|#|Limitation|Description|
|---|---|---|
|1|**No composition**|Cannot chain dependent tasks — no way to say "when this finishes, run that"|
|2|**Blocking operations**|`get()` blocks the calling thread — potential performance bottleneck|
|3|**No completion notification**|No callback/event mechanism — must poll `isDone()` or block with `get()`|
|4|**No exception handling**|Exceptions only surface when `get()` is called — no built-in recovery|

### Why These Matter

All four are directly addressed by `CompletableFuture`:

1. → `thenApply()`, `thenCompose()` for chaining
2. → `thenAccept()`, `thenRun()` for non-blocking callbacks
3. → Callbacks fire automatically on completion
4. → `exceptionally()`, `handle()` for built-in recovery

### Q&A Recap

**Q:** Four limitations of Future? **A:** All four named correctly ✅

---

## 3. Future Cancellation — Cooperative Model

### How cancel(true) Works

`future.cancel(true)` sends an **interrupt signal** to the thread running the task. It does NOT forcefully stop the thread — Java has no mechanism for that.

The interrupted flag is set to `true`. The task must check this flag and exit voluntarily.

### What the Task Must Do

```java
Future<?> future = executor.submit(() -> {
    while (true) {
        if (Thread.currentThread().isInterrupted()) { // ← MUST check this
            System.out.println("Interrupted — stopping.");
            break;
        }
        // do work
    }
});

future.cancel(true); // sets interrupt flag — task checks and exits
```

### What Happens Without the Check

```java
// BROKEN — ignores interrupt flag
Future<?> future = executor.submit(() -> {
    while (true) {
        // never checks isInterrupted()
        // task runs forever even after cancel(true)
    }
});
future.cancel(true); // flag set, but task keeps running — cancel is a no-op
```

### The Rule

> Cancellation in Java is **cooperative**. The task must opt in by periodically checking `Thread.currentThread().isInterrupted()` and exiting when set.

### Q&A Recap

**Q:** What must the task do for cancel(true) to work? **A:** Periodically check Thread.isInterrupted() and exit when set ✅

---

## 4. CompletableFuture — Overview

### What It Is

`CompletableFuture<T>` extends `Future<T>` and implements `CompletionStage<T>`. Introduced in Java 8. Addresses all four `Future` limitations.

### Six Key Features

|Feature|What It Enables|
|---|---|
|Non-blocking|Callbacks execute when task completes — no blocking needed|
|Composition|Chain operations with `thenApply`, `thenCompose`|
|Combination|Combine multiple futures with `allOf`, `anyOf`, `thenCombine`|
|Exception handling|`exceptionally()`, `handle()` — inline recovery|
|Completion callbacks|`thenAccept()`, `thenRun()` — fire on completion|
|Explicit completion|`complete(value)` — manually complete a future|

### The Core Difference from Future

```java
// Future — blocking
String result = future.get(); // main thread blocks here
doNextThing(result);

// CompletableFuture — non-blocking callback
CompletableFuture.supplyAsync(() -> compute())
    .thenAccept(result -> doNextThing(result)); // callback, main thread free
System.out.println("Main thread is free to do other work");
```

---

## 5. get() vs join() — Exception Type Difference

### The Precise Difference

|Method|Exception Type|Compiler Forces Handling?|
|---|---|---|
|`get()`|**Checked** — `InterruptedException`, `ExecutionException`|✅ Yes — must use try-catch|
|`join()`|**Unchecked** — `CompletionException`|❌ No — compiler won't warn you|

### Code Comparison

```java
// get() — compiler forces you to handle
try {
    String result = future.get();
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
} catch (ExecutionException e) {
    Throwable cause = e.getCause(); // original exception
}

// join() — no try-catch required (risky if exceptions can occur)
String result = future.join(); // throws CompletionException if task failed
```

### When to Use join()

Only use `join()` when you are **certain** no exceptions will occur, or inside a callback chain where unchecked exceptions are acceptable. In callbacks (like `thenRun`), `join()` is preferred over `get()` to avoid verbose checked exception handling.

### ⚠️ GAP IDENTIFIED

The exact exception names matter in interviews:

- `get()` throws `InterruptedException` AND `ExecutionException` (both checked)
- `join()` throws `CompletionException` (unchecked)
- `join()` is "not recommended" because the compiler won't enforce handling — silent failures possible

---

## 6. Creating CompletableFutures

### Three Ways to Create

```java
// 1. Already-completed future (useful for testing/mocking)
CompletableFuture<String> completed = CompletableFuture.completedFuture("Result");

// 2. Async task with result (most common)
CompletableFuture<String> async = CompletableFuture.supplyAsync(() -> {
    return "Computed result";
});

// 3. Manual completion (for complex scenarios, timeouts, fallbacks)
CompletableFuture<String> manual = new CompletableFuture<>();
manual.complete("Manual Result"); // completes it explicitly
// complete() returns false if already completed — idempotent
```

### supplyAsync vs runAsync

|Method|Returns|Use When|
|---|---|---|
|`supplyAsync(Supplier)`|`CompletableFuture<T>`|Task produces a result|
|`runAsync(Runnable)`|`CompletableFuture<Void>`|Task has no result (side-effect only)|

### Default Thread Pool

Both `supplyAsync` and `runAsync` use the **ForkJoinPool common pool** by default. Pass a custom `Executor` as second argument to use a different pool.

---

## 7. Chaining — thenApply vs thenApplyAsync

### The Difference — Which Thread Executes

|Method|Executes On|
|---|---|
|`thenApply(fn)`|Same thread that completed the previous stage|
|`thenApplyAsync(fn)`|New thread from ForkJoinPool common pool|

### Article Output Evidence

```
supplyAsync running in:    ForkJoinPool.commonPool-worker-1
thenApply running in:      ForkJoinPool.commonPool-worker-1  ← same thread
thenApplyAsync running in: ForkJoinPool.commonPool-worker-2  ← new thread
```

### When to Use Each

- **`thenApply`** — lightweight transformation, OK to run on current thread
- **`thenApplyAsync`** — heavy computation, or when you don't want to block an important thread (e.g. event loop, I/O thread)

### Chaining Example

```java
CompletableFuture<String> result = CompletableFuture
    .supplyAsync(() -> "Hello")              // async, ForkJoinPool
    .thenApply(s -> s + " World")            // same thread as supplyAsync
    .thenApplyAsync(s -> s + "!")            // new ForkJoinPool thread
    .thenApply(String::toUpperCase);         // same thread as thenApplyAsync
```

### Other Chaining Methods

|Method|Input|Output|Use|
|---|---|---|---|
|`thenApply(fn)`|result|new result|Transform result|
|`thenAccept(fn)`|result|void|Consume result, no return|
|`thenRun(fn)`|nothing|void|Run action after completion|
|`thenCompose(fn)`|result|`CompletableFuture<U>`|Flat-map — chain futures that return futures|

---

## 8. Combining — thenCombine, allOf, anyOf

### thenCombine — Combine Two Futures

```java
CompletableFuture<String> f1 = CompletableFuture.supplyAsync(() -> "Hello");
CompletableFuture<String> f2 = CompletableFuture.supplyAsync(() -> "World");

CompletableFuture<String> combined = f1.thenCombine(f2,
    (result1, result2) -> result1 + " " + result2);

System.out.println(combined.join()); // "Hello World"
```

Both run in parallel. Combination function runs when **both** complete.

### allOf — Wait for All

```java
CompletableFuture<String> userF   = CompletableFuture.supplyAsync(() -> fetchUser());
CompletableFuture<String> orderF  = CompletableFuture.supplyAsync(() -> fetchOrders());

CompletableFuture<Void> all = CompletableFuture.allOf(userF, orderF);

all.thenRun(() -> {
    String user  = userF.join();   // safe — already completed
    String order = orderF.join();  // safe — already completed
    renderPage(user, order);
});
```

**Return type:** `CompletableFuture<Void>` — because futures may be of different types, no single result type works. Fetch individual results from each future after `allOf` completes.

### anyOf — First Completed Wins

```java
CompletableFuture<Object> first = CompletableFuture.anyOf(f1, f2, f3);
Object result = first.join(); // result of whichever finished first
```

**Return type:** `CompletableFuture<Object>` — because it doesn't know which future will complete first or what type it carries. Cast or check `isDone()` on individual futures for typed access.

### allOf vs anyOf

|Method|Waits For|Return Type|Use When|
|---|---|---|---|
|`allOf(...)`|All futures complete|`CompletableFuture<Void>`|Need all results (e.g. render page)|
|`anyOf(...)`|First future completes|`CompletableFuture<Object>`|Need fastest result (e.g. fastest server)|

---

## 9. Exception Handling — exceptionally vs handle

### exceptionally — Recovery on Failure Only

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> {
        throw new RuntimeException("Something went wrong!");
    })
    .exceptionally(ex -> {
        System.out.println("Caught: " + ex.getMessage());
        return "Recovery value"; // returned as result
    });

System.out.println(future.join()); // "Recovery value"
```

- **Only called when exception occurs**
- Receives the exception, returns a recovery value
- If no exception — skipped entirely, original result passes through

### handle — Always Executes

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> "Success path")
    .handle((result, ex) -> {
        if (ex != null) {
            return "Error: " + ex.getMessage();
        }
        return "OK: " + result;
    });
```

- **Always called** — regardless of success or failure
- Receives `(result, exception)` — one will always be null
- More flexible, more verbose

### Comparison Table

|Aspect|`exceptionally`|`handle`|
|---|---|---|
|When called|Only on exception|Always|
|Parameters|`Throwable`|`(T result, Throwable ex)`|
|Return|Recovery value|Any value (success or recovery)|
|Use when|Simple fallback needed|Need to handle both cases|

---

## 10. Timeouts — orTimeout vs completeOnTimeout

### orTimeout — Fail on Timeout

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> slowOperation())         // takes 3 seconds
    .orTimeout(2, TimeUnit.SECONDS);            // timeout after 2 seconds

try {
    System.out.println(future.join());
} catch (CompletionException e) {
    // e.getCause() is a TimeoutException
    System.out.println("Timed out: " + e.getCause().getClass().getSimpleName());
}
```

### completeOnTimeout — Default Value on Timeout

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> slowOperation())
    .completeOnTimeout("Default value", 2, TimeUnit.SECONDS);

System.out.println(future.join()); // "Default value" if timed out
```

### Key Distinction

|Method|On Timeout|Exception?|
|---|---|---|
|`orTimeout(t, unit)`|Completes exceptionally with `TimeoutException`|Yes — `CompletionException` wrapping `TimeoutException`|
|`completeOnTimeout(val, t, unit)`|Completes normally with default value|No|

### Critical — Original Task Keeps Running

Both methods only affect the `CompletableFuture` chain. The underlying task thread **keeps running** after timeout. To actually stop it, you need explicit cancellation.

---

## 11. Future vs CompletableFuture — Full Comparison

|Feature|`Future`|`CompletableFuture`|
|---|---|---|
|Result retrieval|`get()` — blocking only|`get()`, `join()`, or callbacks|
|Non-blocking|❌|✅ `thenApply`, `thenAccept`, etc.|
|Chaining|❌|✅ `thenApply`, `thenCompose`|
|Combining|❌|✅ `allOf`, `anyOf`, `thenCombine`|
|Exception handling|Manual via `get()`|✅ `exceptionally`, `handle`|
|Completion callbacks|❌|✅ `thenAccept`, `thenRun`|
|Manual completion|❌|✅ `complete(value)`|
|Timeouts|`get(timeout, unit)` only|✅ `orTimeout`, `completeOnTimeout`|
|Introduced|Java 5|Java 8|

---

## 12. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|`get()` vs `get(timeout)`|✅|Clean|
|Task keeps running after timeout|✅|Clean|
|Four Future limitations|✅|All four named correctly|
|`cancel(true)` cooperative cancellation|✅|Clean|
|`get()` vs `join()` exception types|⚠️|Direction correct; precise type names needed sharpening|
|`thenApply` vs `thenApplyAsync` thread|✅|Clean|
|`allOf()` return type and why Void|✅|Clean with reasoning|
|`allOf()` vs `anyOf()` behavior|✅|Clean|
|`exceptionally()` vs `handle()`|✅|Clean|
|`orTimeout()` vs `completeOnTimeout()`|✅|Clean|
|`allOf` + `thenRun` skeleton code|✅|Correct; join() over get() noted|
|`supplyAsync()` method name|✅|Clean|
|`anyOf()` safe result usage|✅|Clean|

---

## 13. Revision Targets

### 🔴 Priority 1 — Must Be Instinct

**1. get() vs join() — exact exception names**

```
get()  → checked  → InterruptedException + ExecutionException
join() → unchecked → CompletionException
```

`join()` is "not recommended" unless you're certain no exceptions occur — compiler won't force handling, so exceptions can be silently missed. Inside callbacks (`thenRun`, `thenAccept`), `join()` is preferred to avoid verbose checked exception handling.

---

### 🟡 Priority 2

**2. allOf() return type reasoning** `CompletableFuture<Void>` — futures may be different types, no common type exists. After `allOf` completes, call `join()` on each individual future to get typed results.

**3. orTimeout vs completeOnTimeout**

- `orTimeout` → exceptionally with `TimeoutException` → caught as `CompletionException`
- `completeOnTimeout` → normally with default value → no exception
- Both: original task keeps running after timeout

**4. cancel(true) is cooperative** Sets interrupt flag. Task must check `Thread.currentThread().isInterrupted()` periodically. Without the check, cancel has no effect.

---

### 🟢 Already Solid

- Four Future limitations (no composition, blocking, no notification, no exception handling)
- `supplyAsync()` for async task creation
- `thenApply` (same thread) vs `thenApplyAsync` (new ForkJoinPool thread)
- `exceptionally` (failure only) vs `handle` (always)
- `allOf` (all complete) vs `anyOf` (first completes)
- `thenCombine` for combining two futures' results
- `allOf` + `thenRun` + `join()` pattern for page rendering use case

---

## Quick Reference Cheatsheet

```
FUTURE:
  get()              → blocks indefinitely; checked exceptions
  get(timeout, unit) → TimeoutException if not ready; task keeps running
  isDone()           → any terminal state (success/failure/cancel)
  cancel(true)       → sets interrupt flag; task must check isInterrupted()

COMPLETABLEFUTURE CREATION:
  supplyAsync(Supplier) → async task with result
  runAsync(Runnable)    → async task, no result
  completedFuture(val)  → pre-completed
  new CompletableFuture<>() + complete(val) → manual

get() vs join():
  get()  → checked (InterruptedException, ExecutionException)
  join() → unchecked (CompletionException) — use in callbacks

CHAINING:
  thenApply(fn)      → same thread, transforms result
  thenApplyAsync(fn) → new ForkJoinPool thread, transforms result
  thenAccept(fn)     → consume result, void
  thenRun(fn)        → no input, no output, runs after
  thenCompose(fn)    → flat-map (fn returns CompletableFuture)

COMBINING:
  thenCombine(f2, fn)    → both results when both done
  allOf(f1, f2, ...)     → CompletableFuture<Void> when all done
  anyOf(f1, f2, ...)     → CompletableFuture<Object> when first done

EXCEPTION HANDLING:
  exceptionally(fn) → only on failure; returns recovery value
  handle(fn)        → always; receives (result, ex); one is null

TIMEOUTS:
  orTimeout(t, unit)            → TimeoutException on timeout
  completeOnTimeout(val, t, unit) → default value on timeout
  Both: original task keeps running after timeout
```