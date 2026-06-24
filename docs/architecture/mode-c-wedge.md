# Mode-C wedge — build plan + progress tracker

**Status: planning (authoring not started). Opened 2026-06-23.** This doc is the durable plan
*and* the task tracker for the Mode-C (Vietnamese-AU domestic investor) wedge. The Claude Code
Task list is ephemeral (it does not survive compaction); this file is the source of truth for
"what's left." The grounding-checklist carries a one-line pointer here.

Anchor / upstream: [`fact-model-unification.md`](fact-model-unification.md) ("Mode-C activation"),
[`wedge-build-sequence.md`](wedge-build-sequence.md) (C-before-B by foundationality),
[`engine-contract.md`](engine-contract.md) §9.1, [`architecture.md`](architecture.md) §11.9.
Conforming artifact: [`../blueprints/investor-domestic-au.md`](../blueprints/investor-domestic-au.md).

## What's already done (the unification unit, committed)

The identity layer is unified: the investor blueprint's identity component was conformed to the
canonical `profile` outcome; the engine **resolver is mode-generic** (ingests any blueprint's
rules unchanged); the **disposition resolver mechanism is built and live** (`fh_engine_disposition`,
310 LOC, wired into the turn DAG + Layer-2 gate). Structural compiler gates are green for the
investor blueprint; the artifact is byte-identical (investor still out-of-scope). So this wedge is
**content + activation**, not foundation-laying.

## The one load-bearing design concern — the ASIC / tax-advice line

The tax cluster is the most regulated content in the entire product. Recommending an ownership
**entity** (trust vs company vs SMSF), or asserting that negative gearing "is attractive," borders
on tax/financial advice (AFSL/ACL territory; personal liability is real). Discipline for the whole
wedge, tax cluster first:

- **Decision-support only.** Surface options + considerations + "consult a licensed tax adviser."
  Never "set up a trust" / "you should negatively gear."
- **Regulated figures removed from the LLM's reach.** Tax brackets, the 50% CGT discount, land-tax
  thresholds, depreciation rates are KB-grounded, resolver-computed, and verified against the
  primary source (ATO, state revenue offices). See [`outcome-conformance.md`](outcome-conformance.md),
  and the principle in memory `verify-regulated-figures-by-postcondition`.
- **Banded where projected; labelled-placeholder where genuinely unsourced** (forward-looking
  growth/vacancy), per `honest-deferral-not-rug` / `kb-doc-authoring`.
- **Bilingual {vi,en} at the source** (co-equal), per [`bilingual-content.md`](bilingual-content.md).

## Cross-cutting — the 2026-27 Budget NG/CGT reform (proposed, not yet law)

Surfaced mid-authoring (2026-06-23). The 2026-27 Budget (Budget night 7:30pm AEST 12 May 2026)
announced, via the *Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* (**introduced, not yet
passed**), from **1 July 2027**: (a) the **50% CGT discount → cost-base indexation + a 30% minimum
tax** (individuals/trusts/partnerships; existing holdings split at 1 July 2027; new builds may choose
either regime; pensioners exempt), and (b) **negative gearing limited to new builds** (established
post-Budget purchases lose the wage offset; held-before-Budget grandfathered). This hits the wedge's
**own target buyer** (established purchase, now, held long). Captured in `kb.tax.cgt-50-percent-discount`
and `kb.tax.negative-gearing-mechanics` as **proposed-not-law** sections (current law computed; reform
flagged; post-2027 portion → `to_verify`). **Open decision for P2** (disposition `cgt/1` branch): how
far to model the split-at-2027 vs defer to `to_verify`, and whether a dedicated transitional KB doc +
blueprint anchor is warranted over the inline flags. Default (regulated-safe): compute current law,
flag the reform, `to_verify` the post-2027 portion — do not model unenacted law as settled.

## The fail-closed activation rule

The compiler flip (`IN_SCOPE_BLUEPRINT` → `investor-domestic-au`) is **all-or-nothing**: the
in-scope semantic gates (GATE 2 anchor-resolution, GATE 6 reference-integrity, GATE 7 coverage)
demand *every* anchor resolve at once. KB docs land in clusters while investor stays out-of-scope;
the flip happens only after all 45 are authored. Onboarding dispatch (which makes Mode C
user-selectable) must be **atomic-last** — after the flip greens *and* the shell renderers exist —
or a user onboarding as an investor hits an uncompiled artifact or a blank missing-renderer slot.

