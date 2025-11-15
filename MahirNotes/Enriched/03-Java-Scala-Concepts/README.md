# ☕ Java & Scala Concepts - SDE2 Interview Master Guide

> **"Java is to JavaScript what Car is to Carpet" - Focus on the deep fundamentals that matter**

---

## 📋 Quick Navigation

| **Core Java** | **Advanced Concepts** | **Concurrency** |
|---|---|---|
| [OOP Fundamentals](#oop-fundamentals) | [Collections Deep Dive](#collections-deep-dive) | [Threading Concepts](#threading-concepts) |
| [Inheritance & Polymorphism](#inheritance--polymorphism) | [Streams & Functional](#streams--functional-programming) | [Concurrent Collections](#concurrent-collections) |
| [Exception Handling](#exception-handling) | [Memory Management](#memory-management) | [Executors & Thread Pools](#executors--thread-pools) |
| [Generics](#generics) | [JVM Internals](#jvm-internals) | [Synchronization](#synchronization) |

---

## 🎯 Study Strategy for SDE2

### 📚 **Phase 1: Core Concepts (Week 1)**
**Goal:** Solid foundation in Java fundamentals
- ✅ OOP principles (Encapsulation, Inheritance, Polymorphism)
- ✅ Exception handling patterns
- ✅ Collections framework mastery
- ✅ Generics and type system

### 🔥 **Phase 2: Advanced Features (Week 2)**  
**Goal:** Deep understanding of language-specific features
- ✅ Streams API and functional programming
- ✅ Lambda expressions and method references
- ✅ Memory management and GC concepts
- ✅ JVM performance tuning basics

### 🚀 **Phase 3: Concurrency & Performance (Week 3)**
**Goal:** Master multi-threaded programming
- ✅ Thread safety and synchronization
- ✅ Concurrent collections (ConcurrentHashMap, BlockingQueue)
- ✅ Executor framework and thread pools
- ✅ Lock-free programming concepts

---

## 🏗️ Core Java Concepts

### OOP Fundamentals
**Key Topics:** Encapsulation, Inheritance, Polymorphism, Abstraction
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](./OOP-Fundamentals.md)

---

### Inheritance & Polymorphism  
**Key Topics:** Class vs Abstract Class vs Interface, Method overriding, Diamond problem
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](Inheritance-and-Polymorphism.md)

---

### Collections Deep Dive
**Key Topics:** ArrayList vs LinkedList, HashMap internals, TreeMap vs HashMap
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](./Collections-Deep-Dive.md)

---

### Exception Handling
**Key Topics:** Checked vs unchecked exceptions, try-with-resources, custom exceptions
**Interview Weight:** 🔥🔥🔥 (Medium-High)

[📖 Complete Guide →](./Exception-Handling.md)

---

### Generics
**Key Topics:** Type safety, Wildcards, Type erasure, PECS principle
**Interview Weight:** 🔥🔥🔥 (Medium-High)

[📖 Complete Guide →](./Generics.md)

---

## 🚀 Advanced Java Features

### Streams & Functional Programming
**Key Topics:** Stream operations, Lambda expressions, Method references, Collectors
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Streams-and-Functional-Programming.md)

---

### Memory Management
**Key Topics:** Heap vs Stack, Garbage collection, Memory leaks, JVM tuning
**Interview Weight:** 🔥🔥🔥 (Medium-High)

[📖 Complete Guide →](./Memory-Management.md)

---

### JVM Internals  
**Key Topics:** Class loading, Bytecode, JIT compilation, Profiling
**Interview Weight:** 🔥🔥 (Medium)

[📖 Complete Guide →](./JVM-Internals.md)

---

## 🧵 Concurrency & Multithreading

### Threading Concepts
**Key Topics:** Thread lifecycle, Thread creation, Thread safety, Race conditions
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](./Threading-Concepts.md)

---

### Concurrent Collections
**Key Topics:** ConcurrentHashMap, BlockingQueue, CopyOnWriteArrayList
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Concurrent-Collections.md)

---

### Executors & Thread Pools
**Key Topics:** ThreadPoolExecutor, ScheduledExecutorService, CompletableFuture
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Executors-and-Thread-Pools.md)

---

### Synchronization
**Key Topics:** synchronized keyword, ReentrantLock, Condition variables, Atomic operations
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Synchronization.md)

---

## 🔥 Must-Know Interview Topics

### **🎯 Top 15 Java Concepts for SDE2** #must-do

#### **Core Language Features**
1. ✅ **HashMap Internal Implementation** #must-do #faang
   - Hash collision handling, Load factor, Resize mechanism
   - **Companies:** All FAANG, especially Google and Amazon

2. ✅ **ConcurrentHashMap vs HashMap** #must-do #concurrency
   - Thread safety, Performance comparison, Internal structure
   - **Companies:** All tech companies with concurrent systems

3. ✅ **String Immutability & String Pool** #must-do
   - Memory optimization, Interning, Performance implications
   - **Companies:** Oracle, Amazon, Microsoft

4. ✅ **Garbage Collection Concepts** #must-do
   - GC algorithms, Memory leaks, Performance tuning
   - **Companies:** Netflix, Uber, high-performance systems

