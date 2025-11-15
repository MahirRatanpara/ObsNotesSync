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

### Java Implementation

```java
import java.util.*;

public class QuickSelect {
    private static Random random = new Random();
    
    /**
     * Find the k-th smallest element (0-indexed) in an unsorted array.
     * 
     * @param arr Array of integers
     * @param k Index of element to find (0 for smallest)
     * @return The k-th smallest element
     */
    public static int quickSelect(int[] arr, int k) {
        if (arr.length == 1) {
            return arr[0];
        }
        return quickSelectHelper(arr, 0, arr.length - 1, k);
    }
    
    /**
     * Helper function for quickselect with bounds.
     */
    private static int quickSelectHelper(int[] arr, int left, int right, int k) {
        if (left == right) {
            return arr[left];
        }
        
        // Randomized pivot selection for better average case
        int pivotIndex = left + random.nextInt(right - left + 1);
        pivotIndex = partition(arr, left, right, pivotIndex);
        
        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return quickSelectHelper(arr, left, pivotIndex - 1, k);
        } else {
            return quickSelectHelper(arr, pivotIndex + 1, right, k);
        }
    }
    
    /**
     * Lomuto partition scheme.
     * Moves pivot to its final sorted position.
     */
    private static int partition(int[] arr, int left, int right, int pivotIndex) {
        int pivotValue = arr[pivotIndex];
        
        // Move pivot to end
        swap(arr, pivotIndex, right);
        
        // Partition array
        int storeIndex = left;
        for (int i = left; i < right; i++) {
            if (arr[i] < pivotValue) {
                swap(arr, storeIndex, i);
                storeIndex++;
            }
        }
        
        // Move pivot to final position
        swap(arr, right, storeIndex);
        
        return storeIndex;
    }
    
    /**
     * Swap two elements in an array.
     */
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    
    /**
     * Find the median using quickselect.
     */
    public static double findMedian(int[] arr) {
        int n = arr.length;
        int[] copy = arr.clone();
        
        if (n % 2 == 1) {
            return quickSelect(copy, n / 2);
        } else {
            int[] copy2 = arr.clone();
            return (quickSelect(copy, n / 2 - 1) + quickSelect(copy2, n / 2)) / 2.0;
        }
    }
    
    /**
     * Find the k-th largest element (1-indexed).
     */
    public static int findKthLargest(int[] arr, int k) {
        int[] copy = arr.clone();
        return quickSelect(copy, arr.length - k);
    }
    
    // Test cases
    public static void main(String[] args) {
        int[] arr = {3, 2, 1, 5, 6, 4};
        
        System.out.println("Array: " + Arrays.toString(arr));
        System.out.println("2nd smallest (k=1): " + quickSelect(arr.clone(), 1)); // 2
        System.out.println("Median: " + findMedian(arr)); // 3.5
        System.out.println("2nd largest: " + findKthLargest(arr, 2)); // 5
    }
}
```

### Iterative Version

```java
public class QuickSelectIterative {
    private static Random random = new Random();
    
    /**
     * Iterative version of quickselect to avoid stack overflow.
     */
    public static int quickSelectIterative(int[] arr, int k) {
        int left = 0;
        int right = arr.length - 1;
        
        while (left <= right) {
            int pivotIndex = left + random.nextInt(right - left + 1);
            pivotIndex = partition(arr, left, right, pivotIndex);
            
            if (k == pivotIndex) {
                return arr[k];
            } else if (k < pivotIndex) {
                right = pivotIndex - 1;
            } else {
                left = pivotIndex + 1;
            }
        }
        
        return arr[k];
    }
    
    private static int partition(int[] arr, int left, int right, int pivotIndex) {
        int pivotValue = arr[pivotIndex];
        swap(arr, pivotIndex, right);
        
        int storeIndex = left;
        for (int i = left; i < right; i++) {
            if (arr[i] < pivotValue) {
                swap(arr, storeIndex, i);
                storeIndex++;
            }
        }
        
        swap(arr, right, storeIndex);
        return storeIndex;
    }
    
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

### Median of Medians (Deterministic O(n))

```java
import java.util.*;

public class MedianOfMedians {
    
