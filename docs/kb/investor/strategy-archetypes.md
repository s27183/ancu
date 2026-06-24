---
slug: kb.investor.strategy-archetypes
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Investment strategy archetypes

An investment property is bought to do a job, and the job defines the strategy. This doc owns the **archetype taxonomy** — the named investment strategies an investor's thesis is built on, what each one optimises for (yield vs growth vs both), the kind of property and location it favours, and its cash-flow and risk posture. It grounds `investment_strategy.thesis.strategy_archetype` (the `summary-card`'s `agent_reasoning_required` archetype enum) so the agent reasons over a stable, shared vocabulary rather than inventing labels. It is a **reference** doc — it asserts no figure; the archetype is agent-reasoned against the investor's goals. Informational; not a recommendation to pursue any particular strategy.

## The archetypes

The blueprint's `strategy_archetype` enum is `cash_flow | capital_growth | balanced | dual_income | value_add | land_banking`. Each is a coherent thesis:

- **`cash_flow`** — optimise for **net rental income** (high gross yield, positive or neutral geared). The property pays for itself or better; growth is secondary. Favours regional/affordable markets, higher-yielding dwelling types. Lower growth outlook, lower holding-cost risk, income resilience. The yield-anchored price ceiling ([`kb.investor.yield-anchored-pricing`](yield-anchored-pricing.md)) bites hardest here.
- **`capital_growth`** — optimise for **value appreciation** over the hold. Typically lower yield, often negatively geared early; the return is in the eventual sale (or equity release). Favours land-rich, broad-appeal, supply-constrained metro locations. Higher holding-cost burden, return depends on growth materialising and the hold horizon ([`kb.investor.hold-period-considerations`](hold-period-considerations.md)).
- **`balanced`** — a deliberate middle: acceptable yield *and* a credible growth outlook, neither maximised. The default thesis for many first investors who can't carry a deep cash-flow shortfall but want growth exposure.
- **`dual_income`** — a single title producing **two rental streams** (duplex, granny flat / secondary dwelling, dual-key, rooming). Raises gross yield without buying a second property; the value-add feature is owned by [`kb.property.investor-grade-features`](../property/investor-grade-features.md). Watch zoning/compliance and the narrower resale pool.
- **`value_add`** — buy below intrinsic value and **lift it actively** (renovate, subdivide, develop, re-lease at market). Return is *manufactured*, not waited for. Highest skill/capital/risk; a fresh depreciation schedule may follow a renovation ([`kb.investor.depreciation-schedule-procurement`](depreciation-schedule-procurement.md)).
- **`land_banking`** — hold **land** for future development/rezoning upside; current yield is minimal or negative. The longest horizon, the most speculative, the most sensitive to holding cost. Decision-support only — never framed as assured.

## Yield vs growth — the axis underneath

Every archetype sits on one axis: **income now vs value later**. `cash_flow` and `dual_income` pull toward income; `capital_growth` and `land_banking` pull toward value-later; `balanced` and `value_add` straddle. The archetype the agent assigns must be consistent with the investor's stated `target_gross_yield`, `target_capital_growth_per_year`, and `gearing_type` — an inconsistent thesis (e.g. `cash_flow` archetype with a negatively-geared, low-yield property) is the agent's signal to flag misalignment via `is_property_aligned_with_thesis`.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The thesis comes first, the property second.** The plan names the archetype the investor is actually pursuing, so each property is judged against *its* job — not a generic "good investment".
- **Cash-flow resilience matters for first investors.** For a household carrying its own mortgage, a `cash_flow` or `balanced` thesis limits the monthly shortfall; the plan surfaces the holding cost honestly rather than assuming growth bails it out.
- **Dual-income raises yield without a second purchase.** A common path — a granny flat or dual-key — is named as its own archetype, with the zoning/compliance caveat.
- **No archetype is "recommended".** The plan reflects the investor's goals back as a coherent thesis and checks property-fit; it does not advise which strategy to pursue. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; `strategy_archetype` is agent-reasoned (`reasoning_domain: investment_thesis`) and this doc supplies the shared archetype vocabulary the agent reasons within.

```jsonc
{
  "fills": [],
  "lookup": {
    "strategy_archetypes": {
      "note": "the strategy_archetype enum and what each optimises — the agent's reasoning vocabulary, not a recommendation",
      "entries": [
        { "archetype": "cash_flow", "optimises": "net rental income", "gearing_posture": "positive/neutral", "growth_outlook": "secondary", "risk": "lower holding-cost risk; income resilience" },
        { "archetype": "capital_growth", "optimises": "value appreciation over the hold", "gearing_posture": "often negative early", "growth_outlook": "primary", "risk": "higher holding burden; return depends on growth + horizon" },
        { "archetype": "balanced", "optimises": "acceptable yield + credible growth", "gearing_posture": "neutral-ish", "growth_outlook": "moderate", "risk": "deliberate middle; common first-investor default" },
        { "archetype": "dual_income", "optimises": "two rental streams on one title", "gearing_posture": "yield-lifted", "growth_outlook": "varies", "risk": "zoning/compliance; narrower resale pool", "feature_owner": "kb.property.investor-grade-features" },
        { "archetype": "value_add", "optimises": "manufactured value (reno/subdivide/develop)", "gearing_posture": "varies", "growth_outlook": "active", "risk": "highest skill/capital/execution risk" },
        { "archetype": "land_banking", "optimises": "future development/rezoning upside", "gearing_posture": "negative", "growth_outlook": "speculative", "risk": "longest horizon; most holding-cost sensitive; decision-support only" }
      ]
    }
  },
  "parameters": {
    "archetype_is_agent_reasoned": { "type": "bool", "value": true, "note": "strategy_archetype is set by the agent (reasoning_domain investment_thesis) against the investor's goals; this doc supplies the vocabulary, not a verdict" },
    "yield_vs_growth_is_the_underlying_axis": { "type": "bool", "value": true, "note": "every archetype sits on income-now vs value-later; the archetype must be consistent with target_gross_yield / target_capital_growth / gearing_type, else the agent flags is_property_aligned_with_thesis=false" }
  }
}
```

Notes:

- **No `fills`.** The archetype is agent-reasoned; this doc is the shared vocabulary the agent reasons within, not a setter of any outcome leaf.
- **Single-owner via cross-ref.** Dual-income feature → `kb.property.investor-grade-features`; yield-anchored ceiling → `kb.investor.yield-anchored-pricing`; hold horizon → `kb.investor.hold-period-considerations`; post-reno depreciation → `kb.investor.depreciation-schedule-procurement`. This doc owns only the archetype taxonomy.
- **No recommendation.** Archetypes are descriptive; the plan reflects the investor's chosen thesis and checks property-fit. It does not advise a strategy.

## Sources

- ASIC Moneysmart — *Property investment* (income vs growth as the basic investment-property trade-off) — https://moneysmart.gov.au/property-investment
- ASIC Moneysmart — *Investing in property* (the cash-flow vs capital-growth framing; the upfront and ongoing costs) — https://moneysmart.gov.au/property-investment/investing-in-property
