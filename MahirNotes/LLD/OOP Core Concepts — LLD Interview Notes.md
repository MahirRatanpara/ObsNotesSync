
## Section 1: Inheritance vs Composition

### The One-Line Difference

- **Inheritance** = "IS-A" → `Dog extends Animal` (Dog **is an** Animal)
- **Composition** = "HAS-A" → `Car has an Engine` (Car **has an** Engine)

### When Inheritance Actually Appears

Use inheritance when there is a **genuine taxonomic relationship** and the subclass truly is a specialized version of the parent.

```java
// GOOD use of inheritance — genuine IS-A
abstract class Notification {
    String recipient;
    abstract void send();
}

class EmailNotification extends Notification {
    @Override
    void send() { /* send email */ }
}

class SMSNotification extends Notification {
    @Override
    void send() { /* send SMS */ }
}
```

**Why this works:** An EmailNotification genuinely _is_ a Notification. The behavior varies by type, and we want polymorphic dispatch (`notification.send()` without knowing the concrete type).

### When Composition Actually Appears

Use composition when an object **uses** another object's capability, or when behavior needs to be swapped/combined at runtime.

```java
// GOOD use of composition — HAS-A
class NotificationService {
    private final MessageSender sender;      // strategy injected
    private final MessageFormatter formatter; // another capability

    NotificationService(MessageSender sender, MessageFormatter formatter) {
        this.sender = sender;
        this.formatter = formatter;
    }

    void notify(String user, String msg) {
        String formatted = formatter.format(msg);
        sender.send(user, formatted);
    }
}
```

**Why this works:** `NotificationService` doesn't _become_ a sender — it _uses_ one. You can swap `EmailSender` for `SMSSender` without touching the service. You can also combine formatters and senders in any combination.

### The Classic Anti-Pattern — Inheritance Gone Wrong

```java
// BAD — using inheritance for code reuse, not for IS-A
class Stack extends ArrayList {
    // Stack is NOT a list. Users can now call .get(3), .add(1, x),
    // .remove(0) — all operations that violate stack semantics.
}

// GOOD — composition
class Stack<T> {
    private final List<T> elements = new ArrayList<>();

    void push(T item) { elements.add(item); }
    T pop() { return elements.remove(elements.size() - 1); }
    T peek() { return elements.get(elements.size() - 1); }
    // Only stack operations are exposed. Internal list is hidden.
}
```

**Key insight:** Inheritance exposes the parent's entire public API to your users. Composition lets you expose only what makes sense.

### Decision Framework for LLD Interviews

Ask yourself these 3 questions in order:

**Q1: Is the relationship genuinely IS-A, and will it remain so forever?**

- `Dog extends Animal` → Yes, a dog will always be an animal.
- `Stack extends ArrayList` → No, a stack is not a list.

**Q2: Do I need to substitute subtypes polymorphically?**

- If you need `List<Notification>` where each element calls `.send()` differently → inheritance (or interface implementation) is the right fit.

**Q3: Do I need to mix-and-match behaviors or change them at runtime?**

- If yes → composition. Inheritance is compile-time locked. You can't make a `Dog` become a `Cat` at runtime, but you can swap a `MessageSender` strategy from email to SMS.

### The LLD Interview Preference

**Composition is preferred by default.** Interviewers look for:

1. **Strategy Pattern** over deep class hierarchies — inject behavior via interfaces.
2. **Decorator Pattern** over extending classes — wrap objects to add behavior.
3. **Interface-based design** — depend on abstractions, not concrete classes.
4. Inheritance is acceptable for **1 level deep** where IS-A is unambiguous (e.g., abstract base → concrete implementations like the Notification example).

**Red flag for interviewers:** Multi-level inheritance chains like `Vehicle → Car → ElectricCar → TeslaModelS`. This is fragile and nearly always better modeled with composition:

```java
// Instead of deep inheritance:
class Vehicle {
    private final Engine engine;          // gas, electric, hybrid
    private final DriveSystem drive;      // AWD, FWD, RWD
    private final EntertainmentSystem ui; // basic, premium
}
```

### Summary Table

|Aspect|Inheritance|Composition|
|---|---|---|
|Relationship|IS-A|HAS-A|
|Coupling|Tight (child ↔ parent)|Loose (via interfaces)|
|Flexibility|Fixed at compile time|Swappable at runtime|
|Code reuse mechanism|Extend parent class|Delegate to contained object|
|API exposure|All parent methods visible|Only what you explicitly expose|
|When to use|True taxonomies, polymorphism|Behavior composition, strategies|
|LLD interview default|Use sparingly (1 level)|**Preferred approach**|

---

## Section 2: What is Abstraction (and How It Differs from Polymorphism)

### What Abstraction Actually Means

Abstraction is **not** just "creating interfaces." That's the _mechanism_, not the _concept_.

**Abstraction = hiding the "how" and exposing only the "what."**

