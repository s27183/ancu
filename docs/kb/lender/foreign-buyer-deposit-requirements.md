---
slug: kb.lender.foreign-buyer-deposit-requirements
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://brighten.com.au/home-loans/non-resident/
    retrieved: 2026-10-27
    path: docs/sources/lenders/brighten-non-resident-home-loan.txt
    note: "Brighten's own non-resident product page: \"Suitable borrowers: Australian Temporary Residents or Non Residents\"; \"Maximum LVR 80%\"; \"Owner occupied or investment property\""
  - url: https://www.latrobefinancial.com.au/lending/international-borrower-loan/
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-loan.txt
    note: "La Trobe Financial's own International Borrower page, Non-resident Loan: \"Maximum Loan Amount: $5,000,000 (75% LVR) Maximum LVR: 75%\""
  - url: https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-term-sheet.txt
    note: "La Trobe Financial's International Borrower term sheet (broker document), Non-Resident Loan Maximum LVR: \"75% up to $5,000,000\", \"70% up to $25,000,000\""
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
    note: "Macquarie Residential Home Loans Credit Guidelines v15.0, 2B Residency Matrix: a sole temporary resident is \"Outside guidelines.\"; an AU citizen/PR with \"a spousal co-applicant who is a non-Australian citizen/non-permanent resident … who is not the predominant servicer of the loan\" (all applicants holding a current Australian residential address): \"Standard loan parameters apply.\"; owner occupied \"95% LVR\""
  - url: https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
    retrieved: 2026-10-27
    path: docs/sources/lenders/nab-fixed-rate-home-loan.txt
    note: "NAB: home loan products \"are not available to applicants who reside overseas (regardless of citizenship) and/or for applicants who require Foreign Investment Review Board (FIRB) approval\""
  - url: https://www.stgeorge.com.au/personal/home-loans/apply/checklist
    retrieved: 2026-10-27
    path: docs/sources/lenders/stgeorge-home-loan-checklist.txt
    note: "St.George: \"residential lending is not available for Non-Australian resident borrowers\""
  - url: https://www.hsbc.com.au/content/dam/hsbc/au/docs/help/changes-to-hsbc-australia-faqs.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/hsbc-changes-to-hsbc-australia-faqs.txt
    note: "HSBC Australia (31 July 2026): \"We are no longer accepting new applications for HSBC retail products in Australia.\""
---

# Deposit requirements for foreign buyers and temporary residents

This doc owns the **deposit / LVR bands** a foreign person or temporary resident faces — the size of the cash contribution the lender requires, which for a foreign-income borrower is at least the domestic 20% and, at the lenders that publish a non-resident policy, a 20–25% floor. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically `deposit_requirements.minimum_required_percentage_typical` and the derived `minimum_required_amount` / `recommended_amount`. The **serviceability framework** that also gates the loan is owned by [`kb.lender.serviceability-basics`](serviceability-basics.md) and the foreign-axis deltas by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); this doc owns only the **deposit floor**.

Every band is **lender policy** (tier `LENDER-POLICY`), built only from the lenders' own published pages and named below; a figure no lender's page supports is a `PLACEHOLDER` naming the page to re-ground on. All are surfaced as bands and deferred to a licensed broker (ASIC line: information, no credit advice).

## The deposit bands, by income/residency profile

The deposit turns on the same AU-income-vs-foreign-income axis as the serviceability delta:

