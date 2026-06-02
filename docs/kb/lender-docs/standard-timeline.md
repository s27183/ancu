---
slug: kb.lender-docs.standard-timeline
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# Lender document timeline — approval to settlement

Between signing the contract and settlement, the buyer's loan moves through a fixed sequence of lender stages: **conditional (pre-)approval → unconditional (formal/full) approval → loan documents issued → signed and returned → certified → settlement booked → funds disbursed**. The single most consequential point in that sequence is **unconditional approval** — until the lender gives it, the buyer's finance is not secured, and the contract's finance condition is not satisfied. This doc owns **the lender's document workflow and the conditional-vs-unconditional distinction that governs the finance milestones**; it grounds the `settlement_prep` milestones `finance_approval_unconditional`, `loan_documents_signed` (and `settlement_funds_released` from the lender side) and the `key_dates.finance_approval_deadline` derivation. The **borrowing-capacity / lender-fit reasoning** is owned by the `mortgage_finance` component (`kb.lender.serviceability-basics`); the **surrounding settlement timeline** by `kb.settlement.process-by-state`.

## The stages

1. **Conditional approval (pre-approval).** The lender reviews the buyer's finances against initial criteria and indicates it is *likely* to lend, **subject to conditions** — typically a satisfactory property valuation, verified income/expenses, and acceptable LMI (if applicable). Conditional approval commonly lasts **3–6 months** and is **not a guarantee**.
2. **Property found, contract signed, valuation ordered.** The lender orders a **valuation** of the specific property (the bank valuation — see `kb.property.comparables-methodology`; a low valuation can reopen the deposit/LVR/LMI position). Outstanding conditions are worked through.
3. **Unconditional (formal/full) approval.** Once the valuation is satisfactory and all conditions are met, the lender gives **unconditional approval** — its formal commitment to lend. **This is the point at which the contract's finance condition is satisfied.** It commonly follows conditional approval by **1–2 weeks** once conditions are cleared.
4. **Loan documents issued.** The lender issues the **loan offer / mortgage documents** (loan contract, mortgage, direct-debit and related forms).
5. **Documents signed and returned.** The buyer reviews and **signs the loan documents within the lender's window** (some require witnessing), and returns them.
6. **Certification / verification.** The lender **certifies** the returned documents and completes its final checks; only then is the loan ready to settle.
7. **Settlement booked and funds disbursed.** The lender joins the electronic settlement workspace (see `kb.pexa.settlement`), **books the settlement** date/time, and **disburses the loan funds** at settlement.

## The trap: conditional pre-approval is not finance secured

- **Conditional (pre-)approval ≠ unconditional approval.** A buyer with pre-approval has *not* secured finance — the loan can still fall over at valuation (a low bank valuation), on verification, or on LMI rejection. The contract's **finance condition is cleared only at unconditional approval.**
- **Don't let the finance clause lapse on the strength of pre-approval.** Treating pre-approval as "done" — and letting the contract's finance date pass, or worse, waiving the finance condition — is a high-severity mistake: if the loan then doesn't go unconditional, the buyer is bound with no finance.
- **Time the deadline from the lender's clock.** The `finance_approval_deadline` must allow for valuation + conditions + the lender's turnaround, which varies by lender and is the most perishable part of this timeline.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Unconditional approval is the milestone that matters.** The plan tracks the loan to **unconditional**, not pre-approval, before treating finance as secured — and in QLD, where settlement is time-of-essence (see `kb.settlement.process-by-state`), it sets the finance deadline with extra margin.
- **Lender turnaround drifts — confirm it live.** The plan presents stage timeframes as *typical*, to be confirmed with the buyer's lender or broker; it never asserts a specific lender's processing time as fact, and never steers the buyer to a particular lender (independence + no credit advice).
- **Read the loan documents before signing.** For a second-language buyer, the plan flags the loan documents as a point to review carefully (with the broker/lender, and a professional if needed) within the signing window.
- **Information, not advice.** The plan describes the standard lender workflow and the buyer's deadlines; it does not give credit advice or recommend a lender — the buyer's broker/lender owns the loan, the buyer chooses.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. It grounds the finance-related `settlement_prep` milestones and the `finance_approval_deadline` derivation; the dates and milestone statuses are resolver-derived from the contract and the lender's progress against this doc's stage sequence.

