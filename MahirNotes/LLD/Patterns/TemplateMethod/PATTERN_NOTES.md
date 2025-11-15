# Template Method Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Define the skeleton of an algorithm in a base class, letting subclasses override specific steps without changing the algorithm's structure.

## 📖 The Problem
**Without Template Method**: Code duplication
```java
class TeaMaker {
    public void makeTea() {
        boilWater();
        steepTeaBag();
        pourInCup();
        addLemon();
    }

    void boilWater() { System.out.println("Boiling water"); }
    void steepTeaBag() { System.out.println("Steeping tea"); }
    void pourInCup() { System.out.println("Pouring in cup"); }
    void addLemon() { System.out.println("Adding lemon"); }
}

class CoffeeMaker {
    public void makeCoffee() {
        boilWater();        // ❌ Duplicated
        brewCoffee();
        pourInCup();        // ❌ Duplicated
        addSugar();
    }

    void boilWater() { System.out.println("Boiling water"); }  // ❌ Duplicated
    void brewCoffee() { System.out.println("Brewing coffee"); }
    void pourInCup() { System.out.println("Pouring in cup"); }  // ❌ Duplicated
    void addSugar() { System.out.println("Adding sugar"); }
}
```
❌ Common steps duplicated (boilWater, pourInCup)
❌ Hard to maintain
❌ Can't easily change algorithm flow

**With Template Method**: Reusable skeleton
```java
abstract class BeverageMaker {
    // Template method (final to prevent override)
    public final void makeBeverage() {
        boilWater();      // Common step
        brew();           // Subclass-specific
        pourInCup();      // Common step
        addCondiments();  // Subclass-specific
    }

    void boilWater() { System.out.println("Boiling water"); }
    void pourInCup() { System.out.println("Pouring in cup"); }

    abstract void brew();            // Must override
    abstract void addCondiments();   // Must override
}

class Tea extends BeverageMaker {
    void brew() { System.out.println("Steeping tea"); }
    void addCondiments() { System.out.println("Adding lemon"); }
}

class Coffee extends BeverageMaker {
    void brew() { System.out.println("Brewing coffee"); }
    void addCondiments() { System.out.println("Adding sugar"); }
}
```
✅ Common steps reused
✅ Algorithm structure protected (final)
✅ Subclasses customize only what's needed

## 🔑 Key Concept
```
Parent class defines algorithm skeleton (template)
      ↓
Subclasses fill in the details (concrete steps)
```

**Template Method** = Fixed algorithm structure + Customizable steps

**Also Known As**: Hollywood Principle ("Don't call us, we'll call you")

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Multiple classes share algorithm structure | ✗ Algorithms completely different |
| ✓ Only specific steps vary | ✗ No common structure |
| ✓ Want to prevent algorithm modification | ✗ Need runtime algorithm change (use Strategy) |
| ✓ Code duplication in similar classes | ✗ Simple inheritance suffices |

## 📐 Structure

```
┌──────────────────────────┐
│   AbstractClass          │
├──────────────────────────┤
│ +templateMethod() final  │ ◄─── Template (algorithm skeleton)
│ +primitiveOp1() abstract │ ◄─── Abstract steps (must override)
│ +primitiveOp2() abstract │
│ +hook()                  │ ◄─── Hook (optional override)
└────────────▲─────────────┘
             │
    ┌────────┴──────────┐
    │                   │
┌───▼──────────┐ ┌──────▼────────┐
│ConcreteClass1│ │ConcreteClass2 │
├──────────────┤ ├───────────────┤
│+primitiveOp1 │ │+primitiveOp1  │ ◄─── Implement abstract steps
│+primitiveOp2 │ │+primitiveOp2  │
│+hook()       │ │               │ ◄─── Optionally override hooks
└──────────────┘ └───────────────┘
```

## 💻 Implementation Pattern

