# Cloudflare Interview Prep: 4-Day Study Plan (Nov 16-20)

Nov 16, 2026 · @Mahir

## What the two rounds actually look like

Cloudflare does not publish its process, so this is built from 2024-2026 candidate reports. The pattern is consistent: the coding round is practical backend work judged on production-quality code, and the design round is Cloudflare-flavoured (edge, global scale) and judged on failure handling and tradeoffs. Generic LeetCode grinding is the wrong prep.

**Your confirmed rounds:** "Programming + Backend Coding Exercise" and "Architecture/Systems Design Interview". The first likely pairs a short programming problem with building a small backend piece in the same session, so the Thursday mock copies that format. "Architecture" may also mean explaining a system you built, so Wednesday now includes preparing that story. The debugging and AI-assisted rounds below are reported for some loops, but they are not on your schedule, so they no longer get practice time.

| Round | Format reported | Questions reported by candidates | What gets you marked down |
| --- | --- | --- | --- |
| Coding / pair programming | 45-60 min on CoderPad, HackerRank, or your own editor. Closer to pairing than a contest. Web search is sometimes allowed. Some screens make you parse stdin and format output yourself. | LRU cache (also with TTL or memory layers); token-bucket rate limiter; `isRateLimited` with rules on IP, method, path, user and tenant; parse a log file and count requests per domain or errors per status; check whether an IP is in a CIDR block without the library helper; thread-safe circular queue with unit tests; design hit counter; key-value store with values encrypted at rest; battleship game; 3Sum to 4Sum; minimum partitions to fit data | Missing error handling, crashing on malformed input, no tests, silent thinking. Clever-but-fragile code scores below plain working code. |
| Debugging (in some loops) | 45 min. You get a small, nearly working codebase you did not write, for example an HTTP server with broken routing. | Find and fix the bug while explaining your reasoning | Guessing and editing randomly instead of forming a hypothesis and testing it with prints or a debugger |
| AI-assisted coding (some teams, often not announced) | 45 min. An existing app or service; add features or fix bugs, with AI and Google allowed. The task is usually too big to finish by hand. | Add 4 features to an existing app; fix bugs in an unfamiliar project | Accepting AI output without reading it. The pass is treating the assistant like a fast junior whose code you review. |
| System design | About 60 min, conversational, often tied to Cloudflare products. Several candidates were told not to lean on AWS or GCP managed services. | Distributed rate limiter across many edge locations; ship logs from edge data centers (NYC, LA, SEA) to a core data center with a 1-minute average latency, encryption and HA, then redo it with no cloud; global key-value store like Workers KV; CDN caching layer; DDoS mitigation; HA HTTPS load balancer; distributed hit counter; generic ones too (URL shortener, "Instagram for cats") | A happy-path diagram with no failure handling. Expect "what happens at 100x traffic" and "a data center dies mid-write". One candidate got a no-hire after proposing Kafka then S3/Glue/Athena and being pushed to on-prem. |

**Networking comes up inside both rounds.** Expect "what happens when you type a URL and press enter", DNS and TTLs, TCP vs UDP, the TLS handshake, forward vs reverse proxies, anycast, and how you would tell a 429 from a 500 from a 504.

**Email your recruiter today** and ask: which language and environment (shared pad or own IDE), whether search or AI tools are allowed, whether input comes from stdin, and whether there is a debugging or AI-assisted component. Teams differ, and candidates have been surprised by unannounced AI rounds.

## How to perform in each round

Use the same script every time so that on Friday it runs on autopilot and your attention goes to the problem.

**Coding round: the narration script**

1. **Clarify (3 min).** Restate the task. Ask: where does input come from, what does malformed input look like, does this need to be thread-safe, what scale, what should happen on error.
2. **Sketch the interface (3 min).** Say the types and function signatures out loud before any logic.
3. **Simplest working version first.** Get something end to end, then add features. A working simple version beats an unfinished clever one.
4. **Narrate each choice with "because".** "A map keyed by IP, because lookups are per request." "One mutex for now, because contention is low; I'd shard locks under load."
5. **Handle errors as you go,** not at the end: empty input, bad lines, missing keys, overflow, timeouts.
6. **Write tests,** including one malformed-input case and one edge case. Run them.
7. **Close.** Complexity, what breaks under concurrency or 100x scale, and what you would add (metrics, config, persistence).

