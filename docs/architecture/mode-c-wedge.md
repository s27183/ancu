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

Adding `investor-domestic-au` to the in-scope **set** (`IN_SCOPE_BLUEPRINTS`) is **all-or-nothing**:
its semantic gates (GATE 2 anchor-resolution, GATE 6 reference-integrity, GATE 7 coverage) demand
*every* anchor resolve at once. KB docs land in clusters while investor stays out-of-scope; the
add happens only after all 45 are authored. **This is an addition, not a replacement** — the
runtime is multi-blueprint (each in-scope blueprint carries its own registry; the turn + gates
select by the card's `blueprint_slug`), so activating Mode C never dormants Mode A (engine-contract
§9.1, architecture §11.9). Onboarding dispatch (which makes Mode C user-selectable) must be
**atomic-last** — after the add greens *and* the shell renderers exist — or a user onboarding as an
investor hits a missing blueprint or a blank missing-renderer slot.

## Phase order (neutralizes the KB↔engine↔shell coupling)

Full-live Mode C spans all three tiers. Phasing keeps the high-value regulated foundation
committable on its own (coupling-in-a-unit ≠ coupling-in-a-commit).

- **P1 — Regulated KB** (clusters T → F → Y → S below). One cluster per turn, each fact verified
  vs its primary source, ASIC-framed. Commit as the foundation.
- **P2 — Spec-seam reconciliations** (§ below) + the **`cgt/1` investor branch** in
  `fh_engine_disposition` (consumes P1 tax KB: 50% discount, no PPOR exemption, Div-43/40 clawback).
- **P3 — Multi-blueprint runtime** (foundational reframe of the original "compiler flip": a single
  in-scope constant could not represent two modes — `disposition.cgt_status` is `[exempt, to_verify]`
  vs `[computed, to_verify]` — so the runtime selects the blueprint per plan-card). Contract docs
  (engine-contract §9.1 + architecture §11.9) → compiler emits an in-scope **set** + a registry **per**
  in-scope blueprint (`blueprints[slug].registry`) → engine threads the card's `blueprint_slug` through
  the turn DAG + Layer-1/Layer-2 gates → declare `plan.*` (`EXTERNAL_NS`) + green both modes' semantic
  gates + re-emit artifact + **prove selection** (both registries present; investor disposition
  validates against its own). Modes coexist; no Mode-A regression.
