---
slug: kb.tax.negative-gearing-mechanics
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Negative gearing — the mechanics

**Gearing** is borrowing to invest. A rental property is **negatively geared** when its **deductible expenses (including loan interest) exceed its rental income** — producing a **net rental loss** that can be deducted against the owner's **other assessable income** (salary, wages, business income) for the year, reducing tax. This doc owns **what gearing is, the three gearing positions (negative / neutral / positive), how a net rental loss is applied and carried forward, and the load-bearing caveat that a tax saving from negative gearing is a saving on a real cash loss**. It grounds the `tax_structure` component's **gearing position** field as **decision-support** — it states the mechanism and the trade-off, and never asserts that negative gearing is "attractive" or that an investor "should" gear negatively (that crosses into tax/financial advice; AFSL/ACL territory). Confirm any gearing decision with a registered tax agent.

## The three gearing positions

| Position | Condition | Tax effect | Cash effect |
|---|---|---|---|
| **Negatively geared** | deductible expenses (incl. interest) **>** rental income | net rental **loss** deducted against other income → reduces tax | out-of-pocket each year; relies on capital growth to come out ahead |
| **Neutrally geared** | deductible expenses **≈** rental income | ~nil net rental income | roughly cash-neutral |
| **Positively geared** | rental income **>** deductible expenses | net rental **income** added to assessable income → increases tax | cash-positive each year |

These are descriptions of an outcome, not a ranking. Which position an investor is in falls out of the loan size, the interest rate, the rent, and the expenses — it is an input to the plan's cash-flow and tax projection, not a goal the plan recommends.

## How a net rental loss is applied

When a property is negatively geared, the **full net rental loss** (rental income minus all deductible rental expenses, including interest, for the income year) can be deducted against the owner's other assessable income in that year. Where other income is **insufficient** to absorb the loss, the unused amount is **carried forward** to the next income year. Deductible expenses include loan interest, council rates, insurance, property-management fees, repairs and maintenance, and the **decline in value / capital works deductions** ([`kb.tax.depreciation-division-43-and-40`](depreciation-division-43-and-40.md)) — the depreciation component is what makes a property's *tax* position more negative than its *cash* position.

## The load-bearing caveat — a tax saving on a real loss

A negatively geared property delivers a tax saving **only because it is making a loss**: the investor is out-of-pocket on cash each year and recovers the after-tax shortfall **only if capital growth exceeds the accumulated holding losses** on disposal. The strategy therefore **depends on capital growth** (a forward-looking, uncertain quantity — see [`kb.property.growth-corridors-au`](../property/growth-corridors-au.md), a labelled placeholder) and is sensitive to interest-rate movements. The plan **surfaces** this dependency rather than presenting the tax deduction as a free benefit — the tax saving is real, but it is the wrong figure to optimise in isolation.

## Announced reform — 2026-27 Federal Budget (proposed, not yet law)

The 2026-27 Federal Budget (Budget night **7:30pm AEST, 12 May 2026**) announced that negative gearing for residential property would be **limited to new builds** from **1 July 2027**. As of authoring this is **proposed, not enacted** — the *Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* has been **introduced but has not passed Parliament**. Current full negative gearing (a net rental loss deductible against other income) **remains law** through the transition.

What the reform would do:

- **Properties held at 7:30pm AEST 12 May 2026 are grandfathered** — existing arrangements unchanged for the life of that holding.
- For an **established** property **purchased after Budget night**, from 1 July 2027 a net rental loss can **no longer be deducted against salary or other personal income** — only against **residential rental income or future capital gains from rental property**, with **unused losses carried forward** to later years.
- **New builds remain fully negatively gearable** (losses deductible against other income) — the reform's deliberate steer toward new supply.

This **directly reshapes the wedge's target case**: a Vietnamese-Australian investor buying an **established** property **now** (after Budget night) would, from 1 July 2027, lose the offset against wages — a material change to the after-tax cash-flow story that the headline "negative gearing" benefit assumes. The plan **computes the current-law position** and **flags the announced reform prominently** for any established post-Budget purchase; it neither models unenacted law as settled nor stays silent on a public change that removes the headline benefit for the wedge's own buyer. Re-confirm enactment with a registered tax agent / the ATO.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The gearing position is computed, not chosen for the user.** The plan reports whether the modelled property is negatively, neutrally, or positively geared from the loan, rent, and expense inputs — and what the net rental loss/income is — as an input to the cash-flow and tax projection.
- **Depreciation widens the tax–cash gap.** The non-cash deductions (capital works + plant) can make a property negatively geared for *tax* while close to neutral for *cash* — surfaced explicitly so the investor sees both.
- **Growth dependence is named.** A negative-gearing position is only sound if growth covers the holding losses; the plan states this and points to the (labelled-placeholder) growth thesis rather than implying the deduction alone makes the deal work.
- **Information, not advice.** The plan describes the mechanics and the trade-off and points to a registered tax agent; it never tells an investor to gear negatively or calls the strategy attractive.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the gearing position and net rental loss/income are **resolver-computed** from the loan, rent, and expense inputs (control flow → code, per §11.9), not asserted, and never editorialised as good or bad.

