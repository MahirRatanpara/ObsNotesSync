# Mediator Pattern

## Definition
Defines an object that encapsulates how a set of objects interact. Mediator promotes loose coupling by keeping objects from referring to each other explicitly.

## Problem Solved
- Reduces chaotic dependencies between communicating objects
- Prevents many-to-many relationships that become hard to maintain
- Centralizes complex communications and control logic in one place

## Key Components
1. **Mediator Interface**: Defines communication interface
2. **Concrete Mediator**: Implements coordination logic, knows all colleagues
3. **Colleague Classes**: Communicate via mediator instead of directly

## Benefits
- **Reduces coupling**: Objects don't reference each other directly
- **Centralizes control**: All communication logic in one place
- **Simplifies object protocols**: One-to-many relationships instead of many-to-many
- **Easier maintenance**: Changes to interaction logic localized to mediator
- **Reusable components**: Colleagues can be reused independently

## When to Use
- Set of objects communicate in complex but well-defined ways
- Reusing objects is difficult due to many dependencies
- Behavior distributed among classes should be customizable without subclassing
- Too many subclasses needed to customize behavior

## Common Mistakes
- ❌ Colleagues communicating directly with each other
- ❌ Mediator becoming a "God Object" with too much responsibility
- ❌ Not validating recipient existence before routing messages
- ❌ Forgetting to register colleagues with mediator

## Interview Q&A

**Q: Mediator vs Observer pattern?**
A: Observer is one-to-many (subject notifies observers). Mediator reduces many-to-many to one-to-many (colleagues communicate through mediator). Observer focuses on notification, Mediator on coordinating behavior.

**Q: Mediator vs Facade pattern?**
A: Facade provides simplified interface to subsystem (one-way). Mediator coordinates bidirectional communication between colleagues. Facade hides complexity, Mediator reduces coupling.

**Q: How to prevent mediator from becoming God Object?**
A:
- Keep mediator focused on coordination, not business logic
- Use multiple mediators for different subsystems
- Apply Single Responsibility Principle
- Extract complex logic into separate strategy/command objects

**Q: Real-world examples?**
A:
- Chat applications (chat room coordinates users)
- Air traffic control (tower coordinates planes)
- GUI frameworks (dialog/form coordinates widgets)
- MVC Controller (coordinates model and view)

**Q: Performance concerns?**
A: Mediator can become bottleneck in high-traffic scenarios. Consider:
- Asynchronous message handling
- Message queuing
- Load balancing across multiple mediators
- Caching frequently accessed colleague references

**Q: How does it support Open/Closed Principle?**
A: New colleague types can be added without modifying existing colleagues. Only mediator needs updating, which is acceptable as it's the coordination point.

## Code Highlights (This Implementation)

```java
// Colleagues send messages through mediator, not directly
public void send(String message) {
    mediator.sendMessage(message, this);  // Delegates to mediator
}

// Mediator coordinates and routes messages
public void sendMessage(String message, User sender) {
    System.out.println("[" + sender.getName() + " -> All]: " + message);
    for (User user : users) {
        if (user != sender) {
            user.receive(message, sender);  // Routes to others
        }
    }
}
```

## Quick Revision
- **Intent**: Centralize complex communications
- **Structure**: Mediator + Colleagues
- **Key Benefit**: Reduces coupling between objects
- **Trade-off**: Mediator complexity increases
- **Remember**: Objects talk through mediator, never directly