## Phase order (neutralizes the KB↔engine↔shell coupling)

Full-live Mode C spans all three tiers. Phasing keeps the high-value regulated foundation
committable on its own (coupling-in-a-unit ≠ coupling-in-a-commit).

- **P1 — Regulated KB** (clusters T → F → Y → S below). One cluster per turn, each fact verified
  vs its primary source, ASIC-framed. Commit as the foundation.
- **P2 — Spec-seam reconciliations** (§ below) + the **`cgt/1` investor branch** in
  `fh_engine_disposition` (consumes P1 tax KB: 50% discount, no PPOR exemption, Div-43/40 clawback).
- **P3 — Compiler flip** (`IN_SCOPE` → investor) + declare `plan.*` (add to `EXTERNAL_NS`) +
  green all semantic gates (reconcile whatever GATE 6/7 seams surface) + re-emit artifact + **prove
  selection** (the investor DAG is now in the compiled artifact).
- **P4 — Shell**: 2 net-new renderers (`buying-strategy-card`, `opportunity-card`) + onboarding
  intent selection (the `intent: 'owner_occupier' | 'investment'` type already exists in `api.ts`;
  `onboarding.ts` deliberately hardcodes owner-occupier — unhardcode it).
- **P5 — Onboarding dispatch** (`fh_engine_h_plan_cards.erl`: select blueprint by `intent`) —
  **atomic-last**, only after P3+P4 are green → Mode C live end-to-end.

## Spec-seam reconciliations (P2 — free, reduces 47 anchors → 45 to author)

- `kb.investor.tax-brackets-2026` → the bracket table already exists at
  `kb.tax.income-tax-resident-2025-26`. Repoint the blueprint; do not author a duplicate.
- `kb.investor.serviceability-investment-loans` and `kb.lender.serviceability-investment-loans`
  are one concept under two slugs. Keep one (lean `kb.lender.*`, matching the existing
  `kb.lender.serviceability-basics`), repoint the other.

## P1 — KB authoring tracker (45 docs)

Status legend: `[ ]` not started · `[~]` drafting · `[v]` facts verified vs primary · `[x]` done (bilingual, in-cluster, compiles when in-scope).
"Primary source" is the authority to verify against *at authoring time* — not yet verified here.

### Cluster T — Tax (regulated, highest scrutiny) — source: ATO + state revenue offices

| St | Slug | Consuming component → fields | Figure handling |
|----|------|------------------------------|-----------------|
| [v] | kb.tax.cgt-50-percent-discount | tax_structure, disposition → CGT on sale | resolver-computed, remove-from-reach |
| [v] | kb.tax.negative-gearing-mechanics | tax_structure → gearing position | decision-support framing, no "attractive" verdict |
| [v] | kb.tax.depreciation-division-43-and-40 | tax_structure, disposition → depreciation + clawback | resolver-computed; rates from ATO |
| [v] | kb.tax.entity-comparison-personal-trust-company-smsf | tax_structure → recommended_entity | options + considerations only (ASIC line) |
| [v] | kb.tax.entity-setup-costs | cash_position, settlement_prep → setup cost | banded ranges |
| [v] | kb.tax.land-tax-by-state | tax_structure, ownership_planning_investor → land tax + aggregation | resolver; NSW/VIC/QLD primary-verified, SA/WA/TAS/ACT `to_verify` pending-primary, NT nil |
| [v] | kb.tax.quantity-surveyor-reports | tax_structure, due_diligence → QS report need/cost | banded; reference doc |

