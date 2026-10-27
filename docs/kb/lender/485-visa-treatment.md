---
slug: kb.lender.485-visa-treatment
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
    note: "Macquarie credit guidelines v15.0 §2B: a temporary resident borrowing alone is 'Outside guidelines.'; an AU citizen/PR borrowing with 'a spousal co-applicant who is a non-Australian citizen/non-permanent resident … who is not the predominant servicer of the loan' — 'Standard loan parameters apply.' (all applicants holding a current Australian residential address)."
  - url: https://www.commbank.com.au/home-loans/making-australia-home.html
    retrieved: 2026-10-27
    path: docs/sources/lenders/cba-making-australia-home.txt
    note: "CommBank: a temporary-visa holder's eligibility is checked case by case with a Home Lending Specialist."
  - url: https://www.bankwest.com.au/content/dam/bankwest/documents/legal-library/PDS_BWE-8017.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/bankwest-pds-bwe-8017.txt
    note: "Bankwest broker application checklist BWE-8017: asks for a FIRB approval/exemption certificate for temporary Australian resident visa holders — Bankwest considers them."
  - url: https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
    retrieved: 2026-10-27
    path: docs/sources/lenders/nab-fixed-rate-home-loan.txt
    note: "NAB home loans not available to applicants who require FIRB approval."
  - url: https://www.anz.com.au/personal/home-loans/get-started/
    retrieved: 2026-10-27
    path: docs/sources/lenders/anz-home-loans-get-started.txt
    note: "ANZ: applicants must be an Australian or New Zealand citizen or permanent resident."
  - url: https://distributor.amp.com.au/home-loans/policies
    retrieved: 2026-10-27
    path: docs/sources/lenders/amp-credit-policy-guide.txt
    note: "AMP Bank Credit Policy Guide: individual borrowers must be permanent residents or citizens of Australia or New Zealand."
  - url: https://www.latrobefinancial.com.au/lending/international-borrower-loan/
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-loan.txt
    note: "La Trobe International Borrower: Expatriate Loan maximum LVR 80%; Non-resident Loan maximum LVR 75% — a re-grounding candidate, not a 485-specific product."
  - url: https://foreigninvestment.gov.au/getting-started/investment-information/residential
    retrieved: 2026-10-10
    path: docs/sources/firb/residential-real-estate-2026-10-10.txt
    note: "FIRB, Residential real estate: no application required for joint tenants purchasing with their Australian citizen spouse, Australian permanent resident spouse, or New Zealand citizen spouse eligible to hold a special category visa."
---

# Lending treatment of the 485 graduate visa (and student-with-AU-income)

This doc owns the **485 Temporary Graduate visa lending path** — the specific case where a temporary resident is living and working in Australia on a 485 (or a student visa with AU employment) and earning AUD. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically `loan_path.temp_resident_loan_485_or_student_with_au_income.applicable` and its shortlist. The general foreign-axis framework is owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); this doc owns **why the 485 case is a distinct branch** and the conditions on it.

The visa-class catalogue (which classes are temporary, their FIRB/lending signals) is owned by [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md); this doc owns the *lending treatment*, not the visa definition. Lender figures are lender policy (`CONVENTION`), each tied to the lender that publishes it or marked PLACEHOLDER where no lender publishes it; the FIRB elements are cross-refs to their regulated owners.

## Why the 485 is a distinct branch

A 485 holder working in Australia earns **AUD income in Australia**. Whether that earns near-domestic treatment is **lender by lender**, and the lenders' own pages split sharply:

- **Some major lenders exclude temporary residents outright.** ANZ: "You must be over 18 years and an Australian or New Zealand citizen or permanent resident to apply." AMP Bank requires "Permanent residents or citizens of Australia or New Zealand". NAB's "Home loan products are not available to applicants who reside overseas (regardless of citizenship) and/or for applicants who require Foreign Investment Review Board (FIRB) approval" — and a 485 holder buying alone needs FIRB approval. Macquarie lists a temporary resident borrowing alone as "Outside guidelines."
- **Some consider them.** CommBank: "As a resident holding a permanent or temporary visa, book an appointment with a Home Lending Specialist to check if your current visa classification is eligible for a home loan." Bankwest's broker checklist asks for a "Foreign Investment Review Board (FIRB) approval/exemption certificate for temporary Australian resident visa holders eligible to purchase" property.

No lender page found states a maximum LVR for a 485 holder buying alone, nor that AUD income earned here escapes foreign-income shading. The plan therefore treats an ~80% LVR solo figure and "no foreign shading on AUD income" as **working assumptions to confirm with a broker**, not as published policy (both are PLACEHOLDER below).

So the 485 path is `applicable = true` when the borrower has **AUD employment income in Australia**; it is the reason the component carries a distinct `temp_resident_loan_485_or_student_with_au_income` path separate from the `standard_non_resident_loan` path — the lender pool is narrower than for a citizen, but it is not the non-resident pool ([`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md)).

## The conditions that still apply

Favourable serviceability does **not** remove the foreign-person overlay:

- **FIRB approval is still required** before settlement — a 485 holder is a temporary resident, a foreign person for FIRB ([`kb.firb.status-determination`](../firb/status-determination.md), [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md)).
- **New dwellings only, under the established-dwelling ban** (1 Apr 2025 – 30 Jun 2029), unless an exemption applies ([`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md), [`kb.firb.eligible-property-types-foreign-persons`](../firb/eligible-property-types-foreign-persons.md)).
- **The foreign-buyer stamp-duty surcharge applies** (owned by `kb.foreign-buyer-surcharge.by-state`).
- **Visa tenure.** Lenders that consider temporary residents check the visa; no lender page found publishes a minimum remaining term (the PLACEHOLDER in [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md)).

