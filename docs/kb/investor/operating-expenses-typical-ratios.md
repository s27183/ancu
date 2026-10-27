---
slug: kb.investor.operating-expenses-typical-ratios
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-10-27
    path: docs/sources/asic/moneysmart-buying-an-investment-property.txt
    quotes:
      - "Ongoing costs of investment properties include: council and water rates building insurance landlord insurance body corporate fees land tax property management fees (if you use an agent) repairs and maintenance costs"
      - "The property price is $550,000 with buying costs of $23,000."
      - "Less allowance for repairs and maintenance -$500"
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
    retrieved: 2026-10-27
    path: docs/sources/ato/rental-common-property-expenses.txt
    quotes:
      - "council rates, water charges, land tax"
      - "insurance (building, contents, public liability, loss of rent)"
      - "property agent's fees and commission"
  - url: https://www.ipart.nsw.gov.au/sites/default/files/cm9_documents/Final-Report-Sydney-Water-prices-2025-2030-September-2025.PDF
    retrieved: 2026-10-27
    path: docs/sources/nsw/ipart-sydney-water-prices-2025-2030-final-report.txt
    note: "IPART sets Sydney Water's maximum prices — the regulator's own determination. One city's owner-borne fixed charges; not yet a national band."
    quotes:
      - "IPART decision Residential customers 67.04 117.94 101.55 96.09 96.09 96.09"
      - "Total wastewater charge 618.47 691.90 723.53 773.15 826.16 882.80"
      - "The bills paid by landlords include the fixed water service charge, fixed wastewater service charge and a deemed wastewater usage charge."
---

# Operating expenses — typical ratios for an investment property

An investment property's **operating expenses** are the recurring annual costs of holding and letting it — separate from the loan interest, which is a financing cost modelled on its own. This doc owns the **typical ranges and ratios** the resolver uses to estimate each `yield_modelling.operating_expenses.*` line for a *base-scope* projection, before the investor substitutes actual quotes and statements. The council, water, insurance and maintenance figures are **PLACEHOLDER bands** (no primary yet states a market-wide figure; each names the primary to re-ground on) except where a line is owned by a regulated sibling doc and cross-referenced. Informational — the binding figures are the property's own rates notices, levies, and quotes.

## The expense lines

The model carries each cost as its own line so the investor sees where the money goes, never a single opaque "expenses" lump:

