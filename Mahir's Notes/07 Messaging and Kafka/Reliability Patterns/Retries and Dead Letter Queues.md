# Retries and Dead Letter Queues

## Why It Matters

Retry logic is where well-intentioned code amplifies an outage. Getting backoff, classification, and the DLQ right is the difference between a blip and a cascading failure.

## Classify The Failure First

**The single most important decision: is this failure transient or permanent?**

| Type | Examples | Action |
|---|---|---|
| **Transient** | Timeout, 503, connection reset, throttling, deadlock | **Retry with backoff** |
| **Permanent** | Malformed payload, validation failure, 400, 404, business rule violation | **Straight to DLQ — do not retry** |
| **Ambiguous** | 500, unknown error | Retry a bounded number of times, then DLQ |

**Retrying a permanent failure is pure waste** — it will fail identically every time, consuming capacity and delaying valid messages behind it. Classify before retrying.

## Exponential Backoff With Jitter

```java
delay = min(baseDelay * 2^attempt, maxDelay)
delay = random(0, delay)          // FULL JITTER
```

**Without jitter, retries synchronise.** A downstream service recovers, and every client that failed at the same moment retries at the same moment — producing a thundering herd that knocks it down again.

| Strategy | Behaviour |
|---|---|
| Fixed delay | Synchronised retries — bad |
| Exponential, no jitter | Still synchronised — bad |
| **Full jitter** — `random(0, backoff)` | **Best spread; AWS's recommendation** |
| Equal jitter — `backoff/2 + random(0, backoff/2)` | Slightly more predictable |

**AWS's analysis found full jitter performs best** for both completion time and server load. Naming it is a good signal.

**Cap the total attempts** (typically 3–5) and the maximum delay. Unbounded retry is not resilience; it's a slow-motion outage.

## Retry Amplification — The Cascade

```
Service A retries 3× → Service B retries 3× → Service C
= 9× load on C, exactly when C is already struggling
```

**Retries multiply through a call chain.** Three services each retrying three times produces 27× traffic at the bottom.

**Mitigations:**

| Technique | Detail |
|---|---|
| **Retry at one layer only** | Usually the outermost, closest to the user |
| **Retry budget** | Allow retries only up to ~10% of total requests |
| **Circuit breaker** | Stop retrying a service that's clearly down |
| Propagate a "do not retry" signal | Downstream tells upstream not to bother |

**A retry budget is the most robust answer** — it caps retry traffic as a fraction of normal traffic, so an outage can never amplify load. gRPC and Envoy both implement this.

## Only Retry Idempotent Operations

A retried non-idempotent write can double-charge, double-ship, or double-post.

**Either make the operation idempotent** (idempotency key, conditional update) **or do not retry it.** There is no third option.

A **timeout tells you nothing** about whether the operation succeeded — see [Two Generals Problem](Two%20Generals%20Problem.md). This is exactly why idempotency and retry are inseparable topics.

## Where Retries Live

| Location | Trade-off |
|---|---|
| **In-consumer (loop)** | Simple; **blocks the partition/queue** while retrying |
| **Requeue to the same queue** | Non-blocking; loses ordering; can loop forever without a counter |
| **Dedicated retry topics/queues** | **Non-blocking, delay-tiered, ordered per tier** |
| Broker-native (SQS visibility timeout) | Simplest where available |

### The Kafka Problem

**Kafka has no built-in retry queue**, and offsets advance sequentially. An in-consumer retry loop **blocks the entire partition** — every message behind the failing one waits.

**The standard pattern is retry topics with increasing delays:**

```
main-topic → (fail) → retry-5s → (fail) → retry-1m → (fail) → retry-10m → DLQ
```

Each retry topic has a consumer that waits for the message's age to exceed the tier delay before processing. Non-blocking, bounded, and observable.

**Trade-off: ordering is lost** for retried messages, since they rejoin later. For strictly ordered streams you may have no choice but to block the partition — and then you need very tight timeouts.

## Poison Messages

One message that always fails will block its partition forever if you retry indefinitely.

**Bound retries and move on.** A poison message must reach the DLQ so the stream can continue. Blocking a partition on one bad message is how a single malformed record halts an entire pipeline.

## Dead Letter Queues

The terminal destination for messages that cannot be processed.

**What every DLQ needs:**

| Requirement | Why |
|---|---|
| **Failure context** | Original message + error + stack trace + attempt count + timestamp |
| **Alerting on depth** | **A silent DLQ is invisible data loss** |
| **Replay tooling** | You must be able to fix and reprocess |
| Retention | Long enough to investigate — days, not hours |
| Separate per source queue | Mixed DLQs are unanalysable |

**The most common DLQ failure is that nobody looks at it.** Messages accumulate for months and are eventually deleted. **Alert on DLQ depth greater than zero** — it should be an actionable event, not a dashboard number.

**Replay must be idempotent**, because you may replay the same message more than once while debugging.

## SQS Specifics

```json
"RedrivePolicy": {
  "deadLetterTargetArn": "arn:aws:sqs:...:orders-dlq",
  "maxReceiveCount": 5
}
```

Built in: after 5 receives without deletion, the message moves to the DLQ automatically. **Redrive** moves messages back from the DLQ once fixed.

**Set `maxReceiveCount` above your expected transient-failure count** but low enough to fail fast on poison messages — 3 to 5 is typical.

## Monitoring

| Metric | Meaning |
|---|---|
| **DLQ depth** | Must be zero; alert on any increase |
| **Retry rate** | Rising rate = systemic problem, not isolated failures |
| Consumer lag | Retries are consuming capacity |
| Age of the oldest message | Better signal than depth alone |
| Failure reason distribution | Tells you whether it's one bug or many |

**Alert on retry rate, not just DLQ depth.** A high retry rate that eventually succeeds is invisible in the DLQ but is degrading throughput and signalling an underlying problem.

## Common Mistakes

- Retrying permanent failures
- No jitter → synchronised thundering herd
- Retrying at every layer → 27× amplification
- Retrying non-idempotent operations
- Unbounded retries → poison message blocks the partition
- In-consumer retry loops on Kafka, blocking the partition
- DLQ with no alerting
- DLQ with no replay tooling
- Losing the failure reason, making the DLQ unanalysable

## Related Topics

- [Idempotent Consumers](Idempotent%20Consumers.md)
- [Messaging Fundamentals](Messaging%20Fundamentals.md)
- [Circuit Breaker](Circuit%20Breaker.md)
- [Kafka Deep Dive](Kafka%20Deep%20Dive.md)

## Revision Summary

Classify transient versus permanent before retrying. Use exponential backoff with full jitter, cap attempts, and retry at one layer with a retry budget to prevent amplification. Only retry idempotent operations. On Kafka, use delay-tiered retry topics rather than blocking the partition, and always alert on DLQ depth.

## Quick Recall

- **Classify first** — never retry permanent failures
- **Full jitter**: `random(0, min(base × 2ⁿ, max))`
- Retries multiply: 3 layers × 3 attempts = 27×
- **Retry budget** (~10% of traffic) caps amplification
- Only retry idempotent operations
- Kafka: **retry topics**, not in-consumer loops
- Poison message must reach the DLQ or it blocks the partition
- **Alert on DLQ depth > 0**; keep the failure reason
