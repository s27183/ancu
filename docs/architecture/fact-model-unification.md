# Fact model vs. pipeline — a design finding and direction

**Status:** Direction accepted; the plan-card-unit decision is **resolved** (see Decisions); the **concrete schema is drafted and reconciled to the live Mode A source** (see "The unified fact-base schema"); the four modeling sub-questions are **resolved against the canonical ground** (not open). Grounding revealed Mode A is *already* the canonical identity shape, so **item 2's executable-now work is this spec reconciliation, not a blueprint rewrite** — the structural generalizations and B/C/D authoring are deferred to their real triggers (`target → plan.*` rides the item-4 storage split). **The first such trigger is now firing: the Mode-C build (2026-06-23) activates the C-exercised generalizations — `tax{}`, `existing_portfolio`, `traits`, the `plan` investment fields; `off_title_parties[]`/`visa_class`/off-title `funder{}` were deferred to Mode B, their first-exercising instance. See ["Mode-C activation"](#mode-c-activation--which-generalizations-build-now-2026-06-23) below.** **The second trigger is now firing: the Mode-B build (2026-06-28) activates the remaining generalizations — `off_title_parties[]`, off-title `funder{}`, `visa_class`, and the F14 `firb_required_any` publish — plus the Mode-A `non_buying_partner → off_title_parties[]` retrofit; the VN-side *regulated* `funder{}` content (SBV/PDP/VN tax) is a labelled placeholder per the AU-side-full/VN-side-placeholder scope. See ["Mode-B activation"](#mode-b-activation--the-remaining-generalizations-build-now-2026-06-28) below.** With both triggers fired, the *built / gated / populated* surface equals the full canonical schema; what stays deferred by design is the table-layout sub-question (to the PG-schema step) and **Mode D** blueprint adoption (content only — D reuses B's `funder{}` + C's `existing_portfolio`, adding no new identity generalization). **Mode D shipped build-complete 2026-07-04. A third trigger is now firing: Mode-E's P0 (2026-07-05) adds `plan.buyer_stage` — the first genuinely new *derivation-axis* addition since Decision 1's two axes (mode was previously believed a closed 2×2); see ["Mode is derived — three axes"](#mode-is-derived--three-axes-buyer_stage-added-2026-07-05-mode-e-p0) below and [`mode-e-wedge.md`](mode-e-wedge.md) for the full scoping decision.**

**Why this exists.** While grounding the cross-mode data flow (the §0 pass in [`grounding-checklist.md`](../design/archive/grounding-checklist.md)), a single root cause surfaced under a string of seemingly-separate bugs. This doc records the finding, why the *strategy* (not taste) adjudicates it, and the direction — so the analysis is an artifact to decide against, not something reassembled from memory each time.

Read alongside [`structure-map.md`](structure-map.md), the hub that maps all the structures and how they relate; this doc is about where one part of it (the buyer fact base) should go.

---

## The finding in one line

The data **flow** is sound and should stay. The data **model** forks the buyer's fact shape per mode, and that fork — at the *identity/profile* layer specifically — is an initial scaffold that fights the strategy's central moat and is the root of every cross-mode bug in this workstream.

## What is actually forked

Each of the four blueprints re-declares the buyer's facts as a **different outcome type**:

| Mode | buyer_profile outcome `type` | FIRB facts published | `applicants[]`? |
|---|---|---|---|
| A | `profile` | `firb_required_any` (+ per-applicant `firb_required` in `applicants[]`) | yes |
| B | `profile_foreign` | flat `firb_required` (always true) | no (`au_member.visa_class → firb_classification`) |
| C | `investor_profile_summary` | flat `citizenship_status` | no |
| D | `investor_profile_foreign_summary` | flat `firb_required` (hard-set foreign) | no (`co_investor_count`) |

The **property** layer is *not* forked — all four modes run `property_assessment → property_fit`, one shared shape. So the fork is asymmetric: **shared at the property layer, forked at the identity layer.** That asymmetry is the whole diagnosis.

## Why this is the root of the bugs

Every problem in this workstream traces to "the buyer's facts have four shapes":

- `firb_required` vs `firb_required_any` (F14) — a shared FIRB KB doc can't name one field that exists in all anchoring modes, because each mode publishes the fact under a different name/shape.
- `profile.*` vs `profile_foreign.*` — the namespace-addressing question only exists because the outcome `type` differs per mode.
- "Does this rule resolve in mode X?" — the compiler-gate semantics we had to invent (skip modes lacking the namespace) is entirely a consequence of the fork.

Unify the identity fact shape and this class of bug is **structurally absent**, not patched.

## Why the strategy adjudicates it (not preference)

Three independent lines in the settled docs all require a *single, continuous, mode-independent* buyer fact model:

