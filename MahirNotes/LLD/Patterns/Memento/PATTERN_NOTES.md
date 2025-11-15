# Memento Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Capture and externalize an object's internal state without violating encapsulation, allowing the object to be restored to this state later (undo/redo).

## 📖 The Problem
**Without Memento**: Direct state access violates encapsulation
```java
class TextEditor {
    private String text;
    private int cursorPosition;

    // Client saves state directly
    public String getText() { return text; }
    public int getCursorPosition() { return cursorPosition; }

    // Client restores state directly
    public void setText(String text) { this.text = text; }
    public void setCursorPosition(int pos) { this.cursorPosition = pos; }
}

// Client code
String savedText = editor.getText();
int savedCursor = editor.getCursorPosition();
// ❌ Client knows internal structure
// ❌ If editor adds more fields, client code breaks
// ❌ Violates encapsulation
```

**With Memento**: Opaque snapshot preserves encapsulation
```java
class TextEditor {
    private String text;
    private int cursorPosition;

    public Memento save() {
        return new Memento(text, cursorPosition);  // Create snapshot
    }

    public void restore(Memento memento) {
        this.text = memento.getText();
        this.cursorPosition = memento.getCursorPosition();
    }

    // Memento: Opaque to client
    public static class Memento {
        private final String text;
        private final int cursorPosition;

        private Memento(String text, int cursorPosition) {
            this.text = text;
            this.cursorPosition = cursorPosition;
        }

        private String getText() { return text; }
        private int getCursorPosition() { return cursorPosition; }
    }
}

// Client code
Memento snapshot = editor.save();   // ✅ Opaque snapshot
editor.restore(snapshot);            // ✅ No knowledge of internals
```

## 🔑 Key Concept
```
Originator → creates → Memento (snapshot)
Caretaker → stores → Memento
Caretaker → restores via → Originator.restore(Memento)
```

**Core Idea**: Save and restore object state without exposing internal structure.

**Also Known As**: Token, Snapshot

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Need undo/redo functionality | ✗ State is trivial |
| ✓ Direct state access violates encapsulation | ✗ Snapshot is expensive (large state) |
| ✓ Need to save checkpoints | ✗ No need to restore previous state |
| ✓ Rollback transactions | ✗ State rarely changes |

## 📐 Structure

```
┌──────────────┐
│  Caretaker   │ ◄─── Stores mementos, triggers save/restore
├──────────────┤
│ -mementos    │
│ +save()      │
│ +undo()      │
└──────┬───────┘
       │ uses
       ▼
┌──────────────┐         ┌──────────────┐
│  Originator  │────────►│   Memento    │ ◄─── Opaque snapshot
├──────────────┤ creates ├──────────────┤
│ -state       │         │ -state       │
│ +save()      │         │ +getState()  │ (private/package)
│ +restore()   │         └──────────────┘
└──────────────┘
```

## 💻 Implementation Pattern

### 1. Originator (Object whose state is saved)
```java
public class TextEditor {
    private String text;
    private int cursorPosition;
    private String font;

    public TextEditor() {
        this.text = "";
        this.cursorPosition = 0;
        this.font = "Arial";
    }

    // Modify state
    public void write(String newText) {
        this.text += newText;
        this.cursorPosition += newText.length();
    }

    public void setCursor(int position) {
        this.cursorPosition = position;
    }

    public void setFont(String font) {
        this.font = font;
    }

    // Create memento
    public Memento save() {
        return new Memento(text, cursorPosition, font);
    }

    // Restore from memento
    public void restore(Memento memento) {
        this.text = memento.text;
        this.cursorPosition = memento.cursorPosition;
        this.font = memento.font;
    }

    public String getText() {
        return text;
    }

    @Override
    public String toString() {
        return "Text: '" + text + "', Cursor: " + cursorPosition + ", Font: " + font;
    }

    // Memento (inner class - has access to Originator's private fields)
    public static class Memento {
        private final String text;
        private final int cursorPosition;
        private final String font;

        private Memento(String text, int cursorPosition, String font) {
            this.text = text;
            this.cursorPosition = cursorPosition;
            this.font = font;
        }

        // Private getters - only Originator can access
        // Client sees Memento as opaque token
    }
}
```

