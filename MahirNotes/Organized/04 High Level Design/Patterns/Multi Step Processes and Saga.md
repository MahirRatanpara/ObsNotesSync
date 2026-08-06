# Multi-Step Processes and Saga

## Why It Matters

Once an operation spans several services, you can't wrap it in a database transaction. Every "book a flight, hotel, and car atomically" question is asking about this.

## Why Distributed Transactions Don't Work

**Two-phase commit (2PC)** gives atomicity across services:

1. **Prepare** — coordinator asks all participants to prepare; each locks resources and votes
2. **Commit** — if all voted yes, coordinator tells everyone to commit

**Why it's avoided in microservices:**

| Problem | Detail |
|---|---|
| **Blocking** | Participants hold locks between prepare and commit |
| **Coordinator failure** | If it dies after prepare, participants are stuck holding locks indefinitely |
| Availability | Requires **all** participants up — availability is the product of each |
| Latency | Two round trips to every participant |
| Support | Most modern stores (Cassandra, DynamoDB, Kafka) don't offer XA |

**2PC trades availability for atomicity**, which is the wrong trade for most user-facing systems. Say this — it's the setup for Saga.

## Saga

Replace one distributed transaction with a **sequence of local transactions**, each with a **compensating action** that semantically undoes it.

```
Book flight → Book hotel → Book car
                              ↓ fails
Cancel flight ← Cancel hotel ←┘        (compensate in reverse)
```

**Compensation is not rollback.** A rollback erases history; compensation adds a *new* transaction that offsets the old one. A refund is not the deletion of a charge — both appear in the ledger. This distinction matters and interviewers ask about it.

## Orchestration vs Choreography

| | Orchestration | Choreography |
|---|---|---|
| Control | A central orchestrator drives each step | Each service reacts to events |
| Visibility | **Easy — one place shows the state** | Hard — logic spread across services |
| Coupling | Orchestrator knows all participants | Loose |
| Adding a step | Change the orchestrator | Add a subscriber |
| Debugging | **Straightforward** | Requires distributed tracing |
| Failure point | Orchestrator (must be HA) | None central |
| Risk | Orchestrator becomes a god service | **Cyclic event chains nobody understands** |

**Orchestration for complex flows; choreography for simple ones.**

The honest guidance: choreography looks elegant with three services and becomes unmaintainable with eight, because no single artifact describes the business process. Most teams that start with choreography migrate to orchestration. Saying this demonstrates real experience.

### Orchestration sketch
```java
try {
    var flight = flightService.book(req);        // step 1
    try {
        var hotel = hotelService.book(req);      // step 2
        try {
            carService.book(req);                // step 3
        } catch (Exception e) { hotelService.cancel(hotel); throw e; }
    } catch (Exception e) { flightService.cancel(flight); throw e; }
} catch (Exception e) { markFailed(req); }
```
Nested try/catch doesn't scale past three steps — which is why **workflow engines** exist.

## Workflow Engines

Temporal, AWS Step Functions, Camunda, Netflix Conductor.

They provide what hand-rolled sagas lack:

- **Durable execution** — process state survives crashes and restarts
- Automatic retries with backoff per step
- Timeouts and human-in-the-loop steps
- Built-in compensation ordering
- Visibility into every in-flight workflow

```java
// Temporal-style: this survives process restarts mid-execution
public void bookTrip(TripRequest req) {
    var flight = activities.bookFlight(req);
    saga.addCompensation(() -> activities.cancelFlight(flight));
    var hotel = activities.bookHotel(req);
    saga.addCompensation(() -> activities.cancelHotel(hotel));
    activities.bookCar(req);
}
```

**Recommending a workflow engine over hand-rolled orchestration for anything non-trivial is the mature answer.**

## What Saga Gives Up

Saga provides **ACD**, not ACID — it drops **Isolation**.

Intermediate states are visible: after booking the flight but before the hotel, another process can see a booked flight for a trip that will be cancelled.

**Countermeasures** (from Garcia-Molina's original paper):

| Technique | Meaning |
|---|---|
| **Semantic lock** | Mark the record as PENDING so others know it's in flight |
| **Commutative updates** | Order-independent operations (increments) avoid conflicts |
| **Pessimistic view** | Reorder steps so risky ones happen last |
| **Reread value** | Verify unchanged before acting |
| **Version file** | Record operations and reorder them |
| **By value** | Route low-risk requests through saga, high-risk through 2PC |

**The semantic lock is the one to name** — a PENDING status field is the standard practical answer.

## Compensation Is Hard

| Problem | Handling |
|---|---|
| **Compensation itself fails** | Retry with backoff; escalate to a DLQ and alert a human |
| **Non-compensatable steps** | Order them **last** — you cannot un-send an email |
| **Compensation must be idempotent** | It will be retried |
| **Pivot transaction** | The point after which the saga must go forward, never back |

**Ordering steps so irreversible actions come last is the key design move.** Send the confirmation email after everything else has succeeded.

## Outbox Pattern

A saga step must update its database **and** publish an event. Two systems, no shared transaction — you can do one and crash before the other.

**Fix:** write the event to an `outbox` table in the **same local transaction** as the business change. A separate relay (or CDC via Debezium) reads the outbox and publishes.

```sql
BEGIN;
  UPDATE orders SET status = 'PAID' WHERE id = ?;
  INSERT INTO outbox (topic, payload) VALUES ('order.paid', ?);
COMMIT;
-- relay publishes from outbox, marks sent
```

**This gives at-least-once publication with no dual-write problem, and it's the expected answer to "how do you atomically update state and publish an event?"**

## Common Mistakes

- Proposing 2PC without acknowledging its blocking and availability costs
- Assuming compensation is rollback
- Non-idempotent compensating actions
- Ignoring lost isolation — no PENDING states
- Irreversible steps early in the sequence
- Dual-writing to the database and broker without an outbox
- Hand-rolling orchestration for an eight-step process

## Related Topics

- [Idempotent Consumers](../../07%20Messaging%20and%20Kafka/Reliability%20Patterns/Idempotent%20Consumers.md)
- [Two Generals Problem](../../09%20Distributed%20Systems/Theory/Two%20Generals%20Problem.md)
- [Consistency Models](../../09%20Distributed%20Systems/Consistency/Consistency%20Models.md)
- [Kafka Deep Dive](../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md)

## Revision Summary

2PC blocks and couples availability, so distributed transactions become sagas: local transactions plus compensating actions. Orchestration gives visibility, choreography gives decoupling; prefer orchestration beyond simple flows and use a workflow engine. Saga sacrifices isolation — use semantic locks. Pair with the outbox pattern to publish events atomically.

## Quick Recall

- 2PC blocks on coordinator failure — avoided in microservices
- Saga = local transactions + compensations, applied in reverse
- Compensation ≠ rollback; it's a new offsetting transaction
- Orchestration = visible; choreography = decoupled but opaque
- Saga drops **Isolation** → PENDING semantic locks
- Irreversible steps go **last**
- Outbox table solves the dual-write problem
