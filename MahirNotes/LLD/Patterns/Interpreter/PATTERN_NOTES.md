# Interpreter Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Define a representation for a language's grammar along with an interpreter that uses this representation to interpret sentences in the language.

## 📖 The Problem
**Without Interpreter**: Hard-coded parsing logic
```java
public class Calculator {
    public int evaluate(String expression) {
        // Hard-coded parsing
        if (expression.contains("+")) {
            String[] parts = expression.split("\\+");
            return Integer.parseInt(parts[0]) + Integer.parseInt(parts[1]);
        } else if (expression.contains("-")) {
            String[] parts = expression.split("-");
            return Integer.parseInt(parts[0]) - Integer.parseInt(parts[1]);
        }
        // ❌ Hard to extend
        // ❌ Doesn't handle complex expressions like "5 + 3 - 2"
        // ❌ No grammar structure
    }
}
```

**With Interpreter**: Grammar-based interpretation
```java
// Grammar:
// expression ::= number | addition | subtraction
// addition ::= expression + expression
// subtraction ::= expression - expression

interface Expression {
    int interpret();
}

class Number implements Expression {
    private int value;
    public int interpret() { return value; }
}

class Addition implements Expression {
    private Expression left, right;
    public int interpret() {
        return left.interpret() + right.interpret();
    }
}

// Parse: "5 + 3 - 2" → Addition(5, Subtraction(3, 2))
// Evaluate: 5 + (3 - 2) = 6
```

## 🔑 Key Concept
```
Grammar Rules → Abstract Syntax Tree (AST) → Interpret
```

**Core Idea**: Each grammar rule becomes a class; composite structure represents parsed expressions.

**Typical Use**: Small, simple languages (SQL, regex, math expressions)

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Simple grammar | ✗ Complex grammar (use parser generator) |
| ✓ Grammar rarely changes | ✗ Grammar changes frequently |
| ✓ Efficiency not critical | ✗ Performance critical |
| ✓ Need to interpret sentences | ✗ Just need to parse (not evaluate) |

## 📐 Structure

```
┌─────────────────┐
│  AbstractExpr   │ ◄─── Base expression
├─────────────────┤
│ +interpret()    │
└────────▲────────┘
         │
    ┌────┴─────┬──────────────┐
    │          │              │
┌───▼─────┐ ┌──▼──────┐ ┌────▼────────┐
│Terminal │ │NonTermi │ │NonTerminal2 │
│  Expr   │ │nal1     │ │             │
├─────────┤ ├─────────┤ ├─────────────┤
│+interpr │ │+interpr │ │+interpret() │
│  et()   │ │  et()   │ │             │
└─────────┘ └─────────┘ └─────────────┘
             (composite)
```

**Terminal Expression**: Leaf nodes (numbers, variables)
**Non-Terminal Expression**: Composite nodes (operations)

## 💻 Implementation Pattern

### Example: Boolean Expression Interpreter

**Grammar:**
```
expression ::= constant | variable | and | or | not
constant ::= true | false
variable ::= any identifier
and ::= expression AND expression
or ::= expression OR expression
not ::= NOT expression
```

### 1. Abstract Expression
```java
public interface Expression {
    boolean interpret(Context context);
}
```

### 2. Context (Variable Values)
```java
public class Context {
    private Map<String, Boolean> variables = new HashMap<>();

    public void setVariable(String name, boolean value) {
        variables.put(name, value);
    }

    public boolean getVariable(String name) {
        return variables.getOrDefault(name, false);
    }
}
```

### 3. Terminal Expressions
```java
// Constant: true or false
public class ConstantExpression implements Expression {
    private boolean value;

    public ConstantExpression(boolean value) {
        this.value = value;
    }

    @Override
    public boolean interpret(Context context) {
        return value;
    }

    @Override
    public String toString() {
        return String.valueOf(value);
    }
}

// Variable: looks up value in context
public class VariableExpression implements Expression {
    private String name;

    public VariableExpression(String name) {
        this.name = name;
    }

    @Override
    public boolean interpret(Context context) {
        return context.getVariable(name);
    }

    @Override
    public String toString() {
        return name;
    }
}
```

