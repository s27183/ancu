---
slug: kb.foreign-buyer-surcharge.by-state
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.sro.vic.gov.au/rates-taxes-duties-and-levies/foreign-purchaser-additional-duty-current-rates
    retrieved: 2026-10-27
    path: docs/sources/vic/foreign-purchaser-additional-duty-current-rates.txt
    note: "301-redirects to …/about-us/rates-and-statistics/current-rates/foreign-purchaser-additional-duty-current-rates, the page archived."
    quotes:
      - "1 July 2019, the additional duty rate is 8%"
  - url: https://qro.qld.gov.au/duties/self-assessors/toolkits/afad/
    retrieved: 2026-10-27
    path: docs/sources/qld/afad-residential-land-toolkit.txt
    quotes:
      - "8% where the transaction’s liability for transfer duty arises on or after 1 July 2024."
      - "7% where the transaction’s liability for transfer duty arises between 1 July 2018 and 30 June 2024"
  - url: https://www.wa.gov.au/government/publications/foreign-transfer-duty
    retrieved: 2026-10-27
    path: docs/sources/foreign-buyer-surcharge/wa-foreign-transfer-duty.txt
    quotes:
      - "Additional duty of 7% applies when foreign persons purchase residential property."
  - url: https://sro.tas.gov.au/property-transfer-duties/foreign-investor-duty-surcharge/rates-of-surcharge
    retrieved: 2026-10-27
    note: "PRIMARY (SRO Tasmania) — read 2026-10-27 through a browser-grade fetch (8% residential from 1 April 2020; 1.5% primary-production land); not archived: the host's TLS certificate fails curl, so the archive script cannot fetch it."
  - url: https://revenuesa.sa.gov.au/stamp-duty/foreign-ownership-surcharge
    retrieved: 2026-10-27
    note: "PRIMARY (RevenueSA) — the foreign ownership surcharge, 7% of the value of the interest in residential land; not archived: the host answers 403 to scripted fetches (Cloudflare challenge)."
  - url: https://www.revenue.nsw.gov.au/property-professionals-resource-centre/guides-rulings-cpns/topics/surcharge-purchaser-duty-guide/overview
    retrieved: 2026-10-27
    path: docs/sources/nsw/surcharge-purchaser-duty-overview.txt
    quotes:
      - "Surcharge Purchaser Duty is calculated on the dutiable value (the greater of the purchase price or value) and is paid in addition to transfer duty payable on the acquisition of residential-related property."
  - url: https://qro.qld.gov.au/duties/investors/afad/assessing/
    retrieved: 2026-10-27
    path: docs/sources/qld/afad-assessing-and-calculating.txt
    quotes:
      - "As a foreign acquirer, you may be eligible to claim one of the home concessions"
      - "The concession will only apply to the calculation of transfer duty—you will still need to pay the AFAD calculated on the dutiable value of the AFAD residential land."
  - url: https://www.revenue.act.gov.au/rates-and-property-charges/conveyance-duty-stamp-duty
    retrieved: 2026-10-27
    path: docs/sources/act/conveyance-duty-stamp-duty.txt
    note: "ACT Revenue Office's conveyance duty page — it names no foreign purchaser duty surcharge (the ACT nil rests on that absence)."
  - url: https://www.revenue.act.gov.au/rates-and-property-charges/land-tax/foreign-ownership-surcharge-for-land-tax
    retrieved: 2026-10-27
    path: docs/sources/act/foreign-ownership-surcharge-land-tax.txt
    quotes:
      - "If you’re a foreign person who owns residential land in the ACT, you must pay a land tax surcharge of 0.75 per cent of the Average Unimproved Value per year from 1 July 2018 onwards."
---

# Foreign purchaser stamp-duty surcharge — by state

