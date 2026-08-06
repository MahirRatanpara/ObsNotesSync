# Observability

## Why It Matters

In a distributed system you cannot debug by reading code — there's no stack trace across the network. Observability is how you answer questions you didn't anticipate.

## Monitoring vs Observability

| | Monitoring | Observability |
|---|---|---|
| Answers | **Known** questions — "is CPU high?" | **Unknown** questions — "why are these users slow?" |
| Built from | Predefined dashboards and alerts | High-cardinality data you can slice arbitrarily |

**Monitoring tells you *that* something is wrong; observability lets you find out *why*** without deploying new code.

## The Three Pillars

| Pillar | Answers | Cardinality | Cost |
|---|---|---|---|
| **Metrics** | "How many? How fast?" | **Must be low** | Cheap |
| **Logs** | "What exactly happened?" | High | Expensive |
| **Traces** | "Where did the time go?" | High | Moderate (sampled) |

**The usual workflow:** a metric alert fires → a trace shows which service is slow → logs for that trace ID show why.

**Each pillar should link to the next.** A trace ID in every log line, and an exemplar trace attached to a metric, is what makes that workflow actually work.

## Metrics

**The four golden signals** for every service:

1. **Latency** — always percentiles
2. **Traffic** — requests per second
3. **Errors** — rate and ratio
4. **Saturation** — how full the constrained resource is

**USE method** for resources: Utilisation, Saturation, Errors.
**RED method** for services: Rate, Errors, Duration.

### The Cardinality Trap

**Cardinality = the product of all label value combinations.**

```
http_requests{method, status, endpoint, instance}
  5 × 10 × 200 × 100 = 1,000,000 series          ← manageable
Add user_id → millions of series                 ← the monitoring system dies
```

**Never use unbounded values as metric labels** — user ID, request ID, email, session ID, full URL path with IDs in it.

**High-cardinality dimensions belong in logs or traces, not metrics.** This is the most common way monitoring systems are destroyed, and naming it unprompted is a strong signal.

### Percentiles Cannot Be Averaged

Averaging per-host p99s is mathematically meaningless. For a fleet-wide p99 you must merge **histograms** or **t-digest sketches**. See [Data Structures for Big Data](../04%20High%20Level%20Design/Advanced%20Topics/Data%20Structures%20for%20Big%20Data.md).

**Always look at p99, not the mean.** A mean of 50 ms with a p99 of 3 seconds means 1% of users have a broken experience — and the mean hides it completely.

## Logging

**Structured, not prose:**

```json
{"ts":"2026-08-06T10:00:00Z","level":"ERROR","service":"payment",
 "trace_id":"4bf92f...","user_id":"u_123","event":"charge_failed",
 "amount":4500,"error":"gateway_timeout","duration_ms":3021}
```

**Structured logs are queryable; prose logs are grep-able at best.** `WHERE event='charge_failed' AND duration_ms > 3000` is impossible against free text.

| Level | Use |
|---|---|
| ERROR | Something failed and needs attention |
| WARN | Unexpected but handled |
| INFO | Significant business events — sparingly |
| DEBUG | Off in production, enabled per-request or temporarily |

**Rules:**
- **Always include the trace ID** — this is what joins logs to traces
- **Never log secrets, tokens, card numbers, or PII**
- Log at boundaries (request in, response out, external call), not every line
- Sample high-volume debug logs

**Log volume is a real cost.** A service at 10,000 req/sec logging 5 lines per request produces 4 billion lines a day. Sample, or log only what you'd actually query.

## Distributed Tracing

A **trace** is one request's journey; a **span** is one operation within it.

```
Trace 4bf92f
├─ api-gateway          [============================] 850ms
│  ├─ auth-service      [==]                            40ms
│  ├─ order-service     [======================]       700ms
│  │  ├─ postgres query [=]                             30ms
│  │  └─ payment-service[===================]          650ms  ← the culprit
│  └─ notification      [=]                             25ms
```

**Context propagation** is the mechanism: the trace ID and span ID travel in headers (W3C `traceparent`) across every hop, including through message queues.

**If propagation breaks anywhere, the trace fragments** and you lose the causal chain. This is the most common tracing failure — usually an async boundary or a thread pool that doesn't carry context.

### Sampling

Tracing everything is prohibitively expensive.

| Strategy | Behaviour |
|---|---|
| **Head-based** | Decide at the start — simple, but you may miss the errors |
| **Tail-based** | Decide after completion — **keep all errors and slow requests**, sample the rest |

**Tail-based sampling is what you want** — the interesting traces are the failures and outliers, and head-based sampling drops them randomly. It costs more infrastructure because every span must be buffered until the decision.

## OpenTelemetry

The vendor-neutral standard for all three signals: one instrumentation API, one collector, pluggable backends.

**Instrument once with OTel, export anywhere** — this is the answer to "how do you avoid vendor lock-in in observability?"

Auto-instrumentation covers HTTP, database, and messaging calls with no code changes — a Java agent handles most of it.

## Alerting

**Alert on symptoms, not causes.**

```
✗ "CPU > 80%"                        — may be entirely fine
✓ "p99 latency > 1s for 5 minutes"   — users are affected
✓ "error rate > 1% for 5 minutes"
✓ "queue age > 10 minutes"
```

**Every alert must be actionable.** If the response is "acknowledge and ignore", delete the alert. Alert fatigue is what causes real incidents to be missed.

**SLO-based alerting** is the mature form: define an availability target (99.9%), compute the error budget, and alert on **burn rate** — how fast you're consuming the budget. A slow burn is a ticket; a fast burn pages someone.

## Correlation In Practice

```
Alert: p99 latency breach in checkout
  → Metrics: which endpoint, which region, when it started
  → Traces: sample slow traces → payment-service spans dominate
  → Logs: filter by those trace IDs → "gateway_timeout" to the card processor
  → Root cause in minutes rather than hours
```

**This workflow only works if trace IDs are in the logs and exemplars link metrics to traces.** Wiring that is the practical work of observability.

## Common Mistakes

- High-cardinality metric labels
- Unstructured log messages
- No trace ID in logs
- Alerting on causes rather than symptoms
- Alerts nobody acts on
- Averaging percentiles
- Head-based sampling that drops the errors
- Logging PII or secrets
- Broken context propagation across async boundaries

## Related Topics

- [Microservices Fundamentals](Microservices%20Fundamentals.md)
- [Service Mesh](Service%20Mesh.md)
- [Time Series and Analytics Databases](../04%20High%20Level%20Design/Advanced%20Topics/Time%20Series%20and%20Analytics%20Databases.md)
- [Performance Tuning and Profiling](../02%20Java/Performance/Performance%20Tuning%20and%20Profiling.md)

## Revision Summary

Metrics for low-cardinality aggregates, logs for detail, traces for causality — linked by a trace ID. Keep metric cardinality bounded, structure your logs, use tail-based sampling to retain errors, and alert on user-visible symptoms with an error budget rather than on resource thresholds.

## Quick Recall

- Metrics = known questions; observability = unknown ones
- Golden signals: latency, traffic, errors, saturation
- **Cardinality explosion kills metrics systems** — no unbounded labels
- **Percentiles cannot be averaged** — merge histograms
- Structured logs with a **trace ID in every line**
- W3C `traceparent` propagates context; async boundaries break it
- **Tail-based sampling keeps the errors**
- Alert on symptoms; every alert must be actionable
- OpenTelemetry to avoid lock-in