### 1. Abstract Class with Template Method
```java
public abstract class DataProcessor {
    // Template method - defines algorithm skeleton
    public final void process() {
        openFile();
        extractData();
        parseData();
        analyzeData();
        if (shouldGenerateReport()) {  // Hook method
            generateReport();
        }
        closeFile();
    }

    // Common concrete methods
    void openFile() {
        System.out.println("Opening file...");
    }

    void closeFile() {
        System.out.println("Closing file...");
    }

    // Abstract methods - subclasses must implement
    abstract void extractData();
    abstract void parseData();
    abstract void analyzeData();

    // Hook method - optional override
    void generateReport() {
        System.out.println("Generating default report");
    }

    // Hook - controls flow
    boolean shouldGenerateReport() {
        return true;  // Default behavior
    }
}
```

### 2. Concrete Implementations
```java
public class CSVDataProcessor extends DataProcessor {
    @Override
    void extractData() {
        System.out.println("Extracting CSV data");
    }

    @Override
    void parseData() {
        System.out.println("Parsing CSV format");
    }

    @Override
    void analyzeData() {
        System.out.println("Analyzing CSV data");
    }

    @Override
    void generateReport() {
        System.out.println("Generating CSV-specific report");
    }
}

public class XMLDataProcessor extends DataProcessor {
    @Override
    void extractData() {
        System.out.println("Extracting XML data");
    }

    @Override
    void parseData() {
        System.out.println("Parsing XML format");
    }

    @Override
    void analyzeData() {
        System.out.println("Analyzing XML data");
    }

    @Override
    boolean shouldGenerateReport() {
        return false;  // Override hook to skip report
    }
}

public class JSONDataProcessor extends DataProcessor {
    @Override
    void extractData() {
        System.out.println("Extracting JSON data");
    }

    @Override
    void parseData() {
        System.out.println("Parsing JSON format");
    }

    @Override
    void analyzeData() {
        System.out.println("Analyzing JSON data");
    }
}
```

### 3. Usage
```java
DataProcessor csvProcessor = new CSVDataProcessor();
csvProcessor.process();
// Output:
// Opening file...
// Extracting CSV data
// Parsing CSV format
// Analyzing CSV data
// Generating CSV-specific report
// Closing file...

DataProcessor xmlProcessor = new XMLDataProcessor();
xmlProcessor.process();
// Output:
// Opening file...
// Extracting XML data
// Parsing XML format
// Analyzing XML data
// (No report - hook returned false)
// Closing file...
```

## 🎓 Real-World Examples

| Domain | Template Method | Variable Steps |
|--------|----------------|----------------|
| **Testing** | setUp() → test() → tearDown() | test() |
| **Web Framework** | handleRequest() → authenticate() → process() | authenticate(), process() |
| **Game** | initialize() → startLoop() → render() | render() |
| **Compiler** | parse() → optimize() → generate() | All steps |
| **Java Collections** | Arrays.sort() | Comparator.compare() |

### JUnit Example
```java
// JUnit uses Template Method
abstract class TestCase {
    public final void runTest() {  // Template method
        setUp();      // Hook (optional)
        runTestCase();  // Abstract (must implement)
        tearDown();   // Hook (optional)
    }

    protected void setUp() { }      // Hook
    protected void tearDown() { }   // Hook
    protected abstract void runTestCase();  // Abstract
}

class MyTest extends TestCase {
    protected void setUp() {
        // Initialize test data
    }

    protected void runTestCase() {
        // Actual test logic
    }

    protected void tearDown() {
        // Clean up
    }
}
```

## 🔧 Hook Methods

**Hook**: Optional method with default (often empty) implementation

```java
abstract class Algorithm {
    public final void execute() {
        step1();
        if (shouldDoStep2()) {  // Hook controls flow
            step2();
        }
        step3();
        hook();  // Hook provides extension point
    }

    abstract void step1();
    abstract void step3();

    // Hook methods (optional override)
    void step2() { }  // Default: do nothing

    boolean shouldDoStep2() {
        return true;  // Default: do step2
    }

    void hook() { }  // Extension point
}
```

**Benefits of Hooks**:
- Optional customization
- Control algorithm flow
- Provide extension points
- Default behavior

## ⚖️ Template Method vs Similar Patterns

