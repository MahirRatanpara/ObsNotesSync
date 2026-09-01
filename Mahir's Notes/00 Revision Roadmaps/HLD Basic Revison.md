# System Design Drill — Notes

Seven core concepts, drilled through a URL shortener design. Each round has the question, what you said, what was missing, and the answer to aim for.

---

## Read this part first

### The three habits that cost you marks

**1. You answer the first half and skip the second.**

Happened in rounds 1, 3, 4, and 6. Every time, the second half was the part that separates people who know the words from people who have reasoned it through. Interviewers build two-part questions on purpose.

Fix: when a question has two clauses, answer the second clause first. If asked "what do you shard on, and what happens at 8 to 16 shards," start with the resharding problem.

**2. You use no numbers.**

You never estimated read vs write split, never reached for a latency figure, never sized anything. Every round got sharper once arithmetic was added.

Estimation is a habit, not knowledge. It takes 30 seconds and it changes your answer. In round 1, doing the math showed that writes were a non-problem — that alone would have reordered your whole plan.

Fix: before proposing anything, say out loud "let me size this." Then do it.

**3. You name risks but not decisions.**

"This could cause data loss" is an observation. The interviewer is waiting for the next sentence.

"I would promote the replica with the highest log position and accept losing the last few seconds of writes, because an outage costs more than a handful of lost link creations" is an answer.

Fix: end every response with a decision and the trade-off you accepted.

### Numbers to memorise

|Thing|Value|
|---|---|
|Cross-continent round trip (Sydney to Virginia)|~200 ms|
|Cross-country round trip (US coast to coast)|~70 ms|
|Same-region round trip|~1-5 ms|
|Same-datacentre round trip|~0.5 ms|
|Memory read|~100 ns|
|SSD random read|~100 µs|
|Disk seek|~10 ms|
|Redis / cache hit|~1 ms|
|Simple DB query (indexed, warm)|~5 ms|

The two that matter most: **200 ms cross-continent** and **1-5 ms same-region**. Those two anchor nearly every latency question you will get.

### Estimation shortcuts

- 1 million requests/day is about 12 requests/second
- 100 million requests/day is about 1,200 requests/second
- 1 billion requests/day is about 12,000 requests/second
- A modest Postgres box handles a few thousand simple reads/second
- A single Redis node handles 100,000+ operations/second

---

## Round 1 — Scaling

### Question

A URL shortener runs on one machine, app server and Postgres on the same box. Traffic grows from 100 rps to 10,000 rps, read-heavy at roughly 100 reads per write. What do you change, in what order, and why that order?

### What you said

Replication for reads, then scale API servers with separate read and write fleets, then add Redis if the database still cannot cope.

### What was right

- Read-heavy workload means replication. Correct tool.
- Cache as a lever. Correct tool.
- Recognising reads and writes need different treatment.

### What was missing

- **Skipped step zero.** App and DB share a box. First move is splitting them onto separate machines and vertically scaling each. Cheapest, fastest, adds no new failure modes. Every real team does this before touching replication.
- **Cache came last; it should be near-first.** Short URLs are immutable and access is Zipf-distributed, so a small set of links gets most of the traffic. A cache gets 90%+ hit rate with zero invalidation logic. That single move absorbs most of the 10k rps. Replication is more machines, more lag, more complexity, for less benefit.
- **No sizing.** 10,000 rps at 100:1 gives ~9,900 reads/sec and ~100 writes/sec. 100 writes/sec is nothing — a single modest Postgres handles it. So the write path needs no work at all. Spotting that one side of the problem is a non-problem is exactly the judgment being tested.
- **Separate read and write server fleets is premature.** The app tier is stateless. Just run N identical boxes behind a load balancer. Splitting fleets buys failure isolation but costs deployment complexity — a later move.

### Factual error to unlearn

You said "wait for at least three replication factors."

- **Replication factor** is Cassandra / DynamoDB vocabulary. It is the number of copies of each piece of data. It does not apply to single-leader Postgres.
- It also contradicted itself: you said writes tolerate delay, then chose to _wait_ for replicas. Waiting means synchronous, which means slower writes.
- If writes tolerate delay, you want **asynchronous replication, accepting some lag**. Say it that way.

