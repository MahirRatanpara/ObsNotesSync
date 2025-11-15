
# 🔀 Optimistic vs Pessimistic Concurrency Control

## 🔐 Pessimistic (e.g. [[MahirNotes/HLD/Concurrency Control/2 Phase Locking|2 Phase Locking]])

- Assumes conflicts are **likely**
- Uses **locks** to prevent conflicts
- Includes: Basic 2PL, Strict 2PL, Conservative 2PL
- ✅ Good for: financial, mission-critical apps
- ⚠️ Risks: deadlocks, reduced concurrency

## 🎲 Optimistic Concurrency Control (OCC)

- Assumes conflicts are **rare**
- No locks; uses **validation at commit**
- ✅ Good for: analytics, mostly-read systems
- 🚫 Deadlock-free
- ❗ Retries may occur on conflict

## 🔄 Key Differences

| Feature           | Pessimistic (2PL)      | Optimistic (OCC)      |
|-------------------|------------------------|------------------------|
| Locking           | ✅ Yes                 | ❌ No                  |
| Conflict Handling | Prevent early          | Validate at commit     |
| Deadlocks         | Possible               | Impossible             |
| Cascading Aborts  | Depends on lock policy | Not applicable         |
| Throughput        | Lower on low-conflict  | Higher on low-conflict |