    /**
     * Deterministic O(n) worst-case quickselect.
     * Uses median-of-medians for pivot selection.
     */
    public static int medianOfMedians(int[] arr, int k) {
        return medianOfMediansHelper(arr, 0, arr.length - 1, k);
    }
    
    private static int medianOfMediansHelper(int[] arr, int left, int right, int k) {
        if (right - left < 5) {
            Arrays.sort(arr, left, right + 1);
            return arr[k];
        }
        
        // Divide into groups of 5 and find median of each
        int numMedians = (right - left + 5) / 5;
        int[] medians = new int[numMedians];
        
        for (int i = 0; i < numMedians; i++) {
            int groupLeft = left + i * 5;
            int groupRight = Math.min(groupLeft + 4, right);
            medians[i] = findMedian5(arr, groupLeft, groupRight);
        }
        
        // Find median of medians
        int pivot = medianOfMediansHelper(medians, 0, medians.length - 1, medians.length / 2);
        
        // Find pivot index in original array
        int pivotIndex = -1;
        for (int i = left; i <= right; i++) {
            if (arr[i] == pivot) {
                pivotIndex = i;
                break;
            }
        }
        
        // Partition around pivot
        pivotIndex = partition(arr, left, right, pivotIndex);
        
        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return medianOfMediansHelper(arr, left, pivotIndex - 1, k);
        } else {
            return medianOfMediansHelper(arr, pivotIndex + 1, right, k);
        }
    }
    
    /**
     * Find median of a small group (5 or fewer elements).
     */
    private static int findMedian5(int[] arr, int left, int right) {
        Arrays.sort(arr, left, right + 1);
        return arr[left + (right - left) / 2];
    }
    
    private static int partition(int[] arr, int left, int right, int pivotIndex) {
        int pivotValue = arr[pivotIndex];
        swap(arr, pivotIndex, right);
        
        int storeIndex = left;
        for (int i = left; i < right; i++) {
            if (arr[i] < pivotValue) {
                swap(arr, storeIndex, i);
                storeIndex++;
            }
        }
        
        swap(arr, right, storeIndex);
        return storeIndex;
    }
    
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

---

## Related Sorting Algorithms

### QuickSort

```java
import java.util.*;

public class QuickSort {
    private static Random random = new Random();
    
    /**
     * QuickSort implementation using randomized pivot.
     * Average: O(n log n), Worst: O(n²), Space: O(log n)
     */
    public static void quickSort(int[] arr) {
        quickSortHelper(arr, 0, arr.length - 1);
    }
    
    private static void quickSortHelper(int[] arr, int low, int high) {
        if (low < high) {
            int pivotIndex = low + random.nextInt(high - low + 1);
            pivotIndex = partition(arr, low, high, pivotIndex);
            
            quickSortHelper(arr, low, pivotIndex - 1);
            quickSortHelper(arr, pivotIndex + 1, high);
        }
    }
    
    private static int partition(int[] arr, int low, int high, int pivotIndex) {
        int pivotValue = arr[pivotIndex];
        swap(arr, pivotIndex, high);
        
        int storeIndex = low;
        for (int i = low; i < high; i++) {
            if (arr[i] < pivotValue) {
                swap(arr, storeIndex, i);
                storeIndex++;
            }
        }
        
        swap(arr, high, storeIndex);
        return storeIndex;
    }
    
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    
    public static void main(String[] args) {
        int[] arr = {3, 6, 8, 10, 1, 2, 1};
        System.out.println("Before: " + Arrays.toString(arr));
        quickSort(arr);
        System.out.println("After: " + Arrays.toString(arr));
    }
}
```

**Alternative: Three-Way Partition (Dutch National Flag)**

