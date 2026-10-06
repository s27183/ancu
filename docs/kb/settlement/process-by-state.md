---
slug: kb.settlement.process-by-state
effective_from: 2025-08-01
last_verified: 2026-07-06
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-residential-property-nsw/exchanging-contracts-and-settlement
    retrieved: 2026-07-06
    note: "NSW Government — settlement usually ~6 weeks after exchange; 0.25% cooling-off penalty; electronic settlement via ELN. QLD gov settlement page 403s WebFetch; the NSW/VIC/QLD settlement-period defaults are conveyancing-practice conventions (per the doc body), read against the specific contract."
---

# Settlement — process and timeline, by state

**Settlement** is the moment the purchase legally completes: the balance of the purchase price is paid to the seller, the mortgage is registered, and **title transfers to the buyer**. Between signing the contract and settlement there is a fixed sequence of milestones — finance to unconditional, deposit paid, inspections satisfied, loan documents signed, insurance bound, funds released, title registered, keys handed over — that the plan tracks as a critical path. **How long the buyer has, and what happens if they miss the date, is set by the contract and differs by state.** This doc owns **the end-to-end settlement timeline, the per-state settlement-period convention, and the critical-path milestone sequence**; it grounds the `settlement_prep` `milestones`, `settlement_date`, and the `key_dates` derivations. The **electronic mechanism** by which funds and title transfer is owned by `kb.pexa.settlement`; the **lender's document workflow** by `kb.lender-docs.standard-timeline`; **cooling-off** by `kb.cooling-off.by-state`; **insurance timing** by `kb.insurance.timing-of-risk-pass`.

## The critical path (contract → keys)

Settlement is the end of an ordered chain. Each milestone depends on the one before it; a slip early in the chain pushes the whole settlement date:

1. **Contract signed** (exchange in NSW) — the binding agreement; the clock starts.
2. **Cooling-off** runs (private treaty only; not at auction) — see `kb.cooling-off.by-state`.
3. **Deposit paid to the agent's/solicitor's trust account** (typically 10%, on signing or shortly after).
4. **Building & pest inspection satisfactory** — the building/pest condition cleared (see `kb.building-pest.interpretation`).
5. **Finance to unconditional (formal/full) approval** — the finance condition cleared; **this is the gate buyers most often misjudge** (see `kb.lender-docs.standard-timeline`).
6. **Loan documents signed and returned** to the lender, then certified.
7. **Building insurance bound** — effective from the date risk passes to the buyer (state-dependent; see `kb.insurance.timing-of-risk-pass`).
8. **Settlement day: funds released and title registered** — done electronically and simultaneously via an ELNO (see `kb.pexa.settlement`).
9. **Keys received** — possession passes.

A **pre-settlement (final) inspection** is the buyer's right, typically in the week before settlement, to confirm the property is in the same condition and agreed inclusions remain.

## NSW

- **Standard settlement period: 42 days (6 weeks)** from exchange of contracts. Negotiable, but 42 days is the default.
- **Not "time of the essence."** If a party cannot settle on the due date, the other must first serve a **Notice to Complete** giving a further period (commonly **14 days**) before they can terminate — a built-in grace mechanism.
- **Exchange before binding.** In NSW the parties are not bound until contracts are exchanged; until then the vendor may accept a higher offer (gazumping risk).

## VIC

- **Settlement period: commonly 30, 60 or 90 days; 60 days is the most common** default. Set in the contract and negotiable.
- **Not "time of the essence."** As in NSW, the standard contract provides a **Notice to Complete / default-notice** path (commonly 14 days) before termination, rather than automatic termination on the due date.

## QLD

- **Standard settlement period: 30 days** from the contract date — shorter than NSW/VIC. Negotiable in the contract.
- **Time IS of the essence — the load-bearing difference.** Under the standard REIQ contract the settlement date is an **essential condition**: if the buyer fails to settle on the agreed date, the **seller may terminate, keep the deposit, and sue for damages or specific performance** — with no Notice-to-Complete grace period. A QLD buyer whose finance or funds slip even by a day is exposed in a way a NSW/VIC buyer is not.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The QLD time-of-essence trap is the highest-stakes per-state difference.** A first-home buyer in QLD must have finance **unconditional** and funds positioned well before the 30-day date — there is no second chance. The plan sets the QLD `finance_approval_deadline` conservatively and flags the deposit-at-risk consequence explicitly. In NSW/VIC the Notice-to-Complete buffer exists but is not a plan to rely on.
- **Settlement is a coordinated handover, not a single act.** For a buyer navigating a second-language process, the plan renders the critical path as a timeline (swimlane) with each counterparty's role — conveyancer/solicitor, lender, broker, agent, inspectors, insurer — so nothing is missed.
- **Always with a conveyancer/solicitor.** The buyer does not run settlement themselves; their conveyancer/solicitor coordinates it (and operates the electronic workspace — see `kb.pexa.settlement`). The plan's role is to keep the buyer ahead of each deadline.
- **Information, not advice.** The plan lays out the standard process and the buyer's state-specific deadlines and directs them to their legal/finance professionals; it does not give legal advice on a specific contract.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The `settlement_prep` milestones, dates and `settlement_checklist` are resolver-derived from the contract's dates against this doc's per-state conventions and critical-path sequence; this doc supplies the timeline and the per-state rules, not a filled checklist.

