# Abstract Factory Pattern

## Overview
The Abstract Factory pattern is a creational design pattern that provides an interface for creating families of related or dependent objects without specifying their concrete classes. It's like a factory of factories.

**Analogy**: Think of a furniture store that sells complete furniture sets (Modern, Victorian, Art Deco). You don't buy individual mismatched pieces - you buy a coordinated set where the chair, table, and sofa all match the same style.

## When to Use

### Use Abstract Factory When:
1. **System needs to work with multiple families of related products**
   - UI themes (Dark theme: DarkButton, DarkCheckbox vs Light theme: LightButton, LightCheckbox)
   - Cross-platform UIs (Windows widgets vs Mac widgets vs Linux widgets)
   - Database providers (MySQL connection, MySQL command vs PostgreSQL connection, PostgreSQL command)

2. **You want to enforce consistency across product families**
   - All UI components should match the same theme
   - All database objects should use the same provider
   - All document elements should follow the same format (PDF vs HTML vs Markdown)

3. **You want to provide a library of products without exposing implementation**
   - Client code works with interfaces
   - Concrete implementations are hidden
   - Can swap entire product families easily

4. **Products are designed to work together**
   - Button and Checkbox must be from same UI toolkit
   - Connection and Command must be from same database provider
   - Related objects have dependencies on each other

### Don't Use When:
- You only need to create one type of object (use Factory Method instead)
- Products don't need to be consistent with each other
- Adding new products is more frequent than adding new families (pattern becomes rigid)
- Simple object creation is sufficient

## Key Components

```
┌─────────────────────┐
│  AbstractFactory    │ ←─── Client uses this
├─────────────────────┤
│ +createProductA()   │
│ +createProductB()   │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
┌────▼────┐ ┌───▼─────┐
│Factory1 │ │Factory2 │ ←─── Concrete Factories
├─────────┤ ├─────────┤
│+createA │ │+createA │
│+createB │ │+createB │
└────┬────┘ └────┬────┘
     │           │
     │           │
  Creates     Creates
     │           │
┌────▼───┐   ┌──▼────┐
│ProductA1│  │ProductA2│ ←─── Product families
└─────────┘  └────────┘
┌─────────┐  ┌────────┐
│ProductB1│  │ProductB2│
└─────────┘  └────────┘
```

1. **AbstractFactory**: Interface for creating abstract products
2. **ConcreteFactory**: Implements operations to create concrete products
3. **AbstractProduct**: Interface for type of product objects
4. **ConcreteProduct**: Product objects created by corresponding concrete factory
5. **Client**: Uses only interfaces declared by AbstractFactory and AbstractProduct

## Benefits

### 1. **Consistency Guarantee**
```java
// All components guaranteed to be from same family
UIFactory factory = new DarkThemeFactory();
Button button = factory.createButton();      // DarkButton
Checkbox checkbox = factory.createCheckbox(); // DarkCheckbox
// Both match the dark theme - no mixing!
```

### 2. **Isolation of Concrete Classes**
```java
// Client doesn't know about DarkButton or LightButton
UIFactory factory = getFactory(); // Could be any factory
Button button = factory.createButton(); // Don't know concrete type
button.render(); // Works polymorphically
```

### 3. **Easy Product Family Switching**
```java
// Switch entire family with one line
UIFactory factory = isDarkMode ? new DarkThemeFactory() : new LightThemeFactory();
// All products now from new family
```

### 4. **Single Responsibility Principle**
- Product creation code is isolated in one place
- Each factory responsible for one family

### 5. **Open/Closed Principle**
- Can introduce new product families without changing existing code
- Add new factory without modifying client code

## Implementation Example

### Scenario: Cross-Platform UI Components

