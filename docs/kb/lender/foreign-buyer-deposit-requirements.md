---
slug: kb.lender.foreign-buyer-deposit-requirements
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.canstar.com.au/home-loans/non-resident-home-loans/
    retrieved: 2026-07-06
    note: "Non-residents typically face 60-70% LVR (30-40% deposit); restricted lender pool (mostly non-bank); higher rates. Lender-policy convention (aggregator source)"
  - url: https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
    retrieved: 2026-07-06
    note: "Temp resident with AU income ~80% LVR; up to 95% LVR with a citizen/PR partner (5% deposit). Lender-policy convention (aggregator source)"
---

# Deposit requirements for foreign buyers and temporary residents

This doc owns the **deposit / LVR bands** a foreign person or temporary resident faces — the size of the cash contribution the lender requires, which for a foreign-income borrower is materially larger than the domestic 5–20%. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically `deposit_requirements.minimum_required_percentage_typical` and the derived `minimum_required_amount` / `recommended_amount`. The **serviceability framework** that also gates the loan is owned by [`kb.lender.serviceability-basics`](serviceability-basics.md) and the foreign-axis deltas by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); this doc owns only the **deposit floor**.

All figures are **lender-policy conventions** (flagged `CONVENTION`), surfaced as typical bands and deferred to a licensed broker (ASIC line: information, no credit advice).

## The deposit bands, by income/residency profile

The deposit turns on the same AU-income-vs-foreign-income axis as the serviceability delta:

- **Foreign person earning foreign income (non-resident)** — typically **30–40% deposit** (lenders cap LVR at **60–70%**). 30% is the common baseline; 40% appears for less-standard profiles or currencies. This is the load-bearing figure for the Vietnam-parent-funded / VN-income buyer.
- **Temporary resident earning AUD in Australia** — typically **20% deposit** (80% LVR), i.e. ordinary domestic terms; some lenders will go higher-LVR with LMI (but LMI availability for a foreign person is itself restricted — [`kb.lmi.calculation-for-foreign-persons`](../lmi/calculation-for-foreign-persons.md)).
- **Buying with an Australian citizen / PR / NZ-citizen partner as joint tenants** — can reach **95% LVR (5% deposit)**, because the purchase is assessed on the domestic co-borrower's footing (and the FIRB overlay falls away — [`kb.firb.status-determination`](../firb/status-determination.md), [`kb.lender.485-visa-treatment`](485-visa-treatment.md)).

## Deposit is separate from the other cash-at-settlement costs

The deposit is **not** the whole cash requirement. A foreign buyer also funds the FIRB application fee, the foreign-buyer stamp-duty surcharge, ordinary duty, and FX spread on moving the funds — all owned by the `cash_position` component and its anchors ([`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md), `kb.foreign-buyer-surcharge.by-state`, `kb.fx.typical-spreads-vnd-aud`). This doc owns the **loan deposit only**; the total cash-to-settle is assembled downstream, so the deposit figure here must not be presented as the buyer's total outlay.

## Genuine savings still applies

The **genuine-savings** convention from [`kb.lender.serviceability-basics`](serviceability-basics.md) (typically ~5% of price held ≥3 months) applies to a foreign-person loan the same way — and a **lump-sum gift from an overseas parent may fail it**, which for the Vietnam-parent-funded buyer is a common trap. The larger 30%+ deposit does not remove the genuine-savings expectation on the portion the lender requires as saved funds; surface it early so the funding is structured to qualify.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver selects the deposit band from the profile's income/residency profile and computes the dollar `minimum_required_amount` / `recommended_amount` against the target price; this doc supplies the grounded bands. No leaf asserted; dollar figures are resolver-computed.

```jsonc
{
  "fills": [],
  "parameters": {
    "non_resident_deposit_pct_typical": { "type": "int", "value": 30, "provenance": "CONVENTION", "note": "typical minimum deposit for a foreign person earning foreign income (LVR capped ~70%); the common baseline." },
    "non_resident_deposit_pct_upper": { "type": "int", "value": 40, "provenance": "CONVENTION", "note": "upper end (LVR ~60%) for less-standard profiles / currencies." },
    "non_resident_lvr_cap_pct": { "type": "int", "value": 70, "provenance": "CONVENTION", "note": "lenders commonly cap non-resident LVR at 60–70%; the deposit is the complement." },
    "temp_resident_au_income_deposit_pct_typical": { "type": "int", "value": 20, "provenance": "CONVENTION", "note": "temp resident earning AUD in AU is typically offered ordinary 80% LVR (20% deposit)." },
    "with_au_partner_min_deposit_pct": { "type": "int", "value": 5, "provenance": "CONVENTION", "note": "joint purchase with an AU citizen/PR/NZ-citizen partner as joint tenants can reach 95% LVR (5% deposit); FIRB overlay also falls away." },
    "deposit_is_not_total_cash_to_settle": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "FIRB fee, foreign-buyer surcharge, ordinary duty and FX spread are additional and owned by cash_position anchors; do not present the deposit as total outlay." },
    "genuine_savings_still_applies": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the ~5%-held-3-months genuine-savings rule (kb.lender.serviceability-basics) applies; a lump-sum overseas parental gift may fail it." }
  }
}
```

Notes:

- **Single-owner.** Deposit / LVR bands only. Serviceability core → [`kb.lender.serviceability-basics`](serviceability-basics.md); foreign-axis deltas → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); LMI-for-foreign-persons → [`kb.lmi.calculation-for-foreign-persons`](../lmi/calculation-for-foreign-persons.md); the non-deposit cash-to-settle costs → the `cash_position` anchors.
- **Conventions, not regulated.** Deposit floors are lender policy, flagged `CONVENTION`; presented as bands, deferred to a broker.
- **Don't double-count.** The deposit is one line of the cash-to-settle assembled in `cash_position`; this doc owns the loan deposit, not the total.

## Sources

- Canstar — *Non-Resident Home Loans in Australia* (30–40% deposit / 60–70% LVR for foreign nationals) — https://www.canstar.com.au/home-loans/non-resident-home-loans/
- Home Loan Experts — *Temporary Resident Home Loan Australia* (temp resident with AU income ~80% LVR; up to 95% with an AU citizen/PR partner) — https://www.homeloanexperts.com.au/non-resident-mortgages/temporary-resident-mortgage/
- ASIC Moneysmart — *How much you can borrow* (deposit, LVR, genuine savings) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
