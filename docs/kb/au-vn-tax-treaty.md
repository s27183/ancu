---
slug: kb.au-vn-tax-treaty
effective_from: 2026-07-03
last_verified: 2026-07-03
---

# ⚠ PLACEHOLDER — the Australia–Vietnam Double Tax Agreement (NOT SOURCE-GROUNDED)

**This doc's quantitative/procedural content is a labelled placeholder** — the third of the Mode-D VN-side placeholder cluster, alongside [`kb.vn-tax.brackets-2026`](vn-tax/brackets-2026.md) and [`kb.vn-tax.income-from-foreign-property`](vn-tax/income-from-foreign-property.md). It grounds `tax_structure_non_resident` (component 7) `vn_side_tax_implications.au_vn_tax_treaty_relief_available`.

## The one load-bearing carve-out — read this before treating everything here as out of scope

**The Mode-D scoping decision draws the line at whether a fact changes an AU-side figure, not at whether the source document is the DTA.** If the treaty modifies an **AU** withholding rate — e.g. a reduced AU withholding rate on rental income or on FRCGW specifically for a VN-tax-resident, versus the ordinary domestic rate — that modification is **AU-side content and belongs in [`kb.non-resident.tax-treatment-overview`](non-resident/tax-treatment-overview.md)**, not here. **As of this authoring, `kb.non-resident.tax-treatment-overview` states no such AU-side rate modification has been identified or verified** — the FRCGW rate (15%) and the rental-assessment treatment are currently stated as ordinary domestic-law rates. This doc's placeholder status covers everything **except** that carve-out, which is a live open item, not a closed one: **verifying whether the DTA actually modifies an AU rate is exactly the kind of check the re-ground obligation below should resolve first**, since it's the one piece of treaty content that would need to move out of this placeholder and into the AU-side doc if confirmed.

## What can be stated now (stable principle, not treaty terms)

- **A bilateral DTA between Australia and Vietnam exists** and, as with any DTA, is expected to address double taxation of the same income (here: AU-sourced rental income and capital gains reaching a VN-tax-resident individual) via a foreign-tax-credit or exemption mechanism, and potentially modified withholding rates on specific income categories.
- **The specific relief mechanism, the exact income categories it covers, and whether it modifies any AU withholding rate for a VN-tax-resident** are not yet verified against the treaty text.

## What is PENDING (the placeholder datum)

- The treaty's specific provisions on real property income, capital gains, and any withholding-tax article.
- Whether Article-level treaty relief modifies AU rental-income assessment or the 15% FRCGW rate for a VN-tax-resident vendor — the carve-out question above.
- The VN-side credit/exemption mechanism for AU tax already paid.

## Named re-ground obligation

Verify against the treaty text itself (Australia–Vietnam DTA, as published by the Australian Treasury / austlii, or the ATO's tax treaty guidance) — **specifically checking the carve-out question (does it modify an AU rate) first**, since a positive finding there moves content into the AU-side doc rather than staying here. The broader VN-side declaration/credit mechanics remain deferred per the 2026-07-03 scoping decision regardless of that check's outcome.

## Buyer / funder pointer

The plan states that a tax treaty between Australia and Vietnam exists and may reduce double taxation on AU-sourced income, and directs the investor to their own VN-based tax advisor (and, for the AU-rate carve-out specifically, notes that the plan itself will state any confirmed AU-side rate modification once verified) — it does not assert specific treaty relief terms.

## Rules

Pure-reference (`fills: []`). All content is `is_placeholder: true`, except the carve-out check itself, which is an active open item rather than a deferred one.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — DTA provisions not verified against the treaty text; deferred per the 2026-07-03 Mode-D scoping decision." },
    "au_side_carve_out_is_a_live_open_item": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "unlike the rest of this doc, whether the DTA modifies an AU withholding rate is NOT deferred indefinitely — it is the one question that would move content into kb.non-resident.tax-treatment-overview if confirmed; currently no such modification has been identified." },
    "treaty_exists_between_au_and_vn": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a bilateral Australia-Vietnam DTA exists; its specific provisions on property income/CGT/withholding are the pending content." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder doc**, with one flagged live sub-item (the AU-rate carve-out) rather than a uniformly closed deferral.
- **Consumer:** `tax_structure_non_resident.vn_side_tax_implications.au_vn_tax_treaty_relief_available` (component 7). Cross-ref: `kb.non-resident.tax-treatment-overview` (owns any confirmed AU-side rate modification, per the carve-out).
- **Top-level file, single-segment slug.** `kb.au-vn-tax-treaty` has no further namespace segment — mirrors as `docs/kb/au-vn-tax-treaty.md` directly under the KB root, the first such case in this KB (every other doc so far lives under a folder); consistent with "the slug is its path," just a one-segment path.

## Sources

None yet — placeholder, deferred per the Mode-D scoping decision. If re-grounded: the Australia–Vietnam Double Tax Agreement text (Australian Treasury treaty texts, or ATO tax treaty guidance), checked first for the AU-rate carve-out.
