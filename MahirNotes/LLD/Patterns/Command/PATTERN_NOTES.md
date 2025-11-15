# Command Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Encapsulate a request as an object, allowing you to parameterize clients with different requests, queue requests, log requests, and support undo operations.

## 📖 The Problem
**Without Command Pattern**: Tight coupling between invoker and receiver
```java
// Remote directly knows about devices
class RemoteControl {
    private Light light;

    public void button1Pressed() {
        light.turnOn();  // Tight coupling, no undo, can't reassign
    }
}
```

**With Command Pattern**: Decouple with command objects
```java
// Remote only knows about Command interface
class RemoteControl {
    private Command command;

    public void pressButton() {
        command.execute();  // Decoupled, supports undo, flexible
    }
}
```

## 🔑 Key Concept
```
Client → creates Command with Receiver
   ↓
Invoker → stores and calls execute()
   ↓
Command.execute() → delegates to Receiver
   ↓
Receiver → performs actual work
```

**Encapsulation**: Request becomes an object with `execute()` and `undo()` methods

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Need undo/redo functionality | ✗ Simple direct method call is enough |
| ✓ Queue or schedule operations | ✗ No need for operation history |
| ✓ Log operations | ✗ Tight coupling is acceptable |
| ✓ Parameterize objects with actions | ✗ Operations are fixed |
| ✓ Support transactional behavior | ✗ No need for rollback |
| ✓ Macro commands (combine operations) | ✗ Single operation only |

## 📐 Structure

```
   ┌────────┐
   │ Client │ ──creates──┐
   └────────┘            │
                         ▼
              ┌─────────────────┐
              │ConcreteCommand  │
              │ - receiver      │
              └────────┬────────┘
                       │ implements
                       ▼
    ┌──────────┐  ┌─────────┐  ┌──────────┐
    │ Invoker  │─▶│Command  │  │ Receiver │
    │(Remote)  │  │interface│◄─│ (Light)  │
    └──────────┘  └─────────┘  └──────────┘
```

## 💻 Implementation Pattern

### 1. Command Interface
```java
public interface Command {
    void execute();
    void undo();
}
```

### 2. Receiver (Does actual work)
```java
public class Light {
    private String location;
    private boolean isOn;

    public void turnOn() {
        isOn = true;
        System.out.println(location + " light is ON");
    }

    public void turnOff() {
        isOn = false;
        System.out.println(location + " light is OFF");
    }
}
```

### 3. Concrete Command (Encapsulates request)
```java
public class LightOnCommand implements Command {
    private final Light light;  // Reference to receiver

    public LightOnCommand(Light light) {
        this.light = light;
    }

    public void execute() {
        light.turnOn();  // Delegate to receiver
    }

    public void undo() {
        light.turnOff();  // Reverse the action
    }
}
```

### 4. Invoker (Triggers commands)
```java
public class RemoteControl {
    private Command[] commands;
    private Command lastCommand;

    public void setCommand(int slot, Command command) {
        commands[slot] = command;
    }

    public void pressButton(int slot) {
        commands[slot].execute();
        lastCommand = commands[slot];  // For undo
    }

    public void pressUndo() {
        if (lastCommand != null) {
            lastCommand.undo();
        }
    }
}
```

### 5. Client (Assembles everything)
```java
// Create receiver
Light light = new Light("Living Room");

// Create command with receiver
Command lightOn = new LightOnCommand(light);

// Set command on invoker
RemoteControl remote = new RemoteControl();
remote.setCommand(0, lightOn);

// Invoke
remote.pressButton(0);  // Light turns on
remote.pressUndo();     // Light turns off
```

## 🎓 Real-World Examples

| Domain | Invoker | Command | Receiver |
|--------|---------|---------|----------|
| **GUI** | Button | ActionCommand | Window/Panel |
| **Text Editor** | Menu | CopyCommand, PasteCommand | Document |
| **Database** | Transaction Manager | SQLCommand | Database |
| **Remote Control** | Remote | LightOnCommand | Light |
| **Job Queue** | Thread Pool | JobCommand | Worker |
| **Game** | Input Handler | MoveCommand | Player |

### Java Example: Runnable
```java
// Runnable is a Command!
Runnable command = () -> System.out.println("Execute!");
Thread thread = new Thread(command);  // Thread is invoker
thread.start();  // Invoke command
```

## 🔍 Key Participants

1. **Command**: Interface declaring `execute()` and optionally `undo()`
2. **ConcreteCommand**: Implements Command, binds Receiver to action
3. **Receiver**: Knows how to perform the actual work
4. **Invoker**: Asks command to execute, doesn't know about receiver
5. **Client**: Creates command and sets its receiver

## ⚖️ Command Pattern Variations

### 1. Simple Commands (No Undo)
```java
public interface Command {
    void execute();
}
```

