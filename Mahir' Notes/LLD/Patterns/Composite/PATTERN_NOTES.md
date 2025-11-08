# Composite Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Compose objects into tree structures to represent part-whole hierarchies, allowing clients to treat individual objects and compositions uniformly.

## 📖 The Problem
**Without Composite**: Client must distinguish between leaf and composite
```java
if (obj instanceof Task) {
    Task task = (Task) obj;
    effort = task.getEffort();
} else if (obj instanceof TaskGroup) {
    TaskGroup group = (TaskGroup) obj;
    effort = group.calculateTotalEffort();  // Different method!
}
```

**With Composite**: Uniform treatment
```java
effort = component.getEffort();  // Works for both!
```

## 🔑 Key Concept
```
Component (interface/abstract)
    ├── Leaf (cannot contain children)
    └── Composite (contains children)
```

**Both implement same interface** → Client treats them uniformly

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Part-whole hierarchies (tree structure) | ✗ Flat, non-hierarchical data |
| ✓ Treat individual & groups uniformly | ✗ Leaf and composite need different interfaces |
| ✓ Operations apply recursively | ✗ Simple list/collection is enough |
| ✓ File systems, UI trees, org charts | ✗ No recursive operations needed |

## 📐 Structure

```
        ┌───────────┐
        │ Component │ ◄─── Abstract base (interface/class)
        └─────┬─────┘
              │
      ┌───────┴────────┐
      │                │
┌─────▼─────┐   ┌─────▼──────┐
│   Leaf    │   │ Composite  │
│  (Task)   │   │(TaskGroup) │
└───────────┘   └─────┬──────┘
                      │ contains
                      ▼
                ┌───────────┐
                │ Component │ (children)
                └───────────┘
```

## 💻 Implementation Pattern

### 1. Component (Abstract Base)
```java
public abstract class TaskComponent {
    protected String name;

    public abstract int getEffort();
    public abstract void display(int indent);

    // Optional: Default implementations that throw exception
    public void add(TaskComponent component) {
        throw new UnsupportedOperationException();
    }

    public void remove(TaskComponent component) {
        throw new UnsupportedOperationException();
    }
}
```

### 2. Leaf (Cannot Contain Children)
```java
public class Task extends TaskComponent {
    private int effort;

    public Task(String name, int effort) {
        this.name = name;
        this.effort = effort;
    }

    public int getEffort() {
        return effort;  // Just return own effort
    }

    public void display(int indent) {
        System.out.println("  ".repeat(indent) + name + " (" + effort + " hours)");
    }

    // Inherits add/remove that throw exceptions
}
```

### 3. Composite (Contains Children)
```java
public class TaskGroup extends TaskComponent {
    private List<TaskComponent> children = new ArrayList<>();  // Use List, not Set!

    public TaskGroup(String name) {
        this.name = name;
    }

    @Override
    public void add(TaskComponent component) {
        children.add(component);
    }

    @Override
    public void remove(TaskComponent component) {
        children.remove(component);
    }

    public int getEffort() {
        // Recursive: sum all children's effort
        return children.stream()
            .mapToInt(TaskComponent::getEffort)
            .sum();
    }

    public void display(int indent) {
        // Display self with total effort
        System.out.println("  ".repeat(indent) + name + " (" + getEffort() + " hours)");
        // Recursively display children
        for (TaskComponent child : children) {
            child.display(indent + 1);
        }
    }
}
```

### 4. Usage (Uniform Treatment)
```java
// Create tree structure
TaskComponent task1 = new Task("Database", 10);
TaskComponent task2 = new Task("API", 20);

TaskGroup backend = new TaskGroup("Backend");
backend.add(task1);
backend.add(task2);

TaskGroup project = new TaskGroup("Project");
project.add(backend);
project.add(new Task("Testing", 25));

// Treat all uniformly
project.getEffort();    // 55 hours (recursive sum)
backend.getEffort();    // 30 hours
task1.getEffort();      // 10 hours

// All use same interface!
```