### The order to give

1. Estimate first — 9,900 reads/sec, 100 writes/sec. Writes are a non-issue.
2. Split app and DB onto separate machines. Vertically scale both.
3. Add Redis in front of reads. Data is immutable, so caching is trivial.
4. Load balancer plus N stateless app servers.
5. Read replicas for cache misses.
6. Shard only when write volume or data size actually demands it.

### The general principle

**Order of scaling moves, cheapest first:**

1. Vertical scaling (bigger box)
2. Separate concerns onto their own machines
3. Cache
4. Read replicas
5. Horizontal scaling of stateless tiers
6. Sharding (last — it is the expensive, hard-to-reverse one)

### Follow-up you would get

> "You added async replicas. A user creates a short link and immediately clicks it. It 404s. Why, and what do you do?"

Replication lag. The read hit a replica that had not received the write yet.

Fixes:

- Route a user's reads to the leader for a few seconds after their write. This is called **read-your-writes consistency**.
- Or write the new mapping into the cache at creation time, so the read never touches a replica at all. Cleaner here.

### The deeper trap (worth knowing, unlikely to be asked at CS1)

Adding stateless capacity in front of a shared stateful resource can make things **worse**, not just fail to help. Mechanisms:

- **Connection pool multiplication.** Pools are per-node. 10 nodes x 50 connections = 500. 30 nodes = 1,500. The DB can usefully run maybe 50-100 concurrent queries. The rest queue up, burning context switches and lock waits. You added load, not capacity.
- **Queueing theory.** Past roughly 80% utilisation, wait time rises hyperbolically. Tripling arrival rate at fixed capacity explodes the tail latency, not just the average.
- **Cache hit rate dilution.** More nodes means each node's local cache sees less traffic, so each cache is colder, so DB traffic rises more than proportionally.
- **Retry amplification.** Slow DB, client timeouts, retries, more DB load, slower still. A feedback loop, not a plateau.

"Stateless" describes your code, not your dependencies.

---

## Round 2 — CAP and consistency models

### Question

Two regions, US and EU, both accept writes. A network partition cuts them apart. An EU user tries to create a new short URL. What are your two options and which do you pick?

### What you said

Either make the system unavailable to preserve consistency, or stay available and serve possibly-stale data. Picked availability, reasoning that write throughput is low.

### What was right

- The two-option framing, stated in behaviour terms rather than reciting letters. Good.
- AP is the correct pick for this product.
- Reads should stay up.

### What was missing

- **Your justification was wrong.** Write volume has nothing to do with the partition choice. The deciding variable is the **cost of being wrong**.
    - Short URL creation: low stakes, rare conflict. Rejecting the write annoys a user for no safety benefit. Choose AP.
    - Bank transfer: same low volume, but a wrong answer is unrecoverable. Choose CP.
    - **Same write rate, opposite decision.** Volume is not the variable.
- **The question was about a write; you drifted to reads.** The interesting problem is that the EU accepts the creation locally and the US cannot see it. Read availability is the easy half.
- **You did not name the actual danger.** With both regions writing and no coordination, two users can generate the **same short code** for different long URLs. When the partition heals you have a real conflict — and unlike a shopping cart, you cannot merge it. One URL silently points to the wrong place. Surface this unprompted.

### The answer to give

- **Pick AP.** Rejecting on partition costs a user their link. Accepting costs a rare collision. Collision is cheaper.
- **Then design the conflict away, so AP costs nothing:** partition the ID space. US issues codes from one range or prefix, EU from another. Or give each region pre-allocated blocks of IDs. Two regions can now write independently during a partition and never collide.
- **Reads:** serve from the local region. A brand-new EU link is briefly unresolvable in the US. Acceptable, since links are usually clicked in the region they were created.
- **The exception:** custom aliases like `/my-brand` genuinely need global uniqueness. Make that one path CP — reject custom aliases during a partition, allow auto-generated ones.

### The insight that marks you as mid-level

**CAP is not one decision per system. It is a decision per operation.**

