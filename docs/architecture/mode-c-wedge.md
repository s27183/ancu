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
| [x] | P5-engine | `mortgage_finance` investor variant (branch the shared resolver) — investment-loan serviceability, IO-vs-PI, DTI cap (Cluster-F KB). **Two-path** (5 `lender_fit` agent leaves); shared-name branch on `strategy_thesis` upstream (FHB body byte-identical); new `lender_fit_investor` sidecar module; live-verified |
| [~] | P5-engine | `yield_modelling` resolver — base-spine presence DONE (`fh_engine_fill` inline, honest-partial all-null `cash_flow_projection` + `calculator` + 5 Cluster-Y anchors); the cash-flow **arithmetic** (NEW module) defers to `property_assessment` (its rent-leaf producer) + the banded-vs-scalar seam |
| [~] | P5-engine | `tax_structure` **two-path** — base-spine presence DONE (`fh_engine_fill` inline: resolver scaffold + `entity_structuring` agent leaf `recommended_entity`, live-verified; the two CGT-determinant **constants** `disposition` reads — `cgt_discount_eligible`/`cost_base_depreciation_clawback` = true; `data-table` + 6 Cluster-T anchors). Deferred to `property_assessment`: `cgt_marginal_rate` (needs an ATO-brackets KB doc + income), `setup_costs`/`annual_compliance_cost` (banded-vs-scalar seam), the 5 property/rent-dependent figures |
| [~] | P5-engine | `cash_position` investor variant — base presence DONE (`fh_engine_cash:fill_investor/2`, branched on the `tax_optimised_structure` discriminator like `disposition`; **pure-resolver**, `agent_leaves []`). The compiled `budget_envelope_investor` is 9 point-summary figures, all honestly null at base (plan-first: no property, no savings); emits `calculator` + the 6 Cluster-Y/T cash anchors. Deferred to `property_assessment` (per-property): the property-price-dependent figures; `max_property_price_supported` → investor `mortgage_finance` capacity (unbuilt); HAVE-side → refine turn |
| [~] | P5-engine | `ownership_planning_investor` — base presence DONE (`fh_engine_ownership:fill_investor/2`, a clean sibling on the UNIQUE name — no discriminator, FHB `fill/2` untouched; **pure-resolver**, `agent_leaves []`). **Honest-partial:** `annual_tax_obligations` (5, bilingual) + `alert_triggers_armed` (4 investor alerts, bilingual) filled from the 6 Cluster-S KB anchors via a new `kb.copy.ownership-investor` doc; the 6 post-acquisition figure fields null at base. **Producer half of the P4 `opportunities[]` seam CLOSED**: field added to the schema (recompiled), emitted `[]` at base (populates per-property); `annual_tax_obligations` retyped `array<localized_text>` (validator-enforced bilingual). Emits `data-table` (the reachable primary). Deferred: the 6 figure fields → `property_assessment`; the **consumer half** (shell renders only `renderers[0]`) → a shell unit |
| [x] | P5-activate | per-blueprint `base_components/1` sequence — `?BASE_COMPONENTS_INVESTOR` (8-component property-agnostic investor spine, DISCRIMINATOR-ordered) + a slug clause over a factored `order/2`; FHB macro byte-identical. Verified: `base_components_investor_conformance.escript` 19/19 (set+order, per-property excluded, FHB unchanged, DAG-walk proves each shared-name discriminator fires investor-side) |
| [x] | P5-activate | Onboarding **dispatch** (`fh_engine_h_plan_cards:blueprint_for/1` selects blueprint+mode by `intent`) **+** **intent picker** (`Onboarding.svelte` gate reshape — intent first, first-home gate owner-occupier-only, branched out-of-scope copy; `buildOnboardingInput` threads intent), atomic-last. Mode-E next-home gap logged |

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

