# Chain of Responsibility Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Pass a request along a chain of handlers until one handles it, decoupling the sender from receivers.

## 📖 The Problem
**Without Chain of Responsibility**: Client must know all handlers and their conditions
```java
// Tight coupling - client knows entire hierarchy
if (amount <= 1000) {
    teamLead.approve(expense);
} else if (amount <= 5000) {
    manager.approve(expense);
} else if (amount <= 10000) {
    director.approve(expense);
} else {
    ceo.approve(expense);
}
```

**With Chain of Responsibility**: Client just submits to chain
```java
// Client doesn't know who will handle it
chain.handleRequest(expense);
```

## 🔑 Key Concept
```
Client → [Handler1] → [Handler2] → [Handler3] → [Handler4]
              ↓           ↓           ↓           ↓
          Can handle? Can handle? Can handle? Can handle?
              ↓           ↓           ↓           ↓
           Yes/Pass    Yes/Pass    Yes/Pass    Always Yes
```

**Each handler decides**: Handle it OR pass to next

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Multiple handlers for same request | ✗ Single handler is enough |
| ✓ Don't know handler at compile time | ✗ Know exact handler upfront |
| ✓ Handler set can change dynamically | ✗ Fixed handler structure |
| ✓ Want to decouple sender from receiver | ✗ Direct coupling is fine |
| ✓ Request can be handled by multiple objects | ✗ Only one object should handle |

## 📐 Structure

```
         ┌─────────┐
         │ Client  │
         └────┬────┘
              │ sends request
              ▼
       ┌─────────────┐
       │   Handler   │ ◄─── Abstract/Interface
       │ (abstract)  │
       │ - next      │ ◄─── Reference to next handler
       │ + handle()  │
       └──────┬──────┘
              │
     ┌────────┴────────┬─────────────┐
     │                 │             │
┌────▼─────┐   ┌──────▼──┐   ┌──────▼──┐
│ Handler1 │   │Handler2 │   │Handler3 │
│(TeamLead)│   │(Manager)│   │  (CEO)  │
└──────────┘   └─────────┘   └─────────┘
```

## 💻 Implementation Pattern

### 1. Handler (Abstract Base)
```java
public abstract class ExpenseHandler {
    protected ExpenseHandler nextHandler;

    // Set next handler (enables fluent chaining)
    public ExpenseHandler setNext(ExpenseHandler handler) {
        this.nextHandler = handler;
        return this;  // For chaining: h1.setNext(h2).setNext(h3)
    }

    // Each handler implements this
    public abstract void handleRequest(Expense expense);
}
```

### 2. Concrete Handler (Standard Pattern)
```java
public class ManagerHandler extends ExpenseHandler {
    @Override
    public void handleRequest(Expense expense) {
        if (canHandle(expense)) {
            // Handle it
            System.out.println("Manager approved: " + expense);
        } else if (nextHandler != null) {  // Defensive check!
            // Pass to next
            nextHandler.handleRequest(expense);
        } else {
            // End of chain - no one can handle
            System.out.println("No approver for: " + expense);
        }
    }

    private boolean canHandle(Expense expense) {
        return expense.getAmount() <= 5000;
    }
}
```

### 3. Building the Chain
```java
// Create handlers
ExpenseHandler teamLead = new TeamLeadHandler();
ExpenseHandler manager = new ManagerHandler();
ExpenseHandler director = new DirectorHandler();
ExpenseHandler ceo = new CEOHandler();

// Link them
teamLead.setNext(manager)
        .setNext(director)
        .setNext(ceo);

// Or step by step:
teamLead.setNext(manager);
manager.setNext(director);
director.setNext(ceo);

// Client submits to chain head
teamLead.handleRequest(new Expense("Laptops", 4500));
// Output: Manager approved: Laptops - $4500.00
```

### 4. Usage
```java
// Client doesn't know who will approve
ExpenseHandler chain = buildApprovalChain();
chain.handleRequest(expense);  // Automatically routed
```

## 🎓 Real-World Examples

| Domain | Handler Chain | Request |
|--------|---------------|---------|
| **Logging** | DEBUG → INFO → WARN → ERROR | Log message |
| **Event Handling** | Button → Panel → Window → App | Mouse click |
| **Middleware** | Auth → Validation → Rate Limit → Handler | HTTP request |
| **Support System** | L1 Support → L2 Support → Manager → Director | Ticket |
| **Exception Handling** | Specific catch → General catch → finally | Exception |

### Java Example: Exception Handling
```java
try {
    // Code
} catch (FileNotFoundException e) {      // Handler 1
    // Handle specific
} catch (IOException e) {                 // Handler 2
    // Handle general
} catch (Exception e) {                   // Handler 3 (catch-all)
    // Handle any
}
```

