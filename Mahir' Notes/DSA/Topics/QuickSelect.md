# QuickSelect Algorithm

#algorithms #complexity-analysis #sorting #selection

---

## Table of Contents

- [[#Overview]]
- [[#Mathematical Complexity Analysis]]
- [[#Intuitive Understanding]]
- [[#QuickSelect Implementation]]
- [[#Related Sorting Algorithms]]
- [[#Comparison and Trade-offs]]

---

## Overview

QuickSelect finds the k-th smallest element in an unordered array using a partition-based approach similar to QuickSort, but only recurses into one partition.

**Key Properties:**

- Average Time: O(n)
- Worst Time: O(n²)
- Space: O(1) - in-place algorithm
- Not stable

> [!info] Use Case QuickSelect is optimal when you need the k-th element (like median, percentile) without sorting the entire array.

---

## Mathematical Complexity Analysis

### Average Case: O(n)

**Recurrence Relation:**

```
T(n) = T(n/2) + n
```

After partitioning around a pivot, we expect to recurse into roughly half the array.

**Solving the recurrence:**

```
T(n) = n + n/2 + n/4 + n/8 + ...
     = n(1 + 1/2 + 1/4 + 1/8 + ...)
     = n × Σ(1/2^i) for i=0 to ∞
     = n × 2
     = O(n)
```

**Formal Proof using Master Theorem:**

- Recurrence: T(n) = T(n/2) + Θ(n)
- Form: T(n) = aT(n/b) + f(n) where a=1, b=2, f(n)=n
- Compare: n^(log_b(a)) = n^0 = 1 vs f(n) = n
- Case 3 applies: f(n) = Ω(n^(log_b(a) + ε)) where ε > 0
- Result: **T(n) = Θ(n)**

### Worst Case: O(n²)

**Recurrence Relation:**

```
T(n) = T(n-1) + n
```

Occurs when pivot is always the smallest/largest element.

**Solving:**

```
T(n) = n + (n-1) + (n-2) + ... + 1
     = n(n+1)/2
     = O(n²)
```

### Best Case: O(n)

Pivot always divides array into equal or near-equal parts, similar to average case.

---

## Intuitive Understanding

### Why Average Case is Linear

Think of it like a **shrinking search**:

1. **First iteration**: Process all n elements → **n work**
2. **Second iteration**: Process ~n/2 elements → **n/2 work**
3. **Third iteration**: Process ~n/4 elements → **n/4 work**
4. Continue...

**Key insight**: Each level does _half_ the work of the previous level. This creates a geometric series that converges:

```
n + n/2 + n/4 + n/8 + ... ≈ 2n = O(n)
```

**Visual representation:**

```
Level 0: [████████████████] n work
Level 1: [████████]         n/2 work
Level 2: [████]             n/4 work
Level 3: [██]               n/8 work
```

> [!tip] The Magic Number: 2 The average case sums to **exactly 2n** comparisons. QuickSelect only does about **twice** as much work as just scanning the array once!

### Why Worst Case is Quadratic

Imagine always picking the **worst pivot** (minimum or maximum):

```
Iteration 1: Process 10 elements → 10 work
Iteration 2: Process 9 elements  → 9 work
Iteration 3: Process 8 elements  → 8 work
...
```

This creates: **10 + 9 + 8 + ... + 1 = 55 = O(n²)**

The array barely shrinks, so we do almost the same work repeatedly.

### Comparison with QuickSort

|Algorithm|Average|Worst|Reason|
|---|---|---|---|
|QuickSort|O(n log n)|O(n²)|Recurses into BOTH partitions|
|QuickSelect|**O(n)**|O(n²)|Recurses into ONE partition|

**Why is QuickSelect faster on average?**

- **QuickSort**: T(n) = 2T(n/2) + n → O(n log n)
- **QuickSelect**: T(n) = T(n/2) + n → O(n)

---

## QuickSelect Implementation

### Python Implementation

```python
import random

def quickselect(arr, k):
    """
    Find the k-th smallest element (0-indexed) in an unsorted array.
    
    Args:
        arr: List of comparable elements
        k: Index of element to find (0 for smallest)
    
    Returns:
        The k-th smallest element
    """
    if len(arr) == 1:
        return arr[0]
    
    return quickselect_helper(arr, 0, len(arr) - 1, k)


def quickselect_helper(arr, left, right, k):
    """Helper function for quickselect with bounds."""
    if left == right:
        return arr[left]
    
    # Randomized pivot selection for better average case
    pivot_index = random.randint(left, right)
    pivot_index = partition(arr, left, right, pivot_index)
    
    if k == pivot_index:
        return arr[k]
    elif k < pivot_index:
        return quickselect_helper(arr, left, pivot_index - 1, k)
    else:
        return quickselect_helper(arr, pivot_index + 1, right, k)


def partition(arr, left, right, pivot_index):
    """
    Lomuto partition scheme.
    Moves pivot to its final sorted position.
    """
    pivot_value = arr[pivot_index]
    
    # Move pivot to end
    arr[pivot_index], arr[right] = arr[right], arr[pivot_index]
    
    # Partition array
    store_index = left
    for i in range(left, right):
        if arr[i] < pivot_value:
            arr[store_index], arr[i] = arr[i], arr[store_index]
            store_index += 1
    
    # Move pivot to final position
    arr[right], arr[store_index] = arr[store_index], arr[right]
    
    return store_index


# Example usage
def find_median(arr):
    """Find the median using quickselect."""
    n = len(arr)
    if n % 2 == 1:
        return quickselect(arr[:], n // 2)
    else:
        return (quickselect(arr[:], n // 2 - 1) + 
                quickselect(arr[:], n // 2)) / 2


def find_kth_largest(arr, k):
    """Find the k-th largest element (1-indexed)."""
    return quickselect(arr[:], len(arr) - k)


# Test cases
if __name__ == "__main__":
    arr = [3, 2, 1, 5, 6, 4]
    
    print(f"Array: {arr}")
    print(f"2nd smallest (k=1): {quickselect(arr[:], 1)}")  # 2
    print(f"Median: {find_median(arr)}")  # 3.5
    print(f"2nd largest: {find_kth_largest(arr[:], 2)}")  # 5
```

### Iterative Version

```python
def quickselect_iterative(arr, k):
    """Iterative version of quickselect to avoid stack overflow."""
    left, right = 0, len(arr) - 1
    
    while left <= right:
        pivot_index = random.randint(left, right)
        pivot_index = partition(arr, left, right, pivot_index)
        
        if k == pivot_index:
            return arr[k]
        elif k < pivot_index:
            right = pivot_index - 1
        else:
            left = pivot_index + 1
    
    return arr[k]
```

### Median of Medians (Deterministic O(n))

```python
def median_of_medians(arr, k):
    """
    Deterministic O(n) worst-case quickselect.
    Uses median-of-medians for pivot selection.
    """
    if len(arr) <= 5:
        return sorted(arr)[k]
    
    # Divide into groups of 5 and find median of each
    medians = []
    for i in range(0, len(arr), 5):
        group = arr[i:i+5]
        medians.append(sorted(group)[len(group) // 2])
    
    # Find median of medians
    pivot = median_of_medians(medians, len(medians) // 2)
    
    # Partition around pivot
    lows = [x for x in arr if x < pivot]
    highs = [x for x in arr if x > pivot]
    pivots = [x for x in arr if x == pivot]
    
    if k < len(lows):
        return median_of_medians(lows, k)
    elif k < len(lows) + len(pivots):
        return pivot
    else:
        return median_of_medians(highs, k - len(lows) - len(pivots))
```

---

## Related Sorting Algorithms

### QuickSort

```python
def quicksort(arr):
    """
    QuickSort implementation using randomized pivot.
    Average: O(n log n), Worst: O(n²), Space: O(log n)
    """
    if len(arr) <= 1:
        return arr
    
    pivot = random.choice(arr)
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    
    return quicksort(left) + middle + quicksort(right)


def quicksort_inplace(arr, low=0, high=None):
    """In-place QuickSort implementation."""
    if high is None:
        high = len(arr) - 1
    
    if low < high:
        pivot_index = random.randint(low, high)
        pivot_index = partition(arr, low, high, pivot_index)
        quicksort_inplace(arr, low, pivot_index - 1)
        quicksort_inplace(arr, pivot_index + 1, high)
    
    return arr
```

### Merge Sort

```python
def mergesort(arr):
    """
    Merge Sort implementation.
    Time: O(n log n) always, Space: O(n)
    Stable sorting algorithm.
    """
    if len(arr) <= 1:
        return arr
    
    mid = len(arr) // 2
    left = mergesort(arr[:mid])
    right = mergesort(arr[mid:])
    
    return merge(left, right)


def merge(left, right):
    """Merge two sorted arrays."""
    result = []
    i = j = 0
    
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    
    result.extend(left[i:])
    result.extend(right[j:])
    return result
```

### Heap Sort

```python
def heapsort(arr):
    """
    Heap Sort implementation.
    Time: O(n log n) always, Space: O(1)
    Not stable.
    """
    n = len(arr)
    
    # Build max heap
    for i in range(n // 2 - 1, -1, -1):
        heapify(arr, n, i)
    
    # Extract elements from heap
    for i in range(n - 1, 0, -1):
        arr[0], arr[i] = arr[i], arr[0]
        heapify(arr, i, 0)
    
    return arr


def heapify(arr, n, i):
    """Maintain max heap property."""
    largest = i
    left = 2 * i + 1
    right = 2 * i + 2
    
    if left < n and arr[left] > arr[largest]:
        largest = left
    
    if right < n and arr[right] > arr[largest]:
        largest = right
    
    if largest != i:
        arr[i], arr[largest] = arr[largest], arr[i]
        heapify(arr, n, largest)
```

### Counting Sort

```python
def counting_sort(arr):
    """
    Counting Sort for integers.
    Time: O(n + k) where k is range, Space: O(k)
    Stable sorting algorithm.
    """
    if not arr:
        return arr
    
    min_val = min(arr)
    max_val = max(arr)
    range_size = max_val - min_val + 1
    
    count = [0] * range_size
    output = [0] * len(arr)
    
    # Count occurrences
    for num in arr:
        count[num - min_val] += 1
    
    # Cumulative count
    for i in range(1, len(count)):
        count[i] += count[i - 1]
    
    # Build output array
    for i in range(len(arr) - 1, -1, -1):
        num = arr[i]
        output[count[num - min_val] - 1] = num
        count[num - min_val] -= 1
    
    return output
```

---

## Comparison and Trade-offs

### Time Complexity Comparison

|Algorithm|Best|Average|Worst|Space|Stable|
|---|---|---|---|---|---|
|**QuickSelect**|O(n)|O(n)|O(n²)|O(1)|No|
|QuickSort|O(n log n)|O(n log n)|O(n²)|O(log n)|No|
|Merge Sort|O(n log n)|O(n log n)|O(n log n)|O(n)|Yes|
|Heap Sort|O(n log n)|O(n log n)|O(n log n)|O(1)|No|
|Counting Sort|O(n + k)|O(n + k)|O(n + k)|O(k)|Yes|

> [!warning] When to Use QuickSelect
> 
> - Need only k-th element, not full sorted array
> - Average case performance is critical
> - Memory is constrained (in-place algorithm)
> - Randomization is acceptable

### Practical Implications

**QuickSelect Advantages:**

1. **Faster than sorting**: O(n) vs O(n log n) when you only need k-th element
2. **In-place**: Uses O(1) extra space
3. **Simple implementation**: Easy to understand and code
4. **Randomization helps**: Worst case is extremely unlikely

**QuickSelect Disadvantages:**

1. **Not stable**: Equal elements may change relative order
2. **Worst case exists**: O(n²) with bad pivot selection
3. **Multiple queries costly**: If you need multiple k-th elements, consider sorting

**When to Use Each Algorithm:**

- **QuickSelect**: Finding median, percentiles, top-k selection (single query)
- **QuickSort**: General-purpose sorting, good cache performance
- **Merge Sort**: Need stability, guaranteed O(n log n), external sorting
- **Heap Sort**: Guaranteed O(n log n) in-place, priority queue applications
- **Counting Sort**: Small integer range, need O(n) sorting

---

## Additional Resources

- [[Partition Algorithm]]
- [[Randomized Algorithms]]
- [[Order Statistics]]
- [[Selection Problem]]

---

## Practice Problems

1. Find median of stream of integers
2. Find k-th largest element in array
3. Find k closest elements to target
4. Top K frequent elements
5. Wiggle sort (reorder array in alternating pattern)

---

_Created: 2025-10-26_ _Tags: #algorithms #quickselect #sorting #complexity-analysis #selection-problem_