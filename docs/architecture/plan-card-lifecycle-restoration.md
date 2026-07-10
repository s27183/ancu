# Plan-card lifecycle restoration (A + B1 + B2), mode-general

**Status:** planned, 2026-06-17 (rev 2 — extended to all four modes per Son); **rev 3,
2026-07-10 — B/C/D restructure target redefined, see §11.** Sibling to
[`plan-card-visual-spec.md`](./plan-card-visual-spec.md) (per-component *heroes*). This doc
governs the *spine* — re-assembling filled components into the buyer's **lifecycle journey**,
the structure the prototype [`../first_home_buyer_plan.html`](../first_home_buyer_plan.html) led
with and the current plan card lost — and does so **mode-generally** so investors (Modes C/D)
and foreign buyers (B/D) are content additions, not shell rewrites.

---

## 1. The problem (diagnosis)

The prototype's tabs are **lifecycle phases** (a narrative arc through time); the rendered card's
tabs are **engine component names** (`PlanProjection.svelte:115` iterates `BASE_COMPONENT_ORDER`
and prints each component id as a tab).

**Root cause.** The shell surfaces the engine's *internal decomposition* as the user-facing
navigation instead of the buyer's *journey*. Not a missing design — each blueprint already
carries a **"UI tab mapping"** table; the shell skipped it.

**Why the heroes didn't fix it.** Heroes are *per-component* — they polished each *cell*. The
lifecycle is the *spine* (the tabs + their order) plus an Overview synthesis. The single most
"lifecycle" element — the **Temporal-flow swimlane** — maps to a `per-property` component, so it
never fills at base and the tab is absent.

Three workstreams, greenlit together: **A** (lifecycle framing), **B1** (base journey swimlane),
**B2** (interactive cash calculator). Extended (Son, 2026-06-17) with a **mode-general design
pass** so the framing is validated against all four blueprints, not just Mode A.

---

## 2. Cross-cutting invariants

- **R1 — deterministic outcome→geometry.** Bars, lanes, swimlane cells are pure functions of the
  engine outcome. Nothing agent-drawn.
- **R2 — honest-partial.** A null line ghosts/omits; the base plan is property-agnostic and
  onboarding-thin — say what's not yet known.
- **R3 — vocabulary is a palette.** `swimlane-diagram`, `family-view-card`, `firb-workflow-card`,
  `buying-strategy-card`, `opportunity-card` are all already in the constraint-#7 enum. **No
  vocabulary change** is needed for any mode; several are simply unbuilt renderers (deferred).
- **R4 — bilingual at source.** VI co-equal; copy in KB templates, engine emits `{vi,en}`.
- **One-computer-per-figure.** Regulated figures computed once, in the engine, verified to the
  dollar. **No figure recomputed shell-side** (the load-bearing constraint on B2, §7).

---

## 3. Mode-general design pass (the finding)

Reading the four drafted blueprints' UI-tab-mapping tables side by side:

| Blueprint | Base components (fill at onboarding) |
|---|---|
| **A** fhb-domestic | buyer_profile · eligibility · mortgage_finance · cash_position · ownership_planning |
| **B** fhb-foreign | buyer_profile · family_context · firb_workflow · mortgage_finance · cash_position · cross_border_funding · ownership_planning |
| **C** investor-domestic | investor_profile · investment_strategy · mortgage_finance · yield_modelling · tax_structure · cash_position · ownership_planning_investor |
| **D** investor-foreign | investor_profile_foreign · firb_workflow · investment_strategy · mortgage_finance · yield_modelling · tax_structure_non_resident · cash_position · cross_border_funding · ownership_planning_foreign_investor |

(per-property in every mode: property_assessment · buying_strategy · due_diligence · settlement_prep)

### 3.1 The decisive result

**The four modes do not share a fixed tab set.** They share a **tab vocabulary**; each blueprint
declares an **ordered subset**. This is the second-instance test the "general" abstraction had to
pass — and it *fails the hardcoded-tabs design*. Therefore: **the lifecycle tab list is
blueprint-declared (compiled to the artifact); the shell renders whatever the in-scope blueprint
declares.** (Workstream A, now validated rather than asserted.)

### 3.2 The lifecycle tab vocabulary (union of all four), in canonical journey order

**Superseded by §11 (rev 3).** This table was the first design pass's result — a 12-tab
vocabulary, each mode declaring an ordered subset. What actually shipped for A, then E, was a
*second*, tighter collapse (`lifecycle-simulation-model.md` §7) down to four views
(Overview/Flow/Budget/Q&A), never propagated back to this table or to B/C/D. Kept below as the
historical record of the first pass; §11 is the current target.

| # | Lifecycle tab | A | B | C | D | Base content (component → tab) |
|---|---|:-:|:-:|:-:|:-:|---|
| 1 | **Overview** | ✓ | ✓ | ✓ | ✓ | synthesis over the mode's base outcomes (no engine change) |
| 2 | **Family view** | – | ✓ | opt | opt | `family_context` (`family-view-card`) |
| 3 | **Investment strategy** | – | – | ✓ | ✓ | `investment_strategy` |
| 4 | **FIRB & Funding** | – | ✓ | – | ✓ | `firb_workflow` + `cross_border_funding` |
| 5 | **Before you buy** | ✓ | – | – | – | `eligibility` + `cash_position` detail + `due_diligence`(pp) |
| 6 | **Yield & Tax** | – | – | ✓ | ✓ | `yield_modelling` + `tax_structure(_non_resident)` |
| 7 | **Cash calculator** | ✓ | ✓ | ✓ | ✓ | `cash_position` (interactive — B2) |
| 8 | **Journey** (Temporal flow) | ✓ | ✓ | ✓ | ✓ | **`purchase_journey` (base, NEW — B1)** + `settlement_prep` (pp refine) |
| 9 | **Property** | – | ✓ | ✓ | ✓ | `property_assessment` + `due_diligence` (pp) |
| 10 | **Buying** | ✓ | ✓ | ✓ | ✓ | `buying_strategy` (pp) |
| 11 | **After you buy** | ✓ | ✓ | – | – | `ownership_planning` |
| 12 | **Portfolio** | – | – | ✓ | ✓ | `ownership_planning_investor` / `_foreign` |

