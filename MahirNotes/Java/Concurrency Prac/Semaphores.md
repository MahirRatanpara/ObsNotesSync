
> Source: codeWithAryan article on Semaphores Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets + fair reader-writer deep dive

---

## Table of Contents

1. [What Is a Semaphore?](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-what-is-a-semaphore)
2. [Binary vs Counting Semaphore](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-binary-vs-counting-semaphore)
3. [release() Without acquire() — Legal but Dangerous](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-release-without-acquire--legal-but-dangerous)
4. [Semaphore vs Lock — Four Differences](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-semaphore-vs-lock--four-differences)
5. [Four Core Use Cases](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-four-core-use-cases)
6. [Producer-Consumer with Two Semaphores](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-producer-consumer-with-two-semaphores)
7. [Barrier Synchronization Pattern](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-barrier-synchronization-pattern)
8. [Reader-Writer Lock Using Semaphores](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-reader-writer-lock-using-semaphores)
9. [Fair Reader-Writer Lock — Preventing Write Starvation](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-fair-reader-writer-lock--preventing-write-starvation)
10. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#10-session-scorecard)
11. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#11-revision-targets)

---

## 1. What Is a Semaphore?

### Core Definition

A semaphore is a synchronization primitive that maintains a **count of permits**. Threads acquire permits to proceed and release them when done.

### Two Primary Operations

|Operation|Effect|Behavior When Count = 0|
|---|---|---|
|`acquire()`|Decrements permit count by 1|**Blocks** until a permit becomes available|
|`release()`|Increments permit count by 1|Unblocks a waiting thread if any|

### Key Insight

The permit count is the core primitive. Everything else — binary semaphore, counting semaphore, barriers, resource pools — is built on top of this single counter.

```java
Semaphore semaphore = new Semaphore(3); // 3 permits available

semaphore.acquire(); // count → 2
semaphore.acquire(); // count → 1
semaphore.acquire(); // count → 0
semaphore.acquire(); // BLOCKS — no permits left

semaphore.release(); // count → 1, unblocks one waiting thread
```

### Q&A Recap

**Q:** What is a semaphore and what do acquire/release do? **A:** Permit-based access control; acquire decrements and blocks at 0; release increments and unblocks ✅

---

## 2. Binary vs Counting Semaphore

### Binary Semaphore

- Initialized to **1**
- Only two meaningful states: 0 (locked) or 1 (unlocked)
- Used for **mutual exclusion** — like a mutex
- One thread at a time in the critical section

```java
Semaphore mutex = new Semaphore(1); // binary semaphore

mutex.acquire(); // only one thread proceeds
try {
    // critical section
} finally {
    mutex.release();
}
```

### Counting Semaphore

- Initialized to **N** (any positive integer)
- Controls access to a pool of N resources
- Up to N threads can be inside simultaneously

```java
Semaphore resourcePool = new Semaphore(5); // 5 permits — 5 concurrent threads

resourcePool.acquire(); // one of 5 slots claimed
try {
    // use resource
} finally {
    resourcePool.release(); // slot returned
}
```

### Key Distinction — No Ownership

Unlike `ReentrantLock`, a semaphore has **no ownership concept**. Any thread can call `release()` — even one that never called `acquire()`. This is both a feature and a risk.

Also: Binary semaphore is **not reentrant**. If the same thread calls `acquire()` twice, it deadlocks with itself — count drops to 0 on first acquire, second acquire blocks forever waiting for itself.

### Q&A Recap

**Q:** Two types of semaphores — permit counts and use cases? **A:** Binary (1) = mutual exclusion; Counting (N) = resource pool ✅

---

## 3. release() Without acquire() — Legal but Dangerous

### What Happens

In Java's `Semaphore`, calling `release()` without a prior `acquire()` is **perfectly legal**. It simply increases the permit count — even beyond the initial value.

```java
Semaphore semaphore = new Semaphore(2); // initialized to 2

semaphore.release(); // count → 3 (beyond initial value!)
System.out.println(semaphore.availablePermits()); // prints 3

// Now 3 threads can acquire simultaneously instead of 2
```

### The Risk

Uncontrolled releases break the resource pool contract. If you initialize a semaphore to limit 5 concurrent DB connections but accidentally call `release()` extra times, more than 5 threads access the pool — potentially exhausting connections and causing failures.

### The Rule

Always pair `release()` calls with `acquire()` calls. Only release what you have acquired.

### Q&A Recap

**Q:** release() without acquire() — what happens? **A:** Permit count increases beyond initial value; more threads than intended may proceed ✅

---

## 4. Semaphore vs Lock — Four Differences

### The Four Differences

