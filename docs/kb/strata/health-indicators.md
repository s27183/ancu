---
slug: kb.strata.health-indicators
effective_from: 2025-07-01
last_verified: 2026-06-02
---

# Strata / owners-corporation health — the adequacy rubric

For an apartment or townhouse in a **strata scheme** (NSW), **owners corporation** (VIC) or **body corporate** (QLD), the scheme's **financial and physical health** determines whether the buyer's levy stays stable or is hit by a **special levy** for works the fund can't cover. The single most important metric is whether the **capital-works / sinking / maintenance fund is adequately funded against a forward plan**. This doc owns **the rubric for assessing scheme health — what "good" looks like and how to read the sinking-fund position**; it grounds the `property_assessment` parameters `strata_or_building.{sinking_fund_balance, special_levies_in_last_3_years, structural_red_flags}` (interpreting whether they're healthy) and feeds the `due_diligence` review. The **specific red flags when reading an actual strata report** are owned by `kb.strata-report.red-flags`; this doc owns the **health framework** they're read against.

## The regulated funding backbone — what "adequately funded" means

Each state requires a scheme to plan its major-works funding forward. A **healthy** scheme funds its levies to meet that plan; an under-funded one defers the cost into a future special levy:

- **NSW (Strata Schemes Management Act 2015).** Every scheme has an **administrative fund** (day-to-day) and a **capital works fund** (formerly "sinking fund", for major repair/replacement). The scheme must prepare a **10-year capital works fund plan** in the standard form, **reviewed at least every 5 years** and considered at each AGM. Adequacy = the capital works fund is on track against that 10-year plan.
- **QLD (Body Corporate and Community Management Act 1997; Standard Module Regulation 2020, s160(3)).** A body corporate has an **administrative fund** and a **sinking fund**; the sinking fund budget must reserve to meet anticipated major expenditure over **at least the next 9 years after the financial year**. Adequacy = the sinking fund tracks that ≥9-year forecast.
- **VIC (Owners Corporations Act 2006).** **Tier 1 and tier 2** owners corporations (broadly, more than 50 lots) **must** have a **maintenance plan** and a **maintenance fund**; smaller tiers may have one voluntarily. Adequacy = the maintenance fund is funded to the plan.

## Health indicators (the rubric dimensions)

- **Sinking / capital-works fund adequacy — the core metric.** Is the fund balance reasonable for the building's **age, size and amenities**, and on track against the forward plan? A large, ageing building with lifts and a pool but a thin fund is a special-levy waiting to happen.
- **Levy level in context.** Fees should be **proportionate** to the building. Suspiciously **low** levies are often a warning, not a bargain — they can signal deferred maintenance and under-funding that will surface as a special levy.
- **Special-levy history.** Recent or pending special levies indicate the regular levies weren't enough — either past under-funding or a major works program now underway.
- **Insurance.** Current **building insurance to replacement value** is mandatory; lapsed or under-insurance is a serious health flag.
- **Financial position.** Owner **arrears**, operating deficits, or a body-corporate loan all stress the funds' ability to meet obligations.
- **Physical / structural.** Recent major works completed vs deferred; building **defects** — especially **combustible cladding** and waterproofing in newer buildings — are large latent costs.
- **Governance.** A functioning committee, competent strata/OC management, and a clean dispute history; frequent manager turnover or unresolved disputes are governance flags.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The apartment is often the Mode-A entry property — and the levy is only stable if the scheme is healthy.** A Mode A buyer comparing apartments should read scheme health as a first-class factor: a well-funded sinking fund means the disclosed levy is the real cost; an under-funded one means a special levy is a hidden future cost on top.
- **A low levy is not automatically good.** The plan frames a very low levy as something to investigate (is the fund adequate?), not a saving — the most common way a first-home apartment buyer is later surprised.
- **Information, not advice.** The plan explains what makes a scheme healthy and points the buyer to obtain the strata records / report and have them reviewed; it does not certify a specific scheme.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The strata_or_building leaves are populated from the uploaded records; whether they indicate a **healthy** scheme is agent-reasoned against this rubric.

