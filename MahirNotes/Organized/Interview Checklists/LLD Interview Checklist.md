# LLD Interview Checklist

## Scoping (first 5 minutes)

- [ ] Listed the core use cases and capped them at 3–5
- [ ] Asked which use cases matter most
- [ ] **Wrote non-goals on the board**
- [ ] Confirmed single-process vs distributed
- [ ] Confirmed whether persistence is in scope
- [ ] Asked whether it must be concurrent, and at what scale

## Entities

- [ ] Extracted nouns from the requirements
- [ ] Filtered to things with **both state and behaviour**
- [ ] Stated each class's single responsibility in one sentence
- [ ] Used enums instead of boolean or string flags
- [ ] Avoided a god class

## Relationships

- [ ] Chose composition over inheritance by default
- [ ] Justified any inheritance as a genuine is-a
- [ ] Kept the hierarchy at most two levels deep
- [ ] Marked composition vs aggregation where lifecycle differs

## Behaviour

- [ ] Defined method signatures before bodies
- [ ] Modelled lifecycle with an enum, not booleans
- [ ] **Guarded every state transition** with a validity check
- [ ] Threw meaningful exceptions on invalid transitions
- [ ] Kept collections encapsulated (returned unmodifiable views)
- [ ] Made value objects immutable

## Patterns

- [ ] Used a pattern only where it earned its place
- [ ] **Justified each pattern in one sentence**
- [ ] Did not name a pattern I wasn't using
- [ ] Replaced any growing `switch` on type with polymorphism

## Concurrency (raise it before being asked)

- [ ] Named the shared mutable state
- [ ] Stated the invariant that must hold
- [ ] **Locked the smallest unit, not the whole system**
- [ ] Chose optimistic vs pessimistic deliberately
- [ ] Used a conditional update rather than read-then-write
- [ ] Considered expiry for any held/reserved resource
- [ ] Ordered locks consistently if more than one is held

## The Follow-Up

- [ ] Extended by **adding** a class, not editing existing ones
- [ ] Did not need to rewrite the design
- [ ] Named which principle made the extension cheap

## Red Flags To Avoid

- [ ] Did not start coding before scoping
- [ ] No anaemic model (data classes + one giant Service)
- [ ] No boolean parameters in public methods
- [ ] No public mutable fields or exposed internal collections
- [ ] Did not ignore concurrency until prompted
- [ ] Did not recite pattern names without justification

## Common Problems and Their Core Pattern

| Problem | Expect |
|---|---|
| Parking Lot | Strategy (pricing), Factory (spot), per-spot locking |
| Elevator | State, Strategy (scheduling), Observer |
| Vending Machine | State |
| Movie Booking | State + hold/confirm/expire, per-seat locking |
| Rate Limiter | Strategy (algorithm), Token Bucket |
| Logging Framework | Chain of Responsibility, Strategy, Singleton |
| Splitwise | Strategy (split types), Observer |
| File System | Composite |
| Notification System | Observer + Factory + Strategy |
| Chess / Tic-Tac-Toe | Strategy (piece rules), State, Command (undo) |

## Related

- [LLD Delivery Framework](../03%20Low%20Level%20Design/In%20A%20Hurry/LLD%20Delivery%20Framework.md)
- [LLD Cheat Sheet](../Cheat%20Sheets/LLD%20Cheat%20Sheet.md)
- [Concurrency in LLD](../03%20Low%20Level%20Design/Concurrency%20in%20LLD/Concurrency%20in%20LLD.md)
