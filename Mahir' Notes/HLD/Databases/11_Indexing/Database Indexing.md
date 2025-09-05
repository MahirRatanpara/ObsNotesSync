
- Table data are not stored in the logical table representation which we see.

- They are store using the Concept called **Data Pages**, generally it's size is 8KB, which can store multiple table rows

![[Pasted image 20250614125259.png]]

**Note that the array is not in the sorted order.**


# 📦 DBMS: Data Pages, Data Blocks, and I/O

## 🧩 Data Pages in DBMS
- A **DBMS** creates and manages **data pages** to store table data.
- One table's data can span **multiple data pages**.
- These data pages are the **logical units** of data management within the DBMS.

## 💾 Storage in Physical Memory (Disk)
- Data pages are ultimately stored in **Data Blocks** on physical storage devices like **HDDs or SSDs**.
- Data blocks are managed by the **underlying storage system** (not the DBMS).

---

## ❓ What is a Data Block?
- A **Data Block** is the **smallest unit of data** that can be read from or written to disk during an **I/O operation**.
- Size typically ranges from **4KB to 32KB** (common: **8KB**).
- A data block can hold **one or multiple data pages**, depending on the size of each.
- DBMS maintains a **mapping** between Data Pages and Data Blocks.

### 📋 Example Mapping:

| Data Page  | Data Block  |
|------------|-------------|
| Data Page1 | Data Block1 |
| Data Page2 | Data Block1 |
| Data Page3 | Data Block2 |
| Data Page4 | Data Block2 |

---

## 🔁 I/O: Input/Output in DBMS Context

### 🔹 What is I/O?
- **I/O** stands for **Input/Output**, referring to data transfer between **CPU/memory** and **external storage**.
- In DBMS, this typically means **disk I/O**: reading/writing data to and from disk.

### 🔹 Why is Data Block called the "smallest unit of I/O"?
- Disks operate in fixed-size **blocks**. Even if only a few bytes are needed, **entire blocks** must be read or written.
- The DBMS **cannot request or write less than one data block** from/to disk.
- Hence, **one I/O = one block**, not one row or one byte.

### ⚠️ Implications:
- I/O is **slow** compared to memory, so DBMSs try to **reduce I/O** through:
  - **Caching** data pages
  - **Indexing**
  - **Smart query planning**

---

## 🧠 Summary
- **Data Page**: Logical unit managed by DBMS.
- **Data Block**: Physical unit of disk I/O, managed by OS/storage.
- **I/O Unit**: Data Block (e.g., 8KB); you can’t read/write less than this.
- DBMS uses a **mapping** to locate which data page is in which data block.

---

## 📦 Analogy
> Think of a **data block** like a **book box** in a library:  
> You must take the **whole box** (block) even if you only need **one book** (row).



# ✅ Advantages of Data Pages and Data Blocks in DBMS

## 🧩 Logical Layer: Data Pages

### ✅ 1. Efficient Memory Management
- DBMS operates on **data pages** (typically 4KB–8KB).
- Enables caching in **buffer pools**, applying **LRU policies**, etc.

### ✅ 2. Isolation from Physical Storage
- Abstracts away disk-level details.
- DBMS only manages logical structures, not physical disk layout.

### ✅ 3. Fine-Grained Concurrency Control
- Page-level or row-level **locking** possible.
- Better transaction isolation and parallelism.

### ✅ 4. Simplifies Logging and Recovery
- **Write-Ahead Logging (WAL)** and crash recovery work at the page level.
- Helps in tracking precise changes and recovering data efficiently.

---

## 💾 Physical Layer: Data Blocks

### ✅ 1. Optimized Disk I/O
- Disk reads/writes happen in **block-sized chunks** (e.g., 8KB).
- Reading entire blocks is faster than byte-wise reads.

### ✅ 2. Aligned with Hardware Architecture
- HDDs and SSDs are designed to read/write **blocks**, not bytes.
- Ensures maximum performance with modern disk systems.

