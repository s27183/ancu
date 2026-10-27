---
slug: kb.lender.temp-resident-lending-policies
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
    note: "Macquarie credit guidelines v15.0: §3E foreign income — 'only 80% of the amount after conversion at current exchange rates is to be used for loan servicing'; acceptable currencies GBP, EUR, HKD, NZD, SGD, USD, CAD, JPY and CHF. §2B: a temporary resident borrowing alone is 'Outside guidelines.'"
  - url: https://distributor.amp.com.au/home-loans/policies
    retrieved: 2026-10-27
    path: docs/sources/lenders/amp-credit-policy-guide.txt
    note: "AMP Bank Credit Policy Guide, Foreign income: 'Maximum of 80% foreign income (salary, investment, rental) is acceptable' in listed currencies; Tier 1 currencies 80%, Tier 2 (Chinese Yuan) 50%. Borrowers must be permanent residents or citizens of Australia or New Zealand."
  - url: https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf
    retrieved: 2026-10-27
    path: docs/sources/apra/apg-223-2025-06.txt
    note: "APG 223: 'It would also be good practice to discount offshore income in assessing a borrower's loan servicing capacity.'"
  - url: https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
    retrieved: 2026-10-27
    path: docs/sources/apra/macroprudential-settings-update.txt
    note: "The mortgage serviceability buffer will remain at 3 percentage points — applies identically to foreign borrowers (the buffer is not the source of lower foreign capacity)."
  - url: https://www.commbank.com.au/home-loans/making-australia-home.html
    retrieved: 2026-10-27
    path: docs/sources/lenders/cba-making-australia-home.txt
    note: "CommBank: temporary-visa eligibility checked case by case with a Home Lending Specialist."
  - url: https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
    retrieved: 2026-10-27
    path: docs/sources/lenders/nab-fixed-rate-home-loan.txt
    note: "NAB home loans not available to applicants who reside overseas or who require FIRB approval."
  - url: https://www.westpac.com.au/personal-banking/home-loans/key-fact-sheet/
    retrieved: 2026-10-27
    path: docs/sources/lenders/westpac-key-fact-sheet.txt
    note: "Westpac: 'Residential lending is not available for Non-Australian Resident borrowers.'"
  - url: https://www.anz.com.au/personal/home-loans/get-started/
    retrieved: 2026-10-27
    path: docs/sources/lenders/anz-home-loans-get-started.txt
    note: "ANZ: applicants must be an Australian or New Zealand citizen or permanent resident."
---

# Lender policies for temporary residents and non-residents (the foreign-axis delta)

This doc owns the **non-resident / temporary-resident serviceability *delta*** — what changes about a lender's assessment when the borrower is a foreign person rather than a citizen or permanent resident. It is the foreign-axis analogue of [`kb.lender.serviceability-basics`](serviceability-basics.md): that doc owns the **universal framework every lender shares** (the APRA 3.0 pp buffer, HEM, DTI, income shading, genuine savings); this doc owns **only what is different for a foreign borrower** and points back to it for the shared core rather than restating it.

It grounds the `mortgage_finance` foreign-person variant (component 5) — specifically `borrowing_capacity.non_resident_lender_assessment`, `income_assessment_currency`, `lender_pool_size`, and `loan_path.recommended_path`. Every figure here is **lender policy** (flagged `CONVENTION`), not a regulated constant — each band names the lenders that publish it, and a figure no lender publishes is marked PLACEHOLDER. All of it is surfaced as a typical band and deferred to a licensed mortgage broker for the borrower's actual lender policy (ASIC line: information / decision-support, no credit advice).

## The load-bearing distinction: AU income vs foreign income

The single fact that drives everything is **the currency the assessable income is earned in — not the visa label.**

