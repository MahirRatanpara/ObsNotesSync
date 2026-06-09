# Google L4 (SWE-III, Cloud) — 2.5-Day Prep Plan

**Thursday Jun 11 — two virtual rounds: PDSA + Domain (technical) and Googleyness & Leadership (behavioral)**

## Priority logic

- **P0 — Coding (PDSA).** Backbone of the technical round and 3 of your 4 loop touchpoints. Most hours go here.
- **P0 — Thursday logistics.** A platform/connection fail can sink a round on its own. Lock it down.
- **P1 — Orchestration deep-dive + distributed-systems concepts.** The "domain" half of round 1; your resume is fair game in every round.
- **P1 — STAR stories.** The Googleyness round is _also_ Thursday — this is no longer "later."
- **P2 — AI-acumen story.** Likely woven in, fast to prep, and a strength for you.

You're not starting cold — you've been drilling Java concurrency and LeetCode (DP / graphs / linked lists). Where you've already ground a pattern, it's "keep warm," not "grind again."

---

## Schedule

### Monday evening (tonight) — ~2.5 hrs

- [x] **(P0 · 30m)** Setup check — confirm the VIP link works, test Google Meet + headset + screen-share, pick a quiet room. Skim Google's "Example Coding/Engineering Interview" video for pacing.
- [x] **(P0 · 90m)** Coding on a _plain doc_ (no IDE), talking aloud, 35-min timer each. Start with **graphs**: topological sort + BFS/DFS (Course Schedule I/II, Number of Islands, Clone Graph).

### Tuesday (Jun 9) — full day

- [x] **(P0 · ~2.5h AM)** Coding: **heaps** (Top-K, Merge K Sorted Lists, Task Scheduler) + **intervals** (Merge Intervals, Meeting Rooms II) + one more graph. ~4–5 problems, timed, on a doc.
- [ ] **(P0 · ~3h PM)** practice concurrency syntax on docs using Claude and practice problems 
- [ ] **(P0 · ~3h PM)** remaining LLD problems from 
- [ ] **(P1 · ~1.5h midday)** Orchestration deep-dive — write tight answers to the follow-ups (below), then rehearse the full walkthrough _out loud_. Aim for a 3–4 min architecture story you can pause and branch from. **(Resume Deep Dive)**
- [ ] **(P1 · ~1.5h eve)** STAR — fully draft 4 stories in S-T-A-R with metrics. Use the recruiter's frame: _Achieved [X], quantified by [Y], by doing [Z]_.
- [ ]  **(P1 · 30m)** Brain-dump raw STAR material — list real situations (orchestration re-arch, 3-day→4-hr win, ShivAgri solo build, MTTR/observability work, any conflict/mentoring). Just capture; don't polish.
- [ ] **(P0 · ~3h PM)** DSA continue 

### Wednesday (Jun 10) — full day

- [ ] **(P0 · ~2h AM)** **(P0 · ~3h PM)** DSA continue 
- [ ] **(P1 · ~1h midday)** Distributed-systems one-liners — drill the list (below) aloud. Specifically prep "now make it scale / make it concurrent / what breaks under a partition" as extensions of your coding problems.
- [ ] **(P1 · ~1.5h PM)** STAR — finish the remaining 4 stories; rehearse all 8 aloud and tighten each to ~2 min.
- [ ] **(P2 · 30m PM)** AI-acumen story — one concrete case where AI sped you up _and_ something it got wrong that you caught.
- [ ] **(P0 · ~1h eve)** Light mock, then stop: 1 timed coding problem + 3 STAR stories cold. Logistics re-check, then **sleep early — no late grinding.**

### Thursday morning (Jun 11) — light only

- [ ] **(20m)** One _easy_ problem to warm your fingers — no new Hards.
- [ ] **(15m)** Re-read your STAR one-pager + distributed-systems one-liners.
- [ ] **(30m before)** Setup check, hydrate, scratch paper ready, breathe. Trust the prep.

---

## Reference — orchestration deep-dive: have answers ready

- [ ] Why the actor model / Akka over a thread-pool or a workflow engine?
- [ ] What happens when a worker dies mid-task? At-least-once vs exactly-once, and how you made tasks idempotent.
- [ ] How do you stop two workers grabbing the same job during a network partition? (leader election / locks + fencing tokens)
- [ ] Why Kafka over a DB-backed queue? Your partitioning/sharding choice and why.
- [ ] How you hit 99.9% uptime; how the 60% MTTR cut was achieved (observability).
- [ ] Where does it break at 10×? The bottleneck, and what you'd do differently.

## Reference — distributed-systems one-liners to nail

- [ ] Strong vs eventual consistency; linearizability; read-your-writes — when you'd pick each.
- [ ] Replication: leader / multi-leader / quorum (w + r > n); replication lag; failover risks.
- [ ] Partitioning: range vs hash; consistent hashing; hot partitions; rebalancing.
- [ ] Consensus (high-level): Paxos vs Raft — terms, leader election, log replication, dedup by request ID.
- [ ] CAP / PACELC — the actual trade-off.
- [ ] Delivery: at-most / at-least / effectively-once; why exactly-once is impossible at the network level; idempotency keys + dedup; dead-letter queues.
- [ ] Backpressure, retries with backoff, timeouts, heartbeats.

## Reference — STAR stories to prepare (8 slots)

- [ ] Disagreement / conflict with a teammate or manager
- [ ] Dealing with ambiguity / unclear requirements
- [ ] A failure or mistake + what you learned
- [ ] Leadership / influence without authority
- [ ] Highest-impact work (the orchestration win)
- [ ] Tight deadline / high-pressure delivery
- [ ] A difficult stakeholder or cross-team friction
- [ ] A time you were wrong and changed course

## Reference — Thursday logistics (day-before checklist)

- [ ] VIP link saved and tested; Google Meet works; screen-share tested
- [ ] Headset/mic working; quiet room booked; notifications off
- [ ] Stable internet (backup hotspot ready); laptop charged + charger plugged in
- [ ] Water, scratch paper, pen; resume copy open
- [ ] Two rounds back-to-back — confirm the timing/gap with your recruiter and plan a short reset in between