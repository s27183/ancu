---
slug: kb.maintenance.budget-by-property-type
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/home-loans/buying-a-house
    retrieved: 2026-07-06
---

# Maintenance budgeting — the 1% heuristic, by property type

Owning a home carries an ongoing **maintenance and repairs** cost — replacing what wears out (roof, hot-water system, painting, appliances) and routine upkeep. The standard planning heuristic is to set aside roughly **1% of the property's value each year**; the right figure shifts with the **property type** and **age**. This doc owns **the maintenance-reserve heuristic and how it varies by property type**; it grounds `ownership_planning.maintenance_reserve.{annual_target, percentage_of_property_value}` (default 1%). The figures are **budgeting conventions**, not statutory rates.

## The 1% heuristic

- **Budget ~1% of the property value per year** for maintenance and repairs (some use a 1–2% range for older properties). On a $700k home that is **~$7,000/yr** set aside — not necessarily spent every year, but reserved so a big-ticket replacement (roof, hot-water unit, restumping) doesn't become a financial shock.
- It is a **reserve target**, not a bill: in early years actual spend is often lower; the reserve smooths the lumpy, infrequent large costs.

## How it varies by property type

- **Established freestanding house.** The owner bears **all** maintenance — roof, gutters, exterior, fences, garden, plumbing. Budget at the **full ~1%+**, and **higher for older houses** (pre-1980s stock: wiring, plumbing, restumping, roof). This is the highest owner-borne maintenance load.
- **New house / off-the-plan.** Lower in the **early years** — new fixtures and **builder's warranty** cover many defects — but a prudent reserve is still warranted as the build ages. Don't treat "new" as "zero maintenance."
- **Apartment / townhouse (strata).** **Common-property** maintenance (roof, exterior, common plumbing, lifts) is funded through the **strata levy's capital-works fund**, not the owner's separate budget. So the owner's separate maintenance reserve covers the **interior only** (own appliances, fixtures, internal finishes) and is **materially lower** — but the strata levy itself carries the structural cost (see [`kb.ongoing-costs.rates-water-strata`](../ongoing-costs/rates-water-strata.md)). **Do not double-count**: for strata, structural maintenance is in the levy, not the 1% reserve.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **House vs apartment changes the maintenance picture, not just the price.** A Mode A buyer weighing an older freestanding house against an apartment should see that the house carries a **higher owner-borne maintenance reserve**, while the apartment's structural maintenance is bundled into the **strata levy** — two different cost shapes for the same headline budget.
- **Older first homes need a real reserve.** Many affordable Mode A entry properties are **older houses**; the plan should set the reserve toward the upper end and flag the big-ticket items (roof, hot water, electrical) so a year-3 repair is planned, not a crisis.
- **Information, not advice.** The reserve is a budgeting target; actual costs depend on the specific property and its condition (informed by the building/pest inspection).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `maintenance_reserve.annual_target` is **resolver-computed** (`percentage_of_property_value` × property value), with the percentage adjusted by property type/age per these heuristics; the doc supplies the heuristic, not the dollar figure.

```jsonc
{
  "fills": [],
  "parameters": {
    "reserve_pct_of_value_default":   { "type": "percentage", "value": 1, "note": "CONVENTION — the 1%-of-property-value-per-year maintenance reserve heuristic; matches the blueprint's maintenance_reserve.percentage_of_property_value default" },
    "reserve_pct_of_value_older_high": { "type": "percentage", "value": 2, "note": "CONVENTION — upper end (~1–2%) for older freestanding houses with ageing roof/plumbing/wiring" },
    "house_owner_bears_all_maintenance": { "type": "bool", "value": true, "note": "freestanding house: owner bears all maintenance (roof, exterior, garden, fences) → full ~1%+ reserve, higher when older" },
    "new_build_lower_early_years":    { "type": "bool", "value": true, "note": "CONVENTION — new house/off-the-plan: lower maintenance in early years (builder's warranty, new fixtures), but reserve still prudent as it ages" },
    "strata_structural_maintenance_in_levy": { "type": "bool", "value": true, "note": "apartment/townhouse: common-property/structural maintenance is funded by the strata capital-works fund (see kb.ongoing-costs.rates-water-strata), NOT the owner's reserve — the owner's reserve covers the interior only; do not double-count" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `maintenance_reserve.annual_target` is resolver-computed from the percentage and the property value, with the percentage tuned by type/age. The doc supplies the heuristic and the by-type variation.
- **All figures CONVENTION — none statutory.** The 1% rule is a budgeting heuristic, not a regulated rate. Tagged so the agent presents it as "a prudent reserve of about 1% a year," never as a required amount.
- **No double-counting with strata levies — the load-bearing interaction.** For strata properties, structural/common-property maintenance is already funded by the levy's capital-works fund ([`kb.ongoing-costs.rates-water-strata`](../ongoing-costs/rates-water-strata.md)); the 1% reserve therefore covers the **interior only** for an apartment. Captured explicitly so the two ownership-cost docs don't stack the same expense twice.
- **Condition refines the figure.** The base-scope reserve is the heuristic; once a property is attached, the building/pest report (owned by the due-diligence anchors) sharpens it. This doc supplies only the base heuristic.

## Sources

**Canonical (regulator — concept):**

- ASIC Moneysmart — *Buying a house* (the ongoing costs of owning a home include maintenance and repairs alongside rates, water and insurance) — https://moneysmart.gov.au/home-loans/buying-a-house

**Budgeting convention** — the **~1% of property value per year** maintenance reserve is a widely-used planning heuristic, not a published or statutory rate; it is an order-of-magnitude reserve target, tuned by property type, age and condition, not a figure any authority sets.
