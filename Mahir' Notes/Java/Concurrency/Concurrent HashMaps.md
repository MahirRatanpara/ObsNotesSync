# ConcurrentHashMap & Compare-and-Swap (CAS) Operations

## Overview

ConcurrentHashMap achieves thread-safety through a combination of **finer-grained locking** and **optimistic locking** using Compare-and-Swap (CAS) operations.

## Core Architecture

### Internal Structure

- Uses array of nodes/buckets (similar to [[HashMap]])
- Each bucket contains linked list or tree of nodes
- Thread-safe without synchronizing entire data structure

### Key Components

- **Bucket-level locking**: Only lock specific buckets during modifications
- **CAS operations**: Atomic compare-and-swap for reads and structural changes
- **Volatile fields**: Ensure memory visibility across threads

## Finer-Grained Locking 🔓🔒

### Traditional Approach vs ConcurrentHashMap

```java
// ❌ Traditional synchronized HashMap
synchronized(map) {
    map.put(key, value); // Entire map locked
}

// ✅ ConcurrentHashMap approach  
synchronized(bucketHead) {
    // Only this specific bucket locked
}
```

### Benefits

- Multiple threads can modify different buckets simultaneously
- Reduced thread contention
- Better scalability across CPU cores

## Compare-and-Swap (CAS) Operations

### What is CAS?

> **Compare-and-Swap**: An atomic operation that updates a memory location only if it contains an expected value

### CAS Pattern

```java
while (true) {
    int current = atomicValue.get();           // 1. Read current value
    int newValue = computeNewValue(current);   // 2. Calculate desired value
    
    if (atomicValue.compareAndSet(current, newValue)) {
        break; // 3. Success! Update completed atomically
    }
    // 4. Retry if another thread modified the value
}
```

### Hardware Support

- **x86**: `CMPXCHG` instruction
- **ARM**: Load-Link/Store-Conditional
- Much faster than traditional locking

## Optimistic Locking Strategy

### Core Principle

- **Assumption**: Thread conflicts are rare
- **Approach**: Attempt operation without locks
- **Fallback**: Retry if conflict detected

### Advantages

- **Lock-free reads**: Most read operations need no synchronization
- **High performance**: Avoids lock acquisition overhead
- **Scalability**: Works well under low-to-moderate contention

## ConcurrentHashMap Implementation Details

### Read Operations (get)

```java
public String get(String key) {
    // 🚀 Completely lock-free!
    Node node = buckets.get(index);  // Atomic read
    
    while (node != null) {
        if (key.equals(node.key)) {
            return node.value;  // Volatile read ensures visibility
        }
        node = node.next;      // Volatile read
    }
    return null;
}
```

### Write Operations (put)

```java
// Hybrid approach: CAS + synchronized
for (;;) {
    Node f = table[i];  // Volatile read of bucket head
    
    if (f == null) {
        // Empty bucket: try CAS insertion
        if (casTabAt(table, i, null, newNode)) {
            break; // Success!
        }
    } else {
        // Non-empty bucket: use synchronized block
        synchronized (f) {
            // Safely modify bucket contents
        }
    }
}
```

## Key Concepts

### Memory Visibility

- **Volatile fields**: Ensure changes are visible across threads
- **Happens-before relationships**: CAS operations establish memory ordering
- **No stale reads**: Threads see consistent view of data

### ABA Problem

> **Issue**: Value changes A→B→A between read and CAS **Solutions**:
> 
> - Use versioned references ([[AtomicStampedReference]])
> - Design data structures to avoid problematic patterns

### Performance Characteristics

- **High concurrency**: Excellent under moderate contention
- **Read-heavy workloads**: Nearly zero overhead for reads
- **Write scaling**: Good until very high contention levels

## Related Concepts

### Atomic Classes

- [[AtomicInteger]] - CAS-based integer operations
- [[AtomicReference]] - CAS-based object references
- [[AtomicReferenceArray]] - Array of atomic references

### Alternative Approaches

- [[Synchronized Collections]] - Full synchronization (slower)
- [[Lock-free Data Structures]] - Pure CAS-based implementations
- [[ReentrantReadWriteLock]] - Separate read/write locks

## Code Examples

### Basic CAS Counter

```java
public class CASCounter {
    private AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        while (true) {
            int current = count.get();
            if (count.compareAndSet(current, current + 1)) {
                break; // Success!
            }
            // Retry on failure
        }
    }
}
```

### Lock-free Linked List Insertion

```java
public void insert(String key, String value) {
    Node newNode = new Node(key, value, null);
    
    while (true) {
        Node currentHead = head.get();
        newNode.next = currentHead;
        
        if (head.compareAndSet(currentHead, newNode)) {
            break; // Successfully inserted
        }
        // Another thread modified head, retry
    }
}
```

## Performance Implications

### When CAS Excels

- ✅ Low to moderate thread contention
- ✅ Read-heavy workloads
- ✅ Short critical sections
- ✅ Multi-core systems

### When CAS Struggles

- ❌ Very high contention (many threads competing)
- ❌ Long-running operations in retry loops
- ❌ Memory-constrained systems

## Tags

#concurrency #java #thread-safety #lock-free #performance #data-structures