## ⚖️ Chain Variations

### 1. Pure Chain (Handle OR Pass)
```java
if (canHandle(request)) {
    handle(request);  // STOP here
} else if (nextHandler != null) {
    nextHandler.handleRequest(request);  // PASS along
}
```
**Use**: Approval workflows, support tickets

### 2. Logging Chain (Handle AND Pass)
```java
// Process it
log(request);

// Always pass to next
if (nextHandler != null) {
    nextHandler.handleRequest(request);
}
```
**Use**: Logging, event broadcasting, middleware

### 3. Filtering Chain (Modify and Pass)
```java
// Modify request
request = transform(request);

// Pass modified request
if (nextHandler != null) {
    nextHandler.handleRequest(request);
}
```
**Use**: Data transformation pipelines, filters

## 🚨 Common Mistakes

### ❌ Mistake 1: No null check before passing
```java
// Wrong: Crashes if next is null
public void handleRequest(Expense expense) {
    if (expense.getAmount() > 1000) {
        nextHandler.handleRequest(expense);  // NullPointerException!
    }
}

// Right: Always check
public void handleRequest(Expense expense) {
    if (expense.getAmount() > 1000) {
        if (nextHandler != null) {  // Defensive check
            nextHandler.handleRequest(expense);
        } else {
            System.out.println("No handler available");
        }
    }
}
```

### ❌ Mistake 2: Missing request details in output
```java
// Wrong: Doesn't show WHAT was approved
System.out.println("Manager approved");

// Right: Show complete information
System.out.println("Manager approved expense: " + expense);
```

### ❌ Mistake 3: Circular chain
```java
// Wrong: Creates infinite loop
handler1.setNext(handler2);
handler2.setNext(handler3);
handler3.setNext(handler1);  // Circular!

// Result: StackOverflowError
```

**Fix**: Track visited handlers or ensure linear chain.

### ❌ Mistake 4: Handler modifying request without copying
```java
// Wrong: Modifies original request
public void handleRequest(Request req) {
    req.amount = req.amount * 1.1;  // Side effect!
    nextHandler.handleRequest(req);
}

// Right: Create new request or document mutation
```

### ❌ Mistake 5: Not returning 'this' from setNext()
```java
// Wrong: Can't chain fluently
public void setNext(Handler h) {
    this.nextHandler = h;
}
// Usage: h1.setNext(h2); h2.setNext(h3);  // Verbose

// Right: Enable fluent chaining
public Handler setNext(Handler h) {
    this.nextHandler = h;
    return this;  // Return this!
}
// Usage: h1.setNext(h2).setNext(h3);  // Fluent!
```

## 🎤 Interview Questions & Answers

### Q1: What is Chain of Responsibility?
**A**: A behavioral pattern that passes a request along a chain of handlers. Each handler decides whether to handle the request or pass it to the next handler. It decouples the sender from receivers.

### Q2: When would you use this pattern?
**A**: When:
- Multiple objects can handle a request, but you don't know which one upfront
- Want to issue request to several objects without specifying receiver explicitly
- Set of handlers should be determined dynamically

Examples: Approval workflows, logging levels, event handling, middleware.

### Q3: What's the key benefit?
**A**: **Decoupling** - the client doesn't need to know:
- Which handler will process the request
- The chain structure
- How many handlers exist

This allows adding/removing handlers without changing client code.

### Q4: Chain of Responsibility vs Strategy?
**A**:
- **Chain**: Multiple handlers in sequence, ONE handles request
- **Strategy**: ONE algorithm selected, directly invoked

**Chain**: `handler1 → handler2 → handler3` (traversal)
**Strategy**: `context.setStrategy(algorithm)` (selection)

### Q5: What happens if no handler can handle the request?
**A**: Three options:
1. **Default handler** at end of chain (like CEO approves everything)
2. **Error handling** - each handler checks `nextHandler != null`
3. **Null Object pattern** - special handler that does nothing

### Q6: Can multiple handlers process the same request?
**A**: Yes! Two variations:
- **Pure Chain**: First handler that CAN handle it, DOES handle it and STOPS
- **Logging Chain**: EVERY handler processes it and passes to next

Example of logging chain:
```java
public void handle(LogRecord record) {
    log(record);  // Always log
    if (next != null) next.handle(record);  // Always pass
}
```

### Q7: How do you prevent circular references?
**A**:
- Design: Ensure linear chain construction
- Runtime check: Track visited handlers in request
- Defensive: Set max chain depth

```java
public void handle(Request req) {
    if (req.depth++ > MAX_DEPTH) {
        throw new IllegalStateException("Circular chain");
    }
    // ... handle logic
}
```

