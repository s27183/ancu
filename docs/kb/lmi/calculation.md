---
slug: kb.lmi.calculation
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.qbe.com/lmi
    retrieved: 2026-07-06
    path: docs/sources/qbe_lmi/qbe-lmi-guide.pdf
---

# Lenders Mortgage Insurance — how the premium is calculated

**Lenders Mortgage Insurance (LMI)** is a one-off premium a borrower pays when borrowing **above 80% of the property value** (LVR > 80%). It insures the **lender** (not the borrower) against loss if the loan defaults — the borrower pays it but gets no cover. It is the cost the 5%-deposit FHB faces *unless* a guarantee or waiver removes it, which is why it sits at the centre of `mortgage_finance`'s [FHG-backed vs LMI-payable path comparison](../scheme/fhg.md) and is a line in `cash_position`'s settlement total. This doc owns **how the premium is sized and structured**; the insurer landscape and the ways to avoid it live in [`kb.lmi.providers`](providers.md).

## When it applies

- **The 80% LVR threshold.** At or below 80% LVR (a 20%+ deposit), no LMI. Above 80%, almost every lender requires it. The premium **rises steeply as LVR rises** through the 85% / 90% / 95% bands — a 95% loan costs far more to insure than an 85% one.
- **It scales with two things: LVR *and* loan size.** A higher LVR and a larger loan each push the premium up; the two combine in the insurer's rate table.

## How it is sized

LMI is priced from the insurer's **rate table** — a matrix of (LVR band × loan-amount band) → premium rate, applied as a percentage of the loan amount. The tables are **proprietary to each insurer** ([Helia, QBE, Arch](providers.md)) and not publicly published in full, so a precise premium is only known at application. As an order of magnitude it runs **~0.5% to ~5% of the loan amount**, climbing with LVR:

| Indicative (≈$500k loan) | Indicative premium rate |
|---|---|
| 81–85% LVR | ~0.5–1.0% of loan |
| 86–90% LVR | ~1.5–2.0% of loan |
| 91–95% LVR | ~2.5–4.0% of loan |

Worked anchors (mainstream lender): a **$500k purchase at 90% LVR ≈ $8,190**; a **$400k loan at 90% LVR ≈ $5,840**. These are **indicative only** — the binding figure is the insurer's quote at application.

## What the borrower actually pays — and gets back

- **GST + state insurance duty on top.** The premium attracts **GST**, and the states levy **stamp/insurance duty** on the GST-inclusive premium (e.g. Queensland ~9%). So the borrower's all-in LMI cost is **higher than the base premium** — the duty component varies by state.
- **Minimum premium.** Insurers set a floor, so even a small or low-LVR loan incurs at least the minimum — **QBE's is $1,150 incl GST (excluding state duty)**.
- **Capitalisation.** LMI can be **paid upfront at settlement** or **capitalised** (added to the loan and repaid with interest over the term). Capitalising preserves settlement cash but adds the premium to the debt and the interest on it. Per QBE's guide, capitalising adds **no extra premium cost**, and the cap is expressed as LVR: **max 95% LVR excluding the premium, 100% including the capitalised premium** — i.e. the premium itself can take the loan to 100% but no further.
- **Partial refund.** If the loan is **repaid/discharged within a limited window after settlement**, the insurer may refund part of the premium, on request. QBE's published window is **≤12 months** (loan repaid in full, QBE notified within 30 days, refund ≥$500); other insurers' windows and sliding scales differ — confirm per insurer. Relevant to `ownership_planning`'s refinance/graduation timing.

## Relevance for Vietnamese-Australian buyers (Mode A)

- For the typical 5%-deposit Mode A FHB, LMI would be **thousands to tens of thousands of dollars** — which is exactly what an [FHG](../scheme/fhg.md)-backed loan **avoids** (the government guarantee stands in for LMI). The size of that avoided premium is `eligibility.fhg.lmi_savings_estimate` and a primary reason the FHG path usually wins for an eligible buyer.
- Where FHG is unavailable (e.g. a place not used, or non-qualifying property), the LMI-payable path is the fallback — and **capitalising** the premium is usually how a deposit-constrained buyer absorbs it. Surface the trade-off (cash preserved vs interest paid), as information.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference / formula-in-code doc** — it fills no slot. The precise premium is the **insurer's rate table at application**; the base-scope estimate is **resolver/agent-computed** from these parameters and the indicative band table (the same "computed, not asserted" discipline as stamp duty). The doc supplies the structure (80% threshold, scaling, capitalisation, duty, refund) and indicative coefficients only.

