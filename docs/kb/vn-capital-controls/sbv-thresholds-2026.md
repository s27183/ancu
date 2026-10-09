---
slug: kb.vn-capital-controls.sbv-thresholds-2026
effective_from: 2026-07-03
last_verified: 2026-07-03
sources:
  - note: "PLACEHOLDER — VN-legal-counsel-gated blocker (strategy §9). SBV outbound-transfer approval threshold(s), registration mechanics, and the current governing circular for an individual funding an offshore property purchase have not been verified against an SBV primary or VN legal counsel. Reconfirmed as an open, intentional deferral during the 2026-07-06 Phase B backfill — not resolved here."
---

# ⚠ PLACEHOLDER — SBV outbound transfer thresholds (NOT SOURCE-GROUNDED)

**This doc's quantitative content is a labelled placeholder.** The State Bank of Vietnam (Ngân hàng Nhà nước Việt Nam — SBV) regulates outbound foreign-currency remittance under Vietnam's foreign-exchange management regime, and a property-investment transfer from Vietnam is a **capital-account transaction** — SBV oversight applies from a low bar, not just above some deposit-sized threshold. But the **specific approval threshold(s), registration mechanics, and current circular** that govern an individual funding an offshore property purchase have **not been verified against an SBV primary or VN legal counsel this session** — this is exactly the counsel-gated blocker strategy §9 named for Mode B (see [[foundation-first-for-cross-contract-reframe]] / the Mode-B wedge-open placeholder-split, [[honest-deferral-not-rug]]). This doc grounds `family_context`/`cross_border_funding` (component 7) `vn_capital_control_compliance.amount_exceeds_sbv_threshold` and `.sbv_approval_required`.

## What can be stated now (stable principle, not a number)

- **Capital-account, not current-account.** Funding an overseas property purchase is a capital-account outward remittance under Vietnamese FX law — a categorically stricter regime than a current-account transfer (tuition, family support, travel). Do not apply a current-account mental model (or threshold) to a property-funding transfer.
- **SBV oversight, not a self-service transfer.** A VN-side funder cannot simply wire an unlimited amount offshore through a normal retail channel for the purpose of buying foreign property; the transaction is expected to be **registered/approved through a licensed VN bank**, which applies SBV rules at the point of transfer.
- **Never an informal channel.** Consistent with the platform's standing constraint (never recommend an informal/unofficial transfer route — capital-control evasion is a real legal exposure for the VN-side funder, not just a platform risk), any guidance here always routes the funder to a **licensed VN bank or a licensed remittance/FX provider**, never around one.

## What is PENDING (the placeholder datum)

- `amount_exceeds_sbv_threshold`: **PENDING** — the resolver must not compute or assert this bool until the current SBV threshold value/mechanism is sourced.
- `sbv_approval_required`: **PENDING** — same; do not default to `false`. Because this is a capital-account transaction, the safer honest-partial default when unresolved is to **surface the question to the buyer/funder** rather than silently returning `false` (a silent `false` would understate a real compliance step).
- Any VND-denominated threshold figure, document list, or processing-timeline number.

## Named re-ground obligation

Before this doc's quantitative content can leave placeholder status, verify against (in order of authority):

1. The current **SBV circular governing foreign-exchange management for outward remittance / overseas investment by residents** (the FX management law + its implementing circulars — cite the specific circular number and effective date once sourced).
2. A **licensed VN bank's own compliance/FX desk** guidance for outward property-investment remittances (a provider-primary, per [[kb-doc-authoring]]'s "ask Son for the source doc before resigning to placeholder" move).
3. **VN legal counsel** engaged for the Mode-B wedge (strategy §9's named blocker) — the authoritative source for a regulated determination this specific, in a jurisdiction the platform does not operate a licensed presence in.

## Buyer / funder pointer (what the plan says today)

Until re-grounded, the plan surfaces this as an **action item, not a computed verdict**: the VN-side funder should engage their VN bank (or a licensed VN remittance provider) **before** initiating any transfer, disclose the purpose (property purchase abroad), and follow that institution's SBV-compliant registration process. This is informational routing to a licensed channel, not capital-controls advice — the platform does not determine VN regulatory compliance on the funder's behalf.

## Rules

Pure-reference (`fills: []`). All quantitative content is `is_placeholder: true` — the resolver surfaces PENDING, never a computed threshold-exceeded verdict, until re-grounded.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — quantitative SBV threshold content not yet sourced against a primary; structure built, datum pending re-ground (kb-doc-authoring FIFTH honesty move)." },
    "capital_account_not_current_account": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a property-investment transfer is a capital-account outward remittance under VN FX law — categorically stricter than a current-account transfer (tuition/family support); stable principle, asserted even while the threshold figure is pending." },
    "sbv_approval_required_defaults_to_surfaced_not_false": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — honest-partial default: an unresolved sbv_approval_required must be surfaced to the buyer/funder as an open question, never silently defaulted to false (which would understate a real compliance step)." },
    "never_an_informal_channel": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the plan always routes the VN-side funder to a licensed VN bank or licensed remittance/FX provider for SBV-compliant registration, never an informal/unofficial route — mirrors the platform's own never-custodian discipline (kb.au-aml-ctf.bank-due-diligence-expectations) on the VN side." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc.** The stable qualitative principle (capital-account regime, licensed-channel-only) is asserted now; the quantitative threshold/approval-mechanism content is PENDING pending VN legal counsel / SBV primary / a licensed VN bank.
- **Do not default `sbv_approval_required` to `false`.** Given the capital-account classification, the honest-partial default is "surface, don't silently clear."
- **Consumer:** `family_context` / `cross_border_funding` (component 7), `vn_capital_control_compliance.amount_exceeds_sbv_threshold` / `.sbv_approval_required`. Cross-refs: [`kb.vn-capital-controls.declared-purpose-categories`](declared-purpose-categories.md) (the transfer's declared purpose), [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md) (the AU-side receiving-bank obligations, already built), [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md) / [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md) (provider/cost, distinct concern from SBV compliance).

## Sources

None yet — placeholder. Re-ground against the SBV circular governing outward remittance / overseas investment by residents, a licensed VN bank's own compliance guidance, and/or VN legal counsel engaged for the Mode-B wedge (strategy §9).