**P5-engine 7/suite COMPLETE (2026-06-25) — `mortgage_finance` investor variant (the LAST base
resolver; the base figure-owner spine is now complete end-to-end).** The first **two-path** investor unit
that is also a **shared-name** branch (both traits at once, unlike the prior units): the component is
literally named `mortgage_finance` in both blueprints with **different outcome shapes** (both typed
`mortgage_plan`, distinct per-blueprint registries) **and** carries **five** `lender_fit` agent leaves
(vs the FHB two). **Dispatch — two local shape-sniffs, no signature change, no new wire field** (the
`cash_position`/`disposition` pattern): `fh_engine_mortgage:fill/2` routes on the `strategy_thesis`
upstream (investor reads `investment_strategy`, FHB reads `scheme_stack`) → `fill_investor/2` (new) vs
`fill_fhb/2` (**pure rename — byte-identical**, zero regression); `merge_agent/2` +
`agent_values_from_outcome/1` route on the `io_vs_pi_recommendation` outcome key (investor-only).
`fh_engine_fill.erl` needs **no edit** (already routes `mortgage_finance` → this module). **The five
agent leaves** (io-vs-P&I, fixed-vs-variable, offset strategy, uses-existing-PPOR-equity, investor lender
shortlist) are surfaced slot-scoped: the io/PI + offset choices land both as the top-level enum field AND
inside `recommended_loan_structure` (**place-don't-recompute** — one agent value, two read positions).
**Resolver half = honest-partial** (§98): borrowing capacity / loan cost are compliance-sensitive figures,
PENDING at base (income/debts/property absent) → `loan_cost_estimate_year_1` null, `debt_optimisations` [];
the loan-structure scaffold's IO term + the refinance framing's LVR conventions are **KB params** (`io_max_
term_years_typical` 5, `usable_equity_target_lvr_pct` 80 / with-LMI 90, retest=true), **no magic literal**;
the property/date-dependent refinance figures null. Emits `summary-card` (`renderers[0]`, the reachable
primary) + the **8 Cluster-F lender/loan anchors** (all verified to resolve). **Sidecar — new
`lender_fit_investor` module** (separate from the FHB `lender_fit`: different leaf set + the 8 investor KB
docs injected): a 5-leaf `LenderFitInvestorLeaves` schema (all `Literal` enums = schema-as-constraint, no
number field → §98), its own ASIC/ACL-disciplined prompt (IO-vs-P&I + offset-on-PPOR decision-support, no
named lender, no rate number), dispatched via the public `fill_mortgage_finance` by the same RO-shape sniff
(`io_vs_pi_recommendation` present → investor) — **no new `reasoning_domain` on the wire** (both arrive as
`lender_fit`). **No blueprint edit** (outcome already compiled) → no recompile; **no new copy doc** (all
user-facing prose lives in the agent leaves). **Verified — three grades:** (1) resolver+merge
`mortgage_finance_investor_conformance.escript` **40/40** (scaffold: summary-card, 7-field set, agent slots
null, debt-opt [], loan-cost null, KB-grounded structure+refinance, 8 anchors, input-independence; Layer-1
vs investor `mortgage_plan`; merge: 5 leaves folded both positions, slot-scoped figures byte-identical,
`agent_values_from_outcome` inverts + idempotent re-merge, merged still validates; no-regression: FHB
summary-card, `recommended_path`=fhg_backed, capacity null, no investor field, FHB 2-leaf merge intact);
(2) regression — FHB `mortgage_conformance` **23/23 byte-identical**, `serviceability` 22,
`cash_position_investor` 31, `ownership_planning_investor` 27, `cash_duty` 28, `disposition` 79, `outcome`
21+11; `rebar3 compile` + `erlang-checker` clean; (3) **LIVE** — a real Opus `lender_fit_investor` fill
(43.5s, metered) authored all five leaves: enums constrained (`interest_only` for the negatively-geared
growth thesis, `variable`, `full_offset_on_this_property`), bilingual `{vi,en}` lender reasoning in natural
register, `approval_likelihood: indicative` (honest at base), **no figure authored**, no named lender / no
advice tone (ASIC/ACL line held), and the public-entry shape-sniff delegation fired correctly. **The base
figure-owner spine is COMPLETE** (profile → strategy → mortgage → yield → tax → cash → ownership →
disposition). **Next: P5-activate** (per-blueprint `base_components/1` sequence + onboarding dispatch by
`intent` + intent picker, atomic-last) — the last step to make investor cards live.

**P5-activate COMPLETE (2026-06-25) — investor cards are LIVE (the three wiring pieces, landed atomically).**
The base figure-owner spine (P5-engine 1–7) was built but unreachable: nothing created investor base turns.
P5-activate is the pure wiring that flips it on, all three pieces in one commit (the doc's **atomic-last**
rule — a shell picker while the engine hardcodes `fhb` would be a silent-wrong rug).
(1) **Base sequence** — `fh_engine_turn:base_components/1` now selects the base SET+ORDER by blueprint slug:
a new `?BASE_COMPONENTS_INVESTOR` macro (the **8-component property-agnostic investor spine** — excludes the
four per-property components that read `property_fit_investor`) + a slug clause over a factored `order/2`;
the FHB macro is **byte-identical**. The order is **discriminator-load-bearing, not merely topological**: the
three shared-name modules (`mortgage_finance`/`cash_position`/`disposition`) sniff the accumulated upstream
(keyed by outcome_type) to pick their investor branch, so each must run AFTER the component producing its
discriminating outcome (`strategy_thesis` before mortgage; `tax_optimised_structure` before cash + disposition;
`budget_envelope_investor` before disposition). All 8 investor resolvers were already registered in
`fh_engine_fill` (`has_resolver`/`resolver/3`) by P5-engine — **no fill edit needed**.
(2) **Onboarding dispatch** — `fh_engine_h_plan_cards:blueprint_for/1` (new) maps the `intent` axis to
{blueprint, mode}: `owner_occupier`→{fhb-domestic-au, A}, `investment`→{investor-domestic-au, C}; threaded
through `create_plan_card` + `start_turn` (replacing the hardcoded `?BLUEPRINT`/`?MODE` macros). FIRB stays
false for both (domestic; per-applicant derivation runs in the profile fill).
(3) **Intent picker + gate reshape** — `Onboarding.svelte`: intent is now the FIRST choice and **reshapes the
gate** — citizen/PR applies to both modes, the first-home gate is owner-occupier-only (meaningless for an
investor), `eligible` = owner_occupier ? (citizenPr && firstHome) : citizenPr. Out-of-scope copy branches:
`!citizenPr` → foreign (Mode B/D, deferred); `owner_occupier && !firstHome` → the **Mode-E next-home gap**
(logged, see below). `buildOnboardingInput` threads the chosen intent; new bilingual i18n keys
(`onboarding.intent.*`, `onboarding.outofscope.foreign`). **Verified:**
`base_components_investor_conformance.escript` **19/19** (set+order = the 8-spine, per-property excluded, FHB
byte-identical; a no-PG **DAG walk** through `fh_engine_fill:resolver/3` proves every outcome validates vs the
investor registry AND each shared-name discriminator's key is present in the upstream BEFORE that component
runs → each produces its investor shape: `io_vs_pi_recommendation`/`lmi_payable`/`taxable_gain`); regression —
`base_turn_order_smoke` (FHB DAG + placements end-to-end), `mortgage_conformance` 23, `disposition` 79,
`outcome` 21+11, all investor suites green; `rebar3 compile` + `erlang-checker` clean; shell — `svelte-autofixer`
clean, `svelte-check` 0/0, `npm run build` green. Proportionate gap (deploy-pass): a full-stack LIVE investor
onboarding turn (HTTP `intent=investment` → gen_statem walk + sidecar + PG + SSE) — the gen_statem/seam
mechanism is blueprint-agnostic + FHB-proven, the two-path sidecar fills are per-component live-verified, and
`blueprint_for/1` is a pure 2-clause map; the only unproven-in-integration link is the HTTP→turn glue.

**P5-activate LIVE-PROVEN (2026-06-25) — the HTTP→turn glue closed in integration (full-stack, real Opus).**
The proportionate gap above is now closed. A new `engine/erlang/test/investor_seam_smoke.escript` (clone of
the Mode-A `seam_smoke` with `intent=investment`) self-boots the engine on `:8092`, mints an ed25519 JWT,
POSTs plan-card creation, and drives the real `/api/engine/*` HTTP/SSE surface through the **8-component
investor base spine** end-to-end against live PG **and the real `planner.py` sidecar** (`FH_PLANNER_SCRIPT`
+ `FH_SIDECAR_PYTHON=.venv/bin/python3` + the `.env` `CLAUDE_CODE_OAUTH_TOKEN`). **All assertions passed.**
Three live Opus fills (metered): `investment_strategy` 27.2s, `mortgage_finance` 51.3s, `tax_structure`
8.3s (all opus/medium). **Live outcomes coherent end-to-end:** `archetype=capital_growth →
gearing=negatively_geared → io_vs_pi=interest_only → entity=personal_sole` (a consistent investor thesis,
no figure leaked, enums constrained). **Asserted:** the 37-event sequence (1 + 8×(3 gate + 1 filled) + **3**
usage + 1 — the three `usage` events land after the three two-path fills, in the discriminator-load-bearing
order); 37 events persisted (stream == SOT); 24 audit rows all `clear`, 9 `two_path` rows (3×3), ASIC
`boundary_held`=1; the 8-component snapshot by investor name; **the Mode-C discriminator proofs** —
`io_vs_pi_recommendation` + `recommended_entity` present, bilingual `{vi,en}` `one_liner`,
`disposition.taxable_gain`/`cgt_status` present, and `cash_position` = `budget_envelope_investor` with **no
`stamp_duty` key** (proves the shared-name discriminator fired investor-side, not FHB); cancel idempotency
(204) + auth rejection (401/403). **One observation flagged (not patched, recorded in the harness comment):**
`fh_engine_compliance:advice_adjacent/1` lists only `mortgage_finance`/`eligibility`, so on the investor
spine `tax_structure` (entity structuring) and `investment_strategy` clear ASIC with `no_advice_surface`
rather than `decision_support_boundary_held` → `boundary_held`=1 (mortgage only; no `eligibility` in Mode C).
The ASIC line is held **at the producer** (§98 figure-tightness + schema-as-constraint enums, live-confirmed
— no figure authored); whether the entity/strategy *attestation* should also record `boundary_held` is a
separate compliance-record refinement, not a gate failure (both clear). **The Mode-C wedge is now proven
full-stack live, EN+VI, against real Opus.**

## Phase B — per-property build plan (the `property_assessment` keystone)

**Status: Slice A + B0/B1 + B2 + B3a/B3b/B3c + C DONE — full-stack live-proven (the 28-event Phase-B
turn PASSES against the real planner, exit 0; the earlier "environment-blocked" read was a stub-config
misdiagnosis, corrected in the B2/C notes); `due_diligence` + `settlement_prep` (both prose-only
schemas) deferred.** The per-property financial
spine now computes end-to-end for an attached property (acquire → hold → dispose), gated only by the
regulated CGT `to_verify`, plus the investor **bid plan** (yield-anchored discipline). The base spine
(P5) owns every property-agnostic
figure; Phase B is what a *specific property* unblocks. Grounded against the live engine: the artifact
already carries `property_assessment`'s registry + the `property_fit_investor` outcome schema (validated
when the investor blueprint went in-scope; all 6 KB anchors resolve). The codebase has Phase-B
*awareness* — `simulate`/`refine` reject `property_type_phase_b`, `refresh`/`rerun` promise "per-property
addenda preserved/untouched" — but these are **reservations against addenda that nothing creates yet**.
Absent: any `properties`/addendum table, attach endpoint, per-property turn, `property_assessment` fill.
`fh_engine_store:snapshot_component/3` writes only `content.components.<id>` (base); there is no
per-property namespace. So Phase B is greenfield *runtime* on an already-compiled *structure*.

