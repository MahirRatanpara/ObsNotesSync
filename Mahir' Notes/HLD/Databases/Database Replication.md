
## 1. Streaming Replication

**Streaming replication** is a method where the **primary database continuously sends [[Write-Ahead Logging (WAL)]] entries to the standby (replica) as changes occur**, allowing the replica to stay close to real-time.

### ✅ Key Features:
- **Asynchronous by default** (but can be made synchronous).
- The replica **"replays" the logs** to stay up-to-date.
- Great for **read scalability** and **warm/hot standby** setups.
- Standby is **read-only** (in most cases).

### ⏱️ Delay:

- **Slight lag** can occur, depending on network and load.
- Ideal for **read replicas** or warm standbys where minor data lag is acceptable.

---
## 2. Synchronous Replication

**Synchronous replication** ensures that **transactions are committed to both the primary and the replica before completing**. It’s a **guaranteed data consistency mechanism**.

### ✅ Key Features:

- **No data loss**: Writes are acknowledged only after replicas have received them.
- Ensures **strong consistency** across nodes.
- Useful for **high availability (HA)** and **hot standby** setups.

### 🕒 Trade-off:

- **Slower writes**: because primary waits for replica to confirm.
- Requires **reliable network and high-speed connection**.

---

## 🔍 Summary Table

| Feature                | Streaming Replication                  | Synchronous Replication                   |
| ---------------------- | -------------------------------------- | ----------------------------------------- |
| **Type**               | Typically asynchronous                 | Strictly synchronous                      |
| **Data consistency**   | Eventually consistent                  | Strong consistency                        |
| **Write latency**      | Low (no waiting for replica)           | Higher (waits for replica acknowledgment) |
| **Data loss risk**     | Possible (recent changes may be lost)  | Minimal to none                           |
| **Use case**           | Read replicas, reporting, warm standby | Hot standby, HA, critical systems         |
| **Failover readiness** | Replica may lag slightly               | Replica always up-to-date                 |
