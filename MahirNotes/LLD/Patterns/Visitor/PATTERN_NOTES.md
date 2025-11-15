# Visitor Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Separate algorithms from the objects they operate on by moving operations into external visitor classes, allowing new operations without modifying object structures.

## 📖 The Problem
**Without Visitor**: Operations pollute domain classes
```java
class Circle {
    double radius;

    double calculateArea() { return Math.PI * radius * radius; }
    void exportXML() { /* XML export logic */ }
    void exportJSON() { /* JSON export logic */ }
    void exportPDF() { /* PDF export logic */ }
    // Adding new export format requires modifying this class!
}

class Rectangle {
    double width, height;

    double calculateArea() { return width * height; }
    void exportXML() { /* XML export logic */ }
    void exportJSON() { /* JSON export logic */ }
    void exportPDF() { /* PDF export logic */ }
    // Same export code duplicated!
}
```
❌ Export logic mixed with domain logic
❌ Adding new operation requires modifying all classes
❌ Violates Single Responsibility Principle
❌ Violates Open/Closed Principle

**With Visitor**: Operations externalized
```java
interface Shape {
    void accept(ShapeVisitor visitor);
}

class Circle implements Shape {
    double radius;
    void accept(ShapeVisitor visitor) {
        visitor.visit(this);  // Double dispatch
    }
}

interface ShapeVisitor {
    void visit(Circle circle);
    void visit(Rectangle rectangle);
}

class XMLExportVisitor implements ShapeVisitor {
    void visit(Circle c) { /* Export circle to XML */ }
    void visit(Rectangle r) { /* Export rectangle to XML */ }
}
// Add new operation = new visitor class (no modification to Shape classes!)
```
✅ Operations separate from domain objects
✅ Easy to add new operations (new visitor)
✅ Single Responsibility (each visitor handles one operation)
✅ Open/Closed (add operations without modifying shapes)

## 🔑 Key Concept
```
Element (Shape) → accept(Visitor)
                      ↓
Visitor → visit(ConcreteElement)
```

**Double Dispatch**:
1. Client calls `element.accept(visitor)`
2. Element calls `visitor.visit(this)`
3. Correct visitor method executes based on both element and visitor types

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Need many unrelated operations on objects | ✗ Object structure changes frequently |
| ✓ Object structure is stable | ✗ Only a few operations |
| ✓ Want to keep operations separate from classes | ✗ Operations naturally belong in classes |
| ✓ Operations involve multiple class types | ✗ Simple operations |

## 📐 Structure

```
┌──────────────┐
│   Client     │
└──────┬───────┘
       │ uses
   ┌───┴────────┐
   │            │
   ▼            ▼
┌──────────┐  ┌──────────┐
│ Element  │  │ Visitor  │
├──────────┤  ├──────────┤
│+accept() │  │+visit(A) │
└────▲─────┘  │+visit(B) │
     │        └────▲─────┘
     │             │
┌────┴─────┐   ┌──┴────────┐
│          │   │           │
▼          ▼   ▼           ▼
ConcreteA  ConcreteB  VisitorX  VisitorY
accept(v)  accept(v)  visit(A)  visit(A)
                      visit(B)  visit(B)
```

## 💻 Implementation Pattern

### 1. Element Interface
```java
public interface Shape {
    void accept(ShapeVisitor visitor);
}
```

### 2. Concrete Elements
```java
public class Circle implements Shape {
    private double radius;

    public Circle(double radius) {
        this.radius = radius;
    }

    public double getRadius() {
        return radius;
    }

    @Override
    public void accept(ShapeVisitor visitor) {
        visitor.visit(this);  // Pass self to visitor
    }
}

public class Rectangle implements Shape {
    private double width;
    private double height;

    public Rectangle(double width, double height) {
        this.width = width;
        this.height = height;
    }

    public double getWidth() {
        return width;
    }

    public double getHeight() {
        return height;
    }

    @Override
    public void accept(ShapeVisitor visitor) {
        visitor.visit(this);
    }
}

public class Triangle implements Shape {
    private double base;
    private double height;

    public Triangle(double base, double height) {
        this.base = base;
        this.height = height;
    }

    public double getBase() {
        return base;
    }

    public double getHeight() {
        return height;
    }

    @Override
    public void accept(ShapeVisitor visitor) {
        visitor.visit(this);
    }
}
```

### 3. Visitor Interface
```java
public interface ShapeVisitor {
    void visit(Circle circle);
    void visit(Rectangle rectangle);
    void visit(Triangle triangle);
}
```