### The full Phase-B surface (5 parts)

| # | Part | State |
|---|---|---|
| 1 | **Attachment contract + addendum persistence** — endpoint takes a normalized property_card → writes an addendum | absent (greenfield) |
| 2 | **Phase-B per-property turn** — gen_statem walk over the per-property component set against an attached property | absent |
| 3 | **`property_assessment` two-path fill** → `property_fit_investor` | absent (← **the keystone**) |
| 4 | **Downstream re-fill** of the `both`-scope components now `property_fit_investor` exists — yield cash-flow arithmetic (NEW module), `cash_position` price figures, `tax_structure` rent figures, `disposition` CGT — **+ the banded↔scalar money seam** | resolvers emit null at base; the property branch + the seam decision are absent |
| 5 | **The other 3 per-property components** (`buying_strategy` ✓ Slice C, `settlement_prep` structure-half ✓ Slice C-settle, `due_diligence`) | `buying_strategy` + `settlement_prep` A built; `settlement_prep` B (contract-date input) + `due_diligence` (upload pipeline) deferred |

### Decomposition (sliced by mechanism seam)

- **Slice A — the keystone (build first): #1-minimal + #2 + #3.** Attachment contract + Phase-B turn +
  the `property_assessment` two-path fill. Provable end-to-end: *attach a property → `property_fit_investor`
  live* (viability verdict, rent range, growth/depreciation outlook, strengths/concerns, grade) — directly
  the **Property + Overview tab** content. It defers the figure cluster cleanly behind "`property_fit_investor`
  now exists," and **does not force the banded↔scalar seam** (that bites only when `cash_flow_projection`
  consumes the rent range downstream).
- **Slice B — the figure cluster: #4.** The rent-dependent figures + the banded↔scalar
  cross-contract decision. That decision ripples KB ↔ blueprint ↔ registry ↔ `disposition` consumer ↔
  `calculator` renderer — a docs-first, foundation-first sub-unit of its own (per
  `foundation-first-for-cross-contract-reframe`). **Sub-sliced:**
  - **B0 (the seam) + B1 (the keystone arithmetic) — DONE 2026-06-25** (live-proven, below). B0 decided
    the banded surface; B1 computes the per-property PRE-LOAN rent-economics.
  - **B3a — the POST-loan cash flow — DONE 2026-06-25** (live-proven, below). **Resequenced ahead of B2:**
    grounding showed B2's headline tax figures (negative gearing, tax refund, after-tax cash flow) hang
    off `cash_flow_before_tax_year_1` — a POST-loan figure — so B2 sits *downstream* of the loan. The DAG
    runs `yield_modelling`(4) BEFORE `cash_position`(6) (yield → tax → cash), so the cash-flow loan can't be
    read from cash_position; `yield_modelling` owns a **representative leverage** assumption (price × KB LVR
    × the investor rate, interest-only — = what mortgage_finance would compute per-property). Completes
    `cash_flow_projection`: interest, before-tax cash flow (band, signed), per-week, net-post-loan yield,
    year-5/10 projection, geared position.
  - **B3b — `cash_position` per-property cash-to-complete — DONE 2026-06-25** (live-proven, below).
    `actual_property_price`/`loan_amount`/`lvr`/`lmi_payable`/`total_cash_required` (price-point, scalar
    `money` — NOT banded, the price is exact; same KB 80% LVR convention as B3a). `max_property_price_
    supported` + the HAVE-side → honest-partial null (capacity/savings = refine facts).
  - **B3c — `disposition` per-property — DONE 2026-06-25** (live-proven, below). Re-run disposition in
    the Phase-B turn + **price-aware** (`property_price/2` prefers `property_fit_investor.price` over the
    profile range). The dispose **gross** figures (sale_proceeds, selling_costs, taxable_gain, loan_payout)
    now reflect the ATTACHED property. **Finding (the headline reframe):** the net/full-horizon does NOT
    compute — `cgt_investor` returns `to_verify` whenever the marginal rate is null (income → refine/B2) OR
    `cost_base_depreciation_clawback = true` (the conservative default — the KB defers the clawback dollar
    to a tax agent), so `cgt → null → net_proceeds → null → full_horizon → null`. This is the correct
    ASIC-safe posture, not a gap. So B3c delivered property-specific dispose figures, not "the full-horizon
    computes" (which is structurally `to_verify` until the clawback posture changes).
  - **B2 — `tax_structure` income/cash-flow tax figures — DONE 2026-06-25** (detail below). Unblocked by
    B3a's cash flow: `negative_gearing_active`, `cgt_marginal_rate`, `annual_tax_refund_year_1`,
    `after_tax_cash_flow_*` (= cash flow × marginal rate). The **ATO brackets KB doc already EXISTS**
    (`kb.tax.income-tax-resident-2025-26`, full table — the "unauthored" note was stale), so no KB authoring.
    **Owner:** `tax_structure` owns `cgt_marginal_rate` (computed from `profile.assessable_income` via the new
    `fh_engine_mortgage:marginal_rate/1`, reusing the schedule-indexing module that owns the TAX anchor);
    `disposition` reads it. **Honest-partial:** `negative_gearing_active` lights up off yield's per-property
    cash flow (true iff geared at a loss; null never false — depreciation QS-deferred); the money figures need
    income, which arrives on a **refine turn** (null at property-attach), and `disposition` CGT stays
    `to_verify` while `cost_base_depreciation_clawback = true` regardless of the rate. **NOT in scope (revised
    from the plan):** the entity-cost `setup_costs`/`annual_compliance_cost` are entity-dependent (class b),
    not rent-dependent — left null/scalar, deferred to an entity-cost unit. The announced NG reform flag has
    no outcome field → flagged as a separate blueprint-schema + renderer unit.
- **Slice C — `buying_strategy` investor bid plan — DONE 2026-06-26** (detail below). The first of the three
  trigger-gated per-property components, un-deferred (eager-in-attach + honest-partial, like the figure cluster).
  Foundation-first: authored the prose-only `bid_plan_investor` outcome_schema (10 fields) + the `negotiation`
  planner domain + `kb.copy.buying-strategy`. Resolver owns the **yield-anchored discipline band** (= annual_rent
  × 100 ÷ target_gross_yield, removed from the LLM's reach) + `thesis_alignment`; the one agent leaf is
  `negotiation_style`.
- **Slice C-settle — `settlement_prep` investor checklist (structure half, A) — DONE 2026-06-26** (detail below).
  Resolver-only (zero agent leaves). Grounding revised the "unblocked by `bid_plan_investor`" framing: the
  *dated* path needs contract dates that have no input path (no upload surface built), so A fills the milestone
  structure + the state-conditional insurance rule with every date PENDING, and B (the contract-date input
  surface, a cross-contract feature) is recorded design-first. Foundation-first: authored the prose-only
  `settlement_checklist` schema + `kb.copy.settlement`. `due_diligence` (upload pipeline) + `settlement_prep` **B**
  remain deferred; `due_diligence` still prose-only.
- **Deferred by trigger:** #5 and the real property *sources* (URL-paste = CLAUDE.md item 9; curator push =
  item 8). Slice A proves the contract with a **hand-fed normalized property_card** in a harness — exactly
  how the onboarding turn was proven (`investor_seam_smoke` feeds inputs). The engine's contract is "given a
  property_card, run Phase B"; what *produces* the card is a separate concern.