- **Foreign person earning foreign income (non-resident)** — a **20–25% deposit** at the lenders whose own pages publish a non-resident loan: **Brighten** lends to "Australian Temporary Residents or Non Residents" at a "Maximum LVR 80%" (20% deposit); **La Trobe Financial**'s Non-resident Loan has a "Maximum LVR: 75%" up to $5,000,000 (25% deposit), falling to 70% up to $25,000,000 on its term sheet. This is the load-bearing figure for the Vietnam-parent-funded / VN-income buyer; the plan uses the 25% end, which clears both lenders, and says the lender sets it.
- **The pool is small and mostly non-bank.** Several banks say on their own pages that they do not lend here: NAB's home loans "are not available to applicants who reside overseas … and/or for applicants who require Foreign Investment Review Board (FIRB) approval"; St.George says "residential lending is not available for Non-Australian resident borrowers"; Macquarie's credit guidelines put a sole temporary resident "Outside guidelines"; HSBC Australia is "no longer accepting new applications" for retail products.
- **Temporary resident earning AUD in Australia** — Brighten's 80% maximum LVR covers temporary residents; no other lender page read for this doc publishes a temporary-resident LVR, so the 20% figure is a `PLACEHOLDER` to re-ground on more lenders' own pages (LMI availability for a foreign person is itself restricted — [`kb.lmi.calculation-for-foreign-persons`](../lmi/calculation-for-foreign-persons.md)).
- **Buying with an Australian citizen / PR partner** — Macquarie's guidelines apply "Standard loan parameters" (owner-occupied up to 95% LVR) to an Australian citizen / PR borrowing with a non-resident spouse only when the spouse "is not the predominant servicer of the loan" and every applicant holds a current Australian residential address; otherwise it is "Outside guidelines". One lender's conditional policy, so the 5% figure is a `PLACEHOLDER` (FIRB treatment of the joint purchase — [`kb.firb.status-determination`](../firb/status-determination.md), [`kb.lender.485-visa-treatment`](485-visa-treatment.md)).

## Deposit is separate from the other cash-at-settlement costs

