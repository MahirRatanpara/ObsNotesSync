# Prototype Pattern

## Overview
The Prototype pattern is a creational design pattern that allows you to create new objects by copying existing objects (prototypes) rather than creating them from scratch.

## When to Use

### Use Prototype Pattern When:
1. **Object creation is expensive**
   - Complex initialization logic
   - Heavy computations or database queries during construction
   - Loading resources (files, network data, etc.)

2. **You need many similar objects with slight variations**
   - Game enemies with same stats but different positions
   - UI components with similar configurations
   - Document templates

3. **Object construction requires many parameters**
   - Instead of passing 10+ constructor parameters
   - Pre-configure templates and clone them

4. **You want to avoid subclass explosion**
   - Instead of creating a class for every configuration
   - Use prototypes to represent different configurations

5. **Runtime object creation based on dynamic configuration**
   - Don't know exact types at compile time
   - Objects configured at runtime from user input or files

### Don't Use When:
- Object creation is simple and cheap
- Objects have few variations
- Deep copying is complex and error-prone (circular references, etc.)

## Benefits

### 1. **Performance Optimization**
```java
// Expensive way (every time)
Enemy enemy = new Enemy(
    loadHealthFromDB(),           // DB query
    calculateDamage(),             // Complex calculation
    loadWeaponFromFile(),          // File I/O
    parseAIBehavior()              // Parsing logic
);

// Prototype way (initialization once, clone many times)
Enemy clone = registry.spawn("GRUNT", x, y);  // Fast!
```

### 2. **Reduced Code Duplication**
```java
// Before: Repeating initialization everywhere
Enemy grunt1 = new Enemy(100, 15, 10, 20, new Weapon("Rusty Sword", 20), "AGGRESSIVE");
Enemy grunt2 = new Enemy(100, 15, 45, 78, new Weapon("Rusty Sword", 20), "AGGRESSIVE");

// After: Clean and maintainable
Enemy grunt1 = registry.spawn("GRUNT", 10, 20);
Enemy grunt2 = registry.spawn("GRUNT", 45, 78);
```

### 3. **Flexibility**
- Add new prototypes at runtime
- Modify templates without changing code
- Easy to introduce new variations

### 4. **Encapsulation of Complex Creation**
- Hide complex initialization logic
- Client code doesn't need to know object structure
- Centralized template management

### 5. **Avoiding Subclass Explosion**
```java
// Without Prototype: Need separate classes
class GruntEnemy extends Enemy { }
class EliteEnemy extends Enemy { }
class BossEnemy extends Enemy { }

// With Prototype: One class, multiple templates
registry.spawn("GRUNT", x, y);
registry.spawn("ELITE", x, y);
registry.spawn("BOSS", x, y);
```

## Key Implementation Details

### 1. Shallow vs Deep Copy

**Shallow Copy** (Problem):
```java
public Enemy clone() {
    return (Enemy) super.clone();  // Only copies references!
}
// Result: Cloned enemies share the SAME weapon object
```

**Deep Copy** (Solution):
```java
public Enemy clone() {
    Enemy cloned = (Enemy) super.clone();
    cloned.weapon = this.weapon.clone();  // Clone nested objects
    return cloned;
}
// Result: Each enemy has its OWN weapon object
```

### 2. When to Deep Copy
- **Mutable objects**: Always deep copy (Weapon, AI state, etc.)
- **Immutable objects**: Shallow copy is fine (String, Integer, etc.)
- **Collections**: Clone the collection AND its contents if mutable

### 3. Registry Pattern (Common Companion)
```java
// Centralized template storage
EnemyRegistry registry = new EnemyRegistry();
registry.addTemplate("CUSTOM", customEnemy);
Enemy enemy = registry.spawn("CUSTOM", x, y);
```

## Real-World Use Cases

### 1. **Game Development**
- Enemy spawning systems
- Particle effects
- Level objects/prefabs

### 2. **Document Processing**
- Document templates (invoices, reports)
- Email templates
- Form templates

### 3. **UI Frameworks**
- Widget cloning
- Component libraries
- Theme configurations

### 4. **Configuration Management**
- Server configurations
- Database connection pools
- Cache configurations

### 5. **Testing**
- Test data builders
- Mock object creation
- Fixture templates

## Comparison with Other Patterns

| Pattern | Purpose | Use Case |
|---------|---------|----------|
| **Prototype** | Clone existing objects | Complex initialization, need copies |
| **Factory** | Create new objects from scratch | Type-based creation, simple construction |
| **Builder** | Step-by-step construction | Many optional parameters, fluent API |
| **Singleton** | Ensure one instance | Global access, shared state |

## Common Pitfalls

### 1. Forgetting Deep Copy
```java
// Bug: Shared weapon reference
Enemy clone = template.clone();
clone.getWeapon().setDamage(999);  // Also changes template!
```

### 2. Circular References
```java
class Node {
    Node parent;
    List<Node> children;
    // Cloning becomes complex!
}
```

### 3. Not Handling Exceptions
```java
// Bad: Forcing caller to handle
public Enemy clone() throws CloneNotSupportedException

// Better: Wrap in runtime exception
public Enemy clone() {
    try {
        return (Enemy) super.clone();
    } catch (CloneNotSupportedException e) {
        throw new RuntimeException(e);
    }
}
```

### 4. Cloning Singletons
```java
// Don't clone objects that should be unique!
DatabaseConnection clone = connection.clone();  // Bad idea!
```

## Interview Questions to Expect

1. **What's the difference between shallow and deep copy?**
   - Shallow: Copies references, objects share nested objects
   - Deep: Creates new copies of nested objects

2. **Why not just use `new` instead of clone?**
   - Initialization might be expensive
   - Complex setup logic
   - Runtime configuration

3. **How do you handle circular references when cloning?**
   - Track cloned objects in a map
   - Use copy constructor with visited set
   - Consider if cloning is appropriate

4. **Prototype vs Factory?**
   - Prototype: Copy existing configured object
   - Factory: Create new object from scratch

5. **What if cloning fails?**
   - Handle CloneNotSupportedException
   - Consider copy constructor alternative
   - Validate object state after cloning

## Alternative Approaches

### 1. Copy Constructor
```java
public Enemy(Enemy other) {
    this.health = other.health;
    this.weapon = new Weapon(other.weapon);
}
```

### 2. Builder Pattern
```java
Enemy enemy = new EnemyBuilder()
    .withHealth(100)
    .withWeapon(weapon)
    .build();
```

### 3. Factory with Configuration
```java
Enemy enemy = EnemyFactory.create(config);
```

## Summary

The Prototype pattern is ideal when:
- ✅ Object creation is expensive
- ✅ You need many similar objects
- ✅ Configuration is complex
- ✅ Runtime flexibility is needed

Remember: The key value is **avoiding expensive initialization** by cloning pre-configured objects instead of creating from scratch.