```java
// Abstract Products
interface Button {
    void render();
    void onClick();
}

interface Checkbox {
    void render();
    boolean isChecked();
}

// Concrete Products - Windows Family
class WindowsButton implements Button {
    public void render() {
        System.out.println("Rendering Windows-style button");
    }
    public void onClick() {
        System.out.println("Windows button clicked");
    }
}

class WindowsCheckbox implements Checkbox {
    private boolean checked = false;

    public void render() {
        System.out.println("Rendering Windows-style checkbox");
    }
    public boolean isChecked() {
        return checked;
    }
}

// Concrete Products - Mac Family
class MacButton implements Button {
    public void render() {
        System.out.println("Rendering Mac-style button");
    }
    public void onClick() {
        System.out.println("Mac button clicked");
    }
}

class MacCheckbox implements Checkbox {
    private boolean checked = false;

    public void render() {
        System.out.println("Rendering Mac-style checkbox");
    }
    public boolean isChecked() {
        return checked;
    }
}

// Abstract Factory
interface UIFactory {
    Button createButton();
    Checkbox createCheckbox();
}

// Concrete Factories
class WindowsFactory implements UIFactory {
    public Button createButton() {
        return new WindowsButton();
    }
    public Checkbox createCheckbox() {
        return new WindowsCheckbox();
    }
}

class MacFactory implements UIFactory {
    public Button createButton() {
        return new MacButton();
    }
    public Checkbox createCheckbox() {
        return new MacCheckbox();
    }
}

// Client Code
class Application {
    private Button button;
    private Checkbox checkbox;

    public Application(UIFactory factory) {
        button = factory.createButton();
        checkbox = factory.createCheckbox();
    }

    public void render() {
        button.render();
        checkbox.render();
    }
}

// Usage
public class Main {
    public static void main(String[] args) {
        String os = System.getProperty("os.name").toLowerCase();
        UIFactory factory;

        if (os.contains("win")) {
            factory = new WindowsFactory();
        } else if (os.contains("mac")) {
            factory = new MacFactory();
        } else {
            factory = new WindowsFactory(); // Default
        }

        Application app = new Application(factory);
        app.render();
        // All components guaranteed to match the OS style!
    }
}
```

## Real-World Use Cases

### 1. **UI Toolkits / Themes**
```java
// Material Design vs Cupertino (iOS style)
UIFactory factory = new MaterialDesignFactory();
Button button = factory.createButton();
TextField textField = factory.createTextField();
```

### 2. **Database Abstraction Layers**
```java
// ADO.NET, JDBC patterns
DatabaseFactory factory = new MySQLFactory();
Connection conn = factory.createConnection();
Command cmd = factory.createCommand();
```

### 3. **Game Development**
```java
// Different difficulty levels with matching enemies and obstacles
GameFactory factory = difficulty == HARD
    ? new HardModeFactory()
    : new EasyModeFactory();
Enemy enemy = factory.createEnemy();
Obstacle obstacle = factory.createObstacle();
```

### 4. **Document Generators**
```java
// Generate documents in different formats
DocumentFactory factory = new PDFFactory();
Header header = factory.createHeader();
Body body = factory.createBody();
Footer footer = factory.createFooter();
```

### 5. **Operating System Abstraction**
```java
// Cross-platform file system operations
OSFactory factory = new LinuxFactory();
FileSystem fs = factory.createFileSystem();
ProcessManager pm = factory.createProcessManager();
```

## Comparison with Other Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Abstract Factory** | Create families of related objects | Multiple related products |
| **Factory Method** | Create single product | One product type at a time |
| **Builder** | Construct complex object step-by-step | Focuses on construction process |
| **Prototype** | Clone existing objects | Creates by copying |

### Abstract Factory vs Factory Method

**Factory Method:**
```java
// Creates ONE type of product
abstract class Dialog {
    abstract Button createButton(); // Only buttons
}
```

**Abstract Factory:**
```java
// Creates FAMILY of related products
interface UIFactory {
    Button createButton();    // Multiple
    Checkbox createCheckbox(); // related
    TextField createTextField(); // products
}
```

### When to Use Which?

- **Factory Method**: When you need one product, with possible subclass variations
- **Abstract Factory**: When you need multiple related products that must work together

## Common Pitfalls

### 1. **Adding New Products is Difficult**
```java
// Problem: Want to add ScrollBar
interface UIFactory {
    Button createButton();
    Checkbox createCheckbox();
    // Need to add this to interface = changes ALL factories!
    ScrollBar createScrollBar(); // ❌ Breaks all existing factories
}
```

**Solution**: Plan your product families carefully upfront, or use extension interfaces

### 2. **Over-Engineering for Simple Cases**
```java
// Don't use Abstract Factory for this:
interface AnimalFactory {
    Animal createAnimal(); // Only ONE product? Use Factory Method!
}
```

### 3. **Not Making Factory Creation Strategy Clear**
```java
// Bad: Magic decision making
UIFactory factory = SomeComplexLogic.getFactory();

// Good: Clear strategy
UIFactory factory = config.isDarkMode()
    ? new DarkThemeFactory()
    : new LightThemeFactory();
```

### 4. **Mixing Product Families**
```java
// Bad: Defeats the purpose!
Button button = windowsFactory.createButton();
Checkbox checkbox = macFactory.createCheckbox(); // Inconsistent!

// Good: Use same factory
UIFactory factory = new WindowsFactory();
Button button = factory.createButton();
Checkbox checkbox = factory.createCheckbox();
```

