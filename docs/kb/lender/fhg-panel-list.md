---
slug: kb.lender.fhg-panel-list
effective_from: 2025-10-01
last_verified: 2026-06-01
---

# First Home Guarantee — participating-lender panel

The [First Home Guarantee](../scheme/fhg.md) (and the rest of the Home Guarantee Scheme) is delivered **only through a closed panel of lenders authorised by Housing Australia**. A borrower cannot obtain an FHG-backed loan directly from Housing Australia or from a non-panel lender — the guarantee attaches to a loan written by a **participating lender**. This doc owns the **fact of the panel** (who can write the loan, how the panel works) so `mortgage_finance` can populate the `fhg_backed_path.panel_lender_shortlist` and reason about lender choice within the panel. It does **not** recommend a lender — the per-borrower fit reasoning (rate, HECS treatment, approval likelihood) is the agent's, drawing on [`kb.lender.serviceability-basics`](serviceability-basics.md), [`kb.lender.hecs-treatment-by-lender`](hecs-treatment-by-lender.md) and the live panel.

## How the panel works

- **Housing Australia sets the panel.** It authorises lenders to offer the guarantee; the list is maintained on the Housing Australia / `firsthomebuyers.gov.au` site and **changes over time** (lenders are added; brands consolidate). Treat the live page as source of truth — do not hard-code a membership list that will drift.
- **All four major banks participate** (ANZ, Commonwealth Bank, NAB, Westpac — the last including its St George / Bank of Melbourne / BankSA brands), alongside **~25+ non-major lenders**: customer-owned banks, credit unions, mutuals and regional banks. The total panel is **~30+ lenders** (counted around 30–35 institutions, more if brand sub-labels are listed separately).
- **You apply through the lender** (directly or via a mortgage broker who deals with that lender), not through Housing Australia. The lender checks scheme eligibility, reserves a guarantee place, and processes the loan.

## What the guarantee changes — and what it doesn't

- **The guarantee is uniform across the panel.** It lets an eligible buyer borrow with a **5% deposit and no LMI** (Housing Australia guarantees the portion of the loan above 80% LVR). That benefit is identical whichever panel lender writes the loan.
- **The loan is an ordinary loan.** Each lender applies **its own interest rate, serviceability policy, fees and credit assessment** — there is **no special "FHG rate"**, and crucially **no rate premium for using the guarantee**. So the choice among panel lenders is a normal best-loan comparison (rate, HECS/credit-card treatment, processing time, genuine-savings policy), not a scheme question.
- **Guarantee places are not unlimited per lender at all times.** Since 1 October 2025 the scheme overall has unlimited places, but a given lender may pace its own allocation; the agent should treat availability as a per-lender operational fact, confirmed at application.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The panel includes both majors and customer-owned banks**, several of which have community or first-home niches — useful when a buyer prefers an institution they or their family already bank with. The agent surfaces the panel breadth; the buyer chooses.
- **No rate penalty for the guarantee** is worth stating plainly: a common worry is that the 5%-deposit path costs more in rate. It does not — the saving is the avoided LMI, with no offsetting rate premium.
- **Broker vs direct** is a genuine choice here because the panel is wide; a broker who covers many panel lenders can compare across them. This stays on the information side — surface the option, don't direct the buyer to a specific broker or lender (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `mortgage_finance.loan_path_comparison.fhg_backed_path.panel_lender_shortlist` and the lender-fit synthesis are **agent-reasoned** against the live panel, not asserted here. The doc supplies the structural facts (panel is closed and Housing-Australia-set; all four majors in; no rate premium) the agent grounds that reasoning in.

```jsonc
{
  "fills": [],
  "parameters": {
    "panel_is_closed":              { "type": "bool",    "value": true,  "note": "an FHG-backed loan can be written ONLY by a Housing-Australia-authorised participating lender" },
    "panel_set_by":                 { "type": "string",  "value": "Housing Australia", "note": "membership maintained on firsthomebuyers.gov.au; volatile — resolve against the live list, do not hard-code names" },
    "panel_size_approx":            { "type": "integer", "value": 32,    "note": "~30+ lenders as at last_verified; approximate and drifting — for sizing only, not an authoritative count" },
    "all_four_majors_participate":  { "type": "bool",    "value": true,  "note": "ANZ, CBA, NAB, Westpac (incl. St George / Bank of Melbourne / BankSA) all on the panel as at 2026-06" },
    "fhg_rate_premium":             { "type": "bool",    "value": false, "note": "no interest-rate premium for using the guarantee — the loan is priced as the lender's ordinary loan; the benefit is avoided LMI only" },
    "apply_via":                    { "type": "string",  "value": "participating lender or a broker dealing with one", "note": "application + place reservation happen at the lender, not at Housing Australia" }
  }
}
```

Notes:

- **No `fills`.** Nothing in any outcome is set by this doc. The FHG *eligibility* verdict is owned by [`kb.scheme.fhg`](../scheme/fhg.md) (component 3); the *panel shortlist* is an agent-populated `mortgage_finance` array (component 4). This doc grounds the latter with structural facts only.
- **Membership is deliberately not enumerated.** The panel changes; listing 30+ names (with brand sub-labels) would rot between deploys and invite a stale recommendation. The load-bearing facts are stable — closed panel, Housing-Australia-set, all four majors in, no rate premium — and those are what the parameters capture. `panel_size_approx` is a sizing hint, flagged approximate.
- **Lender-policy facts live in the sibling docs.** How a given panel lender treats HECS, credit cards or BNPL — the substance of choosing *among* panel lenders — is owned by [`kb.lender.hecs-treatment-by-lender`](hecs-treatment-by-lender.md), [`kb.lender.credit-card-treatment`](credit-card-treatment.md) and [`kb.lender.bnpl-treatment-2026`](bnpl-treatment-2026.md). This doc is the panel framework; those are the per-lender variation.
- **Information, not advice.** The doc and the agent describe the panel and how it works; they never assert a "best" or "recommended" FHG lender. The buyer chooses; this keeps the surface on the ASIC information / decision-support side (no credit advice) and matches the independence constraint (the buyer is the customer).

## Sources

- Housing Australia — *Home Guarantee Scheme participating lenders* (panel authorised by Housing Australia; apply via a participating lender) — https://www.housingaustralia.gov.au/home-guarantee-scheme-participating-lenders
- First Home Buyers (Housing Australia) — *Participating lenders, Australian Government 5% Deposit Scheme* (all four majors plus customer-owned / regional lenders; ~30+ panel) — https://firsthomebuyers.gov.au/australian-government-5-percent-deposit-scheme/5-percent-participating-lenders
- Housing Australia — *Unlimited places, higher property price caps for first home buyers from 1 October 2025* — https://www.housingaustralia.gov.au/media/unlimited-places-higher-property-price-caps-first-home-buyers-1-october-2025
