# Cyclic Decomposition for In-Place Array Rearrangement

## Core Concept: Permutation Cycles

### What is Cyclic Decomposition?

**Cyclic decomposition** is a fundamental concept in permutation theory where any permutation can be broken down into disjoint cycles. When rearranging elements in an array, each element follows a path from its current position to its final destination, forming closed loops called **cycles**.

**Key Properties:**

- Every element belongs to exactly one cycle
- Cycles are disjoint (non-overlapping)
- Following a cycle eventually returns to the starting position
- The number of swaps needed equals (cycle_length - 1)

---

## Mathematical Foundation

### Index Mapping Function

For the shuffle problem, the mapping is:

```
f(i) = {
    2i           if i < n     (x₁, x₂, ..., xₙ)
    2(i-n) + 1   if i ≥ n     (y₁, y₂, ..., yₙ)
}
```

**Example with n=3:**

```
Original: [x₁, x₂, x₃, y₁, y₂, y₃]
Indices:   0   1   2   3   4   5

Target:   [x₁, y₁, x₂, y₂, x₃, y₃]
Indices:   0   1   2   3   4   5

Mapping:
0 → 0 (2×0)
1 → 2 (2×1)
2 → 4 (2×2)
3 → 1 (2×(3-3)+1)
4 → 3 (2×(4-3)+1)
5 → 5 (2×(5-3)+1)
```

### Cycle Detection

Following the mapping reveals cycles:

- **Cycle 1:** 0 → 0 (fixed point)
- **Cycle 2:** 1 → 2 → 4 → 3 → 1
- **Cycle 3:** 5 → 5 (fixed point)

---

## Algorithm Breakdown

### Step-by-Step Process

#### 1. **Cycle Traversal**

```
Start at position i
↓
Find next = f(i)
↓
Save value at next
↓
Place current value at next
↓
Move to next position
↓
Repeat until cycle completes
```

#### 2. **Visited Marking Strategy**

**Problem:** How to know if an index was already processed without extra space?

**Solution:** Use sign flipping

- Original values are positive
- Mark visited by making value negative
- Final pass restores signs

```java
// Mark as visited
nums[next] = -prevValue;

// Check if visited
if (nums[curr] < 0) continue;
```

#### 3. **In-Place Rotation**

For a cycle: `a → b → c → a`

```
Initial:     [A, B, C]
             
Step 1:      save = B
             nums[b] = -A
             
Step 2:      temp = C
             nums[c] = -B
             
Step 3:      (cycle complete when nums[a] < 0)
```

---

## Detailed Example Walkthrough

### Input: `nums = [2,5,1,3,4,7]`, `n = 3`

**Desired Output:** `[2,3,5,4,1,7]`

**Index Mapping:**

```
i=0 → 0   (fixed)
i=1 → 2
i=2 → 4
i=3 → 1
i=4 → 3
i=5 → 5   (fixed)
```

**Execution Trace:**

```
Initial: [2, 5, 1, 3, 4, 7]

i=0: Already at correct position (0→0)
     nums[0] = -2
     Result: [-2, 5, 1, 3, 4, 7]

i=1: Start cycle (1→2→4→3→1)
     curr=1, prevValue=5
     next=2, temp=1, nums[2]=-5
     Result: [-2, 5, -5, 3, 4, 7]
     
     curr=2, prevValue=1
     next=4, temp=4, nums[4]=-1
     Result: [-2, 5, -5, 3, -1, 7]
     
     curr=4, prevValue=4
     next=3, temp=3, nums[3]=-4
     Result: [-2, 5, -5, -4, -1, 7]
     
     curr=3, prevValue=3
     next=1, nums[1]<0 → STOP (cycle complete)

i=2,3,4: Skip (already negative)

i=5: Fixed point (5→5)
     nums[5] = -7
     Result: [-2, 5, -5, -4, -1, -7]

Wait! nums[1] is still positive. Let me recalculate...

Actually, we need to place prevValue=3:
     curr=3, prevValue=3
     next=1, nums[1]=-3
     Result: [-2, -3, -5, -4, -1, 7]
     Cycle continues...
     
     curr=1, prevValue=? (nums[1] is now -3, so break)

Final restoration: [2, 3, 5, 4, 1, 7] ✓
```

