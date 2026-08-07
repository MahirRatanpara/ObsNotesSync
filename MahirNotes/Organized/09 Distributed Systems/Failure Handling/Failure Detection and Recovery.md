# Failure Detection and Recovery

## Why It Matters

You cannot recover from a failure you haven't detected, and you cannot reliably detect failure in an asynchronous network. Everything here is a trade-off between detection speed and false positives.

## The Fundamental Limit

**You cannot distinguish a crashed node from a slow one.**

```
No response within T
  → the node crashed?
  → the node is GC-pausing?
  → the network dropped the packet?
  → the node is overloaded?
```

All indistinguishable from outside. This is why **failure detectors are inherently unreliable**, and why FLP impossibility holds — see [Consensus Algorithms](../Consensus/Consensus%20Algorithms.md).

**The practical consequence: every timeout choice is a bet.**

| Timeout | Effect |
|---|---|
| **Too short** | **False positives** — healthy nodes evicted, unnecessary failovers, possible split brain |
| **Too long** | Slow detection, prolonged outage while traffic routes to a dead node |

**A GC pause longer than the failure-detection timeout will get a healthy node declared dead.** This is a real and common cause of spurious failovers.

## Detection Mechanisms

| Mechanism | How | Trade-off |
|---|---|---|
| **Heartbeat** | Node pushes "I'm alive" periodically | Simple; fixed timeout is brittle |
| **Ping / health check** | Monitor pulls from the node | Adds probe load; can be gamed by a shallow endpoint |
| **Lease** | Node holds a time-bounded lease it must renew | **Expiry is automatic and safe** |
| **Phi Accrual** | Outputs a *suspicion level*, not a boolean | **Adapts to observed network variance** |
| **Gossip** | Nodes share observations peer to peer | Scales to large clusters; eventual |

### Phi Accrual — The Adaptive One

Rather than "alive or dead", it outputs a continuously increasing suspicion value derived from the statistical distribution of recent heartbeat intervals.

**Why it's better:** a network with historically variable latency produces a wider distribution, so the detector automatically becomes more tolerant. A fixed 5-second timeout cannot adapt.

Different actions can trigger at different thresholds — stop routing new requests at φ=5, initiate failover at φ=12.

**Used by Cassandra and Akka.** Naming it demonstrates depth beyond "we send heartbeats".

### Gossip — For Large Clusters

Each node exchanges membership state with a few random peers per second. Information spreads exponentially — a cluster of 1,000 nodes converges in roughly log(n) rounds.

**Advantages:** no central monitor, no single point of failure, scales well, and tolerates partial connectivity.

**Trade-off:** eventual rather than immediate detection, and a node can be simultaneously "alive" to some peers and "dead" to others during convergence.

Used by Cassandra, Consul (SWIM), and Riak.

## Health Checks — The Design Rules

**Separate liveness from readiness:**

| Check | Question | Failure action |
|---|---|---|
| **Liveness** | Is the process functional? | **Restart** |
| **Readiness** | Can it serve traffic now? | **Remove from rotation** |

**Liveness must never check downstream dependencies.** If it does, one shared database blip marks every instance unhealthy and restarts the entire fleet — converting a dependency degradation into a total outage.

**Readiness may check dependencies**, since removing an instance from rotation is reversible and harmless.

**Shallow vs deep checks:**

| Type | Checks | Risk |
|---|---|---|
| Shallow (`return 200`) | Process is up | **Misses gray failure** — a broken instance passes |
| Deep | Dependencies, disk, thread pool | May cause correlated failure |

**The right balance:** liveness shallow, readiness moderately deep, and **passive health checking** on real traffic to catch gray failures that probes miss.

## Recovery Patterns

| Pattern | Use |
|---|---|
| **Automatic failover** | Promote a replica; fast, but risks split brain |
| **Restart** | Fixes most transient process-level faults |
| **Fencing** | Prevent the old primary from continuing to act |
| **Reconciliation** | Reconcile divergent state after recovery |
| **Self-healing** | Replace the instance entirely (Kubernetes, ASG) |