```java
public class QuickSortThreeWay {
    /**
     * QuickSort with three-way partitioning for better handling of duplicates.
     */
    public static void quickSort3Way(int[] arr) {
        quickSort3WayHelper(arr, 0, arr.length - 1);
    }
    
    private static void quickSort3WayHelper(int[] arr, int low, int high) {
        if (low >= high) return;
        
        int pivot = arr[low];
        int lt = low;      // arr[low..lt-1] < pivot
        int gt = high;     // arr[gt+1..high] > pivot
        int i = low + 1;   // arr[lt..i-1] == pivot
        
        while (i <= gt) {
            if (arr[i] < pivot) {
                swap(arr, lt++, i++);
            } else if (arr[i] > pivot) {
                swap(arr, i, gt--);
            } else {
                i++;
            }
        }
        
        // Now arr[low..lt-1] < pivot == arr[lt..gt] < arr[gt+1..high]
        quickSort3WayHelper(arr, low, lt - 1);
        quickSort3WayHelper(arr, gt + 1, high);
    }
    
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

### Merge Sort

```java
public class MergeSort {
    
    /**
     * Merge Sort implementation.
     * Time: O(n log n) always, Space: O(n)
     * Stable sorting algorithm.
     */
    public static void mergeSort(int[] arr) {
        if (arr.length <= 1) return;
        
        int[] temp = new int[arr.length];
        mergeSortHelper(arr, temp, 0, arr.length - 1);
    }
    
    private static void mergeSortHelper(int[] arr, int[] temp, int left, int right) {
        if (left < right) {
            int mid = left + (right - left) / 2;
            
            mergeSortHelper(arr, temp, left, mid);
            mergeSortHelper(arr, temp, mid + 1, right);
            merge(arr, temp, left, mid, right);
        }
    }
    
    /**
     * Merge two sorted subarrays.
     */
    private static void merge(int[] arr, int[] temp, int left, int mid, int right) {
        // Copy elements to temp array
        for (int i = left; i <= right; i++) {
            temp[i] = arr[i];
        }
        
        int i = left;
        int j = mid + 1;
        int k = left;
        
        // Merge back to arr
        while (i <= mid && j <= right) {
            if (temp[i] <= temp[j]) {
                arr[k++] = temp[i++];
            } else {
                arr[k++] = temp[j++];
            }
        }
        
        // Copy remaining elements
        while (i <= mid) {
            arr[k++] = temp[i++];
        }
        
        while (j <= right) {
            arr[k++] = temp[j++];
        }
    }
    
    public static void main(String[] args) {
        int[] arr = {38, 27, 43, 3, 9, 82, 10};
        System.out.println("Before: " + Arrays.toString(arr));
        mergeSort(arr);
        System.out.println("After: " + Arrays.toString(arr));
    }
}
```

### Heap Sort

```java
public class HeapSort {
    
    /**
     * Heap Sort implementation.
     * Time: O(n log n) always, Space: O(1)
     * Not stable.
     */
    public static void heapSort(int[] arr) {
        int n = arr.length;
        
        // Build max heap
        for (int i = n / 2 - 1; i >= 0; i--) {
            heapify(arr, n, i);
        }
        
        // Extract elements from heap one by one
        for (int i = n - 1; i > 0; i--) {
            // Move current root to end
            swap(arr, 0, i);
            
            // Heapify reduced heap
            heapify(arr, i, 0);
        }
    }
    
    /**
     * Maintain max heap property.
     */
    private static void heapify(int[] arr, int n, int i) {
        int largest = i;
        int left = 2 * i + 1;
        int right = 2 * i + 2;
        
        if (left < n && arr[left] > arr[largest]) {
            largest = left;
        }
        
        if (right < n && arr[right] > arr[largest]) {
            largest = right;
        }
        
        if (largest != i) {
            swap(arr, i, largest);
            heapify(arr, n, largest);
        }
    }
    
    private static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    
    public static void main(String[] args) {
        int[] arr = {12, 11, 13, 5, 6, 7};
        System.out.println("Before: " + Arrays.toString(arr));
        heapSort(arr);
        System.out.println("After: " + Arrays.toString(arr));
    }
}
```

### Counting Sort

```java
public class CountingSort {
    