### 4. Concrete Visitors
```java
// Operation 1: Calculate area
public class AreaCalculator implements ShapeVisitor {
    private double totalArea = 0;

    @Override
    public void visit(Circle circle) {
        double area = Math.PI * circle.getRadius() * circle.getRadius();
        System.out.println("Circle area: " + area);
        totalArea += area;
    }

    @Override
    public void visit(Rectangle rectangle) {
        double area = rectangle.getWidth() * rectangle.getHeight();
        System.out.println("Rectangle area: " + area);
        totalArea += area;
    }

    @Override
    public void visit(Triangle triangle) {
        double area = 0.5 * triangle.getBase() * triangle.getHeight();
        System.out.println("Triangle area: " + area);
        totalArea += area;
    }

    public double getTotalArea() {
        return totalArea;
    }
}

// Operation 2: Export to XML
public class XMLExporter implements ShapeVisitor {
    @Override
    public void visit(Circle circle) {
        System.out.println("<Circle radius=\"" + circle.getRadius() + "\"/>");
    }

    @Override
    public void visit(Rectangle rectangle) {
        System.out.println("<Rectangle width=\"" + rectangle.getWidth() +
                          "\" height=\"" + rectangle.getHeight() + "\"/>");
    }

    @Override
    public void visit(Triangle triangle) {
        System.out.println("<Triangle base=\"" + triangle.getBase() +
                          "\" height=\"" + triangle.getHeight() + "\"/>");
    }
}

// Operation 3: Draw
public class DrawVisitor implements ShapeVisitor {
    @Override
    public void visit(Circle circle) {
        System.out.println("Drawing circle with radius " + circle.getRadius());
    }

    @Override
    public void visit(Rectangle rectangle) {
        System.out.println("Drawing rectangle " + rectangle.getWidth() + "x" + rectangle.getHeight());
    }

    @Override
    public void visit(Triangle triangle) {
        System.out.println("Drawing triangle with base " + triangle.getBase());
    }
}
```

### 5. Usage
```java
List<Shape> shapes = Arrays.asList(
    new Circle(5),
    new Rectangle(4, 6),
    new Triangle(3, 4)
);

// Operation 1: Calculate area
AreaCalculator areaCalc = new AreaCalculator();
for (Shape shape : shapes) {
    shape.accept(areaCalc);
}
System.out.println("Total area: " + areaCalc.getTotalArea());

// Operation 2: Export to XML
XMLExporter xmlExporter = new XMLExporter();
for (Shape shape : shapes) {
    shape.accept(xmlExporter);
}

// Operation 3: Draw
DrawVisitor drawer = new DrawVisitor();
for (Shape shape : shapes) {
    shape.accept(drawer);
}
```

**Output:**
```
Circle area: 78.54
Rectangle area: 24.0
Triangle area: 6.0
Total area: 108.54

<Circle radius="5.0"/>
<Rectangle width="4.0" height="6.0"/>
<Triangle base="3.0" height="4.0"/>

Drawing circle with radius 5.0
Drawing rectangle 4.0x6.0
Drawing triangle with base 3.0
```

## 🎓 Real-World Examples

| Domain | Elements | Visitors |
|--------|----------|----------|
| **Compiler** | AST Nodes | CodeGenerator, Optimizer, TypeChecker |
| **File System** | Files, Directories | SizeCalculator, Searcher, Zipper |
| **Shopping Cart** | Products | PriceCalculator, TaxCalculator |
| **Document** | Paragraphs, Images | HTMLRenderer, PDFRenderer |

### Compiler Example
```java
// AST Nodes (Elements)
interface ASTNode {
    void accept(ASTVisitor visitor);
}

class NumberNode implements ASTNode {
    int value;
    void accept(ASTVisitor v) { v.visit(this); }
}

class AddNode implements ASTNode {
    ASTNode left, right;
    void accept(ASTVisitor v) { v.visit(this); }
}

// Visitors (Operations)
interface ASTVisitor {
    void visit(NumberNode node);
    void visit(AddNode node);
}

class CodeGenerator implements ASTVisitor {
    void visit(NumberNode n) { emit("PUSH " + n.value); }
    void visit(AddNode a) {
        a.left.accept(this);
        a.right.accept(this);
        emit("ADD");
    }
}

class Optimizer implements ASTVisitor {
    void visit(NumberNode n) { /* No optimization */ }
    void visit(AddNode a) {
        // Constant folding, etc.
    }
}
```

## 🔄 Double Dispatch