1. **Lifecycle continuity is the central moat — and it requires one fact model.** [`03-strategy.md`](../03-strategy.md) §8.3 ("persistent agent from student → PR → FHB → investor, a 10–25 year relationship") and §10.5. The UX makes it concrete: [`04-ux-model.md`](../04-ux-model.md) §13.2 and the An Tran journey (§13.5, Day 365) — *"Mode auto-switches from B → C… data accumulates across modes."* The **same person** is Mode B (foreign student, family-funded) then Mode C (PR investor). Four siloed profile types structurally **cannot** represent "An over time" — which is the moat itself.

2. **Shared schema was always the stated intent.** [`03-strategy.md`](../03-strategy.md) §10: *"All four segments share the same Layer 1 KB, Layer 2 schema, Layer 3 reasoning infrastructure. What changes per segment is which flows are active and which user-state fields matter."* The intent was **one fact model, mode-varying pipelines.** The implementation forked the fact model *as well as* the pipeline; only the pipeline needed forking.

3. **Both data moats are cross-mode analytics over buyer facts.** Demand aggregation (§8.3) and policy intelligence (§8.6 — case-level friction, scheme combinations actually used, cognitive-gap data) join across modes. Four divergent schemas make the asset four datasets that don't join; one fact model makes it the asset the strategy claims.

## What stays (the flow mechanics are right)

Nothing here argues against the pipeline machinery. Several pieces are strategy-required and should not move:

- **Resolver/agent split** ⟸ the ASIC "computed, not advised" line ([`03-strategy.md`](../03-strategy.md) §9.1.4, §9.3).
- **Slug-based KB + build-time compiler + snapshot-on-fill** ⟸ "scheme rules change constantly" (§9.1.3) + reproducible audit trail. This *is* the "evolve intelligently" engine.
- **Outcomes-carry-facts-not-verdicts + one-access-path** ⟸ bounded agent, clean audit.
- **Mode-specific pipelines** ⟸ the genuine ~50% structural difference (architecture §11.9 "Four blueprints"). Pipelines *should* vary by mode; they just shouldn't each redefine the buyer's fact shape.

## Direction (to decide, then design concretely)

1. **One canonical, mode-independent buyer fact model.** The registry's `profile.*` becomes a single schema holding every fact any mode can need (citizenship/visa status, `applicants[]`, cross-border family funder, co-investors, intent, funds provenance). A mode **populates a subset**; it does not redefine the shape. `firb_required` is one fact, derived uniformly regardless of which input fields a mode collects.
2. **Pipelines stay mode-specific** — which components run, and in what order, still varies by mode. They **read the one fact model**.
3. **Mode is a derived view** over the fact model (FIRB status + intent). A mode-switch re-runs a different pipeline over the **same accumulating facts** — exactly [`04-ux-model.md`](../04-ux-model.md) §13.2's "automatic based on user-state attributes."
4. **KB rules bind to the one namespace.** The addressing convention largely dissolves: one `profile.*`, no per-mode type divergence; a rule is mode-scoped only where the *fact* is genuinely mode-specific.

## Wedge 1 staging — this does not expand Wedge 1 scope

Wedge 1 is Mode A only (4–6 weeks). The move is **design the seam now, populate later**: author Mode A's identity layer as *"the shared fact model, Mode-A subset filled,"* not *"Mode A's private `profile` type."* Build nothing for B/C/D. The only cost now is shaping Mode A's profile so B/C/D **populate** it later rather than **fork** it — the difference between forward-compatible and re-paying this debt at Wedge 2.

## Decisions

### 1. Plan-card unit — RESOLVED: do not key on mode

`per (user × mode)` is rejected. A partition key must be **stable** and **single-valued**; the scenario set ([`../blueprints/scenarios.md`](../blueprints/scenarios.md)) proves mode is neither:

- **Mutable** (breaks stability, and the lifecycle moat): the mode-defining facts change inside a live plan — S3 (PR granted mid-plan, `citizenship_status` flips, FIRB re-derives), S22/S23 (applicant set changes), and An's B→C (UX §13.5). Keying on mode would orphan the accumulated fact base at every mode boundary — severing the 10–25-year continuity that is the moat (strategy §8.3).
- **Multi-valued** (breaks single-valuedness): S1 (citizen + 482 co-buyer) and S4 (citizen + foreign parent on title) are **one plan, two modes** — the domestic applicant runs Mode A while the foreign applicant's interest routes to the FIRB path. There is no single mode to key on.

The resolved schema is three layers, mode derived at the top:

1. **User / household fact base** — persistent, accumulating, **mode-independent**: the applicant set (per-applicant facts — F1/F2/F3), the non-buying partner (F4), household financials, documents, decision trail, FIRB approvals. This *is* the unified fact model above and the lifecycle-continuity anchor.
2. **Plan (purchase journey)** — keyed by *journey*, **not** mode: an applicant subset + target (state/price/zone, mutable — S24) + zero-or-more property addenda. **1..N per user** over a lifetime (first home → investment = two journeys over one fact base); Wedge 1 populates exactly one.
3. **Mode** — *derived* per plan **and** per applicant, re-computed as facts change. A label on the view, never a row key.

