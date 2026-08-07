# CDN

## Why It Matters

The cheapest read scaling available — a CDN hit never touches your infrastructure. It should be the first thing you mention for static content and often for dynamic content too.

## Core Idea

A geographically distributed network of **edge servers (PoPs)** that cache content close to users. The user's request terminates at the nearest edge instead of crossing continents to your origin.

**The physics:** a round trip from Sydney to Virginia is ~200 ms. TLS handshake plus request plus response is several round trips — close to a second before the first byte. An edge 10 ms away removes almost all of it.

## Push vs Pull

| | **Pull (origin pull)** | **Push** |
|---|---|---|
| How | Edge fetches from origin on first miss, then caches | You upload content to the CDN ahead of time |
| First user | Pays the origin round trip | Fast for everyone |
| Storage | Only what's requested | Everything you push |
| Best for | **Most cases** — large catalogues, unpredictable demand | Small sets, predictable launches, large files |

**Pull is the default.** Push suits a video launch where you know the content and want no cold start.

## Cache Control

The origin controls edge behaviour through headers:

```http
Cache-Control: public, max-age=31536000, immutable      # hashed static assets
Cache-Control: public, max-age=60, s-maxage=3600        # browser 60s, CDN 1h
Cache-Control: private, no-store                        # never cache
Cache-Control: public, max-age=60, stale-while-revalidate=86400
```

| Directive | Meaning |
|---|---|
| `max-age` | Browser TTL |
| **`s-maxage`** | **CDN TTL — overrides `max-age` for shared caches** |
| `public` / `private` | Cacheable by CDNs / browsers only |
| `no-store` | Never cache anywhere |
| `immutable` | Never revalidate — for content-hashed filenames |
| **`stale-while-revalidate`** | Serve stale immediately, refresh in the background |

**`stale-while-revalidate` is the single most valuable directive** — users never wait for a revalidation, and it eliminates the origin stampede on expiry.

## Invalidation

Two approaches, and the second is strongly preferred:

| Approach | Mechanism | Speed |
|---|---|---|
| **Purge** | Call the CDN API to evict a path | Seconds to minutes; rate-limited |
| **Cache busting / versioned URLs** | `app.a3f9c2.js` — a new URL is a guaranteed miss | **Instant** |

**Content-hashed filenames mean you never need to invalidate.** Set a one-year TTL with `immutable`, and deploy a new filename. This is how every modern build tool works, and it's the right answer to "how do you handle cache invalidation at the CDN?"

Purging still matters for HTML entry points and API responses. **Tag-based purging** (`Surrogate-Key`) lets you evict all pages containing a changed product in one call — far better than enumerating URLs.

## Cache Key Design

By default the key is the full URL. Problems arise with:

- **Query parameters** — tracking params (`?utm_source=...`) fragment the cache. Strip or allowlist them.
- **Cookies** — forwarding cookies usually disables caching entirely
- **Headers** — `Vary: Accept-Encoding` is fine; `Vary: User-Agent` explodes the key space

**A low hit rate is almost always a cache-key problem.** Check that first.

## Beyond Static Assets

Modern CDNs do considerably more:

| Capability | Use |
|---|---|
| **Dynamic acceleration** | Persistent optimised connections to origin, even for uncacheable responses |
| **TLS termination** at the edge | Saves handshake round trips |
| **Edge compute** (Workers, Lambda@Edge) | A/B tests, auth checks, personalisation without origin round trips |
| **Image optimisation** | Resize and re-encode (WebP/AVIF) per device on the fly |
| **DDoS protection and WAF** | Absorb attacks before they reach you |
| **Origin shield** | A mid-tier cache so many PoPs don't all miss to origin simultaneously |

**Origin shield is worth naming in a deep dive:** without it, 200 PoPs missing at once produces 200 simultaneous origin requests for the same object.

## Caching Dynamic and Personalised Content

Even personalised pages can be cached:

- **Split the page** — cache the shell, fetch personalised fragments client-side
- **Edge-side includes** — assemble cached and dynamic fragments at the edge
- **Short TTLs** — even 10 seconds on a hot endpoint removes most origin load
- **Vary by a small key** — cache by country or logged-in/out rather than by user

**A 5-second TTL on a hot endpoint at 200,000 QPS reduces origin traffic to 0.2 QPS.** That arithmetic is a compelling thing to say out loud.

## Choosing A CDN

Cloudflare, CloudFront, Fastly, Akamai. Differentiators: PoP count and locations, purge speed (Fastly's instant purge is notable), edge compute capability, and pricing model (egress-based vs request-based).

For an interview, the vendor matters far less than the behaviour you describe.

## Common Mistakes

- Caching authenticated responses publicly — a serious data leak
- Forwarding all cookies and query strings, destroying the hit rate
- Relying on purge instead of versioned URLs
- No `stale-while-revalidate`, so users wait on revalidation
- Ignoring origin shield with many PoPs
- Treating a CDN as static-only

## Related Topics

- [Caching](Caching.md)
- [Scaling Reads](Scaling%20Reads.md)
- [API Gateway](API%20Gateway.md)

## Revision Summary

Edge caches serve users from nearby PoPs, removing origin load entirely. Pull is the default; `s-maxage` controls the CDN TTL and `stale-while-revalidate` avoids revalidation waits. Prefer content-hashed URLs over purging. Even short TTLs on dynamic endpoints eliminate most origin traffic.

## Quick Recall

- A CDN hit never reaches your infrastructure
- Pull by default; push for known launches
- `s-maxage` = CDN TTL; `stale-while-revalidate` = no waiting
- Versioned filenames beat invalidation
- Low hit rate → cache key (cookies, query params, `Vary`)
- Origin shield prevents simultaneous PoP misses
- Short TTLs work for dynamic content too