**Problem**: Java has single dispatch (method chosen based on receiver type only)

```java
// Single dispatch
Shape shape = new Circle();
shape.draw();  // Which draw()? Determined by shape's runtime type (Circle)
```

**Solution**: Visitor uses double dispatch (method chosen based on both object types)

```java
// Double dispatch
Shape shape = new Circle();
Visitor visitor = new XMLExporter();

shape.accept(visitor);     // (1) Dispatch on shape type → Circle.accept()
  → visitor.visit(this);   // (2) Dispatch on visitor type → XMLExporter.visit(Circle)
```

**Result**: Correct method selected based on:
1. Concrete element type (Circle, Rectangle)
2. Concrete visitor type (XMLExporter, AreaCalculator)

## ⚖️ Visitor vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Visitor** | Add operations to object structure | Operations external |
| **Strategy** | Choose algorithm | Single algorithm, not type-specific |
| **Command** | Encapsulate request | Focuses on undo/redo |
| **Iterator** | Traverse elements | Focuses on traversal, not operations |

### When to Use What?

```java
// Visitor: Operations on heterogeneous types
visitor.visit(Circle);
visitor.visit(Rectangle);  // Different logic for each type

// Strategy: Same interface, different algorithm
context.setStrategy(new QuickSort());  // Algorithm for any data
context.setStrategy(new MergeSort());
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Forgetting double dispatch
```java
// Wrong: Direct call (no double dispatch)
class Circle {
    void doSomething(Visitor v) {
        v.doSomething(this);  // ❌ Loses type information
    }
}

// Right: accept/visit pattern
class Circle {
    void accept(Visitor v) {
        v.visit(this);  // ✅ Double dispatch
    }
}
```

### ❌ Mistake 2: Element structure changes frequently
```java
// Wrong use case: Frequently adding new shapes
// Every new shape requires modifying ALL visitors!
class NewShape implements Shape { }

// Now must update XMLExporter, AreaCalculator, DrawVisitor, etc.
// ❌ Visitor not suitable for volatile hierarchies
```

### ❌ Mistake 3: Visitor modifies element state
```java
// Wrong: Visitor changes element
class BadVisitor implements ShapeVisitor {
    void visit(Circle c) {
        c.setRadius(10);  // ❌ Side effect!
    }
}

// Right: Visitor reads but doesn't modify
class GoodVisitor implements ShapeVisitor {
    void visit(Circle c) {
        double radius = c.getRadius();  // ✅ Read-only
        // Process radius...
    }
}
```

### ❌ Mistake 4: No common visitor interface
```java
// Wrong: Each visitor unrelated
class XMLExporter {
    void exportCircle(Circle c) { }
    void exportRect(Rectangle r) { }
}

class AreaCalc {
    void calcCircle(Circle c) { }
    void calcRect(Rectangle r) { }  // ❌ Inconsistent
}

// Right: Common interface
interface Visitor {
    void visit(Circle c);
    void visit(Rectangle r);  // ✅ Consistent
}
```

### ❌ Mistake 5: Visitor returns values awkwardly
```java
// Wrong: Storing result in visitor field
class AreaVisitor implements Visitor {
    private double result;  // ❌ Stateful, not thread-safe

    void visit(Circle c) {
        result = Math.PI * c.getRadius() * c.getRadius();
    }

    double getResult() { return result; }
}

// Better: Return values (requires modified interface)
interface Visitor<T> {
    T visit(Circle c);
    T visit(Rectangle r);
}

