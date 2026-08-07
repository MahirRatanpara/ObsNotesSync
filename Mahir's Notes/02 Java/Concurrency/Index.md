# Concurrency — Index

[← Master Index](../../Master%20Index.md)

## Notes

| Note | What it covers |
|---|---|
| [Atomics and CAS](Atomics%20and%20CAS.md) | Lock-free programming underpins `ConcurrentHashMap`, `AtomicInteger`, and modern queue implementations. Interv… |
| [CompletableFuture](CompletableFuture.md) | The standard way to compose asynchronous work in Java. Interviewers use it to test whether you can parallelise… |
| [Concurrency Problem Patterns](Concurrency%20Problem%20Patterns.md) | Problem → tool lookup. When an interviewer describes a concurrency scenario, this maps it to the right primiti… |
| [Concurrent Collections](Concurrent%20Collections.md) | Choosing the right concurrent structure is usually better than writing your own synchronisation. Interviewers … |
| [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md) | Nobody creates raw threads in production. Pool sizing and queue choice are real design decisions with real out… |
| [Fork/Join and Parallel Execution](Fork%20Join%20and%20Parallel%20Execution.md) | The engine behind parallel streams and `CompletableFuture`'s default executor. Work stealing is a genuinely el… |
| [Synchronisation and Locks](Synchronisation%20and%20Locks.md) | The difference between `synchronized` and `ReentrantLock`, and knowing when each is appropriate, is standard s… |
| [Synchronizers](Synchronizers.md) | `java.util.concurrent` gives you five coordination primitives that cover almost every "make threads wait for e… |
| [Threads and Lifecycle](Threads%20and%20Lifecycle.md) | The foundation for every other concurrency topic, and the source of the most common warm-up questions. |
| [Virtual Threads and Structured Concurrency](Virtual%20Threads%20and%20Structured%20Concurrency.md) | The largest change to Java concurrency since Java 5. Virtual threads (final in 21) make thread-per-request via… |