```jsonc
{
  "fills": [],
  "parameters": {
    "fund_adequacy_is_core_metric": { "type": "bool", "value": true, "note": "the single most important strata-health metric: is the capital-works/sinking/maintenance fund adequately funded against its forward plan? Under-funding → special-levy risk" },
    "nsw_capital_works_plan_years": { "type": "integer", "value": 10, "note": "REGULATED (NSW, Strata Schemes Management Act 2015) — mandatory 10-year capital works fund plan, in standard form, reviewed at least every 5 years and considered at each AGM" },
    "nsw_capital_works_plan_review_years": { "type": "integer", "value": 5, "note": "REGULATED (NSW) — the 10-year capital works fund plan must be reviewed at least every 5 years" },
    "qld_sinking_fund_forecast_years": { "type": "integer", "value": 9, "note": "REGULATED (QLD, BCCM (Standard Module) Regulation 2020, s160(3); current as at 1 Aug 2025) — the sinking fund budget must reserve to meet anticipated major expenditure over at least the next 9 years after the financial year. NB: the superseded 2008 Standard Module Reg had this at s139" },
    "vic_maintenance_plan_required_tiers": { "type": "array<integer>", "value": [1, 2], "note": "REGULATED (VIC, Owners Corporations Act 2006) — tier 1 (>100 lots) and tier 2 (51–100 lots) owners corporations must have a maintenance plan and maintenance fund; tiers 3–5 may voluntarily" },
    "low_levy_can_signal_underfunding": { "type": "bool", "value": true, "note": "CONVENTION — a suspiciously low levy often signals deferred maintenance / an under-funded fund (a future special levy), not a saving; investigate rather than treat as a bargain" },
    "building_insurance_to_replacement_value_mandatory": { "type": "bool", "value": true, "note": "REGULATED — schemes must hold building insurance to replacement value; lapsed/under-insurance is a serious health flag" },
    "health_dimensions": { "type": "array<string>", "value": ["fund_adequacy", "levy_level_in_context", "special_levy_history", "insurance_currency", "financial_position_arrears", "physical_structural_defects", "governance"], "note": "the rubric dimensions the agent reasons over to assess scheme health" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The strata_or_building values come from the records; the health verdict is agent-reasoned against this rubric. Same pure-reference shape as the other `property_assessment` / `due_diligence` anchors.
- **REGULATED funding backbone + CONVENTION rubric.** The fund-planning horizons (NSW 10-yr / 5-yr review, QLD ≥9-yr, VIC tier 1&2 plan+fund) are statutory and verified against the state authorities (see Sources). The interpretive dimensions (low-levy-as-warning, proportionate-to-building) are convention, tagged so the agent presents them as judgement, not law.
- **Single-owner — the rubric vs the report vs the cost.** This doc owns **what a healthy scheme looks like and sinking-fund interpretation**. The **specific red flags when reading an uploaded report** → `kb.strata-report.red-flags` (which reads against this rubric). The **levy as a recurring cost line + indicative ranges** → `kb.ongoing-costs.rates-water-strata`. The **interior-only maintenance reserve** (no double-count with the levy) → `kb.maintenance.budget-by-property-type`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities / legislation):**

- NSW Government — *10-year capital works fund plan* (mandatory standard-form plan, reviewed at least every 5 years, considered at each AGM) — https://www.nsw.gov.au/housing-and-construction/strata/strata-publications/10-year-capital-works-fund-plan-strata
- NSW Government — *Your strata levies, finances and insurance* (administrative fund + capital works fund; insurance) — https://www.nsw.gov.au/housing-and-construction/strata/living/levies-finances-insurance
- *Body Corporate and Community Management (Standard Module) Regulation 2020* (Qld), **s160(3)** — "the sinking fund budget must … reserve … amounts necessary to be accumulated to meet anticipated major expenditure over at least the next 9 years after the financial year" (current as at 1 Aug 2025; supersedes the 2008 Standard Module Reg, where this was s139) — https://www.legislation.qld.gov.au/view/pdf/inforce/current/sl-2020-0233
- Queensland Government — *Sinking fund* (consumer-facing summary of the ≥9-year reserve requirement) — https://www.qld.gov.au/law/housing-and-neighbours/body-corporate/finance-insurance/funds/sinking
- Consumer Affairs Victoria — *Owners corporation maintenance plan* (tier 1 and tier 2 owners corporations must have a maintenance plan and maintenance fund) — https://www.consumer.vic.gov.au/housing/owners-corporations/property-maintenance/maintenance-plan
- Consumer Affairs Victoria — *Tiers of owners corporations* (tier definitions by lot number) — https://www.consumer.vic.gov.au/housing/owners-corporations/tiers-of-owners-corporations
- ASIC Moneysmart — *Strata levy* (glossary: a fee owners pay for management of the common property of a strata-titled building) — https://moneysmart.gov.au/glossary/strata-levy
