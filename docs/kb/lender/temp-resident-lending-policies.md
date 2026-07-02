---
slug: kb.lender.temp-resident-lending-policies
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Lender policies for temporary residents and non-residents (the foreign-axis delta)

This doc owns the **non-resident / temporary-resident serviceability *delta*** — what changes about a lender's assessment when the borrower is a foreign person rather than a citizen or permanent resident. It is the foreign-axis analogue of [`kb.lender.serviceability-basics`](serviceability-basics.md): that doc owns the **universal framework every lender shares** (the APRA 3.0 pp buffer, HEM, DTI, income shading, genuine savings); this doc owns **only what is different for a foreign borrower** and points back to it for the shared core rather than restating it.

It grounds the `mortgage_finance` foreign-person variant (component 5) — specifically `borrowing_capacity.non_resident_lender_assessment`, `income_assessment_currency`, `lender_pool_size`, and `loan_path.recommended_path`. Every figure here is a **lender-policy convention** (flagged `CONVENTION`), not a regulated constant — surfaced as a typical band and deferred to a licensed mortgage broker for the borrower's actual lender policy (ASIC line: information / decision-support, no credit advice).

## The load-bearing distinction: AU income vs foreign income

The single fact that drives everything is **the currency the assessable income is earned in — not the visa label.**

- **Temporary resident living and working in Australia, earning AUD** — treated **close to a citizen / PR** by most lenders: full serviceability framework ([`kb.lender.serviceability-basics`](serviceability-basics.md)) with an ordinary deposit (typically 20% / 80% LVR), and up to 95% LVR when buying with an Australian citizen / PR / NZ-citizen partner. The visa is a check on *tenure*, not a capacity haircut.
- **Foreign person earning foreign income (e.g. VND)** — the restrictive regime: **income is shaded**, the **deposit is larger** ([`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md)), and the **lender pool is small** ([`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)).

This maps directly onto the component's `income_assessment_currency` enum (`AUD_au_employment_only` / `VND_with_haircut` / `blended`): the value the profile carries selects which regime the resolver applies.

## The deltas on the universal framework

Relative to the shared serviceability core, a foreign borrower faces:

- **Foreign-income shading.** Where income is earned overseas, lenders discount it before it enters the serviceability calculation — **typically ~20%**, but the range across lenders is wide (**some ~10%, some ~40%**), and some lenders will not count foreign income at all. This is *on top of* the ordinary non-base-income shading in [`kb.lender.serviceability-basics`](serviceability-basics.md); AUD income earned in Australia is **not** foreign-shaded.
- **Acceptable-currency lists.** Lenders that count foreign income restrict it to a **list of accepted currencies** and often require it converted at a conservative rate. VND is **not** universally accepted — a material constraint for the Vietnam-parent-funded / VN-income buyer, and a reason the funding structure ([`kb.cross-border.decision-authority-cultural`](../cross-border/decision-authority-cultural.md)) matters to the loan.
- **A small lender pool.** Only a subset of lenders write foreign-person / non-resident loans — **typically about 5–10** — versus the full market for a domestic borrower. Fewer options, not zero.
- **Visa tenure.** Lenders generally want **sufficient time remaining on the visa** (a common convention is ~12 months minimum) and confirmation of ongoing work rights.
- **A rate premium** on the non-resident product (owned as a band by [`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)) and **slower processing** ([`kb.lender.documentation-non-resident`](documentation-non-resident.md)).

The **APRA 3.0 pp buffer, HEM, and DTI** are unchanged — they apply identically. Capacity is lower for a foreign borrower because of shading and the deposit floor, **not** because the buffer differs.

## What this doc does not own

- The **deposit / LVR** bands → [`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md).
- The **485 / student-with-AU-income** path detail → [`kb.lender.485-visa-treatment`](485-visa-treatment.md).
- The **lender-selection criteria + ACL boundary** → [`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md).
- The **FIRB-approval-before-settlement gate** → [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).
- The **universal serviceability core** (buffer, HEM, DTI, genuine savings) → [`kb.lender.serviceability-basics`](serviceability-basics.md).
- The **visa-class catalogue** (which classes are temporary) → [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md).

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver reads the profile's `income_assessment_currency` and visa class, applies the shading + pool deltas below on top of the shared serviceability framework, and produces the banded `non_resident_lender_assessment`; this doc supplies the grounded deltas. No leaf asserted; capacity figures are resolver-computed (removed from the LLM's reach, as in [`kb.lender.serviceability-basics`](serviceability-basics.md)).

```jsonc
{
  "fills": [],
  "parameters": {
    "assessment_axis_is_income_currency_not_visa": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the delta is driven by whether assessable income is AUD-earned-in-AU vs foreign-earned — a temp resident earning AUD is assessed near-domestic; the visa label alone is not the haircut." },
    "foreign_income_shading_pct_typical": { "type": "int", "value": 20, "provenance": "CONVENTION", "note": "typical discount applied to overseas-earned income before serviceability; lender-specific and wide (see range)." },
    "foreign_income_shading_pct_range_low": { "type": "int", "value": 10, "provenance": "CONVENTION", "note": "some lenders shade foreign income as little as ~10%." },
    "foreign_income_shading_pct_range_high": { "type": "int", "value": 40, "provenance": "CONVENTION", "note": "some lenders shade ~40%, and some decline foreign income entirely; defer to a broker for the actual lender." },
    "au_income_not_foreign_shaded": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "AUD income earned in Australia by a temp resident is not foreign-shaded; ordinary serviceability applies (kb.lender.serviceability-basics)." },
    "acceptable_currency_list_applies": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "lenders that count foreign income restrict it to accepted currencies at conservative rates; VND is not universally accepted." },
    "non_resident_lender_pool_size_typical": { "type": "int", "value": 8, "provenance": "CONVENTION", "note": "representative count in the ~5–10 band of lenders that write foreign-person / non-resident loans; sizing hint, not authoritative." },
    "visa_tenure_min_months_convention": { "type": "int", "value": 12, "provenance": "CONVENTION", "note": "lenders commonly want ~12+ months remaining on the visa plus ongoing work rights; lender-specific." },
    "apra_buffer_unchanged_for_foreign": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 3.0 pp serviceability buffer, HEM and DTI apply identically — owned by kb.lender.serviceability-basics; lower foreign capacity comes from shading + deposit floor, not a different buffer." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *foreign-axis serviceability delta*. The universal core stays with [`kb.lender.serviceability-basics`](serviceability-basics.md); deposit, 485-path, criteria/ACL, and the FIRB gate each have their own owner (listed above). No restatement of the buffer/HEM/DTI.
- **Conventions, not regulated constants.** Every figure except the buffer inheritance is lender policy, flagged `CONVENTION`, so the agent presents typical bands and defers the borrower's actual treatment to a licensed broker (ASIC: no credit advice).
- **Removed-from-reach.** The capacity figure is computed by the resolver from these deltas + the shared framework; the agent never asserts a borrowing-capacity number.

## Sources

- ASIC Moneysmart — *How much you can borrow* (serviceability, income assessment, buffer) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
- Canstar — *Non-Resident Home Loans in Australia* (foreign-person deposit/LVR, restricted lender set, acceptable-income criteria) — https://www.canstar.com.au/home-loans/non-resident-home-loans/
- Home Loan Experts — *Temporary Resident Home Loans* (AU-income temp residents assessed near-domestic; foreign-income shading ~10–40%, typically 20%) — https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
- APRA — *APRA announces update on macroprudential settings* (serviceability buffer retained at 3.0 pp; DTI monitoring) — https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
