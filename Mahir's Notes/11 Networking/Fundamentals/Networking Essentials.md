# Networking Essentials

## Why It Matters

Every distributed system is services talking over a network. Latency budgets, connection pooling, load balancer choices, and timeout values all come from network behaviour.

## The Layers That Matter

Only three of the seven OSI layers come up in interviews:

| Layer | Protocols | Concern |
|---|---|---|
| **L3 Network** | IP | Addressing and routing between networks |
| **L4 Transport** | **TCP**, UDP, QUIC | Reliability, ordering, flow control |
| **L7 Application** | HTTP, WebSocket, gRPC, DNS | Application semantics |

**L4 vs L7 is the distinction that matters most in practice** — it determines what a load balancer can and cannot do.

## TCP

Connection-oriented, reliable, ordered, with flow and congestion control.

### The Three-Way Handshake

```
Client → SYN          →  Server
Client ← SYN-ACK      ←  Server
Client → ACK          →  Server
```

**Costs one full round trip before any data flows.** On a 100 ms RTT link, that's 100 ms before the first byte is even sent — which is the entire argument for connection reuse and keep-alive.

### What TCP Gives You

| Guarantee | Mechanism |
|---|---|
| Reliability | Sequence numbers + acknowledgements + retransmission |
| Ordering | Sequence numbers reassemble out-of-order packets |
| **Flow control** | Receiver advertises a window — protects the *receiver* |
| **Congestion control** | Sender infers network capacity — protects the *network* |

**Flow control vs congestion control is a classic question.** Flow control stops a fast sender overwhelming a slow receiver. Congestion control stops all senders collectively overwhelming the network. Different problems, different mechanisms.

### Slow Start

TCP begins with a small congestion window and doubles it each RTT until loss occurs. **A new connection is slow for its first few round trips** — another reason connection reuse matters, and why short-lived connections perform badly for bursty traffic.

### Head-of-Line Blocking

TCP delivers bytes in order. **One lost packet stalls everything behind it**, even data that already arrived. This is TCP's fundamental limitation and the reason QUIC exists.

## UDP

Connectionless, unreliable, unordered, no congestion control. Just addressing and a checksum on top of IP.

**Use when:** late data is worthless (live video, gaming, VoIP), or you're building your own reliability (QUIC, DNS).

**The trade:** you lose reliability but avoid handshake latency, retransmission delays, and head-of-line blocking.

| | TCP | UDP |
|---|---|---|
| Handshake | 1 RTT | **None** |
| Reliability | Yes | No |
| Ordering | Yes | No |
| Head-of-line blocking | **Yes** | No |
| Use | APIs, databases, file transfer | Streaming, gaming, DNS, QUIC |

## QUIC

Runs over UDP and reimplements reliability with independent **streams**.

| Benefit | Detail |
|---|---|
| **0-RTT / 1-RTT handshake** | TLS is built in, not layered on top |
| **No head-of-line blocking** | Loss in one stream doesn't stall others |
| **Connection migration** | Survives a network change (Wi-Fi → cellular) via a connection ID rather than the IP/port tuple |

**Connection migration is the underrated feature** — a mobile client switching networks keeps its connection, where TCP would have to reconnect and redo the handshake.

QUIC is the transport for HTTP/3.

## L4 vs L7 Load Balancing

| | **L4 (transport)** | **L7 (application)** |
|---|---|---|
| Sees | IP and port | **Full HTTP request** |
| Routes by | Connection tuple | **Path, header, cookie, method** |
| Terminates TLS | No (can pass through) | **Yes** |
| Throughput | **Higher** — just forwards packets | Lower — parses requests |
| Capabilities | Fast, protocol-agnostic | Content routing, retries, header rewriting, compression |
| Examples | AWS NLB, IPVS | AWS ALB, NGINX, Envoy, HAProxy |