The same product can be CP for one endpoint and AP for another. Saying this unprompted is a strong signal.

### CAP, stated correctly

- CAP only describes behaviour **during a network partition**.
- Partitions are not optional. You cannot choose to not have them.
- So the real choice is only ever **CP or AP**. "CA" is not an option for a distributed system.
- If a vendor claims CA, they either mean a single node (no partitions possible because there is no network), or they are hiding a CP system that goes unavailable, or an AP system that loses data.

### Consistency models, weakest to strongest

- **Eventual consistency** — replicas converge, eventually. No time bound.
- **Bounded staleness** — eventual, with an SLA. "No more than 2 seconds behind." This is what you should actually say. Saying "eventually consistent" with no bound is the shallow version.
- **Read-your-writes** — you always see your own writes, others may lag.
- **Monotonic reads** — you never see time go backwards.
- **Linearizable / strong** — everyone sees one order, immediately. Expensive: requires coordination on every operation.

### Follow-up you would get

> "You said reads can be stale. How stale is acceptable, and how would you know if you exceeded it?"

Give a target (say under 2 seconds cross-region), then say you would monitor replication lag directly and alert on it. The phrase is **bounded staleness**.

---

## Round 3 — Partitioning (sharding)

### Question

50 TB of URL mappings, one box cannot hold it. What do you shard on, and what exactly happens when you go from 8 shards to 16?

### What you said

Hash the short URL and shard on that hash.

### What was right

The shard key is correct.

### What was missing

You answered the easy half and stopped — and the second half was flagged as the one that mattered.

**Missing justification for the key:**

- Every read is `GET /abc123`, a point lookup by that exact key. Sharding on it means every read hits **exactly one shard**.
- This is the test: **does my shard key match my dominant query pattern?**
- If you had sharded on `user_id` or `created_at`, every redirect would fan out to all 16 shards to find one row. Catastrophic.

**Missing the rejected alternative:**

- Range partitioning would be wrong here. Short codes are sequential-ish, so all new writes would land on the last shard — a hotspot. Hashing spreads them.
- You implied this with "distribute evenly" but never named what you rejected. Naming the alternative and why you rejected it is what makes it a design decision rather than a guess.

### The half you skipped: 8 to 16 shards

- With plain `hash(key) % 8`, moving to `% 16` changes the destination of **roughly 50% of all keys**. Every one of those rows must physically move. During the move, reads cannot find their data.
- This is **the resharding cliff**. Naming it is the point of the question.

**Fix 1 — consistent hashing:**

- Keys and shards are placed on a ring. Each key belongs to the next shard clockwise.
- Adding a shard moves only about 1/N of keys — roughly 6% here, not 50%.
- **Virtual nodes** (many ring positions per physical shard) keep the distribution even and make rebalancing smoother.

**Fix 2 — fixed logical shards (the answer interviewers like more):**

- Do not reshard at all. Start with a large fixed number of logical shards, say 1,024, and map many logical shards onto each physical machine.
- Growing means **reassigning logical shards to new machines**. No key ever changes its logical shard, so nothing is ever rehashed.
- This is what Vitess and Citus do.

**The migration itself, either way:**

1. Dual-write to old and new location
2. Backfill existing data in the background
3. Verify both copies agree
4. Flip reads to the new location
5. Stop dual-writing, delete old data

Not a stop-the-world operation.

### Other sharding traps worth knowing

- **Cross-shard queries.** Anything needing data from many shards (analytics, "all links by this user") becomes a scatter-gather. Slow, and as slow as the slowest shard.
- **Cross-shard transactions.** You lose them, or pay for two-phase commit.
- **Hot shards.** Hashing spreads keys evenly but not _traffic_ evenly. One celebrity key still overloads its shard. Cache fixes this, not sharding.

---

## Round 4 — Replication

### Question

Single-leader Postgres, two async replicas. The leader's disk dies at 3 a.m. Can you promote a replica immediately, and what have you lost if you do?

### What you said

Wait for the replica to finish syncing before promoting; otherwise you lose the writes that had not replicated yet.

### What was right

