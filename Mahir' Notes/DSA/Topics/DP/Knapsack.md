# Dynamic Programming Knapsack Problems

#algorithms #dynamic-programming #optimization

## Overview

Dynamic programming knapsack problems are fundamental optimization problems that model resource allocation under constraints. They demonstrate the **principle of optimality** and are building blocks for understanding more complex DP algorithms.

**Core Concept**: Given limited capacity, choose items to maximize value while staying within constraints.

## Why Knapsack Problems Matter

### Real-World Applications

- **Portfolio Optimization** - [[Finance Applications]]
- **CPU Scheduling** - [[Operating Systems]]
- **Memory Allocation** - [[System Design]]
- **Project Selection** - [[Management Science]]
- **Protein Folding** - [[Bioinformatics]]

### Theoretical Importance

- Demonstrates [[Principle of Optimality]]
- Bridge between [[Greedy Algorithms]] and [[Dynamic Programming]]
- Foundation for [[NP-Complete Problems]] understanding

## The Pattern Recognition Framework

### 1. State Definition Pattern

> **Key Question**: What information do I need to make optimal decisions?

**Template**: `dp[parameters]` where parameters capture changing conditions

**Classic Knapsack**: `dp[i][w]` = maximum value using first `i` items with weight limit `w`

### 2. Recurrence Relation Pattern

**Universal Choice Framework**:

```
For each item: Include OR Exclude
dp[current] = max(all_valid_choices)
```

**Classic Pattern**:

```
dp[i][w] = max(
    dp[i-1][w],                    // exclude item i
    dp[i-1][w-weight[i]] + value[i] // include item i (if fits)
)
```

### 3. Base Case Pattern

- **No items**: `dp[0][w] = 0`
- **No capacity**: `dp[i][0] = 0`
- **Invalid states**: Handle bounds checking

## Knapsack Variations

### [[0-1 Knapsack]]

**Constraint**: Each item used at most once **State**: `dp[i][w]` **Recurrence**: Choose include/exclude for each item **Applications**: Resource allocation, project selection

### [[Unbounded Knapsack]]

**Constraint**: Unlimited use of each item **State**: `dp[i][w]` **Key Difference**: `dp[i][w-weight[i]]` instead of `dp[i-1][w-weight[i]]` **Applications**: Coin change, cutting problems

### [[Multiple Knapsack]]

**Constraint**: Multiple capacity constraints **State**: `dp[i][w1][w2]` (or more dimensions) **Applications**: Multi-resource scheduling

### [[Bounded Knapsack]]

**Constraint**: Limited quantity of each item **Approach**: Expand to 0-1 or use counting **Applications**: Inventory management

### [[Subset Sum]]

**Special Case**: Boolean knapsack (achievable sum?) **State**: `dp[i][sum]` → boolean **Recurrence**: OR operation instead of max

## Problem-Solving Methodology

### Step 1: Problem Analysis

```markdown
- [ ] Identify the capacity constraint(s)
- [ ] Identify the items and their properties
- [ ] Determine if items can be reused
- [ ] Define what "optimal" means
```

### Step 2: State Design

```markdown
- [ ] What parameters change during recursion?
- [ ] What information is needed for decisions?
- [ ] How many dimensions needed?
```

### Step 3: Recurrence Development

```markdown
- [ ] What choices exist at each step?
- [ ] How do choices affect future states?
- [ ] What are the base cases?
```

### Step 4: Implementation Strategy

```markdown
- [ ] Top-down (memoization) or bottom-up?
- [ ] Space optimization possible?
- [ ] Need to track actual solution?
```

## Common Patterns Across Variations

### Decision Pattern

```
For each state:
  For each valid choice:
    Calculate result of making that choice
  Return optimal choice
```

### State Transition Pattern

```
Current State → Action → Next State + Cost/Value
```

### Optimization Pattern

- **Maximization**: `max(current_best, new_option)`
- **Minimization**: `min(current_best, new_option)`
- **Counting**: `sum(all_ways_to_reach_state)`
- **Existence**: `any(ways_to_reach_state)`

## Advanced Concepts

### [[Space Optimization]]

- Rolling arrays for 2D → 1D reduction
- When only previous row needed

### [[Path Reconstruction]]

- Tracking decisions made
- Backtracking from final state

### [[Multiple Objectives]]

- Pareto optimality
- Multi-dimensional value functions

## Practice Strategy

### Beginner Level

1. [[0-1 Knapsack]] - Master the fundamentals
2. [[Subset Sum]] - Boolean version
3. [[Coin Change]] - Unbounded variation

### Intermediate Level

1. [[Partition Problem]] - Advanced subset sum
2. [[Rod Cutting]] - Unbounded with positions
3. [[Edit Distance]] - String DP patterns

### Advanced Level

1. [[Multiple Knapsack]] - Multi-constraint
2. [[Knapsack with Dependencies]] - Graph constraints
3. [[Online Knapsack]] - Streaming algorithms

## Key Insights for Pattern Recognition

### The Meta-Pattern

1. **Identify**: What am I optimizing? What are my constraints?
2. **States**: What information determines my future choices?
3. **Transitions**: What decisions can I make from each state?
4. **Recurrence**: How do decisions affect the optimal value?

### Red Flags (When NOT Knapsack)

- Dependencies between items → [[Graph DP]]
- Sequential ordering matters → [[Sequence DP]]
- Continuous values → [[Mathematical Optimization]]

## Related Topics

- [[Dynamic Programming]]
- [[Greedy Algorithms]]
- [[Complexity Analysis]]
- [[Optimization Theory]]
- [[Algorithm Design Patterns]]

---

_Tags_: #knapsack #dynamic-programming #algorithms #optimization #patterns