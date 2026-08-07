# Atomics and CAS

## Why It Matters

Lock-free programming underpins `ConcurrentHashMap`, `AtomicInteger`, and modern queue implementations. Interviewers ask about CAS to test whether you understand concurrency below the `synchronized` keyword.

## Core Idea

**Compare-And-Swap** is a single atomic CPU instruction (`LOCK CMPXCHG` on x86):

```
CAS(address, expectedValue, newValue):
    if (*address == expectedValue) { *address = newValue; return true; }
    else return false;
```

Software retries in a loop until it succeeds:

```java
int prev, next;
do {
    prev = value.get();
    next = prev + 1;
} while (!value.compareAndSet(prev, next));
```

`AtomicInteger.incrementAndGet()` is exactly this loop.

## Optimistic vs Pessimistic

| | Locking (pessimistic) | CAS (optimistic) |
|---|---|---|
| Assumes | Conflict is likely | Conflict is rare |
| On conflict | Block and context-switch | Retry the loop |
| Cost when uncontended | Low (thin lock) | **Very low** |
| Cost when highly contended | Moderate | **High** — wasted retries |
| Deadlock possible | Yes | **No** |
| Starvation possible | Yes (unfair locks) | Yes (unlucky thread) |

**CAS is not universally faster.** Under heavy contention the retry loop burns CPU. This is the trade-off to state.

## LongAdder vs AtomicLong

Under high contention, `AtomicLong` suffers because every thread CASes the same cache line.

`LongAdder` maintains **per-thread cells** and sums them on read:

| | AtomicLong | LongAdder |
|---|---|---|
| Write throughput (contended) | Low | **Much higher** |
| Read cost | O(1) exact | O(cells), approximate during concurrent writes |
| Memory | 1 field | Array of padded cells |

**Rule: metrics and counters → `LongAdder`. Values you read as often as you write → `AtomicLong`.**

## The ABA Problem

CAS checks the *value*, not whether it changed and changed back.

```
Thread 1: reads A, is preempted
Thread 2: A → B → A
Thread 1: CAS(A, C) SUCCEEDS — but the world moved underneath it
```

Harmless for counters (a number is a number). **Dangerous for pointers** — in a lock-free stack, a node may have been popped, freed, and reallocated.

**Fix:** attach a version stamp.

```java
AtomicStampedReference<Node> top = new AtomicStampedReference<>(node, 0);
int[] stampHolder = new int[1];
Node cur = top.get(stampHolder);
top.compareAndSet(cur, next, stampHolder[0], stampHolder[0] + 1);
```

`AtomicMarkableReference` is the single-bit variant.

**ABA is a very common senior interview question** — know the scenario and the fix.

## The Atomic Family

| Class | Use |
|---|---|
| `AtomicInteger` / `AtomicLong` | Counters, sequence numbers |
| `AtomicBoolean` | One-shot flags (`compareAndSet(false, true)`) |
| `AtomicReference<V>` | Lock-free object swap |
| `AtomicStampedReference` | ABA-safe references |
| `AtomicIntegerArray` | Element-wise atomic array |
| `LongAdder` / `DoubleAdder` | High-contention accumulation |
| `AtomicIntegerFieldUpdater` | Atomic ops on an existing volatile field, no wrapper object |

## VarHandle (Java 9+)

The modern, supported replacement for `sun.misc.Unsafe`:

```java
private static final VarHandle VALUE;
static {
    VALUE = MethodHandles.lookup().findVarHandle(Counter.class, "value", int.class);
}
VALUE.compareAndSet(this, expected, newValue);
VALUE.getAndAdd(this, 1);
VALUE.setRelease(this, x);      // explicit memory ordering
```

Offers fine-grained memory-ordering modes — plain, opaque, acquire/release, volatile — letting you pay only for the barrier you need. `Unsafe` is internal, unsupported, and increasingly blocked; **VarHandle is the answer** if asked about low-level atomics.

## Common Questions

- *Is CAS always better than locking?* — no; under high contention retries waste CPU.
- *What is ABA and when does it matter?* — value returns to its original; matters for pointer-based lock-free structures.
- *Why is LongAdder faster?* — it spreads writes across cache lines, eliminating false sharing on one hot field.
- *Is `AtomicInteger` lock-free?* — yes on any modern CPU with a native CAS.

## Common Mistakes

- Using `AtomicLong` for a hot metric where `LongAdder` belongs
- Ignoring ABA in lock-free data structures
- Assuming `volatile` provides atomicity (it doesn't)
- Reaching for `Unsafe` instead of `VarHandle`
- Writing a CAS loop with a side effect inside it — the loop body may run many times

## Related Topics

- [Java Memory Model](Java%20Memory%20Model.md)
- [Synchronisation and Locks](Synchronisation%20and%20Locks.md)
- [Concurrent Collections](Concurrent%20Collections.md)

## Revision Summary

CAS is an atomic compare-and-set retried in a loop — optimistic, deadlock-free, but wasteful under contention. LongAdder scales writes. ABA needs a version stamp. VarHandle replaces Unsafe.

## Quick Recall

- `do { read; compute } while (!compareAndSet(prev, next));`
- High-contention counter → `LongAdder`
- ABA → `AtomicStampedReference`
- CAS never deadlocks but can starve
- CAS loop bodies must be side-effect free