You identified the core trap: async replication means unreplicated writes existed on the leader when it died, and promoting loses them. You did not give the shallow "just promote a replica" answer.

### The problem

**"Let the replica finish syncing" is impossible.** The leader's disk is dead. There is no source to sync from. Those writes are gone permanently. You cannot wait your way out.

The real choice is: **promote and accept the data loss, or stay down.**

For a URL shortener: promote. A handful of lost link creations is worth far less than an outage. Say the trade-off out loud.

### What else they want to hear

- **Which replica?** The one with the **most recent log position** (highest LSN in Postgres). The two async replicas are at different points; picking the laggier one loses more data.
- **The other replica must be rebuilt, not re-pointed.** It may hold writes the new leader never received — divergent history. Re-clone it from the new leader.
- **Split-brain.** If the old leader was not truly dead (network blip rather than disk failure) and comes back thinking it is still leader, you now have two leaders taking writes. Prevent with **fencing**: forcibly kill the old leader, or require a quorum to promote. Naming split-brain unprompted is a strong signal.
- **Clients must be redirected.** Promotion is useless if the app still points at the dead IP. Handled by a virtual IP, DNS failover, or a proxy like PgBouncer or Patroni.

### Follow-up you would get

> "How do you make sure this never loses data again?"

Make **one** replica synchronous, keep the other async. Every commit is then on at least two disks before being acknowledged.

The cost, which you must state:

- Write latency now includes a network round trip to the sync replica.
- If the sync replica dies, **writes stall** until you demote it to async. You have traded one failure mode for another.

**Durability is paid for in write latency and in a new failure mode.**

### Replication models summary

|Model|Write latency|Data loss on leader failure|
|---|---|---|
|Async|Fast|Yes — last few seconds|
|Sync (one replica)|Slower (+1 RTT)|No|
|Quorum (e.g. 2 of 3)|Middle|No, and tolerates one replica dying|

---

## Round 5 — Caching

### Question

Redis in front of the DB. A celebrity link gets 500,000 rps. The key expires. What happens in the next 50 ms, and how do you prevent it?

### What you said

Warm the key before expiry, give hot keys a long TTL. Alternatively, on a cache miss, hold off the other reads, let one request fetch from the DB and populate the cache, then serve the rest.

### What was right — this was your strongest answer

You produced **single-flight / request coalescing** on your own, unprompted, and described the mechanism accurately. That is the textbook primary mitigation. Cache warming and extended TTLs are valid secondary defences.

### What was missing

- **You never named the failure, so you never quantified it.** Say it plainly: **cache stampede** (also called thundering herd). 500,000 concurrent requests hit a DB sized for maybe 5,000. It does not slow down — it **falls over**. Connections exhaust, and then _every_ key's requests fail, not just this one. The cascade is what makes this a design question rather than a tuning question.
- **"Long TTL for celebrity keys" has a chicken-and-egg problem.** How do you know a key is hot _before_ it gets hot? You need hit-count tracking to promote keys to longer TTLs dynamically. One sentence, otherwise it sounds like manual curation.
- **Missing the cheapest fix: probabilistic early expiry.** Instead of expiring at exactly time T, each request has a small chance of refreshing the key as T approaches, with probability rising as expiry nears. One unlucky request refreshes early; everyone else keeps hitting a warm cache. No locks, no coordination, a few lines of code.
- **You did not say what the waiting requests do.** "Hold off" for how long? If the DB fetch takes 2 seconds you now have a million requests queued in memory and your **app servers** die instead of your database. Bound the wait with a timeout, and serve **stale data** while the refresh happens (_stale-while-revalidate_). For an immutable URL mapping, stale is perfectly safe — which makes this trivially correct here.

### The complete answer

1. Name it: cache stampede.
2. **Single-flight lock** — one fetch per key, others wait.
3. **Serve stale while revalidating**, with a bounded wait for anyone who cannot get stale data.
4. **Probabilistic early refresh** so expiry never lines up with peak traffic.
5. **Jitter TTLs** across keys so a batch never expires together.

### Follow-up you would get

> "Your Redis node itself dies. Now what?"

Same cascade, all keys at once, worse.

