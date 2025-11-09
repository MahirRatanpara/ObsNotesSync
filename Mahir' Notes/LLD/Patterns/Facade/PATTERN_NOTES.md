# Facade Pattern

## Overview
The Facade pattern is a structural design pattern that provides a simplified interface to a complex subsystem. It acts as a front-facing interface that makes the subsystem easier to use by hiding its complexity.

**Analogy**: Like a hotel concierge - instead of you dealing with restaurants, transportation, tour guides separately, the concierge provides a simple interface to access all these services. You just tell the concierge what you want, and they handle the complex coordination behind the scenes.

## When to Use

### Use Facade Pattern When:
1. **Complex subsystem with many interdependent classes**
   - Library with dozens of classes and complex interactions
   - Legacy system with complicated APIs
   - External system with intricate workflow

2. **Want to provide a simple interface to clients**
   - 90% of clients only need 10% of functionality
   - Common use cases should be one-liners
   - Hide complexity from beginners, expose details for experts

3. **Want to decouple client code from subsystem**
   - Client shouldn't depend on subsystem's internal structure
   - Can refactor subsystem without affecting clients
   - Can swap subsystem implementations

4. **Need to layer your subsystems**
   - Each layer communicates through facades
   - Reduces dependencies between layers
   - Promotes loose coupling

5. **Multiple entry points creating confusion**
   - Users don't know which class to use first
   - Workflow is non-obvious
   - Need guided "happy path"

### Don't Use When:
- Subsystem is already simple (1-2 classes)
- Clients need fine-grained control
- One-to-one wrapping (use Adapter instead)
- You're just wrapping a single class (not a facade)

## Key Components

```
┌──────────┐
│  Client  │
└────┬─────┘
     │ uses
     ▼
┌──────────────────┐
│     Facade       │ ←─── Simple unified interface
├──────────────────┤
│ +doSomething()   │
└────┬─────────────┘
     │ coordinates
     │
     ├─────────┬──────────┬──────────┐
     ▼         ▼          ▼          ▼
┌────────┐ ┌──────┐ ┌────────┐ ┌────────┐
│Class A │ │Class B│ │Class C │ │Class D │ ←─── Complex subsystem
└────────┘ └───────┘ └────────┘ └────────┘
```

1. **Facade**: Provides simple methods that delegate to subsystem
2. **Subsystem Classes**: Complex classes that do the actual work
3. **Client**: Uses Facade instead of subsystem directly

## Benefits

### 1. **Simplifies Complex Systems**
```java
// Without Facade: Complex workflow
VideoFile file = new VideoFile("video.mp4");
Codec codec = CodecFactory.extract(file);
AudioMixer mixer = new AudioMixer();
VideoConverter converter = new VideoConverter();
BitrateReader reader = new BitrateReader(file.getPath());
Buffer buffer = reader.read();
VideoResult result = converter.convert(buffer, codec);
mixer.mix(result.getAudio());
// ... many more steps

// With Facade: One line
VideoConverter facade = new VideoConverter();
facade.convertVideo("video.mp4", "mp4");
```

### 2. **Reduces Dependencies**
```java
// Client depends only on Facade
// Not on VideoFile, Codec, AudioMixer, etc.
// Can refactor subsystem without breaking client
```

### 3. **Improves Readability**
```java
// Clear intent
orderFacade.placeOrder(items, payment, shipping);

// vs obscure subsystem calls
inventory.reserve(items);
payment.authorize(payment);
shipping.schedule(shipping);
order.create(items, payment, shipping);
```

### 4. **Provides Layered Architecture**
```java
// Each layer has a facade
Controller → ServiceFacade → RepositoryFacade → Database
// Reduces coupling between layers
```

### 5. **Easier Testing**
```java
// Mock the facade instead of entire subsystem
@Mock
OrderFacade orderFacade;

// vs mocking 10+ subsystem classes
```

## Implementation Example

### Scenario: Home Theater System

