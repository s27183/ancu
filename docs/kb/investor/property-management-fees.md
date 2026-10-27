---
slug: kb.investor.property-management-fees
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.consumer.vic.gov.au/housing/renting/starting-and-changing-rental-agreements/using-a-property-manager-or-agent
    retrieved: 2026-10-27
    path: docs/sources/vic/cav-using-a-property-manager-or-agent.txt
    quotes:
      - "You can negotiate all fees and expenses with an agent, except those that are fixed by law. You must record who is responsible for paying what fees and expenses on the authority (contract), including any GST liabilities."
      - "Generally, this is the initial set-up cost for vetting and finding a renter. It is negotiable and usually charged at the beginning of each rental agreement. Some agents also charge a re-leasing fee (also subject to negotiation) if current renters sign a new rental agreement."
      - "This is an ongoing fee that is taken out of the rent each time it is paid. If the management fee is worked out as a percentage of the rent, make sure it is also included as a dollar amount on the authority (contract)."
      - "Examples of other costs you may be charged by an agent include statement fees, administrative and/or postage costs."
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-10-27
    path: docs/sources/asic/moneysmart-buying-an-investment-property.txt
    quotes:
      - "property management fees (if you use an agent)"
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
    retrieved: 2026-10-27
    path: docs/sources/ato/rental-common-property-expenses.txt
    quotes:
      - "property agent's fees and commission"
---

# Property management fees — structures and benchmarks

A landlord who appoints a managing agent pays a **management fee** (an ongoing % of rent collected) plus a set of **transactional charges** (letting/leasing fee on a new tenancy, lease-renewal fee, and sundries). This doc owns the **fee structures and typical benchmarks** so the resolver can estimate `yield_modelling.operating_expenses.{property_management_annual, letting_fees_periodic}` for a base projection, and so the `ownership_planning_investor` management decision (PM vs self-managed, owned by `kb.investor.property-management-vs-self-managed`, Cluster S) has the cost side grounded. The fee *structure* is grounded on Consumer Affairs Victoria's own guidance; the *percentages* are PLACEHOLDER bands — fees are negotiable and vary by state and agency, and no primary yet states a market-wide figure. Informational, no agency recommendation.

## The fee structure

- **Management fee** — an ongoing fee "taken out of the rent each time it is paid" (Consumer Affairs Victoria); where it is a percentage of rent, Victoria requires it also be stated as a dollar amount on the authority. The model carries a placeholder band of **~5–12%** of rent and defaults to **7.5%** (plus GST) until it is re-grounded on agencies' own published fee schedules. It is charged only on rent actually collected, so vacancy reduces it.
- **Letting / leasing fee** — "the initial set-up cost for vetting and finding a renter", "usually charged at the beginning of each rental agreement" (Consumer Affairs Victoria); the model carries a placeholder **1–2 weeks' rent** (plus GST). It recurs on each turnover, which is why low tenant turnover helps net return.
- **Lease-renewal (re-leasing) fee** — "Some agents also charge a re-leasing fee" when current renters sign a new agreement (Consumer Affairs Victoria); its size is not stated by any primary in hand.
- **Sundries** — "statement fees, administrative and/or postage costs" (Consumer Affairs Victoria), and advertising or inspection fees where the agency charges them; bundled into the model's PM line as a modest loading.

## Why it is its own line

