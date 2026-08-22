# Processes and Threads

## Why It Matters

Explains why thread pools are sized the way they are, why context switching costs, and what virtual threads and async I/O actually solve.

## Process vs Thread

| | Process | Thread |
|---|---|---|
| Address space | **Own, isolated** | **Shared** with other threads in the process |
| Contains | Code, data, heap, one or more threads | Stack, registers, program counter |
| Creation cost | High (~ms) | Lower (~µs) |
| Context switch cost | **High — TLB flush** | Lower — same address space |
| Communication | IPC (pipes, sockets, shared memory) | **Shared memory directly** |
| Failure isolation | **One crash doesn't affect others** | **One crash kills the process** |

**The trade is isolation vs cost.** Processes are safe and expensive; threads are cheap and dangerous. Chrome uses a process per tab for isolation; a web server uses threads for efficiency.

## What A Thread Costs

| Resource | Typical |
|---|---|
| Stack | **1 MB** reserved (Java default, `-Xss`) |
| Kernel structures | A few KB |
| Context switch | 1–10 µs |

**1 MB per thread is why you can't have 100,000 OS threads.** 10,000 threads reserves 10 GB of virtual address space. This single number explains thread pools, async I/O, and virtual threads.

## Context Switching

Saving one thread's registers and restoring another's. Costs:

1. **Direct** — the save/restore itself, ~1–5 µs
2. **Indirect — cache pollution.** The new thread's working set isn't in L1/L2, so it runs slowly until the caches refill. **This is usually the larger cost.**
3. **TLB flush** on a process switch (address space changes) — avoided between threads of the same process

**Practical implication:** more threads than cores means the CPU spends time switching rather than working. This is why CPU-bound pools are sized at `N_cpu + 1`.

## Why I/O-Bound Pools Are Sized Differently

A thread blocked on I/O consumes no CPU. So for I/O-bound work you *want* more threads than cores:

```
threads = N_cpu × (1 + wait_time / service_time)
```

8 cores, 90% of time waiting → `8 × (1 + 9) = 80` threads.

**But you can't scale this indefinitely** — 1 MB per thread caps you at a few thousand. That ceiling is what drives the alternatives.

## Three Ways To Handle Many Connections

| Model | Mechanism | Ceiling |
|---|---|---|
| **Thread per connection** | One OS thread blocks per connection | ~10K (memory-bound) |
| **Event loop (async I/O)** | One thread, non-blocking I/O, `epoll`/`kqueue` | **100K+** |
| **Virtual threads / goroutines** | Many user-mode threads on few OS threads | **Millions** |

**Event loops** (Node.js, Netty, nginx) never block: `epoll` reports which sockets are ready, and the loop handles each. Very efficient, but any blocking call stalls everything — hence "don't block the event loop".

**Virtual threads** (Java 21, Go goroutines) give you the *simplicity* of blocking code with the *scalability* of an event loop. When a virtual thread blocks on I/O, the runtime **unmounts** it from its carrier OS thread and mounts another. The blocking style is preserved; the OS thread isn't wasted.

**This is the key insight:** virtual threads don't make I/O faster — they stop blocking I/O from consuming an expensive OS thread.

**Caveats:** no benefit for CPU-bound work, don't pool them, and `synchronized` blocks can **pin** a virtual thread to its carrier (use `ReentrantLock` instead).

## User Mode vs Kernel Mode

| | User mode | Kernel mode |
|---|---|---|
| Privileges | Restricted | Full hardware access |
| Can execute | Application code | Any instruction |
| Entering the other | **System call** (trap) | Returns to user mode |

**Every system call is a mode switch** costing ~100 ns–1 µs. This is why:
- Buffered I/O beats unbuffered — fewer `read`/`write` calls
- Batching syscalls matters at high throughput
- `io_uring` exists — to submit many operations with one syscall

## Interprocess Communication

| Mechanism | Speed | Use |
|---|---|---|
| **Shared memory** | **Fastest** — no copy | High-throughput local IPC |
| Pipes | Fast | Parent-child streaming |
| Unix domain sockets | Fast | Local services (no TCP overhead) |
| Message queues | Moderate | Structured local messaging |
| **TCP sockets** | Slowest | Networked, but works anywhere |

**Unix domain sockets are meaningfully faster than TCP over loopback** — no protocol stack, no checksums. Worth knowing when a design has co-located processes (a sidecar proxy, for instance).

## Zero-Copy

A normal file-to-socket send copies data four times: disk → kernel buffer → user buffer → socket buffer → NIC.

**`sendfile()` / `splice()` keep the data in kernel space**, eliminating the user-space round trip.

**Kafka's throughput depends heavily on zero-copy** — it sends log segments straight from page cache to socket. Mentioning this when asked "why is Kafka fast?" is a strong answer, alongside sequential I/O and batching.

## Common Mistakes

- Sizing an I/O-bound pool at `N_cpu + 1`
- Blocking inside an event loop
- Pooling virtual threads
- Assuming thread creation is free
- Ignoring cache pollution when reasoning about context-switch cost
- Using TCP loopback where a Unix socket would do

## Related Topics

- [Threads and Lifecycle](Threads%20and%20Lifecycle.md)
- [Executors and Thread Pools](Executors%20and%20Thread%20Pools.md)
- [Memory Management](Memory%20Management.md)
- [Kafka Deep Dive](Kafka%20Deep%20Dive.md)
- [Preemption, Blocking and Thread Migration](../Scheduling/Preemption%2C%20Blocking%20and%20Thread%20Migration.md) — the mechanism behind context switching: timer-interrupt preemption vs I/O blocking, and why threads migrate between cores

## Revision Summary

Processes isolate at high cost; threads share at low cost but no isolation. A thread reserves ~1 MB, which caps thread-per-connection at ~10K and motivates event loops and virtual threads. Context switching costs most through cache pollution. System calls are mode switches, which is why batching and zero-copy matter.

## Quick Recall

- Thread ≈ 1 MB stack → ~10K thread ceiling
- Context switch: direct cost small, **cache pollution large**
- CPU-bound pool = N+1; I/O-bound = N × (1 + wait/service)
- Virtual threads unmount on blocking — blocking style, event-loop scale
- Don't pool virtual threads; `synchronized` pins them
- `sendfile` zero-copy is part of why Kafka is fast