### ✅ 3. Reduced Fragmentation
- Fixed-size blocks reduce disk fragmentation.
- Easier for the OS to manage and allocate storage.

### ✅ 4. Device-Agnostic
- Abstracts physical layout and supports various storage types:
  - HDD, SSD, RAID, SAN, etc.

---

## 🔁 Page–Block Mapping: Best of Both Worlds

> The DBMS maps **logical data pages** to **physical data blocks**, combining benefits from both layers.

### ✅ Benefits:
- **Decouples** logical and physical concerns.
- Allows:
  - Better **buffer management**
  - Efficient **disk I/O**
  - Easier **recovery mechanisms**
  - Storage **portability and tuning**

---

## 🧠 Summary Table

| Layer        | Unit         | Managed by | Key Benefit                              |
|--------------|--------------|------------|------------------------------------------|
| Logical (DB) | Data Page    | DBMS       | Efficient memory + transaction control   |
| Physical     | Data Block   | OS/Disk    | Optimal I/O and alignment with hardware  |

---

## 📦 Analogy

> Think of a **data page** like a chapter in a book, and a **data block** like a box used to transport books.  
> You operate on chapters (pages) in memory, but the system reads/writes whole boxes (blocks) from/to disk.


# ✅ Why Use Data Pages Instead of Accessing Individual Rows?

## 📌 Introduction

Modern DBMSs organize data in **pages** rather than accessing individual rows from disk. A data page typically contains **multiple rows**, and this design has several performance and architectural advantages.

---

## ⚡ Advantages of Data Pages Over Row-Based Access

### ✅ 1. Efficient I/O Operations
- Disks perform I/O in **block-sized units** (e.g., 8KB).
- Reading a page brings in **multiple rows** with **one I/O**.
- Accessing rows individually would require **multiple I/Os**.

➡️ **Fewer disk reads = faster performance.**

---

### ✅ 2. Better Caching and Buffer Pool Management
- DBMS caches **pages**, not rows.
- Once a page is loaded, **all its rows** are accessible from memory.
- This increases the **cache hit ratio** and reduces disk reads.

➡️ **Improves memory efficiency and response times.**

---

### ✅ 3. Reduced Metadata and Processing Overhead
- Each row-level access would require additional **metadata and management**.
- Grouping rows in a page reduces **repetitive overhead**.

➡️ **Lower CPU and memory usage.**

---

### ✅ 4. Optimized for Sequential and Range Access
- Rows in a page are stored **contiguously**.
- Great for:
  - **Table scans**
  - **Range queries**
  - **Index traversal**

➡️ **Faster access patterns for analytical and bulk queries.**

---

### ✅ 5. Simplified Concurrency Control and Recovery
- Locks and logs often operate at the **page level**, not row level.
- Page-level operations reduce lock contention and logging complexity.

➡️ **Better balance between performance and consistency.**

---

## 🧠 Summary Table

| Feature                         | Row-Based Access            | Page-Based Access (✅)           |
|----------------------------------|------------------------------|----------------------------------|
| I/O Efficiency                   | Multiple I/Os per row        | One I/O for many rows            |
| Cache Utilization                | Inefficient                  | High cache hit rate              |
| Metadata Overhead               | High per row                 | Shared across rows               |
| Sequential Scan Performance     | Slower                       | Much faster                      |
| Concurrency / Logging           | Costly per row               | Efficient at page level          |

---

## 📦 Analogy

> Accessing individual rows is like opening **one envelope at a time** from a bundle of letters.  
> Accessing a data page is like picking up the **entire bundle in one go** — **much faster and more efficient**.



# What is Indexing?

If we iterate through each element in the database, we might need to go to each data page, go to its memory block (via mapping) and load it into main memory and perform operation to check if our required data is present or no. We repeat this process until we find all the relevant data. **O(N) in term of time complexity**

 ![[Pasted image 20250614152050.png]]
 