    /**
     * Counting Sort for integers.
     * Time: O(n + k) where k is range, Space: O(k)
     * Stable sorting algorithm.
     */
    public static int[] countingSort(int[] arr) {
        if (arr.length == 0) return arr;
        
        // Find range
        int min = arr[0];
        int max = arr[0];
        for (int num : arr) {
            min = Math.min(min, num);
            max = Math.max(max, num);
        }
        
        int range = max - min + 1;
        int[] count = new int[range];
        int[] output = new int[arr.length];
        
        // Count occurrences
        for (int num : arr) {
            count[num - min]++;
        }
        
        // Cumulative count
        for (int i = 1; i < count.length; i++) {
            count[i] += count[i - 1];
        }
        
        // Build output array (iterate backwards for stability)
        for (int i = arr.length - 1; i >= 0; i--) {
            int num = arr[i];
            output[count[num - min] - 1] = num;
            count[num - min]--;
        }
        
        return output;
    }
    
    public static void main(String[] args) {
        int[] arr = {4, 2, 2, 8, 3, 3, 1};
        System.out.println("Before: " + Arrays.toString(arr));
        int[] sorted = countingSort(arr);
        System.out.println("After: " + Arrays.toString(sorted));
    }
}
```

### Radix Sort

```java
public class RadixSort {
    
    /**
     * Radix Sort for non-negative integers.
     * Time: O(d * (n + k)) where d is number of digits
     * Space: O(n + k)
     * Stable sorting algorithm.
     */
    public static void radixSort(int[] arr) {
        if (arr.length == 0) return;
        
        // Find maximum number to know number of digits
        int max = arr[0];
        for (int num : arr) {
            max = Math.max(max, num);
        }
        
        // Do counting sort for every digit
        for (int exp = 1; max / exp > 0; exp *= 10) {
            countingSortByDigit(arr, exp);
        }
    }
    
    /**
     * Counting sort based on digit represented by exp.
     */
    private static void countingSortByDigit(int[] arr, int exp) {
        int n = arr.length;
        int[] output = new int[n];
        int[] count = new int[10]; // Digits 0-9
        
        // Count occurrences
        for (int i = 0; i < n; i++) {
            int digit = (arr[i] / exp) % 10;
            count[digit]++;
        }
        
        // Cumulative count
        for (int i = 1; i < 10; i++) {
            count[i] += count[i - 1];
        }
        
        // Build output array
        for (int i = n - 1; i >= 0; i--) {
            int digit = (arr[i] / exp) % 10;
            output[count[digit] - 1] = arr[i];
            count[digit]--;
        }
        
        // Copy output to arr
        System.arraycopy(output, 0, arr, 0, n);
    }
    
    public static void main(String[] args) {
        int[] arr = {170, 45, 75, 90, 802, 24, 2, 66};
        System.out.println("Before: " + Arrays.toString(arr));
        radixSort(arr);
        System.out.println("After: " + Arrays.toString(arr));
    }
}
```

### Insertion Sort

```java
public class InsertionSort {
    
    /**
     * Insertion Sort implementation.
     * Time: O(n²) worst/average, O(n) best
     * Space: O(1)
     * Stable sorting algorithm.
     * Good for small arrays or nearly sorted data.
     */
    public static void insertionSort(int[] arr) {
        for (int i = 1; i < arr.length; i++) {
            int key = arr[i];
            int j = i - 1;
            
            // Move elements greater than key one position ahead
            while (j >= 0 && arr[j] > key) {
                arr[j + 1] = arr[j];
                j--;
            }
            arr[j + 1] = key;
        }
    }
    
    public static void main(String[] args) {
        int[] arr = {12, 11, 13, 5, 6};
        System.out.println("Before: " + Arrays.toString(arr));
        insertionSort(arr);
        System.out.println("After: " + Arrays.toString(arr));
    }
}
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
|Radix Sort|O(d(n + k))|O(d(n + k))|O(d(n + k))|O(n + k)|Yes|
|Insertion Sort|O(n)|O(n²)|O(n²)|O(1)|Yes|

_Where k = range of input values, d = number of digits_

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
- **QuickSort**: General-purpose sorting, good cache performance, small constant factors
- **Merge Sort**: Need stability, guaranteed O(n log n), external sorting, linked lists
- **Heap Sort**: Guaranteed O(n log n) in-place, priority queue applications
- **Counting Sort**: Small integer range, need O(n) sorting, counting problems
- **Radix Sort**: Large numbers with limited digits, string sorting
- **Insertion Sort**: Small arrays (< 20 elements), nearly sorted data, online sorting

---

## Additional Resources

