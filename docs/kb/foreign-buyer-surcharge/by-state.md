---
slug: kb.foreign-buyer-surcharge.by-state
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.sro.vic.gov.au/rates-taxes-duties-and-levies/foreign-purchaser-additional-duty-current-rates
    retrieved: 2026-07-06
  - url: https://qro.qld.gov.au/duties/investors/afad/
    retrieved: 2026-07-06
  - url: https://www.wa.gov.au/government/publications/foreign-transfer-duty
    retrieved: 2026-07-06
  - url: https://sro.tas.gov.au/property-transfer-duties/foreign-investor-duty-surcharge/rates-of-surcharge
    retrieved: 2026-07-06
  - url: https://www.pwc.com.au/tax/assets/stamp-duty/australian-stamp-duty-and-land-tax-maps.pdf
    retrieved: 2026-07-06
    path: docs/sources/foreign-buyer-surcharge/pwc-australian-stamp-duty-and-land-tax-maps.pdf
---

# Foreign purchaser stamp-duty surcharge — by state

This doc owns the **per-state foreign purchaser stamp-duty surcharge** — variously called *surcharge purchaser duty* (NSW), *foreign purchaser additional duty* (VIC), *additional foreign acquirer duty / AFAD* (QLD), *foreign transfer duty* (WA), *foreign ownership surcharge* (SA), *foreign investor duty surcharge / FIDS* (TAS). It is the **one-off surcharge on transfer (stamp) duty** a foreign person pays *at purchase*, charged on the property's dutiable value on top of standard duty. It grounds `cash_position` (component 5): the resolver reads the surcharge **percentage** for the property's state (`stamp_duty_and_surcharge.foreign_buyer_surcharge_percentage`, `derived_from: property_fit.state`) and computes `foreign_buyer_surcharge_amount` = dutiable value × rate.

**Three distinct foreign-person imposts, three owners — no double-counting.** The **standard stamp duty** this surcharge sits on top of is owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md); the **annual land-tax** foreign/absentee surcharge (a recurring, separate impost) by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md); the **FIRB application fee** by [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md). This doc owns only the **one-off duty surcharge rate**. `cash_position`'s `regulatory_imposts_total` sums FIRB fee + this duty surcharge + LMI (if any) — each read from its single owner.

## The surcharge — one-off, at purchase

A foreign person pays an **additional transfer-duty surcharge** on residential property, charged on the **dutiable value** (contract price or market value, whichever is higher), **payable at settlement** alongside standard duty. It is a purchase-time cost, not a recurring one. **Two jurisdictions — ACT and NT — levy no such duty surcharge.**

## By state — the rates

**Primary-verified against the state revenue office; QLD and TAS rate-history confirmed to the effective date:**

| State | Foreign purchaser duty surcharge | Effective | Source tier |
|---|---|---|---|
| **NSW** | **9%** (surcharge purchaser duty) | increased from 8% on **1 Jan 2025** — the highest in Australia | PRIMARY (Revenue NSW) |
| **VIC** | **8%** (foreign purchaser additional duty) | stable | PRIMARY (SRO VIC) |
| **QLD** | **8%** (AFAD residential) | increased from 7% on **1 Jul 2024** (aligning with NSW/VIC) | PRIMARY (QRO — 3% 2016–18, 7% 2018–24, 8% from 1 Jul 2024) |
| **WA** | **7%** (foreign transfer duty) | stable | PRIMARY (RevenueWA) |
| **SA** | **7%** (foreign ownership surcharge) | stable | PRIMARY (RevenueSA) |
| **TAS** | **8%** (FIDS, residential) | 8% from **1 Apr 2020** (1.5% for primary-production land) | PRIMARY (SRO Tasmania) |
| **ACT** | **none** | ACT levies **no** foreign purchaser *duty* surcharge | PRIMARY (nil) |
| **NT** | **none** | NT levies **no** foreign purchaser duty surcharge | PRIMARY (nil) |

ACT does apply a separate **annual land-tax** foreign-ownership surcharge (owned in spirit by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md), not here) — but no purchase-time *duty* surcharge, which is what this doc owns.

