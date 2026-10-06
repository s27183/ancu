---
slug: kb.vn-capital-controls.declared-purpose-categories
effective_from: 2026-07-03
last_verified: 2026-07-03
sources:
  - note: "PLACEHOLDER — VN-legal-counsel-gated blocker (strategy §9), sibling of kb.vn-capital-controls.sbv-thresholds-2026. SBV declared-purpose categories/mechanics for an individual funding an offshore property purchase have not been verified against an SBV primary or VN legal counsel. Reconfirmed as an open, intentional deferral during the 2026-07-06 Phase B backfill — not resolved here."
---

# ⚠ PLACEHOLDER — declared-purpose categories for SBV transfers (NOT SOURCE-GROUNDED)

**This doc's quantitative/procedural content is a labelled placeholder**, the sibling of [`kb.vn-capital-controls.sbv-thresholds-2026`](sbv-thresholds-2026.md) — same VN-legal-counsel-gated blocker (strategy §9), same placeholder discipline ([[honest-deferral-not-rug]]'s FIFTH honesty move). This doc grounds `cross_border_funding` (component 7) `vn_capital_control_compliance.declared_purpose_category` and `.purpose_documentation_required`.

## What can be stated now (stable principle, not a document list)

The `declared_purpose_category` enum is already fixed by the blueprint (`student_tuition_and_living_expenses`, `family_remittance`, `property_investment_foreign_direct_investment`, `other`) — this doc's job is to ground *which category applies* and *what documentation each needs*, not to invent the enum.

- **A property-investment funding transfer declares as `property_investment_foreign_direct_investment`** (or the closest analogue in the applicable circular's own category list, once sourced) — **not** `family_remittance`, even where the transfer is a gift from a parent to a child. The purpose of the funds (buying an overseas asset) is what SBV categorisation tests, not the family relationship between sender and recipient. Mis-declaring a property-funding transfer as ordinary family remittance is a real compliance risk for the VN-side funder, distinct from — and more consequential than — a platform-side labelling error.
- **The stricter category likely carries the heavier documentation burden.** Categories that test as capital-account / investment-purpose transactions typically require more registration/supporting-document steps than a current-account family-support remittance. This is a structural expectation carried over from the current-vs-capital-account principle in the sibling threshold doc, not yet confirmed against the applicable circular's specific document list.

## What is PENDING (the placeholder datum)

- The **exact document list per category** required by the VN bank / SBV for a `property_investment_foreign_direct_investment`-declared transfer.
- Whether Vietnamese banking/FX practice has a **narrower or differently-named** category specifically for individual (non-corporate) overseas real-estate purchase, versus the blueprint's four-value enum being a simplification.
- `purpose_documentation_required` as a concrete array: PENDING, not fabricated.

## Named re-ground obligation

Same as [`kb.vn-capital-controls.sbv-thresholds-2026`](sbv-thresholds-2026.md): the applicable SBV circular's category taxonomy, a licensed VN bank's compliance desk, or VN legal counsel engaged for the Mode-B wedge.

## Buyer / funder pointer

The plan tells the family: **declare the transfer's true purpose — buying property abroad — to the VN bank handling the outward transfer**, and expect this to require more documentation than a routine family-support remittance. It does not hand the family a specific document checklist until that checklist is sourced; it points them to their VN bank / a licensed provider to obtain the current one.

## Rules

Pure-reference (`fills: []`). All category-to-document-list mapping content is `is_placeholder: true`.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — the category-to-documentation mapping is not yet sourced against a primary; structure built, datum pending re-ground." },
    "property_funding_declares_as_investment_not_family_remittance": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a transfer funding an overseas property purchase declares under the investment/FDI-analogue category by purpose-of-funds, regardless of the sender-recipient family relationship — mis-declaring it as ordinary family remittance is a funder-side compliance risk, distinct from a platform labelling error." },
    "investment_category_likely_carries_heavier_documentation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER expectation, not confirmed — capital/investment-purpose categories are structurally expected to require more registration steps than current-account family-support remittances; the exact list is pending re-ground." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc.** The category-SELECTION principle (declare by purpose, not by relationship) is asserted now; the document-list content is PENDING.
- **Consumer:** `family_context` / `cross_border_funding` (component 7), `vn_capital_control_compliance.declared_purpose_category` / `.purpose_documentation_required`. Cross-refs: [`kb.vn-capital-controls.sbv-thresholds-2026`](sbv-thresholds-2026.md) (the same transfer's threshold/approval status), [`kb.vietnamese-family.financial-patterns`](../vietnamese-family/financial-patterns.md) (the funding-pattern this purpose-declaration attaches to).

## Sources

None yet — placeholder. Re-ground against the applicable SBV circular's category taxonomy, a licensed VN bank's compliance guidance, and/or VN legal counsel engaged for the Mode-B wedge (strategy §9).
