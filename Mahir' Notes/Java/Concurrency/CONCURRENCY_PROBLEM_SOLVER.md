# Concurrency Problem Solver - Quick Decision Guide

**Quickly identify which concurrency tool to use for any problem!**

---

## 🎯 THE MASTER DECISION TREE

```
What's your problem?
│
├─ SHARED STATE ACCESS
│  ├─ Simple counter/flag?
│  │  ├─ Single variable? → volatile
│  │  ├─ Counter operation? → AtomicInteger
│  │  └─ Complex object? → AtomicReference
│  │
│  ├─ Multiple threads reading/writing?
│  │  ├─ Simple mutual exclusion? → synchronized
│  │  ├─ Need tryLock/timeout? → ReentrantLock
│  │  ├─ Read >> Write? → ReadWriteLock
│  │  └─ Need best read performance? → StampedLock
│  │
│  └─ Shared collection?
│     ├─ Map? → ConcurrentHashMap
│     ├─ List (read-heavy)? → CopyOnWriteArrayList
│     ├─ Queue (no blocking)? → ConcurrentLinkedQueue
│     └─ Queue (blocking)? → BlockingQueue
│
├─ TASK EXECUTION
│  ├─ Need thread pool? → ExecutorService
│  ├─ Scheduled/delayed tasks? → ScheduledExecutorService
│  ├─ Async with chaining? → CompletableFuture
│  └─ Divide and conquer? → ForkJoinPool
│
├─ COORDINATION
│  ├─ Wait for N tasks to complete? → CountDownLatch
│  ├─ Threads wait for each other? → CyclicBarrier
│  ├─ Limit concurrent access? → Semaphore
│  ├─ Exchange data between 2 threads? → Exchanger
│  └─ Complex phased coordination? → Phaser
│
└─ PRODUCER-CONSUMER
   ├─ Need blocking? → BlockingQueue
   ├─ Priority ordering? → PriorityBlockingQueue
   ├─ Delayed elements? → DelayQueue
   └─ Direct handoff? → SynchronousQueue
```

---

## 🔍 PROBLEM → SOLUTION LOOKUP

### "I need to..."

| Problem | Solution | Quick Example |
|---------|----------|---------------|
| **Protect shared counter** | AtomicInteger | `counter.incrementAndGet()` |
| **Protect shared flag** | volatile | `volatile boolean ready` |
| **Protect shared object** | synchronized | `synchronized(lock) { }` |
| **Cache with many readers** | ReadWriteLock | Read lock for get, write lock for put |
| **Thread-safe map** | ConcurrentHashMap | Direct replacement for HashMap |
| **Thread-safe list** | CopyOnWriteArrayList | For event listeners |
| **Run tasks in thread pool** | ExecutorService | `executor.submit(task)` |
| **Schedule periodic task** | ScheduledExecutorService | `scheduleAtFixedRate()` |
| **Chain async operations** | CompletableFuture | `.thenApply().thenAccept()` |
| **Wait for N workers to finish** | CountDownLatch | Workers call `countDown()` |
| **Limit N concurrent users** | Semaphore | `acquire()` / `release()` |
| **Producer-Consumer pattern** | BlockingQueue | `put()` / `take()` |

---

## 🎬 SCENARIO-BASED SOLUTIONS

### Scenario 1: "Implement a thread-safe counter"

**Analysis**: Simple counter, many threads incrementing

**Solution**: `AtomicInteger`

```java
AtomicInteger counter = new AtomicInteger(0);

// Thread-safe increment
counter.incrementAndGet();

// Thread-safe add
counter.addAndGet(5);
```

**Why not synchronized?** Atomic is lock-free, faster for simple operations

---

### Scenario 2: "Design a cache that many threads read, few write"

**Analysis**: Read-heavy workload, need performance

**Solution**: `ReadWriteLock` + `HashMap`

```java
class Cache {
    private Map<String, String> cache = new HashMap<>();
    private ReadWriteLock lock = new ReentrantReadWriteLock();

    public String get(String key) {
        lock.readLock().lock();
        try {
            return cache.get(key);
        } finally {
            lock.readLock().unlock();
        }
    }

    public void put(String key, String value) {
        lock.writeLock().lock();
        try {
            cache.put(key, value);
        } finally {
            lock.writeLock().unlock();
        }
    }
}
```

**Alternative**: `ConcurrentHashMap` (simpler, often sufficient)

---

### Scenario 3: "Producer-Consumer with bounded buffer"

**Analysis**: Multiple producers/consumers, need blocking when full/empty

**Solution**: `ArrayBlockingQueue`

```java
BlockingQueue<Task> queue = new ArrayBlockingQueue<>(100);

// Producer thread
executor.submit(() -> {
    while (running) {
        Task task = createTask();
        queue.put(task);  // Blocks if full
    }
});

// Consumer thread
executor.submit(() -> {
    while (running) {
        Task task = queue.take();  // Blocks if empty
        process(task);
    }
});
```

**Why BlockingQueue?** Built-in blocking, thread-safe, simple

---

