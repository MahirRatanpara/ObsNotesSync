# Adapter

## Why It Matters

The pattern you reach for whenever you integrate a third-party library or legacy system whose interface you cannot change.

## Core Idea

Convert one interface into another the client expects. The adapter sits between them and translates.

```java
interface PaymentProcessor { void pay(BigDecimal amount); }      // what our code wants

class LegacyGateway {                                             // what we're stuck with
    void makePayment(long cents, String currencyCode) { }
}

class LegacyGatewayAdapter implements PaymentProcessor {
    private final LegacyGateway legacy;
    LegacyGatewayAdapter(LegacyGateway legacy) { this.legacy = legacy; }

    public void pay(BigDecimal amount) {
        legacy.makePayment(amount.movePointRight(2).longValueExact(), "USD");
    }
}
```

## Object Adapter vs Class Adapter

| | Object adapter (composition) | Class adapter (inheritance) |
|---|---|---|
| Mechanism | Holds a reference to the adaptee | Extends the adaptee |
| Adapt subclasses too | **Yes** | No |
| Multiple adaptees | Yes | No (single inheritance in Java) |
| Preferred | **Yes** | Rarely |

**Use the object adapter.** Class adapters need multiple inheritance to be useful and couple you to the adaptee's implementation.

## Adapter vs Facade vs Decorator vs Proxy

All four wrap something. The distinctions are the interview:

| Pattern | Interface | Intent |
|---|---|---|
| **Adapter** | **Changes** it | Make an incompatible thing usable |
| **Facade** | **New, simpler** one | Hide subsystem complexity |
| **Decorator** | **Same** | Add behaviour |
| **Proxy** | **Same** | Control access |

**One line:** Adapter changes the interface, Decorator changes the behaviour, Proxy controls access, Facade simplifies many classes into one.

## Two-Way Adapter

Implements both interfaces so objects can be used on either side. Useful when two systems must interoperate bidirectionally. Rare, but worth naming.

## Real Uses

- `Arrays.asList()` — adapts an array to the `List` interface
- `InputStreamReader` — adapts a byte stream to a character stream
- `Collections.enumeration()` — adapts `Iterator` to legacy `Enumeration`
- Spring's `HandlerAdapter`
- Anti-corruption layers in DDD — adapters at a bounded-context boundary

**`Arrays.asList()` is also a good LSP example:** the returned list is fixed-size, so `add()` throws `UnsupportedOperationException` — an adapter that can't fully honour the target contract.

## When To Use

- Integrating a third-party library with a mismatched interface
- Wrapping legacy code you can't modify
- Making several incompatible implementations satisfy one interface
- Isolating your domain from an external model (anti-corruption layer)

## Limitations

- Adds an indirection layer
- If the interfaces differ semantically (not just syntactically), the adapter accumulates real logic and becomes a translation *service*, not an adapter
- Cannot invent capability the adaptee lacks — you'll be forced to throw, which weakens the contract

## Common Questions

- *Adapter vs Decorator?* — different interface vs same interface plus behaviour.
- *Adapter vs Facade?* — one class made compatible vs many classes made simple.
- *Object or class adapter?* — object, via composition.
- *What if the adaptee can't support a target method?* — that's a design smell; consider splitting the target interface (ISP).

## Common Mistakes

- Putting business logic in the adapter
- Using inheritance instead of composition
- Adapting when the real fix is to change the client interface
- Building an adapter with a dozen throwing methods instead of segregating the interface

## Related Topics

- [Facade](Facade.md)
- [Decorator](Decorator.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)

## Revision Summary

Translates an incompatible interface into the one your code expects. Use composition. Distinguish it from Facade (simplifies many), Decorator (adds behaviour), and Proxy (controls access).

## Quick Recall

- Changes the interface
- Object adapter = composition = preferred
- `Arrays.asList`, `InputStreamReader` in the JDK
- Anti-corruption layer at context boundaries
- No business logic inside
