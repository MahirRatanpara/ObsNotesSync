
# 🧵 Java Thread Executors – Full Notes (Based on CodeWithAryan Article)

---

## ✅ Why Use Thread Executors?

Thread Executors provide a **structured concurrency framework** that abstracts direct thread handling and lets developers focus on **task logic** rather than thread lifecycle.

### Key Advantages:

|Feature|Explanation|
|---|---|
|**🧩 Task Abstraction**|You submit a task without creating or managing threads.|
|**🛠 Built-in Thread Pools**|Reduces overhead by reusing threads.|
|**⏱ Scheduling Support**|Delay and periodic scheduling (e.g. cron jobs).|
|**📉 Resource Management**|Avoids uncontrolled thread creation.|
|**📊 Monitoring Support**|Active thread count, queued tasks, etc.|
|**🛑 Graceful Shutdown**|Ensures clean exit and resource cleanup.|

---

## 🔑 Core Interfaces & Classes

### 1. **Executor**

Basic interface with one method:

```java
void execute(Runnable command);
```

- No result tracking.
 
- Abstracts thread creation (e.g. using `new Thread(command).start()` internally).
 

---

### 2. **ExecutorService**

Extends `Executor` and adds:

- `submit()` for task result tracking.
 
- `invokeAll()` to run collections of tasks.
 
- `shutdown()` and `shutdownNow()` for lifecycle control.
 

```java
ExecutorService executor = Executors.newFixedThreadPool(2);
Future<String> future = executor.submit(() -> "Hello");
System.out.println(future.get()); // "Hello"
executor.shutdown();
```

---

### 3. **ScheduledExecutorService**

For **delayed or periodic task execution**.

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
scheduler.scheduleAtFixedRate(() -> {
 System.out.println("Every 2 seconds");
}, 0, 2, TimeUnit.SECONDS);
```

---

### 4. **ThreadPoolExecutor**

Directly configurable thread pool:

```java
ThreadPoolExecutor pool = new ThreadPoolExecutor(
 2, 4, 60, TimeUnit.SECONDS,
 new LinkedBlockingQueue<>()
);
```

Control:

- `corePoolSize`, `maximumPoolSize`
 
- `keepAliveTime`, `BlockingQueue`
 
- `ThreadFactory`, `RejectedExecutionHandler`
 

---

### 5. **ScheduledThreadPoolExecutor**

Concrete class for `ScheduledExecutorService`. Enables:

- Delayed execution
 
- Periodic fixed-rate or fixed-delay tasks
 

```java
ScheduledThreadPoolExecutor scheduledPool = new ScheduledThreadPoolExecutor(1);
scheduledPool.schedule(() -> System.out.println("After 5s"), 5, TimeUnit.SECONDS);
```

---

### 6. **Executors (Factory Class)**

Convenience class for executor creation:

```java
Executors.newFixedThreadPool(int nThreads);
Executors.newCachedThreadPool();
Executors.newSingleThreadExecutor();
Executors.newScheduledThreadPool(int corePoolSize);
```

---

## 🧰 Core ExecutorService Methods

### 🟡 `execute(Runnable command)`

- Fire-and-forget.
 
- No result tracking.
 
- Errors are lost unless manually logged.
 

```java
executor.execute(() -> System.out.println("Executed"));
```

---

### 🟢 `submit(Runnable | Callable)`

- Returns `Future<?>` for result or status.
 

```java
Future<String> future = executor.submit(() -> "Done");
System.out.println(future.get()); // "Done"
```

- Exceptions are captured and rethrown on `get()`.
 
- You can use `isDone()` or `isCancelled()`.
 

---

### 🔵 `invokeAll(Collection<Callable>)`

- Runs tasks in parallel.
 
- Blocks until all complete.
 

```java
List<Future<String>> results = executor.invokeAll(Arrays.asList(
 () -> "A", () -> "B"
));
```

- Failing tasks return `Future` with exceptions.
 
- Timeout version available.
 

---

### 🔴 `shutdown()` and `shutdownNow()`

- `shutdown()`: orderly shutdown (existing tasks complete).
 
- `shutdownNow()`: interrupts ongoing tasks, returns pending ones.
 

---

## ⏰ ScheduledExecutorService Methods

### `schedule()`

```java
scheduler.schedule(() -> println("Delayed"), 2, TimeUnit.SECONDS);
```

### `scheduleAtFixedRate()`

Runs at a consistent interval **between task start times**.

```java
scheduler.scheduleAtFixedRate(task, 0, 3, TimeUnit.SECONDS);
```

### `scheduleWithFixedDelay()`

Waits for task to complete, then delays before next run.

```java
scheduler.scheduleWithFixedDelay(task, 0, 3, TimeUnit.SECONDS);
```

---

## ⚙️ ThreadPoolExecutor Configuration Parameters

|Parameter|Description|
|---|---|
|`corePoolSize`|Min number of always-alive threads|
|`maximumPoolSize`|Max threads allowed|
|`keepAliveTime`|Time idle threads are kept|
|`workQueue`|Holds pending tasks|
|`threadFactory`|Custom thread creation logic|
|`rejectionHandler`|Handles task rejection|

---

## 🔍 Internals: Task Execution Flow

1. If running threads < `corePoolSize`: create a new thread.
 
2. Else, queue the task.
 
3. If queue full & threads < `maxPoolSize`: create new thread.
 
4. Else: reject task via `RejectedExecutionHandler`.
 

---

## 💡 Interview FAQs

### 1. `execute()` vs `submit()`

|Method|Returns|Can handle Callable?|Exception Handling|
|---|---|---|---|
|`execute()`|void|❌|Not captured|
|`submit()`|Future|✅|Captured via `get()`|

---

### 2. What if `shutdown()` is not called?

- JVM won't exit as non-daemon threads stay alive.
 
- May cause memory/resource leaks.
 

---

### 3. `scheduleAtFixedRate()` vs `scheduleWithFixedDelay()`

|Method|Execution Starts|May Overlap?|
|---|---|---|
|`FixedRate`|Fixed time intervals|✅ Yes|
|`FixedDelay`|After previous finishes + delay|❌ No|

---

### 4. How are exceptions handled in tasks?

- **With `submit()`**: Exceptions thrown inside tasks are wrapped in `ExecutionException` and rethrown on `get()`.
 

```java
try {
 future.get();
} catch (ExecutionException e) {
 System.out.println(e.getCause()); // Original exception
}
```

- **Best Practice**: Catch inside task if local handling is needed.
 

---

## 🔚 Conclusion

Thread Executors in Java provide:

- **Structured concurrency** over raw threads.
 
- Built-in pooling, queuing, scheduling, and monitoring.
 
- Fine-grained control via `ThreadPoolExecutor`.
 

They’re essential for building **robust, scalable**, and **resource-efficient** applications.