### Scenario 4: "Download files from multiple URLs in parallel"

**Analysis**: Async I/O, need to combine results

**Solution**: `CompletableFuture`

```java
List<String> urls = Arrays.asList("url1", "url2", "url3");

List<CompletableFuture<String>> futures = urls.stream()
    .map(url -> CompletableFuture.supplyAsync(() -> download(url)))
    .collect(Collectors.toList());

CompletableFuture<Void> allDone = CompletableFuture.allOf(
    futures.toArray(new CompletableFuture[0])
);

allDone.join();  // Wait for all
```

**Alternative**: `ExecutorService.invokeAll()` for simpler cases

---

### Scenario 5: "Rate limiter - allow max 10 requests per second"

**Analysis**: Limit concurrent access

**Solution**: `Semaphore`

```java
Semaphore rateLimiter = new Semaphore(10);

public void handleRequest(Request req) {
    if (rateLimiter.tryAcquire()) {
        try {
            processRequest(req);
        } finally {
            // Release after 1 second
            scheduler.schedule(() -> rateLimiter.release(),
                             1, TimeUnit.SECONDS);
        }
    } else {
        rejectRequest(req);
    }
}
```

**Alternative**: Guava RateLimiter, Token Bucket algorithm

---

### Scenario 6: "Wait for all services to initialize before starting"

**Analysis**: Main thread waits for N initialization tasks

**Solution**: `CountDownLatch`

```java
CountDownLatch latch = new CountDownLatch(3);

// Service 1
executor.submit(() -> {
    initializeDatabase();
    latch.countDown();
});

// Service 2
executor.submit(() -> {
    initializeCache();
    latch.countDown();
});

// Service 3
executor.submit(() -> {
    initializeMessaging();
    latch.countDown();
});

latch.await();  // Wait for all 3
System.out.println("All services ready!");
```

---

### Scenario 7: "Parallel merge sort - divide and conquer"

**Analysis**: Recursive task splitting

**Solution**: `ForkJoinPool`

```java
class MergeSort extends RecursiveAction {
    private int[] array;
    private int low, high;

    protected void compute() {
        if (high - low < THRESHOLD) {
            Arrays.sort(array, low, high);
        } else {
            int mid = (low + high) / 2;
            invokeAll(
                new MergeSort(array, low, mid),
                new MergeSort(array, mid, high)
            );
            merge(array, low, mid, high);
        }
    }
}

ForkJoinPool pool = new ForkJoinPool();
pool.invoke(new MergeSort(array, 0, array.length));
```

---

### Scenario 8: "Event listeners - many reads, rare adds/removes"

**Analysis**: Read-heavy list operations

**Solution**: `CopyOnWriteArrayList`

```java
CopyOnWriteArrayList<EventListener> listeners = new CopyOnWriteArrayList<>();

// Rare: Add listener
public void addListener(EventListener listener) {
    listeners.add(listener);  // Copies entire array
}

// Frequent: Fire event
public void fireEvent(Event event) {
    for (EventListener listener : listeners) {
        listener.onEvent(event);  // Lock-free iteration
    }
}
```

---

### Scenario 9: "Connection pool - max 10 connections"

**Analysis**: Resource pooling with limits

**Solution**: `Semaphore` + Object Pool

```java
class ConnectionPool {
    private Queue<Connection> pool = new ConcurrentLinkedQueue<>();
    private Semaphore available = new Semaphore(10);

    public Connection acquire() throws InterruptedException {
        available.acquire();
        Connection conn = pool.poll();
        return conn != null ? conn : createConnection();
    }

    public void release(Connection conn) {
        pool.offer(conn);
        available.release();
    }
}
```

---

### Scenario 10: "Lazy initialization of expensive singleton"

**Analysis**: Thread-safe lazy init, no double-checked locking bugs

**Solution**: Bill Pugh Singleton

```java
public class ExpensiveService {
    private ExpensiveService() {
        // Expensive initialization
    }

    private static class Holder {
        static final ExpensiveService INSTANCE = new ExpensiveService();
    }

    public static ExpensiveService getInstance() {
        return Holder.INSTANCE;
    }
}
```

**Why not double-checked locking?** Easy to get wrong (need volatile)

---

## 🚦 DECISION MATRICES

### Shared State Protection

| Requirement | Solution |
|-------------|----------|
| Single variable, visibility only | `volatile` |
| Counter/flag with atomic updates | `AtomicInteger/Boolean/Reference` |
| Multiple variables, simple sync | `synchronized` |
| Need timeout or tryLock | `ReentrantLock` |
| Read >> Write | `ReadWriteLock` |
| Best read performance | `StampedLock` |

### Collection Choice

| Requirement | Solution |
|-------------|----------|
| Thread-safe map | `ConcurrentHashMap` |
| Thread-safe list, read-heavy | `CopyOnWriteArrayList` |
| Thread-safe set | `ConcurrentHashMap.newKeySet()` |
| Producer-Consumer queue | `BlockingQueue` |
| Priority queue | `PriorityBlockingQueue` |
| Delayed tasks | `DelayQueue` |
| Non-blocking queue | `ConcurrentLinkedQueue` |