```java
// Complex Subsystem Classes
class Amplifier {
    public void on() {
        System.out.println("Amplifier on");
    }
    public void off() {
        System.out.println("Amplifier off");
    }
    public void setVolume(int level) {
        System.out.println("Setting volume to " + level);
    }
    public void setSurroundSound() {
        System.out.println("Surround sound on");
    }
}

class DVDPlayer {
    private String movie;

    public void on() {
        System.out.println("DVD Player on");
    }
    public void off() {
        System.out.println("DVD Player off");
    }
    public void play(String movie) {
        this.movie = movie;
        System.out.println("Playing: " + movie);
    }
    public void stop() {
        System.out.println("Stopping: " + movie);
    }
    public void eject() {
        System.out.println("Ejecting disc");
    }
}

class Projector {
    public void on() {
        System.out.println("Projector on");
    }
    public void off() {
        System.out.println("Projector off");
    }
    public void wideScreenMode() {
        System.out.println("Projector in widescreen mode");
    }
}

class Lights {
    public void dim(int level) {
        System.out.println("Dimming lights to " + level + "%");
    }
    public void on() {
        System.out.println("Lights on");
    }
}

class Screen {
    public void down() {
        System.out.println("Screen coming down");
    }
    public void up() {
        System.out.println("Screen going up");
    }
}

// Facade - Simplifies the subsystem
class HomeTheaterFacade {
    private Amplifier amp;
    private DVDPlayer dvd;
    private Projector projector;
    private Lights lights;
    private Screen screen;

    public HomeTheaterFacade(Amplifier amp, DVDPlayer dvd,
                             Projector projector, Lights lights,
                             Screen screen) {
        this.amp = amp;
        this.dvd = dvd;
        this.projector = projector;
        this.lights = lights;
        this.screen = screen;
    }

    // Simple interface for complex operation
    public void watchMovie(String movie) {
        System.out.println("\n=== Get ready to watch a movie ===");
        lights.dim(10);
        screen.down();
        projector.on();
        projector.wideScreenMode();
        amp.on();
        amp.setSurroundSound();
        amp.setVolume(50);
        dvd.on();
        dvd.play(movie);
    }

    public void endMovie() {
        System.out.println("\n=== Shutting down theater ===");
        dvd.stop();
        dvd.eject();
        dvd.off();
        amp.off();
        projector.off();
        screen.up();
        lights.on();
    }
}

// Client Code
public class Main {
    public static void main(String[] args) {
        // Setup subsystem components
        Amplifier amp = new Amplifier();
        DVDPlayer dvd = new DVDPlayer();
        Projector projector = new Projector();
        Lights lights = new Lights();
        Screen screen = new Screen();

        // Create facade
        HomeTheaterFacade theater = new HomeTheaterFacade(
            amp, dvd, projector, lights, screen
        );

        // Simple client usage
        theater.watchMovie("Inception");
        // ... enjoy movie ...
        theater.endMovie();
    }
}
```

**Output:**
```
=== Get ready to watch a movie ===
Dimming lights to 10%
Screen coming down
Projector on
Projector in widescreen mode
Amplifier on
Surround sound on
Setting volume to 50
DVD Player on
Playing: Inception

=== Shutting down theater ===
Stopping: Inception
Ejecting disc
DVD Player off
Amplifier off
Projector off
Screen going up
Lights on
```

## Real-World Use Cases

### 1. **Video/Audio Processing**
```java
// Complex: Codecs, formats, compression, audio mixing
VideoConverter converter = new VideoConverter();
converter.convert("input.avi", "output.mp4");
```

### 2. **E-commerce Order Processing**
```java
// Coordinates: Inventory, Payment, Shipping, Notification
OrderFacade facade = new OrderFacade();
facade.placeOrder(cart, payment, shippingAddress);
```

### 3. **Database Access**
```java
// Hides: Connection pooling, transactions, caching, queries
DatabaseFacade db = new DatabaseFacade();
User user = db.findUserById(123);
```

