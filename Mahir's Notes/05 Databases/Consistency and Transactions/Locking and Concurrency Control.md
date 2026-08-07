# Locking and Concurrency Control

> How databases let many transactions run at once without corrupting each other — and how to choose between blocking and retrying.

## Why It Matters

Every "two users booked the same seat" and "the counter is wrong under load" bug is a concurrency control failure. It's also the mechanism behind deadlocks and lock-wait timeouts in production.

## The Two Philosophies

| | **Pessimistic** | **Optimistic** |
|---|---|---|
| Assumes | Conflict is likely | **Conflict is rare** |
| Mechanism | **Lock before reading** | Check a version at write time |
| On conflict | Others **block and wait** | One transaction **fails and retries** |
| Cost when uncontended | Lock overhead on every access | **Near zero** |
| Cost when contended | Queueing, possible deadlock | **Wasted work, retry storms** |
| Best for | High contention, short critical sections | **Low contention — most workloads** |

**Optimistic is the right default.** Most workloads have far less actual conflict than people assume — 100,000 users across 10,000 seats means most individual seats have low contention.

## Optimistic Concurrency Control

```sql
-- Read
SELECT id, balance, version FROM accounts WHERE id = 1;   -- version = 5

-- Write, guarded by the version
UPDATE accounts
   SET balance = 90, version = version + 1
 WHERE id = 1 AND version = 5;
-- 0 rows updated → someone else won → re-read and retry
```

**The `WHERE version = 5` clause is the entire mechanism.** It makes check-and-write atomic without any lock.

**Better still, avoid the read entirely** where the domain allows:

```sql
UPDATE accounts SET balance = balance - 10
 WHERE id = 1 AND balance >= 10;
-- 0 rows → insufficient funds; no race possible
```

**Prefer a conditional update over read-then-write.** It's one statement, needs no retry loop, and cannot race.

**The application must handle 0 rows updated.** Silently ignoring it is a lost update — the most common form of this bug.

## Pessimistic Locking

```sql
BEGIN;
SELECT * FROM seats WHERE id = 42 FOR UPDATE;   -- exclusive lock until commit
-- ... other transactions block here ...
UPDATE seats SET status = 'BOOKED' WHERE id = 42;
COMMIT;
```

| Variant | Behaviour |
|---|---|
| `FOR UPDATE` | Exclusive — blocks other readers-for-update and writers |
| `FOR SHARE` | Shared — allows other readers, blocks writers |
| **`FOR UPDATE NOWAIT`** | **Fails immediately** rather than waiting |
| **`FOR UPDATE SKIP LOCKED`** | **Skips locked rows** — the queue-worker idiom |

**`SKIP LOCKED` is the one worth knowing.** It turns a table into a work queue where multiple workers each claim different rows without contending:

```sql
SELECT * FROM jobs WHERE status='PENDING'
 ORDER BY created_at LIMIT 10
   FOR UPDATE SKIP LOCKED;
```

Used by the [transactional outbox](Transactional%20Outbox.md) relay and by database-backed job queues.

**Never hold a pessimistic lock across a network call.** A lock held for a 3-second payment API call blocks every other transaction touching that row, and exhausts the connection pool under load.

## Lock Granularity

| Level | Concurrency | Overhead |
|---|---|---|
| **Row** | **Highest** | Most locks to track |
| Page | Medium | Fewer locks |
| **Table** | **Lowest** | Cheapest |

Modern databases lock at **row level** for DML. Table locks appear during DDL — which is why a migration can freeze a table.

**Lock escalation** (SQL Server, DB2): too many row locks are promoted to a table lock, collapsing concurrency. **Postgres does not escalate**, which is one reason it handles high-concurrency workloads well.

## Lock Modes

Two locks conflict if they're incompatible on the same object:

| | Shared (read) | Exclusive (write) |
|---|---|---|
| **Shared** | ✓ compatible | ✗ blocks |
| **Exclusive** | ✗ blocks | ✗ blocks |

**Intent locks** (`IS`, `IX`) at the table level signal that row locks exist below, so a table-level request can detect conflict without scanning every row lock.

## MVCC — Why Readers Don't Block

**Multi-Version Concurrency Control:** each write creates a new row version; each transaction sees a snapshot consistent as of its start.

**Consequence: readers never block writers, and writers never block readers.** Only writer-writer pairs conflict.

| Cost | Detail |
|---|---|
| **Dead tuples** | Old versions accumulate |
| **VACUUM required** | Postgres must reclaim them |
| **Long transactions cause bloat** | Old versions can't be removed while any transaction might need them |
| Transaction ID wraparound | A real operational hazard if vacuum falls behind |

**"A long-running analytics query blocks VACUUM and bloats the table" is the practical failure to know** — and the concrete reason not to run reporting queries against the primary.

**MySQL InnoDB also uses MVCC**, storing old versions in the undo log rather than in the table, so it has less bloat but a growing undo tablespace instead.

## Two-Phase Locking

The protocol behind serializable isolation in lock-based systems:

