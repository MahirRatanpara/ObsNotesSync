# Event-Driven Architecture

## Why It Matters

The default way large systems decouple services. Interviewers use it to test whether you understand the costs, not just the benefits.

## Core Idea

Services communicate by publishing **facts about the past** rather than issuing commands. Producers don't know who consumes; consumers don't know who produced.

| | Command | Event |
|---|---|---|
| Tense | Imperative — `ChargeCard` | **Past tense — `PaymentCompleted`** |
| Recipient | One, known | Many, unknown |
| Expects a response | Yes | No |
| Can be rejected | Yes | **No — it already happened** |

**Naming events in the past tense isn't cosmetic.** `OrderPlaced` says something happened; `PlaceOrder` is a disguised command with a queue in front of it, and it reintroduces the coupling you were trying to remove.

## What You Gain

| Benefit | Detail |
|---|---|
| **Temporal decoupling** | The consumer can be down; the broker holds the event |
| **Loose coupling** | Add a consumer without touching the producer |
| **Load levelling** | The queue absorbs bursts the consumer can't handle |
| **Scalability** | Consumers scale independently |
| **Auditability** | The event log is a record of what happened |

## What You Pay

| Cost | Detail |
|---|---|
| **Eventual consistency** | State converges; it isn't immediately correct everywhere |
| **Debugging difficulty** | No stack trace crosses the broker — you need distributed tracing |
| **Ordering** | Only guaranteed within a partition |
| **Duplicates** | At-least-once delivery means consumers must be idempotent |
| **No backpressure to the producer** | The producer can't tell it's overwhelming consumers |
| **Emergent complexity** | Nobody can see the whole flow in one place |

**The honest summary:** event-driven architecture trades *immediate correctness and traceability* for *decoupling and elasticity*. Say that — it's the judgement being assessed.

## Event Notification vs Event-Carried State Transfer

| | Notification | State transfer |
|---|---|---|
| Payload | Just an id — `{orderId: 123}` | The full relevant state |
| Consumer then | **Calls back** to fetch details | Uses the payload directly |
| Coupling | Runtime dependency on the producer | **None at read time** |
| Payload size | Tiny | Large |
| Staleness | Always current | Snapshot at publish time |

**State transfer is usually better** — it removes the synchronous callback that recreates the coupling. The cost is bigger messages and consumers holding replicated data.

A common trap: publishing a notification, then having five consumers immediately call back to the producer. You've built a fan-out DDoS on yourself, and the producer is now on the critical path again.

## CQRS

Separate the **write model** from the **read model**.

```
Commands → Write model (normalised, transactional)
              ↓ events
           Read model(s) (denormalised, per query shape)
Queries  → Read model
```

**When it earns its place:**
- Read and write loads differ by orders of magnitude
- Query shapes are very different from the write shape
- Several read models are needed (search, analytics, API)

**When it doesn't:** simple CRUD. CQRS adds real complexity — two models, sync machinery, and eventual consistency between them.

**The consistency problem:** a user writes, then immediately reads and doesn't see their change. Fixes: read from the write model briefly after a write, return the new state in the write response, or show optimistic UI.

## Event Sourcing

Store the **sequence of events** as the source of truth; current state is the fold over them.

```
AccountOpened(id, 0) → Deposited(100) → Withdrew(30) → balance = 70
```

| Gain | Cost |
|---|---|
| Complete audit trail | Rebuilding state is slow → need **snapshots** |
| Time travel — state at any past point | Querying current state requires projections |
| Debug by replaying | **Schema evolution is genuinely hard** — old events are immutable |
| Fixes are new events, never mutations | Steep learning curve; hard to hire for |

**Event sourcing is a big commitment and often over-applied.** Use it where the audit trail *is* the business requirement — ledgers, trading, compliance. For most CRUD, it's expensive complexity.

**Event sourcing and CQRS are separate.** You can do either alone. They're often paired because event sourcing makes projections natural.

**Schema evolution is the risk to name:** you cannot change events already written. You need upcasters, versioned event types, or tolerant readers from day one.

## Delivery Guarantees

| Guarantee | How |
|---|---|
| At-most-once | Ack before processing |
| **At-least-once** | Ack after processing — the practical default |
| Exactly-once | **Doesn't exist end-to-end** — at-least-once + idempotent consumer |

Every consumer needs an idempotency key. See [Idempotent Consumers](../../07%20Messaging%20and%20Kafka/Reliability%20Patterns/Idempotent%20Consumers.md).

## The Dual-Write Problem

Updating the database and publishing an event are two operations with no shared transaction. Crash between them and they diverge.

**Solution: the outbox pattern** — write the event into an `outbox` table in the same local transaction, and have a relay (or CDC) publish from it. Covered in [Multi-Step Processes and Saga](../Patterns/Multi%20Step%20Processes%20and%20Saga.md).

## Schema Management

Events are a public contract consumed by services you don't control.

- Use a **schema registry** (Avro, Protobuf) with compatibility checks
- Prefer **backward-compatible** changes: add optional fields; never remove or repurpose
- Version the event type when a breaking change is unavoidable
- Consumers should **tolerate unknown fields**

**Treating events as a versioned API is the discipline that separates working event systems from broken ones.**

## When Not To Use It

- Synchronous request/response is genuinely required
- Strong consistency is a hard requirement
- The system is small and the team can't absorb the operational cost
- The flow is a simple linear pipeline — a queue may be enough without the architecture

## Common Mistakes

- Command-shaped events (`PlaceOrder` instead of `OrderPlaced`)
- Dual writes without an outbox
- Non-idempotent consumers
- Claiming exactly-once end to end
- No schema registry, so a producer change breaks consumers silently
- Choreography for a complex flow, leaving nobody able to describe the process
- Adopting event sourcing for ordinary CRUD

## Related Topics

- [Multi-Step Processes and Saga](../Patterns/Multi%20Step%20Processes%20and%20Saga.md)
- [Kafka Deep Dive](../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md)
- [Consistency Models](../../09%20Distributed%20Systems/Consistency/Consistency%20Models.md)
- [Observer](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Observer.md)

## Revision Summary

Publish past-tense facts rather than commands. Gains decoupling and elasticity; costs immediate consistency and traceability. Prefer event-carried state transfer over notification-plus-callback. CQRS and event sourcing are separate, powerful, and frequently over-applied. Use an outbox for atomic publish and a schema registry for compatibility.

## Quick Recall

- Events are **past tense** facts, not commands
- State transfer beats notification + callback
- Trades consistency and traceability for decoupling
- CQRS ≠ event sourcing — either can stand alone
- Event sourcing's hard part is **schema evolution**
- Outbox pattern for the dual-write problem
- Every consumer must be idempotent