The vocabulary lands squarely on the two axes: **FHB↔investor** (5 `Before you buy` + 11 `After
you buy` ⟷ 3 `Investment strategy` + 6 `Yield & Tax` + 12 `Portfolio`), **domestic↔foreign**
(4 `FIRB & Funding`, 2 `Family view`). Tabs 1/7/8/10 are universal. Per-property tabs (9, 10, and
the `settlement_prep` half of 8) are present in their modes but show an honest "attach a property"
affordance at base.

### 3.3 The journey component generalizes (one shape, per-mode content)

The Temporal-flow swimlane has the **same shape** in every mode — phases × actors × cells, each
cell carrying items + money/doc/recurring markers — but **mode-specific content**:

- **A** (FHB-domestic): Prepare → Pre-approve → Contract → Settle → Own; actors You/Gov/Lender/Other.
- **B** (FHB-foreign): + a **FIRB-approval gating phase** + a currency-transfer milestone + surcharge.
- **C** (investor-domestic): + **entity-setup** (trust/company); tenant + property-manager actors;
  depreciation/negative-gearing instead of FHG; no owner-occupier move-in.
- **D** (investor-foreign): FIRB gate + transfer + entity + non-resident tax + repatriation (most actors).

So: **`purchase_journey` is one component with one `journey_swimlane` outcome_schema** (phases[],
actors[], cells[]); the **journey KB doc is per-mode** (`kb.journey.fhg-path` for A; `kb.journey.*`
for the others); the **`SwimlaneDiagram` renderer is mode-agnostic** (renders any phases×actors×
cells). Confirmed general — build Mode A's journey now, the rest are KB+resolver-config additions.

---

## 4. Mode scope — structure all four now, build Mode-A content first

**Historical note (superseded by facts on the ground):** this section's premise — "only Mode A is
`in_scope_blueprint()`, B/C/D are dormant" — was true 2026-06-17 but is **no longer true**. The
Mode C/B/D wedges (`mode-c-wedge.md`, `mode-b-wedge.md`, `mode-d-wedge.md`) each went to
build-complete and activated their blueprint in scope; nobody revisited this doc's deferred
content when that happened, which is *why* B/C/D still carry the stale, never-collapsed §3.2 tab
shape today. §11 picks this back up as a live restructure, not a still-dormant one.

The split that resolves "design all modes vs. build the wedge":

- **Structure (this design pass + the `ui_tabs` declarations) — all four, now.** Each blueprint
  gets a machine-readable `ui_tabs` block (ordered tab list + component→tab + renderer-per-tab),
  the compiler validates + emits it, the shell renders the declared subset. Cheap (doc-layer on
  blueprints that already exist) and it's what makes the abstraction real.
- **Content — Mode A first.** Only `fhb-domestic-au` is the engine's `in_scope_blueprint()`, so at
  runtime the shell only ever receives Mode-A cards in Wedge 1a; B/C/D `ui_tabs` are
  **design-complete but dormant** (compiler-validated, not rendered) until those blueprints come in
  scope. Deferring B/C/D content is not wedge dogma — it's verification cost + regulated liability
  (FIRB foreign-person rules, surcharge, vacancy fee, non-resident/VN tax, Mode-D Decree-13 data
  residency), and the wedge says prove A before paying it.

Net: the **regression fix and the mode-general framing land together for Mode A**; investors/foreign
become content-only follow-ons with zero shell/engine structural rework.

---

## 5. Workstream A — blueprint-driven lifecycle framing

