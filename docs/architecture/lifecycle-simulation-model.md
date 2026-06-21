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

---

## 7. The navigation surface: three views and the phase sheet

§1–§6 fixed the *model* (two spines, one shared primitive, simulation). §7 fixes the *surface* — how those spines are navigated. The residual failure mode is not in the data; it is that the shell renders the engine's component DAG as a **flat list of seven sibling tabs** (overview, cash calculator, journey, before-you-buy, buying, after-you-buy, Q&A) and repeats the same component across several of them (`cash_position` appears in three tabs, `eligibility` in two). The user gets the producer's decomposition, not their own lifecycle. §7 collapses that to the two spines plus a synthesis landing, and gives each phase a drill-down. It introduces no new spine and no new renderer — the tell that this is a unification, not another feature.

### 7.1 Three top-level views, not seven tabs

The plan card presents **three views** (plus the Q&A surface), and nothing else at the top level:

| View | Kind | What it is |
|---|---|---|
| **Overview** | synthesis | The 90-second landing — a shell-composed read over the filled spines ("what this is, where you stand"). Not a spine; a synthesis. |
| **Flow** | the legal/temporal spine | The swimlane (§1) *is* the navigation. Each phase (`prepare → pre_approve → contract → settle → own`) — **and every item cell within it** — is clickable and opens that phase's **phase sheet** (§7.2). (Item cells route to the *phase* sheet because a journey `cell` carries no per-cell backing id; the finer item→component drill lives inside the sheet's checklist, where `phase_playbook` actions carry `component_ref`.) The top-level swimlane is **grid-only navigation** — its all-phases "who deals with whom" (`interactions`) list is **not** shown here; it moves into each phase sheet's Overview tab as a *focused* per-phase slice (§7.2), so the top-level view stays pure navigation. |
| **Budget** | the financial spine | The phased cash-flow (§2) + the simulation cockpit (§4). Renamed from "cash calculator" (§7.3). Presented as **three tabs** (cockpit + verdict / table / breakdown); each cash-event row is clickable and drills to its `source_component` (§7.3). |
| Q&A | qa | The shell's chat surface over the engine's bilingual Q&A stream (no component fills it). |

Everything previously scattered across `before-you-buy`/`buying`/`after-you-buy` is **not** a top-level tab. It is reached *through a spine*: a legal step's detail through its phase sheet (§7.2), a figure's detail through its budget row (§7.3). This is the correction — the surface mirrors the user's lifecycle, not the engine's component list.

### 7.2 The phase sheet (drill-down off the Flow view)

