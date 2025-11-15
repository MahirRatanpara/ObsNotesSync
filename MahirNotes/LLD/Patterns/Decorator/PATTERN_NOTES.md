# Decorator Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Add responsibilities to objects dynamically by wrapping them in decorator objects, without modifying the original class.

## 📖 The Problem
**Without Decorator**: Need classes for every combination
- `EspressoWithMilk`, `EspressoWithSugar`, `EspressoWithMilkAndSugar`, `EspressoWithMilkAndSugarAndWhippedCream`...
- 3 beverages × 4 add-ons = potentially dozens of classes!

**With Decorator**: Mix and match at runtime
- 3 base beverages + 4 decorators = 7 classes
- Infinite combinations possible!

## 🔑 Key Concept
```
Decorator wraps object → adds behavior → delegates to wrapped object
```

**Structure**: `Caramel(Milk(Sugar(Espresso())))`
- Innermost: Base object
- Each layer: Adds its cost and description
- Outermost: Final decorated object

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Add responsibilities dynamically | ✗ Fixed, static behavior |
| ✓ Behavior can be combined/stacked | ✗ Simple inheritance works |
| ✓ Many optional features | ✗ Only one feature to add |
| ✓ Can't use inheritance (final class) | ✗ Performance critical (extra layers) |

## 📐 Structure

```
┌─────────────┐
│  Component  │ ◄─── Abstract base (Beverage)
└──────┬──────┘
       │
   ┌───┴──────────────────┐
   │                      │
┌──▼─────────┐   ┌────────▼────────┐
│  Concrete  │   │   Decorator     │ ◄─── Abstract decorator
│ Component  │   │ (Condiment)     │
└────────────┘   └────────┬────────┘
 (Espresso)              │
 (Tea)              ┌────┴─────┬─────────┐
 (Decaf)            │          │         │
                 ┌──▼──┐   ┌──▼───┐  ┌──▼──┐
                 │Milk │   │Sugar │  │Cream│
                 └─────┘   └──────┘  └─────┘
```

## 💻 Implementation Pattern

### 1. Component (Abstract Base)
```java
public abstract class Beverage {
    public abstract String getDescription();
    public abstract double cost();
}
```

### 2. Concrete Component
```java
public class Espresso extends Beverage {
    public String getDescription() { return "Rich espresso"; }
    public double cost() { return 2.00; }
}
```

### 3. Abstract Decorator
```java
public abstract class CondimentDecorator extends Beverage {
    protected Beverage beverage;  // Wraps a beverage
    public abstract String getDescription();
}
```

### 4. Concrete Decorator
```java
public class Milk extends CondimentDecorator {
    public Milk(Beverage beverage) {
        this.beverage = beverage;
    }

    public String getDescription() {
        return beverage.getDescription() + ", Milk";  // Delegate + add
    }

    public double cost() {
        return beverage.cost() + 0.50;  // Delegate + add
    }
}
```

### 5. Usage
```java
Beverage order = new Espresso();
order = new Milk(order);
order = new Sugar(order);
order = new WhippedCream(order);

System.out.println(order.getDescription());  // Rich espresso, Milk, Sugar, Whipped cream
System.out.println(order.cost());            // 3.40
```

## 🎓 Real-World Examples

| Domain | Example |
|--------|---------|
| **Java I/O** | `BufferedReader(InputStreamReader(FileInputStream))` |
| **UI** | ScrollableWindow(BorderedWindow(BasicWindow)) |
| **Web** | AuthenticationFilter(LoggingFilter(CompressionFilter)) |
| **Coffee Shop** | Caramel(Milk(Espresso)) |

## ⚖️ Decorator vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Decorator** | Add behavior dynamically | Wraps, **same interface** |
| **Adapter** | Change interface | Converts interface |
| **Proxy** | Control access | Same interface, controls access |
| **Strategy** | Choose algorithm | Encapsulates algorithms |
| **Inheritance** | Add behavior statically | Compile-time, not flexible |

### Decorator vs Inheritance
```java
// Inheritance: Fixed at compile time
class MilkEspresso extends Espresso { }  // Can't add sugar later!

// Decorator: Flexible at runtime
Beverage order = new Espresso();
order = new Milk(order);      // Can add
order = new Sugar(order);     // Can add more
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Decorator not abstract
```java
// Wrong: Concrete decorator base class
public class CondimentDecorator extends Beverage {
    // Now you can do: new CondimentDecorator(espresso) - useless!
}

// Right: Abstract
public abstract class CondimentDecorator extends Beverage { }
```

### ❌ Mistake 2: Wrong execution order
```java
// Wrong: Add behavior first, then delegate
public double cost() {
    double extra = 0.50;
    return beverage.cost() + extra;  // OK for cost
}

public String getDescription() {
    System.out.println("With Milk");  // Wrong! Side effect instead of return
    return beverage.getDescription();
}

