# Rate Limiting

## Why It Matters

Protects against abuse, cost overruns, and cascading failure. A standalone design question and a component of dozens of others.

## The Five Algorithms

| Algorithm | Memory | Burst handling | Accuracy |
|---|---|---|---|
| **Fixed window** | O(1) | **Allows 2× at boundaries** | Poor |
| **Sliding window log** | O(requests) | Exact | Perfect |
| **Sliding window counter** | O(1) | Good approximation | Good |
| **Token bucket** | O(1) | **Allows controlled bursts** | Good |
| **Leaky bucket** | O(queue) | Smooths to a constant rate | Good |

### Fixed Window — and its flaw
Count per fixed interval. Simple, but a client can send the full quota at 0:59 and again at 1:00 — **2× the limit in two seconds**. Know this failure; it's the standard follow-up.

### Sliding Window Log
Store a timestamp per request in a sorted set; drop entries outside the window; count what remains. Exact, but memory grows with request volume.

### Sliding Window Counter
Weight the previous window by how much of it remains in view:
```
count = current + previous × (overlap fraction)
```
O(1) memory, close to exact. **The usual production choice.**

### Token Bucket — the most common
A bucket holds up to `capacity` tokens, refilled at `rate` per second. Each request consumes one; empty bucket means reject.

- Allows bursts up to `capacity` — usually desirable, since real traffic is bursty
- O(1) state: token count and last refill time
- Refill is computed lazily on access, not by a timer

### Leaky Bucket
Requests enter a queue drained at a constant rate. Output is perfectly smooth. Use when the downstream needs a **fixed** rate, not just a bounded average.

## Distributed Rate Limiting

The hard part: many gateway nodes must enforce one global limit.

| Approach | Accuracy | Latency | Notes |
|---|---|---|---|
| **Local only** | Poor (N× the limit) | **None** | Divide the limit by N — breaks with uneven load |
| **Centralised (Redis)** | High | +1 network hop | Standard approach |
| **Local + async sync** | Good | Minimal | Best at very high scale |

**The Redis implementation must be atomic.** `GET` then `INCR` is a race across nodes. Use a Lua script:

```lua
local count = redis.call('INCR', KEYS[1])
if count == 1 then redis.call('EXPIRE', KEYS[1], ARGV[2]) end
if count > tonumber(ARGV[1]) then return 0 end
return 1
```

The `count == 1` guard sets the TTL only on creation — without it, the window never expires or resets constantly.

**Local + async sync** at very high scale: each node keeps a local bucket for a fraction of the limit, enforces locally with zero latency, and reconciles with a global counter every few hundred milliseconds. Slight over-admission is traded for removing Redis from the request path.

## Design Decisions

| Decision | Options |
|---|---|
| **Where** | Client, API gateway (usual), service, or sidecar |
| **Key by** | User id, API key, IP, or a combination |
| **Scope** | Global, per-endpoint, per-tier |
| **On exceed** | Reject (429), queue, or throttle |

**Keying by IP alone is weak** — NAT means many users share one IP, and attackers rotate addresses. Key by authenticated identity where possible, with IP as a fallback for anonymous traffic.

## The Response

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1699999999
Retry-After: 30
```

**`Retry-After` matters.** Without it, well-behaved clients retry immediately and make things worse.

## Failure Mode

If Redis is down, do you **fail open** (allow all) or **fail closed** (reject all)?

- **Fail open** for user-facing traffic — a rate limiter outage shouldn't be a site outage
- **Fail closed** for expensive or dangerous operations (payments, LLM calls)

Interviewers like this question because there's no universally right answer — just be explicit about the trade-off.

## Common Mistakes

- Fixed window without acknowledging the 2× boundary burst
- Non-atomic check-then-increment in a distributed setting
- Forgetting the TTL, so counters live forever
- Rate limiting by IP only
- No `Retry-After` header
- Not deciding the fail-open/fail-closed behaviour
- Putting the limiter behind the expensive work instead of in front

## Related Topics

- [Redis](Redis.md)
- [Circuit Breaker](Circuit%20Breaker.md)
- [API Gateway](API%20Gateway.md)

## Revision Summary

Token bucket for burst-tolerant limiting; sliding window counter for accuracy at O(1). Distributed enforcement needs atomic Redis operations via Lua, or local buckets with async global reconciliation. Always return `Retry-After` and decide fail-open vs fail-closed.

## Quick Recall

- Fixed window → 2× burst at the boundary
- Token bucket = burst-tolerant, O(1), lazy refill
- Sliding window counter = weighted previous window
- Distributed → Lua for atomicity, or local + async sync
- 429 + `Retry-After`
- Fail open for reads, closed for expensive writes
