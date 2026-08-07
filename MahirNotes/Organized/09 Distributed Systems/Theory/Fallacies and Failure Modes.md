# Fallacies and Failure Modes

## Why It Matters

Every distributed systems bug traces back to an assumption that holds on one machine and fails across a network. Naming the assumption is how you find the bug.

## The Eight Fallacies of Distributed Computing

Peter Deutsch's list — each is false, and each has a well-known production failure attached.

| # | Fallacy | Reality | Consequence |
|---|---|---|---|
| 1 | **The network is reliable** | Packets drop; partitions happen | Retries, idempotency, timeouts |
| 2 | **Latency is zero** | 150 ms cross-continent | Batch calls; avoid chatty APIs |
| 3 | **Bandwidth is infinite** | Payload size matters | Compression, pagination, field selection |
| 4 | **The network is secure** | Anything can be intercepted | TLS, mTLS, zero trust |
| 5 | **Topology doesn't change** | Instances come and go constantly | Service discovery, health checks |
| 6 | **There is one administrator** | Many teams, many changes | Versioned contracts, backward compatibility |
| 7 | **Transport cost is zero** | Serialisation and egress are billed | Efficient formats, zone-aware routing |
| 8 | **The network is homogeneous** | Different stacks, versions, MTUs | Standard protocols, tolerant parsing |

**Fallacies 1 and 2 cause most real incidents.** If you only remember two, remember that the network drops messages and that latency is never negligible.

## The Failure Modes That Actually Occur

| Mode | Description | Difficulty |
|---|---|---|
| **Crash-stop** | The node dies and stays dead | Easiest — you can detect it |
| **Crash-recovery** | Dies and comes back, possibly with stale state | Needs fencing and reconciliation |
| **Omission** | Messages silently lost | Retries, sequence numbers |
| **Timing** | Responses arrive too late to be useful | Timeouts, deadlines |
| **Byzantine** | Arbitrary or malicious behaviour | Only matters in adversarial settings |
| **Gray failure** | **Degraded but not dead** | **The hardest** |

### Gray Failure — The One To Name

A node that is slow, dropping some requests, or failing intermittently is **worse than a dead node**.

- A dead node fails health checks and is removed from rotation
- A degraded node passes health checks and keeps receiving traffic, failing a fraction of it

**A node at 5% error rate serving 20% of traffic is often more damaging than one that's fully down**, because nothing removes it automatically.

**Detection requires observing real traffic**, not synthetic probes: passive health checking, outlier detection (eject hosts whose error rate deviates from the fleet), and latency-based circuit breaking rather than error-only.

**This is why circuit breakers should trip on slow calls, not just errors.** See [Circuit Breaker](../../08%20Microservices/Circuit%20Breaker.md).

## The Partial Failure Problem

On one machine, a function call either returns or the process dies. Across a network there is a **third outcome**: you don't know.

```
Client → Server: charge card
Client ← [TIMEOUT]

Indistinguishable:
  (a) request never arrived        — nothing happened
  (b) succeeded, response lost     — money moved
  (c) arrived and failed           — nothing happened
```

**This is the [Two Generals Problem](Two%20Generals%20Problem.md), and it is provably unsolvable.** The response is not to seek certainty but to make the ambiguity harmless — idempotency keys make retrying safe regardless of which case occurred.

**A timeout means "unknown", never "failed".** Treating it as failure and retrying a non-idempotent operation is the single most common distributed systems bug.

## Cascading Failure

One component's failure overwhelms the next, propagating outward.

```
Service C slows down
  → B's threads block waiting on C
  → B's pool exhausts, B stops responding to everything
  → A's threads block waiting on B
  → total outage from one degraded dependency
```

**Amplifiers:**

| Amplifier | Effect |
|---|---|
| **Retries** | 3 layers × 3 attempts = 27× load, precisely when the system is struggling |
| Unbounded queues | Memory exhaustion instead of backpressure |
| **Missing timeouts** | Threads block indefinitely |
| Synchronised behaviour | Every client retries at the same instant |

