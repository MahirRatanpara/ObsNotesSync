# Back of the Envelope Estimation

## Why It Matters

Estimation isn't arithmetic for its own sake — it answers one question: **does this fit on one machine?** If yes, don't distribute. If no, the numbers tell you how much to shard, cache, and replicate.

## The Numbers To Memorise

### Latency

| Operation | Time | Relative |
|---|---|---|
| L1 cache reference | 1 ns | 1× |
| Branch mispredict | 3 ns | |
| L2 cache reference | 4 ns | |
| Mutex lock/unlock | 17 ns | |
| **Main memory reference** | **100 ns** | 100× |
| Compress 1 KB | 2 µs | |
| Send 1 KB over 1 Gbps | 10 µs | |
| **SSD random read** | **100 µs** | 1,000× memory |
| Read 1 MB sequentially from memory | 250 µs | |
| **Datacentre round trip** | **500 µs** | |
| Read 1 MB from SSD | 1 ms | |
| **Disk seek (HDD)** | **10 ms** | 100,000× memory |
| Read 1 MB from disk | 20 ms | |
| **CA → Netherlands round trip** | **150 ms** | |

**The three that matter most:** memory 100 ns, SSD 100 µs, network round trip 500 µs in-datacentre / 150 ms cross-continent.

**The takeaway to state aloud:** memory is ~1,000× faster than SSD, and a cross-region round trip is ~300× a local one. That single comparison justifies caching and regional replicas.

### Capacity

| Quantity | Value |
|---|---|
| Seconds per day | **86,400 ≈ 10⁵** |
| 1M requests/day | **~12/sec** |
| 100M requests/day | ~1,200/sec |
| 1B requests/day | ~12,000/sec |
| Single commodity server | 10–50K QPS |
| Single Redis node | ~100K ops/sec |
| Single Postgres node | 5–10K writes/sec, ~50K reads/sec |
| Single Kafka broker | ~100K+ msg/sec |
| 1 Gbps link | ~125 MB/sec |

### Storage

| Item | Size |
|---|---|
| ASCII character | 1 byte |
| UUID | 16 bytes (36 as a string) |
| Timestamp | 8 bytes |
| Typical row / small JSON | 100 B – 1 KB |
| Tweet-sized text | ~300 bytes |
| Compressed image | 200 KB – 2 MB |
| Minute of 1080p video | ~50 MB |

## Powers Of Two

| Power | Value | Name |
|---|---|---|
| 2¹⁰ | ~1 thousand | KB |
| 2²⁰ | ~1 million | MB |
| 2³⁰ | ~1 billion | GB |
| 2⁴⁰ | ~1 trillion | TB |
| 2⁵⁰ | ~1 quadrillion | PB |

## The Estimation Procedure

**Round aggressively. Use powers of ten. Nobody wants precision.**

```
Given: 100M DAU, each posts twice a day, reads 100 posts a day

WRITES
  100M × 2 = 200M writes/day
  200M / 10⁵ = 2,000 writes/sec          (86,400 ≈ 10⁵)
  Peak 2× → 4,000 writes/sec

READS
  100M × 100 = 10B reads/day
  10B / 10⁵ = 100,000 reads/sec
  Peak 2× → 200,000 reads/sec
  Read:write ratio = 50:1 → READ HEAVY

STORAGE
  Post = 300 B text + 100 B metadata = 400 B
  200M × 400 B = 80 GB/day
  × 365 × 5 years ≈ 150 TB
  With replication factor 3 → 450 TB

BANDWIDTH
  Writes: 4,000 × 400 B = 1.6 MB/sec        — trivial
  Reads: 200,000 × 400 B = 80 MB/sec        — significant, needs CDN/cache

MEMORY FOR CACHE
  80/20 rule: 20% of posts serve 80% of reads
  Daily working set = 80 GB × 20% = 16 GB   — fits comfortably in RAM
```

## What The Numbers Should Change

This is the part candidates skip. **State the implication of each figure:**

| Finding | Design implication |
|---|---|
| 4,000 writes/sec | One Postgres node can't do it — shard, or use an LSM store |
| 200,000 reads/sec | Replicas plus a cache; a CDN for anything static |
| 50:1 read:write | Optimise reads aggressively; denormalise; precompute |
| 150 TB over 5 years | Not one machine — plan sharding from the start |
| 16 GB hot working set | **Fits in RAM** — a cache will be very effective |
| 80 MB/sec read bandwidth | CDN offload is worth it |

**"The working set fits in memory, so a cache will absorb most reads" is exactly the kind of conclusion estimation exists to produce.**

## The 80/20 Rule

Assume 20% of data serves 80% of traffic unless told otherwise. It's the standard justification for cache sizing, and interviewers accept it.

## Sanity Checks

Before quoting a number, ask whether it's plausible:

- **> 1M QPS** — very few systems on earth do this. Recheck.
- **> 1 PB/year** for a text-based system — recheck your per-item size.
- **Any latency budget under 1 ms that crosses a network** — impossible; a round trip alone is 500 µs.
- **Storage that fits on one SSD (< 2 TB)** — say so, and don't shard.

**Being willing to say "this fits on one machine, so I won't distribute it" is a strong senior signal.** Most candidates over-engineer because they assume distribution is the expected answer.

## Common Mistakes

- Doing precise arithmetic instead of rounding — it wastes minutes and impresses nobody
- Computing numbers and never using them
- Forgetting the peak multiplier (2–3×)
- Forgetting replication when sizing storage
- Ignoring metadata and index overhead
- Sizing for 5 years when the interviewer said 1
- Not stating the read:write ratio

## Related Topics

- [System Design Delivery Framework](System%20Design%20Delivery%20Framework.md)
- [Scaling Reads](Scaling%20Reads.md)
- [Scaling Writes](Scaling%20Writes.md)
- [Caching](Caching.md)

## Revision Summary

Round to powers of ten, use 86,400 ≈ 10⁵, apply a 2× peak multiplier, and multiply storage by the replication factor. The point is not the numbers but the conclusions: what fits in memory, what fits on one machine, and where the bottleneck is.

## Quick Recall

- Memory 100 ns · SSD 100 µs · DC round trip 500 µs · cross-continent 150 ms
- 86,400 ≈ 10⁵ ; 1M/day ≈ 12/sec
- Peak = 2–3× average
- 80/20 for cache sizing
- Storage × replication factor
- **Always state what each number implies for the design**