- **Growing phase** — acquire locks, never release
- **Shrinking phase** — release locks, never acquire

**Strict 2PL** holds all locks until commit, preventing cascading aborts. This is what most locking databases actually implement.

**Serializability guaranteed, at the cost of blocking and deadlocks.**

**Postgres takes the other route:** Serializable Snapshot Isolation (SSI) is optimistic — it detects conflicts and **aborts** one transaction rather than blocking. **So Postgres `SERIALIZABLE` requires a retry loop in your application.** Code written for Read Committed often breaks when the isolation level is raised, because there's no retry.

## Deadlocks

```
T1: locks A, wants B
T2: locks B, wants A
→ neither can proceed
```

**Databases detect this** with a wait-for graph and abort a victim transaction. Your code must catch the error and retry.

**Prevention, in order of practicality:**

| Technique | Detail |
|---|---|
| **Consistent lock ordering** | Always acquire in the same order — **the standard answer** |
| Shorter transactions | Less overlap, less opportunity |
| Lower isolation where safe | Fewer locks held |
| `NOWAIT` / `SKIP LOCKED` | Fail or skip rather than queue |
| One lock at a time | No cycle possible |

```sql
-- Multi-row update: order deterministically
UPDATE accounts SET ... WHERE id IN (:a, :b) ORDER BY id;
```

**The bank transfer deadlock** — `transfer(A,B)` and `transfer(B,A)` running concurrently — is the canonical example. Sorting the account IDs before locking eliminates it.

**Diagnose with:** `pg_locks` joined to `pg_stat_activity`, or the deadlock detail in the Postgres log. It names both transactions and the exact cycle.

## Advisory Locks

Application-level locks with no row attached:

```sql
SELECT pg_advisory_xact_lock(hashtext('nightly-report'));
```

Useful for "only one instance should run this job". **Held until transaction end** with the `xact` variant — the session variant leaks if you forget to release.

**Cheaper and safer than a distributed lock** when you already have a shared database, and it dies automatically with the connection.

## Lock Waits In Production

| Symptom | Cause | Diagnosis |
|---|---|---|
| Queries hang | Lock wait | `pg_locks` + `pg_stat_activity` |
| **Everything on one table stalls** | **A DDL migration waiting for a lock blocks everything behind it** | Check for waiting `ALTER TABLE` |
| Periodic deadlock errors | Inconsistent lock ordering | Database log names the cycle |
| Connection pool exhausted | Transactions holding locks too long | Check longest-running transactions |
| Growing table bloat | Long transaction blocking vacuum | `pg_stat_activity` for old `xact_start` |

**The migration lock-queue problem is worth naming:** in Postgres, a DDL statement waiting for a lock queues *ahead* of subsequent queries, so a migration blocked by one long transaction freezes the entire table. **Set `lock_timeout` on migrations** so they fail fast instead.

## Choosing

| Situation | Approach |
|---|---|
| Counter increment | **Atomic `UPDATE ... SET n = n + 1`** |
| Low-contention entity update | **Optimistic (version column)** |
| High-contention hot row | Pessimistic `FOR UPDATE`, or queue-serialise it |
| Work queue | **`FOR UPDATE SKIP LOCKED`** |
| Multi-row invariant | Serializable + retry, or explicit locks in a fixed order |
| Cross-service | Saga; a database lock cannot span services |
| Singleton job | **Advisory lock** |

## Common Mistakes

- Read-then-write instead of a conditional update
- Ignoring "0 rows updated" — a silent lost update
- Pessimistic locking on a low-contention workload
- **Holding a lock across a network call**
- Inconsistent lock ordering
- Using `SERIALIZABLE` without a retry loop
- Long transactions causing bloat and lock pile-ups
- No `lock_timeout` on migrations
- Session-level advisory locks that leak

## Related Topics

- [Transactions and Isolation Levels](Transactions%20and%20Isolation%20Levels.md)
- [Concurrency in LLD](Concurrency%20in%20LLD.md)
- [Schema Migrations and Evolution](Schema%20Migrations%20and%20Evolution.md)
- [Design Ticket Booking](Design%20Ticket%20Booking.md)

## Revision Summary

Optimistic concurrency with a version column or conditional update is the default; pessimistic `FOR UPDATE` is for genuinely contended rows. MVCC means readers never block writers, at the cost of dead tuples and vacuum dependency. Prevent deadlocks with consistent lock ordering, never hold locks across network calls, and set a lock timeout on migrations.

## Quick Recall

- **Optimistic by default**; pessimistic under real contention
- **Conditional update beats read-then-write** — and handle 0 rows
- `FOR UPDATE SKIP LOCKED` = database-backed work queue
- **Never hold a lock across a network call**
- MVCC: readers don't block writers; **long transactions bloat**
- Postgres `SERIALIZABLE` is SSI — **you must retry**
- Deadlock → **consistent lock ordering**
- A blocked migration blocks everything behind it — `lock_timeout`
- Advisory locks for singleton jobs