### 4. **Framework Initialization**
```java
// Spring Boot auto-configuration
@SpringBootApplication // Facade for complex setup
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### 5. **Cloud Service APIs**
```java
// AWS SDK facades simplify complex service interactions
S3Client s3 = S3Client.create(); // Facade
s3.putObject(request); // Simple call, complex implementation
```

### 6. **Compiler/Interpreter**
```java
// Compiler facade coordinates: Lexer, Parser, Optimizer, Code Generator
Compiler compiler = new Compiler();
compiler.compile("source.java", "output.class");
```

## Comparison with Other Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Facade** | Simplify complex subsystem | Works with multiple classes |
| **Adapter** | Make incompatible interfaces work | Converts one interface to another |
| **Proxy** | Control access to object | Same interface, adds control |
| **Decorator** | Add responsibilities | Same interface, enhances behavior |
| **Mediator** | Reduce coupling between objects | Coordinates object communication |

### Facade vs Adapter

**Facade:**
```java
// Simplifies MANY classes
class OrderFacade {
    // Coordinates inventory, payment, shipping, etc.
}
```

**Adapter:**
```java
// Converts ONE interface to another
class StripeAdapter implements PaymentProcessor {
    // Wraps StripePay
}
```

### Facade vs Mediator

**Facade:**
- One-way communication (Client → Facade → Subsystem)
- Subsystem doesn't know about facade
- Simplification is the goal

**Mediator:**
- Two-way communication (Objects ↔ Mediator ↔ Objects)
- Objects know about mediator
- Decoupling is the goal

## Common Pitfalls

### 1. **God Object Anti-Pattern**
```java
// Bad: Facade doing everything
class SystemFacade {
    void processOrder() { }
    void generateReport() { }
    void sendEmail() { }
    void backupDatabase() { }
    void analyzeMetrics() { }
    // Too many unrelated responsibilities!
}

// Good: Focused facades
class OrderFacade { void processOrder() { } }
class ReportFacade { void generateReport() { } }
class EmailFacade { void sendEmail() { } }
```

### 2. **Facade with Business Logic**
```java
// Bad: Facade contains business logic
class OrderFacade {
    void placeOrder(Order order) {
        if (order.total() > 1000) { // Business logic!
            applyDiscount(order, 0.1);
        }
        // Delegate to subsystem
    }
}

// Good: Facade only coordinates
class OrderFacade {
    void placeOrder(Order order) {
        orderService.process(order); // Service has business logic
        inventory.reserve(order.items());
        payment.charge(order.payment());
    }
}
```

### 3. **Leaky Abstraction**
```java
// Bad: Exposing subsystem details
class VideoFacade {
    // Returns subsystem type!
    public CodecResult convert(String file) { }
}

// Good: Facade types only
class VideoFacade {
    public boolean convert(String input, String output) { }
}
```

### 4. **Not Allowing Advanced Usage**
```java
// Bad: Can't access subsystem for advanced needs
class HomeTheater {
    private Amplifier amp; // Private, no getter
    // What if I need custom amp settings?
}

// Good: Provide access when needed
class HomeTheater {
    private Amplifier amp;

    // Simple facade methods for common use
    public void watchMovie(String movie) { }

    // Advanced access when needed
    public Amplifier getAmplifier() { return amp; }
}
```

### 5. **Too Thin Facade**
```java
// Bad: Just delegation, no simplification
class DatabaseFacade {
    Connection getConnection() {
        return db.getConnection(); // Not simplifying anything
    }
}

// Good: Actually simplifies
class DatabaseFacade {
    User findUserById(int id) {
        // Handles connection, query, mapping, cleanup
    }
}
```

## Design Decisions

### Should Facade Be Stateless or Stateful?

**Stateless (Recommended):**
```java
class OrderFacade {
    private OrderService orderService; // Dependencies
    private PaymentService paymentService;

    // No state, just coordinates
    public void placeOrder(Order order) { }
}
```
- ✅ Thread-safe
- ✅ Can be singleton
- ✅ Easier to test

**Stateful:**
```java
class OrderFacade {
    private Order currentOrder; // State!

    public void setOrder(Order order) { }
    public void processOrder() { }
}
```
- ❌ Not thread-safe
- ❌ Can't be shared
- ❌ Complex lifecycle

### Should Clients Access Subsystem Directly?

**Option 1: Allow Direct Access** (Recommended)
```java
// Facade for simple cases
facade.watchMovie("Inception");

