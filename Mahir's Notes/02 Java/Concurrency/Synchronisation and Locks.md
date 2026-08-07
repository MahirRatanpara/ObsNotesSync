# Synchronisation and Locks

## Why It Matters

The difference between `synchronized` and `ReentrantLock`, and knowing when each is appropriate, is standard senior-level material.

## synchronized

Every Java object has an intrinsic **monitor**. `synchronized` acquires it on entry and releases on exit — including on exception, which is its main safety advantage.

```java
synchronized void instanceMethod() { }        // locks on `this`
static synchronized void staticMethod() { }   // locks on ClassName.class
synchronized (lockObject) { }                 // locks on a specific object
```

**Instance and static methods use different locks.** They do not exclude each other — a classic trick question.

### Lock Object Selection

```java
private final Object lock = new Object();     // GOOD — private, dedicated
synchronized (lock) { ... }
```

Never synchronise on:
- `this` in a public class — external code can lock your object and deadlock you
- A `String` literal — interned and shared JVM-wide
- A boxed primitive (`Integer`) — cached in the −128..127 range and shared
- A mutable field — reassigning it means threads lock different objects

## Lock Escalation

The JVM optimises uncontended locks:

```
Biased (removed in Java 15+) → Thin/Lightweight (CAS) → Fat/Heavyweight (OS monitor)
```

Uncontended `synchronized` is nearly free — a CAS on the object header. Only genuine contention escalates to an OS-level monitor with context switches. This is why "synchronized is slow" is outdated advice.

## ReentrantLock

```java
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try { criticalSection(); }
finally { lock.unlock(); }   // MUST be in finally
```

### What It Adds Over synchronized

| Capability | synchronized | ReentrantLock |
|---|---|---|
| Auto-release on exception | **Yes** | No — needs `finally` |
| `tryLock()` (non-blocking) | No | **Yes** |
| `tryLock(timeout)` | No | **Yes** |
| Interruptible acquisition | No | **`lockInterruptibly()`** |
| Fairness option | No | **Yes** (`new ReentrantLock(true)`) |
| Multiple condition variables | One wait set | **`newCondition()`** |
| Lock across method boundaries | No | Yes |

**Default to `synchronized`.** Reach for `ReentrantLock` only when you need timeout, interruptibility, fairness, or multiple conditions.

### Fairness

A fair lock grants access in FIFO order, preventing starvation — at a significant throughput cost (it defeats barging). Use only when starvation is demonstrably a problem.

## ReadWriteLock and StampedLock

```java
ReadWriteLock rw = new ReentrantReadWriteLock();
rw.readLock().lock();    // many readers concurrently
rw.writeLock().lock();   // exclusive
```

Worthwhile only with a **high read-to-write ratio** and non-trivial critical sections. With frequent writes it's slower than a plain lock due to bookkeeping.

**`StampedLock`** (Java 8) adds **optimistic reads** — no lock at all, just a version stamp validated afterwards:

```java
long stamp = sl.tryOptimisticRead();
int localCopy = sharedValue;
if (!sl.validate(stamp)) {         // a writer intervened
    stamp = sl.readLock();
    try { localCopy = sharedValue; } finally { sl.unlockRead(stamp); }
}
```

**StampedLock is not reentrant** — recursive acquisition deadlocks.

## wait / notify

```java
synchronized (lock) {
    while (!condition) {      // WHILE, never if
        lock.wait();
    }
    // proceed
}
```

Three rules:

1. **Must hold the monitor** to call `wait`/`notify`, else `IllegalMonitorStateException`
2. **Always loop, never `if`** — protects against *spurious wakeups* and against another thread consuming the condition first
3. **Prefer `notifyAll()`** — `notify()` wakes one arbitrary thread, which may be waiting on a different condition, causing a lost-wakeup deadlock

`Condition` (from `ReentrantLock`) gives separate wait sets so you can signal precisely — `notFull.signal()` vs `notEmpty.signal()` — which makes `signal()` safe where `notify()` was not.

## Deadlock

Requires all four Coffman conditions: mutual exclusion, hold-and-wait, no preemption, circular wait.

**Prevention, in order of practicality:**

1. **Global lock ordering** — always acquire locks in a consistent order (e.g. by `System.identityHashCode`). Breaks circular wait. This is the standard answer.
2. **`tryLock` with timeout** — back off and retry, breaking hold-and-wait
3. **Reduce lock scope** — hold one lock at a time where possible
4. **Open calls** — never invoke unknown/callback code while holding a lock

Detect with `jstack` — it explicitly reports "Found one Java-level deadlock".

## Common Mistakes

- `unlock()` outside `finally` — an exception leaks the lock permanently
- Using `if` instead of `while` around `wait()`
- Synchronising on `this`, a String literal, or a boxed Integer
- Assuming instance and static synchronized methods exclude each other
- Nested locks acquired in inconsistent order

## Related Topics

- [Java Memory Model](Java%20Memory%20Model.md)
- [Atomics and CAS](Atomics%20and%20CAS.md)
- Concurrency Problem Patterns *(not yet written)*

## Revision Summary

`synchronized` is simpler and auto-releases; `ReentrantLock` adds timeout, interruptibility, fairness, and multiple conditions. Always `wait()` in a `while` loop. Prevent deadlock with a global lock ordering.

## Quick Recall

- `lock()` … `finally { unlock() }`
- `while (!cond) wait();` — never `if`
- Prefer `notifyAll()` over `notify()`
- Instance and static locks are different monitors
- Consistent lock ordering breaks circular wait
