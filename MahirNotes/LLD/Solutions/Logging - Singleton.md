
## 🔒 1. Singleton Pattern (Expert Level)  

### 💡 Use Case: Distributed Logging System with Multi-threading Support and Lazy Initialization

  

### 🧩 Problem Statement  

You're building a distributed microservices platform. Each service logs to a central location, but within each service, all logs must go through a single logging instance (singleton) to ensure thread safety, performance, and consistency.

  

The `Logger` must:

- Be lazily initialized.

- Be thread-safe.

- Support log levels (INFO, WARN, ERROR).

- Maintain a recent in-memory cache of the last 10 log messages (ring buffer).

- Optionally support log forwarding to a centralized system (mock it for now).

  

You must ensure the singleton property holds even under reflection and serialization attacks.

  

### 🧱 Class Scaffolding

```java

public class Logger {

    // private constructor

  

    // getInstance(): static method

  

    // log(level, message): logs to console + stores in in-memory ring buffer

  

    // getRecentLogs(): returns last 10 logs

  

    // Optional: enableCentralForwarding(): mocks sending logs to central system

}

```

  

### 🧵 Concurrency Requirements

- Multiple threads can log concurrently.

- Ring buffer should be synchronized or use a lock-free structure.

- Use `volatile` and `synchronized` or alternatives like `Holder` pattern.

  

### 🧠 Hints

- Use double-checked locking or Bill Pugh’s inner static holder.

- Use `Enum`-based singleton to protect against serialization/reflection.

- Use `LinkedBlockingDeque` or `CircularFifoQueue` from Apache Commons.

- Mock forwarding using a `forwardToCentral(String log)` method (just print to stdout).

  

### ✅ Expected Output (Sample)

```

[INFO] 2025-08-01 10:00:01 - Service started

[WARN] 2025-08-01 10:05:01 - Disk usage 90%

[ERROR] 2025-08-01 10:06:01 - NullPointerException in ModuleX

```

  

### 🧪 Test Scenario

- Spawn 10 threads, each logging 50 messages.

- Validate:

  - Singleton instance is shared.

  - Only one instance is created.

  - Logs are collected safely.

  - Ring buffer holds only last 10 logs.

  - Optional: toggle central forwarding and verify logs are sent.


# Solution:

```
package Patterns.Singleton.LoggingUtil;  
  
import java.util.concurrent.ExecutorService;  
import java.util.concurrent.Executors;  
import java.util.concurrent.LinkedBlockingQueue;  
  
public class AdvancedLazyLog4j {  
    private static volatile AdvancedLazyLog4j logger;  
    private final ExecutorService executor;  
    private final LinkedBlockingQueue<String> queue;  
  
    public static AdvancedLazyLog4j getLogger() {  
        if (logger == null) {  
            synchronized (AdvancedLazyLog4j.class) {  
                if(logger == null) {  
                    logger = new AdvancedLazyLog4j();  
                }  
            }  
        }  
        return logger;  
    }  
  
    private AdvancedLazyLog4j() {  
        queue = new LinkedBlockingQueue<>();  
        executor = Executors.newSingleThreadExecutor();  
        executor.submit(this::processLog);  
    }  
  
    public void processLog() {  
        while(true) {  
            try {  
                String msg = queue.take();  
                System.out.println(msg);  
                if(msg.equals("__SHUTDOWN__")) break;  
            } catch (InterruptedException e) {  
                gracefulShutDown();  
                Thread.currentThread().interrupt();  
            }  
        }  
    }  
  
    public void log(String level, String msg) {  
        String threadName = Thread.currentThread().getName();  
        String timestamp = java.time.LocalDateTime.now().toString();  
        try {  
            queue.put(String.format("[%s] [%s] [%s] %s%n", level, timestamp, threadName, msg));  
        } catch (InterruptedException e) {  
            gracefulShutDown();  
            Thread.currentThread().interrupt();  
        }  
    }  
  
  
    public void info(String msg) {  
        log("INFO", msg);  
    }  
  
    public void warn(String msg) {  
        log("WARN", msg);  
    }  
  
    public void error(String msg) {  
        log("ERROR", msg);  
    }  
  
    public void gracefulShutDown() {  
        //gracefully logging remaining log  
        while(!queue.isEmpty()) System.out.println(queue.poll());  
        queue.offer("__SHUTDOWN__");  
        executor.shutdown();  
    }  
}
```

