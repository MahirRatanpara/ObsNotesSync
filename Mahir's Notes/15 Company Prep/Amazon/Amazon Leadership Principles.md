# Amazon Leadership Principles

## Why It Matters

Amazon's behavioural round is not a formality — the **Bar Raiser can veto the hire** regardless of technical performance. Every interviewer scores against specific LPs and submits written evidence.

## How The Loop Works

- Each interviewer is assigned **2–3 specific LPs** to assess
- They must submit **written evidence** with direct quotes from your answers
- The **Bar Raiser** is from outside the hiring team and has veto power
- Debrief compares evidence across interviewers — **repeating one story across rounds is visible and penalised**

**Practical implication: you need enough distinct stories that no two interviewers hear the same one.** Aim for 10–12.

## The 16 Principles

| # | Principle | What it actually tests |
|---|---|---|
| 1 | **Customer Obsession** | Did you start from customer impact, or from the technology? |
| 2 | **Ownership** | Did you act beyond your job description? Long-term thinking. |
| 3 | **Invent and Simplify** | Did you find a simpler solution, not just a clever one? |
| 4 | **Are Right, A Lot** | Judgement under uncertainty; seeking disconfirming views |
| 5 | **Learn and Be Curious** | Did you learn something new and apply it? |
| 6 | **Hire and Develop the Best** | Mentoring, raising others' performance |
| 7 | **Insist on the Highest Standards** | Did you refuse to ship something substandard? |
| 8 | **Think Big** | Did you propose something beyond the immediate ask? |
| 9 | **Bias for Action** | Speed under uncertainty; reversible vs irreversible decisions |
| 10 | **Frugality** | Did you achieve more with fewer resources? |
| 11 | **Earn Trust** | Self-criticism, receiving criticism, candour |
| 12 | **Dive Deep** | Did you get to root cause? Do you know your own numbers? |
| 13 | **Have Backbone; Disagree and Commit** | Did you push back — **and then commit** when overruled? |
| 14 | **Deliver Results** | Outcomes under constraints |
| 15 | **Strive to be Earth's Best Employer** | Team growth and wellbeing |
| 16 | **Success and Scale Bring Broad Responsibility** | Second-order consequences |

**LPs 1–14 carry the weight in engineering loops.** 15 and 16 are newer and rarely probed for SDE roles.

## The Four That Decide Most Loops

### Customer Obsession
Every technical story should connect to customer impact. "We reduced latency" is weak; "checkout p99 was 4 seconds and users were abandoning carts, so I…" is strong.

### Ownership
The signal is doing something **outside your assigned scope** because it needed doing. "It wasn't my service, but the on-call pain was ours, so I…"

Anti-signal: "that was another team's problem."

### Dive Deep
Amazon probes **three to four levels down**. Expect:

> "Why did latency increase?" → "Why did the GC pause grow?" → "Why did allocation rate change?" → "What did you measure to confirm that?"

**Know your own numbers.** Not knowing your system's throughput, latency, or data volume is a direct Dive Deep failure. This is the LP most often failed by otherwise strong candidates.

### Have Backbone; Disagree and Commit
**Both halves are scored.** Many candidates tell a story about disagreeing and being proven right — that's only half.

The complete story: you disagreed, you argued it with data, you were overruled, and **you then committed fully** to the chosen path without sabotage or sulking. That second half is the harder and more valuable signal.

## Frugality and Bias for Action — Commonly Missed

**Frugality** is not about being cheap; it's resourcefulness. "We didn't have budget for a managed service, so I built a lightweight version in two days that covered 90% of the need."

**Bias for Action** hinges on the **one-way vs two-way door** distinction, which is Amazon's own language:

- **Two-way door** (reversible) → decide fast, iterate
- **One-way door** (irreversible) → slow down, gather data

**Using that vocabulary explicitly is a strong signal** — it shows you've internalised how Amazon actually makes decisions.

## Story-to-LP Mapping

Build a matrix. Each story should credibly cover 2–4 LPs so you have coverage without repetition.

| Story | Primary LP | Also covers |
|---|---|---|
| e.g. Latency optimisation | Dive Deep | Customer Obsession, Deliver Results |
| e.g. Pushed back on a design | Have Backbone | Earn Trust, Are Right A Lot |
| e.g. Learned a new technology under deadline | Learn and Be Curious | Bias for Action, Deliver Results |
| e.g. Owned an incident outside your service | Ownership | Customer Obsession, Dive Deep |

**Fill this in with your own stories before the loop, and check no LP has zero coverage.** Your existing stories in `Company-Wise/Amazon/LP/` are the raw material.

## Answer Structure For Amazon

Use [STAR](STAR%20Method.md), but with two Amazon-specific adjustments:

1. **Lead with customer or business impact**, not the technical setup
2. **Quantify everything** — Amazon is a metrics culture and unquantified claims are treated as unsupported

Expect the interviewer to interrupt and drill. **That's normal and positive** — it means they're gathering evidence, not that you're failing.

## Common Mistakes

- Reusing one story across multiple rounds (visible in the debrief)
- "We" instead of "I"
- No metrics
- Backbone stories that stop before the "commit" half
- Not knowing your own system's numbers when pressed
- Treating LP prep as less important than the coding round
- Fewer than 10 prepared stories

## Related Topics

- [STAR Method](STAR%20Method.md)
- [Behavioural Question Bank](Behavioural%20Question%20Bank.md)

## Revision Summary

Sixteen principles; 1–14 matter for engineering. Each interviewer scores 2–3 with written evidence, and the Bar Raiser can veto. Prepare 10–12 distinct quantified stories mapped to LPs, know your own numbers cold for Dive Deep, and always complete the "commit" half of a Backbone story.

## Quick Recall

- Bar Raiser has veto power; evidence is written down
- 10–12 stories — **never repeat one across rounds**
- The four that decide loops: Customer Obsession, Ownership, Dive Deep, Backbone
- Dive Deep goes 3–4 levels — know your numbers
- Backbone = disagree **and then commit**
- Bias for Action = one-way vs two-way doors
- Quantify everything