| Pattern | Mechanism | Flexibility | When to Change |
|---------|-----------|-------------|----------------|
| **Template Method** | Inheritance | Compile-time | Subclass creation |
| **Strategy** | Composition | Runtime | Any time |
| **Factory Method** | Inheritance | Compile-time | Object creation only |

### Template Method vs Strategy
```java
// Template Method: Inheritance (is-a)
abstract class Algorithm {
    final void execute() {
        step1();
        step2();  // Subclass defines
    }
    abstract void step2();
}

// Strategy: Composition (has-a)
class Context {
    private Strategy strategy;
    void execute() {
        strategy.algorithm();  // Runtime swap
    }
}
```

**Key Difference**:
- **Template Method**: Compile-time, inheritance-based
- **Strategy**: Runtime, composition-based

## 🚨 Common Mistakes

### ❌ Mistake 1: Template method not final
```java
// Wrong: Template method can be overridden
public void templateMethod() {  // ❌ Can be overridden
    step1();
    step2();
}

// Right: Make it final
public final void templateMethod() {  // ✅ Cannot override
    step1();
    step2();
}
```

### ❌ Mistake 2: Too many abstract methods
```java
// Wrong: Everything abstract (defeats purpose)
abstract class Processor {
    abstract void step1();
    abstract void step2();
    abstract void step3();
    abstract void step4();
    abstract void step5();
    abstract void step6();  // ❌ No common behavior!
}

// Right: Mix of concrete and abstract
abstract class Processor {
    void step1() { /* common */ }  // ✅ Shared
    abstract void step2();         // ✅ Custom
    void step3() { /* common */ }  // ✅ Shared
    abstract void step4();         // ✅ Custom
}
```

### ❌ Mistake 3: Calling abstract methods from constructor
```java
// Wrong: Abstract method in constructor
abstract class Base {
    public Base() {
        initialize();  // ❌ Subclass not initialized yet!
    }
    abstract void initialize();
}

// Right: Call from template method, not constructor
abstract class Base {
    public final void execute() {
        initialize();  // ✅ Safe
    }
    abstract void initialize();
}
```

### ❌ Mistake 4: Public primitive operations
```java
// Wrong: Public primitive methods
abstract class Algorithm {
    public abstract void step1();  // ❌ Public
    public abstract void step2();
}

// Right: Protected/private
abstract class Algorithm {
    protected abstract void step1();  // ✅ Protected
    protected abstract void step2();
}
```

### ❌ Mistake 5: Hooks with abstract signature
```java
// Wrong: Hook as abstract (forces implementation)
abstract void hook();  // ❌ Not a hook, it's mandatory!

// Right: Hook with default implementation
void hook() { }  // ✅ Optional override
```

## 🎤 Interview Questions & Answers

### Q1: What is the Template Method pattern?
**A**: A behavioral pattern that defines the skeleton of an algorithm in a base class, allowing subclasses to override specific steps without changing the algorithm's overall structure.

### Q2: When would you use Template Method?
**A**: When:
1. Multiple classes share same algorithm structure but differ in specifics
2. Want to avoid code duplication in similar classes
3. Need to control algorithm structure (prevent modification)
4. Subclasses should only customize certain steps

### Q3: What are the key components?
**A**:
1. **Template Method**: Final method defining algorithm skeleton
2. **Abstract Operations**: Steps subclasses must implement
3. **Hook Methods**: Optional steps with default behavior
4. **Concrete Operations**: Common steps defined in base class

### Q4: What's the Hollywood Principle?
**A**: "Don't call us, we'll call you"
- Subclasses don't call parent methods
- Parent's template method calls subclass methods
- Inversion of control

### Q5: Template Method vs Strategy?
**A**:
| Aspect | Template Method | Strategy |
|--------|----------------|----------|
| Mechanism | Inheritance | Composition |
| Flexibility | Compile-time | Runtime |
| Structure | Fixed skeleton | Entire algorithm swappable |
| Use Case | Shared structure, different steps | Different algorithms |

### Q6: What's a hook method?
**A**: A method in the base class with a default (usually empty) implementation that subclasses can optionally override to customize behavior.

