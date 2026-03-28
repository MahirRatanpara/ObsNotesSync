
> A concise, actionable framework for the 35-minute LLD interview. Based on Hello Interview's Delivery Framework.

---

## The 35-Minute Map

| Phase | Focus                    | Time    | What You Produce                          |
| ----- | ------------------------ | ------- | ----------------------------------------- |
| **1** | Requirements             | ~5 min  | Numbered spec + Out of Scope list         |
| **2** | Entities & Relationships | ~3 min  | Entity list + ownership arrows            |
| **3** | Class Design             | ~12 min | State + Behavior per class                |
| **4** | Implementation           | ~10 min | Pseudo-code for key methods + walkthrough |
| **5** | Extensibility            | ~5 min  | High-level extension answers              |

> **🎯 Golden Rule:** If your interviewer pulls you off-framework, follow their lead. But gently guide back to ensure you cover all five phases.

---

## Deep Dive: Prompt → Requirements

This is the highest-leverage skill in LLD interviews. You get a single sentence. You need to turn it into a buildable spec in under 5 minutes.

### The 4-Lens Questioning Strategy

Don't freestyle questions. Run through these four lenses in order, spending roughly 30 seconds on each:

|#|Lens|Core Question|Example Questions to Ask|
|---|---|---|---|
|**1**|Primary Capabilities|What operations must this system support?|What are the core actions a user can perform? What's the main workflow?|
|**2**|Rules & Completion|What defines success, failure, or state transitions?|When does the process end? What constraints exist? Any win/loss/completion conditions?|
|**3**|Error Handling|How should the system respond to invalid inputs?|What happens on bad input? Should we throw, return false, or silently reject?|
|**4**|Scope Boundaries|What's in vs. explicitly out?|Do we handle persistence? UI? Concurrency? Multiple instances?|

### Conversion Strategy: One-Liner to Spec

Follow this exact mental model to convert answers into a written spec:

#### Step 1: Decompose the Prompt

Identify the **subject** (what the system is), the **actions** (verbs in the prompt), and the **constraints** (any qualifiers mentioned).

> **Example:** "Design a parking lot system where cars are assigned to spots as they pull in."
> 
> - **Subject:** Parking Lot System
> - **Actions:** assign cars to spots
> - **Constraints:** assignment happens as cars pull in (implies real-time, automatic)

#### Step 2: Ask the 4 Lenses (out loud, to interviewer)

- **Capabilities:** What types of vehicles? Multiple floors? Different spot sizes?
- **Rules:** How is assignment decided? What if lot is full? Can a car leave and re-enter?
- **Errors:** What if someone tries to park in an occupied spot? Double exit?
- **Scope:** Payment system? Reservation? Tracking time parked? Concurrency?

#### Step 3: Write Requirements (numbered, on whiteboard)

Convert each confirmed answer into a crisp, numbered statement. Each requirement should be:

- **Specific** — no ambiguity about what it means
- **Testable** — you could verify whether the design satisfies it
- **Atomic** — one behavior per requirement, not compound statements

#### Step 4: Write Out of Scope

Explicitly list what you're NOT building. This does three things:

- Prevents scope creep during design
- Shows the interviewer you thought about boundaries
- Gives you comeback material if they ask "what about X?" later

> **⚠️ Common Out-of-Scope Items (pick what applies):** UI/rendering layer, persistence/database layer, networking/API layer, authentication/authorization, concurrency/multi-threading, analytics/logging, payment processing, undo/redo functionality, AI/ML features, variable/dynamic sizing

### Worked Example: "Design a Coffee Machine"

**Prompt:** "Design a coffee machine that dispenses coffee and makes espresso."

After asking the 4 lenses, your whiteboard reads:

**Requirements:**

1. Machine supports multiple drink types (coffee, espresso, latte).
2. Each drink has a recipe (ingredients + quantities).
3. Machine tracks ingredient levels and rejects orders if insufficient.
4. Ingredients can be refilled.
5. System exposes available drinks based on current stock.

**Out of Scope:**

- Payment/pricing system
- Physical hardware simulation
- UI/display rendering
- Concurrency/thread safety
- Custom drink creation

---

## Deep Dive: Entities & Relationships

You have ~3 minutes here. The goal is NOT a detailed class diagram. It's a quick structural sketch that tells the interviewer: "I know what the pieces are and who owns what."

### The Entity Extraction Strategy

#### Step 1: Scan Requirements for Meaningful Nouns

Read through your numbered requirements. Circle/underline every noun that represents a "thing" in your system.

#### Step 2: Apply the Entity Filter

For each noun, ask this single question:

