
# 🔍 Non-Clustered Index Lookup in B+ Tree (SQL Databases)

## 🧠 Overview

In SQL databases, a **non-clustered index lookup** involves using a **B+ Tree structure** to locate data efficiently. When a table has both a **non-clustered index** and a **clustered index**, the lookup is a **two-step process**.

---

## 🌳 Index Types Recap

### 🔹 Clustered Index
- Data rows are **physically ordered** based on the indexed column.
- The **leaf nodes** of the B+ Tree contain the **actual data rows**.

### 🔹 Non-Clustered Index
- Stores a **copy of the indexed column(s)**.
- **Leaf nodes** contain:
  - Indexed column values
  - A **pointer** to the actual row:
    - **Clustered key** (if a clustered index exists)
    - **RID** or physical location (if the table is a heap)

---

## 🔍 Lookup Process with Non-Clustered Index

### 📘 Example
```sql
SELECT salary FROM Employee WHERE name = 'John';
```

Assumptions:
- Non-clustered index on `name`
- Clustered index on `emp_id`

### 🧭 Step-by-Step

#### 1. Traverse Non-Clustered Index (B+ Tree)
- Search for `name = 'John'`.
- Leaf node entry contains:
  ```
  name: 'John', clustered key: 101
  ```

#### 2. Traverse Clustered Index (B+ Tree)
- Use `emp_id = 101` to search the **clustered index**.
- Locate the full row:
  ```
  emp_id: 101, name: 'John', dept: 'IT', salary: 90000
  ```

---

## 🔄 Summary Table

| Step | Index Used             | Traversal | Output                                |
|------|------------------------|-----------|----------------------------------------|
| 1    | Non-clustered on `name`| B+ Tree   | Clustered key: `emp_id = 101`         |
| 2    | Clustered on `emp_id`  | B+ Tree   | Actual row: includes `salary`         |

---

## 🛠️ Why Use Clustered Keys Instead of Physical Addresses?

- Clustered keys are **logical pointers**, not physical.
- More **stable and maintainable** than physical addresses.
- Avoids issues during **row movement** (e.g., page splits, rebalancing).

---

## ⚡ Optimization Tip: Covering Index

Avoid lookups entirely by creating an index that **includes all required columns**:
```sql
CREATE NONCLUSTERED INDEX idx_name_salary ON Employee(name) INCLUDE (salary);
```

Now the query:
```sql
SELECT salary FROM Employee WHERE name = 'John';
```
can be satisfied **entirely by the non-clustered index**, avoiding the second lookup.

---

## 📌 Final Notes

- Both clustered and non-clustered indexes use **B+ Tree structures**.
- Non-clustered index lookups involve **two B+ Tree traversals**.
- Understanding this process helps with **performance tuning** and **query optimization**.
