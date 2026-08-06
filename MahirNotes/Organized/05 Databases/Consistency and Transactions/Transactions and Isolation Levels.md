# Transactions and Isolation Levels

## Why It Matters

Isolation levels are where correctness bugs hide. Interviewers ask because most engineers use the default without knowing what it permits.

## ACID

| Property | Meaning | Provided by |
|---|---|---|
| **Atomicity** | All or nothing | Undo log / rollback segments |
| **Consistency** | Constraints hold before and after | Application + constraints (not really the DB's job) |
| **Isolation** | Concurrent transactions don't corrupt each other | **Locking or MVCC** |
| **Durability** | Committed data survives a crash | **Write-ahead log + fsync** |

**Consistency in ACID is not CAP's consistency.** ACID's C means "constraints are satisfied"; CAP's C means linearizability. Conflating them is a common error.

## The Read Phenomena

| Phenomenon | What happens |
|---|---|
| **Dirty read** | You read data another transaction wrote but hasn't committed |
| **Non-repeatable read** | You read a row twice and get different values (someone committed an UPDATE between) |
| **Phantom read** | You run the same *query* twice and get different *rows* (someone committed an INSERT) |
| **Lost update** | Two transactions read, modify, and write; one overwrites the other |
| **Write skew** | Two transactions read overlapping data, each writes to a different row, and together they violate an invariant |

**Non-repeatable read is about a row; phantom read is about a result set.** That distinction is the thing candidates get wrong.

## The Four Standard Levels

| Level | Dirty read | Non-repeatable | Phantom |
|---|---|---|---|
| **Read Uncommitted** | Possible | Possible | Possible |
| **Read Committed** | Prevented | Possible | Possible |
| **Repeatable Read** | Prevented | Prevented | Possible* |
| **Serializable** | Prevented | Prevented | Prevented |

\* The SQL standard permits phantoms at Repeatable Read; **MySQL InnoDB prevents them anyway** using next-key locks, and **PostgreSQL's Repeatable Read is snapshot isolation**, which also prevents them.

## Defaults Differ — And This Trips People Up

| Database | Default |
|---|---|
| **PostgreSQL** | Read Committed |
| **MySQL (InnoDB)** | **Repeatable Read** |
| Oracle | Read Committed |
| SQL Server | Read Committed |

**Know that Postgres and MySQL differ by default.** Code correct on one can be subtly wrong on the other.

## MVCC — How Modern Databases Achieve This

Rather than locking readers, keep **multiple versions** of each row. Each transaction sees a consistent snapshot as of its start.

**Consequence: readers never block writers, and writers never block readers.** This is why Postgres and MySQL scale reads well under concurrency.

**Costs:**
- Old versions accumulate → Postgres needs **VACUUM**, and a long-running transaction prevents cleanup, causing **table bloat**
- Writers still conflict with writers
- Postgres's transaction ID wraparound is a real operational hazard

**"A long-running analytics query blocks VACUUM and bloats the table" is a good practical detail.**

## Lost Update — The One You'll Actually Hit

```sql
-- Both transactions read balance = 100
UPDATE accounts SET balance = 90 WHERE id = 1;   -- T1 (read 100, subtract 10)
UPDATE accounts SET balance = 80 WHERE id = 1;   -- T2 (read 100, subtract 20)
-- Final: 80. T1's update is LOST. Correct answer: 70.
```

**Three fixes:**

```sql
-- 1. Atomic update — best when possible
UPDATE accounts SET balance = balance - 10 WHERE id = 1 AND balance >= 10;

-- 2. Pessimistic lock
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;

-- 3. Optimistic lock
UPDATE accounts SET balance = 90, version = version + 1
WHERE id = 1 AND version = 5;    -- 0 rows → someone else won → retry
```

**Prefer the atomic update.** It's a single statement, needs no retry loop, and the `balance >= 10` predicate makes the check atomic with the write.

## Write Skew — The Subtle One

Snapshot isolation prevents lost updates but **not write skew**:

```
Rule: at least one doctor must be on call.
Two doctors, both on call, both try to go off call simultaneously.

T1: reads "2 on call" → OK to leave → sets doctor A off
T2: reads "2 on call" → OK to leave → sets doctor B off
Commit both → ZERO doctors on call. Invariant violated.
```

Neither transaction wrote the same row, so no conflict is detected.

**Fixes:** `SERIALIZABLE` isolation, `SELECT ... FOR UPDATE` on the rows you read, or materialising the conflict into a single lockable row.

**Write skew is the strongest thing you can raise in an isolation discussion** — it demonstrates you understand that snapshot isolation is not serializability.

## Serializable

Two implementations:

| | Mechanism | Cost |
|---|---|---|
| **Two-phase locking (2PL)** | Acquire locks, release only at commit | Blocking, deadlocks |
| **Serializable Snapshot Isolation (SSI)** | Optimistic — detect conflicts, abort one | **No blocking, but aborts** |

PostgreSQL uses **SSI**. Transactions can fail with a serialization error, so **the application must retry** — code written for Read Committed often breaks when moved to Serializable because it has no retry loop.

## Two-Phase Locking

- **Growing phase** — acquire locks, never release
- **Shrinking phase** — release locks, never acquire

**Strict 2PL** holds all locks until commit, which prevents cascading aborts. This is what most locking databases actually implement.

## Deadlocks

Databases detect deadlocks via a wait-for graph and abort one transaction (the "victim"). Your code must handle the error and retry.

**Prevention:** access rows in a consistent order — the same lock-ordering rule as in application code.

## Choosing A Level

| Situation | Level |
|---|---|
| Analytics, reporting | Read Committed (or a replica) |
| Most OLTP | **Read Committed + optimistic locking** |
| Multi-row invariants | Repeatable Read / Snapshot |
| Financial invariants, write skew risk | **Serializable** with retries |

**Don't raise the isolation level as a reflex.** An atomic conditional update at Read Committed is usually simpler and faster than Serializable with a retry loop.

## Common Mistakes

- Assuming the default is Repeatable Read (it's Read Committed in Postgres)
- Read-then-write without a version check or atomic update
- Assuming snapshot isolation prevents write skew
- Using Serializable without a retry loop
- Long-running transactions causing bloat and lock contention
- Conflating ACID's C with CAP's C

## Related Topics

- [Consistency Models](../../09%20Distributed%20Systems/Consistency/Consistency%20Models.md)
- [CAP and PACELC](../../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md)
- [Scaling Writes](../../04%20High%20Level%20Design/Patterns/Scaling%20Writes.md)
- [Multi-Step Processes and Saga](../../04%20High%20Level%20Design/Patterns/Multi%20Step%20Processes%20and%20Saga.md)

## Revision Summary

Isolation levels trade correctness for concurrency: Read Committed permits non-repeatable and phantom reads, snapshot isolation still permits write skew, and only Serializable prevents everything — at the cost of aborts requiring retries. MVCC lets readers and writers avoid blocking each other. Prefer atomic conditional updates over raising the isolation level.

## Quick Recall

- Postgres defaults to Read Committed; MySQL to Repeatable Read
- Non-repeatable = a row changed; phantom = the result set changed
- MVCC: readers don't block writers
- Lost update → atomic update, or version check
- **Snapshot isolation does not prevent write skew**
- Postgres Serializable is SSI — you must retry
- ACID's C ≠ CAP's C
