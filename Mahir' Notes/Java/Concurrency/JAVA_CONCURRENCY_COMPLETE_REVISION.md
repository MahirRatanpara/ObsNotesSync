# Java Concurrency - Complete Revision Guide

**Master Java concurrency for interviews and LLD problems!**

---

## 📚 TABLE OF CONTENTS

1. [Thread Fundamentals](#1-thread-fundamentals)
2. [Synchronization Basics](#2-synchronization-basics)
3. [Advanced Locks](#3-advanced-locks)
4. [Atomic Variables](#4-atomic-variables)
5. [Concurrent Collections](#5-concurrent-collections)
6. [Executor Framework](#6-executor-framework)
7. [Synchronization Utilities](#7-synchronization-utilities)
8. [CompletableFuture & Async](#8-completablefuture--async)
9. [Thread Safety Patterns](#9-thread-safety-patterns)
10. [Common Concurrency Problems](#10-common-concurrency-problems)
11. [Best Practices & Interview Tips](#11-best-practices--interview-tips)

---

## 1. THREAD FUNDAMENTALS

### Creating Threads

**Method 1: Extend Thread**
```java
class MyThread extends Thread {
    public void run() {
        System.out.println("Thread running");
    }
}
new MyThread().start();
```

**Method 2: Implement Runnable (Preferred)**
```java
Runnable task = () -> System.out.println("Task running");
new Thread(task).start();
```

**Method 3: Implement Callable (Returns value)**
```java
Callable<String> task = () -> "Result";
FutureTask<String> futureTask = new FutureTask<>(task);
new Thread(futureTask).start();
String result = futureTask.get(); // Blocks until done
```

### Thread Lifecycle

```
NEW → RUNNABLE → RUNNING → TERMINATED
         ↓           ↓
      BLOCKED    WAITING
                TIMED_WAITING
```

### Key Thread Methods

| Method | Description | Blocks? |
|--------|-------------|---------|
| `start()` | Begin execution | No |
| `run()` | Execute task | N/A (don't call directly!) |
| `join()` | Wait for thread to complete | Yes |
| `sleep(ms)` | Pause execution | Yes |
| `interrupt()` | Request thread interruption | No |
| `isAlive()` | Check if running | No |
| `yield()` | Hint to scheduler to yield | No |

### Daemon vs Non-Daemon Threads

```java
Thread daemon = new Thread(() -> {
    while (true) {
        // Background task
    }
});
daemon.setDaemon(true); // JVM exits even if this runs
daemon.start();
```

| Type | JVM Waits? | Use Case |
|------|------------|----------|
| **Daemon** | ❌ No | Background services (GC, logging) |
| **Non-Daemon** | ✅ Yes | Main application logic |

---

## 2. SYNCHRONIZATION BASICS

### The `synchronized` Keyword

**Synchronized Method**
```java
public synchronized void increment() {
    count++;  // Thread-safe
}
```

**Synchronized Block**
```java
public void increment() {
    synchronized(this) {
        count++;
    }
}

// Better: Synchronize on private lock
private final Object lock = new Object();
public void increment() {
    synchronized(lock) {
        count++;
    }
}
```

**Static Synchronization**
```java
public static synchronized void staticMethod() {
    // Locks on Class object
}

// Equivalent to:
synchronized(MyClass.class) { }
```

### wait() / notify() / notifyAll()

**Must be called inside synchronized block!**

```java
class BoundedBuffer {
    private Queue<Integer> queue = new LinkedList<>();
    private int capacity;

    public synchronized void produce(int item) throws InterruptedException {
        while (queue.size() == capacity) {
            wait();  // Release lock and wait
        }
        queue.offer(item);
        notifyAll();  // Wake up consumers
    }

    public synchronized int consume() throws InterruptedException {
        while (queue.isEmpty()) {
            wait();  // Release lock and wait
        }
        int item = queue.poll();
        notifyAll();  // Wake up producers
        return item;
    }
}
```

### `volatile` Keyword

**Purpose**: Ensures memory visibility across threads

```java
private volatile boolean running = true;

// Thread 1
public void stop() {
    running = false;  // Immediately visible to Thread 2
}

// Thread 2
public void run() {
    while (running) {  // Sees latest value
        // Do work
    }
}
```

**When to use**:
- ✅ Boolean flags (shutdown, ready)
- ✅ Single variable read/write
- ❌ Compound operations (count++, check-then-act)

**Guarantees**:
1. Memory visibility (no CPU cache staleness)
2. Happens-before relationship
3. No instruction reordering around volatile

---

## 3. ADVANCED LOCKS

### ReentrantLock

**More flexible than synchronized**

```java
ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    // Critical section
} finally {
    lock.unlock();  // ⚠️ ALWAYS in finally!
}
```

### Features Over synchronized

**1. Try Lock (Non-blocking)**
```java
if (lock.tryLock()) {
    try {
        // Got lock
    } finally {
        lock.unlock();
    }
} else {
    // Couldn't get lock, do something else
}

// With timeout
if (lock.tryLock(5, TimeUnit.SECONDS)) {
    // ...
}
```

**2. Interruptible Lock**
```java
try {
    lock.lockInterruptibly();
    // Can be interrupted while waiting
} catch (InterruptedException e) {
    // Handle interruption
}
```

**3. Fair Lock**
```java
ReentrantLock fairLock = new ReentrantLock(true);
// Threads acquire in FIFO order (slower but prevents starvation)
```

**4. Multiple Conditions**
```java
Condition notFull = lock.newCondition();
Condition notEmpty = lock.newCondition();

// Producer
lock.lock();
try {
    while (isFull()) {
        notFull.await();  // Like wait()
    }
    addItem();
    notEmpty.signal();  // Like notify()
} finally {
    lock.unlock();
}
```

### ReadWriteLock

**Multiple readers OR one writer**

```java
ReadWriteLock rwLock = new ReentrantReadWriteLock();

// Multiple readers can hold this simultaneously
rwLock.readLock().lock();
try {
    // Read data
} finally {
    rwLock.readLock().unlock();
}

// Only one writer allowed (blocks readers too)
rwLock.writeLock().lock();
try {
    // Write data
} finally {
    rwLock.writeLock().unlock();
}
```

**When to use**: Read-heavy workloads (e.g., cache)

### StampedLock (Java 8+)

**Optimistic read lock - fastest for read-heavy scenarios**

```java
StampedLock lock = new StampedLock();

// Optimistic read (lock-free!)
long stamp = lock.tryOptimisticRead();
int value = sharedValue;
if (!lock.validate(stamp)) {
    // Value changed, acquire read lock
    stamp = lock.readLock();
    try {
        value = sharedValue;
    } finally {
        lock.unlockRead(stamp);
    }
}
```

---

## 4. ATOMIC VARIABLES

### AtomicInteger / AtomicLong / AtomicBoolean

**Lock-free thread-safe operations using CAS**

```java
AtomicInteger counter = new AtomicInteger(0);

counter.incrementAndGet();     // Atomic i++, returns new value
counter.getAndIncrement();     // Atomic i++, returns old value
counter.addAndGet(5);          // Atomic add
counter.compareAndSet(10, 20); // CAS: if value==10, set to 20

// Custom atomic operation
counter.updateAndGet(current -> current * 2);
```

### AtomicReference

**Thread-safe object reference**

```java
AtomicReference<User> currentUser = new AtomicReference<>();

currentUser.set(newUser);
User user = currentUser.get();

// Atomic update
currentUser.updateAndGet(oldUser -> {
    User newUser = oldUser.copy();
    newUser.setAge(oldUser.getAge() + 1);
    return newUser;
});
```

### Compare-And-Swap (CAS) Pattern

```java
while (true) {
    int current = atomicInt.get();
    int next = current + 1;
    if (atomicInt.compareAndSet(current, next)) {
        break;  // Success!
    }
    // Retry if another thread modified it
}
```

**How CAS works**:
1. Read current value
2. Compute new value
3. Atomically: if current value unchanged, update; else retry

**Hardware support**: `CMPXCHG` instruction (x86)

---

## 5. CONCURRENT COLLECTIONS

### ConcurrentHashMap

**Thread-safe HashMap with fine-grained locking**

```java
ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();

map.put("key", 1);          // Thread-safe
map.get("key");             // Lock-free read!
map.remove("key");
map.putIfAbsent("key", 1);  // Atomic
map.replace("key", 1, 2);   // Atomic CAS

// Atomic compute
map.compute("key", (k, v) -> v == null ? 1 : v + 1);
```

**Key features**:
- ✅ Lock-free reads
- ✅ Bucket-level locking for writes
- ✅ No ConcurrentModificationException
- ✅ Better than `Collections.synchronizedMap()`

**Internals**:
- Empty bucket: CAS insertion
- Non-empty bucket: Synchronized on bucket head
- High concurrency: 16 segments (Java 7), finer buckets (Java 8+)

### CopyOnWriteArrayList

**Thread-safe ArrayList - copy entire array on write**

```java
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();

list.add("item");  // Creates new array copy
String item = list.get(0);  // Lock-free read

// Iterator sees snapshot
Iterator<String> iter = list.iterator();
list.add("new");  // Won't appear in iterator
```

**When to use**:
- ✅ Read-heavy (many reads, few writes)
- ✅ Small to medium list size
- ✅ Event listeners, observer lists

**Trade-off**: Memory + write performance for read speed

### ConcurrentLinkedQueue

**Lock-free thread-safe queue**

```java
ConcurrentLinkedQueue<String> queue = new ConcurrentLinkedQueue<>();

queue.offer("item");  // Add to tail
String item = queue.poll();  // Remove from head (null if empty)
String peek = queue.peek();  // Read head without removing
```

### BlockingQueue Implementations

**Thread-safe queues with blocking operations**

```java
// 1. ArrayBlockingQueue - bounded
BlockingQueue<String> queue = new ArrayBlockingQueue<>(10);

queue.put("item");   // Blocks if full
String item = queue.take();  // Blocks if empty

// 2. LinkedBlockingQueue - optionally bounded
BlockingQueue<String> queue = new LinkedBlockingQueue<>();

// 3. PriorityBlockingQueue - priority ordering
BlockingQueue<Task> queue = new PriorityBlockingQueue<>();

// 4. DelayQueue - elements available after delay
DelayQueue<DelayedTask> queue = new DelayQueue<>();
```

**Producer-Consumer with BlockingQueue**:
```java
BlockingQueue<Integer> queue = new ArrayBlockingQueue<>(10);

// Producer
new Thread(() -> {
    for (int i = 0; i < 100; i++) {
        queue.put(i);  // Blocks if queue full
    }
}).start();

// Consumer
new Thread(() -> {
    while (true) {
        Integer item = queue.take();  // Blocks if queue empty
        process(item);
    }
}).start();
```

### Synchronized Collections (Avoid!)

```java
List<String> syncList = Collections.synchronizedList(new ArrayList<>());
Map<K, V> syncMap = Collections.synchronizedMap(new HashMap<>());

// ⚠️ Still need manual sync for iterations!
synchronized(syncList) {
    for (String item : syncList) {
        // ...
    }
}
```

**Prefer**: `ConcurrentHashMap`, `CopyOnWriteArrayList`

---

## 6. EXECUTOR FRAMEWORK

### ExecutorService Hierarchy

```
Executor
  └─ ExecutorService
       ├─ ThreadPoolExecutor
       └─ ScheduledExecutorService
            └─ ScheduledThreadPoolExecutor
```

### Creating Executors

```java
// 1. Fixed thread pool
ExecutorService executor = Executors.newFixedThreadPool(4);

// 2. Cached thread pool (creates threads as needed)
ExecutorService executor = Executors.newCachedThreadPool();

// 3. Single thread executor
ExecutorService executor = Executors.newSingleThreadExecutor();

// 4. Scheduled executor
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
```

### Submitting Tasks

**execute() - Fire and forget**
```java
executor.execute(() -> System.out.println("Task"));
// No return value, exceptions lost
```

**submit() - Get Future**
```java
Future<String> future = executor.submit(() -> "Result");
String result = future.get();  // Blocks until done
```

**invokeAll() - Multiple tasks**
```java
List<Callable<String>> tasks = Arrays.asList(
    () -> "Task 1",
    () -> "Task 2"
);
List<Future<String>> results = executor.invokeAll(tasks);
```

### Future API

```java
Future<String> future = executor.submit(callable);

String result = future.get();  // Blocks until done
String result = future.get(5, TimeUnit.SECONDS);  // Timeout

boolean done = future.isDone();
boolean cancelled = future.isCancelled();
future.cancel(true);  // Interrupt if running
```

### Shutdown

```java
executor.shutdown();  // No new tasks, finish existing

// Wait for termination
if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
    executor.shutdownNow();  // Force shutdown
}
```

**⚠️ Important**: Always shutdown executor, or JVM won't exit!

### ThreadPoolExecutor Configuration

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    2,                          // corePoolSize
    4,                          // maximumPoolSize
    60, TimeUnit.SECONDS,       // keepAliveTime
    new LinkedBlockingQueue<>(), // workQueue
    new ThreadPoolExecutor.CallerRunsPolicy()  // rejectionHandler
);
```

**Task submission flow**:
1. If threads < corePoolSize → create new thread
2. Else → add to queue
3. If queue full && threads < maxPoolSize → create new thread
4. Else → reject (call rejectionHandler)

**Rejection Policies**:
- `AbortPolicy` (default): Throw `RejectedExecutionException`
- `CallerRunsPolicy`: Run in caller thread
- `DiscardPolicy`: Silently discard
- `DiscardOldestPolicy`: Discard oldest in queue

### ScheduledExecutorService

**Delayed execution**
```java
scheduler.schedule(() -> System.out.println("After 5s"),
                   5, TimeUnit.SECONDS);
```

**Fixed rate** (start-to-start interval)
```java
scheduler.scheduleAtFixedRate(() -> System.out.println("Every 3s"),
                              0, 3, TimeUnit.SECONDS);
```

**Fixed delay** (end-to-start interval)
```java
scheduler.scheduleWithFixedDelay(() -> System.out.println("3s after finish"),
                                 0, 3, TimeUnit.SECONDS);
```

---

## 7. SYNCHRONIZATION UTILITIES

### CountDownLatch

**Wait for N threads to complete**

```java
CountDownLatch latch = new CountDownLatch(3);

// Worker threads
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        doWork();
        latch.countDown();  // Decrement count
    }).start();
}

latch.await();  // Blocks until count reaches 0
System.out.println("All workers done!");
```

**Use case**: Wait for initialization of multiple services

### CyclicBarrier

**Wait for N threads to reach barrier point, then continue**

```java
CyclicBarrier barrier = new CyclicBarrier(3, () -> {
    System.out.println("All reached barrier!");
});

for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        doPhase1();
        barrier.await();  // Wait for others
        doPhase2();
    }).start();
}
```

**Difference from CountDownLatch**:
- Reusable (can reset)
- Threads wait for each other
- Optional barrier action

### Semaphore

**Control access to N resources**

```java
Semaphore semaphore = new Semaphore(3);  // 3 permits

semaphore.acquire();  // Blocks if no permits
try {
    useResource();
} finally {
    semaphore.release();  // Return permit
}

// Try without blocking
if (semaphore.tryAcquire()) {
    try {
        useResource();
    } finally {
        semaphore.release();
    }
}
```

**Use case**: Connection pool, rate limiting

### Phaser (Java 7+)

**Advanced barrier - dynamic parties**

```java
Phaser phaser = new Phaser(1);  // 1 = main thread

for (int i = 0; i < 3; i++) {
    phaser.register();  // Add party
    new Thread(() -> {
        doWork();
        phaser.arriveAndAwaitAdvance();  // Wait at phase
    }).start();
}

phaser.arriveAndDeregister();  // Main thread done
```

### Exchanger

**Exchange data between two threads**

```java
Exchanger<String> exchanger = new Exchanger<>();

// Thread 1
String data = exchanger.exchange("Data from T1");

// Thread 2
String data = exchanger.exchange("Data from T2");
```

---

## 8. COMPLETABLEFUTURE & ASYNC

### Creating CompletableFuture

```java
// 1. Supply async (returns value)
CompletableFuture<String> future =
    CompletableFuture.supplyAsync(() -> "Result");

// 2. Run async (no return value)
CompletableFuture<Void> future =
    CompletableFuture.runAsync(() -> System.out.println("Done"));

// 3. Completed future
CompletableFuture<String> future =
    CompletableFuture.completedFuture("Immediate result");
```

### Chaining Operations

```java
CompletableFuture.supplyAsync(() -> "Hello")
    .thenApply(s -> s + " World")        // Transform result
    .thenAccept(System.out::println)     // Consume result
    .thenRun(() -> System.out.println("Done"));  // No input

// Get result
String result = future.get();  // Blocks
String result = future.join(); // Blocks, unchecked exception
```

### Combining Futures

```java
CompletableFuture<String> f1 = CompletableFuture.supplyAsync(() -> "A");
CompletableFuture<String> f2 = CompletableFuture.supplyAsync(() -> "B");

// Both complete
CompletableFuture<String> combined = f1.thenCombine(f2, (a, b) -> a + b);

// Either complete
CompletableFuture<String> either = f1.applyToEither(f2, s -> s);

// All complete
CompletableFuture<Void> all = CompletableFuture.allOf(f1, f2);

// Any complete
CompletableFuture<Object> any = CompletableFuture.anyOf(f1, f2);
```

### Exception Handling

```java
CompletableFuture.supplyAsync(() -> {
    if (Math.random() > 0.5) throw new RuntimeException("Error");
    return "Success";
})
.exceptionally(ex -> "Fallback")  // Handle exception
.handle((result, ex) -> {          // Handle both result and exception
    if (ex != null) return "Error: " + ex.getMessage();
    return result;
});
```

### Async Methods

```java
// Run in common ForkJoinPool
future.thenApplyAsync(s -> s.toUpperCase());

// Run in custom executor
ExecutorService executor = Executors.newFixedThreadPool(4);
future.thenApplyAsync(s -> s.toUpperCase(), executor);
```

---

## 9. THREAD SAFETY PATTERNS

### 1. Immutability (Best)

```java
public final class ImmutableUser {
    private final String name;
    private final int age;

    public ImmutableUser(String name, int age) {
        this.name = name;
        this.age = age;
    }

    // Only getters, no setters
    public String getName() { return name; }
    public int getAge() { return age; }
}
```

**Thread-safe by design!**

### 2. Thread Confinement

**Stack Confinement**
```java
public void method() {
    int localVar = 0;  // Each thread has its own copy
    localVar++;        // Thread-safe
}
```

**ThreadLocal**
```java
ThreadLocal<SimpleDateFormat> formatter =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));

// Each thread gets its own instance
SimpleDateFormat sdf = formatter.get();
```

### 3. Synchronized Collections

```java
// Wrap existing collection
List<String> syncList = Collections.synchronizedList(new ArrayList<>());

// Still need sync for iterations
synchronized(syncList) {
    for (String s : syncList) {
        // ...
    }
}
```

### 4. Concurrent Collections (Preferred)

```java
ConcurrentHashMap<K, V> map = new ConcurrentHashMap<>();
CopyOnWriteArrayList<E> list = new CopyOnWriteArrayList<>();
```

### 5. Atomic Variables

```java
AtomicInteger counter = new AtomicInteger();
counter.incrementAndGet();  // Thread-safe without locks
```

### 6. Double-Checked Locking (Singleton)

```java
public class Singleton {
    private static volatile Singleton instance;

    public static Singleton getInstance() {
        if (instance == null) {              // First check
            synchronized (Singleton.class) {
                if (instance == null) {       // Second check
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

**⚠️ volatile is essential!**

---

## 10. COMMON CONCURRENCY PROBLEMS

### Deadlock

**Circular dependency on locks**

```java
// Thread 1
synchronized(lock1) {
    synchronized(lock2) {  // Waits for lock2
        // ...
    }
}

// Thread 2
synchronized(lock2) {
    synchronized(lock1) {  // Waits for lock1
        // DEADLOCK!
    }
}
```

**Prevention**:
1. Lock ordering (always acquire locks in same order)
2. Timeout on lock acquisition
3. Detect and recover
4. Avoid nested locks

### Livelock

**Threads keep changing state in response to each other**

```java
// Both threads keep yielding to each other
while (resource.isLocked()) {
    Thread.yield();  // Infinite politeness!
}
```

### Starvation

**Thread never gets CPU time**

**Causes**:
- Low priority threads
- Unfair locks
- Long-running tasks blocking queue

**Solutions**:
- Use fair locks: `new ReentrantLock(true)`
- Bounded waiting
- Priority inversion handling

### Race Condition

**Result depends on thread timing**

```java
// NOT thread-safe
if (count == 0) {
    count++;  // Race! Another thread might increment between check and update
}

// Thread-safe
synchronized(this) {
    if (count == 0) {
        count++;
    }
}

// Or use atomic
if (atomicCount.compareAndSet(0, 1)) {
    // Success
}
```

---

## 11. BEST PRACTICES & INTERVIEW TIPS

### Thread Safety Checklist

✅ **Do**:
- Use immutable objects when possible
- Prefer concurrent collections over synchronized
- Use executor service instead of raw threads
- Always shutdown executors
- Use `volatile` for flags
- Document thread-safety of classes
- Use atomic variables for simple counters

❌ **Don't**:
- Don't synchronize on `this` (use private lock)
- Don't hold locks while calling external code
- Don't use `Thread.stop()` (deprecated, unsafe)
- Don't forget `volatile` in double-checked locking
- Don't mix synchronized and unsynchronized access

### Interview Code Templates

**Producer-Consumer**
```java
BlockingQueue<Integer> queue = new ArrayBlockingQueue<>(10);

// Producer
executor.submit(() -> {
    for (int i = 0; i < 100; i++) {
        queue.put(i);
    }
});

// Consumer
executor.submit(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        Integer item = queue.take();
        process(item);
    }
});
```

**Thread-Safe Singleton**
```java
// Bill Pugh (Best)
public class Singleton {
    private Singleton() {}

    private static class Holder {
        static final Singleton INSTANCE = new Singleton();
    }

    public static Singleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

**Read-Write Lock Cache**
```java
class Cache {
    private final Map<String, String> map = new HashMap<>();
    private final ReadWriteLock lock = new ReentrantReadWriteLock();

    public String get(String key) {
        lock.readLock().lock();
        try {
            return map.get(key);
        } finally {
            lock.readLock().unlock();
        }
    }

    public void put(String key, String value) {
        lock.writeLock().lock();
        try {
            map.put(key, value);
        } finally {
            lock.writeLock().unlock();
        }
    }
}
```

### Key Interview Questions

**Q: synchronized vs ReentrantLock?**
- synchronized: Built-in, simpler, implicit unlock
- ReentrantLock: tryLock(), fair mode, multiple conditions, interruptible

**Q: volatile vs synchronized?**
- volatile: Visibility only, no atomicity, for single variables
- synchronized: Visibility + atomicity, for code blocks

**Q: ConcurrentHashMap vs Hashtable?**
- ConcurrentHashMap: Fine-grained locking, lock-free reads, better performance
- Hashtable: Full synchronization, slower

**Q: When to use CompletableFuture?**
- Async I/O operations
- Chaining multiple async tasks
- Exception handling in async code
- Combining results from multiple sources

**Q: How to prevent deadlock?**
1. Lock ordering
2. Timeout
3. Avoid nested locks
4. Use tryLock()

### Performance Tips

**Reduce lock contention**:
- Minimize synchronized block size
- Use ReadWriteLock for read-heavy workloads
- Use concurrent collections
- Partition data (reduce shared state)

**Choose right tool**:
- Simple counter → `AtomicInteger`
- Complex state → `synchronized` or `ReentrantLock`
- Read-heavy cache → `ReadWriteLock` or `ConcurrentHashMap`
- Producer-Consumer → `BlockingQueue`

---

## 🎯 QUICK REFERENCE TABLES

### Lock Comparison

| Feature | synchronized | ReentrantLock | ReadWriteLock |
|---------|-------------|---------------|---------------|
| **Fairness** | No | Optional | Optional |
| **Try lock** | No | Yes | Yes |
| **Timeout** | No | Yes | Yes |
| **Interruptible** | No | Yes | Yes |
| **Conditions** | 1 | Many | Many |
| **Performance** | Good | Good | Best for reads |

### Collection Comparison

| Collection | Thread-Safe? | Blocking? | Performance |
|------------|--------------|-----------|-------------|
| ArrayList | ❌ No | No | Fast |
| Vector | ✅ Yes | No | Slow |
| Collections.synchronizedList | ✅ Yes | No | Medium |
| CopyOnWriteArrayList | ✅ Yes | No | Reads: Fast, Writes: Slow |
| ConcurrentLinkedQueue | ✅ Yes | No | Fast |
| ArrayBlockingQueue | ✅ Yes | Yes | Medium |

### Executor Types

| Type | Threads | Queue | Use Case |
|------|---------|-------|----------|
| FixedThreadPool | Fixed N | Unbounded | Controlled resources |
| CachedThreadPool | 0 to ∞ | SynchronousQueue | Short tasks |
| SingleThreadExecutor | 1 | Unbounded | Sequential execution |
| ScheduledThreadPool | Fixed N | DelayedWorkQueue | Cron-like tasks |

---

**🚀 You're now ready to tackle any Java concurrency interview question or LLD problem!**
