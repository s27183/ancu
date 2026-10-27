---
slug: kb.non-resident.investment-loan-deposit-requirements
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://brighten.com.au/home-loans/non-resident/
    retrieved: 2026-10-27
    path: docs/sources/lenders/brighten-non-resident-home-loan.txt
    note: "Brighten's own page: \"Owner occupied or investment property\" under one \"Maximum LVR 80%\" for \"Australian Temporary Residents or Non Residents\""
  - url: https://www.latrobefinancial.com.au/lending/international-borrower-loan/
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-loan.txt
    note: "La Trobe Financial's own page: Non-resident Loan (to invest, with FIRB approval) \"Maximum Loan Amount: $5,000,000 (75% LVR) Maximum LVR: 75%\""
  - url: https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
    note: "POINTER (not re-fetched this session) — ASIC Moneysmart general borrowing-to-invest / investment-loan risk context (not a non-resident-specific figure)."
---

# Deposit requirements — non-resident investment loans

This doc owns the **synthesis** of two single-owned facts for the specific case a pure foreign-buyer doc and a pure domestic-investor doc don't individually state: what a **non-resident investor** (Vietnam-located, buying to let, not to occupy) needs as a deposit. It grounds `cash_position` (component 8) `deposit_requirements.minimum_required_percentage_non_resident_investment_loan`. It owns no new figure — it states which band applies and why the "with an AU partner" reduced-deposit path does not.

## The band is residency-driven, not occupancy-driven — so it's the same band

The **20–25% deposit / 75–80% maximum LVR** for a foreign person earning foreign income, owned by [`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md), is keyed on the borrower's **residency and income currency**, not on whether they intend to occupy or let the property. The two lenders whose own pages publish a non-resident loan show this: **Brighten** applies one "Maximum LVR 80%" to "Owner occupied or investment property"; **La Trobe Financial**'s Non-resident Loan is an investment loan ("looking to invest in Australian real estate") at a "Maximum LVR: 75%". A non-resident investor therefore faces the **same 20–25% band** as a non-resident buying to occupy — lenders differentiate the investment case by rate and serviceability treatment ([`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)), not by a separate deposit floor.

## What genuinely changes for the investment case

- **No first-home-buyer leniency.** [`kb.investor.deposit-requirements-investment-loans`](../investor/deposit-requirements-investment-loans.md)'s "no FHB schemes apply" fact (a scheme rule, grounded there on government pages — not a lender policy) holds for a non-resident investor exactly as it does for a domestic one — there was never an FHB path to begin with, but the plan should not imply otherwise.
- **The "buying with an AU citizen/PR partner" reduced-deposit path (down to 5%) does not apply the same way.** That path in the foreign-buyer-deposit doc assumes the purchase is assessed on the AU co-borrower's footing for what is, in substance, their home. A Vietnam-located investor's co-ownership structure (if any) is an investment decision, not a partner-occupancy one — the plan should not surface the 5%-deposit joint-purchase path as a live option here without the underlying occupancy fact that makes it work.
- **Genuine savings still applies**, same as the base foreign-buyer doc — a lump-sum transfer from Vietnam can still fail the ~5%-held-3-months convention if not structured to qualify in time.

## Relevance for Vietnam-located investors (Mode D)

- **Plan on 20–25%, same as a Mode-D buyer intending to occupy would.** Non-residency, not investment intent, sets the deposit floor.
- **Total cash-to-settle is larger than the deposit alone** — FIRB fee, foreign-buyer stamp-duty surcharge, entity setup cost (if applicable), QS report, and FX spread stack on top, each owned by its own anchor and assembled by `cash_position`.
- **Banded, broker confirms.** Informational; a licensed mortgage broker confirms the actual requirement (ACL line).

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver selects `minimum_required_percentage_non_resident_investment_loan` from the same 20–25% band as `kb.lender.foreign-buyer-deposit-requirements`, applies the no-FHB-schemes fact from `kb.investor.deposit-requirements-investment-loans`, and does not offer the AU-partner reduced-deposit path unless the profile independently supports an occupancy fact justifying it.

