# Resilient Parallel Fan-Out — Timeouts, Circuit Breakers, CompletableFuture

_RRK prep notes — Run Adjustment Summary API example_

---

## 1. The layering model (inside → out)

Each layer protects against a different failure. Know what each one does and does NOT do.

|Layer|Protects against|Does NOT help with|
|---|---|---|
|**Bulkhead** (dedicated executor per source)|One slow source starving threads needed by other sources|Slowness of the source itself|
|**Timeout** (per call)|A single call hanging unboundedly|Repeated calls to a degraded source (each still burns the full timeout)|
|**Fallback** (per future)|An exception poisoning the combined response|The underlying outage|
|**Circuit breaker** (per source)|Repeatedly paying the timeout cost; hammering a struggling dependency|The FIRST slow/failed call — breaker is statistical, it must observe failures before opening|

**Key sentence:** _"Timeout bounds the first slow call; the breaker protects against the hundredth. Without timeouts, the breaker may never trip — slow calls aren't failures unless something declares them slow."_

---

## 2. Circuit breaker state machine

```
            failure/slow rate >= threshold
            (over sliding window)
  CLOSED ─────────────────────────────► OPEN
    ▲                                     │
    │  probes succeed                     │ waitDurationInOpenState elapses
    │                                     ▼
    └────────────────────────────── HALF_OPEN
                probes fail ──────────► back to OPEN
```

- **CLOSED**: calls pass through; outcomes recorded in a sliding window.
- **OPEN**: calls fail immediately (`CallNotPermittedException`) — microseconds, no I/O. This is the point: fast-fail + load shedding so the dependency can recover.
- **HALF_OPEN**: limited probe calls test recovery; pass → CLOSED, fail → OPEN.

### Config knobs (Resilience4j) — defensible example values

|Knob|Example|Trade-off|
|---|---|---|
|`slidingWindowSize`|50 calls|Small = reacts fast but flaps on blips; large = stable but slow to react|
|`failureRateThreshold`|50%|Lower = sensitive (flapping risk); higher = burns latency on a dying source|
|`slowCallDurationThreshold`|800ms (≈ your timeout)|Defines "slow" — without it, hangs don't count as failures|
|`slowCallRateThreshold`|50%|Opens on slowness even when calls eventually "succeed"|
|`waitDurationInOpenState`|30s|Too short = hammering a recovering DB; too long = serving partials needlessly|
|`permittedNumberOfCallsInHalfOpenState`|5|Enough probes for signal, few enough to not re-overload|

If asked "why these numbers": _"The exact values were tuned to the source's normal latency profile; what matters is knowing each knob's failure mode — too sensitive flaps, too lax defeats the purpose."_

---

## 3. Code — plain CompletableFuture (bulkhead + timeout + fallback)

```java
// BULKHEAD: dedicated, bounded, I/O-sized pools — never the commonPool.
// supplyAsync() without an executor uses ForkJoinPool.commonPool(): a small,
// CPU-sized, JVM-wide shared pool. Parking it on blocking I/O starves
// everything else that uses it (parallel streams included).
ExecutorService sqlPool    = Executors.newFixedThreadPool(20);
ExecutorService filesPool  = Executors.newFixedThreadPool(10);
ExecutorService statusPool = Executors.newFixedThreadPool(10);

public SummaryResponse getRunAdjustmentSummary(String runId) {

    CompletableFuture<Section> sql = CompletableFuture
        .supplyAsync(() -> fetchSqlStats(runId), sqlPool)
        .orTimeout(800, TimeUnit.MILLISECONDS)                 // TIMEOUT
        .exceptionally(ex -> Section.unavailable("sqlStats")); // FALLBACK

    CompletableFuture<Section> files = CompletableFuture
        .supplyAsync(() -> buildSignedFileUrls(runId), filesPool)
        .orTimeout(500, TimeUnit.MILLISECONDS)
        .exceptionally(ex -> Section.unavailable("adjustmentFiles"));

    CompletableFuture<Section> status = CompletableFuture
        .supplyAsync(() -> fetchStageStatuses(runId), statusPool)
        .orTimeout(500, TimeUnit.MILLISECONDS)
        .exceptionally(ex -> Section.unavailable("statuses"));

    // Because every future has a fallback attached BEFORE allOf,
    // allOf never sees an exception — the response always assembles.
    return CompletableFuture.allOf(sql, files, status)
        .thenApply(v -> assemble(sql.join(), files.join(), status.join()))
        .join();   // join() inside thenApply is safe: all inputs are done
}
```

### Subtleties to know cold

