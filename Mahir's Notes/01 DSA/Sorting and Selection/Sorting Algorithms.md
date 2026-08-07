# Sorting Algorithms

## Why It Matters

Rarely asked to implement, frequently asked to compare. Knowing stability and space characteristics answers "which sort does Java use and why?"

## Comparison Table

| Algorithm | Best | Average | Worst | Space | Stable | In-place |
|---|---|---|---|---|---|---|
| Merge sort | O(n log n) | O(n log n) | O(n log n) | O(n) | **Yes** | No |
| Quicksort | O(n log n) | O(n log n) | O(n²) | O(log n) | No | Yes |
| Heapsort | O(n log n) | O(n log n) | O(n log n) | O(1) | No | Yes |
| Insertion sort | O(n) | O(n²) | O(n²) | O(1) | Yes | Yes |
| Counting sort | O(n + k) | O(n + k) | O(n + k) | O(k) | Yes | No |
| Radix sort | O(d(n + k)) | O(d(n + k)) | O(d(n + k)) | O(n + k) | Yes | No |
| Bucket sort | O(n + k) | O(n + k) | O(n²) | O(n) | Yes | No |

## What Java Actually Uses

- **`Arrays.sort(int[])`** — dual-pivot quicksort. Primitives have no identity, so stability is meaningless; in-place beats stable.
- **`Arrays.sort(Object[])` / `Collections.sort`** — TimSort (merge + insertion hybrid). Objects need **stability**, since sorting by one key then another must preserve the first ordering.

**This is a very common interview question.** The answer is: primitives don't need stability, objects do.

## TimSort In One Paragraph

Finds naturally ordered "runs" in the data, extends short runs with insertion sort, then merges runs using a stack with size invariants. O(n) on already-sorted input, O(n log n) worst case, stable. It exploits the fact that real data is often partially sorted.

## Stability — Why It Matters

Stable sorts preserve the relative order of equal keys. This is what makes multi-key sorting work:

```java
people.sort(Comparator.comparing(Person::getName));   // secondary first
people.sort(Comparator.comparing(Person::getAge));    // primary second
// within each age, still sorted by name — only because the sort is stable
```

## The O(n log n) Lower Bound

Any **comparison-based** sort needs Ω(n log n) comparisons: there are n! possible orderings, and a binary decision tree of depth d distinguishes at most 2^d outcomes, so d ≥ log₂(n!) = Θ(n log n).

**Counting/radix/bucket sorts beat this because they don't compare** — they use the values as indices. That's only possible when the key range is bounded and known.

## When Non-Comparison Sorts Apply

| Sort | Requires |
|---|---|
| Counting | Small integer range k, ideally k = O(n) |
| Radix | Fixed-width keys (integers, fixed strings) |
| Bucket | Uniformly distributed values |

**Top K Frequent Elements** is the classic place to use bucket sort for a genuine O(n) solution — frequencies are bounded by n, so index buckets by frequency.

## Custom Comparators — The Overflow Trap

```java
// WRONG — overflows for large values
(a, b) -> a - b
// CORRECT
(a, b) -> Integer.compare(a, b)
Comparator.comparingInt(Foo::getValue)
```

A comparator must be **transitive and consistent**, or `Arrays.sort` throws `IllegalArgumentException: Comparison method violates its general contract!`

## Key Problems

| Problem | Technique |
|---|---|
| Sort Colors | Dutch flag, one pass |
| Top K Frequent Elements | Bucket sort, O(n) |
| Merge Intervals | Sort by start |
| Largest Number | Custom comparator on concatenation |
| H-Index | Counting sort |
| Sort an Array | Merge or quicksort implementation |
| Maximum Gap | Bucket sort / pigeonhole |

## Common Mistakes

- `a - b` comparators overflowing
- Assuming `Arrays.sort` is stable for primitives (it isn't, and it doesn't matter)
- Using a comparison sort when the key range is tiny and counting sort is O(n)
- Non-transitive comparators throwing at runtime

## Related Topics

- [Quickselect](Quickselect.md)
- [Complexity Analysis](Complexity%20Analysis.md)
- [Java Collections](Collections%20Overview.md)

## Revision Summary

Merge is stable and O(n log n) guaranteed; quicksort is in-place but O(n²) worst; heapsort is O(1) space. Java uses dual-pivot quicksort for primitives and TimSort for objects, because objects need stability. Counting/radix beat n log n by not comparing.

## Quick Recall

- Primitives → dual-pivot quicksort; objects → TimSort
- Stability enables multi-key sorting
- Comparison lower bound Ω(n log n) from log₂(n!)
- Bounded key range → counting/bucket → O(n)
- Never write `a - b` comparators
