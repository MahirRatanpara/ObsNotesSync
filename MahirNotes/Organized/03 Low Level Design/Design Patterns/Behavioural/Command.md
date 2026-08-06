# Command

## Why It Matters

The pattern behind undo/redo, task queues, and transactional operations. Any "support undo" or "queue these actions" follow-up is Command.

## Core Idea

Encapsulate a request as an object, so it can be stored, queued, logged, passed around, and reversed.

```java
interface Command {
    void execute();
    void undo();
}

class AddTextCommand implements Command {
    private final Document doc; private final String text; private final int position;

    public void execute() { doc.insert(position, text); }
    public void undo()    { doc.delete(position, text.length()); }   // inverse
}

class CommandHistory {
    private final Deque<Command> undoStack = new ArrayDeque<>();
    private final Deque<Command> redoStack = new ArrayDeque<>();

    void run(Command c) { c.execute(); undoStack.push(c); redoStack.clear(); }
    void undo() { if (!undoStack.isEmpty()) { Command c = undoStack.pop(); c.undo(); redoStack.push(c); } }
    void redo() { if (!redoStack.isEmpty()) { Command c = redoStack.pop(); c.execute(); undoStack.push(c); } }
}
```

**`redoStack.clear()` on a new command is the detail people miss** — once you branch history, the old redo path is invalid.

## The Four Roles

| Role | Responsibility |
|---|---|
| **Command** | The interface (`execute`, optionally `undo`) |
| **Concrete command** | Binds a receiver to an action and its parameters |
| **Receiver** | Does the actual work |
| **Invoker** | Triggers commands, unaware of what they do |

**The invoker's ignorance is the point.** A toolbar button, a keyboard shortcut, and a scheduled job can all invoke the same command without knowing anything about it.

## Undo Strategies

| Strategy | How | Best for |
|---|---|---|
| **Inverse operation** | `undo()` performs the opposite | Cheap, reversible ops |
| **Memento snapshot** | Store state before, restore on undo | Complex or irreversible ops |
| **Command log replay** | Replay from a checkpoint minus the last n | Very large state |

Combining Command with [Memento](Memento.md) is the standard answer when an operation can't be cleanly inverted (e.g. a lossy transform).

## Beyond Undo

| Use | How Command enables it |
|---|---|
| **Task queues** | A command is a serialisable unit of work |
| **Macro commands** | A composite command holding a list |
| **Transactions** | Execute all, or undo executed ones on failure |
| **Retry** | The command object holds everything needed to re-run |
| **Audit log** | Persisted commands are a record of intent |
| **Event sourcing** | Commands produce events; state is the fold over them |

**Macro command:**
```java
class MacroCommand implements Command {
    private final List<Command> commands;
    public void execute() { commands.forEach(Command::execute); }
    public void undo() {
        for (int i = commands.size() - 1; i >= 0; i--) commands.get(i).undo();   // REVERSE order
    }
}
```
**Undo must run in reverse order.** Straightforward but frequently got wrong.

## Real Uses

- `Runnable` and `Callable` — the JDK's Command interface; every `executor.submit(task)` is this pattern
- Swing `Action`
- Text editor and IDE undo stacks
- Database transaction logs
- CQRS command handlers

**`Runnable` is the answer to "where is Command in the JDK?"**

## When To Use

- Undo/redo is required
- Operations must be queued, scheduled, or retried
- You want to decouple the trigger from the work
- Operations need logging or auditing as first-class objects

## Limitations

- A class per operation (lambdas help when undo isn't needed)
- Undo requires either an inverse or stored state — memory grows with history
- Long histories need bounding

## Common Questions

- *How do you implement undo?* — inverse operation, or Memento snapshot when inversion isn't possible.
- *JDK example?* — `Runnable`/`Callable` with executors.
- *How do you undo a macro?* — reverse order.
- *Command vs Strategy?* — Command encapsulates a *request* (with receiver and parameters) to defer or reverse it; Strategy encapsulates an *algorithm* to swap it.

## Common Mistakes

- Not clearing the redo stack on a new command
- Undoing a composite in forward order
- Unbounded history causing memory growth
- Commands holding references to mutable state that changes before undo runs
- Putting business logic in the command instead of the receiver

## Related Topics

- [Memento](Memento.md)
- [Strategy](Strategy.md)
- [Executors and Thread Pools](../../../02%20Java/Concurrency/Executors%20and%20Thread%20Pools.md)

## Revision Summary

Turn a request into an object so it can be queued, logged, retried, and undone. Invoker, command, receiver. Undo via inverse or Memento; composites undo in reverse. `Runnable` is the JDK form.

## Quick Recall

- "undo", "queue", "schedule", "audit" → Command
- Invoker doesn't know what the command does
- Clear the redo stack on a new command
- Macro undo runs in reverse
- `Runnable` / `Callable` in the JDK