When you use `list.sort()`, you don't know (or care) whether it uses TimSort, MergeSort, or QuickSort. You only know: "I call sort, my list gets sorted." That hiding of internal complexity is abstraction.

### Three Levels Where Abstraction Operates

**Level 1 — Method-level abstraction (simplest)**

```java
// Without abstraction — caller must know the "how"
connection = DriverManager.getConnection(url);
statement = connection.prepareStatement(sql);
statement.setString(1, userId);
resultSet = statement.executeQuery();
user = mapRow(resultSet);

// With abstraction — caller only knows the "what"
user = userRepository.findById(userId);
```

The method `findById` hides 5 steps behind a single meaningful name. That's abstraction.

**Level 2 — Interface/abstract class abstraction**

```java
interface PaymentProcessor {
    PaymentResult charge(Money amount, PaymentMethod method);
}
```

Any caller using `PaymentProcessor` doesn't know if it's Stripe, Razorpay, or a mock. The interface defines _what_ can be done, hiding _how_ each provider does it.

**Level 3 — Module/system-level abstraction** Your `OrderService` calls `InventoryService.reserve(items)`. It doesn't know if inventory is tracked in PostgreSQL, Redis, or an external warehouse API. The service boundary is the abstraction.

### Abstraction vs Polymorphism — The Actual Difference

They are related but **they answer different questions**:

|Concept|Question it answers|
|---|---|
|Abstraction|_What_ can this thing do? (hide implementation)|
|Polymorphism|_Who_ does the actual work? (choose implementation)|

Think of it as a two-step process:

```
Step 1 — Abstraction:  Define the contract
         interface MessageSender { void send(String msg); }

Step 2 — Polymorphism: Multiple implementations fulfill that contract
         class EmailSender implements MessageSender { ... }
         class SMSSender implements MessageSender { ... }
         class PushSender implements MessageSender { ... }
```

**Abstraction creates the wall** between caller and implementation. **Polymorphism lets different implementations stand behind that wall.**

### Concrete Example Showing Both

```java
// ABSTRACTION: The caller (NotificationService) only sees this contract.
// It has no idea what's behind it.
interface MessageSender {
    void send(String to, String body);
}

// POLYMORPHISM: Multiple types fulfill the same contract.
// The JVM picks the right .send() at runtime based on actual type.
class EmailSender implements MessageSender {
    @Override
    public void send(String to, String body) {
        // SMTP logic
    }
}

class SMSSender implements MessageSender {
    @Override
    public void send(String to, String body) {
        // Twilio API logic
    }
}

// Caller uses ABSTRACTION — doesn't know or care which sender it is.
// JVM uses POLYMORPHISM — dispatches to the correct .send() at runtime.
class NotificationService {
    private final MessageSender sender;

    NotificationService(MessageSender sender) {
        this.sender = sender;
    }

    void notify(String user, String msg) {
        sender.send(user, msg);  // Which send()? Polymorphism decides.
    }
}
```

### Can You Have One Without the Other?

**Abstraction without polymorphism — Yes.**

```java
class MathUtils {
    static double calculateArea(double radius) {
        return Math.PI * radius * radius;
    }
}
// The caller doesn't know the formula. That's abstraction.
// But there's only one implementation. No polymorphism.
```

**Polymorphism without abstraction — Technically yes, but bad design.**

```java
// Method overloading (compile-time polymorphism) with no abstraction
class Printer {
    void print(String s) { System.out.println(s); }
    void print(int n) { System.out.println(n); }
}
// Multiple forms of print(), but nothing is being hidden or contracted.
```

### Quick Mental Model

```
Abstraction  →  "I don't need to know how you do it"
Polymorphism →  "Many can do it, and the right one will be picked"

Abstraction is the WALL.
Polymorphism is MULTIPLE DOORS behind that wall.
```

### Common Interview Misunderstandings

1. **"Abstraction = abstract classes/interfaces"** → No. Those are _tools_ for abstraction. A well-named method hiding complex logic is also abstraction.
    
2. **"Abstraction and encapsulation are the same"** → No. Abstraction hides _complexity_ (what vs how). Encapsulation hides _data_ (private fields, getters). Encapsulation is one way to implement abstraction.
    
3. **"Polymorphism requires interfaces"** → No. Method overriding in concrete classes is also polymorphism. But in good LLD, you almost always use interfaces because that gives you abstraction + polymorphism together.
    

---

## Quick Reference for LLD Interviews

- **Default to composition** over inheritance. Use inheritance only for clear IS-A with 1 level.
- **Program to interfaces** — this gives you abstraction (hide the how) and enables polymorphism (swap implementations).
- **Strategy Pattern** = composition + abstraction + polymorphism working together. It's the interviewer's favorite for a reason.
- When explaining your design, say: _"I'm using an interface here for abstraction — the caller doesn't need to know the implementation. And because multiple classes implement it, I get polymorphism — the right behavior is picked at runtime."_