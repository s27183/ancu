---
slug: kb.foreign-investor.thesis-archetypes
effective_from: 2025-04-01
last_verified: 2026-07-03
---

# Foreign-investor strategy archetypes — the FIRB-driven viability overlay

This doc owns the **overlay** on the shared archetype vocabulary for a **foreign investor**: which of the six archetypes are practically reachable given the established-dwelling ban. It does **not** redefine the vocabulary — the archetype taxonomy (`cash_flow | capital_growth | balanced | dual_income | value_add | land_banking`) is owned by [`kb.investor.strategy-archetypes`](../investor/strategy-archetypes.md) and used as-is. It grounds `investment_strategy` (component 4) `thesis.strategy_archetype` for the foreign-investor case, so the agent reasons within a vocabulary that is already filtered to what's actually buildable, rather than proposing a thesis that turns out FIRB-blocked at `property_assessment`.

## The constraint: new-build / vacant-land only, while the ban is in force

[`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md) (1 Apr 2025 – 30 Jun 2029) and [`kb.firb.eligible-property-types-foreign-persons`](../firb/eligible-property-types-foreign-persons.md) already state — explicitly for Modes B/D — that a foreign person's permitted paths are **new/near-new dwellings, off-the-plan, house-and-land, and vacant residential land** (to develop within 4 years). Established dwellings are not available on any of the standard individual-investor exceptions (the supply-increasing exceptions are commercial-scale — 20+ dwelling redevelopment, BTR, PALM — and do not fit a single-dwelling investor).

## Archetype viability under the constraint

- **`cash_flow`, `capital_growth`, `balanced`** — reachable via **new-build / off-the-plan / house-and-land** stock. No change to the archetype's definition; only the *property universe* it draws from is narrower than a domestic investor's (established stock is excluded entirely).
- **`dual_income`** — reachable via a **new-build** dual-key / duplex / secondary-dwelling product; an *established* dual-income property (a common domestic dual-income path — buy an existing house, add a granny flat) is not available to a foreign investor while the ban is in force.
- **`land_banking`** — reachable and, if anything, a **more natural fit** for a foreign investor than for a domestic one: buying vacant residential land is explicitly permitted (with the 4-year construction condition), and land-banking's speculative, minimal-current-yield profile does not conflict with that condition as long as construction proceeds within the window.
- **`value_add` on established stock is not reachable.** The archetype's classic form — buy an established property below intrinsic value, renovate or subdivide — requires acquiring an established dwelling, which the ban prohibits for a foreign person outside the narrow commercial-scale exceptions. A foreign investor pursuing a `value_add` thesis must reframe it around a **new-build's value-add levers** (e.g. built-to-suit customisation at the off-the-plan stage, or the vacant-land 4-year construction obligation itself as the "value-add" work) — the agent should flag a `value_add` thesis proposed against an established property as **not aligned with FIRB eligibility**, not just "not aligned with the thesis" (`is_property_aligned_with_thesis = false`, with the specific FIRB reason named).

## Relevance for Vietnam-located investors (Mode D)

- **The thesis still comes first, but from a narrower property universe.** The plan names the archetype the investor is pursuing and reasons within the FIRB-permitted set from the start, rather than proposing a thesis and discovering the eligibility conflict later at property selection.
- **Land-banking and new-build capital-growth are the archetypes the ban least disrupts.** Both already assume new/vacant stock as their natural target.
- **`value_add` needs an early, explicit reframe** — established-property renovation is the one classic archetype path genuinely closed off, and the plan should say so plainly rather than let the investor discover it property-by-property.
- **No archetype is "recommended."** Same discipline as the base doc — descriptive, agent-reasoned, decision-support only.

## Rules

Pure-reference (`fills: []`). `strategy_archetype` remains agent-reasoned (`reasoning_domain: investment_thesis`); this doc supplies the FIRB-filtered viability the agent reasons within, on top of the shared vocabulary owned by `kb.investor.strategy-archetypes`.

```jsonc
{
  "fills": [],
  "lookup": {
    "foreign_investor_archetype_viability": {
      "note": "which archetypes are reachable given the established-dwelling ban's new-build/vacant-land-only constraint; the archetype definitions themselves are owned by kb.investor.strategy-archetypes",
      "entries": [
        { "archetype": "cash_flow", "reachable": true, "note": "via new-build/off-the-plan/house-and-land stock" },
        { "archetype": "capital_growth", "reachable": true, "note": "via new-build stock" },
        { "archetype": "balanced", "reachable": true, "note": "via new-build stock" },
        { "archetype": "dual_income", "reachable": true, "note": "via a new-build dual-key/duplex product; an established-plus-granny-flat path is not available" },
        { "archetype": "value_add", "reachable": false, "note": "the classic established-property-renovation form requires an established dwelling — banned; reframe around new-build customisation or the vacant-land construction obligation, or flag not-aligned" },
        { "archetype": "land_banking", "reachable": true, "note": "a natural fit — vacant residential land is explicitly permitted with a 4-year construction condition" }
      ]
    }
  },
  "parameters": {
    "value_add_on_established_flagged_as_firb_ineligible": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a value_add thesis proposed against an established property should be flagged is_property_aligned_with_thesis=false with the specific FIRB reason (established-dwelling ban), not a generic misalignment note." }
  }
}
```

Notes:

- **No `fills`.** The archetype remains agent-reasoned; this doc narrows the property universe the reasoning draws from, it does not add a new outcome leaf.
- **Single-owner via cross-ref.** Archetype definitions → `kb.investor.strategy-archetypes`; the ban window/exceptions → `kb.firb.established-dwelling-ban`; the permitted property-type taxonomy → `kb.firb.eligible-property-types-foreign-persons`. This doc owns only the viability overlay.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Residential land* (permitted property types for foreign persons; vacant-land construction condition) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
- Foreign Investment in Australia — *Changes to foreign purchases of established dwellings* (established-dwelling ban, window, exceptions) — https://foreigninvestment.gov.au/news-and-reports/news/changes-foreign-purchases-established-dwellings