### 2. Caretaker (Manages mementos)
```java
public class EditorHistory {
    private Stack<TextEditor.Memento> history = new Stack<>();

    public void save(TextEditor editor) {
        history.push(editor.save());
        System.out.println("State saved. History size: " + history.size());
    }

    public void undo(TextEditor editor) {
        if (!history.isEmpty()) {
            editor.restore(history.pop());
            System.out.println("Undo performed. History size: " + history.size());
        } else {
            System.out.println("Nothing to undo");
        }
    }

    public int getHistorySize() {
        return history.size();
    }
}
```

### 3. Usage
```java
TextEditor editor = new TextEditor();
EditorHistory history = new EditorHistory();

// Initial state
System.out.println(editor);  // Text: '', Cursor: 0, Font: Arial

// Edit 1
editor.write("Hello");
history.save(editor);
System.out.println(editor);  // Text: 'Hello', Cursor: 5, Font: Arial

// Edit 2
editor.write(" World");
history.save(editor);
System.out.println(editor);  // Text: 'Hello World', Cursor: 11, Font: Arial

// Edit 3
editor.setFont("Times New Roman");
history.save(editor);
System.out.println(editor);  // Text: 'Hello World', Cursor: 11, Font: Times New Roman

// Edit 4
editor.write("!");
System.out.println(editor);  // Text: 'Hello World!', Cursor: 12, Font: Times New Roman

// Undo (revert to before "!")
history.undo(editor);
System.out.println(editor);  // Text: 'Hello World', Cursor: 11, Font: Times New Roman

// Undo (revert to before font change)
history.undo(editor);
System.out.println(editor);  // Text: 'Hello World', Cursor: 11, Font: Arial

// Undo (revert to "Hello")
history.undo(editor);
System.out.println(editor);  // Text: 'Hello', Cursor: 5, Font: Arial
```

## 🎓 Real-World Examples

| Domain | Originator | Memento | Caretaker |
|--------|-----------|---------|-----------|
| **Text Editor** | Document | Snapshot | Undo Manager |
| **Game** | GameState | SavePoint | SaveManager |
| **Database** | Transaction | Savepoint | Transaction Log |
| **Graphics** | Canvas | Snapshot | History Stack |

### Game Save Example
```java
class Game {
    private int level;
    private int health;
    private int score;
    private Vector position;

    public Memento save() {
        return new Memento(level, health, score, position.clone());
    }

    public void restore(Memento m) {
        this.level = m.level;
        this.health = m.health;
        this.score = m.score;
        this.position = m.position.clone();
    }

    public static class Memento {
        private final int level;
        private final int health;
        private final int score;
        private final Vector position;

        private Memento(int level, int health, int score, Vector position) {
            this.level = level;
            this.health = health;
            this.score = score;
            this.position = position;
        }
    }
}

// Usage
Game game = new Game();
game.setLevel(5);

Memento checkpoint = game.save();  // Save before boss fight
game.fightBoss();  // Player dies

game.restore(checkpoint);  // Restore to checkpoint
```

## 🔐 Encapsulation Techniques

### Option 1: Inner Class (Recommended)
```java
class Originator {
    private State state;

    public Memento save() {
        return new Memento(state);
    }

    public static class Memento {
        private final State state;
        private Memento(State state) { this.state = state; }
        // Only Originator can access state
    }
}
```

### Option 2: Package-Private
```java
// Memento.java (same package as Originator)
class Memento {
    final State state;  // Package-private
    Memento(State state) { this.state = state; }
}

// Originator.java
public class Originator {
    private State state;

    public Memento save() {
        return new Memento(state);
    }

    public void restore(Memento m) {
        this.state = m.state;  // Can access (same package)
    }
}
```

