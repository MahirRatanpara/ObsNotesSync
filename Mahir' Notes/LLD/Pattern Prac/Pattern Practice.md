


# 🧠 Expert-Level Low-Level Design Pattern Practice Questions

  

Each section below contains a **design pattern**, an **expert-level scenario**, and a **practice template** (problem, class scaffolding, hints, and expected output) to help you master the pattern and understand its real-world use.

  

---

  

## 🔒 1. Singleton Pattern (Expert Level)  

### 💡 Use Case: Distributed Logging System with Multi-threading Support and Lazy Initialization

  

### 🧩 Problem Statement  

You're building a distributed microservices platform. Each service logs to a central location, but within each service, all logs must go through a single logging instance (singleton) to ensure thread safety, performance, and consistency.

  

The `Logger` must:

- Be lazily initialized.

- Be thread-safe.

- Support log levels (INFO, WARN, ERROR).

- Maintain a recent in-memory cache of the last 10 log messages (ring buffer).

- Optionally support log forwarding to a centralized system (mock it for now).

  

You must ensure the singleton property holds even under reflection and serialization attacks.

  

### 🧱 Class Scaffolding

```java

public class Logger {

    // private constructor

  

    // getInstance(): static method

  

    // log(level, message): logs to console + stores in in-memory ring buffer

  

    // getRecentLogs(): returns last 10 logs

  

    // Optional: enableCentralForwarding(): mocks sending logs to central system

}

```

  

### 🧵 Concurrency Requirements

- Multiple threads can log concurrently.

- Ring buffer should be synchronized or use a lock-free structure.

- Use `volatile` and `synchronized` or alternatives like `Holder` pattern.

  

### 🧠 Hints

- Use double-checked locking or Bill Pugh’s inner static holder.

- Use `Enum`-based singleton to protect against serialization/reflection.

- Use `LinkedBlockingDeque` or `CircularFifoQueue` from Apache Commons.

- Mock forwarding using a `forwardToCentral(String log)` method (just print to stdout).

  

### ✅ Expected Output (Sample)

```

[INFO] 2025-08-01 10:00:01 - Service started

[WARN] 2025-08-01 10:05:01 - Disk usage 90%

[ERROR] 2025-08-01 10:06:01 - NullPointerException in ModuleX

```

  

### 🧪 Test Scenario

- Spawn 10 threads, each logging 50 messages.

- Validate:

  - Singleton instance is shared.

  - Only one instance is created.

  - Logs are collected safely.

  - Ring buffer holds only last 10 logs.

  - Optional: toggle central forwarding and verify logs are sent.

  

---

  

*More design patterns coming next...*

  

---

  

## 🏭 2. Factory Method (Expert Level)  

### 💡 Use Case: Extensible Notification System with Runtime Plugin Support

  

### 🧩 Problem Statement  

Design a notification system that supports Email, SMS, and Push notifications. The system must:

- Allow new notification types to be plugged in without modifying the existing factory logic.

- Select the appropriate notification sender at runtime using configuration.

- Handle invalid or unsupported types gracefully.

  

You must implement a `NotificationFactory` that delegates creation to appropriate concrete creators and encapsulates object instantiation logic.

  

### 🧱 Class Scaffolding

```java

interface Notification {

    void send(String to, String message);

}

  

class EmailNotification implements Notification { ... }

class SMSNotification implements Notification { ... }

class PushNotification implements Notification { ... }

  

abstract class NotificationCreator {

    public abstract Notification create();

}

  

class EmailNotificationCreator extends NotificationCreator { ... }

// Same for SMS, Push

  

class NotificationFactory {

    public static Notification getNotification(String type) { ... }

}

```

  

### 🧠 Hints

- Use `ServiceLoader` or a registration map for pluggability.

- Apply Open-Closed Principle for new notification types.

- Inject via config/environment properties.

  

### ✅ Expected Output

```

Sending email to foo@bar.com

Sending SMS to +91900000000

Sending push notification to deviceId:xyz

```

  

---

  

## 🏭🏭 3. Abstract Factory (Expert Level)  

### 💡 Use Case: Cross-platform UI Widget Library for Web and Deskto
  

