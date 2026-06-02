---
slug: kb.graduation.lvr80
effective_from: 2025-07-01
last_verified: 2026-06-01
---

# The 80% LVR graduation event — when the FHG falls away

A low-deposit loan **"graduates"** when its **loan-to-value ratio (LVR) drops below 80%**: at that point **LMI no longer applies at any lender**, the full lender market opens, and — for an [FHG](../scheme/fhg.md)-backed loan — the government guarantee has finished its work. This doc owns the **graduation milestone and its FHG implications**; it grounds `ownership_planning.lifecycle_alerts.graduation_event_lvr_target` (80), `estimated_graduation_years`, and `scheme_specific_alerts.fhg_ends_at_lvr_80_or_payoff`. The FHG *scheme rules* (eligibility, price caps) are owned by [`kb.scheme.fhg`](../scheme/fhg.md); the refinance *triggers and mechanics* by [`kb.refinance.windows-and-triggers`](../refinance/windows-and-triggers.md) — this doc supplies the milestone those alerts fire on.

## The 80% LVR milestone

- **LVR = loan balance ÷ property value.** As the loan amortises and the property (usually) appreciates, LVR falls. When it crosses **below 80%**, the loan graduates: **no LMI applies** at any lender, because LMI is only required above 80% LVR (see [`kb.lmi.calculation`](../lmi/calculation.md)).
- **The FHG becomes moot at the same point.** The FHG guarantees the slice of the loan between the buyer's deposit and 20%. Once equity reaches 20% (LVR < 80%), that guaranteed slice no longer exists — the guarantee has nothing left to cover and simply falls away.

## What graduation means for an FHG-backed buyer

- **No clawback.** The FHG is a **guarantee, not a grant** — nothing is repaid when it ends. The buyer used it to avoid LMI on entry; on graduation they owe nothing back. The guarantee also ends if the **loan is repaid, refinanced, or the property is sold** — in every case, with no repayment.
- **A free-market refinance window opens.** Below 80% LVR a refinance **cannot re-incur LMI**, so the full lender pool is available at the best rates — the clean first-refinance window. The triggers and switching mechanics are owned by [`kb.refinance.windows-and-triggers`](../refinance/windows-and-triggers.md); this doc supplies the milestone, that doc supplies what to do at it.
- **Estimating the year.** `estimated_graduation_years` is **resolver-computed** from the starting LVR, the amortisation schedule, and a conservative growth assumption — surfaced as an estimate, never a promise about future prices.

## Relevance for Vietnamese-Australian buyers (Mode A)

- A typical FHG 5%-deposit buyer enters at **~95% LVR**; graduation typically lands **~4–8 years in**, depending on repayments and price growth. The platform **arms the graduation alert** so the buyer reviews a refinance exactly when it becomes worthwhile — the lifecycle-continuity value: the same plan that got them in flags the moment the guarantee has done its job.
- **The reassurance matters.** Many first-home buyers fear an FHG "bill" later; the load-bearing message is that there is **no clawback** — graduation is purely an opportunity (cheaper refinance), not an obligation.
- **Information, not advice.** The alert prompts a *review*; the buyer (with a broker) decides and acts. See [`kb.refinance.windows-and-triggers`](../refinance/windows-and-triggers.md) (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `estimated_graduation_years` and `first_refi_window_target` are **resolver-computed** from loan facts (starting LVR, amortisation, growth assumption); the doc supplies the threshold and the FHG-exit semantics, not the dates.

```jsonc
{
  "fills": [],
  "parameters": {
    "graduation_lvr_threshold_pct":  { "type": "percentage", "value": 80, "note": "at/under 80% LVR no LMI applies (see kb.lmi.calculation) and the FHG guaranteed slice no longer exists — the milestone the ownership-planning alerts fire on" },
    "fhg_has_clawback":              { "type": "bool", "value": false, "note": "SCHEME — the FHG is a guarantee, not a grant; nothing is repaid when it ends. FHG eligibility/caps owned by kb.scheme.fhg (single-owner) — this doc owns only the exit" },
    "fhg_ends_on":                   { "type": "array<string>", "value": ["lvr_below_80", "loan_repaid", "refinanced", "property_sold"], "note": "the events at which the FHG guarantee falls away — all with no repayment/clawback" },
    "free_refinance_window_opens_at_graduation": { "type": "bool", "value": true, "note": "below 80% LVR a refinance cannot re-incur LMI → full lender pool opens; the refinance triggers/mechanics are owned by kb.refinance.windows-and-triggers" },
    "typical_graduation_years_low":  { "type": "integer", "value": 4, "note": "CONVENTION/indicative — typical lower bound for a ~95% LVR FHG loan to reach 80% LVR via amortisation + price growth; estimated_graduation_years is resolver-computed per loan, this is orientation only" },
    "typical_graduation_years_high": { "type": "integer", "value": 8, "note": "CONVENTION/indicative — typical upper bound; depends on repayments and growth" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The graduation-year estimate and the first-refi-window date are resolver-computed from loan facts; the doc supplies the threshold and the FHG-exit semantics.
- **Single-owner boundaries, deliberately.** The **FHG scheme rules** (eligibility, price caps, the guarantee replacing LMI on entry) are owned by [`kb.scheme.fhg`](../scheme/fhg.md); the **refinance triggers and switching mechanics** by [`kb.refinance.windows-and-triggers`](../refinance/windows-and-triggers.md); the **80%-LVR LMI trigger** by [`kb.lmi.calculation`](../lmi/calculation.md). This doc owns *only* the graduation milestone and what the FHG's end means — it cross-refs the three rather than duplicating them.
- **No-clawback is the load-bearing fact.** It is the reassurance that distinguishes a guarantee from a grant, captured explicitly so the agent never implies a future FHG repayment.
- **The year range is CONVENTION.** 4–8 years is orientation; the per-loan figure is resolver-computed and surfaced as an estimate, since it depends on unknowable future price growth.

## Sources

**Canonical (scheme administrator + regulator):**

- Housing Australia — *First Home Guarantee* (the scheme is a government **guarantee** enabling purchase with as little as 5% deposit without LMI; not a grant or a payment to the buyer) — https://www.housingaustralia.gov.au/support-buy-home/first-home-guarantee
- ASIC Moneysmart — *Lenders mortgage insurance* (LMI is required above 80% LVR and not below — the basis for the graduation threshold) — https://moneysmart.gov.au/home-loans/lenders-mortgage-insurance