- Replicate Redis.
- Keep a small in-process local cache on each app server as a second layer.
- Critically: **rate-limit or shed load at the DB connection layer**, so a cache failure degrades the service instead of destroying the database.

**A cache should be an optimisation, not a load-bearing dependency. If losing your cache takes down your system, you do not have a cache — you have a tier.**

### Caching strategies to have ready

**Write patterns:**

- **Cache-aside (lazy loading)** — app checks cache, on miss reads DB and populates. Most common. Simple. First request after a write is always a miss.
- **Write-through** — write to cache and DB together. Cache always fresh, writes slower.
- **Write-behind (write-back)** — write to cache, flush to DB asynchronously. Fast writes, risk of data loss if cache dies.
- **Refresh-ahead** — proactively refresh hot keys before expiry.

**Eviction policies:** LRU (most common), LFU (better for skewed access), FIFO, TTL-only.

**The three classic cache failures:**

- **Cache stampede** — one hot key expires, everyone hits the DB.
- **Cache penetration** — requests for keys that do not exist anywhere, so the cache never helps. Fix with a bloom filter or by caching negative results.
- **Cache avalanche** — many keys expire at the same moment. Fix with TTL jitter.

---

## Round 6 — Networking

### Question

User in Sydney, servers in Virginia, redirect takes 900 ms. Break down where the time goes and say which parts you can eliminate.

### What you said

Physical distance across undersea fibre is the main cost; put a server closer to users.

### What was right

Correct diagnosis and correct fix.

### What was missing

The question asked you to **decompose 900 ms into round trips**. You gave cause and cure but skipped the analysis, which was the actual ask.

The number to reach for: **Sydney to Virginia is roughly 200 ms round trip.** Speed of light in fibre, about 16,000 km, plus routing overhead.

### The breakdown

|Step|Round trips|Time|
|---|---|---|
|DNS lookup (uncached)|1|~200 ms|
|TCP handshake|1|~200 ms|
|TLS handshake|1-2|~200-400 ms|
|HTTP request/response|1|~200 ms|
|Server processing (cache hit)|—|~5 ms|
|**Total**|**4-5**|**~800-1000 ms**|

**Note what dominates.** Four to five round trips of _setup_, only one of which carries your actual data. Server processing is 0.5% of the total.

**Optimising your code here is worthless.** That realisation is the whole point of the question.

### What you can eliminate

- **DNS** — anycast DNS with local resolvers, plus caching. Near zero.
- **TCP + TLS** — connection reuse (keep-alive), TLS session resumption, HTTP/2. TLS 1.3 cuts the handshake to 1 RTT, and 0-RTT resumption removes it for repeat visitors.
- **Distance** — an edge presence in Sydney. This is the big one, because it shrinks _every_ round trip from 200 ms to about 5 ms, turning 900 ms into roughly 30 ms.
- **Server processing** — already 5 ms. Nothing to gain.

### The ideal answer for this product

**Serve the redirect from a CDN edge node.** The mapping is immutable and tiny — perfect for edge caching. The request never crosses an ocean at all.

### Follow-up you would get

> "Why does a cold connection cost so much more than a warm one?"

Because setup round trips are **per-connection, not per-request**. Once established, each subsequent request costs 1 RTT instead of 5. This is why connection pooling matters and why HTTP/1.1 without keep-alive was so expensive.

### Networking facts to have ready

- **TCP** — reliable, ordered, connection-oriented. 3-way handshake. Has slow start, so the first few packets are throttled.
- **UDP** — no handshake, no ordering guarantee, no retransmission. Used where late data is worse than lost data (video, gaming, DNS).
- **HTTP/1.1** — one request at a time per connection, head-of-line blocking.
- **HTTP/2** — multiplexes many requests over one connection. Fixes application- level head-of-line blocking, but not TCP-level.
- **HTTP/3 (QUIC)** — runs over UDP, fixes TCP head-of-line blocking, 0-RTT reconnection.
- **Long polling / WebSockets / SSE** — the three options when the server needs to push. WebSockets are bidirectional; SSE is server-to-client only and simpler.

---