### Split Brain And Fencing

The most dangerous recovery failure: two nodes both believe they are primary.

```
Primary A partitioned from the cluster (but alive and reachable by some clients)
→ cluster promotes B
→ A and B both accept writes → divergence
```

**Prevention:**

| Mechanism | How |
|---|---|
| **Quorum** | Only a majority partition may elect; the minority becomes read-only |
| **Fencing tokens** | Monotonic number; storage rejects writes bearing a stale token |
| STONITH | Forcibly power off the old node |
| `min-replicas-to-write` | Primary refuses writes if it can't reach enough replicas |

**Fencing tokens are the general solution**, because they work even when the old primary is alive, healthy, and unaware it has been replaced. A lease alone is insufficient — a GC pause can outlast it.

```
Client acquires lease with token 33 → GC pause → lease expires
Another client acquires with token 34, writes
First client wakes, writes with token 33 → STORAGE REJECTS (33 < 34)
```

**The storage layer must enforce the token.** This is the detail candidates miss.

## Graceful Degradation

Not every failure warrants failover.

| Failure | Response |
|---|---|
| Recommendation service down | Hide the panel; serve the page |
| Cache down | Fall through to the database, slower |
| Search down | Fall back to a simple filtered query |
| One region down | Route to another |
| Payment provider down | Queue the request; process later |

**Decide the degraded behaviour of every dependency at design time**, not during the incident. Stating it in an interview is a strong signal.

## Recovery Objectives

| | Meaning | Determined by |
|---|---|---|
| **RTO** | How long you can be down | Failover automation and speed |
| **RPO** | How much data you can lose | Replication mode |

| RPO | Requires |
|---|---|
| Zero | Synchronous replication |
| Seconds | Semi-synchronous |
| Minutes | Asynchronous replication |
| Hours | Periodic backups |

**Ask for RTO and RPO explicitly in a design interview** — they determine the entire replication and failover strategy, and most candidates never ask.

## Testing Failure

**A recovery path that is never exercised does not work.**

| Practice | Detail |
|---|---|
| **Chaos engineering** | Deliberately kill instances in production |
| Fault injection | Latency and error injection via a [service mesh](../../08%20Microservices/Service%20Mesh.md) |
| **Game days** | Rehearsed failure scenarios with the on-call team |
| Regular failover drills | Prove the runbook works before you need it |

**The most common discovery from a first game day is that the documented failover procedure doesn't work.** That's precisely why you run them.

## Common Mistakes

- Liveness probes that check dependencies
- Timeouts shorter than the worst-case GC pause
- Automatic failover without quorum or fencing
- Distributed locks without fencing tokens
- Shallow health checks that miss gray failures
- No defined degraded behaviour
- Never testing the recovery path
- Not asking for RTO and RPO

## Related Topics

- [Fallacies and Failure Modes](../Theory/Fallacies%20and%20Failure%20Modes.md)
- [Consensus Algorithms](../Consensus/Consensus%20Algorithms.md)
- [Database Replication](../../05%20Databases/Replication%20and%20Failover/Database%20Replication.md)
- [Service Discovery](../../08%20Microservices/Service%20Discovery.md)

## Revision Summary

Crashed and slow are indistinguishable, so every timeout trades false positives against detection speed. Phi Accrual adapts to observed variance; gossip scales detection without a central monitor. Separate liveness from readiness and never let liveness check dependencies. Failover needs quorum plus fencing tokens enforced at the storage layer.

## Quick Recall

- **Cannot distinguish crashed from slow** — every timeout is a bet
- GC pause > timeout → spurious failover
- Phi Accrual = adaptive suspicion, not a boolean
- Gossip scales to large clusters, converges in log(n)
- **Liveness restarts — must not check dependencies**
- Split brain → quorum + **fencing tokens enforced by storage**
- Define degraded behaviour per dependency upfront
- Ask for RTO and RPO
- Untested recovery paths don't work
