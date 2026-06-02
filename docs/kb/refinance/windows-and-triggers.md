---
slug: kb.refinance.windows-and-triggers
effective_from: 2025-07-01
last_verified: 2026-06-01
---

# Refinancing — the triggers (when) and the switching mechanics (how)

**Refinancing** replaces an existing home loan with a new one — either by **repricing with the same lender** or by **switching to a new lender** — to get a lower rate, a better structure, or to release equity. The planning questions are **when a refinance is worth reviewing** and **what switching costs**, so the saving can be weighed against the cost. This doc owns the **refinance triggers and the switching mechanics**; it grounds `mortgage_finance.refinance_planning` (`fixed_rate_roll_off_date`, `lvr_graduation_estimate_year`, `refinance_review_cadence_months`) and `ownership_planning.lifecycle_alerts` (`refi_review_cadence_months`, `first_refi_window_target`) — informationally, arming alerts, never directing a switch.

## When to review a refinance — the triggers

The agent arms an alert against each trigger; the buyer (with a broker) acts:

1. **Fixed-rate roll-off.** A fixed term ends and the loan reverts to the lender's (usually higher) variable rate — the moment to review before the revert bites. Grounds `refinance_planning.fixed_rate_roll_off_date`.
2. **LVR drops below 80% (the graduation window).** Once the loan is at/under 80% LVR, **no LMI applies either way** and the **full lender market opens** — the cleanest point to refinance a low-deposit loan. The **graduation event itself and its FHG implications are owned by `kb.graduation.lvr80`** (single-owner; this doc treats LVR-below-80% only as a *trigger* and does not re-derive the event). Grounds `lvr_graduation_estimate_year` / `first_refi_window_target`.
3. **Periodic rate review.** A review cadence of **~24 months** is the planning default (`refinance_review_cadence_months: 24`; the market norm is refinancing every 2–4 years); an **RBA cash-rate move** that widens the gap between the borrower's rate and market rates brings the review forward.
4. **Equity release / changed circumstances.** Releasing equity (e.g. for a renovation or a next property) or a change in income/structure. Later-stage and more investor-relevant — light for a Mode A owner-occupier.

## How switching works — the mechanics

- **Two forms.** **Internal repricing** (the *same* lender lowers the rate) avoids a discharge, new valuation and registration — it is the **cheapest first move and worth trying before switching**. **External refinance** (a *new* lender) is a fresh loan.
- **External refinance is a new credit application.** The new lender **re-assesses serviceability** (income, debts, buffer rate — see [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md)), so HECS, credit-card limits and BNPL matter again just as at first approval. It involves a **valuation**, **discharge of the old mortgage**, and **registration of the new mortgage**.

## The costs to weigh against the saving

- **Lender fees.** A **discharge/exit fee** from the old lender and an **application/establishment fee** plus **valuation fee** at the new one.
- **Government discharge + registration fees.** State-set mortgage discharge and registration fees apply — these are **owned by [`kb.buyer-costs.inspections-conveyancing-fees`](../buyer-costs/inspections-conveyancing-fees.md)** (per-state, regulated) and not re-tabled here.
- **Fixed-rate break cost.** Breaking a fixed loan early can incur a **break cost** — an *economic-cost* calculation (larger if market rates have fallen since fixing), not a flat fee. Can be substantial.
- **Fresh LMI above 80% LVR.** **LMI is not portable between lenders**, so refinancing while still **above 80% LVR can trigger a new premium** (see [`kb.lmi.calculation`](../lmi/calculation.md)). This is precisely why the **LVR-80 graduation window** is the clean refinance point.
- **The frame.** Switching pays only when the **ongoing saving outweighs the up-front cost** over a sensible horizon. ASIC Moneysmart's *mortgage switching calculator* computes that **recovery period**. The plan surfaces the break-even; it does not issue a switch instruction.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The FHG-backed 5%-deposit buyer's natural first refinance is the graduation window.** Until LVR reaches 80% a refinance can re-incur LMI and the guarantee is still doing work; once graduated, the full lender pool opens with no LMI either way. The platform arms `first_refi_window_target` for that moment — see `kb.graduation.lvr80`.
- **Fixed-rate FHBs should diary the roll-off date.** Revert rates are typically higher than the fixed rate; the alert prompts a *review*, not an automatic switch.
- **Information, not advice.** The agent surfaces the windows and the cost-vs-saving math and **arms alerts**; the buyer (with a broker) decides and acts. No steer to a specific lender — recommending a particular switch crosses into credit advice (ASIC: no credit advice without an ACL).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The alert dates (`fixed_rate_roll_off_date`, `first_refi_window_target`) and the graduation-year estimate are **resolver/agent-computed** from loan facts (fixed term, projected amortisation/LVR) against these triggers; the doc supplies the trigger set and the switching mechanics, not a verdict.

