# Greedy Algorithms

## Why It Matters

When greedy works it is dramatically simpler and faster than DP. When it doesn't, it silently produces wrong answers. The skill is telling the two apart quickly.

## Core Idea

Make the locally optimal choice at each step and never reconsider. Valid only when the problem has the **greedy choice property**: a local optimum is part of some global optimum.

## How To Verify Greedy Works

Three approaches, in order of interview practicality:

1. **Exchange argument** — show any optimal solution can be transformed into the greedy one without getting worse. This is the standard proof and the one to sketch aloud.
2. **Try to build a counterexample.** Spend 60 seconds. If you find one, use DP.
3. **Compare against brute force** on small inputs (only viable when practising, not in the interview).

**Never assert greedy works without at least attempting step 2.**

## The Canonical Counterexample

Coin Change with coins `[1, 3, 4]`, amount `6`:
- Greedy: 4 + 1 + 1 = **3 coins**
- Optimal: 3 + 3 = **2 coins**

Greedy works for canonical currency systems (1, 5, 10, 25) but not arbitrary sets. Know this example cold — it's the most common "why not greedy?" probe.

## Common Greedy Shapes

| Shape | Example | Greedy rule |
|---|---|---|
| Activity selection | Non-overlapping Intervals | Earliest end time |
| Reach / jump | Jump Game | Track farthest reachable |
| Fractional resource | Fractional Knapsack | Highest value/weight ratio |
| Scheduling with deadlines | Task Scheduler | Most frequent first |
| Two-side sweep | Candy, Trapping Rain Water | Satisfy each constraint in one pass per direction |
| Exchange / swap | Gas Station | Reset start on deficit |
| Huffman-style | Minimum Cost to Connect Sticks | Always merge the two smallest |

## Jump Game — The Reachability Idiom

```java
int farthest = 0;
for (int i = 0; i < n; i++) {
    if (i > farthest) return false;              // unreachable
    farthest = Math.max(farthest, i + nums[i]);
}
return true;
```

Jump Game II (minimum jumps) extends this with a "current level end" pointer — it's BFS on an array:

```java
int jumps = 0, curEnd = 0, farthest = 0;
for (int i = 0; i < n - 1; i++) {
    farthest = Math.max(farthest, i + nums[i]);
    if (i == curEnd) { jumps++; curEnd = farthest; }
}
```

## Gas Station — The Reset Insight

If total gas ≥ total cost, a solution exists and is unique. Track a running tank; whenever it goes negative, no start in the passed range can work, so reset the start to `i + 1`.

```java
int total = 0, tank = 0, start = 0;
for (int i = 0; i < n; i++) {
    int diff = gas[i] - cost[i];
    total += diff; tank += diff;
    if (tank < 0) { start = i + 1; tank = 0; }
}
return total >= 0 ? start : -1;
```

## Greedy vs DP

| | Greedy | DP |
|---|---|---|
| Considers | One choice per step | All choices |
| Reconsiders | Never | Implicitly |
| Complexity | Usually O(n log n) | Usually O(n·k) or worse |
| Requires proof | **Yes** | No |
| Fails silently | **Yes** | No |

**Interview strategy:** if you can't justify greedy in ~60 seconds, write the DP. A correct slow solution beats an elegant wrong one.

## Key Problems

| Problem | Greedy rule |
|---|---|
| Jump Game / II | Farthest reachable |
| Gas Station | Reset start on deficit |
| Task Scheduler | Schedule the most frequent first |
| Partition Labels | Extend to the last occurrence |
| Candy | Two passes, left then right |
| Minimum Number of Arrows | Sort by end |
| Merge Sticks / Huffman | Merge two smallest |
| Best Time to Buy and Sell Stock II | Take every positive delta |

## Common Mistakes

- Assuming greedy without testing a counterexample
- Sorting by the wrong key (duration instead of end time)
- Applying greedy to 0/1 knapsack — only the *fractional* version is greedy-solvable
- Missing that some problems need two greedy passes in opposite directions (Candy)

## Related Topics

- [Intervals](Intervals.md)
- [Dynamic Programming Fundamentals](../Dynamic%20Programming/Dynamic%20Programming%20Fundamentals.md)
- [Pattern Confusion Matrix](../Foundations/Pattern%20Confusion%20Matrix.md)

## Revision Summary

Greedy needs a proof. Try the exchange argument, then hunt for a counterexample. Coins `[1,3,4]` for amount 6 is the counterexample to remember. Fractional knapsack is greedy; 0/1 is DP.

## Quick Recall

- Always attempt a counterexample first
- Activity selection → earliest end time
- Jump Game → farthest reachable
- Gas Station → reset start when tank < 0
- Fractional knapsack greedy; 0/1 knapsack DP
