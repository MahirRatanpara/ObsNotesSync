  
## 💾 What is WAL?


**WAL (Write-Ahead Logging)** is a **crash-recovery mechanism** used by many databases to ensure **data integrity**.  

> 📝 **“Always write the change to a log file before applying it to the actual database.”**

---

## ⚙️ How WAL Works – Step by Step

  

1. **Client issues a transaction** (e.g., `INSERT`, `UPDATE`, etc.).

2. The database:

   - **Writes the change to the WAL log file** on disk.

   - Then applies the change to **in-memory data pages**.

3. The transaction is **committed only after the WAL is written** to durable storage.

4. Changes from memory are later **flushed to actual data files** during checkpoints.

---
## 🛠️ Why WAL is Important

- **Crash recovery**: Replay WAL logs to restore a consistent state.

- **Performance**: Faster writes (sequential log vs random data writes).

- **Replication**: WAL is the **foundation for streaming/logical replication**.

---

## 🔄 Example (PostgreSQL Style)

  

```sql

BEGIN;

UPDATE users SET name = 'Alice' WHERE id = 1;

COMMIT;

```

  

Internally:

- WAL record for the `UPDATE` is written first.

- After it's safely on disk, the `COMMIT` succeeds.

- Table data is updated later in background.

  

---

  

## 🧠 Summary

  

| Aspect              | WAL (Write-Ahead Logging)                  |

|---------------------|--------------------------------------------|

| **Purpose**         | Durability, crash recovery, replication    |

| **Commit condition**| WAL written to disk                        |

| **Performance**     | Fast (sequential writes)                   |

| **Recovery**        | Replays WAL after crash                    |

| **Replication**     | Used in streaming/logical replication      |