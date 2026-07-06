---
slug: kb.investor.land-tax-aggregation
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/understanding-land-tax/how-land-tax-is-calculated
    retrieved: 2026-07-06
  - url: https://www.sro.vic.gov.au/land-tax
    retrieved: 2026-07-06
  - url: https://qro.qld.gov.au/land-tax/about/overview/
    retrieved: 2026-07-06
---

# Land-tax aggregation

Land tax surprises investors because it isn't assessed property-by-property — it's assessed on the **total** taxable land an owner holds in a state, which means a second property can trigger (and amplify) a tax the first never did. This doc owns the **aggregation behaviour** — how a state pools an owner's holdings, why it pushes the owner up a progressive scale, and the interstate and entity nuances. The per-state **thresholds and rates** are owned by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) and consumed by the resolver, not re-stated here. It grounds `ownership_planning_investor.lifecycle_alerts.land_tax_aggregation_warning` and the resolver's land-tax estimate. It is a **reference** doc — the figure is **resolver-computed** from the T doc's thresholds; this doc asserts no rate. Informational; not tax advice.

## How aggregation works

- **One owner, one state, one assessment.** Each state aggregates the **total taxable land value** an owner holds in that state — on the unimproved/site value, as at a fixed date (NSW and VIC: midnight 31 December; QLD: midnight 30 June) — and assesses land tax on the **sum**, above the state's tax-free threshold. The thresholds and the progressive rate scale are the T doc's.
- **The PPOR is generally exempt.** A principal place of residence is exempt in the assessment in most states — so the family home usually doesn't count toward the aggregate. Available to a domestic (resident) investor (Mode C); a foreign/absentee owner faces surcharges (Mode D).
- **A second property has two effects.** It (a) adds its land value to the aggregate — possibly crossing the threshold for the first time — and (b) because the scale is **progressive**, lifts the marginal land-tax rate applied across the *whole* holding. The marginal cost of the next property's land tax is therefore higher than the average — the aggregation surprise.
- **Land in different states is NOT pooled across states.** Each state assesses only the land within it; holdings in NSW and QLD are assessed separately, each against its own threshold. This is why **interstate diversification can lower aggregate land tax** — a genuine planning consequence (and one reason `portfolio_diversification_strategy` includes `different_state_diversify`), surfaced as information, not a recommendation to do so.

## Entity and ownership nuances

- **Trusts and companies aggregate differently.** Several states apply special-trust surcharge rates and/or no tax-free threshold to land held in trust, and group related companies. The detail is the T doc's and the entity-comparison doc's ([`kb.tax.entity-comparison-personal-trust-company-smsf`](../tax/entity-comparison-personal-trust-company-smsf.md)); the aggregation interaction is flagged so structuring (decided at strategy stage) accounts for land tax.
- **Joint ownership** is assessed under each state's joint-owner rules — flagged, detail deferred to the state revenue office.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The second property's land tax is the surprise.** The plan warns that aggregation can trigger land tax the first property avoided, and that the progressive scale raises the rate across the whole holding — so the holding cost of scaling is shown honestly.
- **Interstate holdings aren't pooled.** The plan notes that diversifying across states keeps each holding under its own threshold — surfaced as a factual consequence of how aggregation works, not as advice to diversify.
- **Structure affects aggregation.** The plan flags that trust/company holdings aggregate differently (surcharges, no threshold), pointing to the tax docs, so the entity decision accounts for land tax.
- **Figure from the SOT, not asserted.** The land-tax estimate is resolver-computed from the per-state thresholds in the tax doc; SA/WA/TAS/ACT scales there are `to_verify`. Information, not tax advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the land-tax figure is **resolver-computed** in `ownership_planning_investor` by consuming the per-state thresholds/rates owned by `kb.tax.land-tax-by-state`. This doc supplies the aggregation behaviour the resolver applies.

```jsonc
{
  "fills": [],
  "parameters": {
    "aggregation_is_per_owner_per_state": { "type": "bool", "value": true, "note": "REGULATED principle — each state aggregates the owner's TOTAL taxable land value in that state (site value, at a fixed date: NSW/VIC 31 Dec, QLD 30 Jun) and assesses above the state threshold; thresholds/rates owned by kb.tax.land-tax-by-state" },
    "ppor_generally_exempt": { "type": "bool", "value": true, "note": "the principal place of residence is generally exempt from the assessment (Mode C resident); foreign/absentee surcharges apply for Mode D" },
    "progressive_scale_lifts_marginal_rate": { "type": "bool", "value": true, "note": "a second property adds to the aggregate AND, because the scale is progressive, lifts the marginal rate across the WHOLE holding — the marginal land-tax cost of the next property exceeds the average" },
    "not_pooled_across_states": { "type": "bool", "value": true, "note": "land in different states is assessed separately, each against its own threshold; interstate diversification can lower aggregate land tax — a factual consequence, surfaced not recommended (portfolio_diversification_strategy.different_state_diversify)" },
    "thresholds_and_rates_owner": { "type": "string", "value": "kb.tax.land-tax-by-state", "note": "OWNED ELSEWHERE — the per-state thresholds + progressive rate scales the resolver consumes; SA/WA/TAS/ACT scales are to_verify there" },
    "entity_aggregation_differs": { "type": "bool", "value": true, "note": "trusts/companies aggregate differently (special-trust surcharges, no threshold, company grouping) — detail in kb.tax.land-tax-by-state + kb.tax.entity-comparison-personal-trust-company-smsf; flagged so structuring accounts for land tax" },
    "figure_is_resolver_computed": { "type": "bool", "value": true, "note": "the land-tax estimate is resolver-computed in ownership_planning_investor from the T-doc thresholds — removed from the LLM's reach; this doc supplies the aggregation behaviour, not a rate" }
  }
}
```

Notes:

- **No `fills`.** The land-tax figure is resolver-computed in `ownership_planning_investor` from the T doc's thresholds (place-don't-recompute / removed-from-reach). This doc supplies the aggregation behaviour the resolver applies.
- **Single-owner via cross-ref.** Thresholds/rates (incl. the SA/WA/TAS/ACT `to_verify` rows) → `kb.tax.land-tax-by-state`; entity aggregation detail → `kb.tax.entity-comparison-personal-trust-company-smsf`. This doc owns only the aggregation behaviour and its interstate/entity nuances.
- **Interstate non-pooling is factual, not advice.** That diversifying across states lowers aggregate land tax is surfaced as a consequence of the rules, not a recommendation to do so.
- **Not tax advice.** The estimate is informational; the state revenue office / a tax adviser is the binding authority, especially for trust and joint-ownership cases.

## Sources

- Revenue NSW — *Land tax* (aggregation of total taxable land value at 31 December; the PPOR exemption; trust surcharge) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax
- State Revenue Office Victoria — *Land tax* (total taxable value of all Victorian land at 31 December; progressive rates; trust surcharge) — https://www.sro.vic.gov.au/land-tax
- Queensland Government — *Land tax* (total taxable value of freehold land at 30 June; thresholds) — https://www.qld.gov.au/environment/land/tax
