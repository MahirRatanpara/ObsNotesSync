# Abstract Factory

## Why It Matters

The pattern for keeping a *family* of related objects consistent. Interviewers use it to test whether you understand the difference from Factory Method.

## Core Idea

An interface for creating **families of related products** without specifying concrete classes. The guarantee it provides: you can never accidentally mix a Windows button with a Mac checkbox.

## Structure

```java
interface GUIFactory {
    Button createButton();
    Checkbox createCheckbox();
    Menu createMenu();
}

class WindowsFactory implements GUIFactory {
    public Button createButton()     { return new WindowsButton(); }
    public Checkbox createCheckbox() { return new WindowsCheckbox(); }
    public Menu createMenu()         { return new WindowsMenu(); }
}

class Application {
    private final GUIFactory factory;
    Application(GUIFactory factory) { this.factory = factory; }   // injected once
    void build() {
        Button b = factory.createButton();       // guaranteed same family
        Checkbox c = factory.createCheckbox();
    }
}
```

**The consistency guarantee is the whole point.** With separate factories per product, nothing stops a caller mixing families.

## Real Use Cases

| Domain | Family |
|---|---|
| Cross-platform UI | Button, Checkbox, Menu per OS |
| Multi-cloud provisioning | VM, LoadBalancer, Storage per AWS/GCP/Azure |
| Database access | Connection, Command, Transaction per vendor |
| Document formats | Parser, Renderer, Validator per PDF/DOCX |
| Environments | Real vs mock service clients for testing |

The multi-cloud example is the strongest one to reach for in an interview — provisioning an AWS VM alongside a GCP load balancer is exactly the incoherence the pattern prevents.

## Factory Method vs Abstract Factory

|                             | Factory Method                   | Abstract Factory                           |
| --------------------------- | -------------------------------- | ------------------------------------------ |
| Scope                       | One product                      | **A family**                               |
| Mechanism                   | Inheritance — subclass overrides | **Composition — inject the factory**       |
| Adding a product **type**   | Easy                             | **Hard — every factory must implement it** |
| Adding a product **family** | Easy                             | Easy — one new factory class               |

**The asymmetry is the key trade-off and the classic follow-up question.** Abstract Factory makes new *families* trivial and new *product types* expensive, because every existing factory must be updated. If your product types churn more than your families, it's the wrong pattern.

## When To Use

- Several products must be used together consistently
- You need to swap the entire family at runtime or by configuration
- Product families are stable; new families are added occasionally

## When Not To Use

- Only one product type — use Factory Method
- Products are independent and mixing them is fine
- The set of product types changes frequently

## In The JDK

`DocumentBuilderFactory`, `TransformerFactory`, `SAXParserFactory` — each produces a coherent set of parsing objects.

## Common Questions

- *Difference from Factory Method?* — family vs single product; composition vs inheritance.
- *What's the main drawback?* — adding a new product type forces a change in every concrete factory (an OCP violation on that axis).
- *How is the family chosen?* — configuration, environment, or DI wiring, resolved once at startup.

## Common Mistakes

- Using it for unrelated products that never need to be consistent
- A factory interface that grows to a dozen methods — a sign the "family" isn't cohesive
- Instantiating the concrete factory inside business logic instead of injecting it
- Confusing it with Factory Method in interviews

## Related Topics

- [Factory Method](Factory%20Method.md)
- [Builder](Builder.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)

## Revision Summary

Creates families of related products so they stay mutually consistent. Composition-based, injected once. New families are cheap; new product types are expensive because every factory must implement them.

## Quick Recall

- Family, not one product
- Guarantees no cross-family mixing
- Inject the factory; don't `new` it in business logic
- New family = easy; new product type = touches every factory
- Multi-cloud provisioning is the best example
