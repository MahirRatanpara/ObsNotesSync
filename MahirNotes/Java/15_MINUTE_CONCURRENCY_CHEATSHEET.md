# Java Concurrency - 15 Minute Cheatsheet

**Last-minute revision before your interview!**

---

## ⚡ CRITICAL CONCEPTS (Must Know)

### Thread Creation (3 ways)

```java
// 1. Extend Thread
new Thread() { public void run() { } }.start();

// 2. Runnable (Preferred)
new Thread(() -> { }).start();

// 3. Callable (Returns value)
FutureTask<String> task = new FutureTask<>(() -> "result");
new Thread(task).start();
String result = task.get();
```

### synchronized Keyword

```java
// Method
public synchronized void method() { }

// Block (better - use private lock)
private final Object lock = new Object();
synchronized(lock) { }

// Static
public static synchronized void method() { }
// = synchronized(ClassName.class) { }
```

**Rules**:
- Always use same lock for related data
- Keep critical section small
- Don't call external code while holding lock

### volatile Keyword

```java
private volatile boolean flag = true;
```

**Use for**: Simple flags (boolean, reference)
**Not for**: count++ (use AtomicInteger)
**Guarantees**: Memory visibility, happens-before

---

## 🔒 LOCKS QUICK REFERENCE

### ReentrantLock

```java
ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    // Critical section
} finally {
    lock.unlock();  // ALWAYS in finally!
}

// Try lock (non-blocking)
if (lock.tryLock()) {
    try { } finally { lock.unlock(); }
}

// Fair lock (FIFO)
new ReentrantLock(true);
```

**vs synchronized**: tryLock(), timeout, fairness, multiple conditions

### ReadWriteLock

```java
ReadWriteLock rwLock = new ReentrantReadWriteLock();

// Multiple readers
rwLock.readLock().lock();
try { } finally { rwLock.readLock().unlock(); }

// One writer
rwLock.writeLock().lock();
try { } finally { rwLock.writeLock().unlock(); }
```

**Use case**: Read-heavy workloads (cache, config)

---

## 💥 ATOMIC VARIABLES

```java
AtomicInteger counter = new AtomicInteger(0);

counter.incrementAndGet();     // i++, return new
counter.getAndIncrement();     // i++, return old
counter.addAndGet(5);          // += 5
counter.compareAndSet(10, 20); // CAS

// Custom operation
counter.updateAndGet(c -> c * 2);
```

**How CAS works**:
```java
while (true) {
    int current = atomic.get();
    int next = current + 1;
    if (atomic.compareAndSet(current, next)) break;
}
```

---

## 📦 CONCURRENT COLLECTIONS

### ConcurrentHashMap

```java
ConcurrentHashMap<K, V> map = new ConcurrentHashMap<>();

map.put(k, v);
map.putIfAbsent(k, v);  // Atomic
map.compute(k, (key, val) -> newVal);  // Atomic update
```

**Why better than Hashtable**:
- Lock-free reads
- Bucket-level locking (not full map)
- No ConcurrentModificationException

### CopyOnWriteArrayList

```java
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
```

**Trade-off**: Copy entire array on write → slow writes, fast reads
**Use when**: Read >> Write, small list, event listeners

### BlockingQueue

```java
BlockingQueue<Integer> queue = new ArrayBlockingQueue<>(10);

queue.put(item);   // Blocks if full
Integer item = queue.take();  // Blocks if empty

// Non-blocking
queue.offer(item);  // Returns false if full
Integer item = queue.poll();  // Returns null if empty
```

**Perfect for**: Producer-Consumer

---

## 🎯 EXECUTOR FRAMEWORK

### Creating Executors

```java
// Fixed threads
ExecutorService exec = Executors.newFixedThreadPool(4);

// Cached (creates as needed)
ExecutorService exec = Executors.newCachedThreadPool();

// Single thread
ExecutorService exec = Executors.newSingleThreadExecutor();

// Scheduled
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
```

