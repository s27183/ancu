---
slug: kb.lmi.calculation-for-foreign-persons
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# LMI for foreign persons — the availability delta

This doc owns the **foreign-person availability delta** for Lenders Mortgage Insurance: *whether LMI is even on the table* for a foreign person or temporary resident, and on what terms. It grounds two components — `mortgage_finance` (component 5, the "some accept 20% with LMI" deposit path) and `cash_position` (component 6, the `other_buying_costs.lmi_if_lvr_above_80` line).

The **universal LMI mechanics** — the 80% LVR trigger, how the premium is sized (the insurer's proprietary LVR × loan-size rate table), capitalisation, GST + state duty, refund window — are owned by [`kb.lmi.calculation`](calculation.md), which declares itself owner of "how the premium is sized and structured", and the insurer landscape by [`kb.lmi.providers`](providers.md). This doc owns **only what changes for a foreign borrower** and points back to those for the universal core rather than restating it — the same split-by-axis discipline as [`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md) relative to serviceability-basics.

## The delta: LMI is usually not available to a foreign borrower

For a domestic FHB, LMI is the standard way to borrow above 80% LVR with a small deposit. For a foreign person earning foreign income, it mostly **is not an option**:

- **Non-resident lending is typically capped at 60–80% LVR** ([`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md)) — i.e. **at or below the 80% threshold, so LMI does not arise.** The larger deposit is required *instead of*, not *alongside*, LMI.
- **LMI insurers restrict cover for non-residents.** Even where a lender might go above 80%, several LMI insurers will not accept a non-resident risk, so the high-LVR-with-LMI path that a domestic borrower relies on is largely closed.
- **Consequence:** for the standard non-resident (foreign-income) buyer, plan on the **deposit floor**, not on LMI bridging a small deposit. The `lmi_if_lvr_above_80` line is typically **$0** for this profile because the LVR is held at/under 80%.

## Where LMI *does* re-enter

- **Temporary resident earning AUD in Australia.** Assessed near-domestic, some lenders will lend above 80% LVR **with LMI** — the ordinary mechanics of [`kb.lmi.calculation`](calculation.md) then apply, subject to the lender/insurer accepting the visa profile ([`kb.lender.485-visa-treatment`](485-visa-treatment.md)).
- **Buying with an Australian citizen / PR / NZ-citizen partner.** The purchase is assessed on the domestic co-borrower's footing, up to 95% LVR, and **LMI applies as it would for any local** high-LVR loan — sized per [`kb.lmi.calculation`](calculation.md). This is the main route by which a Mode-B buyer meets LMI at all.

In both re-entry cases the **premium is sized by the universal doc, not here** — this doc only determines *whether* LMI applies to the profile.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Don't model LMI for the standard foreign-income buyer.** The deposit floor is the binding constraint; LMI is generally unavailable, so the cash plan carries the 30%+ deposit rather than an LMI premium.
- **Do model LMI on the AU-income and joint-purchase paths.** There it behaves like a domestic high-LVR loan; size it via [`kb.lmi.calculation`](calculation.md).
- **The cash-calculator line is conditional.** `lmi_if_lvr_above_80` is $0 unless the profile is one of the re-entry cases — the resolver decides which, this doc supplies the rule.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` and `cash_position` resolvers use the availability rule below to decide **whether** LMI applies to the profile; when it does, the premium is computed by [`kb.lmi.calculation`](calculation.md)'s parameters, not here. No leaf asserted; no premium figure duplicated.

```jsonc
{
  "fills": [],
  "parameters": {
    "lmi_generally_unavailable_for_foreign_income_borrower": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "non-resident lending is typically capped at 60–80% LVR and LMI insurers restrict non-resident cover, so LMI mostly does not arise — the deposit floor binds instead." },
    "non_resident_lvr_at_or_under_80_so_no_lmi": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "with LVR held at/under 80%, LMI does not apply; lmi_if_lvr_above_80 is typically $0 for the standard foreign-income profile." },
    "lmi_applies_for_temp_resident_au_income_above_80": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a temp resident earning AUD may borrow above 80% LVR with LMI where the lender/insurer accepts the visa; premium sized by kb.lmi.calculation." },
    "lmi_applies_for_joint_purchase_with_au_partner": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "buying with an AU citizen/PR/NZ-citizen partner (up to 95% LVR) meets LMI as an ordinary local high-LVR loan; premium sized by kb.lmi.calculation." },
    "premium_sizing_owned_by_universal_lmi_doc": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "when LMI applies, the premium (80% trigger, LVR × loan-size rate table, capitalisation, GST + state duty, refund) is owned by kb.lmi.calculation — this doc only decides applicability." }
  }
}
```

Notes:

- **Single-owner via split-by-axis.** This doc owns *foreign-person LMI availability*; the premium sizing stays with [`kb.lmi.calculation`](calculation.md) and the insurer landscape with [`kb.lmi.providers`](providers.md). No premium mechanics restated.
- **Consumed by two components.** `mortgage_finance` (deposit path) and `cash_position` (the LMI cash line) both read this applicability rule; the deposit bands themselves are owned by [`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md).
- **Conventions.** Availability is lender/insurer policy, flagged `CONVENTION`, deferred to a broker.

## Sources

- Professional Home Loans — *Home Loans for Temporary Visa Holders* (LMI over 80% LVR available for AU-income temp residents with the right visa; options otherwise capped at 80%) — https://www.professionalhomeloans.com.au/home-loans/home-loans-temporary-visa/
- Home Loan Experts — *Temporary Resident Home Loan Australia* (non-resident deposit 20–30%+, LVR commonly capped at 70–80%; up to 95% with an AU partner) — https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
- ASIC Moneysmart — *Lenders mortgage insurance* (LMI required above 80% LVR; insures the lender) — https://moneysmart.gov.au/home-loans/lenders-mortgage-insurance
