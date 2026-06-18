# Lifecycle & Simulation Model — the two spines and the saved scenario

This document is the conceptual anchor for how a plan card represents the *whole* first-home lifecycle and lets a user **simulate** it. It exists because the plan card was drifting into a bag of independent components (good nodes, no spine) and into a static read-only artifact (a plan that cannot simulate is not a plan). It states one model that the engine contract, the blueprint, and the UX all conform to.

The model has two halves:

1. **Two spines.** The lifecycle is projected onto two axes — a **legal/temporal** axis (the swimlane) and a **financial** axis (the cash calculator) — over one shared primitive: a list of **cash events**. Every other component is a *coupling* of a specific legal step to its cash consequence.
2. **Simulation.** A user explores what-ifs ephemerally and persists exactly one chosen scenario on demand. Structural what-ifs recompute deterministically in the engine (verified to the dollar); cash-on-hand resolves instantly in the client.

Companion references: [`engine-contract.md`](engine-contract.md) (the simulation/refine primitive, metering of a resolver-only recompute, persistence), [`architecture.md`](architecture.md) (§11.9 component-flow + the renderer vocabulary this extends), [`agentic-boundary.md`](agentic-boundary.md) and [`resolver-semantics.md`](resolver-semantics.md) (why structural what-ifs are resolver work, not agent work), [`plan-card-refresh.md`](plan-card-refresh.md) (the per-card re-run + resolver-only sweep this reuses), [`eligibility-resolution.md`](eligibility-resolution.md) §9 and [`ongoing-costs-projection.md`](ongoing-costs-projection.md) (the figure-owning components that *place* events onto the spine), [`outcome-conformance.md`](outcome-conformance.md) (the gate that keeps placement honest), [`isolation-model.md`](isolation-model.md) (the saved scenario as a unit of persisted state). The blueprint that realizes this is [`../blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md).

---

## 1. The plan card is a lifecycle, projected twice

A first home purchase is one process unfolding over time: **Prepare → Pre-approve → Contract → Settle → Own.** A plan card's job is to make that one process legible and *steerable*. The failure mode we are correcting is treating the process as a set of tabs (eligibility here, costs there, a journey diagram somewhere else) — the user gets nodes but never the threads that connect them.

There are exactly two threads worth drawing, because there are two things a buyer is anxious about and must coordinate:

- **What happens, who does it, and when** — the *legal/temporal* process. Title machinery, documents, approvals, the parties and their handoffs. Rendered as the **swimlane** (`swimlane-diagram`).
- **Where every dollar enters, converts, and leaves** — the *financial* process. Deposit, duty, scheme benefits, settlement balance, ongoing outgoings. Rendered as the **cash calculator** (`calculator`).

These are not two features. They are **two projections of the same lifecycle** — the legal spine projects the lifecycle onto the *party × phase* plane; the financial spine projects it onto the *money × phase* axis. Everything else (eligibility, schemes, buffers, due diligence, ownership obligations) is a **coupling**: a point where a specific legal step has a specific cash consequence (contract exchange ⟷ deposit to trust + insurance in force; settlement ⟷ balance + registration; ownership ⟷ monthly P&I + rates). A coupling component therefore reads from *both* spines and never invents a third source of truth.

```
                         the lifecycle (one process)
   Prepare ──────── Pre-approve ──────── Contract ──────── Settle ──────── Own
      │                  │                   │                 │             │
  ┌───┴──────────────────┴───────────────────┴─────────────────┴─────────────┴───┐
  │ LEGAL SPINE   (swimlane): party × phase — who does what, who hands to whom     │
  ├───────────────────────────────────────────────────────────────────────────────┤
  │ FINANCIAL SPINE (calculator): money × phase — what enters/leaves, cumulative   │
  └───────────────────────────────────────────────────────────────────────────────┘
            ▲                          ▲                         ▲
        eligibility               cash_position            ownership_planning
        (couplings place their figures onto BOTH spines; they do not recompute)
```

## 2. The shared primitive: cash events

The two spines read **one** data structure so they cannot disagree. That structure is an ordered list of **cash events** — every place money enters or leaves across the lifecycle.

A cash event:

```jsonc
{
  "id": "deposit_to_trust",
  "phase": "contract",                     // prepare | pre_approve | contract | settle | own
  "label": { "vi": "...", "en": "..." },   // localized_text
  "direction": "out",                      // out (money_out) | in (money_in)
  "amount": [v_lo, v_hi],                  // money_range — banded at base, point when narrowed; VERIFIED figures only
  "timing": "one_off",                     // one_off | recurring
  "period": null,                          // null for one_off; e.g. "month" | "quarter" | "year" for recurring
  "counterparty": "vendor_agent",          // an actor id (ties to the swimlane's actors)
  "source_component": "cash_position"      // provenance — which component owns this figure (one-computer-per-figure)
}
```

**The spines are projections of this list:**

- The **financial spine** groups events by `phase`, runs the cumulative cash-flow (need side = sum of `out`; have side = `cash_available` − cumulative), and renders the verdict per phase and overall. It is no longer a flat settlement-cost snapshot; it is a phased cash-flow.
- The **legal spine** places each event as a cell at `(phase, counterparty)` with `flow_marker` derived from `direction`. The swimlane's amount-bearing cells *are* cash events. Cells with no money (a pure document/milestone step) carry `flow_marker ∈ {document, milestone}` and no event.

**Provenance, not a new computer.** The cash-events list is *assembled by placement*, not by a new calculation: each figure-owning component contributes its events with `source_component` set, and the spine renders them. This extends one-computer-per-figure (the rule that already keeps stamp duty computed once, in the engine, verified to the dollar — [`stamp-duty-concession-mechanics.md`](stamp-duty-concession-mechanics.md)) from "the LLM must not recompute" to "**no consumer recomputes**, including the spine and including the client." A duty figure travels from `cash_position` to both spines unchanged; a scheme benefit travels from `eligibility`; ongoing outgoings from `ownership_planning`. *Which* component assembles the union is a blueprint decision (see [`../blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md)); this document fixes only that the union is a placement of owned figures and that [`outcome-conformance.md`](outcome-conformance.md) gates it so a placed event always traces to an owner.

