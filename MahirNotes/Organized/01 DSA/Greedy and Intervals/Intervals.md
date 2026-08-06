# Intervals

## Why It Matters

Meetings, bookings, calendars, and resource allocation all reduce to interval problems. The pattern is small and completely learnable.

## Core Idea

**Sort first.** Which key you sort by determines which problem you can solve:

| Sort by | Solves |
|---|---|
| **Start** | Merging, insertion, room counting |
| **End** | Maximum non-overlapping set (activity selection) |

Getting this backwards is the main failure.

## Merge Overlapping Intervals

```java
Arrays.sort(intervals, (a, b) -> Integer.compare(a[0], b[0]));
List<int[]> res = new ArrayList<>();
for (int[] cur : intervals) {
    if (!res.isEmpty() && cur[0] <= res.get(res.size() - 1)[1]) {
        res.get(res.size() - 1)[1] = Math.max(res.get(res.size() - 1)[1], cur[1]);
    } else {
        res.add(cur);
    }
}
```

Note `Math.max` on the end — a fully-contained interval must not shrink the merged range.

## Minimum Meeting Rooms — Two Approaches

**Min-heap of end times:**
```java
Arrays.sort(intervals, (a, b) -> a[0] - b[0]);
PriorityQueue<Integer> ends = new PriorityQueue<>();
for (int[] it : intervals) {
    if (!ends.isEmpty() && ends.peek() <= it[0]) ends.poll();   // a room freed up
    ends.offer(it[1]);
}
return ends.size();
```

**Sweep line (often cleaner, and generalises):**
```java
int[] starts = ..., ends = ...;
Arrays.sort(starts); Arrays.sort(ends);
int rooms = 0, best = 0, j = 0;
for (int i = 0; i < n; i++) {
    while (j < n && ends[j] <= starts[i]) { rooms--; j++; }
    rooms++;
    best = Math.max(best, rooms);
}
```

The sweep-line form extends directly to "maximum concurrent X" of any kind.

## Maximum Non-Overlapping (Activity Selection)

**Sort by END time** and greedily take whatever fits:

```java
Arrays.sort(intervals, (a, b) -> Integer.compare(a[1], b[1]));
int count = 0, lastEnd = Integer.MIN_VALUE;
for (int[] it : intervals)
    if (it[0] >= lastEnd) { count++; lastEnd = it[1]; }
return count;      // removals needed = n - count
```

**Why end time?** Finishing earliest leaves the most room for everything after. Sorting by start or by duration both produce counterexamples — be ready to give one.

## Insert Interval

Three phases, no sorting needed (input is already sorted):
1. Add all intervals ending before the new one starts
2. Merge everything that overlaps into the new interval
3. Add the remainder

## Key Problems

| Problem | Sort by | Technique |
|---|---|---|
| Merge Intervals | Start | Extend last |
| Insert Interval | — | Three-phase |
| Non-overlapping Intervals | **End** | Greedy count |
| Meeting Rooms | Start | Adjacent overlap check |
| Meeting Rooms II | Start | Heap or sweep |
| Interval List Intersections | — | Two pointers |
| Employee Free Time | Start | Merge all, take gaps |
| Minimum Number of Arrows | **End** | Greedy, same as non-overlapping |
| Car Pooling | — | Difference array over positions |

## Boundary Convention

Decide whether `[1,2]` and `[2,3]` overlap. For meetings they usually do **not** (one ends as the next begins) → use `<` rather than `<=`. **Ask the interviewer.** Getting this wrong silently produces off-by-one answers.

## Common Mistakes

- Sorting by start for activity selection (needs end)
- Forgetting `Math.max` when extending a merged interval
- Ambiguous touching-endpoint handling
- Using a heap where a difference array would be simpler (fixed small coordinate range)

## Related Topics

- [Greedy Algorithms](Greedy%20Algorithms.md)
- [Heaps and Priority Queues](../Heaps/Heaps%20and%20Priority%20Queues.md)
- [Prefix Sum](../Arrays%20and%20Strings/Prefix%20Sum.md)

## Revision Summary

Sort by start to merge, sort by end to select the most non-overlapping. Sweep line generalises to any "maximum concurrent" question.

## Quick Recall

- Merge → sort by start, `Math.max` the end
- Count max non-overlapping → sort by **end**
- Rooms needed → min-heap of ends, or sweep line
- Clarify whether touching endpoints overlap