5. ✅ **Stream API Operations** #must-do #java8
   - Lazy evaluation, Parallel streams, Custom collectors
   - **Companies:** Modern Java shops, fintech companies

#### **Object-Oriented Programming**
6. ✅ **Interface vs Abstract Class** #must-do #oop
   - When to use which, Multiple inheritance, Default methods
   - **Companies:** All companies testing OOP knowledge

7. ✅ **Method Overriding vs Overloading** #must-do
   - Dynamic dispatch, Compile-time vs runtime binding
   - **Companies:** Basic concept tested everywhere

8. ✅ **Equals() and HashCode() Contract** #must-do
   - Object equality, Hash-based collections behavior
   - **Companies:** Amazon, Google (collections-heavy problems)

#### **Concurrency & Threading**
9. ✅ **Thread Safety Mechanisms** #must-do #concurrency
   - synchronized, volatile, Atomic classes, Lock interfaces
   - **Companies:** All companies with concurrent systems

10. ✅ **Producer-Consumer Problem** #must-do #threading
    - BlockingQueue, wait/notify, Condition variables
    - **Companies:** System-focused companies like Uber, Lyft

11. ✅ **Executor Framework** #must-do #threadpools
    - ThreadPoolExecutor, ScheduledExecutor, CompletableFuture
    - **Companies:** Server-side companies like LinkedIn, Twitter

#### **Performance & Memory**
12. ✅ **Memory Leaks in Java** #must-do #performance
    - Common causes, Detection techniques, Prevention
    - **Companies:** Performance-critical companies like HFT firms

13. ✅ **ArrayList vs LinkedList** #must-do #collections
    - Performance characteristics, Use cases, Memory overhead
    - **Companies:** Basic DS knowledge tested everywhere

14. ✅ **Exception Handling Best Practices** #must-do
    - Checked vs unchecked, try-with-resources, Custom exceptions
    - **Companies:** All companies focusing on code quality

15. ✅ **Lambda Expressions & Method References** #must-do #java8
    - Functional interfaces, Closure concepts, Performance
    - **Companies:** Modern Java development companies

---

## 💻 Hands-On Coding Patterns

### **Common Java Interview Coding Problems**

#### **Collections & Data Structures**
```java
// Implement LRU Cache using LinkedHashMap
class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int capacity;
    
    public LRUCache(int capacity) {
        super(capacity + 1, 0.75f, true);
        this.capacity = capacity;
    }
    
    @Override
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
}
```

#### **Concurrency Patterns**
```java
// Thread-safe Singleton (Double-checked locking)
public class Singleton {
    private static volatile Singleton instance;
    
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

#### **Streams & Functional Programming**
```java
// Complex stream operations example
Map<Department, Optional<Employee>> highestPaidByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::getDepartment,
        Collectors.maxBy(Comparator.comparing(Employee::getSalary))
    ));
```

---

## 🧠 Common Interview Questions & Answers

### **🔥 Fundamental Questions**

#### **Q1: Explain HashMap internal implementation** #hashmap-internals

**Perfect Answer Structure:**
1. **Array + LinkedList/TreeNode structure**
2. **Hash function and collision handling** 
3. **Load factor and resizing mechanism**
4. **Tree conversion (Java 8+)**

```java
// Simplified HashMap implementation
public class SimpleHashMap<K, V> {
    private Node<K, V>[] table;
    private int size;
    private final float loadFactor = 0.75f;
    
    static class Node<K, V> {
        final int hash;
        final K key;
        V value;
        Node<K, V> next;
        
        Node(int hash, K key, V value, Node<K, V> next) {
            this.hash = hash;
            this.key = key;
            this.value = value;
            this.next = next;
        }
    }
    
    public V put(K key, V value) {
        int hash = hash(key);
        int index = hash & (table.length - 1);
        
        // Handle collision with chaining
        for (Node<K, V> node = table[index]; node != null; node = node.next) {
            if (node.hash == hash && Objects.equals(node.key, key)) {
                V oldValue = node.value;
                node.value = value;
                return oldValue;
            }
        }
        
        // Add new node
        table[index] = new Node<>(hash, key, value, table[index]);
        if (++size > table.length * loadFactor) {
            resize();
        }
        return null;
    }
}
```

#### **Q2: What makes ConcurrentHashMap thread-safe?** #concurrenthashmap

**Key Points:**
1. **Segment-based locking (Java 7) vs CAS operations (Java 8+)**
2. **Lock-free reads**
3. **Fine-grained locking for writes**

```java
// Key thread-safety mechanisms in ConcurrentHashMap
public V get(Object key) {
    // Completely lock-free read
    Node<K,V>[] tab; Node<K,V> e; int n; long eh; K ek;
    int h = spread(key.hashCode());
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (e = tabAt(tab, (n - 1) & h)) != null) {
        // Volatile read ensures visibility
        // No locking needed for reads
    }
}