### Submitting Tasks

```java
// execute() - no result
executor.execute(() -> System.out.println("Task"));

// submit() - returns Future
Future<String> future = executor.submit(() -> "Result");
String result = future.get();  // Blocks

// invokeAll() - multiple tasks
List<Future<String>> results = executor.invokeAll(tasks);
```

### Shutdown (Always!)

```java
executor.shutdown();  // No new tasks, finish existing
executor.awaitTermination(60, TimeUnit.SECONDS);
executor.shutdownNow();  // Interrupt all
```

### ScheduledExecutorService

```java
// Delay
scheduler.schedule(task, 5, TimeUnit.SECONDS);

// Fixed rate (start-to-start)
scheduler.scheduleAtFixedRate(task, 0, 3, TimeUnit.SECONDS);

// Fixed delay (end-to-start)
scheduler.scheduleWithFixedDelay(task, 0, 3, TimeUnit.SECONDS);
```

---

## 🛠️ SYNCHRONIZATION UTILITIES

### CountDownLatch - Wait for N events

```java
CountDownLatch latch = new CountDownLatch(3);

// Worker
latch.countDown();

// Main
latch.await();  // Blocks until count = 0
```

### CyclicBarrier - N threads wait for each other

```java
CyclicBarrier barrier = new CyclicBarrier(3);

// Each thread
barrier.await();  // Wait until all 3 arrive
```

**vs CountDownLatch**: Reusable, threads wait for each other

### Semaphore - Limit N concurrent accesses

```java
Semaphore sem = new Semaphore(3);  // 3 permits

sem.acquire();  // Blocks if no permits
try {
    // Use resource
} finally {
    sem.release();
}
```

**Use case**: Connection pool, rate limiting

---

## 🚀 COMPLETABLEFUTURE

### Creating

```java
// Supply async (returns value)
CompletableFuture<String> f = CompletableFuture.supplyAsync(() -> "Hi");

// Run async (no return)
CompletableFuture<Void> f = CompletableFuture.runAsync(() -> {});
```

### Chaining

```java
future
    .thenApply(s -> s.toUpperCase())     // Transform
    .thenAccept(System.out::println)     // Consume
    .thenRun(() -> System.out.println("Done"));
```

### Combining

```java
f1.thenCombine(f2, (a, b) -> a + b);  // Both
f1.applyToEither(f2, s -> s);         // Either
CompletableFuture.allOf(f1, f2);      // All
CompletableFuture.anyOf(f1, f2);      // Any
```

### Exception Handling

```java
future
    .exceptionally(ex -> "Fallback")
    .handle((result, ex) -> ex != null ? "Error" : result);
```

---

## 🐛 COMMON PROBLEMS

### Deadlock

```java
// Thread 1: lock1 → lock2
// Thread 2: lock2 → lock1  → DEADLOCK!
```

**Prevention**: Lock ordering, timeout, avoid nested locks

### Race Condition

```java
// WRONG
if (count == 0) {
    count++;  // Another thread might increment between!
}

// RIGHT
synchronized(this) {
    if (count == 0) count++;
}
// OR
atomicCount.compareAndSet(0, 1);
```

### Visibility Problem

```java
// Thread 1
flag = true;  // Might not be visible to Thread 2!

// Thread 2
while (!flag) { }  // Infinite loop!

// FIX: Use volatile
private volatile boolean flag;
```

---

## 💡 INTERVIEW LIGHTNING ROUND

**Q: synchronized vs ReentrantLock?**
**A**: ReentrantLock has tryLock(), timeout, fairness. synchronized is simpler.

**Q: volatile vs AtomicInteger?**
**A**: volatile for visibility only. Atomic for visibility + atomicity (CAS).

**Q: wait() vs sleep()?**
**A**: wait() releases lock, sleep() doesn't. wait() needs synchronized.