- [[Partition Algorithm]]
- [[Randomized Algorithms]]
- [[Order Statistics]]
- [[Selection Problem]]

---

## Complete Java Examples

### Comprehensive Demo Program

```java
import java.util.*;

public class AlgorithmComparison {
    
    public static void main(String[] args) {
        // Test data
        int[] arr = {3, 2, 1, 5, 6, 4};
        
        System.out.println("=== QuickSelect Examples ===");
        System.out.println("Original array: " + Arrays.toString(arr));
        
        // Find k-th smallest
        int[] copy1 = arr.clone();
        System.out.println("2nd smallest (k=1): " + QuickSelect.quickSelect(copy1, 1));
        
        // Find median
        System.out.println("Median: " + QuickSelect.findMedian(arr));
        
        // Find k-th largest
        System.out.println("2nd largest: " + QuickSelect.findKthLargest(arr, 2));
        
        System.out.println("\n=== Sorting Comparison ===");
        
        // Generate random array for performance testing
        int[] testArray = generateRandomArray(10);
        System.out.println("Test array: " + Arrays.toString(testArray));
        
        // QuickSort
        int[] arr1 = testArray.clone();
        long start = System.nanoTime();
        QuickSort.quickSort(arr1);
        long end = System.nanoTime();
        System.out.println("QuickSort: " + Arrays.toString(arr1) + 
                          " (" + (end - start) / 1000 + " μs)");
        
        // MergeSort
        int[] arr2 = testArray.clone();
        start = System.nanoTime();
        MergeSort.mergeSort(arr2);
        end = System.nanoTime();
        System.out.println("MergeSort: " + Arrays.toString(arr2) + 
                          " (" + (end - start) / 1000 + " μs)");
        
        // HeapSort
        int[] arr3 = testArray.clone();
        start = System.nanoTime();
        HeapSort.heapSort(arr3);
        end = System.nanoTime();
        System.out.println("HeapSort:  " + Arrays.toString(arr3) + 
                          " (" + (end - start) / 1000 + " μs)");
        
        // CountingSort (for small range)
        int[] arr4 = testArray.clone();
        start = System.nanoTime();
        int[] sorted = CountingSort.countingSort(arr4);
        end = System.nanoTime();
        System.out.println("CountingSort: " + Arrays.toString(sorted) + 
                          " (" + (end - start) / 1000 + " μs)");
    }
    
    private static int[] generateRandomArray(int size) {
        Random random = new Random();
        int[] arr = new int[size];
        for (int i = 0; i < size; i++) {
            arr[i] = random.nextInt(100);
        }
        return arr;
    }
}
```

### Top K Elements Problem

```java
import java.util.*;

public class TopKElements {
    
    /**
     * Find K largest elements using QuickSelect.
     * Time: O(n) average case
     */
    public static int[] topKLargest(int[] arr, int k) {
        int[] copy = arr.clone();
        
        // Find the k-th largest element
        int kthLargest = QuickSelect.quickSelect(copy, arr.length - k);
        
        // Collect all elements >= k-th largest
        List<Integer> result = new ArrayList<>();
        for (int num : arr) {
            if (num >= kthLargest) {
                result.add(num);
            }
        }
        
        return result.stream().mapToInt(i -> i).toArray();
    }
    
    /**
     * Find K smallest elements using QuickSelect.
     * Time: O(n) average case
     */
    public static int[] topKSmallest(int[] arr, int k) {
        int[] copy = arr.clone();
        
        // Find the k-th smallest element
        int kthSmallest = QuickSelect.quickSelect(copy, k - 1);
        
        // Collect all elements <= k-th smallest
        List<Integer> result = new ArrayList<>();
        for (int num : arr) {
            if (num <= kthSmallest) {
                result.add(num);
            }
        }
        
        return result.stream().mapToInt(i -> i).toArray();
    }
    
    public static void main(String[] args) {
        int[] arr = {3, 2, 1, 5, 6, 4};
        
        System.out.println("Array: " + Arrays.toString(arr));
        System.out.println("Top 2 largest: " + Arrays.toString(topKLargest(arr, 2)));
        System.out.println("Top 2 smallest: " + Arrays.toString(topKSmallest(arr, 2)));
    }
}
```