**Debugging round: the narration script**

1. Reproduce the bug first, and read the error or the wrong output.
2. Say what you expect a function to do, then check whether it does.
3. Form one hypothesis, test it with a print or a debugger, and narrow the search.
4. Fix, re-run, and say how you would stop this bug coming back (a test).

**AI-assisted round: the rules**

1. Read the codebase for 5 minutes before prompting. Know where things live.
2. Give the AI small, specific prompts that name files, functions, and constraints.
3. Read every diff before accepting it. Say out loud what it does and what you checked.
4. Run it after each change. Catch and fix at least one mistake the AI makes, and call it out.

**System design round: the 8-step frame**

1. **Requirements.** Functional, then non-functional: latency target, availability, consistency needs, data volume. Ask what is out of scope.
2. **Estimates.** Requests per second, peak, storage per day, bandwidth. Show the arithmetic.
3. **API.** 3-5 endpoints or interfaces.
4. **Data model and storage.** Pick stores you can run yourself (Postgres, Redis, Kafka, ClickHouse, Cassandra), not managed services. Say why each fits.
5. **High-level design.** Draw the request path end to end: user, anycast edge, service, store.
6. **Deep dive** on the 1-2 hardest parts, usually where the interviewer steers.
7. **Scale to 100x.** Sharding, caching, replication, batching, hot keys, multi-region. Say what is local to a data center and what is synchronised globally.
8. **Failure walk-through.** Go through what happens when a node, a data center, the network between them, or a dependency fails. Say whether each component fails open or closed, and why. This step is where candidates most often lose the round.

## Schedule at a glance

Each full day is about 3 hours of coding and 2 hours of design, because leaving design until the end is the riskiest choice. Every problem below comes from the reported question list, except Thursday's, which are kept unseen for the mocks.

| Day | Hours | Coding (about 3 h) | System design (about 2 h) |
| --- | --- | --- | --- |
| Mon Nov 16, evening | 2.5 | Recruiter email, setup, LRU cache with TTL and tests | Networking primer: what happens when you type a URL |
| Tue Nov 17 | 5 | Log parser, multi-rule rate limiter, CIDR match from scratch | Design frame, build-it-yourself toolkit, distributed rate limiter across edge locations |
| Wed Nov 18 | 5 | KV store HTTP service with TTL and auth, dependency-ordered provisioner, provisioning job service, your own architecture story | Edge-to-core log pipeline (no cloud), config distribution to every data center |
| Thu Nov 19 | 5 | Mock "programming + backend" round, then a machine-coding mock | Mock design: self-service provisioning platform, then a fleet deployment system or a CDN |
| Fri Nov 20, morning | 1-1.5 | One warmup problem | Re-read the frame and failure checklist |

## Question bank: job description plus reported questions

The role is on an internal infrastructure-platform team in Bengaluru. They build services, APIs and tools that provision, configure and run Cloudflare's global fleet, with a focus on testing, CI/CD, observability and self-healing. So the bank mixes two kinds of question: "JD" ones built around that work, and "Reported" ones that candidates said they were actually asked. The day sections below already use these.

**Coding and backend exercises**