**Defences, in order of importance:**

1. **Timeouts on everything** — the most damaging omission
2. **Bulkheads** — a separate pool per dependency, so one can't exhaust all threads
3. **Circuit breakers** — stop calling a failing dependency
4. **Bounded queues** — backpressure rather than OOM
5. **Jittered retries with a budget**
6. **Load shedding** — reject explicitly rather than degrade everything

## The Thundering Herd

Many clients act simultaneously after a triggering event.

| Trigger | Manifestation |
|---|---|
| Cache expiry | Thousands of simultaneous database reads |
| Service restart | All clients reconnect at once |
| Cron at `:00` | Every job starts on the same second |
| Recovery | Everyone retries the moment the service returns |

**The fix is always the same: add randomness.** TTL jitter, jittered reconnect backoff, spread cron schedules, and request coalescing so one loader serves many waiters.

## Metastable Failure

**A system that stays broken after the trigger is removed.**

```
Load spike → queues fill → latency rises → clients time out and retry
→ retries add load → queues stay full → EVEN AFTER THE SPIKE ENDS
```

The retry load generated by the overload is now sufficient to sustain the overload. Removing the original cause doesn't help.

**Recovery requires breaking the loop:** shed load, drain queues, or restart. This is why "we removed the traffic spike but it's still down" happens.

**Prevention:** bounded queues, retry budgets, and load shedding before saturation. **Naming metastable failure is a strong senior signal** — it explains a class of incident most engineers have seen but can't name.

## Clock Assumptions

| Assumption | Reality |
|---|---|
| Clocks are synchronised | NTP drift of milliseconds to seconds |
| Clocks move forward | NTP corrections and leap seconds move them backward |
| Timestamps order events | **They do not** across machines |

**Never order distributed events by wall-clock timestamps.** See [Clocks and Ordering](../Time%20and%20Ordering/Clocks%20and%20Ordering.md).

## Designing For Failure

| Principle | Practice |
|---|---|
| **Assume every call fails** | Timeout, retry, fallback |
| **Make operations idempotent** | Retries become safe |
| **Bound everything** | Queues, pools, retries, payload sizes |
| **Degrade, don't fail** | Serve stale data rather than an error |
| **Isolate** | Bulkheads, cells, blast-radius limits |
| **Test failure deliberately** | Chaos engineering, fault injection |

**Graceful degradation is the design goal:** a recommendation service outage should hide the recommendations panel, not fail the page.

## Common Mistakes

- Treating a timeout as a definite failure
- No timeout at all
- Retrying without jitter or a budget
- Health checks that miss gray failures
- Unbounded queues
- Ordering by wall-clock timestamps
- Assuming removing the trigger ends the incident
- Testing only the happy path

## Related Topics

- [Two Generals Problem](Two%20Generals%20Problem.md)
- [Failure Detection and Recovery](../Failure%20Handling/Failure%20Detection%20and%20Recovery.md)
- [Circuit Breaker](../../08%20Microservices/Circuit%20Breaker.md)
- [Clocks and Ordering](../Time%20and%20Ordering/Clocks%20and%20Ordering.md)

## Revision Summary

The fallacies name the assumptions that break across a network. Partial failure means a timeout is ambiguous, not a failure. Gray failures are harder than crashes because nothing removes the degraded node. Cascading and metastable failures are sustained by retries — bound everything and add jitter.

## Quick Recall

- Fallacies: network unreliable, latency non-zero — these two cause most incidents
- **Timeout = unknown, never failed**
- **Gray failure is worse than a crash** — trip breakers on slow calls too
- Cascades: retries amplify 27× across three layers
- Thundering herd → **add jitter everywhere**
- **Metastable failure persists after the trigger is gone** — break the loop
- Never order by wall clock
- Degrade, don't fail