### Option 3: Interface + Private Implementation
```java
// Public interface (opaque to client)
public interface Memento { }

// Private implementation
class Originator {
    private State state;

    public Memento save() {
        return new MementoImpl(state);
    }

    public void restore(Memento memento) {
        MementoImpl impl = (MementoImpl) memento;
        this.state = impl.state;
    }

    private static class MementoImpl implements Memento {
        private final State state;
        MementoImpl(State state) { this.state = state; }
    }
}
```

## ⚖️ Memento vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Memento** | Save/restore state | Encapsulation preserved |
| **Command** | Encapsulate request | Focuses on undo via reverse command |
| **Prototype** | Clone object | Creates new object, not state snapshot |
| **Serialization** | Save object to storage | Generic, loses encapsulation |

### Memento vs Command (Undo)
```java
// Memento: Save entire state
Memento snapshot = editor.save();
editor.restore(snapshot);

// Command: Undo via inverse operation
Command cmd = new InsertTextCommand("Hello");
cmd.execute(editor);
cmd.undo(editor);  // Removes "Hello"

// Memento: Simpler for complex state
// Command: More flexible, can redo operations
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Memento not immutable
```java
// Wrong: Mutable memento
class Memento {
    public String state;  // ❌ Public and mutable!

    public void setState(String state) {  // ❌ Setter
        this.state = state;
    }
}

// Right: Immutable memento
class Memento {
    private final String state;  // ✅ Final

    private Memento(String state) {  // ✅ Private constructor
        this.state = state;
    }
    // No setters
}
```

### ❌ Mistake 2: Client accesses memento internals
```java
// Wrong: Public getters
class Memento {
    public String getState() { return state; }  // ❌ Public
}

// Client code
Memento m = editor.save();
String state = m.getState();  // ❌ Violates encapsulation

// Right: Opaque to client
class Memento {
    private String getState() { return state; }  // ✅ Private
}
```

### ❌ Mistake 3: Not using caretaker
```java
// Wrong: Client manages mementos
Memento m1 = editor.save();
Memento m2 = editor.save();
editor.restore(m1);  // ❌ Client handles history

// Right: Caretaker manages mementos
history.save(editor);
history.save(editor);
history.undo(editor);  // ✅ Caretaker handles history
```

### ❌ Mistake 4: Storing mutable objects directly
```java
// Wrong: Shallow copy
class Memento {
    private List<String> items;  // ❌ Reference copied

    Memento(List<String> items) {
        this.items = items;  // Shallow copy!
    }
}

// Right: Deep copy
class Memento {
    private final List<String> items;

    Memento(List<String> items) {
        this.items = new ArrayList<>(items);  // ✅ Deep copy
    }
}
```

### ❌ Mistake 5: Expensive snapshots without optimization
```java
// Wrong: Always save full state
Memento save() {
    return new Memento(hugeData.clone());  // ❌ Expensive
}

