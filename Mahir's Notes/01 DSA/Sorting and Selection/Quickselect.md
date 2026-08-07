# Quickselect

## Why It Matters

Finds the kth smallest/largest in **O(n) average** — beating both sorting (O(n log n)) and heaps (O(n log k)) for one-shot queries on an in-memory array.

## Core Idea

Quicksort that only recurses into the side containing the target. Each partition discards on average half the remaining elements, giving `n + n/2 + n/4 + ... = 2n`.

```java
int quickselect(int[] a, int k) {          // k is 0-indexed
    int lo = 0, hi = a.length - 1;
    Random rnd = new Random();
    while (lo < hi) {
        int p = lo + rnd.nextInt(hi - lo + 1);   // RANDOM pivot
        swap(a, p, hi);
        int idx = partition(a, lo, hi);
        if (idx == k) return a[k];
        if (idx < k) lo = idx + 1;
        else hi = idx - 1;
    }
    return a[lo];
}

int partition(int[] a, int lo, int hi) {   // Lomuto, pivot at hi
    int pivot = a[hi], i = lo;
    for (int j = lo; j < hi; j++)
        if (a[j] < pivot) swap(a, i++, j);
    swap(a, i, hi);
    return i;
}
```

**Iterative, not recursive** — avoids stack depth issues and is just as clear.

## Why Random Pivots Are Mandatory

With a fixed pivot (first/last element), an adversarial or already-sorted input makes every partition split 1-vs-(n−1), giving O(n²). LeetCode tests include exactly these cases.

Random pivot makes O(n²) probabilistically negligible. **Say this in the interview** — it's a known follow-up.

## Median of Medians (Deterministic O(n))

Guarantees O(n) worst case by choosing a provably good pivot: split into groups of 5, take each median, recursively find the median of those. The chosen pivot always discards ≥30% of elements.

High constant factor — rarely used in practice, but knowing it exists is a senior-level signal.

## Three-Way Partition (Many Duplicates)

Lomuto degrades to O(n²) when most elements are equal. Dutch-flag partitioning into `< pivot`, `== pivot`, `> pivot` fixes it:

```java
int lt = lo, i = lo, gt = hi;
while (i <= gt) {
    if (a[i] < pivot) swap(a, lt++, i++);
    else if (a[i] > pivot) swap(a, i, gt--);
    else i++;
}
```

Mention this when the input may contain many repeats.

## Quickselect vs Heap vs Sort

| | Quickselect | Heap (size k) | Full sort |
|---|---|---|---|
| Time | O(n) avg, O(n²) worst | O(n log k) | O(n log n) |
| Space | O(1) | O(k) | O(1)–O(n) |
| Streaming input | No | **Yes** | No |
| Modifies input | **Yes** | No | Yes |
| Returns all top-k in order | No | Yes | Yes |

**Decision rule:** streaming or k small and you need them sorted → heap. One-shot on a full array, order irrelevant → quickselect.

## Key Problems

| Problem | Note |
|---|---|
| Kth Largest Element in an Array | Canonical; k → `n - k` for 0-indexed |
| Top K Frequent Elements | Quickselect on frequency, or O(n) bucket sort |
| K Closest Points to Origin | Partition by squared distance |
| Wiggle Sort II | Quickselect for the median, then index mapping |
| Find Median from Data Stream | **Not** quickselect — streaming, use two heaps |

## Common Mistakes

- Fixed pivot → O(n²) on sorted input
- Index confusion: kth *largest* is index `n - k` when sorted ascending
- Using quickselect on streaming data (it needs the whole array)
- Forgetting that it reorders the caller's array

## Related Topics

- [Heaps and Priority Queues](Heaps%20and%20Priority%20Queues.md)
- [Sorting Algorithms](Sorting%20Algorithms.md)
- [Complexity Analysis](Complexity%20Analysis.md)

## Revision Summary

Partition and recurse into one side only. Random pivot is mandatory. Three-way partition for duplicates. Heap instead when data streams.

## Quick Recall

- O(n) average, O(n²) worst without randomisation
- kth largest → index `n - k`
- Duplicates → Dutch-flag three-way partition
- Streaming → heap, not quickselect
