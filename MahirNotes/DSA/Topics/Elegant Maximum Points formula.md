# Proof and Intuition: Maximum Points Formula

## The Correct Formula

**Maximum Points = min(⌊sum/2⌋, sum - max_element)**

## Intuition

### The Two Competing Constraints

Think of this as a **resource allocation problem** with two bottlenecks:

1. **Total Resource Constraint**: You have `sum` total units, each point costs 2 units
    
    - Maximum possible points = ⌊sum/2⌋
2. **Pairing Constraint**: The largest element can only pair with other elements
    
    - The largest element has `max` units
    - All other elements combined have `sum - max` units
    - So the largest element can make at most `sum - max` pairings

### Visual Intuition

```
Example: [3, 4]
┌─────────┐  ┌─────────────┐
│ Element │  │   Element   │
│    3    │  │      4      │
│ ● ● ●   │  │ ● ● ● ●     │
└─────────┘  └─────────────┘

Pairing process:
● from left ↔ ● from right  (Point 1)
● from left ↔ ● from right  (Point 2)  
● from left ↔ ● from right  (Point 3)
              ● left alone  (No more pairs possible)

Maximum pairs = min(3, 4) = 3
```

### The "Hungry Giant" Analogy

Imagine the largest number as a hungry giant that wants to eat pairs:

- Giant has `max` units of hunger
- Everyone else has `sum - max` units of food
- Giant can only eat as much food as others provide: `sum - max`
- But giant also can't eat more than half the total food: `sum/2`

The giant gets `min(sum/2, sum - max)` meals!

## Formal Proof

### Theorem

For a list of non-negative integers with at least 2 positive values, the maximum achievable points is: __P_ = min(⌊S/2⌋, S - M)_*

where S = sum of all positive numbers, M = maximum element.

### Proof

#### Part 1: Upper Bound (No strategy can exceed this)

**Lemma 1**: No strategy can achieve more than ⌊S/2⌋ points. _Proof_: Each move reduces total sum by 2, and game ends when sum ≤ 1. Maximum moves = ⌊S/2⌋.

**Lemma 2**: No strategy can achieve more than S - M points. _Proof_:

- Let M be the largest element initially
- In any sequence of moves, let k be the total number of times we reduce the largest element
- The largest element contributes k to our point total
- All other elements together contribute at most their initial sum = S - M
- But every point requires pairing largest element's unit with some other unit
- So k ≤ S - M (largest element can't pair more than others provide)
- Total points ≤ k ≤ S - M

**Combining**: Maximum points ≤ min(⌊S/2⌋, S - M)

#### Part 2: Lower Bound (This bound is achievable)

We'll prove by construction using a **greedy algorithm**:

**Algorithm**: Always pick the two largest positive numbers and reduce both by 1.

**Invariant**: At any point in the game, if current sum is s and current max is m, then remaining achievable points = min(⌊s/2⌋, s - m).

**Proof by strong induction**:

_Base case_: When s ≤ 1 or fewer than 2 positive numbers exist:

- No moves possible, so remaining points = 0
- Formula gives: min(⌊s/2⌋, s - m) = 0 ✓

_Inductive step_: Assume invariant holds for all states with sum < s.

- Current state: sum = s, max = m, at least 2 positive numbers
- Pick max element m and second largest element n (where n ≥ 1)
- After move: sum' = s - 2, max' ≤ max(m-1, n-1, other_elements)

**Case Analysis**:

_Case 1_: m > n (strict inequality)

- After move: max' = m - 1
- By induction: remaining points = min(⌊(s-2)/2⌋, (s-2) - (m-1)) = min(⌊(s-2)/2⌋, s-m-1)
- Total points = 1 + min(⌊(s-2)/2⌋, s-m-1)

_Subcase 1a_: Original constraint was S/2 (i.e., S/2 ≤ S-M)

- This means M ≤ S/2, so m ≤ s/2
- Total points = 1 + ⌊(s-2)/2⌋ = ⌊s/2⌋ ✓

_Subcase 1b_: Original constraint was S-M (i.e., S-M < S/2)

- This means M > S/2, so m > s/2
- Total points = 1 + (s-m-1) = s-m ✓

_Case 2_: m = n

- Similar analysis applies

Therefore, the greedy algorithm achieves exactly min(⌊S/2⌋, S-M) points.

### Part 3: The Formula's Elegance

The beauty of `min(sum/2, sum - max)` is that it automatically detects which constraint dominates:

- **When max ≤ sum/2**: Numbers are balanced → use sum/2
- **When max > sum/2**: Largest number dominates → use sum - max

## Detailed Example: [2, 1, 8, 1]

Let's trace through a complete example to see both constraints in action.

**Initial Analysis:**

- Numbers: [2, 1, 8, 1]
- Sum = 12, Max = 8
- Constraint 1 (total units): ⌊12/2⌋ = 6 points possible
- Constraint 2 (pairing limit): 12 - 8 = 4 points possible
- **Prediction: min(6, 4) = 4 points**

**Step-by-Step Simulation:**

```
Step 0: [2, 1, 8, 1] (sum=12, positive_count=4)
Step 1: Pick 8,2 → [1, 1, 7, 1] (sum=10, positive_count=4) +1 point
Step 2: Pick 7,1 → [1, 0, 6, 1] (sum=8, positive_count=3)  +1 point  
Step 3: Pick 6,1 → [1, 0, 5, 0] (sum=6, positive_count=2)  +1 point
Step 4: Pick 5,1 → [0, 0, 4, 0] (sum=4, positive_count=1)  +1 point
Step 5: [0, 0, 4, 0] → Only 1 positive number left, STOP
```

**Total: 4 points** ✓

**Why 4, not 6?**

- We had 12 total units, theoretically enough for 6 points
- But the largest element (8) could only pair with 4 other units: 2+1+1=4
- After 4 pairings, the largest element still had 4 units left unpaired
- These 4 units became "waste" because they had no partners

## More Examples with Intuition

**Balanced Case: [5, 3, 2]**

- sum = 10, max = 5
- 5 ≤ 10/2, so balanced → answer = 10/2 = 5

**Imbalanced Case: [1, 3]**

- sum = 4, max = 3
- 3 > 4/2, so imbalanced → answer = 4-3 = 1

**Extreme Case: [100, 1, 1, 1]**

- sum = 103, max = 100
- 100 > 103/2, so very imbalanced → answer = 103-100 = 3
- The giant has 100 units but can only find 3 units to pair with!

## Why Other Formulas Fail

- **sum/2**: Ignores distribution constraints
- **sum - max**: Ignores the fact that we might not have enough total units
- **min(max, others)**: Doesn't account for the "2 units per point" cost

The correct formula elegantly captures both the resource constraint and the pairing constraint in one simple expression.

---

## Obsidian-Specific Features

### Linked Concepts

- [[Game Theory]] - This is a zero-sum optimization problem
- [[Greedy Algorithms]] - The pairing strategy is inherently greedy
- [[Resource Allocation]] - Two competing bottlenecks
- [[Mathematical Proof Techniques]] - Uses constructive proof and invariants

### Tags

#optimization #algorithms #game-theory #mathematical-proof #greedy-strategy

### Key Insight Callout

> [!important] Core Insight The formula `min(sum/2, sum - max)` elegantly handles two constraints:
> 
> 1. **Total units constraint**: Can't make more than sum/2 points
> 2. **Pairing constraint**: Largest element can't pair more than sum-max times

### Quick Reference

> [!tip] Formula **Maximum Points = min(⌊sum/2⌋, sum - max_element)**
> 
> Works for any distribution of positive integers!