```jsonc
{
  "fills": [],
  "parameters": {
    "lvr_threshold_pct":            { "type": "percentage", "value": 80,   "note": "LMI required above 80% LVR; at/under 80% none — the universal trigger" },
    "premium_is_one_off":           { "type": "bool",       "value": true, "note": "single premium at loan start, not recurring" },
    "premium_scales_with":          { "type": "array<string>", "value": ["lvr_band", "loan_amount"], "note": "rises with both LVR and loan size; combined in the insurer's rate table" },
    "indicative_premium_pct_of_loan_low":  { "type": "percentage", "value": 0.5, "note": "INDICATIVE only — low end (~81–85% LVR); actual = insurer rate table at application, not asserted" },
    "indicative_premium_pct_of_loan_high": { "type": "percentage", "value": 5.0, "note": "INDICATIVE only — high end (~95% LVR, large loan); actual = insurer rate table" },
    "capitalisable":                { "type": "bool",       "value": true, "note": "may be added to the loan (then interest-bearing); QBE primary: no extra premium to capitalise, max 95% LVR excl premium / 100% incl capitalised premium" },
    "min_premium_aud_qbe":          { "type": "money",      "value": 1150, "note": "REGULATED-adjacent primary (QBE LMI Guide, Apr 2026) — minimum premium $1,150 incl GST, excl state duty; insurer-specific floor, QBE cited as a published example" },
    "attracts_gst_and_state_duty":  { "type": "bool",       "value": true, "note": "premium attracts GST + state insurance/stamp duty (e.g. QLD ~9%) — borrower's all-in cost exceeds the base premium; duty varies by state (confirmed QBE LMI Guide §11)" },
    "partial_refund_window_months": { "type": "integer",    "value": 12,   "note": "QBE LMI Guide (primary): partial refund only if loan discharged ≤12 months after settlement, repaid in full, QBE notified within 30 days, refund ≥$500. Window/scale is insurer-specific — some historically to ~24mo; confirm per insurer" }
  },
  "lookup": {
    "indicative_premium_by_lvr_band": {
      "note": "INDICATIVE rates at ~$500k loan for a base-scope estimate ONLY; the binding premium is the insurer's proprietary (LVR × loan-size) rate table at application — resolver produces an estimate, not an assertion",
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
- **The lookup is flagged INDICATIVE, deliberately.** Real LMI is a proprietary 2D matrix (LVR band × loan-amount band) that insurers don't publish in full. Encoding a precise table would assert figures we cannot verify and that drift per insurer. The band table is an order-of-magnitude estimator for the **base-scope** number; the **per-property** figure is the quote. Same honesty as recording HEM as a basis, not a number, in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md).
- **State duty is named but not tabled here.** The GST + state-insurance-duty uplift varies by state; only QLD's ~9% is cited as an example. If a precise per-state LMI-duty calculation is ever needed it composes with [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md)'s per-state logic rather than duplicating a duty table here (single-owner discipline).
- **The 80% threshold is a `parameter`, not a `criteria`.** Whether a given purchase exceeds 80% LVR is control flow over price + deposit — resolver code per §11.9, consuming this number; the doc supplies the threshold, not a declarative predicate.

## Sources

- QBE — *LMI Guide* (April 2026) — primary (insurer's own underwriting guide): minimum premium **$1,150 incl GST**; capitalisation to **100% LVR incl premium / 95% excl** at no extra premium cost; stamp duty payable on the premium, varies by state (§11); partial refund only if discharged **≤12 months** after settlement (§9); premium **rates are not published** — "Lender should contact QBE LMI" (§6), confirming the matrix is proprietary. (primary: `docs/sources/qbe_lmi/qbe-lmi-guide.pdf`)
- ASIC Moneysmart — *Lenders mortgage insurance* (LMI required above 80% LVR; insures the lender; one-off; can be added to the loan) — https://moneysmart.gov.au/home-loans/lenders-mortgage-insurance
- Helia — *LMI fee estimator* (the market-leading LMI insurer's own premium estimator; fee typically 1–2% of the loan, scaling with LVR and loan size; premium can be capitalised into the loan) — https://www.helia.com.au/the-hub/calculators-estimators/lmi-fee-estimator
- money.com.au — *Lenders Mortgage Insurance Guide: How Much Is LMI?* (indicative — worked premium examples; per-state insurance-duty rates on the premium) — https://www.money.com.au/home-loans/lenders-mortgage-insurance

> The exact premium rate matrix is **proprietary** to each LMI insurer (Helia/QBE/Arch do not publish their full rate tables) — the QBE LMI Guide §6 confirms this directly ("Lender should contact QBE LMI" for rates), so premium **percentages** are **INDICATIVE**; the structural figures above (min premium, capitalisation LVR caps, refund window, stamp-duty-on-premium) are now anchored to the QBE primary. See [`kb.lmi.providers`](providers.md) for the insurer landscape.