### 2. Commands with Undo
```java
public interface Command {
    void execute();
    void undo();
}
```

### 3. Macro Commands
```java
public class MacroCommand implements Command {
    private List<Command> commands;

    public void execute() {
        for (Command cmd : commands) {
            cmd.execute();
        }
    }

    public void undo() {
        // Undo in reverse order
        for (int i = commands.size() - 1; i >= 0; i--) {
            commands.get(i).undo();
        }
    }
}
```

### 4. Command History (Multi-level Undo)
```java
public class CommandHistory {
    private Stack<Command> history = new Stack<>();
    private Stack<Command> redoStack = new Stack<>();

    public void execute(Command cmd) {
        cmd.execute();
        history.push(cmd);
        redoStack.clear();  // Clear redo on new action
    }

    public void undo() {
        if (!history.isEmpty()) {
            Command cmd = history.pop();
            cmd.undo();
            redoStack.push(cmd);
        }
    }

    public void redo() {
        if (!redoStack.isEmpty()) {
            Command cmd = redoStack.pop();
            cmd.execute();
            history.push(cmd);
        }
    }
}
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Receiver without feedback
```java
// Wrong: Silent execution
public void turnOn() {
    isOn = true;  // No output!
}

// Right: Provide feedback
public void turnOn() {
    isOn = true;
    System.out.println(location + " light is ON");
}
```

### ❌ Mistake 2: Command without proper undo
```java
// Wrong: Undo doesn't reverse execute
public class LightOnCommand implements Command {
    public void execute() { light.turnOn(); }
    public void undo() { /* Empty - doesn't reverse! */ }
}

// Right: Undo reverses execute
public void undo() {
    light.turnOff();  // Opposite of turnOn
}
```

### ❌ Mistake 3: Invoker coupled to receiver
```java
// Wrong: Invoker knows about receiver
public void pressButton() {
    light.turnOn();  // Direct coupling!
}

// Right: Invoker only knows Command interface
public void pressButton() {
    command.execute();  // Decoupled
}
```

### ❌ Mistake 4: Not storing state for undo
```java
// Wrong: Can't undo to previous state
public class SetTempCommand implements Command {
    public void execute() {
        thermostat.setTemp(72);
    }

    public void undo() {
        thermostat.setTemp(??);  // What was previous temp?
    }
}

// Right: Store previous state
public class SetTempCommand implements Command {
    private int prevTemp;

    public void execute() {
        prevTemp = thermostat.getTemp();  // Save state
        thermostat.setTemp(72);
    }

    public void undo() {
        thermostat.setTemp(prevTemp);  // Restore state
    }
}
```

### ❌ Mistake 5: Using non-standard naming
```java
// Wrong: Non-Java conventions
private final Light _light;  // C# style

// Right: Java conventions
private final Light light;
```

## 🎤 Interview Questions & Answers

### Q1: What is the Command pattern?
**A**: A behavioral pattern that encapsulates a request as an object, allowing you to parameterize objects with operations, queue operations, log operations, and support undoable operations. It decouples the invoker from the receiver.

### Q2: When would you use Command pattern?
**A**: When you need:
- Undo/redo functionality (text editors, games)
- Operation queuing/scheduling (thread pools, job queues)
- Operation logging (transaction logs)
- Macro commands (combine multiple operations)
- Decouple invoker from receiver

### Q3: What are the key participants?
**A**:
- **Command**: Interface with `execute()` and `undo()`
- **ConcreteCommand**: Binds receiver to action
- **Receiver**: Does the actual work
- **Invoker**: Calls execute(), doesn't know receiver
- **Client**: Creates command and sets receiver

### Q4: How does undo work?
**A**: Each command implements `undo()` that reverses `execute()`. The invoker stores the last executed command and calls its `undo()` when needed. For complex cases, commands may need to store previous state to restore.

### Q5: Command vs Strategy pattern?
**A**:
- **Command**: Encapsulates **requests** (actions), supports undo, queuing
- **Strategy**: Encapsulates **algorithms**, focuses on interchangeable behaviors

**Command**: "Do this action" (LightOnCommand, SaveCommand)
**Strategy**: "Do it this way" (BubbleSort, QuickSort)

### Q6: What's a macro command?
**A**: A command that contains multiple commands and executes them sequentially. Example:
```java
MacroCommand partyMode = new MacroCommand(
    Arrays.asList(lightOn, musicOn, dimLights)
);
partyMode.execute();  // Executes all three
partyMode.undo();     // Undoes all three in reverse order
```

### Q7: How do you implement multi-level undo?
**A**: Use two stacks:
- **History stack**: Stores executed commands
- **Redo stack**: Stores undone commands
- Execute pushes to history, clears redo
- Undo pops from history, pushes to redo
- Redo pops from redo, pushes to history

### Q8: Can commands be queued?
**A**: Yes! Commands are objects, so they can be:
- Added to a queue for sequential execution
- Stored in a list for batch processing
- Saved to disk for later execution
- Sent over network to remote systems

### Q9: Real-world Java example?
**A**: `java.lang.Runnable` interface:
```java
Runnable command = () -> System.out.println("Work!");
ExecutorService invoker = Executors.newFixedThreadPool(5);
invoker.submit(command);  // Queue command for execution
```

### Q10: What are disadvantages?
**A**:
- **More classes**: Each operation needs a command class
- **Complexity**: Extra layer of indirection
- **Memory**: Storing command history for undo
- **Overhead**: Simple operations may not need full pattern

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Encapsulate requests as objects |
| **Key Benefit** | Decouple invoker from receiver, support undo |
| **Structure** | Command → execute() → Receiver |
| **Undo** | Each command knows how to reverse itself |
| **Macro** | Command containing multiple commands |
| **Participants** | Client, Invoker, Command, Receiver |
| **Flexibility** | Queue, log, schedule, undo operations |

## 🔍 Quick Checklist

When implementing Command pattern:
- [ ] Command interface with `execute()` and `undo()`
- [ ] Concrete commands hold reference to receiver
- [ ] Commands delegate to receiver methods
- [ ] Receiver provides feedback (print/log actions)
- [ ] Undo reverses execute (opposite action or restore state)
- [ ] Invoker stores last command for undo
- [ ] Invoker doesn't know about receiver types
- [ ] Client creates command with receiver
- [ ] Use standard Java naming (no underscore prefix)

## 📊 Pattern Template

```java
// 1. Command Interface
interface Command {
    void execute();
    void undo();
}

