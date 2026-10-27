---
slug: kb.lender.non-resident-friendly-shortlist
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://asic.gov.au/for-finance-professionals/credit-licensees/
    retrieved: 2026-10-11
    note: "ASIC — credit assistance / recommending a credit product requires an Australian Credit Licence. Grounds the ACL boundary (criteria + reasoning, user picks, no named recommendation)"
  - url: https://brighten.com.au/home-loans/non-resident/
    retrieved: 2026-10-27
    path: docs/sources/lenders/brighten-non-resident-home-loan.txt
    note: "Brighten's own page: non-resident loan \"Variable rate from 7.58 p.a.\", maximum LVR 80%, \"we accept over 24 income currencies, most notably: … United States of America and Vietnam\""
  - url: https://www.latrobefinancial.com.au/lending/international-borrower-loan/
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-loan.txt
    note: "La Trobe Financial's own page: Non-resident Loan \"Current Rate^: 8.14%\", maximum LVR 75%, FIRB approval"
  - url: https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-term-sheet.txt
    note: "La Trobe Financial term sheet: \"90% of foreign income used for serviceability calculation\"; \"Non-Resident Premium 1.00% of the loan amount.\" (a fee, not a rate loading)"
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
    note: "Macquarie Credit Guidelines v15.0 2B: a sole temporary resident, or any applicant without a current Australian residential address, is \"Outside guidelines.\""
  - url: https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
    retrieved: 2026-10-27
    path: docs/sources/lenders/nab-fixed-rate-home-loan.txt
    note: "NAB: not available to applicants who reside overseas or who require FIRB approval"
  - url: https://www.stgeorge.com.au/personal/home-loans/apply/checklist
    retrieved: 2026-10-27
    path: docs/sources/lenders/stgeorge-home-loan-checklist.txt
    note: "St.George: \"residential lending is not available for Non-Australian resident borrowers\""
  - url: https://www.hsbc.com.au/content/dam/hsbc/au/docs/help/changes-to-hsbc-australia-faqs.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/hsbc-changes-to-hsbc-australia-faqs.txt
    note: "HSBC Australia: \"We are no longer accepting new applications for HSBC retail products in Australia.\""
---

# Non-resident-friendly lender shortlist — selection criteria

When a foreign person or temporary resident needs financing, lenders differ sharply in whether — and on what terms — they will lend. This doc owns the **criteria that make a lender "non-resident-friendly"** so `mortgage_finance` (component 5) can produce a **shortlist with reasoning** the user evaluates — it does **not** recommend or rank a lender. It lists, as facts drawn from each lender's own page, which lenders publish a non-resident loan and which say they do not (below, alphabetical); that list is information, not a recommendation. The agent applies these criteria to the buyer's situation and surfaces *which kinds of policy* fit (and why); the **user picks, with a licensed mortgage broker.** This is the Mode-B analogue of [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md) and, like it, the most ACL-sensitive doc in the finance cluster: naming a lender as "recommended" crosses from information into **credit advice** (ACL territory; personal liability). The boundary is built into the doc — criteria and reasoning, never a recommendation.

## What "non-resident-friendly" means — the criteria

A lender's fit for a foreign / temporary-resident borrower turns on a handful of policy levers, each owned in detail by a sibling doc:

- **Foreign-income acceptance and shading generosity** — whether the lender counts overseas income at all, the accepted-currency list (does it accept VND? Brighten's page lists Vietnam among "over 24 income currencies"), and how heavily it shades (La Trobe Financial's term sheet uses "90% of foreign income"). More generous → higher assessed capacity. (Owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md).)
- **Residency / visa appetite** — whether the lender writes non-resident loans, and its treatment of the specific visa class (e.g. the favourable 485-with-AU-income branch). (Owned by [`kb.lender.485-visa-treatment`](485-visa-treatment.md), [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md).)
- **Deposit / LVR appetite** — the maximum LVR offered to the borrower's profile (75–80% non-resident at the lenders that publish one; 95% at Macquarie only for an AU citizen/PR with a non-resident spouse who is not the main servicer). (Owned by [`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md).)
- **FIRB-conditional handling** — whether the lender will issue a loan offer conditional on FIRB approval and settle only after it. (Owned by [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).)
- **Documentation capability for non-residents** — whether the lender can process overseas-sourced income, identity and source-of-funds evidence, and its processing time. (Owned by [`kb.lender.documentation-non-resident`](documentation-non-resident.md).)
- **Rate and fees** — the lender's published non-resident rate and fees (La Trobe Financial's Non-resident Loan from 8.14%, plus a "Non-Resident Premium" fee of 1.00% of the loan amount; Brighten's non-resident loan from 7.58%) — one input among several, never the only one. No lender's own page states a premium over a domestic rate, so the plan's 50–150 bp premium is a `PLACEHOLDER` (below).

## Which lenders publish a non-resident policy — facts from their own pages

Alphabetical; not a ranking and not a recommendation. Each line is what the lender's own page says, on the date checked; policies change, and a broker confirms what applies.

