---
slug: kb.off-the-plan.risk-considerations
effective_from: 2025-08-01
last_verified: 2026-06-28
---

# Off-the-plan purchase — risk considerations

This doc grounds **`property_assessment`** (component 3, agent-reasoned) on the risks of buying **off-the-plan** — a dwelling bought before (or during) construction, on the strength of plans rather than a built product. It matters disproportionately for Mode B because a foreign person is **restricted to new builds** ([`kb.firb.eligible-property-types-foreign-persons`](../firb/eligible-property-types-foreign-persons.md)), so off-the-plan and house-and-land are the **main paths available** to them — the risks below are not edge cases for this buyer, they are the default terrain.

Single-owner discipline: the **completion valuation gap** and **sunset clauses** are owned by [`kb.building-types.risk-by-type`](../building-types/risk-by-type.md); the **cooling-off** period (NSW's longer off-the-plan window) by [`kb.cooling-off.by-state`](../cooling-off/by-state.md); the **FIRB approval-validity window** by [`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md). This doc owns the **risk catalogue as a whole** and the **one foreign-person-specific interaction** the other docs don't carry.

## The general off-the-plan risks (agent reasons over these)

- **Completion valuation gap.** At settlement the lender re-values the finished dwelling; in a soft or oversupplied market the valuation can land **below** the contracted price, and the bank lends only against the valuation — the buyer covers the shortfall in cash, and LVR/LMI are recalculated on the lower figure. Owned by [`kb.building-types.risk-by-type`](../building-types/risk-by-type.md); the foreign-person consequence is that the shortfall must be funded from the **cross-border transfer**, sizing it against an uncertain final valuation.
- **Construction delay / long, floating settlement.** Completion dates routinely slip (supply-chain, labour, builder capacity); a "2-years-away" project can settle much later. The settlement date is tied to completion, not a fixed calendar date.
- **Developer insolvency / non-completion.** If the developer fails before completion, the project may not be delivered; the deposit's protection depends on how it is held (below).
- **Deposit protection.** The deposit is generally held in a **trust account** (solicitor / conveyancer / licensed agent) until settlement, or covered by a **deposit bond** — it is not the developer's to spend. Confirm the deposit is held in trust, not released to the developer.
- **Sunset clauses.** A sunset clause lets either party rescind if the project is not completed by a long-stop date. In **NSW** and **VIC**, a **developer-initiated** sunset rescission requires the **buyer's written consent or Supreme Court approval** — a protection against developers deliberately delaying to re-sell at a higher price. Statute owned by [`kb.building-types.risk-by-type`](../building-types/risk-by-type.md) (NSW *Conveyancing Act 1919* s 66ZS; VIC *Sale of Land Act 1962* ss 10A–10F).
- **Cooling-off.** Off-the-plan cooling-off differs by state (NSW gives a longer window for off-the-plan than for established) — owned by [`kb.cooling-off.by-state`](../cooling-off/by-state.md).
- **Product risk.** What is delivered can differ from the display suite / render (finishes, size, aspect, strata mix); the strata scheme is unbuilt, so its [health indicators](../strata/health-indicators.md) cannot yet be read.

## The foreign-person-specific trap (owned here)

**An off-the-plan completion can outrun the FIRB approval window.** A FIRB approval to buy carries a **time limit to settle** (typically ~12 months — owned by [`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md) and the `firb_workflow` compliance gate). An off-the-plan dwelling whose construction slips can reach completion **after** the approval's window — leaving the foreign buyer to seek a fresh/extended approval before settling. So for a Mode B off-the-plan purchase the FIRB application is best **timed to the realistic completion window, not signed-contract date**, and the plan should treat a long completion as a live risk to approval validity. This interaction is unique to the foreign-person path and is this doc's reason to exist.

It compounds with the **cross-border transfer**: the VN-side funds must arrive for a settlement whose date floats with completion — so the transfer plan ([`cross_border_funding`](../../blueprints/fhb-foreign-au.md)) needs buffer and re-confirmation as the completion date firms, not a fixed early transfer.

## Rules

Pure-reference (`fills: []`) — `property_assessment` is agent-reasoned (viability / fit); this doc supplies the risk catalogue it reasons over, asserting no leaf. Cross-referenced regulated figures (valuation gap, sunset statute, cooling-off, FIRB window) live with their owners.

```jsonc
{
  "fills": [],
  "parameters": {
    "off_the_plan_is_primary_foreign_person_path": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "foreign persons are restricted to new builds (kb.firb.eligible-property-types-foreign-persons), so off-the-plan / house-and-land are their main paths — these risks are the default terrain, not edge cases." },
    "completion_can_outrun_firb_approval_window": { "type": "bool", "value": true, "provenance": "REGULATED (interaction)", "note": "FIRB approval has a settle-by window (~12mo, owned by kb.firb.approval-to-settlement-timeline); a slipped completion can land after it → time the FIRB application to realistic completion, not contract date. The foreign-person-specific trap this doc owns." },
    "deposit_held_in_trust": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "deposit generally held in trust (solicitor/conveyancer/agent) or via deposit bond until settlement; confirm it is not released to the developer." }
  },
  "lookup": {
    "off_the_plan_risk_catalogue": {
      "keydim": ["risk"],
      "provenance": "CONVENTION + cross-referenced REGULATED owners",
      "rows": [
        { "risk": "completion_valuation_gap",      "owner": "kb.building-types.risk-by-type",          "foreign_person_note": "shortfall funded from the cross-border transfer; size against uncertain final valuation" },
        { "risk": "construction_delay",            "owner": "this doc",                                "foreign_person_note": "floating settlement date; compounds the FIRB-window and transfer-timing risks" },
        { "risk": "developer_insolvency",          "owner": "this doc",                                "foreign_person_note": "non-completion; deposit protection depends on trust/bond" },
        { "risk": "deposit_protection",            "owner": "this doc",                                "foreign_person_note": "confirm held in trust / deposit bond, not released to developer" },
        { "risk": "sunset_clause",                 "owner": "kb.building-types.risk-by-type",          "foreign_person_note": "NSW/VIC require buyer consent or court approval for developer-initiated rescission" },
        { "risk": "cooling_off",                   "owner": "kb.cooling-off.by-state",                 "foreign_person_note": "NSW off-the-plan window longer than established" },
        { "risk": "firb_window_vs_completion",     "owner": "this doc",                                "foreign_person_note": "approval may lapse before a slipped completion — time the application to completion" },
        { "risk": "product_vs_render",             "owner": "this doc",                                "foreign_person_note": "delivered finishes/size/strata can differ; unbuilt strata can't be assessed yet" }
      ]
    }
  }
}
```

Notes:

- **Single-owner.** Valuation gap + sunset → [`kb.building-types.risk-by-type`](../building-types/risk-by-type.md); cooling-off → [`kb.cooling-off.by-state`](../cooling-off/by-state.md); FIRB approval-validity window → [`kb.firb.approval-to-settlement-timeline`](../firb/approval-to-settlement-timeline.md); eligibility of the new-build path → [`kb.firb.eligible-property-types-foreign-persons`](../firb/eligible-property-types-foreign-persons.md). This doc owns the **catalogue + the FIRB-window-vs-completion interaction**, restating none of the cross-referenced figures.
- **`firb_window_vs_completion` is the load-bearing addition.** It is the one off-the-plan risk that the (mode-agnostic) building-types / cooling-off docs do not carry, because it arises only when the buyer is a foreign person needing a time-limited approval.
- **Risk catalogue is grounded, not LLM-generated.** Each row names its owning doc; the agent reasons over the catalogue rather than inventing risks (reliability is structural). No regulated figure is asserted here.

## Sources

- Moneysmart (ASIC) — *Buying off the plan* (completion risk, valuation at settlement, deposit, developer risk) — https://moneysmart.gov.au/property/buying-off-the-plan
- Foreign Investment in Australia (Treasury/FIRB) — *Residential land* (new dwellings as the permitted foreign-person path) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
- NSW Fair Trading — *Off the plan purchases* (off-the-plan cooling-off; sunset-clause protections; deposit holding) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-off-the-plan
- Consumer Affairs Victoria — *Buying off the plan* (sunset clauses; what off-the-plan means) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property/buying-off-the-plan
