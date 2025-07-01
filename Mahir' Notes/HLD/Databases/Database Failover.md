
Keep the database layer different from the application layer so that it can be scaled independently.

## Cold Standby:

**Cold standby** in database failover refers to a **disaster recovery setup** where a **secondary database server (standby)** is available but **not running or synchronized in real time** with the primary server.

### Key Characteristics:

- **Inactive until failover**: The standby server is **powered off or idle** and only activated manually or semi-automatically when the primary server fails.
- **Manual intervention**: Typically requires **manual startup, configuration, and data restoration**.
- **Lag in recovery**: Recovery time is **longer** compared to hot or warm standby, since data may need to be **restored from backups**.
- **Cost-effective**: Cheaper to maintain because resources are not actively used.
### Use Case:

Suitable for **non-critical systems** where **downtime is acceptable** and **cost savings** are prioritized over high availability.

![[Pasted image 20250701224738.png]]


## Warm Standby:

**Warm standby** refers to a **partially active** backup server that is **kept up-to-date periodically** and can take over when the primary database server fails — with **moderate recovery time**.

---

### 🔑 **Key Characteristics:**

- **Server is running**, but **not actively serving traffic**.
- **Data is replicated regularly**, but **not in real-time** (e.g., log shipping, periodic snapshots).
- **Faster recovery** than cold standby but **slower** than hot standby.
- Usually requires **some manual intervention** to promote the standby to primary.
---
### ✅ **Pros:**

- **Reduced downtime** compared to cold standby.
- **Lower cost** than hot standby since it doesn’t need full real-time replication.
- Can be a good balance between **cost and availability**.
---
### 🚫 **Cons:**

- Some **data loss possible**, depending on replication frequency.
- **Failover is not immediate** and might require **manual promotion**.
---
### 📌 Use Case:

Ideal for systems where **some downtime and minimal data loss** is tolerable, but **faster recovery** than cold standby is needed — e.g., internal business tools or non-critical services.

![[Pasted image 20250701225156.png]]

| **Aspect**               | **Cold Standby**                                  | **Warm Standby**                                      |
| ------------------------ | ------------------------------------------------- | ----------------------------------------------------- |
| **Server status**        | Turned off or idle                                | Running but not actively serving                      |
| **Data synchronization** | No real-time sync; relies on backups              | Periodic sync (e.g., log shipping, scheduled updates) |
| **Failover time**        | **Slow** – requires manual setup and data restore | **Moderate** – faster than cold, may need promotion   |
| **Automation**           | Mostly manual                                     | Semi-automated or manual                              |
| **Data freshness**       | Could be outdated (depends on last backup)        | Relatively fresh (depends on replication interval)    |
| **Cost**                 | Lower (idle resources)                            | Moderate (resources running but not active)           |
| **Downtime tolerance**   | Suitable when downtime is acceptable              | Suitable for limited downtime                         |

## Hot Standby:

**Hot standby** is a **real-time, fully synchronized backup** server that is **always running and ready** to take over **immediately** if the primary database fails.

#### **NOTE:** we can read from the secondary database in this standby as the database is almost real time replicated. But here we would have only one master and it can follow any of the replication strategy to keep the slave ready for the disaster or next read.

---
### 🔑 **Key Characteristics:**

- **Fully active server**, running and constantly updated.
- Uses [[Database Replication]] (e.g., streaming replication or synchronous replication).
- **Automatic or near-instant failover** with **minimal or no downtime**.
- Often used in **high availability (HA)** and **mission-critical systems**.
---

### ✅ **Pros:**

- **Fastest recovery** – often automatic and seamless.
- **Minimal data loss**, especially with synchronous replication.
- **Ensures business continuity**.

---
### 🚫 **Cons:**

- **High cost** – requires full-time duplicate infrastructure and resources.
- **Complex setup** and monitoring needed.
- May need **load balancing** or failover automation logic.

---
### 📌 Use Case:

Ideal for **critical systems** (e.g., banking, trading platforms, healthcare, etc.) where **even seconds of downtime or data loss** is unacceptable.


# All the above stand by types are master slave, now we look at multi master.

## Multi-Primary Standby (Multi-Master Replication)

## 🌐 What is Multi-Primary Standby?

**Multi-primary standby**, also known as **multi-master replication**, is a database setup where **two or more nodes can all accept write operations**. All nodes replicate changes to each other to maintain data consistency.

---
## 🔑 Key Characteristics

| Feature                     | Description                                                             |
| --------------------------- | ----------------------------------------------------------------------- |
| **Multiple writable nodes** | All nodes can handle **read and write operations**                      |
| **Data replication**        | Changes are **replicated across nodes**, often in near real-time        |
| **Conflict resolution**     | Mechanisms must be in place to **handle write conflicts**               |
| **High availability**       | No single point of failure — one primary can fail, others still operate |
| **Geographic distribution** | Often used in **multi-region setups** for latency and redundancy        |
  
---
## 🧠 Example

Two database nodes:

- **Node A (India)** accepts writes from users in Asia.

- **Node B (US)** accepts writes from users in America.

Each node replicates its changes to the other.  

Conflicts may arise if both update the same record simultaneously.

---

## ⚠️ Challenges

  
| Challenge               | Description                                                                                                                                                             |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Conflict resolution** | If two users update the same row on different nodes at the same time, the system must decide **which version wins** (last-write-wins, version vector, timestamps, etc.) |
| **Latency**             | Propagating changes across data centers can cause **replication lag**                                                                                                   |
| **Complexity**          | Configuration, monitoring, and failure handling are **significantly more complex**                                                                                      |
| **Data consistency**    | Must deal with **eventual consistency**, or use consensus protocols (e.g., Paxos, Raft)                                                                                 |

---

  ## ✅ Benefits

  

- **High Availability**: One node can fail without affecting writes.

- **Write Scalability**: Load distributed across writable nodes.

- **Geographic Flexibility**: Local nodes reduce latency for users.

  

---

## 🛠️ Technologies That Support It

  
- **CockroachDB**

- **Cassandra**

- **MySQL Group Replication / Galera Cluster**

- **PostgreSQL BDR (Bi-Directional Replication)**

  

---

  ## 📌 When to Use

- Global apps needing **high availability and local writes**

- Systems that **tolerate eventual consistency**