```jsonc
{
  "fills": [],
  "parameters": {
    "settlement_is_title_and_funds_transfer": { "type": "bool", "value": true, "note": "CONVENTION — settlement is the moment the balance is paid and title transfers to the buyer; in all three states this now happens electronically and simultaneously (see kb.pexa.settlement)" },
    "qld_settlement_time_is_of_the_essence": { "type": "bool", "value": true, "note": "CONVENTION (strong — QLD standard REIQ contract + common law) — in QLD the settlement date is an essential condition; failure to settle on the date lets the seller terminate, keep the deposit and sue. NO Notice-to-Complete grace, unlike NSW/VIC. Load-bearing Mode-A trap: position QLD finance + funds well ahead of the 30-day date. Sourced to standard-contract/conveyancing guidance, not a single statute (it is contractual + common law)" },
    "nsw_vic_notice_to_complete_days": { "type": "integer", "value": 14, "note": "CONVENTION (NSW/VIC standard contract) — NSW and VIC contracts are not time-of-essence; a defaulting party must first be served a Notice to Complete (commonly 14 days) before the other can terminate. A grace mechanism QLD lacks" },
    "buyer_final_inspection_before_settlement": { "type": "bool", "value": true, "note": "CONVENTION — the buyer has a pre-settlement (final) inspection right, typically in the week before settlement, to confirm condition + inclusions unchanged" },
    "typical_deposit_pct": { "type": "percentage", "value": 10, "note": "CONVENTION — ~10% deposit paid to trust on/after signing; exact figure is in the contract and negotiable (owned with kb.contract-of-sale.review-points-by-state)" }
  },
  "lookup": {
    "settlement_period_by_state": {
      "_note": "CONVENTION — standard-contract default settlement periods (calendar days from contract/exchange); negotiable in every state. Not a statutory schedule.",
      "NSW": { "typical_days": 42, "time_of_essence": false, "notice_to_complete_days": 14 },
      "VIC": { "typical_days": 60, "range_days": [30, 90], "time_of_essence": false, "notice_to_complete_days": 14 },
      "QLD": { "typical_days": 30, "time_of_essence": true, "notice_to_complete_days": null }
    },
    "settlement_critical_path": {
      "_note": "Ordered milestone chain; each depends on the prior. Maps to settlement_prep.milestones. Cooling-off applies to private treaty only (not auction).",
      "sequence": [
        { "milestone": "contract_signed", "dependency": null },
        { "milestone": "cooling_off_end", "dependency": "contract_signed", "applies": "private_treaty_only" },
        { "milestone": "deposit_paid_to_trust", "dependency": "contract_signed" },
        { "milestone": "building_pest_satisfactory", "dependency": "contract_signed" },
        { "milestone": "finance_approval_unconditional", "dependency": "building_pest_satisfactory" },
        { "milestone": "loan_documents_signed", "dependency": "finance_approval_unconditional" },
        { "milestone": "insurance_bound", "dependency": "finance_approval_unconditional" },
        { "milestone": "settlement_funds_released", "dependency": "loan_documents_signed" },
        { "milestone": "title_registered", "dependency": "settlement_funds_released" },
        { "milestone": "keys_received", "dependency": "title_registered" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The `settlement_checklist` (dates, critical-path milestones, at-risk milestones, next action) is resolver-derived from the uploaded contract's dates against this doc's per-state conventions; this doc is the grounding timeline. Same pure-reference shape as the other `settlement_prep` anchors.
- **Provenance is CONVENTION.** Settlement periods, the deposit %, the milestone sequence and the time-of-essence/Notice-to-Complete contrast are standard-contract practice, not a statutory schedule — so the lookup is CONVENTION, not EXACT (unlike the duty scales). The regulated piece of settlement — that it is now electronic and simultaneous — lives in `kb.pexa.settlement`.
- **QLD time-of-essence is the load-bearing param.** Lifted out of prose because it changes the plan: the QLD `finance_approval_deadline` and funds timing must be conservative, and the deposit-at-risk consequence is flagged high-severity. Sourced to standard-contract/conveyancing guidance — recorded as contractual + common law, not pinpointed to a statute (verification-honesty note).
- **Single-owner across the settlement_prep cluster.** This doc owns the **timeline + per-state periods + critical-path sequence**. The **electronic settlement mechanism** (ELNO, simultaneous funds/title, VOI) → `kb.pexa.settlement`. The **lender document workflow** (conditional→unconditional→loan docs→certification) → `kb.lender-docs.standard-timeline`. **Cooling-off** → `kb.cooling-off.by-state`. **Insurance effective date** → `kb.insurance.timing-of-risk-pass`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities):**

- NSW Government — *Exchanging contracts and settlement* (settlement after exchange; standard ~6-week settlement; deposit) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-residential-property-nsw/exchanging-contracts-and-settlement
- Queensland Government — *Buying and selling a property: settlement* (the settlement process; REIQ standard contract; time for settlement) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property
- Consumer Affairs Victoria — *Buying property: settlement* (the settlement process in Victoria) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property

**Convention / point-in-time (settlement-period defaults; time-of-essence position) — indicative, conveyancing-practice:**

- Standard settlement periods (NSW 42 days; VIC 30/60/90, 60 common; QLD 30 days) and the NSW/VIC Notice-to-Complete vs QLD time-of-essence contrast are standard-contract conventions confirmed across conveyancing-practice guidance; verify the exact figure against the specific contract, which governs. QLD time-of-essence is a feature of the standard REIQ contract + QLD common law (not pinpointed to a statute in this pass).