// Right: Delegate first, then add
public String getDescription() {
    return beverage.getDescription() + ", Milk";
}
```

### ❌ Mistake 3: Not matching component interface
```java
// Wrong: Decorator has different interface
public abstract class CondimentDecorator {  // Doesn't extend Beverage!
    public void add() { }  // Different interface
}

// Right: Same type as component
public abstract class CondimentDecorator extends Beverage { }
```

### ❌ Mistake 4: Forgetting to wrap
```java
// Wrong: Not actually wrapping
public class Milk extends CondimentDecorator {
    public double cost() {
        return 0.50;  // Only decorator cost, lost base!
    }
}

// Right: Delegate + add
public double cost() {
    return beverage.cost() + 0.50;
}
```

## 🎤 Interview Questions & Answers

### Q1: What is the Decorator pattern?
**A**: A structural pattern that adds responsibilities to objects dynamically by wrapping them, without modifying their class. Decorators have the same interface as the objects they wrap.

### Q2: When would you use Decorator?
**A**: When you need to add features to objects dynamically and in any combination, without creating a class for every possible combination. Example: Java I/O streams, UI components with borders/scrollbars.

### Q3: Decorator vs Inheritance?
**A**:
- **Inheritance**: Static, compile-time, rigid (can't change at runtime)
- **Decorator**: Dynamic, runtime, flexible (can add/remove features)
- Decorator favors composition over inheritance

### Q4: What's the key requirement for decorators?
**A**: Decorators must have the **same interface** (extend same base class) as objects they decorate. This allows:
1. Decorators to wrap components
2. Decorators to wrap other decorators
3. Client code to treat both uniformly

### Q5: Can you give a real-world Java example?
**A**: Java I/O streams:
```java
BufferedReader reader = new BufferedReader(
    new InputStreamReader(
        new FileInputStream("file.txt")
    )
);
```
- `FileInputStream`: Base component (read bytes)
- `InputStreamReader`: Decorator (bytes → characters)
- `BufferedReader`: Decorator (adds buffering)

### Q6: How is Decorator different from Adapter?
**A**:
- **Decorator**: Same interface, adds behavior
- **Adapter**: Different interface, converts interface
- Decorator enhances; Adapter translates

### Q7: What are disadvantages of Decorator?
**A**:
- **Complexity**: Many small classes, harder to understand
- **Debugging**: Stack of wrappers hard to debug
- **Performance**: Extra method calls through layers
- **Identity**: `decorated instanceof ConcreteComponent` may fail

### Q8: Can decorators be applied multiple times?
**A**: Yes! That's a key benefit:
```java
Beverage order = new Espresso();
order = new Milk(order);
order = new Milk(order);  // Double milk!
```

### Q9: Why make the decorator base class abstract?
**A**: To prevent direct instantiation. The base decorator doesn't add any behavior itself - only concrete decorators do. Making it abstract enforces this.

### Q10: How do you prevent "decorator explosion"?
**A**:
- Keep decorators focused (single responsibility)
- Use strategy pattern for algorithms
- Consider builder pattern if too many decorators
- Question if you really need all combinations

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Add behavior dynamically without modifying class |
| **Structure** | Wrapping: `Decorator(Decorator(Component))` |
| **Key Rule** | Decorator has **same type** as what it decorates |
| **Delegation** | Decorator delegates to wrapped object + adds behavior |
| **Flexibility** | Can combine decorators in any order, any number |
| **vs Inheritance** | Runtime flexibility vs compile-time rigidity |

## 🔍 Quick Checklist

When implementing Decorator pattern:
- [ ] Component is abstract base class
- [ ] Decorator extends Component (same interface)
- [ ] Decorator is abstract (can't instantiate)
- [ ] Concrete decorators extend Decorator
- [ ] Decorator holds reference to Component
- [ ] Decorator delegates to wrapped object
- [ ] Decorator adds its own behavior after/before delegation
- [ ] Can nest decorators infinitely

## 📊 Pattern Template

```java
// 1. Component
abstract class Component {
    abstract String operation();
}

// 2. Concrete Component
class ConcreteComponent extends Component {
    String operation() { return "Base"; }
}

// 3. Decorator (abstract)
abstract class Decorator extends Component {
    protected Component component;
}

// 4. Concrete Decorator
class ConcreteDecorator extends Decorator {
    ConcreteDecorator(Component c) { component = c; }
    String operation() {
        return component.operation() + " + Decorated";
    }
}

// 5. Usage
Component obj = new ConcreteComponent();
obj = new ConcreteDecorator(obj);
obj.operation();  // "Base + Decorated"
```

## 💡 Remember
> "Decorators wrap objects like Russian nesting dolls, each adding its own behavior while keeping the same interface."

---

**For Amazon Interviews**: Focus on explaining the **why** (avoid class explosion), **how** (wrapping with same interface), and **when** (dynamic behavior combination). Be ready to code it in 10 minutes and discuss Java I/O as a real-world example.
