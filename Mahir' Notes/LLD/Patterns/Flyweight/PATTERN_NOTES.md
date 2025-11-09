# Flyweight Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Save memory by sharing common state among multiple objects instead of storing it in each object.

## 📖 The Problem
**Without Flyweight**: Memory explosion
- 10,000 tree objects × (position + texture + color + mesh) = **Huge memory usage**
- Each tree stores its own texture and mesh data
- Most trees share the same species (oak, pine, birch)

**With Flyweight**: Memory efficient
- 10,000 tree objects × (position only) + 3 shared textures/meshes = **Small memory**
- Shared data extracted and reused
- Intrinsic state shared, extrinsic state stored externally

## 🔑 Key Concept
```
Flyweight = Intrinsic State (shared) + Extrinsic State (unique)
```

**Intrinsic State** (inside flyweight):
- Shared among many objects
- Doesn't depend on flyweight's context
- Immutable
- Example: Tree species, texture, color

**Extrinsic State** (passed to flyweight):
- Unique to each object
- Depends on context
- Stored by client
- Example: Tree position, health

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Many similar objects | ✗ Few objects |
| ✓ Most state can be shared | ✗ All state is unique |
| ✓ Memory is a concern | ✗ Unlimited memory |
| ✓ Object identity doesn't matter | ✗ Need unique object identity |

## 📐 Structure

```
┌──────────────┐
│ FlyweightFac │ ◄─── Manages and returns shared flyweights
│    tory      │      Creates if doesn't exist, returns if exists
└──────┬───────┘
       │ manages
       │
       │       ┌─────────────┐
       └──────►│  Flyweight  │ ◄─── Shared object (intrinsic state)
               │   (Tree     │
               │  Species)   │
               └─────────────┘
                      ▲
                      │ uses
               ┌──────┴──────┐
               │   Client    │ ◄─── Stores extrinsic state (position)
               │  (Forest)   │
               └─────────────┘
```

## 💻 Implementation Pattern

### 1. Flyweight Interface
```java
// Represents shared state
public interface TreeType {
    void render(int x, int y);  // Extrinsic state passed as parameter
}
```

### 2. Concrete Flyweight
```java
public class TreeTypeFlyweight implements TreeType {
    // Intrinsic state (shared)
    private String name;
    private Color color;
    private Texture texture;

    public TreeTypeFlyweight(String name, Color color, Texture texture) {
        this.name = name;
        this.color = color;
        this.texture = texture;
    }

    @Override
    public void render(int x, int y) {  // Extrinsic state
        System.out.println("Drawing " + name + " at (" + x + ", " + y + ")");
        // Use intrinsic state + extrinsic state to render
    }
}
```

### 3. Flyweight Factory
```java
public class TreeTypeFactory {
    private static Map<String, TreeType> treeTypes = new HashMap<>();

    public static TreeType getTreeType(String name, Color color, Texture texture) {
        String key = name + color + texture;

        if (!treeTypes.containsKey(key)) {
            treeTypes.put(key, new TreeTypeFlyweight(name, color, texture));
            System.out.println("Creating new tree type: " + name);
        }
        return treeTypes.get(key);
    }

    public static int getTotalTreeTypes() {
        return treeTypes.size();
    }
}
```

### 4. Context (Client)
```java
public class Tree {
    // Extrinsic state (unique to each tree)
    private int x;
    private int y;

    // Intrinsic state (shared via flyweight)
    private TreeType type;

    public Tree(int x, int y, TreeType type) {
        this.x = x;
        this.y = y;
        this.type = type;
    }

    public void draw() {
        type.render(x, y);  // Pass extrinsic state
    }
}
```

### 5. Usage
```java
public class Forest {
    private List<Tree> trees = new ArrayList<>();

    public void plantTree(int x, int y, String name, Color color, Texture texture) {
        TreeType type = TreeTypeFactory.getTreeType(name, color, texture);
        Tree tree = new Tree(x, y, type);
        trees.add(tree);
    }

    public void draw() {
        for (Tree tree : trees) {
            tree.draw();
        }
    }
}

// Client code
Forest forest = new Forest();
for (int i = 0; i < 10000; i++) {
    forest.plantTree(random.nextInt(1000), random.nextInt(1000),
                     "Oak", Color.GREEN, OakTexture);
}
// Only 1 TreeType object created for all 10,000 oak trees!
```

