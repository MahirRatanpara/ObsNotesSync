# 10-Minute Design Patterns Quick Revision

**Read this before your interview for instant recall of all 23 GoF patterns!**

---

## 🏗️ CREATIONAL PATTERNS (5) - Object Creation

### 1. SINGLETON
**One-liner**: One instance globally, single point of access
**Code**: `private constructor + static getInstance() + Bill Pugh (inner Holder class)`
**When**: Configuration, Logger, Connection Pool
**Remember**: Bill Pugh > DCL, use `volatile` for DCL

### 2. FACTORY METHOD
**One-liner**: Subclasses decide which class to instantiate
**Code**: `abstract Product create()` in parent, override in children
**When**: Don't know exact type at compile time, framework extension points
**Remember**: Inheritance-based, ONE product type

### 3. ABSTRACT FACTORY
**One-liner**: Create families of related objects without specifying concrete classes
**Code**: Interface with multiple `createX()` methods
**When**: Multiple related products (UI themes: Button + Checkbox + TextField)
**Remember**: Composition-based, MULTIPLE product types

### 4. BUILDER
**One-liner**: Construct complex object step-by-step
**Code**: `Builder.setX().setY().build()`
**When**: Many optional parameters, immutable objects
**Remember**: Fluent API, solves telescoping constructors

### 5. PROTOTYPE
**One-liner**: Clone existing objects instead of creating new ones
**Code**: `implement Cloneable, override clone()`
**When**: Object creation expensive, need independent copies
**Remember**: Deep copy vs shallow copy, clone vs copy constructor

---

## 🔧 STRUCTURAL PATTERNS (7) - Object Composition

### 6. ADAPTER
**One-liner**: Convert one interface to another
**Code**: Adapter wraps adaptee, implements target interface
**When**: Incompatible interfaces, legacy code integration
**Remember**: Translation, object adapter (composition) > class adapter (inheritance)

### 7. BRIDGE
**One-liner**: Decouple abstraction from implementation
**Code**: Abstraction has-a Implementation
**When**: Both abstraction and implementation vary independently
**Remember**: Two hierarchies, avoids combinatorial explosion

### 8. COMPOSITE
**One-liner**: Treat individual objects and compositions uniformly
**Code**: Leaf and Composite implement Component
**When**: Tree structure, part-whole hierarchy
**Remember**: File/Folder, UI components, treat single and group same way

### 9. DECORATOR
**One-liner**: Add responsibilities dynamically by wrapping
**Code**: `Decorator(Decorator(Component))`
**When**: Add features without modifying class, avoid subclass explosion
**Remember**: Wrapper with same interface, Java I/O streams

### 10. FACADE
**One-liner**: Simplified interface to complex subsystem
**Code**: Facade delegates to subsystem classes
**When**: Complex system, need simple API
**Remember**: Simplification, doesn't hide subsystem (can still access)

### 11. PROXY
**One-liner**: Control access to another object
**Code**: Proxy has same interface as RealSubject
**When**: Lazy loading, access control, remote object
**Types**: Virtual (lazy), Protection (access), Remote (different location)
**Remember**: Same interface, controls access, delegates to real object

### 12. FLYWEIGHT
**One-liner**: Share common state to save memory
**Code**: Factory returns shared instances, extrinsic state passed as parameter
**When**: Many similar objects, significant shared state
**Remember**: Intrinsic (shared) vs Extrinsic (unique), String pool

---

## 🎭 BEHAVIORAL PATTERNS (11) - Object Interaction

### 13. CHAIN OF RESPONSIBILITY
**One-liner**: Pass request along chain until handled
**Code**: Each handler has `next`, either handles or passes
**When**: Multiple potential handlers, don't know handler in advance
**Remember**: Logging levels, event bubbling, request may go unhandled

### 14. COMMAND
**One-liner**: Encapsulate request as object
**Code**: Command interface with `execute()`, store in invoker
**When**: Queue operations, undo/redo, macro commands
**Remember**: Store state for undo, parameterize objects with operations

### 15. ITERATOR
**One-liner**: Access elements sequentially without exposing structure
**Code**: `hasNext()` + `next()`
**When**: Traverse collection without exposing internals
**Remember**: Java Iterator, forEach, internal vs external iteration

### 16. MEDIATOR
**One-liner**: Centralize complex communications between objects
**Code**: Components communicate via Mediator, not directly
**When**: Many-to-many relationships, reduce coupling
**Remember**: Air traffic control, components know mediator only

### 17. OBSERVER
**One-liner**: One-to-many dependency, auto-notify on change
**Code**: `attach()`, `detach()`, `notify()` → `update()`
**When**: One object change affects many, event-driven
**Remember**: Pub-Sub, push vs pull, memory leaks if not detached

### 18. STATE
**One-liner**: Change behavior when internal state changes
**Code**: Delegate to state objects, states control transitions
**When**: Behavior depends on state, avoid massive if-else
**Remember**: State objects (not enum), states transition themselves, Vending machine

### 19. STRATEGY
**One-liner**: Encapsulate interchangeable algorithms
**Code**: Context has-a Strategy, `setStrategy()`
**When**: Multiple ways to do same task, switch algorithm at runtime
**Remember**: Client chooses strategy, composition not inheritance, Payment methods

