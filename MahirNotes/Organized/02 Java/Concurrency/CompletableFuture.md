# CompletableFuture

## Why It Matters

The standard way to compose asynchronous work in Java. Interviewers use it to test whether you can parallelise I/O correctly and handle failure.

## Creating

```java
CompletableFuture.supplyAsync(() -> fetch())            // returns a value
CompletableFuture.runAsync(() -> doWork())              // returns void
CompletableFuture.supplyAsync(() -> fetch(), executor)  // ALWAYS pass an executor
CompletableFuture.completedFuture(value)                // already done
```

**Always supply your own executor.** The default is `ForkJoinPool.commonPool()`, which is sized to `cores − 1` and shared JVM-wide — blocking I/O on it starves parallel streams and every other library using it.

## Chaining

| Method | Transform | Runs on |
|---|---|---|
| `thenApply(fn)` | `T → U` | Completing thread (may be the caller) |
| `thenApplyAsync(fn, ex)` | `T → U` | The given executor |
| `thenCompose(fn)` | `T → CompletableFuture<U>` — **flatMap** | — |
| `thenCombine(other, fn)` | Two futures → one result | — |
| `thenAccept(c)` | Consume, return void | — |
| `thenRun(r)` | Ignore the value | — |

**`thenApply` vs `thenCompose`** is the classic question: `thenApply` with a function that returns a future gives you `CompletableFuture<CompletableFuture<U>>`. `thenCompose` flattens it. Same relationship as `map` vs `flatMap`.

## Parallel Fan-Out — The Correct Pattern

```java
List<CompletableFuture<Result>> futures = ids.stream()
    .map(id -> CompletableFuture.supplyAsync(() -> fetch(id), executor))
    .collect(Collectors.toList());          // MATERIALISE first

CompletableFuture<Void> all = CompletableFuture.allOf(
        futures.toArray(new CompletableFuture[0]));

List<Result> results = all.thenApply(v ->
        futures.stream().map(CompletableFuture::join).collect(Collectors.toList())
).join();
```

**The `.collect()` before `allOf` is essential.** Streams are lazy — without materialising, the futures are created one at a time during the terminal operation and execute **sequentially**. This is a genuinely common bug and a great thing to point out unprompted.

`allOf` returns `CompletableFuture<Void>`; you must re-join each future to collect results. `anyOf` completes with the first result — useful for hedged requests.

## Timeouts

```java
future.orTimeout(2, TimeUnit.SECONDS)                      // fail with TimeoutException
      .completeOnTimeout(fallback, 2, TimeUnit.SECONDS)    // supply a default
```

Both are Java 9+. **A timeout does not cancel the underlying work** — the task keeps running and consuming a thread. For real cancellation you need the task itself to observe interruption.

## Error Handling

| Method | Behaviour |
|---|---|
| `exceptionally(fn)` | Recover from a failure, same type |
| `handle((v, ex) -> ...)` | Runs on both success and failure |
| `whenComplete((v, ex) -> ...)` | Side effect, **does not** change the result |

```java
fetchUser(id)
    .thenCompose(this::fetchOrders)
    .orTimeout(3, TimeUnit.SECONDS)
    .exceptionally(ex -> {
        log.warn("failed, serving degraded response", ex);
        return Collections.emptyList();
    })
    .thenAccept(this::render);
```

**Exceptions propagate down the chain** — a failure short-circuits all subsequent `thenApply` stages straight to the first handler.

`join()` throws unchecked `CompletionException`; `get()` throws checked `ExecutionException`. Both wrap the original cause — unwrap with `ex.getCause()`.

## Resilience Composition

Production fan-out layers these, innermost first:

```
retry( circuitBreaker( bulkhead( timeout( call ) ) ) )
```

- **Timeout** — bound each individual call
- **Bulkhead** — a dedicated pool per downstream, so one slow dependency can't exhaust shared threads
- **Circuit breaker** — stop calling a failing dependency (CLOSED → OPEN → HALF_OPEN)
- **Retry** — only for *transient* failures, with exponential backoff and jitter, and only on idempotent operations

Resilience4j implements all four as decorators.

## Common Mistakes

- Using the default common pool for blocking I/O
- Not materialising the stream before `allOf` — silently sequential
- `thenApply` where `thenCompose` is needed, producing nested futures
- Expecting `orTimeout` to cancel the running task
- Ignoring the returned future of `exceptionally` (it returns a new future)
- Retrying non-idempotent operations

## Related Topics

- [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md)
- [Circuit Breaker](../../08%20Microservices/Circuit%20Breaker.md)
- Concurrency Problem Patterns *(not yet written)*

## Revision Summary

Compose with `thenApply`/`thenCompose`/`thenCombine`, always on your own executor. Materialise the list before `allOf` or the fan-out runs sequentially. Layer timeout, bulkhead, circuit breaker, and retry for resilience.

## Quick Recall

- Always pass an executor — never the common pool for I/O
- `thenCompose` = flatMap; `thenApply` = map
- `.collect()` before `allOf`, or it's sequential
- `orTimeout` doesn't cancel the work
- `join()` unchecked, `get()` checked; unwrap `getCause()`
