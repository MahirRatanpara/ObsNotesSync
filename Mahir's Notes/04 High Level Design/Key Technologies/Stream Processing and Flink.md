# Stream Processing and Flink

## Why It Matters

Any design involving real-time aggregation — ad click counts, live metrics, fraud detection, trending topics — needs stream processing. Interviewers probe windowing and late data.

## Batch vs Stream

| | Batch | Stream |
|---|---|---|
| Input | Bounded dataset | **Unbounded** |
| Latency | Minutes to hours | Milliseconds to seconds |
| Reprocessing | Rerun the job | Replay from the log |
| Correctness | Easy — all data present | **Hard — data arrives late and out of order** |

**Stream processing is just batch processing where you can never be sure you have all the data.** Everything difficult follows from that.

## Event Time vs Processing Time

The most important distinction in the whole topic.

| | Definition | Problem |
|---|---|---|
| **Event time** | When the event actually happened | Events arrive **late and out of order** |
| **Processing time** | When the system processed it | Simple, but results depend on system speed and are **not reproducible** |
| Ingestion time | When it entered the pipeline | Middle ground |

**Use event time for correctness.** A user's click at 10:00:00 belongs in the 10:00 window even if network delay means it arrives at 10:00:45. Processing time would put it in the wrong window, and reprocessing the same data would give a different answer.

## Watermarks

A watermark asserts: *"no events with a timestamp earlier than T will arrive from now on."*

```
Watermark(10:05) → the 10:00–10:05 window can be closed and emitted
```

**It's a heuristic, not a guarantee.** It trades latency against completeness:

- Aggressive watermark → results emitted sooner, more data missed
- Conservative watermark → more complete, higher latency

**Late data handling** options: drop it, send it to a side output for reconciliation, or **allow lateness** and emit an updated result.

**Explaining watermarks as an explicit latency-versus-completeness dial is what a strong answer looks like.**

## Windowing

| Window | Behaviour | Use |
|---|---|---|
| **Tumbling** | Fixed size, non-overlapping | Hourly counts |
| **Sliding** | Fixed size, overlapping | "Last 5 minutes, updated every minute" |
| **Session** | Closes after a gap of inactivity | User sessions |
| Global | One window, custom trigger | Custom logic |

**Sliding windows multiply state.** A 1-hour window sliding every minute means each event belongs to 60 windows — a real memory consideration.

## Exactly-Once — What It Actually Means

Stream processors claim exactly-once, but only for **state**, not for external side effects.

**Flink's mechanism: distributed snapshots (Chandy-Lamport).** Barriers flow through the dataflow graph; when an operator sees barriers on all inputs it snapshots its state. On failure, the whole job rewinds to the last complete checkpoint and replays from the source offsets.

**This gives exactly-once *state* updates.** For exactly-once *output*, the sink must be transactional (Kafka transactions) or idempotent. Otherwise a replay re-emits results.

**The honest statement:** "exactly-once processing semantics, with at-least-once delivery to external systems unless the sink is transactional or idempotent." That distinction is the interview point.

## Flink vs Kafka Streams vs Spark Streaming

| | **Flink** | **Kafka Streams** | **Spark Structured Streaming** |
|---|---|---|---|
| Model | True streaming, event at a time | True streaming | **Micro-batch** |
| Latency | **Milliseconds** | Milliseconds | Hundreds of ms to seconds |
| Deployment | Separate cluster | **A library in your app** | Spark cluster |
| Source/sink | Many | **Kafka only** | Many |
| State | Large, RocksDB-backed | RocksDB, local | Distributed |
| Best for | Complex event-time processing at scale | Kafka-to-Kafka transformations | Unified batch and streaming |

**Kafka Streams is the underrated choice.** If the input and output are both Kafka, it's a library — no cluster to operate. Choosing it over Flink for a simple transformation demonstrates judgement.

## Lambda vs Kappa Architecture

| | **Lambda** | **Kappa** |
|---|---|---|
| Paths | Batch (accurate) **+** speed (fast) layer | **Stream only** |
| Correction | Batch layer overwrites approximations | Replay the log |
| Complexity | **Two codebases for the same logic** | One |
| Modern verdict | Largely superseded | **Preferred** |

**Lambda's fatal flaw is maintaining the same business logic twice** in different systems, which inevitably diverge.

**Kappa works because Kafka retains the log** — reprocessing is replaying from an earlier offset through a new job version. Prefer Kappa and explain why.

## Worked Example: Ad Click Aggregator

```
Click events → Kafka (partitioned by ad_id)
             → Flink: keyBy(ad_id), tumbling 1-minute event-time window
             → aggregate count + dedupe by click_id
             → sink to OLAP store (Druid / ClickHouse) for queries
```

**Design points to raise:**

- **Partition by `ad_id`** so all clicks for an ad reach the same operator and state is local
- **Deduplicate** on `click_id` within a window using keyed state plus a TTL — clicks are retried
- **Watermark with allowed lateness** to handle mobile clients with poor connectivity
- **Hot key**: a viral ad saturates one partition — add a random salt and aggregate the sub-keys in a second stage
- **Approximate first**: `HyperLogLog` for unique users, exact counts only where billing requires it

The two-stage aggregation for hot keys is the deep-dive answer worth having ready.

## Common Mistakes

- Using processing time where event time is required
- No watermark strategy, so late data is silently dropped
- Claiming exactly-once end to end without a transactional sink
- Sliding windows without accounting for state multiplication
- Ignoring hot keys in the partitioning scheme
- Choosing Flink where Kafka Streams would avoid a cluster
- Building Lambda architecture in a new system

## Related Topics

- [Kafka Deep Dive](Kafka%20Deep%20Dive.md)
- [Event Driven Architecture](Event%20Driven%20Architecture.md)
- [Data Structures for Big Data](Data%20Structures%20for%20Big%20Data.md)
- [Clocks and Ordering](Clocks%20and%20Ordering.md)

## Revision Summary

Streams are unbounded, so correctness hinges on event time plus watermarks, which trade latency against completeness. Flink checkpoints give exactly-once state but need a transactional or idempotent sink for exactly-once output. Prefer Kappa over Lambda, and Kafka Streams over Flink when both ends are Kafka.

## Quick Recall

- **Event time for correctness**, processing time for simplicity
- Watermark = latency vs completeness dial; plan for late data
- Tumbling / sliding / session windows; sliding multiplies state
- Exactly-once **state**; output needs a transactional sink
- Kappa over Lambda — one codebase, replay from the log
- Kafka Streams is a library, not a cluster
- Hot key → salt, then two-stage aggregate