| # | Problem | Source | What it tests | Day |
| --- | --- | --- | --- | --- |
| C1 | LRU cache with TTL, thread-safe, with tests | Reported | Data structures, locking, injectable clock | Mon |
| C2 | Log parser: requests per domain, errors per status, top N from stdin | Reported | Streaming, malformed input, sorting | Tue |
| C3 | Rate limiter: token bucket, then `isRateLimited` with rules on IP, method, path, user, tenant | Reported | Rule matching, time-based logic, concurrency | Tue |
| C4 | IP in CIDR block without library helpers, then 100,000 CIDRs | Reported | Bit operations, validation, tries | Tue |
| C5 | KV store HTTP service with TTL, login, values encrypted at rest | Reported | REST API, status codes, layering, tests | Wed |
| C6 | Dependency-ordered provisioner: resources with `depends_on`, run in topological order, detect cycles, run independent ones in parallel with a concurrency limit, skip dependents of a failed resource | JD | Graphs, worker pools, failure propagation | Wed |
| C7 | Provisioning job service: `POST /jobs` with an idempotency key, async worker pool, retries with exponential backoff and jitter, `GET /jobs/{id}` status, cancel | JD | Backend from scratch, idempotency, retries | Wed |
| C8 | Minimum partitions to fit data | Reported | Greedy, edge cases | Thu mock |
| C9 | Health checker with self-healing: poll many targets concurrently, mark unhealthy after K failures and healthy after M successes, trigger a restart with backoff and a cap on restarts per minute, expose `/status` and `/metrics` | JD | Concurrency, state machines, safety limits | Thu mock |
| C10 | Desired-state reconciler, like `terraform plan` then `apply`: diff desired config (JSON) against actual state, output create, update and delete actions, apply idempotently with retries, support a dry run | JD | Diffing, idempotency, clean design | Thu mock |
| C11 | Label-selector CLI: filter a server inventory with expressions like `role=edge,region!=eu,env in (prod,staging)` | JD | Parsing, validation, testing | Extra |
| C12 | Staged rollout controller: release to data centers in waves (1 site, 5%, 25%, 100%), halt and roll back if the error rate passes a threshold | JD | State machine, time windows | Extra |
| C13 | Thread-safe bounded circular queue with unit tests | Reported | Concurrency, tests | Extra |
| C14 | Hit counter for the last 300 seconds, then across many servers | Reported | Time buckets, scaling | Extra |
| C15 | Battleship game | Reported | Object-oriented design, validation | Extra |

**System design**

| # | Problem | Source | Core tradeoffs to bring out | Day |
| --- | --- | --- | --- | --- |
| D1 | Distributed rate limiter across 300 edge data centers | Reported | Local vs global counters, fail open vs closed | Tue |
| D2 | Ship logs from edge data centers to a core data center, 1-minute average latency, encrypted, no managed cloud | Reported | Buffering, at-least-once delivery, Kafka and ClickHouse | Wed |
| D3 | Config distribution: push a config change to every machine in 300+ data centers within seconds, with versioning, staged rollout and instant rollback | JD | Push vs pull, consistency vs speed, blast radius | Wed |
| D4 | Self-service infrastructure provisioning platform: request, plan, approve, apply; state store with locking, drift detection, audit log | JD | Locking, idempotent apply, drift, permissions | Thu mock |
| D5 | Fleet-wide deployment system with canaries and automatic rollback | JD | Safe rollout speed, health signals, rollback | Thu mock (option) |
| D6 | Fleet observability and auto-remediation: metrics and logs from every machine, alerting, automated fixes with safety limits | JD | Cardinality, alert noise, when not to auto-fix | Extra |
| D7 | Global key-value store like Workers KV | Reported | Eventual vs strong consistency, edge caching | Extra |
| D8 | CDN caching layer | Reported | Tiered cache, purge, stampedes | Thu mock (option) |
| D9 | DDoS mitigation, or a highly available HTTPS load balancer | Reported | Filtering without blocking real users, no single point of failure | Extra |

**Infra-platform questions to answer aloud (60 seconds each)**

1. REST vs gRPC: when would you choose each for an internal API?
2. What makes an operation idempotent, and how do you make a provisioning call safe to retry?
3. How does Terraform track state? What are state locking and drift, and how would you detect drift automatically?
4. What is a reconciliation loop, as in Kubernetes controllers, and why is it robust?
5. Canary vs blue-green vs rolling deploys: tradeoffs, and what signals decide a rollback.
6. Why use exponential backoff with jitter rather than fixed retries?
7. SLI, SLO and error budget: define them and give one for a provisioning API.
8. A service is slow on 1% of machines only. How do you investigate?
9. How do you test infrastructure code: unit, integration, and in CI?
10. When should a self-healing tool refuse to act automatically?

## Monday evening (about 2.5 hours)

Goal: remove surprises, get your setup ready, and solve the single most-reported Cloudflare coding problem properly.

**Block 1, 20 min: recon and setup**

- [x] Email the recruiter the questions in the first section (language, environment, search or AI allowed, stdin, debugging or AI component).
- [x] Pick your strongest language and stick with it. Go is common at Cloudflare and is a plus if you already know it, but do not switch this week.
- [x] Set up a blank project with a test runner, and practise reading stdin and printing formatted output in it.

**Block 2, 75 min: LRU cache, production quality**

