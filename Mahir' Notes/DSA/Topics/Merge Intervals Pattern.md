# Merge Intervals Pattern

## General Rules by Problem Type

---

## 1. Basic Merge Overlapping Intervals

**Recognition:** Given intervals, merge all overlapping ones.

**General Rule:**

- **Sort by start time** first
- **Iterate and merge:** If current interval overlaps with last merged interval, merge them; otherwise add current interval
- **Overlap condition:** `current.start <= last.end`

**Steps:**

```
1. Sort intervals by start time
2. Initialize result with first interval
3. For each interval:
   - If overlaps with last in result: merge (update end to max)
   - Else: add to result
4. Return result
```

**Complexity:** O(n log n) time, O(n) space

---

## 2. Insert Interval

**Recognition:** Insert a new interval into sorted non-overlapping intervals and merge if needed.

**General Rule:**

- **Three phases approach:**
    1. Add all intervals that end before new interval starts
    2. Merge all overlapping intervals with new interval
    3. Add remaining intervals

**Steps:**

```
1. Add all intervals with end < newInterval.start
2. While intervals overlap with newInterval:
   - Merge by updating newInterval bounds
3. Add merged interval
4. Add remaining intervals
```

**Complexity:** O(n) time, O(n) space

---

## 3. Interval Intersection

**Recognition:** Find common parts between two sorted interval lists.

**General Rule:**

- **Two-pointer technique**
- **Intersection exists when:** `max(start1, start2) <= min(end1, end2)`
- **Move pointer** of interval that ends first

**Steps:**

```
1. Use two pointers i, j for both lists
2. Find intersection: [max(start), min(end)]
3. If valid intersection: add to result
4. Advance pointer of interval ending earlier
5. Repeat until either list exhausted
```

**Complexity:** O(m + n) time, O(min(m,n)) space

---

## 4. Meeting Rooms I (Can Attend All)

**Recognition:** Check if person can attend all meetings (no overlaps).

**General Rule:**

- **Sort by start time**
- **Check consecutive pairs:** Each meeting should end before next starts
- **Condition:** `meetings[i-1].end <= meetings[i].start`

**Steps:**

```
1. Sort meetings by start time
2. Iterate through sorted meetings
3. If any meeting starts before previous ends: return false
4. Return true
```

**Complexity:** O(n log n) time, O(1) space

---

## 5. Meeting Rooms II (Minimum Rooms Needed)

**Recognition:** Find minimum meeting rooms/resources needed for overlapping intervals.

### Method 1: Min Heap

**General Rule:**

- **Sort by start time**
- **Use min-heap to track end times**
- **Heap size = rooms needed at any point**

**Steps:**

```
1. Sort meetings by start time
2. Add first meeting's end time to min-heap
3. For each meeting:
   - If starts after earliest ending (heap top): remove from heap
   - Add current meeting's end time to heap
4. Return max heap size seen
```

**Complexity:** O(n log n) time, O(n) space

### Method 2: Event Sweep

**General Rule:**

- **Create events:** start (+1), end (-1)
- **Sort events, count active intervals**

**Steps:**

```
1. Create array of (time, +1 for start / -1 for end)
2. Sort by time (if tie, process end before start)
3. Track running count and max count
4. Return max count
```

**Complexity:** O(n log n) time, O(n) space

---

## 6. Non-overlapping Intervals (Minimum Removals)

**Recognition:** Remove minimum intervals to make rest non-overlapping.

**General Rule:**

- **Greedy approach: Sort by end time**
- **Keep intervals ending earliest** (like activity selection)
- **Remove if current starts before previous ends**

**Steps:**

```
1. Sort intervals by end time
2. Track last kept interval's end
3. For each interval:
   - If starts >= last end: keep it, update last end
   - Else: remove it (increment count)
4. Return removal count
```

**Complexity:** O(n log n) time, O(1) space

---

## 7. Employee Free Time

**Recognition:** Find common free time across all employees' schedules.

**General Rule:**