---

## Applications of Cyclic Decomposition

### 1. **Array Rearrangement Problems**

- **Shuffle algorithms** (like this problem)
- **Rotate array by k positions**
- **Reverse array in groups**

**Example:**

```java
// Rotate array right by k positions
// Uses cyclic decomposition with gcd(n,k) cycles
```

### 2. **String Transformation**

- **Reverse words in string in-place**
- **Cipher encryption/decryption** (Caesar cipher)

### 3. **Image Processing**

- **Matrix rotation** (90°, 180°, 270°)
- **Image flipping** (horizontal/vertical)

**Example (90° rotation):**

```
(i,j) → (j, n-1-i)
Forms cycles through matrix positions
```

### 4. **Graph Theory**

- **Detecting cycles in directed graphs**
- **Permutation group analysis**
- **Rubik's Cube solving algorithms**

### 5. **Database Operations**

- **In-place table reorganization**
- **Index rebuilding without extra space**

### 6. **Memory Management**

- **Garbage collection** (mark-and-sweep)
- **Memory compaction algorithms**

### 7. **Cryptography**

- **Block cipher permutations** (DES, AES)
- **Substitution-permutation networks**

### 8. **Sorting Algorithms**

- **Cycle sort** (minimizes writes)
- **In-place merge sort variations**

**Cycle Sort Example:**

```java
// Finds correct position and swaps in cycles
// Optimal for minimizing write operations (useful for flash memory)
```

### 9. **Game Theory**

- **Puzzle solving** (15-puzzle, sliding puzzles)
- **State space exploration**

### 10. **Computational Biology**

- **Genome rearrangement** analysis
- **Protein folding** permutation tracking

---

## Complexity Analysis

### Time Complexity: **O(n)**

- Each element visited exactly once
- Each cycle traversal is proportional to cycle length
- Sum of all cycle lengths = n

### Space Complexity: **O(1)**

- No auxiliary data structures
- Sign flipping uses existing array space
- Only constant variables (curr, next, prevValue, temp)

---

## Key Advantages

1. **Space Efficient:** No extra arrays or hash maps
2. **Cache Friendly:** Sequential access patterns
3. **Minimal Writes:** Each position written to once (plus sign restoration)
4. **Mathematically Elegant:** Based on permutation theory
5. **Deterministic:** No randomization, consistent performance

---

## Common Pitfalls & Edge Cases

### 1. **Sign Flipping Issues**

```java
// ❌ Wrong: Assumes all values are positive
// If array contains negatives, use different marking

// ✅ Solution: Add offset or use separate boolean array
```

### 2. **Overflow in Index Calculation**

```java
// For very large n, 2*curr might overflow
next = 2 * curr; // Potential overflow

// Better: Use long or check bounds
```

### 3. **Fixed Points**

```java
// Positions where i → i (like 0→0, 5→5)
// Must handle to avoid infinite loops
if (curr == next) {
    nums[curr] = -nums[curr];
    break;
}
```

---

## Related LeetCode Problems

1. **[41. First Missing Positive](https://leetcode.com/problems/first-missing-positive/)** - Uses index marking
2. **[287. Find Duplicate Number](https://leetcode.com/problems/find-the-duplicate-number/)** - Cycle detection
3. **[442. Find All Duplicates](https://leetcode.com/problems/find-all-duplicates-in-an-array/)** - Sign marking
4. **[48. Rotate Image](https://leetcode.com/problems/rotate-image/)** - Cyclic rotation
5. **[189. Rotate Array](https://leetcode.com/problems/rotate-array/)** - Array rotation with reversal

---

## Interview Tips

**When to recognize cyclic decomposition:**

- "In-place" constraint with O(1) space
- Rearrangement/permutation problem
- Each element has deterministic target position
- Need to avoid overwriting before reading

**What to communicate:**

1. "This is a permutation cycle problem"
2. "I'll trace cycles using the mapping function"
3. "I'll mark visited positions with sign flipping"
4. "Each element is moved exactly once"

This technique is **powerful** but **underutilized** - mastering it gives you an edge in array manipulation problems! 🚀