## 🎓 Real-World Examples

| Domain | Example | Intrinsic | Extrinsic |
|--------|---------|-----------|-----------|
| **Text Editor** | Characters | Font, style | Position |
| **Game** | Particles | Sprite, color | Position, velocity |
| **Database** | Connection Pool | Connection | Query data |
| **Java** | String Pool | String value | Variables |

### Java String Interning
```java
String s1 = "hello";        // Stored in string pool
String s2 = "hello";        // Reuses same object
System.out.println(s1 == s2);  // true (same reference!)

String s3 = new String("hello");  // New object in heap
System.out.println(s1 == s3);     // false (different reference)

String s4 = s3.intern();    // Returns pooled instance
System.out.println(s1 == s4);     // true (same reference!)
```

## ⚖️ Flyweight vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Flyweight** | Save memory via sharing | Shares intrinsic state |
| **Singleton** | One instance globally | One instance, not shared state |
| **Object Pool** | Reuse expensive objects | Reuses entire objects |
| **Prototype** | Clone objects | Creates copies, doesn't share |

### Flyweight vs Object Pool
```java
// Object Pool: Reuse entire object
Connection conn = pool.getConnection();  // Borrow entire connection
// ... use it
pool.returnConnection(conn);             // Return for reuse

// Flyweight: Share part of object
TreeType type = factory.getTreeType("Oak");  // Share species data
Tree tree1 = new Tree(10, 20, type);         // Unique position
Tree tree2 = new Tree(30, 40, type);         // Different position, same type
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Storing extrinsic state in flyweight
```java
// Wrong: Position stored in flyweight (should be extrinsic!)
class TreeTypeFlyweight {
    private int x, y;  // ❌ Unique to each tree!
    private String name;
}

// Right: Only intrinsic state in flyweight
class TreeTypeFlyweight {
    private String name;  // ✅ Shared among trees
}
```

### ❌ Mistake 2: Not using factory
```java
// Wrong: Direct creation (no sharing!)
TreeType type1 = new TreeTypeFlyweight("Oak", GREEN);
TreeType type2 = new TreeTypeFlyweight("Oak", GREEN);  // Duplicate!

// Right: Factory ensures sharing
TreeType type1 = TreeTypeFactory.getTreeType("Oak", GREEN);
TreeType type2 = TreeTypeFactory.getTreeType("Oak", GREEN);  // Same instance!
```

### ❌ Mistake 3: Mutable intrinsic state
```java
// Wrong: Mutable shared state (thread-unsafe!)
class TreeTypeFlyweight {
    private Color color;

    public void setColor(Color color) {  // ❌ Changes all trees!
        this.color = color;
    }
}

// Right: Immutable intrinsic state
class TreeTypeFlyweight {
    private final Color color;  // ✅ Final, immutable

    // No setters!
}
```

### ❌ Mistake 4: Using when state is mostly unique
```java
// Wrong: Each user has unique data
class User {
    private String id;        // Unique
    private String name;      // Unique
    private String email;     // Unique
    private String password;  // Unique
}
// No shared state → Flyweight inappropriate!

