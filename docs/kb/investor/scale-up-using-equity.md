---
slug: kb.investor.scale-up-using-equity
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
    retrieved: 2026-07-06
  - url: https://www.apra.gov.au/prudential-practice-guide-apg-223-residential-mortgage-lending
    retrieved: 2026-07-06
    path: docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf
---

# Scaling up using equity

The way most investors buy a second (and third) property isn't by saving another deposit — it's by **releasing equity** from a property that has grown in value to fund the next deposit. This doc owns the **equity-release scale-up method and its risks** — how equity recycling works, what gates it, and where it goes wrong. The **serviceability, LVR, and DTI ceilings** that bound it are owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md) and the F-cluster loan-policy docs; this doc owns the *strategy and its risks*, not the lending figures. It grounds `ownership_planning_investor.scale_up_planning` and the `ready_for_next_property_at_lvr` / `equity_release_required_for_next` fields. It is a **decision-support** doc — it asserts no figure. Informational; ACL line — no credit advice, no lender recommendation.

## How equity recycling works

- **Equity is value minus loan.** As a property grows in value and/or the loan is paid down, the owner's equity rises. **Usable** equity is the portion a lender will release — bounded by the lender's maximum LVR (the LVR cap and how usable equity is calculated are owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md), not asserted here).
- **Release it as a deposit.** The usable equity is drawn (via a loan increase / separate facility) and used as the **deposit + costs** on the next property, which is itself ~80–90% financed. No cash deposit is saved; the portfolio funds its own growth.
- **`ready_for_next_property_at_lvr`** (blueprint default 70%) is the self-set trigger: when the existing property's LVR falls to the target through growth/paydown, there's enough equity to consider the next move. The valuation review ([`kb.investor.portfolio-review-cadence`](portfolio-review-cadence.md)) is where this is checked.

## What gates it — and where it bites

- **Serviceability is the real ceiling.** Equity gets you the deposit; **servicing** the larger total debt gets you the loan. Each new loan is assessed at the buffered rate over the whole position, and the **APRA DTI cap (from Feb 2026)** is the binding scale-up limit for higher-leverage borrowers — all owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md). A portfolio can have equity but no borrowing capacity.
- **Cross-collateralisation risk.** If the released equity is structured so the lender holds *both* properties as security for *both* loans, the investor loses flexibility (can't easily sell or refinance one) and concentrates risk. Structuring releases as **separate, stand-alone facilities** preserves flexibility — a structuring point to raise with a broker, not advice.
- **Over-leverage amplifies the downside.** Recycling equity raises total LVR across the portfolio; a value fall or a rate rise then hits a larger, more-leveraged base. Scale-up multiplies both the upside and the fragility.
- **Equity is not cash, and growth is not assured.** Released equity is *borrowed money* with an interest cost; and it only exists if the growth that created it materialised — which the projection band ([`kb.property.capital-growth-bands`](../property/capital-growth-bands.md)) explicitly does not promise.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The portfolio can fund its own growth.** The plan shows how released equity becomes the next deposit, with the LVR trigger checked at the valuation review.
- **Servicing — not equity — is the real ceiling.** The plan makes clear that having equity isn't the same as being able to service the next loan, and points to the serviceability and DTI rules.
- **Structure releases to keep flexibility.** The plan flags cross-collateralisation as a risk and raises stand-alone facilities as a structuring point for the broker.
- **Equity is borrowed, growth isn't promised.** The plan frames equity release as debt against unrealised, uncertain growth. ACL line — no credit advice. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **decision-support** doc — it fills no slot; the scale-up fields live in `ownership_planning_investor` and the lending ceilings are owned by the lender cluster. This doc supplies the strategy and its risks.

```jsonc
{
  "fills": [],
  "parameters": {
    "equity_recycling_funds_the_next_deposit": { "type": "bool", "value": true, "note": "usable equity is drawn and used as the deposit + costs on the next property; the portfolio funds its own growth — no fresh cash deposit saved" },
    "usable_equity_and_lvr_owner": { "type": "string", "value": "kb.lender.serviceability-investment-loans", "note": "OWNED ELSEWHERE — the LVR cap and how usable equity is calculated; not asserted here" },
    "serviceability_is_the_real_ceiling": { "type": "bool", "value": true, "note": "equity gets the deposit; servicing the larger total debt gets the loan — assessed at the buffered rate; the APRA DTI cap (Feb 2026) is the binding scale-up limit (kb.lender.serviceability-investment-loans)" },
    "cross_collateralisation_risk": { "type": "bool", "value": true, "note": "if the lender holds both properties as security for both loans, the investor loses flexibility + concentrates risk; stand-alone facilities preserve flexibility — a structuring point for the broker, not advice" },
    "over_leverage_amplifies_downside": { "type": "bool", "value": true, "note": "recycling raises total portfolio LVR; a value fall / rate rise hits a larger, more-leveraged base — scale-up multiplies upside AND fragility" },
    "equity_is_borrowed_growth_not_assured": { "type": "bool", "value": true, "note": "released equity is borrowed money with an interest cost, against growth that is unrealised and uncertain (kb.property.capital-growth-bands, labelled placeholder)" },
    "ready_at_lvr_trigger": { "type": "bool", "value": true, "note": "ready_for_next_property_at_lvr (blueprint default 70%) is the self-set trigger checked at the valuation review (kb.investor.portfolio-review-cadence)" }
  }
}
```

Notes:

- **No `fills`.** The scale-up fields live in `ownership_planning_investor`; the lending ceilings are the lender cluster's. This doc supplies the strategy and risks.
- **Single-owner via cross-ref.** Usable equity / LVR / serviceability / DTI cap → `kb.lender.serviceability-investment-loans`; growth uncertainty → `kb.property.capital-growth-bands`; the LVR trigger review → `kb.investor.portfolio-review-cadence`. This doc owns the equity-recycling strategy and its risks.
- **ACL line.** Strategy and risks only — no credit advice, no lender recommendation, no asserted lending figure; structuring points are raised for the broker.

## Sources

- ASIC Moneysmart — *Using equity to buy an investment property* (how equity release works; the risks of borrowing against your home) — https://moneysmart.gov.au/property-investment/investing-in-property
- APRA — *Prudential Practice Guide APG 223 Residential Mortgage Lending* (serviceability assessment; the buffered-rate test — referenced; owned by kb.lender.serviceability-investment-loans) — https://www.apra.gov.au/residential-mortgage-lending
