# Backtracking

## Why It Matters

The only way to enumerate combinations, permutations, subsets, and constraint solutions. Recognisable instantly from "all possible", "generate every", or small n.

## Core Idea

Depth-first search over a decision tree, with state mutated on the way down and **undone on the way back up**. Prune branches that can't lead to a valid solution.

```
choose → explore → un-choose
```

The un-choose step is what makes it backtracking rather than plain DFS.

## Universal Template

```java
void backtrack(List<Integer> path, int start) {
    if (isComplete(path)) { res.add(new ArrayList<>(path)); return; }   // COPY the list
    for (int i = start; i < n; i++) {
        if (!isValid(i)) continue;          // prune
        path.add(nums[i]);                  // choose
        backtrack(path, i + 1);             // explore
        path.remove(path.size() - 1);       // un-choose
    }
}
```

**`new ArrayList<>(path)`** — adding `path` directly stores a reference that you then mutate. This is the single most common backtracking bug.

## The Three Shapes

| Shape | Recursive call | Meaning |
|---|---|---|
| Subsets / Combinations | `backtrack(i + 1)` | Each element used at most once, order irrelevant |
| Combinations with reuse | `backtrack(i)` | Element may repeat |
| Permutations | loop from 0 with a `used[]` array | Order matters |

## Handling Duplicates

Sort first, then skip duplicates **at the same tree depth**:

```java
Arrays.sort(nums);
for (int i = start; i < n; i++) {
    if (i > start && nums[i] == nums[i - 1]) continue;   // note: i > start, not i > 0
    ...
}
```

For permutations with duplicates:
```java
if (used[i] || (i > 0 && nums[i] == nums[i-1] && !used[i-1])) continue;
```

Both conditions are worth memorising verbatim — they're easy to get subtly wrong.

## Pruning Is The Real Skill

Without pruning, backtracking is brute force. Examples:

- **Combination Sum:** if `nums[i] > remaining`, break (after sorting) — all later values are larger too
- **N-Queens:** track attacked columns and diagonals in sets, O(1) validity check
- **Sudoku:** pick the cell with the fewest candidates next
- **Word Search:** return early once found; mark the cell visited in place, restore after

Interviewers explicitly look for pruning discussion.

## N-Queens Diagonal Trick

```java
// for cell (r, c):
//   "/" diagonal identified by  r + c
//   "\" diagonal identified by  r - c + n
```
Three boolean arrays give O(1) placement checks.

## Complexity

| Problem | Complexity |
|---|---|
| Subsets | O(n · 2ⁿ) |
| Permutations | O(n · n!) |
| Combination Sum | O(n^(target/min)) |
| N-Queens | O(n!) with pruning |
| Word Search | O(m · n · 4^L) |

The `n` factor is the cost of copying each result — mention it.

## Key Problems

| Problem | Shape |
|---|---|
| Subsets / Subsets II | `i + 1`, dedupe |
| Permutations / II | `used[]`, dedupe |
| Combination Sum | `i` (reuse) |
| Combination Sum II | `i + 1`, dedupe |
| N-Queens | Constraint sets |
| Word Search | Grid DFS + in-place marking |
| Palindrome Partitioning | Prefix check + recurse |
| Letter Combinations of a Phone Number | Digit-indexed branching |
| Restore IP Addresses | Segment validation |

## Common Mistakes

- Adding `path` instead of a copy
- Forgetting to un-choose, leaking state into sibling branches
- `i > 0` instead of `i > start` in the dedupe check
- Not sorting before deduping
- No pruning, causing a timeout on entirely correct logic

## Related Topics

- [Pattern Confusion Matrix](../Foundations/Pattern%20Confusion%20Matrix.md)
- [BFS and DFS](../Graphs/BFS%20and%20DFS.md)
- [Bit Manipulation](../Bit%20Manipulation/Bit%20Manipulation.md)

## Revision Summary

Choose, explore, un-choose. Copy results. Sort and skip duplicates at the same depth. Pruning is what separates a passing solution from a timeout.

## Quick Recall

- Always `new ArrayList<>(path)`
- Subsets → `i+1`; reuse → `i`; permutations → `used[]`
- Dedupe: sort, then `i > start && nums[i] == nums[i-1]`
- N-Queens diagonals: `r+c` and `r-c+n`
- n ≤ 20 in constraints → backtracking is intended