public V put(K key, V value) {
    // Use CAS for atomic updates or synchronized blocks for bucket modifications
    for (Node<K,V>[] tab = table;;) {
        if (tab == null || (n = tab.length) == 0)
            tab = initTable();
        else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
            if (casTabAt(tab, i, null, new Node<K,V>(hash, key, value, null)))
                break;  // No lock needed - CAS succeeded
        }
        else {
            synchronized (f) {  // Lock only this bucket
                // Modify bucket contents safely
            }
        }
    }
}
```

#### **Q3: Explain the difference between == and equals()** #equals-hashcode

**Complete Answer:**
- `==` compares **reference equality** (memory addresses)
- `equals()` compares **logical equality** (content)
- **Contract:** If `a.equals(b)` is true, then `a.hashCode() == b.hashCode()`

```java
public class Person {
    private String name;
    private int age;
    
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        
        Person person = (Person) obj;
        return age == person.age && Objects.equals(name, person.name);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }
}

// Usage examples
String s1 = new String("hello");
String s2 = new String("hello");
String s3 = "hello";
String s4 = "hello";

System.out.println(s1 == s2);     // false (different objects)
System.out.println(s1.equals(s2)); // true (same content)
System.out.println(s3 == s4);     // true (string pool optimization)
```

---

## ⚖️ Performance Considerations

### **Memory Optimization Patterns**

#### **String Optimization**
```java
// ❌ Inefficient string concatenation
String result = "";
for (int i = 0; i < 10000; i++) {
    result += "item" + i;  // Creates new String objects each time
}

// ✅ Efficient approach
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 10000; i++) {
    sb.append("item").append(i);
}
String result = sb.toString();
```

#### **Collection Sizing**
```java
// ❌ Default capacity causes multiple resizes
List<String> list = new ArrayList<>();  // default capacity 10

// ✅ Pre-size if you know approximate size
List<String> list = new ArrayList<>(1000);  // Avoids resizing
```

#### **Memory Leak Prevention**
```java
// ❌ Memory leak - listeners not removed
public class EventPublisher {
    private List<EventListener> listeners = new ArrayList<>();
    
    public void addListener(EventListener listener) {
        listeners.add(listener);  // Never removed!
    }
}

// ✅ Proper cleanup
public class EventPublisher {
    private List<WeakReference<EventListener>> listeners = new ArrayList<>();
    
    public void addListener(EventListener listener) {
        listeners.add(new WeakReference<>(listener));
    }
    
    // Cleanup method
    public void cleanup() {
        listeners.removeIf(ref -> ref.get() == null);
    }
}
```

---

## 🎓 Advanced Topics for Senior Engineers

### **JVM Performance Tuning**

#### **GC Tuning Parameters**
```bash
# G1 Garbage Collector (recommended for most applications)
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=32m

# Memory settings
-Xms4g -Xmx4g  # Initial and max heap size
-XX:NewRatio=2  # Old generation to young generation ratio

# Monitoring and debugging
-XX:+PrintGC
-XX:+PrintGCDetails  
-XX:+PrintGCTimeStamps
```

#### **Profiling and Monitoring**
```java
// JMX monitoring example
public class ApplicationMonitor {
    private final MemoryMXBean memoryMBean;
    private final ThreadMXBean threadMBean;
    
    public ApplicationMonitor() {
        this.memoryMBean = ManagementFactory.getMemoryMXBean();
        this.threadMBean = ManagementFactory.getThreadMXBean();
    }
    
    public void logMemoryUsage() {
        MemoryUsage heapUsage = memoryMBean.getHeapMemoryUsage();
        long used = heapUsage.getUsed();
        long max = heapUsage.getMax();
        double percentage = (double) used / max * 100;
        
        System.out.printf("Heap usage: %.2f%% (%d/%d MB)%n", 
                          percentage, used >> 20, max >> 20);
    }
}
```

---

## 📚 Study Resources & Practice

### **Essential Books**
- *Effective Java* - Joshua Bloch (Bible for Java best practices)
- *Java Concurrency in Practice* - Brian Goetz (Concurrency masterclass)
- *Java: The Complete Reference* - Herbert Schildt (Comprehensive coverage)

### **Online Resources**
- [Oracle Java Documentation](https://docs.oracle.com/en/java/) - Official reference
- [Baeldung](https://www.baeldung.com/) - High-quality Java tutorials
- [Java Code Geeks](https://www.javacodegeeks.com/) - Articles and examples

### **Practice Platforms**
- [LeetCode](https://leetcode.com/) - Focus on Java-specific collections problems
- [HackerRank](https://hackerrank.com/domains/java) - Java domain problems
- [Codewars](https://codewars.com/) - Language-specific challenges

### **Mock Interview Topics**
- Implement thread-safe data structures
- Design patterns implementation
- Performance optimization scenarios
- Memory management and GC analysis

---

**Study Progress Tracker:**
- [ ] Core Java Concepts (0/6 topics mastered)
- [ ] Advanced Features (0/4 topics completed)
- [ ] Concurrency & Threading (0/4 areas practiced)
- [ ] Interview Questions (0/15 questions practiced)
- [ ] Coding Patterns (0/5 patterns implemented)

**Last Updated:** August 2025  
**Next Focus:** [ConcurrentHashMap deep dive implementation]