# Java Memory Model (JMM)

## Why It Matters

Every concurrency bug that isn't a race condition is a **visibility** bug. The JMM defines when one thread's writes become visible to another. Senior interviews probe this directly.

## Core Idea

Without synchronisation, the JVM and CPU may reorder instructions and cache values in registers or core-local caches. A write by thread A is **not guaranteed** to ever be seen by thread B.

The JMM defines a **happens-before** relation. If action X happens-before Y, then X's effects are visible to Y.

## Happens-Before Rules

| Rule | Guarantee |
|---|---|
| Program order | Within a single thread, statements appear in order |
| Monitor lock | `unlock` happens-before a subsequent `lock` on the same monitor |
| Volatile | A write to a volatile happens-before every subsequent read of it |
| Thread start | `Thread.start()` happens-before anything in that thread |
| Thread join | Everything in a thread happens-before `join()` returns |
| Final fields | Correctly constructed final fields are visible without synchronisation |
| Transitivity | X hb Y and Y hb Z ⟹ X hb Z |

## The Three Guarantees

| Mechanism | Atomicity | Visibility | Ordering |
|---|---|---|---|
| Plain field | No | No | No |
| `volatile` | **No** (except long/double) | Yes | Yes |
| `synchronized` | Yes | Yes | Yes |
| `AtomicInteger` etc | Yes | Yes | Yes |
| `final` (after construction) | — | Yes | Yes |

**`volatile` does not make `count++` thread-safe.** That is a read-modify-write — three operations. This is the most common Java concurrency interview question.

## What Volatile Actually Does

1. **Visibility** — reads/writes go to main memory, not a cached copy
2. **Ordering** — inserts memory barriers preventing reordering across the access
3. **Long/double atomicity** — 64-bit reads/writes become atomic (they are not otherwise on 32-bit JVMs)

Correct uses: status flags, the double-checked-locking reference, and any single-writer/multi-reader value.

```java
private volatile boolean running = true;   // correct
public void stop() { running = false; }
public void run() { while (running) { ... } }   // without volatile, may loop forever
```

## Double-Checked Locking

```java
private static volatile Singleton instance;   // volatile is MANDATORY

public static Singleton getInstance() {
    if (instance == null) {                   // 1st check, no lock
        synchronized (Singleton.class) {
            if (instance == null) {           // 2nd check, under lock
                instance = new Singleton();
            }
        }
    }
    return instance;
}
```

**Why volatile is required:** `new Singleton()` is three steps — allocate, construct, assign. Without volatile the JVM may reorder to allocate, *assign*, construct. Another thread then sees a non-null but partially constructed object.

Prefer the **Bill Pugh holder idiom** instead — simpler and correct without volatile:

```java
private static class Holder { static final Singleton INSTANCE = new Singleton(); }
public static Singleton getInstance() { return Holder.INSTANCE; }
```

Class initialisation is guaranteed thread-safe by the JVM, and the holder loads lazily on first access.

## False Sharing

Two independent variables on the same 64-byte cache line cause cores to invalidate each other's caches despite no logical contention. `@Contended` (with `-XX:-RestrictContended`) pads them apart. Relevant for high-throughput counters — mention it if asked about scaling contended atomics.

## Common Questions

- *Does volatile make operations atomic?* — No, except for 64-bit reads/writes.
- *Why is volatile needed in DCL?* — to prevent publishing a partially constructed object.
- *What's the difference between volatile and synchronized?* — volatile gives visibility and ordering; synchronized adds mutual exclusion and atomicity.
- *Can a final field be seen as uninitialised?* — not if the object is safely published and `this` doesn't escape the constructor.

## Common Mistakes

- Using volatile for counters
- Omitting volatile in double-checked locking
- Assuming that because a bug "never reproduces locally", the code is correct — JMM violations are timing- and JIT-dependent
- Letting `this` escape from a constructor, breaking final-field guarantees

## Related Topics

- [Synchronisation and Locks](Synchronisation%20and%20Locks.md)
- [Atomics and CAS](Atomics%20and%20CAS.md)
- Singleton Pattern *(not yet written)*

## Revision Summary

Happens-before defines visibility. Volatile gives visibility and ordering but not atomicity. Synchronized gives all three. Double-checked locking needs volatile; the holder idiom avoids the problem entirely.

## Quick Recall

- volatile ≠ atomic
- `count++` is read-modify-write — needs Atomic or a lock
- DCL requires `volatile` on the field
- Bill Pugh holder is the preferred lazy singleton
- unlock happens-before the next lock on the same monitor
