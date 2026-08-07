# Schema Migrations and Evolution

> Changing a schema without downtime. The constraint that makes it hard: **two versions of your application run simultaneously during every deploy.**

## Why It Matters

Most deployment incidents originate here. A migration that works in staging with one app instance fails in production where old and new code run against one database for several minutes.

## The Core Constraint

```
Rolling deploy timeline:
  t0   100% old code
  t1   50% old, 50% new     ← BOTH must work against the SAME schema
  t2   100% new code
```

**Therefore every migration must be backward compatible with the currently-deployed code.** That single rule generates everything below.

## Safe vs Unsafe Changes

| **Safe in one step** | **Unsafe — needs expand/contract** |
|---|---|
| Add a nullable column | **Drop a column** |
| Add a table | **Rename a column or table** |
| Add an index (concurrently) | **Change a column type** |
| Add a nullable-permitting constraint | **Add `NOT NULL` without a default** |
| Widen a type (`varchar(50)` → `varchar(200)`) | Narrow a type |
| Add a default to a new column | **Add a constraint existing rows violate** |

**Why dropping a column breaks:** old code still does `SELECT *` or references the column, and errors the moment it's gone. **Why renaming breaks:** it's a drop plus an add — both versions break simultaneously.

## Expand–Contract (Parallel Change)

The pattern for every unsafe change. To rename `user_name` → `full_name`:

```
1. EXPAND    Add full_name (nullable). Deploy.
             → old code ignores it; new column exists

2. BACKFILL  Copy user_name → full_name in batches.
             Deploy code that WRITES BOTH columns.
             → both columns stay in sync

3. SWITCH    Deploy code that READS full_name, still writes both.
             → verify with metrics before proceeding

4. CONTRACT  Deploy code that stops writing user_name.
             → old column now unused

5. CLEANUP   Drop user_name. Deploy.
```

**Five deployments to rename a column.** That is the actual cost of zero-downtime schema change — stating it demonstrates real experience rather than theory.

**Each step is individually reversible**, which is the point. If step 3 shows problems, you roll back the code and the data is still intact in both columns.

## Backfilling Safely

A `UPDATE users SET full_name = user_name` over 50 million rows will:

- Lock rows for the duration
- Generate enormous WAL
- Bloat the table with dead tuples (Postgres MVCC)
- Possibly time out and roll back everything

**Batch it:**

```sql
-- Repeat until zero rows affected
UPDATE users SET full_name = user_name
WHERE id IN (
  SELECT id FROM users
  WHERE full_name IS NULL
  ORDER BY id LIMIT 10000
);
```

| Rule | Reason |
|---|---|
| **Small batches** (1K–10K rows) | Short transactions, less lock contention |
| **Sleep between batches** | Let replication and vacuum catch up |
| **Idempotent** | Safe to re-run after interruption |
| **Resumable** | Track progress; don't restart from zero |
| Run off-peak | Less contention |
| **Monitor replication lag** | A fast backfill can lag replicas badly |

**Replication lag is the one people miss.** A backfill generating 500 MB/s of WAL will push replicas minutes behind, breaking read-after-write for real users.

## Locking Behaviour

The failure mode: a migration takes a lock that blocks all traffic.

| Operation | Postgres lock |
|---|---|
| `ADD COLUMN` (nullable, no default) | **Metadata only — instant** |
| `ADD COLUMN ... DEFAULT` | Instant in PG 11+; **full rewrite before that** |
| `CREATE INDEX` | **Blocks writes** for the duration |
| **`CREATE INDEX CONCURRENTLY`** | **Doesn't block** — but is slower and can fail |
| `ALTER COLUMN TYPE` | **Full table rewrite + exclusive lock** |
| `ADD CONSTRAINT ... CHECK` | Full scan under lock |
| `ADD CONSTRAINT ... NOT VALID` then `VALIDATE` | **Two steps, no long lock** |
| `DROP COLUMN` | Metadata only |

**Always `CREATE INDEX CONCURRENTLY` on a large production table.** A plain `CREATE INDEX` on a 500 GB table blocks writes for however long it takes — potentially an outage.

**The `NOT VALID` trick is worth knowing:**
```sql
ALTER TABLE orders ADD CONSTRAINT chk CHECK (total >= 0) NOT VALID;  -- instant
ALTER TABLE orders VALIDATE CONSTRAINT chk;                          -- scans, weaker lock
```

**The lock-queue trap:** in Postgres, a migration waiting for a lock **blocks every query behind it**, even ones that would not have conflicted. A migration waiting on a long-running transaction can freeze the entire table.

**Mitigation:** set `lock_timeout` (a few seconds) and retry, so a migration fails fast rather than causing a pile-up.

## Adding NOT NULL Safely

