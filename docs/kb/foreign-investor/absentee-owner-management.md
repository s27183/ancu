---
slug: kb.foreign-investor.absentee-owner-management
effective_from: 2025-07-01
last_verified: 2026-07-03
---

# Managing the property from Vietnam — the absentee-owner overlay

This doc owns the **remote-management practicalities and the compounding compliance surface** for an owner who cannot readily visit the property — the Mode-D delta on top of the domestic property-management decision. The management-model decision itself (professional PM vs self-managed) is owned by [`kb.investor.property-management-vs-self-managed`](../investor/property-management-vs-self-managed.md) and is **not** duplicated here; this doc states why that decision tilts differently for a Vietnam-located owner, and consolidates the compliance obligations "absentee" already triggers elsewhere in the KB. It grounds `ownership_planning_foreign_investor` (component 11) `property_management` and the vacancy-fee / absentee-surcharge ongoing-obligations surface.

## The decision tilts toward professional management — but is not mandated

[`kb.investor.property-management-vs-self-managed`](../investor/property-management-vs-self-managed.md) already names "distance... makes professional management close to necessary" as a general trade-off. For a Vietnam-located owner the distance is total, not just interstate — self-management (inspections, urgent repairs, tenant meetings, tribunal appearances if a dispute arises) is not practically available in person. This is decision-support, not a rule: a professional PM is the practical default for a genuinely absentee owner, and the plan states the reasoning rather than asserting it as mandatory.

## "Absentee" is already a defined, cost-bearing status elsewhere — this doc consolidates it

Several already-built anchors trigger specifically on **absentee** status, independent of the property-management decision itself; the investor should see them **together**, not discover them one at a time:

- **State land-tax absentee/foreign surcharge** — [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) already carries NSW (5%, as the FIRB foreign surcharge), VIC (4% absentee owner surcharge), QLD (3% absentee surcharge ≥ $350,000), and TAS (2% FILTS) as per-state figures, on top of ordinary land tax.
- **FIRB annual vacancy fee** — [`kb.firb.vacancy-fee-rules-2026`](../firb/vacancy-fee-rules-2026.md): the 183-day occupied-or-genuinely-available test, and critically the **lodgement trap** (failing to lodge the annual return triggers the fee even if the property was actually occupied ≥183 days) — an absentee owner is the buyer most likely to miss this deadline precisely because they are not physically present to be reminded of it by routine property contact.
- **Documentation for remote instruction** — a genuinely absentee owner typically needs a **power of attorney** (or equivalent authority arrangement) so a trusted AU-based person (the property manager, a family member, or a solicitor) can sign routine documents, receive notices, or act in an emergency without the owner's physical presence or same-day signature. This is a practical/legal-structuring consideration the plan surfaces; it is not a recommendation of a specific POA form or a substitute for legal advice on executing one validly.

## Relevance for Vietnam-located investors (Mode D)

- **Professional PM is the practical default, not asserted as mandatory.** The plan states the distance-driven reasoning and lets the investor decide, per the base management-decision doc's own decision-support discipline.
- **The absentee-triggered costs and deadlines are shown together**, so the plan does not let the vacancy-fee lodgement trap or the land-tax surcharge surface as a surprise discovered one anchor at a time.
- **A POA / remote-authority arrangement is named as a practical need**, not asserted as legally required — the plan points to a solicitor for the actual instrument.
- **Information, not advice.** No specific PM, solicitor, or POA form is recommended.

## Rules

Pure-reference (`fills: []`). This is a decision-support/consolidation doc — it fills no slot; `ownership_planning_foreign_investor`'s `property_management` reasoning and lifecycle alerts read this doc to surface the distance-driven PM lean and the absentee-triggered obligations together, each figure still resolver-drawn from its own owning doc.

```jsonc
{
  "fills": [],
  "parameters": {
    "professional_pm_practical_default_for_absentee": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "distance-driven decision-support lean toward professional PM for a genuinely absentee (Vietnam-located) owner, per the general trade-off already in kb.investor.property-management-vs-self-managed; not mandated." },
    "absentee_obligations_surfaced_together": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "consolidates land-tax absentee surcharge (kb.tax.land-tax-by-state) + FIRB vacancy fee/lodgement trap (kb.firb.vacancy-fee-rules-2026) so an absentee owner sees the compounding compliance surface at once, not anchor-by-anchor." },
    "vacancy_fee_lodgement_trap_elevated_risk_for_absentee": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "an owner not physically present for routine property contact is more likely to miss the annual vacancy-fee return deadline that kb.firb.vacancy-fee-rules-2026 already flags as a trap regardless of actual occupancy." },
    "poa_or_remote_authority_named_as_practical_need": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a genuinely absentee owner typically needs an AU-based person authorised to act on routine/emergency matters; the plan names the need, points to a solicitor for the instrument, and does not recommend a specific form." }
  }
}
```

Notes:

- **No `fills`.** Consolidates already-owned figures/obligations for the absentee case; introduces no new dollar figure.
- **Single-owner via cross-ref.** Management-model decision → `kb.investor.property-management-vs-self-managed`; land-tax absentee surcharges → `kb.tax.land-tax-by-state`; vacancy fee regime/lodgement trap → `kb.firb.vacancy-fee-rules-2026`. This doc owns only the *absentee-specific consolidation + POA consideration*.

## Sources

- ASIC Moneysmart — *Property investment* (using a property manager; distance and time considerations) — https://moneysmart.gov.au/property-investment
- NSW Fair Trading / relevant state consumer-affairs body — *Powers of attorney* (POA as the mechanism for a remote owner to authorise an AU-based person to act) — https://www.nsw.gov.au/family-and-relationships/powers-of-attorney

See also the Sources sections of `kb.tax.land-tax-by-state` and `kb.firb.vacancy-fee-rules-2026` for the primary citations behind the absentee-triggered figures consolidated above.
