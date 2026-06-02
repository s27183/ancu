---
slug: kb.lender.hecs-treatment-by-lender
effective_from: 2025-09-30
last_verified: 2026-06-01
---

# HECS-HELP treatment in serviceability — by lender

Every lender counts the **compulsory HELP repayment** at the borrower's income as a committed expense that reduces borrowing capacity — that universal principle, and the repayment schedule it draws on, live in [`kb.lender.serviceability-basics`](serviceability-basics.md) and [`kb.hecs.thresholds`](../hecs/thresholds.md). This doc owns the **variation**: a 2025 regulatory change let lenders, *by exception*, **exclude** the HELP repayment from serviceability in narrow cases, and the major banks have adopted different versions of that exception. The variation is material to `mortgage_finance`'s "clear HECS before applying?" reasoning and its lender shortlist — because the *same* HECS balance can bind capacity at one lender and be ignored at another.

## The 2025 APRA change (the snapshot moved)

On **19 June 2025** APRA finalised targeted changes to **APG 223** (Residential Mortgage Lending) and **ARS 223.0**, effective **30 September 2025**, clarifying how ADIs treat HELP debt:

- **Near-term-payoff exception.** APRA confirmed it can be reasonable for a lender to **remove the HELP repayment from serviceability** where the borrower is expected to **pay the HELP debt off in the near term** through compulsory repayments — in practice lenders apply this where the debt clears within about **12 months**.
- **DTI reporting clarification.** APRA also clarified that HELP debt may be treated differently in the **debt-to-income** metric, removing a reason lenders had previously kept HELP fully loaded into capacity.

This **inverts** pre-2025 guidance that HELP always reduced capacity for its full term. It is **relief by exception, not a blanket exclusion** — the baseline expectation remains that lenders count the HELP repayment in most assessments.

## Major-bank adoption (illustrative, time-sensitive)

The exception is implemented per-lender; the policies below are **examples as at `last_verified`, not an exhaustive or guaranteed list** — confirm at application:

- **Commonwealth Bank (CBA)** — from **April 2025**, excludes the HELP repayment from serviceability where the debt is expected to be **repaid within 12 months**; has also **piloted a reduced serviceability buffer** (toward ~1% instead of 3%) for borrowers due to clear HELP within ~5 years.
- **NAB** — from **31 July 2025**, may **disregard HELP balances of $20,000 or less** in the assessment.
- **ANZ and Westpac** — have signalled easing of HELP treatment in line with the APRA change; specific thresholds vary and move.

The pattern: a **small or near-cleared** HELP balance is increasingly likely to be ignored, which can make **not** clearing it the better call (preserving deposit cash). A **large** balance still loads capacity at most lenders.

## Why this drives lender choice and the clear-HECS decision

- `mortgage_finance.debt_optimisation_recommendations.hecs` weighs **clearing the balance** (lifts capacity, drains deposit cash) against **leaving it** — and the right answer now depends on **which lender** and **how close to payoff** the balance is. A buyer with a $15k balance might keep the cash and choose a lender that disregards it, rather than clearing it.
- `mortgage_finance.lender_synthesis.lenders_with_lenient_hecs` is the agent's shortlist of lenders whose HELP treatment suits this borrower. This doc grounds that list with the policy facts; the agent does the matching.

## Relevance for Vietnamese-Australian buyers (Mode A)

