---
slug: kb.lender.firb-approval-as-condition-precedent
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://wise.com/us/blog/getting-a-mortgage-in-australia
    retrieved: 2026-07-06
    note: "\"Your mortgage application can't proceed without Foreign Investment Review Board approval, so start this process early\" — grounds the loan-side sequencing (FIRB before settlement). The regulated approval-before-acquisition requirement is owned by kb.firb.* (cross-ref). Lender-practice convention (aggregator source)"
---

# FIRB approval as a condition precedent to the loan

This doc owns the **loan-side FIRB gate** — how a foreign person's mortgage sequences around FIRB approval. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically the `firb_gate` block (`firb_approval_must_precede_unconditional_offer`, `lender_requires_firb_approval_before_loan_settlement`, `loan_offer_can_be_conditional_on_firb`).

It is the **lender/loan** counterpart to the **contract**-side gate owned by [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md) (the strategy of making the *sale contract* conditional on FIRB) and [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md) (the clause anatomy). Those own the contract; this doc owns the **loan**: a lender will pre-approve and issue an offer *conditional* on FIRB, but will not advance funds at settlement until the approval letter is in hand. The regulated requirement itself — that a foreign person must hold FIRB approval before acquiring the interest — is owned by [`kb.firb.status-determination`](../firb/status-determination.md) and [`kb.firb.application-process`](../firb/application-process.md); this doc points to it and states only the lending consequence.

## The gate, in sequence

FIRB approval and loan pre-approval run in **parallel**, but the loan cannot **complete** without the approval:

1. **Pre-approval can proceed without FIRB.** A lender will assess serviceability and issue a conditional pre-approval before FIRB is granted — so the buyer knows their budget while the FIRB application is in train.
2. **A formal loan offer can be issued conditional on FIRB.** Lenders routinely make the offer expressly **subject to FIRB approval**, mirroring the contract's FIRB condition. This lets the buyer sign a conditional contract and arrange finance in the same window.
3. **Unconditional loan settlement requires the FIRB approval letter.** The lender will **not advance funds / settle** until it has sighted the FIRB **No Objection Notification (approval letter)**. The buyer provides it to the lender as a settlement document, alongside the usual title and identity paperwork.

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
    "loan_offer_can_be_conditional_on_firb": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "lenders routinely issue a loan offer expressly subject to FIRB approval, mirroring the contract's FIRB condition." },
    "pre_approval_available_before_firb": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "conditional serviceability pre-approval can be obtained while the FIRB application is in train — the two run in parallel." },
    "lender_requires_firb_approval_before_loan_settlement": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the lender will not advance funds / settle until it has sighted the FIRB No Objection Notification; lender practice reflecting the regulated requirement (owned by kb.firb.status-determination)." },
    "firb_approval_must_precede_unconditional_contract": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a foreign person must hold FIRB approval before acquiring the interest; going unconditional without it (or a FIRB contract condition) risks the deposit — regulated requirement owned by kb.firb.status-determination / kb.firb.contract-conditional-on-approval." },
    "firb_approval_letter_is_a_settlement_document": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the FIRB approval letter (No Objection Notification) is provided to the lender at settlement; its reference also appears in the non-resident document pack." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *loan-side* FIRB sequencing. The contract-side conditional strategy → [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md); the clause anatomy → [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md); the regulated approval requirement and process → the `kb.firb.*` owners.
- **Convention vs regulated.** The lender behaviours (conditional offer, settlement gate) are `CONVENTION`; the underlying "approval before acquisition" is `REGULATED` but owned elsewhere — this doc points, does not restate.
- **The letter is the join.** The FIRB approval letter is both the settlement document here and a line in [`kb.lender.documentation-non-resident`](documentation-non-resident.md).

## Sources

- FIRB / Treasury — *Guidance Note 6: Residential land* (approval required before acquiring an interest; No Objection Notification) — https://foreigninvestment.gov.au/guidance/guidance-notes
- Wise — *Australian mortgages and home loans for non-residents* (FIRB approval letter provided to the lender; approval required before purchase) — https://wise.com/us/blog/getting-a-mortgage-in-australia
- Home Loan Experts — *Non-Resident Home Loans: Australian Mortgage Guide* (loan offers conditional on FIRB; approval before settlement) — https://www.homeloanexperts.com.au/non-resident-mortgages/
