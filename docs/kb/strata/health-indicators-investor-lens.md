---
slug: kb.strata.health-indicators-investor-lens
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/strata/living/levies-finances-insurance
    retrieved: 2026-07-06
    note: "NSW Government — administrative fund + capital works fund; levies as the owner's recurring cost; special levies for major works. The ATO rental-expense deductibility page and the Moneysmart strata-levy glossary both block automated fetch this session; body citations retained."
---

# Strata / owners-corporation health — the investor lens

For an investor buying an apartment or townhouse in a strata scheme, the scheme's health is read through an extra filter the owner-occupier doesn't apply: **how it hits yield, cash flow, and resale**. This doc owns the **investor-specific deltas** on strata health — it **builds on** the general rubric and the regulated funding backbone owned by [`kb.strata.health-indicators`](health-indicators.md) and adds only what changes when the buyer is an investor. The regulated fund-planning horizons (NSW 10-year capital-works plan, QLD ≥9-year sinking fund, VIC tier 1&2 maintenance plan) are **owned by the framework doc and referenced here, not re-declared**. Informational; the strata records and a strata report are the binding source.

## What changes under the investor lens

- **The levy is a recurring operating expense that eats yield.** For an owner-occupier the levy is a cost of living; for an investor it is a deductible **operating-expense line** that directly reduces net rental yield. The scheme's `body_corporate_quarterly_fees` flow straight into [`kb.investor.operating-expenses-typical-ratios`](../investor/operating-expenses-typical-ratios.md) as the body-corporate line — so a high levy isn't just an outgoing, it lowers the yield the whole thesis rests on.
- **A special levy is a cash-flow shock, not just a one-off bill.** An under-funded sinking fund (the framework's core metric) means a future **special levy** — for an investor that lands as an unplanned hit to a cash-flow model that may already be negatively geared, and it is **not** rent-recoverable. Fund inadequacy is therefore a *cash-flow risk*, weighted more heavily than for an owner-occupier who absorbs it personally.
- **Scheme health is a resale-liquidity factor.** A scheme with high levies, special-levy history, defects (e.g. combustible cladding), or governance disputes is **harder to sell and to finance** — lenders and future buyers discount it. For an investor whose return depends on an eventual exit, scheme health feeds the `disposition`/resale side, not only the holding cost.
- **By-laws and short-stay rules affect lettability.** Scheme by-laws can restrict letting, pets, or short-stay — directly affecting the tenant pool and the income strategy. An owner-occupier rarely checks these; an investor must.
- **Deductibility of strata costs.** Ordinary levies are deductible against rental income; **special levies for capital works are generally not immediately deductible** (they may form part of the capital-works/cost-base treatment) — a tax nuance flagged, with the detail owned by [`kb.tax.depreciation-division-43-and-40`](../tax/depreciation-division-43-and-40.md) and a tax adviser confirming.

## Same rubric, investor weighting

The framework doc's health dimensions (fund adequacy, levy level in context, special-levy history, insurance currency, financial position, physical/structural, governance) all still apply — the investor lens **re-weights** them toward cash-flow and resale impact rather than personal amenity. A low levy that signals under-funding is, for an investor, a *future cash-flow risk to the yield model*, not just "a saving to investigate".

## Relevance for Vietnamese-Australian investors (Mode C)

- **The levy is a yield line, not just a cost.** The plan flows the body-corporate fee into the operating-expense model, so the investor sees a high levy directly compress net yield.
- **Special-levy risk threatens the cash-flow plan.** The plan weights an under-funded sinking fund as a cash-flow shock (unplanned, non-recoverable), heavier than an owner-occupier would — protecting a possibly geared position.
- **Health is also a resale factor.** The plan reads scheme health as affecting resale liquidity and financeability, feeding the exit/disposition side, not just the holding cost.
- **Check by-laws and letting rules.** The plan flags scheme restrictions on letting/short-stay/pets as lettability factors — and notes the deductibility nuance on special levies. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the `strata_or_building` leaves carry the scheme's facts, scheme health is **agent-reasoned** against the framework rubric, and this doc adds the investor-lens weightings. The regulated funding horizons are referenced from the framework doc, not re-declared.

```jsonc
{
  "fills": [],
  "parameters": {
    "levy_is_operating_expense_eating_yield": { "type": "bool", "value": true, "note": "INVESTOR DELTA — the body-corporate levy is a recurring deductible operating expense that directly reduces net yield; body_corporate_quarterly_fees flows into kb.investor.operating-expenses-typical-ratios" },
    "special_levy_is_cash_flow_shock": { "type": "bool", "value": true, "note": "INVESTOR DELTA — an under-funded sinking fund → a future special levy = an unplanned, non-rent-recoverable hit to a possibly geared cash-flow model; fund inadequacy is a cash-flow risk, weighted heavier than for an owner-occupier" },
    "scheme_health_affects_resale_liquidity": { "type": "bool", "value": true, "note": "INVESTOR DELTA — high levies / special-levy history / defects / governance disputes make a scheme harder to sell and finance; feeds the disposition/resale side, not only holding cost" },
    "bylaws_affect_lettability": { "type": "bool", "value": true, "note": "INVESTOR DELTA — scheme by-laws restricting letting / short-stay / pets affect the tenant pool and income strategy; an investor must check them" },
    "special_levy_deductibility_nuance": { "type": "bool", "value": true, "note": "INVESTOR DELTA — ordinary levies are deductible against rent; special levies for capital works are generally NOT immediately deductible (capital-works/cost-base treatment) — detail owned by kb.tax.depreciation-division-43-and-40, tax adviser confirms" },
    "framework_owner": { "type": "string", "value": "kb.strata.health-indicators", "note": "OWNED ELSEWHERE — the general health rubric AND the regulated fund-planning horizons (NSW 10yr/5yr-review, QLD ≥9yr, VIC tier 1&2, building-insurance-to-replacement-value); referenced, NOT re-declared here" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set; the strata facts come from the records, health is agent-reasoned against the framework rubric, and this doc supplies the investor-lens re-weighting.
- **Variant builds on framework.** The general rubric and all regulated funding horizons are owned by `kb.strata.health-indicators`; this doc declares only the investor deltas (levy-as-yield-line, special-levy-as-cash-flow-shock, resale liquidity, by-laws, deductibility) and references the framework's regulated constants rather than re-stating them — single-owner at the param level.
- **Cross-refs.** Levy → `kb.investor.operating-expenses-typical-ratios`; deductibility detail → `kb.tax.depreciation-division-43-and-40`. No regulated horizon is duplicated.

## Sources

- NSW Government — *Your strata levies, finances and insurance* (administrative + capital works funds; the levy as the owner's recurring cost) — https://www.nsw.gov.au/housing-and-construction/strata/living/levies-finances-insurance
- ATO — *Rental expenses you can claim now* (body corporate fees and charges as a deductible rental expense; special-levy capital-works treatment differs) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/rental-expenses-you-can-claim-now
- ASIC Moneysmart — *Body corporate and strata fees* (levies as an ongoing cost; special levies for major works) — https://moneysmart.gov.au/glossary/strata-levy
