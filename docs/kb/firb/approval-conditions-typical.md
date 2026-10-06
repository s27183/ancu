---
slug: kb.firb.approval-conditions-typical
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/guidance/types-investments/residential-land
    retrieved: 2026-07-06
---

# FIRB — typical approval conditions

This doc owns the **conditions a No Objection Notification typically carries** — what the approval *obliges the foreign buyer to do after* it issues. It grounds the `firb_workflow` post-approval obligation surface (component 4) and the plan's settlement-and-after sequencing. It does **not** own the **approval process** ([`kb.firb.application-process`](application-process.md)), the **vacancy fee** (`kb.firb.vacancy-fee-rules-2026`, Cluster R4), or the **consequences of breaching a condition** ([`kb.firb.penalties-non-compliance`](penalties-non-compliance.md)) — each is its own owner; this doc is the catalogue of the conditions themselves.

## The principle — conditions vary by property type

The Treasurer may impose **any** condition considered necessary to protect the national interest; all applications are decided **case-by-case**, so actual conditions vary. The catalogue below is the *common* set by property type — informational, not a guarantee for a specific approval.

## New (or near-new) dwellings — usually light

Approval for a **new dwelling** is **not usually subject to ongoing conditions** beyond the purchase price being no greater than the value specified in the approval. Once acquired, there are generally no ongoing restrictions on use — the foreign person may occupy it or rent it out. (A **vacancy fee return** obligation still applies — owned by `kb.firb.vacancy-fee-rules-2026`, R4.)

## Vacant residential land — the construction obligations

This is the conditioned case. An approval to buy **vacant residential land** is generally granted subject to:

- the **purchase price** being no greater than the value specified in the approval;
- **at least one residential dwelling being built** on the land;
- **construction of all dwelling(s) completed within four years** from the date of notice of approval;
- **evidence of completion submitted to the Government within 30 days** of being received (e.g. a certificate of fitness for occupancy/use, final occupancy, or builder's completion certificate); and
- the foreign person **not selling, transferring, or otherwise disposing of the interest before construction is complete** (no "land banking").

Once developed, there are generally no ongoing conditions on use. There is no limit on the number of vacant parcels a foreign person can acquire for residential development.

## Registration obligation (all approved acquisitions)

A foreign person who acquires an interest in Australian residential land must **register the acquisition on the Register of Foreign Ownership of Australian Assets**. This is a standing obligation distinct from the approval conditions above.

## Rules

Pure-reference (`fills: []`). The resolver attaches the applicable condition set to the plan by property type (`new_dwelling` → light; `vacant_land` → construction obligations) and sequences the deadlines; this doc supplies the grounded catalogue. No leaf asserted; the durations (4 years, 30 days) are regulated periods placed by the resolver, not money figures.

```jsonc
{
  "fills": [],
  "parameters": {
    "new_dwelling_usually_no_ongoing_conditions": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a new dwelling approval is not usually subject to ongoing conditions beyond the price cap; use is unrestricted (occupy or rent). Vacancy fee return still applies (R4)." },
    "vacant_land_construction_years": { "type": "integer", "value": 4, "provenance": "REGULATED", "note": "vacant residential land must have all dwelling(s) construction completed within 4 years of the date of notice of approval." },
    "vacant_land_no_disposal_before_completion": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the foreign person must not sell/transfer/dispose of vacant land before construction is complete (anti land-banking)." },
    "completion_evidence_days": { "type": "integer", "value": 30, "provenance": "REGULATED", "note": "evidence of completion (occupancy/builder's certificate) must be submitted to the Government within 30 days of receipt." },
    "register_of_foreign_ownership_required": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "an acquired interest must be registered on the Register of Foreign Ownership of Australian Assets — a standing obligation, separate from the case-specific conditions." },
    "conditions_are_case_by_case": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the Treasurer may impose any condition necessary for the national interest; the catalogue is the common set, not a guarantee for a specific approval." }
  }
}
```

Notes:

- **Single-owner.** The approval that carries these conditions → [`kb.firb.application-process`](application-process.md); the vacancy-fee return → `kb.firb.vacancy-fee-rules-2026` (R4); what happens if a condition is breached → [`kb.firb.penalties-non-compliance`](penalties-non-compliance.md). This doc owns only the **condition catalogue**.
- **Conditions are obligations the plan must track to deadline.** The 4-year construction clock and the 30-day evidence window are calendar items the resolver places on the plan's timeline, not disclaimers — a breach is a penalty event ([`kb.firb.penalties-non-compliance`](penalties-non-compliance.md)).
- **Decision-support framing.** The authoritative conditions are those written into the specific No Objection Notification; this is the common-case catalogue.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025) — approval conditions for new dwellings (usually none ongoing) and vacant land (build ≥1 dwelling, complete within 4 years, evidence within 30 days, no disposal before completion); case-by-case condition principle; Register of Foreign Ownership — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
- Foreign Investment in Australia (Treasury/FIRB) — *Principles for Developing Conditions Guidance Note* (the Treasurer may impose any condition necessary for the national interest) — https://foreigninvestment.gov.au/guidance/conditions-and-reporting