This satisfies both grounding factors and leaves the COVERED scenario core (scheme stacking, LVR, strata, settlement) untouched — they read the fact base exactly as today.

**Deferred sub-question (to the PG-schema step):** whether the user fact base and the journey-keyed plan are **one table with a journey discriminator** or **two tables** (fact base ⟵ plans by FK). Both express the decision above; it's a normalisation call made when the migration is written.

### 2. Sequencing — design-first

We are on path: work the unified-fact-model design to a concrete shape *before* further KB/blueprint edits, treating the four current blueprints as the thing being refactored. KB/blueprint edits stay parked until the unification is planned (see below).

## The unified fact-base schema (concrete design)

This realizes the Direction above as a concrete shape — item 1 of [`../grounding-checklist.md`](../design/archive/grounding-checklist.md). It is what the four blueprints' identity layer refactors onto (item 2) and what the PG migration keys against (item 4). Wedge 1 authors **Mode A's subset of this one type**, not a Mode-A-private `profile`.

Grounded in the live identity outcomes of all four blueprints (re-read at design time): Mode A `profile` (the rich one — `applicants[]`, `non_buying_partner`, `firb_required_any`), Mode B `profile_foreign` (`au_member` scalar + `vn_family_member` funder), Mode C `investor_profile_summary` (portfolio + `marginal_tax_rate`), Mode D `investor_profile_foreign_summary` (global portfolio + `vn_marginal_tax_rate`). Every field below traces to one of those.