```jsonc
{
  "fills": [],
  "parameters": {
    "band_is_residency_driven_not_occupancy_driven": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "Brighten applies one 80% max LVR to owner-occupied or investment non-resident loans; La Trobe Financial's Non-resident Loan is investment-only at 75% — the band follows residency, not occupy-vs-invest intent." },
    "non_resident_investment_deposit_pct_low": { "type": "int", "value": 20, "provenance": "LENDER-POLICY", "note": "Brighten: non-resident, owner occupied or investment, maximum LVR 80% — the same low end as kb.lender.foreign-buyer-deposit-requirements." },
    "non_resident_investment_deposit_pct_high": { "type": "int", "value": 25, "provenance": "LENDER-POLICY", "note": "La Trobe Financial Non-resident Loan (investment): maximum LVR 75% up to $5,000,000; a distinct deposit floor for the investment case is not published." },
    "au_partner_reduced_deposit_path_not_applicable": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the 95% LVR joint-purchase-with-AU-partner path assumes occupancy on the AU co-borrower's footing; not surfaced for a Vietnam-located investor's co-ownership structure without that occupancy fact." },
    "no_fhb_schemes_for_non_resident_investor": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "no FHB scheme/concession applies — a scheme rule owned and grounded by kb.investor.deposit-requirements-investment-loans (government pages), restated for the non-resident case; not a lender policy." }
  },
  "lookup": {
    "line_details": {
      "note": "one entry per statement line this doc's figure is placed on (not a fee line); the engine attaches it as the line's detail, filling {params} with the figures it computed (fh_engine_line_detail, behavior 93)",
      "entries": [
        {
          "id": "deposit_chosen",
          "tier": "LENDER-POLICY",
          "how": {
            "vi": "{amount} — mức đặt cọc bạn chọn ({pct}% giá nhà), trả khi ký hợp đồng. Mức thấp nhất kế hoạch chấp nhận là {min_pct}%; bạn có thể đặt đến toàn bộ giá nhà (mua đứt, không vay).",
            "en": "{amount} — the deposit you chose ({pct}% of the price), paid when you sign the contract. The smallest this plan accepts is {min_pct}%; you can put down up to the whole price (buying outright, with no loan)."
          },
          "payer": {
            "vi": "Bạn trả từ tiền của mình; khoản này được giữ trong tài khoản ủy thác (trust) đến ngày settlement.",
            "en": "You, from your own money; it is held in trust until settlement."
          },
          "drivers": {
            "vi": "Đặt cọc nhiều hơn thì khoản vay nhỏ hơn và tiền lãi ít hơn; từ 20% giá nhà trở lên thì không phải trả bảo hiểm khoản vay (LMI).",
            "en": "A larger deposit means a smaller loan and less interest; from 20% of the price there is no lenders mortgage insurance (LMI)."
          },
          "note": {
            "vi": "Bạn đổi được con số này trong “Tài chính của bạn”.",
            "en": "You can change this in “Your finances”."
          },
          "source": 0
        },
        {
          "id": "deposit",
          "tier": "LENDER-POLICY",
          "how": {
            "vi": "{pct}% của {price} — mức giữa của khoảng {lo}–{hi}% mà các bên cho vay công bố chính sách cho người không cư trú yêu cầu khi vay để đầu tư (Brighten cho vay tối đa 80%, La Trobe Financial tối đa 75%).",
            "en": "{pct}% of {price} — the middle of the {lo}–{hi}% deposit the lenders that publish a non-resident policy ask for an investment loan (Brighten lends up to 80%, La Trobe Financial up to 75%)."
          },
          "payer": {
            "vi": "Bạn và người thân góp tiền mua nhà, trả khi ký hợp đồng; khoản này được giữ trong tài khoản ủy thác (trust) đến ngày settlement.",
            "en": "You and any family funding the purchase, paid when you sign the contract and held in trust until settlement."
          },
          "drivers": {
            "vi": "Bên cho vay bạn chọn và số tiền vay: La Trobe Financial yêu cầu 25% với khoản vay đến 5 triệu đô.",
            "en": "The lender you choose and the loan size: La Trobe Financial asks 25% on loans up to $5 million."
          },
          "note": {
            "vi": "Theo chính sách các bên cho vay tự công bố — bên cho vay bạn chọn sẽ quyết định.",
            "en": "From the lenders' own published policy — the lender you choose sets it."
          },
          "source": 0
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** A synthesis of two existing bands, not a new figure. The lenders are named because their own pages are the band's primaries, not as a recommendation. `deposit_ready_for_purchase` remains resolver-computed by placing the band against the price and summing the sibling-owned acquisition costs.
- **Single-owner via cross-ref.** The base non-resident deposit band → `kb.lender.foreign-buyer-deposit-requirements`; the investment-specific no-FHB-schemes fact → `kb.investor.deposit-requirements-investment-loans`; investment-loan serviceability → `kb.lender.serviceability-investment-loans`.

## Sources

- Brighten — *Non-Resident Home Loans* (owner occupied or investment; maximum LVR 80%) — https://brighten.com.au/home-loans/non-resident/
- La Trobe Financial — *International Borrower* (Non-resident Loan to invest; maximum LVR 75%) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
- ASIC Moneysmart — *Borrowing to invest* (investment-loan deposit and risk considerations) — https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
