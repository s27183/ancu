---
slug: kb.investor.rental-income-modelling
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Rental income modelling — methodology

The first line of an investor's cash-flow projection is **rental income**: the weekly rent an estimated tenant pays, annualised, then reduced by an assumed **vacancy** allowance to a realistic *effective* figure. This doc owns the **methodology** by which `yield_modelling` turns a weekly-rent estimate into annual gross and effective rental income — `rental_income.{annual_gross_rental_income, effective_annual_rental_income}`. It is a **reference** doc: the figures themselves come from upstream (the agent's `estimated_weekly_rent_range` and the suburb data), the vacancy band from its own doc, and the arithmetic from resolver code. Informational — a property manager's rental appraisal is the binding figure.

## The income calculation, step by step

1. **Weekly rent estimate** — the input. It is the agent-reasoned `estimated_weekly_rent_range` on `property_assessment` (`reasoning_domain: rentability`), grounded in comparable rents from the data sources (owned by [`kb.property.rental-market-data-sources`](../property/rental-market-data-sources.md)). It is a **range**, not a point, and the model carries it as such where it can.
2. **Annual gross rental income** = weekly rent **× 52**. (Not ×52.18 — the 52-week convention is the industry standard and slightly conservative.) This is the headline rent before any vacancy or cost.
3. **Effective annual rental income** = annual gross **× (1 − vacancy rate)**. The vacancy allowance (owned by [`kb.investor.vacancy-rate-assumptions`](vacancy-rate-assumptions.md)) reduces gross to the rent realistically *collected* across a year, accounting for the periods between tenancies.

The **effective** figure — not the gross — is the rental line every downstream yield and cash-flow figure builds on, so a property never reads as more cash-positive than its real vacancy exposure allows.

## Gross rent vs the cash actually collected

Gross rent is what the lease says; effective rent is what lands in the account. Three things sit between them — **vacancy** (modelled here via the vacancy band), **arrears** (a tenant who falls behind) and **letting fees / re-advertising** on turnover. Vacancy is the one carried into the income line; arrears is a risk noted, not modelled (it is not predictable per-property); letting fees sit in operating expenses (owned by [`kb.investor.property-management-fees`](property-management-fees.md)), not netted off income, so each cost is visible once.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Effective, not gross, is the honest income line.** The plan shows annual gross rent and then the effective figure after vacancy, so the investor sees the realistic collected rent — not a 52-week-perfect number that overstates cash flow.
- **Rent is an estimate until a PM appraises it.** The weekly rent is the agent's range from comparables; the plan flags that a property manager's written rental appraisal (owned by `kb.investor.rental-appraisal-from-pm-agent`, Cluster S) is the figure to bank on.
- **Carried as a range.** Because the rent estimate is a range, the income line — and the yields built on it — are surfaced as ranges, not false-precision points.
- **Information, not advice.** The plan models income; it makes no promise of a particular rent or occupancy.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; `yield_modelling`'s rental-income leaves are **resolver-computed** from the upstream weekly-rent estimate and the vacancy band (the arithmetic is a formula §11.9 keeps in code). The doc supplies the method, not a figure.

```jsonc
{
  "fills": [],
  "parameters": {
    "weeks_per_year": { "type": "integer", "value": 52, "note": "CONVENTION — annual gross rent = weekly rent × 52 (the industry 52-week convention; slightly conservative vs 52.18)" },
    "annual_gross_formula": { "type": "string", "value": "annual_gross_rental_income = weekly_rent_estimate × 52", "note": "resolver formula (in code) — gross rent before vacancy and costs" },
    "effective_income_formula": { "type": "string", "value": "effective_annual_rental_income = annual_gross_rental_income × (1 − vacancy_rate)", "note": "resolver formula — applies the vacancy band (kb.investor.vacancy-rate-assumptions); the income line all downstream yields build on" },
    "rent_input_is_agent_range": { "type": "bool", "value": true, "note": "the weekly rent is the agent-reasoned estimated_weekly_rent_range on property_assessment (reasoning_domain rentability), grounded in comparables (kb.property.rental-market-data-sources); carried as a range, surfaced as a range" },
    "vacancy_is_the_gross_to_effective_bridge": { "type": "bool", "value": true, "note": "vacancy (not arrears/letting fees) is the one reduction applied to gross→effective here; letting fees live in operating expenses (kb.investor.property-management-fees), counted once" }
  }
}
```

Notes:

- **No `fills`.** The rental-income leaves are resolver-computed from the weekly-rent estimate and the vacancy band; the doc owns the *method* (gross = rent × 52; effective = gross × (1 − vacancy)), not a dollar figure.
- **Cross-refs, not duplicates.** The vacancy band is owned by `kb.investor.vacancy-rate-assumptions`; the rent estimate's data provenance by `kb.property.rental-market-data-sources`; letting fees by `kb.investor.property-management-fees`. This doc owns the income *computation* that consumes them.
- **Effective is the load-bearing line.** Every downstream yield and cash-flow figure builds on *effective* annual income, not gross — so the projection never overstates collected rent.

## Sources

- ASIC Moneysmart — *Investing in property* (rental income, vacancy and ongoing costs as the components of a property's return) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Rental income* (what counts as assessable rental income for an investor) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-income-you-must-declare