### 4. Non-Terminal Expressions
```java
// AND: both must be true
public class AndExpression implements Expression {
    private Expression left;
    private Expression right;

    public AndExpression(Expression left, Expression right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public boolean interpret(Context context) {
        return left.interpret(context) && right.interpret(context);
    }

    @Override
    public String toString() {
        return "(" + left + " AND " + right + ")";
    }
}

// OR: at least one must be true
public class OrExpression implements Expression {
    private Expression left;
    private Expression right;

    public OrExpression(Expression left, Expression right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public boolean interpret(Context context) {
        return left.interpret(context) || right.interpret(context);
    }

    @Override
    public String toString() {
        return "(" + left + " OR " + right + ")";
    }
}

// NOT: negation
public class NotExpression implements Expression {
    private Expression expression;

    public NotExpression(Expression expression) {
        this.expression = expression;
    }

    @Override
    public boolean interpret(Context context) {
        return !expression.interpret(context);
    }

    @Override
    public String toString() {
        return "NOT(" + expression + ")";
    }
}
```

### 5. Usage
```java
// Build expression: (x AND y) OR (NOT z)
// Manually construct AST
Expression x = new VariableExpression("x");
Expression y = new VariableExpression("y");
Expression z = new VariableExpression("z");

Expression xAndY = new AndExpression(x, y);
Expression notZ = new NotExpression(z);
Expression expression = new OrExpression(xAndY, notZ);

// Set variable values
Context context = new Context();
context.setVariable("x", true);
context.setVariable("y", false);
context.setVariable("z", false);

// Interpret
System.out.println("Expression: " + expression);
System.out.println("Result: " + expression.interpret(context));

// Output:
// Expression: ((x AND y) OR NOT(z))
// Result: true  (because NOT z is true)

// Change values
context.setVariable("z", true);
System.out.println("Result: " + expression.interpret(context));
// Output: false (because x AND y is false, and NOT z is false)
```

## 🎓 Real-World Examples

| Domain | Grammar | Interpreter |
|--------|---------|-------------|
| **SQL** | SELECT, WHERE, FROM | SQL Engine |
| **Regex** | *, +, ?, [] | Pattern Matcher |
| **Math** | +, -, *, / | Expression Evaluator |
| **Scripting** | if, while, for | Script Engine |
| **Format** | {name}, {age} | Template Engine |

### Math Expression Evaluator
```java
// Grammar: expression ::= number | add | subtract | multiply | divide

interface MathExpression {
    int interpret();
}

class Number implements MathExpression {
    private int value;
    public Number(int value) { this.value = value; }
    public int interpret() { return value; }
}

class Add implements MathExpression {
    private MathExpression left, right;

    public Add(MathExpression left, MathExpression right) {
        this.left = left;
        this.right = right;
    }

    public int interpret() {
        return left.interpret() + right.interpret();
    }
}

class Multiply implements MathExpression {
    private MathExpression left, right;

    public Multiply(MathExpression left, MathExpression right) {
        this.left = left;
        this.right = right;
    }

    public int interpret() {
        return left.interpret() * right.interpret();
    }
}

// Build: (5 + 3) * 2
MathExpression expr = new Multiply(
    new Add(new Number(5), new Number(3)),
    new Number(2)
);

System.out.println(expr.interpret());  // Output: 16
```

## 🔧 Parsing (Building AST)

Interpreter pattern doesn't specify how to parse; typically use:

### Option 1: Manual Construction
```java
// Manually build AST
Expression expr = new Add(new Number(5), new Number(3));
```

### Option 2: Recursive Descent Parser
```java
public class Parser {
    private String[] tokens;
    private int pos = 0;

    public Expression parse(String input) {
        tokens = input.split(" ");
        return parseExpression();
    }

    private Expression parseExpression() {
        String token = tokens[pos++];

        if (token.matches("\\d+")) {
            return new Number(Integer.parseInt(token));
        } else if (token.equals("+")) {
            Expression left = parseExpression();
            Expression right = parseExpression();
            return new Add(left, right);
        }
        // ... handle other operators
        throw new IllegalArgumentException("Invalid token: " + token);
    }
}

// Usage (prefix notation)
Parser parser = new Parser();
Expression expr = parser.parse("+ 5 3");  // 5 + 3
System.out.println(expr.interpret());  // 8
```

