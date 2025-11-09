# Design Pattern Identification Cheatsheet

**Quickly identify which pattern to use based on your problem!**

---

## 🎯 THE MASTER DECISION TREE

```
What's your problem?
│
├─ CREATING OBJECTS
│  ├─ Need only ONE instance globally? → SINGLETON
│  ├─ Too many constructor parameters? → BUILDER
│  ├─ Creating is expensive, want to copy? → PROTOTYPE
│  ├─ Don't know exact type at compile time?
│  │  ├─ Create ONE type of product? → FACTORY METHOD
│  │  └─ Create FAMILY of related products? → ABSTRACT FACTORY
│
├─ COMBINING/STRUCTURING OBJECTS
│  ├─ Incompatible interfaces? → ADAPTER
│  ├─ Two independent hierarchies? → BRIDGE
│  ├─ Tree structure (part-whole)? → COMPOSITE
│  ├─ Add features without modifying? → DECORATOR
│  ├─ Simplify complex subsystem? → FACADE
│  ├─ Control access to object? → PROXY
│  └─ Too many similar objects (memory)? → FLYWEIGHT
│
└─ OBJECT INTERACTION/BEHAVIOR
   ├─ Pass request through chain? → CHAIN OF RESPONSIBILITY
   ├─ Need undo/redo?
   │  ├─ Undo via reverse operation? → COMMAND
   │  └─ Undo via state snapshot? → MEMENTO
   ├─ Traverse collection? → ITERATOR
   ├─ Reduce many-to-many coupling? → MEDIATOR
   ├─ One change affects many? → OBSERVER
   ├─ Behavior depends on state?
   │  ├─ State transitions internally? → STATE
   │  └─ Choose behavior externally? → STRATEGY
   ├─ Share algorithm skeleton? → TEMPLATE METHOD
   ├─ Add operations to structure? → VISITOR
   └─ Interpret language/grammar? → INTERPRETER
```

---

## 🔍 PROBLEM → PATTERN LOOKUP

### "I need to create objects..."

| Problem | Pattern | Quick Test |
|---------|---------|------------|
| "Only one instance should exist" | **Singleton** | Logger, Config, ConnectionPool |
| "Constructor has 10+ parameters" | **Builder** | `new User(...)` has too many params |
| "Creating object is expensive" | **Prototype** | Complex initialization, clone faster |
| "Type decided at runtime" | **Factory Method** | if(type) return new ConcreteA() |
| "Need related objects together" | **Abstract Factory** | WindowsButton + WindowsCheckbox |

### "I need to structure objects..."

| Problem | Pattern | Quick Test |
|---------|---------|------------|
| "Class A can't talk to Class B" | **Adapter** | Legacy code, third-party library |
| "Two dimensions vary independently" | **Bridge** | Shape (circle, square) + Color (red, blue) |
| "Part-whole hierarchy" | **Composite** | File system, UI widgets, org chart |
| "Add features at runtime" | **Decorator** | Add toppings to pizza, BufferedReader |
| "Complex system, need simple API" | **Facade** | One method hides 10 subsystem calls |
| "Control access to object" | **Proxy** | Lazy loading, security, remote object |
| "1000s of similar objects" | **Flyweight** | Text editor characters, game particles |

### "I need objects to interact..."

| Problem | Pattern | Quick Test |
|---------|---------|------------|
| "Try handlers until one works" | **Chain of Responsibility** | Exception handling, approval chain |
| "Queue/schedule operations" | **Command** | Button clicks, transaction log, macros |
| "Access elements sequentially" | **Iterator** | Loop through collection |
| "Objects communicate indirectly" | **Mediator** | Chat room, air traffic control |
| "Notify multiple dependents" | **Observer** | Event listeners, spreadsheet cells |
| "Behavior changes with state" | **State** | Vending machine, TCP connection |
| "Swap algorithm at runtime" | **Strategy** | Sort strategy, payment method |
| "Same steps, different details" | **Template Method** | Coffee/Tea maker, data parser |
| "Operations on complex structure" | **Visitor** | Compiler AST, export formats |
| "Save and restore state" | **Memento** | Undo/Redo, game save, transaction |
| "Parse/interpret sentences" | **Interpreter** | Math expressions, SQL, regex |

---

## 🎬 SCENARIO-BASED IDENTIFICATION

### Interview Scenario Questions

#### Q: "Design a logging system for your application"
**Think**: Only one logger instance needed
**Pattern**: **Singleton**
**Bonus**: Thread-safe (Bill Pugh), different log levels (Strategy)

#### Q: "Users have many optional settings (name, email, phone, address, preferences...)"
**Think**: Too many constructor parameters
**Pattern**: **Builder**
**Code**: `new UserBuilder().setName().setEmail().build()`