**Scope:** all four blueprints (`ui_tabs` declarations) + the compiler/artifact + the shell. (Engine
runtime unchanged beyond passing the blueprint's `ui_tabs` through; it already serves `blueprint_slug`.)

1. **`ui_tabs` schema + declarations (all four blueprints).** Define a `ui_tabs` block: ordered
   `[{ tab_id, label_key, components: [...], render_as }]`. Populate it in all four blueprints from
   §3.2 (canonicalising each drafted prose table; folding in the new `purchase_journey` on the
   Journey tab). This is "the four mappings as data."
2. **Compiler + validate_build.** `kb_compiler` emits `ui_tabs` into the artifact; `validate_build`
   asserts every referenced component exists in that blueprint, every `render_as` is in the enum,
   and the tab order is well-formed. (Open: confirm the compiler validates all four blueprints, not
   only the in-scope one — §10.)
3. **Shell reads declared tabs.** `LIFECYCLE_TABS` in `planCard.ts` becomes a *type*, not a constant;
   the projection reads the in-scope blueprint's `ui_tabs` (from the card / a small engine field).
   `PlanProjection.svelte` renders the declared tabs in order, each body rendering its mapped
   `ComponentCard`(s) or an "attach a property" affordance for unfilled per-property tabs.
   `BASE_COMPONENT_ORDER` stays as the engine fill/merge order (data order ≠ nav order).
4. **`OverviewCard.svelte`** — shell synthesis (not a vocabulary entry, R3): reads the already-filled
   base outcomes and composes the "plan in 90 seconds" headline + recommended path + reach + cash-need
   line. Honest-partial: unfilled inputs ghost. (Mode A content; the tab itself is universal.)
5. **i18n + validate.** Bilingual labels for the full tab vocabulary (`plan.ltab.*`) + overview copy.
   svelte-autofixer → svelte-check 0/0 → vite build. Dev-stack eyeball (the one check the harness
   can't self-run — report honestly).

---

## 6. Workstream B2 — interactive cash calculator (shell-only)

**Scope:** `Calculator.svelte`. No engine change. Universal across modes (the Cash-calculator tab is
in every mode's vocabulary).

**The load-bearing constraint.** The prototype recomputes duty in JS as you change price — porting
that creates a **second computer** for a regulated figure (the registry-verified duty would gain an
unverified JS twin). So B2 is **cash-only**:

- The engine already computed `total_cash_required` as a `money_range`. The client adds a
  **cash-on-hand input** and computes `gap = cash − total` (subtraction only) + a **range-aware
  verdict** (covers low end / short of high / short of both). No duty recompute.
- The what-if is **ephemeral** (decision-support). The engine keeps `verdict = null`; honest-partial
  base output untouched. Persisting a verdict = the **refine turn** (savings captured → engine stores).
- **Changing price** is therefore out of scope — it changes `target_price_range`, a refine/re-onboard
  action that re-runs the engine (single-sourced duty). Surface "to test a different price, refine
  your plan," not a client-side price slider.

**ASIC framing.** Arithmetic against a stated need range + the prototype's informational disclaimer.
**Verify:** autofixer → svelte-check 0/0 → build; cash below/within/above the band → three verdicts.

---

## 7. Workstream B1 — base lifecycle swimlane (engine + KB + blueprint + renderer)

**Scope:** the heavyweight — blueprint, KB, engine (Erlang), artifact, new renderer. Mode-A content;
**the component + renderer are mode-general (§3.3)**.

**New base component `purchase_journey`, not `settlement_prep`.** The prototype's swimlane is the
*generic whole-journey overview* (property-agnostic, driven by `{mode, state, path}`).
`settlement_prep` is a *property-specific settlement checklist* (`per-property`) — left untouched; it
refines the Settle phase once a property is attached.

**Resolver, not agent.** The journey *structure* is generic KB content; only figures branch on
`{state, path}`. Resolver-filled (consistent with `reserve-the-agent-for-the-irreducible`).

**Pieces (Mode A):**
1. **Blueprint** (`fhb-domestic-au.md`): add base component `purchase_journey` reading
   `{profile, scheme_stack, mortgage_plan}`; define `journey_swimlane` outcome_schema (phases[],
   actors[], cells[{phase, actor, items[] as `localized_text`, flow_marker}], figures `money`/
   `money_range`). Update the `ui_tabs` Journey entry + renderer table.
2. **KB** `docs/kb/journey/fhg-path.md` (slug `kb.journey.fhg-path`): bilingual journey template — 5
   phases × 4 actors, cells, money-flow markers, `{state, path}` variant figures. Every figure
   verified against its primary (`verify-regulated-figures-by-postcondition`).
3. **Engine** `fh_engine_journey.erl`: `fill/2` selects the template by `{state, path}` and stamps
   state/path figures (reusing `fh_engine_cash` figures where regulated — never a second computer).
   Add `<<"purchase_journey">>` to `?BASE_COMPONENTS` (`fh_engine_turn.erl:42`) in DAG order (after
   `mortgage_finance`); wire `component_scope`/renderer.
4. **Artifact**: recompile via `kb_compiler` (slug resolves, renderer in enum, acyclic); `validate_build` green.
5. **Frontend** `SwimlaneDiagram.svelte` (R1 deterministic phases×actors grid, flow markers,
   recurring/⟳ styling — ports the prototype's visual language; compact vs full density);
   `JourneySwimlaneOutcome` type; `ComponentCard` dispatch on `renderer === 'swimlane-diagram'`;
   placed in the Journey tab.
6. **Conformance**: figure-gate covers journey figures; bilingual both-languages check; a journey
   resolver eval anchor.

**Verify:** engine green (`rebar3` + conformance), artifact recompiles, `validate_build` green,
svelte-check 0/0, Journey tab renders the swimlane from a real base turn.

---

## 8. Ordering & dependencies

A and B2 are shell-weighted and independent; B1 is the heavyweight and lands last (the Journey tab
shows an honest "coming" affordance until B1 fills it). The `ui_tabs` work in A precedes everything
because it defines the surface the rest renders into.

1. **A** — `ui_tabs` (all four) → compiler/artifact → shell renders declared tabs → Overview synthesis.
2. **B2** — interactive cash what-if (shell).
3. **B1** — base swimlane: blueprint → KB → engine → artifact → renderer → conformance.

One change at a time; each phase green by its own gate before the next.

---

## 9. Open decisions — RESOLVED at implementation

- **`purchase_journey` DAG placement** — **RESOLVED: reads `{scheme_stack, mortgage_plan,
  budget_envelope}` and runs AFTER `cash_position`.** The §9 proposal ("after `mortgage_finance`") was
  overturned by grounding: the journey's money flows (deposit, duty, total cash, scheme benefit) are
  *already computed upstream*, so the journey **places** them and computes none of its own
  (one-computer-per-figure, stronger than reuse). Placing requires `budget_envelope`, which exists only
  after `cash_position` — so it runs there, not earlier.
- **Compiler scope** — **RESOLVED: structural gates (slug, renderer-enum, acyclicity, ui_tabs
  ref-integrity / GATE 9) run over ALL four blueprints; semantic gates (reference-integrity, coverage,
  type-compat) run in-scope (Mode A) only.** So B/C/D `ui_tabs` are validated now, dormant until their
  modes activate.
- **Journey KB granularity** — **RESOLVED: one `kb.journey.fhg-path` copy doc** (phase/actor labels +
  per-cell prose + assumptions, bilingual). It carries NO `{state, path}` figure variants — the figures
  ride in the outcome's `amount` field from upstream, not the KB doc. Per-state prose nuance (cooling-off
  days, settlement weeks) is deferred (the journey points to Before-you-buy), not embedded.
- **Overview "best/safer path"** — **RESOLVED: Overview shows the single recommended path** (A4
  shipped). Multi-strategy compare is a later refine/per-property enhancement.

## 10. Non-goals

- No B/C/D **content** now (KB figures, resolvers, the unbuilt renderers `family-view-card`,
  `firb-workflow-card`, yield/tax cards) — structure only (§4).
- No price-varying client-side calculator (duplicates the regulated duty computer — §6).
- No new renderer vocabulary entries (all needed renderers already in the enum — §2 R3).
- No expansion of onboarding capture to force a stored cash verdict (honest-partial base is finished).
- No change to `settlement_prep` (it stays the per-property settlement detail — §7).

---

## 11. Rev 3 — B/C/D lifecycle-spine restructure (2026-07-10)

### 11.1 What triggered this

Son reviewed a live Mode D card (Melbourne VIC, investor-foreign-au) and found: Overview and Buy
both highlighted at once (a real shell bug, §11.6); the Journey tab showing almost nothing (§3.2's
`purchase_journey` was never built for B/C/D — still `settlement_prep` only, gated on a property
that doesn't exist yet); the cash calculator sitting under "Hold" and not responding to input
(a real engine shape bug, §11.6); and — the question this section answers — **why does B/C/D's
tab structure look nothing like A/E's four-view spine.** §4's "content-only follow-on" was never
picked up (§4 historical note above); this section replaces the stale §3.2 target with the one
actually proven on A/E.

### 11.2 The placement test

A/E's four-view spine (Overview/Flow/Budget/Q&A — `lifecycle-simulation-model.md` §7) works because
every A/E component is either **phase-shaped** (has a temporal position with a completion point
the purchase passes through — `eligibility`, `mortgage_finance`, `buying_strategy`, `due_diligence`,
`ownership_planning` all fold into a Flow phase's action checklist) or **money-shaped** (a cash
row — `cash_position`, `disposition` fold into Budget). Nothing in A/E is a persistent, no-completion-
point surface, so four views was enough.

B/C/D introduce concepts that must be tested the same way, not assumed to need their own tab:

- **Phase-shaped → Flow.** `firb_workflow` is a literal gate ("cannot sign a contract until FIRB
  approval is confirmed") between Pre-approve and Contract, with a knowable fee — this is exactly
  what §3.3 already called a **"FIRB-approval gating phase"** for Mode B and a **"FIRB gate"** for
  Mode D, before this doc's tab table (§3.2) contradicted its own journey design by giving FIRB a
  separate tab instead. `cross_border_funding` is §3.3's own **"currency-transfer milestone"** —
  funds must land by Contract (deposit) and Settle (balance). `investment_strategy` and entity
  setup (C/D) are pre-Contract one-time steps. All four → Flow phases/milestones, not tabs.
- **Money-shaped → Budget.** FIRB's fee, cross-border transfer cost/FX risk, `yield_modelling`'s
  cash-flow projection, `tax_structure(_non_resident)`'s after-tax figures — all become Budget rows,
  the same treatment `disposition` already gets in A/C/D.
- **State-shaped, no completion point → its own view.** `family_context` (Mode B's parent+child
  coordination dashboard) and `ownership_planning_investor`/`_foreign` (Portfolio — forward,
  recurring, multi-property) persist across the *whole* plan with no single completion point;
  folding either into a phase action would make it disappear exactly when it's needed. These are
  the only concepts that earn a dedicated tab beyond Overview/Flow/Budget/Q&A.

### 11.3 Target `ui_tabs` per mode

| Mode | Tabs | What moved off the old flat list |
|---|---|---|
| **A** | Overview / Flow / Budget / Q&A | unchanged |
| **E** | Overview / Flow / Budget / Q&A | unchanged |
| **B** | Overview / Flow / Budget / **Family** / Q&A | `firb_workflow` → Flow gating phase + Budget fee row; `cross_border_funding` → Flow milestone + Budget row; `property_assessment`/`buying_strategy`/`due_diligence` → Flow Contract/Settle drill-down (no more flat "Property"/"Buying" tabs) |
| **C** | Overview / Flow / Budget / **Portfolio** / Q&A | `investment_strategy` → Flow phase + Overview synthesis; `yield_modelling`/`tax_structure` → Budget rows; property components → Flow drill-down |
| **D** | Overview / Flow / Budget / **Portfolio** / Q&A (Family opt-in only, per the blueprint's existing note — investors are typically solo/couple) | same as B (FIRB/cross-border) + same as C (investment strategy/tax/entity), all folded; property components → Flow drill-down |

`purchase_journey` + `phase_playbook` become base-scope for B/C/D exactly as they are for A/E —
this is the piece that was designed in §3.3 and never built (KB doc + resolver branch + a
`?BASE_COMPONENTS_*` entry per mode), not a new design.

### 11.4 Mode B gains `disposition`

Mode B is the only mode with no dispose-phase figure owner at all. Adding it for parity: a foreign
FHB can still face a forced or voluntary sale (visa status change, relocation), and the FIRB
vacancy-fee obligation makes "what if I need to sell" a live question, not a hypothetical. Same
shape as A/C/D's `disposition` — base scope, resolver-filled, runs after `cash_position`.

### 11.5 Build sequencing

**C first, then D, then B.** C is domestic — no FIRB, no cross-border, no family view — the closest
remaining gap to A/E's already-proven shape, so it validates the restructure pattern (Flow
phases/milestones absorbing what used to be tabs, Portfolio as the one addition) with the least new
surface. D adds FIRB/cross-border/Family(opt-in) on top of a proven Portfolio pattern. B lands last
and gains `disposition` (§11.4) alongside its own FIRB/cross-border/Family work. Each mode is its
own gated pass (blueprint → KB → engine resolver → artifact recompile → shell → conformance),
matching how A's B1/B2 workstreams were verified independently before being called done.

### 11.6 Independent bug fixes — do now, not gated on the restructure

Two bugs found on the live Mode D card are unrelated to the tab restructure and should not wait
for it:

- **Mode D `total_cash_required` is a scalar, not a `[lo,hi]` money_range.** `fh_engine_cash.erl`'s
  `fill_investor_foreign` computes it via `sum_or_null` as a plain integer; `Calculator.svelte` and
  `OverviewCard.svelte` both gate on `hasRange()`, so the value is silently treated as absent — the
  cash-what-if input has nothing to write to, and Overview's "Cash to get in" shows "Not yet" for a
  figure the engine actually computed. Fix: emit `[v, v]` like every other mode's point figures.
- **`OverviewCard.svelte` reads `components.eligibility` and `mortgage.recommended_path`** for its
  benefit tile and recommended-path tile. Neither exists for Mode C/D (`eligibility` isn't a C/D
  component; `fill_investor_foreign`/`fill_investor_domestic` never set `recommended_path`, an
  FHB-only concept) — these tiles will read "Not yet" forever for C/D, not "pending." Fix: make the
  Overview synthesis mode-conditional on which fields actually exist for that blueprint, or supply a
  C/D-appropriate substitute (e.g. `investment_strategy`'s thesis headline in place of a scheme
  benefit).

The Overview/Buy double-highlight bug (`PlanProjection.svelte:118`, `TAB_GROUP[sub] ?? 'buy'`
defaulting Overview into the Buy group) is **not** fixed separately — it only exists because B/C/D
currently exceed `RAIL_GROUP_THRESHOLD` (5 tabs); §11.3's target drops every mode to ≤5 tabs, which
removes the grouped-rail mechanism's precondition entirely. It self-resolves as each mode's
restructure lands, mode by mode per §11.5 — not worth a standalone patch to a UI path being deleted.

### 11.7 Non-goals (rev 3)

- No new renderer vocabulary — `family-view-card`, `firb-workflow-card` etc. are already in the R3
  enum (§2); this is placement, not new rendering primitives.
- No change to A/E — they're already at the §11.3 target.
- No fabricated journey/phase content — `purchase_journey` for B/C/D is a copy doc (`fills:[]`,
  place-not-compute per §7); any figure it surfaces must still be placed from an already-verified
  upstream outcome, never authored fresh (`verify-regulated-figures-by-postcondition`).
- No resolving Mode-specific open questions silently — Mode B's `disposition` addition (§11.4) was
  an explicit call, not a default; any similarly-shaped judgment call surfacing during C/D/B builds
  gets the same treatment.

### 11.8 Build progress

- **Mode C KB content — done 2026-07-10.** `kb.journey.investor-path` (the swimlane copy doc),
  `kb.journey.investor-phase-actions` (the per-phase checklist), `kb.risks.investor-by-phase` (the
  per-phase risk-flag-list) — same three-doc shape as Mode A's `kb.journey.fhg-path` /
  `kb.journey.phase-actions` / `kb.risks.fhb-by-phase`. Structurally verified (each `content_json`
  parses; every `layout.phases[].actions[]`/`risks[]` id resolves to a matching `{vi,en}` copy pair
  with no orphans). Two design calls made and grounded rather than defaulted:
  - **Six actors, not four.** You / Government / Lender / Property manager / Tenant / Services —
    Property manager and Tenant earn their own row because rent is a real actor-attributable cash
    flow (`counterparty: tenant` for the inflow, `counterparty: property_manager` for the fee
    outflow); collapsing them into a generic "Other" would blur the who-pays-whom `interactions`
    view cell counterparties drive.
  - **Entity-setup DECISION (Prepare-phase content, this doc) vs. entity-setup EXECUTION (a Settle-
    phase milestone `settlement_prep.investor_milestones` already owns, per-property, unchanged).**
    §11.2's "entity setup is a pre-Contract one-time step" is about `tax_structure`'s base-scope
    `recommended_entity` call, not the act of establishing it — that stays where
    `settlement_prep` (component 10) already placed it. Not a conflict to resolve, a distinction to
    keep.
  - **Open engine dependency, not a KB gap.** `budget_envelope_investor` / `cash_flow_projection` /
    `tax_optimised_structure` don't yet carry a `cash_events[]` array (only `disposition` does
    today) — the underlying figures exist as params but aren't exposed under stable event ids. This
    doc's preamble declares the full id vocabulary (`deposit`/`stamp_duty`/`other_buying_costs`/
    `entity_setup_costs`/`lmi` acquisition; `rental_income`/`operating_expenses`/`loan_interest`/
    `tax_refund` hold, recurring/year) task #4 (engine wiring) must expose those outcomes under —
    the forward declaration Mode A's own build order (§7, blueprint/KB before engine) already
    established as the normal sequencing, not a shortcut. **Resolved by task 4, below.**

- **Mode C engine wiring — done 2026-07-10 (task 4).** `budget_envelope_investor` (`fh_engine_cash:
  cash_events_investor/4`), `cash_flow_projection` (`fh_engine_fill:yield_cash_events/1`), and
  `tax_optimised_structure` (`fh_engine_fill:tax_cash_events/1`) now emit `cash_events` — 8 of the 9
  declared ids resolve to real events (`entity_setup_costs` stays unemitted: the underlying
  `tax_optimised_structure.setup_costs` figure is permanently null, a separate still-open entity-cost
  seam, flagged not patched here). `fh_engine_journey`/`fh_engine_phase_playbook` gained
  `fill_investor/1` (investor-specific actors/phases/prose cells, hand-derived flow markers against
  `kb.journey.investor-path`'s authored `cell_<phase>_<actor>` keys — one authored key,
  `cell_own_recurring`, is intentionally left unreferenced: the four hold-phase money cells already
  carry that content per-counterparty, so a combined prose cell would duplicate them).
  - **Design call: generic multi-source harvest, not a Mode-C branch** (advisor-flagged before
    writing any event builder). `harvest_cash_events/1` concatenates the `cash_events` field off
    *every* upstream outcome that exposes it, rather than reading one hardcoded key. Mode A has
    exactly one source (`budget_envelope`) so this is behaviourally identical to before (verified —
    both Mode-A conformance escripts pass unchanged); Mode C has three. The KB-slug selection stays
    genuinely mode-specific (unavoidable — different bilingual content per mode); the figure-harvest
    does not. This means Modes D and B (tasks 8/12) need **zero** change to `fh_engine_journey`/
    `fh_engine_phase_playbook` — they only need their own components to emit `cash_events`.
  - **Design call: `cash_event.amount` needed no widening.** The registry already types it
    `money_range`, and the codebase's existing convention (`point/1` in `fh_engine_cash`,
    `money_range/1` in `fh_engine_disposition`) already collapses scalar figures to `[v,v]` — so the
    mix of banded (`rental_income`/`operating_expenses`) and scalar (`loan_interest`/`lmi`/
    `tax_refund`) hold-phase figures needed no schema change, just the same collapse-to-range
    convention (`hold_amount/1` in `fh_engine_fill.erl`).
  - `purchase_journey`/`phase_playbook` added to `investor-domestic-au.md` as components 13/14
    (mode-general `journey_swimlane`/`phase_playbook` outcome types reused verbatim, per §3.3) and to
    `?BASE_COMPONENTS_INVESTOR`; the compiled artifact recompiled clean (no gate failures).
  - **Verified, not just implemented:** a new end-to-end investor smoke run (synthetic
    `budget_envelope_investor`/`cash_flow_projection`/`tax_optimised_structure`/`disposition`
    upstream) places all 10 harvested cash_events at the correct `(phase, actor)` with
    `fh_engine_outcome:validate/3` returning `ok` for both outcomes; a negative test confirms
    `cash_events` is genuinely schema-gated (the §13 placement check — "money flow has no
    counterparty" — fires on a malformed event), not silently passed (the known `validate/3`
    fail-open gap did not apply here because the field is now declared).
  - **Adjacent drift fixed en route.** The same "reform not yet law" staleness already caught once
    this session (`interest-only-vs-pi-investor.md`) recurred in `kb.copy.tax-structure` and
    `kb.copy.disposition` — both corrected to the Act's actual enacted status (Act No. 49 of 2026,
    Royal Assent 26 June 2026, effective 1 July 2027). A repo-wide grep confirmed no further
    instances remain.
- **Mode C `ui_tabs` rewrite — done 2026-07-10 (task 5).** `investor-domestic-au.md`'s machine-readable
  `ui_tabs` block rewritten from the stale flat eight-tab rail to the §11.3 five-view spine —
  `overview` (`investor_profile`/`investment_strategy`/`mortgage_finance`/`cash_position`), `flow`
  (`purchase_journey`/`phase_playbook`/`settlement_prep`), `budget` (`cash_position`/
  `yield_modelling`/`tax_structure`/`disposition`, interactive), `portfolio`
  (`ownership_planning_investor`), `qa` (empty) — mirroring `fhb-domestic-au.md`'s
  `overview`/`flow`/`budget`/`qa` shape exactly, plus `portfolio` for the one state-shaped concept
  §11.2 doesn't fold. `property_assessment`/`buying_strategy`/`due_diligence` (per-property) are
  dropped from the tab list entirely, same treatment as Mode A's dropped set — reached only via
  `phase_playbook.actions[].component_ref`. `investment_strategy` appears in `overview` (a visible
  synthesis read) but not in `flow`'s components array, mirroring how Mode A's `eligibility` folds
  into a phase's action checklist without being a literal Flow-tab component. The human-readable "UI
  tab mapping" table above it rewritten to match (5 rows, `#`/View/`kind`/What-it-shows), same format
  as `fhb-domestic-au.md`'s. `engine/build/kb_compiler.py` recompiled clean — GATE 9 (`ui_tabs`
  reference-integrity: every `tab_id` unique, every `kind` in the enum, every listed component real)
  passed for all 5 in-scope blueprints; the emitted artifact's `blueprints.investor-domestic-au.ui_tabs`
  inspected directly and matches the five tabs above.