This doc owns the **per-state foreign purchaser stamp-duty surcharge** — variously called *surcharge purchaser duty* (NSW), *foreign purchaser additional duty* (VIC), *additional foreign acquirer duty / AFAD* (QLD), *foreign transfer duty* (WA), *foreign ownership surcharge* (SA), *foreign investor duty surcharge / FIDS* (TAS). It is the **one-off surcharge on transfer (stamp) duty** a foreign person pays *at purchase*, charged on the property's dutiable value on top of standard duty. It grounds `cash_position` (component 5): the resolver reads the surcharge **percentage** for the property's state (`stamp_duty_and_surcharge.foreign_buyer_surcharge_percentage`, `derived_from: property_fit.state`) and computes `foreign_buyer_surcharge_amount` = dutiable value × rate.

**Three distinct foreign-person imposts, three owners — no double-counting.** The **standard stamp duty** this surcharge sits on top of is owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md); the **annual land-tax** foreign/absentee surcharge (a recurring, separate impost) by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md); the **FIRB application fee** by [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md). This doc owns only the **one-off duty surcharge rate**. `cash_position`'s `regulatory_imposts_total` sums FIRB fee + this duty surcharge + LMI (if any) — each read from its single owner.

## The surcharge — one-off, at purchase

A foreign person pays an **additional transfer-duty surcharge** on residential property, charged on the **dutiable value** (contract price or market value, whichever is higher), **payable at settlement** alongside standard duty. It is a purchase-time cost, not a recurring one. **ACT and NT levy no such duty surcharge** — for the ACT, its revenue office's conveyance-duty page names none; the NT figure is a PLACEHOLDER (below).

## By state — the rates

Each row cites its own state's revenue office (full list under Sources below):