> **The Entity Filter:** Does this thing maintain **CHANGING STATE** or **enforce RULES**?
> 
> → **YES** → It's an Entity (its own class) → **NO** → It's just a field on another entity (a primitive, enum, or simple type)

**Examples of applying the filter:**

|Noun|Has changing state / enforces rules?|Verdict|
|---|---|---|
|Board|YES – tracks cell contents, checks wins, checks full|**Entity ✓**|
|Player|YES – holds mark (X/O), identity|**Entity ✓**|
|Game|YES – orchestrates turns, tracks state, declares winner|**Entity ✓**|
|Mark (X/O)|NO – it's a fixed label, never changes|Enum field|
|Row/Column|NO – just coordinates, no behavior|int parameters|
|GameState|NO – a named set of values (IN_PROGRESS, WON, DRAW)|Enum field|

#### Step 3: Establish Relationships (3 Questions)

Once you have your entities, answer these three questions to draw your arrows:

|#|Question|What It Determines|
|---|---|---|
|**1**|Who is the orchestrator?|Which entity drives the main workflow and holds references to others. This is your "god object" (not a bad thing in LLD).|
|**2**|Who owns durable state?|Which entities track data that must survive across operations (board contents, player info, inventory levels).|
|**3**|Who depends on whom?|Draw has-a / uses / contains arrows. Always point from owner to owned (Game → Board, not Board → Game).|

### Worked Example: Coffee Machine Entities

From the coffee machine requirements, scanning for nouns:

**Entities:**

- CoffeeMachine (orchestrator)
- Recipe
- Inventory

**Relationships:**

- CoffeeMachine → Inventory
- CoffeeMachine → Recipe (many)
- Recipe → Ingredient (list)

> **💡 Whiteboard Tip:** Don't overthink notation. Simple boxes with labeled arrows work. You're NOT drawing UML. The goal is to communicate structure clearly enough that you can build on it in the Class Design phase.

---

## Quick Reference: Remaining Phases

### Phase 3: Class Design (~12 min)

For each entity, top-down starting from the orchestrator:

|Aspect|How to Derive|Anchor Principle|
|---|---|---|
|**State**|Map each requirement → what this class must track to fulfill it|If you can't point to a requirement, you don't need that field|
|**Behavior**|Map each requirement → what operation satisfies it|Small API: each method = one real action from the problem|

> **Encapsulation Rule:** Keep rules with the entity that owns the relevant state. Workflow rules → orchestrator. Data rules → the entity that owns the data. This is "Tell, Don't Ask."

### Phase 4: Implementation (~10 min)

- **Ask the interviewer** what level of detail they want (pseudo-code vs. real code).
- **Happy path first:** inputs → sequence of steps → state changes → return value.
- **Edge cases second:** invalid inputs, illegal state transitions, boundary conditions.
- **Verify with a walkthrough:** trace 3–4 operations showing initial state → mutation → final state.
- **Don't force patterns:** Singleton/Factory/etc. only if they genuinely add value.

### Phase 5: Extensibility (~5 min)

- **Interviewer-led:** they propose a twist, you show your design handles it cleanly.
- **Stay high level:** point to the right parts of your design, don't rewrite code.
- **Key signal:** your design can absorb new requirements without restructuring.

> **Extension Formula:** "All state transitions flow through [single method]. To add [feature], I'd introduce [pattern/structure] at that point. The rest of the system doesn't need to change."

---

## Interview Day Cheat Sheet

|Minute|Action|
|---|---|
|`0:00–1:00`|Read prompt. Silently decompose: subject, actions, constraints.|
|`1:00–3:00`|Ask 4-lens questions out loud. Confirm answers with interviewer.|
|`3:00–5:00`|Write numbered Requirements + Out of Scope on whiteboard.|
|`5:00–6:00`|Scan requirements for nouns. Apply entity filter.|
|`6:00–8:00`|List entities. Draw ownership arrows. Identify orchestrator.|
|`8:00–20:00`|Class design: for each entity, derive State then Behavior from requirements.|
|`20:00–30:00`|Implement key methods: happy path → edge cases → pseudo-code.|
|`30:00–32:00`|Verify: trace a concrete scenario through your code.|
|`32:00–35:00`|Extensibility: answer "what if" questions at high level.|

---

## Anti-Patterns to Avoid

|✗ DON'T|✓ DO|
|---|---|
|Jump straight into code|Spend 5 min on requirements first|
|Model every noun as a class|Apply the entity filter ruthlessly|
|Draw formal UML diagrams|Use simple boxes + arrows|
|Force design patterns everywhere|Use patterns only when they add real value|
|Implement every single method|Focus on the 1–2 most interesting methods|
|Skip verification|Always trace through a concrete scenario|
|Gold-plate edge cases early|Happy path first, then add edge cases|