## What it applies to, and the "foreign person" test

- **Base:** standard duty on the dutiable value, **plus** the surcharge percentage on that same value. The surcharge is not reduced by any first-home concession.
- **Foreign persons are ineligible for first-home-buyer duty concessions** — the blueprint fixes `first_home_concession_applicable_for_foreign_person: false`. (The eligibility replacement is why Mode B drops the Mode-A scheme stack.)
- **The "foreign person" test is per-state and distinct from FIRB's test** (though overlapping). Permanent residents are exempt in some states and not others; NZ citizens on a Special Category Visa are commonly treated as non-foreign; a temporary resident may or may not be "foreign" for a given state's *duty* test even while being a foreign person for FIRB. The precise per-state definition is deferred to the state revenue office — the resolver applies the **rate**, not the eligibility ruling.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The single largest one-off regulatory impost after the deposit.** On a $1M NSW purchase, 9% = **$90,000** on top of standard duty — the defining Mode-B cost the plan must surface transparently.
- **State choice is a real ~1–2% swing.** WA/SA (7%) versus NSW/VIC/QLD/TAS (8–9%); ACT/NT levy none. Where the buyer is flexible on state, the surcharge is a material input.
- **Distinct from the FIRB fee and the annual land-tax surcharge** — surfaced separately in `regulatory_imposts_total` so the buyer sees each foreign-person impost, not a blended number.
- **Information, not advice.** The plan applies the current published rate and points to the state revenue office to confirm the rate and the "foreign person" ruling for the buyer's circumstances.

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver reads the surcharge **percentage** for the property's state from the schedule below and computes `foreign_buyer_surcharge_amount` = dutiable value × rate; **postcondition** — that computed surcharge should match the state revenue office's foreign-surcharge calculator **to the dollar** (the rate is the regulated input; the standard duty it sits atop is owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md)). No leaf asserted here; no dollar figure stored.