### Percentile Calculation

```java
public class PercentileCalculator {
    
    /**
     * Calculate the p-th percentile (0-100).
     * Example: p=50 gives median, p=95 gives 95th percentile
     */
    public static double percentile(int[] arr, int p) {
        if (p < 0 || p > 100) {
            throw new IllegalArgumentException("Percentile must be between 0 and 100");
        }
        
        int[] copy = arr.clone();
        int n = copy.length;
        
        // Calculate position
        double pos = (p / 100.0) * (n - 1);
        int lower = (int) Math.floor(pos);
        int upper = (int) Math.ceil(pos);
        
        if (lower == upper) {
            return QuickSelect.quickSelect(copy, lower);
        }
        
        // Interpolate between two values
        int lowerVal = QuickSelect.quickSelect(copy.clone(), lower);
        int upperVal = QuickSelect.quickSelect(copy.clone(), upper);
        double weight = pos - lower;
        
        return lowerVal * (1 - weight) + upperVal * weight;
    }
    
    public static void main(String[] args) {
        int[] scores = {55, 62, 71, 83, 88, 91, 94, 97, 99};
        
        System.out.println("Scores: " + Arrays.toString(scores));
        System.out.println("25th percentile: " + percentile(scores, 25));
        System.out.println("50th percentile (median): " + percentile(scores, 50));
        System.out.println("75th percentile: " + percentile(scores, 75));
        System.out.println("90th percentile: " + percentile(scores, 90));
    }
}
```

### Generic QuickSelect (Works with any Comparable)

```java
import java.util.*;

public class GenericQuickSelect<T extends Comparable<T>> {
    private Random random = new Random();
    
    public T quickSelect(T[] arr, int k) {
        return quickSelectHelper(arr, 0, arr.length - 1, k);
    }
    
    private T quickSelectHelper(T[] arr, int left, int right, int k) {
        if (left == right) {
            return arr[left];
        }
        
        int pivotIndex = left + random.nextInt(right - left + 1);
        pivotIndex = partition(arr, left, right, pivotIndex);
        
        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return quickSelectHelper(arr, left, pivotIndex - 1, k);
        } else {
            return quickSelectHelper(arr, pivotIndex + 1, right, k);
        }
    }
    
    private int partition(T[] arr, int left, int right, int pivotIndex) {
        T pivotValue = arr[pivotIndex];
        swap(arr, pivotIndex, right);
        
        int storeIndex = left;
        for (int i = left; i < right; i++) {
            if (arr[i].compareTo(pivotValue) < 0) {
                swap(arr, storeIndex, i);
                storeIndex++;
            }
        }
        
        swap(arr, right, storeIndex);
        return storeIndex;
    }
    
    private void swap(T[] arr, int i, int j) {
        T temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    
    public static void main(String[] args) {
        // Works with Strings
        GenericQuickSelect<String> stringSelector = new GenericQuickSelect<>();
        String[] words = {"banana", "apple", "cherry", "date", "elderberry"};
        System.out.println("2nd smallest word: " + stringSelector.quickSelect(words.clone(), 1));
        
        // Works with Doubles
        GenericQuickSelect<Double> doubleSelector = new GenericQuickSelect<>();
        Double[] prices = {19.99, 5.99, 12.50, 8.75, 15.25};
        System.out.println("Median price: " + doubleSelector.quickSelect(prices.clone(), 2));
    }
}
```

---

## Practice Problems

### 1. Kth Largest Element in an Array (LeetCode 215)

**Problem:** Find the kth largest element in an unsorted array. Note that it is the kth largest element in sorted order, not the kth distinct element.

**Example:**

```
Input: nums = [3,2,1,5,6,4], k = 2
Output: 5
```

**Solution Template:**