**Cluster T COMPLETE (7/7, 2026-06-23).** All verified vs ATO / state revenue / ASIC primaries; the 2026-27 Budget NG/CGT reform captured as proposed-not-law in the cgt + negative-gearing + entity-comparison docs (see cross-cutting section above). **Two seams surfaced for later clusters:** (a) **land-tax SA/WA/TAS/ACT** scales are `to_verify` (secondary-only) — re-ground against RevenueSA/RevenueWA/SRO-Tas/ACT-Revenue (a P1-Cluster-S or freshness-pass trigger; NSW/VIC/QLD + NT are settled). (b) **QS-report overlap** — `kb.tax.quantity-surveyor-reports` (this cluster, owns the report's purpose/cost) vs Cluster-S `kb.investor.depreciation-report-quantity-surveyor` + `kb.investor.depreciation-schedule-procurement` (settlement timeline) may be redundant; reconcile single-owner when authoring Cluster S (this doc owns purpose+cost, the S docs own the settlement-phase procurement milestone).

### Cluster F — Finance / lending — source: APRA serviceability framework + lender published policy (ACL: informational only)

| St | Slug | Consuming component → fields | Figure handling |
|----|------|------------------------------|-----------------|
| [v] | kb.lender.investment-loan-policies | mortgage_finance → policy constraints | reference |
| [v] | kb.lender.investor-friendly-shortlist | mortgage_finance → lender shortlist | shortlist + reasoning, user picks (no recommendation) |
| [v] | kb.lender.serviceability-investment-loans | mortgage_finance → approx_borrowing_capacity | resolver-computed, banded (§98) |
| [v] | kb.loan.interest-only-vs-pi-investor | mortgage_finance, tax_structure → IO vs P&I | decision-support |
| [v] | kb.loan.offset-vs-redraw-investor | mortgage_finance → offset/redraw | reference |
| [v] | kb.loan.refinance-strategies-portfolio-growth | ownership_planning_investor → scale-up via equity | reference |
| [v] | kb.loan.fixed-rate-roll-off-planning | mortgage_finance → roll-off planning | reference |
| [v] | kb.investor.deposit-requirements-investment-loans | cash_position → deposit_ready_for_purchase | banded ranges |

**Cluster F COMPLETE (8/8, 2026-06-23).** All verified vs APRA (APG 223, macroprudential settings) / ATO / ASIC Moneysmart primaries; ACL line built in (decision-support only, no named lender recommendation — `investor-friendly-shortlist` owns *criteria*, not a lender list; the four ACL policy flags mirror the tax cluster's ASIC flags). The `kb.lender.serviceability-investment-loans` keeper was authored (not the `kb.investor.*` duplicate — P2 repoints the blueprint's investor_profile anchor to it). **Three load-bearing regulated facts captured:** (a) **IO assessed as P&I over the residual term** (APG 223) → IO yields a *lower* max loan; (b) **APRA DTI cap from Feb 2026** (DTI ≥6 limited to 20% of new lending, investor portfolio separately) → the binding scale-up ceiling; (c) **ATO TR 2000/2 "use" test** for offset-vs-redraw → offset preserves deductibility, private redraw permanently contaminates the loan. The 2026-27 Budget NG reform is cross-ref'd from `interest-only-vs-pi-investor` (IO tax rationale narrows for established post-Budget purchases). **Two dangling cross-refs (expected — later clusters):** `kb.buyer-costs.investor-additional-costs` (Cluster Y) and `kb.investor.scale-up-using-equity` (Cluster S); GATE 6 reference-integrity only fires at the P3 all-or-nothing flip, so these resolve when those clusters land. No new spec-seam beyond the already-tracked serviceability slug duplication (P2).

### Cluster Y — Yield / market data — source: rental market data + methodology (several forward-looking → labelled placeholders)

| St | Slug | Consuming component → fields | Figure handling |
|----|------|------------------------------|-----------------|
| [v] | kb.investor.rental-income-modelling | yield_modelling → rental income | methodology; figures from suburb data |
| [v] | kb.investor.operating-expenses-typical-ratios | yield_modelling → opex | banded ratios |
| [v] | kb.investor.vacancy-rate-assumptions | yield_modelling → vacancy | labelled-placeholder (forward-looking) |
| [v] | kb.investor.cash-flow-modelling-methodology | yield_modelling → cash_flow_projection | methodology |
| [v] | kb.investor.property-management-fees | yield_modelling → PM fees | banded ranges |
| [v] | kb.property.growth-corridors-au | property_assessment → growth thesis | labelled-placeholder (forward-looking) |
| [v] | kb.property.depreciation-by-build-year | property_assessment, tax_structure → depreciation basis | reference |
| [v] | kb.property.investor-grade-features | property_assessment → fit | reference |
| [v] | kb.property.rental-market-data-sources | property_assessment, yield_modelling → data provenance | reference (source list) |
| [v] | kb.strata.health-indicators-investor-lens | property_assessment → strata health | reference |
| [v] | kb.buyer-costs.investor-additional-costs | cash_position → investor cost adders | banded ranges |

**Cluster Y COMPLETE (11/11, 2026-06-23).** All pure-reference (`fills: []`) — consumed by the computed/agent-reasoned components (yield_modelling = calculator/resolver, property_assessment = summary-card/agent, cash_position = calculator), matching the shape rule (cost/computed component → pure-reference). Verified vs ATO / state tenancy authorities / ABS / SQM / ASIC Moneysmart primaries. **Single-owner handled across three doc-pairs:** (a) `growth-corridors-au` owns the *qualitative location-factor → outlook* methodology and **references** the numeric projection band owned by the existing `kb.property.capital-growth-bands` (not duplicated — the band stays the single labelled-placeholder for sale-value projection); (b) `depreciation-by-build-year` owns the *build-year → eligibility classification* and references the rates/clawback owned by Cluster-T `kb.tax.depreciation-division-43-and-40`; (c) `strata.health-indicators-investor-lens` is a **variant** that owns only investor deltas (levy-as-yield-line, special-levy-as-cash-flow-shock, resale liquidity, by-laws, deductibility) and references the regulated funding horizons owned by FHB `kb.strata.health-indicators`; `investor-additional-costs` is the **delta** on FHB `kb.buyer-costs.inspections-conveyancing-fees`. **Two labelled placeholders** per the tracker: `vacancy-rate-assumptions` (default fallback band is the placeholder; suburb-specific path is sourced) and `growth-corridors-au` (forward outlook framed decision-support, no named-corridor forecast; numeric band deferred to capital-growth-bands). **One new regulated fact removed-from-reach:** state **minimum rental/housing standards** as an investor-only acquisition cost (VIC 14 standards from 29 Mar 2021; QLD all tenancies from 1 Sep 2024; NSW 7 standards + mandatory smoke alarms — regulator-confirmed; SA/WA/TAS/ACT/NT `to_verify` at the row level, same honest-partial move as land-tax-by-state). **Five expected-dangling cross-refs to Cluster S** (`kb.investor.{strategy-archetypes, property-management-vs-self-managed, rental-appraisal-from-pm-agent, tenancy-in-situ-considerations, land-tax-aggregation}`) — all in the Cluster-S list below; GATE 6 reference-integrity only fires at the P3 all-or-nothing flip, so these resolve when Cluster S lands. All 11 slug==path OK; all non-Cluster-S cross-refs resolve.

### Cluster S — Strategy / process — source: mixed reference / process (lower figure-density; decision-support framed)

| St | Slug | Consuming component → fields | Figure handling |
|----|------|------------------------------|-----------------|
| [v] | kb.investor.strategy-archetypes | investment_strategy → archetype | reference |
| [v] | kb.investor.gearing-types-and-implications | investment_strategy → gearing | decision-support |
| [v] | kb.investor.hold-period-considerations | investment_strategy → hold period | reference |
| [v] | kb.investor.exit-strategy-options | investment_strategy, disposition → exit | reference |
| [v] | kb.investor.experience-levels | investor_profile → traits.experience_level | reference (bands) |
| [v] | kb.investor.bid-discipline | buying_strategy → bid plan | decision-support |
| [v] | kb.investor.yield-anchored-pricing | buying_strategy → price ceiling | resolver-anchored to yield |
| [v] | kb.investor.tenancy-in-situ-considerations | due_diligence → tenancy | reference |
| [v] | kb.investor.rental-appraisal-from-pm-agent | due_diligence → rental appraisal | reference |
| [v] | kb.investor.depreciation-report-quantity-surveyor | due_diligence, settlement_prep → QS report | reference |
| [v] | kb.investor.entity-setup-timeline | settlement_prep → entity setup milestone | reference |
| [v] | kb.investor.depreciation-schedule-procurement | settlement_prep → depreciation schedule | reference |
| [v] | kb.investor.property-management-appointment-timeline | settlement_prep → PM appointment | reference |
| [v] | kb.investor.property-management-vs-self-managed | ownership_planning_investor → management model | decision-support |
| [v] | kb.investor.annual-tax-return-investor | ownership_planning_investor → annual return | reference |
| [v] | kb.investor.cash-flow-tracking | ownership_planning_investor → tracking | reference |
| [v] | kb.investor.portfolio-review-cadence | ownership_planning_investor → review cadence | reference |
| [v] | kb.investor.scale-up-using-equity | ownership_planning_investor → scale-up | decision-support |
| [v] | kb.investor.land-tax-aggregation | ownership_planning_investor → land-tax aggregation | resolver (consumes kb.tax.land-tax-by-state) |

**Cluster S COMPLETE (19/19, 2026-06-24).** All pure-reference (`fills: []`) — the consuming components are agent-reasoned (`investment_strategy` archetype/gearing, `buying_strategy` negotiation style, `due_diligence` lease interpretation) or resolver-computed (`yield_anchored_max_price`, the land-tax estimate), so these docs supply vocabulary / method / behaviour, never a setter. **P1 now COMPLETE: T(7) + F(8) + Y(11) + S(19) = 45/45.** Verified against ATO / state revenue offices / state tenancy authorities / APRA / ASIC Moneysmart primaries. **Two earlier-cluster seams closed:** (a) the **QS-report overlap** flagged in Cluster T is resolved by a clean three-way single-owner split — `kb.tax.quantity-surveyor-reports` owns **purpose+cost**, `kb.investor.depreciation-report-quantity-surveyor` owns the **due-diligence validation lens** (pre-purchase estimate), `kb.investor.depreciation-schedule-procurement` owns the **post-settlement procurement milestone + refresh**; rates/rules → tax doc, eligibility → `kb.property.depreciation-by-build-year`; no fact duplicated. (b) **All five previously-dangling Cluster-Y → Cluster-S cross-refs** (`strategy-archetypes`, `property-management-vs-self-managed`, `rental-appraisal-from-pm-agent`, `tenancy-in-situ-considerations`, `land-tax-aggregation`) **and the Cluster-F → `scale-up-using-equity` ref now resolve** — every relative `.md` link target in the 19 docs checked on disk (zero missing). **Single-owner across cost-vs-decision and figure-vs-method seams:** management *fee* → `kb.investor.property-management-fees` vs management *decision* → `property-management-vs-self-managed`; the *yield-anchored price* method (this cluster) reads the *rent* (`rental-income-modelling`) and *binding rent source* (`rental-appraisal-from-pm-agent`); land-tax *aggregation behaviour* (this cluster) vs *thresholds/rates* → `kb.tax.land-tax-by-state` (its SA/WA/TAS/ACT `to_verify` rows inherited, not re-asserted — the figure is resolver-computed, removed-from-reach). **Reform default applied** in `gearing-types-and-implications` + `hold-period-considerations`: current law computed, the 2026-27 Budget NG/CGT change flagged, post-1-July-2027 → `to_verify`; the status itself owned by the Cluster-T tax docs. **One regulated structural fact, principle-level not figure:** state land-tax aggregation (per-owner, per-state pooling on a progressive scale; PPOR exempt; not pooled across states) and tenancy-in-situ (a fixed-term lease binds the buyer) — both asserted as stable national principles, with the time-sensitive per-state details (`to_verify`) deferred to the owning docs. All 19 slug==path OK. GATE 6 reference-integrity (P3 flip) should now find P1 closed end-to-end.

## P2–P5 — engine + shell tracker

| St | Phase | Item |
|----|-------|------|
| [ ] | P2 | Reconcile `tax-brackets-2026` → `kb.tax.income-tax-resident-2025-26` (blueprint edit) |
| [ ] | P2 | Reconcile serviceability slug duplication (keep `kb.lender.*`) |
| [ ] | P2 | `cgt/1` investor branch in `fh_engine_disposition` (50% discount, no PPOR exemption, Div-43/40 clawback) — currently returns `to_verify` for non-PPOR |
| [ ] | P3 | Flip `IN_SCOPE_BLUEPRINT` → `investor-domestic-au` in `kb_compiler.py` |
| [ ] | P3 | Declare `plan.*` (add `"plan"` to `EXTERNAL_NS`) |
| [ ] | P3 | Green all semantic gates; reconcile GATE 6/7 reference-integrity / coverage seams |
| [ ] | P3 | Re-emit artifact; prove the investor DAG is selected (not a silent no-op) |
| [ ] | P4 | Shell renderer: `buying-strategy-card` (enum + §11.9 table + Svelte component) |
| [ ] | P4 | Shell renderer: `opportunity-card` (enum + §11.9 table + Svelte component) |
| [ ] | P4 | Onboarding intent selection UI (`onboarding.ts` — unhardcode owner-occupier) |
| [ ] | P5 | Onboarding dispatch: `fh_engine_h_plan_cards.erl` selects blueprint by `intent` (atomic-last) |

## Deferred out (honest — first-exercising instance is Mode B/D, not here)

`off_title_parties[]` (array vs A's scalar `non_buying_partner`), `visa_class`, off-title
`funder{}`, and B/D publishing `firb_required_any` (the F14 close) ride **Mode B** — they have zero
exercising instance in Mode C, and `facts_jsonb` makes their later addition migration-free. See
[`fact-model-unification.md`](fact-model-unification.md) "Mode-C activation".