**Q: ConcurrentHashMap vs Hashtable?**
**A**: ConcurrentHashMap: lock-free reads, bucket locks. Hashtable: full sync.

**Q: When use CompletableFuture?**
**A**: Async I/O, chaining operations, combining multiple async sources.

**Q: Prevent deadlock?**
**A**: 1. Lock ordering 2. Timeout 3. Avoid nested locks

**Q: Fair lock performance?**
**A**: Slower (FIFO overhead) but prevents starvation.

**Q: ThreadLocal use case?**
**A**: SimpleDateFormat, DB connections (one per thread).

---

## 🎯 CODE TEMPLATES

### Thread-Safe Singleton (Bill Pugh)

```java
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

### Producer-Consumer

```java
BlockingQueue<Integer> queue = new ArrayBlockingQueue<>(10);

// Producer
executor.submit(() -> {
    for (int i = 0; i < 100; i++) queue.put(i);
});

// Consumer
executor.submit(() -> {
    while (true) {
        Integer item = queue.take();
        process(item);
    }
});
```

### Read-Write Cache

```java
class Cache {
    private Map<K, V> map = new HashMap<>();
    private ReadWriteLock lock = new ReentrantReadWriteLock();

    V get(K key) {
        lock.readLock().lock();
        try { return map.get(key); }
        finally { lock.readLock().unlock(); }
    }

    void put(K key, V val) {
        lock.writeLock().lock();
        try { map.put(key, val); }
        finally { lock.writeLock().unlock(); }
    }
}
```

### Wait-Notify Pattern

```java
class Queue {
    private Queue<Integer> queue = new LinkedList<>();

    public synchronized void produce(int item) throws InterruptedException {
        while (isFull()) wait();
        queue.offer(item);
        notifyAll();
    }

    public synchronized int consume() throws InterruptedException {
        while (isEmpty()) wait();
        int item = queue.poll();
        notifyAll();
        return item;
    }
}
```

---

## ⚖️ COMPARISON TABLES

### Lock Types

| Lock | Fair? | TryLock? | Timeout? | Multiple Conditions? |
|------|-------|----------|----------|---------------------|
| synchronized | ❌ | ❌ | ❌ | ❌ |
| ReentrantLock | Optional | ✅ | ✅ | ✅ |
| ReadWriteLock | Optional | ✅ | ✅ | ✅ |

### Thread-Safe Collections

| Collection | Mechanism | Best For |
|------------|-----------|----------|
| Hashtable | Full sync | ❌ Obsolete |
| Collections.synchronizedMap | Full sync | ❌ Avoid |
| ConcurrentHashMap | Bucket locks + CAS | ✅ General use |
| CopyOnWriteArrayList | Copy on write | ✅ Read-heavy |

### Executor Types

| Type | Core Threads | Max Threads | Queue |
|------|--------------|-------------|-------|
| Fixed | N | N | Unbounded |
| Cached | 0 | Integer.MAX | SynchronousQueue |
| Single | 1 | 1 | Unbounded |

---

## 🔥 FINAL CHECKLIST

Before interview:
- [ ] Can explain synchronized vs ReentrantLock
- [ ] Can code thread-safe Singleton
- [ ] Know when to use volatile
- [ ] Understand CAS and atomic variables
- [ ] Can implement Producer-Consumer
- [ ] Know ConcurrentHashMap internals
- [ ] Can explain deadlock prevention
- [ ] Understand ExecutorService lifecycle
- [ ] Can use CompletableFuture
- [ ] Know difference: wait() vs sleep()

---

## 🎓 GOLDEN RULES

1. **Always unlock in finally**
2. **Always shutdown executors**
3. **Use concurrent collections over synchronized**
4. **Immutability is thread-safe**
5. **Keep synchronized blocks small**
6. **Don't synchronize on this**
7. **volatile for flags, atomic for counters**
8. **Document thread-safety of classes**

---

**🚀 You're ready! Good luck!**
