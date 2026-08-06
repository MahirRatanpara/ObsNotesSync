# Database Replication

## Why It Matters

The foundation for read scaling, high availability, and disaster recovery — and the source of the lag bugs users actually notice.

## Topologies

| Topology | Writes | Pros | Cons |
|---|---|---|---|
| **Single-leader** | One primary | Simple, no write conflicts | Primary is a write bottleneck and a failure point |
| **Multi-leader** | Several primaries | Multi-region low-latency writes | **Write conflicts must be resolved** |
| **Leaderless** | Any replica | No failover needed, highly available | Quorum tuning, read repair complexity |

Single-leader covers the vast majority of systems. Reach for multi-leader only for genuine multi-region write locality, and be ready to explain conflict resolution.

## Synchronous vs Asynchronous

| | Synchronous | Asynchronous | Semi-synchronous |
|---|---|---|---|
| Commit waits for | Replica ack | Nothing | **One** replica ack |
| Write latency | High | **Low** | Moderate |
| Data loss on primary failure | **None** | Possible | Bounded |
| Availability | Replica failure blocks writes | Unaffected | Tolerates most failures |

**Semi-synchronous is the usual production compromise:** wait for one replica, let the rest catch up asynchronously. Bounded data loss, acceptable latency.

## Replication Mechanisms

| Method | How | Notes |
|---|---|---|
| **Statement-based** | Ship the SQL | Breaks on `NOW()`, `RAND()`, auto-increment races |
| **Write-ahead log (physical)** | Ship WAL records | Postgres streaming replication; version-coupled |
| **Logical / row-based** | Ship row changes | Version-independent, enables CDC |
| Trigger-based | Application-level | Flexible, slow |

**Write-Ahead Logging** is the underlying durability mechanism: changes are written to a sequential log and fsynced *before* the data pages are modified. This makes commits fast (sequential write) and crash recovery possible (replay the log). Replication then just ships that same log.

## Replication Lag

The gap between a primary commit and its appearance on a replica. Causes the three anomalies:

| Anomaly | User sees | Fix |
|---|---|---|
| Read-after-write | Their own edit missing | Read from primary for N seconds after writing |
| Monotonic reads | Data appears, then vanishes on refresh | Pin the session to one replica |
| Consistent prefix | A reply before its parent message | Route related writes to the same partition |

**Monitor lag explicitly** (`pg_stat_replication`, `Seconds_Behind_Master`) and remove lagging replicas from the read pool automatically.

## Failover

```mermaid
flowchart LR
    A[Primary fails] --> B[Detect via missed heartbeats]
    B --> C[Elect the most up-to-date replica]
    C --> D[Promote to primary]
    D --> E[Repoint clients / update DNS or proxy]
    E --> F[Rebuild the old primary as a replica]
```

**The dangers:**

- **Data loss** — with async replication, unreplicated writes are gone. If the old primary rejoins, its extra writes are typically discarded.
- **Split brain** — two nodes both believe they're primary, accepting conflicting writes. Prevent with a **quorum/witness** or **fencing** (STONITH). Never rely on timeouts alone.
- **Flapping** — an aggressive timeout causes failover on a transient network blip. Too long a timeout means extended downtime. This is a real tuning trade-off.

## Standby Types

| Type | Data currency | Recovery time |
|---|---|---|
| Cold | Restored from backup | Hours |
| Warm | Replicating, not serving | Minutes |
| **Hot** | Replicating and serving reads | Seconds |

## RTO and RPO

- **RTO** (Recovery Time Objective) — how long you can be down
- **RPO** (Recovery Point Objective) — how much data you can lose

| RPO | Requires |
|---|---|
| Zero | Synchronous replication |
| Seconds | Semi-sync or low-lag async |
| Minutes | Async replication |
| Hours | Periodic backups |

**Ask for RTO and RPO explicitly in a design interview.** They determine the entire replication strategy, and most candidates never ask.

## Common Mistakes

- Async replication with a zero-RPO requirement
- No split-brain protection
- Reading from a replica immediately after writing
- Not monitoring lag or removing stale replicas from the pool
- Assuming failover is automatic when it's actually manual
- Confusing replication (availability) with backups (recovery from *logical* errors — replication faithfully replicates your `DROP TABLE`)

## Related Topics

- [Consistency Models](../../09%20Distributed%20Systems/Consistency/Consistency%20Models.md)
- [Partitioning and Sharding](../Partitioning%20and%20Sharding/Partitioning%20and%20Sharding.md)
- [CAP and PACELC](../../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md)

## Revision Summary

Single-leader by default; semi-synchronous replication as the usual compromise. Lag causes read-after-write and monotonic-read anomalies. Failover risks data loss and split brain — use quorum and fencing. Ask for RTO and RPO.

## Quick Recall

- Semi-sync = one replica ack = bounded loss
- WAL is written and fsynced before data pages
- Lag anomalies: read-after-write, monotonic reads, consistent prefix
- Split brain → quorum or fencing, never timeouts alone
- Replication ≠ backup