// Flyweight only makes sense when there's significant shared state
```

## 🎤 Interview Questions & Answers

### Q1: What is the Flyweight pattern?
**A**: A structural pattern that minimizes memory usage by sharing as much data as possible with similar objects. It separates intrinsic (shared) state from extrinsic (unique) state.

### Q2: When would you use Flyweight?
**A**: When:
1. Application uses large number of objects
2. Storage costs are high due to quantity
3. Most object state can be made extrinsic
4. Many groups of objects can be replaced by few shared objects
5. Application doesn't depend on object identity

### Q3: What's intrinsic vs extrinsic state?
**A**:
- **Intrinsic**: Internal, shared, context-independent, stored in flyweight
- **Extrinsic**: External, unique, context-dependent, passed to flyweight

Example:
- Font character: intrinsic = glyph shape, extrinsic = position in document

### Q4: How does Flyweight save memory?
**A**: Instead of storing shared data in each of N objects, store it once and reference it.
- **Without**: N objects × (shared + unique) = N × shared + N × unique
- **With**: 1 × shared + N × unique
- **Savings**: (N - 1) × shared state

### Q5: Can you give a real Java example?
**A**: Java's String interning:
```java
String s1 = "hello";  // Creates in string pool
String s2 = "hello";  // Reuses same object (flyweight!)
System.out.println(s1 == s2);  // true
```
All strings with same value share one object in pool.

### Q6: What's the role of the factory?
**A**: The factory:
1. Maintains pool of flyweight instances
2. Returns existing flyweight if available
3. Creates new flyweight only if needed
4. Ensures flyweights are properly shared

### Q7: Is flyweight thread-safe?
**A**: The **flyweight itself** must be thread-safe (immutable intrinsic state). The **factory** needs thread-safe cache:
```java
private static ConcurrentHashMap<String, TreeType> cache = new ConcurrentHashMap<>();
```

### Q8: Flyweight vs Singleton?
**A**:
- **Singleton**: One instance globally (one object)
- **Flyweight**: One instance per intrinsic state (few objects, many references)
- Singleton is about instance count, Flyweight is about shared state

### Q9: What are disadvantages?
**A**:
- **Complexity**: Code becomes more complex
- **Extrinsic state management**: Client must track extrinsic state
- **Runtime cost**: Passing extrinsic state has overhead
- **Not always applicable**: Needs significant shared state

### Q10: How do you identify intrinsic vs extrinsic state?
**A**:
- **Intrinsic**: If removed, all instances change (shared properties)
- **Extrinsic**: If removed, only one instance changes (unique properties)
- Ask: "Can this be shared across instances?"

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Reduce memory by sharing common state |
| **Intrinsic** | Shared, immutable, context-independent |
| **Extrinsic** | Unique, mutable, context-dependent |
| **Factory** | Manages and ensures flyweight sharing |
| **Trade-off** | Memory savings vs code complexity |
| **When** | Many objects, significant shared state |

## 🔍 Quick Checklist

When implementing Flyweight pattern:
- [ ] Identify intrinsic state (what can be shared)
- [ ] Identify extrinsic state (what must be unique)
- [ ] Make intrinsic state immutable
- [ ] Create flyweight with intrinsic state only
- [ ] Create factory to manage flyweight instances
- [ ] Factory uses cache (HashMap) for sharing
- [ ] Client stores extrinsic state
- [ ] Client passes extrinsic state to flyweight methods
- [ ] Don't use if most state is unique

## 📊 Memory Comparison

### Without Flyweight
```
10,000 trees × (texture[1MB] + mesh[500KB] + position[16B])
= 10,000 × 1.5MB ≈ 15GB
```

### With Flyweight
```
3 tree types × 1.5MB + 10,000 × 16B
= 4.5MB + 160KB ≈ 4.7MB
```

**Savings: ~15GB → ~5MB (99.97% reduction!)**

## 💡 Remember
> "Flyweight is like a library: one book (flyweight) shared by many readers (contexts), each reading at their own page (extrinsic state)."

## 📝 Code Template

```java
// 1. Flyweight Interface
interface Flyweight {
    void operation(ExtrinsicState state);
}

// 2. Concrete Flyweight
class ConcreteFlyweight implements Flyweight {
    private final IntrinsicState intrinsic;  // Immutable!

    public ConcreteFlyweight(IntrinsicState intrinsic) {
        this.intrinsic = intrinsic;
    }

    public void operation(ExtrinsicState state) {
        // Use intrinsic + state
    }
}

// 3. Flyweight Factory
class FlyweightFactory {
    private Map<String, Flyweight> cache = new HashMap<>();

    public Flyweight getFlyweight(String key) {
        if (!cache.containsKey(key)) {
            cache.put(key, new ConcreteFlyweight(...));
        }
        return cache.get(key);
    }
}

// 4. Client
Flyweight fw = factory.getFlyweight("key");
fw.operation(extrinsicState);
```

---

**For Amazon Interviews**: Focus on **memory optimization** (why), **intrinsic vs extrinsic** separation (how), and **factory pattern** usage. Be ready to calculate memory savings and discuss thread-safety.
