
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