### Option 3: Parser Generator (ANTLR, JavaCC)
For complex grammars, use parser generators instead of Interpreter pattern.

## ⚖️ Interpreter vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Interpreter** | Interpret language grammar | Evaluates expressions |
| **Composite** | Tree structure | Generic tree, not language-specific |
| **Visitor** | Operations on structure | Separates operations from structure |
| **Strategy** | Choose algorithm | Single algorithm, not grammar |

### Interpreter Uses Composite
Interpreter often uses Composite pattern for AST structure:
- Terminal expressions = leaves
- Non-terminal expressions = composites

## 🚨 Common Mistakes

### ❌ Mistake 1: Using for complex grammar
```java
// Wrong: Implementing full programming language with Interpreter
// ❌ Too complex, slow, hard to maintain

// Right: Use for simple DSLs only
// ✅ Boolean expressions, math formulas, simple queries
```

### ❌ Mistake 2: No context
```java
// Wrong: Hardcoding values
class Variable implements Expression {
    public int interpret() {
        return 5;  // ❌ Hardcoded!
    }
}

// Right: Use context for variables
class Variable implements Expression {
    private String name;

    public int interpret(Context ctx) {
        return ctx.getValue(name);  // ✅ Dynamic
    }
}
```

### ❌ Mistake 3: Mixing parsing and interpretation
```java
// Wrong: Interpret does parsing
public int interpret(String expression) {
    String[] parts = expression.split("\\+");  // ❌ Parsing!
    return Integer.parseInt(parts[0]) + Integer.parseInt(parts[1]);
}

// Right: Separate concerns
// 1. Parse: String → AST
// 2. Interpret: AST → Result
```

### ❌ Mistake 4: Inefficient repeated interpretation
```java
// Wrong: Re-interpret same expression multiple times
for (int i = 0; i < 1000; i++) {
    expr.interpret(context);  // ❌ Wasteful if context unchanged
}

// Right: Cache interpretation results
Map<Expression, Result> cache = new HashMap<>();
if (cache.containsKey(expr)) {
    return cache.get(expr);
} else {
    Result result = expr.interpret(context);
    cache.put(expr, result);
    return result;
}
```

### ❌ Mistake 5: Not using Composite pattern properly
```java
// Wrong: Not treating terminals and non-terminals uniformly
// ❌ Different interfaces for different expression types

// Right: Single Expression interface
interface Expression {
    int interpret(Context ctx);  // ✅ Uniform interface
}
```

## 🎤 Interview Questions & Answers

### Q1: What is the Interpreter pattern?
**A**: A behavioral pattern that defines a representation for a grammar and provides an interpreter to process sentences in that grammar. Each grammar rule becomes a class.

### Q2: When would you use Interpreter?
**A**: When:
1. Grammar is simple and well-defined
2. Efficiency is not critical
3. Need to interpret or execute domain-specific language
4. Grammar doesn't change frequently

### Q3: What are the key components?
**A**:
1. **AbstractExpression**: Interface for interpret operation
2. **TerminalExpression**: Leaf nodes (constants, variables)
3. **NonterminalExpression**: Composite nodes (operations)
4. **Context**: Global information for interpretation

### Q4: How does Interpreter relate to Composite?
**A**: Interpreter uses Composite pattern for AST structure:
- AbstractExpression = Component
- TerminalExpression = Leaf
- NonterminalExpression = Composite
Difference: Interpreter adds `interpret()` operation for language evaluation.

### Q5: What are advantages?
**A**:
1. Easy to change and extend grammar (new class per rule)
2. Easy to implement grammar (one class per rule)
3. Complex grammars are manageable (composite structure)
4. Adding new operations is easy (new method in Expression)

### Q6: What are disadvantages?
**A**:
1. **Complex grammars**: Many classes (one per rule)
2. **Performance**: Slower than compiled approach
3. **Maintenance**: Hard to maintain for large grammars
4. **Better alternatives**: Parser generators for complex grammars

### Q7: Interpreter vs Visitor?
**A**:
- **Interpreter**: Each node interprets itself (`expr.interpret()`)
- **Visitor**: External visitor interprets nodes (`visitor.visit(expr)`)
- **Interpreter**: Hard to add operations (modify all classes)
- **Visitor**: Easy to add operations (new visitor class)

