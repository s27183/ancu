---
slug: kb.investor.property-management-fees
effective_from: 2025-07-01
last_verified: 2026-10-16
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
    retrieved: 2026-07-06
  - url: https://www.canstar.com.au/home-loans/real-estate-commission-fees/
    retrieved: 2026-07-06
  - url: https://www.localagentfinder.com.au/blog/property-management-commission-fees
    retrieved: 2026-10-16
    path: docs/sources/investor/laf-property-management-fees.txt
    quotes:
      - "The national average management fee across Australia is approximately 7.5% of weekly rent. The average letting fee is approximately 1.4 weeks' rent ."
  - url: https://www.propspotter.com.au/property-management-fees
    retrieved: 2026-10-16
    path: docs/sources/investor/propspotter-property-management-fees.txt
    quotes:
      - "A fee closer to 5% could mean you are paying for management only."
      - "Regional NSW landlords pay 7–12%, compared to Sydney's 5.4%."
      - "In Sydney, expect 1–2 weeks' rent, averaging 1.2 weeks."
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
    "lease_renewal_fee_applies": { "type": "bool", "value": true, "note": "CONVENTION — a smaller lease-renewal fee may apply where the agency charges one (a few hundred dollars or a fraction of a week's rent)" },
    "sundries_loading": { "type": "string", "value": "modest loading for statement/admin, new-tenancy advertising, routine-inspection fees where applicable", "note": "CONVENTION — small per-agency charges, bundled into the PM line as a modest loading" },
    "fee_charged_on_rent_collected": { "type": "bool", "value": true, "note": "the management % is on rent COLLECTED — vacancy reduces it; letting fee recurs per new tenancy, so turnover raises cost" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "property_management",
          "phase": "own",
          "timing": "per_year",
          "tier": "CONVENTION",
          "basis": "pct_of_rent",
          "low": 5,
          "high": 12,
          "applies": {
            "modes": [
              "investor-domestic-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "national average about 7.5%; regional NSW up to 12% (the prior band was 5–10%)",
          "label": {
            "vi": "Phí quản lý cho thuê (property management)",
            "en": "Property management fee"
          },
          "payer": {
            "vi": "Chủ nhà trả, trừ thẳng vào tiền thuê; được khấu trừ thuế",
            "en": "The owner pays, taken from the rent; tax-deductible"
          },
          "drivers": {
            "vi": "Thành phố lớn cạnh tranh (~5–7,5%) rẻ hơn vùng xa (tới ~12%); có thể thương lượng. Tính trên tiền thuê thực thu, cộng GST.",
            "en": "Competitive capital cities (~5–7.5%) cost less than regional areas (up to ~12%); negotiable. Charged on rent collected, plus GST."
          },
          "source": "https://www.propspotter.com.au/property-management-fees"
        },
        {
          "id": "letting_fee",
          "phase": "own",
          "timing": "per_year",
          "tier": "CONVENTION",
          "basis": "pct_of_rent",
          "low": 1.9,
          "high": 3.8,
          "applies": {
            "modes": [
              "investor-domestic-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "1–2 weeks' rent ÷ 52 weeks, assuming one re-let a year; national average about 1.4 weeks",
          "label": {
            "vi": "Phí tìm người thuê (letting fee)",
            "en": "Letting fee (finding a tenant)"
          },
          "payer": {
            "vi": "Chủ nhà trả mỗi khi có người thuê mới",
            "en": "The owner pays each time a new tenant signs"
          },
          "drivers": {
            "vi": "Khoảng 1–2 tuần tiền thuê mỗi lần tìm người thuê mới; dòng này giả định mỗi năm đổi người thuê một lần. Người thuê ở lâu thì ít tốn hơn.",
            "en": "About 1–2 weeks' rent per new tenancy; this line assumes one new tenancy a year. A tenant who stays longer makes it cheaper."
          },
          "source": "https://www.propspotter.com.au/property-management-fees"
        }
      ]
    }
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