**This schema is the persistent fact base (the item-4 storage shape), not a blueprint outcome.** Each mode's `buyer_profile` *outcome* is a flatter **projection** of it; Mode A's validated `profile` outcome ([`../blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md) §1) is the **reference projection** and is **already** the canonical identity shape — `applicants[].citizenship_status → applicant.firb_required → profile.firb_required_any`, the scalar `non_buying_partner`, the F1–F12 facts — validated 45/45 and wired into the KB (e.g. `status-determination.md`, `established-dwelling-ban.md`). So item 2 does **not** churn Mode A, and the canonical field names are **Mode A's** (e.g. `citizenship_status`, not a fresh `residency_status`): renaming would churn a regulated graph for zero Mode-A gain. The structural generalizations below that go *beyond* Mode A's current outcome — `off_title_parties[]` (array vs Mode A's scalar `non_buying_partner`), `tax{}` (object vs flat `tax_residency`), the `household_financials`/`derived`/`traits` grouping, `existing_portfolio` — are the **canonical target**; Mode A keeps filling its validated subset. **As of the Mode-C build (2026-06-23) the subset Mode C exercises — `tax{}`, `existing_portfolio`, `traits`, and the `plan` investment fields — moves from canonical-target to active (see ["Mode-C activation"](#mode-c-activation--which-generalizations-build-now-2026-06-23) below); `off_title_parties[]`/`visa_class`/off-title `funder{}` stay deferred to Mode B, their first-exercising instance.** Mode-A's own restructure (its scalar→array `non_buying_partner`) stays deferred under "build nothing until the trigger fires." Two consequences ride later items, not this one: `target → plan.*` rides the **item-4** storage split (where the plan/profile partition is actually built); B/D adopting the canonical names rides their authoring (the cross-border/FIRB modes) — and *that* is what closes F14 (`established-dwelling-ban` already reads the aggregate `profile.firb_required_any` correctly, confirmed live; the fork to fix is B/D publishing it, not the KB doc).

### Three layers, concretely (Decision 1, made buildable)

| Layer | Lifetime | Keyed by | Holds |
|---|---|---|---|
| `profile` | persistent, accumulates over the user's life | user / household | the buyer facts — **one** mode-independent shape |
| `plan` | per purchase journey (1..N) | journey id | what *this* purchase is: applicant subset, intent, target, addenda |
| `mode` | derived, recomputed as facts change | — (**never** a key) | a label = (firb axis × intent axis) |

### `profile` — one canonical type, every mode a subset

```jsonc
profile {                                  // ONE type, all modes; a mode fills a subset, never redefines the shape
  applicants: [ {                          // 1..N — the eligibility/FIRB fact surface
                                           //   (unifies A.applicants[], B.au_member, C/D scalar identity + co_investor_count)
    role,                                  // primary | co_buyer | co_investor
    citizenship_status,                    // citizen | permanent_resident | temporary_resident | non_resident
                                           //   ← the canonical FIRB axis. ADOPTS Mode A's validated field name (already wired
                                           //     into status-determination + the KB, validated 45/45) — NOT a fresh
                                           //     `residency_status`. B/C/D adopt THIS (was B.visa_class class, C.citizenship_status,
                                           //     D.firb_classification).
    visa_class,                            // B-add: finer detail when temporary_resident (Mode B lender treatment + FIRB nuance);
                                           //     null otherwise. Mode A's surface does not collect it yet.
    firb_required,                         // DERIVED per applicant from residency_status (+ visa_class) — the per-person fact
    age,
    owner_occupier_intent,                 // this person intends to live there (A, B)
    ownership_history { ever_owned_au_property, ever_owned_and_occupied_residence,
                        years_since_last_au_property_interest, prior_overseas_property_ownership,
                        prior_fhss_release, currently_owns_property },   // A today; B/C/D fill the subset their schemes test
    tax { residency_for_tax, marginal_rate, jurisdiction }              // unifies A.tax_residency, C.marginal_tax_rate (AU),
                                                                        //   D.vn_marginal_tax_rate (VN); jurisdiction disambiguates
  } ],
  off_title_parties: [ {                   // 0..N — people linked to the purchase but NOT on title
                                           //   (unifies A.non_buying_partner + B.vn_family_member)
    relationship,                          // spouse | de_facto | parent | sibling | family_pool | other
    counts_for_couple_as_one,              // true → ownership folds into the all-applicants eligibility test (F4)
    ownership_history { … },               // populated when counts_for_couple_as_one
    funder { expected_to_fund, residence_country, contribution_capacity_aud }   // populated when this party funds (B VN parent, D family pool)
  } ],
  household_financials {
    income { assessable_income, foreign_sourced_component, foreign_income_currency, income_stability },  // A; B au-side; D vn-side→AUD-equiv
    savings_and_deposit { cash_savings, genuine_savings_evidence_months, family_gift_or_loan_amount,
                          fhss_contributions_to_date,
                          funds_provenance { deposit_source, cross_border_transfer, transfer_channel } },
    debts { hecs_balance, credit_card_limits_total, personal_loans_balance, car_loan_balance, buy_now_pay_later_balance },
    existing_portfolio { ppor_owned, ppor_estimated_equity, investment_count, investment_value,
                         investment_loans, net_yield_estimate }         // C/D; A fills ppor_* only for a rentvestor
  },
  traits {                                 // persistent dispositions that ACCUMULATE across journeys (per-journey posture lives in `plan`)
    experience_level                       // C/D — monotonic across journeys (first → experienced)
  },
  derived {                                // household-level FACTS (not verdicts), recomputed on any applicant change
    applicant_count,
    firb_required_any,                     // TRUE iff ANY applicant.firb_required — the SINGLE household FIRB fact, ALL modes
                                           //   (B/D = true definitionally). This is the F14 fix.
    new_build_only_constraint,             // property-INDEPENDENT corollary of foreign + ban-in-force
                                           //   (the per-property verdict established_property_eligible lives in firb_workflow — sub-question 3)
    approx_borrowing_capacity,             // owner-occ (A/B) or investment-loan (C/D) flavoured by plan.intent
    deposit_ready_for_purchase_amount,
    ppor_equity_available_for_leverage,    // C/D
    available_capital_aud_equivalent       // D
  },
  narrative { key_constraints, key_strengths }
}
```

### `plan` — the purchase journey (what moves OUT of `profile`)

Everything *about a specific purchase* — therefore mutable per journey — moves here. Today Mode A's `profile` outcome conflates `target_price_range` / `target_zone` into the persistent profile; under Decision 1 (target is per-journey, mutable — scenario S24) they belong to the plan:

```jsonc
plan {                                     // one purchase journey; 1..N per profile (first home → later investment = two plans, one fact base)
  applicant_subset,                        // which profile.applicants are on THIS purchase
  intent,                                  // owner_occupier | investment   ← the intent axis of mode
  buyer_stage,                             // first_home | next_home ← the THIRD mode axis (Mode-E, 2026-07-05).
                                           //   Meaningful only when intent=owner_occupier — investment has no
                                           //   first-home concept, C/D ignore it. SELF-DECLARED at onboarding,
                                           //   NEVER derived from ownership_history: a repeat buyer mis-flagged
                                           //   first_home would wrongly assert FHG/FHSS entitlement (misadvice
                                           //   risk, mode-e-wedge.md).
  intended_occupancy_use,                  // sole_occupier | partial_rental | granny_flat | not_occupied (F12) — only when intent=owner_occupier
  target { price_range, zone, state, timeline },                        // MOVED out of profile (mutable per journey — S24)
  risk_tolerance { negative_gearing_comfort, vacancy_months_comfort,    // per-journey posture (sub-question 2); was C/D investor_profile params
                   leverage_comfort_lvr, currency_volatility_concern },
  investment_goals { primary, secondary, intended_hold_period_years, exit_strategy },   // only when intent=investment (was C/D params)
  property_addenda: [ … ]                  // 0..N attached properties (unchanged)

}
```

### Mode is derived — three axes (buyer_stage added 2026-07-05, Mode-E P0)

```
firb_axis   = profile.derived.firb_required_any   →  domestic | foreign    (COMPOSITIONAL: per-applicant firb_required picks each person's sub-path)
intent_axis = plan.intent                         →  owner_occupier | investment  (per-plan)
stage_axis  = plan.buyer_stage                     →  first_home | next_home      (per-plan; meaningful ONLY when
                                                       intent_axis = owner_occupier — investment has no
                                                       first-home concept, C/D read it as n/a)

                    owner_occupier                          investment
              first_home      next_home
  domestic         A              E                             C
  foreign           B      unsupported_combination               D
                           (fails closed — see
                            mode-e-wedge.md scoping
                            decision #4; blueprint_for/3
                            fails closed at the ENGINE
                            layer too as of mode-e-
                            wedge.md P5 — the shell
                            gate is now a backstop on
                            top of this, not the only
                            control)
```

A missing/malformed `buyer_stage` for `owner_occupier` is a FOURTH failure mode, distinct from
the table above (which assumes `stage_axis` resolved to one of its two values): `blueprint_for/3`
fails closed on it too (`{error, missing_buyer_stage}`), rather than guessing either value —
mode-e-wedge.md P5 found that a silent default (in either direction) creates its own misadvice-
adjacent risk, not just first_home defaulting does (see that doc's P5 phase note for the
reasoning). `intent = investment` is unaffected — the axis is genuinely irrelevant there, so an
absent/malformed `buyer_stage` for an investor onboarding is not an error.

Adding `stage_axis` does not touch the existing 2×2 for `intent_axis = investment` (C/D are unchanged — the axis is simply irrelevant there); it only subdivides the `domestic × owner_occupier` and `foreign × owner_occupier` cells that used to be single-valued. `domestic × owner_occupier × first_home` = A (unchanged); `domestic × owner_occupier × next_home` = **E** (new); `foreign × owner_occupier × first_home` = B (unchanged); `foreign × owner_occupier × next_home` = out of scope, fails closed (new — see mode-e-wedge.md).

A **mixed-status plan** (S1 citizen + 482 partner; S4 citizen + foreign parent on title) is exactly "one plan, two modes": `intent_axis` is fixed for the plan (e.g. `fhb`), while `firb_axis` varies **by applicant** — the domestic applicant runs the A sub-path, the foreign applicant's interest routes to the B (FIRB) sub-path. That is why mode cannot be a row key (it is multi-valued here) and the partition is `applicants[]` + journey instead.

### How each mode populates the one schema

| Branch | A (dom FHB) | B (foreign FHB) | C (dom investor) | D (foreign investor) | E (dom next-home)† |
|---|---|---|---|---|---|
| `applicants[]` | 1..N, mixed status | AU member (1) | 1..N citizen/PR | 1..N foreign | 1..N citizen/PR |
| `off_title_parties[]` | non-buying partner | VN funder | — | family pool | non-buying partner |
| `household_financials.income` | ✓ | au-side | ✓ | vn-side → AUD | ✓ |
| `…existing_portfolio` | ppor only (rentvestor) | — | ✓ | ✓ global | ✓ — the seller-side PPOR being sold now |
| `traits` | — | — | ✓ | ✓ | — |
| `derived.firb_required_any` | computed | = true | = false | = true | = false |
| `derived.new_build_only_constraint` | (false) | = true | (false) | = true | (false) |
| `plan.intent` | owner_occupier | owner_occupier / future-PPOR | investment | investment | owner_occupier |
| `plan.buyer_stage` | first_home | first_home | n/a | n/a | **next_home** |
| `plan.risk_tolerance` | — | — | ✓ | ✓ | — |
| `plan.investment_goals` | — | — | ✓ | ✓ | — |

† **E's `existing_portfolio` row is the one genuinely new content need** — not just activating the existing `ppor_owned`/`ppor_estimated_equity` slots (A already can for a rentvestor), but computing *net sale proceeds of that PPOR being sold now* (sale price − loan payout − selling costs − CGT via the main-residence exemption) as a new `cash_position` input. Not yet built — mode-e-wedge.md P1/P2. All other E cells are P0-designed only (this axis + table), pending P1–P5.

### What this collapses (the bug class that becomes structurally absent)

- **F14** — one `derived.firb_required_any`, present in every mode (B/D = true definitionally). `kb.firb.established-dwelling-ban` reads it uniformly; the fork that made the field un-nameable across modes is gone.
- **`profile.*` vs `profile_foreign.*`** — one type, one read namespace. The §11.9 "canonical slot alias" is simply `profile.*`; the per-mode addressing question dissolves.
- **`au_member` / `co_investor_count` / `buying_alone`** — degenerate views of `applicants[]` (`au_member` = the lone AU applicant; `co_investor_count` = length − 1; `buying_alone` = count == 1).
- **`non_buying_partner` + `vn_family_member`** — one role-tagged `off_title_parties[]`.
- **`marginal_tax_rate` (C) + `vn_marginal_tax_rate` (D) + `tax_residency` (A)** — per-applicant `tax{}` with `jurisdiction`.

### Modeling sub-questions — resolved against the canonical ground

These are not preference calls. The canonical ground for the project's design decisions, in priority: **strategy** (`../03-strategy.md`) → **architecture principles + §11.9 component-flow** (outcomes-carry-facts-not-verdicts, one-access-path, components-read-outcomes-not-params, DAG ordering) → **the designed scenarios** (`../blueprints/scenarios.md`) → **the live blueprints** (the consuming components). Each sub-question is adjudicated by that corpus, not by taste.

1. **`off_title_parties[]` merge → MERGE.** Ground: *one-access-path*. A funding non-buying spouse is one person carrying two role flags; two separate fields would split that person across two records and break one-access-path. The schema stays one array; each consumer filters by the flag it reads (`eligibility` ← `counts_for_couple_as_one`; `cross_border_funding` ← `funder`).
2. **`traits` placement → SPLIT (per Decision-1's per-journey test).** `experience_level` accumulates monotonically across journeys → stays in `profile`. `risk_tolerance` is a per-journey posture (cautious first home vs aggressive later investment) → moves to `plan` alongside `investment_goals`. `tax.marginal_rate` is assessed per person → stays per-applicant in `applicants[]`. *(This corrects the schema above, which provisionally placed `risk_tolerance` under `profile.traits`.)*
3. **`established_property_eligible` → VERDICT; moves to `firb_workflow` (not a `profile` field).** Two grounds converge. (a) *Outcomes-carry-facts-not-verdicts* — precedent in this very file: Mode A already **removed `fhg_eligible_basic`** from its `profile` outcome ("a scheme verdict; now computed in `eligibility`", `fhb-domestic-au.md` line 221); `established_property_eligible` in B/D is the identical category error. (b) *DAG ordering* — it depends on `property_fit.property_type`, but `profile` runs **before** `property_assessment`, so it cannot be a profile field at all. `profile.derived` keeps only the property-independent status facts (`firb_required_any`, `new_build_only_constraint`); the per-property determination is produced by `firb_workflow` (reads `firb_required_any` + `property_fit.property_type` + `kb.firb.established-dwelling-ban`). *(This corrects the schema above, which provisionally kept `established_property_eligible` under `profile.derived`.)*
4. **`target` profile→plan → not an open fork.** Already settled by Decision 1 (per-journey, mutable — S24). Listed here only to mark it as a *consequence* executed in the item-2 refactor + item-4 migration, not a decision still to make.

### Wedge-1 staging (no scope expansion)

Mode A is **already** authored as this canonical identity shape ([`../blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md) §1, validated 45/45): `applicants[]` with `citizenship_status`/`firb_required`, the scalar `non_buying_partner`, household income/savings/debts, `derived.firb_required_any`, `new_build_only_constraint` (= false for Mode A), `narrative`. So Wedge 1 needs **no Mode-A restructure**. The only forward-compat cost *now* is a **spec** one: recording in this doc that the canonical fact base generalizes Mode A's scalars (`non_buying_partner → off_title_parties[]`, `tax_residency → tax{}`) and that `target` is a `plan` attribute — so B/C/D **populate** the shared shape later, and item 4 partitions storage correctly, rather than re-forking at Wedge 2. Build nothing for B/C/D now.

## Mode-C activation — which generalizations build now (2026-06-23)

The build order ([`wedge-build-sequence.md`](wedge-build-sequence.md)) puts **Mode C first** after the unification, so building it fires the first real trigger on this schema. Not all of the canonical generalizations activate at once — each rides its **first-exercising instance**:

| Generalization | First exercised by | Status as of 2026-06-23 |
|---|---|---|
| `tax{ residency_for_tax, marginal_rate, jurisdiction }` | C (AU `marginal_rate`) | **active** |
| `household_financials.existing_portfolio{}` | C (investor portfolio) | **active** |
| `traits.experience_level` | C | **active** |
| `plan.intent=investment` + `risk_tolerance` + `investment_goals` | C | **active** |
| `off_title_parties[]` (array vs A's scalar `non_buying_partner`) | **B** (VN funder) | deferred to Mode B |
| `visa_class`, off-title `funder{}`, cross-border funding slots | **B** | deferred to Mode B |

**Why not the full schema now (foundation-first, correctly bound).** The foundation is the **shared mechanism A and C both ride** — one `profile.*` fact base, mode derived, `derived.firb_required_any` as the single aggregate, the read-namespace convention — *not* the union of every mode's fields. A field only a future mode populates (`off_title_parties[]`) is that wedge's **content**, not foundation; building it now would harden the cross-border `funder{}` shape with **zero exercising instance** (the shape Mode-B authoring reveals) and add **semantic gates with nothing to gate**. And because the fact base is `facts_jsonb` (the item-5 migration is done), **deferring B/D fields costs no migration** — new keys, not a schema change. So the asymmetry runs one way: deferral ≈ free, early-build ≈ speculative. Build the mechanism fully; let each content slot ride its first-exercising wedge (honest-deferral; prove-generality — A + C are the two unlike instances that validate the activated subset).

**The one foundation-touching piece in the B set.** Generalizing A's scalar `non_buying_partner → off_title_parties[]` touches A's eligibility *couple-as-one* read, so it is mechanism-adjacent — but the retrofit is cheap and jsonb-additive (A's single party = the array's head element) and is done **when Mode B lands**, not pre-emptively. Nothing else in the B set touches any A/C path.

**Consequence for the build.** The contract docs ([`engine-contract.md`](engine-contract.md) §9.1, the [`architecture.md`](architecture.md) §11.9 read-namespace convention) and the compiler's **semantic** gates extend for the **C-activated** fields only; the Mode-C blueprint ([`../blueprints/investor-domestic-au.md`](../blueprints/investor-domestic-au.md)) + investor KB (`kb.tax.*` / `kb.investor.*`) author against this activated subset. The schema **text** above stays the complete canonical target; only the *built / gated / populated* surface tracks the instances we actually have.

## Mode-B activation — the remaining generalizations build now (2026-06-28)

The build order ([`wedge-build-sequence.md`](wedge-build-sequence.md)) puts **Mode B** next after Mode C, so building it fires the **second and final** trigger on this schema: the slots the Mode-C section explicitly deferred to "Mode B, its first-exercising instance." Mode B (Vietnam-parent-funded / AU-temp-resident foreign-person FHB) is exactly that instance — its `buyer_profile` carries a visa-classed AU applicant + an off-title VN funder. With Mode B activated, every canonical generalization has a real exerciser; nothing in the schema text above remains canonical-target-only.

| Generalization | First exercised by | Status as of 2026-06-28 |
|---|---|---|
| `off_title_parties[]` (array vs A's scalar `non_buying_partner`) | B (VN funder, role=parent/family_pool) | **active** |
| `off_title_parties[].funder{ expected_to_fund, residence_country, contribution_capacity_aud }` | B (the cross-border VN funder) | **active** |
| `applicants[].visa_class` (finer detail when `temporary_resident`) | B (485/student/482 lender + FIRB nuance) | **active** |
| `derived.firb_required_any` published by a foreign mode (= true definitionally) — **the F14 close** | B (then D) | **active** |
| `off_title_parties[].funder{}` VN-side **regulated** content (SBV/PDP/VN tax) | B — but **labelled placeholder** (see below) | **placeholder** |

**Why these activate now, correctly bound.** Mode B is the first design where a person *linked to the purchase but not on title* both (a) folds into the couple-as-one eligibility test (the existing `non_buying_partner` role) **and** (b) funds across a border (the new `funder{}` role). The one-access-path resolution in sub-question 1 (MERGE → one role-tagged `off_title_parties[]`, each consumer filters by the flag it reads) is what makes the array honest here: `eligibility` reads `counts_for_couple_as_one`, `family_context` / `cross_border_funding` read `funder`. Building the array now is no longer speculative — Mode B is the exercising instance that the Mode-C section said it needed. `visa_class` and the F14 publish-side close likewise have their first real consumer (non-resident lending + the household FIRB aggregate that `established-dwelling-ban` already reads).

**The AU-side / VN-side split (Son, 2026-06-28).** The `funder{}` *shape* is AU-side-buildable in full (who funds, how much in AUD-equivalent, from where) — that is the active row. What is **labelled-placeholder**, not built, is the VN-side **regulated** content the funder triggers: SBV capital-control thresholds, VN PDP cross-border-data rules, VN-side parent tax. Rationale: a Vietnam-parent-funded purchase is, to the buyer, an *Australian* property problem; the VN remittance side is theirs to run, and authoring its regulated detail needs VN legal counsel (strategy §9). So the **structure** (the `funder{}` slots, the `cross_border_funding` component's VN block) is built now; the **regulated VN datum** is a placeholder (⚠ banner + `is_placeholder` + named re-ground obligation + bilingual buyer-pointer copy), per [`mode-b-wedge.md`](mode-b-wedge.md) and the [[honest-deferral-not-rug]] / [[kb-doc-authoring]] placeholder discipline. This dissolves Mode B's launch-gate: the only counsel-gated content was the VN side, now deferred honestly.

**The one foundation-touching piece — the Mode-A retrofit, done now.** Generalizing A's scalar `non_buying_partner → off_title_parties[]` touches A's `eligibility` couple-as-one read, so it is mechanism-adjacent. The Mode-C section deferred it to "when Mode B lands"; **that is now** (Son, 2026-06-28: retrofit Mode A now rather than leave two shapes for one concept — the fork the unification exists to remove). The retrofit is jsonb-additive (A's single party = the array's head element; no migration) and re-verifies A's couple-as-one read against the array head. Mode A keeps filling exactly one party; only the shape generalizes.

**How the retrofit lands without churning the live regulated KB (the (B) decision, Son 2026-06-28).** The couple-as-one read could ride a *filtered array predicate*, but that would add a role-filtered quantifier to the regulated KB predicate engine for a scenario **no planned mode exercises** (B/D replace `eligibility` with `firb_workflow`; C is an investor — only Mode A runs the couple-as-one gate). Instead the read binds **per consumer**: the **funder** subset is N-valued → read directly off `off_title_parties[]` by its Erlang consumers (Mode B, P2); the **couple-as-one** subset is **dyadic (≤1 by domain law — a spouse)** → the producer (`fh_engine_fill:couple_as_one_view/1`) filters the array by `counts_for_couple_as_one`, **enforces ≤1 fail-closed**, and projects the flat `profile.non_buying_partner.*` read-model the existing KB criteria read **unchanged**. So the array is the sole fact base (the A-scalar fork is gone), the role-flag filter lives in the resolver where filtering is trivial at any cardinality, and the KB predicate language + the 4 NSW/VIC couple-as-one criteria + the compiler's registry projection stay **byte-stable** — `non_buying_partner.*` is a *derived view* of the array, not a second fact shape. Detail: [`registry-projection.md`](registry-projection.md) "Mode-B activation update", architecture §11.9 `off_title.*`.

**Consequence for the build.** The contract docs (engine-contract §9.1, the architecture §11.9 read convention) and the compiler's **semantic** gates extend for the **B-activated** fields (`off_title_parties[]` + `funder{}` + `visa_class` + the F14 publish), Mode-A retrofit included; the Mode-B blueprint ([`../blueprints/fhb-foreign-au.md`](../blueprints/fhb-foreign-au.md)) + AU-side KB author against them, with the VN-side anchors as placeholders. After this, the *built / gated / populated* surface equals the full canonical schema text above — Mode D adds no new identity-layer generalization (it reuses B's `funder{}` family-pool + C's `existing_portfolio`), only content.

## Relationship to parked work

The two edits parked earlier — pinning the read-namespace convention in architecture §11.9, and the `established-dwelling-ban` FIRB read — are **downstream of decision 1**, now resolved, and grounding in the live source corrects what they are:

- **Read-namespace convention.** Under the unified fact base there is one `profile.*` namespace across modes, so the convention is "read by the canonical (mode-independent) slot alias." This is a §11.9/`structure-map.md` edit, and it rides Wedge-2 (when B/C/D actually adopt the shape and a second namespace would otherwise appear); for Mode A alone there is only ever `profile.*`, so nothing to pin yet.
- **`established-dwelling-ban` read — no revert needed.** The parked note assumed it should read flat `profile.firb_required`; the live predicate already reads the aggregate `profile.firb_required_any` (`established-dwelling-ban.md` line 74), which is **correct** under the unified design (the household-level FIRB fact). There is no Mode-A edit here. The only fix this anchor needs is on the **B/D publish side** (they currently emit flat `firb_required`; they must publish `firb_required_any`) — Wedge-2 authoring, the F14 close.

## Per-override storage mapping — the simulate/refine seam

[`engine-contract.md`](engine-contract.md) §10.2 (the saved-scenario commit) and [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4.3 defer the per-override profile-vs-card mapping here, because *where a saved override lands* is a fact-model question, not a contract one. The structural overrides the base simulate/refine accepts map by Decision 1's partition:

| Override | Canonical layer | Persists on commit to | Why |
|---|---|---|---|
| `target_price` (→ `target.price_range`) | **`plan`** | the **card** (plan-target overlay) | `target.*` is per-journey, mutable (Decision 1, sub-question 4 — S24); a profile-level write leaks across a profile's other journeys |
| `state` (→ `target.state`, the projection basis) | **`plan`** | the **card** (plan-target overlay) | same — the projection state is a property of *this* journey's target, not the household |
| `target_sal` / `target_zone` (the projection pin) | **`plan`** | the **card** (plan-target overlay) | same; and a `state` save **strips** these (precedence `sal` > `zone` > `state` — an explicit state save supersedes the pin, [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4.3) |
| `property_type` | per-property addendum | n/a at base | no property attached at base → moves zero base figures; a Phase-B dimension (engine-contract §10.1), rejected by base simulate |

So **every base override is a `plan` fact** — they all persist on the card via the plan-target overlay, none touches `profiles`. This is the first concrete consumer of item-4's plan/profile storage split: the overlay column **is** `plan.target` realized for Wedge 1, additive over the 1:1 shape (an empty overlay = today's behaviour). The persistent `profile` (applicants, household financials, `derived`) is never written by a base refine — only the journey's target moves. The earlier note in engine-contract §10.2 that called `target_price_range` a *profile fact* reflected the legacy conflation (target lived in `profiles.facts_jsonb.onboarding` only because `profile:card` was 1:1); it is corrected to a *plan* fact there.