### 5. **Forgetting to Handle Default Cases**
```java
// Bad: What if OS is unknown?
UIFactory factory;
if (os.contains("win")) factory = new WindowsFactory();
else if (os.contains("mac")) factory = new MacFactory();
// factory might be uninitialized!

// Good: Always have a default
UIFactory factory = new WindowsFactory(); // Default
if (os.contains("mac")) factory = new MacFactory();
```

## Design Decisions

### How to Choose Factory at Runtime?

**Option 1: Configuration-Based**
```java
String theme = config.getTheme();
UIFactory factory = switch(theme) {
    case "dark" -> new DarkThemeFactory();
    case "light" -> new LightThemeFactory();
    default -> new LightThemeFactory();
};
```

**Option 2: Environment-Based**
```java
String os = System.getProperty("os.name");
UIFactory factory = os.contains("windows")
    ? new WindowsFactory()
    : new MacFactory();
```

**Option 3: Dependency Injection**
```java
@Configuration
public class FactoryConfig {
    @Bean
    public UIFactory uiFactory() {
        return new WindowsFactory();
    }
}
```

### Should Factories be Singletons?

**Yes, if:**
- Factory has no state
- Same factory instance can be reused
- Want to save memory

**No, if:**
- Factory needs configuration per instance
- Factory maintains state
- Need different factory instances with different settings

## Interview Questions to Expect

### 1. **What is the Abstract Factory pattern?**
**Answer**: A creational pattern that provides an interface for creating families of related/dependent objects without specifying their concrete classes. It ensures products from the same family are used together.

### 2. **Abstract Factory vs Factory Method?**
**Answer**:
- **Abstract Factory**: Creates multiple related products (families)
- **Factory Method**: Creates one product type
- Abstract Factory uses composition, Factory Method uses inheritance

### 3. **When would you use Abstract Factory?**
**Answer**:
- Multiple product families that must work together
- Need to enforce consistency across related products
- Want to swap entire product families easily
- Example: UI themes, cross-platform components, database providers

### 4. **What's the main disadvantage?**
**Answer**: Adding new products to the family requires changing all factory interfaces and implementations. This violates the Open/Closed Principle for product addition (though it follows it for family addition).

### 5. **How does it support Open/Closed Principle?**
**Answer**:
- **Open**: Can add new product families (new factory) without changing existing code
- **Closed**: Existing factories don't need modification when new family is added
- **But**: Adding new product types requires modifying all factories

### 6. **Real-world example?**
**Answer**: Java's AWT (Abstract Window Toolkit) uses this pattern. Different factories create platform-specific components (Windows, Mac, Linux) but all implement the same interfaces.

### 7. **Can you combine Abstract Factory with other patterns?**
**Answer**: Yes:
- **With Singleton**: Factory instances can be singletons
- **With Factory Method**: Factory methods can be used within abstract factory
- **With Prototype**: Products can be created by cloning prototypes
- **With Builder**: Products can be built using builders

### 8. **How do you add new products without modifying existing factories?**
**Answer**:
- Use default methods in interfaces (Java 8+)
- Create extension interfaces
- Use builder pattern for product configuration
- Accept that some modification is necessary (trade-off)

## Advantages vs Disadvantages

### Advantages
- ✅ Ensures product compatibility
- ✅ Isolates concrete classes
- ✅ Easy to swap product families
- ✅ Promotes consistency
- ✅ Single Responsibility Principle
- ✅ Open/Closed Principle (for families)

### Disadvantages
- ❌ Complexity (many interfaces and classes)
- ❌ Difficult to add new products
- ❌ Violates Open/Closed for product types
- ❌ Can be overkill for simple cases
- ❌ More code to maintain

## Key Takeaways

1. **Purpose**: Create families of related objects that work together
2. **When**: Multiple product types that must be consistent
3. **How**: Abstract factory interface with concrete implementations per family
4. **Remember**: Good for adding families, bad for adding products
5. **Trade-off**: Consistency and flexibility vs complexity and rigidity

## Summary

The Abstract Factory pattern is ideal when:
- ✅ You need multiple related products
- ✅ Products must be consistent (from same family)
- ✅ You want to swap entire product families
- ✅ You want to hide concrete implementations

Remember: Use Abstract Factory when you need **families of related products**. If you only need one product type, use Factory Method instead. If adding new products is more common than adding new families, reconsider this pattern.

## Pattern Checklist

When implementing Abstract Factory:
- [ ] Define abstract product interfaces
- [ ] Create concrete product classes for each family
- [ ] Define abstract factory interface
- [ ] Implement concrete factories for each family
- [ ] Each factory creates products from same family
- [ ] Client code uses only abstract interfaces
- [ ] Factory selection logic is clear
- [ ] Consider using Singleton for factories
- [ ] Plan for product family evolution
