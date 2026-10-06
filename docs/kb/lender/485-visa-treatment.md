---
slug: kb.lender.485-visa-treatment
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
    retrieved: 2026-07-06
    note: "Temp resident with AU income assessed near-domestic — capped LVR usually 80% (sometimes 90% for strong applicants); up to 95% LVR when married/de facto with a citizen/PR; buying in an AU partner's name avoids FIRB and surcharges. Lender-policy convention (aggregator source), not a regulator figure"
---

# Lending treatment of the 485 graduate visa (and student-with-AU-income)

This doc owns the **485 Temporary Graduate visa lending path** — the specific case where a temporary resident is living and working in Australia on a 485 (or a student visa with AU employment) and earning AUD. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically `loan_path.temp_resident_loan_485_or_student_with_au_income.applicable` and its shortlist. The general foreign-axis framework is owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); this doc owns **why the 485 case is the favourable branch** and the conditions on it.

The visa-class catalogue (which classes are temporary, their FIRB/lending signals) is owned by [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md); this doc owns the *lending treatment*, not the visa definition. Figures are lender-policy **conventions** (flagged `CONVENTION`); the FIRB elements are cross-refs to their regulated owners.

## Why the 485 is the favourable branch

A 485 holder working in Australia earns **AUD income in Australia** — which, per the load-bearing distinction in [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md), means most lenders assess them **close to a citizen / PR**, not on the restrictive non-resident terms:

- **Up to ~80% LVR (20% deposit)** is typically available — ordinary domestic-style terms, not the 30–40% non-resident deposit ([`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md)).
- **No foreign-income shading** on the AUD income earned here (shading bites on *overseas* income, which a 485 holder working locally usually does not rely on).
- **Up to 95% LVR** when buying with an Australian citizen / PR / NZ-citizen partner as joint tenants.

So the 485 path is `applicable = true` precisely when the borrower has **AUD employment income in Australia**; it is the reason the component carries a distinct `temp_resident_loan_485_or_student_with_au_income` path separate from the `standard_non_resident_loan` path.

## The conditions that still apply

Favourable serviceability does **not** remove the foreign-person overlay:

- **FIRB approval is still required** before settlement — a 485 holder is a temporary resident, a foreign person for FIRB ([`kb.firb.status-determination`](../firb/status-determination.md), [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md)).
- **New dwellings only, under the established-dwelling ban** (1 Apr 2025 – 30 Jun 2029), unless an exemption applies ([`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md), [`kb.firb.eligible-property-types-foreign-persons`](../firb/eligible-property-types-foreign-persons.md)).
- **The foreign-buyer stamp-duty surcharge applies** (owned by `kb.foreign-buyer-surcharge.by-state`).
- **Visa tenure.** Lenders want sufficient time remaining on the 485 and confirmation of ongoing work rights (the ~12-month convention in [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md)).

## The joint-purchase route removes the overlay

Buying **with an Australian citizen / PR / NZ-citizen partner as joint tenants** removes the FIRB requirement, the foreign-buyer surcharge, and the established-dwelling ban for that purchase — and unlocks up to 95% LVR. This is the single most consequential structuring fact for a 485 holder partnered with a domestic buyer, and the plan should surface it early. (The FIRB consequence is owned by [`kb.firb.status-determination`](../firb/status-determination.md); this doc notes only its lending effect.)

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver sets `temp_resident_loan_485_or_student_with_au_income.applicable` from the profile's visa class + `income_assessment_currency == AUD_au_employment_only` and applies the near-domestic terms below; this doc supplies the grounded treatment. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "path_applicable_when_au_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the 485/student-with-AU-income path applies when the borrower earns AUD employment income in Australia; assessed near-domestic." },
    "typical_max_lvr_pct_solo": { "type": "int", "value": 80, "provenance": "CONVENTION", "note": "up to ~80% LVR (20% deposit) for a 485 holder with AU income buying alone." },
    "max_lvr_pct_with_au_partner": { "type": "int", "value": 95, "provenance": "CONVENTION", "note": "up to 95% LVR when buying with an AU citizen/PR/NZ-citizen partner as joint tenants." },
    "no_foreign_shading_on_au_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "AUD income earned in Australia is not foreign-shaded; overseas income (if relied on) still is (kb.lender.temp-resident-lending-policies)." },
    "firb_still_required_solo": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a 485 holder is a foreign person for FIRB; approval before settlement required when buying alone — owned by kb.firb.status-determination / kb.lender.firb-approval-as-condition-precedent." },
    "new_dwellings_only_under_ban": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "temporary residents restricted to new dwellings under the 1 Apr 2025 – 30 Jun 2029 ban — owned by kb.firb.established-dwelling-ban." },
    "joint_purchase_removes_firb_and_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "buying with an AU citizen/PR/NZ-citizen partner as joint tenants removes FIRB, the surcharge and the ban for that purchase — owned by kb.firb.status-determination." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *485 lending treatment*. The visa definition → [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md); the general foreign-axis framework → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); the FIRB status/ban/joint-tenant consequences → the `kb.firb.*` owners cross-referenced above.
- **Conventions vs regulated.** LVR/shading are lender `CONVENTION`; the FIRB/ban/surcharge facts are `REGULATED` but *owned elsewhere* — this doc points, does not restate the regulated substance.
- **The joint-purchase fact is the lever.** Surface it early for a 485 holder partnered with a domestic buyer — it changes both the FIRB position and the achievable LVR.

## Sources

- Professional Home Loans — *485 Graduate Visa Home Loan Australia* (up to 80% LVR solo; 95% with an AU partner; FIRB before settlement) — https://www.professionalhomeloans.com.au/home-loans/home-loan-485-graduate-visa/
- Home Loan Experts — *Temporary Resident Home Loan Australia* (485/student with AU income assessed near-domestic; joint purchase removes FIRB/surcharge/ban) — https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
- ASIC Moneysmart — *How much you can borrow* (LVR, deposit, serviceability) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