#### Q: "We have MySQL, PostgreSQL, MongoDB - need to create connections"
**Think**: Different types, decided at runtime
**Pattern**: **Factory Method** or **Abstract Factory**
**Decide**: One product (Connection)? Factory Method. Multiple (Connection + Query + Transaction)? Abstract Factory

#### Q: "Old library uses XML, new system uses JSON"
**Think**: Interface mismatch
**Pattern**: **Adapter**
**Code**: JSONAdapter wraps XMLLibrary, implements JSONInterface

#### Q: "Add milk, sugar, caramel to coffee - any combination"
**Think**: Add features dynamically, avoid class explosion
**Pattern**: **Decorator**
**Avoid**: CoffeeWithMilk, CoffeeWithSugar, CoffeeWithMilkAndSugar...

#### Q: "Home theater: turn on TV, sound system, DVD player, dim lights"
**Think**: Simplify complex interactions
**Pattern**: **Facade**
**Code**: `homeTheater.watchMovie()` does everything

#### Q: "Load images only when scrolling to them"
**Think**: Lazy loading
**Pattern**: **Proxy** (Virtual Proxy)
**Code**: ImageProxy loads real image on first access

#### Q: "Spreadsheet: change cell A1, update B1, C1, chart"
**Think**: One change affects many
**Pattern**: **Observer**
**Code**: Cell A1 notifies observers (B1, C1, Chart)

#### Q: "Order states: Pending → Paid → Shipped → Delivered"
**Think**: Behavior varies by state
**Pattern**: **State**
**Code**: OrderState objects (PendingState, PaidState...)

#### Q: "Support QuickSort, MergeSort, BubbleSort - switch at runtime"
**Think**: Interchangeable algorithms
**Pattern**: **Strategy**
**Code**: `sorter.setStrategy(new QuickSort())`

#### Q: "Undo last 10 text edits"
**Think**: Save and restore state
**Pattern**: **Memento** or **Command**
**Decide**: Complex state? Memento. Discrete operations? Command

#### Q: "Render shapes: Circle, Rectangle, Triangle to XML, JSON, PDF"
**Think**: Add operations to structure
**Pattern**: **Visitor**
**Code**: XMLVisitor, JSONVisitor visit each shape

---

## 🚦 RED FLAGS (When NOT to use)

| Pattern | Don't Use When | Alternative |
|---------|----------------|-------------|
| **Singleton** | Testing needs multiple instances | Dependency Injection |
| **Factory** | Only one concrete class | Just use `new` |
| **Builder** | < 4 constructor parameters | Regular constructor |
| **Prototype** | Object creation is cheap | Just use `new` |
| **Adapter** | You control both interfaces | Change the interface |
| **Decorator** | Need to remove wrappers later | Use Composition |
| **Proxy** | Direct access is fine | Direct object |
| **Flyweight** | Few objects or mostly unique state | Regular objects |
| **Observer** | Only one subscriber | Direct method call |
| **State** | 2-3 simple states | if-else or enum |
| **Strategy** | Algorithm never changes | Just implement it |
| **Template Method** | No shared structure | Separate classes |
| **Visitor** | Object structure changes often | Keep operations in classes |
| **Memento** | State is trivial | Just save the field |
| **Interpreter** | Complex grammar | Use parser generator (ANTLR) |

---

## ⚡ QUICK RECOGNITION PATTERNS

### Code Smells → Pattern Solutions

| Code Smell | Pattern |
|------------|---------|
| `new SomeClass()` everywhere | Factory |
| Giant constructor | Builder |
| Massive if-else on type | Strategy or State or Factory |
| Copy-paste similar code | Template Method |
| Tight coupling between objects | Mediator or Observer |
| Deep inheritance for variants | Composition (Decorator/Strategy) |
| Can't extend without modifying | Open/Closed → Factory/Strategy/Decorator |

### Keywords in Requirements

| Keyword | Likely Pattern |
|---------|---------------|
| "global", "single instance" | Singleton |
| "optional parameters", "build" | Builder |
| "clone", "copy", "template" | Prototype |
| "create", "factory", "type" | Factory Method/Abstract Factory |
| "wrapper", "wrap", "legacy" | Adapter |
| "separate", "decouple" | Bridge |
| "tree", "hierarchy", "recursive" | Composite |
| "add features", "dynamic", "extend" | Decorator |
| "simplify", "unified interface" | Facade |
| "control", "lazy", "placeholder" | Proxy |
| "share", "memory", "lightweight" | Flyweight |
| "chain", "pass along", "handlers" | Chain of Responsibility |
| "undo", "redo", "queue", "log" | Command or Memento |
| "iterate", "traverse", "loop" | Iterator |
| "coordinate", "central hub" | Mediator |
| "notify", "subscribe", "event" | Observer |
| "state machine", "states" | State |
| "algorithm", "policy", "swap" | Strategy |
| "skeleton", "template", "hook" | Template Method |
| "operations", "traverse structure" | Visitor |
| "save", "restore", "snapshot" | Memento |
| "parse", "interpret", "grammar" | Interpreter |