- **Brighten** — lends to "Australian Temporary Residents or Non Residents", owner-occupied or investment, maximum LVR 80%, principal and interest or interest only up to 5 years; accepts over 24 income currencies including Vietnam.
- **HSBC Australia** — "no longer accepting new applications for HSBC retail products in Australia" (31 July 2026).
- **La Trobe Financial** — Non-resident Loan for "International borrowers looking to invest in Australian real estate" with FIRB approval; maximum LVR 75% (to $5,000,000); principal and interest only; counts 90% of foreign income; income documents translated by NAATI.
- **Macquarie** — a sole temporary resident, or applicants without a current Australian residential address, are "Outside guidelines".
- **NAB** — home loans "not available to applicants who reside overseas (regardless of citizenship) and/or for applicants who require … FIRB approval".
- **St.George** — "residential lending is not available for Non-Australian resident borrowers".

## How the shortlist is produced — and what it is not

The agent **matches the buyer's situation** (income currency, visa class, deposit, target property) **against these criteria** and surfaces a shortlist of *policy profiles that fit*, each with reasoning ("a lender that accepts AUD-only assessment for a 485 holder and issues FIRB-conditional offers suits this AU-employed temporary-resident buyer"). The shortlist is **decision-support**: it explains the trade-offs so the user — with a licensed broker — chooses. It is explicitly **not**:

- a recommendation of a named lender ("use Lender X");
- a ranking that implies one lender is best for the user;
- a substitute for a broker's whole-of-market assessment.

The plan always closes with "confirm with a licensed mortgage broker," and the figures driving the comparison (capacity, rates, deposit) are resolver-grounded, not asserted by the agent.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The income-currency profile shrinks the fitting set.** A VN-income buyer needs a lender that both accepts foreign income and accepts VND — a narrow subset; the criteria surface this so the buyer sees the financing consequence of the funding structure.
- **The 485-with-AU-income buyer has a much wider set.** Being assessed near-domestic changes which criteria bind; the shortlist reflects that.
- **A broker is the right channel.** The plan points to a broker for the actual selection from the small non-resident panel (whole-of-market, current policy), keeping the platform informational.
- **Information, not credit advice.** The shortlist is reasoning over policy criteria; the user picks (ACL line).

## Rules

Pure-reference (`fills: []`). This is a decision-support doc — it fills no slot; the agent produces the shortlist by reasoning over these criteria against the buyer's situation, and the policy flags below enforce the ACL boundary (criteria + reasoning, user picks, no named recommendation). The rate-premium band is a `PLACEHOLDER` (no lender's own page states a premium over a domestic rate); the boundary flags mirror [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md).

