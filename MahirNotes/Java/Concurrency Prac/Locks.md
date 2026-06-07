
> Source: codeWithAryan article on Locks and Types of Locks Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets

---

## Table of Contents

1. [Why Explicit Locks? synchronized vs ReentrantLock](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-why-explicit-locks-synchronized-vs-reentrantlock)
2. [ReentrantLock — Core Mechanics](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-reentrantlock--core-mechanics)
3. [The Three Exclusive Advantages of ReentrantLock](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-the-three-exclusive-advantages-of-reentrantlock)
4. [tryLock() — Non-Blocking Acquisition](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-trylock--non-blocking-acquisition)
5. [lockInterruptibly() — Interruptible Acquisition](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-lockinterruptibly--interruptible-acquisition)
6. [Fairness Policy](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-fairness-policy)
7. [ReentrantReadWriteLock](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-reentrantreadwritelock)
8. [Lock Downgrading vs Lock Upgrading](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-lock-downgrading-vs-lock-upgrading)
9. [Writer Starvation](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-writer-starvation)
10. [Common Traps and Bugs](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#10-common-traps-and-bugs)
11. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#11-session-scorecard)
12. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#12-revision-targets)

---

## 1. Why Explicit Locks? synchronized vs ReentrantLock

### synchronized — What It Gives You

- Built into the language — no imports needed
- Automatically acquires and releases the monitor lock
- Lock released automatically on block exit, even on exception
- Simple to use — low risk of forgetting to unlock

### synchronized — What It Cannot Do

|Limitation|Description|
|---|---|
|No timeout|Waits indefinitely for the lock — no escape|
|Not interruptible|Thread in BLOCKED state cannot be interrupted|
|No fairness|Any waiting thread may be chosen arbitrarily|
|No try-acquire|Cannot attempt lock and proceed if unavailable|
|Single condition|Only one wait set per object|

### ReentrantLock — Explicit Lock Advantages

|Capability|Method|synchronized equivalent|
|---|---|---|
|Try-acquire with timeout|`tryLock(time, unit)`|❌ not available|
|Interruptible waiting|`lockInterruptibly()`|❌ not available|
|Fairness (FIFO)|`new ReentrantLock(true)`|❌ not available|
|Manual release control|`lock()` / `unlock()`|Auto on block exit|
|Multiple conditions|`lock.newCondition()`|❌ only one per object|

---

## 2. ReentrantLock — Core Mechanics

### What Is Reentrancy?

A thread that already holds a `ReentrantLock` can **re-acquire it** without deadlocking. The lock keeps an internal count of how many times the holding thread has acquired it.

**Problem it solves:** Without reentrancy, a thread calling a synchronized/locked method that internally calls another locked method on the same object would deadlock with itself — waiting for a lock it already owns.

> ⚠️ IMPORTANT: `synchronized` is ALSO reentrant in Java. Reentrancy is NOT an exclusive advantage of `ReentrantLock`. Never name it as a differentiator.

### The Mandatory finally Pattern

```java
lock.lock();          // MUST be BEFORE the try block
try {
    // critical section
} finally {
    lock.unlock();    // MUST be in finally — always releases
}
```

### Why lock.lock() Must Be Before try

```java
// WRONG — lock.lock() inside try
try {
    lock.lock();      // if this throws, finally still runs
    // critical section
} finally {
    lock.unlock();    // called on a lock never acquired → IllegalMonitorStateException
}

// CORRECT — lock.lock() before try
lock.lock();          // if this throws, finally does NOT run
try {
    // critical section
} finally {
    lock.unlock();    // only runs if lock was successfully acquired
}
```

**Consequence of wrong pattern:** `unlock()` called on unacquired lock → `IllegalMonitorStateException`.

### Why finally Is Mandatory

If an exception is thrown inside the `try` block and `unlock()` is not in `finally`, the lock is **never released**. Every thread waiting to acquire it blocks forever — effectively a deadlock.

### Full Example

```java
private final ReentrantLock lock = new ReentrantLock();
private int counter = 0;

public void increment() {
    lock.lock();
    try {
        counter++;
    } finally {
        lock.unlock(); // always releases, even on exception
    }
}
```

### Q&A Recap

**Q:** Why unlock() in finally? **A:** Exception must not prevent lock release — deadlock otherwise ✅

**Q:** Why lock.lock() before try? **A:** If inside try and throws → finally calls unlock() on unacquired lock → IllegalMonitorStateException ✅

---

## 3. The Three Exclusive Advantages of ReentrantLock

These are the **only three** capabilities `ReentrantLock` has that `synchronized` does not. Know these cold — reentrancy is NOT one of them.

### 1. tryLock() — Non-Blocking / Timed Acquisition

Attempt to acquire the lock without blocking indefinitely.

### 2. lockInterruptibly() — Interruptible Waiting

Thread waiting for lock can be interrupted and give up.

### 3. Fairness Policy — FIFO Ordering

`new ReentrantLock(true)` ensures threads acquire the lock in the order they requested it.

### The Differentiator Table

|Capability|`synchronized`|`ReentrantLock`|
|---|---|---|
|Reentrancy|✅|✅ (not a differentiator)|
|tryLock() with timeout|❌|✅|
|lockInterruptibly()|❌|✅|
|Fairness (FIFO)|❌|✅|

### ⚠️ GAP IDENTIFIED

In the session, reentrancy was named as a differentiator — this is wrong. `synchronized` is also reentrant. If asked for what `ReentrantLock` offers that `synchronized` does not, the answer is always the three above: `tryLock`, `lockInterruptibly`, fairness.

---

## 4. tryLock() — Non-Blocking Acquisition

### What It Does

Attempts to acquire the lock. Returns immediately (or after a timeout) with a boolean result.

```java
// Without timeout — returns immediately
if (lock.tryLock()) {
    try {
        // got the lock
    } finally {
        lock.unlock();
    }
} else {
    // didn't get the lock — do something else
}

// With timeout
if (lock.tryLock(2, TimeUnit.SECONDS)) {
    try {
        // acquired within 2 seconds
    } finally {
        lock.unlock();
    }
} else {
    // couldn't acquire in 2 seconds
    System.out.println("Lock not available — taking alternate action");
}
```

### Two Actions After Failed tryLock()

1. **Take an alternate action** — log failure, return error, skip the operation entirely
2. **Retry later** — wait a bit and call `tryLock()` again

### Why Impossible with synchronized

`synchronized` puts the thread in BLOCKED state with no timeout and no way to give up. The thread waits indefinitely — no alternate path possible.

### The Article's Example

Task-A holds lock for 5 seconds. Task-B calls `tryLock(2, TimeUnit.SECONDS)`:

```
Task-A acquired the lock and is performing a long task.
Task-B could not acquire the lock using tryLock within 2 seconds.
Task-A finished the task and is releasing the lock.
```

Task-B moved on instead of blocking for 5 seconds.

### Q&A Recap

**Q:** Two actions after failed tryLock()? **A:** Alternate action or retry later ✅. Contrast with synchronized blocking ✅

---

## 5. lockInterruptibly() — Interruptible Acquisition

### The Problem with synchronized

A thread waiting for a `synchronized` lock is in BLOCKED state and **cannot be interrupted**. Calling `thread.interrupt()` has no effect — the thread waits forever until the lock is released.

### What lockInterruptibly() Does

If a thread is waiting to acquire a `ReentrantLock` via `lockInterruptibly()` and another thread calls `interrupt()` on it, it immediately throws `InterruptedException` instead of continuing to wait.

```java
try {
    lock.lockInterruptibly(); // waits for lock but CAN be interrupted
    try {
        // critical section
    } finally {
        lock.unlock();
    }
} catch (InterruptedException e) {
    // interrupted while waiting for the lock
    Thread.currentThread().interrupt(); // restore flag
    System.out.println("Gave up waiting for lock — interrupted");
}
```

### Real-World Use Cases

- Thread waiting for a long-held lock needs to be cancelled (shutdown signal)
- Deadlock recovery — interrupt one thread to break the cycle
- Request timeout — give up waiting if response takes too long

### Comparison

|Scenario|`synchronized`|`lockInterruptibly()`|
|---|---|---|
|Thread waiting for lock|BLOCKED — no escape|Can be interrupted|
|`thread.interrupt()` called|Ignored|`InterruptedException` thrown|
|Timeout/cancellation|Impossible|Possible|

### Q&A Recap

**Q:** Name 3 advantages of ReentrantLock over synchronized. **A:** Named reentrancy (wrong) + tryLock (✅) — needed explanation for lockInterruptibly() ⚠️

### ⚠️ GAP IDENTIFIED

`lockInterruptibly()` was not known from the article alone. Key points:

- `synchronized` BLOCKED state ignores interrupts entirely
- `lockInterruptibly()` converts an interrupt into `InterruptedException` while waiting
- Must still restore interrupt flag in catch block

---

## 6. Fairness Policy

### What It Is

By default, `ReentrantLock` (like `synchronized`) gives no ordering guarantee — any waiting thread may be chosen when the lock becomes available. A thread could theoretically wait indefinitely if others keep cutting in.

Fairness mode enforces **FIFO ordering** — threads acquire the lock in the order they requested it.

```java
// Unfair (default) — any waiting thread may go next
ReentrantLock unfairLock = new ReentrantLock();
ReentrantLock unfairLock = new ReentrantLock(false);

// Fair — FIFO ordering guaranteed
ReentrantLock fairLock = new ReentrantLock(true);
```

### Trade-off

Fair locks have **lower throughput** than unfair locks. Enforcing FIFO requires tracking request order — this overhead means fair locks are slower overall, but prevent thread starvation.

Use fairness when starvation is a real risk. Default to unfair for better performance.

---

## 7. ReentrantReadWriteLock

### What It Is

A lock split into two parts:

- **Read lock** — shared; multiple threads can hold simultaneously
- **Write lock** — exclusive; only one thread, blocks all others

```java
private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();

// Read operation
public void read() {
    rwLock.readLock().lock();
    try {
        // multiple threads can be here simultaneously
    } finally {
        rwLock.readLock().unlock();
    }
}

// Write operation
public void write(int value) {
    rwLock.writeLock().lock();
    try {
        // exclusive — no readers or writers allowed
    } finally {
        rwLock.writeLock().unlock();
    }
}
```

### The Three Concurrency Rules

|Situation|Allowed?|
|---|---|
|Multiple threads reading, no writer|✅ All readers proceed concurrently|
|Thread writing, others want to read|❌ Readers must wait|
|Thread writing, others want to write|❌ Other writers must wait|
|Thread reading, writer wants in|❌ Writer must wait for all readers|

### When to Use It

Use `ReentrantReadWriteLock` when reads are **significantly more frequent** than writes. The concurrent read capability eliminates the serialization bottleneck that `synchronized` and `ReentrantLock` impose on reads.

**Example:** A shared cache with 95% reads / 5% writes — readers never block each other, only writers cause contention.

### Why synchronized Is Wrong for Read-Heavy Workloads

`synchronized` (or plain `ReentrantLock`) treats reads and writes identically — every access is exclusive. 100 threads wanting to read must queue one by one, even though concurrent reads are completely safe. This is unnecessary contention that `ReentrantReadWriteLock` eliminates.

### Q&A Recap

**Q:** Concurrency rules for read/write lock? **A:** Multiple concurrent reads allowed; write is exclusive ✅

**Q:** Why better than synchronized for read-heavy? **A:** Concurrent reads; synchronized serializes even safe read operations ✅

---

## 8. Lock Downgrading vs Lock Upgrading

### Lock Downgrading — SUPPORTED ✅

Acquiring a **read lock while already holding the write lock**, then releasing the write lock.

```java
rwLock.writeLock().lock();
try {
    data = computeNewValue();      // write operation
    rwLock.readLock().lock();      // ✅ acquire read while holding write
} finally {
    rwLock.writeLock().unlock();   // release write — now only hold read
}
try {
    return data;                   // read while holding read lock
} finally {
    rwLock.readLock().unlock();
}
```

**Why useful:** Guarantees the data you just wrote is the same data you read back, without releasing the write lock first and risking another writer modifying it.

### Lock Upgrading — NOT SUPPORTED ❌

Acquiring a **write lock while already holding a read lock**.

```java
rwLock.readLock().lock();
// ...
rwLock.writeLock().lock(); // ❌ DEADLOCK — not supported
```

This deadlocks because the write lock waits for all readers to release — including the current thread itself. The thread waits for itself to release the read lock, which never happens.

### Summary

|Operation|Direction|Supported|
|---|---|---|
|Lock downgrading|write → read|✅ Yes|
|Lock upgrading|read → write|❌ No — deadlocks|

### Q&A Recap

**Q:** Is acquiring read lock while holding write lock valid? **A (initial):** No — write is mutually exclusive ❌ **A (corrected):** Yes — this is lock downgrading, supported by ReentrantReadWriteLock ✅

### ⚠️ GAP IDENTIFIED

Lock downgrading is valid and supported. Lock upgrading is not (deadlock). Know both directions and their names cold.

---

## 9. Writer Starvation

### What It Is

In a read-heavy system with continuous incoming reads, a writer may **never acquire the write lock** because:

- Write lock requires all current readers to release
- New readers keep arriving before the writer gets a turn
- Writer waits indefinitely — **writer starvation**

### The Fix

Enable the **fairness policy** on the `ReentrantReadWriteLock`:

```java
// Without fairness — writers can starve
ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();

// With fairness — FIFO ordering prevents starvation
ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock(true);
```

With fairness enabled, once a writer is waiting, new readers queue behind it rather than jumping ahead.

### What NOT to Do

Switching to plain `ReentrantLock` or `synchronized` is NOT the fix — this serializes all reads and destroys the performance benefit. The correct fix is always the fairness policy on the same `ReentrantReadWriteLock`.

### Q&A Recap

**Q:** What is writer starvation and how do you fix it? **A:** Defined correctly ✅. Fix: said switch to ReentrantLock ❌ → Correct: fairness policy `new ReentrantReadWriteLock(true)` ✅

### ⚠️ GAP IDENTIFIED

Writer starvation fix = **fairness policy**, not lock type change. `new ReentrantReadWriteLock(true)` is the answer. Switching to `ReentrantLock` defeats the entire purpose.

---

## 10. Common Traps and Bugs

### Trap 1 — Reentrancy as a Differentiator

```
WRONG: "ReentrantLock is better because it supports reentrancy"
RIGHT: synchronized is ALSO reentrant in Java
```

Never name reentrancy as an advantage of `ReentrantLock` over `synchronized`.

### Trap 2 — lock.lock() Inside try Block

```java
// WRONG
try {
    lock.lock();      // throws → finally runs → unlock() on unacquired lock
} finally {
    lock.unlock();    // IllegalMonitorStateException
}

// CORRECT
lock.lock();          // before try
try {
    // ...
} finally {
    lock.unlock();
}
```

### Trap 3 — Forgetting unlock() in finally

```java
// WRONG — exception skips unlock()
lock.lock();
// ... exception thrown here ...
lock.unlock(); // never reached → permanent deadlock

// CORRECT
lock.lock();
try {
    // ...
} finally {
    lock.unlock(); // always runs
}
```

### Trap 4 — Lock Upgrading Attempt

```java
// DEADLOCK — never do this
rwLock.readLock().lock();
rwLock.writeLock().lock(); // waits for self to release read lock → deadlock
```

### Trap 5 — Writer Starvation Fix

```
WRONG fix: switch to ReentrantLock (destroys concurrent read benefit)
CORRECT fix: new ReentrantReadWriteLock(true) (fairness policy)
```

### Trap 6 — Using synchronized for Read-Heavy Workload

```java
// WRONG — serializes safe concurrent reads
public synchronized Data read() { return data; }

// CORRECT — allows concurrent reads
public Data read() {
    rwLock.readLock().lock();
    try { return data; } finally { rwLock.readLock().unlock(); }
}
```

---

## 11. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|Reentrancy — definition and problem solved|✅|Clean|
|unlock() in finally — why mandatory|✅|Clean|
|3 ReentrantLock advantages over synchronized|⚠️|Named reentrancy as differentiator — wrong|
|lockInterruptibly() — concept|❌ → ✅|Not known; understood after explanation|
|ReentrantReadWriteLock concurrency rules|✅|Clean|
|lock.lock() before try — why|✅|Correct in session; imprecise in rapid-fire|
|tryLock() — two actions after failure|✅|Clean|
|ReentrantLock vs synchronized read-heavy|✅|Clean|
|Lock downgrading — valid or not|❌ → ✅|Said invalid; corrected after explanation|
|Cache scenario — correct lock recommendation|✅|ReentrantReadWriteLock|
|Writer starvation — definition|✅|Clean|
|Writer starvation — fix|❌|Said ReentrantLock — wrong; fairness policy is correct|
|lockInterruptibly() method name|✅|Clean after learning|
|3 differentiators in rapid-fire|⚠️|Named reentrancy again instead of fairness|

---

## 12. Revision Targets

### 🔴 Priority 1 — Must Be Instinct

**1. Reentrancy is NOT exclusive to ReentrantLock**

`synchronized` is also reentrant. Never name it as a differentiator. The three real differentiators are:

1. `tryLock()` with timeout
2. `lockInterruptibly()`
3. Fairness policy — `new ReentrantLock(true)`

---

**2. Writer starvation fix = fairness policy, NOT lock type change**

```java
// CORRECT FIX
new ReentrantReadWriteLock(true) // fairness = FIFO for writers

// WRONG FIX
new ReentrantLock() // destroys concurrent read benefit
```

---

**3. Lock downgrading vs upgrading**

|Direction|Name|Supported|
|---|---|---|
|write → read (acquire read while holding write)|Downgrading|✅ Yes|
|read → write (acquire write while holding read)|Upgrading|❌ Deadlocks|

---

### 🟡 Priority 2

**4. lockInterruptibly() — full explanation**

`synchronized` BLOCKED state ignores interrupts. `lockInterruptibly()` converts a thread interrupt into `InterruptedException` while waiting for a lock. Useful for deadlock recovery, timeout cancellation, graceful shutdown.

**5. lock.lock() placement — two-part answer**

1. Inside `try` + throws before acquired → `finally` runs → `unlock()` on unacquired lock → `IllegalMonitorStateException`
2. Before `try` → if throws, `finally` doesn't run → no spurious unlock

**6. Three concurrency rules for ReentrantReadWriteLock**

- Multiple readers with no writer → ✅ all proceed
- Any writer present → ❌ all others blocked
- Writer wants in, readers active → ❌ writer waits for all readers

---

### 🟢 Already Solid

- Reentrancy definition and the deadlock it prevents
- unlock() in finally — mandatory, exception-safety
- tryLock() with timeout — two actions after failure
- synchronized serializes reads — why ReentrantReadWriteLock wins for read-heavy
- Writer starvation definition
- IllegalMonitorStateException on unlock without lock

---

## Quick Reference Cheatsheet

```
REENTRANTLOCK vs SYNCHRONIZED:
  Both:      reentrant, mutual exclusion, automatic reentrancy
  ReentrantLock ONLY:
    tryLock(time, unit)      → non-blocking / timed acquisition
    lockInterruptibly()      → interruptible waiting (synchronized ignores interrupt)
    new ReentrantLock(true)  → FIFO fairness

MANDATORY PATTERN:
  lock.lock();           // BEFORE try
  try {
      // critical section
  } finally {
      lock.unlock();     // ALWAYS in finally
  }

REENTRANTREADWRITELOCK RULES:
  Multiple readers, no writer  → ✅ concurrent reads
  Any writer                   → ❌ exclusive — all others blocked
  Writer waiting               → ❌ must wait for all active readers

LOCK DOWNGRADING (supported):
  writeLock.lock() → readLock.lock() → writeLock.unlock() → readLock.unlock()

LOCK UPGRADING (not supported — DEADLOCKS):
  readLock.lock() → writeLock.lock() → DEADLOCK

WRITER STARVATION:
  Problem: continuous readers starve waiting writer
  Fix:     new ReentrantReadWriteLock(true)  ← fairness policy
  NOT:     switching to ReentrantLock (destroys concurrent reads)

TRYLOCKPATTERN:
  if (lock.tryLock(2, TimeUnit.SECONDS)) {
      try { ... } finally { lock.unlock(); }
  } else {
      // alternate action or retry
  }
```