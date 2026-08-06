# Kubernetes Core Concepts

## Why It Matters

Assumed knowledge for backend roles at most companies. Interviewers test the mental model, not `kubectl` flags.

## The Control Loop

Kubernetes is a set of **controllers** continuously reconciling actual state toward declared state. You declare intent; controllers make it true and keep it true.

**This is the entire mental model.** Everything else follows from it.

| Component | Role |
|---|---|
| **API server** | The only thing that talks to etcd; all state changes go through it |
| **etcd** | Raft-backed store of all cluster state |
| **Scheduler** | Assigns pods to nodes by resources, affinity, taints |
| **Controller manager** | Runs the reconciliation loops |
| **kubelet** | On each node; starts containers, reports status |
| **kube-proxy** | Programs iptables/IPVS for Service routing |

## Workload Objects

| Object | Use |
|---|---|
| **Pod** | Smallest unit — one or more containers sharing network and storage |
| **ReplicaSet** | Maintains N identical pods |
| **Deployment** | Manages ReplicaSets; **gives you rolling updates and rollback** |
| **StatefulSet** | Stable identities and persistent volumes — databases |
| **DaemonSet** | One pod per node — log and metrics agents |
| **Job / CronJob** | Run to completion / on a schedule |

**Never create bare pods.** A pod isn't rescheduled if its node dies; a Deployment's controller recreates it.

**Deployment vs StatefulSet:** StatefulSet gives stable names (`db-0`, `db-1`), stable storage, and ordered rollout. Use it only for stateful workloads that need identity — Kafka, Postgres, Zookeeper.

## Networking

| Object | Purpose |
|---|---|
| **Service (ClusterIP)** | Stable virtual IP and DNS name for a set of pods |
| **NodePort** | Exposes on a port of every node |
| **LoadBalancer** | Provisions a cloud load balancer |
| **Ingress** | L7 HTTP routing by host and path, with TLS |
| **Headless Service** | No virtual IP; DNS returns pod IPs directly — used by StatefulSets |

Pods are ephemeral and their IPs change. **A Service is the stable indirection** — this is Kubernetes' service discovery. Pods resolve `my-service.my-namespace.svc.cluster.local`.

## Configuration and Secrets

- **ConfigMap** — non-sensitive configuration, mounted as files or env vars
- **Secret** — base64-encoded, **not encrypted by default**. Enable encryption at rest, or use an external secrets manager

**Secrets are not secure out of the box.** Saying this is a good signal.

## Resources: Requests and Limits

| | Meaning |
|---|---|
| **Request** | Guaranteed minimum; the **scheduler** uses this to place the pod |
| **Limit** | Hard ceiling |

- **CPU over limit** → the container is **throttled** (slowed)
- **Memory over limit** → the container is **OOMKilled** (terminated)

**QoS classes:** `Guaranteed` (requests = limits) is evicted last; `Burstable` next; `BestEffort` (nothing set) is evicted first.

**Setting no requests is the most common production mistake** — the scheduler over-packs the node and everything degrades under load.

## Health Probes

| Probe | Failure action | Purpose |
|---|---|---|
| **Liveness** | **Restart** the container | Detect deadlock/hang |
| **Readiness** | Remove from Service endpoints | Don't route traffic to a warming or overloaded pod |
| **Startup** | Delay the other probes | Slow-starting apps (JVM) |

**Liveness and readiness must not be the same endpoint.** If a readiness check fails because a dependency is down and it's also the liveness probe, Kubernetes restarts every pod — turning a dependency blip into a full outage. This is a classic interview question and a classic real incident.

## Scaling

- **HPA** — scales pod count on CPU, memory, or custom metrics
- **VPA** — adjusts requests/limits (restarts pods)
- **Cluster Autoscaler** — adds/removes nodes when pods can't be scheduled

## Rolling Updates

Deployments replace pods gradually, controlled by `maxSurge` and `maxUnavailable`. `kubectl rollout undo` reverts to the previous ReplicaSet.

**PodDisruptionBudget** protects availability during *voluntary* disruptions (node drains): "at least 2 replicas must remain available".

## Debugging Sequence

```bash
kubectl get pods                    # status, restart count
kubectl describe pod <name>         # events — usually the answer
kubectl logs <name> --previous      # logs from the crashed instance
kubectl exec -it <name> -- sh       # inspect from inside
kubectl top pods                    # resource usage
```

| Status | Usual cause |
|---|---|
| `Pending` | Insufficient resources, or no node matches |
| `CrashLoopBackOff` | App exits on startup — check `logs --previous` |
| `ImagePullBackOff` | Bad image name or missing registry credentials |
| `OOMKilled` | Memory limit too low |
| `Evicted` | Node under memory/disk pressure |

## Common Mistakes

- No resource requests
- Same endpoint for liveness and readiness
- Bare pods instead of Deployments
- `latest` image tags — no reproducibility, no meaningful rollback
- Secrets in ConfigMaps
- StatefulSet where a Deployment would do
- No PodDisruptionBudget on critical services

## Related Topics

- [Service Mesh](../08%20Microservices/Service%20Mesh.md)
- [Circuit Breaker](../08%20Microservices/Circuit%20Breaker.md)

## Revision Summary

Declarative desired state reconciled by controllers. Deployments for stateless, StatefulSets for identity-bearing workloads. Services provide stable discovery over ephemeral pods. Requests drive scheduling; limits cause throttling or OOMKill. Liveness restarts, readiness de-routes — never share the endpoint.

## Quick Recall

- Controllers reconcile actual → desired
- Deployment (stateless) vs StatefulSet (identity + storage)
- Service = stable IP/DNS over ephemeral pods
- Request = scheduling; limit = throttle (CPU) or kill (memory)
- Liveness restarts; readiness removes from endpoints
- `describe pod` events answer most questions