- The typical Mode A buyer is a university-educated professional carrying a HELP balance — so lender HELP treatment is frequently the **binding capacity lever**, and the 2025 change is genuinely favourable.
- Where a buyer is within ~12 months of clearing HELP, surface the lenders applying the near-payoff exception — the capacity uplift can be large without spending the deposit.
- Keep it informational: present the lender policies as **published, time-sensitive facts to confirm**, not as a recommendation of a particular lender (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The capacity impact and the lenient-lender shortlist are **agent/resolver-reasoned** from these facts plus the borrower's balance and income, not asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "apra_near_term_payoff_exclusion_allowed": { "type": "bool",    "value": true,         "note": "REGULATED (APG 223, finalised 19 Jun 2025, effective 30 Sep 2025) — by exception a lender MAY exclude the HELP repayment from serviceability where the debt is paid off in the near term via compulsory repayments" },
    "apra_change_effective_date":              { "type": "date",    "value": "2025-09-30" },
    "near_term_payoff_window_months":          { "type": "integer", "value": 12,           "note": "CONVENTION — the ~12-month horizon lenders typically apply the near-payoff exception within; not a fixed regulatory figure" },
    "baseline_is_still_counted":               { "type": "bool",    "value": true,         "note": "REGULATED baseline — outside the exception, the HELP repayment is still counted in serviceability (relief is targeted, not blanket)" },
    "cba_payoff_exclusion_window_months":      { "type": "integer", "value": 12,           "note": "LENDER POLICY (CBA, from Apr 2025), time-sensitive — excludes HELP repayment if debt repaid within 12 months; confirm at application" },
    "cba_reduced_buffer_pilot":                { "type": "bool",    "value": true,         "note": "LENDER POLICY (CBA pilot), time-sensitive — reduced serviceability buffer (~1% vs 3%) where HELP clears within ~5 years" },
    "nab_disregard_balance_at_or_below":       { "type": "money",   "value": 20000,        "note": "LENDER POLICY (NAB, from 31 Jul 2025), time-sensitive — may disregard HELP balances ≤$20,000; confirm at application" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set here. The compulsory-repayment figure is resolver-computed from [`kb.hecs.thresholds`](../hecs/thresholds.md); the capacity uplift from clearing, and the lenient-lender shortlist, are agent-reasoned in `mortgage_finance`. This doc supplies the per-lender policy facts those computations consume.
- **Regulated vs lender-policy, tagged.** Only the APRA items (`apra_near_term_payoff_exclusion_allowed`, `apra_change_effective_date`, `baseline_is_still_counted`) are regulatory. The bank-specific thresholds (`cba_*`, `nab_*`) are **lender policy and time-sensitive** — flagged so the agent presents them as "confirm with the lender," never as fixed rules or as a steer toward that lender (ASIC information line). Same discipline as the `CONVENTION` tagging in [`kb.lender.serviceability-basics`](serviceability-basics.md).
- **Named-lender policies will drift fastest.** The CBA / NAB figures are the most perishable facts in the KB — they are dated in the notes and `last_verified` is the freshness anchor. The stable, load-bearing fact is the APRA exception itself; the named examples illustrate how it is being applied.
- **No day-count or balance comparison as a `criteria`.** Whether a given borrower clears within 12 months, or sits under $20k, is control flow over the balance + income — resolver code per §11.9, consuming these numbers. The doc supplies the thresholds, not a declarative predicate.

## Sources

**Canonical (regulator + lenders' own policy pages):**

- APRA — *Clarifying the treatment of Higher Education Loan Program debt obligations* (final changes to APG 223 / ARS 223.0, June 2025; near-term-payoff exception; effective 30 September 2025) — https://www.apra.gov.au/clarifying-treatment-of-higher-education-loan-program-debt-obligations
- NAB — *Does HECS affect your home loan application?* (NAB's own policy: a HELP/HECS balance of $20,000 or less does not affect borrowing capacity, with ATO evidence; cites the APRA near-term-payoff guidance) — https://www.nab.com.au/personal/life-moments/home-property/buy-first-home/hecs-home-loan
- CommBank Newsroom — *First home buyers taking new steps to get on the property ladder* (12 March 2026; CBA confirms "a more nuanced view of HELP debt" in its home-lending settings) — https://www.commbank.com.au/articles/newsroom/2026/03/first-home-buyers-taking-new-steps-to-get-on-property-ladder.html

**Point-in-time reporting** — the dated CBA specifics below are not stated on CBA's own current pages; retained as the source-of-record for those figures, to be re-verified at `last_verified`:

- savings.com.au — *CBA eases HECS home loan restrictions* (excludes HELP where repaid within 12 months, from April 2025; reduced-buffer pilot) — https://www.savings.com.au/news/cba-eases-hecs-home-loan-restrictions
