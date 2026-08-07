# API Gateway

## Why It Matters

The single entry point for client traffic. Interviewers check whether you can distinguish it from a load balancer.

## Gateway vs Load Balancer

| | Load Balancer | API Gateway |
|---|---|---|
| Layer | L4 (or L7) | **L7, application-aware** |
| Routes by | Host / simple path | **Path, method, headers, version, claims** |
| Auth | No | **Yes** |
| Rate limiting | Basic | **Per-user, per-endpoint** |
| Aggregation | No | **Yes** |
| Protocol translation | No | REST ↔ gRPC, HTTP/2 |

**One sentence:** a load balancer distributes traffic across identical instances; a gateway routes and enriches traffic across *different* services. Production systems usually have both — LB in front of a horizontally-scaled gateway fleet.

## Responsibilities

| Concern | Why it belongs at the gateway |
|---|---|
| **Authentication** | Validate the token once, pass identity downstream |
| **Authorisation (coarse)** | Reject obviously unauthorised calls early |
| **Rate limiting** | Protect all services from one client |
| **Routing** | Map public paths to internal services |
| **Request aggregation** | One client call → several service calls |
| **Protocol translation** | Public REST, internal gRPC |
| **TLS termination** | Certificates in one place |
| **Observability** | Correlation ids, metrics, access logs |
| **Versioning** | Route `/v1` and `/v2` to different backends |

**Authentication at the gateway, authorisation in the service.** The gateway verifies *who you are*; the service decides *what you may do* with its data, because only it knows its own rules.

## Why Not Direct Client-to-Service

- The client must know every service's address, and every deployment change breaks it
- N round trips over mobile networks instead of one
- Auth logic duplicated in every service
- CORS and TLS configured everywhere
- Internal topology leaks to the public

## Backend for Frontend (BFF)

One gateway per client type — web, mobile, partner API — each aggregating and shaping responses for that client's needs. Prevents a single gateway becoming a compromise that serves nobody well. Mobile wants fewer, smaller payloads; web can afford more.

## The Risks

| Risk | Mitigation |
|---|---|
| **Single point of failure** | Multiple instances behind an LB, across zones |
| **Performance bottleneck** | Keep it stateless and horizontally scalable |
| **Becomes a monolith** | **Strictly no business logic** — routing and cross-cutting concerns only |
| Deployment coupling | Config-driven routing, not code changes per service |

**The "gateway becomes a monolith" failure is the one to name.** Once teams start adding business rules to the gateway, every change requires a gateway deploy and you've recreated the coupling microservices were meant to remove.

## Service Discovery

The gateway needs current service addresses:

| Pattern | How |
|---|---|
| Client-side discovery | Gateway queries a registry (Eureka, Consul) and load-balances itself |
| Server-side discovery | Gateway calls a stable virtual address; the platform routes (Kubernetes Service) |
| DNS-based | Simple; TTL caching makes failover slow |

In Kubernetes, server-side discovery via Services and kube-proxy is the default, so an explicit registry is often unnecessary.

## Common Products

Kong, AWS API Gateway, Envoy, Spring Cloud Gateway, NGINX, Traefik, Apigee.

## Common Mistakes

- Putting business logic in the gateway
- A single instance — an obvious SPOF
- Doing fine-grained authorisation at the gateway, which requires domain knowledge it shouldn't have
- Synchronous aggregation without timeouts and circuit breakers per downstream
- Not propagating correlation ids, making distributed tracing impossible

## Related Topics

- [Circuit Breaker](Circuit%20Breaker.md)
- [Service Mesh](Service%20Mesh.md)
- [Rate Limiting](Rate%20Limiting.md)

## Revision Summary

L7 entry point handling auth, rate limiting, routing, aggregation, and observability. Load balancers distribute across identical instances; gateways route across different services. Keep it stateless and free of business logic.

## Quick Recall

- LB = across identical instances; gateway = across different services
- AuthN at the gateway, authZ in the service
- BFF = one gateway per client type
- Never put business logic in the gateway
- Always multi-instance
