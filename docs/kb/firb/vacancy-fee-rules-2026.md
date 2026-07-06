---
slug: kb.firb.vacancy-fee-rules-2026
effective_from: 2017-05-09
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2024-08/gn-10-fees-fi-apps-aug-2024.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn10-fees-fi-apps-v5-aug-2024.pdf
---

# FIRB — annual vacancy fee (the regime)

This doc owns the **annual vacancy fee regime**: when a foreign owner is liable, what counts as occupied/genuinely available, the vacancy year, the return obligation, and the lodgement trap. It grounds the `ownership_planning` component (vacancy-fee monitoring) and the plan's ongoing-obligations surface. It owns the **regime**; the **doubling from 9 April 2024** is owned by [`kb.firb.vacancy-fee-double-from-2024`](vacancy-fee-double-from-2024.md), and the **dollar figures** by [`kb.firb.fee-schedule-current`](fee-schedule-current.md) — this doc states the *rule*, not the amounts.

## When the vacancy fee applies

Under **Part 6A of the FATA**, an annual vacancy fee is levied on a foreign owner of a residential dwelling if the dwelling is **not residentially occupied, and not genuinely available on the rental market, for at least 183 days (about six months) in a 12-month vacancy year.**

It applies to:

- foreign persons who made a foreign-investment application for residential land **on or after 7:30pm AEST 9 May 2017**; and
- foreign persons who bought a dwelling under a developer's **New (or Near-New) Dwelling Exemption Certificate** applied for by the developer on or after that time ([`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md)).

## What counts as occupied / genuinely available

A dwelling is treated as residentially occupied **or** genuinely available for rent if, in the vacancy year, it can be proven that:

- the owner (or a relative) genuinely occupied it as a residence; **or**
- it was genuinely occupied as a residence under a **lease or licence with a term of at least 30 days**; **or**
- it was made genuinely available on the rental market under a **contract term of at least 30 days**.

**Short-term lets of fewer than 30 days do not count** — including web-based vacation-rental sites. A property let only as short-stay accommodation is **not** genuinely available for the purpose of the fee, even if its total occupied days exceed 183 (the 183 days must be made up of qualifying ≥30-day periods).

## The vacancy year and the return

- The **vacancy year** is the 12-month period starting on the **first day the owner acquires the right to occupy** the property (typically the settlement date, or the date an occupancy certificate issues for a new build).
- The owner must **lodge an annual vacancy fee return** within **30 days of the end of each vacancy year**, stating whether the property met the 183-day test.
- Returns are lodged electronically via the ATO; lodgement requires the property to be on the **Register of Foreign Ownership** (the Register reference number is needed to lodge).

## The lodgement trap

**Failing to lodge the return on time makes the owner liable for the vacancy fee even if the dwelling was occupied for more than 183 days.** The return is not optional paperwork — non-lodgement is itself the trigger for the fee. The plan arms a vacancy-declaration reminder against each vacancy-year end for this reason.

## The amount

The fee amount is **derived, not flat**: it equals the foreign-investment **application fee** for that purchase (doubled for vacancy years starting on or after 9 April 2024 — [`kb.firb.vacancy-fee-double-from-2024`](vacancy-fee-double-from-2024.md)). The dollar figures live in [`kb.firb.fee-schedule-current`](fee-schedule-current.md). Where the original application fee was waived, the vacancy fee falls back to a fixed Fees-Regulations amount (≈A$29,400 per *GN 10 v5*, 2 Aug 2024 — ⚠ **this figure indexes each 1 July and has not been re-grounded since GN 10 v5; confirm the current Fees-Regulations amount before quoting** — owned by the fee schedule). This doc states only that the fee is application-fee-linked; it asserts no dollar figure.

## Rules

Pure-reference (`fills: []`). The `ownership_planning` resolver reads the property's occupancy plan + the application-fee figure and projects the vacancy-fee-at-risk amount + arms the return reminder; this doc supplies the grounded regime. No leaf asserted; the only figures referenced live in their owners.

```jsonc
{
  "fills": [],
  "parameters": {
    "vacancy_fee_levied_under_part_6a": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "Part 6A FATA — annual vacancy fee on foreign owners of residential dwellings." },
    "occupancy_threshold_days": { "type": "int", "value": 183, "provenance": "REGULATED", "note": "liable unless residentially occupied OR genuinely available for rent for at least 183 days in the vacancy year." },
    "qualifying_tenancy_min_term_days": { "type": "int", "value": 30, "provenance": "REGULATED", "note": "occupancy/availability counts only via lease/licence/contract terms of at least 30 days; short-stay <30 days (incl. web vacation rentals) does not count." },
    "applies_from_application_date": { "type": "string", "value": "2017-05-09T19:30:00+10:00", "provenance": "REGULATED", "note": "applies to foreign-investment applications made on/after 7:30pm AEST 9 May 2017, and to developer-exemption-certificate purchases applied for on/after that time." },
    "vacancy_year_starts_at_right_to_occupy": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 12-month vacancy year starts on the first day the owner acquires the right to occupy (settlement or occupancy-certificate date)." },
    "return_due_days_after_vacancy_year": { "type": "int", "value": 30, "provenance": "REGULATED", "note": "the annual vacancy fee return is due within 30 days of the end of each vacancy year (s115C(3) FATA)." },
    "register_reference_required_to_lodge": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "lodgement requires the property to be on the Register of Foreign Ownership (Register reference number needed)." },
    "non_lodgement_triggers_fee_regardless": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "failing to lodge on time makes the owner liable for the fee even if occupied >183 days — the trap the plan's reminder guards against." },
    "amount_is_application_fee_linked": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the fee equals the application fee (doubled from 9 Apr 2024 — kb.firb.vacancy-fee-double-from-2024); dollar figures owned by kb.firb.fee-schedule-current; no figure asserted here." }
  }
}
```

Notes:

- **Single-owner.** The doubling cutover → [`kb.firb.vacancy-fee-double-from-2024`](vacancy-fee-double-from-2024.md); the dollar amounts → [`kb.firb.fee-schedule-current`](fee-schedule-current.md); the developer-certificate path → [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md); the post-approval condition catalogue (which references this fee) → [`kb.firb.approval-conditions-typical`](approval-conditions-typical.md). This doc owns the **regime** (trigger, test, vacancy year, return, lodgement trap).
- **Removed-from-reach.** No dollar figure is stated here; the fee is expressed as application-fee-linked so it cannot drift when fees reindex. The agent never emits a vacancy-fee dollar amount — the resolver computes it from the fee-schedule figure.
- **Decision-support framing.** Informational; the owner confirms their specific liability via the ATO vacancy fee return.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025), §J Vacancy fees — Part 6A, 183-day test, ≥30-day qualifying terms, 12-month vacancy year, 30-day return — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 10: Fees on foreign investment applications*, Version 5 (2 August 2024), §G Vacancy fees — non-lodgement makes the fee payable regardless; amount is application-fee-linked — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2024-08/gn-10-fees-fi-apps-aug-2024.pdf
- Foreign Acquisitions and Takeovers Act 1975 (Cth), Part 6A; s115C(3) — vacancy fee and annual return — https://www.legislation.gov.au/C2004A00289/latest/text