- **Temporary resident living and working in Australia, earning AUD** — the lender pool is narrower than for a citizen (ANZ and AMP lend only to citizens and permanent residents; NAB not where FIRB approval is required; Macquarie lists a temporary resident borrowing alone as "Outside guidelines."), but some lenders consider them (CommBank: "As a resident holding a permanent or temporary visa, book an appointment with a Home Lending Specialist to check if your current visa classification is eligible for a home loan."). The lenders' published foreign-income shading applies to foreign-currency income; none found says how AUD income of a temporary resident is treated, so the plan's "assessed near-domestic" is a working assumption to confirm with a broker. Detail → [`kb.lender.485-visa-treatment`](485-visa-treatment.md).
- **Foreign person earning foreign income (e.g. VND)** — the restrictive regime: **income is shaded**, the **deposit is larger** ([`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md)), and the **lender pool is small** ([`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)).

This maps directly onto the component's `income_assessment_currency` enum (`AUD_au_employment_only` / `VND_with_haircut` / `blended`): the value the profile carries selects which regime the resolver applies.

## The deltas on the universal framework

Relative to the shared serviceability core, a foreign borrower faces:

- **Foreign-income shading.** APRA calls it "good practice to discount offshore income in assessing a borrower's loan servicing capacity" (APG 223), and lenders publish the discount. Macquarie: "only 80% of the amount after conversion at current exchange rates is to be used for loan servicing" — a 20% shading. AMP Bank: "Maximum of 80% foreign income (salary, investment, rental) is acceptable" for its Tier 1 currencies, and 50% for its Tier 2 currency (Chinese Yuan) — a 50% shading. So a **typical ~20%**, up to **50%** at the published high end; some lenders do not count foreign income at all. This is *on top of* the ordinary non-base-income shading in [`kb.lender.serviceability-basics`](serviceability-basics.md).
- **Acceptable-currency lists.** Lenders that count foreign income restrict it to a list. Macquarie: "Acceptable foreign currencies are GBP, EUR, HKD, NZD, SGD, USD, CAD, JPY and CHF." AMP Bank's list is CAD, CNY, EUR, GBP, HKD, JPY, NZD, SGD and USD. **VND is on neither list** — a material constraint for the Vietnam-parent-funded / VN-income buyer, and a reason the funding structure ([`kb.cross-border.decision-authority-cultural`](../cross-border/decision-authority-cultural.md)) matters to the loan.
- **A small lender pool.** Only a subset of lenders write foreign-person / non-resident loans. Westpac: "Residential lending is not available for Non-Australian Resident borrowers."; NAB excludes applicants who reside overseas or need FIRB approval; ANZ lends only to citizens and permanent residents. No primary gives a count of the lenders that do; the plan's figure is a PLACEHOLDER. Fewer options, not zero.
- **Visa tenure.** Lenders that consider temporary residents check the visa class (CommBank, above); no lender page found publishes a minimum remaining term, so the plan's ~12 months is a PLACEHOLDER to confirm with a broker.
- **A rate premium** on the non-resident product (owned as a band by [`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)) and **slower processing** ([`kb.lender.documentation-non-resident`](documentation-non-resident.md)).

The **APRA 3.0 pp buffer, HEM, and DTI** are unchanged — APRA's announcement says "the mortgage serviceability buffer will remain at 3 percentage points" with no foreign-borrower variant. Capacity is lower for a foreign borrower because of shading and the deposit floor, **not** because the buffer differs.

## What this doc does not own

- The **deposit / LVR** bands → [`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md).
- The **485 / student-with-AU-income** path detail → [`kb.lender.485-visa-treatment`](485-visa-treatment.md).
- The **lender-selection criteria + ACL boundary** → [`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md).
- The **FIRB-approval-before-settlement gate** → [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).
- The **universal serviceability core** (buffer, HEM, DTI, genuine savings) → [`kb.lender.serviceability-basics`](serviceability-basics.md).
- The **visa-class catalogue** (which classes are temporary) → [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md).

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver reads the profile's `income_assessment_currency` and visa class, applies the shading + pool deltas below on top of the shared serviceability framework, and produces the banded `non_resident_lender_assessment`; this doc supplies the deltas. No leaf asserted; capacity figures are resolver-computed (removed from the LLM's reach, as in [`kb.lender.serviceability-basics`](serviceability-basics.md)).

```jsonc
{
  "fills": [],
  "parameters": {
    "assessment_axis_is_income_currency_not_visa": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "model rule: the delta is driven by whether assessable income is AUD-earned-in-AU vs foreign-earned. Lenders publish shading for foreign-currency income (Macquarie §3E, AMP); the visa label still gates eligibility lender by lender (kb.lender.485-visa-treatment)." },
    "foreign_income_shading_pct_typical": { "type": "int", "value": 20, "provenance": "CONVENTION", "note": "LENDER-POLICY band — Macquarie: 'only 80% of the amount after conversion at current exchange rates is to be used for loan servicing' (20%); AMP Bank: 'Maximum of 80% foreign income' for Tier 1 currencies (20%)." },
    "foreign_income_shading_pct_range_low": { "type": "int", "value": 10, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on the La Trobe International Borrower term sheet (https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf, foreign income used for serviceability)." },
    "foreign_income_shading_pct_range_high": { "type": "int", "value": 50, "provenance": "CONVENTION", "note": "LENDER-POLICY band — AMP Bank: Tier 2 currency (Chinese Yuan) 50% of foreign income acceptable (50% shading); Macquarie: 20%. Some lenders decline foreign income entirely; defer to a broker for the actual lender." },
    "au_income_not_foreign_shaded": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on https://www.commbank.com.au/home-loans/making-australia-home.html. Published shading (Macquarie, AMP) is on foreign-currency income." },
    "acceptable_currency_list_applies": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY band — Macquarie: 'Acceptable foreign currencies are GBP, EUR, HKD, NZD, SGD, USD, CAD, JPY and CHF.'; AMP Bank: CAD, CNY, EUR, GBP, HKD, JPY, NZD, SGD, USD. VND is on neither list." },
    "non_resident_lender_pool_size_typical": { "type": "int", "value": 8, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on the lenders' own eligibility pages (e.g. https://www.westpac.com.au/personal-banking/home-loans/key-fact-sheet/, https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan, https://www.latrobefinancial.com.au/lending/international-borrower-loan/). Sizing hint only." },
    "visa_tenure_min_months_convention": { "type": "int", "value": 12, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on https://www.commbank.com.au/home-loans/making-australia-home.html (visa classification checked case by case)." },
    "apra_buffer_unchanged_for_foreign": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 3.0 pp serviceability buffer, HEM and DTI apply identically — owned by kb.lender.serviceability-basics; lower foreign capacity comes from shading + deposit floor, not a different buffer." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *foreign-axis serviceability delta*. The universal core stays with [`kb.lender.serviceability-basics`](serviceability-basics.md); deposit, 485-path, criteria/ACL, and the FIRB gate each have their own owner (listed above). No restatement of the buffer/HEM/DTI.
- **Lender policy, not regulated constants.** Every figure except the buffer inheritance is lender policy, flagged `CONVENTION`, so the agent presents typical bands and defers the borrower's actual treatment to a licensed broker (ASIC: no credit advice). PLACEHOLDER figures are working assumptions, never stated as fact.
- **Removed-from-reach.** The capacity figure is computed by the resolver from these deltas + the shared framework; the agent never asserts a borrowing-capacity number.

## Sources

- Macquarie — *Residential Home Loans Credit Guidelines* v15.0 (§2B residency; §3E foreign income and currencies) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
- AMP Bank — *Credit Policy Guide* (borrowers; foreign income tiers) — https://distributor.amp.com.au/home-loans/policies
- APRA — *APG 223 Residential Mortgage Lending* (June 2025; discounting offshore income) — https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf
- APRA — *APRA announces update on macroprudential settings* (serviceability buffer retained at 3 percentage points) — https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
- CommBank — *Making Australia home* (temporary-visa eligibility case by case) — https://www.commbank.com.au/home-loans/making-australia-home.html
- NAB — *Fixed rate home loan* (eligibility) — https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
- Westpac — *Home loan key fact sheet* (no residential lending to non-Australian residents) — https://www.westpac.com.au/personal-banking/home-loans/key-fact-sheet/
- ANZ — *Get started* (citizen or permanent resident only) — https://www.anz.com.au/personal/home-loans/get-started/
