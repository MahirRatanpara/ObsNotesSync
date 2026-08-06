# DP on Strings

## Why It Matters

Edit distance, LCS, and palindrome problems are among the most common hard DP questions, and they all share two skeletons.

## The Two Skeletons

### Skeleton 1 — Two Sequences: `dp[i][j]` over prefixes

State: answer for `s1[0..i-1]` and `s2[0..j-1]`.

```java
for (int i = 1; i <= m; i++)
    for (int j = 1; j <= n; j++)
        if (s1.charAt(i-1) == s2.charAt(j-1))
            dp[i][j] = dp[i-1][j-1] + 1;                     // characters match
        else
            dp[i][j] = Math.max(dp[i-1][j], dp[i][j-1]);     // skip one
```

**The `i-1` indexing with `1..m` loops is deliberate:** it makes `dp[0][*]` and `dp[*][0]` natural base cases (empty prefix), avoiding a nest of boundary conditions.

### Skeleton 2 — One String, Intervals: `dp[i][j]` over substrings

State: answer for `s[i..j]`. **Must iterate by increasing length**, because `dp[i][j]` depends on shorter intervals.

```java
for (int len = 1; len <= n; len++)
    for (int i = 0; i + len - 1 < n; i++) {
        int j = i + len - 1;
        if (s.charAt(i) == s.charAt(j)) dp[i][j] = dp[i+1][j-1] + 2;
        else dp[i][j] = Math.max(dp[i+1][j], dp[i][j-1]);
    }
```

**Iterating by length is the whole trick.** A naive `for i, for j` loop reads `dp[i+1][j-1]` before it's computed.

## Edit Distance — The Canonical Problem

```java
int[][] dp = new int[m+1][n+1];
for (int i = 0; i <= m; i++) dp[i][0] = i;     // delete all
for (int j = 0; j <= n; j++) dp[0][j] = j;     // insert all

for (int i = 1; i <= m; i++)
    for (int j = 1; j <= n; j++)
        if (s1.charAt(i-1) == s2.charAt(j-1))
            dp[i][j] = dp[i-1][j-1];                       // free
        else
            dp[i][j] = 1 + Math.min(dp[i-1][j-1],          // replace
                          Math.min(dp[i-1][j],             // delete
                                   dp[i][j-1]));           // insert
```

**Know which neighbour maps to which operation** — interviewers ask directly:

| Neighbour | Operation |
|---|---|
| `dp[i-1][j-1]` | Replace |
| `dp[i-1][j]` | Delete from s1 |
| `dp[i][j-1]` | Insert into s1 |

## The Problem Family

| Problem | Relation |
|---|---|
| Longest Common Subsequence | The base skeleton |
| Edit Distance | LCS with three operations |
| Longest Palindromic Subsequence | **LCS(s, reverse(s))** |
| Delete Operation for Two Strings | `m + n − 2·LCS` |
| Minimum ASCII Delete Sum | LCS weighted by char value |
| Shortest Common Supersequence | `m + n − LCS`, then reconstruct |
| Distinct Subsequences | Counting variant |
| Interleaving String | 2D over two sources |
| Regular Expression / Wildcard Matching | LCS skeleton + pattern rules |
| Longest Palindromic Substring | Interval DP, or expand-around-centre |

**"Longest Palindromic Subsequence = LCS(s, reverse(s))" is the highest-value reduction to memorise.** It converts an unfamiliar problem into one you already know.

## Space Optimisation

Each row depends only on the previous, so O(m·n) becomes O(n):

```java
int[] prev = new int[n+1], cur = new int[n+1];
for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++)
        cur[j] = s1.charAt(i-1) == s2.charAt(j-1)
               ? prev[j-1] + 1 : Math.max(prev[j], cur[j-1]);
    int[] t = prev; prev = cur; cur = t;                   // swap, don't reallocate
}
```

**You lose the ability to reconstruct the actual string** — only the length survives. If reconstruction is required, keep the full table and walk it backwards from `dp[m][n]`.

## Palindromic Substring — Two Approaches

| | Interval DP | Expand around centre |
|---|---|---|
| Time | O(n²) | O(n²) |
| Space | **O(n²)** | **O(1)** |
| Code | Longer | Shorter |

**Expand-around-centre is strictly better for Longest Palindromic Substring** — same time, constant space. Use 2n−1 centres to handle both odd and even lengths. Mention Manacher's O(n) algorithm exists, but don't attempt it unless asked.

## Pattern Matching (Regex / Wildcard)

The tricky case is `*`:

```java
// '*' matches zero or more of the PRECEDING character (regex)
if (p.charAt(j-1) == '*') {
    dp[i][j] = dp[i][j-2]                                   // zero occurrences
            || (matches(s.charAt(i-1), p.charAt(j-2)) && dp[i-1][j]);   // one more
}
```

**Regex `*` and wildcard `*` differ:** regex `*` modifies the preceding character; wildcard `*` matches any sequence on its own. Confusing them is the most common error in these problems.

## Common Mistakes

- Forgetting to iterate interval DP by increasing length
- Off-by-one between the `1..m` loop and `charAt(i-1)`
- Missing base cases (`dp[i][0] = i`, not 0, for edit distance)
- Space-optimising when the problem needs the reconstructed string
- Overwriting `prev` before reading it in the 1D variant
- Treating regex `*` as wildcard `*`

## Related Topics

- [Dynamic Programming Fundamentals](Dynamic%20Programming%20Fundamentals.md)
- [Knapsack Patterns](Knapsack%20Patterns.md)
- [Two Pointers](../Two%20Pointers%20and%20Sliding%20Window/Two%20Pointers.md)

## Revision Summary

Two skeletons: prefix DP over two strings, and interval DP over one. Most problems reduce to LCS — notably longest palindromic subsequence as LCS with the reverse. Space-optimise to two rows unless you must reconstruct the answer.

## Quick Recall

- Two strings → `dp[i][j]` over prefixes, loop `1..m`, index `charAt(i-1)`
- One string intervals → **iterate by length**
- LPSubsequence = LCS(s, reverse(s))
- Edit distance: diagonal = replace, up = delete, left = insert
- Two rows for O(n) space; full table if reconstructing
- Longest palindromic **substring** → expand around centre, O(1) space
