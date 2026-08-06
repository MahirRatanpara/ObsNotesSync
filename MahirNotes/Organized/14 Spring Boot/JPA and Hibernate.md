# JPA and Hibernate

## Why It Matters

The ORM layer is where most Spring performance problems originate. Interviewers ask about N+1 because it separates people who have profiled a real application from people who have only written CRUD.

## The Persistence Context

A **first-level cache** scoped to the transaction. Every managed entity lives in it, keyed by ID.

| Consequence | Detail |
|---|---|
| **Identity guarantee** | Two loads of the same ID in one transaction return the **same object** |
| **Dirty checking** | Hibernate compares entity state at flush and issues UPDATEs automatically |
| **No explicit save needed** | Modifying a managed entity inside a transaction persists it |
| Write-behind | SQL is batched and deferred until flush |

```java
@Transactional
public void rename(Long id, String name) {
    User u = repo.findById(id).orElseThrow();
    u.setName(name);          // no save() call — dirty checking handles it
}
```

**"Why does this update without calling save()?" is a common interview question.** The answer is dirty checking on a managed entity.

### Entity States

```
NEW/TRANSIENT → (persist) → MANAGED → (commit/flush) → DATABASE
                              ↓ (close tx / evict)
                           DETACHED → (merge) → MANAGED
                              ↓ (remove)
                            REMOVED
```

**Detached entities are the source of `LazyInitializationException`** — the transaction is over, the persistence context is gone, and touching an uninitialised proxy fails.

## The N+1 Problem

The single most important thing in this note.

```java
List<Order> orders = orderRepo.findAll();          // 1 query
for (Order o : orders) {
    o.getCustomer().getName();                     // N queries — one per order
}
```

100 orders → **101 queries**. In production this is the difference between 20 ms and 4 seconds.

**Why it happens:** `@ManyToOne` defaults to `EAGER`, `@OneToMany` defaults to `LAZY`. Lazy associations issue a query on first access.

### The Fixes

| Fix | Use |
|---|---|
| **`JOIN FETCH`** | One query, explicit — the default answer |
| **`@EntityGraph`** | Declarative, reusable across repository methods |
| **`@BatchSize`** | Fetch lazy associations in batches of N — turns 101 queries into ~11 |
| **Projections / DTOs** | Select only needed columns — often the best answer |

```java
@Query("SELECT o FROM Order o JOIN FETCH o.customer WHERE o.status = :status")
List<Order> findByStatusWithCustomer(@Param("status") Status status);

@EntityGraph(attributePaths = {"customer", "items"})
List<Order> findByStatus(Status status);
```

**The `JOIN FETCH` trap — MultipleBagFetchException:** fetching two `List` collections in one query produces a cartesian product, and Hibernate refuses. Fix by using `Set` instead of `List`, or fetching one collection per query with `@BatchSize` for the other.

**Pagination + `JOIN FETCH` is worse:** Hibernate silently loads *everything* into memory and paginates in Java (`HHH000104` warning in the logs). Use `@BatchSize` or a two-query approach instead.

**Always enable SQL logging in development:**
```properties
spring.jpa.show-sql=true
logging.level.org.hibernate.stat=DEBUG
spring.jpa.properties.hibernate.generate_statistics=true
```
**If you have never looked at the generated SQL, you have N+1 problems you don't know about.**

## Fetch Strategy

| | Default | Recommendation |
|---|---|---|
| `@ManyToOne` | **EAGER** | **Set to LAZY explicitly** |
| `@OneToOne` | EAGER | LAZY |
| `@OneToMany` | LAZY | Leave LAZY |
| `@ManyToMany` | LAZY | Leave LAZY |

**Make everything LAZY and fetch explicitly per use case.** EAGER loads data every query whether you need it or not, and you cannot turn it off at the call site — whereas LAZY can always be joined when required.

**`@OneToOne` lazy loading often doesn't work** on the non-owning side: Hibernate must know whether the row exists to decide between a proxy and null, so it queries anyway. Use `@MapsId` with a shared primary key, or bytecode enhancement.

## DTO Projections — Frequently The Right Answer

```java
public interface OrderSummary {
    Long getId();
    String getCustomerName();
    BigDecimal getTotal();
}
List<OrderSummary> findByStatus(Status status);
```