- **P4 — Shell renderers**: 2 renderers net-new *to the shell* (`buying-strategy-card`,
  `opportunity-card`) — the enum + §11.9 rows already exist (authored with the blueprint), so the
  work is **Svelte-component + dispatcher-branch only**. Both are Phase-B/agent components with no
  live producer in either mode yet, so they render against the §11.9 contract, honest-partial —
  pure-additive, zero Mode-A risk. (The onboarding intent picker moved to P5: unhardcoding `intent`
  in the shell while the engine still hardcodes `fhb` is a silent-wrong rug, so the picker must land
  **atomically** with the engine dispatch — the doc's own atomic-last rule.)
- **P5 — Investor base engine + onboarding activation.** Grounding the live engine (2026-06-24)
  reshaped this phase: the original line ("dispatch + per-blueprint `base_components` → an investor
  base turn verifies end-to-end") was **under-scoped**. An investor base turn can't run — its
  resolvers don't exist. `has_resolver/1` lists only Mode-A component names; `investor_profile`,
  `yield_modelling`, `ownership_planning_investor` have no module (a base turn `error`s on the first),
  and the shared-name `cash_position`/`mortgage_finance` resolvers run **Mode-A** logic (FHB schemes /
  P&I — wrong figures). Only `disposition` is investor-ready (P2). So P5 splits:
  - **P5-engine** — the investor resolver suite, decomposed **one component at a time** (each verified
    in isolation via a conformance escript against its KB — the P2 disposition rhythm; no onboarding
    needed). Regulated figures resolver-computed + removed-from-reach throughout (tax_structure is the
    most-regulated surface). The per-applicant `tax{}` / `existing_portfolio` / `traits` are the
    Mode-C-activated canonical-`profile` deltas.
  - **P5-activate (atomic-last)** — the per-blueprint `base_components/1` sequence (the P3 follow-on)
    **+** the `fh_engine_h_plan_cards` dispatch (select `blueprint_slug` by `intent`) **+** the
    `onboarding.ts` intent picker (the type already exists in `api.ts`), landing **together** once the
    turn computes end-to-end — so a user onboarding as an investor never hits a half-built turn.

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
| [x] | P2 | Reconcile `tax-brackets-2026` → `kb.tax.income-tax-resident-2025-26` (blueprint edit) |
| [x] | P2 | Reconcile serviceability slug duplication (keep `kb.lender.*`) |
| [x] | P2 | `cgt/1` investor branch in `fh_engine_disposition` (50% discount, no PPOR exemption, Div-43/40 clawback) — currently returns `to_verify` for non-PPOR |
| [x] | P3 | **Contract docs** — pin the multi-blueprint runtime (engine-contract §9.1 + architecture §11.9): in-scope **set**, per-blueprint registry, per-card blueprint resolution |
| [x] | P3 | **Compiler** — `IN_SCOPE_BLUEPRINT` (str) → `IN_SCOPE_BLUEPRINTS` (set `{fhb, investor}`); registry materialized + GATE 6/7-gated **per** in-scope blueprint; emit `blueprints[slug].registry`; declare `plan.*` (`EXTERNAL_NS`) |
| [x] | P3 | **Engine** — thread the card's `blueprint_slug`: `fh_engine_kb:registry/1,2` + `in_scope_blueprints/0`; `fh_engine_outcome:validate/3` + `component_names/1`; `fh_engine_turn:base_components/1` + `dag_reads/2`; `fh_engine_simulate:run/3,4`; 4 turn-starters |
| [x] | P3 | Re-emit artifact; **prove selection** — both registries present, investor `disposition.cgt_status` `[computed, to_verify]`; both modes green |
| [x] | P4 | Shell renderer: `buying-strategy-card` (Svelte component + dispatcher branch; enum + §11.9 row already authored) |
| [x] | P4 | Shell renderer: `opportunity-card` (Svelte component + dispatcher branch; enum + §11.9 row already authored) |
| [x] | P5-engine | `investor_profile` resolver (`fh_engine_fill` inline, mirrors `buyer_profile`) — canonical `profile`, investor lens (per-applicant `tax{}`, no owner-occupier leaves, domestic-investor strength); honest-partial |
| [x] | P5-engine | `investment_strategy` **two-path** (resolver scaffold + 3 `investment_thesis` agent leaves) — `strategy_thesis` from the Cluster-S KB (archetype/gearing/one_liner); first Mode-C agent component |
| [ ] | P5-engine | `mortgage_finance` investor variant (branch the shared resolver) — investment-loan serviceability, IO-vs-PI, DTI cap (Cluster-F KB) |
| [~] | P5-engine | `yield_modelling` resolver — base-spine presence DONE (`fh_engine_fill` inline, honest-partial all-null `cash_flow_projection` + `calculator` + 5 Cluster-Y anchors); the cash-flow **arithmetic** (NEW module) defers to `property_assessment` (its rent-leaf producer) + the banded-vs-scalar seam |
| [~] | P5-engine | `tax_structure` **two-path** — base-spine presence DONE (`fh_engine_fill` inline: resolver scaffold + `entity_structuring` agent leaf `recommended_entity`, live-verified; the two CGT-determinant **constants** `disposition` reads — `cgt_discount_eligible`/`cost_base_depreciation_clawback` = true; `data-table` + 6 Cluster-T anchors). Deferred to `property_assessment`: `cgt_marginal_rate` (needs an ATO-brackets KB doc + income), `setup_costs`/`annual_compliance_cost` (banded-vs-scalar seam), the 5 property/rent-dependent figures |
| [~] | P5-engine | `cash_position` investor variant — base presence DONE (`fh_engine_cash:fill_investor/2`, branched on the `tax_optimised_structure` discriminator like `disposition`; **pure-resolver**, `agent_leaves []`). The compiled `budget_envelope_investor` is 9 point-summary figures, all honestly null at base (plan-first: no property, no savings); emits `calculator` + the 6 Cluster-Y/T cash anchors. Deferred to `property_assessment` (per-property): the property-price-dependent figures; `max_property_price_supported` → investor `mortgage_finance` capacity (unbuilt); HAVE-side → refine turn |
| [~] | P5-engine | `ownership_planning_investor` — base presence DONE (`fh_engine_ownership:fill_investor/2`, a clean sibling on the UNIQUE name — no discriminator, FHB `fill/2` untouched; **pure-resolver**, `agent_leaves []`). **Honest-partial:** `annual_tax_obligations` (5, bilingual) + `alert_triggers_armed` (4 investor alerts, bilingual) filled from the 6 Cluster-S KB anchors via a new `kb.copy.ownership-investor` doc; the 6 post-acquisition figure fields null at base. **Producer half of the P4 `opportunities[]` seam CLOSED**: field added to the schema (recompiled), emitted `[]` at base (populates per-property); `annual_tax_obligations` retyped `array<localized_text>` (validator-enforced bilingual). Emits `data-table` (the reachable primary). Deferred: the 6 figure fields → `property_assessment`; the **consumer half** (shell renders only `renderers[0]`) → a shell unit |
| [ ] | P5-activate | per-blueprint `base_components/1` sequence (the P3 follow-on — derive the investor base set + DAG order, replacing the Mode-A `?BASE_COMPONENTS` macro) |
| [ ] | P5-activate | Onboarding **dispatch** (`fh_engine_h_plan_cards.erl` selects blueprint by `intent`) **+** **intent picker** (`onboarding.ts`), atomic-last |

**P2 COMPLETE (2026-06-24).** Two free repoints + the investor CGT branch, all committable now (no
deploy until P3). **Repoints** in `investor-domestic-au.md`: `kb.investor.tax-brackets-2026` →
`kb.tax.income-tax-resident-2025-26` (shared with Mode A → de-italicised in the anchor index) and
`kb.investor.serviceability-investment-loans` → `kb.lender.serviceability-investment-loans` (the
Cluster-F keeper; investor_profile now shares it with mortgage_finance, anchor index "1, 4"). Both
are dormant until GATE 6 fires at the P3 flip. **`fh_engine_disposition`** gained a mode branch:
`fill/2` dispatches on a `tax_optimised_structure` upstream (only the investor blueprint runs a
`tax_structure` component) → `fill_owner_occupier/2` (Mode-A path, byte-unchanged) vs
`fill_investor/3` (full CGT). `cgt_investor/4` computes the discounted taxable gain × marginal rate
for the **clean case only** (resident individual, rate known, no Div-43 clawback in play) and returns
**`to_verify` (cgt = null → net/full PENDING)** once a trap applies — non-resident period,
trust/company/SMSF entity, unknown rate, or a live clawback. **Seam reconciled** (cgt-50-percent vs
depreciation-43-40): the depreciation doc defers the dollar clawback to a tax agent, so when a
clawback is in play the branch surfaces the indicative pre-clawback `taxable_gain` but returns the
CGT `to_verify` — never an overstated net. All figures resolver-computed, removed from the LLM's
reach: the 50% discount + by-entity rates from `kb.tax.cgt-50-percent-discount`, the investment-loan
amortisation rate = owner-occupier representative (6.0%) + premium (0.35pp) from the F-cluster docs.
**Reform default applied** (the open decision above): current 50% law computed, the 2026-27 Budget
reform surfaced as a flagged bilingual `key_assumption`, no dedicated transitional KB doc (the inline
flags suffice). New bilingual copy in `kb.copy.disposition` (`assumption_cgt_computed` /
`assumption_cgt_investor_to_verify` / `assumption_cgt_reform`). Verified by
`disposition_conformance.escript` — **78 anchors green** (50 Mode-A unchanged + 28 investor: exact
figures, no-second-computer, honest-partial, bilingual). **P2/P3 boundary surfaced:** `taxable_gain`
and `cgt_status: computed` are absent from the **in-scope (Mode-A) registry**, so (a) the validator's
lenient unknown-field pass-through lets `taxable_gain` ride harmlessly now, and (b) the
investor-**computed** Layer-1 case can only green once IN_SCOPE flips at P3 (the enum becomes
`[computed, to_verify]`) — its figures are exactly asserted in `investor_cases/0` meanwhile, and the
investor-**to_verify** Layer-1 case (shared enum) already passes. The artifact is untracked
(gitignored, `KB.rglob` includes all on-disk docs), so re-emit is a no-tracked-file P3 step.

**P3 COMPLETE (2026-06-24) — reframed from "compiler flip" to the multi-blueprint runtime.** The
one-line plan ("flip `IN_SCOPE_BLUEPRINT` → investor") would have *replaced* Mode A, not added Mode
C: `in_scope_blueprint` was load-bearing at runtime (turn DAG, both gates, the registry), and the
registry is one flat map keyed by outcome-type name — but the modes share names with divergent
fields/enums (`disposition.cgt_status` `[exempt, to_verify]` vs `[computed, to_verify]`;
`profile`/`mortgage_plan` differ too). So a flat registry physically can't hold both → the runtime
must select per-card. **Built docs-first** (Son's order for a cross-contract reframe): (1) contract —
engine-contract §9.1 + architecture §11.9 pin the in-scope **set**, the per-blueprint registry, and
per-card resolution from `plan_cards.blueprint_slug`; (2) compiler — `IN_SCOPE_BLUEPRINTS` (set),
`semantic_gates/4` materializes + GATE-6/7-gates each in-scope blueprint's own registry, emits
`blueprints[slug].registry` + top-level `in_scope_blueprints` (dropped the singular `registry`/
`in_scope_blueprint`); also generalized `build_registry` to key the identity component off the
`profile` *outcome* (not the `buyer_profile` *name*) so the investor registry's applicant types
populate; (3) engine — `fh_engine_kb:registry/1,2` + `in_scope_blueprints/0`,
`fh_engine_outcome:validate/3` + `component_names/1`, `fh_engine_turn:base_components/1` +
`dag_reads/2`, `fh_engine_simulate:run/3,4`, the 4 turn-starters thread the card's `blueprint_slug`.
**Verified:** compiler 0 fails (both registries, divergent enums coexist); `disposition_conformance`
**79 anchors** (the investor-**computed** Layer-1 case now validates against the investor registry —
the P2 deferral closed); the full Mode-A conformance suite green (no regression); `refine_smoke`
against live PG green with a 67-card refresh sweep through the threaded turn path; `erlang-checker`
clean. **One honest follow-on:** `base_components/1`'s base SET+ORDER is still the Mode-A
`?BASE_COMPONENTS` macro — correct for `fhb` (the only blueprint creating base turns until P5), no
investor caller exists yet; deriving a per-blueprint base sequence from the `scope` table lands in
P5 where an investor base turn verifies it end-to-end.

**P4 COMPLETE (2026-06-24) — shell renderers (Svelte-only; onboarding picker reclassified to P5).**
Grounding the live shell reshaped the tracker line two ways. (1) **"enum + §11.9 table" was already
done** — both rows exist in `architecture.md` §11.9 (added with the blueprint), so the deliverable
was purely the **Svelte component + dispatcher branch**, not a three-layer ripple. (2) **Neither
renderer has a live producer.** `buying_strategy` (→`bid_plan_investor`) and
`ownership_planning_investor` (→`portfolio_position`) are Phase-B/agent components, unwired to any
resolver in *either* mode (Mode A never rendered these seven vocabulary renderers either). So they
render against the **§11.9 contract shape**, honest-partial — pure-additive, **zero Mode-A risk**
(Mode A emits neither renderer). This is the "no blank slot when the investor blueprint fills"
foundation the atomic-last rule requires. **Built:** `BuyingStrategyCard.svelte` (a bid-discipline
price ladder — walk-away / yield-anchored ceiling / max bid on one axis, `thesis_alignment` +
negotiation `style` as $t'd closed-enum chips, comparables, conditions), `OpportunityCard.svelte`
(list-tolerant `{ kind, modeled_benefit, action }`), two `ComponentCard.svelte` dispatcher branches,
two spec-derived `planCard.ts` types (`BidPlanInvestorOutcome`, `OpportunityCardOutcome`), and the
renderer-internal bilingual `plan.*` labels (en+vi, incl. the thesis/style enum display labels).
Component **title** keys for investor components stay P5 (they render only when an investor turn runs).
**Verified:** `svelte-autofixer` clean on both, `svelte-check` 0/0, production build green.
**One producer seam — producer half CLOSED in P5-engine 6/suite; consumer half is a shell unit.**
`opportunity-card`'s §11.9 contract `{ kind, modeled_benefit, action }` had no matching field in
`portfolio_position`. The seam splits across the engine↔shell contract: (a) **producer** — the
schema lacked `opportunities[]`; **now added + emitted `[]` at base** by `fill_investor/2` (an
opportunity is defined by its `modeled_benefit`, a figure off an owned property, so none exist
plan-first — it populates per-property in Phase B). (b) **consumer** — the shell renders only
`renderers[0]` per component (`planCard.ts:389` — `entry.renderer` = "first of the blueprint's
renderers"), so the *second* declared renderer (`opportunity-card`) is **unreached for every
dual-renderer component**, incl. the already-shipped FHB `ownership_planning` (same
`['data-table','opportunity-card']`). Dispatching the second renderer changes behaviour for 5+
shipped components → a scoped **shell** unit, not foldable into a Mode-C engine resolver. Logged
here + in the `OpportunityCardOutcome` type comment; the renderer is built to its contract meanwhile.

**P5-engine STARTED (2026-06-24) — `investor_profile` resolver (1st of the suite).** Grounding the
live engine surfaced that P5 is an investor **resolver suite**, not a dispatch wire (the reshape is in
the phase bullet above + the table). Built the DAG-root resolver first (Son's "one resolver, fully"):
`investor_profile` as an inline fill in `fh_engine_fill` (mirroring `buyer_profile`, reusing
`eval_applicants` / `tri_to_json` / the IC3 `assessable_income`/`debts` helpers / `copy`), plus
`has_resolver(<<"investor_profile">>) -> true` and the dispatch clause. It projects the **canonical,
mode-independent `profile`** (identity-layer unification), with the Mode-C deltas: a per-applicant
`tax{ residency_for_tax=resident, jurisdiction=AU }` object (marginal_rate PENDING until income),
**no** owner-occupier eligibility leaves, and a definitional domestic-investor strength
(`strength_domestic_investor`, new `kb.copy.profile` key — no FIRB / no foreign surcharge / resident
CGT-discount eligible, decision-support tone). Honest-partial: `existing_portfolio` / `traits` /
capacity / deposit / ppor-equity ABSENT at onboarding (refine-turn / downstream facts). **Verified**
by `investor_profile_conformance.escript` — **40 anchors** (applicant projection, honest-partial,
financials framing, bilingual narration + KB-anchor audit, Layer-1 conformance to the investor
registry, and **no Mode-A regression**: `buyer_profile` still dispatches + conforms to the FHB
registry). Recompiled the artifact (the new copy key + the 3 investor KB anchors present);
`resolver_conformance` / `outcome_conformance` / `disposition_conformance` all still green;
`erlang-checker` clean. **Distinct component name ⟹ zero Mode-A reach** (the FHB turn never selects
the clause); dormant until P5-activate wires the dispatch.

**P5-engine 2/suite COMPLETE (2026-06-24) — `investment_strategy` (the FIRST Mode-C agent component).**
Son picked it as the DAG keystone. Grounding the live engine corrected the initial scoping (the
mortgage variant is *agent*-path, not a clean resolver, and sits *downstream* of `investment_strategy`)
and settled the design as **two-path** (mirroring `mortgage_finance`), not pure-agent — so the
kb_versions **audit trail** stays resolver-owned (not agent-fabricable), the honest-partial nulls are
structural, and the unit reuses the **tested resolver-only-refresh re-attach** (a base component must
re-attach stored leaves without re-running the LLM). **Erlang** (`fh_engine_fill`, all additive):
`has_resolver` + dispatch clause; the `investment_strategy/1` resolver **scaffold** (renderer
`summary-card`; the four-anchor strategy kb_versions; `hold_period_years` carried off upstream
`profile`; every agent slot + property-relative target + alignment verdict null = honest-partial —
the targets follow from the archetype *and* a property, both absent at base); `merge_agent/3` +
`agent_values_from_outcome/2` clauses (slot-scoped fold of the 3 leaves; §98 — no figure/verdict moved).
**Python** (`planner.py`, generalized at the 2nd two-path instance): new `investment_thesis`
`_DOMAINS` module + `InvestmentThesisLeaves` schema (`archetype`/`gearing_type` as Literals,
`one_liner` as bilingual `LocalizedText` — **no number field → targets out of the LLM's reach**) +
`fill_investment_strategy` coroutine + `_FILLERS` entry; `_kb_block`/`build_user_content` parameterized
(per-domain descriptors), `_PREAMBLE`/`_STYLE` de-FHB'd ("buyers", not "first home buyers") to serve
both domains — the mortgage path preserved. **Verified:** `investment_strategy_conformance.escript`
**27 anchors** (scaffold, slot-scoped merge, refresh round-trip = inverse of merge, Layer-1 conformance
to the investor `strategy_thesis` schema incl. the `{vi,en}` `one_liner` passing the `string`/scalar
field, no Mode-A regression); a Python structural suite (schema enums + bilingual rejection + prompt
assembly + dispatch + mortgage-path-preserved); and a **live end-to-end Opus fill** (subscription
credit) — `capital_growth` + `negatively_geared` (consistent), a register-appropriate KB-grounded
bilingual one-liner, decision-support tone, no figure leaked (23s, 2510-in/1049-out). `erlang-checker`
clean; no recompile needed (no new copy doc — the 4 strategy anchors already compiled). **Observation
(flagged, not patched):** the registry types `one_liner`/`alignment_reasoning` as `string`, but they're
produced/displayed bilingual — the bilingual contract is enforced at the producer (Pydantic), and a
`string→localized` registry upgrade for backstop enforcement is a deliberate cross-field pass, separate
from this unit. **Next P5-engine unit:** `mortgage_finance` investor variant (now unblocked — its
`strategy_thesis` upstream exists), or `yield_modelling` / `cash_position` resolver — Son's call.

**P5-engine 3/suite COMPLETE (2026-06-24) — `yield_modelling` base-spine presence (a pure-resolver
figure-owner).** Grounding settled the shape: `cash_flow_projection` has **no free-text field** (every
field is a figure/enum), so `yield_modelling` is a **pure resolver** (empty `agent_leaves`), the same
class as `fh_engine_disposition` — no two-path, the figures removed from the LLM's reach. **At base it
is necessarily honest-partial, all-null:** the binding input is the **weekly rent**, which the KB sources
from `estimated_weekly_rent_range` — an *agent leaf on `property_assessment`*, a per-property component
that is **unbuilt** (and there is no base rent source — suburb median-rent data isn't wired, the paid
feeds are deferred). Every figure hangs off that rent → null at base, exactly as `disposition` returns
null when its inputs are unset. **Erlang** (`fh_engine_fill`, additive): `has_resolver` + dispatch clause
+ the `yield_modelling/1` resolver returning the 11-field honest-partial null `cash_flow_projection`,
`calculator` renderer, and the **five Cluster-Y anchors** as the resolver-owned method/band audit trail.
One clause serves both investor blueprints (the Mode-D `cash_flow_projection_foreign` variant too — fine
at base, its fields deferred with Mode D). **Verified:** `yield_modelling_conformance.escript` **33
anchors** (renderer; all 11 figures null + input-independent on empty upstream; exact field set; the five
anchors; `has_resolver` true; Layer-1 conformance of the all-null scaffold to the `cash_flow_projection`
schema; **pure-resolver — no `merge_agent`/`agent_values_from_outcome` clause**; no Mode-A/Mode-C
regression). All existing suites green (investment_strategy 27, investor_profile 40, disposition 79,
outcome 21+11, resolver lockstep); `erlang-checker` clean; no recompile (no new copy doc — the 5 anchors
already compiled). **Deferred (honest — unbuilt upstream dependency, not a rug):** the cash-flow
**arithmetic** (income→opex→yields→cash-flow→year-5/10) is a NEW module that reads `property_assessment`'s
rent leaf; building it now would assert an ungrounded producer shape ([[place-upstream-figures-dont-
recompute]]). It lands with `property_assessment`. **Cross-contract seam flagged (decide there, not
patched):** `cash_flow_projection` figures are typed `money`/`percentage` **scalar** in the registry AND
`disposition` already consumes `cash_flow_before_tax_year_1` as a scalar number, but the KB says **banded
ranges** (rent is a range) and every other figure-owner (disposition's `sale_proceeds` etc.) is
`money_range` — the banded-vs-scalar call ripples KB ↔ blueprint ↔ registry ↔ `disposition` consumer ↔
`calculator` renderer; it doesn't bite at base (all null).

**P5-engine 4/suite COMPLETE (2026-06-25) — `tax_structure` base-spine presence (a two-path
component, the most regulated surface in the wedge).** Picked next over `cash_position` (which
*consumes* `tax_structure`'s CGT figures → producer-first) and `property_assessment` (per-property /
Phase-B, not on the base spine). Grounding settled the shape: `tax_optimised_structure` has **one
irreducible judgment field** — `recommended_entity` (the artifact's single `agent_leaves` entry,
`reasoning_domain entity_structuring`) — so `tax_structure` is **two-path** like `investment_strategy`
(resolver scaffold + one agent leaf), not pure-resolver. **Foundation-first payoff:** the *already-built*
`disposition` consumer (`fh_engine_disposition:cgt_investor/4`) reads **exactly four**
`tax_optimised_structure` fields and its `Clean` test already defines their contract
(`recommended_entity` ∈ personal_sole/joint; `cgt_marginal_rate` `is_number`; `cgt_discount_eligible`
true; `cost_base_depreciation_clawback` =:= false) — so this base output is not free-floating, it
**closes wiring `disposition` already expected** (producer + consumer designed together). **Erlang**
(`fh_engine_fill`, additive): `has_resolver` + dispatch clause + `tax_structure/1` (the **two
KB-grounded boolean constants** the consumer reads — `cgt_discount_eligible`/`cost_base_depreciation_
clawback` = true, the latter → `disposition` `to_verify`, the conservative outcome the depreciation KB
demands; `data-table` renderer; the **six Cluster-T anchors**), `merge_agent` (slot-scoped fold of the
one entity leaf, §98), `agent_values_from_outcome` (entity round-trip for base-resolver refresh).
**Python** (`planner.py`): `EntityStructuringLeaves` (single-enum, **no number field** → §98 by schema),
the `entity_structuring` domain (ASIC discipline load-bearing in the prompt — a *starting structure to
confirm with a registered tax agent*, never a directive; base default = lowest-complexity personal
ownership), `fill_tax_structure`, `_FILLERS` registration. **Verified:**
`tax_structure_conformance.escript` **39 anchors** (data-table renderer; the 2 constants +
input-independence; 9 nulls; exact 11-field set; 6 anchors; `has_resolver` true; Layer-1 conformance of
both the scaffold AND the merged outcome; two-path merge folds **only** the entity + **§98 figure-tight**
— a stray `setup_costs`/`cgt_discount_eligible` in the agent reply is NOT folded; `agent_values`
round-trip; no regression — `yield_modelling` stays pure-resolver, `investment_strategy` two-path intact).
**Live Opus** (`fill_tax_structure`, subscription credit): returns `personal_sole` for a single resident
base profile (the KB-grounded low-complexity default), exactly one leaf, no figure leaked, ASIC posture
held. All regression suites green; `erlang-checker` clean; no recompile (the 6 anchors + outcome schema
already compiled). **Deferred (honest, trigger-gated — all to `property_assessment`):** `cgt_marginal_rate`
(needs an **ATO income-tax-brackets KB doc** — unauthored — + `assessable_income`; null → `disposition`
CGT `to_verify`); `setup_costs`/`annual_compliance_cost` (the **same banded-vs-scalar seam** flagged on
`yield_modelling` — KB gives bands, registry types scalar `money`); the 5 property/rent-dependent figures
(`negative_gearing_active`, tax refund, after-tax cash flow ×2, depreciation). **Two doc/schema seams
flagged (not patched):** (1) `cgt_discount_eligible`'s "true if held >12 months" semantics wants
`strategy_thesis.hold_period_years`, but `strategy_thesis` is **not a declared `tax_structure` input**
(profile + cash_flow_projection are) → constant `true` matches the compiled blueprint; a hold-aware
refinement needs the input declared. (2) the regulated `recommended_entity` has **no `reasoning` field**
in the compiled outcome — surfacing its reasoning is a separate outcome-schema unit. **Next P5-engine
unit:** `cash_position` investor variant (now unblocked — its `tax_optimised_structure` upstream exists),
`mortgage_finance` investor variant, or `ownership_planning_investor` (NEW module + the P4 `opportunities[]`
seam) — Son's pick. Then P5-activate (base_components/1 + dispatch + intent picker, atomic-last).

**P5-engine 5/suite COMPLETE (2026-06-25) — `cash_position` investor variant (a pure-resolver
figure-owner).** Picked next per the DAG order (…→ tax_structure → **cash_position** → …), now
unblocked since its `tax_optimised_structure` upstream landed in 4/suite. **First shared-component-name
collision in the suite:** both blueprints have a component literally named `cash_position` (the resolver
keys on name only), emitting *different* outcome types (`budget_envelope` vs `budget_envelope_investor`).
**Resolved by the `disposition` pattern** — one module, internal branch on the `tax_optimised_structure`
upstream discriminator (an investor-only outcome; cash_position's investor `dag_reads` include it and it
runs after tax_structure, so it's present for the investor path and **never** for FHB). `fh_engine_cash:fill/2`
now dispatches: absent → `fill_fhb/2` (the existing body, **pure rename — byte-identical**, zero
regression); present → `fill_investor/2` (new). **Classification:** `budget_envelope_investor` has
`agent_leaves []` → **pure-resolver** (no two-path, no `merge_agent`), unlike tax_structure. **Base output:**
the compiled outcome is **9 point-summary figures** (no range/breakdown subtrees, no `cash_events` — unlike
the richer FHB `budget_envelope`); at base every field is honestly unknowable (property-price-dependent →
`property_assessment`; `max_property_price_supported` → investor `mortgage_finance` capacity, variant unbuilt;
HAVE-side `gap_or_surplus`/`verdict` → refine turn). So `fill_investor` emits the **all-null/empty scaffold**
+ `calculator` + the **6 cash anchors** (`kb.stamp-duty.calc-by-state`, `kb.investor.deposit-requirements-
investment-loans`, `kb.lmi.calculation`, `kb.buyer-costs.investor-additional-costs`,
`kb.tax.quantity-surveyor-reports`, `kb.tax.entity-setup-costs` — all verified to resolve).
**Verified:** `cash_position_investor_conformance.escript` **31 anchors** (scaffold: 9-field set, 8 nulls +
empty mitigation, input-independence, renderer, 6 anchors, `has_resolver`; Layer-1 conformance vs
`budget_envelope_investor`; **discriminator** — present → investor 9-field set with NO `stamp_duty` key,
absent → FHB `budget_envelope` with `stamp_duty`, the two never cross; no-regression — FHB validates +
`stamp_duty` sub-tree intact, `yield_modelling` stays pure-resolver). **No live model** (pure resolver, no
agent leaf). `cash_duty_conformance` **28/28 byte-identical** (FHB dollar-exact duty unchanged),
`disposition` 79, `outcome` 21+11 all green; `erlang-checker` clean; no recompile (outcome type + anchors
already compiled). **Two seams flagged (not patched):** (1) `total_cash_required` is typed scalar `money`
but the natural base figure is a money_range over the target price range — the **banded-vs-scalar seam**
recurring from yield_modelling/tax_structure; FHB-parity base NEED-side ranges would be a
registry+blueprint+shell redesign, not this resolver. (2) `budget_envelope_investor` has no `cash_events`
field, so the investor acquire-phase financial spine is **design-first (§8.5)** — only disposition's
`dispose_cash_events` + the yield/tax hold events exist on the investor temporal flow. **Next P5-engine
unit:** `mortgage_finance` investor variant (also a shared-name branch — unblocks
`max_property_price_supported`), or `ownership_planning_investor` (NEW module + the P4 `opportunities[]`
seam) — Son's pick. Then P5-activate (base_components/1 + dispatch + intent picker, atomic-last).

**P5-engine 6/suite COMPLETE (2026-06-25) — `ownership_planning_investor` (the hold/operate base
spine; closes the base figure-owner spine: profile → strategy → yield → tax → cash → ownership →
disposition).** A **pure-resolver** figure-owner (`agent_leaves []`), built in `fh_engine_ownership:
fill_investor/2` — a clean sibling on the **unique** component name (no shared-name collision, unlike
`cash_position`; the FHB `fill/2` is untouched → zero regression by construction). **Honest-partial,
not all-null** (unlike `cash_position`-investor's point-shaped outcome): `portfolio_position` carries
two array fields with mode-level, property-agnostic, KB-grounded content — `annual_tax_obligations`
(5 bilingual lines) + `alert_triggers_armed` (4 investor alerts: rent review, refi/equity review,
depreciation refresh, land-tax aggregation) — filled at base (the FHB ownership precedent); the six
post-acquisition figure fields (tracked cash flow, current LVR, equity, diversification, ready-for-next)
are null plan-first. Bilingual copy externalized to a **new `kb.copy.ownership-investor`** doc (12
`{vi,en}` templates; cadences qualitative — the KB frames them "a default, not a deadline"). Renderer
`data-table` (the reachable primary) + the 6 Cluster-S anchors.

**The P4 `opportunities[]` seam — producer half dealt with here (not deferred).** On Son's challenge,
re-grounded the defer against his foundation-first/honest-deferral discriminator (build-but-unconsumed
= honest; unbuilt-foundation = rug): the `opportunities[]` *producer* is a foundation, so it gets built
now — added to the `portfolio_position` schema (recompiled) + emitted `[]` at base (an opportunity is
defined by its `modeled_benefit`, a figure off an owned property → none plan-first; populates Phase B).
Also retyped `annual_tax_obligations` `array<string>` → `array<localized_text>` (validator-enforced
bilingual; matches `disposition.key_assumptions`). **Residual, proven (not asserted):** the shell
renders only `renderers[0]`, so `opportunity-card` is unreached for every dual-renderer component incl.
shipped FHB ownership — the *consumer* half is a scoped shell unit.

**Verified:** `ownership_planning_investor_conformance.escript` 27/27 (scaffold: data-table, 9-field
set, 6 nulls + input-independence, 5 obligations + 4 alerts, `opportunities []`, 6 anchors,
`has_resolver`; Layer-1 vs `portfolio_position` incl. localized-text enforcement; bilingual: every
obligation + alert half a well-formed `{vi,en}`; no-regression: FHB ownership untouched, yield_modelling
stays pure-resolver). Recompile clean (copy doc + schema landed). Regression: `ownership_conformance`
17, `cash_duty` 28 (byte-identical FHB), `cash_position_investor` 31, `disposition` 79, `outcome` 21+11.
`rebar3 compile` + erlang-checker clean. Pure resolver → no live model. **Next P5-engine unit:**
`mortgage_finance` investor variant (shared-name branch — unblocks `max_property_price_supported`), the
last base resolver before P5-activate (base_components/1 + dispatch + intent picker, atomic-last).

## Deferred out (honest — first-exercising instance is Mode B/D, not here)

`off_title_parties[]` (array vs A's scalar `non_buying_partner`), `visa_class`, off-title
`funder{}`, and B/D publishing `firb_required_any` (the F14 close) ride **Mode B** — they have zero
exercising instance in Mode C, and `facts_jsonb` makes their later addition migration-free. See
[`fact-model-unification.md`](fact-model-unification.md) "Mode-C activation".
