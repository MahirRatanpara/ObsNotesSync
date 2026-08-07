# Mediator

## Why It Matters

The cure for many-to-many coupling. When n components each reference the others, you have n² relationships; a mediator reduces it to n.

## The Problem

```java
// Every component knows every other component
class Button   { TextField field; Checkbox box; Label label; ... }
class Checkbox { Button btn; TextField field; ... }
```

Adding one component means editing all the others. Nothing can be tested or reused in isolation.

## The Solution

Components talk only to a mediator, never to each other.

```java
interface DialogMediator { void notify(Component sender, String event); }

class AuthDialog implements DialogMediator {
    private Checkbox rememberMe; private TextField username; private Button submit;

    public void notify(Component sender, String event) {
        if (sender == rememberMe && event.equals("check")) {
            username.setEnabled(rememberMe.isChecked());
        } else if (sender == submit && event.equals("click")) {
            if (validate()) authenticate();
        }
    }
}

class Checkbox extends Component {
    void check() { mediator.notify(this, "check"); }   // knows only the mediator
}
```

**n² relationships become n.** Each component knows one thing: the mediator.

## Mediator vs Observer

The pair interviewers actually probe:

| | Mediator | Observer |
|---|---|---|
| Direction | **Bidirectional** — components both notify and are commanded | **Unidirectional** — subject → observers |
| Knowledge | Components **know** the mediator | Subject doesn't know observer types |
| Coordination logic | **Centralised in the mediator** | Distributed across observers |
| Relationship | Many-to-many | One-to-many |

**One line:** Observer broadcasts events outward; Mediator coordinates peers in both directions.

They're often combined — components publish events *to* the mediator, which then commands the appropriate peers.

## Mediator vs Facade

| | Mediator | Facade |
|---|---|---|
| Subsystem knows it | **Yes** | No |
| Direction | Bidirectional | One-way (client → subsystem) |
| Adds behaviour | **Yes — coordination logic** | No, just delegation |

## Real Uses

- UI dialog coordination (the classic example)
- Air traffic control — planes talk to the tower, never to each other
- Chat rooms — the room mediates between participants
- `java.util.Timer` coordinating scheduled tasks
- Spring's `ApplicationContext` as a coordination hub
- **Message brokers** — the distributed form of Mediator
- Microservice orchestration — an orchestrator coordinating services

**Air traffic control is the cleanest analogy** and worth using verbatim.

## The Central Risk: The God Mediator

All coordination logic concentrates in one class. With many components and complex rules, the mediator becomes exactly the tangled monolith you were escaping.

**Mitigations:**
- One mediator per **cohesive group**, not one per application
- Delegate rules to strategies or handlers the mediator dispatches to
- Consider an event bus (a "dumb" mediator that only routes) when coordination is simple
- If the mediator's `notify` becomes a 200-line `if/else`, that's the signal to decompose

**Naming this risk unprompted is a strong signal** — it's the pattern's well-known failure mode.

## Orchestration vs Choreography

The distributed version of the same trade-off:

| | Orchestration (Mediator) | Choreography (Observer) |
|---|---|---|
| Control | Central coordinator | Each service reacts to events |
| Visibility | **Easy — one place to look** | Hard — logic is spread out |
| Coupling | Coordinator knows everyone | Loose |
| Single point of failure | Yes | No |

Directly relevant to Saga design in system design interviews.

## When To Use

- Components are tightly interconnected in a many-to-many web
- Reuse is blocked because components reference each other
- Coordination logic is complex and worth centralising
- You want interaction rules in one testable place

## Limitations

- Risk of a god object
- Adds indirection; control flow is less obvious
- The mediator becomes a single point of failure and a bottleneck

## Common Questions

- *Mediator vs Observer?* — bidirectional coordination with known mediator vs unidirectional broadcast.
- *Mediator vs Facade?* — subsystem knows the mediator and coordination flows both ways.
- *What's the main risk?* — the god mediator.
- *Distributed equivalent?* — a message broker or orchestrator; orchestration vs choreography.

## Common Mistakes

- One mediator for the whole application
- Components retaining direct references to each other "just for this one case", which defeats the pattern
- Business logic accumulating in the mediator that belongs in domain objects
- Using it for a genuinely one-to-many broadcast, where Observer is simpler

## Related Topics

- [Observer](Observer.md)
- [Facade](Facade.md)
- [Kafka Deep Dive](Kafka%20Deep%20Dive.md)

## Revision Summary

Centralises many-to-many interaction so components know only the mediator, turning n² relationships into n. Bidirectional, and components are aware of it — unlike Observer and Facade. The failure mode is a god mediator; scope one per cohesive group.

## Quick Recall

- n² couplings → n
- Air traffic control analogy
- Bidirectional; components know the mediator
- Observer broadcasts; Mediator coordinates
- Watch for the god mediator
- Orchestration (mediator) vs choreography (observer)
