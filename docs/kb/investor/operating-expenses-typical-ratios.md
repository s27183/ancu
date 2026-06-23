---
slug: kb.investor.operating-expenses-typical-ratios
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Operating expenses — typical ratios for an investment property

An investment property's **operating expenses** are the recurring annual costs of holding and letting it — separate from the loan interest, which is a financing cost modelled on its own. This doc owns the **typical ranges and ratios** the resolver uses to estimate each `yield_modelling.operating_expenses.*` line for a *base-scope* projection, before the investor substitutes actual quotes and statements. Figures are **banded** (market conventions, not regulated constants) except where a line is owned by a regulated sibling doc and cross-referenced. Informational — the binding figures are the property's own rates notices, levies, and quotes.

## The expense lines

The model carries each cost as its own line so the investor sees where the money goes, never a single opaque "expenses" lump:

- **Property management** — typically **~7–8% of rent** (the model defaults to 7.5%), plus letting/leasing fees on turnover. Owned by [`kb.investor.property-management-fees`](property-management-fees.md); cross-referenced here, not re-banded.
- **Council rates** — **~$1,500–$2,500/year** for a typical metropolitan dwelling, set by the local council on the property's land value; higher for higher-value land.
- **Water rates / charges** — **~$700–$1,500/year**; in most states the **fixed service charge** is the owner's, while **usage** is commonly the tenant's (varies by state and lease) — the model takes the owner-borne portion.
- **Landlord insurance** — **~$300–$700/year**; covers loss of rent, tenant damage and liability — *distinct from* building insurance, and the investor-specific cover an owner-occupier doesn't carry.
- **Building insurance** — **~$1,000–$2,000/year** for a **freestanding house**; for **strata**, building cover sits inside the body-corporate levy (don't double-count — see body corporate below).
- **Body corporate / strata levies** — applicable only to strata/owners-corporation properties; the amount is the scheme's actual levy (a property fact from `property_assessment.strata_or_building.body_corporate_quarterly_fees`), read against scheme health (owned by [`kb.strata.health-indicators-investor-lens`](../strata/health-indicators-investor-lens.md)). The model uses the actual levy, not a band.
- **Land tax** — applies to investment property (no PPOR exemption); the figure is **resolver-computed** from the state scales and the investor's aggregated landholding — owned by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) and the aggregation projection [`kb.investor.land-tax-aggregation`](land-tax-aggregation.md). Not banded here.
- **Maintenance & repairs reserve** — **~0.5–1.0% of property value/year** (or ~$1,000–$2,000 as a floor); for a strata property, structural maintenance is in the levy, so the reserve is **interior-only** to avoid double-counting (the same no-double-count rule as the FHB [`kb.maintenance.budget-by-property-type`](../maintenance/budget-by-property-type.md)).

## Ratio vs fixed — which lines scale

Two of these scale with the property and are best carried as **ratios** (property management with rent; maintenance reserve with value); the rest are **fixed dollar bands** the investor replaces with the actual notice. The model uses the ratio for the base estimate and the actual figure once known.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Every cost line is visible.** The plan itemises the operating expenses rather than netting them into one number, so the investor sees that management, rates, insurance, and maintenance — not just the loan — shape the cash flow.
- **Landlord insurance is the investor-specific add.** The plan flags landlord insurance (loss of rent + tenant damage) as cover an owner-occupier doesn't carry — a line first-time investors often miss.
- **Strata vs house — no double-counting.** For a strata property the levy carries building insurance and structural maintenance, so those lines are zeroed and only the interior reserve is added; for a house they're separate. The plan applies the right structure per property type.
- **Banded until actuals land.** The percentages and ranges are typical-market starting points; the binding figures are the property's own rates notices, levy statements, and insurance quotes.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; each `yield_modelling.operating_expenses.*` line is **resolver-estimated** from these ratios/bands (or computed by the owning sibling for PM fees, land tax, body corporate). Ratios are CONVENTION; the regulated/owned lines are cross-referenced, not re-declared.

```jsonc
{
  "fills": [],
  "parameters": {
    "council_rates_annual_low":   { "type": "money", "value": 1500, "note": "CONVENTION — typical metro council rates p.a., lower end; set by council on land value" },
    "council_rates_annual_high":  { "type": "money", "value": 2500, "note": "CONVENTION — typical metro council rates p.a., upper end" },
    "water_rates_annual_low":     { "type": "money", "value": 700,  "note": "CONVENTION — owner-borne water service charge p.a., lower end; usage commonly the tenant's (varies by state/lease)" },
    "water_rates_annual_high":    { "type": "money", "value": 1500, "note": "CONVENTION — owner-borne water charge p.a., upper end" },
    "landlord_insurance_annual_low":  { "type": "money", "value": 300, "note": "CONVENTION — landlord insurance p.a. (loss of rent + tenant damage + liability); the investor-specific cover, distinct from building insurance" },
    "landlord_insurance_annual_high": { "type": "money", "value": 700, "note": "CONVENTION — landlord insurance p.a., upper end" },
    "building_insurance_house_annual_low":  { "type": "money", "value": 1000, "note": "CONVENTION — building insurance for a freestanding HOUSE p.a.; for strata, building cover is inside the body-corporate levy (don't double-count)" },
    "building_insurance_house_annual_high": { "type": "money", "value": 2000, "note": "CONVENTION — building insurance (house) p.a., upper end" },
    "maintenance_reserve_pct_of_value_low":  { "type": "percentage", "value": 0.5, "note": "CONVENTION — maintenance & repairs reserve as % of property value p.a., lower end; strata = interior-only (structural is in the levy)" },
    "maintenance_reserve_pct_of_value_high": { "type": "percentage", "value": 1.0, "note": "CONVENTION — maintenance reserve as % of value p.a., upper end" },
    "property_management_pct_owner": { "type": "string", "value": "kb.investor.property-management-fees", "note": "OWNED ELSEWHERE — PM fee % of rent + letting fees; cross-ref, not re-banded here" },
    "land_tax_owner": { "type": "string", "value": "kb.tax.land-tax-by-state", "note": "OWNED ELSEWHERE — land tax is resolver-computed from the state scales + aggregation (kb.investor.land-tax-aggregation); no PPOR exemption for investment property" },
    "body_corporate_is_property_fact": { "type": "bool", "value": true, "note": "the body-corporate levy is the scheme's ACTUAL figure (property_assessment.strata_or_building.body_corporate_quarterly_fees), read against kb.strata.health-indicators-investor-lens — not a band" }
  }
}
```

Notes:

- **No `fills`.** Each operating-expense line is a resolver estimate from these ratios/bands or computed by the owning sibling; the doc supplies the typical figures, asserting no property-specific total.
- **Ratios vs fixed bands.** Property management (% of rent) and the maintenance reserve (% of value) scale and are carried as ratios; council/water/insurance are fixed dollar bands replaced by the actual notice.
- **Single-owner via cross-ref.** PM fees → `kb.investor.property-management-fees`; land tax → `kb.tax.land-tax-by-state` + `kb.investor.land-tax-aggregation`; body corporate → the actual levy read against `kb.strata.health-indicators-investor-lens`; strata maintenance no-double-count mirrors `kb.maintenance.budget-by-property-type`. This doc owns the council/water/insurance/maintenance bands.

## Sources

- ASIC Moneysmart — *Investing in property* (ongoing costs of an investment property: management, rates, insurance, maintenance, land tax) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Rental expenses you can claim now* (the categories of deductible rental operating expenses: rates, insurance, property agent fees, repairs) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/rental-expenses-you-can-claim-now
- Canstar — *Landlord insurance* (indicative — landlord insurance cost and what it covers vs building insurance) — https://www.canstar.com.au/landlord-insurance/
