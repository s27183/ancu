---
slug: kb.cross-border-settlement.coordination-best-practices
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Cross-border settlement coordination — sequencing the two-country critical path

This doc owns the **coordination sequence and buffer discipline** that gets Vietnamese-side funds cleared into an Australian trust account *before* settlement — so `settlement_prep` (component 10) can order its `currency_transfer_milestones` and justify `buffer_days_before_settlement`. It owns the **ordering and the buffer rationale**; each milestone's substance lives in its owner: the FIRB validity window in [`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md), the AU bank AML clearance in [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md), the transfer cost/provider in [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md), and the VN-side outbound process in the VN placeholders [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) / [`kb.vn-capital-controls.declared-purpose-categories`](../vn-capital-controls/declared-purpose-categories.md).

## The critical path — order and dependencies

A Mode-B settlement stacks obligations across two countries, each with its own clock. The load-bearing ordering:

1. **FIRB approval in force through settlement.** The No Objection Notification must be granted *and still valid on the settlement date* — its validity window ([`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md)) is the outer constraint the whole timeline sits inside.
2. **VN-side outbound compliance documented.** SBV thresholds / declared purpose must be satisfied before the transfer can leave Vietnam (VN placeholders) — often the slowest, least predictable leg.
3. **Transfer initiated with the buffer.** The transfer is initiated early enough to clear both sides before settlement, via the cost-ranked provider ([`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md)).
4. **AU bank AML/CTF clearance.** The receiving bank's enhanced due diligence must complete so the funds are usable, not held ([`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md)) — pre-engaged and source-of-funds-evidenced up front.
5. **Funds received in the AUD trust account** — cleared and available for the conveyancer to draw on at settlement.

The transfer's earliest leg (2) and the bank's clearance (4) are the two that most often overrun; the **buffer** (`buffer_days_before_settlement`, default 14) exists to absorb exactly those overruns.

## Why the buffer, and who coordinates

- **The buffer is the shock absorber.** Cross-border transfers and ECDD reviews have variable, hard-to-predict timing; initiating with a **~14-day** buffer before settlement converts a delay into slack rather than a missed settlement (and a defaulted contract).
- **Name the counterparties early.** A **conveyancer** aware of the FIRB and currency-transfer milestones, ideally **Vietnamese-speaking** (and a Vietnamese-speaking immigration lawyer if visa questions arise), keeps the two-country coordination from stalling on communication.
- **One held leg fails the whole chain.** Funds held for AML review, or an FIRB approval that lapses before settlement, defaults the contract regardless of how well the other legs went — which is why the plan tracks each as a critical-path milestone, not a checklist item.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Two clocks, one settlement date.** The FIRB validity window and the transfer-plus-clearance timeline must both land before settlement; the plan sequences backward from the settlement date.
- **The buffer is not padding — it is the plan.** VN-side outbound compliance and AU-side ECDD are the unpredictable legs; the 14-day buffer is sized for them.
- **Coordination is decision-support.** The plan surfaces the sequence, dependencies, and buffer; the buyer's conveyancer and bank execute — the platform never touches funds or acts as agent.

## Rules

Pure-reference (`fills: []`). The `settlement_prep` resolver orders `currency_transfer_milestones` by the sequence below and seeds/justifies `buffer_days_before_settlement` (blueprint default 14). All `CONVENTION` (coordination practice); the FIRB-validity constraint it depends on is `REGULATED` but owned by [`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md), not restated. No leaf asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "sequence_backward_from_settlement_date": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "both the FIRB validity window and the transfer+clearance timeline must land before settlement; plan the milestones backward from the settlement date." },
    "buffer_days_before_settlement_default": { "type": "int", "value": 14, "provenance": "CONVENTION", "note": "recommended buffer to absorb variable cross-border transfer + ECDD timing; seeds blueprint buffer_days_before_settlement." },
    "unpredictable_legs_are_vn_outbound_and_au_ecdd": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the VN-side outbound compliance and the AU bank ECDD clearance are the two legs that most often overrun; the buffer is sized for them." },
    "one_held_leg_defaults_the_contract": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "funds held for AML review or an FIRB approval lapsing before settlement defaults the contract regardless of the other legs — each is tracked as a critical-path milestone." },
    "name_vietnamese_speaking_conveyancer_early": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a conveyancer aware of FIRB + currency-transfer milestones, ideally Vietnamese-speaking, keeps two-country coordination from stalling." },
    "platform_never_touches_funds": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the conveyancer and bank execute; the platform is informational and never a custodian or agent (AUSTRAC line)." }
  },
  "lookup": {
    "coordination_sequence": {
      "note": "the ordered critical path; each milestone's substance is owned by the cross-referenced doc, not duplicated here.",
      "entries": [
        { "step": 1, "milestone": "firb_approval_in_force_through_settlement", "owner": "kb.firb.approval-to-settlement-timeline" },
        { "step": 2, "milestone": "vn_side_outbound_compliance_documented", "owner": "kb.vn-capital-controls.declared-purpose-categories" },
        { "step": 3, "milestone": "transfer_initiated_with_buffer", "owner": "kb.fx-providers.wise-ofx-bank-comparison" },
        { "step": 4, "milestone": "au_bank_aml_clearance_completed", "owner": "kb.au-aml-ctf.bank-due-diligence-expectations" },
        { "step": 5, "milestone": "funds_received_in_aud_trust_account", "note": "cleared and available for the conveyancer at settlement" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; a sequencing doc.** It owns the *order + the buffer rationale*; each milestone's substance is owned elsewhere (FIRB validity, AML clearance, transfer provider, VN outbound). This is the *coordination* layer over those owners.
- **Critical path, not a checklist.** The value is the *dependency ordering and the buffer* — any single held leg defaults the contract, so the milestones are tracked as a critical path.
- **Decision-support framing.** The conveyancer and bank execute; the plan surfaces the sequence and buffer. The 14-day buffer is a starting recommendation, tuned to the actual VN-side and bank timelines.

## Sources

- ASIC Moneysmart — *International money transfers* (transfers take time; use licensed providers; confirm timing) — https://moneysmart.gov.au/banking/international-money-transfers
- AUSTRAC — *International funds transfer instruction (IFTI) reports* (bank reporting within 10 business days; clearance timing) — https://www.austrac.gov.au/business/core-guidance/reporting/money-transferred-and-overseas-international-funds-transfer-instruction-ifti-reports
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land* (approval must be in place before acquisition; validity window) — https://foreigninvestment.gov.au/guidance/guidance-notes