**Choose L4** for raw throughput, non-HTTP protocols, or when you need to preserve the client IP without header tricks.
**Choose L7** when routing decisions depend on request content — which is most API traffic.

**Real systems use both:** an L4 balancer distributes across a fleet of L7 proxies.

## Load Balancing Algorithms

| Algorithm | Behaviour |
|---|---|
| Round robin | Even distribution, ignores load |
| **Least connections** | Sends to the least busy — better with variable request cost |
| Weighted | Accounts for heterogeneous server capacity |
| **Consistent hash** | Same client/key → same server (cache affinity, sticky sessions) |
| Random with two choices | Pick two at random, choose the less loaded — nearly as good as least-connections, far cheaper |

**"Power of two choices" is worth naming** — it gets most of the benefit of least-connections without tracking global state.

## Health Checks

| Type | Detail |
|---|---|
| **Passive** | Observe real traffic; eject on error rate |
| **Active** | Periodic probe to a health endpoint |

**The health endpoint must not check downstream dependencies.** If it does, one shared dependency failing marks *every* instance unhealthy and takes the whole service out. Check only whether this instance can serve — the same reasoning as the Kubernetes liveness/readiness split.

## DNS

```
browser cache → OS cache → resolver → root → TLD (.com) → authoritative
```

| Record | Purpose |
|---|---|
| A / AAAA | Hostname → IPv4 / IPv6 |
| CNAME | Alias to another name |
| **ALIAS / ANAME** | CNAME-like at the zone apex (which CNAME can't do) |
| MX | Mail |
| TXT | Verification, SPF/DKIM |
| NS | Delegation |

**TTL is the operational lever.** Low TTL means fast failover but more queries; high TTL means better caching but slow propagation.

**DNS is a poor failover mechanism** — clients and intermediate resolvers cache aggressively and often ignore TTLs. Use it for coarse geographic routing, not for fast failover; use health-checked load balancers for that.

**GeoDNS** returns different answers by resolver location, routing users to the nearest region. **Anycast** advertises one IP from many locations and lets BGP route to the nearest — used by CDNs and public DNS resolvers.

## Latency Budget

| Hop | Typical |
|---|---|
| Same datacentre round trip | 0.5 ms |
| Cross-AZ | 1–2 ms |
| Cross-region (same continent) | 10–30 ms |
| Cross-continent | 100–150 ms |
| TCP handshake | 1 RTT |
| TLS 1.3 handshake | 1 RTT (0 on resume) |
| TLS 1.2 handshake | 2 RTT |

**A cold HTTPS request across continents costs ~450 ms before the first byte** (TCP 150 + TLS 300). That arithmetic justifies CDNs, connection pooling, and keep-alive — say it out loud.

## Common Mistakes

- Not reusing connections — paying handshake and slow-start repeatedly
- Health checks that verify downstream dependencies
- Relying on DNS TTL for fast failover
- Using L4 when routing needs request content
- Ignoring head-of-line blocking when discussing HTTP/2 performance
- Assuming UDP is "just faster TCP" — it has no reliability at all

## Related Topics

- [HTTP and TLS](HTTP%20and%20TLS.md)
- [CDN](CDN.md)
- [API Gateway](API%20Gateway.md)
- [Real-Time Updates](Real%20Time%20Updates.md)

## Revision Summary

TCP costs a round trip to connect, starts slow, and suffers head-of-line blocking; UDP and QUIC trade differently. L4 balancers forward packets fast; L7 balancers route on request content. DNS is for coarse routing, not failover. Connection reuse is the highest-value network optimisation.

## Quick Recall

- TCP handshake = 1 RTT; TLS 1.3 = 1 more; TLS 1.2 = 2
- Flow control protects the receiver; congestion control protects the network
- TCP head-of-line blocking → QUIC fixes it with independent streams
- QUIC survives network changes via connection ID
- L4 = fast and blind; L7 = content-aware
- Health checks must not test dependencies
- DNS caching makes it unreliable for failover
