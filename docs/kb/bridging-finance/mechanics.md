---
slug: kb.bridging-finance.mechanics
effective_from: 2026-07-05
last_verified: 2026-07-06
sources:
  - url: https://www.westpac.com.au/personal-banking/home-loans/bridging-loan/
    retrieved: 2026-07-06
    note: "Westpac bridging loan — confirms ONLY the stable principle: a short-term (~12-month) facility to buy before selling, carrying combined 'peak debt' then 'end debt' after the sale, generally interest-only/capitalised. The doc's QUANTITATIVE content (peak-debt calc, capitalised-interest estimate, lender shortlist) REMAINS a deliberate placeholder — deferred on ACL-caution grounds per mode-e-wedge.md #3; this source does not ground those figures."
---

# ⚠ PLACEHOLDER — bridging finance mechanics (NOT SOURCE-GROUNDED)

**This doc's quantitative content is a labelled placeholder.** A Mode E buyer (upsizer/downsizer/relocator) who needs to **settle the new purchase before the old home sells** typically funds the gap with **bridging finance** — a short-term facility covering both properties' debt until the old home settles. But the **specific mechanics** — peak-debt calculation, capitalised-interest treatment, typical facility terms, and which lenders offer the product on what conditions — have **not been verified against any primary source this session**, and a grep of the entire `docs/kb/` tree confirms **zero existing bridging-*loan* content** (every prior "bridging" hit is bridging *visa*, a FIRB/immigration term — an unrelated homonym). This is the load-bearing reason it stays a placeholder rather than a full build (mode-e-wedge.md scoping decision #3): **recommending a specific bridging-loan structure** (a peak-debt figure, a capitalised-interest estimate, a lender shortlist) edges toward **credit-advice / ACL territory** — the same caution as the platform's standing "no named-lender recommendation" rule (constraint: don't recommend specific lenders/brokers in a way that requires ACL licensure).

This doc grounds the anticipated `bridging_finance_considered` flag on the **not-yet-built** existing-home-disposal resolver (mode-e-wedge.md P2), feeding `cash_position` — the resolver does not exist yet; this doc's job is to name the placeholder shape it must use once built, not to describe a live consumer.

## What can be stated now (stable principle, not a computed figure)

- **The trigger is a settlement-timing mismatch, not a financial-need concept.** Bridging finance is only relevant when the new purchase's settlement date falls **before** the old home's sale settles — a timing fact the plan can detect (two settlement dates, or one settlement date + no confirmed sale) without computing any bridging economics.
- **It is a distinct product category, commercially.** Bridging loans are typically offered by mainstream and non-bank lenders as a short-term facility bridging the equity between the two properties; terms (peak-debt cap, interest treatment — capitalised vs serviced, maximum term) are lender-specific and commercially set, not a regulated rate or figure.
- **Never a named-lender or named-structure recommendation.** Consistent with the platform's standing constraint, any guidance here always routes the buyer to a **mortgage broker or lender with the relevant credit licence (ACL)** to discuss bridging products, never a specific structure or provider asserted by the platform itself.

## What is PENDING (the placeholder datum)

- `bridging_finance_considered`: **may be set `true`** by the settlement-timing check above (a structural fact, not a regulated computation) — but once `true`, the plan does **not** proceed to compute peak debt, capitalised interest, or a facility recommendation. It surfaces the timing mismatch and stops.
- Any peak-debt formula, capitalised-interest estimate, typical facility term/rate, or lender shortlist.
- `is_bridging_likely_required`: **PENDING** as a *verdict* — the resolver may report the *fact* (mismatched settlement dates) but must not assert a recommendation-shaped conclusion ("you will need bridging finance") without a professional in the loop.

## Named re-ground obligation

Before this doc's mechanics can leave placeholder status, verify against (in order of authority):

1. **ASIC MoneySmart's own bridging-loan explainer** (if one exists) — the consumer-facing regulator source, analogous to how `kb.tax.cgt-main-residence-exemption` verified against the ATO directly.
2. **A specific ACL-licensed lender's or broker's published bridging-loan product terms** (peak-debt cap, capitalised-interest mechanics, typical term) — provider-primary, not a comparison-site aggregation.
3. **A mortgage broker consulted for the Mode-E wedge** (the credit-advice-adjacent professional-in-the-loop this doc currently lacks) — the authoritative source for a determination this close to ACL-licensed advice.

## Buyer pointer (what the plan says today)

Until re-grounded, the plan surfaces this as an **action item, not a computed verdict**: when the settlement-timing mismatch is detected, the buyer is pointed to a **mortgage broker or ACL-licensed lender** to discuss bridging finance options **before** committing to the new purchase's settlement date — informational routing to a licensed professional, not credit advice.

## Rules

Pure-reference (`fills: []`). All quantitative/mechanics content is `is_placeholder: true` — the resolver may surface the structural timing-mismatch fact, never a computed bridging-finance figure or recommendation, until re-grounded.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — bridging-loan mechanics not yet sourced against any primary; zero KB content exists (grep-confirmed 2026-07-05). Structure named, datum pending re-ground." },
    "trigger_is_settlement_timing_mismatch": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "bridging_finance_considered is set from a STRUCTURAL fact (new-purchase settlement date precedes old-home sale settlement, or the old home has no confirmed sale yet) — not a financial-need judgement, so this piece is NOT gated by the placeholder status." },
    "never_computes_peak_debt_or_recommends_structure": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — the resolver must not compute peak-debt, capitalised-interest, or facility terms, and must not name a lender or product, until this doc is re-grounded against an ACL-adjacent primary (credit-advice risk, mirrors the platform's standing no-named-lender-recommendation rule)." },
    "buyer_pointer_channel": { "type": "string", "value": "mortgage broker or ACL-licensed lender", "provenance": "CONVENTION", "note": "the only routing this doc gives today — a licensed professional, never a specific named provider or structure." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc.** The stable structural fact (settlement-timing mismatch detection) is asserted now; the bridging-economics content is PENDING pending an ACL-adjacent primary source.
- **The structural/regulated split is deliberate.** Detecting *that* a timing mismatch exists is a plain date comparison — no professional judgement, no placeholder needed. Computing *what that means financially* (peak debt, cost) is where the ACL-adjacent risk starts, and that's exactly what stays gated.
- **Consumer:** the anticipated existing-home-disposal resolver (mode-e-wedge.md P2, not yet built), feeding `cash_position`. Cross-refs: [`kb.existing-home-sale.net-proceeds`](../existing-home-sale/net-proceeds.md) (the sale-proceeds side of the same transition), [`kb.land-tax.dual-ownership-transition`](../land-tax/dual-ownership-transition.md) (the land-tax side of holding both properties during the same transition window).

## Sources

None yet — placeholder. Re-ground against ASIC MoneySmart (if a bridging-loan explainer exists), a specific ACL-licensed lender's or broker's published bridging-loan product terms, and/or a mortgage broker consulted for the Mode-E wedge.
