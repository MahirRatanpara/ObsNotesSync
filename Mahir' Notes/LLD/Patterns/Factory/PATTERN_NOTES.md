# Factory Method Pattern

## Overview
The Factory Method pattern is a creational design pattern that provides an interface for creating objects in a superclass, but allows subclasses to alter the type of objects that will be created. It defines an interface for creating an object, but lets subclasses decide which class to instantiate.

**Analogy**: Like a logistics company - a RoadLogistics company creates Trucks, while a SeaLogistics company creates Ships. Both follow the same delivery interface, but the type of transport created depends on the specific logistics subclass.

## When to Use

### Use Factory Method When:
1. **Don't know exact types at compile time**
   - Type depends on user input, configuration, or runtime conditions
   - Need to decide which class to instantiate dynamically
   - Type varies based on context

2. **Want to provide extension points**
   - Framework defines how objects are created
   - Users of framework provide concrete implementations
   - Open for extension, closed for modification

3. **Want to delegate instantiation to subclasses**
   - Superclass doesn't know which concrete class to create
   - Each subclass creates appropriate type
   - Encapsulates object creation

4. **Reusing existing objects instead of creating new ones**
   - Object pool pattern
   - Caching mechanism
   - Resource management

5. **Centralizing object creation logic**
   - Single place for creation logic
   - Easier to modify creation process
   - Consistent object initialization

### Don't Use When:
- Object creation is simple (just `new ClassName()`)
- Only one concrete class exists
- No variation in object creation
- Adding unnecessary abstraction

## Key Components

```
┌────────────────┐
│    Creator     │ ←─── Abstract creator
├────────────────┤
│ +factoryMethod()│ ←─── Abstract factory method
│ +someOperation()│
└───────┬────────┘
        │
   ┌────┴─────┐
   │          │
┌──▼────────┐ ┌▼──────────┐
│Concrete   │ │Concrete   │ ←─── Concrete creators
│Creator A  │ │Creator B  │
├───────────┤ ├───────────┤
│+factory() │ │+factory() │
└─────┬─────┘ └─────┬─────┘
      │             │
   Creates       Creates
      │             │
┌─────▼────┐  ┌────▼─────┐
│Product A │  │Product B │ ←─── Concrete products
└──────────┘  └──────────┘
      │             │
      └──────┬──────┘
             │
        ┌────▼────┐
        │ Product │ ←─── Product interface
        └─────────┘
```

1. **Product**: Interface for objects factory method creates
2. **ConcreteProduct**: Specific implementations of Product
3. **Creator**: Declares factory method returning Product
4. **ConcreteCreator**: Overrides factory method to return specific ConcreteProduct

## Benefits

### 1. **Loose Coupling**
```java
// Client code depends on interface, not concrete class
Logistics logistics = getLogistics(); // Could be Road or Sea
Transport transport = logistics.createTransport();
transport.deliver(); // Works with any transport type
```

### 2. **Single Responsibility Principle**
```java
// Creation logic separated from business logic
class RoadLogistics {
    Transport createTransport() {
        // Creation logic here
    }

    void planDelivery() {
        // Business logic here
    }
}
```

### 3. **Open/Closed Principle**
```java
// Add new product types without modifying existing code
class AirLogistics extends Logistics {
    Transport createTransport() {
        return new Plane(); // New type, no existing code changed
    }
}
```

### 4. **Encapsulation of Creation**
```java
// Hide complex creation logic
Transport createTransport() {
    Transport truck = new Truck();
    truck.setCapacity(1000);
    truck.setFuelType(DIESEL);
    truck.initialize();
    return truck; // Complex creation hidden
}
```

## Implementation Example

### Scenario: Logistics Management System