### Q8: What's a real-world Java example?
**A**: **Java Servlet Filters**:
```java
public void doFilter(ServletRequest req, ServletResponse res,
                     FilterChain chain) {
    // Pre-processing
    authenticate(req);

    // Pass to next filter
    chain.doFilter(req, res);

    // Post-processing
    log(res);
}
```

### Q9: Should handlers be immutable?
**A**: Not required, but **next handler should be set only once** (during chain construction). Changing chain at runtime can cause race conditions in concurrent environments.

### Q10: What are disadvantages?
**A**:
- **No guarantee** request will be handled
- **Debugging** can be hard (which handler processed it?)
- **Performance** - traverses entire chain in worst case
- **Complex chains** - hard to understand control flow

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Decouple sender from receiver, dynamic handler selection |
| **Structure** | Handler1 → Handler2 → Handler3... (linked list) |
| **Key Rule** | Each handler: handle OR pass to next |
| **Decision** | Handler decides based on request properties |
| **Null Safety** | Always check `nextHandler != null` before passing |
| **Complete Info** | Print/log full request details, not just handler name |
| **Fluent API** | Return `this` from `setNext()` for chaining |

## 🔍 Quick Checklist

When implementing Chain of Responsibility:
- [ ] Handler is abstract base class
- [ ] Handler has `nextHandler` reference
- [ ] `setNext()` returns `this` (fluent API)
- [ ] Each concrete handler implements `handleRequest()`
- [ ] Handler checks if it CAN handle request
- [ ] If yes: Handle it (show complete info)
- [ ] If no: Check `nextHandler != null` before passing
- [ ] End of chain handled gracefully
- [ ] No circular references in chain
- [ ] Client only knows chain head, not structure

## 📊 Pattern Template

```java
// 1. Handler (Abstract)
abstract class Handler {
    protected Handler next;

    public Handler setNext(Handler h) {
        this.next = h;
        return this;  // Fluent API
    }

    public abstract void handle(Request req);
}

// 2. Concrete Handler
class ConcreteHandler extends Handler {
    public void handle(Request req) {
        if (canHandle(req)) {
            // Process request
            System.out.println("Handled by: " + this);
        } else if (next != null) {
            // Pass to next
            next.handle(req);
        } else {
            // End of chain
            System.out.println("No handler available");
        }
    }

    private boolean canHandle(Request req) {
        return /* condition */;
    }
}

// 3. Client
Handler chain = new Handler1()
    .setNext(new Handler2())
    .setNext(new Handler3());

chain.handle(request);
```

## 🔄 Chain of Responsibility vs Similar Patterns

| Aspect | Chain of Responsibility | Decorator | Strategy |
|--------|------------------------|-----------|----------|
| **Intent** | Pass request until handled | Add behavior | Select algorithm |
| **Structure** | Linear chain | Nested wrappers | Single strategy |
| **Decision** | Handler decides | All apply | Client decides |
| **Processing** | ONE handles | ALL add behavior | ONE executes |
| **Example** | Approval chain | Beverage + condiments | Sort algorithm |

## 💡 Pro Tips

### 1. Builder Pattern for Chain Construction
```java
class ApprovalChainBuilder {
    public ExpenseHandler build() {
        return new TeamLeadHandler()
            .setNext(new ManagerHandler())
            .setNext(new DirectorHandler())
            .setNext(new CEOHandler());
    }
}

// Usage
ExpenseHandler chain = new ApprovalChainBuilder().build();
```

### 2. Logging in Chain
```java
public void handleRequest(Expense expense) {
    System.out.println("[" + getClass().getSimpleName() + "] Received: " + expense);

    if (canHandle(expense)) {
        System.out.println("[" + getClass().getSimpleName() + "] Approved: " + expense);
    } else if (nextHandler != null) {
        System.out.println("[" + getClass().getSimpleName() + "] Passing to next");
        nextHandler.handleRequest(expense);
    }
}
```

### 3. Response Propagation
```java
public Result handleRequest(Request req) {
    if (canHandle(req)) {
        return new Result(true, "Handled by " + this);
    } else if (next != null) {
        return next.handleRequest(req);
    } else {
        return new Result(false, "Not handled");
    }
}
```

## 💡 Remember
> "Chain of Responsibility is like customer support escalation: L1 tries first, if they can't help, escalates to L2, then L3, until someone resolves it or it reaches the end."

---

**For Amazon Interviews**:
- Focus on **decoupling** (sender doesn't know receiver)
- Explain **dynamic chain building** (add/remove handlers)
- Discuss **null safety** (always check before passing)
- Be ready to code in 10 minutes
- Mention servlet filters or logging frameworks as real examples
- Show you understand variations: pure chain vs logging chain
