---
slug: kb.investor.property-management-fees
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
    retrieved: 2026-07-06
  - url: https://www.canstar.com.au/home-loans/real-estate-commission-fees/
    retrieved: 2026-07-06
---

# Property management fees — structures and benchmarks

A landlord who appoints a managing agent pays a **management fee** (an ongoing % of rent collected) plus a set of **transactional charges** (letting/leasing fee on a new tenancy, lease-renewal fee, and sundries). This doc owns the **fee structures and typical benchmarks** so the resolver can estimate `yield_modelling.operating_expenses.{property_management_annual, letting_fees_periodic}` for a base projection, and so the `ownership_planning_investor` management decision (PM vs self-managed, owned by `kb.investor.property-management-vs-self-managed`, Cluster S) has the cost side grounded. Figures are **banded** market conventions — fees are negotiable and vary by state and agency. Informational, no agency recommendation.

## The fee structure

- **Management fee** — an ongoing percentage of **rent collected**, typically **~5–10%** (plus GST), with **~7–8%** the common metropolitan band; the model defaults to **7.5%**. It is charged only on rent actually collected, so vacancy reduces it.
- **Letting / leasing fee** — a one-off charge when a **new tenant** is placed, typically **1–2 weeks' rent** (plus GST); recurs on each turnover, which is why low tenant turnover helps net return.
- **Lease-renewal fee** — a smaller charge to re-paper an existing tenant (a few hundred dollars or a fraction of a week's rent), where the agency charges one.
- **Sundries** — periodic statement/admin fees, advertising for a new tenancy, and routine-inspection fees, where applicable — small but real; bundled into the model's PM line as a modest loading.

## Why it is its own line

Property management is the single largest controllable operating cost and the pivot of the **manage vs self-manage** decision: self-managing saves the fee but costs time and carries compliance risk (the manager handles bond lodgement, entry/exit condition reports, repairs coordination, and the rental minimum-standards obligations). The model carries the fee explicitly so that trade-off is visible; the *decision* is owned by the Cluster-S doc, this doc owns the *cost*.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The fee is visible and negotiable.** The plan shows the management fee (~7.5% default) and the letting fee (1–2 weeks' rent) as explicit lines, noting they are negotiable — not a fixed cost.
- **Turnover costs money.** Because the letting fee recurs on each new tenancy, the plan flags that tenant retention (and lower turnover) improves net return — relevant when weighing a managing agent's quality, not just its fee.
- **Manage vs self-manage is a real fork.** The plan surfaces the fee saved by self-managing against the time and compliance burden (bond, condition reports, minimum standards) — decision-support, the investor chooses (the decision doc is `kb.investor.property-management-vs-self-managed`).
- **Banded, confirm with the agency.** Fees vary by state and agency; the binding figure is the management agreement the investor signs.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the PM cost lines are **resolver-estimated** from these benchmarks against the (effective) rent. All figures are CONVENTION — negotiable, state- and agency-variable.

```jsonc
{
  "fills": [],
  "parameters": {
    "management_fee_pct_default": { "type": "percentage", "value": 7.5, "note": "CONVENTION — default management fee as % of rent collected (the yield_modelling default); plus GST; charged on rent collected so vacancy reduces it" },
    "management_fee_pct_low": { "type": "percentage", "value": 5, "note": "CONVENTION — lower end of the management-fee band; varies by state/agency, negotiable" },
    "management_fee_pct_high": { "type": "percentage", "value": 10, "note": "CONVENTION — upper end of the management-fee band" },
    "letting_fee_weeks_of_rent_low": { "type": "number", "value": 1, "note": "CONVENTION — one-off letting/leasing fee on a NEW tenancy, lower end (weeks of rent, plus GST); recurs on turnover" },
    "letting_fee_weeks_of_rent_high": { "type": "number", "value": 2, "note": "CONVENTION — letting fee, upper end (weeks of rent)" },
    "lease_renewal_fee_applies": { "type": "bool", "value": true, "note": "CONVENTION — a smaller lease-renewal fee may apply where the agency charges one (a few hundred dollars or a fraction of a week's rent)" },
    "sundries_loading": { "type": "string", "value": "modest loading for statement/admin, new-tenancy advertising, routine-inspection fees where applicable", "note": "CONVENTION — small per-agency charges, bundled into the PM line as a modest loading" },
    "fee_charged_on_rent_collected": { "type": "bool", "value": true, "note": "the management % is on rent COLLECTED — vacancy reduces it; letting fee recurs per new tenancy, so turnover raises cost" }
  }
}
```

Notes:

- **No `fills`.** The PM cost lines are resolver-estimated from these benchmarks against the rent; the doc supplies the structures and bands, not a property-specific fee.
- **All CONVENTION.** Property management fees are not regulated figures — they are negotiable and vary by state and agency; presented as typical, the management agreement binds.
- **Cost here, decision elsewhere.** This doc owns the *fee structure and benchmarks* (consumed by `yield_modelling` for the cost line and by `ownership_planning_investor` for the management-cost side); the *PM-vs-self-managed decision* is owned by `kb.investor.property-management-vs-self-managed` (Cluster S). Single-owner via cross-ref.

## Sources

- ASIC Moneysmart — *Investing in property* (property management fees as an ongoing cost of an investment property) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Rental expenses you can claim now* (property agent fees/commissions are a deductible rental expense) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/rental-expenses-you-can-claim-now
- Canstar — *Property management fees* (indicative — typical management %, letting fee in weeks of rent, by state) — https://www.canstar.com.au/home-loans/property-management-fees/