```java
// Product Interface
interface Transport {
    void deliver();
}

// Concrete Products
class Truck implements Transport {
    @Override
    public void deliver() {
        System.out.println("Delivery by truck on road");
    }
}

class Ship implements Transport {
    @Override
    public void deliver() {
        System.out.println("Delivery by ship on sea");
    }
}

class Plane implements Transport {
    @Override
    public void deliver() {
        System.out.println("Delivery by plane in air");
    }
}

// Creator (Abstract)
abstract class Logistics {
    // Factory Method (abstract)
    public abstract Transport createTransport();

    // Template method using factory method
    public void planDelivery() {
        // Business logic that uses the product
        Transport transport = createTransport();
        System.out.println("Planning delivery...");
        transport.deliver();
        System.out.println("Delivery completed!");
    }
}

// Concrete Creators
class RoadLogistics extends Logistics {
    @Override
    public Transport createTransport() {
        return new Truck();
    }
}

class SeaLogistics extends Logistics {
    @Override
    public Transport createTransport() {
        return new Ship();
    }
}

class AirLogistics extends Logistics {
    @Override
    public Transport createTransport() {
        return new Plane();
    }
}

// Client Code
public class Main {
    public static void main(String[] args) {
        // Configuration determines which logistics to use
        String deliveryType = "SEA"; // Could come from config, user input, etc.

        Logistics logistics;
        if (deliveryType.equals("ROAD")) {
            logistics = new RoadLogistics();
        } else if (deliveryType.equals("SEA")) {
            logistics = new SeaLogistics();
        } else {
            logistics = new AirLogistics();
        }

        // Client code works with any logistics type
        logistics.planDelivery();
    }
}
```

## Variations

### 1. Simple Factory (Not Factory Method, but related)

```java
// Not a design pattern, but a programming idiom
class TransportFactory {
    public static Transport createTransport(String type) {
        switch (type) {
            case "truck": return new Truck();
            case "ship": return new Ship();
            case "plane": return new Plane();
            default: throw new IllegalArgumentException();
        }
    }
}

// Usage
Transport transport = TransportFactory.createTransport("truck");
```

**Differences from Factory Method:**
- No inheritance/polymorphism
- Static method
- Simple if/switch logic
- Less flexible, but simpler

### 2. Parameterized Factory Method

```java
abstract class Logistics {
    public abstract Transport createTransport(String type);
}

class ModernLogistics extends Logistics {
    public Transport createTransport(String type) {
        if (type.equals("urgent")) {
            return new Plane();
        } else {
            return new Truck();
        }
    }
}
```

### 3. Factory Method with Object Pool

```java
class ConnectionFactory {
    private Queue<Connection> pool = new LinkedList<>();

    public Connection createConnection() {
        if (!pool.isEmpty()) {
            return pool.poll(); // Reuse existing
        }
        return new DatabaseConnection(); // Create new
    }

    public void releaseConnection(Connection conn) {
        pool.offer(conn); // Return to pool
    }
}
```

## Real-World Use Cases

### 1. **UI Frameworks**
```java
// Different dialogs for different OSs
abstract class Dialog {
    abstract Button createButton();

    void render() {
        Button button = createButton();
        button.render();
    }
}

class WindowsDialog extends Dialog {
    Button createButton() { return new WindowsButton(); }
}

class MacDialog extends Dialog {
    Button createButton() { return new MacButton(); }
}
```

### 2. **Document Generators**
```java
abstract class DocumentCreator {
    abstract Document createDocument();

    void exportDocument() {
        Document doc = createDocument();
        doc.export();
    }
}

class PDFCreator extends DocumentCreator {
    Document createDocument() { return new PDFDocument(); }
}

class HTMLCreator extends DocumentCreator {
    Document createDocument() { return new HTMLDocument(); }
}
```

### 3. **Database Connections (JDBC)**
```java
// DriverManager.getConnection() uses factory pattern
Connection conn = DriverManager.getConnection(url);
// Actual connection type depends on driver (MySQL, PostgreSQL, etc.)
```

### 4. **Spring Framework**
```java
// BeanFactory creates beans
ApplicationContext context = new ClassPathXmlApplicationContext("beans.xml");
MyBean bean = context.getBean(MyBean.class);
```

