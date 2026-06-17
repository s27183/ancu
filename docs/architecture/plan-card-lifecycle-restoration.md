# Plan-card lifecycle restoration (A + B1 + B2), mode-general

**Status:** planned, 2026-06-17 (rev 2 — extended to all four modes per Son). Sibling to
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

## 9. Open decisions

- **`purchase_journey` DAG placement** — after `mortgage_finance` (reads scheme_stack + path) is the
  proposal; confirm it shouldn't read only `{profile, eligibility}` and run earlier.
- **Compiler scope** — does `kb_compiler`/`validate_build` process all four blueprints (so B/C/D
  `ui_tabs` are validated now), or only the in-scope one? If only in-scope, the B/C/D declarations are
  authored-but-unvalidated until those modes activate — acceptable, but worth knowing.
- **Journey KB granularity** — one `kb.journey.fhg-path` with `{state, path}` variants inline
  (proposal), vs per-state docs.
- **Overview "best/safer path"** — the prototype showed two strategies; at base we have one
  target+path. Proposal: Overview shows the single recommended path; multi-strategy compare is a later
  (refine/per-property) enhancement.

## 10. Non-goals

- No B/C/D **content** now (KB figures, resolvers, the unbuilt renderers `family-view-card`,
  `firb-workflow-card`, yield/tax cards) — structure only (§4).
- No price-varying client-side calculator (duplicates the regulated duty computer — §6).
- No new renderer vocabulary entries (all needed renderers already in the enum — §2 R3).
- No expansion of onboarding capture to force a stored cash verdict (honest-partial base is finished).
- No change to `settlement_prep` (it stays the per-property settlement detail — §7).
