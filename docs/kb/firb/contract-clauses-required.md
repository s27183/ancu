---
slug: kb.firb.contract-clauses-required
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/guidance/types-investments/residential-land
    retrieved: 2026-07-06
---

# FIRB — pre-signing contract-clause checklist (due diligence)

This doc owns the **verification checklist**: before a foreign person signs a contract of sale, what FIRB-related terms must be confirmed present (or confirmed unnecessary). It grounds the `due_diligence` component (8). It owns the *pre-signing verification*; the **strategy** of whether to go conditional is owned by [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md), and the **anatomy of the condition** by [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md). This is the checklist that the conveyancer works through with the buyer; the engine surfaces it so the buyer knows what to check.

## The checklist

For a foreign person, due diligence on the contract has FIRB-specific items that a domestic buyer does not. Before signing, confirm:

- **Is FIRB approval needed at all?** If the dwelling is covered by a developer's New/Near-New Dwelling Exemption Certificate and under the $3M cap, no individual approval is required ([`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md)) — confirm the certificate and obtain a copy. Otherwise, an individual application is needed and the contract should be conditional.
- **Is the "subject to FIRB approval" condition present** (if not approve-then-sign)? Confirm the special condition exists, with an **approval-by date** that gives the ~30-day decision window room ([`kb.firb.timelines-standard`](timelines-standard.md)), a **termination right** on failure, and a clear **deposit-return position** — the anatomy in [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md).
- **Is the property an eligible type?** Confirm the property is a new dwelling / vacant land (not an established dwelling, which is banned — [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md), [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md)). A contract for an established dwelling is a hard stop regardless of clauses.
- **Auction vs private treaty.** Confirm whether the sale is by auction (generally unconditional — see [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md)); if so, approval should be in hand before bidding.
- **Settlement date vs approval window.** Confirm the settlement date leaves room for approval to issue first (especially off-the-plan, where slipped completion is the risk — [`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md)).

## What this checklist is *not*

- It is **not contract drafting**. The conveyancer/solicitor drafts and advises; this is the list of questions the buyer ensures are answered.
- It is **not the source-of-funds / AML checklist** — that is the bank's, owned by `kb.au-aml-ctf.source-of-funds-documentation` (Cluster X). The plan keeps the FIRB contract checklist and the bank's funds checklist separate ([`kb.firb.documents-required`](documents-required.md)).

## Rules

Pure-reference (`fills: []`). The `due_diligence` resolver/agent runs this checklist against the property facts + FIRB state and flags any missing confirmation; this doc supplies the grounded item list. No leaf asserted; the only figure referenced ($3M cap) lives in its owner.

```jsonc
{
  "fills": [],
  "parameters": {
    "check_whether_approval_needed_first": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "first confirm whether a developer exemption certificate covers the dwelling (no individual approval, under $3M); else the contract should be conditional (kb.firb.exemption-certificates-developer)." },
    "check_subject_to_firb_condition_present": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "confirm the subject-to-FIRB condition exists with approval-by date, termination right, and a clear deposit-return position (kb.foreign-buyer.subject-to-firb-clauses)." },
    "check_property_type_eligible": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "confirm the property is an eligible type (new/vacant, not a banned established dwelling) — a contract for an established dwelling is a hard stop (kb.firb.established-dwelling-ban)." },
    "check_settlement_leaves_room_for_approval": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "confirm the settlement date leaves room for approval to issue first; off-the-plan slipped-completion is the risk (kb.off-the-plan.risk-considerations)." },
    "checklist_is_not_drafting_or_aml": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this is a pre-signing verification checklist, not contract drafting (conveyancer's job) and not the bank's source-of-funds/AML checklist (Cluster X)." }
  }
}
```

Notes:

- **Single-owner.** The strategy → [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md); the clause anatomy → [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md); the developer-certificate path → [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md); eligibility → [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md). This doc owns only the **pre-signing checklist**.
- **The three contract docs form a chain:** decide the route (strategy) → understand the condition (anatomy) → confirm it before signing (this checklist). Each references the others; none restates.
- **Decision-support framing.** The buyer works the checklist *with* their conveyancer; the engine surfaces it so the buyer knows what to confirm, not as a substitute for legal review.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025) — approval required before the action; established-dwelling ban; conditional-contract route — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
- ATO — *Residential property application for foreign investors* (eligibility, application before acquiring) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
