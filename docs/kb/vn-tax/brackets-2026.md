---
slug: kb.vn-tax.brackets-2026
effective_from: 2026-07-03
last_verified: 2026-07-03
sources:
  - note: "PLACEHOLDER — VN-side tax content is out of scope per the 2026-07-03 Mode-D scoping decision; a Vietnam-located investor's own VN tax advisor handles VN-side filing. Doc exists as a structural anchor only (fills: [], pure-reference), asserting no VN tax law. Reconfirmed as an intentional, locked deferral during the 2026-07-06 Phase B backfill — not to be de-placeholdered without revisiting that scoping decision."
---

# ⚠ PLACEHOLDER — Vietnamese personal income tax brackets (NOT SOURCE-GROUNDED)

**This doc's quantitative content is a labelled placeholder.** Per the 2026-07-03 Mode-D scoping decision, VN-side tax content is explicitly out of scope for this wedge's regulated-build work: a Vietnam-located investor's own VN-based tax advisor handles VN-side filing, and the plan's job is limited to what the buyer owes **in Australia**. This doc exists so `investor_profile_foreign` (component 1) and `tax_structure_non_resident` (component 7) `vn_side_tax_implications` have a resolvable anchor — it structurally satisfies the compiler gates (`fills: []`, pure-reference) without asserting VN tax law.

## What can be stated now (stable principle, not a bracket table)

- **Vietnam taxes its residents on worldwide income**, which is why an AU-sourced rental or capital gain can, in principle, also be a VN tax event for a VN-tax-resident individual — the general reason this anchor exists at all, not a computed bracket application.
- **The Australia–Vietnam DTA may provide relief** (a foreign tax credit for AU tax already paid, or an exemption) — the mechanism, not the specific relief amount, is named in [`kb.au-vn-tax-treaty`](../au-vn-tax-treaty.md) (also a placeholder).

## What is PENDING (the placeholder datum)

- The current VND personal income tax bracket schedule and its applicability to foreign-sourced (AU) rental/capital-gain income.
- Whether AU rental/capital-gain income is taxed under Vietnam's ordinary progressive PIT schedule, a separate capital/investment-income rate, or another mechanism entirely.

## Named re-ground obligation

Before this doc's quantitative content can leave placeholder status: the current Vietnamese PIT circular/law governing foreign-sourced income for a VN tax resident, sourced from GDT Vietnam (Tổng cục Thuế) or VN legal/tax counsel. **Per the scoping decision, this re-grounding is explicitly deferred** — the buyer's own VN-based tax advisor is the intended channel, not a future platform build, unless Son revisits the scope.

## Buyer / funder pointer (what the plan says today)

The plan states that AU-sourced rental income and capital gains may also be a VN tax event for a VN-tax-resident investor, and directs the investor to **their own VN-based tax advisor** to determine the Vietnamese-side liability and any treaty relief — it does not compute or estimate a VN tax figure.

## Rules

Pure-reference (`fills: []`). All quantitative content is `is_placeholder: true`.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — VN PIT bracket content not sourced; deferred per the 2026-07-03 Mode-D scoping decision (buyer's own VN-based tax advisor handles VN-side liability)." },
    "vn_taxes_worldwide_income_for_residents": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "stable principle asserted now — the general reason AU-sourced income can also be a VN tax event; not a bracket computation." },
    "vn_tax_figure_never_computed_by_platform": { "type": "bool", "value": true, "provenance": "POLICY", "note": "the plan states that a VN tax event may arise and points to the investor's own VN-based advisor; it never estimates a VN tax liability figure." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc.** Mirrors Mode B's `kb.vn-capital-controls.*` placeholder discipline exactly ([[kb-doc-authoring]]'s fifth honesty move) — structure built, datum pending, deferral named and scoped by Son's own directive rather than left open-ended.
- **Consumer:** `investor_profile_foreign` (component 1), `tax_structure_non_resident.vn_side_tax_implications.vn_tax_on_au_rental_income` / `.vn_tax_on_au_capital_gain` (component 7).

## Sources

None yet — placeholder, deferred per the Mode-D scoping decision. If re-grounded: GDT Vietnam (Tổng cục Thuế) PIT circulars, or VN legal/tax counsel.