### 5. **Game Development**
```java
abstract class Level {
    abstract Enemy createEnemy();

    void spawnEnemies() {
        Enemy enemy = createEnemy();
        enemy.spawn();
    }
}

class EasyLevel extends Level {
    Enemy createEnemy() { return new WeakEnemy(); }
}

class HardLevel extends Level {
    Enemy createEnemy() { return new StrongEnemy(); }
}
```

## Comparison with Other Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Factory Method** | Create one product type via inheritance | Subclasses decide what to create |
| **Abstract Factory** | Create families of related products | Multiple related products |
| **Builder** | Construct complex object step-by-step | Focuses on construction process |
| **Prototype** | Clone existing objects | Creates by copying |
| **Simple Factory** | Create objects via static method | Not polymorphic, simpler |

### Factory Method vs Abstract Factory

**Factory Method:**
```java
// ONE product type
abstract class Creator {
    abstract Product createProduct();
}
```

**Abstract Factory:**
```java
// MULTIPLE related products
interface Factory {
    ProductA createProductA();
    ProductB createProductB();
}
```

### Factory Method vs Simple Factory

**Simple Factory:**
```java
// Static method, no inheritance
class Factory {
    static Product create(String type) { }
}
```

**Factory Method:**
```java
// Polymorphic, uses inheritance
abstract class Creator {
    abstract Product create();
}
class ConcreteCreator extends Creator { }
```

## Common Pitfalls

### 1. **Overusing Factory Method**
```java
// Bad: Unnecessary abstraction
abstract class StringCreator {
    abstract String createString();
}
// Just use: String s = "hello";
```

### 2. **Tight Coupling in Creator**
```java
// Bad: Creator depends on all concrete products
class LogisticsFactory {
    Transport create(String type) {
        if (type.equals("truck")) return new Truck(); // Knows Truck
        if (type.equals("ship")) return new Ship();   // Knows Ship
        // Adding new type requires modifying this class!
    }
}

// Good: Use polymorphism
abstract class Logistics {
    abstract Transport create(); // Doesn't know concrete types
}
```

### 3. **Factory Method Doing Too Much**
```java
// Bad: Factory has business logic
Transport createTransport() {
    Transport truck = new Truck();
    truck.deliver(); // Business logic!
    truck.sendNotification();
    return truck;
}

// Good: Factory only creates
Transport createTransport() {
    return new Truck();
}
```

### 4. **Not Validating Parameters**
```java
// Bad: No validation
Transport create(String type) {
    return new Truck(); // Ignores type!
}

// Good: Validate and handle
Transport create(String type) {
    if (type == null || type.isEmpty()) {
        throw new IllegalArgumentException("Type required");
    }
    // Create based on type
}
```

### 5. **Forgetting to Make Factory Method Abstract**
```java
// Bad: Concrete method in abstract creator
abstract class Creator {
    public Product create() {
        return new DefaultProduct(); // Default implementation
    }
}
// Subclasses might forget to override!

// Good: Force override
abstract class Creator {
    public abstract Product create(); // Must override
}
```

## Design Decisions

### Where Should Factory Method Be?

**Option 1: Abstract Class (Template Method Pattern)**
```java
abstract class Logistics {
    abstract Transport createTransport();

    void planDelivery() {
        Transport t = createTransport(); // Uses factory method
        t.deliver();
    }
}
```
- ✅ Factory method used in template method
- ✅ More structure

**Option 2: Interface**
```java
interface LogisticsFactory {
    Transport createTransport();
}
```
- ✅ More flexible
- ✅ Doesn't force inheritance hierarchy

### Should Factory Return Interface or Abstract Class?

**Best Practice**: Return interface or abstract class, not concrete class
```java
// Good
public Transport createTransport() { return new Truck(); }

// Bad
public Truck createTransport() { return new Truck(); }
// Defeats the purpose of polymorphism!
```

### Static Factory Method vs Instance Factory Method?

**Static (Simple Factory):**
```java
static Transport createTransport(String type) { }
```
- ✅ Simple, easy to use
- ❌ Not polymorphic
- ❌ Can't be overridden

**Instance (Factory Method):**
```java
abstract Transport createTransport();
```
- ✅ Polymorphic
- ✅ Can be overridden
- ✅ More flexible