```java
class Solution {
    public int findKthLargest(int[] nums, int k) {
        return quickSelect(nums, 0, nums.length - 1, nums.length - k);
    }
    
    private int quickSelect(int[] arr, int left, int right, int k) {
        if (left == right) return arr[left];
        
        int pivotIndex = partition(arr, left, right);
        
        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return quickSelect(arr, left, pivotIndex - 1, k);
        } else {
            return quickSelect(arr, pivotIndex + 1, right, k);
        }
    }
    
    private int partition(int[] arr, int left, int right) {
        int pivot = arr[right];
        int i = left;
        
        for (int j = left; j < right; j++) {
            if (arr[j] < pivot) {
                swap(arr, i, j);
                i++;
            }
        }
        
        swap(arr, i, right);
        return i;
    }
    
    private void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

### 2. Top K Frequent Elements (LeetCode 347)

**Problem:** Given an integer array nums and an integer k, return the k most frequent elements.

**Example:**

```
Input: nums = [1,1,1,2,2,3], k = 2
Output: [1,2]
```

**Solution Template:**

```java
class Solution {
    public int[] topKFrequent(int[] nums, int k) {
        // Count frequencies
        Map<Integer, Integer> count = new HashMap<>();
        for (int num : nums) {
            count.put(num, count.getOrDefault(num, 0) + 1);
        }
        
        // Convert to array of [num, frequency] pairs
        int[][] freqArray = new int[count.size()][2];
        int idx = 0;
        for (Map.Entry<Integer, Integer> entry : count.entrySet()) {
            freqArray[idx][0] = entry.getKey();
            freqArray[idx][1] = entry.getValue();
            idx++;
        }
        
        // Use quickselect to find k-th largest frequency
        quickSelect(freqArray, 0, freqArray.length - 1, k - 1);
        
        // Return top k elements
        int[] result = new int[k];
        for (int i = 0; i < k; i++) {
            result[i] = freqArray[i][0];
        }
        return result;
    }
    
    private void quickSelect(int[][] arr, int left, int right, int k) {
        if (left >= right) return;
        
        int pivotIndex = partition(arr, left, right);
        
        if (pivotIndex == k) {
            return;
        } else if (pivotIndex < k) {
            quickSelect(arr, pivotIndex + 1, right, k);
        } else {
            quickSelect(arr, left, pivotIndex - 1, k);
        }
    }
    
    private int partition(int[][] arr, int left, int right) {
        int pivot = arr[right][1];
        int i = left;
        
        for (int j = left; j < right; j++) {
            if (arr[j][1] > pivot) { // Sort by frequency descending
                swap(arr, i, j);
                i++;
            }
        }
        
        swap(arr, i, right);
        return i;
    }
    