- **Property management** — typically **~7–8% of rent** (the model defaults to 7.5%), plus letting/leasing fees on turnover. Owned by [`kb.investor.property-management-fees`](property-management-fees.md); cross-referenced here, not re-banded.
- **Council rates** — set by the local council on the property's land value; the model carries a placeholder **~$1,500–$2,500/year** until it is re-grounded on councils' own published average residential rates (no primary states a national band yet).
- **Water rates / charges** — in most states the **fixed service charges** are the owner's, while **usage** is commonly the tenant's (varies by state and lease) — the model takes the owner-borne portion, a placeholder **~$700–$1,500/year**. One regulator's own figure so far: IPART's 2025–30 Sydney Water determination puts a landlord's fixed charges for 2026–27 at **$101.55** (water service) plus **$723.53** (wastewater, incl. the deemed usage charge), in $2025-26 — about **$825/year**.
- **Landlord insurance** — a placeholder **~$430–$1,200/year** for landlord-only cover; covers loss of rent, tenant damage and liability — *distinct from* building insurance, and the investor-specific cover an owner-occupier doesn't carry. The binding figure is the insurer's quote.
- **Building insurance** — a placeholder **~$1,400–$3,050/year** for a **freestanding house**, in every mode, owner-occupier or investor (premiums run highest in the north, for cyclone and flood); for **strata**, building cover sits inside the body-corporate levy (don't double-count — see body corporate below). The binding figure is the insurer's quote.
- **Body corporate / strata levies** — applicable only to strata/owners-corporation properties; the amount is the scheme's actual levy (a property fact from `property_assessment.strata_or_building.body_corporate_quarterly_fees`), read against scheme health (owned by [`kb.strata.health-indicators-investor-lens`](../strata/health-indicators-investor-lens.md)). The model uses the actual levy, not a band.
- **Land tax** — applies to investment property (no PPOR exemption); the figure is **resolver-computed** from the state scales and the investor's aggregated landholding — owned by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) and the aggregation projection [`kb.investor.land-tax-aggregation`](land-tax-aggregation.md). Not banded here.
- **Maintenance & repairs reserve** — a placeholder **~0.5–1.0% of property value/year** (ASIC Moneysmart's worked example allows $500 a month for repairs and maintenance on a $550,000 unit, about 1.1% a year — an illustration, not a market band); for a strata property, structural maintenance is in the levy, so the reserve is **interior-only** to avoid double-counting (the same no-double-count rule as the FHB [`kb.maintenance.budget-by-property-type`](../maintenance/budget-by-property-type.md)).

## Ratio vs fixed — which lines scale

Two of these scale with the property and are best carried as **ratios** (property management with rent; maintenance reserve with value); the rest are **fixed dollar bands** the investor replaces with the actual notice. The model uses the ratio for the base estimate and the actual figure once known.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Every cost line is visible.** The plan itemises the operating expenses rather than netting them into one number, so the investor sees that management, rates, insurance, and maintenance — not just the loan — shape the cash flow.
- **Landlord insurance is the investor-specific add.** The plan flags landlord insurance (loss of rent + tenant damage) as cover an owner-occupier doesn't carry — a line first-time investors often miss.
- **Strata vs house — no double-counting.** For a strata property the levy carries building insurance and structural maintenance, so those lines are zeroed and only the interior reserve is added; for a house they're separate. The plan applies the right structure per property type.
- **Placeholders until actuals land.** The percentages and ranges are labelled placeholders, not measured market figures; the binding figures are the property's own rates notices, levy statements, and insurance quotes.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; each `yield_modelling.operating_expenses.*` line is **resolver-estimated** from these ratios/bands (or computed by the owning sibling for PM fees, land tax, body corporate). The bands are PLACEHOLDER; the regulated/owned lines are cross-referenced, not re-declared.

```jsonc
{
  "fills": [],
  "parameters": {
    "council_rates_annual_low":   { "type": "money", "value": 1500, "note": "PLACEHOLDER — no primary states this; re-ground on councils' own published average residential rates (NSW Office of Local Government's Your Council data; Victoria's Local Government Performance Reporting average rate per assessment). Lower end; set by council on land value" },
    "council_rates_annual_high":  { "type": "money", "value": 2500, "note": "PLACEHOLDER — no primary states this; re-ground on councils' own published average residential rates. Upper end" },
    "water_rates_annual_low":     { "type": "money", "value": 700,  "note": "PLACEHOLDER — no primary states a national band; one regulator figure: IPART Sydney Water 2026-27 landlord fixed charges $101.55 water + $723.53 wastewater ($2025-26) ≈ $825. Re-ground on each state's water price regulator (ESC Victoria, QCA, ESCOSA, ERA WA). Lower end; usage commonly the tenant's (varies by state/lease)" },
    "water_rates_annual_high":    { "type": "money", "value": 1500, "note": "PLACEHOLDER — no primary states a national band; re-ground on each state's water price regulator. Upper end" },
    "maintenance_reserve_pct_of_value_low":  { "type": "percentage", "value": 0.5, "note": "PLACEHOLDER — no primary states this; ASIC Moneysmart's worked example ($500/month on a $550,000 unit ≈ 1.1% a year) is an illustration, not a band; re-ground on a producer's own maintenance-cost data. Lower end; strata = interior-only (structural is in the levy)" },
    "maintenance_reserve_pct_of_value_high": { "type": "percentage", "value": 1.0, "note": "PLACEHOLDER — no primary states this; see the lower end. Upper end" },
    "property_management_pct_owner": { "type": "string", "value": "kb.investor.property-management-fees", "note": "OWNED ELSEWHERE — PM fee % of rent + letting fees; cross-ref, not re-banded here" },
    "land_tax_owner": { "type": "string", "value": "kb.tax.land-tax-by-state", "note": "OWNED ELSEWHERE — land tax is resolver-computed from the state scales + aggregation (kb.investor.land-tax-aggregation); no PPOR exemption for investment property" },
    "body_corporate_is_property_fact": { "type": "bool", "value": true, "note": "the body-corporate levy is the scheme's ACTUAL figure (property_assessment.strata_or_building.body_corporate_quarterly_fees), read against kb.strata.health-indicators-investor-lens — not a band" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "building_insurance",
          "phase": "own",
          "timing": "per_year",
          "tier": "PLACEHOLDER",
          "basis": "fixed",
          "low": 1400,
          "high": 3050,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": "all",
            "property": "house"
          },
          "optional": false,
          "note": "PLACEHOLDER — no primary states this; re-ground on the ACCC's own Insurance monitoring report (June 2026; average home building premiums by region — https://www.accc.gov.au/system/files/accc-insurance-monitoring-report-june2026.pdf, fetch refused 403 this session) or insurers' own premium quotes. The one owner of building insurance, first year included, for all five modes",
          "label": {
            "vi": "Bảo hiểm nhà (building insurance) — nhà riêng",
            "en": "Building insurance — house"
          },
          "payer": {
            "vi": "Chủ nhà trả hằng năm; ngân hàng thường yêu cầu có từ ngày settlement; với nhà cho thuê thì được khấu trừ thuế",
            "en": "The owner pays yearly; the lender usually requires it from settlement; tax-deductible on a rental"
          },
          "drivers": {
            "vi": "Bang và vùng (QLD, miền bắc nước Úc và NT cao nhất vì bão, lũ), diện tích và vật liệu nhà, mức miễn thường (excess). Căn hộ (strata) không có dòng này — bảo hiểm tòa nhà nằm trong phí quản lý chung cư (strata levy).",
            "en": "State and region (QLD, northern Australia and NT highest for cyclone and flood), the home's size and construction, the excess chosen. A strata unit has no line here — building cover is inside the strata levy."
          },
          "source": "https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses"
        },
        {
          "id": "landlord_insurance",
          "phase": "own",
          "timing": "per_year",
          "tier": "PLACEHOLDER",
          "basis": "fixed",
          "low": 430,
          "high": 1200,
          "applies": {
            "modes": [
              "investor-domestic-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "PLACEHOLDER — no primary states this; re-ground on insurers' own landlord-insurance premium quotes (landlord-only cover, no building). A house's combined building + landlord premium is building_insurance + this line",
          "label": {
            "vi": "Bảo hiểm chủ nhà cho thuê (landlord insurance)",
            "en": "Landlord insurance"
          },
          "payer": {
            "vi": "Chủ nhà trả hằng năm; được khấu trừ thuế",
            "en": "The owner pays yearly; tax-deductible"
          },
          "drivers": {
            "vi": "Chỉ phần của chủ nhà cho thuê: mất tiền thuê, hư hại do người thuê, đồ đạc, trách nhiệm pháp lý. Tòa nhà được bảo hiểm riêng — nhà riêng ở dòng bảo hiểm nhà (building insurance), căn hộ trong phí strata. Mức bảo hiểm và mức miễn thường (excess) quyết định mức phí.",
            "en": "Landlord cover only: loss of rent, tenant damage, fittings, liability. The building is insured separately — a house on the building-insurance line, a unit inside the strata levy. The cover chosen and the excess set the premium."
          },
          "source": "https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses"
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** Each operating-expense line is a resolver estimate from these ratios/bands or computed by the owning sibling; the doc supplies the typical figures, asserting no property-specific total.
- **Ratios vs fixed bands.** Property management (% of rent) and the maintenance reserve (% of value) scale and are carried as ratios; council/water/insurance are fixed dollar bands replaced by the actual notice.
- **PLACEHOLDER bands.** No primary yet states a market-wide council, water, insurance or maintenance figure; each note names the primary to re-ground on. The only regulator figure in hand is IPART's Sydney Water landlord charges (~$825 for 2026–27).
- **Single-owner via cross-ref.** PM fees → `kb.investor.property-management-fees`; land tax → `kb.tax.land-tax-by-state` + `kb.investor.land-tax-aggregation`; body corporate → the actual levy read against `kb.strata.health-indicators-investor-lens`; strata maintenance no-double-count mirrors `kb.maintenance.budget-by-property-type`. This doc owns the council/water/insurance/maintenance bands.

## Sources

- ASIC Moneysmart — *Buying an investment property* (ongoing costs of an investment property: rates, insurance, body corporate, land tax, management, maintenance; the worked example's maintenance allowance) — https://moneysmart.gov.au/property-investment/buying-an-investment-property
- ATO — *Common property expenses* (the deductible rental operating expenses: rates, water, land tax, insurance, agent fees, repairs) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
- IPART — *Sydney Water prices 2025–2030, Final Report* (the fixed water and wastewater charges a landlord pays in Sydney) — https://www.ipart.nsw.gov.au/sites/default/files/cm9_documents/Final-Report-Sydney-Water-prices-2025-2030-September-2025.PDF
