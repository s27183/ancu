---
slug: kb.foreign-buyer.subject-to-firb-clauses
effective_from: 2025-04-01
last_verified: 2026-06-28
---

# Foreign buyer — anatomy of a "subject to FIRB approval" clause

This doc owns the **anatomy of the special condition** that makes a contract conditional on foreign-investment approval: what the condition does, the moving parts a buyer should understand, and the failure-path. It grounds the `buying_strategy` component (7). It owns the *clause content*; the **strategy decision** of whether to use a conditional contract is owned by [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md), and the **pre-signing verification checklist** by [`kb.firb.contract-clauses-required`](../firb/contract-clauses-required.md).

## What the condition is for

A "subject to FIRB approval" special condition makes the buyer's obligation to complete **contingent on the No Objection Notification issuing**. It lets the buyer sign and secure the property without breaching the rule that they must not settle before approval ([`kb.firb.application-process`](../firb/application-process.md)). Without it, a foreign buyer who signs an unconditional contract is exposed: if approval is refused or delayed past settlement, they face either a breach of FATA or a breach of the contract.

## The moving parts a buyer should understand

These are the elements a conveyancer typically addresses; the buyer should understand them, not draft them:

- **The approval-by date.** A long-stop date by which approval must be obtained, aligned to the realistic decision window (~30 days from full fee payment — [`kb.firb.timelines-standard`](../firb/timelines-standard.md)), with margin. Setting it too tight risks the condition lapsing before the decision; too loose weakens the vendor's certainty.
- **The termination right.** What happens if approval is **not** obtained by the date — typically a right for the buyer (and/or vendor) to terminate.
- **The deposit treatment on failure.** Whether the **deposit is returned or forfeited** if the condition is not satisfied. This is the highest-stakes term: a poorly framed condition can forfeit the deposit even on a *bona fide* failed FIRB application. The buyer must confirm the deposit-return position before signing.
- **The obligation to apply.** A requirement that the buyer **apply promptly and pursue the application in good faith** — vendors commonly require this so the buyer cannot use the condition as a free option to walk away.

## The failure-path is the point

The reason this clause matters is the failure-path: **if FIRB approval is refused or not granted in time, the contract can be terminated and (if correctly framed) the deposit returned.** A buyer who understands only "the contract is conditional" but not "on what terms the deposit comes back" has not understood the clause. The plan surfaces the deposit-treatment question explicitly.

## Rules

Pure-reference (`fills: []`). The `buying_strategy` agent surfaces these elements for the buyer's understanding and flags the deposit-treatment question; the actual terms are the conveyancer's. This doc supplies the grounded anatomy. No leaf asserted; no figure here.

```jsonc
{
  "fills": [],
  "parameters": {
    "condition_makes_completion_contingent_on_approval": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the special condition makes the buyer's obligation to complete contingent on the No Objection Notification issuing — lets the buyer sign without breaching the must-not-settle rule." },
    "has_approval_by_date": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a long-stop date by which approval must be obtained, aligned to the ~30-day decision window with margin." },
    "has_termination_right_on_failure": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a right to terminate if approval is not obtained by the date." },
    "deposit_treatment_is_highest_stakes_term": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "whether the deposit is returned or forfeited on a failed FIRB application is the key term the buyer must confirm before signing." },
    "buyer_must_apply_in_good_faith": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "vendors commonly require the buyer to apply promptly and pursue the application in good faith, so the condition is not a free walk-away option." }
  }
}
```

Notes:

- **Single-owner.** The strategy choice → [`kb.firb.contract-conditional-on-approval`](../firb/contract-conditional-on-approval.md); the pre-signing checklist → [`kb.firb.contract-clauses-required`](../firb/contract-clauses-required.md); the must-not-act rule → [`kb.firb.application-process`](../firb/application-process.md); decision timing → [`kb.firb.timelines-standard`](../firb/timelines-standard.md). This doc owns only the **clause anatomy**.
- **No drafting.** This describes what the condition *achieves* and the questions a buyer should ask; it does **not** provide clause wording — drafting is the conveyancer's/solicitor's, and providing it would cross into legal advice.
- **Decision-support framing.** Informational; the buyer's specific contract is reviewed by their own legal professional.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025), footnote 3 — contract conditional on receiving foreign-investment approval — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
- ATO — *Apply to buy residential property as a foreign person* — approval required before the action completes — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