## 🎓 Real-World Examples

| Domain | Leaf | Composite | Operation |
|--------|------|-----------|-----------|
| **File System** | File | Directory | getSize() |
| **UI** | Button | Panel | render() |
| **Organization** | Employee | Department | getSalary() |
| **Graphics** | Shape | Group | draw() |
| **Project** | Task | TaskGroup | getEffort() |

### Java Examples
```java
// AWT/Swing UI
Component button = new JButton("OK");
Container panel = new JPanel();
panel.add(button);  // Composite contains component

// Both extend Component, treated uniformly
button.setVisible(true);
panel.setVisible(true);
```

## ⚖️ Design Decisions

### 1. Transparency vs Safety

**Transparency (What we used):**
```java
// add/remove in Component base class
public abstract class TaskComponent {
    public void add(TaskComponent c) {
        throw new UnsupportedOperationException();
    }
}
```
- ✅ Uniform interface - client doesn't need to know type
- ❌ Leaf can call add() - throws runtime exception

**Safety:**
```java
// add/remove only in Composite
public class TaskGroup {
    public void add(TaskComponent c) { }  // Only here
}
```
- ✅ Type-safe - leaf can't call add()
- ❌ Client must know if it's composite to call add()

**Trade-off**: Transparency is usually preferred in Composite pattern.

### 2. Who Manages Children?

**Component (Common):**
```java
abstract class Component {
    List<Component> children;  // In base class
}
```
- ✅ Uniform implementation
- ❌ Wastes memory in leaf nodes

**Composite Only (Better):**
```java
class Composite extends Component {
    List<Component> children;  // Only in composite
}
```
- ✅ Memory efficient
- ✅ Clear responsibility

## 🚨 Common Mistakes

### ❌ Mistake 1: Using Set instead of List
```java
// Wrong: HashSet loses order
Set<TaskComponent> children = new HashSet<>();

// Right: ArrayList preserves insertion order
List<TaskComponent> children = new ArrayList<>();
```
**Why**: Tree structures need predictable order for proper display.

### ❌ Mistake 2: Inconsistent display format
```java
// Wrong: Composite doesn't show effort
public void display(int indent) {
    System.out.println(name);  // Missing effort!
    for (TaskComponent child : children) {
        child.display(indent + 1);
    }
}

// Right: Same format as leaf
public void display(int indent) {
    System.out.println(name + " (" + getEffort() + " hours)");
    for (TaskComponent child : children) {
        child.display(indent + 1);
    }
}
```
**Why**: Leaf and composite must be indistinguishable to client.

### ❌ Mistake 3: Forgetting recursion in composite
```java
// Wrong: Only direct children
public int getEffort() {
    return children.size();  // Just count!
}

// Right: Recursive sum
public int getEffort() {
    return children.stream()
        .mapToInt(TaskComponent::getEffort)  // Recursive!
        .sum();
}
```

### ❌ Mistake 4: Not handling circular references
```java
TaskGroup group = new TaskGroup("A");
group.add(group);  // Circular reference - infinite recursion!
```

**Fix**: Check before adding
```java
public void add(TaskComponent component) {
    if (component == this) {
        throw new IllegalArgumentException("Cannot add to itself");
    }
    children.add(component);
}
```

## 🎤 Interview Questions & Answers

### Q1: What is the Composite pattern?
**A**: A structural pattern that lets you compose objects into tree structures to represent part-whole hierarchies. It allows clients to treat individual objects (leaf) and compositions (composite) uniformly through a common interface.

### Q2: When would you use Composite?
**A**: When you have:
- Tree structures (file systems, UI hierarchies, organizational charts)
- Need to treat part and whole uniformly
- Operations that apply recursively (calculate total, render all, etc.)

### Q3: What's the key principle of Composite?
**A**: **Uniform treatment** - leaf and composite implement the same interface, so clients don't need to distinguish between them. This simplifies client code.

