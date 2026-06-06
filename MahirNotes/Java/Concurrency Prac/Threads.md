# Java Concurrency — Quick Revision Notes

## Google SWE3 Interview Prep

---

## 1. Core Concepts

### Thread vs Process

||Process|Thread|
|---|---|---|
|Memory|Separate memory space|Shared memory (same process)|
|Cost|Heavy — expensive to create|Lightweight — cheap to create|
|Communication|IPC (pipes, sockets, queues)|Direct shared memory|
|Fault isolation|Crash doesn't affect others|Crash can kill entire process|
|Use when|Strong isolation needed|Tasks share data, need responsiveness|

---

## 2. Creating Threads — 3 Ways

### A. Extending Thread

```java
class MyThread extends Thread {
    public void run() { /* task */ }
}
new MyThread().start();
```

**Limitation:** Can't extend any other class (Java single inheritance).

### B. Implementing Runnable ✅ Preferred

```java
class MyTask implements Runnable {
    public void run() { /* task */ }
}
Thread t = new Thread(new MyTask());
t.start();
```

**Advantage:** Separates task from thread. Same Runnable reusable across multiple threads.

### C. Implementing Callable (when you need a return value)

```java
class MyTask implements Callable<String> {
    public String call() throws Exception { return "result"; }
}
ExecutorService exec = Executors.newFixedThreadPool(2);
Future<String> future = exec.submit(new MyTask());
String result = future.get(); // blocks until done
```

---

## 3. run() vs start() — CRITICAL

||`t.run()`|`t.start()`|
|---|---|---|
|Threads created|0 (runs in current thread)|1 new thread|
|JVM thread stack|Not allocated|New stack allocated|
|Thread state|No state change|NEW → RUNNABLE|
|Use this?|❌ Never for concurrency|✅ Always|

**Key:** `start()` allocates a new thread stack in JVM, transitions state NEW → RUNNABLE, and hands off to the OS thread scheduler. The scheduler decides _when_ it actually runs.

---

## 4. Thread Lifecycle (One-Directional)

```
NEW → RUNNABLE → RUNNING → TERMINATED
                    ↕
                 WAITING/BLOCKED
```

**Critical:** Once TERMINATED, a Thread object cannot be restarted. Calling `start()` again throws `IllegalThreadStateException`.  
**Reason:** `threadStatus` field inside Thread is one-directional. The underlying OS-level native thread is dead — nothing to restart.  
**Fix:** Reuse the `Runnable`, wrap it in a fresh `Thread` object.

---

## 5. Object Monitor Lock — How synchronized Works

**Every Java object has a built-in monitor lock (intrinsic lock).**

```java
synchronized void methodA() { }  // locks on `this`
synchronized void methodB() { }  // SAME lock as methodA!
```

This is sugar for:

```java
void methodA() { synchronized(this) { } }
void methodB() { synchronized(this) { } }
```

Think of it as **one key per object**. All synchronized methods on the same object compete for the same key. If Thread A is inside `methodA()`, Thread B cannot enter `methodB()` either.

For finer control, use explicit lock objects:

```java
private final Object lockA = new Object();
private final Object lockB = new Object();
synchronized(lockA) { } // independent of lockB
```

---

## 6. Race Conditions — The Lost Update Problem

`count++` looks atomic but is **3 steps**: READ → INCREMENT → WRITE

```
t1 reads count = 500
t2 reads count = 500   ← reads before t1 writes back
t1 writes count = 501
t2 writes count = 501  ← t1's increment LOST
```

Result: non-deterministic value between 1000–2000, never reliably 2000.

### Fixes and Tradeoffs

|Approach|Fixes|Tradeoff|
|---|---|---|
|`synchronized`|Atomicity + Visibility|Lock contention — threads block, serial execution|
|`volatile`|Visibility ONLY|❌ NOT atomic — never use for `count++`|
|`AtomicInteger`|Atomicity + Visibility|CAS thrashing under high contention — burns CPU|

### volatile — What It Does and Doesn't Do

- ✅ Prevents stale cache reads — all reads go to main memory
- ✅ Prevents JVM instruction reordering (happens-before guarantee)
- ❌ Does NOT make compound operations atomic

