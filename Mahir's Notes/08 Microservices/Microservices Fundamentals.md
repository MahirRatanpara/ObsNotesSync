# Microservices Fundamentals

## Why It Matters

The decomposition decision is the one you cannot easily undo. Interviewers ask to see whether you understand the costs, not just the benefits.

## What You Actually Gain

| Benefit | Reality check |
|---|---|
| **Independent deployment** | Real, and the strongest argument |
| **Team autonomy** | Real — this is usually the actual driver |
| Independent scaling | Real, but often achievable with a modular monolith |
| Technology diversity | Real, and mostly a liability |
| Fault isolation | **Only with circuit breakers and bulkheads** — otherwise failures cascade |

**The honest framing: microservices are an organisational solution before a technical one.** Conway's Law — a system's architecture mirrors the communication structure of the team that built it. If you have one team, you don't need microservices; you need a well-structured monolith.

## What You Pay

| Cost | Detail |
|---|---|
| **Distributed transactions vanish** | You need [sagas](Multi%20Step%20Processes%20and%20Saga.md) and compensating actions |
| **Every call can fail** | Timeouts, retries, circuit breakers everywhere |
| **Debugging is much harder** | No stack trace crosses the network — you need tracing |
| Operational overhead | N deployment pipelines, N dashboards, N on-call surfaces |
| Data duplication | No joins across services |
| **Testing** | Integration testing becomes genuinely hard |
| Latency | Every hop adds a network round trip |

**Start with a modular monolith.** Extract services when a specific, demonstrated need appears — a component with different scaling needs, a team that's blocked on deployment coordination, or a bounded context that's genuinely independent.

**Saying "I'd start with a monolith and extract later" is a strong signal, not a weak one.** Premature decomposition is far more expensive to reverse than delayed decomposition.

## How To Draw Boundaries

**By business capability, not by technical layer.**

```
✗ WRONG: user-service, database-service, api-service, validation-service
✓ RIGHT: ordering, payments, inventory, shipping, identity
```

A "database service" means every other service is coupled to it and nothing can deploy independently — you've built a distributed monolith, which has all the costs and none of the benefits.

**Domain-Driven Design gives the vocabulary:**

| Concept | Meaning |
|---|---|
| **Bounded context** | A boundary within which a model is consistent — usually one service |
| Ubiquitous language | Shared terms within a context; "customer" may mean different things in billing and support |
| Aggregate | A consistency boundary — a transaction should not span aggregates |
| Anti-corruption layer | An [adapter](Adapter.md) translating another context's model into yours |

**The practical test for a good boundary:**

1. Can it be deployed without coordinating with others?
2. Does it own its data exclusively?
3. Does a typical feature change touch only this service?
4. Does one team own it?

**If a typical change requires deploying three services together, the boundary is wrong.** That's the diagnostic to state.

## Database Per Service

**Non-negotiable.** A shared database means:

- Schema changes require cross-team coordination
- Services couple through table structure, invisibly
- You cannot deploy or scale independently

**Consequences you must handle:**

| Problem | Solution |
|---|---|
| No cross-service joins | API composition, or a read model built from events |
| No distributed transactions | Saga with compensating actions |
| Data duplication | Accept it; sync via events |
| Reporting across services | A separate analytical store fed by CDC |

**Data duplication is correct here, not a smell.** The ordering service holding a copy of the customer's name is fine — it's a snapshot at order time, and arguably more correct than a live lookup.

## Communication

| Style | Use |
|---|---|
| **Synchronous (REST/gRPC)** | The caller needs the answer now |
| **Asynchronous (events)** | Fire-and-forget, fan-out, temporal decoupling |

**Prefer asynchronous where the semantics allow.** Every synchronous call couples availability: if A calls B synchronously, A's uptime is bounded by B's. Chain four services and your availability is the product of four numbers.

```
99.9% × 99.9% × 99.9% × 99.9% = 99.6%   (~3.5 hours downtime/month)
```

**That arithmetic is worth stating** — it's the concrete argument against deep synchronous chains.

**Avoid chatty communication.** If A calls B five times per request, either the boundary is wrong or you need a coarser-grained API.

## The Distributed Monolith — The Failure Mode To Name

Symptoms:

- Services must be deployed together
- A shared database
- Synchronous call chains three or more deep
- One service's schema change breaks others
- Cannot test a service in isolation

**This has every cost of microservices and none of the benefits.** It's the most common outcome of premature decomposition, and naming it demonstrates real experience.

## Cross-Cutting Concerns

| Concern | Where it lives |
|---|---|
| Authentication | [API gateway](API%20Gateway.md) |
| Authorisation | **In the service** — only it knows its rules |
| Rate limiting | Gateway |
| Retries, timeouts, circuit breaking | Library or [service mesh](Service%20Mesh.md) |
| Tracing | Auto-instrumentation, propagated headers |
| Configuration | Central config service or environment |

## Migration: Strangler Fig

Extracting from a monolith incrementally:

1. Put a facade or proxy in front of the monolith
2. Build the new service alongside
3. Route a slice of traffic to it
4. Verify by comparing outputs (shadow traffic)
5. Cut over fully
6. Delete the old code path

**Extract the least-coupled, highest-value component first.** The riskiest thing you can do is extract the core domain first — it has the most dependencies and the most business risk.

**Data migration is the hard part**, not the code. Dual-write with reconciliation, or CDC from the monolith's database, until the new service owns the data.

## When Microservices Are Wrong

- Small team (fewer than ~15 engineers)
- Early-stage product with changing boundaries
- No DevOps capability — you'll drown in operations
- Genuinely tightly-coupled domain
- Existing monolith performing fine

**"The domain isn't well understood yet, so I'd keep it modular within one deployable and extract once boundaries stabilise" is a mature answer.**

## Common Mistakes

- Decomposing by technical layer
- Shared database
- Deep synchronous chains
- Extracting before boundaries are understood
- No distributed tracing
- Ignoring the availability multiplication
- Treating data duplication as a defect
- Microservices for a five-person team

## Related Topics

- [API Gateway](API%20Gateway.md)
- [Service Discovery](Service%20Discovery.md)
- [Observability](Observability.md)
- [Multi-Step Processes and Saga](Multi%20Step%20Processes%20and%20Saga.md)
- [Circuit Breaker](Circuit%20Breaker.md)

## Revision Summary

Microservices solve organisational scaling first and technical scaling second. Draw boundaries by business capability with a database per service. Prefer asynchronous communication, because synchronous chains multiply availability downward. Start with a modular monolith and extract via strangler fig once boundaries are proven.

## Quick Recall

- Conway's Law — architecture mirrors team structure
- Boundaries by **business capability**, never technical layer
- **Database per service** is non-negotiable
- Availability multiplies: 4 × 99.9% ≈ 99.6%
- Data duplication is correct, not a smell
- **Distributed monolith** = deploy together, shared DB, deep chains
- Strangler fig for migration; extract least-coupled first
- Start with a monolith
