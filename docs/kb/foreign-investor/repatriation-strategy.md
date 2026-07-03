---
slug: kb.foreign-investor.repatriation-strategy
effective_from: 2025-07-01
last_verified: 2026-07-03
---

# Repatriating rental income and sale proceeds — the AU-side outbound transfer

This doc owns the **AU-side of sending money out of Australia** — rental income or eventual sale proceeds moving from the investor's AU account back to Vietnam. Per the 2026-07-03 Mode-D scoping decision, this doc is **AU-side only**: the outbound transfer mechanics, provider choice, and the AU bank's AML/CTF reporting obligation. The **VN-side receiving process** (SBV inbound registration, if any, declared-purpose categorisation) is **not** duplicated here — it is the same VN-side concern the [`kb.vn-capital-controls.*`](../vn-capital-controls/) placeholders already own for the *inbound-to-Australia* direction, and the plan points the investor to the same VN bank / licensed channel for the reverse direction rather than asserting VN-side rules. It grounds `ownership_planning_foreign_investor` (component 11) repatriation-related ongoing obligations.

## The AU-side mechanics — symmetric to the inbound case, in reverse

An outbound transfer from Australia is not materially different in mechanism from the inbound transfer [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md) already owns:

- **The bank (or licensed provider) is the reporting entity, never this platform.** Same never-custodian discipline as the inbound case — the platform is informational only; the investor's own bank or a licensed money-transfer provider (Wise, OFX, or a bank) executes the transfer.
- **AUSTRAC reporting is symmetric.** An **International Funds Transfer Instruction (IFTI)** is lodged for a transfer of any value **out of** Australia, the same as for a transfer in — this is the AU bank/provider's filing, not the investor's, and is routine rather than a flag on the investor specifically.
- **Provider choice is the same cost lever.** The FX spread on converting AUD rental income or sale proceeds to VND is owned by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md) and the provider-comparison framework by [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md) — both already built mode-agnostic; this doc does not restate the spread bands, only confirms they apply in the outbound direction too.

## What's different about the sale-proceeds case specifically

A one-off, large outbound transfer of **net sale proceeds** (after FRCGW, agent/legal selling costs, and loan payout — owned by `disposition`, component 14) is the highest-value single outbound event in the lifecycle and the one most likely to trigger the AU bank's own **enhanced due diligence on the outbound side** (a large, first-time or infrequent outbound transfer from an account is itself a due-diligence trigger, mirroring the inbound ECDD pattern). Pre-engaging the sending bank before initiating a large sale-proceeds transfer — confirming what evidence it wants (proof the funds are the settlement proceeds of the specific property, the investor's own identity documentation) — is the same pre-engagement discipline the inbound doc already recommends, applied in reverse.

## The VN-side, named but not built

The plan states, without asserting VN regulatory content: **the investor should confirm with their VN bank or a licensed VN remittance provider what inbound documentation Vietnam requires before initiating a large repatriation** — the same "engage the licensed channel before moving funds" discipline as [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) states for the outbound-from-Vietnam direction, mirrored for this reverse flow. This is a labelled gap, not a computed verdict — consistent with the wedge's scoping decision that VN-side regulatory content is the investor's own VN-based advisor's domain.

## Relevance for Vietnam-located investors (Mode D)

- **The mechanism is the same as funding the purchase, reversed.** No new AU-side compliance concept — the same bank/provider, the same IFTI reporting, the same FX-spread economics, just moving the other direction.
- **The sale-proceeds transfer is the one to plan for.** It is the largest single outbound amount, and pre-engaging the bank before initiating it avoids the same held-pending-review risk the inbound doc already names.
- **VN-side documentation is confirmed with the investor's own VN bank/advisor**, not asserted by the plan.
- **The platform never touches the money.** Informational only; all transfer and holding is via the investor's own bank / a licensed provider.

## Rules

Pure-reference (`fills: []`). This is a synthesis/pointer doc — it fills no slot; `ownership_planning_foreign_investor` surfaces the sale-proceeds-transfer pre-engagement step as a qualitative ongoing-obligations note when a disposal is being planned, without asserting a VN-side compliance verdict.

```jsonc
{
  "fills": [],
  "parameters": {
    "au_side_only_vn_side_is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "per the 2026-07-03 scoping decision — this doc owns the AU outbound-transfer mechanics only; VN-side receiving compliance is a labelled gap pointing to the investor's own VN bank/advisor, not asserted content." },
    "ifti_reporting_symmetric_outbound": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "AUSTRAC — an IFTI is lodged for an international funds transfer of any value in either direction; the bank/provider's filing, routine, not a flag on the investor." },
    "never_custodian_of_funds": { "type": "bool", "value": true, "provenance": "POLICY", "note": "the platform never holds or moves the investor's funds; all transfer is via the investor's own bank or a licensed provider, mirroring the inbound-funding discipline." },
    "sale_proceeds_transfer_warrants_pre_engagement": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a large, infrequent outbound transfer of net sale proceeds is likely to trigger the sending bank's own enhanced due diligence; pre-engaging before initiating avoids a held-pending-review delay, mirroring kb.au-aml-ctf.bank-due-diligence-expectations' inbound pre-engagement recommendation." }
  }
}
```

Notes:

- **No `fills`; AU-side only, by design.** VN-side content is deliberately not built here — see the Mode-D scoping decision in `mode-d-wedge.md`.
- **Single-owner via cross-ref.** Inbound AML/CTF pattern (mirrored, not restated) → `kb.au-aml-ctf.bank-due-diligence-expectations`; FX spread → `kb.fx.typical-spreads-vnd-aud`; provider comparison → `kb.fx-providers.wise-ofx-bank-comparison`; sale-proceeds figure → `disposition` (component 14); VN-side placeholder → `kb.vn-capital-controls.sbv-thresholds-2026` / `.declared-purpose-categories`.

## Sources

- AUSTRAC — *International funds transfer instructions (IFTIs)* (reported for transfers of any value into or out of Australia, filed by the reporting entity) — https://www.austrac.gov.au/business/how-comply-and-report-guidance-and-resources/reporting/international-funds-transfer-instructions-iftis
- ASIC Moneysmart — *International money transfers* (provider comparison, exchange-rate margin as the real cost — applies to outbound transfers the same as inbound) — https://moneysmart.gov.au/banking/international-money-transfers
