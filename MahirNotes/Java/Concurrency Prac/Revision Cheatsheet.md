
> One-pass revision. Patterns first, then full API syntax for Executors / Callable / Future / CompletableFuture, then the gotchas you actually tripped on.

---

## 0. Your two recurring failure modes (read this first)

1. **Parked threads need waking before they can exit.** A thread blocked in `wait()` / `await()` / `acquire()` will _never_ re-check its termination guard until something signals/releases it. Always ask: "when the work is done, who wakes the thread that's still parked?" Prefer **loop the exact count** over **shared counter + break** when you can.
2. **API slips.** `Executors` (factory) ≠ `ExecutorService` (interface). `lock()/unlock()` (ReentrantLock) ≠ `acquire()/release()` (Semaphore). Write each from memory once before the round.

---

## 1. Thread creation — 3 ways

```java
// A. extend Thread  (loses single-inheritance slot — avoid)
class T extends Thread { public void run() { /* task */ } }
new T().start();

// B. implement Runnable  ✅ preferred (no return value)
Runnable r = () -> { /* task */ };
new Thread(r).start();

// C. implement Callable  ✅ when you need a RETURN VALUE or to throw checked exceptions
Callable<String> c = () -> { return "result"; };   // submit via ExecutorService
```

**`start()` vs `run()`:** `start()` allocates a new OS thread stack, NEW→RUNNABLE, hands to scheduler. `run()` is just a method call on the current thread — **zero new threads**.

**Lifecycle is one-directional:** NEW → RUNNABLE → (RUNNING ⇄ WAITING/BLOCKED) → TERMINATED. Calling `start()` twice → `IllegalThreadStateException`. Reuse the `Runnable` in a fresh `Thread`.

---

## 2. The 5 coordination patterns we drilled

### 2.1 Two-thread alternation (intrinsic lock)

_Odd/Even printer. `for` counts iterations, `while` guards the turn._

```java
synchronized (lock) {
    while (current <= max) {
        if (current % 2 == 1) { print(current++); lock.notifyAll(); }
        else                  { lock.wait(); }   // else-branch, so it re-checks & exits cleanly
    }
}
```

- `while` not `if` around `wait()` → spurious wakeups.
- `lock.wait()/notifyAll()` must be called on the SAME object you `synchronized` on, else `IllegalMonitorStateException`.

### 2.2 Bounded blocking queue (producer/consumer)

_Two conditions on one monitor → use `notifyAll()`._

```java
void enqueue(int x) throws InterruptedException {
    synchronized (lock) {
        while (queue.size() >= capacity) lock.wait();
        queue.offer(x);
        lock.notifyAll();              // notify(), not notifyAll(), can wake the WRONG class of waiter → stall
    }
}
int dequeue() throws InterruptedException {
    synchronized (lock) {
        while (queue.isEmpty()) lock.wait();
        int x = queue.poll();
        lock.notifyAll();
        return x;
    }
}
```

### 2.3 ReentrantLock + Condition (the efficient upgrade)

_Two conditions → `signal()` only the right waiter. No wasted wakeups._

```java
private final ReentrantLock lock = new ReentrantLock();
private final Condition notFull  = lock.newCondition();
private final Condition notEmpty = lock.newCondition();

void enqueue(int x) throws InterruptedException {
    lock.lock();
    try {
        while (queue.size() >= capacity) notFull.await();
        queue.offer(x);
        notEmpty.signal();             // wakes ONLY a consumer
    } finally { lock.unlock(); }       // unlock in finally — NOT auto-released on exception
}
```