# Database Indexing Using B+ Tree

## 📘 What is Indexing?
Indexing is a data structure technique used to quickly locate and access data in a database table. Without an index, the database engine performs a full table scan, which is slow for large datasets.

## 🌳 B+ Tree Overview

The **B+ Tree** is a balanced tree data structure used by most modern database systems (like MySQL, PostgreSQL, etc.) for indexing. It ensures logarithmic time complexity `O(log n)` for search, insert, and delete operations.

### Structure
- **Internal (non-leaf) nodes** store **keys only** and act as routing guides.
- **Leaf nodes** store **actual data pointers** (or row IDs / primary keys).
- All **data is stored in the leaf nodes**.
- **Leaf nodes are linked** in a **doubly linked list** for range/ordered access.

     [50]
	   /     \
	[10 30]  [60 70]
	 |  |      |  |
	 ↓  ↓      ↓  ↓

---

## 🔍 Search Operation

1. Start from the root node.
2. Traverse internal nodes using key comparisons.
3. Reach the leaf node and find the actual record pointer.
4. Time complexity: `O(log n)`

---

## 🌱 Insert Operation and Page Splitting

### Step-by-step Process
1. **Navigate** to the appropriate **leaf node**.
2. **Insert** the key in sorted order.
3. If the **leaf node overflows** (i.e., exceeds its capacity `n`):
   - **Split** the node into two.
   - **Promote** the **middle key** to the parent internal node.
   - If the **parent overflows**, recursively split it too.
4. If the **root overflows**, a new root is created — **tree height increases by 1**.

### 🧠 Page Splitting Strategy

- **Leaf Split**:
  - If a leaf node `[10, 20, 30, 40]` (max 4 keys) gets new key `25`, it becomes `[10, 20, 25, 30, 40]`.
  - Split into:
    - Left leaf: `[10, 20]`
    - Right leaf: `[25, 30, 40]`
  - Promote `25` to parent internal node.

- **Internal Split**:
  - Internal node `[25, 50, 75]` + new key `60` becomes `[25, 50, 60, 75]`.
  - Split into:
    - Left: `[25, 50]`
    - Right: `[75]`
  - Promote `60` to the next level.

---

## 🏗️ Internal Mechanics of B+ Tree Index

### Pages and Nodes

- **Each node == a page** (usually 4KB or 8KB).
- Page stores keys and pointers (to children or data).
- Designed to minimize disk I/O by keeping tree **shallow and wide**.

### Fan-out
- The number of keys per node (fan-out) is high due to large page size and small key size.
- A B+ Tree of height 3 with fan-out 1000 can index up to **1 billion records** (`1000^3`).

---

## 🧵 Range Queries

- Since **leaf nodes are linked**, range queries (e.g., `WHERE age BETWEEN 20 AND 30`) are fast.
- Traverse to the first matching leaf node, then **follow linked leaves** until range ends.

---

## ✅ Benefits

- Fast reads (logarithmic time).
- Maintains sorted order (great for `ORDER BY`, `BETWEEN`, etc.).
- Efficient use of disk via high fan-out.
- Only leaf nodes store data → compact internal nodes → better caching.

---

## ⚠️ When Not to Use

- On columns with **low cardinality** (e.g., `gender`, `status`).
- When **write-heavy** workloads constantly trigger splits/merges.

---

## 📌 Summary

| Feature             | B+ Tree Index                          |
|---------------------|----------------------------------------|
| Search Time         | O(log n)                               |
| Insertion Time      | O(log n) + possible splits             |
| Deletion Time       | O(log n) + possible merges             |
| Sorted Order        | Yes (leaf nodes linked)                |
| Data Stored In      | Leaf nodes only                        |
| Good for            | Range queries, frequent lookups        |
| Page Split Action   | Split → promote middle key             |

Next:
# [[Types of DB Indexing]]