### 🧩 Problem Statement  

Build a cross-platform UI toolkit that can produce families of components (Button, Menu, Checkbox) for different operating systems (e.g., Windows, MacOS, Linux).

  

The client code should remain agnostic to the operating system.

  

### 🧱 Class Scaffolding

```java

interface Button { void render(); }

interface Menu { void show(); }

  

interface UIFactory {

    Button createButton();

    Menu createMenu();

}

  

class WindowsUIFactory implements UIFactory { ... }

class MacOSUIFactory implements UIFactory { ... }

  

class UIClient {

    private UIFactory factory;

    public UIClient(UIFactory factory) { ... }

}

```

  

### 🧠 Hints

- Inject the concrete factory based on OS detection logic.

- Follow Open/Closed Principle for adding new OS support.

  

### ✅ Expected Output

```

Rendering Windows button

Showing Windows menu

Rendering Mac button

Showing Mac menu

```

  

---

  

## 🧱 4. Builder Pattern (Expert Level)  

### 💡 Use Case: Immutable Meal Plan Generator with Fluent API

  

### 🧩 Problem Statement  

Design a `Meal` class that supports the building of complex, immutable objects representing daily meal plans. Use a fluent builder interface to construct combinations.

  

Constraints:

- `Meal` is immutable.

- Support validation (e.g., max 2 desserts, 1 drink).

- Builder should support chaining and enforce valid build sequences.

  

### 🧱 Class Scaffolding

```java

class Meal {

    private final List<String> mainCourse;

    private final String drink;

    private final List<String> desserts;

    // Getters

  

    static class Builder {

        // fluent methods like addMainCourse(), setDrink(), addDessert(), build()

    }

}

```

  

### 🧠 Hints

- Use private constructor in `Meal`.

- Use nested `Builder` class.

- Apply validation logic inside `build()`.

  

### ✅ Expected Output

```

Meal: Pasta, Coke, IceCream, Brownie

```

  

---

  

## 🧬 5. Prototype Pattern (Expert Level)  

### 💡 Use Case: Graphic Editor with Cloneable Shapes and Undo

  

### 🧩 Problem Statement  

You are building a graphics editor. Shapes like `Circle`, `Rectangle`, and `Polygon` must support cloning so users can copy, paste, and undo actions quickly.

  

All shapes should:

- Support deep cloning.

- Be registered and cloned via a shape registry.

- Allow modifying position or color post-cloning without affecting the original.

  

### 🧱 Class Scaffolding

```java

abstract class Shape implements Cloneable {

    int x, y;

    String color;

    public abstract Shape clone();

}

  

class Circle extends Shape { ... }

class Rectangle extends Shape { ... }

  

class ShapeRegistry {

    Map<String, Shape> registry;

    Shape getClone(String type);

}

```

  

### 🧠 Hints

- Use `super.clone()` and deep copy mutable fields.

- Use a registry to avoid repeated instantiations.

  

### ✅ Expected Output

```

Cloned Circle at (0,0)

Original Circle at (10,10)

```

  

---

  

## 🔌 6. Adapter Pattern (Expert Level)  

### 💡 Use Case: Integrating Legacy Payment Gateway with New Interface

  

### 🧩 Problem Statement  

You are replacing your old payment system but need to keep the legacy one functional during the transition. Build an adapter that makes the legacy system conform to the new `PaymentProcessor` interface.

  

The system must:

- Handle currency conversion.

- Translate error codes between the two systems.

- Log compatibility warnings if legacy API is used.

  

### 🧱 Class Scaffolding

```java

interface PaymentProcessor {

    boolean pay(String account, double amount);

}

  

class LegacyPaymentSystem {

    boolean sendMoney(String acc, float amt) { ... }

}

  

class LegacyAdapter implements PaymentProcessor {

    private LegacyPaymentSystem legacy;

    // implements pay()

}

```

  

### 🧠 Hints

- Handle data type conversion carefully.

- Add logging for tracking legacy usage.

- Use adapter wherever PaymentProcessor is required.

  

### ✅ Expected Output

```

[Adapter] Converted $50.00 to ₹4150.00 and processed via legacy

```

  