```jsonc
{
  "fills": [],
  "parameters": {
    "surcharge_basis": { "type": "string", "value": "one-off surcharge on transfer (stamp) duty, charged on the dutiable value (price or market value, whichever higher), payable at settlement on top of standard duty; not reduced by any first-home concession", "provenance": "REGULATED", "note": "the structural basis common to all surcharging states" },
    "nsw_surcharge_pct": { "type": "percentage", "value": 9, "provenance": "REGULATED", "note": "Revenue NSW surcharge purchaser duty; increased from 8% to 9% on 1 Jan 2025 (highest in Australia)." },
    "vic_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "SRO VIC foreign purchaser additional duty." },
    "qld_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "QRO additional foreign acquirer duty (AFAD) residential; increased from 7% to 8% on 1 Jul 2024." },
    "wa_surcharge_pct": { "type": "percentage", "value": 7, "provenance": "REGULATED", "note": "RevenueWA foreign transfer duty." },
    "sa_surcharge_pct": { "type": "percentage", "value": 7, "provenance": "REGULATED", "note": "RevenueSA foreign ownership surcharge." },
    "tas_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "SRO Tasmania foreign investor duty surcharge (FIDS) residential; 8% from 1 Apr 2020 (1.5% primary-production land)." },
    "act_has_no_duty_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ACT levies no foreign purchaser DUTY surcharge (a separate annual land-tax foreign surcharge is owned by kb.tax.land-tax-by-state)." },
    "nt_has_no_duty_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "NT levies no foreign purchaser stamp-duty surcharge." }
  },
  "lookup": {
    "foreign_buyer_surcharge_by_state": {
      "note": "per-state foreign purchaser DUTY surcharge rate; the resolver reads surcharge_pct for the property's state and computes amount = dutiable value × rate (postcondition vs the state revenue calculator). Standard duty is owned by kb.stamp-duty.calc-by-state; annual land-tax surcharge by kb.tax.land-tax-by-state.",
      "entries": [
        { "state": "NSW", "surcharge_pct": 9, "effective": "2025-01-01", "label": "surcharge purchaser duty", "verification": "PRIMARY (Revenue NSW)" },
        { "state": "VIC", "surcharge_pct": 8, "effective": "stable", "label": "foreign purchaser additional duty", "verification": "PRIMARY (SRO VIC)" },
        { "state": "QLD", "surcharge_pct": 8, "effective": "2024-07-01", "label": "additional foreign acquirer duty (AFAD)", "verification": "PRIMARY (QRO)" },
        { "state": "WA", "surcharge_pct": 7, "effective": "stable", "label": "foreign transfer duty", "verification": "PRIMARY (RevenueWA)" },
        { "state": "SA", "surcharge_pct": 7, "effective": "stable", "label": "foreign ownership surcharge", "verification": "PRIMARY (RevenueSA)" },
        { "state": "TAS", "surcharge_pct": 8, "effective": "2020-04-01", "label": "foreign investor duty surcharge (FIDS), residential", "verification": "PRIMARY (SRO Tasmania)" },
        { "state": "ACT", "surcharge_pct": 0, "effective": "n/a", "label": "no duty surcharge", "verification": "PRIMARY (nil)" },
        { "state": "NT", "surcharge_pct": 0, "effective": "n/a", "label": "no duty surcharge", "verification": "PRIMARY (nil)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; the resolver computes the amount, not this doc.** The doc supplies the regulated **rate schedule**; `cash_position` computes `foreign_buyer_surcharge_amount` = dutiable value × rate and verifies it to the dollar against the state revenue calculator ([[verify-regulated-figures-by-postcondition]]). A regulated dollar figure is not stored in the KB.
- **Single-owner cross-refs.** Standard duty → [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md); annual land-tax foreign/absentee surcharge → [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md); FIRB fee → [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md). This doc owns only the one-off duty surcharge rate.
- **Annual reindexation / rate change.** Rates change by state budget (NSW 8→9% Jan-2025; QLD 7→8% Jul-2024; TAS →8% Apr-2020). `last_verified` is the freshness anchor; re-confirm each rate against the state revenue office on the annual pass.
- **"Foreign person" is a per-state ruling, deferred.** The resolver applies the rate; the eligibility/exemption determination (PR, SCV, temp resident) is confirmed with the state revenue office.

## Sources

**Canonical (state revenue offices):**

- Revenue NSW — *Surcharge purchaser duty* (9% for foreign persons; increased from 8% on 1 Jan 2025) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/surcharge-purchaser-duty
- State Revenue Office Victoria — *Foreign purchaser additional duty* (8%) — https://www.sro.vic.gov.au/foreign-purchaser-additional-duty
- Queensland Revenue Office — *Additional foreign acquirer duty (AFAD)* (8% residential from 1 Jul 2024; 3% 2016–18, 7% 2018–24) — https://qro.qld.gov.au/duties/investors/afad/
- RevenueWA (Department of Treasury and Finance WA) — *Foreign transfer duty* (7%) — https://www.wa.gov.au/organisation/department-of-treasury-and-finance/foreign-transfer-duty
- RevenueSA — *Foreign ownership surcharge* (7%) — https://www.revenuesa.sa.gov.au/stampduty/stamp-duty-and-land-tax-changes/foreign-ownership-surcharge
- State Revenue Office Tasmania — *Foreign investor duty surcharge — rates of surcharge* (8% residential from 1 Apr 2020; 1.5% primary-production) — https://sro.tas.gov.au/property-transfer-duties/foreign-investor-duty-surcharge/rates-of-surcharge

**Cross-source (professional / secondary, for the by-state consolidation):**

- PwC — *Australian Stamp Duty & Land Tax Maps* (1 Feb 2026; national foreign-surcharge consolidation) — https://www.pwc.com.au/tax/assets/stamp-duty/australian-stamp-duty-and-land-tax-maps.pdf
- Home Loan Experts — *Foreign Buyer Stamp Duty Surcharge Rates by State 2026* (NSW 9%, VIC/QLD/TAS 8%, WA/SA 7%, ACT/NT none) — https://www.homeloanexperts.com.au/non-resident-mortgages/foreign-citizen-stamp-duty/