The deposit is **not** the whole cash requirement. A foreign buyer also funds the FIRB application fee, the foreign-buyer stamp-duty surcharge, ordinary duty, and FX spread on moving the funds — all owned by the `cash_position` component and its anchors ([`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md), `kb.foreign-buyer-surcharge.by-state`, `kb.fx.typical-spreads-vnd-aud`). This doc owns the **loan deposit only**; the total cash-to-settle is assembled downstream, so the deposit figure here must not be presented as the buyer's total outlay.

## Genuine savings still applies

The **genuine-savings** convention from [`kb.lender.serviceability-basics`](serviceability-basics.md) (typically ~5% of price held ≥3 months) applies to a foreign-person loan the same way — and a **lump-sum gift from an overseas parent may fail it**, which for the Vietnam-parent-funded buyer is a common trap. The larger non-resident deposit does not remove the genuine-savings expectation on the portion the lender requires as saved funds; surface it early so the funding is structured to qualify.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver selects the deposit band from the profile's income/residency profile and computes the dollar `minimum_required_amount` / `recommended_amount` against the target price; this doc supplies the grounded bands. No leaf asserted; dollar figures are resolver-computed.

```jsonc
{
  "fills": [],
  "parameters": {
    "non_resident_deposit_pct_typical": { "type": "int", "value": 25, "provenance": "LENDER-POLICY", "note": "the deposit that clears both lenders' own published non-resident maxima: La Trobe Financial 75% max LVR (Non-resident Loan, up to $5m), Brighten 80% max LVR (temporary residents or non-residents). The plan's base estimate is the higher end of the 20–25% band so it does not under-state the cash a buyer needs; the lender sets it." },
    "non_resident_deposit_pct_upper": { "type": "int", "value": 25, "provenance": "LENDER-POLICY", "note": "La Trobe Financial Non-resident Loan: 75% max LVR up to $5,000,000 (70% up to $25,000,000 on its term sheet)." },
    "non_resident_lvr_cap_pct": { "type": "int", "value": 80, "provenance": "LENDER-POLICY", "note": "the highest non-resident LVR a lender's own page publishes (Brighten 80%; La Trobe 75%); the deposit floor is the complement." },
    "temp_resident_au_income_deposit_pct_typical": { "type": "int", "value": 20, "provenance": "PLACEHOLDER", "note": "only Brighten's page publishes a temporary-resident LVR (80%); Macquarie's 2B Residency Matrix puts a sole temporary resident outside guidelines. Re-ground on further lenders' own temporary-resident policy pages before treating as a band." },
    "with_au_partner_min_deposit_pct": { "type": "int", "value": 5, "provenance": "PLACEHOLDER", "note": "Macquarie Credit Guidelines v15.0 2B only: an AU citizen/PR with a non-resident spouse who is not the predominant servicer, all applicants holding a current Australian address, gets standard parameters (owner occupied 95% LVR); otherwise outside guidelines. One lender, conditional — re-ground on other lenders' residency policies." },
    "deposit_is_not_total_cash_to_settle": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "FIRB fee, foreign-buyer surcharge, ordinary duty and FX spread are additional and owned by cash_position anchors; do not present the deposit as total outlay." },
    "genuine_savings_still_applies": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the ~5%-held-3-months genuine-savings rule (kb.lender.serviceability-basics) applies; a lump-sum overseas parental gift may fail it." }
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
            "vi": "{pct}% của {price} — mức đặt cọc đủ cho cả hai bên cho vay công bố chính sách cho người không cư trú (La Trobe Financial cho vay tối đa 75% giá nhà, Brighten tối đa 80%).",
            "en": "{pct}% of {price} — a deposit that meets both lenders that publish a non-resident policy (La Trobe Financial lends up to 75% of the price, Brighten up to 80%)."
          },
          "payer": {
            "vi": "Bạn và người thân góp tiền mua nhà, trả khi ký hợp đồng; khoản này được giữ trong tài khoản ủy thác (trust) đến ngày settlement.",
            "en": "You and any family funding the purchase, paid when you sign the contract and held in trust until settlement."
          },
          "drivers": {
            "vi": "Bên cho vay bạn chọn và khoản vay: La Trobe Financial yêu cầu 25% (30% khi vay trên 5 triệu đô); mua chung với vợ/chồng là công dân hay thường trú nhân Úc có thể giảm mức này ở một số bên cho vay.",
            "en": "The lender you choose and the loan size: La Trobe Financial asks 25% (30% above $5 million); buying with a partner who is an Australian citizen or permanent resident can lower it at some lenders."
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

- **Single-owner.** Deposit / LVR bands only. Serviceability core → [`kb.lender.serviceability-basics`](serviceability-basics.md); foreign-axis deltas → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); LMI-for-foreign-persons → [`kb.lmi.calculation-for-foreign-persons`](../lmi/calculation-for-foreign-persons.md); the non-deposit cash-to-settle costs → the `cash_position` anchors.
- **Lender policy, not regulated.** Deposit floors are lender policy (`LENDER-POLICY`), each band naming the lenders whose own pages state it (Brighten, La Trobe Financial); the temporary-resident and AU-partner figures rest on one lender each and are `PLACEHOLDER`. Presented as bands, deferred to a broker.
- **Lenders named as facts, not recommendations.** The lenders are named because their own pages are the primaries for the band; naming them is not a recommendation (the shortlist boundary — [`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)).
- **Don't double-count.** The deposit is one line of the cash-to-settle assembled in `cash_position`; this doc owns the loan deposit, not the total.

## Sources

- Brighten — *Non-Resident Home Loans* (temporary residents or non-residents; owner occupied or investment; maximum LVR 80%) — https://brighten.com.au/home-loans/non-resident/
- La Trobe Financial — *International Borrower* (Non-resident Loan: maximum LVR 75%, $5,000,000 at 75% LVR) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
- La Trobe Financial — *International Borrower term sheet* (Non-Resident Loan: 75% up to $5,000,000, 70% up to $25,000,000) — https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
- Macquarie — *Residential Home Loans Credit Guidelines* v15.0 (2B Residency Matrix; owner occupied 95% LVR) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
- NAB — *Fixed rate home loan* (home loans not available to overseas residents or FIRB applicants) — https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
- St.George — *Home loan application checklist* (no residential lending to non-Australian residents) — https://www.stgeorge.com.au/personal/home-loans/apply/checklist
- HSBC Australia — *Changes to HSBC Australia FAQs* (no new retail applications) — https://www.hsbc.com.au/content/dam/hsbc/au/docs/help/changes-to-hsbc-australia-faqs.pdf
- ASIC Moneysmart — *How much you can borrow* (deposit, LVR, genuine savings) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