## Round 7 — Load balancing

### Question

5 app servers behind round robin. One is running twice as slow due to GC pauses. Round robin keeps sending it an equal share. Impact on users, and what do you change?

### What you said

One in five users faces higher latency. Switch to least-connections, or route based on CPU threshold. Least-connections works because a slow server holds fewer... (you reasoned it as a live signal).

### What was right — best structured answer of the drill

You answered impact **and** fix without prompting, and your reasoning for least-connections was correct: a slow server **accumulates in-flight connections** because they take longer to drain, so connection count is a live health signal that round robin is blind to. That is the key insight.

### Two refinements

**Sharpen the impact statement.**

Not "1 in 5 users has a latency problem." Say:

> "My p99 is now entirely determined by that one server."

20% of requests being twice as slow means the **tail metric your SLA is written against** is broken, even though the average barely moves and 80% of users notice nothing. Framing it as a **tail latency** problem rather than a "some users" problem is the mid-level answer. Averages hide this; percentiles expose it.

**You did not mention health checks.**

- Least-connections handles _gradual degradation_.
- It does **not** handle an _unhealthy_ server — one accepting connections but returning errors, or GC-pausing for 10 seconds at a stretch.
- You need **active health checks**: periodic probe, remove from rotation on failure, re-add after it passes.
- Least-connections reduces the damage. Health checks stop it.

**Bonus: outlier detection.** Automatically eject a server whose latency or error rate deviates sharply from its peers, even if it passes health checks. This is what Envoy does, and it answers "what if the server is slow but technically healthy."

### Load balancing algorithms

|Algorithm|Use when|
|---|---|
|Round robin|Servers identical, requests uniform|
|Weighted round robin|Servers have different capacity|
|Least connections|Request durations vary, or servers degrade|
|Least response time|You want the LB to react to real latency|
|IP hash / consistent hash|You need session stickiness or cache affinity|
|Random with two choices|Cheap approximation of least-connections at scale|

### Layer 4 vs Layer 7

- **L4 (transport)** — routes on IP and port. Fast, cheap, protocol-agnostic. Cannot see URLs or headers.
- **L7 (application)** — reads HTTP. Can route by path, host, or header. Can do TLS termination, compression, rewriting. Slower and more expensive.
- For a URL shortener you want **L7** so you can route `/api/*` differently from redirects.

### Related things worth a sentence

- **The LB itself is a single point of failure.** Run at least two, with a floating IP or DNS failover between them.
- **Sticky sessions** tie a user to one server. Convenient, but they break scaling and failover. Prefer stateless servers with shared session storage.
- **Health check tuning** matters: too aggressive and you eject healthy servers during a blip; too lax and you keep sending traffic to a dead one.

---

## Quick review sheet

Read this alone the morning of the interview.

**Process:**

1. Clarify requirements and constraints
2. **Estimate** — reads/sec, writes/sec, storage, bandwidth
3. Draw the simple version
4. Find the bottleneck the numbers point at
5. Fix that one bottleneck
6. Repeat

**Scaling order:** vertical → separate concerns → cache → read replicas → horizontal → shard.

**CAP:** partitions are not optional, so the choice is only CP or AP. Decide **per operation**, not per system. The variable is **cost of a conflict**, not write volume.

**Sharding:** match the shard key to the dominant query pattern. Plain modulo hashing moves ~50% of keys on resize — use consistent hashing or fixed logical shards.

**Replication:** async loses recent writes on failover; sync costs write latency and adds a stall risk. Promote the replica with the highest log position. Watch for split-brain.

**Caching:** stampede, penetration, avalanche. Single-flight, stale-while- revalidate, jittered TTLs. A cache must be optional, not load-bearing.

**Networking:** cold connections cost 4-5 round trips. 200 ms cross-continent, 1-5 ms same region. Move compute to the edge before optimising code.

**Load balancing:** least-connections for uneven servers, health checks for unhealthy ones, L7 when you need to route on content. Think in percentiles.

**Three habits to fix:**

1. Answer the second half of the question first
2. Do arithmetic before proposing anything
3. End every answer with a decision and its trade-off