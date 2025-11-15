
2PL is the Pessimistic concurrency control technique, which work by applying specific phases of locking and unlocking the resources.

![[Pasted image 20250612231342.png]]
![[Pasted image 20250612231551.png]]

**Example of transaction**:
![[Pasted image 20250612232850.png]]

Here ideal way to work is:
T1 and T2 and trying to access same resource concurrently, T1 starts first and acquires lock on A and B in growing phase, then when it enters shrinking phase T2 starts and start acquiring the lock.

### 📌 Types of Two-Phase Locking (2PL)

---

### 1. **Basic 2PL**

- Follows the two phases (growing then shrinking).
- Does **not** prevent deadlocks.
- Ensures conflict serializability.

 **Disadvantages of Basic Two-Phase Locking (2PL)**

1. **Deadlocks**  
   Transactions can end up waiting for each other indefinitely, causing deadlocks.

![[Pasted image 20250612235705.png]]
![[Pasted image 20250612235723.png]]


2. **Blocking & Waiting**  
   A transaction holding a lock blocks others from accessing the same data, reducing concurrency.

3. **Cascading Aborts**  
   If one transaction fails and others have read its uncommitted data, those must also abort.

4. **Complex Deadlock Handling**  
   Requires extra logic (like wait-for graphs or timeouts) to detect or avoid deadlocks.

5. **Lower System Throughput**  
   Due to locking delays and waiting, overall performance and transaction throughput can decrease.

## 🛡️ Deadlock Prevention Strategies

Deadlock prevention ensures that at least one of the **four necessary conditions for deadlock** never holds:

1. **Mutual Exclusion** – Only one process can use a resource at a time.  
2. **Hold and Wait** – A process holding resources can request more.  
3. **No Preemption** – Resources cannot be forcibly taken.  
4. **Circular Wait** – A closed chain of processes exists, each waiting on the next.

### ✅ Prevention Techniques

### 1. **Eliminate Hold and Wait**
- Require each process to **request all resources at once** before starting.
- 🔻 Reduces resource utilization (may lead to starvation).

### 2. **Eliminate No Preemption**
- If a process holding some resources requests another that is unavailable, **preempt all held resources**.
- Preempted resources are returned to the pool and re-acquired later.

### 3. **Eliminate Circular Wait**
- Impose a **global ordering** on resource types.
- Processes must request resources in a **predefined order**.

### 4. **Use Timeout-Based Methods**
- If a process waits too long for a resource, abort and roll back.
- Often combined with retry mechanisms.

### 5. **Resource Allocation Graph with a Single Instance**
- If the graph becomes cyclic, a deadlock is possible.
- Avoid granting requests that would create cycles.

![[Pasted image 20250613000813.png]]
![[Pasted image 20250613000828.png]]
![[Pasted image 20250613000908.png]]
![[Pasted image 20250614112249.png]]
![[Pasted image 20250614112255.png]]

---

### 2. **Conservative (Static) 2PL**

- All locks are acquired **before** the transaction begins execution.
- If all required locks are not available, the transaction **waits**.
- ✅ **Prevents deadlocks** but may reduce concurrency.
- ❌ May lead to unnecessary waiting and lower throughput.
![[Pasted image 20250613001901.png]]


### **Cascading Aborts**

When a transaction **T1** modifies some data and **T2** reads that data before **T1 is committed**, then:

- If **T1 aborts**, the changes made by T1 are rolled back.
- Since **T2 has read uncommitted or unconfirmed data**, it also needs to **abort** to maintain database consistency.
- This can trigger a chain reaction if other transactions (**T3**, **T4**, etc.) also depend on **T2**.

➡️ This chain reaction is known as a **cascading abort**.

![[Pasted image 20250614112550.png]]

# The next two types of 2PL are Cascading Abort prevention strategies:

### 3. **Strict 2PL**

- A transaction **holds all exclusive (write) locks** until it **commits or aborts**.
- Shared (read) locks can still be released earlier.
- ✅ Prevents **cascading aborts**.
- Commonly used in real systems like databases (e.g., Oracle, SQL Server).

---

### 4. **Rigorous 2PL**

- A transaction **holds all locks (shared and exclusive)** until it commits or aborts.
- ✅ Stronger than strict 2PL.
- ✅ Simplifies recovery and ensures serializability and recoverability.
- ❌ Lower concurrency.

---

### Summary Table

