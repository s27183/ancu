---
slug: kb.vn-tax.income-from-foreign-property
effective_from: 2026-07-03
last_verified: 2026-07-03
sources:
  - note: "PLACEHOLDER — VN-side tax content is out of scope per the 2026-07-03 Mode-D scoping decision, sibling of kb.vn-tax.brackets-2026. A Vietnam-located investor's own VN tax advisor handles VN-side filing. Reconfirmed as an intentional, locked deferral during the 2026-07-06 Phase B backfill — not to be de-placeholdered without revisiting that scoping decision."
---

# ⚠ PLACEHOLDER — Vietnam's tax treatment of foreign (AU) property income (NOT SOURCE-GROUNDED)

**This doc's quantitative/procedural content is a labelled placeholder**, the sibling of [`kb.vn-tax.brackets-2026`](brackets-2026.md) — same scoped-deferral, same placeholder discipline. This doc grounds `tax_structure_non_resident` (component 7) `vn_side_tax_implications.foreign_tax_credit_for_au_tax_paid_in_vn` and the declaration-obligation question (does a VN-tax-resident investor need to declare AU rental/gain income on a VN return, and how).

## What can be stated now (stable principle, not a filing rule)

- **A VN tax resident who receives foreign (AU) rental income or a foreign capital gain is generally expected to declare it as part of worldwide income**, consistent with Vietnam's residence-based taxation principle already named in the sibling doc. The **specific declaration mechanism, timing, and whether a foreign tax credit is available for AU tax already paid** are not yet sourced.
- **This is distinct from the SBV capital-control question** — [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) governs whether/how funds may move between Vietnam and Australia; this doc concerns whether the *income itself* is a VN tax event, a separate question from the *transfer* of funds.

## What is PENDING (the placeholder datum)

- Whether Vietnam has a specific regime for individually-held foreign real estate income vs. treating it as ordinary foreign-sourced income.
- The foreign-tax-credit mechanism (if any) for AU tax already withheld/paid (FRCGW, AU rental-income tax) against a VN liability on the same income.
- Filing timing and documentation Vietnam requires to substantiate AU-sourced income and AU tax paid.

## Named re-ground obligation

Same as [`kb.vn-tax.brackets-2026`](brackets-2026.md): GDT Vietnam primary guidance or VN legal/tax counsel — explicitly deferred per the 2026-07-03 Mode-D scoping decision, not a build item for this wedge.

## Buyer / funder pointer

The plan states that AU rental income and capital gains may need to be declared in Vietnam and that a foreign-tax-credit mechanism may reduce double taxation, and directs the investor to their own VN-based tax advisor to confirm the current declaration obligation and credit mechanics — it does not assert a specific filing requirement or compute a credit.

## Rules

Pure-reference (`fills: []`). All content is `is_placeholder: true`.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — VN declaration/foreign-tax-credit mechanics not sourced; deferred per the 2026-07-03 Mode-D scoping decision." },
    "distinct_from_sbv_capital_control_question": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc concerns whether the INCOME is a VN tax event; whether FUNDS may move is the separate kb.vn-capital-controls.* concern — not conflated." },
    "foreign_tax_credit_availability_pending": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PENDING — whether/how AU tax already paid (FRCGW, rental-income tax) offsets a VN liability on the same income; not asserted true or false." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc.** Structure built, datum pending, deferral scoped by Son's own directive.
- **Consumer:** `tax_structure_non_resident.vn_side_tax_implications.foreign_tax_credit_for_au_tax_paid_in_vn` (component 7).
- **Distinct from its sibling.** `kb.vn-tax.brackets-2026` owns the *rate schedule*; this doc owns the *declaration obligation + foreign-tax-credit* question for foreign property income specifically.

## Sources

None yet — placeholder, deferred per the Mode-D scoping decision. If re-grounded: GDT Vietnam (Tổng cục Thuế), or VN legal/tax counsel.
