# Interpreter

## Why It Matters

The rarest GoF pattern in practice, but it appears whenever you build a rule engine, query filter, or small DSL — and those come up in LLD interviews more often than you'd expect.

## Core Idea

Define a grammar as a class hierarchy, where each rule is a class with an `interpret()` method. Evaluating an expression is a recursive walk over the resulting tree.

```java
interface Expression { boolean interpret(Context ctx); }

class Equals implements Expression {                     // terminal
    private final String field, value;
    public boolean interpret(Context ctx) { return value.equals(ctx.get(field)); }
}

class And implements Expression {                        // non-terminal
    private final Expression left, right;
    public boolean interpret(Context ctx) {
        return left.interpret(ctx) && right.interpret(ctx);
    }
}

class Or implements Expression {
    private final Expression left, right;
    public boolean interpret(Context ctx) {
        return left.interpret(ctx) || right.interpret(ctx);
    }
}

// (country = IN) AND (tier = GOLD OR spend > 1000)
Expression rule = new And(
    new Equals("country", "IN"),
    new Or(new Equals("tier", "GOLD"), new GreaterThan("spend", 1000)));

rule.interpret(customerContext);
```

## Terminal vs Non-Terminal

| Kind | Role | Example |
|---|---|---|
| **Terminal** | A leaf — evaluates directly | `Equals`, `GreaterThan`, `Literal` |
| **Non-terminal** | Composes sub-expressions recursively | `And`, `Or`, `Not` |

**This is Composite with an `interpret()` method.** Saying so out loud demonstrates that you see the relationship rather than memorising 23 unrelated patterns.

## The Context

Holds whatever the expressions need at evaluation time — variable bindings, the object under test, accumulated results. Keeping it a parameter (rather than state on the expressions) makes the expression tree **reusable and thread-safe**: build the rule once, evaluate it against many inputs concurrently.

## What Interpreter Is Not

**The pattern covers evaluation, not parsing.** Turning `"country = IN AND tier = GOLD"` into the tree is a separate concern — a hand-written recursive-descent parser, or a generator like ANTLR.

In interviews, it's usually fine to say: "I'd use a builder or a small parser to construct the tree; Interpreter defines how it evaluates." Conflating the two is a common error.

## When To Use

- A simple, **stable** grammar
- Rules change often but the grammar doesn't
- Business users need to define rules without code deploys
- Expressions must be stored, versioned, or transmitted as data

## When Not To Use

- **Complex or evolving grammars** — the class count explodes, and a parser generator is the right tool
- Performance-critical evaluation — tree walking is slow; compile to bytecode or use an expression library
- An existing library will do: SpEL, MVEL, JEXL, Drools, JSONLogic, or CEL

**Naming an existing library is a strength, not a weakness.** Interviewers want judgement, and hand-rolling an expression language is usually the wrong call.

## Real Uses

- `java.util.regex.Pattern` — a compiled regex is an expression tree
- `java.text.Format` subclasses
- Spring Expression Language (SpEL)
- Drools and other rule engines
- SQL query planners
- Feature-flag targeting rules
- Search filter builders

**Regex is the best JDK example:** `Pattern.compile()` builds the tree; `Matcher` interprets it against input.

## Adding Operations Without Editing Nodes

Once the tree exists, [Visitor](Visitor.md) lets you add operations — pretty-printing, optimisation, validation, cost estimation — without touching the expression classes.

This Composite + Interpreter + Visitor trio is exactly how compilers are structured.

## Limitations

- **One class per grammar rule** — grammars of any size become unmanageable
- Slow compared to compiled evaluation
- No parsing support
- Deep expressions risk stack overflow on recursive evaluation

## Common Questions

- *How does it relate to Composite?* — it *is* Composite, with `interpret()` as the operation.
- *Does it handle parsing?* — no, only evaluation.
- *When would you not use it?* — non-trivial grammars; reach for ANTLR or an existing expression library.
- *JDK example?* — `java.util.regex.Pattern`.
- *How do you add operations later?* — Visitor over the expression tree.

## Common Mistakes

- Using it for a grammar that will grow
- Building a bespoke DSL where SpEL or Drools would do
- Storing evaluation state on the expression objects, breaking reuse and thread safety
- Assuming the pattern includes a parser

## Related Topics

- [Composite](../Structural/Composite.md)
- [Visitor](Visitor.md)
- [Design Pattern Selection](../Design%20Pattern%20Selection.md)

## Revision Summary

Represents grammar rules as classes with an `interpret()` method, evaluated recursively over a tree. Structurally Composite. Covers evaluation only, not parsing. Suitable for small stable grammars; use an existing rule engine or parser generator otherwise.

## Quick Recall

- Grammar rule → class; evaluate recursively
- Terminal = leaf; non-terminal = composes children
- It *is* Composite plus `interpret()`
- No parsing — that's separate
- `Pattern.compile()` / `Matcher` is the JDK example
- Prefer SpEL, Drools, or ANTLR for real grammars