---

  

*(More patterns will follow in the next step due to space)*  

  

---

  

## 🎨 7. Decorator Pattern (Expert Level)  

### 💡 Use Case: Dynamic Pricing Engine with Pluggable Discounts and Taxes

  

### 🧩 Problem Statement  

You are building a pricing engine for an e-commerce platform. Base products have prices, but discounts and taxes can be dynamically applied.  

Use decorators to add various pricing features like:

- Loyalty discount

- Seasonal discount

- GST/VAT tax

  

Support chaining decorators and log each transformation.

  

### 🧱 Class Scaffolding

```java

interface PriceComponent {

    double getPrice();

    String getBreakdown();

}

  

class BasePrice implements PriceComponent { ... }

  

abstract class PriceDecorator implements PriceComponent { ... }

  

class GSTDecorator extends PriceDecorator { ... }

class LoyaltyDiscountDecorator extends PriceDecorator { ... }

```

  

### 🧠 Hints  

- Decorators wrap and delegate to `PriceComponent`.

- Append to `getBreakdown()` string for log.

- Ensure immutability.

  

### ✅ Expected Output  

```

Base: 100.0 + GST: 18.0 - Loyalty: 10.0 => Final: 108.0

```

  

---

  

## 🧠 8. Strategy Pattern (Expert Level)  

### 💡 Use Case: Pluggable Routing Algorithms for a Map Navigation App

  

### 🧩 Problem Statement  

Design a routing engine where users can switch between routing strategies (ShortestPath, FastestRoute, ScenicRoute).  

Strategies must be dynamically interchangeable during runtime.

  

### 🧱 Class Scaffolding

```java

interface RouteStrategy {

    List<String> computeRoute(String from, String to);

}

  

class ShortestPathStrategy implements RouteStrategy { ... }

class FastestRouteStrategy implements RouteStrategy { ... }

  

class NavigationContext {

    private RouteStrategy strategy;

    void setStrategy(RouteStrategy strategy);

    List<String> navigate(String from, String to);

}

```

  

### 🧠 Hints

- Switch strategies using `setStrategy()`.

- Use dummy route computation for mocking.

  

### ✅ Expected Output

```

Using Shortest Path Strategy: A → B → C

Using Fastest Route Strategy: A → D → C

```

  

---

  

## 👀 9. Observer Pattern (Expert Level)  

### 💡 Use Case: Stock Price Notifier System for Real-Time Subscribers

  

### 🧩 Problem Statement  

Create a real-time stock monitoring system. Users can subscribe to stock tickers and get notified on price changes.

  

- Observers can subscribe/unsubscribe at runtime.

- Avoid memory leaks using weak references or deregistration.

- Support broadcasting updates to all subscribers.

  

### 🧱 Class Scaffolding

```java

interface Observer {

    void update(String stock, double price);

}

  

interface Subject {

    void register(Observer o);

    void unregister(Observer o);

    void notifyObservers(String stock, double price);

}

  

class StockTicker implements Subject { ... }

class InvestorDashboard implements Observer { ... }

```

  

### 🧠 Hints

- Use `CopyOnWriteArrayList` or similar for thread-safe observer list.

- Ensure scalability for 1000s of subscribers.

  

### ✅ Expected Output

```

AAPL price updated to $210.5 → Notified 3 dashboards

```

  

---

  

## 🕹️ 10. Command Pattern (Expert Level)  

### 💡 Use Case: Smart Home Controller with Undo/Redo and Macro Commands

  

### 🧩 Problem Statement  

You are designing a smart home remote that can control appliances like lights, fans, etc. Each command should support execution, undo, and macro commands.

  

- Each button press triggers a command.

- Commands can be batched as a MacroCommand.

- Support undo/redo functionality.

  

### 🧱 Class Scaffolding

```java

interface Command {

    void execute();

    void undo();

}

  

class LightOnCommand implements Command { ... }

class LightOffCommand implements Command { ... }

  

class RemoteControl {

    void setCommand(Command cmd);

    void pressButton();

    void undoButton();

}

```

  

### 🧠 Hints

- Use Stack for undo/redo.