| State | Foreign purchaser duty surcharge | Effective | Source tier |
|---|---|---|---|
| **NSW** | **9%** (surcharge purchaser duty) | from **1 Jan 2025** (8% 1 Jul 2017 – 31 Dec 2024; 4% 21 Jun 2016 – 30 Jun 2017) — the highest in Australia | [Revenue NSW](https://www.revenue.nsw.gov.au/property-professionals-resource-centre/guides-rulings-cpns/topics/surcharge-purchaser-duty-guide/overview) |
| **VIC** | **8%** (foreign purchaser additional duty) | from **1 Jul 2019** (7% 1 Jul 2016 – 30 Jun 2019) | [SRO Victoria](https://www.sro.vic.gov.au/rates-taxes-duties-and-levies/foreign-purchaser-additional-duty-current-rates) |
| **QLD** | **8%** (AFAD, residential land) | from **1 Jul 2024** (3% 1 Oct 2016 – 30 Jun 2018; 7% 1 Jul 2018 – 30 Jun 2024) | [QRO](https://qro.qld.gov.au/duties/self-assessors/toolkits/afad/) |
| **WA** | **7%** (foreign transfer duty) | current | [WA Government — RevenueWA](https://www.wa.gov.au/government/publications/foreign-transfer-duty) |
| **SA** | **7%** (foreign ownership surcharge) | current | [RevenueSA](https://revenuesa.sa.gov.au/stamp-duty/foreign-ownership-surcharge) |
| **TAS** | **8%** (FIDS, residential) | from **1 Apr 2020** (1.5% for primary-production land) | [SRO Tasmania](https://sro.tas.gov.au/property-transfer-duties/foreign-investor-duty-surcharge/rates-of-surcharge) |
| **ACT** | **none** | the conveyance-duty page names no foreign purchaser *duty* surcharge | [ACT Revenue Office](https://www.revenue.act.gov.au/rates-and-property-charges/conveyance-duty-stamp-duty) (nil by absence) |
| **NT** | **none** (PLACEHOLDER) | no primary read this pass | re-ground on the Territory Revenue Office's stamp-duty pages on treasury.nt.gov.au (refused scripted fetch, 2026-10-27) |

ACT does apply a separate **annual land-tax** foreign-ownership surcharge — "a land tax surcharge of 0.75 per cent of the Average Unimproved Value per year from 1 July 2018 onwards" ([ACT Revenue Office](https://www.revenue.act.gov.au/rates-and-property-charges/land-tax/foreign-ownership-surcharge-for-land-tax); owned in spirit by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md), not here) — but no purchase-time *duty* surcharge, which is what this doc owns.

## What it applies to, and the "foreign person" test

- **Base:** standard duty on the dutiable value, **plus** the surcharge percentage on that same value (Revenue NSW: "calculated on the dutiable value (the greater of the purchase price or value)"). In QLD a home concession reduces only the transfer duty — "you will still need to pay the AFAD calculated on the dutiable value of the AFAD residential land."
- **First-home duty concessions for a foreign person are per state, not a blanket bar.** QLD says: "As a foreign acquirer, you may be eligible to claim one of the home concessions" (on transfer duty, if the criteria are met). The blueprint's `first_home_concession_applicable_for_foreign_person: false` is therefore not true for QLD; other states are not established here — confirm with the state revenue office.
- **The "foreign person" test is per-state and distinct from FIRB's test** (though overlapping). Permanent residents are exempt in some states and not others; NZ citizens on a Special Category Visa are commonly treated as non-foreign; a temporary resident may or may not be "foreign" for a given state's *duty* test even while being a foreign person for FIRB. The precise per-state definition is deferred to the state revenue office — the resolver applies the **rate**, not the eligibility ruling.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The single largest one-off regulatory impost after the deposit.** On a $1M NSW purchase, 9% = **$90,000** on top of standard duty — the defining Mode-B cost the plan must surface transparently.
- **State choice is a real ~1–2% swing.** WA/SA (7%) versus NSW/VIC/QLD/TAS (8–9%); the ACT levies none (NT: PLACEHOLDER, above). Where the buyer is flexible on state, the surcharge is a material input.
- **Distinct from the FIRB fee and the annual land-tax surcharge** — surfaced separately in `regulatory_imposts_total` so the buyer sees each foreign-person impost, not a blended number.
- **Information, not advice.** The plan applies the current published rate and points to the state revenue office to confirm the rate and the "foreign person" ruling for the buyer's circumstances.

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver reads the surcharge **percentage** for the property's state from the schedule below and computes `foreign_buyer_surcharge_amount` = dutiable value × rate; **postcondition** — that computed surcharge should match the state revenue office's foreign-surcharge calculator **to the dollar** (the rate is the regulated input; the standard duty it sits atop is owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md)). No leaf asserted here; no dollar figure stored.

```jsonc
{
  "fills": [],
  "parameters": {
    "surcharge_basis": { "type": "string", "value": "one-off surcharge on transfer (stamp) duty, charged on the dutiable value (price or market value, whichever higher), payable at settlement on top of standard duty; not reduced by any first-home concession", "provenance": "REGULATED", "note": "Revenue NSW (dutiable value = the greater of the purchase price or value); QRO (a home concession applies only to transfer duty, AFAD is still paid on the dutiable value)" },
    "nsw_surcharge_pct": { "type": "percentage", "value": 9, "provenance": "REGULATED", "note": "Revenue NSW surcharge purchaser duty guide; 9% from 1 Jan 2025 (8% 1 Jul 2017 – 31 Dec 2024)." },
    "vic_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "SRO Victoria foreign purchaser additional duty current rates; 8% from 1 Jul 2019." },
    "qld_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "QRO AFAD residential land toolkit; 8% from 1 Jul 2024 (7% 1 Jul 2018 – 30 Jun 2024)." },
    "wa_surcharge_pct": { "type": "percentage", "value": 7, "provenance": "REGULATED", "note": "WA Government (RevenueWA) foreign transfer duty publication: additional duty of 7%." },
    "sa_surcharge_pct": { "type": "percentage", "value": 7, "provenance": "REGULATED", "note": "RevenueSA foreign ownership surcharge page (7% of the value of the interest in residential land); not archived — the host refuses scripted fetches." },
    "tas_surcharge_pct": { "type": "percentage", "value": 8, "provenance": "REGULATED", "note": "SRO Tasmania FIDS rates of surcharge; 8% residential from 1 Apr 2020 (1.5% primary-production land); not archived — the host's certificate fails curl." },
    "act_has_no_duty_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "rests on an absence: the ACT Revenue Office's conveyance-duty page names no foreign purchaser DUTY surcharge (a separate annual land-tax foreign surcharge, 0.75% of AUV, is owned by kb.tax.land-tax-by-state)." },
    "nt_has_no_duty_surcharge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "PLACEHOLDER — no primary states this; re-ground on the Territory Revenue Office's stamp-duty pages on treasury.nt.gov.au (refused scripted fetch 2026-10-27)." }
  },
  "lookup": {
    "line_details": {
      "note": "one entry per statement line this doc's figure is placed on (not a fee line); the engine attaches it as the line's detail, filling {params} with the figures it computed (fh_engine_line_detail, behavior 93)",
      "entries": [
        {
          "id": "surcharge",
          "tier": "REGULATED",
          "how": {
            "vi": "{pct}% của {price} — khoản thuế trước bạ bổ sung của bang {state} cho người mua nước ngoài, cộng thêm vào thuế thông thường.",
            "en": "{pct}% of {price} — {state}'s extra duty for a foreign buyer, on top of the ordinary duty."
          },
          "payer": {
            "vi": "Bạn (người mua nước ngoài) trả khi settlement, cùng với thuế trước bạ thông thường.",
            "en": "You, the foreign buyer, at settlement, with the ordinary duty."
          },
          "drivers": {
            "vi": "Giá nhà và bang: mỗi bang tự đặt thuế suất (ACT và NT không thu).",
            "en": "The price and the state: each state sets its own rate (the ACT and NT charge none)."
          },
          "source": {
            "VIC": 0,
            "QLD": 1,
            "WA": 2,
            "TAS": 3,
            "NSW": 5,
            "SA": 4,
            "ACT": 7
          }
        }
      ]
    },
    "foreign_buyer_surcharge_by_state": {
      "note": "per-state foreign purchaser DUTY surcharge rate; the resolver reads surcharge_pct for the property's state and computes amount = dutiable value × rate (postcondition vs the state revenue calculator). Standard duty is owned by kb.stamp-duty.calc-by-state; annual land-tax surcharge by kb.tax.land-tax-by-state.",
      "entries": [
        { "state": "NSW", "surcharge_pct": 9, "effective": "2025-01-01", "label": "surcharge purchaser duty", "verification": "PRIMARY (Revenue NSW surcharge purchaser duty guide)" },
        { "state": "VIC", "surcharge_pct": 8, "effective": "2019-07-01", "label": "foreign purchaser additional duty", "verification": "PRIMARY (SRO Victoria current rates)" },
        { "state": "QLD", "surcharge_pct": 8, "effective": "2024-07-01", "label": "additional foreign acquirer duty (AFAD)", "verification": "PRIMARY (QRO AFAD toolkit)" },
        { "state": "WA", "surcharge_pct": 7, "effective": "stable", "label": "foreign transfer duty", "verification": "PRIMARY (WA Government foreign transfer duty)" },
        { "state": "SA", "surcharge_pct": 7, "effective": "stable", "label": "foreign ownership surcharge", "verification": "PRIMARY (RevenueSA; not archived)" },
        { "state": "TAS", "surcharge_pct": 8, "effective": "2020-04-01", "label": "foreign investor duty surcharge (FIDS), residential", "verification": "PRIMARY (SRO Tasmania; not archived)" },
        { "state": "ACT", "surcharge_pct": 0, "effective": "n/a", "label": "no duty surcharge", "verification": "PRIMARY by absence (ACT Revenue Office conveyance-duty page names none)" },
        { "state": "NT", "surcharge_pct": 0, "effective": "n/a", "label": "no duty surcharge", "verification": "PLACEHOLDER — no primary read; re-ground on the Territory Revenue Office's stamp-duty pages (treasury.nt.gov.au)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; the resolver computes the amount, not this doc.** The doc supplies the regulated **rate schedule**; `cash_position` computes `foreign_buyer_surcharge_amount` = dutiable value × rate and verifies it to the dollar against the state revenue calculator ([[verify-regulated-figures-by-postcondition]]). A regulated dollar figure is not stored in the KB.
- **Single-owner cross-refs.** Standard duty → [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md); annual land-tax foreign/absentee surcharge → [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md); FIRB fee → [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md). This doc owns only the one-off duty surcharge rate.
- **Annual reindexation / rate change.** Rates change by state budget (NSW 8→9% Jan-2025; QLD 7→8% Jul-2024; VIC 7→8% Jul-2019; TAS →8% Apr-2020). `last_verified` is the freshness anchor; re-confirm each rate against the state revenue office on the annual pass.
- **"Foreign person" is a per-state ruling, deferred.** The resolver applies the rate; the eligibility/exemption determination (PR, SCV, temp resident) is confirmed with the state revenue office.

## Sources

State revenue offices, one per row of the table:

- Revenue NSW — *Surcharge purchaser duty overview* (guide: 9% from 1 Jan 2025, 8% 1 Jul 2017 – 31 Dec 2024, 4% 21 Jun 2016 – 30 Jun 2017; calculated on the dutiable value) — https://www.revenue.nsw.gov.au/property-professionals-resource-centre/guides-rulings-cpns/topics/surcharge-purchaser-duty-guide/overview (archived at docs/sources/nsw/surcharge-purchaser-duty-overview.txt)
- State Revenue Office Victoria — *Foreign purchaser additional duty (current rates)* ("1 July 2019, the additional duty rate is 8%") — https://www.sro.vic.gov.au/rates-taxes-duties-and-levies/foreign-purchaser-additional-duty-current-rates (archived at docs/sources/vic/foreign-purchaser-additional-duty-current-rates.txt)
- Queensland Revenue Office — *AFAD residential land toolkit* (8% from 1 Jul 2024; 7% 1 Jul 2018 – 30 Jun 2024; 3% 1 Oct 2016 – 30 Jun 2018) — https://qro.qld.gov.au/duties/self-assessors/toolkits/afad/ (archived at docs/sources/qld/afad-residential-land-toolkit.txt)
- Queensland Revenue Office — *Assessing and calculating AFAD* (a foreign acquirer may claim a home concession on transfer duty; AFAD is still paid) — https://qro.qld.gov.au/duties/investors/afad/assessing/ (archived at docs/sources/qld/afad-assessing-and-calculating.txt)
- WA Government (RevenueWA) — *Foreign transfer duty* ("Additional duty of 7% applies when foreign persons purchase residential property.") — https://www.wa.gov.au/government/publications/foreign-transfer-duty (archived at docs/sources/foreign-buyer-surcharge/wa-foreign-transfer-duty.txt)
- RevenueSA — *Foreign ownership surcharge* (7%) — https://revenuesa.sa.gov.au/stamp-duty/foreign-ownership-surcharge (not archived: 403 to scripted fetches)
- State Revenue Office Tasmania — *Foreign investor duty surcharge — rates of surcharge* (8% residential from 1 Apr 2020; 1.5% primary-production) — https://sro.tas.gov.au/property-transfer-duties/foreign-investor-duty-surcharge/rates-of-surcharge (not archived: certificate fails curl)
- ACT Revenue Office — *Conveyance duty (stamp duty)* (names no foreign purchaser duty surcharge) — https://www.revenue.act.gov.au/rates-and-property-charges/conveyance-duty-stamp-duty (archived at docs/sources/act/conveyance-duty-stamp-duty.txt); *Foreign ownership surcharge for land tax* (0.75% of AUV a year, an annual land tax, not a duty) — https://www.revenue.act.gov.au/rates-and-property-charges/land-tax/foreign-ownership-surcharge-for-land-tax (archived at docs/sources/act/foreign-ownership-surcharge-land-tax.txt)
- NT — PLACEHOLDER: no primary read this pass; re-ground on the Territory Revenue Office's stamp-duty pages on treasury.nt.gov.au.
