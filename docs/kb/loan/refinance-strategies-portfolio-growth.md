---
slug: kb.loan.refinance-strategies-portfolio-growth
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Refinance strategies — portfolio growth via equity

Investors scale a portfolio by **releasing equity** from existing properties to fund the next deposit, rather than saving a fresh cash deposit each time. This doc owns the **mechanics and risks** of equity-release refinancing so `ownership_planning_investor` can frame scale-up: how usable equity is calculated, why the serviceability re-test (not the equity) is usually the binding constraint, and the cross-collateralisation trap. It is a **reference / decision-support** doc — the scale-up *strategy* is owned by [`kb.investor.scale-up-using-equity`](../investor/scale-up-using-equity.md); this doc owns the *refinance mechanics*. Informational; a broker and tax adviser confirm the structure (ACL line).

## Usable equity

**Usable equity** is not the full gap between value and loan. Lenders let you borrow back up to a target LVR — typically **80% of the property's current value, minus the current loan balance** (you can go to **90% with LMI**, at extra cost). For a property worth $800,000 with a $400,000 loan, usable equity at 80% is $800,000 × 80% − $400,000 = **$240,000**. Releasing it requires a **revaluation** and a new loan or split. This is the figure the plan bands when projecting scale-up capacity (cross-ref [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)).

## Equity is necessary but rarely sufficient — serviceability is the binding constraint

Having usable equity does not mean a lender will release it. **Every equity release is a new loan and triggers a full serviceability re-test** — assessed at the buffered rate, with **all existing mortgages counted as commitments** and the **DTI cap** (≥6× income limited to 20% of new lending from Feb 2026) applying. As a portfolio grows, the buffered repayments on existing debt accumulate and **serviceability — not equity — becomes the ceiling**. The plan models scale-up against the serviceability re-test, not just the equity available, so it does not over-promise the next purchase.

## The cross-collateralisation trap

When equity is released, the lender may **cross-collateralise** — using more than one property as security for the loans (e.g. a new purchase secured against both the new property and an existing one). This is convenient but risky: it **entangles the properties** (selling one requires the lender's consent and can trigger a revaluation of the whole group; a default exposes all secured properties; refinancing away is harder). The general guidance the plan surfaces is to **keep loans standalone** — release equity as a **separate split** against the existing property, and secure the new purchase against itself — so each property can be sold or refinanced independently. Whether to cross-collateralise is a decision-support point, not a recommendation.

## Clean use of released funds

Equity released to fund an **investment** keeps its interest deductible (the "use" test — the funds are used to produce income). Releasing equity and using it for a **private** purpose is non-deductible and contaminates the split (cross-ref [`kb.loan.offset-vs-redraw-investor`](offset-vs-redraw-investor.md)). The plan flags structuring the release as a clean, separately-identifiable investment borrowing.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Equity recycling is the scale-up engine.** The plan shows usable equity (banded at 80% LVR) as the funding path to the next property — but anchors it to the serviceability re-test, not the equity alone.
- **Serviceability caps the portfolio, not equity.** The plan flags that past a point the buffered cost of existing debt and the DTI cap stop further borrowing even with equity available.
- **Avoid entangling properties.** The plan surfaces the cross-collateralisation trap and the standalone-split alternative so each property stays independently sellable.
- **Decision-support, advisers confirm.** Structure and timing are decided with a broker and tax adviser; the plan stays informational (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference / decision-support** doc — it fills no slot; usable equity is **resolver-computed** (formula → code) from the property value and loan balance, and the scale-up projection is anchored to the serviceability re-test owned by `kb.lender.serviceability-investment-loans`.

```jsonc
{
  "fills": [],
  "parameters": {
    "usable_equity_target_lvr_pct":    { "type": "percentage", "value": 80, "note": "CONVENTION — usable equity ≈ value × 80% − current loan (to 90% with LMI at extra cost); resolver computes the band from value and loan balance" },
    "usable_equity_with_lmi_lvr_pct":  { "type": "percentage", "value": 90, "note": "CONVENTION — equity can be released to ~90% LVR with LMI; more cash out, higher cost" },
    "equity_release_triggers_serviceability_retest": { "type": "bool", "value": true, "note": "every equity release is a new loan → full serviceability re-test at the buffered rate with all existing debt counted; serviceability (not equity) is usually the binding scale-up constraint (cross-ref kb.lender.serviceability-investment-loans, DTI cap)" },
    "avoid_cross_collateralisation":   { "type": "bool", "value": true, "note": "decision-support — keeping loans standalone (separate split + secure new purchase against itself) keeps each property independently sellable/refinanceable; cross-collateralisation entangles them. Not a recommendation, a flagged trade-off" },
    "released_equity_deductible_if_investment_use": { "type": "bool", "value": true, "note": "REGULATED (ATO 'use' test) — interest on released equity is deductible only if the funds are used to produce income; private use is non-deductible (cross-ref kb.loan.offset-vs-redraw-investor)" }
  }
}
```

Notes:

- **No `fills`.** Usable equity is resolver-computed from value and loan balance (a formula §11.9 keeps in code); the scale-up projection is anchored to the serviceability re-test owned elsewhere. The doc supplies the mechanics and the binding-constraint framing.
- **Equity vs serviceability.** The load-bearing investor insight — equity is necessary but serviceability (buffer + DTI cap) is usually the ceiling — is owned here and anchored to `kb.lender.serviceability-investment-loans`.
- **Cross-refs, not duplicates.** The scale-up *strategy* is owned by `kb.investor.scale-up-using-equity` (Cluster S); deductibility of released funds by `kb.loan.offset-vs-redraw-investor`; serviceability by the lender doc. This doc owns the *refinance mechanics*.
- **Cross-collateralisation is a flagged trade-off, not advice.** Decision-support framing keeps it on the information side of the ACL line.

## Sources

- ASIC Moneysmart — *Using equity in your home* (usable equity; borrowing against equity; risks) — https://moneysmart.gov.au/home-loans
- ATO — *Interest expenses* (deductibility follows the use of borrowed funds; the "use" test) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/interest-expenses
- APRA — *Activating debt-to-income limits as a macroprudential policy tool* (DTI ≥6 lending limit from Feb 2026 — the scale-up ceiling) — https://www.apra.gov.au/activating-debt-to-income-limits-as-a-macroprudential-policy-tool