|Aspect|Lock (ReentrantLock)|Semaphore|
|---|---|---|
|**Concurrency**|Exactly 1 thread (mutual exclusion)|N threads concurrently (configurable)|
|**Ownership**|Owned by acquiring thread — only that thread can release|No ownership — any thread can release|
|**Permit overflow**|Not applicable|`release()` without `acquire()` increases count beyond initial|
|**Condition variables**|Supports multiple (`lock.newCondition()`)|No condition variable support — permit-based only|

### The Ownership Distinction — Most Important

```java
// Lock — ONLY the acquiring thread can unlock
lock.lock();                    // Thread-A acquires
lock.unlock();                  // Thread-B unlocking → IllegalMonitorStateException

// Semaphore — ANY thread can release
semaphore.acquire();            // Thread-A acquires
semaphore.release();            // Thread-B can legally release it
```

This makes semaphores useful for **cross-thread signaling** — one thread signals another to proceed, without the signaling thread ever acquiring the semaphore.

### Q&A Recap

**Q:** Three differences between Semaphore and Lock? **A:** Concurrency level ✅, no ownership ✅, permit overflow ✅ **Note:** Fourth difference (condition variables) added — Locks support `newCondition()`, Semaphores do not.

---

## 5. Four Core Use Cases

### ⚠️ Know These Precisely — Don't Confuse with Advanced Patterns

The article's four core use cases (not the barrier/reader-writer patterns):

|Use Case|Semaphore Init|Description|
|---|---|---|
|**Resource pool management**|N (pool size)|DB connections, file handlers, thread pools|
|**Producer-consumer**|emptySlots=bufferSize, filledSlots=0|Coordinate buffer access|
|**Concurrency limiting**|Max threads allowed|Prevent system overload|
|**Mutual exclusion**|1 (binary)|Single-thread critical section|

```java
// 1. Resource pool
Semaphore dbPool = new Semaphore(5); // 5 DB connections

// 2. Producer-consumer
Semaphore emptySlots = new Semaphore(bufferSize);
Semaphore filledSlots = new Semaphore(0);

// 3. Concurrency limiting
Semaphore maxThreads = new Semaphore(10); // max 10 concurrent

// 4. Mutual exclusion
Semaphore mutex = new Semaphore(1); // binary semaphore
```

### ⚠️ GAP IDENTIFIED

In rapid-fire, the barrier and reader-writer patterns were named as core use cases — these are from the interview questions section, not the four use cases. Know the four above cold and separately from the advanced patterns.

---

## 6. Producer-Consumer with Two Semaphores

### The Two Semaphores

|Semaphore|Initial Value|Meaning|
|---|---|---|
|`emptySlots`|`bufferSize`|Number of slots available for filling|
|`filledSlots`|`0`|Number of items available for consuming|

### Why These Initial Values?

- `emptySlots = bufferSize` — buffer starts completely empty, all slots available to produce into
- `filledSlots = 0` — buffer starts empty, no items to consume — consumer blocks immediately

### The Acquire/Release Pattern

**Producer:**

```java
emptySlots.acquire();  // wait if buffer full (no empty slots)
buffer.add(item);      // produce item
filledSlots.release(); // signal consumer: new item available
```

**Consumer:**

```java
filledSlots.acquire(); // wait if buffer empty (no filled slots)
item = buffer.take();  // consume item
emptySlots.release();  // signal producer: slot freed
```

### The Elegance

No explicit `wait()`/`notify()` needed. The semaphores themselves encode the blocking condition:

- Producer blocked when `emptySlots = 0` (buffer full)
- Consumer blocked when `filledSlots = 0` (buffer empty)

### Q&A Recap

**Q:** What does each semaphore represent and what do producer/consumer acquire/release? **A:** Correct overall logic ✅. Precise acquire/release pattern per role needed sharpening ⚠️

---

## 7. Barrier Synchronization Pattern

### What Is a Barrier?

No thread can proceed past a certain point until **all** threads have reached that point. Used for phased execution — all threads complete Phase 1 before any begins Phase 2.

### Two Semaphores Used

|Semaphore|Init|Role|
|---|---|---|
|`mutex`|1|Protects `readerCount` — atomic counter updates|
|`barrier`|**0**|Blocks all threads until the last one arrives|

### Why barrier Starts at 0

Every thread that calls `barrier.acquire()` immediately blocks — no permits available. Only when the **last thread** arrives does it call `barrier.release(parties - 1)`, unblocking all waiting threads simultaneously.

### The await() Logic

```java
public void await() throws InterruptedException {
    mutex.acquire();
    count--;
    if (count == 0) {
        // Last thread: unblock everyone
        barrier.release(parties - 1);
        count = parties; // reset for reuse
        mutex.release();
    } else {
        // Not last: release mutex, wait at barrier
        mutex.release();
        barrier.acquire(); // blocks here until last thread arrives
    }
}
```