### Q8: Real-world example?
**A**:
- **Java Regex**: `Pattern.compile(regex).matcher(text)`
- **SQL Engines**: Parse and execute SQL queries
- **Spring SpEL**: Expression Language for Spring
- **Template Engines**: Mustache, Thymeleaf

### Q9: When NOT to use Interpreter?
**A**:
1. Grammar is complex (use ANTLR, JavaCC instead)
2. Performance critical (compile or use parser generator)
3. Grammar changes frequently (maintenance nightmare)
4. Only need parsing, not evaluation (use parser only)

### Q10: How to optimize performance?
**A**:
1. **Caching**: Cache interpretation results
2. **Compilation**: Compile to bytecode
3. **Flyweight**: Share terminal expressions
4. **Lazy evaluation**: Evaluate only when needed
5. **Short-circuit**: For boolean expressions (AND, OR)

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Interpret sentences in a language |
| **Structure** | Grammar rules → Classes → AST |
| **Terminal** | Leaf nodes (constants, variables) |
| **Non-Terminal** | Composite nodes (operations) |
| **Context** | Stores global state (variables) |
| **Best For** | Simple DSLs, not complex languages |

## 🔍 Quick Checklist

When implementing Interpreter pattern:
- [ ] Define grammar clearly (BNF notation)
- [ ] Create AbstractExpression interface with interpret()
- [ ] Create TerminalExpression for each terminal
- [ ] Create NonterminalExpression for each rule
- [ ] Use Context for global state
- [ ] Separate parsing from interpretation
- [ ] Use Composite pattern for AST structure
- [ ] Consider performance implications
- [ ] Don't use for complex grammars (use parser generator)
- [ ] Cache results if expressions reused

## 📊 Pattern Template

```java
// 1. Abstract Expression
interface Expression {
    int interpret(Context context);
}

// 2. Terminal Expression
class Number implements Expression {
    private int value;

    public Number(int value) {
        this.value = value;
    }

    public int interpret(Context context) {
        return value;
    }
}

// 3. Non-Terminal Expression
class Add implements Expression {
    private Expression left;
    private Expression right;

    public Add(Expression left, Expression right) {
        this.left = left;
        this.right = right;
    }

    public int interpret(Context context) {
        return left.interpret(context) + right.interpret(context);
    }
}

// 4. Context
class Context {
    private Map<String, Integer> variables = new HashMap<>();

    public void set(String name, int value) {
        variables.put(name, value);
    }

    public int get(String name) {
        return variables.getOrDefault(name, 0);
    }
}

// 5. Usage
Expression expr = new Add(new Number(5), new Number(3));
Context context = new Context();
int result = expr.interpret(context);  // 8
```

## 💡 Remember
> "Interpreter is like a grammar tree: each grammar rule is a node, and interpreting means walking the tree and evaluating each node."

## 🔧 Grammar Notation (BNF)

**Backus-Naur Form (BNF)**: Standard notation for grammars

```
expression ::= term (('+' | '-') term)*
term       ::= factor (('*' | '/') factor)*
factor     ::= number | '(' expression ')'
number     ::= digit+
digit      ::= '0' | '1' | ... | '9'
```

**Translates to:**
- `expression`, `term`, `factor` → NonterminalExpression classes
- `number`, `digit` → TerminalExpression classes
- `+`, `-`, `*`, `/` → Operator classes

## 📈 When to Use What?

| Grammar Complexity | Solution |
|-------------------|----------|
| **Very Simple** (math, boolean) | Interpreter Pattern |
| **Moderate** (SQL subset, regex) | Recursive Descent Parser |
| **Complex** (full language) | Parser Generator (ANTLR, JavaCC) |
| **High Performance Needed** | Compiler (generate bytecode) |

---

**For Amazon Interviews**: Focus on **grammar representation** (BNF), **AST structure** (Composite pattern), **Terminal vs Non-Terminal** expressions, and when **NOT** to use Interpreter (complex grammars). Be ready to implement a simple math or boolean expression evaluator and discuss performance trade-offs vs parser generators.
