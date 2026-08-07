# Deployment Patterns

## Why It Matters

How you release determines your blast radius. Interviewers ask because it reveals whether you've operated a system in production.

## The Strategies

| Strategy | Downtime | Rollback | Cost | Risk |
|---|---|---|---|---|
| **Recreate** | **Yes** | Redeploy old | Low | High |
| **Rolling** | No | Slow — roll forward or back gradually | Low | Medium |
| **Blue-green** | No | **Instant — flip traffic back** | **2× infrastructure** | Low |
| **Canary** | No | Fast — shift traffic away | Low | **Lowest** |
| **Shadow** | No | N/A — no user traffic | Moderate | **None** |

## Rolling Update

Replace instances gradually. The Kubernetes default.

```yaml
strategy:
  rollingUpdate:
    maxSurge: 25%          # extra pods allowed above desired
    maxUnavailable: 0      # never go below desired capacity
```

**`maxUnavailable: 0` with `maxSurge` > 0 means you never lose capacity** — new pods come up before old ones go down. That's the safe configuration.

**The constraint rolling updates impose: both versions run simultaneously.** So every change must be backward compatible — old and new code will coexist for minutes.

## Blue-Green

Two identical environments; flip all traffic at once.

```
Blue (v1) ← 100% traffic          Deploy v2 to Green
Blue (v1) ← 0%    Green (v2) ← 100%    Flip
                                       Keep Blue warm for instant rollback
```

**Instant rollback is the whole point.** If v2 misbehaves, flip back in seconds — no waiting for pods to roll.

**Costs:** double the infrastructure during deployment, and **database migrations are the hard part** — both versions must work against one schema.

## Canary

Route a small percentage to the new version, watch metrics, and increase gradually.

```
5% → observe 10 min → 25% → observe → 50% → 100%
Automated rollback if error rate or latency regresses
```

**Automated analysis is what makes canary valuable** — comparing the canary's error rate and p99 against the baseline, and rolling back automatically. Manual watching doesn't scale and misses subtle regressions.

**Choose the canary population deliberately:** random users, internal employees, or a low-risk region. Random gives representative signal; internal-first limits customer impact.

Tools: Argo Rollouts, Flagger, or an [Istio](Service%20Mesh.md) traffic split.

## Feature Flags — Decouple Deploy From Release

```java
if (featureFlags.isEnabled("new-checkout", user)) {
    return newCheckout(user);
}
return oldCheckout(user);
```

**Deploying code and releasing a feature become separate events.** You can ship dark, enable for 1% of users, and disable instantly without a deployment.

| Benefit | Detail |
|---|---|
| **Instant kill switch** | Turn a feature off in seconds — faster than any rollback |
| Gradual rollout | Independent of the deploy cadence |
| A/B testing | Same mechanism |
| Trunk-based development | Merge incomplete work safely behind a flag |

**The cost: flag debt.** Every flag is a branch in the code. Remove flags once a feature is fully rolled out, or the codebase becomes unreadable and untestable — the number of code paths grows as 2ⁿ.

**Feature flags are often a better answer than canary deployment** — finer-grained, instantly reversible, and no infrastructure duplication.

## Database Migrations — The Genuinely Hard Part

**Both versions run simultaneously, so the schema must satisfy both.** This is where most deployment incidents originate.

**Expand–contract (parallel change):**

```
1. EXPAND    Add the new column, nullable. Deploy. (old code ignores it)
2. MIGRATE   Backfill data. Deploy code writing BOTH old and new.
3. SWITCH    Deploy code reading the new column.
4. CONTRACT  Stop writing the old column. Deploy.
5. CLEANUP   Drop the old column. Deploy.
```

**Five deployments to rename a column.** That is the actual cost of zero-downtime schema change, and stating it demonstrates real experience.

**Never in a single deploy:**
- Rename or drop a column
- Add a `NOT NULL` column without a default
- Change a column type incompatibly
- Add a constraint that existing rows violate

**Migrations must be backward compatible, and rollback must be considered.** A migration that can't be reversed means the deploy can't be rolled back either.

**Long-running migrations lock tables.** Adding an index on a large table in Postgres needs `CREATE INDEX CONCURRENTLY`; otherwise writes block for the duration.

## Zero-Downtime Requirements

| Requirement | Why |
|---|---|
| **Graceful shutdown** | Stop accepting new requests, drain in-flight, then exit |
| **Readiness probe** | Remove from rotation before shutdown begins |
| **`preStop` hook + `terminationGracePeriodSeconds`** | Give the load balancer time to notice |
| Backward-compatible APIs | Old clients still call the old contract |
| Backward-compatible schemas | Both versions share one database |
| Idempotent operations | Retries during the deploy are safe |

**The classic zero-downtime bug:** the pod receives SIGTERM and exits immediately while the load balancer is still routing to it. Requests fail for a few seconds.

**Fix:** on SIGTERM, fail the readiness probe, wait a few seconds for the LB to deregister, *then* drain and exit. A `preStop` sleep of 5–10 seconds is the standard trick.

## Rollback Strategy

| Approach | Speed |
|---|---|
| **Feature flag off** | **Seconds** |
| Blue-green flip | Seconds |
| Canary traffic shift | Seconds |
| `kubectl rollout undo` | Minutes |
| Redeploy previous image | Minutes |
| **Database rollback** | **Often impossible** |

**Database changes are usually irreversible** — that's why expand–contract exists. If you must roll back after a destructive migration, you're restoring from backup.

**Always tag images immutably.** `latest` makes rollback ambiguous and reproducibility impossible.

## Deployment Health Checks

Verify after deploying, not just that pods started:

- Error rate compared to the pre-deploy baseline
- p99 latency comparison
- Business metrics — orders per minute, sign-ups
- Downstream dependency error rates

**A deploy that starts successfully but breaks a business metric is still a failed deploy.** Watching only pod status misses it.

## Common Mistakes

- Destructive migrations in a single deploy
- No graceful shutdown → dropped requests on every deploy
- `latest` image tags
- Canary without automated metric analysis
- Feature flags never removed
- Rolling updates with backward-incompatible changes
- No rollback plan for schema changes
- Only checking pod health, not business metrics

## Related Topics

- [Kubernetes Core Concepts](Kubernetes%20Core%20Concepts.md)
- [Service Mesh](Service%20Mesh.md)
- [Observability](Observability.md)
- [Microservices Fundamentals](Microservices%20Fundamentals.md)

## Revision Summary

Rolling updates are the default but force backward compatibility; blue-green buys instant rollback at double the infrastructure; canary with automated analysis carries the least risk. Feature flags decouple deploy from release and give the fastest kill switch. Schema changes need expand–contract, and graceful shutdown is required for genuine zero downtime.

## Quick Recall

- Rolling: `maxUnavailable: 0` + `maxSurge` → never lose capacity
- Blue-green: instant rollback, 2× infrastructure
- Canary: needs **automated** metric comparison
- **Feature flags = fastest kill switch**; remove them afterwards
- Both versions run together → **backward compatibility mandatory**
- Expand–contract: five deploys to rename a column
- SIGTERM → fail readiness → wait → drain → exit
- Database rollback is usually impossible
