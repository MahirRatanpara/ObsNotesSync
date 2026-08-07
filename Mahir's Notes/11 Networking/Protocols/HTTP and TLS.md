# HTTP and TLS

## Why It Matters

The protocol every API speaks. Version differences change latency materially, and caching and idempotency semantics are frequently misused.

## HTTP Versions

| | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---|---|---|---|
| Transport | TCP | TCP | **QUIC over UDP** |
| Multiplexing | **No** — one request at a time per connection | **Yes** — many streams per connection | Yes |
| Head-of-line blocking | **At the request level** | **At the TCP level** | **None** |
| Header compression | None | HPACK | QPACK |
| Server push | No | Yes (largely abandoned) | Yes |
| Encryption | Optional | Effectively required | **Built in** |

**The progression is one problem being pushed down a layer:**

- HTTP/1.1 blocks at the *request* level, so browsers open ~6 connections per domain to work around it
- HTTP/2 multiplexes streams over one connection — but they share one TCP connection, so **a single lost packet stalls every stream**
- HTTP/3 gives each stream independent delivery over QUIC, eliminating it entirely

**"HTTP/2 moved head-of-line blocking from the application layer to the transport layer; HTTP/3 removed it" is the answer that shows you understand the evolution.**

**Practical consequence:** HTTP/2 is a clear win on reliable networks and can be *worse* than HTTP/1.1 on lossy mobile links, because six independent connections degrade more gracefully than one multiplexed one.

## Methods and Semantics

| Method | Safe | **Idempotent** | Cacheable |
|---|---|---|---|
| GET | Yes | Yes | Yes |
| HEAD | Yes | Yes | Yes |
| **PUT** | No | **Yes** | No |
| **DELETE** | No | **Yes** | No |
| **POST** | No | **No** | Rarely |
| PATCH | No | **No** (usually) | No |

**Idempotent means repeating the request has the same effect as making it once.** It's the property that makes retries safe.

**PUT is idempotent, POST is not** — that's why retrying a POST can double-charge a customer, and why write endpoints need an idempotency key. See [Idempotent Consumers](Idempotent%20Consumers.md).

**PATCH is usually not idempotent** — `{"op": "increment", "value": 1}` applied twice differs from once. A PATCH that sets absolute values *is* idempotent.

## Status Codes That Matter

| Code | Meaning | Note |
|---|---|---|
| 200 / 201 / 204 | OK / Created / No content | |
| **301 vs 302** | Permanent vs temporary redirect | **301 is cached by browsers, possibly forever** |
| 304 | Not modified | Conditional request succeeded |
| 400 / 401 / 403 | Bad request / unauthenticated / **unauthorised** | 401 = who are you; 403 = you may not |
| 404 | Not found | |
| **409** | Conflict | Optimistic locking failure |
| **429** | Too many requests | **Must include `Retry-After`** |
| 500 / 502 / 503 / 504 | Server error / bad gateway / unavailable / **gateway timeout** | 504 means **unknown**, not failed |

**504 is ambiguous, not a failure.** The upstream may have completed the work. This is the Two Generals problem in HTTP form — never treat a 504 as "it didn't happen".

## Caching Headers

```http
Cache-Control: public, max-age=3600, s-maxage=86400, stale-while-revalidate=604800
ETag: "a3f9c2"
Last-Modified: Wed, 06 Aug 2026 10:00:00 GMT
```

**Conditional requests** avoid re-sending unchanged bodies:

```http
GET /resource
If-None-Match: "a3f9c2"
→ 304 Not Modified          (no body — saves bandwidth, not the round trip)
```

**ETags also enable optimistic concurrency:**
```http
PUT /resource
If-Match: "a3f9c2"
→ 412 Precondition Failed   if someone else changed it first
```

This is the HTTP-native equivalent of a version column, and it's a strong thing to mention in an API design discussion.

## TLS

### The Handshake

**TLS 1.2** — 2 round trips: client hello → server hello + certificate → key exchange → finished.

**TLS 1.3** — **1 round trip**, by having the client guess the key-exchange parameters in its first message. Also removed all legacy insecure ciphers.

**0-RTT resumption** sends application data in the very first packet using a pre-shared key. **The catch: 0-RTT data is replayable**, so it must only carry idempotent requests. Naming this trade-off is a good signal.

### What TLS Provides

| Property | Mechanism |
|---|---|
| **Confidentiality** | Symmetric encryption (AES-GCM, ChaCha20) |
| **Integrity** | AEAD — tampering is detected |
| **Authentication** | Certificate chain to a trusted root CA |
| **Forward secrecy** | Ephemeral keys (ECDHE) — a stolen private key can't decrypt past traffic |

**Forward secrecy is the property to name:** without it, an attacker recording traffic today can decrypt it all if they later obtain the server key. With ECDHE, each session's key is discarded.

### Certificate Validation

1. Is the certificate signed by a trusted CA?
2. Does the hostname match (SAN, not the deprecated CN)?
3. Is it within its validity period?
4. Has it been revoked (OCSP stapling)?

**mTLS** adds client certificate verification in the other direction — the basis of zero-trust service-to-service authentication and what a [service mesh](Service%20Mesh.md) automates.

### Where To Terminate TLS

| Point | Trade-off |
|---|---|
| **Load balancer / CDN edge** | Simplest; internal traffic unencrypted |
| **End to end** | Most secure; L7 balancer can't inspect or route on content |
| **Terminate then re-encrypt** | Common compromise — inspect at the edge, encrypt internally |

## API Design Notes

| Concern | Practice |
|---|---|
| **Pagination** | **Cursor, not offset** — offset drifts and forces scan-and-discard |
| **Versioning** | URL path (`/v1/`) is clearest; header versioning is cleaner in theory, worse in practice |
| **Idempotency** | `Idempotency-Key` header on POST |
| **Rate limits** | `X-RateLimit-*` plus `Retry-After` on 429 |
| Partial responses | `?fields=` to reduce payload |
| Errors | Consistent shape with a machine-readable code, not just a message |

## Common Mistakes

- Retrying a POST without an idempotency key
- Treating 504 as a definite failure
- 301 redirects when the target might change — browsers cache them indefinitely
- Offset pagination on a frequently-inserted collection
- 403 where 401 is meant
- 429 without `Retry-After`
- Assuming HTTP/2 is always faster (it isn't on lossy links)
- 0-RTT for non-idempotent requests

## Related Topics

- [Networking Essentials](Networking%20Essentials.md)
- [CDN](CDN.md)
- [API Gateway](API%20Gateway.md)
- [Idempotent Consumers](Idempotent%20Consumers.md)

## Revision Summary

HTTP/2 multiplexes but still suffers TCP head-of-line blocking; HTTP/3 over QUIC removes it. PUT and DELETE are idempotent, POST is not, which is why retries need idempotency keys. TLS 1.3 halves handshake latency; forward secrecy protects recorded traffic. Use cursor pagination and ETags for optimistic concurrency.

## Quick Recall

- HTTP/1.1 blocks per request → HTTP/2 per TCP connection → HTTP/3 not at all
- PUT/DELETE idempotent; **POST is not**
- 504 = unknown, never "failed"
- 429 must carry `Retry-After`
- TLS 1.3 = 1 RTT; 0-RTT data is replayable
- Forward secrecy via ECDHE
- ETag + `If-Match` = optimistic concurrency over HTTP
