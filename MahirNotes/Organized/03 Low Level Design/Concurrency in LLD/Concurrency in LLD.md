# Concurrency in LLD

## Why It Matters

Almost every LLD problem has a concurrency follow-up: two users booking the same seat, two threads dispensing the last item. Handling it well separates SDE-2 from SDE-1.

## The Three Questions

Ask these in order for any shared state:

1. **What is the shared mutable state?** (the seat map, the inventory count, the lock table)
2. **What invariant must hold?** ("a seat is assigned to at most one booking")
3. **What is the smallest unit I can lock?** (a seat, not the whole theatre)

**Locking granularity is what interviewers actually probe.** Locking the entire system is correct but doesn't scale; per-entity locking is the expected answer.

## Correctness Problems

| Problem | Cause | Fix |
|---|---|---|
| **Race condition** | Interleaved read-modify-write | Atomic operation or lock |
| **Lost update** | Two writers, one overwrites | Optimistic versioning or lock |
| **Dirty read** | Reading uncommitted state | Transaction isolation |
| **Deadlock** | Circular lock wait | Consistent lock ordering |
| **Livelock** | Threads endlessly react to each other | Randomised backoff |
| **Starvation** | A thread never gets the lock | Fair locks |

## Optimistic vs Pessimistic

| | Pessimistic | Optimistic |
|---|---|---|
| Assumes | Conflict likely | Conflict rare |
| Mechanism | Lock before reading | Version check on write |
| Cost | Blocks others | Retry on conflict |
| Best for | High contention, short critical sections | **Low contention — most cases** |

```java
// Optimistic — the DB equivalent of CAS
UPDATE seats SET status='BOOKED', version=version+1
WHERE id=? AND version=? AND status='AVAILABLE';
// 0 rows → someone beat you → return "seat taken"
```

The `status='AVAILABLE'` predicate makes the check and the update atomic. **Never read, check in application code, then write** — that's the race.

## The Seat-Booking Problem (asked constantly)

Requirements: a seat must not be double-booked; a user needs time to pay; abandoned holds must be released.

**Two-phase approach:**

1. **Hold** — atomically transition `AVAILABLE → HELD` with an expiry timestamp and the holder's id
2. **Confirm** — on payment success, `HELD → BOOKED`, checking the holder still matches
3. **Expire** — a background sweeper (or a lazy check on read) returns expired holds to `AVAILABLE`

```java
enum SeatStatus { AVAILABLE, HELD, BOOKED }
```

**Lazy expiry beats a sweeper thread** in an interview: when reading a seat, treat `HELD` with a past expiry as `AVAILABLE`. No background thread, no clock-skew coordination — and it degrades gracefully.

**Lock per seat, not per show.** A `ConcurrentHashMap<SeatId, Seat>` with `compute` gives per-key atomicity without a global lock.

## Choosing the Mechanism

| Situation | Tool |
|---|---|
| Single counter | `AtomicInteger` |
| Map of independent entities | `ConcurrentHashMap` + `compute` / `merge` |
| Limit concurrent users of a resource | `Semaphore` |
| Invariant spanning several fields | `ReentrantLock` |
| Read-heavy shared config | `ReadWriteLock` |
| Producer-consumer | `BlockingQueue` (bounded) |
| Wait for N tasks | `CountDownLatch` |
| Cross-process | Database row lock, or Redis lock **with a fencing token** |

**`ConcurrentHashMap.compute` is the highest-value tool in LLD** — it gives you per-key atomic read-modify-write with no explicit locking:

```java
seats.compute(seatId, (id, seat) -> {
    if (seat.status != AVAILABLE) throw new SeatUnavailableException();
    return seat.hold(userId, now.plusMinutes(10));
});
```

## Immutability

The strongest concurrency tool is not needing synchronisation at all. Immutable objects are inherently thread-safe.

```java
public final class Money {
    private final BigDecimal amount;
    private final Currency currency;
    public Money add(Money o) { return new Money(amount.add(o.amount), currency); }
}
```

Make value objects immutable; confine mutability to a small number of clearly-owned classes. Say this — interviewers reward it.

## Deadlock Prevention in LLD

The bank-transfer classic:

```java
// DEADLOCK: transfer(A,B) and transfer(B,A) concurrently
void transfer(Account from, Account to, BigDecimal amt) {
    synchronized (from) { synchronized (to) { ... } }
}

// FIXED: consistent global ordering
Account first  = from.getId() < to.getId() ? from : to;
Account second = from.getId() < to.getId() ? to : from;
synchronized (first) { synchronized (second) { ... } }
```

**Order locks by a stable global key.** This is the standard answer and it comes up often.

## Common Mistakes

- Locking the entire system instead of the contended entity
- Read-check-write instead of a conditional/atomic update
- Pessimistic locking when contention is actually low
- Holding a lock while doing I/O or calling unknown code
- Ignoring hold expiry, leaking held resources forever
- Distributed locks without fencing tokens
- Not mentioning concurrency until asked

## Related Topics

- [Synchronisation and Locks](../../02%20Java/Concurrency/Synchronisation%20and%20Locks.md)
- [Concurrent Collections](../../02%20Java/Concurrency/Concurrent%20Collections.md)
- [LLD Delivery Framework](../In%20A%20Hurry/LLD%20Delivery%20Framework.md)

## Revision Summary

Name the shared state, the invariant, and the smallest lockable unit. Prefer optimistic concurrency and atomic conditional updates. `ConcurrentHashMap.compute` gives per-key atomicity. Order locks consistently to avoid deadlock. Immutability removes the problem entirely.

## Quick Recall

- Lock per entity, never globally
- Conditional update, never read-then-write
- Optimistic by default; pessimistic under real contention
- Hold → Confirm → Expire, with lazy expiry
- `ConcurrentHashMap.compute` for per-key atomicity
- Consistent lock ordering prevents deadlock
- Immutable value objects need no locks