**When volatile IS enough:** Single writer, multiple readers. Classic use case: double-checked locking for Singleton.

```java
private static volatile Singleton instance;

public static Singleton getInstance() {
    if (instance == null) {
        synchronized (Singleton.class) {
            if (instance == null) {
                instance = new Singleton(); // volatile prevents reordering of init steps
            }
        }
    }
    return instance;
}
```

### AtomicInteger — How CAS Works

```java
AtomicInteger count = new AtomicInteger(0);
count.incrementAndGet(); // thread-safe, no lock
```

CAS mechanism (3 steps):

1. Read current value (e.g. 500)
2. Compute new value (501)
3. **Compare-and-Swap:** "Write 501 ONLY IF current value is still 500. If not, retry from step 1."

In the lost-update scenario:

- t1: reads 500, CAS succeeds → writes 501 ✅
- t2: reads 500, CAS checks → value is now 501 ≠ 500 → **retry**
- t2: re-reads 501, CAS succeeds → writes 502 ✅

No lost update. No lock. CPU-level atomic instruction.

---

## 7. sleep() vs wait() — CRITICAL DISTINCTION

||`Thread.sleep(ms)`|`object.wait()`|
|---|---|---|
|Defined on|`Thread` class|`Object` class|
|Releases lock?|❌ NO — holds lock|✅ YES — releases object's monitor|
|Woken by|Timer expiry|`notify()` / `notifyAll()` / `interrupt()`|
|Requires synchronized?|No|Yes — must own the lock|
|Purpose|Pause the thread|Wait for a condition to be met|

**Why the distinction makes sense architecturally:**

- `sleep` is about the thread itself pausing — nothing to do with any shared object
- `wait` is about coordination between threads via an object's monitor — lives on `Object` because any object can be a monitor

### The Classic Deadlock Pattern (sleep inside synchronized)

```java
// ❌ DEADLOCK — consumer holds lock while sleeping, producer can never enter
synchronized void consume() throws InterruptedException {
    while (queue.isEmpty()) {
        Thread.sleep(1000); // holds the lock! producer blocked forever
    }
    process(queue.poll());
}
synchronized void produce(Order o) {
    queue.add(o); // can never run — consumer holds the lock
}
```

```java
// ✅ CORRECT — Producer-Consumer with wait/notify
synchronized void consume() throws InterruptedException {
    while (queue.isEmpty()) {
        wait(); // releases lock — producer can now enter produce()
    }
    process(queue.poll());
}
synchronized void produce(Order o) {
    queue.add(o);
    notify(); // wake up waiting consumer
}
```

**Why `while` and not `if` around wait():** Spurious wakeups — a thread can wake up without being notified. Always re-check the condition.

---

## 8. notify() vs notifyAll()

||`notify()`|`notifyAll()`|
|---|---|---|
|Wakes up|1 random waiting thread|All waiting threads|
|Risk|Wakes wrong thread → missed notification|All wake up, compete for lock, most go back to wait|
|Performance|Better when all waiters are identical|Worse — more contention|
|Safety|Dangerous with multiple condition types|Safe — always correct|

**Danger of notify():** If multiple threads wait for different conditions on the same object, `notify()` might wake a thread whose condition isn't met — it goes back to `wait()`, and the thread that actually needed waking never gets notified. Use `notifyAll()` unless you're certain all waiters are identical.

---

## 9. interrupt() on a Waiting Thread

When `interrupt()` is called on a thread inside `wait()`:

1. Thread **immediately wakes up**
2. Thread **reacquires the lock**
3. `InterruptedException` is thrown **right there inside wait()**

It is NOT deferred. This is why every `wait()` call forces `InterruptedException` handling.

---

## 10. Callable and Future — Exception Handling

```java
Future<String> future = executor.submit(callable);
String result = future.get(); // blocks — use timeout in production!
future.get(5, TimeUnit.SECONDS); // ✅ production-grade
```

### Exception Flow Across Thread Boundaries

When `call()` throws an exception:

1. Exception is **caught and stored inside the Future object**
2. Does NOT propagate immediately
3. On `future.get()` → wrapped in `ExecutionException` and thrown