```jsonc
{
  "fills": [],
  "parameters": {
    "unconditional_approval_required_before_finance_condition_satisfied": { "type": "bool", "value": true, "note": "CONVENTION (strong) — LOAD-BEARING: the contract's finance condition is satisfied only at UNCONDITIONAL (formal/full) approval, not at conditional/pre-approval. The plan tracks the loan to unconditional before treating finance as secured" },
    "conditional_preapproval_is_not_a_guarantee": { "type": "bool", "value": true, "note": "CONVENTION — conditional/pre-approval is a likely-to-lend indication subject to valuation, verification and LMI; the loan can still fall over. Do not waive or let the contract's finance clause lapse on the strength of pre-approval" },
    "loan_documents_signed_before_settlement_booked": { "type": "bool", "value": true, "note": "CONVENTION — the lender issues loan/mortgage documents after unconditional approval; the buyer signs+returns them within the lender's window, the lender certifies them, then books settlement and disburses" },
    "lender_valuation_governs_the_loan": { "type": "bool", "value": true, "note": "CONVENTION — the lender orders its own valuation of the specific property; a low bank valuation can reopen deposit/LVR/LMI (see kb.property.comparables-methodology). Agent appraisal/advertised price do not govern the loan" }
  },
  "lookup": {
    "lender_doc_timeline_stages": {
      "_note": "INDICATIVE — typical lender document workflow; durations are LENDER-POLICY and time-sensitive, vary by lender, and must be confirmed with the buyer's lender/broker. Not statutory.",
      "sequence": [
        { "stage": "conditional_preapproval", "typical": "valid 3-6 months", "tier": "lender-policy" },
        { "stage": "valuation_ordered", "typical": "after contract on the specific property", "tier": "lender-policy" },
        { "stage": "unconditional_approval", "typical": "~1-2 weeks after conditions cleared", "tier": "lender-policy" },
        { "stage": "loan_documents_issued", "typical": "shortly after unconditional", "tier": "lender-policy" },
        { "stage": "documents_signed_returned", "typical": "within the lender's signing window", "tier": "lender-policy" },
        { "stage": "certification", "typical": "lender verifies returned documents", "tier": "lender-policy" },
        { "stage": "settlement_booked_funds_disbursed", "typical": "at the contract settlement date", "tier": "lender-policy" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. This doc grounds the finance milestones and the `finance_approval_deadline` derivation; statuses/dates are resolver-derived. Pure-reference, same shape as the other `settlement_prep` anchors.
- **Provenance is CONVENTION + LENDER-POLICY (time-sensitive).** The conditional-vs-unconditional structure and the stage sequence are stable conventions; the *durations* are lender-policy that drifts fastest, so the lookup is flagged INDICATIVE and the agent presents timeframes as "typical, confirm with your lender." Nothing here is statutory.
- **ASIC line — describe the workflow, never recommend a lender.** This doc describes the standard process and stages; it does not name or rank lenders and does not give credit advice. The buyer's broker/lender owns the loan; the buyer chooses (independence + no ACL).
- **Single-owner.** This doc owns the **lender document workflow + the conditional/unconditional distinction**. The **borrowing capacity / serviceability** → `kb.lender.serviceability-basics` (mortgage_finance). The **bank valuation method** → `kb.property.comparables-methodology`. The **LMI mechanics** → `kb.lmi.calculation`. The **surrounding settlement timeline** → `kb.settlement.process-by-state`. Cross-ref, not duplicated.

## Sources

**Convention / lender-policy (indicative — confirm with the lender) :**

- Moneysmart (ASIC) — *Applying for a home loan* (conditional vs unconditional approval; the loan application and settlement steps) — https://moneysmart.gov.au/home-loans/applying-for-a-home-loan
- Suncorp Bank — *Conditional and unconditional approval* (Australian framing: conditional/pre-approval typically valid 3–6 months; unconditional is the lender's formal commitment; the steps from unconditional approval to settlement — loan documents signed within the lender's timeframe, final inspection, settlement) — https://www.suncorpbank.com.au/shine-blog/home-loans/conditional-and-unconditional-approval.html

The stage *durations* are lender-policy and time-sensitive (they vary by lender and change over time); they are indicative only and must be confirmed against the buyer's specific lender/broker. Nothing in the lender document workflow is statutory.