### Q4: Composite vs Decorator - what's the difference?
**A**:
- **Composite**: Represents part-whole hierarchy (1-to-many), focuses on tree structure
- **Decorator**: Adds responsibilities (1-to-1), focuses on wrapping behavior
- Composite has **multiple children**; Decorator wraps **one object**

### Q5: Why use List instead of Set for children?
**A**: Tree structures need to preserve order for:
- Predictable traversal
- Proper display/rendering
- Maintaining logical structure (e.g., file order in directory)

### Q6: Should add/remove be in Component or Composite?
**A**: Two approaches:
- **Transparency**: In Component (uniform interface, but leaf throws exception)
- **Safety**: Only in Composite (type-safe, but client must check type)

Transparency is usually preferred for Composite pattern.

### Q7: How do you handle operations that only make sense for leaf?
**A**:
- Option 1: Default implementation in Component that returns null/throws exception
- Option 2: Use type checking (breaks uniform treatment)
- Option 3: Make operation return empty/neutral value for composite

### Q8: What's a real-world example in Java?
**A**: Java AWT/Swing UI:
```java
Container panel = new JPanel();  // Composite
Component button = new JButton(); // Leaf
panel.add(button);
// Both extend Component - uniform treatment
```

### Q9: How do you prevent circular references?
**A**: Check before adding:
```java
if (component == this || component.contains(this)) {
    throw new IllegalArgumentException("Circular reference");
}
```

### Q10: What are disadvantages of Composite?
**A**:
- **Overly general**: Hard to restrict component types
- **Complexity**: More classes than simple collection
- **Performance**: Recursive operations can be slow for deep trees
- **Circular references**: Need explicit handling

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Tree structures with uniform treatment |
| **Structure** | Component → Leaf + Composite (contains Components) |
| **Key Rule** | Leaf and Composite implement same interface |
| **Operations** | Recursive in Composite, direct in Leaf |
| **Data Structure** | Use **List** (preserves order), not Set |
| **Uniformity** | Same display format for leaf and composite |

## 🔍 Quick Checklist

When implementing Composite pattern:
- [ ] Component is abstract base class/interface
- [ ] Leaf extends Component (no children)
- [ ] Composite extends Component (has children)
- [ ] Composite uses **List**, not Set
- [ ] Both implement same operations
- [ ] Composite operations are recursive
- [ ] Display format is consistent (leaf & composite)
- [ ] add/remove in Component or only Composite (pick one)

## 📊 Pattern Template

```java
// 1. Component
abstract class Component {
    abstract void operation();
    void add(Component c) { throw new UnsupportedOperationException(); }
    void remove(Component c) { throw new UnsupportedOperationException(); }
}

// 2. Leaf
class Leaf extends Component {
    void operation() { /* do leaf work */ }
}

// 3. Composite
class Composite extends Component {
    private List<Component> children = new ArrayList<>();

    void add(Component c) { children.add(c); }
    void remove(Component c) { children.remove(c); }

    void operation() {
        for (Component child : children) {
            child.operation();  // Recursive!
        }
    }
}

// 4. Client
Component leaf = new Leaf();
Composite composite = new Composite();
composite.add(leaf);
composite.operation();  // Treats both uniformly
```

## 💡 Remember
> "Composite lets you build trees where branches and leaves are treated the same way - the client doesn't care if it's talking to a single object or a whole structure."

## 🔄 Composite vs Similar Patterns

| Aspect | Composite | Decorator |
|--------|-----------|-----------|
| **Relationship** | 1-to-many (parent-children) | 1-to-1 (wrapper-wrapped) |
| **Purpose** | Represent hierarchy | Add behavior |
| **Structure** | Tree | Chain/Stack |
| **Children** | Multiple | One |
| **Example** | Directory contains files | Milk wraps Espresso |

---

**For Amazon Interviews**: Focus on explaining **tree structures**, **uniform treatment**, and **recursive operations**. Be ready to code in 10 minutes and discuss file system or UI hierarchy as examples. Remember: **List, not Set!**