- Composite pattern for MacroCommand.

  

### ✅ Expected Output

```

[Command] Turned Light ON → Undo → Turned Light OFF

```

  

---

  

## 🔗 11. Chain of Responsibility (Expert Level)  

### 💡 Use Case: Customer Support Escalation System

  

### 🧩 Problem Statement  

Design a support system where customer requests are passed through Level1 → Level2 → Manager until someone handles it.

  

- Each handler checks if it can handle the request.

- Passes to next if not applicable.

- Log the handler chain.

  

### 🧱 Class Scaffolding

```java

abstract class SupportHandler {

    protected SupportHandler next;

    void setNext(SupportHandler handler);

    abstract void handle(Request r);

}

  

class Level1Support extends SupportHandler { ... }

class ManagerSupport extends SupportHandler { ... }

```

  

### 🧠 Hints

- Apply chain by linking handlers in order.

- Use request metadata to decide eligibility.

  

### ✅ Expected Output

```

Level1 → Level2 → Manager → [Handled Ticket: Refund for Product X]

```

  

---

  

## 🧪 12. Template Method (Expert Level)  

### 💡 Use Case: ETL Data Pipeline Parser for Multiple File Types

  

### 🧩 Problem Statement  

You are implementing a parser for multiple file types: CSV, JSON, XML. The flow includes: read → parse → validate → transform → load.

  

- Use Template Method in base class.

- Override specific steps in subclasses.

  

### 🧱 Class Scaffolding

```java

abstract class FileParser {

    public final void parseFile(String path) {

        read(path);

        validate();

        transform();

        load();

    }

    protected abstract void read(String path);

    protected abstract void validate();

    protected abstract void transform();

    protected abstract void load();

}

```

  

### ✅ Expected Output

```

Parsing CSV → Validating rows → Loading to DB

```

  

---

  

## 🧿 13. State Pattern (Expert Level)  

### 💡 Use Case: Vending Machine with State Transitions

  

### 🧩 Problem Statement  

Design a vending machine that reacts differently based on internal state: `Idle`, `HasMoney`, `Dispensing`, `OutOfStock`.

  

- All actions are delegated to state objects.

- Support state transitions inside state handlers.

  

### 🧱 Class Scaffolding

```java

interface State {

    void insertCoin();

    void selectProduct(String product);

    void dispense();

}

  

class VendingMachine {

    State currentState;

    void setState(State s);

}

```

  

### ✅ Expected Output

```

Coin inserted → Product selected → Dispensing chocolate

```

  

---

  

## 💬 14. Mediator Pattern (Expert Level)  

### 💡 Use Case: In-App Chat Room Mediator

  

### 🧩 Problem Statement  

Build a chatroom mediator system. Each user sends/receives messages through the chatroom mediator instead of talking to each other directly.

  

- Mediator handles routing.

- Support group and private messages.

  

### 🧱 Class Scaffolding

```java

class ChatRoomMediator {

    void send(String from, String to, String msg);

}

  

class User {

    ChatRoomMediator mediator;

    void send(String to, String msg);

    void receive(String from, String msg);

}

```

  

### ✅ Expected Output

```

[Bob → Alice]: Hi Alice!

```

  

---

  

## 🪶 15. Flyweight Pattern (Expert Level)  

### 💡 Use Case: Character Rendering Engine for Text Editor

  

### 🧩 Problem Statement  

Design a text editor that renders millions of characters efficiently. Characters with same font/size/style must share the same intrinsic object.

  

- Store extrinsic state (position, color) outside the flyweight.

- Maintain a character object pool.

  

### 🧱 Class Scaffolding

```java

class CharacterFlyweight {

    String font;

    int size;

    void render(int x, int y, String color);

}

  

class CharacterFactory {

    Map<String, CharacterFlyweight> cache;

    CharacterFlyweight get(char c, String font, int size);

}

```

  

### ✅ Expected Output

```

Reused flyweight for 'A' 1000 times.

```

  

---

  

# ✅ End of Design Pattern Practice Templates

  

Each example helps you apply the pattern in a realistic scenario while thinking in terms of scalability, extensibility, and performance.