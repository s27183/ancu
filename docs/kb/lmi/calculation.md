---
slug: kb.lmi.calculation
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.qbe.com/lmi
    retrieved: 2026-07-06
    path: docs/sources/qbe_lmi/qbe-lmi-guide.pdf
  - url: https://www.helia.com.au/the-hub/calculators-estimators/lmi-fee-estimator
    retrieved: 2026-10-27
    path: docs/sources/lmi/helia-lmi-fee-estimator.txt
    note: "Helia's own LMI fee estimator page: \"LMI can either be paid upfront or capitalised into the loan.\"; results are the \"Upfront LMI premium (including GST) excluding stamp duty\"; \"the actual premium is the premium calculated by Helia at the time of application for LMI\"; \"The results from this premium estimator should be used as an indication only.\" The archive holds the form, not a rate table — the band figures are PLACEHOLDER until the estimator's outputs are archived."
  - url: https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi
    retrieved: 2026-10-27
    path: docs/sources/lmi/moneysmart-glossary-lmi.txt
    note: "ASIC Moneysmart: LMI \"is usually a one-off cost to a home loan borrower, payable when the amount borrowed exceeds 80% of the value of the property. LMI does not benefit the borrower, it only protects the lender.\""
  - url: https://qro.qld.gov.au/duties/insurance-duty/rates/
    retrieved: 2026-10-27
    path: docs/sources/qld/qro-insurance-duty-rates.txt
    note: "Queensland Revenue Office: \"The insurance duty rate for both class 1 and class 2 general insurance is 9% of the premium paid (including GST).\""
---

# Lenders Mortgage Insurance — how the premium is calculated

**Lenders Mortgage Insurance (LMI)** is a one-off premium a borrower pays when borrowing **above 80% of the property value** (LVR > 80%). It insures the **lender** (not the borrower) against loss if the loan defaults — the borrower pays it but gets no cover. It is the cost the 5%-deposit FHB faces *unless* a guarantee or waiver removes it, which is why it sits at the centre of `mortgage_finance`'s [FHG-backed vs LMI-payable path comparison](../scheme/fhg.md) and is a line in `cash_position`'s settlement total. This doc owns **how the premium is sized and structured**; the insurer landscape and the ways to avoid it live in [`kb.lmi.providers`](providers.md).

## When it applies

- **The 80% LVR threshold.** ASIC's Moneysmart: LMI is "payable when the amount borrowed exceeds 80% of the value of the property". At or below 80% LVR (a 20%+ deposit), no LMI. The premium **rises steeply as LVR rises** through the 85% / 90% / 95% bands — a 95% loan costs far more to insure than an 85% one.
- **It scales with two things: LVR *and* loan size.** A higher LVR and a larger loan each push the premium up; the two combine in the insurer's rate table.

## How it is sized

LMI is priced from the insurer's **rate table** — a matrix of (LVR band × loan-amount band) → premium rate, applied as a percentage of the loan amount. The tables are **proprietary to each insurer** ([Helia, QBE, Arch](providers.md)) and not publicly published in full — QBE's guide tells the lender to contact QBE LMI for rates, and Helia's estimator says "the actual premium is the premium calculated by Helia at the time of application for LMI". So a precise premium is only known at application.

The engine still needs an order of magnitude for a base-scope estimate, so it carries the band table below. **No primary in this doc's archive states these figures** — they are a `PLACEHOLDER`, to be re-grounded on Helia's own LMI fee estimator (its upfront premium, including GST, excluding stamp duty, at a ≈$500k loan for each LVR band) once those outputs are archived:

| Placeholder band (≈$500k loan) | Placeholder premium rate |
|---|---|
| 81–85% LVR | ~0.5–1.0% of loan |
| 86–90% LVR | ~1.5–2.0% of loan |
| 91–95% LVR | ~2.5–4.0% of loan |

The binding figure is always the insurer's quote at application.

## What the borrower actually pays — and gets back

- **GST + state insurance duty on top.** Helia's estimator quotes the premium "(including GST)" and "excluding stamp duty"; QBE's guide (§11) says stamp duty is payable on LMI premiums and varies by state or territory. In Queensland, "The insurance duty rate for both class 1 and class 2 general insurance is 9% of the premium paid (including GST)" (Queensland Revenue Office). So the borrower's all-in LMI cost is **higher than the base premium** — the duty component varies by state.
- **Minimum premium.** Insurers set a floor, so even a small or low-LVR loan incurs at least the minimum — **QBE's is $1,150 incl GST (excluding state duty)**.
- **Capitalisation.** Helia: "LMI can either be paid upfront or capitalised into the loan." It can be **paid upfront at settlement** or **capitalised** (added to the loan and repaid with interest over the term). Capitalising preserves settlement cash but adds the premium to the debt and the interest on it. Per QBE's guide, capitalising adds **no extra premium cost**, and the cap is expressed as LVR: **max 95% LVR excluding the premium, 100% including the capitalised premium** — i.e. the premium itself can take the loan to 100% but no further.
- **Partial refund.** If the loan is **repaid/discharged within a limited window after settlement**, the insurer may refund part of the premium, on request. QBE's published window is **≤12 months** (loan repaid in full, QBE notified within 30 days, refund ≥$500), and it depends on "arrangements between QBE LMI and Lenders" — a refund is not universal; other insurers' and lenders' terms differ — confirm per insurer. Relevant to `ownership_planning`'s refinance/graduation timing.