Property management is the single largest controllable operating cost and the pivot of the **manage vs self-manage** decision: self-managing saves the fee but costs time and carries compliance risk (the manager handles bond lodgement, entry/exit condition reports, repairs coordination, and the rental minimum-standards obligations). The model carries the fee explicitly so that trade-off is visible; the *decision* is owned by the Cluster-S doc, this doc owns the *cost*.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The fee is visible and negotiable.** The plan shows the management fee (a placeholder 7.5% default) and the letting fee (a placeholder 1–2 weeks' rent) as explicit lines, noting they are negotiable — not a fixed cost.
- **Turnover costs money.** Because the letting fee recurs on each new tenancy, the plan flags that tenant retention (and lower turnover) improves net return — relevant when weighing a managing agent's quality, not just its fee.
- **Manage vs self-manage is a real fork.** The plan surfaces the fee saved by self-managing against the time and compliance burden (bond, condition reports, minimum standards) — decision-support, the investor chooses (the decision doc is `kb.investor.property-management-vs-self-managed`).
- **Banded, confirm with the agency.** Fees vary by state and agency; the binding figure is the management agreement the investor signs.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the PM cost lines are **resolver-estimated** from these benchmarks against the (effective) rent. The structure is grounded; the percentages are PLACEHOLDER — negotiable, state- and agency-variable, with no primary yet stating a market band.

```jsonc
{
  "fills": [],
  "parameters": {
    "management_fee_pct_default": { "type": "percentage", "value": 7.5, "note": "PLACEHOLDER — no primary states this; re-ground on several managing agencies' own published fee schedules. Default management fee as % of rent collected (the yield_modelling default); plus GST; charged on rent collected so vacancy reduces it" },
    "lease_renewal_fee_applies": { "type": "bool", "value": true, "note": "Consumer Affairs Victoria: 'Some agents also charge a re-leasing fee (also subject to negotiation) if current renters sign a new rental agreement.' Its size is not stated by a primary" },
    "sundries_loading": { "type": "string", "value": "modest loading for statement/admin, new-tenancy advertising, routine-inspection fees where applicable", "note": "Consumer Affairs Victoria names 'statement fees, administrative and/or postage costs'; their size is set per agency, bundled into the PM line as a modest loading" },
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
          "tier": "PLACEHOLDER",
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
          "note": "PLACEHOLDER — no primary states this; re-ground on several managing agencies' own published fee schedules (management % of rent collected, plus GST)",
          "label": {
            "vi": "Phí quản lý cho thuê (property management)",
            "en": "Property management fee"
          },
          "payer": {
            "vi": "Chủ nhà trả, trừ thẳng vào tiền thuê; được khấu trừ thuế",
            "en": "The owner pays, taken from the rent; tax-deductible"
          },
          "drivers": {
            "vi": "Khoảng tạm tính ~5–12% tiền thuê, tùy bang và công ty quản lý; có thể thương lượng. Trừ vào tiền thuê mỗi lần thu, cộng GST.",
            "en": "A placeholder ~5–12% of rent, varying by state and agency; negotiable. Taken out of the rent each time it is paid, plus GST."
          },
          "source": "https://www.consumer.vic.gov.au/housing/renting/starting-and-changing-rental-agreements/using-a-property-manager-or-agent"
        },
        {
          "id": "letting_fee",
          "phase": "own",
          "timing": "per_year",
          "tier": "PLACEHOLDER",
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
          "note": "PLACEHOLDER — no primary states this; re-ground on several managing agencies' own published fee schedules. 1–2 weeks' rent ÷ 52 weeks, assuming one re-let a year",
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
          "source": "https://www.consumer.vic.gov.au/housing/renting/starting-and-changing-rental-agreements/using-a-property-manager-or-agent"
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The PM cost lines are resolver-estimated from these benchmarks against the rent; the doc supplies the structures and bands, not a property-specific fee.
- **Structure grounded, percentages PLACEHOLDER.** Property management fees are not regulated figures — they are negotiable and vary by state and agency. Consumer Affairs Victoria grounds the structure (management fee, letting fee, re-leasing fee, sundries; all negotiable; recorded on the authority); the percentages await agencies' own fee schedules. The management agreement binds.
- **Cost here, decision elsewhere.** This doc owns the *fee structure and benchmarks* (consumed by `yield_modelling` for the cost line and by `ownership_planning_investor` for the management-cost side); the *PM-vs-self-managed decision* is owned by `kb.investor.property-management-vs-self-managed` (Cluster S). Single-owner via cross-ref.

## Sources

- Consumer Affairs Victoria — *Using a property manager or agent* (the management, letting and re-leasing fees and sundries; all negotiable; recorded on the authority, a percentage fee also as a dollar amount) — https://www.consumer.vic.gov.au/housing/renting/starting-and-changing-rental-agreements/using-a-property-manager-or-agent
- ASIC Moneysmart — *Buying an investment property* (property management fees as an ongoing cost of an investment property) — https://moneysmart.gov.au/property-investment/buying-an-investment-property
- ATO — *Common property expenses* (property agent fees and commission are a deductible rental expense) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/common-property-expenses