Clicking a phase (or any item cell within it) opens a **popup modal sheet** (the shell's reusable `Modal` — a scrim backdrop + a bottom-sheet on phone / centred card on desktop; close via ✕, the scrim, or Escape) carrying **three tabs** (a shared `Tabs` rail — the same control the Budget view uses, §7.3), in this order (lead with the picture, then the actions, then the warnings):

1. **Overview / who deals with whom** — the swimlane slice for that phase (existing `journey_swimlane` data; computes nothing new), *including* the focused per-phase `interactions` ("ai làm việc với ai") that §7.1 removed from the top-level swimlane. This is the focused tab the all-phases list collapses into.
2. **Action checklist, in temporal order** — the ordered "do these, in this sequence" for the phase. Each item may carry:
   - `budget_ref` → a `cash_event.id` (§2). This is the concrete checklist↔budget coupling the user asked for: the Budget view already groups `cash_events` by the same `phase`, so an item and its money consequence pair automatically. `null` when an action has no cash consequence.
   - `component_ref` → a component id. Tapping an item with rich backing (e.g. "Apply for FHG" → `eligibility`'s scheme stack; "Get pre-approval" → `mortgage_finance`'s shortlist) opens that component's own renderer as the item's detail — **in a second modal layered over the phase modal** (layered representation; not inline). So the components removed from the top level in §7.1 do not vanish — they become the **explanation behind a checklist item**. This is symmetric with the budget-row drill-down (§7.3).
   - `status` — a user-attested toggle (`not_started | done`). The engine seeds it; the user sets it. It is stored in the card's **user-set layer**, not in the computed snapshot — see §7.4a (the same survives-recompute foundation the plan-target overlay uses, §4.3).
3. **Risks + mitigation** — a `risk-flag-list` for the phase: `{ severity, item, action }` per risk, where `item` is the often-seen risk and `action` is the mitigation. **Layered:** each row *summarises* the risk (severity badge + the risk itself) and is clickable; the mitigation/solution opens in a popup modal layered over the phase modal (same `Modal` as the action and budget drill-downs). Honest-partial extends to the *tab itself*: the Risks tab is present only when the KB substantiates at least one risk for the phase — a phase with no grounded risk shows **no Risks tab** (two tabs, not an empty third), never a fabricated one (§7.5).

### 7.3 The Budget view and buyer_profile as input

- **Rename.** "Cash calculator" becomes **"budget calculator"** throughout. It aligns with the engine's own outcome type (`budget_envelope`) — "cash calculator" was the outlier. The inline "cash calculator" references in §1/§5, the blueprint `ui_tabs`, and `04-ux-model.md` are renamed in the conformance pass (§7.7); this anchor uses the new name from here on.
- **buyer_profile is the input surface, not a view.** `buyer_profile`'s facts (target price, state, income, deposit) are the budget calculator's dynamic input fields — the same fields the structural what-if varies (§4.1). There is no standalone "who you are" tab; the buyer's facts live where they are *used*.
- **Three tabs (a shared `Tabs` rail, the same control the phase sheet uses, §7.2):**
  1. **Bạn đã đủ chưa? (inputs + verdict)** — the simulation cockpit's input fields (target price, state, cash-on-hand; property type locked at base) **and** the "Am I ready?" verdict hero they drive. The cockpit lives *on this tab*: editing a scenario means this tab. A scenario preview still re-renders every tab and the other two tabs signpost an active preview (with a reset), since the cockpit is tabbed away.
  2. **Dòng tiền theo giai đoạn (table)** — the phased cash-flow table; each cash-event row drills to its owner (below).
  3. **Chi tiết ngân sách (breakdown)** — the line breakdown (duty before/after, deposit, other costs, buffer) and the budget summary (max price, genuine-savings verdict, mitigation, assumptions), **inline on its own tab** (no longer a modal). The page stays scannable; detail is one tab away.
- **Each cash-event row drills to its owner — layered.** Every `cash_event` carries `source_component` (§2). A row whose owner is an **external** component (e.g. `grant_1` → `eligibility`) opens that component's renderer in a popup modal (the same `Modal` as §7.2) — the budget-side mirror of §7.2's checklist drill-down. A row owned by `cash_position` **itself** (deposit/duty/other) has no external explainer — drilling to `cash_position` would recurse into the whole calculator — so it **switches to the Breakdown tab** (where its line detail + notes live) instead. (In the standalone `full` render used by `ComponentCard`/the dossier — which has no tabs — the same self-owned row opens a Budget-breakdown *modal*.)

### 7.4 The `phase_playbook` component (the checklist + risks owner)

The per-phase checklist and risks are **net-new producer data** — neither exists today (the swimlane `cells` are per-`(phase, actor)` narrative prose; `preparation` is a *global* document checklist; `risk-flag-list` is wired only to per-property `due_diligence`). A new **base-scope component, `phase_playbook`**, owns them. It is kept **separate from `purchase_journey`**, not folded in, for three reasons:

- **Single goal.** `purchase_journey` is a pure *projection* — it places already-computed figures and computes nothing of its own (§2, one-computer-per-figure). `phase_playbook` *authors* KB-sourced content. Mixing the two would overload the projection.
- **Progressive fill.** Separate components fill independently, so the Flow spine renders progressively: the cheap swimlane projection appears immediately, then the checklist, then risks — each with its own honest-partial pending state — instead of the phase blocking on one all-or-nothing fill.
- **Clean gating.** [`outcome-conformance.md`](outcome-conformance.md) gates a projection (every figure traces to an owner) differently from authored content (every risk/action traces to a KB anchor).

The user still sees **two spines** — the split is producer-internal.

**Outcome shape (`phase_playbook`)** — fixed here as the conceptual SOT; the renderer composition (`checklist` + `risk-flag-list`, both already in the vocabulary) and the `budget_ref`/`component_ref` affordances on the `checklist` renderer are an `architecture.md` §11.9 conformance item (§7.7):

```jsonc
{
  "type": "phase_playbook",
  "phases": [
    {
      "phase": "prepare",                          // matches journey_swimlane.phases + cash_event.phase
      "actions": [
        {
          "id": "apply_fhg",
          "label":  { "vi": "...", "en": "..." },   // localized_text
          "detail": { "vi": "...", "en": "..." },   // why / how, bilingual
          "order": 1,                               // temporal order within the phase
          "budget_ref": "fhg_benefit",              // → a cash_event.id; null when no cash consequence
          "component_ref": "eligibility",           // → open this component's renderer as backing detail; null when none
          "status": "not_started"                   // user-attested: not_started | done (engine-seeded, user-set)
        }
      ],
      "risks": [
        {
          "severity": "medium",                     // risk-flag-list: low | medium | high
          "item":   { "vi": "...", "en": "..." },   // the often-seen risk
          "action": { "vi": "...", "en": "..." }    // the mitigation
        }
      ]
    }
  ],
  "key_assumptions": [ /* localized_text[] */ ]
}
```

**Fill path: resolver.** Both lists are bilingual KB content placed against the phase, with `budget_ref` linking to upstream `cash_events` — no agent leaf, no figure recomputed. The KB anchors are new: a per-phase action template and a per-phase risk template (`kb.journey.*` extended, or new `kb.risks.*`), authored and verified against the existing scattered risk KB (`kb.s32.review-points`, `kb.cooling-off.by-state`, `kb.special-conditions.standard-set`, `kb.auction.rules-by-state`, `kb.agent-tactics.detection`, etc.).

### 7.4a User-attested state: the card's user-set layer

A checklist whose items cannot be ticked is not actionable — so the `status` toggle is part of this foundation, built now, not deferred. It forces a persistence decision that must be made concretely, because getting it wrong silently corrupts the plan:

**Where user-set per-card state lives — forced, not chosen.** `status` is a *user-attested* fact (the user, not the engine, decides an action is done). It therefore cannot live where the engine recomputes:

- **Not in `content_jsonb`** (the computed snapshot): the resolver re-seeds `status: not_started` on every recompute — refresh, simulate-save — and would **silently clobber** the user's ticks. This is exactly the §4.3 clobber problem.
- **Not in `profiles.facts_jsonb`**: status is per-*journey* progress; storing it on the profile leaks it across the profile's other cards (the same leak §4.3 names for `target_*`).

So it joins the **card user-set layer** that §4.3 already established for the plan-target overlay — one card-level store of user-set, survives-recompute state, now with a **second member**: a status map keyed by stable item id (`{ component_id: { item_id: status } }`). The resolver seeds defaults into the *computed* outcome; the read path **overlays** the user-set layer onto the seed (empty layer ⇒ reads as the seed, backward-compatible). The write is a small per-card patch (event-logged for the audit trail, no recompute, no metering). One mechanism serves `phase_playbook` **and** `preparation` — it closes preparation's pre-existing same gap. The engine seam is [`engine-contract.md`](engine-contract.md) §10.4.

This is the concrete foundation under "actionable": the user's progress is first-class persisted state, on the same footing as a saved scenario, not a render-only flourish that a recompute erases.

### 7.5 Grounding and the ASIC boundary

Two constraints keep this honest:

- **Risks and actions are KB-grounded, never LLM-generated.** A plausible-sounding generated risk list is worse than none — it has no audit trail and invites over-claiming. `phase_playbook` is resolver-filled from KB; the agent does not author the lists. (The reliability comes from removing the content from the LLM's reach, not from a second LLM judging it.)
- **Decision-support, not advice.** Per-phase risks are surfaced informationally ("here is what often goes wrong and how buyers manage it"), never as a recommendation — the ASIC line holds. "It's all about risk management" is true *with this boundary*: we surface the risks the KB substantiates, bilingually, with a stated mitigation, and stop short of advising.

### 7.6 What §7 does not change

The model of §1–§6 is untouched: the **two spines**, the shared **`cash_events`** primitive, the **simulation/save** paths and one-saved-scenario rule, **one-computer-per-figure**, and **base-scope-before-property**. §7 reshapes only the *surface* over that model and adds one authored-content component beside the projection. No new spine, no new renderer, no new persistence store.

### 7.7 Sequencing and downstream conformance

The reshape splits by *what each part needs*:

- **Slice 1 — surface only** (ships on today's engine data): the three views + Q&A (§7.1), phase sheets reading existing swimlane data (§7.2 section 1), budget rows → `source_component` (§7.3), and the **budget-calculator rename** (§7.3). One `ui_tabs` re-key; no new producer data.
- **Slice 2 — per-phase action checklist** (§7.2 section 2): new `phase_playbook` actions + the `budget_ref`/`component_ref` affordances, **and the user-set layer + toggle-write** (§7.4a) so the checklist is genuinely actionable, not read-only. New KB + schema + the persistence foundation → docs-first.
- **Slice 3 — per-phase risks** (§7.2 section 3): base-scope `risk-flag-list` + new per-phase risk KB. The heaviest (net-new bilingual risk curation) → docs-first.

Conforming docs for §7 (each updated in its own pass, after this anchor is agreed):

- **`engine-contract.md`** — `phase_playbook` as a base-scope component + its `component_filled` event; the `status` toggle write.
- **`architecture.md` §11.9** — `phase_playbook` outcome type; the `checklist` renderer's `budget_ref`/`component_ref` affordances; `risk-flag-list` at base scope.
- **`../blueprints/fhb-domestic-au.md`** — the `ui_tabs` re-key (three views + Q&A; phase sheets); the `phase_playbook` component (goal, inputs, KB anchors, resolver fill); the rename.
- **`04-ux-model.md`** — the three-view navigation, the phase sheet (viz → checklist → risks), the budget/checklist drill-downs, pending-as-progressive.
- **New KB** — per-phase action + risk templates (Slices 2–3), verified against the existing transactional risk KB.

---

## 8. The full temporal flow: hold and dispose

§1–§7 model the lifecycle as **Prepare → Pre-approve → Contract → Settle → Own**. That arc **ends at ownership entry**. It has no multi-year *hold* and no terminal *dispose* — so a policy that acts on the holding years (negative gearing — a recurring annual tax effect on a rented investment) or on the sale (capital gains tax — a one-off at disposal) has **nowhere to land**. The investor blueprint already gestures at this with a `cgt_projection` field, but it is a placeholder: a figure with no phase, no cash event, and no owner. §8 extends the lifecycle to the full **buy → hold → sell** arc, so those figures have a home and the plan can answer *"over my whole hold-and-sell, where do I stand?"*

This is a **bounded extension, not a new model.** Every property §1–§7 fixed carries forward: two spines, one `cash_events` primitive, simulation as a resolver-only recompute, one-computer-per-figure, base-scope-before-property, the ASIC boundary. §8 adds two phases' worth of timeline and one figure-owner — and nothing else.

### 8.1 What is net-new (and what is not)

**The shared primitive is already temporal.** A `cash_event` (§2) carries `timing: one_off | recurring` and `period: month | quarter | year`. So a recurring holding flow (rent, management, the gearing tax effect) and a one-off disposal flow (sale proceeds, CGT) **fit the existing schema with no change**. What is missing is *where on the timeline they sit* and *who computes them*:

1. **The phase enum gains a terminal `dispose`** → `prepare | pre_approve | contract | settle | own | dispose`. `own` becomes **horizon-aware** (it is the hold span; see §8.2).
2. **A hold horizon `H`** (years) — the lifecycle is phase-*ordinal* today; negative gearing accrues per-year and CGT depends on hold-length, neither expressible without a horizon (§8.3).
3. **A growth assumption** — disposal proceeds depend on projected capital growth over `H`; a banded, honest-partial, ASIC-safe projection input (§8.4).
4. **A `disposition` figure-owner** — the component that computes the dispose-phase figures the placeholder lacks (§8.5).

### 8.2 Why `dispose` is a phase but "hold" is not — phase ⊥ timing

The candidate alternative was to add **two** phases (`hold` for the steady-state years, `dispose` for the sale). It is rejected on a structural ground, recorded here because it is load-bearing for every downstream conformance.

In this model **phase and timing are orthogonal axes.** `phase` is *where on the timeline* a movement sits — the bucket both spines project onto. `timing` (`one_off | recurring`) is *whether it repeats*. The multi-year hold is therefore **already expressible** as `recurring`/`period: year` events inside one post-settlement phase. "Establish (year-0 one-offs)" vs "steady-state (annual recurring)" — the distinction a separate `hold` phase would encode — **is a `timing` distinction, not a phase distinction**: a move-in cost is a `one_off` event in `own`; council rates are a `recurring` event in `own`. Promoting it to a phase re-encodes an axis the model already has.

Two concrete failures follow from a split `own`+`hold`:

- **It breaks one-computer-per-figure (§2).** A recurring `ownership_planning`-owned cost (e.g. council rates) recurs in year-0 **and** years 1..H. A `cash_event` carries exactly **one** `phase`. So the single recurring event must either *duplicate* into both phases (two events for one real cost) or arbitrarily *pick one* (incoherent — it demonstrably recurs in both). `own` as a single horizon-spanning phase has one clean owner; the horizon is a **parameter on the projection**, not a second bucket.
- **It puts a content-empty column on the legal spine.** A phase boundary on the swimlane marks a *legal handoff* (contract exchange, settlement, title transfer). `own → dispose` transfers title **out** — new actors (the purchaser, your agent, your conveyancer, the ATO), real one-off events, a real column: it **earns a phase**. `own → hold` is no handoff (same title, same legal status) — a `hold` column would be empty on the legal axis, the inverse of §7.2's honest-partial "no Risks tab when nothing substantiates it".

So `dispose` is a genuine phase; **`hold` is `own` parameterized by horizon `H`.** The establish-vs-steady-state view a `hold` phase seemed to buy is still available under one `own` phase — by projecting `own` on the `timing` axis (one-offs vs recurring) that is already on every event. The single phase loses nothing.

### 8.3 The hold horizon `H`

`H` (years held) is a new **card-level parameter** — mutable per journey, exactly like `target_*` (the plan-target overlay, §4.3), not a profile fact. It is what makes the hold **projectable** and the disposal **placeable**:

- **Default by mode.** An investor's `H` derives from `exit_strategy` (the investor blueprint already captures it); an owner-occupier defaults to a long/indefinite hold with an optional *"what if I sell in N years?"*.
- **It is a structural what-if dimension.** Varying `H` (and the growth assumption) re-derives the financial spine through the **same resolver recompute** §4.1 already specifies — deterministic, verified-to-the-dollar, and **free** (a resolver-only turn emits no `usage`). *"Hold 5 vs 10 years"* rides the identical path as *"VIC vs QLD"*. The simulator extends for free.
- **It persists where `target_*` persists.** A saved horizon is one more override on the card's `target_jsonb` overlay (§4.3) — no new persistence store; the existing refine-commit / refresh-sweep machinery applies unchanged.

### 8.4 The growth assumption — banded, honest-partial, ASIC-safe

Disposal proceeds depend on projected capital growth over `H`. This is the one genuinely *uncertain* input the model introduces, and it is handled by the disciplines already in force:

- **Banded, never a point.** Growth resolves to a `money_range` (honest-partial §3); an unparameterized projection renders **PENDING**, never a fabricated point figure.
- **KB-grounded and resolver-computed.** Conservative growth bands live in a KB doc (a new `kb.tax`/`kb.property` anchor); proceeds and CGT are computed by the **resolver**, removed from the LLM's reach (the §98 / verify-by-postcondition discipline). The agent never authors a growth or CGT figure.
- **Decision-support, not a forecast.** Growth and any disposal figure are surfaced informationally with their assumption stated in `key_assumptions` — *"on a conservative N% p.a. assumption"* — never as a prediction or advice. The ASIC line holds exactly as it does for the acquisition figures.

### 8.5 The `disposition` component — the new figure-owner

A new component owns the dispose-phase figures (the placeholder's missing computer). Outcome shape (conceptual SOT; the renderer composition and the `architecture.md` §11.9 type are a conformance item, §8.8):

```jsonc
{
  "type": "disposition",
  "horizon_years": 10,                          // the hold H this projection assumes
  "sale_proceeds":  [v_lo, v_hi],               // money_range — growth-projected over H; PENDING when unparameterized
  "selling_costs":  [v_lo, v_hi],               // agent commission + legal/marketing (money_out at dispose)
  "loan_payout":    [v_lo, v_hi],               // remaining principal discharged at settlement of sale
  "cgt":            null,                        // money_range | null — tax on the gain; null/exempt on the main-residence path
  "net_proceeds":   [v_lo, v_hi],               // sale_proceeds − selling_costs − loan_payout − cgt
  "key_assumptions": [ /* localized_text[] */ ] // the growth rate, the held-period, the exemption basis
}
```

- **One-computer-per-figure.** `disposition` owns these; the spines **place** them (§2). It emits the dispose-phase `cash_events` — `sale_proceeds` (in), `selling_costs`/`loan_payout`/`cgt` (out) — each `source_component: disposition`, gated by the placement/provenance check (§13). It does **not** recompute upstream figures.
- **Mode-A path (Wedge-1a, built now): the main-residence exemption.** For an owner-occupier the principal-residence is CGT-**exempt**, so `cgt` is typically `null` and the value of the dispose phase is **equity at sale → the next purchase** — the *graduation/upgrade* story `ownership_planning` already gestures at. Light, regulated, in scope.
- **Mode-C path (design-first, when Mode C ships): full CGT.** The 50%-discount-if-held-over-12-months calculation, depreciation interplay, and the negative-gearing recurring hold-phase events (owned by `yield_modelling`/`tax_structure`) are the same structure, populated when the dangling `kb.tax.*`/`kb.investor.*` anchors are authored (§8.7).

### 8.6 The financial spine extends to a full-horizon net position

Today the financial spine answers *"cumulative cash to **acquire**"* (verdict: can you get in). With the hold and dispose events on the list, it extends — using the *same* grouping-by-phase projection — to a **full-horizon net position**:

```
   acquire (out)        →   hold over H (recurring in/out)   →   dispose (net)
   deposit · duty · costs    rent · costs · gearing effect        proceeds − costs − payout − CGT
```

It now answers the richer question the truncated model could not: *over buy → hold → sell, what is my total position?* — the investor's core question, and the owner-occupier's *"is this a good first step, and when can I step up?"*. It is still **one `cash_events` list, projected twice** (§1); the hold and dispose flows are simply more entries carrying their `phase`/`timing`.

### 8.7 Scope — full model now, Mode-A content now, investor tax design-first

The split follows the foundation-first / honest-deferral discipline and the kb-update-runbook's Phase-0 scope gate:

- **Structure / mechanism for all modes — build now:** the phase enum, the horizon + growth machinery, the `disposition` outcome shape, the full-horizon spine.
- **Mode-A (Wedge-1a) content — author now:** the FHB hold → dispose path (main-residence exemption, graduation-linked), and the KB it anchors.
- **Mode-C investor tax — design-first, trigger-gated:** negative gearing, the CGT discount, depreciation. Defined here as the same structure; the `kb/tax/*` + `kb/investor/*` docs (currently *dangling anchors* in `investor-domestic-au.md`) are authored when Mode C enters scope. This reframe is the **worked "kind-3" instance** the [kb-update-runbook](kb-update-runbook.md) Phase-0 classifier anticipates — a policy change that acts on a lifecycle *phase the model must first grow*, entered at this anchor, not at the blueprint.

### 8.8 What §8 does not change

The model of §1–§7 is untouched: the **two spines**, the shared **`cash_events`** primitive, the **simulation/save** paths (the horizon and growth are new *what-if dimensions* on the existing resolver recompute), **one-computer-per-figure** (`disposition` owns; the spines place), and **base-scope-before-property** (the spine carries banded hold/dispose events before any property; they narrow to points when one attaches). It introduces **no new spine, no new persistence store** (the horizon rides the §4.3 overlay), **no client-side figure computer** (growth/CGT are resolver-computed), and — the conformance expectation for §8.9 — **no new renderer**: the phased cash-flow extension is the `calculator` extended and the dispose column the `swimlane-diagram` extended (constraint #7; confirmed in the `architecture.md` §11.9 pass).

### 8.9 Sequencing and downstream conformance

This anchor fixes the model. The contracts and artifacts that conform are updated one at a time, each in its own pass (the tracked wave is grounding-checklist item 10):

- **`engine-contract.md`** — the `disposition` component + its `component_filled` event; `horizon`/`growth` as resolver-override inputs to the §10 simulate/refine primitive; resolver-only metering; the dispose-phase `cash_events`.
- **`architecture.md` §11.9** — the `disposition` outcome type; the phase-enum addition; the renderer check (`calculator`/`swimlane-diagram` extended, no new renderer).
- **`../blueprints/fhb-domestic-au.md`** — the hold-horizon input + the `disposition` component (Mode-A main-residence path); it must compile, so author the Mode-A KB it anchors.
- **`../blueprints/investor-domestic-au.md` (+ foreign)** — wire `yield_modelling`/`tax_structure` into the horizon/dispose model; resolve the dangling tax anchors (design-first).
- **New KB** — `kb.tax.cgt-main-residence-exemption` + growth-band + selling-costs (Mode-A, ATO-primary-verified); investor tax docs design-first.
- **`04-ux-model.md`** — the timeline UI: the Flow view gains a Dispose column + horizon-aware Own; the Budget view gains the full-horizon net-position view + a horizon slider (structural what-if); phase sheets for the new phase.
- **`structure-map.md` + `README.md`** — register the extended model; fold the [kb-update-runbook](kb-update-runbook.md) Phase-0 change-kind classifier in.
