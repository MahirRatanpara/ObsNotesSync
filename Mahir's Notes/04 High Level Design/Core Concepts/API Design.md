# API Design

## Why It Matters

The API is the contract every other design decision hangs off. In a system design interview it's a 5-minute phase that signals whether you think about consumers, versioning, and failure.

## REST vs gRPC vs GraphQL

| | **REST** | **gRPC** | **GraphQL** |
|---|---|---|---|
| Transport | HTTP/1.1 or 2, JSON | **HTTP/2, Protobuf** | HTTP, JSON |
| Contract | OpenAPI (optional) | **`.proto`, enforced** | **Schema, enforced** |
| Performance | Moderate | **Fastest — binary, multiplexed** | Moderate |
| Streaming | SSE / WebSocket | **Native bidirectional** | Subscriptions |
| Browser support | **Native** | Needs grpc-web proxy | Native |
| Over/under-fetching | Common | Common | **Solved — client picks fields** |
| Caching | **HTTP caching works** | Manual | **Hard — POST, dynamic queries** |

**Choose REST** for public APIs and browser clients — universal, cacheable, debuggable.
**Choose gRPC** for internal service-to-service — binary, typed, fast, with generated clients.
**Choose GraphQL** when many diverse clients need different shapes of the same data, and you accept the caching and complexity cost.

**The common production answer is REST or GraphQL at the edge, gRPC internally.**

**GraphQL's real costs** are worth naming: the N+1 problem (needs DataLoader batching), the difficulty of rate limiting (query cost analysis rather than request counting), and unbounded query depth requiring explicit limits.

## Resource Modelling

```
GET    /v1/orders                 list
POST   /v1/orders                 create
GET    /v1/orders/{id}            read
PUT    /v1/orders/{id}            replace (idempotent)
PATCH  /v1/orders/{id}            partial update
DELETE /v1/orders/{id}            delete (idempotent)
POST   /v1/orders/{id}/cancel     action that isn't CRUD
```

- **Plural nouns**, not verbs (`/orders`, not `/getOrders`)
- Nest only one level deep — `/users/{id}/orders` is fine, three levels is not
- **Actions that don't fit CRUD become sub-resources**: `POST /orders/{id}/cancel` is more honest than contorting `PATCH` to express it

## Pagination

**Cursor, always.**

```
GET /v1/orders?limit=20&cursor=eyJpZCI6MTIzfQ
→ { "data": [...], "next_cursor": "eyJpZCI6MTQzfQ" }
```

| | Offset | **Cursor** |
|---|---|---|
| Stability under inserts | **Breaks** — items shift, pages repeat or skip | **Stable** |
| Performance at depth | **O(offset)** — scan and discard | **O(limit)** |
| Jump to page N | Possible | No |

Offset pagination on an insert-heavy collection is a correctness bug, not just a performance one. The only reason to use it is a UI requiring numbered pages.

**Encode the cursor opaquely** (base64 of the sort key) so clients can't construct one and you can change the implementation.

## Idempotency

```http
POST /v1/payments
Idempotency-Key: 9f2c1e7a-...
```

The server records the key with the response, and returns the **original result** on a repeat.

**Required on any non-idempotent operation with money or side effects.** A network timeout is ambiguous — the client cannot know whether the payment succeeded, so it must be safe to retry. See [Two Generals Problem](Two%20Generals%20Problem.md).

**The dedup record must be written in the same transaction as the side effect** — otherwise a crash between the two breaks the guarantee.

## Versioning

| Approach | Trade-off |
|---|---|
| **URL path** (`/v1/`) | **Clearest, most common**; visible in logs and easy to route |
| Header (`Accept: application/vnd.api.v2+json`) | Cleaner URLs, harder to test and cache |
| Query param (`?version=2`) | Easy but pollutes the query space |

**Use the URL path.** Purists prefer headers; operationally, path versioning is easier to route, cache, log, and debug.

**Prefer never versioning at all** by making only backward-compatible changes:

| Safe | Breaking |
|---|---|
| Add an optional field | Remove a field |
| Add a new endpoint | Rename a field |
| Add an optional parameter | Change a type |
| Add an enum value* | Make an optional field required |

\* Only safe if clients tolerate unknown values — specify this in your contract.

## Error Design

```json
{
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Account balance is below the requested amount",
    "request_id": "req_9f2c1e",
    "details": { "available": 4500, "requested": 10000 }
  }
}
```

- **A stable machine-readable `code`** — clients must never parse the message
- A human-readable `message` for logs and developers
- **`request_id`** so a user report maps to a specific trace
- Consistent shape across every endpoint

**Use the right status code:** 400 (malformed), 401 (unauthenticated), 403 (unauthorised), 404 (absent), 409 (conflict), 422 (semantically invalid), 429 (rate limited), 5xx (server fault).

**401 vs 403 is asked often:** 401 means "I don't know who you are"; 403 means "I know, and you may not".

## Rate Limiting Headers

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1699999999
Retry-After: 30
```

**`Retry-After` on a 429 is not optional** — without it, well-behaved clients retry immediately and worsen the overload.

## Other Contract Decisions

| Concern | Practice |
|---|---|
| **Long-running operations** | Return `202 Accepted` with a status URL to poll, or a webhook |
| **Bulk operations** | Accept an array; return **per-item** results, since some may fail |
| **Filtering / sorting** | `?status=active&sort=-created_at` |
| **Partial responses** | `?fields=id,name` to reduce payload |
| **Field naming** | Pick `snake_case` or `camelCase` and never mix |
| **Timestamps** | **Always ISO 8601 with timezone** |
| **Money** | **Integer minor units** (cents) — never floats |
| Enums | Strings, not integers — readable in logs and stable |

**Money as floats is a real correctness bug**, and stating it unprompted signals production experience.

## Security

- **HTTPS only**; HSTS
- Bearer tokens (JWT) or OAuth 2.0 — **never API keys in query strings** (they land in logs and referrers)
- Validate and bound every input, including `limit`
- **Authenticate at the gateway, authorise in the service** — only the service knows its own rules
- Return 404 rather than 403 where existence itself is sensitive

## Common Mistakes

- Offset pagination
- No idempotency key on payment-like endpoints
- Verbs in resource paths
- Error messages as the only machine-readable signal
- Breaking changes without a version bump
- 200 with an error body
- Floats for money
- Naive timestamps without a timezone
- 429 without `Retry-After`

## Related Topics

- [HTTP and TLS](HTTP%20and%20TLS.md)
- [API Gateway](API%20Gateway.md)
- [Rate Limiting](Rate%20Limiting.md)
- [Idempotent Consumers](Idempotent%20Consumers.md)

## Revision Summary

REST at the edge, gRPC internally, GraphQL when clients need varied shapes. Cursor pagination always. Idempotency keys on anything with side effects. Version in the URL path but prefer backward-compatible evolution. Errors need a stable code and a request ID.

## Quick Recall

- REST public, gRPC internal, GraphQL for varied clients
- **Cursor pagination, never offset**
- `Idempotency-Key` on payment-like POSTs
- URL path versioning; add fields, never remove or rename
- Stable error `code` + `request_id`
- 401 = who are you; 403 = you may not
- 429 must include `Retry-After`
- Money in integer minor units; timestamps ISO 8601 with zone