```java
try {
    String result = future.get();
} catch (ExecutionException e) {
    Throwable actual = e.getCause(); // original exception from call()
}
```

**Key insight:** Exceptions are transported across thread boundaries via the Future — serialized in, unwrapped on get().

### Danger of future.get() without timeout

In production, if the Callable hangs (e.g., DB connection gone), `future.get()` blocks forever → thread pool exhaustion → cascading failures. Always use `future.get(timeout, unit)`.

---

## 11. Exception Handling in Runnable

`Runnable.run()` cannot throw checked exceptions. Uncaught exceptions in `run()` silently terminate the thread — main thread has no idea.

**Fix: UncaughtExceptionHandler**

```java
Thread t = new Thread(myRunnable);
t.setUncaughtExceptionHandler((thread, exception) -> {
    log.error("Thread " + thread.getName() + " threw: " + exception.getMessage());
});
t.start();

// Or globally for all threads:
Thread.setDefaultUncaughtExceptionHandler((thread, exception) -> {
    // catches uncaught exceptions from ANY thread
});
```

---

## 12. Full Exception Handling Comparison

|Mechanism|Exception Behavior|
|---|---|
|`Thread` / `Runnable`|Swallowed silently unless UncaughtExceptionHandler set|
|`Callable` / `Future`|Stored in Future, wrapped in ExecutionException on get()|
|`synchronized` blocks|Propagates normally — lock auto-released|

---

## 13. Interview Q&A — Quick Fire

**Q: What does start() do that run() doesn't?**  
A: Allocates a new thread stack in JVM, transitions state NEW→RUNNABLE, hands off to OS scheduler. `run()` is just a method call in the current thread.

**Q: Why can't you call start() twice on the same Thread?**  
A: `threadStatus` is one-directional. Once TERMINATED, the native OS thread is dead. JVM protects this via `threadStatus` check — anything other than NEW throws `IllegalThreadStateException`.

**Q: Will this print 2000?**

```java
// Two threads sharing same Counter (count++) 
```

A: No. `count++` is READ-INCREMENT-WRITE — three non-atomic steps. Race condition causes lost updates. Result is non-deterministic between 1000–2000.

**Q: What's wrong with volatile for count++?**  
A: `volatile` guarantees visibility (no stale reads) but NOT atomicity. `count++` still has 3 steps — two threads can both read the same value before either writes back.

**Q: sleep() vs wait() — key difference?**  
A: `sleep` holds the lock. `wait` releases the object's monitor lock, allowing other threads in. `sleep` is on Thread class, `wait` is on Object class.

**Q: What happens when interrupt() is called on a thread in wait()?**  
A: Immediately wakes up, reacquires lock, throws `InterruptedException` right inside the `wait()` call. Not deferred.

**Q: Callable throws exception inside call() — what does future.get() return?**  
A: Throws `ExecutionException`. Original exception is wrapped inside — retrieve with `e.getCause()`.

**Q: How do you catch exceptions from a Runnable in the main thread?**  
A: Set an `UncaughtExceptionHandler` on the thread. Without it, exceptions silently terminate the thread.

---

## 14. Things to Remember — Traps & Gotchas

1. **`t.run()` ≠ `t.start()`** — run() doesn't create a new thread. Ever.
2. **`volatile` ≠ atomic** — fixes visibility, not compound operations.
3. **`synchronized` locks the object, not the method** — all synchronized methods on the same object share one lock.
4. **`sleep` inside `synchronized` = potential deadlock** — always use `wait` for condition waiting.
5. **Always `while` not `if` around `wait()`** — spurious wakeups are real.
6. **`notify()` can wake the wrong thread** — prefer `notifyAll()` unless all waiters are identical.
7. **`future.get()` without timeout = production bomb** — always specify a timeout.
8. **`ExecutionException` wraps the real cause** — always call `getCause()`.
9. **Thread lifecycle is one-directional** — can't restart a terminated thread; reuse Runnable instead.
10. **`interrupt()` on `wait()` is immediate** — throws `InterruptedException` right there, not deferred.