| Type             | Prevents Deadlocks | Prevents Cascading Aborts | Lock Release Timing                  |
| ---------------- | ------------------ | ------------------------- | ------------------------------------ |
| Basic 2PL        | ❌ No               | ❌ No                      | After acquiring all, release anytime |
| Conservative 2PL | ✅ Yes              | ✅ Yes (indirectly)        | All before execution                 |
| Strict 2PL       | ❌ No               | ✅ Yes                     | Exclusive locks released at commit   |
| Rigorous 2PL     | ❌ No               | ✅ Yes                     | All locks released at commit         |


# Final Verdict

## 🔐 Types of 2PL

| Type                         | Deadlock-Free | Cascading-Abort-Free | Lock Behavior                                   |
|------------------------------|---------------|-----------------------|-------------------------------------------------|
| **Basic 2PL**                | ❌ No          | ❌ No                  | Acquire/release dynamically                     |
| **Strict 2PL**               | ❌ No          | ✅ Yes                | Hold **exclusive** locks until **commit**       |
| **Rigorous 2PL**             | ❌ No          | ✅ Yes                | Hold **all** locks (shared + exclusive) till commit |
| **Conservative 2PL (C2PL)**  | ✅ Yes         | ❌\* Maybe            | Acquire all locks **before** execution          |
| **Strict + Conservative 2PL**| ✅ Yes         | ✅ Yes                | Acquire all locks upfront, release at commit    |

---

## ✅ Notes

- Cascading aborts occur if a transaction reads **uncommitted** data from another transaction.
- **Strict 2PL** prevents cascading aborts by delaying release of **write locks** until commit.
- **Conservative 2PL** avoids **deadlocks** by acquiring all locks upfront, but may still allow cascading aborts if locks are released early.
- **To eliminate both deadlocks and cascading aborts**, use:  
  **→ Conservative + Strict 2PL**

---

## 📌 Recommendations

- For **performance-critical systems** with low tolerance for abort chains:  
  → Use **Strict + Conservative 2PL**.

- For systems where **deadlock detection** is acceptable:  
  → **Strict 2PL** is sufficient to avoid cascading aborts.

# 🚦 2PL Type vs Application Suitability & Concurrency Impact

## 🔐 Two-Phase Locking (2PL) Types and Use-Cases

| Type                         | Suitable For                          | Concurrency Impact         | Notes |
|------------------------------|----------------------------------------|-----------------------------|-------|
| **Basic 2PL**                | Simple apps, low consistency need     | 🔼 High                     | Allows early reads, but unsafe — may cause cascading aborts and deadlocks. |
| **Strict 2PL**               | Banking, e-commerce, ERP systems      | ⏸️ Medium                   | Safe: avoids cascading aborts, but can still deadlock. |
| **Rigorous 2PL**             | Audit-sensitive, fully serialized apps| ⏸️⏸️ Low                    | Over-conservative: holds all locks → lowest concurrency. |
| **Conservative 2PL (C2PL)**  | Real-time systems, deadlock-intolerant| 🔽 Low                      | Safe from deadlocks, but concurrency suffers due to upfront locking. |
| **Strict + Conservative 2PL**| Financial systems, critical workflows | ⛔ Very Low                 | Most restrictive, safest — zero cascading aborts and deadlocks. |

---

## 📊 Concurrency Impact (Summary)

| Impact       | Description                                 |
|--------------|---------------------------------------------|
| 🔼 High       | High concurrency, but risk of anomalies     |
| ⏸️ Medium     | Balanced safety and concurrency             |
| 🔽 Low        | Reduced concurrency due to cautious locking |
| ⛔ Very Low   | Locks limit almost all overlap — safest     |

---

## ✅ Recommendations by Application Type

### 🏦 Banking / Financial Systems
- 🔐 **Use:** Strict + Conservative 2PL
- ✅ **Why:** Maximum safety, no dirty reads, no deadlocks

### 🛒 E-commerce / ERP
- 🔐 **Use:** Strict 2PL
- ⚖️ **Why:** Tolerable deadlocks, but must avoid cascading aborts

### 🕒 Real-Time / Embedded Systems
- 🔐 **Use:** Conservative 2PL
- ⚡ **Why:** Must avoid blocking/deadlocks; consistency may be relaxed slightly

### 🧪 Analytics / BI Tools
- 🔐 **Use:** Basic 2PL (or even Snapshot Isolation)
- 📈 **Why:** Prioritize speed over strict consistency

---

## 🧠 Final Takeaway

> Choose 2PL type based on your app’s **consistency requirements**, **deadlock tolerance**, and **latency sensitivity**.