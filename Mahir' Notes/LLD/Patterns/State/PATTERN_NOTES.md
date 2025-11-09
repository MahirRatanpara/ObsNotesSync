# State Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Allow an object to alter its behavior when its internal state changes, appearing as if the object changed its class.

## 📖 The Problem
**Without State Pattern**: Giant if-else or switch statements
```java
class VendingMachine {
    private String state = "NO_COIN";

    public void insertCoin() {
        if (state.equals("NO_COIN")) {
            state = "HAS_COIN";
        } else if (state.equals("HAS_COIN")) {
            System.out.println("Already has coin");
        } else if (state.equals("SOLD")) {
            System.out.println("Please wait");
        }
    }

    public void selectProduct() {
        if (state.equals("NO_COIN")) {
            System.out.println("Insert coin first");
        } else if (state.equals("HAS_COIN")) {
            state = "SOLD";
            dispense();
        } else if (state.equals("SOLD")) {
            System.out.println("Already sold");
        }
    }
    // ... more methods with same if-else chains
}
```
❌ Repeated conditionals everywhere
❌ Hard to add new states
❌ Difficult to maintain
❌ Violates Open/Closed Principle

**With State Pattern**: Clean, extensible state objects
```java
class VendingMachine {
    private State state = new NoCoinState();

    public void insertCoin() {
        state.insertCoin(this);  // Delegate to current state
    }
}
```
✅ Each state encapsulated in its own class
✅ Easy to add new states
✅ No if-else chains
✅ Follows Open/Closed Principle

## 🔑 Key Concept
```
Context → delegates to → Current State object
State changes → Context switches state objects
```

**Core Idea**: Instead of storing state as data (string/enum) and using conditionals, store state as object and delegate behavior to it.

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Object behavior depends on state | ✗ Only 2-3 simple states |
| ✓ Many conditional statements based on state | ✗ State logic is trivial |
| ✓ State transitions are complex | ✗ States don't have different behavior |
| ✓ Need to add new states frequently | ✗ State-specific code is minimal |

## 📐 Structure

```
┌──────────────┐
│   Context    │ ◄─── Maintains current state
├──────────────┤      Delegates to state object
│ -state: State│
│ +request()   │──────┐
└──────────────┘      │
                      │ delegates to
                      ▼
              ┌───────────────┐
              │     State     │ ◄─── Abstract state
              ├───────────────┤
              │ +handle()     │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼─────┐ ┌─────▼──────┐ ┌───▼────────┐
│ConcreteState│ │ConcreteState│ │ConcreteState│
│     A       │ │     B       │ │     C      │
├─────────────┤ ├────────────┤ ├────────────┤
│ +handle()   │ │ +handle()  │ │ +handle()  │
└─────────────┘ └────────────┘ └────────────┘
```

## 💻 Implementation Pattern

### 1. State Interface
```java
public interface State {
    void insertCoin(VendingMachine machine);
    void ejectCoin(VendingMachine machine);
    void selectProduct(VendingMachine machine);
    void dispense(VendingMachine machine);
}
```

### 2. Context
```java
public class VendingMachine {
    private State noCoinState;
    private State hasCoinState;
    private State soldState;
    private State soldOutState;

    private State currentState;
    private int count;

    public VendingMachine(int count) {
        this.count = count;
        noCoinState = new NoCoinState();
        hasCoinState = new HasCoinState();
        soldState = new SoldState();
        soldOutState = new SoldOutState();

        currentState = (count > 0) ? noCoinState : soldOutState;
    }

    public void insertCoin() {
        currentState.insertCoin(this);
    }

    public void ejectCoin() {
        currentState.ejectCoin(this);
    }

    public void selectProduct() {
        currentState.selectProduct(this);
    }

    public void dispense() {
        currentState.dispense(this);
    }

    // State transitions
    public void setState(State state) {
        this.currentState = state;
    }

    // Getters for states
    public State getNoCoinState() { return noCoinState; }
    public State getHasCoinState() { return hasCoinState; }
    public State getSoldState() { return soldState; }
    public State getSoldOutState() { return soldOutState; }

    public void releaseProduct() {
        if (count > 0) {
            count--;
            System.out.println("Product dispensed");
        }
    }

    public int getCount() { return count; }
}
```

