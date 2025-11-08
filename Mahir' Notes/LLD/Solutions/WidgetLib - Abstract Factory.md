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

  


# Abstract Factory Pattern

## Overview
The Abstract Factory pattern provides an interface for creating families of related or dependent objects without specifying their concrete classes. It's a creational design pattern that encapsulates object creation logic and promotes loose coupling.

## Key Components

### 1. Abstract Products
- `Button` - Interface for button components
- `Menu` - Interface for menu components

### 2. Abstract Factory
- `UIFactory` - Interface that declares methods for creating abstract products

### 3. Concrete Factories
- `WindowsUIFactory` - Creates Windows-specific UI components
- `MacOSUIFactory` - Creates macOS-specific UI components

### 4. Factory Provider
- `UIApplicationFactory` - Provides the appropriate factory based on configuration

### 5. Client
- `UIClient` - Uses the abstract factory to create UI components

## Code Structure

```java
// Abstract Products
interface Button { void render(); }
interface Menu { void show(); }

// Abstract Factory
interface UIFactory {
    Button createButton();
    Menu createMenu();
}

// Concrete Factories
class WindowsUIFactory implements UIFactory { ... }
class MacOSUIFactory implements UIFactory { ... }

// Factory Provider
class UIApplicationFactory {
    public static UIFactory getGeneratedUI(String name) { ... }
}

// Client
class UIClient {
    private final UIFactory factory;
    public UIClient(String config) { ... }
}
```

## Benefits

- **Consistency**: Ensures that products from the same family work together
- **Loose Coupling**: Client code is decoupled from concrete product classes
- **Easy Extension**: New product families can be added without changing existing code
- **Single Responsibility**: Each factory is responsible for creating one family of products

## When to Use

- When you need to create families of related objects
- When you want to ensure products from the same family are used together
- When you need to support multiple product lines or platforms
- When you want to hide the creation logic from the client

## Real-World Applications

- **UI Frameworks**: Different look-and-feel implementations (Windows, macOS, Linux)
- **Database Drivers**: Different database implementations (MySQL, PostgreSQL, Oracle)
- **Gaming Engines**: Different platform implementations (PC, Console, Mobile)
- **Document Processing**: Different file format handlers (PDF, Word, Excel)

## Implementation Details

### Factory Selection
```java
UIFactory factory = UIApplicationFactory.getGeneratedUI("Mac");
// or
UIFactory factory = UIApplicationFactory.getGeneratedUI("Windows");
```

### Anonymous Inner Classes
The implementation uses anonymous inner classes for concrete products, which is a lightweight approach for simple implementations.

## Comparison with Related Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Abstract Factory** | Create families of objects | Creates multiple related objects |
| **Factory Method** | Create single objects | Creates one type of object |
| **Builder** | Construct complex objects | Focuses on step-by-step construction |

## Tags
#design-patterns #creational-patterns #factory #abstraction #java #object-creation