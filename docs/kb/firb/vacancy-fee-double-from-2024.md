---
slug: kb.firb.vacancy-fee-double-from-2024
effective_from: 2024-04-09
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2024-08/gn-10-fees-fi-apps-aug-2024.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn10-fees-fi-apps-v5-aug-2024.pdf
---

# FIRB — vacancy fee doubled from 9 April 2024

This doc owns the **2024 doubling rule**: the multiplier that turns a foreign owner's application fee into their vacancy fee, and the cutover date that selects it. It grounds the `ownership_planning` vacancy-fee projection alongside the regime in [`kb.firb.vacancy-fee-rules-2026`](vacancy-fee-rules-2026.md). It owns the **multiplier and the cutover**; the **regime** (who is liable, the 183-day test, the return) is owned by the rules doc, and the **dollar figures** by [`kb.firb.fee-schedule-current`](fee-schedule-current.md).

## The rule

The vacancy fee is the foreign-investment **application fee**, multiplied by:

- **2× (double)** — for vacancy years **starting on or after 9 April 2024**; or
- **1× (equal)** — for vacancy years starting **before** 9 April 2024.

For a dwelling bought under a developer's exemption certificate (where the buyer paid no individual application fee), the same applies to the application fee that **would have** been payable had the dwelling not been covered by the certificate ([`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md)).

## The non-obvious part: the cutover is on the *vacancy year*, not the purchase

The doubling keys off **when the vacancy year starts**, not when the property was bought. So a foreign owner who purchased **before** 9 April 2024 still pays the **doubled** fee for any vacancy year that starts on or after that date. The doubling is not limited to new purchases — it reaches existing foreign-held dwellings on their next vacancy-year roll. This is the fact a buyer most often gets wrong, and the reason this rule has its own owner rather than living as a footnote to the amount.

## The amount stays application-fee-linked

This doc supplies the **multiplier** only. The application-fee dollar figures (which set the base the multiplier applies to) live in [`kb.firb.fee-schedule-current`](fee-schedule-current.md), and reindex annually — so the doubled vacancy fee changes with them. The resolver computes `vacancy_fee = multiplier × application_fee_for_tier`; no dollar figure is asserted here.

## Rules

Pure-reference (`fills: []`). The `ownership_planning` resolver selects the multiplier by the vacancy-year start date and applies it to the fee-schedule figure; this doc supplies the grounded multiplier rule. No leaf asserted; no dollar figure here.

```jsonc
{
  "fills": [],
  "parameters": {
    "doubling_cutover_date": { "type": "string", "value": "2024-04-09", "provenance": "REGULATED", "note": "vacancy years starting on/after this date use the 2× multiplier; earlier vacancy years use 1×." },
    "multiplier_on_or_after_cutover": { "type": "int", "value": 2, "provenance": "REGULATED", "note": "vacancy fee = 2× the original application fee for vacancy years starting on/after 9 Apr 2024." },
    "multiplier_before_cutover": { "type": "int", "value": 1, "provenance": "REGULATED", "note": "vacancy fee = the original application fee for vacancy years starting before 9 Apr 2024." },
    "cutover_keys_on_vacancy_year_not_purchase": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the doubling applies by vacancy-year start, so pre-9-Apr-2024 purchases also pay double for vacancy years starting on/after the cutover — not limited to new purchases." },
    "developer_certificate_uses_notional_fee": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "for exemption-certificate dwellings the multiplier applies to the application fee that would have been payable absent the certificate (kb.firb.exemption-certificates-developer)." },
    "amount_owned_by_fee_schedule": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the application-fee base (and thus the doubled figure) is owned by kb.firb.fee-schedule-current and reindexes; this doc supplies only the multiplier." }
  }
}
```

Notes:

- **Single-owner.** The regime (liability, 183-day test, vacancy year, return, lodgement trap) → [`kb.firb.vacancy-fee-rules-2026`](vacancy-fee-rules-2026.md); the dollar figures → [`kb.firb.fee-schedule-current`](fee-schedule-current.md); the developer-certificate path → [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md). This doc owns only the **multiplier and the cutover**.
- **Removed-from-reach.** The doc carries a multiplier (a stable regulated constant), not a dollar figure — so it is reindex-immune, the same split applied to penalty units in [`kb.firb.penalties-non-compliance`](penalties-non-compliance.md). The doubled dollar amount is computed by the resolver from the fee-schedule base.
- **Decision-support framing.** Informational; the ATO states the actual amount after the vacancy fee return is lodged.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 10: Fees on foreign investment applications*, Version 5 (2 August 2024), §G Vacancy fees — "for vacancy years starting on or after 9 April 2024 — double the amount of the original application fee" — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2024-08/gn-10-fees-fi-apps-aug-2024.pdf
- Foreign Acquisitions and Takeovers Fees Imposition Regulations 2020 (Cth), s67(2) — vacancy fee calculation — https://www.legislation.gov.au/F2020L00880/latest/text
