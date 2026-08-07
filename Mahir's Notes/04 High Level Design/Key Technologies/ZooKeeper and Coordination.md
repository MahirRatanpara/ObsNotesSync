# ZooKeeper and Coordination

## Why It Matters

Whenever a design needs leader election, distributed locking, or dynamic configuration, this is the component. Interviewers check that you don't try to hand-roll it.

## What It Provides

A small, strongly-consistent, hierarchical key-value store with **watches**.

```
/services
  /payment
    /instance-1   (ephemeral)  → {"host":"10.0.1.5","port":8080}
    /instance-2   (ephemeral)
/config
  /rate-limits                 → {"default": 1000}
/locks
  /order-123
```

**Consensus-backed** — ZooKeeper uses ZAB, etcd and Consul use Raft. All are **CP**: during a partition, the minority side becomes unavailable rather than serving stale data.

## The Two Primitives Everything Is Built On

### Ephemeral nodes
Exist only while the creating session is alive. **Client dies or its session times out → the node disappears automatically.**

This gives failure detection for free: service registration, presence, and lock release on crash all fall out of it.

### Sequential nodes
Appending `SEQUENTIAL` gives a monotonically increasing suffix: `lock-0000000001`, `lock-0000000002`.

**Combined — ephemeral + sequential — you get correct distributed locks and leader election.**

## Leader Election

```
1. Each candidate creates /election/n_ (EPHEMERAL_SEQUENTIAL)
2. List children. Lowest sequence number → you are the leader.
3. Otherwise, watch ONLY the node immediately before yours.
4. That node disappears → re-check whether you are now lowest.
```

**Watching only your predecessor is the important detail.** Watching *all* nodes means every client is notified on every change — the **herd effect**, which turns a 1,000-node cluster into a notification storm. The chained watch means exactly one client wakes per event.

## Distributed Locks

Same construction. To acquire, create an ephemeral sequential node under `/locks/resource` and proceed only if you hold the lowest sequence number.

**Why this beats a Redis lock:**

| | ZooKeeper | Redis `SET NX PX` |
|---|---|---|
| Consistency | **Consensus-backed** | Single node (or async replicas) |
| Holder crashes | **Session expiry releases automatically** | Waits for TTL |
| Split brain | Prevented by quorum | **Possible on failover** |
| Latency | Higher (consensus) | **Lower** |

**Neither eliminates the fundamental problem:** a GC pause longer than the session timeout means the lock is released while the holder still believes it holds it. **You still need a fencing token** — ZooKeeper's `zxid` serves as one. See [Two Generals Problem](Two%20Generals%20Problem.md).

## Guarantees

| Guarantee | Meaning |
|---|---|
| **Sequential consistency** | Updates from a client apply in the order sent |
| Atomicity | Updates succeed or fail entirely |
| Single system image | Same view regardless of which server you connect to |
| Durability | Applied updates persist |
| **Timeliness** | Client views are current within a bound |

**Reads are served locally by any node and may be slightly stale.** For a guaranteed-fresh read you must issue `sync()` first — a genuine subtlety that surprises people.

## What It Is Not For

**ZooKeeper is a coordination service, not a database.**

- Data is held in memory — total size should stay well under ~1 GB
- Each znode should hold **kilobytes**, not megabytes
- Write throughput is limited by consensus — thousands per second, not millions
- **Never put application data in it**

**Writes go through the leader; reads scale with followers.** Adding nodes improves read capacity and durability but makes writes *slower*, since the quorum grows. Five nodes is the usual maximum.

## ZooKeeper vs etcd vs Consul

| | ZooKeeper | etcd | Consul |
|---|---|---|---|
| Consensus | ZAB | **Raft** | Raft |
| API | Custom (znodes) | **gRPC / HTTP** | HTTP / DNS |
| Ecosystem | Kafka (legacy), HBase, Hadoop | **Kubernetes** | HashiCorp stack |
| Service discovery | Manual | Manual | **Built in, with health checks** |
| DNS interface | No | No | **Yes** |

**etcd is the modern default** — it backs Kubernetes, has a cleaner API, and uses Raft. **Consul** adds first-class service discovery and health checking.

**Kafka removed ZooKeeper entirely** in favour of KRaft (internal Raft) as of 4.0 — a good example of a system absorbing its own coordination rather than depending on an external one.

## When You Don't Need It

Reaching for coordination is often avoidable, and saying so is a strong signal:

| Instead of | Use |
|---|---|
| Distributed lock to prevent duplicate work | **Idempotency** — make duplicates harmless |
| Leader election for a scheduler | A database row with a conditional update lease |
| Coordination for uniqueness | A unique constraint in the database |
| Dynamic config | A config service with polling, or a feature-flag platform |
| Service discovery | Kubernetes Services, or a load balancer |

**"I'd make the operation idempotent rather than add a distributed lock" is usually the better engineering answer** — it removes a dependency and a failure mode.

## Common Mistakes

- Storing application data in it
- Watching all children → herd effect
- Distributed locks without fencing tokens
- Assuming reads are always fresh (they can be stale without `sync()`)
- Running an even number of nodes
- Adding it when idempotency would solve the problem
- Treating it as highly available — it is **CP**, so a minority partition is unavailable by design

## Related Topics

- [Consensus Algorithms](Consensus%20Algorithms.md)
- [Two Generals Problem](Two%20Generals%20Problem.md)
- [Kafka Deep Dive](Kafka%20Deep%20Dive.md)
- [Kubernetes Core Concepts](Kubernetes%20Core%20Concepts.md)

## Revision Summary

A consensus-backed hierarchical store whose ephemeral and sequential nodes give leader election, locking, and failure detection. Watch only your predecessor to avoid the herd effect. It's a coordination service, not a database — and idempotency often removes the need for it entirely.

## Quick Recall

- Ephemeral = disappears on session loss; sequential = ordered suffix
- Leader election = lowest sequential node, **watch only your predecessor**
- CP — a minority partition is unavailable by design
- Reads can be stale without `sync()`
- Kilobytes per znode; never application data
- Odd node count; five is usually the maximum
- Locks still need **fencing tokens**
- Prefer idempotency over distributed locks