- [ ] (30 min) `get` and `put` in O(1) with a hash map plus doubly linked list. Narrate every step.
- [ ] (20 min) Add a TTL per entry with lazy expiry on `get`, using an injectable clock so tests never sleep.
- [ ] (15 min) Make it thread-safe, and explain why `get` also needs the lock (it changes recency order).
- [ ] (10 min) Tests: capacity 1, overwrite an existing key, expired key, eviction order.
- [ ] Follow-up to answer out loud: how would a "memory-layered" version work (small hot in-process cache in front of a bigger one)?

**Block 3, 45 min: networking primer**

- [ ] Say out loud, end to end, in under 5 minutes: what happens when you type `https://example.com` and press enter. Cover DNS lookup (stub resolver, recursive resolver, root, TLD, authoritative, TTL caching), TCP handshake, TLS handshake (certificate check, key exchange), HTTP request, the CDN or reverse proxy, and the origin.
- [ ] Then add where Cloudflare sits: anycast IP, the nearest data center terminates TLS, serves from cache or goes to the origin.
- [ ] Read Cloudflare's own Learning Center pages on DNS, anycast and DDoS if any part felt shaky.

**Block 4, 10 min:** record yourself doing the URL walkthrough once, listen back, and note your silences.

## Tuesday (5 hours): practical coding set plus the rate limiter design

Goal: three reported Cloudflare coding problems done to production quality, then the most-reported design.

**Coding 1, 50 min: log parser**

- [ ] Read access-log lines from stdin (for example `timestamp ip method host path status bytes`). Count requests per domain and errors per status code, and print the top N sorted.
- [ ] Handle: blank lines, lines with missing fields, a non-numeric status, very large files (stream line by line, never load it all).
- [ ] Follow-ups to answer aloud: count over the last 5 minutes only; the file is 100 GB; logs arrive from 300 servers.

**Coding 2, 70 min: multi-rule rate limiter**

- [ ] (25 min) Token bucket per key with lazy refill from timestamps, no background thread.
- [ ] (30 min) `isRateLimited(request)` where rules match on any of IP, method, path, user ID and tenant ID, each with its own limit. A request is limited if any matching rule is over its limit. Decide how you store rules and match them quickly.
- [ ] (15 min) Thread safety and tests, including two rules matching one request and an empty rule set.
- [ ] Say out loud: sliding window vs token bucket, and memory per key at 10 million keys.

**Coding 3, 40 min: IP in CIDR, from scratch**

- [ ] Parse `"192.168.1.0/24"` and `"192.168.1.77"` yourself: split octets, validate 0-255, build the 32-bit integer, build the mask from the prefix length, compare.
- [ ] Reject bad input: `256.1.1.1`, `/33`, missing parts, extra dots.
- [ ] Follow-up: checking against 100,000 CIDRs per request. Answer: a binary trie on the bits (longest-prefix match). Mention IPv6 is the same idea with 128 bits.

**Break, 15 min.**

**Design toolkit, 40 min**

- [ ] Read the build-it-yourself toolkit table in the Reference section, so you can name a self-hosted component for each job.
- [ ] Learn anycast in one paragraph: many data centers announce the same IP range over BGP, users reach the nearest, and a failed site withdraws its route so traffic shifts.
- [ ] Learn the consistency vocabulary: strong vs eventual, quorum reads and writes, leader-based replication, CRDT counters.

**Design 1, 60 min: global rate limiter across 300 edge data centers, spoken and drawn**

- Requirements: per-customer rules, a check that adds under 1 ms, accuracy within a few percent.
- Core decision: local counters in each data center with asynchronous sync, versus a central counter. Global sync on every request is too slow across continents, so counts are local with periodic gossip or aggregation and accept small overshoot.
- Hot customers: shard counters within a data center, and push precomputed "block this key" decisions to the edge.
- Failure: if the counter store in a data center dies, fail open (allow traffic), because a broken limiter must not take a customer's site down. Say when you would fail closed instead (abuse or login endpoints).
- Config: rules change in seconds, through a pushed config pipeline with versioning.

* [ ] Write down the 3 tradeoffs you named and the 1 you forgot.

## Wednesday (5 hours): two backend services from scratch, your architecture story, plus log pipeline and config distribution designs

