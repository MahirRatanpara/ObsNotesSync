# Memento

## Why It Matters

The pattern for snapshot-and-restore without breaking encapsulation — the standard partner to Command for undo.

## Core Idea

Capture an object's internal state in an opaque object, so it can be restored later **without exposing the object's internals**.

```java
class Editor {
    private String content; private int cursorPosition;

    public Memento save() { return new Memento(content, cursorPosition); }

    public void restore(Memento m) {
        this.content = m.content;
        this.cursorPosition = m.cursorPosition;
    }

    // Nested and private — only Editor can read its fields
    public static final class Memento {
        private final String content; private final int cursorPosition;
        private Memento(String c, int p) { this.content = c; this.cursorPosition = p; }
    }
}
```

**The encapsulation guarantee is the whole point.** The caretaker holds mementos but cannot inspect or alter them. A nested class with private fields achieves this in Java — the outer class can read them, nobody else can.

If your "memento" is just a public DTO with getters, **you have broken the pattern** and exposed internal state. This is the detail interviewers check.

## The Three Roles

| Role | Responsibility |
|---|---|
| **Originator** | Creates and restores from mementos; the only thing that understands the contents |
| **Memento** | Opaque state snapshot |
| **Caretaker** | Stores mementos; never looks inside |

```java
class History {                       // caretaker
    private final Deque<Editor.Memento> stack = new ArrayDeque<>();
    void push(Editor.Memento m) { stack.push(m); }
    Editor.Memento pop() { return stack.pop(); }
}
```

## Memento + Command

Command handles *what happened*; Memento handles *how to get back*.

Use Memento when an operation **cannot be cleanly inverted** — an image filter, a sort, a lossy transform. Instead of writing an inverse, snapshot before and restore after.

```java
class FilterCommand implements Command {
    private Image.Memento before;
    public void execute() { before = image.save(); image.applyFilter(filter); }
    public void undo()    { image.restore(before); }
}
```

**Choosing between inverse-operation and snapshot is the real design decision:**

| | Inverse operation | Memento snapshot |
|---|---|---|
| Memory | **Low** | High — full state per step |
| Implementation | Must derive an inverse | Trivial |
| Works for irreversible ops | No | **Yes** |

## Managing Memory

Full snapshots grow fast. Standard mitigations:

- **Bound the history** (last N states)
- **Incremental mementos** — store only the delta
- **Copy-on-write** — share unchanged structure between snapshots
- **Checkpoints + replay** — snapshot every N operations, replay commands from the nearest one

The checkpoint-plus-replay approach is exactly how database recovery and event sourcing work — worth connecting.

## Deep vs Shallow Snapshots

The same trap as [Prototype](Prototype.md): if the memento stores a reference to a mutable collection, later mutations corrupt the snapshot.

```java
this.items = new ArrayList<>(original.items);   // defensive copy required
```

**Immutable state makes mementos trivially safe** and is the cleanest solution.

## Real Uses

- Editor and IDE undo stacks
- Database transaction rollback and savepoints
- Game save states
- Form wizards with back navigation
- `java.io.Serializable` as a crude memento mechanism
- VM and container snapshots

## When To Use

- Undo/rollback is required
- Operations are hard or impossible to invert
- You need checkpoints in a long process
- State must be captured without exposing internals

## Limitations

- **Memory cost** — the dominant concern
- Snapshot creation can be expensive for large objects
- The caretaker can't easily know a memento's cost
- Java's language support is weak — true opacity relies on nested-class visibility

## Common Questions

- *How does Memento preserve encapsulation?* — the memento is opaque; only the originator can read it. A nested private-field class enforces this.
- *Memento vs Command undo?* — snapshot-and-restore vs inverse operation; use Memento when inversion isn't possible.
- *How do you control memory?* — bounded history, incremental deltas, copy-on-write, checkpoint plus replay.
- *Related large-scale idea?* — event sourcing with periodic snapshots.

## Common Mistakes

- A "memento" with public getters — encapsulation gone
- Storing references to mutable state instead of copies
- Unbounded history
- Snapshotting the entire object when only a small part changes
- Restoring into a *different* originator instance than the one that created it

## Related Topics

- [Command](Command.md)
- [Prototype](Prototype.md)
- [State](State.md)

## Revision Summary

An opaque snapshot that only the originator can interpret, held by a caretaker that cannot inspect it. Partners with Command for undo when operations can't be inverted. Memory is the main constraint — bound the history or use deltas and checkpoints.

## Quick Recall

- Originator, Memento, Caretaker
- Memento must be opaque — nested class, private fields
- Use when the operation can't be inverted
- Deep-copy mutable state, or make it immutable
- Bound history; consider checkpoint + replay
