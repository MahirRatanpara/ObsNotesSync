
**The single-threaded nature applies _per Redis instance_, not across your entire system.**

When you shard (partition) data across multiple Redis instances, each shard is its own independent Redis process with its own single thread, its own memory, and its own event loop. So if you have 6 shards, you effectively have 6 independent single-threaded processes — potentially running on 6 different CPU cores or even 6 different machines.

Here's how that scales writes:

**Without sharding** — one Redis instance handles _all_ writes sequentially on one thread, one CPU core. That single core becomes your bottleneck, typically around 100K–200K ops/sec depending on payload size.

**With sharding** — say you hash your keys across 6 shards. A write to `user:101` goes to shard 3, while a write to `user:842` goes to shard 5. These two writes execute _in parallel_ on two completely separate processes. You've now roughly multiplied your write throughput by the number of shards.

Think of it like a bank. One teller (single-threaded) can serve one customer at a time. Adding more tellers (shards) doesn't make any individual teller faster — but the bank as a whole serves more customers per minute.

A few nuances worth knowing:

**How the client knows which shard to hit** — Redis Cluster uses a hash slot mechanism. There are 16,384 slots, and each key is hashed (CRC16) to one slot. Each shard owns a range of slots. The client libraries (Jedis, Lettuce) are cluster-aware and route commands directly to the correct shard — no proxy bottleneck.

**What stays single-threaded** — command execution within each shard. One shard still processes its commands sequentially. So if one shard gets a disproportionate share of traffic (hot key problem), that shard's single thread becomes the bottleneck even though others are idle.

**What's actually multi-threaded in modern Redis (6.0+)** — network I/O (reading from sockets, writing responses) is handled by I/O threads. But the actual command execution — the data mutation — remains single-threaded per instance. This is an important distinction: I/O threading helps with network-bound workloads, but the core execution model is still single-threaded per shard.

So the short answer: sharding scales writes because you're distributing the load across _N independent single-threaded processes_, each with its own CPU core budget. The single-threaded guarantee is per-instance (which is what gives you atomicity without locks), and sharding is how you go beyond what one instance can handle.