# 🧠 Multi-Source BFS (Breadth-First Search)

  

## 📌 What is Multi-Source BFS?

  

**Multi-Source BFS** is a variation of BFS where **multiple nodes are treated as starting points simultaneously**.

  

Instead of finding:

> Shortest distance from *one* source

  

We find:

> **Shortest distance from the *nearest* source**

  

All sources start at **distance = 0** and expand together.

  

---

  

## 🧠 Core Intuition (Must Remember)

  

Think in terms of **spreading**:

- 🔥 Fire

- 💧 Water

- 🦠 Virus

- 🍊 Rotting

  

Each source spreads **one step per unit time**.

When two spreads meet, **the earlier one wins**.

  

➡️ BFS guarantees this because it explores **level by level**.

  

---

  

## 🔁 Single-Source vs Multi-Source BFS

  

| Aspect | Single-Source BFS | Multi-Source BFS |

|------|------------------|------------------|

| Starting nodes | 1 | Many |

| Queue initialization | One node | All sources |

| Distance meaning | From that source | From nearest source |

| Time Complexity | O(V + E) | O(V + E) |

  

⚠️ Time complexity **does not increase** with more sources.

  

---

  

## ⚙️ How Multi-Source BFS Works

  

### Step 1: Initialize

- Push **all source nodes** into the queue

- Mark them visited

- Set distance = 0

  

### Step 2: Run Normal BFS

- Pop from queue

- Visit neighbors

- Assign `distance = parent + 1`

- Push into queue

  

### Step 3: First Visit = Best Answer

- Never revisit a node

- First arrival gives shortest distance

  

---

  

## 🧩 Mental Trigger (Interview / Problem Solving)

  

Whenever you see:

- “distance to **nearest** X”

- “minimum time until **all** are reached”

- “spread / rot / infection / flood”

  

👉 **Immediately think: Multi-Source BFS**

  

---

  

## 🧪 Classic Grid Example

  

### Problem:

Given a grid:

- `1` → source

- `0` → empty cell

  

Find distance of each `0` to the nearest `1`.

  

### Approach:

- Push **all `1`s** into the queue

- BFS once

- Compute distances for all cells

  

---

  

## 🧾 Pseudocode (Grid-Based)

  

```java

Queue<int[]> q = new LinkedList<>();

  

// Push all sources

for (int i = 0; i < rows; i++) {

for (int j = 0; j < cols; j++) {

if (grid[i][j] == 1) {

q.add(new int[]{i, j});

dist[i][j] = 0;

}

}

}

  

// BFS

while (!q.isEmpty()) {

int[] cur = q.poll();

for (int[] d : directions) {

int ni = cur[0] + d[0];

int nj = cur[1] + d[1];

if (valid && dist[ni][nj] == -1) {

dist[ni][nj] = dist[cur[0]][cur[1]] + 1;

q.add(new int[]{ni, nj});

}

}

}

```

  

---

  

## 🚀 High-Value Use Cases

  

### 1️⃣ Rotting Oranges

- All rotten oranges → sources

- BFS levels = minutes

- Answer = max distance

  

### 2️⃣ Distance to Nearest Zero / One

- All zeros (or ones) → sources

- Single BFS pass

  

### 3️⃣ Walls and Gates

- All gates → sources

- Distance to nearest gate

  

### 4️⃣ Spread Problems

- Fire, virus, water, gas

- Time = BFS level

  

### 5️⃣ Nearest Facility

- Hospitals / police stations / charging points

- All facilities → sources

  

---

  

## ❌ Common Mistake

  

🚫 Running BFS separately from each source

- Time: **O(K × (V + E))**

  

✅ Correct approach:

- Push all sources together

- Time: **O(V + E)**

  

---

  

## 🧠 Key Insight

  

> **Multi-Source BFS is Parallel BFS**

  

All sources expand simultaneously.

The first time a node is visited → optimal solution.