// Direct access for advanced needs
theater.getAmplifier().setVolume(75);
theater.getProjector().set3DMode();
```

**Option 2: Only Through Facade**
```java
// Force all access through facade
// Good for encapsulation, bad for flexibility
```

**Best Practice**: Provide facade for common cases, allow direct access for advanced scenarios.

### How Many Methods Should Facade Have?

**Guidelines:**
- Group related operations into semantic methods
- One method per common workflow
- Don't expose all subsystem methods
- Typical: 5-15 methods

```java
// Good balance
class OrderFacade {
    void placeOrder(Order order);
    void cancelOrder(String orderId);
    OrderStatus getOrderStatus(String orderId);
    List<Order> getUserOrders(String userId);
}
```

## Interview Questions to Expect

### 1. **What is the Facade pattern?**
**Answer**: A structural pattern that provides a simplified interface to a complex subsystem. It hides complexity and makes the subsystem easier to use.

### 2. **When would you use Facade?**
**Answer**:
- Complex subsystem with many interdependent classes
- Want to provide simple interface for common use cases
- Need to decouple client from subsystem implementation
- Want to layer your application

### 3. **Facade vs Adapter?**
**Answer**:
- **Facade**: Simplifies interface to multiple classes
- **Adapter**: Converts one interface to another (typically one class)
- Facade is about simplification, Adapter is about compatibility

### 4. **Does Facade violate Single Responsibility Principle?**
**Answer**: Not if designed correctly. Facade's single responsibility is to **coordinate** the subsystem. It doesn't contain business logic, just delegates to subsystem classes.

### 5. **Can you bypass the Facade?**
**Answer**: Yes, typically. Facade doesn't enforce encapsulation - clients can access subsystem directly if needed for advanced use cases. This provides both simplicity and flexibility.

### 6. **Real-world example?**
**Answer**: Spring Boot's `@SpringBootApplication` annotation is a facade that simplifies complex framework initialization. Instead of manually configuring dozens of components, one annotation does it all.

### 7. **What's the difference between Facade and Proxy?**
**Answer**:
- **Facade**: Works with multiple objects, simplifies interface
- **Proxy**: Works with one object, same interface, adds control
- Facade changes the interface, Proxy keeps it the same

### 8. **How do you prevent Facade from becoming a God Object?**
**Answer**:
- Keep facades focused on one subsystem
- Create multiple facades for different subsystems
- Facades only coordinate, don't contain business logic
- Follow Single Responsibility Principle

## Advantages vs Disadvantages

### Advantages
- ✅ Simplifies complex subsystems
- ✅ Reduces dependencies
- ✅ Improves code readability
- ✅ Promotes loose coupling
- ✅ Easy to use for common cases
- ✅ Hides implementation details
- ✅ Easier to test (mock facade)

### Disadvantages
- ❌ Can become a God Object if not careful
- ❌ Additional layer (slight performance overhead)
- ❌ May limit access to advanced features
- ❌ Can hide too much complexity
- ❌ Need to maintain facade as subsystem evolves

## Key Takeaways

1. **Purpose**: Provide simple interface to complex subsystem
2. **When**: Complex subsystem, need simplification, want loose coupling
3. **How**: Create class that delegates to subsystem classes
4. **Remember**: Facade coordinates, doesn't contain business logic
5. **Trade-off**: Simplicity vs flexibility

## Summary

The Facade pattern is ideal when:
- ✅ You have a complex subsystem
- ✅ Most clients need only basic functionality
- ✅ You want to hide implementation details
- ✅ You want to reduce dependencies

Remember: Facade is about **simplification**. It provides an easy interface for common tasks while still allowing direct subsystem access for advanced needs. Don't confuse it with Adapter (compatibility) or Proxy (control).

## Pattern Checklist

When implementing Facade:
- [ ] Identify complex subsystem
- [ ] Determine common use cases
- [ ] Create facade class
- [ ] Facade methods coordinate subsystem calls
- [ ] Facade doesn't contain business logic
- [ ] Consider allowing direct subsystem access
- [ ] Keep facade focused (avoid God Object)
- [ ] Make facade stateless if possible
- [ ] Provide semantic, use-case-oriented methods
- [ ] Document what facade simplifies