// Or use separate result collector
```

## 🎤 Interview Questions & Answers

### Q1: What is the Visitor pattern?
**A**: A behavioral pattern that separates algorithms from objects by moving operations into external visitor classes, allowing new operations without modifying existing object structures.

### Q2: When would you use Visitor?
**A**: When:
1. Need many unrelated operations on object structure
2. Object structure is stable (rarely add new types)
3. Operations don't naturally fit in element classes
4. Want to gather related operations in one class

### Q3: What is double dispatch?
**A**: A technique to select method based on two object types:
1. First dispatch: `element.accept(visitor)` → chooses element's accept method
2. Second dispatch: `visitor.visit(this)` → chooses visitor's visit method
Result: Method selection based on both element and visitor types.

### Q4: What are the key components?
**A**:
1. **Visitor**: Interface with visit methods for each element type
2. **ConcreteVisitor**: Implements operations for each element
3. **Element**: Interface with accept method
4. **ConcreteElement**: Implements accept by calling visitor.visit(this)

### Q5: Advantages of Visitor?
**A**:
1. **Open/Closed**: Add operations without modifying elements
2. **Single Responsibility**: Related operations grouped in visitor
3. **Accumulation**: Visitor can accumulate state across visits
4. **Type Safety**: Compile-time checking of element types

### Q6: Disadvantages of Visitor?
**A**:
1. **Violated Encapsulation**: Visitor may need access to element internals
2. **Rigid Structure**: Adding new element type requires modifying all visitors
3. **Circular Dependency**: Elements and visitors know about each other
4. **Complexity**: Double dispatch can be confusing

### Q7: Visitor vs Strategy?
**A**:
- **Visitor**: Operations on multiple types, type-specific logic
- **Strategy**: Single algorithm, type-agnostic
- **Visitor**: Harder to add new types
- **Strategy**: Easier to add new strategies

### Q8: Real-world example?
**A**:
- **Java Compiler**: AST visitors for code generation, optimization
- **Apache Commons**: FileVisitor for file tree operations
- **ASM Library**: ClassVisitor for bytecode manipulation

### Q9: Can visitor return values?
**A**: Standard Visitor returns void. For return values:
1. Store result in visitor field (not thread-safe)
2. Use generic visitor: `interface Visitor<T> { T visit(...); }`
3. Use function interfaces (Java 8+): `Function<Element, Result>`

### Q10: What if element structure changes often?
**A**: Don't use Visitor! Every new element type requires:
- Adding visit method to Visitor interface
- Implementing visit in all concrete visitors
Better: Keep operations in element classes or use Strategy

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Separate operations from object structure |
| **Double Dispatch** | Method selection based on 2 types |
| **Best For** | Stable structure, many operations |
| **Not For** | Volatile structure, few operations |
| **Trade-off** | Easy to add operations, hard to add types |
| **Encapsulation** | May violate (visitor needs access to internals) |

## 🔍 Quick Checklist

When implementing Visitor pattern:
- [ ] Define Visitor interface with visit method for each element type
- [ ] Create ConcreteVisitor for each operation
- [ ] Define Element interface with accept method
- [ ] Each ConcreteElement implements accept with `visitor.visit(this)`
- [ ] Visitor methods are type-specific (Circle, Rectangle, etc.)
- [ ] Consider if object structure is stable (rarely add types)
- [ ] Provide element getters for visitor to access data
- [ ] Don't use if element structure changes frequently
- [ ] Consider thread-safety if visitors store state
- [ ] Document that adding element type requires updating all visitors

## 📊 Pattern Template

```java
// 1. Visitor Interface
interface Visitor {
    void visit(ConcreteElementA element);
    void visit(ConcreteElementB element);
}

// 2. Concrete Visitors
class ConcreteVisitor1 implements Visitor {
    public void visit(ConcreteElementA e) {
        // Operation on A
    }

    public void visit(ConcreteElementB e) {
        // Operation on B
    }
}

// 3. Element Interface
interface Element {
    void accept(Visitor visitor);
}

// 4. Concrete Elements
class ConcreteElementA implements Element {
    public void accept(Visitor visitor) {
        visitor.visit(this);  // Double dispatch
    }

    // Element-specific methods
    public String getDataA() { return "A"; }
}

class ConcreteElementB implements Element {
    public void accept(Visitor visitor) {
        visitor.visit(this);  // Double dispatch
    }

    public String getDataB() { return "B"; }
}

// 5. Usage
List<Element> elements = Arrays.asList(
    new ConcreteElementA(),
    new ConcreteElementB()
);

Visitor visitor = new ConcreteVisitor1();
for (Element e : elements) {
    e.accept(visitor);  // Double dispatch
}
```

## 💡 Remember
> "Visitor is like a tour guide: the buildings (elements) stay the same, but different guides (visitors) tell different stories (operations) about them."

## 📈 Decision Matrix

| Scenario | Use Visitor? |
|----------|-------------|
| 10 operations, 3 types | ✅ Yes |
| 3 operations, 10 types | ❌ No |
| Operations change frequently | ✅ Yes |
| Types change frequently | ❌ No |
| Need to traverse object structure | ✅ Yes (with composite) |
| Operations belong in element classes | ❌ No |

---

**For Amazon Interviews**: Focus on **separation of concerns** (why), **double dispatch** (how it works), **trade-offs** (easy to add operations, hard to add types), and when NOT to use Visitor (volatile hierarchies). Be ready to code the accept/visit pattern and discuss real-world use cases like compilers or file system operations.