```jsonc
{
  "fills": [],
  "parameters": {
    "shortlist_is_decision_support": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the shortlist surfaces fitting policy profiles + reasoning; it is decision-support, NOT a recommendation." },
    "lender_shortlist_user_picks": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the user selects, with a licensed broker; the plan never selects a lender for the user." },
    "no_named_lender_recommendation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "ACL boundary — the app does not recommend a lender. The doc may list lenders as facts drawn from their own pages (alphabetical, no ranking), but never names one as 'recommended' or best for the user; that crosses into credit advice (ACL)." },
    "defer_lender_selection_to_broker": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "actual whole-of-market selection from the small non-resident panel is deferred to a licensed mortgage broker — the platform stays informational." },
    "non_resident_rate_premium_bp_low": { "type": "int", "value": 50, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no lender's own page states a non-resident premium over its domestic owner-occupier rate (La Trobe Financial publishes 8.14% non-resident vs 7.49% expatriate; Brighten 7.58% non-resident). Re-ground by comparing each of those lenders' non-resident rate with a domestic owner-occupier rate on the same lender's own page." },
    "non_resident_rate_premium_bp_high": { "type": "int", "value": 150, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — upper end; same re-ground as the low end. One input among several, never the only criterion." }
  },
  "lookup": {
    "non_resident_friendly_criteria": {
      "note": "the policy levers the agent reasons over to build a fitting-profile shortlist; each detail is owned by a sibling doc (cross-ref), not duplicated here.",
      "entries": [
        { "criterion": "foreign_income_acceptance_and_shading", "owner": "kb.lender.temp-resident-lending-policies" },
        { "criterion": "residency_visa_appetite", "owner": "kb.lender.485-visa-treatment" },
        { "criterion": "deposit_lvr_appetite", "owner": "kb.lender.foreign-buyer-deposit-requirements" },
        { "criterion": "firb_conditional_handling", "owner": "kb.lender.firb-approval-as-condition-precedent" },
        { "criterion": "documentation_capability_non_resident", "owner": "kb.lender.documentation-non-resident" },
        { "criterion": "rate_and_fees", "owner": "kb.lender.temp-resident-lending-policies" }
      ]
    },
    "line_details": {
      "note": "behavior 98: a foreign buyer's (Mode B, D) loan lines — the repayments and the payout at sale — are priced at the representative rate plus the non-resident premium band above, so their details name that premium; the engine fills {params} with the figures it computed (fh_engine_line_detail).",
      "entries": [
        {
          "id": "loan_repayments",
          "tier": "PLACEHOLDER",
          "how": {
            "vi": "Trả cả gốc và lãi cho khoản vay {principal} (giá nhà trừ tiền đặt cọc) trong {term} năm, lãi suất {rate}%/năm — lãi suất tham khảo cộng một khoản chênh tạm tính cho người không cư trú (0,5–1,5%, chưa có bên cho vay nào công bố), không phải lãi suất khoản vay của bạn.",
            "en": "Principal and interest on a loan of {principal} (the price less your deposit) over {term} years at {rate}% a year — a typical rate plus a provisional non-resident premium (0.5–1.5%, which no lender publishes), not your loan's rate."
          },
          "payer": {
            "vi": "Bạn trả cho ngân hàng, thường hằng tháng.",
            "en": "You, to your lender, usually monthly."
          },
          "drivers": {
            "vi": "Lãi suất ngân hàng cho bạn (ít ngân hàng cho người không cư trú vay, nên chênh lệch lớn), số tiền vay và thời hạn vay.",
            "en": "The rate your lender gives you (few lenders take non-residents, so rates vary widely), the loan size and the term."
          },
          "note": {
            "vi": "Ước tính theo lãi suất tham khảo — đề nghị cho vay của ngân hàng mới quyết định.",
            "en": "An estimate at a typical rate — your loan offer decides."
          }
        },
        {
          "id": "loan_payout",
          "tier": "PLACEHOLDER",
          "how": {
            "vi": "Phần còn lại của khoản vay {principal} sau {years} năm trả góp (thời hạn {term} năm, lãi suất {rate}%/năm, gồm phần chênh tạm tính cho người không cư trú) — được trả từ tiền bán nhà.",
            "en": "What is left of a {principal} loan after {years} years of repayments ({term}-year term at {rate}% a year, a provisional non-resident premium included) — repaid from the sale."
          },
          "payer": {
            "vi": "Trả cho ngân hàng từ tiền bán nhà khi hoàn tất việc bán.",
            "en": "Paid to your lender from the sale money at settlement."
          },
          "drivers": {
            "vi": "Số tiền vay, lãi suất qua các năm, và việc trả thêm: trả thêm sớm thì còn nợ ít hơn.",
            "en": "The loan size, the rate over the years, and extra repayments: paying more early leaves less to repay."
          },
          "note": {
            "vi": "Ước tính theo lãi suất tham khảo — đề nghị cho vay của ngân hàng mới quyết định.",
            "en": "An estimate at a typical rate — your loan offer decides."
          }
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`, no recommended lender.** The doc owns the *criteria* the agent reasons over. It names lenders only as facts from their own pages (alphabetical, no ranking); it never recommends one. The shortlist is produced at runtime as fitting *policy profiles* + reasoning, and the user picks.
- **Rate premium is a placeholder.** The 50–150 bp band prices Mode B/D loan lines but no lender publishes it; the line details say so (tier `PLACEHOLDER`).
- **ACL boundary as data.** The four policy flags make the boundary machine-checkable (decision-support, user-picks, no-named-recommendation, defer-to-broker) — the Mode-B mirror of [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md).
- **Criteria reference siblings, not duplicate.** Each criterion's detail is owned by the sibling doc named in the lookup; this doc is the *selection-criteria* layer that composes them.

## Sources

- ASIC — *Credit and finance: Australian credit licence* (credit assistance / recommendation requires an ACL) — https://asic.gov.au/for-finance-professionals/credit-licensees/
- ASIC Moneysmart — *Using a mortgage broker* (broker role; credit assistance is a licensed activity) — https://moneysmart.gov.au/home-loans/using-a-mortgage-broker
- Brighten — *Non-Resident Home Loans* (rate from 7.58%, maximum LVR 80%, income currencies incl. Vietnam) — https://brighten.com.au/home-loans/non-resident/
- La Trobe Financial — *International Borrower* (Non-resident Loan rate 8.14%, maximum LVR 75%) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
- La Trobe Financial — *International Borrower term sheet* (90% of foreign income; Non-Resident Premium fee 1.00%) — https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
- Macquarie — *Residential Home Loans Credit Guidelines* v15.0 (2B Residency Matrix) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
- NAB — *Fixed rate home loan* (not available to overseas residents or FIRB applicants) — https://www.nab.com.au/personal/home-loans/nab-fixed-rate-home-loan
- St.George — *Home loan application checklist* (no residential lending to non-Australian residents) — https://www.stgeorge.com.au/personal/home-loans/apply/checklist
- HSBC Australia — *Changes to HSBC Australia FAQs* (no new retail applications) — https://www.hsbc.com.au/content/dam/hsbc/au/docs/help/changes-to-hsbc-australia-faqs.pdf