### Task Execution

| Requirement | Solution |
|-------------|----------|
| Thread pool for tasks | `ExecutorService` |
| Fixed number of threads | `newFixedThreadPool(N)` |
| Create threads as needed | `newCachedThreadPool()` |
| Sequential execution | `newSingleThreadExecutor()` |
| Scheduled/periodic tasks | `ScheduledExecutorService` |
| Async with chaining | `CompletableFuture` |
| Recursive divide-and-conquer | `ForkJoinPool` |

### Coordination

| Requirement | Solution |
|-------------|----------|
| Wait for N events | `CountDownLatch` |
| N threads wait for each other | `CyclicBarrier` |
| Limit N concurrent accesses | `Semaphore` |
| Exchange between 2 threads | `Exchanger` |
| Complex multi-phase | `Phaser` |

---

## 🎯 RED FLAGS (When NOT to use)

| Tool | Don't Use When | Use Instead |
|------|---------------|-------------|
| **synchronized** | Need timeout | `ReentrantLock.tryLock()` |
| **volatile** | Compound operations (count++) | `AtomicInteger` |
| **ReentrantLock** | Simple mutual exclusion | `synchronized` (simpler) |
| **CopyOnWriteArrayList** | Many writes | `Collections.synchronizedList()` |
| **ForkJoinPool** | Not divide-and-conquer | `ExecutorService` |
| **wait/notify** | Complex conditions | `ReentrantLock.newCondition()` |

---

## 💡 INTERVIEW PROBLEM PATTERNS

### Pattern: "Design thread-safe X"

**Steps**:
1. Identify shared state
2. Determine access pattern (read-heavy? write-heavy?)
3. Choose protection mechanism
4. Handle edge cases (null, empty, exceptions)

**Example**: "Design thread-safe LRU Cache"
- Shared state: Map + LinkedList
- Access: Reads and writes
- Solution: `ConcurrentHashMap` + `ReentrantLock` for ordering

### Pattern: "Implement X using Y threads"

**Steps**:
1. Create thread pool (`ExecutorService`)
2. Split work into tasks
3. Submit to executor
4. Collect results (`Future` or `CompletableFuture`)

**Example**: "Process files using 4 threads"
```java
ExecutorService executor = Executors.newFixedThreadPool(4);
List<Future<Result>> futures = files.stream()
    .map(file -> executor.submit(() -> process(file)))
    .collect(Collectors.toList());
```

### Pattern: "Coordinate multiple threads"

**Steps**:
1. Identify coordination point (start together? finish together?)
2. Choose sync utility (Latch, Barrier, Semaphore)
3. Implement coordination logic

**Example**: "Run 3 phases, threads wait at each phase"
```java
CyclicBarrier barrier = new CyclicBarrier(N);
// Each thread: phase1(); barrier.await(); phase2(); barrier.await(); phase3();
```

---

## 🧠 QUICK RECOGNITION KEYWORDS

| Keyword in Problem | Likely Solution |
|-------------------|----------------|
| "thread-safe counter" | `AtomicInteger` |
| "cache" | `ConcurrentHashMap` or `ReadWriteLock` |
| "producer-consumer" | `BlockingQueue` |
| "rate limiting" | `Semaphore` |
| "wait for all" | `CountDownLatch` |
| "thread pool" | `ExecutorService` |
| "scheduled task" | `ScheduledExecutorService` |
| "async operation" | `CompletableFuture` |
| "event listeners" | `CopyOnWriteArrayList` |
| "lazy initialization" | Bill Pugh Singleton |
| "divide and conquer" | `ForkJoinPool` |

---

## 📊 COMPLEXITY REFERENCE

### Time Complexity (Concurrent Collections)

| Operation | ConcurrentHashMap | CopyOnWriteArrayList | ConcurrentLinkedQueue |
|-----------|-------------------|----------------------|-----------------------|
| **Read** | O(1) | O(n) | O(n) |
| **Write** | O(1) | O(n) copy! | O(1) |
| **Iteration** | O(n) | O(n) | O(n) |

### Lock Overhead

| Lock Type | Overhead | Best For |
|-----------|----------|----------|
| Atomic (CAS) | Lowest | Simple operations |
| synchronized | Low | Simple critical sections |
| ReentrantLock | Medium | Complex locking needs |
| ReadWriteLock | Medium-High | Read-heavy workloads |

---

## ✅ FINAL DECISION CHECKLIST

Before choosing a concurrency tool:

1. **Can I avoid shared state?** (Immutability, ThreadLocal)
2. **Is it a simple counter?** → `AtomicInteger`
3. **Is it a complex object?** → `synchronized` or `ReentrantLock`
4. **Do I need a thread-safe collection?** → Concurrent collections
5. **Do I need task execution?** → `ExecutorService`
6. **Do I need coordination?** → Sync utilities (Latch, Barrier, etc.)
7. **Is performance critical?** → Measure and optimize

---

**🎯 Pattern: When in doubt, start simple (synchronized), then optimize if needed!**
