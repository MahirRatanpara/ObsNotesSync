# Java Thread Synchronization — Mock Interview Notes

> Source: codeWithAryan article on Thread Synchronization Session type: Google SWE3 Mock Interview Coverage: Full Q&A recap + gaps + revision targets + CAS deep dive

---

## Table of Contents

1. [Race Conditions and Why count++ Is Unsafe](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#1-race-conditions-and-why-count-is-unsafe)
2. [Synchronized Method](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#2-synchronized-method)
3. [Synchronized Block](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#3-synchronized-block)
4. [volatile Keyword](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#4-volatile-keyword)
5. [Atomic Variables and CAS](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#5-atomic-variables-and-cas)
6. [Synchronization Traps and Edge Cases](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#6-synchronization-traps-and-edge-cases)
7. [Choosing the Right Tool](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#7-choosing-the-right-tool)
8. [Session Scorecard](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#8-session-scorecard)
9. [Revision Targets](https://claude.ai/chat/d087d7aa-7e9b-46af-b215-52eec3f5c1db#9-revision-targets)

---

## 1. Race Conditions and Why count++ Is Unsafe

### Technical Name — Race Condition

A **race condition** occurs when the outcome of a program depends on the non-deterministic ordering of thread execution. The "lost update" problem is the most common manifestation — but in an interview, always name it **race condition**.

### Why count++ Is Not Atomic

`count++` looks like one operation but is actually three:

|Step|Operation|
|---|---|
|1|**Read** — load current value from memory|
|2|**Modify** — compute value + 1|
|3|**Write** — store new value back to memory|

Any thread can interrupt another between any of these steps.

### The Failure Scenario

```
Thread-A reads count = 5
Thread-B reads count = 5   ← reads before A writes back
Thread-A writes count = 6
Thread-B writes count = 6  ← overwrites A's update — lost update!
Final count = 6 (should be 7)
```

### Q&A Recap

**Q:** What specific problem occurs with no synchronization on a shared counter? **A:** Lost update / race condition ✅ (mechanism correct, precise name needed)

### ⚠️ GAP IDENTIFIED

"Lost update" describes the symptom. **Race condition** is the technical term. Use race condition in an interview — it's the term that signals you know the concept precisely.

---

## 2. Synchronized Method

### How It Works

When a method is declared `synchronized`, the thread must acquire the monitor lock before executing and releases it when the method exits (normally or via exception).

```java
public synchronized void increment() {
    count++; // only one thread executes this at a time
}
```

### Lock Object — Instance vs Static

|Method Type|Lock Acquired On|
|---|---|
|Instance synchronized method|`this` — the current object instance|
|Static synchronized method|`ClassName.class` — the Class object|

**Critical implication:** A static synchronized method and an instance synchronized method on the same class use **different locks**. They do not block each other.

```java
public synchronized void instanceMethod() { }        // lock: this
public static synchronized void staticMethod() { }  // lock: MyClass.class
// These two can execute concurrently — different monitors!
```

### Full Example

```java
public class CounterSyncMethod {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public synchronized int getCount() { // MUST also be synchronized
        return count;
    }
}
```

### Q&A Recap

**Q:** What object is the lock acquired on for instance vs static synchronized methods? **A:** `this` for instance, `ClassName.class` for static ✅ Clean.

---

## 3. Synchronized Block

### Why Use It Over Synchronized Method

A synchronized method locks the **entire method** including any non-critical work. A synchronized block lets you lock **only the critical section**, reducing the time the lock is held.

```java
private final Object lock = new Object();

public void increment() {
    // Non-critical — runs concurrently, no lock needed
    System.out.println("Pre-processing: " + Thread.currentThread().getName());

    synchronized (lock) {
        // Critical section only — lock held here
        count++;
    }

    // Non-critical — runs concurrently again
    System.out.println("Post-processing: " + Thread.currentThread().getName());
}
```

### Performance Benefit

Reduces the **contention window** — the duration the lock is held. Threads spend less time in BLOCKED state waiting. More concurrent execution of non-critical code = better throughput.

### Why lock Must Be final

```java
private final Object lock = new Object(); // ✅ correct
private Object lock = new Object();       // ❌ dangerous
```

If `lock` is non-final, a thread could reassign it (`lock = new Object()`). Different threads would then synchronize on **different objects** — no mutual exclusion at all. Two threads could be in the critical section simultaneously.

`final` guarantees all threads always synchronize on the **same object** for the lifetime of the instance.

### Q&A Recap

**Q:** Primary reason to choose synchronized block over synchronized method? **A:** Minimizes locked code to critical section only; non-critical work runs concurrently ✅

**Q:** Why declare lock as final? **A:** Prevents reassignment — ensures all threads use the same monitor object ✅

---

## 4. volatile Keyword

### Two Guarantees

#### 1. Visibility

Without `volatile`, threads may read values from their **local CPU cache** rather than main memory. Updates by one thread may not be seen by others.

`volatile` forces all reads and writes to go directly to **main memory** — changes are immediately visible to all threads.

```java
// Without volatile — workerThread may loop forever (reads cached value)
private boolean running = true;

// With volatile — workerThread sees main thread's update immediately
private volatile boolean running = true;
```

#### 2. Ordering (Happens-Before)

Modern CPUs and JVMs can **reorder instructions** for optimization. This is invisible in single-threaded code but causes bugs in multithreaded scenarios.

`volatile` establishes a **happens-before relationship**: any write to a volatile variable happens-before any subsequent read of that variable by any thread.

**Classic example — broken singleton without volatile:**

```java
// CPU can reorder object construction:
// 1. Allocate memory
// 2. Assign reference (instance is now non-null!)  ← another thread sees non-null
// 3. Call constructor (object not fully initialized yet)

// volatile prevents this reordering
private volatile static Singleton instance;
```

### What volatile Does NOT Guarantee — Atomicity

`volatile` guarantees visibility and ordering — **not atomicity**.

`count++` is read-modify-write. Even with `volatile count`:

```
Thread-A reads count = 5  (from main memory — visibility ✅)
Thread-B reads count = 5  (from main memory — visibility ✅)
Thread-A writes count = 6
Thread-B writes count = 6  ← lost update — atomicity ❌
```

Two threads can still read the same value simultaneously before either writes back.

### When to Use volatile

|Use Case|Why volatile Works|
|---|---|
|Boolean flags (`running`, `shutdown`)|Single atomic write — no read-modify-write|
|Status variables|Same — only assigned, not incremented|
|Double-checked locking (singleton)|Prevents instruction reordering during construction|

**Rule:** Use `volatile` when you only need **visibility** and operations are **single atomic writes**. The moment you need atomicity for compound operations → use `synchronized` or `AtomicInteger`.

### Q&A Recap

**Q:** Two guarantees of volatile? **A:** Visibility and ordering ✅

**Q:** Why is volatile insufficient for count++? **A:** Doesn't guarantee atomicity — two threads can read same value simultaneously ✅

### ⚠️ GAP IDENTIFIED

**volatile ordering ≠ scheduling/mutex**. It's about **instruction reordering prevention** by the compiler/CPU. The happens-before guarantee means writes are not reordered past reads of the same variable. This is critical for singleton double-checked locking — not about thread scheduling order.

---

## 5. Atomic Variables and CAS

### What Are Atomic Variables?

Found in `java.util.concurrent.atomic` package. Provide lock-free, thread-safe operations on single variables using hardware-level atomicity.

```java
import java.util.concurrent.atomic.AtomicInteger;

private AtomicInteger counter = new AtomicInteger(0);

public void increment() {
    int newValue = counter.incrementAndGet(); // atomic — returns new value
}
```

### Key Methods

|Method|Returns|Description|
|---|---|---|
|`incrementAndGet()`|new value|Increment then return|
|`getAndIncrement()`|old value|Return then increment|
|`compareAndSet(expected, update)`|boolean|CAS — write only if current == expected|
|`get()`|current value|Read current value|

### CAS — Compare-And-Swap (Deep Dive)

#### The Mechanism

CAS is a **single atomic CPU instruction** (`CMPXCHG` on x86):

```
CAS(memoryLocation, expectedValue, newValue):
  if current value at memoryLocation == expectedValue:
      write newValue → return true
  else:
      do nothing  → return false
```

The check-and-write is indivisible — no thread can interleave between them at the hardware level.

#### How incrementAndGet() Uses CAS Internally

```java
// Conceptual implementation
public int incrementAndGet() {
    while (true) {                           // spin loop
        int current = get();                 // step 1: read current value
        int next = current + 1;             // step 2: compute new value
        if (compareAndSet(current, next)) {  // step 3: atomic CAS attempt
            return next;                     // success — return new value
        }
        // CAS failed — another thread changed the value between read and write
        // retry with fresh read
    }
}
```

#### What Happens Under Contention

```
Thread-A reads count = 5, computes next = 6
Thread-B reads count = 5, computes next = 6
Thread-A CAS: memory(5) == expected(5) → writes 6 ✅ SUCCESS
Thread-B CAS: memory(6) != expected(5) → FAILS, retries
Thread-B re-reads count = 6, computes next = 7
Thread-B CAS: memory(6) == expected(6) → writes 7 ✅ SUCCESS
Final count = 7 ✅ No lost update
```

#### Lock-Free vs Lock-Based

|Aspect|`synchronized`|`AtomicInteger` (CAS)|
|---|---|---|
|Blocking|Threads park in BLOCKED state|Threads spin and retry|
|Context switch|Yes — OS involvement|No|
|Overhead|Higher under low contention|Lower under low contention|
|High contention|Threads sleep, no CPU waste|Threads spin, burns CPU|
|Best for|Complex multi-step critical sections|Single variable operations|

#### When CAS Performs Worse

Under **very high contention**, many threads fail CAS repeatedly and spin — burning CPU cycles. In this case, `synchronized` (where blocked threads sleep) can outperform CAS. CAS shines under **low-to-moderate contention**.

### Q&A Recap

**Q:** How does AtomicInteger achieve lock-free thread safety? **A:** CAS — Compare-And-Swap. Named correctly, steps explained well ✅

---

## 6. Synchronization Traps and Edge Cases

### Trap 1 — Unsynchronized Getter

```java
public class Counter {
    private int count = 0;

    public synchronized void increment() { count++; }
    public int getCount() { return count; } // ❌ NOT synchronized
}
```

**The bug:** `synchronized` on `increment()` only prevents concurrent execution of **synchronized methods**. `getCount()` has no lock — Thread-B can call it at any time while Thread-A holds the lock in `increment()`. Thread-B may read a stale cached value.

**The fix:** Synchronize the getter too, or declare `count` as `volatile`.

```java
public synchronized int getCount() { return count; } // ✅
```

Both methods now synchronize on `this` — they share the same monitor. Thread-B's `getCount()` blocks while Thread-A is inside `increment()`.

### Q&A Recap

**Q:** Thread-A calls synchronized increment(), Thread-B calls unsynchronized getCount() simultaneously. Thread safety issue? **A (initial):** No issue — entire object is locked ❌ **A (corrected):** Yes — getCount() bypasses the monitor entirely; may read stale value ✅

### ⚠️ GAP IDENTIFIED

**Synchronized only protects synchronized methods.** Non-synchronized methods on the same object are completely unprotected — any thread can call them at any time regardless of who holds the lock. Always ask: "Is every access to shared mutable state synchronized?"

### Trap 2 — Non-final Lock Object

```java
private Object lock = new Object(); // ❌ can be reassigned

synchronized (lock) { // Thread-A acquires lock on Object@1
    lock = new Object(); // reassigned mid-execution
}
// Thread-B now synchronizes on Object@2 — different monitor!
```

Result: Two threads in critical section simultaneously. Always declare lock objects `final`.

### Trap 3 — volatile Is Not Enough for Compound Operations

```java
private volatile int count = 0;
count++; // ❌ still not thread-safe — volatile doesn't fix read-modify-write
```

Use `AtomicInteger` or `synchronized` for compound operations.

---

## 7. Choosing the Right Tool

|Scenario|Tool|Why|
|---|---|---|
|Multiple operations must be atomic together|`synchronized`|Exclusive access to entire block|
|Single variable, simple increment/decrement|`AtomicInteger`|Lock-free CAS, lower overhead|
|Boolean flag, status variable|`volatile`|Visibility only needed, single write|
|Singleton (double-checked locking)|`volatile` + `synchronized`|Ordering + atomicity both needed|
|Read-heavy, write-rare|`volatile` (if single write)|No contention on reads|
|Complex critical section with multiple variables|`synchronized`|CAS only works on one variable at a time|

### The Decision Flow

```
Need thread safety for a variable?
    │
    ▼
Is it a simple flag/status (single atomic write only)?
    YES → volatile
    NO  ▼
Is it a single numeric variable with simple +/-?
    YES → AtomicInteger / AtomicLong
    NO  ▼
Complex multi-step operation or multiple variables?
    YES → synchronized block/method
```

---

## 8. Session Scorecard

|Topic|Result|Notes|
|---|---|---|
|Race condition — correct technical name|⚠️|Said "lost update" — correct mechanism, imprecise name|
|count++ three non-atomic steps|✅|Clean|
|Lock for instance synchronized method|✅|Clean|
|Lock for static synchronized method|✅|`ClassName.class` — clean|
|Synchronized block vs method — performance|✅|Clean|
|volatile visibility guarantee|✅|Clean|
|volatile ordering / happens-before|❌ → ✅|Confused with scheduling; corrected after explanation|
|volatile insufficient for count++|✅|Good reasoning|
|AtomicInteger CAS mechanism|✅|Named and explained correctly|
|Unsynchronized getter — thread safety issue|❌ → ✅|Said object fully locked — wrong; corrected|
|final lock object — why it matters|✅|Clean|
|volatile vs synchronized — when to use each|✅|Clean|
|incrementAndGet() return value|✅|New value after increment|

---

## 9. Revision Targets

### 🔴 Priority 1 — Must Be Instinct Before the Interview

**1. Race condition — use the precise technical term**

"Lost update" = symptom. "Race condition" = the technical term.

Definition: outcome depends on non-deterministic ordering of thread execution. Always name it race condition in an interview — it signals you know the concept at the right level.

---

**2. Non-synchronized methods bypass the monitor entirely**

This is one of the most common real-world bugs and a frequent interview trap.

```java
public synchronized void write() { ... }  // protected
public int read() { return value; }        // ❌ completely unprotected
```

`synchronized` on one method does NOT protect the object from other non-synchronized method calls. Every access to shared mutable state must be synchronized — reads AND writes.

---

**3. volatile ordering = instruction reordering prevention, NOT scheduling**

`volatile` ordering prevents the **compiler/CPU from reordering instructions** around volatile variable access. It establishes a happens-before relationship — writes are visible and not reordered past reads.

This is NOT about thread execution order or mutex behavior. The key use case: double-checked locking singleton where object construction can be reordered without `volatile`.

---

### 🟡 Priority 2 — High Probability Interview Topics

**4. The three tools and their guarantees**

|Tool|Visibility|Atomicity|Ordering|
|---|---|---|---|
|`volatile`|✅|❌|✅ (happens-before)|
|`synchronized`|✅|✅|✅|
|`AtomicInteger`|✅|✅ (CAS)|✅|

**5. CAS failure and retry loop** CAS fails when another thread changes the value between read and write. The thread retries in a spin loop — no blocking, no context switch. Under high contention, spinning burns CPU — `synchronized` (sleeping threads) can be better.

**6. static vs instance synchronized — different locks** Static synchronized uses `ClassName.class`. Instance synchronized uses `this`. They don't block each other. Two threads can hold both simultaneously.

---

### 🟢 Already Solid — Just Review

- count++ three steps: read, modify, write
- synchronized block reduces contention window
- final lock object prevents monitor identity corruption
- volatile for flags/status — correct use case
- incrementAndGet() returns new value; getAndIncrement() returns old value
- AtomicInteger shines under low-to-moderate contention; synchronized better under very high contention

---

## Quick Reference Cheatsheet

```
RACE CONDITION:
  Outcome depends on non-deterministic thread ordering
  count++ = read + modify + write = NOT atomic

SYNCHRONIZED:
  Method lock  → this (instance) or ClassName.class (static)
  Block lock   → explicit object — must be final
  Unsynchronized methods bypass monitor entirely
  Both methods using same lock = mutual exclusion

VOLATILE:
  Visibility  → forces read/write to main memory (no CPU cache)
  Ordering    → prevents instruction reordering (happens-before)
  NOT atomic  → count++ still broken with volatile
  Use for     → flags, status vars, singleton double-checked locking

ATOMIC VARIABLES:
  CAS = Compare-And-Swap (hardware atomic instruction)
  Steps: read → compute → CAS(expected, new) → retry if fail
  Lock-free = no blocking, threads spin on failure
  Best for single variable simple operations
  Degrades under very high contention (spinning burns CPU)

DECISION FLOW:
  Flag/status (single write)    → volatile
  Single numeric var (+/-)      → AtomicInteger
  Complex / multi-var operation → synchronized

TOOL GUARANTEES:
  volatile      → visibility + ordering (NO atomicity)
  synchronized  → visibility + atomicity + ordering
  AtomicInteger → visibility + atomicity (CAS) + ordering
```