## Relevance for Vietnamese-Australian buyers (Mode A)

- For the typical 5%-deposit Mode A FHB, LMI would be **thousands of dollars or more** (the placeholder 91–95% band applied to the loan) — which is exactly what an [FHG](../scheme/fhg.md)-backed loan **avoids** (the government guarantee stands in for LMI). The size of that avoided premium is `eligibility.fhg.lmi_savings_estimate` and a primary reason the FHG path usually wins for an eligible buyer.
- Where FHG is unavailable (e.g. a place not used, or non-qualifying property), the LMI-payable path is the fallback — and **capitalising** the premium is usually how a deposit-constrained buyer absorbs it. Surface the trade-off (cash preserved vs interest paid), as information.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference / formula-in-code doc** — it fills no slot. The precise premium is the **insurer's rate table at application**; the base-scope estimate is **resolver/agent-computed** from these parameters and the indicative band table (the same "computed, not asserted" discipline as stamp duty). The doc supplies the structure (80% threshold, scaling, capitalisation, duty, refund) and placeholder coefficients only (the band figures await re-grounding on Helia's estimator).

```jsonc
{
  "fills": [],
  "parameters": {
    "lvr_threshold_pct":            { "type": "percentage", "value": 80,   "provenance": "REGULATED", "note": "ASIC Moneysmart glossary: LMI is \"payable when the amount borrowed exceeds 80% of the value of the property\"; at/under 80% none — the universal trigger" },
    "premium_is_one_off":           { "type": "bool",       "value": true, "provenance": "REGULATED", "note": "ASIC Moneysmart glossary: LMI \"is usually a one-off cost to a home loan borrower\"" },
    "premium_scales_with":          { "type": "array<string>", "value": ["lvr_band", "loan_amount"], "note": "rises with both LVR and loan size; combined in the insurer's rate table" },
    "indicative_premium_pct_of_loan_low":  { "type": "percentage", "value": 0.5, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no primary states this; re-ground on Helia's LMI fee estimator (https://www.helia.com.au/the-hub/calculators-estimators/lmi-fee-estimator), upfront premium incl GST excl stamp duty at ~81% LVR. Low end only; actual = insurer rate table at application." },
    "indicative_premium_pct_of_loan_high": { "type": "percentage", "value": 5.0, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no primary states this; re-ground on Helia's LMI fee estimator at 95% LVR and a large loan. High end only; actual = insurer rate table." },
    "capitalisable":                { "type": "bool",       "value": true, "provenance": "LENDER-POLICY", "note": "may be added to the loan (then interest-bearing); Helia estimator: \"LMI can either be paid upfront or capitalised into the loan\"; QBE LMI Guide §8: no extra premium to capitalise, max 95% LVR excl premium / 100% incl capitalised premium" },
    "min_premium_aud_qbe":          { "type": "money",      "value": 1150, "provenance": "LENDER-POLICY", "note": "QBE LMI Guide, Apr 2026 (the insurer's own guide) — minimum premium $1,150 incl GST, excl state duty; insurer-specific floor, QBE cited as a published example" },
    "attracts_gst_and_state_duty":  { "type": "bool",       "value": true, "provenance": "REGULATED", "note": "premium attracts GST + state insurance/stamp duty — QLD 9% of the premium paid including GST (Queensland Revenue Office, insurance duty rates); duty varies by state (QBE LMI Guide §11); Helia's estimator quotes premiums incl GST, excl stamp duty" },
    "partial_refund_window_months": { "type": "integer",    "value": 12,   "provenance": "LENDER-POLICY", "note": "QBE LMI Guide §9 (the insurer's own guide): partial refund only if loan discharged ≤12 months after settlement, repaid in full, QBE notified within 30 days, refund ≥$500, and subject to arrangements between QBE LMI and the lender. Window/scale is insurer-specific; confirm per insurer" }
  },
  "lookup": {
    "line_details": {
      "note": "one entry per statement line this doc's figure is placed on (not a fee line); the engine attaches it as the line's detail, filling {params} with the figures it computed (fh_engine_line_detail, behavior 93; the lmi line, behavior 101)",
      "entries": [
        {
          "id": "lmi",
          "tier": "PLACEHOLDER",
          "how": {
            "vi": "Khoảng {lo}–{hi}% của khoản vay {loan}, vì bạn vay {lvr}% giá nhà (trên 80%) — biểu phí tham khảo của bảo hiểm khoản vay (LMI); công ty bảo hiểm của ngân hàng sẽ báo phí chính xác.",
            "en": "About {lo}–{hi}% of your {loan} loan, because you borrow {lvr}% of the price (above 80%) — the indicative lenders mortgage insurance (LMI) band; your lender's insurer quotes the exact premium."
          },
          "payer": {
            "vi": "Bạn trả một lần khi settlement; thường có thể cộng vào khoản vay.",
            "en": "You pay it once, at settlement; it can usually be added to the loan."
          },
          "drivers": {
            "vi": "Đặt cọc nhiều hơn: từ 20% giá nhà trở lên thì không còn LMI; chương trình Đặt cọc 5% (First Home Guarantee) cũng miễn LMI.",
            "en": "A larger deposit: from 20% of the price there is no LMI; the 5% Deposit Scheme (First Home Guarantee) also waives it."
          },
          "source": 0
        }
      ]
    },
    "indicative_premium_by_lvr_band": {
      "note": "PLACEHOLDER — no primary states these rates; re-ground on Helia's LMI fee estimator (https://www.helia.com.au/the-hub/calculators-estimators/lmi-fee-estimator), upfront premium incl GST excl stamp duty at ~$500k loan per LVR band, archived. For a base-scope estimate ONLY; the binding premium is the insurer's proprietary (LVR × loan-size) rate table at application — resolver produces an estimate, not an assertion",
      "entries": [
        { "lvr_band": "81-85", "indicative_rate_pct_of_loan_low": 0.5, "indicative_rate_pct_of_loan_high": 1.0 },
        { "lvr_band": "86-90", "indicative_rate_pct_of_loan_low": 1.5, "indicative_rate_pct_of_loan_high": 2.0 },
        { "lvr_band": "91-95", "indicative_rate_pct_of_loan_low": 2.5, "indicative_rate_pct_of_loan_high": 4.0 }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `eligibility.fhg.lmi_savings_estimate`, `mortgage_finance.loan_path_comparison.*.lmi_payable_estimate`, and the `cash_position` LMI line are all **resolver/agent estimates** from these parameters — the actual premium comes from the insurer at application. The doc grounds the estimate; it does not assert the premium.
- **The lookup is a PLACEHOLDER, deliberately.** Its figures came from a comparison site (removed under behavior 138) and are kept only because the engine reads them; Helia's own estimator is the primary to re-ground them on. Real LMI is a proprietary 2D matrix (LVR band × loan-amount band) that insurers don't publish in full. Encoding a precise table would assert figures we cannot verify and that drift per insurer. The band table is an order-of-magnitude estimator for the **base-scope** number; the **per-property** figure is the quote. Same honesty as recording HEM as a basis, not a number, in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md).
- **State duty is named but not tabled here.** The GST + state-insurance-duty uplift varies by state; only QLD's 9% (Queensland Revenue Office) is cited as an example. If a precise per-state LMI-duty calculation is ever needed it composes with [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md)'s per-state logic rather than duplicating a duty table here (single-owner discipline).
- **The 80% threshold is a `parameter`, not a `criteria`.** Whether a given purchase exceeds 80% LVR is control flow over price + deposit — resolver code per §11.9, consuming this number; the doc supplies the threshold, not a declarative predicate.

## Sources

- QBE — *LMI Guide* (April 2026) — primary (insurer's own underwriting guide): minimum premium **$1,150 incl GST**; capitalisation to **100% LVR incl premium / 95% excl** at no extra premium cost; stamp duty payable on the premium, varies by state (§11); partial refund only if discharged **≤12 months** after settlement (§9); premium **rates are not published** — "Lender should contact QBE LMI" (§6), confirming the matrix is proprietary. (primary: `docs/sources/qbe_lmi/qbe-lmi-guide.pdf`)
- ASIC Moneysmart — *lenders mortgage insurance (LMI)* glossary (usually a one-off cost; payable above 80% of the property's value; protects the lender only) — https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi (archived: `docs/sources/lmi/moneysmart-glossary-lmi.txt`)
- Helia — *LMI fee estimator* (the insurer's own premium estimator: upfront or capitalised; premium incl GST, excl stamp duty; indication only, the actual premium is Helia's at application) — https://www.helia.com.au/the-hub/calculators-estimators/lmi-fee-estimator (archived: `docs/sources/lmi/helia-lmi-fee-estimator.txt`; the archive holds the form, not its outputs)
- Queensland Revenue Office — *Insurance duty rates* (9% of the premium paid, including GST) — https://qro.qld.gov.au/duties/insurance-duty/rates/ (archived: `docs/sources/qld/qro-insurance-duty-rates.txt`)

> The exact premium rate matrix is **proprietary** to each LMI insurer (Helia/QBE/Arch do not publish their full rate tables) — the QBE LMI Guide §6 confirms this directly ("Lender should contact QBE LMI" for rates), so premium **percentages** are a **PLACEHOLDER** until Helia's estimator outputs are archived; the structural figures above (min premium, capitalisation LVR caps, refund window, stamp-duty-on-premium) are now anchored to the QBE primary. See [`kb.lmi.providers`](providers.md) for the insurer landscape.