Or explicitly:
```java
@Query("SELECT new com.app.OrderDto(o.id, c.name, o.total) FROM Order o JOIN o.customer c")
```

**Loading full entities for a read-only list view is waste** — you pay for every column, the persistence context, and dirty checking on data you'll never modify. Projections avoid all three.

Pair with `@Transactional(readOnly = true)`, which disables dirty checking entirely.

## Locking

```java
// Pessimistic — SELECT ... FOR UPDATE
@Lock(LockModeType.PESSIMISTIC_WRITE)
Optional<Seat> findById(Long id);

// Optimistic — version column
@Entity class Account { @Version private Long version; }
```

**Optimistic locking throws `OptimisticLockException` on conflict** — the caller must catch and retry. Prefer it; use pessimistic only under genuine high contention. See [Transactions and Isolation Levels](../05%20Databases/Consistency%20and%20Transactions/Transactions%20and%20Isolation%20Levels.md).

## Cascade And orphanRemoval

| Cascade | Effect |
|---|---|
| `PERSIST` | Save children with the parent |
| `MERGE` | Merge children |
| **`REMOVE`** | **Delete children with the parent — dangerous** |
| `ALL` | All of the above |
| `orphanRemoval = true` | Delete a child removed from the collection |

**`CascadeType.ALL` on `@ManyToMany` is a real hazard** — deleting one entity can cascade into deleting shared entities. Never cascade REMOVE across a many-to-many.

**`orphanRemoval` vs `CascadeType.REMOVE`:** orphanRemoval deletes a child when it's removed *from the collection*; REMOVE deletes children only when the *parent* is deleted.

## Batching

```properties
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

**Batching does not work with `GenerationType.IDENTITY`** — Hibernate must execute each insert to obtain the generated ID, so it cannot batch. Use `SEQUENCE` with an allocation size instead. This is a very common and invisible performance loss.

For genuinely bulk operations, drop to JDBC or use `@Modifying` queries — the persistence context is not designed for a million rows.

## Common Annotations Worth Knowing

| Annotation | Purpose |
|---|---|
| `@Transactional(readOnly = true)` | Disables dirty checking; may route to a replica |
| `@Modifying` | Required for UPDATE/DELETE `@Query` methods |
| `@Version` | Optimistic locking |
| `@BatchSize(size = 25)` | Batch-load lazy associations |
| `@NamedEntityGraph` | Reusable fetch plan |
| `@DynamicUpdate` | Only update changed columns |

## Common Mistakes

- **N+1 queries** — the default state of an unprofiled application
- Leaving `@ManyToOne` as EAGER
- Loading entities for read-only views instead of projections
- `JOIN FETCH` combined with pagination
- `CascadeType.ALL` on `@ManyToMany`
- `IDENTITY` generation, silently disabling batching
- Never inspecting the generated SQL
- Business logic depending on `LazyInitializationException` not occurring
- Using JPA for bulk operations

## Related Topics

- [Spring Transactions and AOP](Spring%20Transactions%20and%20AOP.md)
- [Database Indexing](../05%20Databases/Indexing/Database%20Indexing.md)
- [Transactions and Isolation Levels](../05%20Databases/Consistency%20and%20Transactions/Transactions%20and%20Isolation%20Levels.md)
- [PostgreSQL](../04%20High%20Level%20Design/Key%20Technologies/PostgreSQL.md)

## Revision Summary

The persistence context gives identity and dirty checking within a transaction. N+1 is the dominant performance problem — fix with `JOIN FETCH`, `@EntityGraph`, `@BatchSize`, or DTO projections. Make all associations LAZY and fetch deliberately. Watch for `IDENTITY` disabling batching and `JOIN FETCH` breaking pagination.

## Quick Recall

- Dirty checking means no `save()` needed on managed entities
- **`@ManyToOne` is EAGER by default — change it**
- N+1: 100 orders → 101 queries; fix with `JOIN FETCH` / `@EntityGraph` / `@BatchSize`
- `JOIN FETCH` + pagination → in-memory paging
- Two `List` fetches → `MultipleBagFetchException`; use `Set`
- Projections beat entities for read-only views
- `IDENTITY` generation disables JDBC batching
- `LazyInitializationException` = detached entity
- Always read the generated SQL