Goal: get two reps of the "backend service from scratch" style, prepare to explain your own architecture, then the two designs closest to Cloudflare's real systems.

**Coding 1, 75 min: key-value store as an HTTP service**

- [ ] `PUT /kv/{key}`, `GET /kv/{key}`, `DELETE /kv/{key}` with correct status codes (201, 200, 404, 400, 401, 413 for an oversized value).
- [ ] TTL per key, lazy expiry plus a background sweeper. Say why you need both.
- [ ] Simple user login (hash passwords, never store them plain) and values "encrypted at rest". Put hashing and encryption behind an interface and use the standard library's crypto. Never write your own.
- [ ] Separate the HTTP layer from the store so the store is unit-tested without a server. Add 4-5 tests.
- [ ] Follow-up aloud: persistence (append-only log plus snapshots), and replicating to a second node.

**Coding 2, 40 min: dependency-ordered provisioner (C6, JD)**

- [ ] Input: resources, each with a name and a `depends_on` list. Output: a valid run order using topological sort (Kahn's algorithm), with a clear error naming the cycle if there is one.
- [ ] Run independent resources in parallel with at most N at once. If one fails, skip everything that depends on it and report what ran, failed and was skipped.
- [ ] Tests: no dependencies, a chain, a diamond, a cycle, a missing dependency name, and one failure in the middle.

**Coding 3, 50 min: provisioning job service from scratch (C7, JD)**

- [ ] `POST /jobs` takes a job spec (for example "create 3 servers in BLR") and an `Idempotency-Key` header. The same key returns the same job instead of creating a second one. Return 202 with a job ID.
- [ ] A worker pool runs jobs asynchronously. Retry failures with exponential backoff and jitter, up to a limit, then mark the job failed with the error.
- [ ] `GET /jobs/{id}` returns status (queued, running, succeeded, failed, cancelled) and attempts. `POST /jobs/{id}/cancel` stops queued or running jobs.
- [ ] Keep the HTTP layer, job store and executor separate, with the executor behind an interface so tests use a fake that fails on demand. Write tests for idempotency, retry then success, retry exhaustion, and cancel.
- [ ] Follow-up aloud: surviving a restart (persist jobs), running workers on many machines (a queue plus leases so one job is not run twice), and the metrics you would expose.

**Architecture story, 15 min: a system you built**

- [ ] Pick one system from your work, ideally automation, tooling or a platform, since this team builds infrastructure software. Prepare a 2-minute overview and a diagram you can draw in 3 minutes, with real numbers (requests per second, data size, latency).
- [ ] Have ready: one tradeoff you made and why, one failure or incident and how you handled it, and what you would change now at 10x scale. A reported candidate was marked down for "not handling scale" here, so lead with numbers.

**Design 2, 60 min: logs from edge data centers to a core data center**

This is a reported question. Practice it as asked: logs from NYC, LA and SEA edge sites reach a database in the core, queryable centrally, 1-minute average latency and 15-minute max, encrypted in transit and at rest, highly available, eventual consistency is fine. Then the follow-up: no AWS or GCP.

- Edge: an agent buffers logs to local disk, batches and compresses them, and ships over TLS. The local disk buffer is what survives a network outage.
- Transport: a Kafka cluster in the core (or a small Kafka per edge site with mirroring), partitioned by site and customer. At-least-once delivery, deduplicated by a batch ID.
- Storage and query: consumers write to ClickHouse (columnar, fast aggregations), partitioned by day, with a retention policy.
- Estimates: work out lines per second, bytes per line, compression ratio, and storage per day, out loud.
- Failures: a core outage means edges keep buffering (state how many hours of disk); a Kafka broker death is covered by replication factor 3; a slow consumer creates lag, so alert on it; replays after recovery must not double count.

**Design 3, 50 min: config distribution to every machine in 300+ data centers (D3, JD)**

- Requirements: an engineer changes a config (for example a firewall rule or a feature flag) and every machine has it within seconds, with versioning, staged rollout and instant rollback.
- Write path: changes go to a central, strongly consistent store (a replicated log, for example etcd or a Raft-based store), and each change gets a version number.
- Fan-out: push changes through a tree (core, then regional relays, then a replica in each data center), and machines read from their local replica. Compare this with every machine polling the core and explain why polling does not scale.
- Safety: validate before publishing, roll out to one site, then 5%, then everything, watch error rates between stages, and roll back by publishing the previous version.
- Failures: a site that loses its link keeps serving its last good version and catches up by version number when it reconnects. A bad config is the biggest risk, so name blast-radius limits.
- Link it to the global KV design: readers at the edge, eventual consistency, versions to detect staleness.

**Review, 10 min:** list today's mistakes and add them to your Thursday checklist.

## Thursday (5 hours): full mocks on problems you have not seen

Goal: rehearse the real conditions. Timer on, talking the whole time, no pausing to look things up. Use a friend as interviewer if you can; otherwise paste the prompt below into a new Claude chat and let it run the round and interrupt you.

**Mock coding, 2 hours**

- [ ] (60 min) Mock A, in the same format as your real round: programming problem then backend exercise. First 20 min: minimum partitions to fit data (C8, reported). Given partition sizes and used sizes, find the fewest partitions that can hold all the data; if stuck, total the data and fill the largest partitions first. Then 40 min: health checker with self-healing (C9, JD). Poll targets concurrently, use K-failure and M-success thresholds, restart with backoff and a per-minute cap, and expose `/status` and `/metrics`, with tests.
- [ ] (50 min) Mock B: desired-state reconciler (C10, JD). Diff desired JSON config against actual state, print a plan of creates, updates and deletes, then apply it idempotently with retries and a dry-run flag. Clean structure and tests.
- [ ] (10 min) Review: where did you go silent, skip error handling, or skip tests?

**Break, 15 min.**

**Mock design, 1 hour 45 minutes**

- [ ] (50 min) Self-service infrastructure provisioning platform (D4, JD): engineers request resources through an API or CLI, the platform produces a plan, an approver signs off, and workers apply it. Cover the state store and locking (two people changing the same resource), idempotent apply, drift detection, audit logging, permissions, and what happens if a worker dies halfway through an apply.
- [ ] (50 min) Pick one: a fleet-wide deployment system with canaries and automatic rollback (D5, JD), or a CDN caching layer (D8, reported). For the deployment system, cover waves across data centers, which health signals trigger a rollback, a deploy freeze, and how to stop a bad release from reaching all sites.
- [ ] (5 min) Score both against the failure checklist: did you say fail open or closed, and what happens when a site dies?

**Final 30 min**

- [ ] Rapid fire: answer the infra-platform questions in the question bank and the networking questions in the Reference list aloud, 60 seconds or less each.
- [ ] Pick your 3 worst habits from your mistakes list and redo a 5-minute drill on each.

**Mock-interviewer prompt to paste into a new chat**

```markdown
You are a senior Cloudflare engineer running a [coding / system design] interview round for me. Give me one problem at a time from this style: practical backend tasks for coding, edge and global-scale systems for design. Stay quiet while I think aloud. Interrupt only as a real interviewer would: ask about malformed input, error handling, concurrency, 100x traffic, a data center failing mid-write, and whether I would use managed cloud services (push me to self-host). Keep time. At the end, score me 1-5 on communication, correctness, production quality, depth, and tradeoffs, and list my 3 biggest fixes.
```

## Friday morning (1-1.5 hours): warm up, nothing new

- [ ] Sleep 7+ hours on Thursday night. It is worth more than any extra problem.
- [ ] Re-read the four scripts in "How to perform" and your mistakes list (20 min).
- [ ] One warmup out loud (25 min): a small log-parsing or LRU-style task, with error handling and a test. Then stop.
- [ ] Say the URL walkthrough once, and the 8-step frame once.
- [ ] Setup check: language and editor ready with a blank project and test runner, stdin reading snippet ready, charged laptop, stable internet, mic and camera, pen and paper for diagrams, water.
- [ ] Have 2-3 questions ready for the interviewer, for example how the team handles incidents, or what the hardest scaling problem in their system is.

**In the room**

- Silence reads as being stuck. If you freeze, restate the problem and write the brute force.
- Ask before assuming; clarifying questions score well here.
- End every design choice with "because" and name one downside.
- If you spot your own bug, say so and fix it calmly. That is a good signal.

## Reference

**Networking rapid-fire questions (answer each in 60 seconds or less)**

1. What happens when you type a URL and press enter?
2. Walk through DNS resolution. What do A, AAAA, CNAME, NS and TXT records do? What does the TTL trade off?
3. TCP vs UDP: when would you choose each? Why is QUIC (HTTP/3) built on UDP?
4. What happens during a TLS handshake, and why does TLS 1.3 need fewer round trips?
5. Forward proxy vs reverse proxy: which one is Cloudflare?
6. What is anycast, and how does it help with failover and DDoS?
7. A user sees a 429, a 500, or a 504. What does each mean, and where would you look first?
8. What did HTTP/2 change compared with HTTP/1.1?
9. Threads vs processes, and which Linux tools show you sockets, processes and logs (`ss`, `lsof`, `top`, `strace`, `journalctl`)?

**Build-it-yourself toolkit: say these instead of managed cloud services**

| Job | Self-hosted choice | Instead of | Tradeoff to mention |
| --- | --- | --- | --- |
| Message queue or log transport | Kafka | SQS, Kinesis, Pub/Sub | Durable and replayable, but you run brokers and watch consumer lag |
| Analytics and log queries | ClickHouse | Athena, BigQuery | Very fast columnar aggregations; weak at updates and point lookups |
| Relational data | Postgres with a replica | RDS, Cloud SQL | Strong consistency; you shard it yourself when it outgrows one node |
| Wide-column, write-heavy | Cassandra or ScyllaDB | DynamoDB | Scales writes linearly; tunable but eventual consistency |
| Cache and counters | Redis | ElastiCache | Fast; memory-bound, and you need replication for failover |
| Blob storage | Ceph or MinIO | S3 | You handle disks, replication and erasure coding |
| Config and coordination | etcd | managed config services | Strongly consistent through Raft; small data only, writes are slower |

**Failure checklist for every design**

- A single node dies. A whole data center dies. The link between edge and core breaks.
- A dependency is slow rather than down (timeouts, circuit breakers).
- A hot key or a single huge customer.
- Fail open or closed, and why.
- What is local to a data center and what is synchronised globally?

**Problem bank if you finish early**

- Coding: LRU with a memory tier, request counter per domain over a sliding window, trie-based HTTP router with wildcards, consistent hash ring with virtual nodes, delayed job scheduler with a min-heap, sliding window maximum, 3Sum then 4Sum.
- Design: distributed hit counter, monitoring and alerting system, URL shortener, Durable Objects-style coordination service, DNS at scale, "Instagram for cats".

**Numbers to know**

- 1 million requests per day is about 12 per second; peak is usually 3-5x the average.
- Memory access takes about 100 ns, an SSD read about 100 microseconds, a same-datacenter round trip about 0.5 ms, and a cross-continent round trip 100-150 ms.
- Cloudflare-scale framing: hundreds of edge data centers and millions of requests per second. Use round numbers and say they are assumptions.

## Sources

These are candidate reports and prep guides, not an official Cloudflare process. Rounds vary by team and level.

- [LeetCode: Cloudflare SWE onsite, hit counter and edge-to-core log design](https://leetcode.com/discuss/interview-experience/6796944)
- [Glassdoor: Austin 2026 loop with debugging, system design and AI-assisted coding](https://www.glassdoor.co.uk/Interview/Cloudflare-Interview-RVW74810175.htm)
- [TechPrep: London 2026 loop (HTTP server debugging, AI-assisted features)](https://www.techprep.app/community/interview-experiences/cloudflare-senior-fullstack-engineer-interview-london-2026)
- [TechPrep: Cloudflare interview process and low-level design questions](https://www.techprep.app/companies/cloudflare)
- [PracHub: reported Cloudflare coding, design and networking questions](https://prachub.com/interview-guide/cloudflare-software-engineer-interview-questions-guide-2026)
- [PracHub: key-value store technical screen with AI allowed](https://prachub.com/interview-experiences/cloudflare-software-engineer-interview-experience-hm-chat-hr-screen-then-a-key-value-store-round-where-ai-wrote-my-crypto)
- [techinterview.org: what Cloudflare tests in Code Pair, debugging and design](https://www.techinterview.org/post/3233476849/cloudflare-engineering-interview/)
- [Design Gurus: Cloudflare interview guide](https://www.designgurus.io/blog/cloudflare-interview-guide)
- [Educative: Cloudflare system design interview](https://www.educative.io/blog/cloudflare-system-design-interview)