```jsonc
{
  "fills": [],
  "parameters": {
    "net_rental_loss_deductible":        { "type": "bool", "value": true, "note": "REGULATED (ATO) — a net rental loss (deductible expenses incl. interest > rental income) is deductible against other assessable income for the income year" },
    "unused_loss_carried_forward":       { "type": "bool", "value": true, "note": "REGULATED (ATO) — where other income is insufficient to absorb the loss, the unused amount is carried forward to the next income year" },
    "interest_is_deductible_expense":    { "type": "bool", "value": true, "note": "REGULATED (ATO) — interest on money borrowed to acquire/maintain the rental property is a deductible rental expense and is counted in the gearing test" },
    "gearing_position_is_decision_support": { "type": "bool", "value": true, "note": "POLICY (ASIC line) — the plan reports the gearing position and net loss/income as computed facts; it never recommends a gearing strategy or calls one 'attractive'" },
    "announced_reform_not_yet_law":      { "type": "string", "value": "2026-27 Budget (12 May 2026): proposed limiting of negative gearing to new builds from 1 July 2027 (Treasury Laws Amendment (Tax Reform No. 1) Bill 2026 — introduced, NOT yet passed); properties held at 7:30pm AEST 12 May 2026 grandfathered; established property purchased after Budget night loses the offset against wages from 1 July 2027 (losses only vs rental income / future capital gains, carried forward); new builds remain fully negatively gearable", "note": "PROPOSED — not enacted; full negative gearing remains current law through the transition. Resolver computes current law and flags the reform prominently for an established post-Budget purchase. Re-confirm enactment." }
  },
  "lookup": {
    "gearing_positions": {
      "note": "the three positions keyed by the relation of deductible expenses to rental income; resolver classifies the modelled property and reports it (no ranking)",
      "entries": [
        { "position": "negative", "condition": "deductible_expenses > rental_income", "net": "rental loss deducted against other income; depends on capital growth to recover" },
        { "position": "neutral",  "condition": "deductible_expenses ≈ rental_income", "net": "≈ cash-neutral" },
        { "position": "positive", "condition": "rental_income > deductible_expenses", "net": "net rental income added to assessable income" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The gearing position and net rental loss/income are resolver-computed from the loan/rent/expense inputs; the doc supplies the mechanism and the deductibility rules, not a figure or a verdict.
- **REGULATED — verified against the ATO.** Net rental loss deductibility against other income, carry-forward of unused losses, and interest as a deductible expense were confirmed against the ATO *Negative gearing* and *How to claim rental expenses* pages (verified 2026-06-23).
- **Decision-support, not advice.** The single most important discipline in this doc: report the gearing position and the trade-off (a tax saving on a real cash loss that depends on growth); never recommend gearing negatively. This is the ASIC line, enforced as a policy parameter.
- **Depreciation links here.** The non-cash deductions that widen the tax–cash gap are owned by `kb.tax.depreciation-division-43-and-40`; this doc references them as part of deductible expenses, it does not own their rates.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *Negative gearing* (a property is negatively geared when it is bought with borrowed funds and rental income is less than deductible expenses including interest) — https://www.ato.gov.au/forms-and-instructions/rental-properties-2025/other-tax-considerations
- ATO — *How to claim rental expenses* (a net rental loss may be claimed against rental and other income; where other income is insufficient the loss is carried forward) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/how-to-claim-rental-expenses
- ATO — *IT6 Net rental property loss* (definition and treatment of the net rental property loss) — https://www.ato.gov.au/forms-and-instructions/individual-tax-return-2025-instructions/income-test-it1-it8-individual-tax-return-2025/it6-net-rental-property-loss-2025

**Announced reform (proposed, not yet law — verified 2026-06-23):**

- ATO — *Tax reform – Boosting home ownership – Reforming negative gearing and capital gains tax* (negative gearing limited to new builds from 1 July 2027; established post-Budget purchases lose the offset against other income; not yet law) — https://www.ato.gov.au/about-ato/new-legislation/in-detail/individuals/tax-reform-boosting-home-ownership-reforming-negative-gearing-and-capital-gains-tax
- Treasury — *Budget 2026-27 tax system changes* — https://treasury.gov.au/policy-topics/taxation/budget2026-27
- Parliament of Australia — *Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* (introduced; not yet passed) — https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/bd/bd2526/26bd067
