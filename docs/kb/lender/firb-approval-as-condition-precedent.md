---
slug: kb.lender.firb-approval-as-condition-precedent
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2026-06/guidance-note-6-residential-land-v5.pdf
    retrieved: 2026-10-27
    path: docs/sources/firb/guidance-note-6-residential-land-v5.txt
    note: "\"Foreign persons generally require foreign investment approval before acquiring an interest in residential land, regardless of its value.\" Fn 3: a foreign person \"can enter into a contract as long as the contract is conditional on receiving foreign investment approval.\""
  - url: https://www.westpac.com.au/content/dam/public/brokers/documents/applications/wbc-minimum-required-documents-checklist.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/westpac-minimum-required-documents-checklist.txt
    note: "Westpac's own checklist, Section 5 Property Purchases — \"Temporary VISA Applicants\": \"Foreign Investment Review Board (FIRB) approval\""
---

# FIRB approval as a condition precedent to the loan

This doc owns the **loan-side FIRB gate** — how a foreign person's mortgage sequences around FIRB approval. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically the `firb_gate` block (`firb_approval_must_precede_unconditional_offer`, `lender_requires_firb_approval_before_loan_settlement`, `loan_offer_can_be_conditional_on_firb`).

It is the **lender/loan** counterpart to the **contract**-side gate owned by [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md) (the strategy of making the *sale contract* conditional on FIRB) and [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md) (the clause anatomy). Those own the contract; this doc owns the **loan**: a lender asks for the FIRB approval among the documents for the purchase (Westpac lists "Foreign Investment Review Board (FIRB) approval" for temporary visa applicants). The regulated requirement itself — that a foreign person must hold FIRB approval before acquiring the interest — is owned by [`kb.firb.status-determination`](../firb/status-determination.md) and [`kb.firb.application-process`](../firb/application-process.md); this doc points to it and states only the lending consequence.

## The gate, in sequence

FIRB approval and loan pre-approval run in **parallel**, but the loan cannot **complete** without the approval:

1. **The contract can be signed conditional on FIRB.** FIRB's Guidance Note 6: a foreign person "can enter into a contract as long as the contract is conditional on receiving foreign investment approval."
2. **The lender asks for the FIRB approval.** Westpac's own document checklist lists, under Property Purchases for "Temporary VISA Applicants", "Foreign Investment Review Board (FIRB) approval"; other lenders' application checklists ask for it too ([`kb.lender.documentation-non-resident`](documentation-non-resident.md)).
3. **Whether a lender pre-approves, or issues a formal offer conditional on FIRB, before the approval is granted is each lender's own practice.** No lender publishes it — ask the lender (or a licensed broker) before relying on a conditional offer.

The practical rule the plan surfaces: **do not go unconditional on the contract before FIRB approval is secured** unless the contract itself carries a FIRB condition — because the loan cannot settle without it, and an unconditional contract the buyer cannot complete puts the deposit at risk. The auction trap (no cooling-off, no conditions) is owned by [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md); this doc reinforces it from the financing side.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Sequencing is the whole game.** The buyer can hold pre-approval and a FIRB application at once; the plan should show FIRB approval as a hard milestone on the settlement path, not a formality.
- **The approval letter is a settlement document.** Its FIRB reference also appears in the non-resident document pack ([`kb.lender.documentation-non-resident`](documentation-non-resident.md)) — the two docs meet at the approval letter.
- **Information, not credit advice.** The doc explains the loan sequencing; the actual conditional-offer terms come from the lender via a licensed broker ([`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)).

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver sets the `firb_gate` booleans (all `true` for a foreign person) and orders the `pre_approval_workflow` milestones so FIRB approval precedes settlement; this doc supplies the grounded sequencing. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "loan_offer_can_be_conditional_on_firb": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on a lender's own non-resident or temporary-resident credit policy (e.g. Bankwest, CBA)." },
    "pre_approval_available_before_firb": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on a lender's own non-resident or temporary-resident credit policy (e.g. Bankwest, CBA)." },
    "lender_requires_firb_approval_before_loan_settlement": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — the lender asks for the FIRB approval as an application document (Westpac minimum required documents checklist: \"Temporary VISA Applicants … Foreign Investment Review Board (FIRB) approval\"); reflects the regulated requirement owned by kb.firb.status-determination." },
    "firb_approval_must_precede_unconditional_contract": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a foreign person must hold FIRB approval before acquiring the interest; going unconditional without it (or a FIRB contract condition) risks the deposit — regulated requirement owned by kb.firb.status-determination / kb.firb.contract-conditional-on-approval." },
    "firb_approval_letter_is_a_settlement_document": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — the FIRB approval is one of the documents the lender asks for (Westpac checklist); its reference also appears in the non-resident document pack." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *loan-side* FIRB sequencing. The contract-side conditional strategy → [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md); the clause anatomy → [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md); the regulated approval requirement and process → the `kb.firb.*` owners.
- **Convention vs regulated.** The lender asking for the approval is lender policy (Westpac's checklist); a conditional offer before approval is a PLACEHOLDER until a lender states it; the underlying "approval before acquisition" is `REGULATED` but owned elsewhere — this doc points, does not restate.
- **The letter is the join.** The FIRB approval letter is both the settlement document here and a line in [`kb.lender.documentation-non-resident`](documentation-non-resident.md).

## Sources

- FIRB / Treasury — *Guidance Note 6: Residential land* v5 (approval required before acquiring an interest, regardless of value; a contract conditional on approval) — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2026-06/guidance-note-6-residential-land-v5.pdf
- Westpac — *Minimum required documents checklist* (Section 5 Property Purchases: FIRB approval for temporary visa applicants) — https://www.westpac.com.au/content/dam/public/brokers/documents/applications/wbc-minimum-required-documents-checklist.pdf