### 20. TEMPLATE METHOD
**One-liner**: Algorithm skeleton in parent, steps in children
**Code**: `final templateMethod()` calls `abstract primitiveOps()`
**When**: Share algorithm structure, vary specific steps
**Remember**: Inheritance-based, template method is final, hooks (optional)

### 21. VISITOR
**One-liner**: Separate operations from object structure
**Code**: `element.accept(visitor)` → `visitor.visit(element)` (double dispatch)
**When**: Many operations on stable structure
**Remember**: Easy add operations, hard add elements, AST traversal

### 22. MEMENTO
**One-liner**: Save and restore object state
**Code**: Originator creates Memento (opaque), Caretaker stores it
**When**: Undo/redo, checkpoints, rollback
**Remember**: Encapsulation preserved, memento immutable, undo stack

### 23. INTERPRETER
**One-liner**: Define grammar and interpreter for language
**Code**: Grammar rules → Classes, Terminal + Non-Terminal expressions
**When**: Simple DSL, grammar rarely changes
**Remember**: AST structure, use parser generator for complex grammar

---

## 🎯 CRITICAL DISTINCTIONS

### Factory Method vs Abstract Factory
- **Factory Method**: ONE product, inheritance, `abstract create()`
- **Abstract Factory**: MULTIPLE related products, composition, `interface Factory`

### Strategy vs State
- **Strategy**: Client chooses algorithm explicitly
- **State**: State controls its own transitions

### Decorator vs Proxy
- **Decorator**: Add functionality, same interface, stack decorators
- **Proxy**: Control access, same interface, one proxy per object

### Composite vs Decorator
- **Composite**: Tree structure, treat leaf and composite same
- **Decorator**: Linear wrapping, add behavior

### Adapter vs Facade
- **Adapter**: Convert ONE interface to another (1-to-1)
- **Facade**: Simplify MANY interfaces to one (N-to-1)

### Template Method vs Strategy
- **Template Method**: Inheritance, compile-time, algorithm skeleton
- **Strategy**: Composition, runtime, entire algorithm swappable

### Observer vs Mediator
- **Observer**: One-to-many (Subject → Observers)
- **Mediator**: Many-to-many via central hub

### Command vs Memento (Undo)
- **Command**: Undo via reverse operation
- **Memento**: Undo via state snapshot

### Prototype vs Flyweight
- **Prototype**: Clone to create new instances
- **Flyweight**: Share instances to save memory

---

## ⚡ SPEED RECALL TRIGGERS

| Keyword | Pattern |
|---------|---------|
| **One instance** | Singleton |
| **Too many constructors** | Builder |
| **Clone/Copy** | Prototype |
| **Don't know type** | Factory Method |
| **Family of objects** | Abstract Factory |
| **Interface mismatch** | Adapter |
| **Two hierarchies** | Bridge |
| **Tree structure** | Composite |
| **Add behavior dynamically** | Decorator |
| **Simplify complex system** | Facade |
| **Control access** | Proxy |
| **Save memory** | Flyweight |
| **Pass request along** | Chain of Responsibility |
| **Undo/Redo operations** | Command |
| **Traverse collection** | Iterator |
| **Reduce coupling** | Mediator |
| **Event listeners** | Observer |
| **State machine** | State |
| **Swap algorithms** | Strategy |
| **Algorithm skeleton** | Template Method |
| **Operations on structure** | Visitor |
| **Undo/Redo state** | Memento |
| **Language/Grammar** | Interpreter |

---

## 🚀 LAST-MINUTE CRAMMING

**If you only have 2 minutes, memorize these 5 most common patterns:**

1. **Singleton**: One instance (`Bill Pugh` inner holder class)
2. **Factory**: Create objects (`Factory Method` = inheritance, `Abstract Factory` = families)
3. **Observer**: Pub-Sub (`attach`, `notify`, `update`)
4. **Strategy**: Swap algorithms (`context.setStrategy()`)
5. **Decorator**: Wrap to add behavior (`same interface`)

**Second tier (3 more minutes):**
6. **Builder**: Complex construction (`.setX().setY().build()`)
7. **Adapter**: Interface conversion (wraps incompatible interface)
8. **Proxy**: Control access (virtual, protection, remote)
9. **Command**: Encapsulate request (undo/redo)
10. **State**: Behavior based on state (state objects, not enum)

---

## 💡 INTERVIEW PRO TIPS

1. **Always mention trade-offs**: Every pattern has pros/cons
2. **Real-world examples**: Show you've used patterns in practice
3. **When NOT to use**: Shows you don't over-engineer
4. **Compare similar patterns**: Factory Method vs Abstract Factory
5. **Code on whiteboard**: Practice 2-3 patterns to code from memory

---

## 🎓 PATTERN SELECTION QUICK CHECK

**Ask yourself:**
- Creating objects? → **Creational**
- Combining objects? → **Structural**
- Objects interacting? → **Behavioral**

Then:
- Multiple ways to create? → **Factory patterns**
- Need flexibility in structure? → **Decorator/Composite/Bridge**
- Runtime behavior change? → **Strategy/State/Command**

---

**✅ You're ready! Good luck with your interview! 🚀**