---

## 🎯 PATTERN COMBINATIONS (Common Pairs)

Often patterns work together:

| Combination | Use Case |
|-------------|----------|
| **Abstract Factory + Singleton** | One factory instance, creates product families |
| **Factory + Prototype** | Factory returns clones instead of new instances |
| **Composite + Iterator** | Traverse tree structure |
| **Composite + Visitor** | Operations on tree structure |
| **Decorator + Factory** | Factory creates decorated objects |
| **Strategy + Factory** | Factory selects appropriate strategy |
| **Command + Memento** | Commands store mementos for undo |
| **Observer + Mediator** | Mediator notifies observers |
| **Proxy + Singleton** | Single proxy instance |
| **Flyweight + Factory** | Factory manages flyweight pool |

---

## 🧠 MEMORIZATION TRICKS

### By Category Initials
- **Creational**: **S**am **F**ound **A** **B**ig **P**izza (Singleton, Factory, Abstract Factory, Builder, Prototype)
- **Structural**: **A** **B**ig **C**at **D**ancing **F**or **P**oor **F**amily (Adapter, Bridge, Composite, Decorator, Facade, Proxy, Flyweight)
- **Behavioral**: Use the first letters or make your own!

### By Shape/Analogy
- **Singleton**: ⚫ One dot
- **Factory**: 🏭 Factory building
- **Adapter**: 🔌 Plug adapter
- **Proxy**: 🚪 Door/gatekeeper
- **Observer**: 📢 Megaphone (broadcast)
- **Strategy**: 🔄 Swap/exchange
- **Decorator**: 🎁 Gift wrapping
- **Composite**: 🌳 Tree
- **Chain**: ⛓️ Chain links
- **State**: 🚦 Traffic light (changes)

---

## 📊 COMPARISON MATRIX

### Factory Patterns

|  | Factory Method | Abstract Factory | Builder |
|--|----------------|------------------|---------|
| **Products** | One | Family (multiple) | One complex |
| **Focus** | Type selection | Related objects | Step-by-step |
| **Mechanism** | Inheritance | Composition | Fluent API |
| **Example** | TransportFactory | UIFactory (Button+Checkbox) | UserBuilder |

### Wrapper Patterns

|  | Adapter | Decorator | Proxy |
|--|---------|-----------|-------|
| **Intent** | Convert interface | Add behavior | Control access |
| **Same interface?** | No (converts) | Yes | Yes |
| **Multiple layers?** | No | Yes (stack) | No |
| **Example** | XMLToJSON | CoffeeDecorators | LazyImage |

### Behavior Patterns

|  | Strategy | State | Template Method |
|--|----------|-------|-----------------|
| **What varies?** | Algorithm | Behavior | Steps |
| **Who decides?** | Client | State itself | Subclass |
| **Mechanism** | Composition | Composition | Inheritance |
| **Runtime change?** | Yes | Yes | No |
| **Example** | SortStrategy | OrderState | DataProcessor |

---

## 🎓 FINAL INTERVIEW CHECKLIST

Before using ANY pattern, ask:
1. ✅ **Is it solving a real problem?** (Not over-engineering)
2. ✅ **Is this the simplest solution?** (KISS principle)
3. ✅ **Can I explain the trade-offs?** (Pros and cons)
4. ✅ **Do I know a real-world example?** (Shows experience)
5. ✅ **Can I code it in 5 minutes?** (Practice!)

---

## 🚀 BONUS: One-Sentence Summaries

**If you can only remember ONE sentence per pattern:**

1. **Singleton**: One instance, global access
2. **Factory Method**: Subclass decides type
3. **Abstract Factory**: Family of related objects
4. **Builder**: Step-by-step construction
5. **Prototype**: Clone instead of new
6. **Adapter**: Interface converter
7. **Bridge**: Separate abstraction from implementation
8. **Composite**: Tree structure, uniform treatment
9. **Decorator**: Wrap to add behavior
10. **Facade**: Simplified interface
11. **Proxy**: Control access
12. **Flyweight**: Share to save memory
13. **Chain of Responsibility**: Pass request along
14. **Command**: Request as object
15. **Iterator**: Sequential access
16. **Mediator**: Central communication hub
17. **Observer**: Notify dependents automatically
18. **State**: Behavior varies with state
19. **Strategy**: Interchangeable algorithms
20. **Template Method**: Algorithm skeleton
21. **Visitor**: External operations
22. **Memento**: Save and restore state
23. **Interpreter**: Parse and execute grammar

---

**🎯 You've got this! Pattern selection is all about recognizing the problem type.**
