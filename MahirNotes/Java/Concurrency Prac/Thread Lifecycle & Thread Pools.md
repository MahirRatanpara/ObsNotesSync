> Source: codeWithAryan article on Thread Pool and Thread Lifecycle Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets

---

## Table of Contents

1. [Thread Lifecycle States](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-thread-lifecycle-states)
2. [BLOCKED vs WAITING — The Critical Distinction](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-blocked-vs-waiting--the-critical-distinction)
3. [wait() — Prerequisites and Mechanics](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-wait--prerequisites-and-mechanics)
4. [sleep() vs wait() — Lock Behavior](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-sleep-vs-wait--lock-behavior)
5. [notify() vs notifyAll()](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-notify-vs-notifyall)
6. [Thread Pools — Core Concepts](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-thread-pools--core-concepts)
7. [ThreadPoolExecutor — Parameters and Task Submission Order](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-threadpoolexecutor--parameters-and-task-submission-order)
8. [shutdown() vs shutdownNow()](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-shutdown-vs-shutdownnow)
9. [Interruption Handling — The Subtle Bug](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-interruption-handling--the-subtle-bug)
10. [newFixedThreadPool vs newCachedThreadPool](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#10-newfixedthreadpool-vs-newcachedthreadpool)
11. [Thread Starvation](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#11-thread-starvation)
12. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#12-session-scorecard)
13. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#13-revision-targets)

---

## 1. Thread Lifecycle States

### States in Order

|State|Description|
|---|---|
|**NEW**|Thread created, `start()` not yet called|
|**RUNNABLE**|`start()` called; ready and waiting for CPU scheduler to pick it up|
|**RUNNING**|CPU scheduler has allocated time; `run()` is actively executing|
|**BLOCKED**|Waiting to acquire a monitor lock held by another thread|
|**WAITING**|Indefinitely waiting for another thread's explicit action|
|**TIMED_WAITING**|Waiting for a specified duration; auto-returns after timeout|
|**TERMINATED**|`run()` has exited (normally or via exception); cannot be restarted|

### Key Point — RUNNABLE vs RUNNING

Java's `Thread.State` enum only exposes `RUNNABLE` for both states, but conceptually they are distinct:

- **RUNNABLE** = ready, waiting for CPU
- **RUNNING** = actively executing on CPU

This distinction matters when reasoning about thread behavior even if the JVM doesn't surface it separately.

### Q&A Recap

**Q:** After calling `start()`, does the thread immediately execute code on the CPU? **A:** No. It moves to RUNNABLE and waits for the CPU scheduler to pick it up. **Result:** ✅

---

## 2. BLOCKED vs WAITING — The Critical Distinction

### The Rule

|State|Caused By|Waiting For|
|---|---|---|
|**BLOCKED**|Trying to enter a `synchronized` block/method locked by another thread|Monitor lock to be released|
|**WAITING**|Voluntarily called `wait()`, `join()`, or `LockSupport.park()`|Explicit `notify()` / `notifyAll()` / thread completion|

### The Trap

> "Thread is waiting" does **not** automatically mean WAITING state. If it's waiting for a **lock**, it's BLOCKED. If it voluntarily **gave up** the lock and is waiting for a signal, it's WAITING.

### Q&A Recap

**Q:** Thread-A holds a `synchronized` lock. Thread-B tries to enter the same block. What state is Thread-B in? **A (initial):** WAITING ❌ **A (corrected):** BLOCKED ✅ — waiting to _acquire_ the monitor lock, not waiting for a signal.

### ⚠️ GAP IDENTIFIED

You initially said WAITING instead of BLOCKED. This is one of the most common interview traps on this topic. Drill the distinction until it's instinct.

---

## 3. wait() — Prerequisites and Mechanics

### The Rule

Before calling `wait()` on an object, the thread **must** hold the monitor lock on that object (i.e. be inside a `synchronized(object)` block).

If `wait()` is called without holding the lock → `IllegalMonitorStateException` is thrown.

```java
synchronized(lock) {
    lock.wait(); // legal — we hold the monitor
}

lock.wait(); // ILLEGAL — throws IllegalMonitorStateException
```

### What Happens When wait() Is Called

1. Thread releases the monitor lock immediately
2. Thread moves to WAITING state
3. Other threads can now acquire the lock
4. Thread stays in WAITING until `notify()` / `notifyAll()` is called on the same object

### Methods That Trigger WAITING (Pure — No Timeout)

1. `Object.wait()`
2. `Thread.join()`
3. `LockSupport.park()`

### Q&A Recap

**Q:** What must a thread hold before calling `wait()`? What exception if it doesn't? **A:** Must hold the monitor lock. `IllegalMonitorStateException` if not. **Result:** ⚠️ — needed prompting to reach the full answer.

### ⚠️ GAP IDENTIFIED

You knew `wait()` releases the lock but didn't volunteer the prerequisite (must hold monitor) or the exception name upfront. In a real interview, stating the exception name proactively shows depth. Know: **`IllegalMonitorStateException`** cold.

---

## 4. sleep() vs wait() — Lock Behavior

### The Single Most Important Distinction

|Method|Releases Lock?|Requires Monitor?|State Entered|
|---|---|---|---|
|`Thread.sleep(ms)`|❌ No — holds all locks|❌ No|TIMED_WAITING|
|`Object.wait()`|✅ Yes — releases monitor|✅ Yes|WAITING|
|`Object.wait(ms)`|✅ Yes — releases monitor|✅ Yes|TIMED_WAITING|

### The Trap

`wait(timeout)` behaves like `wait()` for lock purposes — it **releases** the lock. The timeout just means it can wake up automatically without `notify()`. Do not confuse it with `sleep()`.

### Practical Consequence

```java
// Thread-A sleeping — Thread-B CANNOT enter this block
synchronized(lock) {
    Thread.sleep(2000); // lock is HELD during sleep
}

// Thread-A waiting — Thread-B CAN enter this block
synchronized(lock) {
    lock.wait(2000); // lock is RELEASED during wait
}
```

### Methods That Trigger TIMED_WAITING

- `Thread.sleep(timeout)`
- `Object.wait(timeout)`
- `Thread.join(timeout)`
- `LockSupport.parkNanos()` / `LockSupport.parkUntil()`

### Q&A Recap

**Q:** Does `wait(timeout)` release the lock? **A (initial):** No ❌ **A (corrected after explanation):** Yes ✅ **Result:** ❌ → ✅ after correction

### ⚠️ GAP IDENTIFIED

This is a high-frequency interview trap. You got it wrong initially. The fix: associate `wait` (with or without timeout) **always** with lock release. Associate `sleep` **always** with lock retention. No exceptions.

---

## 5. notify() vs notifyAll()

### Behavior

|Method|Wakes Up|Woken Threads Move To|
|---|---|---|
|`notify()`|One arbitrarily chosen waiting thread|**BLOCKED** (must re-acquire lock)|
|`notifyAll()`|All threads waiting on the object's monitor|**BLOCKED** (all compete for lock)|

### The Trap — notifyAll() → BLOCKED, not RUNNABLE

After `notifyAll()`, all woken threads do **not** go to RUNNABLE. They go to **BLOCKED** because only one can hold the monitor at a time. The winner acquires the lock and moves to RUNNABLE. The rest stay BLOCKED until the lock is released.

```
notifyAll() called
    → All waiting threads wake up
    → All move to BLOCKED (competing for monitor)
    → One wins the lock → RUNNABLE → RUNNING
    → Others stay BLOCKED until lock is released again
```

### Q&A Recap

**Q:** After `notifyAll()`, what state do the woken threads move to? **A:** RUNNABLE ❌ **Correct answer:** BLOCKED ✅

### ⚠️ GAP IDENTIFIED

This was missed in rapid-fire. The intuition "they wake up so they're RUNNABLE" is wrong — they still need to compete for the lock first. This is a classic interview trap. Commit to: **notifyAll() → BLOCKED**.

---

## 6. Thread Pools — Core Concepts

### What Is a Thread Pool?

A managed collection of reusable threads that execute submitted tasks. Threads are not destroyed after task completion — they return to the pool and wait for the next task.

### Benefits

- **Resource Management** — limits total thread count, prevents system overload
- **Performance** — eliminates overhead of creating/destroying threads per task
- **Predictability** — controlled scheduling and thread creation
- **Task Management** — queuing, monitoring, rejection policies built-in

### Basic Usage

```java
ExecutorService executor = Executors.newFixedThreadPool(3);

for (int i = 1; i <= 5; i++) {
    executor.submit(new WorkerThread(i));
}

executor.shutdown();
```

### Thread State in a Pool

- Idle thread in pool → RUNNABLE (waiting for next task)
- Task assigned → RUNNING
- Task blocks on I/O or lock → BLOCKED / WAITING / TIMED_WAITING
- Task completes → thread returns to pool, back to RUNNABLE

---

## 7. ThreadPoolExecutor — Parameters and Task Submission Order

### Constructor Parameters

```java
new ThreadPoolExecutor(
    int corePoolSize,        // Min threads kept alive always
    int maximumPoolSize,     // Max threads that can ever exist
    long keepAliveTime,      // How long non-core idle threads live
    TimeUnit unit,           // Unit for keepAliveTime
    BlockingQueue<> queue    // Queue type and capacity for waiting tasks
)
```

### keepAliveTime — Precise Meaning

Applies **only to non-core threads** (threads created above corePoolSize). If a non-core thread is idle for this duration with no new tasks, it is **terminated**, shrinking the pool back toward core size.

Core threads by default stay alive indefinitely.

### Task Submission Order — CRITICAL

```
New task submitted
    │
    ▼
Core threads available?
    YES → assign to core thread
    NO  ▼
Queue not full?
    YES → add to queue
    NO  ▼
Non-core threads available (< maxPoolSize)?
    YES → spawn new thread, assign task
    NO  ▼
Apply Rejection Policy (e.g. AbortPolicy → RejectedExecutionException)
```

### Worked Example (core=2, max=4, queue=2, 6 tasks)

|Task|Goes To|
|---|---|
|Task 1|Core thread 1|
|Task 2|Core thread 2|
|Task 3|Queue slot 1|
|Task 4|Queue slot 2 (queue full)|
|Task 5|New non-core thread 3|
|Task 6|New non-core thread 4|
|Task 7|**Rejected** (AbortPolicy → `RejectedExecutionException`)|

### Q&A Recap

**Q:** Walk through 6 tasks submitted to core=2, max=4, queue=2. **A:** Minor ordering confusion initially (said tasks 5/6 sit in queue) ⚠️ → corrected to perfect sequence in rapid-fire ✅

### Queue Size Tradeoffs

|Queue Size|Effect|
|---|---|
|Too small|Tasks rejected frequently; more threads spawned|
|Too large|Tasks wait longer; fewer extra threads; lower CPU usage|
|Balanced|Best throughput with controlled memory usage|

---

## 8. shutdown() vs shutdownNow()

### Precise Behavioral Difference

|Aspect|`shutdown()`|`shutdownNow()`|
|---|---|---|
|Currently executing tasks|Continue to completion|Interrupted immediately|
|Tasks in queue|**Also complete** (graceful drain)|**Never executed** — returned as `List<Runnable>`|
|New task submissions|Rejected|Rejected|
|Return value|void|`List<Runnable>` (unstarted tasks)|

### The Trap on shutdown()

> `shutdown()` does **not** abandon queued tasks. It drains the queue gracefully. Only `shutdownNow()` abandons queued tasks.

### awaitTermination()

```java
boolean completed = executor.awaitTermination(10, TimeUnit.SECONDS);
```

- Returns `true` → all tasks completed within timeout, pool fully terminated
- Returns `false` → timeout elapsed, threads may still be running → typically call `shutdownNow()` next

**Return type: `boolean`** (not `List<Runnable>` — that's `shutdownNow()`)

### Typical Graceful Shutdown Pattern

```java
executor.shutdown();
try {
    if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
        executor.shutdownNow();
    }
} catch (InterruptedException e) {
    executor.shutdownNow();
}
```

### Q&A Recap

**Q:** Behavioral difference between `shutdown()` and `shutdownNow()`? **A:** Got `shutdownNow()` correct. Said queued tasks "would not get executed" after `shutdown()` ❌ — corrected after explanation ✅

**Q:** `shutdownNow()` return type? **A:** boolean ❌ **Correct:** `List<Runnable>` ✅

### ⚠️ GAP IDENTIFIED (TWO GAPS)

1. **`shutdown()` drains the queue** — it does not abandon it. Only `shutdownNow()` abandons it.
2. **`shutdownNow()` returns `List<Runnable>`** — not boolean. `awaitTermination()` returns boolean. Do not mix these up.

---

## 9. Interruption Handling — The Subtle Bug

### The Bug

```java
// BUGGY VERSION
public void run() {
    try {
        while (!Thread.currentThread().isInterrupted()) {
            System.out.println("Checking for updates...");
            Thread.sleep(2000);
        }
    } catch (InterruptedException e) {
        // BUG: interrupt flag is now CLEARED
        System.out.println("Thread interrupted, shutting down gracefully.");
    }
}
```

### Why It's a Bug

When `Thread.sleep()` throws `InterruptedException`, Java **clears the interrupt flag** as part of throwing the exception. If execution somehow continues after the catch, `isInterrupted()` returns `false` and the loop condition doesn't terminate correctly.

### The Fix

```java
// CORRECT VERSION
public void run() {
    try {
        while (!Thread.currentThread().isInterrupted()) {
            System.out.println("Checking for updates...");
            Thread.sleep(2000);
        }
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt(); // ← restore the interrupt flag
        System.out.println("Thread interrupted, shutting down gracefully.");
    }
}
```

### The Rule

> If you catch `InterruptedException` and do not re-throw it, you **must** call `Thread.currentThread().interrupt()` to restore the interrupt status.

### Q&A Recap

**Q:** Spot the bug in the interruption handling code. **A:** Couldn't spot it initially, but reasoned to the fix correctly when guided. ✅

---

## 10. newFixedThreadPool vs newCachedThreadPool

### Comparison

|Aspect|`newFixedThreadPool(n)`|`newCachedThreadPool()`|
|---|---|---|
|Thread count|Fixed — always n threads|Dynamic — grows as needed|
|Idle thread cleanup|Threads live forever|Idle threads terminated after ~60s|
|Best for|CPU-bound tasks|I/O-bound, short-lived tasks|
|Risk|Underutilization if threads block on I/O|Unbounded thread creation under extreme load|

### CPU-Bound Tasks → newFixedThreadPool

- Tasks spend most time on CPU (image processing, complex calculations)
- Optimal thread count = number of CPU cores
- Too many threads → excessive context switching → slower

```java
int cores = Runtime.getRuntime().availableProcessors();
ExecutorService pool = Executors.newFixedThreadPool(cores);
```

### I/O-Bound Tasks → newCachedThreadPool

- Tasks spend most time waiting (network calls, DB queries, file I/O)
- Threads blocked on I/O are idle — waste of fixed pool slots
- Cached pool spins up new threads to keep CPU busy while others wait
- Idle threads reclaimed automatically

```java
ExecutorService pool = Executors.newCachedThreadPool();
```

### Why newCachedThreadPool Wins for I/O

- Threads blocked on I/O don't consume useful CPU time
- More concurrent threads = more I/O operations in flight simultaneously
- Auto-reclaims idle threads when load drops

### The Risk to Always Mention

`newCachedThreadPool()` has **no upper bound** on thread count. Under extreme load it can create thousands of threads, exhausting heap memory or causing JVM crash. Always flag this tradeoff in interviews.

### Q&A Recap

**Q:** Real-time stock price updates — thousands of short-lived network-waiting tasks. Which pool? **A:** `newCachedThreadPool()` ✅. Correctly identified the underutilization risk of fixed pool ✅. Correctly identified unbounded thread creation risk of cached pool ✅.

---

## 11. Thread Starvation

### Definition

Thread starvation occurs when threads are unable to gain regular access to shared resources and make no meaningful progress — typically because higher-priority threads or unfair scheduling continuously win access.

### How Thread Pools Help Prevent It

- **Controlled concurrency** — fixed thread count prevents resource oversaturation
- **FIFO queue scheduling** — tasks executed in order, not by priority
- **Fair access** — all submitted tasks get a turn regardless of thread priority

### Without Pool (Potential Starvation)

- Threads created with different priorities
- OS scheduler favors high-priority threads
- Low-priority threads may never get CPU time

### With Pool (Fair Scheduling)

- `LinkedBlockingQueue` processes tasks in FIFO order
- All tasks get scheduled regardless of the "priority" they were submitted with
- Balanced completion across all task types

### Q&A Recap

**Q:** What is thread starvation? **A:** Threads indefinitely waiting for a resource to be allocated ✅

---

## 12. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|Thread lifecycle states (NEW, RUNNABLE, RUNNING)|✅|Clean|
|BLOCKED vs WAITING distinction|⚠️|Confused initially, self-corrected|
|`wait()` prerequisites + `IllegalMonitorStateException`|⚠️|Needed prompting|
|`sleep()` vs `wait()` lock behavior|❌ → ✅|Got it wrong, corrected after explanation|
|`notify()` vs `notifyAll()`|✅|Clean|
|`notifyAll()` → BLOCKED not RUNNABLE|❌|Missed in rapid-fire|
|ThreadPoolExecutor 5 parameters|✅|Clean|
|Core → Queue → Non-core → Reject ordering|✅|Minor confusion early, perfect in rapid-fire|
|`shutdown()` queue behavior|❌ → ✅|Said queue abandoned — wrong, corrected|
|`shutdownNow()` return type|❌|Said boolean, correct is `List<Runnable>`|
|Interruption handling bug|✅|Reasoned to it well when guided|
|`newFixedThreadPool` vs `newCachedThreadPool`|✅|Clean with tradeoffs|
|Thread starvation|✅|Clean|
|`LockSupport.park()` as WAITING trigger|⚠️|Missed the third method|

---

## 13. Revision Targets

### 🔴 Priority 1 — Must Be Instinct Before the Interview

**1. notifyAll() → BLOCKED, not RUNNABLE**

The intuition "they wake up so they must be RUNNABLE" is wrong. All woken threads still need to compete for the monitor lock. They land in BLOCKED. Only the one that wins the lock moves to RUNNABLE.

Drill this: _notifyAll() → all threads → BLOCKED → one wins lock → RUNNABLE_

---

**2. shutdownNow() returns List\<Runnable\>**

- `shutdownNow()` → `List<Runnable>` (tasks that never started)
- `awaitTermination(timeout, unit)` → `boolean` (did everything finish in time?)
- `shutdown()` → `void` (graceful drain, no return)

Also remember: `shutdown()` **does not abandon the queue**. It drains it. Only `shutdownNow()` abandons queued tasks.

**3. sleep() holds locks. wait() releases locks. Always.**

|Method|Lock behavior|
|---|---|
|`Thread.sleep(ms)`|HOLDS all locks|
|`Object.wait()`|RELEASES the monitor|
|`Object.wait(ms)`|RELEASES the monitor (same as wait())|

No exceptions. No edge cases. Burn this in.

---

### 🟡 Priority 2 — High Probability Interview Topics

**4. All Three WAITING Triggers**

Know all three cold:

- `Object.wait()`
- `Thread.join()`
- `LockSupport.park()`

---

**5. IllegalMonitorStateException**

Calling `wait()` without holding the monitor lock throws `IllegalMonitorStateException`. State this proactively — don't wait to be asked.

---

**6. Interrupt Flag Restoration**

When `InterruptedException` is caught, the interrupt flag is **cleared**. Always call `Thread.currentThread().interrupt()` inside the catch if you're not re-throwing. This is a standard code review catch at Google level.

---

### 🟢 Priority 3 — Already Solid, Just Review

- Thread lifecycle state transitions
- ThreadPoolExecutor task submission ordering (core → queue → non-core → reject)
- `newFixedThreadPool` vs `newCachedThreadPool` tradeoffs including the unbounded thread risk
- Thread starvation definition and how pools mitigate it
- `notify()` vs `notifyAll()` semantics

---

## Quick Reference Cheatsheet

```
THREAD STATES:
NEW → RUNNABLE → (RUNNING) → TERMINATED
                           ↕
                        BLOCKED (waiting for lock)
                        WAITING (wait/join/park)
                        TIMED_WAITING (sleep/wait(ms)/join(ms))

LOCK BEHAVIOR:
sleep()      → HOLDS lock    → TIMED_WAITING
wait()       → RELEASES lock → WAITING
wait(ms)     → RELEASES lock → TIMED_WAITING

NOTIFY:
notify()    → wakes 1 thread  → BLOCKED
notifyAll() → wakes all       → BLOCKED (all compete for lock)

THREAD POOL SUBMISSION ORDER:
core threads → queue → non-core threads → rejection policy

SHUTDOWN:
shutdown()     → drains queue + running tasks → void
shutdownNow()  → interrupts running, abandons queue → List<Runnable>
awaitTermination(t, unit) → boolean
```