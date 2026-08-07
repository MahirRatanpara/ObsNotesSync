# Composite

## Why It Matters

The pattern for tree structures where clients shouldn't care whether they're holding a leaf or a branch. File systems, UI hierarchies, and org charts are all Composite.

## Core Idea

Leaves and containers implement the **same interface**, so client code treats an individual object and a whole subtree identically.

```java
interface FileSystemNode {
    String getName();
    long getSize();
}

class FileNode implements FileSystemNode {                 // leaf
    private final long size;
    public long getSize() { return size; }
}

class DirectoryNode implements FileSystemNode {            // composite
    private final List<FileSystemNode> children = new ArrayList<>();
    public void add(FileSystemNode n) { children.add(n); }
    public long getSize() {
        return children.stream().mapToLong(FileSystemNode::getSize).sum();   // recursion
    }
}

root.getSize();   // client doesn't know or care about the shape
```

**The recursive aggregation in the composite is the pattern.** The client writes no traversal code at all.

## The Central Design Trade-Off

Where do child-management methods (`add`, `remove`, `getChild`) go?

| Approach | Where | Pros | Cons |
|---|---|---|---|
| **Transparency** | On the base interface | Uniform treatment; client never type-checks | Leaves must implement `add()` — usually by throwing, an **LSP violation** |
| **Safety** | Only on the composite | Type-safe; leaves have no meaningless methods | Client must check the type before adding |

**GoF favours transparency; modern practice favours safety.** In an interview, name the trade-off explicitly and pick safety, justifying it with LSP. That reasoning is what's being assessed.

## Real Examples

| Domain | Leaf | Composite |
|---|---|---|
| File system | File | Directory |
| UI toolkits | Button | Panel / Container |
| Org chart | Individual contributor | Manager |
| Graphics | Shape | Group |
| Menus | Menu item | Submenu |
| Expression trees | Literal | Operator node |
| Java Swing | `JButton` | `JPanel` |

## Combining With Visitor

Composite defines the structure; [Visitor](Visitor.md) adds operations over it without modifying the node classes. Compilers use exactly this pair: Composite for the AST, Visitor for type-checking, optimisation, and code generation.

**Mentioning this pairing is a strong signal.**

## Practical Concerns

- **Deep recursion** — a very deep tree can overflow the stack. Convert to an explicit stack if depth is unbounded.
- **Cycles** — a composite containing an ancestor causes infinite recursion. Validate on `add`, or track visited nodes.
- **Caching** — recomputing `getSize()` on every call is O(n) each time. Cache and invalidate upward on mutation.
- **Parent pointers** — needed for upward traversal and cycle checks, but complicate copying and serialisation.

## When To Use

- The data is genuinely a part-whole hierarchy
- Clients should treat individual and composed objects uniformly
- Operations naturally recurse over the structure

**Don't force it** where the hierarchy is only two levels deep and fixed — a list of items inside a container doesn't need the pattern.

## Common Questions

- *Transparency vs safety?* — uniform interface with throwing leaves, versus type-safe with client-side checks. Prefer safety.
- *How do you avoid infinite recursion?* — validate against cycles on insertion.
- *How is it usually extended with operations?* — Visitor.
- *JDK example?* — Swing containers, `java.io.File` (partially).

## Common Mistakes

- Leaves throwing `UnsupportedOperationException` from `add()` without acknowledging the LSP violation
- No cycle detection
- Recomputing aggregates on every call
- Applying it to a flat collection

## Related Topics

- [Visitor](Visitor.md)
- [Iterator](Iterator.md)
- [SOLID Principles](SOLID%20Principles.md)

## Revision Summary

Leaves and composites share an interface so clients treat trees uniformly; composites recurse over children. The main decision is transparency versus safety — prefer safety and cite LSP. Pairs naturally with Visitor.

## Quick Recall

- Part-whole hierarchy, uniform treatment
- Composite recurses; leaf returns directly
- Transparency (LSP violation) vs safety (type checks) — pick safety
- Watch for cycles and deep recursion
- Composite + Visitor = AST processing
