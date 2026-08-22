# Scheduling and Deadlocks

## Why It Matters

Explains tail latency, why CPU limits in containers cause mysterious slowdowns, and gives you the vocabulary for deadlock questions in both OS and application contexts.

## Scheduler Goals — In Tension

| Goal | Conflicts with |
|---|---|
| **Throughput** — work per second | Latency |
| **Latency** — responsiveness | Throughput |
| **Fairness** — no starvation | Priority |
| **Priority** — important work first | Fairness |

No scheduler optimises all four. General-purpose systems favour fairness and throughput; real-time systems favour predictable latency.

## Algorithms

| Algorithm | Behaviour | Problem |
|---|---|---|
| FCFS | Run to completion in arrival order | **Convoy effect** — one long job blocks everything |
| SJF | Shortest job first | Optimal average wait, but needs the future; starves long jobs |
| **Round robin** | Fixed time slice each | Fair; quantum size trades context-switch overhead against responsiveness |
| Priority | Highest priority first | **Starvation** — fixed by ageing |
| Multi-level feedback queue | Demote CPU-heavy tasks, promote interactive ones | Complex; what most real schedulers approximate |
| **CFS (Linux)** | Track virtual runtime, always run the least-run task | Fair by construction, no fixed quantum |

**Linux CFS is the one to know.** It doesn't use fixed time slices — it tracks each task's accumulated `vruntime` and always schedules the task with the smallest value, weighted by nice level. Fairness emerges from the invariant rather than from a quantum.

## Preemptive vs Cooperative

| | Preemptive | Cooperative |
|---|---|---|
| Who yields | The scheduler forces it | The task yields voluntarily |
| Misbehaving task | Contained | **Blocks everything** |
| Used by | OS threads | Event loops, older green threads, coroutines |

**Go's goroutine scheduler was cooperative until 1.14** — a tight loop with no function calls could hang the scheduler. It's now asynchronously preemptive. **Node.js remains cooperative**, which is precisely why "don't block the event loop" is the rule.

## Priority Inversion

A high-priority task waits on a lock held by a low-priority task, which is itself preempted by a medium-priority task. The high-priority task is effectively blocked by the medium one.

**The famous case: the Mars Pathfinder rover**, which repeatedly reset in 1997 due to exactly this.

**Fixes:**
- **Priority inheritance** — the lock holder temporarily inherits the waiter's priority
- **Priority ceiling** — acquiring a lock raises priority to a predefined ceiling

## CPU Throttling In Containers

The single most valuable practical item here.

Kubernetes CPU limits are enforced by **CFS quota**: a container gets `quota` microseconds of CPU per 100 ms **period**. Exhaust the quota and the container is **frozen until the next period**.

**The consequence:** a service with a 1-core limit that briefly needs 2 cores gets throttled for up to 100 ms — appearing as unexplained p99 latency spikes with no corresponding load.

**This is worse for multi-threaded runtimes.** A JVM with 8 GC threads on a 1-core limit burns the entire quota almost instantly and stalls repeatedly.

**Mitigations:**
- Set CPU **requests** (for scheduling) and consider omitting **limits** for latency-sensitive services
- Right-size `-XX:ActiveProcessorCount` so the JVM doesn't create threads for cores it can't use
- Monitor `container_cpu_cfs_throttled_seconds_total`

**"p99 spikes with no load increase" pointing to CFS throttling is a strong diagnostic answer.**

## Deadlock — The Four Coffman Conditions

All four must hold simultaneously:

1. **Mutual exclusion** — a resource is held exclusively
2. **Hold and wait** — a holder requests more resources
3. **No preemption** — resources can't be forcibly taken
4. **Circular wait** — a cycle exists in the wait-for graph

**Break any one and deadlock is impossible.**

| Strategy | Breaks | Practicality |
|---|---|---|
| **Global lock ordering** | Circular wait | **The standard answer** |
| Acquire all locks atomically | Hold and wait | Often impractical |
| Timeout / `tryLock` and back off | Hold and wait | Practical, needs retry logic |
| Preemptible resources (transaction abort) | No preemption | What databases do |
| Lock-free algorithms | Mutual exclusion | Hard, but deadlock-free by construction |

## Detection And Recovery

Databases build a **wait-for graph** and detect cycles, then abort a victim transaction. Your application must catch the deadlock error and retry.

**Java:** `jstack` reports "Found one Java-level deadlock" with the exact cycle.

## Related Failures

| Problem | Meaning | Fix |
|---|---|---|
| **Livelock** | Threads keep responding to each other, no progress | Randomised backoff |
| **Starvation** | A thread never gets the resource | Fair locks, ageing |
| **Priority inversion** | Low-priority holder blocks high-priority waiter | Priority inheritance |
| **Convoy effect** | Fast tasks queue behind a slow one | Shorter critical sections, separate queues |

**Livelock is the subtle one:** unlike deadlock, threads are actively running — they're just achieving nothing. Two people repeatedly stepping aside for each other in a corridor is the standard analogy, and randomised backoff is the standard fix.

## Common Mistakes

- Setting CPU limits on latency-sensitive services without understanding CFS throttling
- Relying on thread priority for correctness
- Inconsistent lock ordering
- No timeout on lock acquisition, so a deadlock hangs forever instead of failing
- Not retrying after a database deadlock abort
- Confusing livelock with deadlock

## Related Topics

- [Synchronisation and Locks](Synchronisation%20and%20Locks.md)
- [Concurrency in LLD](Concurrency%20in%20LLD.md)
- [Processes and Threads](Processes%20and%20Threads.md)
- [Kubernetes Core Concepts](Kubernetes%20Core%20Concepts.md)
- [Preemption, Blocking and Thread Migration](Preemption%2C%20Blocking%20and%20Thread%20Migration.md) — the mechanism beneath "preemptive vs cooperative": timer interrupts, blocking, and CPU affinity

## Revision Summary

Schedulers trade throughput, latency, fairness, and priority; Linux CFS achieves fairness via virtual runtime. Container CPU limits throttle in 100 ms windows and are a common hidden cause of p99 spikes. Deadlock needs all four Coffman conditions — break circular wait with a global lock ordering.

## Quick Recall

- CFS: run the task with the least virtual runtime
- Node.js is cooperative — don't block the event loop
- Priority inversion → priority inheritance (Mars Pathfinder)
- **CPU limit → CFS quota → throttled up to 100 ms → p99 spikes**
- Coffman: mutual exclusion, hold-and-wait, no preemption, circular wait
- Global lock ordering breaks circular wait
- Livelock = active but no progress → randomised backoff
