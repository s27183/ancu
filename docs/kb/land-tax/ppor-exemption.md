---
slug: kb.land-tax.ppor-exemption
effective_from: 2025-01-01
last_verified: 2026-06-28
---

# Land tax — the principal-place-of-residence exemption

**Land tax** is an annual **state** tax on the value of land an owner holds. The land a person **lives in as their home is exempt** — the **principal place of residence (PPR / PPOR) exemption**, called the **home exemption** in Queensland. For a Mode A owner-occupier first-home buyer the answer is therefore almost always **exempt**; this doc owns **the PPOR exemption rules per state, the conditions to hold it, and the trigger that makes land tax apply** (the home ceasing to be the owner's residence). It grounds `ownership_planning.annual_obligations.land_tax_check` (enum: `exempt_ppor | applicable | to_verify`, default `exempt_ppor`) — informationally; the exemption is not financial advice but a statutory fact to confirm with the revenue office.

## The PPOR exemption, by state

Each state exempts the owner's home from land tax. The occupancy conditions differ:

- **NSW (Revenue NSW).** The land must be **used and occupied as the owner's principal place of residence**, continuously since **1 July before the taxing date (31 December)**. The owner must be a **natural person** (not a company or special trust) and, from the **2025 land tax year**, must hold **at least a 25% interest** in the land. Only **one** property worldwide can be the PPR.
- **VIC (State Revenue Office).** The owner (or eligible trust beneficiary) must **live on the land for at least 6 months** from 1 July of the year before the assessment. A **dual-PPR exemption** covers the year you buy a new home and still hold the old one — **both are exempt** for that assessment year.
- **QLD (Queensland Revenue Office).** A **home exemption** applies to the land you own and occupy as your home; its value is **excluded** when working out whether you exceed the land-tax threshold.

## When land tax *does* apply — the lifecycle trigger

The home stops being exempt if it **stops being the owner's principal residence** — most commonly when the owner **moves out and rents it** (it becomes an investment) or it is otherwise not occupied as a home. Land tax then applies to that land once the owner's total **non-exempt** land value reaches the state threshold:

- **NSW** general threshold **$1,075,000** of land value (fixed from 2025; frozen by the 2024–25 Budget).
- **VIC** threshold **$50,000** of land value (**$25,000** for trusts) since 1 January 2024 — far lower than before, so even modest non-exempt land can attract VIC land tax.
- **QLD** threshold **$600,000** of taxable land value for individuals.
- **WA** threshold **$300,000** of aggregated taxable land value (plus a separate metro improvement levy above the same figure).
- **TAS** threshold **$125,000** of aggregated land value.

Most states also offer an **absence concession** — you can be temporarily away and keep the PPOR exemption for a limited period (rules vary by state). The **detailed non-PPOR rates and the investor treatment** are out of scope for a Mode A owner-occupier; they belong to the investor blueprints' land-tax handling — this doc owns the exemption and the loss-of-exemption trigger.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The base case is `exempt_ppor`.** A Mode A FHB buying a home to live in pays **no land tax** on it — the plan states this plainly rather than leaving the line ambiguous.
- **The trap is the lifecycle move.** Many Mode A owners later move (upgrade, or relocate) and **keep the first home as a rental** — at which point it becomes **investment land** and land tax can apply, especially in **VIC** with its $50k threshold. The platform **arms an alert** so a future mode-switch to investor surfaces the land-tax obligation rather than letting it ambush the owner.
- **Information, not advice.** The plan states the exemption and the trigger and points to the revenue office to confirm; it does not compute a binding assessment.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `land_tax_check` is **resolver-derived**: `exempt_ppor` while the property is the owner's PPOR, `applicable`/`to_verify` once it is not, evaluated against these per-state rules.

```jsonc
{
  "fills": [],
  "parameters": {
    "ppor_exempt_all_states":        { "type": "bool", "value": true, "note": "REGULATED — the owner's principal place of residence (QLD: 'home') is exempt from land tax in NSW, VIC and QLD; the Mode A owner-occupier default is exempt_ppor" },
    "nsw_ppor_occupancy_from":       { "type": "string", "value": "continuous since 1 July before the 31 December taxing date; natural person; ≥25% interest from the 2025 land tax year", "note": "REGULATED (Revenue NSW) — NSW PPR exemption conditions; only one PPR worldwide" },
    "vic_ppor_min_occupancy_months": { "type": "integer", "value": 6, "note": "REGULATED (SRO VIC) — must live on the land ≥6 months from 1 July before assessment; dual-PPR exemption covers the upgrade year (old + new both exempt)" },
    "qld_home_exemption":            { "type": "bool", "value": true, "note": "REGULATED (QRO) — QLD home exemption; the home's value is excluded from the land-tax threshold test" },
    "nsw_general_threshold_aud":     { "type": "money", "value": 1075000, "note": "REGULATED (Revenue NSW) — general land-value threshold above which NON-exempt land attracts land tax; fixed from 2025, frozen by the 2024–25 Budget" },
    "vic_threshold_aud":             { "type": "money", "value": 50000,   "note": "REGULATED (SRO VIC) — non-exempt land-value threshold ($25,000 for trusts) since 1 Jan 2024; low, so a rented former home readily attracts VIC land tax" },
    "qld_threshold_individual_aud":  { "type": "money", "value": 600000,  "note": "REGULATED (QRO) — taxable land-value threshold for individuals above which non-exempt land attracts QLD land tax" },
    "wa_general_threshold_aud":      { "type": "money", "value": 300000,  "note": "REGULATED (Treasury & Finance WA, primary-verified 2026-06-28) — aggregated taxable land-value threshold above which non-exempt land attracts WA land tax (a separate metro improvement levy also applies above this figure); same general threshold as kb.tax.land-tax-by-state. Feeds the Mode-A mode-switch alert" },
    "tas_general_threshold_aud":     { "type": "money", "value": 125000,  "note": "REGULATED (SRO Tasmania, primary-verified 2026-06-28) — aggregated land-value threshold above which non-exempt land attracts TAS land tax; same general threshold as kb.tax.land-tax-by-state. Feeds the Mode-A mode-switch alert" },
    "loss_of_exemption_trigger":     { "type": "string", "value": "property ceases to be the owner's principal residence (typically: owner moves out and rents it → investment land)", "note": "the lifecycle trigger flipping land_tax_check from exempt_ppor to applicable; arms a mode-switch alert" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `land_tax_check` is resolver-derived from PPOR status against these rules — `exempt_ppor` for the owner-occupier base case. The doc supplies the per-state rules and the loss trigger, not a verdict.
- **REGULATED, per-state — verified against the revenue offices.** The exemption conditions and the non-exempt thresholds are statutory and were confirmed against Revenue NSW, SRO VIC and QRO directly (see Sources). FY/calendar-year-stamped: NSW assessed at 31 December, QLD at 30 June, VIC at midnight 31 December; thresholds current as listed. The **WA ($300,000) and TAS ($125,000) general thresholds** were added 2026-06-28 (primary-verified against Treasury & Finance WA and SRO Tasmania) so the mode-switch alert names a concrete threshold in those states too; they carry the same figure as `kb.tax.land-tax-by-state` (two Mode-scoped copies — exemption-side here, investor-scale-side there — both freshness-tracked).
- **Scope discipline.** The exemption and its loss-trigger are owned here (what a Mode A owner needs). The **full non-PPOR land-tax rate scales and investor structuring** are out of scope for Mode A and belong to the investor blueprints — not duplicated here. Surcharge land tax for foreign persons is a FIRB-adjacent matter for Modes B/D, not Mode A.
- **The VIC $50k threshold is the load-bearing trap.** It is low enough that a Mode A owner who later rents out the first home can attract VIC land tax on a modest block — captured explicitly so the mode-switch alert fires rather than surprising the owner.

## Sources

**Canonical (state revenue offices):**

- Revenue NSW — *Land tax exemption for principal place of residence* (occupancy from 1 July before the taxing date; natural person; ≥25% interest from 2025; one PPR worldwide) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/exemptions-and-concessions/principal-place-of-residence
- Revenue NSW — *Land tax thresholds and rates* (general threshold $1,075,000, fixed from 2025) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/understanding-land-tax/thresholds-and-rates
- State Revenue Office Victoria — *Principal place of residence exemption* (live on the land ≥6 months; dual-PPR exemption on upgrade) — https://www.sro.vic.gov.au/land-tax/principal-place-of-residence-exemption
- State Revenue Office Victoria — *Land tax current rates* (threshold $50,000; $25,000 for trusts, since 1 Jan 2024) — https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-tax-current-rates
- Queensland Revenue Office — *Land tax home exemption for individuals* (home exemption; liable when total taxable value ≥ $600,000) — https://qro.qld.gov.au/land-tax/relief/home-exemption-individuals/
- Department of Treasury and Finance WA — *Land tax assessment* (aggregated land-value threshold $300,000; metro improvement levy above the same figure) — https://www.wa.gov.au/organisation/department-of-treasury-and-finance/land-tax-assessment
- State Revenue Office Tasmania — *Rates of land tax* (general threshold $125,000) — https://www.sro.tas.gov.au/land-tax/rates-of-land-tax