**`who pays whom`.** Because every event names a `counterparty`, the legal spine can finally draw the missing relationships — the swimlane gains an `interactions` view (from-actor → to-actor, per phase, what flows) derived from events plus the acting party. This is the structural answer to "who talks to whom," at purchase *and* in ownership.

## 3. Base scope: the spines exist before any property

Both spines are **base-scope** — they exist for a card with no property attached, in keeping with plan-first onboarding (constraint #1). At base:

- Phases `prepare`, `settle`, `own` carry generic events with **banded** `money_range` amounts derived from `target_price_range` (honest-partial — [`eligibility-resolution.md`](eligibility-resolution.md) §9; never a fabricated point figure, never a misleading `$0`).
- When a property attaches, the bands **narrow to points** and property-specific events appear; nothing about the spine's shape changes.

A "Chưa có / pending" on a spine is therefore never a dead end — it is a *missing input*, which §4 turns into an invitation to simulate.

## 4. Simulation: explore freely, save one scenario

A plan is for simulating scenarios. The model has two recompute paths and one persistence rule.

### 4.1 Two recompute paths

| What the user varies | Path | Where it runs | Cost | Persisted? |
|---|---|---|---|---|
| **Cash on hand** | client-side subtraction (have-side only) | the browser | instant | no, until saved |
| **Structural** — target price, state | **deterministic resolver recompute** of the financial spine | the engine | a resolver-only turn | no, until saved |

The structural path is the one that makes the calculator *powerful and precise rather than a regression*. The prototype recomputed stamp duty in client-side JavaScript — an unverified second computer. We instead route a structural what-if through the engine's deterministic resolver (no LLM leaf, no agent reasoning — [`agentic-boundary.md`](agentic-boundary.md), [`resolver-semantics.md`](resolver-semantics.md)), which reuses the per-card re-run + resolver-only sweep already specified in [`plan-card-refresh.md`](plan-card-refresh.md). Two consequences:

- **It is verified to the dollar** — the same regulated figure path, not an approximation.
- **It is free to the shell** — [`engine-contract.md`](engine-contract.md) already states that a resolver-only turn (it names "a `cash_position` recompute") emits no `usage` and so does not meter. Maximum interactivity does not cost tokens.

Cash-on-hand stays in the client because it is pure subtraction against an already-verified `total_cash_required` — it introduces no new computed figure, so it needs no engine round-trip and no gate.

> **Scope boundary.** Varying *price/state* is resolver work because the figures downstream of those facts are deterministic given the KB. It is **not** an agent turn. (`property_type` is **not** a base structural override — at base no property is attached, so it moves zero base figures; it is a Phase-B per-property dimension, [`engine-contract.md`](engine-contract.md) §10.1.) Anything that would change *reasoning* (a new constraint, an uploaded document, a free-text question) remains an agent turn and meters as usual — the resolver path is for re-deriving figures, not for re-thinking the plan.

### 4.2 One saved scenario

Persistence rule: **the card's snapshot *is* the saved scenario — there is exactly one current persisted scenario per card, and there is no separate scenarios table.**

- A what-if is an **ephemeral overlay** in the client. Exploring never writes.
- **Save** fires a **refine turn**: the resolver recompute is committed, writing a new `content_jsonb` snapshot + a `plan_card_events` row (the existing lifecycle machinery — [`engine-contract.md`](engine-contract.md), [`plan-card-lifecycle-restoration.md`](plan-card-lifecycle-restoration.md)).
- Therefore the card always shows one *current* scenario; **history lives in the append-only event log**, not in parallel saved rows. "Save" advances the single current snapshot; it does not fork it. This is the unit of persisted state the [`isolation-model.md`](isolation-model.md) tracks — no new isolation concept is introduced.

This keeps the regulated audit trail intact: each saved scenario is a snapshot with `deploy_commit_sha` + resolved KB, exactly like every other filled card (constraint #6).

### 4.3 Where a saved override persists — the plan-target overlay

§4.2 commits the recomputed *snapshot*. But a save must also persist the override *inputs*, or the next refresh sweep ([`plan-card-refresh.md`](plan-card-refresh.md)) recomputes from the **stale** facts and silently clobbers the saved scenario. So the question "where do the override inputs land?" is not an implementation detail — it is the load-bearing half of "save."

**The answer is forced by the fact model, not chosen.** [`fact-model-unification.md`](fact-model-unification.md) (Decision 1, sub-question 4) places `target {price_range, zone, state, …}` on the **`plan` (the card)**, not the persistent `profile` — it is mutable *per journey* (scenario S24). Therefore a structural override (which only ever varies `target_*`) must persist **on the card**. Persisting it to `profiles.facts_jsonb` is a leak: that is leak-free *only* while `profile:card` is 1:1 (the Wedge-1 shape), and breaks the moment a profile gains a second card — a `target_price` save on card-1 would overwrite card-2's target. W7b is the first consumer that *forces* fact-model item-4's plan/profile storage split; it pulls in the minimal slice.

**Mechanism — a plan-target overlay (additive, backward-compatible).**

- A new card-level store (the canonical `plan.target`) holds the per-journey target. It starts empty.
- The base-turn / refresh read of "onboarding" becomes `profile…onboarding` **overlaid with** the card's target when the overlay is non-empty. An empty overlay — every card created today — reads exactly as before, so nothing existing changes behaviour.
- **Save** (the refine turn) computes the *effective* target (`profile…onboarding` ⊕ existing overlay), applies the chosen overrides through the **same pure mapping the preview uses** (one mapping, both paths — never a second copy), and writes the **full resulting target** back to the overlay. Writing the full result, not a sparse patch, means "strip a key" needs no patch-deletion semantics.

**Saving a *state* what-if supersedes a pinned suburb — forced, not a product toggle.** Projection precedence is `target_sal` > `target_zone` > `state` (the pinned suburb is more specific than a state filter). If a user pins a suburb and then saves a `state` what-if, *keeping* the pin would be incoherent: projection would re-derive the pinned suburb's state and the saved card would not match the previewed scenario. So the explicit save strips `target_sal`/`target_zone` (exactly what the override mapping already does for the preview) — the deliberate save replaces the basis. The only product surface is a UX warning ("saving a Victoria projection clears your pinned suburb"); that is **shell-side**, not an engine decision.

**Everything else about a refine is inherited, not new.** A refine is an authenticated, tenant-scoped resolver-only turn over the existing turn primitive (the dev-only `/rerun` minus its dev gate, plus the override mapping + the overlay write). So: the full FIRB/ASIC/AML pipeline runs at commit (§10.3), the turn emits `fill_path: resolver` with **no `usage`** (§4.1), per-card serialization (the 409) holds, and the snapshot carries `deploy_commit_sha` + resolved KB (§4.2) — all by construction.

## 5. What this model fixes (and what it deliberately does not)

It fixes, by construction:

- **The inert calculator** → a phased financial spine with real interactivity (§2, §4).
- **"Numbers appear when you add income/savings" with nowhere to enter them** → the calculator is the input surface; entering savings is a cash-on-hand overlay, saving it is a refine turn (§4).
- **Pending states as dead ends** → every "Chưa có" on a spine is a missing input the user can simulate to fill (§3).
- **"Who talks to whom" never modeled** → the `counterparty` on every event gives the swimlane an `interactions` view (§2).

It does **not** introduce: a new persistence store (§4.2), a client-side figure computer (§2), an agent turn for structural what-ifs (§4.1), or any property dependency for the base plan (§3). Those are the four ways this could go wrong; each is closed on purpose.

## 6. Downstream conformance (tracked separately)

This anchor fixes the model. The contracts and artifacts that must conform are updated in their own docs, one at a time:

- **`engine-contract.md`** — the structural-what-if resolver primitive, the save-as-refine seam, metering of a resolver-only recompute, one-saved-scenario persistence.
- **`architecture.md` §11.9** — the renderer vocabulary extensions this requires (a Q&A surface; the swimlane `interactions` capability; whether the phased cash-flow is the `calculator` renderer extended or a distinct capability), plus the `cash_events` output and the new base-scope preparation component.
- **`../blueprints/fhb-domestic-au.md`** — tab order (the lifecycle rail + Q&A); `cash_position` emits `cash_events`; the swimlane reads them and gains `interactions`; the base-scope preparation component (document checklist / people-to-engage / buffer, reclassified out of per-property `due_diligence`); ownership counterparty table + graduation hint.
- **`04-ux-model.md`** — the lifecycle tab rail, the explore→save simulation UX, the "what this is" overview intro, pending-as-invitation.
- **`structure-map.md` + `README.md`** — register this node in the doc graph.