- **Mode C shell rendering — done 2026-07-10 (task 6).** Traced the render path
  (`PlanProjection.svelte` → `OverviewCard`/`FlowView`/`Calculator`) before writing anything: it
  already renders any `ui_tabs` the engine declares generically — `kind: synthesis`/`flow`/
  `components`/`qa` dispatch, `TAB_GROUP`/`plan.ltab.*` i18n already cover `flow`/`budget`/
  `portfolio`, and `OverviewCard` was already fixed for Modes C/D's `investor_profile`/
  `investment_strategy` fields (task 2). So the five-view spine needed **no new UI**, only a
  data-completeness fix surfaced by tracing it:
  - **Bug found: two consumers read `cash_events` off a single hardcoded component, not the
    harvested set.** `PlanProjection.svelte`'s `flowCashEvents` (feeds `FlowView`'s budget_ref → amount
    join) and `Calculator.svelte`'s `events` (feeds the Budget tab's cash-events table) both read only
    `cash_position.outcome.cash_events`. For Mode A this is harmless (`cash_position` is the only
    source). For Mode C it silently drops the amount for every hold-phase action/row sourced from
    `yield_modelling`/`tax_structure` — concretely, `kb.journey.investor-phase-actions`' `own`-phase
    `lodge_annual_return` action links `budget_ref: "tax_refund"` (a `tax_structure` event); the engine
    validates it fine (its own `harvest_cash_events/1` already covers all three sources, task 4), but
    the shell would show no amount chip and the Budget spine table would show only 4 of 8 rows — a
    silent shell-side regression from the engine's own fix, not a new engine gap.
  - **Fix: `harvestCashEvents(components)` added to `planCard.ts`**, mirroring
    `fh_engine_journey:harvest_cash_events/1` exactly (concatenate `cash_events` off every component's
    outcome; `dispose_cash_events` deliberately excluded — the engine harvest excludes it too, so no
    authored action ever links a dispose-phase `budget_ref`). `flowCashEvents` now calls it directly;
    `Calculator.svelte`'s `events` calls it when `components` is non-empty, falling back to the
    outcome's own `cash_events` for the componentless standalone render (`ComponentCard`'s bare
    `<Calculator outcome={entry.outcome} />`, which has no siblings to harvest). Verified inert for
    Mode A: `cash_position` is its only `cash_events`-bearing component at runtime, so the harvested
    set is byte-identical to the old single-source read.
  - **Verified:** `npm run check` (svelte-check) 0 errors / 0 warnings; `npm run build` succeeds
    clean. Full live-browser verification against a real filled Mode C card is task 7's job (the
    seam-smoke gate), not duplicated here.

