# LLD Delivery Framework

## Why It Matters

LLD interviews are won on structure. Candidates who jump to classes without scoping produce designs that collapse under the first follow-up.

## The 35-Minute Map

| Phase | Time | Output |
|---|---|---|
| 1. Clarify requirements | 5 min | Functional list, explicit non-goals |
| 2. Identify entities | 5 min | Nouns → classes, with responsibilities |
| 3. Define relationships | 5 min | Associations, multiplicities, class skeleton |
| 4. Core API / behaviour | 10 min | Method signatures, state transitions |
| 5. Handle the follow-up | 7 min | Extend without rewriting |
| 6. Concurrency & edge cases | 3 min | Locking strategy, invariants |

## Phase 1 — Clarify

Ask, then **write the answers on the board**:

- What are the core use cases? (Cap at 3–5; ask which to prioritise.)
- Single machine or distributed? (LLD is usually single-process — confirm it.)
- Do we need persistence, or is in-memory fine?
- Is it concurrent? How many users?
- What's explicitly out of scope?

**State non-goals out loud.** "I'm going to assume no payment processing and no distributed coordination — is that right?" This prevents the interviewer from later judging you on something you deliberately excluded.

## Phase 2 — Entities

Extract nouns from the requirements, then filter: a class needs **state plus behaviour**. A noun with neither is an enum or a field.

For a parking lot: `ParkingLot`, `Level`, `ParkingSpot`, `Vehicle`, `Ticket`, `Payment`.

For each entity state its **single responsibility** in one sentence. If you can't, split it.

## Phase 3 — Relationships

| Relationship | Meaning | Lifetime |
|---|---|---|
| **Composition** | "part-of", owner controls lifecycle | Child dies with parent |
| **Aggregation** | "has-a", independent lifecycle | Child outlives parent |
| **Association** | "uses-a" | Independent |
| **Inheritance** | "is-a" | — |

**Prefer composition over inheritance.** Modern interviewers actively penalise deep hierarchies. Use inheritance only for genuine "is-a" with no behavioural exceptions; otherwise inject a strategy.

## Phase 4 — Behaviour and State

Model state explicitly with an enum and validate transitions:

```java
enum TripState { REQUESTED, DRIVER_ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED }

void startTrip() {
    if (state != TripState.DRIVER_ASSIGNED)
        throw new IllegalStateException("Cannot start from " + state);
    state = TripState.IN_PROGRESS;
}
```

**Guard every transition.** Interviewers look for this specifically — it shows you think about invalid states, not just the happy path.

If transitions get complex (more than ~4 states with branching), reach for the **State pattern**.

## Phase 5 — The Follow-Up

Every LLD interview ends with "now also support X". The design should absorb it by **adding a class, not editing existing ones** — that's the Open-Closed Principle in practice.

Common follow-ups and their answers:

| Follow-up | Pattern |
|---|---|
| "Add another pricing model" | Strategy |
| "Add another vehicle/product type" | Factory + polymorphism |
| "Notify multiple systems on an event" | Observer |
| "Add logging/caching/auth around calls" | Decorator or Proxy |
| "Support undo" | Command or Memento |
| "Add a new step to the workflow" | Chain of Responsibility or Template Method |

## Phase 6 — Concurrency

Name the shared mutable state, then pick the narrowest mechanism:

| Contention | Mechanism |
|---|---|
| Single counter | `AtomicInteger` |
| One shared map | `ConcurrentHashMap` + `compute`/`merge` |
| A resource pool | `Semaphore` |
| Compound invariant across fields | `ReentrantLock` (or `synchronized`) |
| Read-heavy, write-rare | `ReadWriteLock` |

**Lock the smallest unit possible.** Locking a whole `ParkingLot` serialises every user; locking per `Level` or per `Spot` scales. Interviewers probe exactly this.

## Anti-Patterns

- **God class** — one class doing everything
- **Anaemic model** — data classes with getters/setters and all logic in a "Service"
- **Deep inheritance** — three or more levels
- **Premature patterns** — naming patterns you don't need
- **Boolean parameters** — `book(true, false)` is unreadable; use enums
- **Public mutable fields** — always encapsulate collections (`Collections.unmodifiableList` on return)

## Common Mistakes

- Coding before scoping
- Not stating assumptions
- Ignoring concurrency until asked
- Rewriting the design when the follow-up arrives — a sign the abstraction was wrong
- Reciting pattern names without justifying them

## Related Topics

- [SOLID Principles](../SOLID/SOLID%20Principles.md)
- [OOP Core Concepts](../OOP%20Foundations/OOP%20Core%20Concepts.md)
- [Design Pattern Selection](../Design%20Patterns/Design%20Pattern%20Selection.md)
- [Concurrency in LLD](../Concurrency%20in%20LLD/Concurrency%20in%20LLD.md)

## Revision Summary

Clarify and write down scope, extract entities with single responsibilities, prefer composition, guard state transitions, and design so the follow-up is an addition rather than an edit.

## Quick Recall

- 5 min scope, 5 entities, 5 relationships, 10 behaviour, 7 follow-up, 3 concurrency
- Write non-goals on the board
- Composition over inheritance
- Guard every state transition
- Follow-up should add a class, not modify one
- Lock the smallest unit
