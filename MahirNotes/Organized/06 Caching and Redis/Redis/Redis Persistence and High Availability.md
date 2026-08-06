# Redis Persistence and High Availability

## Why It Matters

"Is Redis durable?" and "what happens when the primary fails?" are standard follow-ups once you put Redis in a design. The honest answers involve real data-loss windows.

## Persistence Options

| | **RDB (snapshot)** | **AOF (append-only file)** |
|---|---|---|
| What | Point-in-time binary snapshot | Log of every write command |
| Loss window | **Up to the snapshot interval** | `everysec` → ~1s; `always` → ~0 |
| Restart speed | **Fast** — load one compact file | Slower — replay the log |
| File size | **Compact** | Larger (mitigated by rewrite) |
| Fork cost | **Forks the process** — memory spike | Rewrite also forks |

```
save 900 1        # RDB: snapshot if ≥1 key changed in 900s
appendonly yes
appendfsync everysec
```

**Recommended: both.** RDB for fast restarts and backups, AOF for a small loss window.

**The fork problem:** RDB snapshots and AOF rewrites `fork()` the process. Copy-on-write means memory usage can spike toward 2× if the workload writes heavily during the save. **On a 20 GB instance this can trigger the OOM killer** — a genuinely common production incident.

Mitigate with `vm.overcommit_memory=1`, headroom in the memory allocation, and snapshotting from a replica rather than the primary.

**`appendfsync always` is slow** — an fsync per write. Almost everyone runs `everysec` and accepts a one-second window.

## Redis Is Not A Durable Database

Even with AOF `always`, edge cases lose data. The honest position:

- Use Redis for data you can **rebuild** — caches, sessions, ephemeral state, derived aggregates
- If losing the last second of writes is unacceptable, Redis is the wrong primary store
- Persistence exists mainly to **avoid a cold start after restart**, not to guarantee durability

**Saying this plainly is a strong signal.** Candidates who claim Redis is durable get probed until they concede.

## Replication

**Asynchronous by default.** The primary acknowledges the client, then propagates to replicas.

```
Client → PRIMARY (ack immediately) → replicas (async)
```

**Consequence: a failover can lose acknowledged writes.** The primary confirmed a write, died before replicating, and the promoted replica never saw it.

`WAIT numreplicas timeout` blocks until N replicas confirm — but it is **not** synchronous replication and offers no guarantee across a failover, only a best-effort check.

**Replica behaviour:**
- Replicas are read-only by default
- Full resync on first connection (RDB transfer); partial resync afterwards via a replication backlog
- A replica that falls too far behind triggers an expensive full resync

## Sentinel — HA Without Sharding

For a single primary with replicas:

```
Sentinel monitors PRIMARY + replicas
  → primary unreachable → sentinels agree (quorum) → elect + promote a replica
  → reconfigure other replicas → notify clients
```

| Requirement | Detail |
|---|---|
| **Odd number of sentinels** | At least 3, so a quorum survives one loss |
| **Sentinels on separate hosts** | Co-locating them with Redis defeats the purpose |
| Client support | Clients query sentinels for the current primary |

**Split-brain risk:** during a partition, the old primary may keep accepting writes from clients that can still reach it. Those writes are lost on reconciliation.

**Mitigate with:**
```
min-replicas-to-write 1
min-replicas-max-lag 10
```
The primary **refuses writes** if it can't reach at least one sufficiently-current replica — choosing consistency over availability at that moment.

## Redis Cluster — Sharding Plus HA

**16,384 hash slots** distributed across primaries, each with replicas.

- `CRC16(key) mod 16384` determines the slot
- Automatic failover: replicas of a failed primary elect a new one
- Clients are cluster-aware and follow `MOVED` / `ASK` redirects

| Constraint | Detail |
|---|---|
| **Multi-key ops need one slot** | Use hash tags `{user123}:profile` |
| No cross-slot transactions | `MULTI` across slots fails |
| Minimum practical size | 3 primaries + 3 replicas |
| Resharding | Migrate slots; online but operationally involved |

**`cluster-require-full-coverage yes`** (the default) makes the **entire cluster** reject writes if any slot is unavailable. Setting it to `no` allows partial availability — a real availability-versus-consistency choice worth naming.

## Sentinel vs Cluster vs Managed

| | Sentinel | Cluster | Managed (ElastiCache, MemoryDB) |
|---|---|---|---|
| Sharding | **No** | **Yes** | Yes |
| HA | Yes | Yes | Yes |
| Max data | One node's memory | Sum of primaries | Sum |
| Complexity | Moderate | **High** | **Low** |
| Multi-key ops | Unrestricted | Same-slot only | Same-slot only |

**If the dataset fits in one node's memory, Sentinel is simpler and gives unrestricted multi-key operations.** Don't reach for Cluster until you actually need sharding — that judgement is what's being assessed.

**AWS MemoryDB** is worth knowing as the durable variant: multi-AZ transaction-log-backed Redis with genuine durability, at higher latency and cost. It's the answer if someone insists on Redis semantics *and* durability.

## Failure Scenarios

| Failure | Behaviour |
|---|---|
| Primary crashes | Sentinel/Cluster promotes a replica; **unreplicated writes lost** |
| Replica crashes | No impact; rejoins and resyncs |
| Network partition | Minority side unavailable (Cluster); Sentinel may split-brain without `min-replicas-to-write` |
| AOF rewrite during heavy writes | Memory spike from fork; possible OOM |
| Full resync storm | Multiple replicas resyncing saturate primary I/O |
| Memory full | Eviction per policy, or **write errors** under `noeviction` |

## Operational Rules

- **Never `KEYS *`** or `FLUSHALL` in production — both block the single thread
- Keep Lua scripts short
- Avoid values over ~100 KB
- Set `maxmemory` and an eviction policy deliberately
- Monitor: memory usage, eviction rate, replication lag, blocked clients, slow log
- Snapshot from a replica to keep fork cost off the primary
- Set `timeout` and TCP keepalive to reap dead connections

## Common Mistakes

- Treating Redis as a durable primary datastore
- Ignoring the async-replication data-loss window on failover
- Even numbers of sentinels, or sentinels co-located with Redis
- No `min-replicas-to-write`, permitting split-brain writes
- Redis Cluster when the data fits one node
- Cross-slot multi-key operations without hash tags
- Ignoring fork memory spikes on large instances
- `noeviction` on a cache

## Related Topics

- [Redis](../../04%20High%20Level%20Design/Key%20Technologies/Redis.md)
- [Redis Data Structures](Redis%20Data%20Structures.md)
- [Distributed Caching](../Caching/Distributed%20Caching.md)
- [Database Replication](../../05%20Databases/Replication%20and%20Failover/Database%20Replication.md)

## Revision Summary

RDB gives fast restarts, AOF a ~1 second loss window; run both, and beware fork-induced memory spikes. Replication is asynchronous, so failover can lose acknowledged writes — bound it with `min-replicas-to-write`. Sentinel gives HA without sharding; Cluster adds sharding with same-slot constraints. Redis is not a durable primary store.

## Quick Recall

- RDB = snapshot (fast restart); AOF = command log (~1s loss)
- **Both, with `appendfsync everysec`**
- Fork on save → memory spike → possible OOM
- **Async replication → failover loses writes**
- `min-replicas-to-write` prevents split-brain writes
- Sentinel = HA only; Cluster = HA + sharding + slot constraints
- 16,384 slots; hash tags for multi-key
- **Not a durable database** — use for rebuildable data
