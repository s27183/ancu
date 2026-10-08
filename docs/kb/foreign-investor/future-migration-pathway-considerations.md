---
slug: kb.foreign-investor.future-migration-pathway-considerations
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-6-residential-land-v3.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/guidance-note-6-residential-land-v3.pdf
    note: "FIRB GN6 v3 — Australian permanent residents and citizens are NOT foreign persons; acquiring PR/citizenship removes the foreign-person restrictions. Confirms the mode-switch trigger this doc owns. (Tax-residency change follows the separate ATO residency test, as the doc states.)"
---

# Future migration pathway — the Mode-D mode-switch structural doc

This doc owns the **mode-switch consequence** when a Mode-D investor's residency status changes — the Mode-D analogue of Mode B's `pr_grant_event_triggers_mode_switch` and Mode C/D's shared investor-status continuity. It grounds `investment_strategy` (component 4) forward-looking reasoning and `ownership_planning_foreign_investor`'s lifecycle-alert surface. It asserts no new regulated figure — it names the trigger and points to the individual docs that already carry each consequence, mirroring the design Mode B established.

## The trigger and what changes

A Mode-D investor who is granted **Australian permanent residency or citizenship** stops being a "foreign person" for FIRB purposes and a "foreign resident for tax" for ATO purposes (subject to the ordinary residency tests — the trigger is the **grant**, but the tax-residency change follows the ATO's own residency test, not automatically the same date). When that happens, a cluster of Mode-D-specific constraints and costs **fall away for future transactions and future tax years** — but do **not** retroactively change what already happened:

- **FIRB approval, fee, and the established-dwelling ban no longer apply** to a *future* purchase — [`kb.firb.status-determination`](../firb/status-determination.md), [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md). The property already held does not need re-approval; a new acquisition after the grant does not need FIRB approval at all.
- **The foreign-buyer stamp-duty surcharge no longer applies** to a *future* purchase — [`kb.foreign-buyer-surcharge.by-state`](../foreign-buyer-surcharge/by-state.md).
- **The state land-tax foreign/absentee surcharge stops accruing** from the point residency status changes (state-specific timing; the *general* land-tax position, aggregated across all AU land held, continues regardless) — [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md).
- **The CGT discount becomes available for the resident period going forward.** [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md)'s foreign-resident apportionment means the discount is unavailable *for the portion of the gain accruing while a foreign/temporary resident* — a later disposal, after a sustained period of Australian tax residency, can access the discount for that later span. The pre-grant, foreign-resident-period gain remains undiscounted; this is an apportionment, not a clean switch.
- **FRCGW no longer applies at a future sale**, once the investor can supply a **clearance certificate** as an Australian resident for tax at the time of that sale — [`kb.non-resident-tax.foreign-resident-cgt-withholding`](../non-resident-tax/foreign-resident-cgt-withholding.md).
- **The vacancy fee's foreign-owner basis and the entity-structuring restrictions (SMSF residency, FIRB look-through) fall away** — [`kb.firb.vacancy-fee-rules-2026`](../firb/vacancy-fee-rules-2026.md), [`kb.non-resident.entity-options-au-property`](../non-resident/entity-options-au-property.md).

## What does not change

- **Nothing about the property itself, or the acquisition, is retroactively altered.** The FIRB approval, surcharge, and non-resident tax treatment applying at purchase and during the foreign-resident holding period stand; the mode-switch affects the treatment of **future** events (a later sale, a later purchase, a later tax year), not the historical ones.
- **The investor's mode does not automatically become Mode C.** The blueprint's `blueprint_for/1` dispatch is onboarding-time; an existing Mode-D plan card does not silently re-platform to `investor-domestic-au` on a residency change within this wedge's scope — a Mode-switch UX (offering the migration) is the same **design-first, not-in-this-wedge** item the blueprint's own open questions already name (see `mode-d-wedge.md`'s open seams — "mode-switch on PR grant").

## Relevance for Vietnam-located investors (Mode D)

- **The plan names the trigger and its forward-looking consequences without asserting a re-computed history.** A residency-status change is good news for future costs and eligibility; the plan should say so plainly, without implying the foreign-resident-period tax outcomes are undone.
- **Migration status is a genuine investment-thesis input**, not just a compliance fact — an investor actively pursuing a migration pathway (e.g. an existing skilled-visa or partner pathway) may reasonably weight a longer hold horizon differently than one with no such pathway, since the FIRB/surcharge/discount picture materially improves post-grant. The plan can name this as a consideration without predicting or advising on immigration outcomes (an immigration question, out of this platform's scope entirely).
- **Information, not advice — and not immigration advice.** The plan states the tax/FIRB consequence of a residency-status change; it makes no immigration-pathway recommendation and does not assess migration eligibility.

## Rules

Pure-reference (`fills: []`). No leaf is set by this doc; it grounds a qualitative lifecycle alert (`ownership_planning_foreign_investor.lifecycle_alerts` — mirrors Mode B's `pr_grant_event_triggers_mode_switch` shape) that names the trigger and cross-references the docs each individual consequence lives in.

```jsonc
{
  "fills": [],
  "parameters": {
    "pr_or_citizenship_grant_is_the_trigger": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the mode-switch trigger is the residency/citizenship grant; the tax-residency change follows the ATO's own residency test, not automatically the same date." },
    "consequences_are_forward_looking_not_retroactive": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FIRB/surcharge/FRCGW/vacancy-fee relief and CGT-discount availability apply to future transactions and future tax years; the foreign-resident-period treatment already applied is not undone." },
    "cgt_discount_apportioned_not_switched": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "owned by kb.tax.cgt-50-percent-discount — the discount becomes available only for the gain accruing during the resident period going forward, an apportionment not a clean switch for a later disposal." },
    "mode_switch_ux_design_first_not_this_wedge": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "an existing Mode-D plan card does not auto-reclassify to Mode C on a residency change within this wedge's scope — the UX to offer the migration is a named open seam, design-first." },
    "not_immigration_advice": { "type": "bool", "value": true, "provenance": "POLICY", "note": "the plan states the tax/FIRB consequence of a residency change; it makes no immigration-pathway recommendation or eligibility assessment." }
  }
}
```

Notes:

- **No `fills`.** A structural/lifecycle-alert doc; every individual consequence is single-owned by its own doc and cross-referenced, not restated with a figure here.
- **Mirrors Mode B's mode-switch design**, adapted: Mode B switches an owner-occupier's exemption/discount treatment (Mode B → Mode A); Mode D switches an investor's FIRB/surcharge/discount/withholding treatment for future transactions (Mode D → an unconstrained investor position — not necessarily a full Mode-C re-platform within this wedge).

## Sources

None directly — this is a synthesis/lifecycle-alert doc. See the Sources section of each cross-referenced doc for the primary citation behind each individual consequence.
