# 🧠 Dynamic Programming - Complete Interview Guide

> **"Those who cannot remember the past are condemned to compute it again" - DP Philosophy**

---

## 🎯 Table of Contents

1. [Recognition Patterns](#-recognition-patterns)
2. [Problem-Solving Framework](#-problem-solving-framework)  
3. [Memoization vs Tabulation](#-memoization-vs-tabulation)
4. [Classic Problem Categories](#-classic-problem-categories)
5. [Interview Question Bank](#-interview-question-bank)
6. [Common Pitfalls](#-common-pitfalls)
7. [Practice Templates](#-practice-templates)

---

## 🔍 Recognition Patterns

### **The Three Pillars of DP** #fundamental

Dynamic programming problems **ALWAYS** exhibit these three characteristics:

#### 1. **Optimal Substructure** 🏗️
> The optimal solution contains optimal solutions to subproblems

**Mental Model:** Building a tower - each level depends on the stability of levels below
**Test:** Can you say "the best way to solve the big problem uses the best solutions to smaller problems"?

**Example:** 
- Fibonacci: F(n) = F(n-1) + F(n-2) 
- Shortest path from A→C = Shortest path A→B + Shortest path B→C

#### 2. **Overlapping Subproblems** 🔄
> The same subproblems are solved multiple times

**Mental Model:** Calculating F(5) requires F(4) and F(3), but F(4) also needs F(3) - this overlap is your cue!
**Test:** Would a naive recursive solution recalculate the same values multiple times?

#### 3. **Optimization Objective** 🎯
> Looking for maximum, minimum, longest, shortest, or counting possibilities

**Recognition Keywords:**
- ✅ "maximize profit" → `max()`
- ✅ "minimum cost" → `min()`  
- ✅ "longest sequence" → track maximum length
- ✅ "number of ways" → sum possibilities
- ✅ "optimal solution" → compare alternatives

---

## 🛠️ Problem-Solving Framework

### **The 4-Step DP Approach** #methodology

#### **Step 1: Define Subproblems** 🎯
**Critical Question:** What does `dp[i]` represent?

**Examples:**
- Coin Change: `dp[i]` = minimum coins needed to make amount `i`
- Climbing Stairs: `dp[i]` = number of ways to reach step `i`
- LCS: `dp[i][j]` = length of LCS for strings `s1[0...i]` and `s2[0...j]`

#### **Step 2: Find Recurrence Relation** ⚡
**Discovery Process:** How does the current state relate to previous states?

**Template:**
```
dp[current_state] = optimize(dp[previous_states] + transition_cost)
```

**Examples:**
```java
// Fibonacci
dp[i] = dp[i-1] + dp[i-2]

// Coin Change  
dp[i] = min(dp[i-coin] + 1) for all coins

// LCS
if (s1[i] == s2[j]) dp[i][j] = dp[i-1][j-1] + 1
else dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

#### **Step 3: Identify Base Cases** 🧱
**Foundation Principle:** Simple scenarios where answer is known directly

**Examples:**
```java
// Fibonacci
dp[0] = 0, dp[1] = 1

// Coin Change
dp[0] = 0 (0 coins needed for amount 0)

// Climbing Stairs  
dp[0] = 1, dp[1] = 1
```

#### **Step 4: Build Solution** 🔨
Choose between memoization (top-down) or tabulation (bottom-up)

---

## 🔄 Memoization vs Tabulation

### **Memoization: Top-Down Approach** ⬇️

**Mental Model:** Maze explorer with notebook - write down answers as you discover them
**When to Use:** Don't need to solve ALL subproblems, recursive structure is natural

**Template:**
```java
public int solveDP(int state, Map<Integer, Integer> memo) {
    // Base case
    if (baseCondition) return baseValue;
    
    // Check memo
    if (memo.containsKey(state)) return memo.get(state);
    
    // Compute result
    int result = recurrenceRelation();
    
    // Store and return
    memo.put(state, result);
    return result;
}
```

**Example - Fibonacci:**
```java
public int fibonacci(int n, Map<Integer, Integer> memo) {
    if (n <= 1) return n;
    if (memo.containsKey(n)) return memo.get(n);
    
    int result = fibonacci(n-1, memo) + fibonacci(n-2, memo);
    memo.put(n, result);
    return result;
}
```

### **Tabulation: Bottom-Up Approach** ⬆️

**Mental Model:** Foundation builder - construct floor by floor from base to target
**When to Use:** Need most subproblems anyway, want better performance, need solution path

**Template:**
```java
public int solveDP(int n) {
    // Initialize DP table
    int[] dp = new int[n + 1];
    
    // Set base cases
    dp[0] = baseValue0;
    if (n > 0) dp[1] = baseValue1;
    
    // Fill table bottom-up
    for (int i = 2; i <= n; i++) {
        dp[i] = recurrenceRelation(dp, i);
    }
    
    return dp[n];
}
```

**Example - Fibonacci:**
```java
public int fibonacci(int n) {
    if (n <= 1) return n;
    
    int[] dp = new int[n + 1];
    dp[0] = 0;
    dp[1] = 1;
    
    for (int i = 2; i <= n; i++) {
        dp[i] = dp[i-1] + dp[i-2];
    }
    
    return dp[n];
}
```

---

## 📚 Classic Problem Categories

### **1. Linear DP** #linear-dp

**Pattern:** `dp[i]` depends on `dp[i-1]`, `dp[i-2]`, etc.
**Use Case:** Sequential decision making

#### **🔥 Must-Do Problems:**
- ✅ [Climbing Stairs](https://leetcode.com/problems/climbing-stairs/) - **Basic** #must-do
- ✅ [House Robber](https://leetcode.com/problems/house-robber/) - **Classic** #must-do  
- ✅ [Maximum Subarray](https://leetcode.com/problems/maximum-subarray/) - **Kadane's** #must-do

**Template:**
```java
// Linear DP Template
public int solve(int[] arr) {
    int n = arr.length;
    int[] dp = new int[n];
    
    dp[0] = baseCase;
    for (int i = 1; i < n; i++) {
        dp[i] = Math.max/min(dp[i-1] + arr[i], otherOptions);
    }
    
    return dp[n-1];
}
```

### **2. Knapsack Problems** #knapsack

**Pattern:** Choose/don't choose decisions with capacity constraints
**Variations:** 0/1, Unbounded, Bounded, Multi-dimensional

#### **🔥 Problem Variations:**
- ✅ [0/1 Knapsack](https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/) - **Classic** #must-do
- ✅ [Coin Change](https://leetcode.com/problems/coin-change/) - **Unbounded** #faang
- ✅ [Partition Equal Subset Sum](https://leetcode.com/problems/partition-equal-subset-sum/) - **Subset** #faang
- ✅ [Target Sum](https://leetcode.com/problems/target-sum/) - **Counting** #microsoft

**0/1 Knapsack Template:**
```java
public int knapsack(int[] weights, int[] values, int capacity) {
    int n = weights.length;
    int[][] dp = new int[n + 1][capacity + 1];
    
    for (int i = 1; i <= n; i++) {
        for (int w = 0; w <= capacity; w++) {
            if (weights[i-1] <= w) {
                dp[i][w] = Math.max(
                    dp[i-1][w], // don't take
                    dp[i-1][w - weights[i-1]] + values[i-1] // take
                );
            } else {
                dp[i][w] = dp[i-1][w];
            }
        }
    }
    
    return dp[n][capacity];
}
```

### **3. String DP** #string-dp

**Pattern:** Compare characters, build solutions for substrings
**Common:** Edit distance, palindromes, pattern matching

#### **🔥 Key Problems:**
- ✅ [Longest Common Subsequence](https://leetcode.com/problems/longest-common-subsequence/) - **Classic** #must-do
- ✅ [Edit Distance](https://leetcode.com/problems/edit-distance/) - **Hard** #google
- ✅ [Palindromic Substrings](https://leetcode.com/problems/palindromic-substrings/) - **Medium** #amazon
- ✅ [Distinct Subsequences](https://leetcode.com/problems/distinct-subsequences/) - **Hard** #netflix

**LCS Template:**
```java
public int longestCommonSubsequence(String text1, String text2) {
    int m = text1.length(), n = text2.length();
    int[][] dp = new int[m + 1][n + 1];
    
    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (text1.charAt(i-1) == text2.charAt(j-1)) {
                dp[i][j] = dp[i-1][j-1] + 1;
            } else {
                dp[i][j] = Math.max(dp[i-1][j], dp[i][j-1]);
            }
        }
    }
    
    return dp[m][n];
}
```

### **4. Grid/Path DP** #grid-dp

**Pattern:** Move through 2D grid, optimize path from start to end
**Variations:** Unique paths, minimum cost, obstacles

#### **🔥 Essential Problems:**
- ✅ [Unique Paths](https://leetcode.com/problems/unique-paths/) - **Basic** #must-do
- ✅ [Unique Paths II](https://leetcode.com/problems/unique-paths-ii/) - **With Obstacles** #amazon
- ✅ [Minimum Path Sum](https://leetcode.com/problems/minimum-path-sum/) - **Cost** #microsoft
- ✅ [Dungeon Game](https://leetcode.com/problems/dungeon-game/) - **Reverse DP** #hard

**Grid DP Template:**
```java
public int uniquePaths(int m, int n) {
    int[][] dp = new int[m][n];
    
    // Base cases
    for (int i = 0; i < m; i++) dp[i][0] = 1;
    for (int j = 0; j < n; j++) dp[0][j] = 1;
    
    // Fill grid
    for (int i = 1; i < m; i++) {
        for (int j = 1; j < n; j++) {
            dp[i][j] = dp[i-1][j] + dp[i][j-1];
        }
    }
    
    return dp[m-1][n-1];
}
```

### **5. Tree DP** #tree-dp

**Pattern:** Combine information from children to solve parent
**Applications:** Path sums, node selection, tree modification

#### **🔥 Tree DP Problems:**
- ✅ [House Robber III](https://leetcode.com/problems/house-robber-iii/) - **Tree** #medium
- ✅ [Binary Tree Maximum Path Sum](https://leetcode.com/problems/binary-tree-maximum-path-sum/) - **Hard** #faang
- ✅ [Diameter of Binary Tree](https://leetcode.com/problems/diameter-of-binary-tree/) - **Easy** #google

**Tree DP Template:**
```java
class TreeNode {
    int val;
    TreeNode left, right;
}

public int rob(TreeNode root) {
    int[] result = robHelper(root);
    return Math.max(result[0], result[1]);
}

// Returns [rob_root, not_rob_root]
private int[] robHelper(TreeNode node) {
    if (node == null) return new int[]{0, 0};
    
    int[] left = robHelper(node.left);
    int[] right = robHelper(node.right);
    
    int rob = node.val + left[1] + right[1];
    int notRob = Math.max(left[0], left[1]) + Math.max(right[0], right[1]);
    
    return new int[]{rob, notRob};
}
```

---

## 💡 Interview Question Bank

### **🔥 Easy Level** (Build Confidence)
1. ✅ [Climbing Stairs](https://leetcode.com/problems/climbing-stairs/) #must-do
2. ✅ [Best Time to Buy and Sell Stock](https://leetcode.com/problems/best-time-to-buy-and-sell-stock/)
3. ✅ [Maximum Subarray](https://leetcode.com/problems/maximum-subarray/)
4. ✅ [Range Sum Query - Immutable](https://leetcode.com/problems/range-sum-query-immutable/)

### **🔥 Medium Level** (Core Practice)
1. ✅ [Coin Change](https://leetcode.com/problems/coin-change/) #must-do #faang
2. ✅ [Unique Paths](https://leetcode.com/problems/unique-paths/) #must-do
3. ✅ [Longest Common Subsequence](https://leetcode.com/problems/longest-common-subsequence/) #must-do
4. ✅ [Word Break](https://leetcode.com/problems/word-break/) #amazon #microsoft
5. ✅ [House Robber](https://leetcode.com/problems/house-robber/) #must-do
6. ✅ [Decode Ways](https://leetcode.com/problems/decode-ways/) #facebook
7. ✅ [Jump Game](https://leetcode.com/problems/jump-game/) #amazon
8. ✅ [Partition Equal Subset Sum](https://leetcode.com/problems/partition-equal-subset-sum/) #google

### **🔥 Hard Level** (Advanced Mastery)
1. ✅ [Edit Distance](https://leetcode.com/problems/edit-distance/) #google #hard
2. ✅ [Regular Expression Matching](https://leetcode.com/problems/regular-expression-matching/) #hard
3. ✅ [Burst Balloons](https://leetcode.com/problems/burst-balloons/) #hard #interval-dp
4. ✅ [Super Egg Drop](https://leetcode.com/problems/super-egg-drop/) #hard #optimization
5. ✅ [Palindrome Partitioning II](https://leetcode.com/problems/palindrome-partitioning-ii/) #hard

---

## ⚠️ Common Pitfalls

### **❌ Mistakes That Kill Interviews** #pitfalls

1. **Wrong State Definition**
   - ❌ `dp[i]` = result at index i vs result using first i elements
   - ✅ **Always clarify**: What exactly does `dp[i]` represent?

2. **Base Case Errors**
   - ❌ Forgetting edge cases like empty string, zero amount
   - ✅ **Test**: What's the answer for the smallest valid input?

3. **Index Confusion**
   - ❌ Off-by-one errors in array indexing
   - ✅ **Practice**: Draw examples with indices labeled

4. **Optimization Direction**
   - ❌ Using max when need min, or vice versa
   - ✅ **Check**: Does the problem want maximum or minimum?

5. **Space Optimization Errors**
   - ❌ Overwriting values still needed
   - ✅ **Verify**: Which previous states does current state actually need?

### **🛡️ Debugging Checklist**

When your DP solution fails:
- [ ] Verify base cases with hand calculation
- [ ] Check recurrence relation matches problem logic
- [ ] Test with small examples (n=0, 1, 2)
- [ ] Confirm index boundaries and array access
- [ ] Validate optimization direction (max vs min)

---

## 📝 Practice Templates

### **💪 Daily Practice Routine**

**Week 1-2: Foundation**
- Day 1-3: Linear DP (Fibonacci variants, House Robber)
- Day 4-5: Grid DP (Unique Paths, Min Path Sum)
- Weekend: Review and practice mixed problems

**Week 3-4: Intermediate**
- Day 1-2: Knapsack variations (0/1, Unbounded, Subset Sum)
- Day 3-4: String DP (LCS, Edit Distance)
- Day 5: Tree DP (Binary Tree problems)
- Weekend: Mock interview with DP problems

**Week 5+: Advanced**
- Focus on hard problems and optimizations
- Practice explaining approach clearly
- Work on time management (20-30 min per problem)

### **🎯 Interview Simulation**

**Template Response Structure:**

1. **"I recognize this as a DP problem because..."**
   - Mention optimal substructure + overlapping subproblems

2. **"Let me define my subproblems..."**
   - Clearly state what dp[i] represents

3. **"The recurrence relation is..."**
   - Derive the formula with explanation

4. **"Base cases are..."**
   - Handle edge cases and simple scenarios

5. **"Let me implement and trace through an example..."**
   - Code + walk through small test case

---

## 🎓 Mastery Checkpoints

**✅ Beginner Level:**
- [ ] Can identify DP problems from description
- [ ] Understand difference between memoization/tabulation  
- [ ] Solved 10+ easy DP problems
- [ ] Can explain base cases and recurrence

**✅ Intermediate Level:**
- [ ] Solved 25+ DP problems across different patterns
- [ ] Can derive state transitions independently
- [ ] Understand space optimization techniques
- [ ] Handle 2D DP problems confidently

**✅ Advanced Level:**
- [ ] Solved 50+ DP problems including hard ones
- [ ] Can solve most medium DP problems in 20-30 minutes
- [ ] Recognize non-obvious DP problems (like some greedy problems)
- [ ] Can teach DP concepts to others clearly

---

**Study Progress:**
- [ ] Linear DP (0/15 problems)
- [ ] Knapsack DP (0/10 problems)  
- [ ] String DP (0/8 problems)
- [ ] Grid DP (0/6 problems)
- [ ] Tree DP (0/5 problems)

**Last Updated:** August 2025  
**Next Focus:** [Complete knapsack variations]