- **Mode C conformance + live seam-smoke — done 2026-07-10 (task 7).** Found and fixed a real
  authoring bug, not just staleness: `investor-domestic-au.md`'s `purchase_journey`/`phase_playbook`
  sections (13/14) declared their `**Outcome schema:**` type inline (`journey_swimlane`/
  `phase_playbook`, prose "identical to Mode A's, not repeated here") instead of the fenced
  ` ```jsonc ` block `kb_compiler.py` actually parses (it materializes `outcome_type` per-blueprint,
  never by cross-reference) — so both components compiled with `outcome_type: null`. Consequence:
  `fh_engine_outcome:validate/3` silently no-ops for both (the known fail-open registry gap,
  §grounding-checklist item, now concretely instantiated for 2 more components) and both components
  collided under the SAME `null` accumulator key in `fh_engine_turn`'s DAG walk (harmless today only
  because `harvest_cash_events/1` reads by value not key — a latent landmine for any future consumer
  that reads `Upstream` keyed by outcome_type). Fixed by adding the fenced schema blocks (mirroring
  Mode A's `fhb-domestic-au.md` components 10/12 exactly, six-actor set noted for `journey_swimlane`);
  recompiled — `outcome_type` now resolves to `journey_swimlane`/`phase_playbook` correctly.
  - **Conformance sweep found + fixed 5 more stale fixtures** (all the same class: written before
    task 4 added purchase_journey/phase_playbook + cash_events, never updated) —
    `base_components_investor_conformance.escript` (SET+ORDER fixture missing the 2 new components),
    its 3 mirrored no-regression cross-checks in `base_components_foreign_investor_conformance.escript`
    / `base_components_foreign_conformance.escript` / `base_components_nexthome_conformance.escript`
    (each asserts Mode C's set byte-identical to a fixture that still said 8), and
    `cash_position_investor_conformance.escript` / `tax_structure_conformance.escript` /
    `yield_modelling_conformance.escript` (each missing `cash_events` from their exact-field-set
    assertion — extended with an honest-empty-at-base check + a per-property/discriminator check
    that the harvested `cash_events` actually carry `source_component: <owner>`). Full sweep of all
    58 non-seam-smoke conformance escripts: 56 pass; 2 unrelated pre-existing failures flagged
    separately below (not fixed here — out of this task's scope).
  - **`investor_seam_smoke.escript` rewritten for the 10-component spine** (was still asserting the
    original 8: wrong event count, wrong audit count, wrong order — it had `ownership_planning_investor`
    before `disposition`, but the real order is the reverse, a staleness independent of task 4).
    New counts: 45 events (`1 + 10×4 + 3 usage + 1`), 30 audit rows, ASIC `boundary_held` still 1
    (purchase_journey/phase_playbook are not `advice_adjacent`). Added two live assertions specific
    to the restructure: the six-actor investor set (`property_manager`/`tenant`, not Mode A's four)
    and the `own`-phase `lodge_annual_return` action (`kb.journey.investor-phase-actions`) — both
    proving the investor KB branch fired over the real HTTP/SSE surface, not Mode A's. Cash-amount
    placement itself isn't asserted here (this is a property-less, income-less onboarding turn, so
    every upstream `cash_events` source is honestly empty — that positive case is what
    `cash_position_investor_conformance.escript`'s new per-property check proves instead).
  - **Ran LIVE** (real `claude-sonnet-5` sidecar fills, metered, via `CLAUDE_CODE_OAUTH_TOKEN`):
    `investment_strategy`/`mortgage_finance`/`tax_structure` all filled live; all 45 events matched;
    all 30 audit rows `clear`; both new journey/playbook assertions passed
    (`archetype=balanced gearing=neutral_geared io_vs_pi=principal_and_interest entity=personal_sole`;
    `actors=[you,government,lender,property_manager,tenant,services]`;
    `own_actions` includes `lodge_annual_return`). **ALL ASSERTIONS PASSED.**
  - **Flagged, not fixed (out of scope):** two pre-existing, unrelated conformance failures surfaced
    by the full sweep — `due_diligence_conformance.escript` (`agent_leaves` classification mismatch
    for the deferred `lease_interpretation` leaf) and `profile_enrichment_conformance.escript`
    (`mortgage.expected_borrowing_capacity` IC0 fixture off "to the dollar" — likely tax-bracket
    fixture drift from the 2026-27 update, the same class `5f87af9` already fixed for HECS but may
    not have caught here). Neither touches `cash_events`/`journey`/`phase_playbook`/`ui_tabs`; not
    investigated further here — a separate, later pass.
  - **Task 7 closes out the Mode C restructure** (tasks 3–7 all done). Next: task 8, Mode D.

- **Mode D KB content + engine wiring — done 2026-07-10 (task 8).** Three new bilingual copy docs
  mirroring Mode C's shape exactly: `kb.journey.investor-foreign-path` (the swimlane), `kb.journey.
  investor-foreign-phase-actions` (the per-phase checklist), `kb.risks.investor-foreign-by-phase`
  (the per-phase risk-flag-list) — layering §3.3's FIRB gate + cross-border transfer milestone +
  entity + non-resident tax + repatriation onto Mode C's phase/actor skeleton, not a new design.
  One design call made and grounded, not defaulted:
  - **Reuses Mode C's six actors unchanged — no seventh row for the FX/transfer provider.** The
    swimlane's actor set must be a superset of every cash_event counterparty Mode D's figure-owners
    emit (government/lender/tenant/property_manager), and all of them already sit inside the six.
    The cross-border transfer provider is a service the investor engages once, not a party with a
    recurring relationship the way tenant/property_manager are — the same `services` bucket already
    holds the conveyancer/QS. VN-side capital-control steps are `you`/`services` prose, not a
    jurisdiction-ambiguous `government` cell (AU FIRB and VN SBV are different governments).
  - **The FIRB gate and the transfer milestone are not new phases.** Both are narrated across the
    existing `pre_approve → contract → settle` span on the government/lender/services rows —
    matching how §11.2 places `firb_workflow` as a Flow *gating phase*, not its own tab.
  - Learned from task 7 and applied proactively this time: both new components carry the full
    fenced ` ```jsonc ` `type` blocks in the blueprint (not a prose "same as Mode A/C" reference) —
    verified post-recompile by inspecting the artifact directly: `purchase_journey` → `outcome_type:
    journey_swimlane`, `phase_playbook` → `outcome_type: phase_playbook` (neither `null`).
  - **Engine wiring is smaller than Mode C's was**, because two of the three cash_events sources
    are already generic/shared code: `yield_modelling` is the SAME resolver function for Mode C and
    D (one component name, name-keyed dispatch in `fh_engine_fill.erl`) and already emits
    `cash_events` — no change needed. `disposition`'s `fill_investor/3` is likewise shared C/D and
    already emits `dispose_cash_events` — no change needed. Only `fh_engine_cash:fill_investor_
    foreign/2` (cash_position) and `fh_engine_fill:tax_structure_non_resident/1` needed a
    `cash_events => []` addition — a **literal, not a helper**: Mode D's `cash_position` has no
    per-property branch yet (flagged below), and `tax_structure_non_resident`'s candidate figure
    (`annual_au_tax_payable_on_rental`) is null at base *and* per-property (no non-resident
    marginal-rate KB table exists yet), so a real event-builder would be permanently-dead code.
    `fh_engine_journey`/`fh_engine_phase_playbook` gained a Mode-D dispatch branch each
    (`investor-foreign-au` → `fill_investor_foreign/1` / the new actions+risks doc pair) — verified
    the dispatch is genuinely wired, not silently falling through to Mode A's `_ -> fill_fhb`/
    `_ -> {?ACTIONS,?RISKS}` default (a fail-*silent* class of bug, distinct from task 7's fail-open
    validate gap). `purchase_journey`/`phase_playbook` added to `?BASE_COMPONENTS_FOREIGN_INVESTOR`
    (10 → 12) — appended at the END, not copying Mode C's exact tail: Mode D's `ownership_planning_
    foreign_investor` already runs *before* `disposition` (the reverse of Mode C's order, because
    unlike Mode C's `ownership_planning_investor` it never reads `disposition`'s figures for an
    `equity_release` opportunity), so simply appending the two new components after the existing 10
    is correct without reordering anything.
  - **Flagged, not fixed (a `cash_position` build, explicitly out of scope for this task).** Mode
    D's `fill_investor_foreign/2` has no per-property branch (unlike Mode C's, which lights up a
    real acquisition spine once a property attaches) — so `purchase_journey`'s acquisition-phase
    money cells (deposit, stamp duty + surcharge, FIRB fee) stay empty even per-property, today.
    `yield_modelling`'s hold-phase cells DO light up per-property (shared code with Mode C). The
    swimlane therefore renders the full legal/prose spine now but a sparse money spine until that
    seam closes — disclosed in the KB doc's own preamble, not silently implied as complete.
  - **Not run yet: the full conformance sweep + live seam-smoke** (task 10, after task 9's `ui_tabs`
    rewrite). A quick sanity pass this task: every individual per-component registry check + every
    real-code-dependency DAG-order check in `base_components_foreign_investor_conformance.escript`
    passes (incl. `purchase_journey`/`phase_playbook`); its own SET+ORDER fixture now fails as
    **expected** (still asserts the pre-task-8 ten-component list) — task 7's precedent (the same
    fixture-staleness class hit three files) predicts this will recur in Mode D's own conformance
    files and `mode_d_seam_smoke.escript`'s `expected_sequence()`; task 10 owns fixing all of it,
    not patched ad hoc here.
  - **Next: task 9**, Mode D's `ui_tabs` rewrite to the five-view spine (Overview/Flow/Budget/
    Portfolio/Q&A) + shell restructure — folding `firb_workflow`/`cross_border_funding`/
    `investment_strategy`/`tax_structure_non_resident` into Flow phases + Budget rows, same
    placement test Mode C's task 5 already proved.

