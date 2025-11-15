# Complete Java & Concurrency Interview Guide
*Comprehensive reference for SDE2 interviews covering Java fundamentals, concurrency, and multithreading*

## 📚 Table of Contents

1. [Java Fundamentals](#java-fundamentals)
2. [Thread Fundamentals](#thread-fundamentals) 
3. [Locks and Synchronization](#locks-and-synchronization)
4. [Concurrent Collections](#concurrent-collections)
5. [ExecutorService and Thread Pools](#executorservice-and-thread-pools)
6. [Atomic Classes and CAS](#atomic-classes-and-cas)
7. [CompletableFuture and Async Programming](#completablefuture-and-async-programming)
8. [Memory Model and Visibility](#memory-model-and-visibility)
9. [Deadlocks and Prevention](#deadlocks-and-prevention)
10. [Performance and Best Practices](#performance-and-best-practices)
11. [Real-world Examples](#real-world-examples)
12. [Interview Questions](#interview-questions)

---

## 🔷 Java Fundamentals

### Inheritance: Class vs Abstract Class vs Interface

#### Key Differences Table

| Feature               | Class          | Abstract Class                | Interface                       |
|-----------------------|----------------|--------------------------------|----------------------------------|
| Can be instantiated   | ✅ Yes         | ❌ No                          | ❌ No                            |
| Constructors          | ✅ Yes         | ✅ Yes                         | ❌ No                            |
| Fields                | ✅ Yes         | ✅ Yes                         | ✅ (Only constants)              |
| Methods               | ✅ Yes         | ✅ Abstract + Concrete         | ✅ Abstract (default/static ok)  |
| Inheritance type      | Single         | Single                         | Multiple                        |
| Access modifiers      | Any            | Any                            | Only `public` (by default)      |

#### Diamond Problem Solution

```java
interface A {
    default void sayHello() { System.out.println("Hello from A"); }
}

interface B {
    default void sayHello() { System.out.println("Hello from B"); }
}

class C implements A, B {
    public void sayHello() {
        A.super.sayHello(); // Resolve manually
    }
}
```

#### Modern Interface Features (Java 8+)

| Feature         | Java Version | Description                            |
|-----------------|--------------|----------------------------------------|
| `default`       | Java 8       | Method with body in interface          |
| `static`        | Java 8       | Static helper methods                  |
| `private`       | Java 9       | Helper methods inside interfaces       |

```java
interface Logger {
    default void log(String msg) {
        System.out.println("LOG: " + msg);
    }
    
    static void printVersion() {
        System.out.println("Logger v1.0");
    }
}
```

#### Best Practice Decision Matrix

| Use Case                                        | Prefer            |
|------------------------------------------------|-------------------|
| Need to share common fields/methods            | Abstract class    |
| Need to enforce a contract/capability          | Interface         |
| Want multiple behaviors                        | Interface         |
| Need to extend existing class hierarchy        | Abstract class    |
| Want to support default behavior without state | Interface         |

### Common SDK Interface Examples

| Interface     | Common Implementations       | Use Case |
|---------------|------------------------------|----------|
| `Runnable`    | `Thread`, `ExecutorTask`     | Thread execution |
| `Comparable`  | `String`, `Integer`, `Date`  | Natural ordering |
| `Serializable`| `HashMap`, `ArrayList`       | Object serialization |
| `List`        | `ArrayList`, `LinkedList`    | Ordered collections |

---

## 🧵 Thread Fundamentals

### Thread Lifecycle and States

```java
public enum State {
    NEW,         // Thread created but not started
    RUNNABLE,    // Thread executing or ready to execute
    BLOCKED,     // Thread blocked waiting for monitor lock
    WAITING,     // Thread waiting indefinitely for another thread
    TIMED_WAITING, // Thread waiting for specified period
    TERMINATED   // Thread has completed execution
}
```

### Thread Creation Patterns

#### Method 1: Extending Thread Class

```java
class MyThread extends Thread {
    @Override
    public void run() {
        System.out.println("Thread: " + Thread.currentThread().getName());
    }
}

// Usage
MyThread thread = new MyThread();
thread.start();
```

#### Method 2: Implementing Runnable (Preferred)

```java
class MyTask implements Runnable {
    @Override
    public void run() {
        System.out.println("Task running in: " + Thread.currentThread().getName());
    }
}

// Usage
Thread thread = new Thread(new MyTask());
thread.start();
```

#### Method 3: Lambda Expression (Java 8+)

```java
Thread thread = new Thread(() -> {
    System.out.println("Lambda thread: " + Thread.currentThread().getName());
});
thread.start();
```

### Thread Control Methods

| Method | Purpose | Behavior |
|--------|---------|----------|
| `start()` | Begin thread execution | Calls run() in new thread |
| `join()` | Wait for thread completion | Current thread waits |
| `sleep(ms)` | Pause execution | Thread sleeps for specified time |
| `interrupt()` | Request thread interruption | Sets interrupt flag |
| `yield()` | Suggest thread scheduler | Give up CPU voluntarily |

### Thread Interruption Pattern

```java
public void interruptibleTask() {
    while (!Thread.currentThread().isInterrupted()) {
        try {
            // Some work
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // Restore interrupt status
            break;
        }
    }
}
```

---

## 🔒 Locks and Synchronization

### Synchronized Keyword

#### Method-level Synchronization

```java
public synchronized void synchronizedMethod() {
    // Only one thread can execute this method at a time
}

// Equivalent to:
public void method() {
    synchronized(this) {
        // Critical section
    }
}
```

#### Block-level Synchronization

```java
private final Object lock = new Object();

public void method() {
    synchronized(lock) {
        // Critical section using specific lock object
    }
}
```

### ReentrantLock: Advanced Locking

#### Basic Usage Pattern

```java
ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    // Critical section
} finally {
    lock.unlock(); // Always unlock in finally block
}
```

#### Advanced ReentrantLock Features

| Feature                 | `synchronized`        | `ReentrantLock`            |
|-------------------------|------------------------|-----------------------------|
| Lock acquisition        | Implicit               | Explicit (`lock()`)        |
| Lock release            | Implicit               | Explicit (`unlock()`)      |
| Reentrancy              | ✅ Yes                 | ✅ Yes                     |
| Multiple conditions     | ❌ No                  | ✅ Yes                     |
| Fairness                | ❌ No                  | ✅ With constructor         |
| Try lock                | ❌ No                  | ✅ (`tryLock()`)            |
| Interruptible wait      | ❌ No                  | ✅ (`lockInterruptibly()`)  |

#### Fair vs Unfair Locking

```java
// Unfair lock (default) - higher throughput
ReentrantLock unfairLock = new ReentrantLock();

// Fair lock - prevents thread starvation
ReentrantLock fairLock = new ReentrantLock(true);
```

#### Condition Variables with ReentrantLock

```java
class BoundedBlockingQueue {
    private Queue<Integer> queue = new LinkedList<>();
    private int capacity;
    private ReentrantLock lock = new ReentrantLock();
    private Condition notFull = lock.newCondition();
    private Condition notEmpty = lock.newCondition();

    public void enqueue(int element) throws InterruptedException {
        lock.lock();
        try {
            while (queue.size() == capacity) {
                notFull.await(); // Wait for space
            }
            queue.offer(element);
            notEmpty.signal(); // Notify consumers
        } finally {
            lock.unlock();
        }
    }

    public int dequeue() throws InterruptedException {
        lock.lock();
        try {
            while (queue.isEmpty()) {
                notEmpty.await(); // Wait for elements
            }
            int item = queue.poll();
            notFull.signal(); // Notify producers
            return item;
        } finally {
            lock.unlock();
        }
    }
}
```

### ReadWriteLock for Read-Heavy Workloads

```java
ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
Lock readLock = rwLock.readLock();
Lock writeLock = rwLock.writeLock();

// Multiple readers can access simultaneously
public String read() {
    readLock.lock();
    try {
        return data;
    } finally {
        readLock.unlock();
    }
}

// Only one writer can access at a time
public void write(String newData) {
    writeLock.lock();
    try {
        data = newData;
    } finally {
        writeLock.unlock();
    }
}
```

---

## 📦 Concurrent Collections

### ConcurrentHashMap Deep Dive

#### Architecture and Thread Safety

- Uses **bucket-level locking** instead of full synchronization
- **CAS operations** for atomic updates
- **Lock-free reads** for better performance
- **Segment-based** design for reduced contention

```java
ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();

// Thread-safe operations
map.put("key", 1);
map.compute("key", (k, v) -> v == null ? 1 : v + 1);
map.merge("key", 1, Integer::sum);
```

#### Compare-and-Swap (CAS) Pattern

```java
// CAS pattern for atomic updates
while (true) {
    int current = atomicValue.get();           // 1. Read current value
    int newValue = computeNewValue(current);   // 2. Calculate desired value
    
    if (atomicValue.compareAndSet(current, newValue)) {
        break; // 3. Success! Update completed atomically
    }
    // 4. Retry if another thread modified the value
}
```

### Thread-Safe Collection Alternatives

| Use Case | Thread-Safe Option | Performance Characteristics |
|----------|-------------------|----------------------------|
| List operations | `Collections.synchronizedList()` | Full synchronization overhead |
| List operations | `CopyOnWriteArrayList` | Excellent reads, expensive writes |
| Set operations | `ConcurrentHashMap.newKeySet()` | High concurrency |
| Queue operations | `LinkedBlockingQueue` | Blocking when empty/full |
| Queue operations | `ConcurrentLinkedQueue` | Non-blocking, wait-free |
| Deque operations | `LinkedBlockingDeque` | Blocking double-ended queue |

### CopyOnWriteArrayList for Read-Heavy Scenarios

```java
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();

// Reads are fast and never block
public String read(int index) {
    return list.get(index); // No synchronization needed
}

// Writes create new copy (expensive)
public void write(String item) {
    list.add(item); // Creates new internal array
}
```

---

## ⚙️ ExecutorService and Thread Pools

### ThreadPool Types and Use Cases

```java
// Fixed thread pool - predictable resource usage
ExecutorService fixedPool = Executors.newFixedThreadPool(4);

// Cached thread pool - auto-scaling
ExecutorService cachedPool = Executors.newCachedThreadPool();

// Single thread executor - sequential execution
ExecutorService singleExecutor = Executors.newSingleThreadExecutor();

// Scheduled executor - delayed/periodic tasks
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
```

### Custom ThreadPoolExecutor Configuration

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    2,                      // corePoolSize
    4,                      // maximumPoolSize  
    60L,                    // keepAliveTime
    TimeUnit.SECONDS,       // time unit
    new LinkedBlockingQueue<>(100), // work queue
    Executors.defaultThreadFactory(), // thread factory
    new ThreadPoolExecutor.CallerRunsPolicy() // rejection policy
);
```

### Rejection Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `AbortPolicy` | Throws `RejectedExecutionException` | Fail-fast systems |
| `CallerRunsPolicy` | Runs task in calling thread | Throttling mechanism |
| `DiscardPolicy` | Silently discards task | Non-critical tasks |
| `DiscardOldestPolicy` | Discards oldest queued task | Latest data priority |

### Proper Executor Shutdown

```java
public void shutdownExecutor(ExecutorService executor) {
    executor.shutdown(); // Initiate shutdown
    
    try {
        if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
            executor.shutdownNow(); // Force shutdown
            
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                System.err.println("Executor did not terminate");
            }
        }
    } catch (InterruptedException e) {
        executor.shutdownNow();
        Thread.currentThread().interrupt();
    }
}
```

### Future and Task Submission

```java
// Submit Callable task
Future<String> future = executor.submit(() -> {
    return "Task result";
});

// Get result (blocking)
try {
    String result = future.get(5, TimeUnit.SECONDS);
} catch (TimeoutException e) {
    future.cancel(true); // Interrupt if running
}

// Submit multiple tasks
List<Callable<String>> tasks = Arrays.asList(
    () -> "Task 1",
    () -> "Task 2"
);

List<Future<String>> futures = executor.invokeAll(tasks);
```

---

## ⚛️ Atomic Classes and CAS

### Atomic Primitives

```java
AtomicInteger atomicInt = new AtomicInteger(0);
AtomicLong atomicLong = new AtomicLong(0L);
AtomicBoolean atomicBool = new AtomicBoolean(false);
AtomicReference<String> atomicRef = new AtomicReference<>();
```

### Lock-Free Counter Implementation

```java
public class CASCounter {
    private final AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        while (true) {
            int current = count.get();
            if (count.compareAndSet(current, current + 1)) {
                break; // Success!
            }
            // Retry on failure
        }
    }
    
    // More efficient using built-in atomic operation
    public void incrementEfficient() {
        count.incrementAndGet();
    }
}
```

### AtomicReference for Object Updates

```java
public class AtomicStack<T> {
    private final AtomicReference<Node<T>> head = new AtomicReference<>();
    
    private static class Node<T> {
        final T data;
        final Node<T> next;
        
        Node(T data, Node<T> next) {
            this.data = data;
            this.next = next;
        }
    }
    
    public void push(T item) {
        Node<T> newNode = new Node<>(item, null);
        Node<T> currentHead;
        
        do {
            currentHead = head.get();
            newNode.next = currentHead;
        } while (!head.compareAndSet(currentHead, newNode));
    }
    
    public T pop() {
        Node<T> currentHead;
        Node<T> newHead;
        
        do {
            currentHead = head.get();
            if (currentHead == null) return null;
            newHead = currentHead.next;
        } while (!head.compareAndSet(currentHead, newHead));
        
        return currentHead.data;
    }
}
```

### ABA Problem and Solutions

#### The Problem
```java
// Thread 1 sees value A
int current = atomicRef.get(); // Gets A

// Thread 2 changes A -> B -> A
// Thread 1's CAS succeeds but data may be corrupted
atomicRef.compareAndSet(current, newValue); // May succeed incorrectly
```

#### Solution: AtomicStampedReference
```java
AtomicStampedReference<String> stampedRef = 
    new AtomicStampedReference<>("A", 0);

int[] stampHolder = new int[1];
String current = stampedRef.get(stampHolder);
int stamp = stampHolder[0];

// CAS with stamp comparison
boolean success = stampedRef.compareAndSet(
    current, newValue, stamp, stamp + 1
);
```

---

## 🚀 CompletableFuture and Async Programming

### Basic CompletableFuture Operations

```java
// Create completed future
CompletableFuture<String> completedFuture = 
    CompletableFuture.completedFuture("Hello");

// Async supply
CompletableFuture<String> asyncFuture = 
    CompletableFuture.supplyAsync(() -> {
        return "Computed value";
    });

// Async run (no return value)
CompletableFuture<Void> runAsync = 
    CompletableFuture.runAsync(() -> {
        System.out.println("Running asynchronously");
    });
```

### Chaining and Transformation

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> "Hello")
    .thenApply(s -> s + " World")
    .thenApply(String::toUpperCase);

// Handle both success and failure
CompletableFuture<String> handled = future
    .handle((result, exception) -> {
        if (exception != null) {
            return "Error: " + exception.getMessage();
        }
        return result;
    });
```

### Combining Multiple Futures

```java
CompletableFuture<String> future1 = 
    CompletableFuture.supplyAsync(() -> "Hello");
CompletableFuture<String> future2 = 
    CompletableFuture.supplyAsync(() -> "World");

// Combine two futures
CompletableFuture<String> combined = future1
    .thenCombine(future2, (s1, s2) -> s1 + " " + s2);

// Wait for all futures
CompletableFuture<Void> allOf = 
    CompletableFuture.allOf(future1, future2);

// Wait for any future
CompletableFuture<Object> anyOf = 
    CompletableFuture.anyOf(future1, future2);
```

### Error Handling Patterns

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> {
        if (Math.random() > 0.5) {
            throw new RuntimeException("Random error");
        }
        return "Success";
    })
    .exceptionally(throwable -> {
        return "Fallback value";
    })
    .whenComplete((result, exception) -> {
        if (exception != null) {
            System.err.println("Error occurred: " + exception);
        } else {
            System.out.println("Result: " + result);
        }
    });
```

---

## 🧠 Memory Model and Visibility

### Java Memory Model Fundamentals

#### Happens-Before Relationships

1. **Program Order**: Instructions in a thread execute in program order
2. **Monitor Lock**: Unlock happens-before subsequent lock of same monitor
3. **Volatile**: Write to volatile field happens-before read of same field
4. **Thread Start**: `Thread.start()` happens-before any action in started thread
5. **Thread Join**: Any action in thread happens-before `join()` returns

### Volatile Keyword

```java
public class VolatileExample {
    private volatile boolean flag = false;
    private int counter = 0;
    
    // Writer thread
    public void writer() {
        counter = 42;  // 1
        flag = true;   // 2 - volatile write
    }
    
    // Reader thread
    public void reader() {
        if (flag) {           // 3 - volatile read
            int value = counter; // 4 - guaranteed to see 42
        }
    }
}
```

### Memory Visibility Patterns

#### Double-Checked Locking (Correct Implementation)

```java
public class Singleton {
    private volatile static Singleton instance;
    
    public static Singleton getInstance() {
        if (instance == null) {                    // First check
            synchronized(Singleton.class) {
                if (instance == null) {            // Second check
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

#### Safe Publication Patterns

```java
// 1. Static initialization (thread-safe)
public class SafePublication {
    private static final List<String> list = new ArrayList<>();
}

// 2. Volatile field
public volatile List<String> volatileList;

// 3. Final field (if immutable)
public final List<String> finalList;

// 4. Synchronized method/block
public synchronized List<String> getList() {
    return list;
}
```

---

## 💀 Deadlocks and Prevention

### Classic Deadlock Example

```java
public class DeadlockExample {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();
    
    public void method1() {
        synchronized(lock1) {
            synchronized(lock2) {
                // Critical section
            }
        }
    }
    
    public void method2() {
        synchronized(lock2) {  // Different order!
            synchronized(lock1) {
                // Critical section
            }
        }
    }
}
```

### Deadlock Prevention Strategies

#### 1. Lock Ordering

```java
public class OrderedLocking {
    private static final Object lock1 = new Object();
    private static final Object lock2 = new Object();
    
    public void method1() {
        synchronized(lock1) {    // Always acquire in same order
            synchronized(lock2) {
                // Critical section
            }
        }
    }
    
    public void method2() {
        synchronized(lock1) {    // Same order prevents deadlock
            synchronized(lock2) {
                // Critical section
            }
        }
    }
}
```

#### 2. Timeout-based Locking

```java
public boolean tryLockWithTimeout(ReentrantLock lock1, ReentrantLock lock2) {
    boolean acquired1 = false;
    boolean acquired2 = false;
    
    try {
        acquired1 = lock1.tryLock(5, TimeUnit.SECONDS);
        if (!acquired1) return false;
        
        acquired2 = lock2.tryLock(5, TimeUnit.SECONDS);
        if (!acquired2) return false;
        
        // Both locks acquired - do work
        return true;
        
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return false;
    } finally {
        if (acquired2) lock2.unlock();
        if (acquired1) lock1.unlock();
    }
}
```

#### 3. Detecting and Breaking Deadlocks

```java
// JMX-based deadlock detection
ThreadMXBean bean = ManagementFactory.getThreadMXBean();
long[] deadlockedThreads = bean.findDeadlockedThreads();

if (deadlockedThreads != null) {
    ThreadInfo[] infos = bean.getThreadInfo(deadlockedThreads);
    for (ThreadInfo info : infos) {
        System.out.println("Deadlocked thread: " + info.getThreadName());
    }
}
```

### Concurrency Control Approaches

#### Optimistic vs Pessimistic Concurrency

| Approach | Assumption | Strategy | Best For |
|----------|------------|----------|----------|
| **Pessimistic** | Conflicts likely | Lock early, prevent conflicts | Financial systems, high contention |
| **Optimistic** | Conflicts rare | Check at commit time | Analytics, read-heavy systems |

#### Optimistic Concurrency Example

```java
public class OptimisticCounter {
    private volatile int version = 0;
    private volatile int value = 0;
    
    public boolean updateValue(int expectedVersion, int newValue) {
        synchronized(this) {
            if (version == expectedVersion) {
                value = newValue;
                version++;
                return true; // Success
            }
            return false; // Conflict - retry
        }
    }
    
    public int getValue() {
        return value;
    }
    
    public int getVersion() {
        return version;
    }
}
```

---

## ⚡ Performance and Best Practices

### Thread Pool Sizing Guidelines

#### CPU-Intensive Tasks
```java
// Formula: Number of CPU cores
int cpuIntensivePoolSize = Runtime.getRuntime().availableProcessors();

ExecutorService cpuPool = Executors.newFixedThreadPool(cpuIntensivePoolSize);
```

#### I/O-Intensive Tasks
```java
// Formula: CPU cores × (1 + wait time / compute time)
// Example: 4 cores, 90% I/O wait = 4 × (1 + 9) = 40 threads
int ioIntensivePoolSize = Runtime.getRuntime().availableProcessors() * 10;

ExecutorService ioPool = Executors.newFixedThreadPool(ioIntensivePoolSize);
```

### Performance Monitoring

```java
public class ThreadPoolMonitor {
    private final ThreadPoolExecutor executor;
    
    public void logStats() {
        System.out.printf(
            "Pool Size: %d, Active: %d, Completed: %d, Queue: %d%n",
            executor.getPoolSize(),
            executor.getActiveCount(),
            executor.getCompletedTaskCount(),
            executor.getQueue().size()
        );
    }
}
```

### Best Practices Checklist

#### ✅ DO
- Use `final` for thread-safe immutability
- Prefer `concurrent` collections over synchronized wrappers
- Use thread pools instead of creating threads directly
- Always unlock in `finally` blocks
- Use atomic operations for simple state changes
- Design for thread safety from the beginning

#### ❌ DON'T
- Don't use `Thread.stop()`, `Thread.suspend()`, `Thread.resume()`
- Don't synchronize on mutable objects
- Don't hold locks while calling external methods
- Don't ignore `InterruptedException`
- Don't use double-checked locking without `volatile`
- Don't access collections concurrently without proper synchronization

---

## 🌍 Real-world Examples

### Multi-threaded Web Crawler

#### Solution 1: Using Blocking Queue with Timeout

```java
public class WebCrawler {
    private final LinkedBlockingQueue<String> nextUp = new LinkedBlockingQueue<>();
    private final Set<String> seen = ConcurrentHashMap.newKeySet();
    private final List<String> results = Collections.synchronizedList(new ArrayList<>());
    private final AtomicInteger workers = new AtomicInteger(0);
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();

    public List<String> crawl(String startUrl, HtmlParser htmlParser) {
        String startHost = extractHost(startUrl);
        seen.add(startUrl);
        nextUp.offer(startUrl);

        while (true) {
            try {
                String url = nextUp.poll(100, TimeUnit.MILLISECONDS);
                
                if (url != null) {
                    results.add(url);
                    workers.incrementAndGet();
                    executor.submit(() -> processUrl(url, startHost, htmlParser));
                } else if (workers.get() == 0) {
                    break; // No more work
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }

        executor.shutdown();
        return results;
    }

    private void processUrl(String url, String host, HtmlParser htmlParser) {
        try {
            for (String nextUrl : htmlParser.getUrls(url)) {
                if (extractHost(nextUrl).equals(host) && seen.add(nextUrl)) {
                    nextUp.offer(nextUrl);
                }
            }
        } finally {
            workers.decrementAndGet();
        }
    }
}
```

#### Solution 2: Using Semaphore for Coordination

```java
public class SemaphoreCrawler {
    private final LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<>();
    private final Set<String> visited = ConcurrentHashMap.newKeySet();
    private final List<String> results = Collections.synchronizedList(new ArrayList<>());
    private final AtomicInteger activeWorkers = new AtomicInteger(0);
    private final Semaphore signal = new Semaphore(0); // Wake-up signal
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();

    public List<String> crawl(String startUrl, HtmlParser htmlParser) {
        String targetHost = extractHost(startUrl);
        visited.add(startUrl);
        queue.offer(startUrl);

        while (true) {
            String url = queue.poll();
            
            if (url != null) {
                results.add(url);
                activeWorkers.incrementAndGet();
                executor.submit(() -> processUrl(url, targetHost, htmlParser));
            } else {
                if (activeWorkers.get() == 0) break; // Done
                
                try {
                    signal.acquire(); // Wait for signal
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }

        shutdownExecutor();
        return results;
    }

    private void processUrl(String url, String host, HtmlParser htmlParser) {
        try {
            for (String nextUrl : htmlParser.getUrls(url)) {
                if (extractHost(nextUrl).equals(host) && visited.add(nextUrl)) {
                    queue.offer(nextUrl);
                    signal.release(); // Signal new work available
                }
            }
        } finally {
            if (activeWorkers.decrementAndGet() == 0) {
                signal.release(); // Signal completion
            }
        }
    }
}
```

### Producer-Consumer with Multiple Conditions

```java
public class MultiConditionBuffer<T> {
    private final Queue<T> buffer = new LinkedList<>();
    private final int capacity;
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notEmpty = lock.newCondition();
    private final Condition notFull = lock.newCondition();
    private volatile boolean shutdown = false;

    public boolean produce(T item, long timeout, TimeUnit unit) 
            throws InterruptedException {
        lock.lock();
        try {
            long nanos = unit.toNanos(timeout);
            
            while (buffer.size() >= capacity && !shutdown) {
                if (nanos <= 0) return false;
                nanos = notFull.awaitNanos(nanos);
            }
            
            if (shutdown) return false;
            
            buffer.offer(item);
            notEmpty.signal();
            return true;
        } finally {
            lock.unlock();
        }
    }

    public T consume(long timeout, TimeUnit unit) throws InterruptedException {
        lock.lock();
        try {
            long nanos = unit.toNanos(timeout);
            
            while (buffer.isEmpty() && !shutdown) {
                if (nanos <= 0) return null;
                nanos = notEmpty.awaitNanos(nanos);
            }
            
            T item = buffer.poll();
            if (item != null) {
                notFull.signal();
            }
            return item;
        } finally {
            lock.unlock();
        }
    }

    public void shutdown() {
        lock.lock();
        try {
            shutdown = true;
            notEmpty.signalAll();
            notFull.signalAll();
        } finally {
            lock.unlock();
        }
    }
}
```

---

## ❓ Interview Questions

### Beginner Level

**Q: What's the difference between `start()` and `run()` methods?**

A: `start()` creates a new thread and calls `run()` in that thread. `run()` executes in the current thread.

```java
Thread t = new Thread(() -> System.out.println("New thread"));
t.start(); // Creates new thread
t.run();   // Runs in current thread
```

**Q: Why use `volatile` keyword?**

A: `volatile` ensures:
- Visibility across threads
- Prevents reordering of operations
- No atomicity guarantee for compound operations

**Q: When would you use `ConcurrentHashMap` over `HashMap`?**

A: When multiple threads need to access/modify the map concurrently. `HashMap` can cause infinite loops in concurrent access.

### Intermediate Level

**Q: Explain the difference between fair and unfair locks.**

A: 
- **Fair lock**: Threads acquire lock in request order (FIFO)
- **Unfair lock**: Threads may "cut in line" for better performance

```java
ReentrantLock unfairLock = new ReentrantLock(); // Default
ReentrantLock fairLock = new ReentrantLock(true);
```

**Q: What is the ABA problem and how to solve it?**

A: Thread reads A, value changes A→B→A, thread's CAS succeeds but data may be corrupted.

Solution: Use `AtomicStampedReference` or `AtomicMarkableReference`.

**Q: How does `CompletableFuture` differ from `Future`?**

A: `CompletableFuture` allows:
- Chaining operations
- Combining multiple futures  
- Exception handling
- Manual completion

### Advanced Level

**Q: Design a thread-safe cache with expiration.**

```java
public class ExpiringCache<K, V> {
    private final ConcurrentHashMap<K, CacheEntry<V>> cache = new ConcurrentHashMap<>();
    private final ScheduledExecutorService cleanup = 
        Executors.newScheduledThreadPool(1);
    private final long expirationMillis;
    
    private static class CacheEntry<V> {
        final V value;
        final long timestamp;
        
        CacheEntry(V value) {
            this.value = value;
            this.timestamp = System.currentTimeMillis();
        }
        
        boolean isExpired(long expirationMillis) {
            return System.currentTimeMillis() - timestamp > expirationMillis;
        }
    }
    
    public ExpiringCache(long expirationMillis) {
        this.expirationMillis = expirationMillis;
        // Schedule cleanup every minute
        cleanup.scheduleWithFixedDelay(this::cleanup, 60, 60, TimeUnit.SECONDS);
    }
    
    public V get(K key) {
        CacheEntry<V> entry = cache.get(key);
        if (entry != null && !entry.isExpired(expirationMillis)) {
            return entry.value;
        }
        cache.remove(key); // Remove expired entry
        return null;
    }
    
    public void put(K key, V value) {
        cache.put(key, new CacheEntry<>(value));
    }
    
    private void cleanup() {
        cache.entrySet().removeIf(entry -> 
            entry.getValue().isExpired(expirationMillis));
    }
}
```

**Q: Implement a rate limiter using token bucket algorithm.**

```java
public class TokenBucket {
    private final long capacity;
    private final long refillRate; // tokens per second
    private final AtomicReference<BucketState> state;
    
    private static class BucketState {
        final long tokens;
        final long lastRefill;
        
        BucketState(long tokens, long lastRefill) {
            this.tokens = tokens;
            this.lastRefill = lastRefill;
        }
    }
    
    public TokenBucket(long capacity, long refillRate) {
        this.capacity = capacity;
        this.refillRate = refillRate;
        this.state = new AtomicReference<>(
            new BucketState(capacity, System.currentTimeMillis()));
    }
    
    public boolean tryAcquire(long tokens) {
        while (true) {
            BucketState current = state.get();
            long now = System.currentTimeMillis();
            long elapsed = now - current.lastRefill;
            
            // Calculate new token count
            long newTokens = Math.min(capacity, 
                current.tokens + (elapsed * refillRate / 1000));
            
            if (newTokens < tokens) {
                return false; // Not enough tokens
            }
            
            BucketState newState = new BucketState(newTokens - tokens, now);
            if (state.compareAndSet(current, newState)) {
                return true;
            }
            // Retry if CAS failed
        }
    }
}
```

### System Design Questions

**Q: Design a thread-safe singleton with lazy initialization.**

```java
public class ThreadSafeSingleton {
    // Using enum (best approach)
    public enum SingletonEnum {
        INSTANCE;
        
        public void doSomething() {
            // Implementation
        }
    }
    
    // Using initialization-on-demand holder
    public static class Holder {
        private static final ThreadSafeSingleton INSTANCE = new ThreadSafeSingleton();
    }
    
    public static ThreadSafeSingleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

**Q: How would you detect and handle deadlocks in a production system?**

```java
public class DeadlockDetector {
    private final ThreadMXBean threadBean = ManagementFactory.getThreadMXBean();
    private final ScheduledExecutorService scheduler = 
        Executors.newScheduledThreadPool(1);
    
    public void startMonitoring() {
        scheduler.scheduleWithFixedDelay(
            this::checkForDeadlocks, 10, 10, TimeUnit.SECONDS);
    }
    
    private void checkForDeadlocks() {
        long[] deadlockedThreads = threadBean.findDeadlockedThreads();
        
        if (deadlockedThreads != null) {
            ThreadInfo[] infos = threadBean.getThreadInfo(deadlockedThreads);
            
            // Log deadlock information
            for (ThreadInfo info : infos) {
                System.err.printf("Deadlocked thread: %s, State: %s%n",
                    info.getThreadName(), info.getThreadState());
                
                // Log stack trace
                for (StackTraceElement element : info.getStackTrace()) {
                    System.err.println("\t" + element);
                }
            }
            
            // Handle deadlock (restart affected threads, etc.)
            handleDeadlock(deadlockedThreads);
        }
    }
    
    private void handleDeadlock(long[] threadIds) {
        // Implementation depends on application requirements
        // Could interrupt threads, restart services, etc.
    }
}
```

---

## 📋 Quick Reference Cheat Sheet

### Thread States
```
NEW → RUNNABLE → BLOCKED/WAITING/TIMED_WAITING → TERMINATED
```

### Synchronization Mechanisms
| Mechanism | Use Case | Performance | Flexibility |
|-----------|----------|-------------|-------------|
| `synchronized` | Simple mutual exclusion | Good | Limited |
| `ReentrantLock` | Advanced locking needs | Good | High |
| `volatile` | Visibility only | Excellent | Limited |
| Atomic classes | Simple atomic operations | Excellent | Medium |

### Collections Thread Safety
| Collection | Thread Safe | Alternative |
|------------|-------------|-------------|
| `ArrayList` | ❌ | `CopyOnWriteArrayList` |
| `HashMap` | ❌ | `ConcurrentHashMap` |
| `HashSet` | ❌ | `ConcurrentHashMap.newKeySet()` |
| `ArrayDeque` | ❌ | `LinkedBlockingDeque` |

### Memory Visibility
- `volatile` - Single variable visibility
- `synchronized` - Mutual exclusion + visibility  
- `final` - Immutable field visibility
- Atomic classes - Atomic operations + visibility

---

## 🏷️ Tags

#java #concurrency #multithreading #thread-safety #synchronization #locks #atomic #memory-model #performance #interview-prep #sde2 #system-design

## 📚 Related Topics

- [[Complete-HLD-Guide|System Design Patterns]]
- [[Complete-Patterns-Guide|DSA Patterns]]  
- [[05-Low-Level-Design/Design-Patterns-Guide|Design Patterns]]
- [[06-Behavioral-Interview/Complete-Behavioral-Guide|Behavioral Interview]]