### 3. Concrete States
```java
public class NoCoinState implements State {
    @Override
    public void insertCoin(VendingMachine machine) {
        System.out.println("Coin inserted");
        machine.setState(machine.getHasCoinState());
    }

    @Override
    public void ejectCoin(VendingMachine machine) {
        System.out.println("No coin to eject");
    }

    @Override
    public void selectProduct(VendingMachine machine) {
        System.out.println("Insert coin first");
    }

    @Override
    public void dispense(VendingMachine machine) {
        System.out.println("Pay first");
    }
}

public class HasCoinState implements State {
    @Override
    public void insertCoin(VendingMachine machine) {
        System.out.println("Already has coin");
    }

    @Override
    public void ejectCoin(VendingMachine machine) {
        System.out.println("Coin returned");
        machine.setState(machine.getNoCoinState());
    }

    @Override
    public void selectProduct(VendingMachine machine) {
        System.out.println("Product selected");
        machine.setState(machine.getSoldState());
    }

    @Override
    public void dispense(VendingMachine machine) {
        System.out.println("Select product first");
    }
}

public class SoldState implements State {
    @Override
    public void insertCoin(VendingMachine machine) {
        System.out.println("Please wait, dispensing");
    }

    @Override
    public void ejectCoin(VendingMachine machine) {
        System.out.println("Already dispensing, no refund");
    }

    @Override
    public void selectProduct(VendingMachine machine) {
        System.out.println("Already dispensing");
    }

    @Override
    public void dispense(VendingMachine machine) {
        machine.releaseProduct();
        if (machine.getCount() > 0) {
            machine.setState(machine.getNoCoinState());
        } else {
            System.out.println("Sold out!");
            machine.setState(machine.getSoldOutState());
        }
    }
}

public class SoldOutState implements State {
    @Override
    public void insertCoin(VendingMachine machine) {
        System.out.println("Machine sold out");
    }

    @Override
    public void ejectCoin(VendingMachine machine) {
        System.out.println("No coin inserted");
    }

    @Override
    public void selectProduct(VendingMachine machine) {
        System.out.println("Sold out");
    }

    @Override
    public void dispense(VendingMachine machine) {
        System.out.println("Sold out");
    }
}
```

### 4. Usage
```java
VendingMachine machine = new VendingMachine(2);

machine.insertCoin();      // "Coin inserted"
machine.selectProduct();   // "Product selected"
machine.dispense();        // "Product dispensed"

machine.insertCoin();      // "Coin inserted"
machine.selectProduct();   // "Product selected"
machine.dispense();        // "Product dispensed"
                          // "Sold out!"

machine.insertCoin();      // "Machine sold out"
```

## 🎓 Real-World Examples

| Domain | States | Transitions |
|--------|--------|-------------|
| **TCP Connection** | Listen, Established, Closed | connect() → Established |
| **Document** | Draft, Review, Published | submit() → Review |
| **Order** | Pending, Paid, Shipped, Delivered | pay() → Paid |
| **Media Player** | Playing, Paused, Stopped | play(), pause(), stop() |
| **Traffic Light** | Red, Yellow, Green | timer → next state |

### Order Processing Example
```java
// States: Pending → Paid → Shipped → Delivered

interface OrderState {
    void pay(Order order);
    void ship(Order order);
    void deliver(Order order);
}

class Order {
    private OrderState state = new PendingState();

    public void pay() { state.pay(this); }
    public void ship() { state.ship(this); }
    public void deliver() { state.deliver(this); }
    public void setState(OrderState state) { this.state = state; }
}
```

## ⚖️ State vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **State** | Change behavior based on state | States control transitions |
| **Strategy** | Choose algorithm | Client chooses strategy |
| **Command** | Encapsulate request | Stores operation + undo |
| **Enum** | Fixed set of constants | No behavior, just values |

### State vs Strategy
```java
// Strategy: Client chooses
Context context = new Context();
context.setStrategy(new ConcreteStrategyA());  // Client decides
context.execute();

// State: State controls transitions
VendingMachine machine = new VendingMachine();
machine.insertCoin();  // State internally changes to HasCoinState
```

**Key Difference**:
- **Strategy**: Client explicitly sets strategy
- **State**: State transitions happen internally based on events

## 🚨 Common Mistakes

### ❌ Mistake 1: Using strings/enums instead of objects
```java
// Wrong: String-based state (not State pattern!)
class Order {
    private String state = "PENDING";

    public void pay() {
        if (state.equals("PENDING")) {
            state = "PAID";
        }
    }
}

// Right: Object-based state
class Order {
    private OrderState state = new PendingState();

    public void pay() {
        state.pay(this);  // Delegate to state object
    }
}
```

### ❌ Mistake 2: Context has state logic
```java
// Wrong: Context decides state transitions
public void insertCoin() {
    if (currentState instanceof NoCoinState) {
        currentState = new HasCoinState();  // ❌ Context logic!
    }
}

// Right: State decides transitions
public void insertCoin() {
    currentState.insertCoin(this);  // ✅ State handles it
}
```

### ❌ Mistake 3: Creating new state instances every time
```java
// Wrong: Creates new objects on every transition
machine.setState(new HasCoinState());  // ❌ Wasteful

// Right: Reuse state instances (Flyweight)
private State hasCoinState = new HasCoinState();  // ✅ Singleton-like
machine.setState(hasCoinState);
```

### ❌ Mistake 4: States with mutable data
```java
// Wrong: State has mutable context data
class HasCoinState implements State {
    private int coinValue;  // ❌ State shouldn't store context data
}

// Right: Context stores data, state only has behavior
class VendingMachine {
    private int coinValue;  // ✅ Context stores data
    private State state;
}
```

### ❌ Mistake 5: Too many invalid operation handlers
```java
// Code smell: Every state has lots of "invalid" methods
class SoldState implements State {
    public void insertCoin() { error(); }  // Invalid
    public void ejectCoin() { error(); }   // Invalid
    public void select() { error(); }      // Invalid
    public void dispense() { /* valid */ }
}

// Consider: Narrow interfaces or default implementations
```