- **Mode D `ui_tabs` rewrite + shell restructure — done 2026-07-10 (task 9).**
  `investor-foreign-au.md`'s machine-readable `ui_tabs` rewritten from the stale flat 9-tab rail to
  the five-view spine, mirroring Mode C's shape exactly with `firb_workflow`/`cross_border_funding`
  added where Mode C has no equivalent: `overview` (`investor_profile_foreign` + `firb_workflow` +
  `investment_strategy` + `mortgage_finance` + `cash_position` — `firb_workflow` included as a
  headline the same way Mode A's `overview` includes `eligibility`); `flow` (`purchase_journey` +
  `phase_playbook` + `settlement_prep`, with the FIRB gate and transfer milestone narrated across
  Pre-approve→Contract→Settle, not new phases); `budget` (`cash_position` + `firb_workflow` +
  `cross_border_funding` + `yield_modelling` + `tax_structure_non_resident` + `disposition`);
  `portfolio` (`ownership_planning_foreign_investor`); `qa`. **No default Family tab** — Mode D
  stays solo/couple by default per §11.3's own note, offered as opt-in only. `kb_compiler.py`
  recompiled clean, GATE 9 (`ui_tabs` reference-integrity) passed, artifact's `ui_tabs` inspected
  directly and matches the declared 5 tabs/16 components exactly.
  - **Shell verification (mostly confirmation, like Mode C's task 6): the render path is already
    fully mode-general** — `PlanProjection.svelte` dispatches purely on `ui_tabs[].kind`
    (`synthesis`/`flow`/`interactive`/generic), never on blueprint slug; `FlowView`'s
    `flowJourney`/`flowPlaybook`/`flowCashEvents` derive from `viewComponents.purchase_journey`/
    `phase_playbook` + the harvested `cash_events` (task 6's `harvestCashEvents()`), with no mode
    gating; the interactive Budget tab renders `cash_position`'s `Calculator` directly and never
    actually iterates `activeTab.components` (that array is declarative/GATE-9-validated, not
    consumed for rendering — true for Mode C's budget tab too, confirmed by reading the code, not
    assumed). The Overview/Buy double-highlight bug (§11.6) self-resolved as predicted:
    `nonOverviewRailTabs.length` is now 3 for Mode D (well under `RAIL_GROUP_THRESHOLD=5`), so the
    grouped-rail mechanism no longer engages.
  - **One real gap found and fixed**: `OverviewCard.svelte` didn't read `firb_workflow` at all,
    even though task 9's own `ui_tabs` rewrite just declared it as an Overview-tab component — the
    doc would have said "Overview shows FIRB status" while the shell silently didn't. FIRB status is
    a first-class user attribute (CLAUDE.md #10 — "build the gate into the architecture, not as a
    disclaimer"), not optional headline chrome, so this was fixed rather than left as a documentation/
    behavior mismatch: added a `firbStatus`-presence-gated tile (mirrors the existing `scheme`/
    `existingHome` presence-gating pattern) showing the `current_stage` label via the already-existing
    `plan.firb.stage.*` i18n keys — no new copy needed. Presence-gated on the component, not
    mode-name, so it activates automatically once Mode B's own `firb_workflow` restructure lands
    (task 13) with zero further OverviewCard change.
  - **Verified:** `svelte-autofixer` clean, `npm run check` 0 errors/0 warnings, `npm run build`
    clean (pre-existing >500kB chunk-size warning unrelated).
  - **Next: task 10**, Mode D conformance + live seam-smoke verification — the full 58-file sweep
    (expected to need the same fixture-staleness fixes task 7 made for Mode C: the base SET+ORDER
    fixture already confirmed stale in task 8's sanity check) plus `mode_d_seam_smoke.escript`
    rewritten for the 12-component spine and run live against the real sidecar.