// 2. Receiver
class Receiver {
    void action() {
        System.out.println("Action performed");
    }
}

// 3. Concrete Command
class ConcreteCommand implements Command {
    private Receiver receiver;

    ConcreteCommand(Receiver receiver) {
        this.receiver = receiver;
    }

    public void execute() {
        receiver.action();
    }

    public void undo() {
        // Reverse action
    }
}

// 4. Invoker
class Invoker {
    private Command command;
    private Command lastCommand;

    void setCommand(Command cmd) {
        this.command = cmd;
    }

    void invoke() {
        command.execute();
        lastCommand = command;
    }

    void undo() {
        if (lastCommand != null) {
            lastCommand.undo();
        }
    }
}

// 5. Client
Receiver receiver = new Receiver();
Command command = new ConcreteCommand(receiver);
Invoker invoker = new Invoker();
invoker.setCommand(command);
invoker.invoke();  // Execute
invoker.undo();    // Undo
```

## 🔄 Command vs Similar Patterns

| Aspect | Command | Strategy | Chain of Responsibility |
|--------|---------|----------|-------------------------|
| **Intent** | Encapsulate request | Encapsulate algorithm | Pass request along chain |
| **Focus** | What to do | How to do | Who handles it |
| **Undo** | Supported | Not applicable | Not applicable |
| **Receiver** | Command knows receiver | Strategy doesn't have receiver | Handler is receiver |
| **Example** | SaveCommand | QuickSort | ApprovalChain |

## 💡 Pro Tips

### 1. Null Object Pattern for NoCommand
```java
public class NoCommand implements Command {
    public void execute() { /* Do nothing */ }
    public void undo() { /* Do nothing */ }
}

// Initialize remote with NoCommand
for (int i = 0; i < slots; i++) {
    commands[i] = new NoCommand();  // No null checks needed
}
```

### 2. Command with Result
```java
public interface Command<T> {
    T execute();
    void undo();
}

public class GetTemperatureCommand implements Command<Integer> {
    public Integer execute() {
        return thermostat.getTemperature();
    }
}
```

### 3. Transactional Commands
```java
public class TransactionCommand implements Command {
    private List<Command> commands;
    private List<Command> executed = new ArrayList<>();

    public void execute() {
        try {
            for (Command cmd : commands) {
                cmd.execute();
                executed.add(cmd);
            }
        } catch (Exception e) {
            // Rollback executed commands
            for (int i = executed.size() - 1; i >= 0; i--) {
                executed.get(i).undo();
            }
            throw e;
        }
    }
}
```

## 💡 Remember
> "Command pattern turns requests into objects, giving you superpowers: you can queue them, log them, undo them, and pass them around like any other object."

---

**For Amazon Interviews**:
- Focus on **encapsulation** (request as object)
- Explain **decoupling** (invoker doesn't know receiver)
- Demonstrate **undo** mechanism (reverse action or restore state)
- Be ready to code in 10 minutes
- Mention real examples: Runnable, GUI actions, text editor undo
- Understand variations: macro commands, command history, transactions