```
1. Add the column nullable
2. Deploy code that always populates it
3. Backfill existing rows in batches
4. ADD CONSTRAINT ... CHECK (col IS NOT NULL) NOT VALID
5. VALIDATE CONSTRAINT              -- scans without a long exclusive lock
6. (PG 12+) SET NOT NULL            -- instant, uses the validated constraint
```

Six steps for one `NOT NULL`. **Doing it in one statement on a large table takes an exclusive lock for a full scan.**

## Rollback

**Code rolls back in seconds. Schema often cannot roll back at all.**

| Change | Reversible? |
|---|---|
| Add column | Yes — drop it |
| Add index | Yes |
| **Drop column** | **No — data is gone** |
| **Type change** | Usually no — data may be truncated |
| Backfill | Only if the original data survives |

**This is why expand–contract exists.** At every intermediate step both schemas work, so the *code* can roll back even though the schema only moves forward.

**Rule: never combine a destructive migration with a code deploy.** Ship the code, verify it in production, then ship the destructive migration separately — hours or days later.

## Migration Tooling

| Tool | Notes |
|---|---|
| Flyway | Versioned SQL files; simple and predictable |
| Liquibase | XML/YAML changesets; database-agnostic |
| Rails/Django/Alembic | Framework-integrated |

**Requirements regardless of tool:**

- **Version-controlled**, reviewed like code
- **Applied automatically** in a pipeline, never by hand
- **Immutable once applied** — never edit a migration that has run
- **Tested against production-like data volume** — a migration that's instant on 1,000 rows may take an hour on 100 million

**Test against realistic volume.** This is the most commonly skipped step and the most common source of surprise.

## Who Runs Migrations

| Approach | Trade-off |
|---|---|
| **On application startup** | Simple; **races when N instances start simultaneously** |
| **Separate pipeline step** | **Preferred** — runs once, before the deploy |
| Init container / job | Kubernetes-native, runs once |
| Manual | Error-prone; unacceptable at scale |

**Startup migrations race.** Ten pods starting together each try to migrate. Most tools take an advisory lock so only one proceeds, but the other nine block on startup — and if the migration is slow, health checks fail and the deploy stalls.

**Run migrations as a separate step that completes before new pods start.**

## Event And API Schema Evolution

The same principle applies beyond the database.

| Change | Safe? |
|---|---|
| Add an optional field | **Yes** |
| Add a new event type | Yes |
| **Remove a field** | **No** |
| **Rename a field** | **No** |
| Change a type | No |
| Add a required field | No |

**Consumers must tolerate unknown fields.** Use a schema registry (Avro, Protobuf) with compatibility checks enforced at publish time, so a breaking change is rejected before it reaches production.

**Events already written are immutable** — you cannot migrate them. Version the event type, or use upcasters that translate old versions on read. This is the hardest part of event sourcing.

## Migration Checklist

- [ ] Backward compatible with currently-deployed code
- [ ] Tested against production-scale data
- [ ] Locking behaviour understood; `CONCURRENTLY` where needed
- [ ] `lock_timeout` set so it fails fast
- [ ] Backfills batched, idempotent, resumable
- [ ] Replication lag monitored during backfill
- [ ] Destructive steps separated from code deploys
- [ ] Rollback plan explicit (or acknowledged as impossible)
- [ ] Runs in the pipeline, not on startup

## Common Mistakes

- Renaming or dropping a column in one step
- `CREATE INDEX` without `CONCURRENTLY` on a large table
- Unbatched backfills
- Ignoring replication lag
- Testing only against a small dataset
- Migrations on application startup
- Destructive migration in the same deploy as the code
- Editing a migration that has already run
- Assuming rollback is always possible

## Related Topics

- [Data Modelling and Schema Design](Data%20Modelling%20and%20Schema%20Design.md)
- [Deployment Patterns](../../08%20Microservices/Deployment%20Patterns.md)
- [Database Replication](../Replication%20and%20Failover/Database%20Replication.md)
- [Event Driven Architecture](../../04%20High%20Level%20Design/Advanced%20Topics/Event%20Driven%20Architecture.md)

## Revision Summary

Both application versions run against one schema during a rolling deploy, so every migration must be backward compatible. Unsafe changes use expand–contract — five deploys to rename a column. Batch backfills, use `CONCURRENTLY` for indexes, set a lock timeout, and never ship a destructive migration alongside the code that depends on it.

## Quick Recall

- **Old and new code share one schema during every deploy**
- Safe: add nullable column, add table, add index concurrently
- Unsafe: drop, rename, type change, `NOT NULL` without default
- **Expand → backfill → switch → contract → cleanup** (5 deploys)
- Backfill in batches; **watch replication lag**
- **`CREATE INDEX CONCURRENTLY`** always on large tables
- `NOT VALID` then `VALIDATE` avoids the long lock
- A blocked migration **blocks everything behind it** — set `lock_timeout`
- Schema rolls forward only; separate destructive steps from deploys