1. **`allOf` does not fail fast and does not cancel siblings.** It completes when ALL inputs complete; if any completed exceptionally (and you didn't attach fallbacks), the allOf future completes exceptionally too. Pattern: fallback-per-future BEFORE allOf.
2. **`orTimeout` completes the future, but does NOT stop the work.** The thread in the pool keeps running `fetchSqlStats` to completion. So you also need timeouts at the client layer — JDBC socket/query timeout, HTTP client read timeout. _"Timeouts at every layer"_ — otherwise timed-out work silently eats your pool.
3. `completeOnTimeout(defaultValue, 800, MS)` = timeout that yields a default instead of an exception (alternative to orTimeout + exceptionally).
4. `exceptionally` vs `handle`: `exceptionally` runs only on failure; `handle((result, ex) -> ...)` runs always — use it when you need both paths.
5. **MDC / trace context does not cross thread hops.** Correlation IDs vanish unless you propagate them (task decorator / context-aware executor). Good "what broke during the refactor" war story.

---

## 4. Code — adding the circuit breaker (Resilience4j)

```java
CircuitBreakerConfig cbConfig = CircuitBreakerConfig.custom()
    .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
    .slidingWindowSize(50)
    .failureRateThreshold(50)                               // % failures to open
    .slowCallDurationThreshold(Duration.ofMillis(800))      // what "slow" means
    .slowCallRateThreshold(50)                              // % slow calls to open
    .waitDurationInOpenState(Duration.ofSeconds(30))
    .permittedNumberOfCallsInHalfOpenState(5)
    .recordExceptions(SQLException.class, TimeoutException.class)
    .build();

// One breaker PER DOWNSTREAM SOURCE, shared across requests (registry-managed).
// A breaker per request would never accumulate statistics — common design error.
CircuitBreaker sqlBreaker = circuitBreakerRegistry.circuitBreaker("cloudSql", cbConfig);

CompletableFuture<Section> sql = CompletableFuture
    .supplyAsync(
        CircuitBreaker.decorateSupplier(sqlBreaker, () -> fetchSqlStats(runId)),
        sqlPool)
    .orTimeout(800, TimeUnit.MILLISECONDS)
    .exceptionally(ex -> Section.unavailable("sqlStats"));
```

Flow when Cloud SQL degrades:

1. First slow calls: bounded by **timeout** at 800ms → fallback → partial response.
2. Sliding window fills with timeouts/slow calls → breaker **opens**.
3. Subsequent calls fail in **microseconds** (`CallNotPermittedException`) → fallback immediately. Latency recovers fully; Cloud SQL gets breathing room.
4. After 30s → **half-open** → 5 probes → recovery closes it.

**Important correction of a common misstatement:** an open breaker on Cloud SQL affects ONLY the Cloud SQL future. The other futures are independent — they complete on their own with their own data. Nothing "makes all the other futures complete."

Bonus: Resilience4j publishes breaker state + call metrics to Micrometer → Prometheus → Grafana. Alert on `state == OPEN`. Ties the resilience story to your observability story.

---

## 5. The spoken answer (assembled)

> "The independent fetches run as CompletableFutures on dedicated bounded executors — bulkheads, so a slow source can't starve the others. Each future has a per-call timeout and an `exceptionally` fallback that converts failure into a typed 'section unavailable' result — attached before `allOf`, since `allOf` doesn't fail fast and one raw exception would poison the combine. Around each source there's a Resilience4j circuit breaker: timeouts bound the first slow calls, and once the failure/slow rate crosses the window threshold the breaker opens and subsequent calls fail in microseconds instead of burning the timeout — which also sheds load off the struggling source. The API returns a partial response with degraded sections flagged; we agreed that contract with users upfront — they preferred fast-partial over slow-complete."

---

## 6. Likely follow-ups — one-line answers

- **"Which pool do the futures run on?"** Dedicated bounded executors per source; never commonPool for blocking I/O.
- **"Why both timeout AND breaker?"** Timeout bounds one call; breaker stops paying that cost repeatedly and sheds load. Breaker without timeout may never trip on hangs.
- **"What happens to the thread when orTimeout fires?"** Keeps running the work — hence client-level timeouts too (JDBC/HTTP).
- **"Breaker per request or per source?"** Per source, registry-managed singleton — it needs cross-request statistics.
- **"How do you know the breaker opened in prod?"** Resilience4j metrics → Prometheus; Grafana alert on state transitions.
- **"What broke during the refactor?"** MDC/trace-ID loss across thread hops; fixed with a context-propagating task decorator. (Have one true war story ready.)