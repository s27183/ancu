# Plan-card visual spec — hero-visual-per-section

**Status:** draft for review · Wedge 1a · base components only
**Owner question it answers:** the rendered plan card is a spec sheet (label/value rows + bullet lists); the [prototype](../first_home_buyer_plan.html) is visually powerful. This pins how every plan section earns a **hero visual** that summarizes its essence — without breaking the locked constraints (renderer vocabulary, honest-partial, bilingual-at-source, no agent-drawn markup).

This is a **presentation** spec. It changes renderers (shell) and, where noted, asks for richer outcome fields (engine). It does **not** change the agent's job: the agent fills the typed outcome; the renderer draws the visual from it.

---

## 1. The model: one outcome → two surfaces

There is **one** outcome model (the five base outcome types in [`planCard.ts`](../../shell/web/frontend/src/lib/planCard.ts)) and **two** surfaces that render it. Both draw the same hero visuals; they differ only in density.

| Surface | What it is | Density | Built |
|---|---|---|---|
| **Projection** | the in-map sheet/modal — one section per sub-tab ([`PlanProjection.svelte`](../../shell/web/frontend/src/lib/PlanProjection.svelte)) | `compact` — hero leads, detail collapses below | first |
| **Dossier** | the on-demand export — all sections stacked, full-scroll, [prototype](../first_home_buyer_plan.html) design language (constraint #6; [`04-ux-model.md`](../04-ux-model.md) §13.4) | `full` — hero + all detail | second |

**Implication for renderers:** each renderer takes a `density: 'compact' | 'full'` prop. One component, two zoom levels — not two components. The projection is what the user stares at today, so it ships first; the dossier is the same renderers at full density assembled into a scroll.

---

## 2. Cross-cutting rules (the stakes — do not negotiate these away)

- **R1 — Deterministic from the outcome. Never agent-drawn.** A hero visual is a pure function `outcome → geometry`, drawn in Svelte/SVG/CSS, exactly like the existing `Calculator` computes from inputs. The agent never emits `<svg>` or markup with figures in it. *Why:* this is the only way figures stay verifiable-by-postcondition, the audit trail holds, the renderer vocabulary stays a closed set, and there's no injection surface. The moment "$1.0M" lives in agent-authored SVG, every guarantee in the engine contract is gone.
- **R2 — Honest-partial degradation is part of the visual.** Base fills are three-valued ([base-turn-honest-partial-output]). Every hero must render the PENDING state *as a visual* — a ghosted segment, a banded range, a neutral gauge — never a zero, never a fake point. A visual that implies precision the base plan doesn't have is a regression, not a polish.
- **R3 — The vocabulary is a palette, not a ceiling (constraint #7).** Heroes are built *inside* the named renderers (`summary-card`, `scheme-stack-card`, `calculator`, `data-table`). No new renderer name is needed for the five base heroes. New renderer names remain intentional design decisions (the deferred swimlane is one — §5).
- **R4 — Bilingual at the source (constraint, [bilingual-content]).** All visual labels are either enum-driven (chrome `$t`) or `LocalizedText` picked by `$lang`. No figure or prose is minted in the renderer.

**One hero per outcome type, not per renderer or component.** `summary-card` serves two outcome types (`profile`, `mortgage_plan`) → it hosts two heroes, branched on outcome type. This keeps heroes aligned to the typed interface downstream components read (constraint #5).

---

## 3. The five hero visuals

Each: the **essence** the section must convey, the **visual**, the **driving fields** (all already in the schema unless flagged `[NEW]`), and the **PENDING** form. Sketches are indicative, not final layout.

### 3.1 `profile` (buyer_profile · renderer `summary-card`) — **Reach bar**
**Essence:** who you are as a buyer, and whether your target fits your reach.
**Visual:** a horizontal bar = deposit block + borrowing-capacity band; the target price range marked as a bracket against it, tinted in-reach / stretch / over.
```
 Deposit   Borrowing capacity
 ▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░   reach
        [   target $600–750k   ]   ✓ in reach
 FIRB: not required · 2 applicants
```
**Driving fields:** `deposit_ready_for_purchase_amount`, `approx_borrowing_capacity`, `target_price_range`, `firb_required_any` (badge), `applicant_count` (label).
**PENDING:** capacity null → deposit block solid + target bracket, capacity zone ghosted "computing"; target null → FIRB gate + applicant chips only.

### 3.2 `scheme_stack` (eligibility · renderer `scheme-stack-card`) — **Scheme stack bar**  ⟵ build first
**Essence:** which government schemes stack, and what they're worth together.
**Visual:** a stacked bar, one segment per applicable scheme sized by `benefit_value`, summing to `total_benefit_value`; rejected schemes as ghosted chips; application order as numbered ticks.
```
 eligible: all applicants ✓
 ┌──────────┬─────────┬──────┐
 │ FHG      │ QLD duty │ FHSS │   = $X total benefit
 └──────────┴─────────┴──────┘
 order: ① FHSS → ② FHG → ③ duty
 not eligible: FHOG (price over cap)
```
**Driving fields:** `applicable_schemes[].{name, benefit_value}`, `total_benefit_value`, `rejected_schemes[].name`, `recommended_application_order`, `eligibility_basis` (header chip).
**PENDING:** a scheme with null `benefit_value` renders as a fixed-width hatched segment (counted, not sized); basis null → header "computing".
**Status: DONE & verified.** Correction to the original premise — the data did **not** "already flow": `benefit_value` was prose / `total_benefit_value` null (qualitative-at-base). It took the **Decision 8 foundation** ([eligibility-resolution.md §8](eligibility-resolution.md)) — `benefit_value` typed as `money_range`, computed in `fh_engine_eligibility` (duty via the shared `fh_engine_cash`, FHG LMI band, FHOG fixed), VIC wired into `state_catalog`, conformance-locked (`eligibility_benefit_eval.py`). The hero now sizes segments by each range's **midpoint**, shows ranges in the legend (collapsing `[x,x]`→`$x`), marks estimates with `~`, hatches null benefits, and renders the total as a range.

### 3.3 `mortgage_plan` (mortgage_finance · renderer `summary-card`) — **Path + capacity**
**Essence:** the recommended financing route, and what you can borrow.
**Visual:** a 3-lane route picker (20%+ · 5%+FHG · 5–20%+LMI) with the recommended lane highlighted; expected-capacity band; lender shortlist as chips.
```
  ○ 20%+ deposit
  ● 5% + FHG (no LMI)  ← recommended
  ○ 5–20% + LMI
  borrow ~ $700–760k
  lenders: CBA · NAB · …
```
**Driving fields:** `recommended_path` (enum), `expected_borrowing_capacity`, `recommended_lender_shortlist[].{lender, approval_likelihood}`.
**PENDING:** path null → all lanes neutral + "computing".

### 3.4 `budget_envelope` (cash_position · renderer `calculator`) — **Cash waterfall + verdict**
**Essence:** do I have enough cash at settlement? (the prototype calculator's core question, as a visual)
**Visual:** a stacked "need" bar (deposit + stamp duty after concession + other costs + buffer) against a "have" bar (cash available); gap/surplus called out; `verdict` tints the block ok/warn/bad. The interactive calculator stays below.
```
 need  ▓deposit▓ ▓duty▓ ▓costs▓ ▓buffer▓   $73k
 have  ▓▓▓▓▓▓▓▓▓▓▓▓▓                        $50k
 gap   $23k short                ⚠ tight
```
**Driving fields:** `stamp_duty.{after_concession, before_concession, concession_applied}`, `total_cash_required`, `cash_available`, `gap_or_surplus`, `verdict`. *(The "other costs" + "buffer" breakdown for the need-bar segments may need `[NEW]` fields — today only `total_cash_required` is itemized partway; resolve in build.)*
**PENDING:** figures null → banded segments; verdict null → neutral tint.
**Base-turn scope (2026-06-17, see §4 revision):** the **need bar is real** at base (deposit · duty · other costs → `total_cash_required`, all `money_range`); the **have bar + verdict are PENDING by design** (no savings captured at onboarding) — ghost the have-bar with an "add your savings" CTA, `reserve_buffer` stays null (needs the loan repayment). The hero answers "here's what it costs to get in," not yet "can you afford it."

### 3.5 `ongoing_obligations` (ownership_planning · renderer `data-table`) — **Outgoings breakdown**
**Essence:** what owning it costs each period, and what to watch.
**Visual:** a segmented bar of recurring costs (statutory band · strata · utilities · insurance) → monthly/annual total; maintenance reserve as a separate marker; armed alert triggers as a short list.
```
 monthly ~$X
 ┌─rates─┬─strata─┬─utils─┬─insur─┐
 reserve target: ~$10k/yr
 ⚑ armed: LVR<80% → refinance
```
**Driving fields:** `total_monthly_outgoings_estimate`, `total_annual_outgoings_estimate`, `recurring_costs_estimate.{statutory_band, strata_levies, utilities, building_insurance}`, `maintenance_reserve_target`, `alert_triggers_armed[].{trigger, action}`.
**PENDING:** any null → banded / omitted segment.

---

## 4. Build order

1. **`scheme_stack` hero** — data exists, no engine change; proves the pattern + the `density` prop + the shared bar primitive. **DONE & verified** (§3.2).
2. **`budget_envelope` hero** — highest user value (the "can I afford it" answer); may surface `[NEW]` need-bar fields.
3. **`profile` reach bar.**
4. **`mortgage_plan` path picker.**
5. **`ongoing_obligations` breakdown.**
6. **Dossier assembly** — stack all five at `density: full` in the export surface ([prototype](../first_home_buyer_plan.html) as design language).

### Build-order revision (2026-06-17 — grounded against the live engine)

The order above ranked `budget_envelope` "build second, highest value" **assuming the data exists**. Reading the five resolver fills shows it does not, uniformly — each hero's base-turn data richness differs, and the original order ignored that:

| Hero | Component fill | Real at base | Pending at base |
|---|---|---|---|
| 1 `scheme_stack` ✓ | `fh_engine_eligibility` | schemes + benefit ranges + total | — |
| 4 `mortgage_plan` path picker | `fh_engine_mortgage` (two-path) | `recommended_path` (`fhg_backed`/null), lender chips (agent) | `expected_borrowing_capacity` |
| 3 `profile` reach bar | `fh_engine_fill:buyer_profile` | target range, `firb_required_any`, `applicant_count` | deposit, borrowing capacity (financials → refine turn) |
| 5 `ongoing_obligations` | `fh_engine_ownership` | rates band, reserve target, armed alerts, land-tax | totals, strata/utils/insurance |
| 2 `budget_envelope` cash waterfall | `fh_engine_cash` | `stamp_duty.*` + price ceiling **only** | total cash, cash available, gap, verdict, deposit, other costs, buffer — **all null** |

`fh_engine_cash` (`cash_position`) deliberately fills only the `stamp_duty.*` sub-tree at base (`fh_engine_cash.erl:16-17`); everything else is deferred to "separate fills" that did not exist. So the cash waterfall — the spec's #2 — was the **weakest** hero today (one duty segment, empty need/have bars), not the strongest.

**Son's call (2026-06-17): build the engine cash fills first**, so the waterfall lands with real data, rather than reorder cash to last. The honest achievable scope of those fills (blueprint + both cost KBs):

- **NEED side becomes real** — `deposit` (min required = 5% × price-range, gated on `recommended_path = fhg_backed` from upstream `mortgage_plan`) + `stamp_duty` (exact, built) + `other_buying_costs` (per-state registration **regulated/exact** + convention bands → `money_range`) → `total_cash_required` (= these three; the blueprint names it `_at_settlement`).
- **HAVE side + verdict stay PENDING by design** — `cash_available = cash_on_hand + fhss_release + family_contribution`, and onboarding captures **no savings** (§7.1 plan-first minimalism; `buyer_profile` defers financials to a refine turn). So `cash_available`/`gap_or_surplus`/`verdict` are honestly null at base; the have-bar ghosts with a "add your savings" CTA, the verdict computes on refine. *We do not expand onboarding to capture savings — that fights the plan-first design.*
- **`reserve_buffer` stays PENDING** at base — it is `3 × monthly repayment`, which needs the loan rate (an agent/refine fact); honest-null + note. (The `kb.cash-reserve` 8–10%-of-price prudent band is a planning marker, not the settlement total.)

**Revised order:** (2) engine cash NEED-side fills → cash waterfall hero · (3) `mortgage_plan` path picker · (4) `profile` reach bar · (5) `ongoing_obligations` breakdown · (6) dossier. Heroes 3–5 are pure-frontend honest-partials (their real fields above already flow).

**Schema decision — cash totals are `money_range` at base** (analogous to Decision 8 for benefits): price is a range at base → deposit / other-costs / total are ranges; per-property they collapse to a point. Tracked in [`eligibility-resolution.md`](eligibility-resolution.md) and reflected in the `budget_envelope` outcome schema (§3.4 of [`fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md) — the `[NEW]` `deposit`/`other_buying_costs`/`reserve_buffer` itemized sub-objects, resolving §6-Q2).

**Shared primitive:** extract a tiny deterministic SVG/CSS toolkit (stacked bar, range bar, gauge) at the **second** renderer that needs it (per [decompose-build-unit-by-mechanism]) — pure `outcome → geometry`, no per-renderer reinvention. Lean CSS/flex for the simple bars (responsive, theme-able, no viewBox math); SVG only where geometry demands it (gauges, the future swimlane).

---

## 5. Deferred (noted, not in scope)

- **Temporal-flow / swimlane component** — the prototype's showpiece (who-pays-whom-when across actors × phases). It has **no producing base component today**; shipping it means a new base component + a new `temporal_flow` outcome type + the `swimlane-diagram` renderer (a constraint-#7 vocabulary entry that exists in name only). **Held for a later pass** (Son's call, 2026-06-17) until the five heroes above land. Revisit then.
- **Per-suburb gradient** in the projection (the zone→suburb overlay) — already deferred in `PlanProjection`; orthogonal to this spec.

---

## 6. Open questions for review

1. **`density` prop vs separate components** — recommend one component + `density: compact | full`. Confirm.
2. **`budget_envelope` need-bar segments** — ~~add `[NEW]` itemized fields (other_costs, buffer) to the outcome, or have the renderer show only deposit + duty + remainder?~~ **RESOLVED (2026-06-17, §4 revision):** add the `[NEW]` itemized `deposit` / `other_buying_costs` / `reserve_buffer` sub-objects to the `budget_envelope` outcome (typed `money_range` at base) and compute them in `fh_engine_cash` — the need bar is honest *and* itemized. `reserve_buffer` stays null at base (needs the loan repayment).
3. **Dossier trigger/surface** — out of this spec's scope, but the dossier needs an export route; flag when we get to step 6.