### Execution Flow

```
Threads 1-4 arrive → decrement count → release mutex → block on barrier.acquire()
Thread 5 arrives → count hits 0 → calls barrier.release(4) → unblocks all 4
All 5 threads proceed to Phase 2 simultaneously
```

### Q&A Recap

**Q:** What does each semaphore do in the barrier pattern? **A:** mutex protects count ✅; barrier blocks all until last thread ✅; initialized to 0 ✅ with correct reasoning

---

## 8. Reader-Writer Lock Using Semaphores

### Three Semaphores Used

|Semaphore|Init|Role|
|---|---|---|
|`mutex`|1|Protects `readerCount` atomically|
|`wrt`|1|Blocks writers when readers active; blocks readers when writer active|

### lockRead() — Why Only First Reader Acquires wrt

```java
public void lockRead() throws InterruptedException {
    mutex.acquire();          // protect readerCount update
    readerCount++;
    if (readerCount == 1) {   // FIRST reader only
        wrt.acquire();        // block writers on behalf of all readers
    }
    mutex.release();
}
```

**Why first reader only?** `wrt` is initialized to 1. If **every** reader acquired `wrt`, Reader-2 would block waiting for Reader-1 to release it — readers would serialize each other. This defeats the entire purpose of the reader-writer pattern (concurrent reads).

Only the first reader acquires `wrt` to block writers. All subsequent readers proceed without touching `wrt`.

### unlockRead() — Why Only Last Reader Releases wrt

```java
public void unlockRead() throws InterruptedException {
    mutex.acquire();
    readerCount--;
    if (readerCount == 0) {   // LAST reader only
        wrt.release();        // unblock waiting writers
    }
    mutex.release();
}
```

The `mutex` ensures `readerCount--` and the `== 0` check are atomic — no two readers can simultaneously think they're the last one.

### lockWrite() / unlockWrite()

```java
public void lockWrite() throws InterruptedException {
    wrt.acquire(); // exclusive — waits for all readers to finish
}

public void unlockWrite() {
    wrt.release();
}
```

### Concurrent Access Rules

|Situation|Result|
|---|---|
|Multiple readers, no writer|✅ All read concurrently|
|Writer active|❌ All readers and writers blocked|
|First reader arrives while writer active|❌ Blocks on wrt.acquire()|
|Last reader finishes|✅ Writer unblocked|

### Q&A Recap

**Q:** Why only first reader acquires wrt? **A (initial):** No functional difference — just cleaner ❌ **A (corrected):** If every reader acquired wrt, readers would serialize — defeats concurrent read purpose ✅

### ⚠️ GAP IDENTIFIED

This is a functional requirement, not a style choice. Every reader acquiring `wrt` → readers queue one-by-one → same as plain mutex → no concurrent read benefit at all. The first-reader pattern is **mandatory** for correct behavior.

---

## 9. Fair Reader-Writer Lock — Preventing Write Starvation

### The Problem

In the basic implementation, readers have priority. A writer waiting on `wrt.acquire()` can be perpetually skipped as new readers keep arriving and incrementing `readerCount`. The writer waits indefinitely — **write starvation**.

### The Fix — Queue Turnstile Semaphore

Add a third semaphore `queue` (initialized to 1) that **both readers and writers** must pass through first.

```java
private final Semaphore mutex = new Semaphore(1);  // protects readerCount
private final Semaphore wrt   = new Semaphore(1);  // writer exclusion
private final Semaphore queue = new Semaphore(1);  // FIFO turnstile — fairness
private int readerCount = 0;

public void lockRead() throws InterruptedException {
    queue.acquire();          // join the queue — if writer waiting, block here
    mutex.acquire();
    readerCount++;
    if (readerCount == 1) wrt.acquire();
    mutex.release();
    queue.release();          // let next thread (reader or writer) through
}

public void lockWrite() throws InterruptedException {
    queue.acquire();          // join the same queue as readers
    wrt.acquire();            // wait for active readers to finish
    queue.release();
}
```

### How the Turnstile Works

```
Reader-1 reading (holds wrt)
Writer-1 arrives → acquires queue → blocks on wrt.acquire() (holds queue)
Reader-2 arrives → tries queue.acquire() → BLOCKED (Writer-1 holds queue)
Reader-3 arrives → BLOCKED behind Reader-2

Reader-1 finishes → wrt released → Writer-1 proceeds
Writer-1 releases queue → Reader-2 and Reader-3 proceed
```

New readers cannot jump ahead of a waiting writer — they must queue behind it.

### Key Insight

When Writer-1 is waiting on `wrt`, it **holds the `queue` semaphore**. New readers trying to enter must acquire `queue` first — they block at the turnstile behind the writer. Writer starvation eliminated.