### Q7: Why make template method final?
**A**: To prevent subclasses from changing the algorithm structure. Only specific steps should be customizable, not the overall flow.

### Q8: Can you give a real Java example?
**A**:
- **AbstractList.addAll()**: Template method calling abstract `add()`
- **InputStream.read(byte[])**: Template calling `read()`
- **Collections.sort()**: Template using `Comparator.compare()`

### Q9: What are advantages?
**A**:
1. Code reuse (common steps in base class)
2. Consistent algorithm structure
3. Easy to extend (add new variations)
4. Single Responsibility (each step separate)

### Q10: What are disadvantages?
**A**:
1. Inheritance-based (less flexible than composition)
2. Violates Liskov Substitution if not careful
3. Can lead to deep inheritance hierarchies
4. Hard to change at runtime (use Strategy for that)

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Define algorithm skeleton, let subclasses customize steps |
| **Mechanism** | Inheritance (is-a relationship) |
| **Template Method** | Final method defining algorithm flow |
| **Abstract Operations** | Steps subclasses must implement |
| **Hooks** | Optional customization points |
| **vs Strategy** | Template = inheritance; Strategy = composition |

## 🔍 Quick Checklist

When implementing Template Method pattern:
- [ ] Template method is `final`
- [ ] Template method defines algorithm steps
- [ ] Common steps are concrete methods
- [ ] Variable steps are abstract methods
- [ ] Hooks have default implementation
- [ ] Primitive operations are protected/private, not public
- [ ] Don't call abstract methods from constructor
- [ ] Base class doesn't have too many abstract methods
- [ ] Subclasses only override what they need
- [ ] Algorithm structure is consistent across subclasses

## 📊 Pattern Template

```java
// 1. Abstract Class
abstract class AbstractClass {
    // Template method (final)
    public final void templateMethod() {
        primitiveOperation1();
        primitiveOperation2();
        if (hook1()) {
            concreteOperation();
        }
        hook2();
    }

    // Abstract operations (must override)
    protected abstract void primitiveOperation1();
    protected abstract void primitiveOperation2();

    // Concrete operation (shared)
    protected void concreteOperation() {
        // Common implementation
    }

    // Hooks (optional override)
    protected boolean hook1() {
        return true;  // Default behavior
    }

    protected void hook2() {
        // Default: do nothing
    }
}

// 2. Concrete Class
class ConcreteClass extends AbstractClass {
    @Override
    protected void primitiveOperation1() {
        // Implementation specific to ConcreteClass
    }

    @Override
    protected void primitiveOperation2() {
        // Implementation specific to ConcreteClass
    }

    // Optionally override hooks
    @Override
    protected boolean hook1() {
        return false;  // Custom behavior
    }
}

// 3. Usage
AbstractClass obj = new ConcreteClass();
obj.templateMethod();  // Executes algorithm
```

## 💡 Remember
> "Template Method is like a recipe: the steps are fixed (boil, mix, bake), but the ingredients (what you boil, what you mix) can vary."

## 🔧 Types of Methods

| Method Type | Characteristics | Override |
|-------------|-----------------|----------|
| **Template Method** | `final`, defines skeleton | ❌ No |
| **Abstract Operation** | `abstract`, must implement | ✅ Required |
| **Concrete Operation** | Shared implementation | ❌ Usually no |
| **Hook** | Default (often empty) | ✅ Optional |

## 📈 Decision Tree

```
Do classes share algorithm structure?
    ├─ Yes → Continue
    └─ No → Don't use Template Method

Do only specific steps vary?
    ├─ Yes → Continue
    └─ No → Consider Strategy

Need runtime flexibility?
    ├─ Yes → Use Strategy instead
    └─ No → Use Template Method
```

---

**For Amazon Interviews**: Focus on **algorithm skeleton** (why), **inheritance-based code reuse** (how), **Template Method vs Strategy** (key difference), and **hooks** (optional customization). Be ready to discuss real examples (JUnit, Collections) and when Template Method is preferable to Strategy (compile-time vs runtime).