### Refinement vs the grounding map — `property_assessment` is two-path, not pure-agent

Its outcome splits cleanly: a **resolver half** copies the neutral facts the attachment supplies
(`state/suburb/price/property_type`) and computes the deterministic ratio (`rental_yield_gross_estimate`
= annualized rent ÷ price, at merge-back once the agent's rent range is known); an **agent half** authors
the irreducible judgments (`estimated_weekly_rent_range`, the four verdict enums, `key_strengths`/
`key_concerns`, `investor_grade_overall`). Matches the existing two-path mechanism and keeps the yield
figure computed-not-authored (out of the LLM's reach, per `verify-regulated-figures-by-postcondition`).

### Slice A design specifics

- **Attachment + persistence:** `POST /api/engine/plan-cards/:id/properties` takes the normalized Property
  JSON (the `basics` + strata facts a source would supply) → persists it and runs the Phase-B turn.
  **Addenda as a namespace under `content_jsonb`** — `content.addenda.<property_id> = {property_card,
  components: {…}}`, sibling to base `content.components`, **not a separate table** (CLAUDE.md marks
  `properties` "OPTIONAL — not load-bearing"). This makes the existing "addenda preserved" reservations
  *literal* (the base refresh/rerun sweep touches `content.components`, leaves `content.addenda` alone) and
  needs no new migration. (Confirm the exact `snapshot_component` merge SQL at build.)
- **Phase-B turn:** same `gen_statem` mechanism, component set filtered to `[property_assessment]` for
  Slice A, with the attached property_card threaded into the agent context (planner.py already builds the
  prompt from state + property context + KB anchors).
- **Fill:** register `property_assessment` two-path; agent leaves = rent range + verdicts (bilingual
  `{vi,en}`, constrained enums, KB-grounded); resolver computes the yield ratio at merge-back.
- **Compliance:** runs the FIRB→ASIC→AML gates like every component. Verdicts are decision-support enums
  with no authored money — verify it clears ASIC cleanly; note where it lands in `advice_adjacent/1`.
- **Proof:** a `property_assessment_seam.escript` — attach a hand-fed Cabramatta property_card to a live
  investor card → assert the Phase-B turn runs, `property_fit_investor` produced live (rent range present,
  verdict enum valid, yield = rent÷price, bilingual one-liners), persisted under `content.addenda`,
  audited clear.

### Slice A — LIVE-PROVEN (2026-06-25, full-stack, real Opus)

Built and proven exactly as designed. **Engine:** `property_assessment` is two-path —
`fh_engine_fill` (resolver copies state/suburb/price/property_type + computes `rental_yield_gross_estimate`
in `merge_agent/3` from the agent's rent band ÷ price; `has_resolver`/`agent_values_from_outcome` added);
`fh_engine_turn` gained the `kind => property` init (seeds base outcomes by outcome_type via
`outcomes_by_type/2`, walks `property_components/1` = `[property_assessment]` for Slice A), an addendum
commit dispatch (`property_id` → `snapshot_addendum_component`, events `tag_property`-tagged), and threads
the `property_card` to the sidecar; `fh_engine_store` gained `attach_property/3` (writes
`content.addenda.<pid>.{property_card, components:{}}`, a sibling to base `content.components`, **no new
migration**) + `snapshot_addendum_component/4`; a new `fh_engine_h_attach_property` handler on
`POST /plan-cards/:id/properties` (investor-only gate, price+facts validation, attach-then-turn,
registry-serialized 409); `property_assessment` added to `advice_adjacent/1` (it carries a viability
verdict → ASIC records `boundary_held`). **Sidecar (`planner.py`):** a new `property_fit` reasoning_domain
module + `PropertyFitLeaves` schema (the rent BAND + verdicts/scores/bilingual strengths-concerns —
dispatched by component_id, since the artifact's 4 agent_leaves span two domains valuation+rentability)
+ the six property KB docs wired; the `<output>` block is now per-domain (property_fit DOES author the
rent band, unlike the "no figure" components). **Validator seams confirmed:** `money_range_per_week` /
`percentage` compile to `kind:unknown` (pass gracefully → rent `[lo,hi]`, yield bare number);
`key_strengths`/`key_concerns` are `array<string>` but the string check is graceful, so `{vi,en}` arrays
pass (bilingual-always honored, as `buyer_profile` does).

**`property_assessment_seam.escript` — EXIT 0, all assertions passed.** A live Cabramatta `established_house`
@ $920k attached to a live investor card. Phase-B sequence `turn_started, gate×3, component_filled, usage,
turn_completed` (7 events; one two-path fill, **38.4s** live Opus). Live outcome: rent `[620,720]`/wk,
**yield `3.8%` = `round1(670×52÷920000×100)` exactly** (the §98 proof — resolver-computed, not
agent-authored), verdict `acceptable_investment`, grade `7`, growth `moderate`, bilingual `key_strengths`.
Persisted: addendum under `content.addenda.<pid>` (property_card + the component), base `content.components`
**untouched at 8** (addenda is a sibling); 3 audit rows clear/two_path; ASIC `boundary_held`; auth 401/403.
Regression: `outcome_conformance` (21+11) and `base_components_investor_conformance` (19) green; `rebar3
compile` + `erlang-checker` + planner import clean. **Deferred (unchanged):** Slice B (the figure cluster
+ the banded↔scalar seam), the other three per-property components, and the real property *sources*.

### Slice B0 + B1 — LIVE-PROVEN (2026-06-25, full-stack, real Opus)

**The banded↔scalar seam, decided (B0).** Grounding showed the scalar typing was the *anomaly*: the KB
SOT (`rental-income-modelling`: "surfaced as ranges, not false-precision points"), the shipped
`calculator` renderer (built for `money_range`, collapses `[x,x]` to a point), and `disposition`'s
already-banded surface all said *band* — only the registry typed `cash_flow_projection` scalar. So the
rent-dependent fields are retyped **`money_range`/`percentage_range`** `[lo,hi]` bands (the one exception:
`annual_interest_year_1` stays scalar `money` — it's `loan × rate`, deterministic, not rent-derived).
`percentage_range` is a **new validated figure type** added to the compiler `SCALAR_TYPES`/`NUMERIC_TYPES`
+ the outcome validator (`check_scalar`, a `[lo,hi]` list, alongside `money_range`) + **both lockstep
case-sets** (`tests/outcome_validate.py` + `outcome_conformance.escript`, +4 cases each). The blueprint
schema documents the decision; the artifact recompiled (verified: the 6 fields now banded).

**The keystone arithmetic (B1).** `yield_modelling`'s resolver now **branches on the per-property
keystone**: base (no `property_fit_investor`) → the honest-partial all-null scaffold; Phase-B (after
`property_assessment`) → the banded **PRE-LOAN** rent-economics, each a `[lo,hi]` band **removed from the
LLM's reach** (resolver-computed, KB-grounded constants citing their owning doc): effective income
(`rent×52×(1−vacancy)`, vacancy 3% placeholder default), opex (fixed bands + maintenance `0.5–1.0%` of
value + PM `7.5%` of rent collected), gross yield, net-pre-loan yield. **House/strata branch:** a house
carries full opex; a strata property **nulls opex** (the body-corporate levy is not carried in
`property_fit_investor` → honest-partial, the KB no-double-count + conservative discipline) — income +
gross yield still compute. The **POST-loan figures stay null** (need `budget_envelope_investor.loan_amount`,
a `cash_position`-per-property figure → Slice B3). `disposition`'s `full_horizon_investor` band-propagates
the now-banded `cash_flow_before_tax_year_1` via the existing `money_range/1` coercion (scalar→`[v,v]`, so
**byte-identical for the existing scalar path** — disposition's 79 anchors green). The Phase-B turn's
`property_components/1` gained `yield_modelling` after `property_assessment` (order/2 keeps the read order).

**Verified — three grades.** (1) `yield_modelling_conformance.escript` **53/53** (33 base + 20 B1: exact
house bands `income=[31273,36317]`/`opex=[10445,18624]`/`gross=[3.5,4.1]`/`net=[1.4,2.8]`, strata
income+gross-only, ill-formed→null, post-loan null, Layer-1 conforms with the banded types). (2)
Regression — `outcome_conformance` **25+11** (the +4 `percentage_range` lockstep cases), `disposition` 79,
`base_components_investor` 19, FHB `cash_duty` 28 (byte-identical), `mortgage_conformance` 23,
`resolver_conformance`, `ownership_conformance` 17, `validate_build.py` + `resolver_eval` (8) green; `rebar3
compile` + `erlang-checker` clean; **no planner.py change** (yield_modelling is a pure resolver). (3)
**LIVE** — `property_assessment_seam.escript` EXIT 0: the Phase-B turn now runs **two** components, exact
**11-event** sequence `turn_started, PA[gate×3,filled,usage], yield[gate×3,filled], turn_completed`. Live
Cabramatta house @ $920k: rent `[580,660]/wk` → income `[29255,33290]`, opex `[10294,18397]`, **gross_yield
`[3.3,3.7]` = exact `[580,660]×52÷920k`** (the §98 banded proof), net-pre-loan `[1.2,2.5]`; the band
**brackets** property_fit's `3.5%` scalar (coherence); post-loan null; the banded `cash_flow_projection`
persisted under `content.addenda.<pid>`, **base `yield_modelling` still null** (addendum didn't leak into
base).

### Slice B3a — the POST-loan cash flow — LIVE-PROVEN (2026-06-25, full-stack, real Opus)

**Resequencing finding (drove the order).** Grounding B2 showed its headline tax figures depend on
`cash_flow_before_tax_year_1` (a POST-loan figure), so **B2 sits downstream of the loan** — the tracker's
"B2 before B3" had the dependency backwards. So B3 (the loan) was built first. A second finding settled
*where* the loan lives: the DAG runs `yield_modelling`(4) before `cash_position`(6) (chain yield → tax →
cash, because `tax_structure` reads `cash_flow_projection` and `cash_position` reads `tax_optimised_
structure`), and yield's `dag_reads` include neither's loan — so the cash-flow loan **can't** be read from
`cash_position`. The KB (`cash-flow-modelling-methodology`) assigns interest to the financing structure;
the blueprint's `yield_modelling` params already carry a `loan_costs` block (`loan_amount`,
`interest_rate_assumed`, `interest_only_period_years: 5`). So `yield_modelling` owns a **representative
leverage** assumption — = what `mortgage_finance` would compute per-property — flagged, refined when the
actual deal financing (savings/capacity) is captured.

**What B3a computes.** `yield_modelling`'s per-property branch (house) now completes the POST-loan cluster:
`loan = price × LVR baseline (80% — `deposit-requirements`)`, `rate = OO product rate (`serviceability-basics`,
6.0%) + investment premium (`serviceability-investment-loans`, 0.35pp) = 6.35%`, **interest-only** basis
(`interest-only-vs-pi-investor`) → `annual_interest_year_1 = loan × rate` (a scalar **point** — loan and
rate are points, so interest is `money` not banded, as B0 kept it). Then `cash_flow_before_tax_year_1 =
income − opex − interest` (a signed band), `cash_flow_before_tax_per_week` (÷52), `net_yield_post_loan_pre_
tax` (band %), `year_5`/`year_10` projections (income & opex compounded at the KB 3% growth, interest flat
— indicative bands), and `is_positive_neutral_or_negative_geared_pre_tax` (band sign: wholly-neg → negative,
wholly-pos → positive, straddle → neutral). All financing figures are **KB-read** (`param/2` — no magic
literal, single-source with `disposition`'s amortisation rate). **Strata** stays null for the whole post-loan
cluster (its opex is null — the levy isn't carried). The post-loan branch adds the **4 financing anchors** to
`kb_versions` (9 total) and to the blueprint's `yield_modelling` declaration (declaration ⊇ used).

**Verified.** `yield_modelling_conformance` **67/67** (53 + 14 B3a: exact house `interest=46736`,
`CF=[−34087,−20864]`, `/week=[−656,−401]`, `net-post=[−3.7,−2.3]`, geared=negative; year-5/10 structural —
bands improving over time as rent grows over fixed interest; 9 anchors; strata post-loan all-null). Regression:
`disposition` 79 (its band-propagation consumes `cash_flow_before_tax_year_1` unchanged), `outcome` 25+11,
`base_components_investor` 19, FHB `cash_duty` 28, `mortgage` 23, `ownership_planning_investor` 27,
`validate_build` (gates green with the 4 new yield anchors) — all green; `rebar3 compile` + `erlang-checker`
clean; artifact recompiled. **LIVE** (`property_assessment_seam` EXIT 0): same 11-event Phase-B sequence;
live Cabramatta house — the post-loan cluster asserted resolver-computed (interest = price×80%×6.35%, CF =
income−opex−interest band, per-week = CF÷52, geared consistent with the band sign, year-10 > year-5, the
financing provenance in `kb_versions`).

### Slice B3b — `cash_position` per-property cash-to-complete — LIVE-PROVEN (2026-06-25, full-stack, real Opus)

`fh_engine_cash:fill_investor/2` now BRANCHES on the per-property keystone (the same shape-sniff as
yield_modelling): base (no `property_fit_investor`) → the all-null scaffold (unchanged); per-property → the
**cash-to-complete POINT figures** off the EXACT attached price (so scalar `money`, not banded — the price
is a point, unlike the rent band). `actual_property_price` = price; `loan_amount` = price × 80% LVR baseline
(`deposit-requirements`, the same KB convention B3a uses → they agree by construction); `lvr` = 80;
`lmi_payable` = 0 (no LMI at the 80% baseline); `total_cash_required` = deposit + full stamp duty (no FHB
concession — investor; no foreign surcharge for a domestic investor) + acquisition adders. The adders
(`acquisition_costs_investor`) = registration (exact, per state) + the shared due-diligence/legal lines
(building+pest inspection, conveyancing, lender application fee) at a representative midpoint, **EXCLUDING**
the owner-occupier/holding lines (moving, utility, building insurance — the last is a recurring OPERATING
expense in yield_modelling; no double-count). `max_property_price_supported` (capacity → income) + the
HAVE-side (`gap_or_surplus`, `verdict` → savings) stay honest-partial null (refine facts). Reuses the
existing FHB `stamp_duty`/`duty`/`registration_total`/`cost_param` kernels (no new duty logic); the FHB path
is **byte-identical** (`fill_fhb` untouched). The banded↔scalar seam does NOT bite here — for a specific
property the price is exact, so the scalar `money` typing is correct (no false precision).

**Verified.** `cash_position_investor_conformance` **43/43** (31 + 12 B3b: `price=920000`, `loan=736000`,
`lvr=80`, `lmi=0`, `total_cash` a scalar integer = deposit + duty + adders verified against the EXPORTED
`stamp_duty`/`registration_total` non-tautologically, the HAVE-side null, Layer-1 conforms). Regression: FHB
`cash_duty` **28** (byte-identical), `base_components_investor` 19, `disposition` 79, `outcome` 25+11,
`yield_modelling` 67, `mortgage` 23, `ownership_planning_investor` 27, `validate_build` + `resolver` lockstep
— all green; `rebar3 compile` + `erlang-checker` clean; **no artifact recompile** (no schema/anchor change).
**LIVE** (`property_assessment_seam` EXIT 0): the Phase-B turn now runs **three** components, exact **15-event**
sequence `turn_started, PA[gate×3,filled,usage], yield[gate×3,filled], cash[gate×3,filled], turn_completed`.
Live Cabramatta house @ $920k: `budget_envelope_investor: price=920000 loan=736000 lvr=80 total_cash=222913`
(= deposit 184000 + NSW duty + adders, asserted); persisted under `content.addenda.<pid>`.

### Slice B3c — `disposition` per-property — LIVE-PROVEN (2026-06-25, full-stack, real Opus)

`fh_engine_disposition:fill_investor/3` is now **price-aware** (`property_price/2` reads
`property_fit_investor.price` from upstream, falling back to the profile-range ceiling at base — zero base
regression by construction), and disposition is added to the Phase-B `property_components` (it runs last,
reading the per-property `cash_flow_projection` (B3a) + `budget_envelope_investor` (B3b)). So the dispose
**gross** figures reflect the ATTACHED property: `sale_proceeds = price × growth^H`, `selling_costs`,
`taxable_gain`, and `loan_payout` (which now computes — B3b supplied `loan_amount`).

**The regulated reframe (surfaced before building, Son confirmed).** Grounding showed the headline
`full_horizon_net_position` does NOT compute, and that is *correct*: `cgt_investor`'s clean (computed) case
requires `is_number(cgt_marginal_rate)` AND `cost_base_depreciation_clawback =:= false`. Both fail now —
the marginal rate is null (income → a refine turn / B2) and the clawback is the conservative `true` (the KB
defers the clawback dollar to a registered tax agent) — so `cgt → to_verify → cgt=null → net_proceeds=null
→ full_horizon=null`. The ASIC-safe posture: never assert a net sale position when the CGT hinges on an
unresolved clawback. So B3c is a **correctness improvement for the dispose tab** (property-accurate gross
figures), not the full-horizon net (which is structurally `to_verify` until the clawback posture changes).

**Verified.** `disposition_conformance` **87/87** (79 + 8 B3c: per-property `sale_proceeds` uses the
attached 920k — lo > 1.0M vs the base 800k's 975196; `loan_payout`/`taxable_gain` compute; `cgt_status =
to_verify`; `cgt`/`net_proceeds`/`full_horizon` null; **base unchanged** — no `property_fit_investor` → the
800k ceiling, lo = 975196). Regression: `cash_position_investor` 43, `base_components_investor` 19, FHB
`cash_duty` 28, `outcome` 25+11, `yield` 67, `mortgage` 23, `ownership_planning_investor` 27, `validate_build`
+ `resolver` lockstep — all green; `rebar3 compile` + `erlang-checker` clean; no artifact recompile. **LIVE**
(`property_assessment_seam` EXIT 0): the Phase-B turn now runs **four** components, exact **19-event** sequence
(PA two-path + yield/cash/disposition resolvers). With the onboarding carrying `hold_horizon_years: 10`,
live disposition: `sale_proceeds=[1121475,1498583]` (= attached 920k × growth^10 — the price-aware proof),
`cgt_status=to_verify`, `full_horizon=null` (regulated-gated). *(Observed: the base turn's ~70s of live
sidecar fills can occasionally trip the harness SSE idle window — a flaky environmental timeout, not a
defect; the rerun passed EXIT 0.)* **Deferred:** B2 (the income/cash-flow tax figures — negative gearing,
after-tax cash flow; needs income on a refine turn for the marginal rate), the other three per-property
components, the real property *sources*. **The per-property financial spine is now complete end-to-end**
(attach → cash-to-complete + banded cash flow + property-specific dispose), the only gap being the
regulated CGT `to_verify`.

### Slice B2 — `tax_structure` income/cash-flow tax figures — DONE (2026-06-25)

**The income/cash-flow tax figures, refreshed per-property.** `tax_structure` now computes its rent/income-
dependent figures (class a): `negative_gearing_active`, `cgt_marginal_rate`, `annual_tax_refund_year_1`,
`after_tax_cash_flow_year_1`/`_per_week`. Each is honest-partial on its inputs:
- **`negative_gearing_active`** PLACES yield's gearing classification (`is_positive_neutral_or_negative_
  geared_pre_tax`) — `true` iff `negative`, else **`null` never `false`** (depreciation is QS-deferred →
  a cash-positive property can still be tax-negative, so the tax position is undetermined). Lights up on the
  per-property turn (needs only the cash flow).
- **`cgt_marginal_rate`** (scalar `percentage`) — computed from `profile.assessable_income` via the new
  exported `fh_engine_mortgage:marginal_rate/1` (bracket marginal % + 2% Medicare above the low-income
  threshold), reusing `find_band`/the TAX anchor the one schedule-owning module holds. `tax_structure` owns
  it; `disposition` reads it (no second computer). **Null until income** — plan-first onboarding carries none,
  so it lands on a refine turn (the same honest-partial as borrowing capacity).
- **the after-tax trio** (bands, retyped `money → money_range` in the outcome_schema — the B0 banded surface,
  since they derive from the banded cash flow): `after_tax = Cf × (1 − r)`; `refund = −r × Cf`. Computed only
  when negatively geared AND the rate is known; depreciation is excluded from the loss (QS-deferred) →
  understates the refund → more-negative after-tax = the conservative direction. Every figure resolver-
  computed, removed from the LLM's reach (§98).

**The runtime wiring (the part that made B2 reach a real turn).** Grounding found `tax_structure` was NOT in
the Phase-B `property_components` set — so it never re-ran per-property and B2 would have been inert ("build
green ≠ loaded/selected"). Fix: add `tax_structure` to the set in canonical order (PA → yield → **tax** →
cash → disposition). But it's two-path (the entity agent leaf), and the entity is a **base** judgment, not
per-property — re-invoking the sidecar per-property would waste a call and risk drift. So the turn's two-path
handling now decides reuse-vs-fresh via `two_path_stored_leaf/2`: on a `property` turn a two-path component
whose outcome_type is already in the base seed (tax_structure, scope:both) **reuses the stored entity**
(resolver-only refresh — re-run the resolver over the per-property cash flow, re-attach the entity via
`agent_values_from_outcome → merge_agent`, **no sidecar/LLM/usage**), while a per-property component with no
base outcome (`property_assessment`) runs the agent. base_resolver keeps reusing from `existing_outcomes`;
base/other stay fresh.

**Two stale comments corrected in-flight:** the "ATO brackets KB UNAUTHORED" note (`income-tax-resident-2025-
26` exists, Mode-A-authored, explicitly reusable by C/D), and the class-(b) deferral framing (setup_costs/
annual_compliance_cost are entity-dependent, out of B2's rent scope — left null/scalar). **One flag, not
silent scope:** the announced NG reform (limited to new builds 1 Jul 2027; an established post-Budget purchase
loses the wage offset) has no outcome field — a separate blueprint-schema + renderer unit, material to the
wedge's own target case.

**Verified.** `tax_structure_conformance` **61/61** (39 base + 22 B2: drives the REAL `yield_modelling`
producer for a negatively-geared house, then exercises no-income → gearing lights up / money figures null,
income → `marginal_rate(120000)=32`, refund/after-tax bands = `Cf × (1−r)` / `−r × Cf`, positive-geared →
`negative_gearing_active` null never false). New no-PG **`phase_b_wiring_smoke` 16/16** proves the Phase-B
machinery below the live LLM: the DAG position (tax after yield, before cash/disposition), the reuse-vs-fresh
decision matrix (`two_path_stored_leaf/2`), and the reuse-refresh composition (entity reused + figures
refreshed off the per-property cash flow — replicating the gen_statem reuse branch exactly). Regression all
green: `yield` 67, `cash_position_investor` 43, `disposition` 87, FHB `cash_duty` 28, `outcome` 25+11,
`resolver` lockstep, python `outcome_validate` 36; `base_turn_order`/`refine`/`simulate` smokes (the
base_resolver/resolver-only paths the two-path refactor touches) green; `rebar3 compile` + `erlang-checker`
clean; artifact recompiled (3 fields → `money_range`).

**Full-stack seam — was a STUB-config issue, now PASSES live (corrected 2026-06-26).** `property_assessment_
seam` was failing at `property_assessment`'s rent band coming back `null` (line 144). The original note here
called this "environment-blocked / degraded live LLM" — **that was a misdiagnosis** (a cause asserted without
reading the ground truth, [[debug-ground-truth-before-theorizing]]). The actual cause: the seam was running the
**stub** sidecar. `fh_engine_turn:planner_script/0` defaults to `planner_stub.py` when `FH_PLANNER_SCRIPT` is
unset (and `.env` doesn't set it); the stub returns every agent leaf `null` by design (the `usage` event
recorded `"model": "stub", 0 tokens` the whole time — the tell I should have read). The "committed baseline
fails identically" fact was real but meant "both ran the stub," not "the model is degraded." **Run against the
real planner** (`FH_PLANNER_SCRIPT=engine/python/planner.py` + `FH_SIDECAR_PYTHON=.venv/bin/python3`) the seam
**PASSES** (exit 0; real Opus authored the rent band). The event
count moved 23 → **28** when Slice C added `buying_strategy` (below).

### Slice C — `buying_strategy` investor bid plan — DONE (2026-06-26)

**The first of the three remaining per-property components — un-deferred.** The plan marked
`buying_strategy`/`due_diligence`/`settlement_prep` "deferred by trigger" (bid readiness / doc upload /
contract signed). Grounding showed `buying_strategy` is the dependency-clean head (`settlement_prep` reads its
`bid_plan_investor`; `due_diligence` is genuinely blocked on the unbuilt upload pipeline) and that it fits the
figure-cluster pattern: eager in the property-attach turn, honest-partial, the "bid readiness" trigger becoming
a refine-turn refinement rather than a gate on existence. The defining value is **yield-anchored bid
discipline**.

**Foundation-first (the schema didn't exist).** `bid_plan_investor` was *prose-only* in the blueprint ("same
as Mode A `bid_plan` + 2 fields") — no `outcome_schema` fenced block, so the compiler never materialized it
(not in the registry). Step 1 was authoring the explicit 10-field block; same for the planner (no `negotiation`
reasoning_domain existed). The two other deferred components are still prose-only by the same token.

**The figure posture (§98, [[verify-regulated-figures-by-postcondition]]).** Every money figure is
resolver-computed in the new `fh_engine_buying` module and **removed from the LLM's reach** — the agent schema
(`NegotiationLeaves`) carries only `negotiation_style`, so it has no slot for a price:
- **`yield_anchored_max_price`** (`money_range`) = `annual_rent × 100 ÷ strategy_thesis.target_gross_yield`, a
  **band** because rent is a band (the B0 convention). `max_bid_value` / `walk_away_price` ARE this band — the
  discipline line ("above this your thesis breaks"), **not** "bid this".
- **`thesis_alignment`** (enum) classifies the attached price against the band: `aligned` (≤ low end),
  `stretched` (within), `misaligned` (> high end).
- **`conditions_to_request`** / **`max_bid_reasoning`** are bilingual via the new `kb.copy.buying-strategy`
  doc (no English/VI literal in code, the `fh_engine_i18n:subst` pattern); **`red_flags_to_monitor`** PLACES
  `property_fit_investor.key_concerns` ({vi,en} already — place-don't-recompute).
- **Honest-partial:** absent rent OR yield → anchored figures null; absent price → alignment null;
  `max_bid_confidence` null (market depth not wired). No figure fabricated.

**The ASIC/ACL grounding (corrected from reflex).** A property bid figure is **not** an ASIC/AFSL matter — real
property is not a financial product; the AFSL/ACL personal-liability line governs the *finance/credit* side
(`mortgage_finance`/`eligibility`). The constraint here is **ACL misleading-conduct**, met by computing from KB
methodology + the bilingual decision-support framing. `buying_strategy` is still added to
`fh_engine_compliance:advice_adjacent/1` (→ ASIC `boundary_held`) as a consistent decision-support hedge.

**Runtime wiring.** Added to `property_components/1` last (PA → yield → tax → cash → disposition →
**buying_strategy**); per-property scope → `two_path_stored_leaf/2` returns `fresh` (its `bid_plan_investor`
outcome_type is not a base seed) → the sidecar runs for the one negotiation leaf. `fill_path = two_path`. The
planner gains the `negotiation` domain (KB: `kb.investor.bid-discipline` + `kb.negotiation.patterns-by-market-
condition`; the style grounds in `thesis_alignment` — discipline when stretched/misaligned), `NegotiationLeaves`,
`_BUYING_COMPONENT`, `fill_buying_strategy`, and the `_FILLERS["negotiation"]` dispatch.

**Verified.** New **`buying_strategy_conformance` 37/37** (the worked example: rent `[620,720]` @ 4.0% target →
anchored band `[806000, 936000]`; `$920k` → `stretched`; the full aligned/stretched/misaligned classification
incl. boundaries; honest-partial nulls; Layer-1 conformance of scaffold + merged; two-path merge folds only the
style, an adversarial stray price key is dropped §98). **`phase_b_wiring_smoke` 19/19** (DAG position + the
`fresh` decision for `buying_strategy`). Regression green: `tax_structure` 61, `outcome` 25+11, `disposition`
87, `base_components_investor` 19; `rebar3 compile` + `erlang-checker` (new module) clean; planner imports with
the negotiation filler; artifact recompiled. **Full-stack: the live seam PASSES against the real planner**
(exit 0, real Opus — rent `[590,670]`, `negotiation_style` authored live; `buying_strategy` fires last as
two-path-fresh, gate×3 + filled + usage). The earlier "environment-blocked" read was a stub-config
misdiagnosis (see the corrected B2 note above).

**The `target_gross_yield` unblock (a) — what made the anchor non-dormant.** Implementing `buying_strategy`
walked a spec seam: its defining figure (`yield_anchored_max_price`) needs `target_gross_yield`, which was a
hardcoded scaffold `null` in `investment_strategy` that **nothing computed** (the first live run showed
`anchor=null` — `buying_strategy` honest-partialled correctly, but the value was dormant). Fix (Son's call,
option (a)): `target_gross_yield` is now **derived in `merge_agent(investment_strategy)` from the agent's
archetype** via a new **labelled-placeholder** KB doc `kb.investor.target-yield-by-archetype` (indicative
planning defaults — `cash_flow` 5.5 / `dual_income` 5.0 / `value_add` 4.5 / `balanced` 4.0 / `capital_growth`
3.0 / `land_banking` null; `is_placeholder: true`, the [[capital-growth-bands]] pattern — **not** market-
sourced, a tracked re-ground obligation). The archetype is the agent's; the mapping to a number is the
resolver's → the figure stays out of the LLM's reach (§98). This keeps the yield discipline from being silent
at base; the investor's own stated target (a future refine input, option (c)) would override it.

**Still deferred:** `due_diligence` (upload pipeline) and `settlement_prep` (reads `bid_plan_investor`, now
available) — both prose-only schemas. *(settlement_prep's structure-now half is built next — Slice C-settle below.)*

### Slice C-settle — `settlement_prep` investor checklist (structure half, A) — DONE (2026-06-26)

**The honest split — A built now, B recorded design-first.** Grounding revised the plan's "settlement_prep
unblocked because it reads `bid_plan_investor`" framing. The component's *defining* output — the **dated**
settlement critical path with at-risk detection — depends on `contract_signed_date` + `settlement_date`, which
arrive `<from_document>` from a signed contract. A whole-engine grep confirmed **no contract-date / upload input
path exists**: the only Phase-B input is the source-supplied `property_card` of *neutral property facts*, and
contract dates are facts about the user's *transaction* (a different layer). So shipping a date-less skeleton as
"done" would be a rug ([[honest-deferral-not-rug]] — it removes the feature's defining capability). The split:

- **A (built):** the **knowable structure now** — the standard settlement critical-path milestone sequence +
  dependency DAG (KB-grounded, property-generic), the investor-specific milestones (entity-setup conditioned on
  the upstream `recommended_entity`; QS / depreciation / PM / landlord-insurance always-applicable), and the
  **state-conditional building-insurance-timing rule**. Every date PENDING (`dates_status: pending_contract`,
  `settlement_date` null, `at_risk_milestones` []); `next_action_for_user` asks the user to supply the dates.
- **B (design-first, deferred):** a **per-property transaction-input surface** (user-attested contract dates, or
  later document-extraction) that flips `dates_status` to `active` and lights up the dated path + at-risk
  detection + the swimlane projection. B is a **cross-contract feature** (engine↔shell API for submitting dates,
  a shell date-entry surface, addendum persistence for transaction facts distinct from the `property_card`) →
  pin the contract on paper first per [[foundation-first-for-cross-contract-reframe]], not bolt-on.

**Foundation-first (the schema didn't exist).** `settlement_checklist` was prose-only in the investor blueprint
("same as Mode A with added investor milestones") — never compiled into the registry (Mode-A `settlement_prep`
is itself unbuilt, so "same as Mode A" pointed at nothing). Step 1 authored the explicit fenced 7-field block
(`dates_status` enum, `critical_path_milestones`/`investor_milestones` as `array<object>`, `insurance_timing_rule`
`localized_text|null`, `at_risk_milestones`, `settlement_date date|null`, `next_action_for_user`).

**Resolver-only (zero agent leaves).** Unlike `buying_strategy` (two-path), `settlement_prep` has no
`reasoning_domain` — the whole outcome is deterministic, so **no planner domain was added**. New
`fh_engine_settlement` module; `fill_path = resolver` (no sidecar, no `usage`). NOT `advice_adjacent` (milestones
/ dates / insurance-timing are process & statutory facts) → ASIC records `no_advice_surface`, the catch-all
pass-through, never `boundary_held`.

**The state-conditional insurance fix.** The insurance rule branches on the property state, resolver-selected
from `kb.insurance.timing-of-risk-pass.risk_passing_by_state` (NSW/VIC → from settlement; **QLD → the day after
contract**; a known other state → the universal lender-overlay; unknown → null). This *is* the fix that KB doc
flagged as "the blueprint's single `derived_from: settlement_date` hint is wrong for QLD — surfaced for a
separate blueprint fix." Strata lots (apartment/unit) get the contents-only note appended. Bilingual throughout
via a new `kb.copy.settlement` copy doc (`fills: []`; the milestone names, investor why-lines, per-state
insurance rules, and `next_action` — Vietnamese authored for register, not transliterated).

**Verified.** New **`settlement_prep_conformance` 39/39** (renderer + the six read anchors + zero agent leaves;
the nine-milestone DAG with correct dependencies, dates PENDING; entity-setup conditioned company/trust→applicable
vs personal_sole/joint/null→not; the state-conditional insurance rule incl. SA-generic, null-state, strata-append;
Layer-1 conformance of enum/array<object>/localized_text|null/date|null; no-upstream honest-partial). **`phase_b_
wiring_smoke` 21/21** (settlement_prep last, after tax_structure). Regression green: `validate_build`,
`outcome_conformance` 25+11, `base_components_investor` 19; `rebar3 compile` + `erlang-checker` (new module) clean;
artifact recompiled (111 KB entries, +1 for the copy doc) and `settlement_prep` PROVEN in the investor registry
(`agent_leaves: []`, outcome fields present). **Full-stack: the live seam PASSES against the real planner** (exit
0, real Opus — event count moved 28 → **32**; `settlement_prep` fires last as resolver-only, gate×3 + filled, NO
usage; live NSW property → the NSW insurance rule rendered, `dates=pending_contract`, `milestones=9+5`).

**Still deferred after C-settle:** `settlement_prep` **B** (the contract-date input surface — design-first) and
`due_diligence` (blocked on the upload pipeline) — `due_diligence` still prose-only.

## Deferred out (honest — first-exercising instance is Mode B/D, not here)

`off_title_parties[]` (array vs A's scalar `non_buying_partner`), `visa_class`, off-title
`funder{}`, and B/D publishing `firb_required_any` (the F14 close) ride **Mode B** — they have zero
exercising instance in Mode C, and `facts_jsonb` makes their later addition migration-free. See
[`fact-model-unification.md`](fact-model-unification.md) "Mode-C activation".

## Mode-E gap (surfaced at P5-activate onboarding gate)

The P5-activate intent gate (`Onboarding.svelte`) splits owner-occupier (still first-home-gated →
Mode A) from investor (citizen/PR only → Mode C). That leaves one domestic cell **out of scope by
construction**: *citizen/PR · NOT first-home · buying to live in* — a **repeat / next-home
owner-occupier** (upsizer, downsizer, relocator). It maps to none of the four modes: Mode A is
first-home-only (its FHB schemes — FHG, FHSS, first-home stamp-duty concessions — would assert
benefits this buyer can't claim), and Mode C is the investor frame (yield / gearing / CGT / tax
structure — wrong for a home to live in). Routing this segment to either blueprint produces wrong
figures, so the gate correctly shows the calm "coming soon" out-of-scope note rather than forcing a
mismatched plan.

Closing it is a **new blueprint** — provisional **Mode E (domestic next-home owner-occupier)**:
shaped like Mode A minus the first-home schemes, plus equity-from-current-home / bridging finance /
CGT-on-sale-of-the-existing-home. It is a **roadmap decision, not a wedge task** — logged here so the
gap is explicit, not silently wired around. No engine, blueprint, or KB work is in scope now.