---

## 10. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|Semaphore — permit count, acquire/release|✅|Clean|
|Binary vs counting semaphore|✅|Clean|
|release() without acquire() — effect and risk|✅|Clean|
|Semaphore vs Lock — 3 differences|✅|Clean; 4th (condition variables) added|
|Four core use cases — precise naming|⚠️|Named barrier/reader-writer instead of concurrency limiting + binary mutex|
|Producer-consumer two semaphores|✅|Good mental model; precise pattern needed sharpening|
|Barrier — mutex and barrier roles|✅|Clean|
|barrier initialized to 0 — why|✅|Clean with correct reasoning|
|First-reader-only acquiring wrt|❌ → ✅|Said no functional difference — corrected|
|Fair reader-writer lock|➕|New concept learned — queue turnstile understood|
|Database connection pool design|✅|Clean|
|Binary semaphore vs ReentrantLock|✅|Reentrancy difference added|
|emptySlots / filledSlots initial values|✅|Clean|

---

## 11. Revision Targets

### 🔴 Priority 1 — Must Be Instinct

**1. Four core use cases — precise names**

These are the four from the use cases section — not barrier/reader-writer:

1. **Resource pool management** — DB connections, file handlers
2. **Producer-consumer** — emptySlots + filledSlots semaphores
3. **Concurrency limiting** — max N threads running simultaneously
4. **Mutual exclusion** — binary semaphore (initialized to 1)

Barrier and reader-writer are advanced patterns from the interview questions section — separate category.

---

**2. First-reader-only acquiring wrt — functional, not stylistic**

If every reader acquires `wrt` → readers serialize → concurrent reads destroyed → same performance as plain mutex.

The first-reader pattern is **mandatory** for correct behavior. The first reader blocks writers on behalf of all readers. The last reader unblocks writers when `readerCount` hits 0.

---

### 🟡 Priority 2

**3. Producer-consumer exact acquire/release per role**

```
Producer: emptySlots.acquire() → produce → filledSlots.release()
Consumer: filledSlots.acquire() → consume → emptySlots.release()
```

Both initial values and the direction of acquire/release must be stated precisely.

**4. Fair reader-writer — queue turnstile**

Third semaphore `queue` (init=1) that both readers and writers must pass through. Writer holding `queue` while waiting on `wrt` blocks all new readers — they queue behind the writer. Prevents write starvation without sacrificing concurrent reads.

**5. Binary semaphore not reentrant** Same thread calling `acquire()` twice on binary semaphore → deadlocks with itself. Unlike `ReentrantLock` which allows re-acquisition.

---

### 🟢 Already Solid

- Semaphore permit count mechanics
- Binary (1) vs counting (N) initialization and use cases
- release() without acquire() increases count beyond initial
- Semaphore has no ownership — any thread can release
- barrier semaphore initialized to 0 — all threads block, last thread releases all
- mutex semaphore in barrier/reader-writer — protects shared counter atomically
- Database connection pool → counting semaphore initialized to pool size

---

## Quick Reference Cheatsheet

```
SEMAPHORE CORE:
  acquire() → count-- (blocks if count = 0)
  release() → count++ (unblocks waiting thread)
  release() without acquire() → legal, count increases beyond initial

TYPES:
  Binary (init=1)     → mutual exclusion (not reentrant — same thread deadlocks)
  Counting (init=N)   → resource pool, concurrency limiting

SEMAPHORE vs LOCK:
  Lock       → 1 thread, owned by acquirer, condition variables supported
  Semaphore  → N threads, no ownership, no condition variables
  Both       → any thread can release semaphore (key differentiator)

FOUR CORE USE CASES:
  1. Resource pool (DB connections)    → init = pool size
  2. Producer-consumer                 → emptySlots=bufferSize, filledSlots=0
  3. Concurrency limiting              → init = max concurrent threads
  4. Mutual exclusion                  → init = 1 (binary)

PRODUCER-CONSUMER PATTERN:
  Producer: emptySlots.acquire() → produce → filledSlots.release()
  Consumer: filledSlots.acquire() → consume → emptySlots.release()

BARRIER PATTERN:
  mutex (init=1)   → protects count atomically
  barrier (init=0) → all threads block; last thread releases(parties-1)

READER-WRITER PATTERN:
  mutex (init=1)   → protects readerCount atomically
  wrt (init=1)     → FIRST reader acquires (blocks writers); LAST reader releases
  Why first only:  every reader acquiring wrt → readers serialize → no concurrent reads

FAIR READER-WRITER (write starvation fix):
  queue (init=1)   → turnstile; both readers and writers acquire it
  Writer holds queue while waiting on wrt → new readers block at turnstile
  Result: writers get a turn in FIFO order; write starvation eliminated
```