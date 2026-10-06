---
slug: kb.non-resident.investment-loan-deposit-requirements
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.canstar.com.au/home-loans/non-resident-home-loans/
    retrieved: 2026-07-06
    note: "SECONDARY — WebFetched 2026-07-06. NOTE: the page uses 30% deposit @ 70% LVR / 40% @ 60% LVR only as an ILLUSTRATIVE explanation of how LVR works, and states deposit/LVR terms are lender-dependent — it does NOT assert the 30-40% band as a firm non-resident requirement. This is a synthesis doc (fills: []); the firm band is OWNED by kb.lender.foreign-buyer-deposit-requirements, which is where the authoritative citation belongs."
  - url: https://www.odinmortgage.com/resources/7-australian-banks-and-lenders-that-finance-investment-properties-for-non-residents-what-each-one-requires-in-2026/
    retrieved: 2026-07-06
    note: "SECONDARY — WebFetched 2026-07-06. Confirms non-resident investment lending has tighter/individualized LVR policies and foreign-income shading, but gives no single firm deposit %/LVR figure (borrower-profile dependent)."
  - url: https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
    note: "POINTER (not re-fetched this session) — ASIC Moneysmart general borrowing-to-invest / investment-loan risk context (not a non-resident-specific figure); carried from the doc's markdown Sources block."

# Deposit requirements — non-resident investment loans

This doc owns the **synthesis** of two single-owned facts for the specific case a pure foreign-buyer doc and a pure domestic-investor doc don't individually state: what a **non-resident investor** (Vietnam-located, buying to let, not to occupy) needs as a deposit. It grounds `cash_position` (component 8) `deposit_requirements.minimum_required_percentage_non_resident_investment_loan`. It owns no new figure — it states which band applies and why the "with an AU partner" reduced-deposit path does not.

## The band is residency-driven, not occupancy-driven — so it's the same band

The **30–40% deposit / 60–70% LVR cap** for a foreign person earning foreign income, owned by [`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md), is keyed on the borrower's **residency and income currency**, not on whether they intend to occupy or let the property. A non-resident investor faces the **same 30–40% band** as a non-resident buying to occupy — lender policy differentiates owner-occupier from investment loans by rate and serviceability treatment (investment loans are generally assessed more conservatively — [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)), not by a separate, higher deposit floor specifically for the non-resident-investment combination.

## What genuinely changes for the investment case

- **No first-home-buyer leniency.** [`kb.investor.deposit-requirements-investment-loans`](../investor/deposit-requirements-investment-loans.md)'s "no FHB schemes apply" fact holds for a non-resident investor exactly as it does for a domestic one — there was never an FHB path to begin with, but the plan should not imply otherwise.
- **The "buying with an AU citizen/PR partner" reduced-deposit path (down to 5%) does not apply the same way.** That path in the foreign-buyer-deposit doc assumes the purchase is assessed on the AU co-borrower's footing for what is, in substance, their home. A Vietnam-located investor's co-ownership structure (if any) is an investment decision, not a partner-occupancy one — the plan should not surface the 5%-deposit joint-purchase path as a live option here without the underlying occupancy fact that makes it work.
- **Genuine savings still applies**, same as the base foreign-buyer doc — a lump-sum transfer from Vietnam can still fail the ~5%-held-3-months convention if not structured to qualify in time.

## Relevance for Vietnam-located investors (Mode D)

- **Plan on 30–40%, same as a Mode-D buyer intending to occupy would.** Non-residency, not investment intent, sets the deposit floor.
- **Total cash-to-settle is larger than the deposit alone** — FIRB fee, foreign-buyer stamp-duty surcharge, entity setup cost (if applicable), QS report, and FX spread stack on top, each owned by its own anchor and assembled by `cash_position`.
- **Banded, broker confirms.** Informational; a licensed mortgage broker confirms the actual requirement (ACL line).

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver selects `minimum_required_percentage_non_resident_investment_loan` from the same 30–40% band as `kb.lender.foreign-buyer-deposit-requirements`, applies the no-FHB-schemes fact from `kb.investor.deposit-requirements-investment-loans`, and does not offer the AU-partner reduced-deposit path unless the profile independently supports an occupancy fact justifying it.

```jsonc
{
  "fills": [],
  "parameters": {
    "band_is_residency_driven_not_occupancy_driven": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the 30-40% non-resident deposit band (kb.lender.foreign-buyer-deposit-requirements) is keyed on residency/income currency, not on occupy-vs-invest intent — the same band applies to a non-resident investor." },
    "non_resident_investment_deposit_pct_low": { "type": "int", "value": 30, "provenance": "CONVENTION", "note": "same lower band as kb.lender.foreign-buyer-deposit-requirements, applied to the investment case." },
    "non_resident_investment_deposit_pct_high": { "type": "int", "value": 40, "provenance": "CONVENTION", "note": "same upper band; investment loans generally assessed more conservatively than owner-occupier on rate/serviceability, not on a distinct deposit floor." },
    "au_partner_reduced_deposit_path_not_applicable": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the 95% LVR joint-purchase-with-AU-partner path assumes occupancy on the AU co-borrower's footing; not surfaced for a Vietnam-located investor's co-ownership structure without that occupancy fact." },
    "no_fhb_schemes_for_non_resident_investor": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "no FHB scheme/concession applies — same fact as kb.investor.deposit-requirements-investment-loans, restated for the non-resident case." }
  }
}
```

Notes:

- **No `fills`.** A synthesis of two existing bands, not a new figure. `deposit_ready_for_purchase` remains resolver-computed by placing the band against the price and summing the sibling-owned acquisition costs.
- **Single-owner via cross-ref.** The base non-resident deposit band → `kb.lender.foreign-buyer-deposit-requirements`; the investment-specific no-FHB-schemes fact → `kb.investor.deposit-requirements-investment-loans`; investment-loan serviceability → `kb.lender.serviceability-investment-loans`.

## Sources

- Canstar — *Non-Resident Home Loans in Australia* (30–40% deposit / 60–70% LVR for foreign nationals; band keyed on residency/income currency) — https://www.canstar.com.au/home-loans/non-resident-home-loans/
- Odin Mortgage — *7 Australian Banks and Lenders That Finance Investment Properties for Non-Residents* (non-resident investment lending policy and deposit expectations, 2026) — https://www.odinmortgage.com/resources/7-australian-banks-and-lenders-that-finance-investment-properties-for-non-residents-what-each-one-requires-in-2026/
- ASIC Moneysmart — *Borrowing to invest* (investment-loan deposit and risk considerations) — https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
