# Service Discovery

## Why It Matters

In a dynamic environment instances appear, disappear, and change addresses constantly. Hardcoded hosts stop working the moment you autoscale.

## The Problem

```
Static config:  payment-service = 10.0.1.5:8080
Reality:        instances scale 3 → 30 → 5, IPs change on every deploy
```

You need a way to answer "where is service X right now?" that stays current automatically.

## The Two Patterns

### Client-Side Discovery

```
Client → Registry: "where is payment-service?"
Registry → Client: [10.0.1.5, 10.0.1.7, 10.0.1.9]
Client picks one (load balances itself) → calls it
```

| | |
|---|---|
| Pros | No extra hop; client controls the load-balancing algorithm; can do zone-aware routing |
| Cons | **Discovery logic in every client, in every language**; clients must handle registry failure |
| Examples | Netflix Eureka + Ribbon, Consul with a client library |

### Server-Side Discovery

```
Client → stable address (load balancer / DNS name)
Router → looks up healthy instances → forwards
```

| | |
|---|---|
| Pros | **Clients stay simple** — just call a name; language-agnostic |
| Cons | Extra network hop; the router is a component to operate |
| Examples | **Kubernetes Services**, AWS ALB, Envoy |

**Server-side is the modern default**, because the platform provides it. In Kubernetes you get it for free and most applications need no discovery code at all.

## How Kubernetes Does It

```
Pod → resolves "payment-service.default.svc.cluster.local"
    → ClusterIP (a stable virtual IP)
    → kube-proxy (iptables/IPVS) → a healthy pod
```

- **Service** = stable name and virtual IP over a changing set of pods
- **Endpoints/EndpointSlice** = the current healthy pod IPs, maintained by the control plane
- **Readiness probe** determines membership — a pod failing readiness is removed from the endpoint list

**Readiness probes are the health-check mechanism for discovery.** That's the connection to make: discovery and health checking are the same system.

**Headless Service** (`clusterIP: None`) returns pod IPs directly from DNS instead of a virtual IP — used by StatefulSets and by clients that want to load balance themselves.

## Registration

| Approach | How |
|---|---|
| **Self-registration** | The instance registers itself on startup, deregisters on shutdown, sends heartbeats |
| **Third-party registration** | The platform registers it (Kubernetes does this) |

**Self-registration's weakness is ungraceful shutdown** — a crashed instance never deregisters. Heartbeats with TTL solve it: no heartbeat, entry expires.

**This is exactly what [ZooKeeper ephemeral nodes](../04%20High%20Level%20Design/Key%20Technologies/ZooKeeper%20and%20Coordination.md) provide** — the registration disappears automatically when the session dies.

## Health Checking

| Type | Detail |
|---|---|
| **Active** | The registry or LB probes `/health` periodically |
| **Passive** | Observe real traffic; eject on error rate |
| **Heartbeat** | The instance pushes liveness |

**The health endpoint must not check downstream dependencies.** If it does, one shared dependency failing marks every instance unhealthy simultaneously — turning a dependency degradation into a total outage.

**Separate liveness from readiness:**
- **Liveness** — is the process functional? Failure → restart
- **Readiness** — can it serve traffic now? Failure → remove from rotation

A pod that's warming up, or shedding load, should fail readiness but pass liveness.

## DNS-Based Discovery

Simplest option: an A record listing all instances.

**Problems:**
- **TTL caching** — clients and resolvers cache aggressively, often ignoring low TTLs
- Many HTTP clients resolve once and reuse the connection forever
- No health awareness in plain DNS
- No weighting or advanced load balancing

**DNS alone is insufficient for fast failover.** Use it for coarse routing (region selection) and a health-checked load balancer or mesh for instance selection. Same conclusion as in [Networking Essentials](../11%20Networking/Fundamentals/Networking%20Essentials.md).

## Load Balancing Strategies

| Strategy | Note |
|---|---|
| Round robin | Simple; ignores actual load |
| **Least connections** | Better with variable request cost |
| **Power of two choices** | Pick two at random, choose the less loaded — nearly as good as least-connections, far cheaper |
| Consistent hash | Session or cache affinity |
| **Zone-aware** | Prefer same-zone instances — **avoids cross-AZ latency and data transfer cost** |

**Zone-aware routing is the underrated one.** Cross-AZ traffic adds ~1 ms and is billed; preferring local instances is free performance and cost savings.

## Registry Options

| Tool | Note |
|---|---|
| **Kubernetes Services** | Built in — use this if you're on Kubernetes |
| **Consul** | Service discovery plus health checks and a DNS interface |
| **etcd** | Raft-backed KV; what Kubernetes itself uses |
| ZooKeeper | Ephemeral nodes; older ecosystem |
| Eureka | Netflix, client-side, AP-oriented |

**Consistency choice matters:** Consul, etcd, and ZooKeeper are **CP** — during a partition the minority side can't read the registry. Eureka is deliberately **AP** — it serves possibly-stale data rather than nothing.

**For service discovery, AP is arguably correct.** A slightly stale instance list is far better than no instance list — you'd rather try a dead instance and fail over than be unable to route at all. Raising this trade-off is a strong signal.

## Common Mistakes

- Health endpoints that check downstream dependencies
- Relying on DNS TTL for fast failover
- HTTP clients that resolve once and cache forever
- No deregistration on shutdown, and no heartbeat TTL
- Client-side discovery in a polyglot estate — reimplemented per language
- Ignoring zone-aware routing
- Treating the registry as strongly consistent when it's AP

## Related Topics

- [API Gateway](API%20Gateway.md)
- [Service Mesh](Service%20Mesh.md)
- [Kubernetes Core Concepts](../13%20Kubernetes/Kubernetes%20Core%20Concepts.md)
- [ZooKeeper and Coordination](../04%20High%20Level%20Design/Key%20Technologies/ZooKeeper%20and%20Coordination.md)

## Revision Summary

Client-side discovery gives control but duplicates logic per language; server-side keeps clients simple and is what Kubernetes provides by default. Registration needs heartbeats with TTL so crashed instances expire. Health checks must not test dependencies, and readiness — not liveness — controls routing membership.

## Quick Recall

- Server-side (Kubernetes Service) is the modern default
- Readiness probe controls endpoint membership
- **Health checks must not test downstream dependencies**
- Heartbeat + TTL handles ungraceful shutdown
- DNS caching makes it unsuitable for fast failover
- Zone-aware routing saves latency and cross-AZ cost
- Registry AP beats CP for discovery — stale beats nothing