// Better: Incremental snapshots or compression
Memento save() {
    Memento prev = getLastMemento();
    return new Memento(delta(prev));  // ✅ Store only changes
}
```

## 🎤 Interview Questions & Answers

### Q1: What is the Memento pattern?
**A**: A behavioral pattern that captures and externalizes an object's internal state without violating encapsulation, so the object can be restored to this state later.

### Q2: When would you use Memento?
**A**: When:
1. Need undo/redo functionality
2. Must save object state snapshots
3. Direct state access would violate encapsulation
4. Need rollback capabilities (transactions, games)

### Q3: What are the key components?
**A**:
1. **Originator**: Creates and restores from mementos
2. **Memento**: Stores originator's state (opaque to caretaker)
3. **Caretaker**: Manages mementos, triggers save/restore

### Q4: How does Memento preserve encapsulation?
**A**:
- Memento stores private state
- Only Originator can access memento internals (inner class, package-private)
- Caretaker sees memento as opaque token
- Client can't inspect or modify memento

### Q5: Memento vs Command for undo?
**A**:
| Aspect | Memento | Command |
|--------|---------|---------|
| **Mechanism** | Save entire state | Reverse operation |
| **Complexity** | Simpler | More complex |
| **Memory** | Can be expensive | Usually lighter |
| **Redo** | Requires forward history | Built-in |
| **Best for** | Complex state | Discrete operations |

### Q6: What are the disadvantages?
**A**:
1. **Memory**: Large state = expensive snapshots
2. **Performance**: Creating snapshots can be slow
3. **Cloning**: Need deep copies for mutable objects
4. **Versioning**: Hard if Originator changes structure

### Q7: How to optimize memory usage?
**A**:
1. **Incremental**: Store only changes (delta)
2. **Compression**: Compress large snapshots
3. **Limit history**: Keep only N recent mementos
4. **Lazy copy**: Copy-on-write for large data
5. **Serialization**: Serialize to disk for old snapshots

### Q8: Can Memento be serialized?
**A**: Yes, if you need to persist snapshots:
```java
class Memento implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String state;
}
```

### Q9: What if Originator structure changes?
**A**: Versioning strategies:
1. Include version number in Memento
2. Handle missing fields with defaults
3. Migrate old mementos to new format
4. Use flexible serialization (JSON, Protocol Buffers)

### Q10: Real-world examples?
**A**:
- **Ctrl+Z (Undo)**: Text editors, graphics software
- **Browser Back**: Page navigation history
- **Game Save**: Checkpoints, save files
- **Database Transactions**: Savepoints, rollback

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Save and restore object state |
| **Encapsulation** | Memento opaque to caretaker |
| **Immutability** | Mementos should be immutable |
| **Caretaker** | Manages mementos, doesn't inspect them |
| **vs Command** | Memento = state; Command = operation |
| **Trade-off** | Simplicity vs memory usage |

## 🔍 Quick Checklist

When implementing Memento pattern:
- [ ] Originator has save() and restore() methods
- [ ] Memento is immutable (final fields)
- [ ] Memento internals private (inner class or package-private)
- [ ] Caretaker stores mementos without inspecting
- [ ] Deep copy mutable objects in memento
- [ ] Consider memory optimization for large state
- [ ] Handle serialization if persisting mementos
- [ ] Version mementos if originator structure changes
- [ ] Don't expose memento internals to client
- [ ] Consider using Command pattern if operations are discrete

## 📊 Pattern Template

```java
// 1. Originator
public class Originator {
    private State state;

    public Memento save() {
        return new Memento(state);
    }

    public void restore(Memento memento) {
        this.state = memento.state;
    }

    // Inner class - opaque to client
    public static class Memento {
        private final State state;

        private Memento(State state) {
            this.state = state;  // Deep copy if mutable
        }
    }
}

// 2. Caretaker
public class Caretaker {
    private Stack<Originator.Memento> history = new Stack<>();

    public void save(Originator originator) {
        history.push(originator.save());
    }

    public void undo(Originator originator) {
        if (!history.isEmpty()) {
            originator.restore(history.pop());
        }
    }
}

// 3. Usage
Originator obj = new Originator();
Caretaker caretaker = new Caretaker();

obj.setState(state1);
caretaker.save(obj);  // Save checkpoint

obj.setState(state2);  // Make changes

caretaker.undo(obj);  // Restore to checkpoint
```

## 💡 Remember
> "Memento is like taking a photo: you capture the exact state at a moment in time, and can look back at it later without changing the original moment."

## 🔧 Advanced: Redo Support

```java
class EditorHistory {
    private Stack<Memento> undoStack = new Stack<>();
    private Stack<Memento> redoStack = new Stack<>();

    public void save(TextEditor editor) {
        undoStack.push(editor.save());
        redoStack.clear();  // Clear redo after new change
    }

    public void undo(TextEditor editor) {
        if (!undoStack.isEmpty()) {
            Memento current = editor.save();
            redoStack.push(current);
            editor.restore(undoStack.pop());
        }
    }

    public void redo(TextEditor editor) {
        if (!redoStack.isEmpty()) {
            Memento current = editor.save();
            undoStack.push(current);
            editor.restore(redoStack.pop());
        }
    }
}
```

---

**For Amazon Interviews**: Focus on **encapsulation preservation** (why), **opaque snapshots** (how), **undo/redo** implementation, and **memory optimization** strategies. Be ready to compare with Command pattern and discuss real-world applications like text editors or game saves.