- **Flatten all intervals into one list**
- **Merge overlapping busy times**
- **Gaps between merged intervals = free time**

**Steps:**

```
1. Combine all intervals from all employees
2. Sort by start time
3. Merge overlapping intervals
4. Find gaps between merged intervals
5. Return gaps as free time
```

**Complexity:** O(n log n) time, O(n) space

---

## 8. Maximum Overlapping Intervals / CPU Load

**Recognition:** Find maximum number of overlapping intervals at any point, or max simultaneous load.

**General Rule:**

- **Event sweep with counter**
- **Start event: +1, End event: -1** (or +weight, -weight)
- **Track maximum running count**

**Steps:**

```
1. Create events: (start, +load) and (end, -load)
2. Sort by time (process starts before ends for ties)
3. Iterate, maintain running sum
4. Track maximum sum seen
5. Return maximum
```

**Complexity:** O(n log n) time, O(n) space

---

## 9. Missing Ranges / Covered Ranges

**Recognition:** Find gaps in interval coverage or check if range is fully covered.

**General Rule:**

- **Sort by start time**
- **Track last covered point**
- **Gaps = [last_covered + 1, current_start - 1]**

**Steps:**

```
1. Sort intervals by start
2. Initialize last_covered = start_of_range - 1
3. For each interval:
   - If gap exists: record it
   - Update last_covered = max(last_covered, interval.end)
4. Check final gap to end_of_range
```

**Complexity:** O(n log n) time, O(k) space (k = gaps)

---

## 10. Partition Labels / Group Intervals

**Recognition:** Partition into maximum groups where elements don't appear in multiple groups.

**General Rule:**

- **Find last occurrence/end of each element**
- **Extend partition end as you go**
- **Cut partition when current position reaches partition end**

**Steps:**

```
1. Record last occurrence of each element
2. Track partition_end = last occurrence of first element
3. Iterate:
   - Update partition_end = max(partition_end, last[current])
   - If index == partition_end: cut partition
4. Return partition sizes
```

**Complexity:** O(n) time, O(1) space

---

## Key Recognition Patterns

|Problem Asks For|Approach|
|---|---|
|Merge overlapping|Sort + iterate with merge|
|Insert new interval|Three-phase: before/merge/after|
|Intersection of lists|Two pointers|
|Can attend all?|Sort + check consecutive|
|Min rooms/resources|Heap or event sweep|
|Min removals|Sort by end + greedy|
|Common free time|Flatten + merge + gaps|
|Max overlaps|Event sweep with counter|
|Missing ranges|Sort + track last covered|

---

## Universal Tips

1. **Always sort first** (usually by start time, sometimes by end)
2. **Overlap condition:** `start1 <= end2 AND start2 <= end1` or simplified: `max(start1, start2) <= min(end1, end2)`
3. **Merge formula:** `[min(start1, start2), max(end1, end2)]`
4. **Event sweep** is powerful for counting overlaps
5. **Greedy works** for optimization problems (sort by end time)
6. **Edge cases:** Empty input, single interval, no overlaps, complete overlaps

---

## Common Pitfalls to Avoid

- **Forgetting to sort** the intervals first
- **Wrong overlap condition** (using < instead of <=)
- **Not handling edge cases** (empty arrays, single interval)
- **In event sweep:** Processing start events before end events at the same time point
- **In greedy problems:** Sorting by start time instead of end time
- **Memory issues:** Creating too many intermediate arrays instead of in-place operations

---

## Quick Reference: When to Use What

### Sort by Start Time

- Basic merge
- Insert interval
- Meeting Rooms I
- Meeting Rooms II (heap method)
- Missing ranges

### Sort by End Time

- Non-overlapping intervals (greedy)
- Activity selection problems
- Minimum removal problems

### Two Pointers

- Interval intersection
- Merging two sorted interval lists

### Heap/Priority Queue

- Meeting Rooms II
- Resource allocation problems
- When you need to track earliest ending

### Event Sweep

- Maximum overlaps
- CPU load problems
- When counting simultaneous events matters

---

**Happy Coding! 🚀**