## Interview Questions to Expect

### 1. **What is the Factory Method pattern?**
**Answer**: A creational pattern that defines an interface for creating objects but lets subclasses decide which class to instantiate. It delegates the instantiation to subclasses.

### 2. **When would you use Factory Method?**
**Answer**:
- Don't know exact object type at compile time
- Want to provide extension points for object creation
- Need to delegate creation to subclasses
- Want to centralize creation logic

### 3. **Factory Method vs Simple Factory?**
**Answer**:
- **Simple Factory**: Static method with if/switch logic, not polymorphic
- **Factory Method**: Abstract method overridden by subclasses, polymorphic
- Factory Method is more flexible but more complex

### 4. **Factory Method vs Abstract Factory?**
**Answer**:
- **Factory Method**: Creates one product type
- **Abstract Factory**: Creates families of related products
- Factory Method uses inheritance, Abstract Factory uses composition

### 5. **What are the benefits?**
**Answer**:
- Loose coupling (depend on interfaces)
- Single Responsibility (creation separate from use)
- Open/Closed (add new types without modifying existing code)
- Encapsulation of creation logic

### 6. **Real-world example?**
**Answer**:
- JDBC `DriverManager.getConnection()` - returns Connection interface, but actual type depends on driver
- Java Collections `ArrayList.iterator()` - returns Iterator, but specific type varies

### 7. **What's the main disadvantage?**
**Answer**: Can lead to many subclasses (one for each product type). May be overkill for simple creation. Consider using Simple Factory for straightforward cases.

### 8. **How does it support Open/Closed Principle?**
**Answer**: Can add new product types by creating new subclasses without modifying existing creator code. Existing code remains closed to modification, open to extension.

## Code Smells to Watch For

### Smell: Creating Multiple Related Objects
```java
// Hint: Use Abstract Factory instead
class Factory {
    Button createButton() { }
    Checkbox createCheckbox() { }
    TextField createTextField() { }
}
```

### Smell: Complex Creation Logic
```java
// Hint: Use Builder instead
Product create() {
    Product p = new Product();
    p.setField1(...);
    p.setField2(...);
    // ... 20 more setters
    return p;
}
```

### Smell: Cloning Existing Objects
```java
// Hint: Use Prototype instead
Product create() {
    return existingProduct.clone();
}
```

## Advantages vs Disadvantages

### Advantages
- ✅ Loose coupling
- ✅ Single Responsibility Principle
- ✅ Open/Closed Principle
- ✅ Encapsulates creation
- ✅ Flexibility in object creation
- ✅ Easy to extend with new types

### Disadvantages
- ❌ Can lead to many subclasses
- ❌ Increased complexity
- ❌ May be overkill for simple cases
- ❌ Requires inheritance hierarchy

## Key Takeaways

1. **Purpose**: Delegate object creation to subclasses
2. **When**: Unknown types at compile time, need extension points
3. **How**: Abstract method in creator, overridden by concrete creators
4. **Remember**: One product type, use inheritance
5. **Trade-off**: Flexibility vs complexity

## Summary

The Factory Method pattern is ideal when:
- ✅ Object type determined at runtime
- ✅ Want to provide extension points
- ✅ Need to decouple creation from use
- ✅ Creating one type of product (not families)

Remember: Factory Method uses **inheritance** to delegate creation to subclasses. If you need to create **families** of related products, use Abstract Factory instead. If creation is simple, consider Simple Factory or just using `new`.

## Pattern Checklist

When implementing Factory Method:
- [ ] Define Product interface
- [ ] Create ConcreteProduct classes
- [ ] Define Creator with abstract factory method
- [ ] Create ConcreteCreator classes
- [ ] Each ConcreteCreator returns appropriate ConcreteProduct
- [ ] Creator can have template methods using factory method
- [ ] Factory method returns Product interface
- [ ] Client code uses Creator and Product interfaces only
- [ ] Consider if Simple Factory would be sufficient
- [ ] Don't put business logic in factory method