    private void swap(int[][] arr, int i, int j) {
        int[] temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

### 3. Find Median from Data Stream (LeetCode 295)

**Problem:** Design a data structure that supports adding integers and finding the median.

**Solution Template:**

```java
class MedianFinder {
    private PriorityQueue<Integer> maxHeap; // Lower half
    private PriorityQueue<Integer> minHeap; // Upper half
    
    public MedianFinder() {
        maxHeap = new PriorityQueue<>(Collections.reverseOrder());
        minHeap = new PriorityQueue<>();
    }
    
    public void addNum(int num) {
        if (maxHeap.isEmpty() || num <= maxHeap.peek()) {
            maxHeap.offer(num);
        } else {
            minHeap.offer(num);
        }
        
        // Balance heaps
        if (maxHeap.size() > minHeap.size() + 1) {
            minHeap.offer(maxHeap.poll());
        } else if (minHeap.size() > maxHeap.size()) {
            maxHeap.offer(minHeap.poll());
        }
    }
    
    public double findMedian() {
        if (maxHeap.size() == minHeap.size()) {
            return (maxHeap.peek() + minHeap.peek()) / 2.0;
        } else {
            return maxHeap.peek();
        }
    }
}
```

### 4. K Closest Points to Origin (LeetCode 973)

**Problem:** Given an array of points, return the k closest points to the origin (0, 0).

**Example:**

```
Input: points = [[1,3],[-2,2]], k = 1
Output: [[-2,2]]
```

**Solution Template:**

```java
class Solution {
    public int[][] kClosest(int[][] points, int k) {
        quickSelect(points, 0, points.length - 1, k - 1);
        return Arrays.copyOfRange(points, 0, k);
    }
    
    private void quickSelect(int[][] points, int left, int right, int k) {
        if (left >= right) return;
        
        int pivotIndex = partition(points, left, right);
        
        if (pivotIndex == k) {
            return;
        } else if (pivotIndex < k) {
            quickSelect(points, pivotIndex + 1, right, k);
        } else {
            quickSelect(points, left, pivotIndex - 1, k);
        }
    }
    
    private int partition(int[][] points, int left, int right) {
        int[] pivot = points[right];
        int pivotDist = distance(pivot);
        int i = left;
        
        for (int j = left; j < right; j++) {
            if (distance(points[j]) < pivotDist) {
                swap(points, i, j);
                i++;
            }
        }
        
        swap(points, i, right);
        return i;
    }
    
    private int distance(int[] point) {
        return point[0] * point[0] + point[1] * point[1];
    }
    
    private void swap(int[][] points, int i, int j) {
        int[] temp = points[i];
        points[i] = points[j];
        points[j] = temp;
    }
}
```

### 5. Wiggle Sort II (LeetCode 324)

**Problem:** Given an integer array nums, reorder it such that nums[0] < nums[1] > nums[2] < nums[3]...

**Example:**

```
Input: nums = [1,5,1,1,6,4]
Output: [1,6,1,5,1,4]
```

**Solution Template:**

```java
class Solution {
    public void wiggleSort(int[] nums) {
        int n = nums.length;
        
        // Find median using quickselect
        int median = findKthLargest(nums, (n + 1) / 2);
        
        // Three-way partition around median
        int left = 0, i = 0, right = n - 1;
        
        while (i <= right) {
            if (nums[index(i, n)] > median) {
                swap(nums, index(left++, n), index(i++, n));
            } else if (nums[index(i, n)] < median) {
                swap(nums, index(right--, n), index(i, n));
            } else {
                i++;
            }
        }
    }
    
    // Virtual indexing to interleave elements
    private int index(int i, int n) {
        return (1 + 2 * i) % (n | 1);
    }
    
    private int findKthLargest(int[] nums, int k) {
        // QuickSelect implementation
        return quickSelect(nums.clone(), 0, nums.length - 1, k - 1);
    }
    
    private int quickSelect(int[] arr, int left, int right, int k) {
        if (left == right) return arr[left];
        
        int pivotIndex = partition(arr, left, right);
        
        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return quickSelect(arr, left, pivotIndex - 1, k);
        } else {
            return quickSelect(arr, pivotIndex + 1, right, k);
        }
    }
    
    private int partition(int[] arr, int left, int right) {
        int pivot = arr[right];
        int i = left;
        
        for (int j = left; j < right; j++) {
            if (arr[j] > pivot) {
                swap(arr, i, j);
                i++;
            }
        }
        
        swap(arr, i, right);
        return i;
    }
    
    private void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

### Additional Practice Problems

6. **Kth Smallest Element in a Sorted Matrix** (LeetCode 378)
7. **Split Array into Consecutive Subsequences** (LeetCode 659)
8. **Find K Pairs with Smallest Sums** (LeetCode 373)
9. **Maximum Gap** (LeetCode 164) - Use Radix Sort
10. **Sort Colors** (LeetCode 75) - Three-way partition (Dutch National Flag)

---

_Created: 2025-10-26_ _Language: Java_ _Tags: #algorithms #quickselect #sorting #complexity-analysis #selection-problem #java #leetcode_

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│ QuickSelect Cheat Sheet                             │
├─────────────────────────────────────────────────────┤
│ Average Time:  O(n)                                 │
│ Worst Time:    O(n²) [extremely rare with random]  │
│ Space:         O(1)                                 │
│ Stable:        No                                   │
├─────────────────────────────────────────────────────┤
│ Key Operations:                                     │
│  • quickSelect(arr, k)         → k-th smallest     │
│  • findMedian(arr)             → median value      │
│  • findKthLargest(arr, k)      → k-th largest      │
├─────────────────────────────────────────────────────┤
│ When to Use:                                        │
│  ✓ Finding k-th element (median, percentile)       │
│  ✓ Top-K problems (single query)                   │
│  ✓ Memory constrained (in-place)                   │
│  ✗ Multiple k-th queries (use sorting instead)     │
│  ✗ Need stable ordering                            │
└─────────────────────────────────────────────────────┘
```