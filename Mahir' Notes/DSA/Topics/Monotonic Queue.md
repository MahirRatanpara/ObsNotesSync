# Monotonic Queue

## Definition
A **monotonic queue** is a data structure that maintains elements in either strictly **increasing** or **decreasing** order. When adding a new element, you remove elements from the back that violate the monotonic property before inserting the new element.

## Key Concepts

### Monotonic Property
- **Increasing Queue**: Elements are arranged in non-decreasing order (useful for finding minimums)
- **Decreasing Queue**: Elements are arranged in non-increasing order (useful for finding maximums)

### Core Operations
- `push(value)` - Add element while maintaining monotonic property
- `front()` - Get the front element (min/max depending on queue type)
- `popFront()` - Remove front element
- `isEmpty()` - Check if queue is empty

## Why Monotonic Queues Work

The key insight is **aggressive pruning** of redundant elements:

> If element A comes before element B in time, and A is "worse" than B (A ≤ B for max problems, A ≥ B for min problems), then A will **never** be the optimal answer for any future query that includes both A and B.

Therefore, we can safely discard A when B arrives.

## Applications

### Primary Use Cases
- [[Sliding Window Maximum/Minimum]]
- [[Next Greater/Smaller Element]]
- [[Largest Rectangle in Histogram]]
- [[Stock Span Problem]]

### Time Complexity Benefits
- Reduces O(n²) naive solutions to **O(n)**
- Each element pushed once, popped at most once
- **Amortized O(1)** per operation

## Implementation Strategy

```
For Decreasing Queue (Max):
1. When adding element x:
   - Remove all elements from back that are ≤ x
   - Add x to back
   - Front contains maximum

For Increasing Queue (Min):  
1. When adding element x:
   - Remove all elements from back that are ≥ x
   - Add x to back
   - Front contains minimum
```

## Java Implementation

```java
import java.util.ArrayDeque;
import java.util.Deque;

/**
 * Monotonic Queue implementation that maintains elements in either 
 * increasing or decreasing order.
 */
public class MonotonicQueue {
    
    /**
     * Inner class to store value-index pairs
     */
    public static class Element {
        int value;
        int index;
        
        public Element(int value, int index) {
            this.value = value;
            this.index = index;
        }
        
        @Override
        public String toString() {
            return "(" + value + ", " + index + ")";
        }
    }
    
    private Deque<Element> deque;
    private boolean increasing;
    
    /**
     * Creates a monotonic queue
     * @param increasing if true, maintains increasing order (for finding mins)
     *                  if false, maintains decreasing order (for finding maxs)
     */
    public MonotonicQueue(boolean increasing) {
        this.deque = new ArrayDeque<>();
        this.increasing = increasing;
    }
    
    /**
     * Adds element to queue while maintaining monotonic property
     * @param value the value to add
     * @param index the index/timestamp of the value
     */
    public void push(int value, int index) {
        if (increasing) {
            // For increasing queue: remove elements >= current value
            while (!deque.isEmpty() && deque.peekLast().value >= value) {
                deque.pollLast();
            }
        } else {
            // For decreasing queue: remove elements <= current value
            while (!deque.isEmpty() && deque.peekLast().value <= value) {
                deque.pollLast();
            }
        }
        
        deque.offerLast(new Element(value, index));
    }
    
    /**
     * Removes and returns the front element
     * @return the front element, or null if empty
     */
    public Element popFront() {
        return deque.pollFirst();
    }
    
    /**
     * Returns the front element without removing it
     * @return the front element, or null if empty
     */
    public Element front() {
        return deque.peekFirst();
    }
    
    /**
     * Returns the back element without removing it
     * @return the back element, or null if empty
     */
    public Element back() {
        return deque.peekLast();
    }
    
    /**
     * Checks if the queue is empty
     * @return true if empty, false otherwise
     */
    public boolean isEmpty() {
        return deque.isEmpty();
    }
    
    /**
     * Returns the size of the queue
     * @return number of elements in queue
     */
    public int size() {
        return deque.size();
    }
    
    /**
     * Removes elements that are outside the current sliding window
     * @param currentIndex current position in array
     * @param windowSize size of sliding window
     */
    public void removeExpired(int currentIndex, int windowSize) {
        while (!deque.isEmpty() && 
               deque.peekFirst().index <= currentIndex - windowSize) {
            deque.pollFirst();
        }
    }
    
    /**
     * Returns string representation of the queue
     */
    @Override
    public String toString() {
        return deque.toString();
    }
    
    /**
     * Example usage demonstrating basic operations
     */
    public static void main(String[] args) {
        System.out.println("=== Monotonic Queue Demo ===\n");
        
        // Decreasing queue (for finding maximums)
        System.out.println("Decreasing Queue (maintains max at front):");
        MonotonicQueue maxQueue = new MonotonicQueue(false);
        int[] values = {3, 1, 4, 1, 5, 9, 2, 6};
        
        for (int i = 0; i < values.length; i++) {
            maxQueue.push(values[i], i);
            System.out.printf("After adding %d: front=%s, queue=%s%n", 
                            values[i], maxQueue.front(), maxQueue);
        }
        
        System.out.println("\nIncreasing Queue (maintains min at front):");
        MonotonicQueue minQueue = new MonotonicQueue(true);
        
        for (int i = 0; i < values.length; i++) {
            minQueue.push(values[i], i);
            System.out.printf("After adding %d: front=%s, queue=%s%n", 
                            values[i], minQueue.front(), minQueue);
        }
        
        // Demonstrate sliding window usage
        System.out.println("\n=== Sliding Window Example ===");
        MonotonicQueue windowQueue = new MonotonicQueue(false); // For max
        int[] arr = {1, 3, -1, -3, 5, 3, 6, 7};
        int windowSize = 3;
        
        System.out.printf("Array: %s%n", java.util.Arrays.toString(arr));
        System.out.printf("Window size: %d%n", windowSize);
        System.out.println("Sliding window maximums:");
        
        for (int i = 0; i < arr.length; i++) {
            windowQueue.push(arr[i], i);
            windowQueue.removeExpired(i, windowSize);
            
            if (i >= windowSize - 1) {
                System.out.printf("Window [%d-%d]: max = %d%n", 
                                i - windowSize + 1, i, windowQueue.front().value);
            }
        }
    }
}
```

## Memory and Performance

### Space Complexity
- **O(n)** in worst case (when elements are in strict monotonic order)
- **O(k)** average case for sliding window problems (k = window size)

### Time Complexity
- **Push**: Amortized O(1) - each element added once, removed at most once
- **Front/Back**: O(1)
- **Remove Expired**: Amortized O(1)

## Important Notes

### When to Use Increasing vs Decreasing
- **Increasing Queue**: Use when you need to find **minimum** values
  - Elements maintained in non-decreasing order
  - Smallest element always at front
  
- **Decreasing Queue**: Use when you need to find **maximum** values  
  - Elements maintained in non-increasing order
  - Largest element always at front

### Common Pitfalls
1. **Index Tracking**: Always store both value and index for sliding window problems
2. **Window Expiry**: Remember to remove expired elements before using front()
3. **Queue Type**: Choose increasing/decreasing based on whether you need min/max

## Related Topics
- [[Sliding Window Technique]]
- [[Stack Applications]]
- [[Deque (Double-ended Queue)]]
- [[Dynamic Programming Optimizations]]

---

*Tags: #algorithms #data-structures #queue #optimization #sliding-window*