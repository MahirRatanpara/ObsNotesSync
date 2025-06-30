# 📚 Subset Pattern in Algorithms

## ✅ What is the Subset Pattern?

The **Subset Pattern** is used when solving problems that involve **generating all combinations** of a given set — typically by including or excluding each element. It is commonly used in:

- Combinatorics
- Backtracking
- Bitmasking
- Interview problems

---

## 🧠 Classic Problem: Generate All Subsets (Power Set)

### Problem Statement:
> Given a set of distinct integers, return all possible subsets (the power set).

### Example:
```text
Input: [1, 2, 3]
Output: 
[
  [], [1], [2], [3], 
  [1,2], [1,3], [2,3], 
  [1,2,3]
]
```

---

## ✨ Common Approaches

### 1. 🔁 Iterative Approach

```java
public List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    result.add(new ArrayList<>()); // empty subset

    for (int num : nums) {
        int n = result.size();
        for (int i = 0; i < n; i++) {
            List<Integer> subset = new ArrayList<>(result.get(i));
            subset.add(num);
            result.add(subset);
        }
    }

    return result;
}
```

---

### 2. 🔍 Backtracking (Recursive DFS)

```java
public List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    backtrack(0, nums, new ArrayList<>(), result);
    return result;
}

private void backtrack(int start, int[] nums, List<Integer> current, List<List<Integer>> result) {
    result.add(new ArrayList<>(current));
    for (int i = start; i < nums.length; i++) {
        current.add(nums[i]);
        backtrack(i + 1, nums, current, result);
        current.remove(current.size() - 1); // undo
    }
}
```

---

### 3. ⚙️ Bit Manipulation

```java
public List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    int total = 1 << nums.length; // 2^n subsets

    for (int mask = 0; mask < total; mask++) {
        List<Integer> subset = new ArrayList<>();
        for (int i = 0; i < nums.length; i++) {
            if ((mask & (1 << i)) != 0) {
                subset.add(nums[i]);
            }
        }
        result.add(subset);
    }

    return result;
}
```

---

## 🔁 Variations of Subset Problems

- ✅ **Subset Sum**: Is there a subset that adds up to a given sum?
- 🧮 **K-Subsets**: Generate subsets of exactly size `k`
- ❌ **Subsets with Duplicates**: Avoid duplicate subsets
- 🎯 **Combination Sum**: Find subsets that sum to a target