- `lock()/unlock()` — **NOT** `acquire()/release()` (that's Semaphore).
- `unlock()` in `finally` is mandatory; forget it and an exception leaks the lock → deadlock.
- still `while` around `await()`.

### 2.4 Semaphore as a GATE + RENDEZVOUS (H2O)

_`acquire(n)` makes a semaphore a "wait for N events" rendezvous. One method call = one atom; the harness owns the repetition._

```java
private final Semaphore hSem = new Semaphore(2);   // at most 2 H at a time
private final Semaphore oSem = new Semaphore(0);

void hydrogen(Runnable releaseH) throws InterruptedException {
    hSem.acquire();        // one atom, one permit — NO loop inside
    releaseH.run();
    oSem.release();        // signal: one H placed
}
void oxygen(Runnable releaseO) throws InterruptedException {
    oSem.acquire(2);       // BLOCK until both H placed  ← the rendezvous
    releaseO.run();
    hSem.release(2);       // reset gate for next molecule (only AFTER O prints)
}
```

### 2.5 Semaphore token-ring (Zero-Even-Odd, 3-way)

_One thread per role; loop lives INSIDE. Token cycles through the `zero` hub._

```java
private final Semaphore zeroSem = new Semaphore(1);   // only zero may start
private final Semaphore oddSem  = new Semaphore(0);
private final Semaphore evenSem = new Semaphore(0);

void zero(IntConsumer p) throws InterruptedException {
    for (int i = 1; i <= n; i++) {
        zeroSem.acquire();
        p.accept(0);
        if (i % 2 == 1) oddSem.release(); else evenSem.release();
    }
}
void odd(IntConsumer p) throws InterruptedException {
    for (int i = 1; i <= n; i += 2) { oddSem.acquire(); p.accept(i); zeroSem.release(); }
}
void even(IntConsumer p) throws InterruptedException {
    for (int i = 2; i <= n; i += 2) { evenSem.acquire(); p.accept(i); zeroSem.release(); }
}
```

> **Contract tell:** `Runnable` param (no args) → fire once per call, loop in the harness (H2O). `IntConsumer` param (called with values) → loop inside the method (Zero-Even-Odd). **Read the signature.**

---

## 3. ExecutorService + Callable + Future — full syntax

### Creating pools (`Executors` factory)

```java
ExecutorService fixed  = Executors.newFixedThreadPool(4);      // bounded, CPU-bound work
ExecutorService cached = Executors.newCachedThreadPool();      // grows/shrinks, short async tasks
ExecutorService single = Executors.newSingleThreadExecutor();  // serial, ordered
ScheduledExecutorService sched = Executors.newScheduledThreadPool(2);
// Java 21+: Executors.newVirtualThreadPerTaskExecutor()       // virtual threads
```

### Submitting work

```java
Future<Long> f   = pool.submit(callable);     // Callable → Future<T>
Future<?>    f2  = pool.submit(runnable);      // Runnable → Future<?> (get() returns null)
pool.execute(runnable);                        // fire-and-forget, no Future

// batch:
List<Future<Long>> fs = pool.invokeAll(listOfCallables);   // blocks until ALL done
Long first = pool.invokeAny(listOfCallables);              // returns first success, cancels rest
```

### Retrieving results

```java
Long v = f.get();                       // BLOCKS forever — danger in prod
Long v = f.get(5, TimeUnit.SECONDS);    // ✅ production: bounded wait → TimeoutException
boolean done = f.isDone();
f.cancel(true);                         // true = interrupt if running
```

### Exception flow across the thread boundary

```java
try {
    Long v = f.get();
} catch (ExecutionException e) {
    Throwable real = e.getCause();      // the exception thrown inside call()
} catch (TimeoutException e) {
    // get(timeout) expired
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // restore the flag
}
```

- Callable exception is **stored in the Future**, re-thrown wrapped in `ExecutionException` on `get()`. Unwrap with `getCause()`.

### Lifecycle / shutdown

```java
pool.shutdown();                                  // stop accepting new; finish queued. NON-BLOCKING
boolean ok = pool.awaitTermination(10, TimeUnit.SECONDS);   // THIS blocks
List<Runnable> dropped = pool.shutdownNow();      // interrupt running, drop queued
```

> **Canonical shutdown idiom:**

```java
pool.shutdown();
try {
    if (!pool.awaitTermination(60, TimeUnit.SECONDS)) pool.shutdownNow();
} catch (InterruptedException e) {
    pool.shutdownNow();
    Thread.currentThread().interrupt();
}
```

### Parallel-sum skeleton (submit ALL, then drain)

```java
List<Future<Long>> futures = new ArrayList<>();
for (chunk) {
    int lo = ..., hi = ...;                        // effectively-final locals for lambda capture
    futures.add(pool.submit(() -> { long s=0; for (int x=lo;x<=hi;x++) s+=arr[x]; return s; }));
}
long total = 0;
try { for (Future<Long> f : futures) total += f.get(); }   // get AFTER all submitted (parallel)
finally { pool.shutdown(); }
```

- Accumulator must be `long` (int[] sum overflows `int`).
- `get()` inside the submit loop = accidental serialization. Submit all first.

---

## 4. CompletableFuture — full syntax

### Starting async work

```java
CompletableFuture<Long> a = CompletableFuture.supplyAsync(() -> fetch());          // returns a value
CompletableFuture<Void> b = CompletableFuture.runAsync(() -> doSomething());        // no value
CompletableFuture<Long> c = CompletableFuture.supplyAsync(() -> fetch(), ioPool);   // ✅ custom executor
CompletableFuture<Long> done = CompletableFuture.completedFuture(42L);              // already-complete
```

> Default (no executor) runs on the **common ForkJoinPool** (CPU-sized). For **blocking I/O**, pass a dedicated executor or you starve the common pool.

### Transform ONE future

```java
cf.thenApply(x -> x + 1);          // sync transform,  T -> U          (returns CF<U>)
cf.thenApplyAsync(x -> x + 1);     // same, on a pool thread
cf.thenAccept(x -> print(x));      // consume,  T -> void              (returns CF<Void>)
cf.thenRun(() -> log("done"));     // ignore result, run a Runnable    (returns CF<Void>)
```

### Chain DEPENDENT futures (flatMap)

```java
// second call NEEDS the first's result AND itself returns a CompletableFuture
fetchUser(id).thenCompose(user -> fetchOrders(user));   // CF<User> -> CF<Orders>, flattened
// thenApply here would give you a CF<CF<Orders>> — nested. Use thenCompose to flatten.
```

### Combine TWO INDEPENDENT futures (run in parallel)

```java
CompletableFuture<Long> base = CompletableFuture.supplyAsync(() -> fetchBase(item));
CompletableFuture<Long> tax  = CompletableFuture.supplyAsync(() -> fetchTax(item));
CompletableFuture<Long> total = base.thenCombine(tax, (b, t) -> b + t);   // ~max(t1,t2), not sum
```

### thenApply vs thenCompose vs thenCombine

|Method|Use when|Function shape|
|---|---|---|
|`thenApply`|transform one future's result, sync|`T -> U`|
|`thenCompose`|next step DEPENDS on result & returns a CF|`T -> CF<U>`|
|`thenCombine`|two INDEPENDENT futures, merge results|`(T,U) -> V`|

### Error handling

```java
cf.exceptionally(ex -> fallbackValue);             // recover: only runs on failure
cf.handle((result, ex) -> ex == null ? result : fallback);   // runs on BOTH success & failure
cf.whenComplete((result, ex) -> log(result, ex));  // side-effect, does NOT alter the value
```

### Fan-out / fan-in

```java
CompletableFuture.allOf(f1, f2, f3).join();        // wait for ALL (returns CF<Void>)
// allOf gives no results — re-join each to pull values:
long sum = Stream.of(f1, f2, f3).map(CompletableFuture::join).mapToLong(Long::longValue).sum();

CompletableFuture.anyOf(f1, f2).thenAccept(System.out::println);   // first to finish wins
```

### Getting the result (terminal)

```java
Long v = cf.join();                   // unchecked — throws CompletionException (no checked decl)
Long v = cf.get();                    // checked — throws ExecutionException + InterruptedException
Long v = cf.get(5, TimeUnit.SECONDS); // bounded
```

- **In the pipeline, return the `CompletableFuture` — don't `.join()`/`.get()` early.** Blocking defeats the async point.
- `join()` ≈ `get()` but throws unchecked `CompletionException` (cause via `getCause()`).

---

## 5. Race conditions & memory (quick recall)

`count++` = READ → INCREMENT → WRITE (3 steps, not atomic).

|Tool|Fixes|Watch out|
|---|---|---|
|`synchronized`|atomicity + visibility|contention, serial execution|
|`volatile`|**visibility only**|❌ NOT atomic — never for `count++`|
|`AtomicInteger`|atomicity + visibility (CAS)|CAS thrash under high contention|

- **`volatile` is enough only for single-writer/multi-reader** (e.g. double-checked-locking singleton flag).
- **CAS** (`AtomicInteger.incrementAndGet`): read → compute → swap-if-unchanged → retry. Lock-free.
- **Semaphore/Lock release→acquire establishes happens-before** — that's why a shared counter handed across a semaphore handoff is visible without `volatile`.

---

## 6. sleep vs wait, notify vs notifyAll, interrupt

||`Thread.sleep(ms)`|`obj.wait()`|
|---|---|---|
|Class|`Thread`|`Object`|
|Releases lock?|❌ NO (holds it)|✅ YES (releases monitor)|
|Wakes on|timer|`notify`/`notifyAll`/`interrupt`|
|Needs `synchronized`?|no|yes|

- `sleep()` inside `synchronized` = classic deadlock (holds lock while sleeping). Use `wait()`.
- `notify()` may wake the WRONG thread (different condition) → missed signal. Prefer `notifyAll()` unless all waiters are identical.
- `interrupt()` on a thread in `wait()`: wakes immediately, reacquires lock, throws `InterruptedException` right there — not deferred.
- Catching `InterruptedException`: restore the flag with `Thread.currentThread().interrupt();`

---

## 7. 60-second pre-round drill (write each from memory)

1. `Executors.newFixedThreadPool(n)` → `submit(callable)` → `future.get(timeout)` → `shutdown()`.
2. `ReentrantLock` + 2 `Condition`s, `lock()/try/.../finally unlock()`.
3. `Semaphore(2)` gate + `acquire(2)` rendezvous (H2O).
4. `supplyAsync(...) .thenCombine(other, (a,b)->...)` — parallel; vs `.thenCompose(...)` — dependent.
5. Say out loud: "`shutdown()` is non-blocking; `awaitTermination`/`get` block." and "common ForkJoinPool is CPU-sized; pass a custom executor for blocking I/O."