```jsonc
{
  "fills": [],
  "parameters": {
    "refinance_review_cadence_months":   { "type": "integer",    "value": 24, "note": "CONVENTION/planning — default periodic rate-review cadence; matches the blueprint's refi_review_cadence_months; market norm is refinancing every 2–4 years" },
    "lvr_free_refinance_threshold_pct":  { "type": "percentage", "value": 80, "note": "at/under 80% LVR no LMI applies either way → the clean refinance window; the graduation EVENT + FHG implications are owned by kb.graduation.lvr80 (single-owner — this is the trigger threshold only)" },
    "triggers":                          { "type": "array<string>", "value": ["fixed_rate_roll_off", "lvr_below_80_graduation", "periodic_rate_review", "rba_rate_move", "equity_release"], "note": "the trigger set the agent arms ownership_planning alerts against" },
    "lmi_transferable_between_lenders":  { "type": "bool", "value": false, "note": "LENDER/insurer — LMI is not portable; refinancing while still above 80% LVR can incur a fresh premium (see kb.lmi.calculation) — the reason to wait for the graduation window" },
    "internal_reprice_cheaper_than_external": { "type": "bool", "value": true, "note": "CONVENTION — same-lender repricing avoids discharge/registration/valuation costs; worth trying before an external switch" },
    "fixed_rate_break_cost_applies":     { "type": "bool", "value": true, "note": "CONVENTION — breaking a fixed loan early can incur an economic break cost (not a flat fee); larger if market rates fell since fixing" },
    "requires_fresh_serviceability_assessment": { "type": "bool", "value": true, "note": "an external refinance is a new credit application; income/debts/HECS/BNPL are re-assessed (see kb.lender.serviceability-basics)" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The alert dates and the graduation-year estimate are resolver/agent-computed from loan facts against these triggers; the doc supplies the trigger set and mechanics, not the dates.
- **Single-owner boundaries, deliberately.** The **LVR-80 graduation event and its FHG consequence** are owned by `kb.graduation.lvr80` (a sibling anchor, to be authored under Component 9); this doc references it as one trigger and does not re-derive it. **Government discharge/registration fees** are owned by [`kb.buyer-costs.inspections-conveyancing-fees`](../buyer-costs/inspections-conveyancing-fees.md); **LMI-on-refinance** by [`kb.lmi.calculation`](../lmi/calculation.md); **the serviceability re-assessment** by [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md). This doc cross-refs all three rather than duplicating them.
- **All figures CONVENTION — none regulated.** The 24-month cadence is a planning default; the 80% threshold is the LMI trigger (regulated treatment of *which* it owns lives in the LMI docs); the break-cost and reprice facts are market mechanics. Tagged so the agent presents them as "review around every two years / the clean window is graduation," never as a rule to refinance.
- **Internal-vs-external is the load-bearing mechanic.** Repricing with the existing lender avoids most switching costs, so it is the first lever — captured explicitly so the agent does not default to "switch lenders" when a same-lender rate review may capture the saving for free.

## Sources

**Canonical (regulator — ASIC):**

- ASIC Moneysmart — *Switching home loans* (refinancing to a lower rate can save money, but the benefits must outweigh the costs; check exit/break/application fees before switching; up-front fees added to the loan) — https://moneysmart.gov.au/home-loans/switching-home-loans
- ASIC Moneysmart — *Mortgage switching calculator* (works out whether switching saves money and how long it takes to recover the cost of switching — the recovery-period frame) — https://moneysmart.gov.au/home-loans/mortgage-switching-calculator
- ASIC — *Switching home loans? ASIC tips for refinancing* (regulator guidance on weighing the costs of refinancing against the saving) — https://www.asic.gov.au/about-asic/news-centre/news-items/switching-home-loans-asic-tips-for-refinancing/