## The joint-purchase route removes the overlay

FIRB lists, among buyers for whom an application is **not** required: "Joint tenants who are purchasing with their: Australian citizen spouse; Australian permanent resident spouse; or New Zealand citizen spouse, who is eligible to hold a special category visa." So a 485 holder buying **with a citizen / PR / eligible NZ-citizen spouse as joint tenants** needs no FIRB approval for that purchase, and the established-dwelling ban (a condition of FIRB approval) does not bite. Whether the state foreign-buyer surcharge also falls away is a state rule, owned by `kb.foreign-buyer-surcharge.by-state`.

On the lending side, Macquarie treats an Australian citizen/PR borrowing with "a spousal co-applicant who is a non-Australian citizen/non-permanent resident (i.e. temporary resident or temporary visa holder) who is not the predominant servicer of the loan" under "Standard loan parameters apply." — provided every applicant holds a current Australian residential address; if the temporary-resident spouse is the predominant servicer it is "Outside guidelines." Macquarie's standard owner-occupied ceiling is "95% LVR inclusive of low deposit fee capitalisation." That is one lender's policy, not a market figure. This is the single most consequential structuring fact for a 485 holder partnered with a domestic buyer, and the plan should surface it early. (The FIRB consequence is owned by [`kb.firb.status-determination`](../firb/status-determination.md); this doc notes only its lending effect.)

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver sets `temp_resident_loan_485_or_student_with_au_income.applicable` from the profile's visa class + `income_assessment_currency == AUD_au_employment_only` and applies the terms below; this doc supplies the treatment. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "path_applicable_when_au_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the 485/student-with-AU-income path applies when the borrower earns AUD employment income in Australia. Lender acceptance is lender by lender: CommBank (case by case) and Bankwest (FIRB certificate for temporary resident visa holders) consider them; ANZ, AMP and NAB do not; Macquarie only with a citizen/PR co-applicant." },
    "typical_max_lvr_pct_solo": { "type": "int", "value": 80, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on https://www.commbank.com.au/home-loans/making-australia-home.html, https://www.bankwest.com.au/content/dam/bankwest/documents/legal-library/PDS_BWE-8017.pdf and https://www.latrobefinancial.com.au/lending/international-borrower-loan/. Working assumption only: Macquarie lists a temporary resident borrowing alone as 'Outside guidelines.'" },
    "max_lvr_pct_with_au_partner": { "type": "int", "value": 95, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this as a market figure; re-ground on the Macquarie credit guidelines §2B (https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf): with a temporary-resident spouse who is not the predominant servicer, 'Standard loan parameters apply.' (owner occupied 95% LVR) — one lender, all applicants at a current Australian address." },
    "no_foreign_shading_on_au_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on https://www.commbank.com.au/home-loans/making-australia-home.html. Lenders' published shading applies to foreign-currency income (kb.lender.temp-resident-lending-policies)." },
    "firb_still_required_solo": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a 485 holder is a foreign person for FIRB; approval before settlement required when buying alone — owned by kb.firb.status-determination / kb.lender.firb-approval-as-condition-precedent." },
    "new_dwellings_only_under_ban": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "temporary residents restricted to new dwellings under the 1 Apr 2025 – 30 Jun 2029 ban — owned by kb.firb.established-dwelling-ban." },
    "joint_purchase_removes_firb_and_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FIRB part: no application required for 'Joint tenants who are purchasing with their: Australian citizen spouse; Australian permanent resident spouse; or New Zealand citizen spouse, who is eligible to hold a special category visa.' (https://foreigninvestment.gov.au/getting-started/investment-information/residential; owned by kb.firb.status-determination). Surcharge part: a state rule owned by kb.foreign-buyer-surcharge.by-state." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *485 lending treatment*. The visa definition → [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md); the general foreign-axis framework → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); the FIRB status/ban/joint-tenant consequences → the `kb.firb.*` owners cross-referenced above; the surcharge → `kb.foreign-buyer-surcharge.by-state`.
- **Conventions vs regulated.** LVR/shading are lender `CONVENTION` (two are PLACEHOLDER until a lender publishes them); the FIRB/ban/surcharge facts are `REGULATED` but *owned elsewhere* — this doc points, does not restate the regulated substance.
- **The joint-purchase fact is the lever.** Surface it early for a 485 holder partnered with a domestic buyer — it changes the FIRB position, and at Macquarie it moves the loan onto standard parameters.

## Sources

- Macquarie — *Residential Home Loans Credit Guidelines* v15.0 (§2B residency; §1D owner-occupied LVR) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
- CommBank — *Making Australia home* (temporary-visa eligibility checked case by case) — https://www.commbank.com.au/home-loans/making-australia-home.html
- Bankwest — *Application Submission Checklist* BWE-8017 (FIRB certificate for temporary resident visa holders) — https://www.bankwest.com.au/content/dam/bankwest/documents/legal-library/PDS_BWE-8017.pdf
- NAB — *Fixed rate home loan* (not available where FIRB approval is required) — https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
- ANZ — *Get started* (citizen or permanent resident only) — https://www.anz.com.au/personal/home-loans/get-started/
- AMP Bank — *Credit Policy Guide* (permanent residents or citizens of Australia or New Zealand) — https://distributor.amp.com.au/home-loans/policies
- La Trobe Financial — *International Borrower Loan* (expatriate 80%, non-resident 75% maximum LVR) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
- Foreign Investment Review Board — *Residential real estate* (joint tenants with a citizen/PR/NZ-citizen spouse: no application) — https://foreigninvestment.gov.au/getting-started/investment-information/residential