## 🎤 Interview Questions & Answers

### Q1: What is the State pattern?
**A**: A behavioral pattern that allows an object to change its behavior when its internal state changes. The object appears to change its class by delegating behavior to state objects.

### Q2: When would you use State?
**A**: When:
1. Object behavior depends on its state
2. Have large conditional statements based on state
3. State transitions are complex
4. Need to add new states without modifying existing code

### Q3: How is State different from Strategy?
**A**:
- **State**: States know about each other and control transitions automatically
- **Strategy**: Strategies are independent, client chooses which to use
- **State**: Internal state management
- **Strategy**: External algorithm selection

### Q4: What are the key components?
**A**:
1. **Context**: Maintains current state, delegates requests
2. **State Interface**: Declares methods for all states
3. **Concrete States**: Implement behavior for each state

### Q5: Who controls state transitions?
**A**: Usually the **state objects themselves**. States know which state should come next and call `context.setState()`. Sometimes the context controls transitions for simple cases.

### Q6: Should state objects be singletons?
**A**: Often yes (Flyweight pattern). If states have no instance-specific data, reuse the same instance for efficiency:
```java
private static final State INSTANCE = new HasCoinState();
```

### Q7: What if states need context data?
**A**: Pass context as parameter:
```java
void handle(Context context) {
    int value = context.getValue();  // Access context data
    context.setState(new NextState());
}
```
Don't store context reference in state (memory leak risk).

### Q8: How do you handle invalid operations?
**A**: Options:
1. Throw exception
2. Ignore silently
3. Log warning
4. Default no-op implementation in base class

### Q9: Real-world example?
**A**:
- **TCP**: Connection states (Listen, SYN_SENT, ESTABLISHED, CLOSE_WAIT, etc.)
- **Workflow**: Document approval (Draft → Review → Approved)
- **Game**: Character states (Idle, Walking, Running, Jumping)

### Q10: Advantages and disadvantages?
**A**:
**Advantages**:
- Eliminates conditional statements
- Easy to add new states
- Single Responsibility (each state is separate)
- Open/Closed Principle

**Disadvantages**:
- More classes
- Can be overkill for simple state machines
- State objects may need context reference

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Encapsulate state-specific behavior |
| **Core Idea** | State as object, not data |
| **Delegation** | Context delegates to current state |
| **Transitions** | Usually managed by state objects |
| **vs Strategy** | State auto-transitions; Strategy client-chosen |
| **Efficiency** | Reuse state instances (Flyweight) |

## 🔍 Quick Checklist

When implementing State pattern:
- [ ] Define State interface with all operations
- [ ] Create ConcreteState class for each state
- [ ] Context maintains current state
- [ ] Context delegates operations to current state
- [ ] States handle transitions by calling `context.setState()`
- [ ] Reuse state instances (don't create new each time)
- [ ] States should be stateless (no instance data)
- [ ] Context provides state access via getters
- [ ] Handle invalid operations gracefully
- [ ] Consider if simple if-else would suffice (don't over-engineer)

## 📊 Pattern Template

```java
// 1. State Interface
interface State {
    void handleA(Context context);
    void handleB(Context context);
}

// 2. Concrete States
class StateA implements State {
    public void handleA(Context context) {
        // StateA logic for operation A
    }

    public void handleB(Context context) {
        // Transition to StateB
        context.setState(context.getStateB());
    }
}

class StateB implements State {
    public void handleA(Context context) {
        // StateB logic for operation A
        context.setState(context.getStateA());
    }

    public void handleB(Context context) {
        // StateB logic for operation B
    }
}

// 3. Context
class Context {
    private State stateA = new StateA();
    private State stateB = new StateB();
    private State currentState = stateA;

    public void operationA() { currentState.handleA(this); }
    public void operationB() { currentState.handleB(this); }

    public void setState(State state) { this.currentState = state; }
    public State getStateA() { return stateA; }
    public State getStateB() { return stateB; }
}

// 4. Usage
Context context = new Context();
context.operationA();  // Handled by StateA
context.operationB();  // Transitions to StateB
context.operationA();  // Handled by StateB, transitions back to StateA
```

## 💡 Remember
> "State pattern is like a person's mood: their behavior (friendly vs grumpy) depends on their current state, and their state changes based on events (good news vs bad news)."

## 🔧 State Transition Diagram

```
    insertCoin()
NoCoin ──────────► HasCoin
  ▲                   │
  │                   │ selectProduct()
  │                   ▼
  │                 Sold
  │                   │
  └───────────────────┘
      dispense()
```

**Flow**:
1. Start in `NoCoin` state
2. `insertCoin()` → transition to `HasCoin`
3. `selectProduct()` → transition to `Sold`
4. `dispense()` → transition back to `NoCoin`

---

**For Amazon Interviews**: Focus on **eliminating conditionals** (why), **state objects** managing transitions (how), and **State vs Strategy** difference. Be ready to model a real system (order processing, connection states) and discuss when State pattern is overkill vs necessary.
