---
slug: kb.investor.target-yield-by-archetype
effective_from: 2026-06-26
last_verified: 2026-06-26
sources:
  # PLACEHOLDER doc — figures are NOT source-grounded (Son's call 2026-06-26). The entry below
  # is the named re-grounding candidate (CoreLogic/Cotality gross-yield-by-dwelling-type), not a
  # validation of the archetype defaults. Re-ground and bump last_verified before surfacing as authoritative.
  - url: https://propertyinvestmentprofessionals.com.au/research-insights/cotality-housing-chart-pack-april-2026-investor-analysis
    retrieved: 2026-07-06
---

# Default target gross yield by strategy archetype — PLACEHOLDER (pending authoritative source)

> **⚠ PLACEHOLDER — NOT SOURCE-GROUNDED.** The per-archetype target gross yields below are
> **indicative planning defaults**, not measured market figures. They give `investment_strategy` a
> defensible *default* `target_gross_yield` to derive from the agent-assigned archetype, so the
> downstream yield-anchored bid discipline (`buying_strategy.yield_anchored_max_price`) has a value
> to compute from when the investor has not stated their own target. They are **not** drawn from an
> authoritative series. Before any figure derived from these is surfaced as authoritative, the
> defaults **must** be re-grounded (candidates: a buyer's-agent / investment-advisory yield-target
> convention; SQM Research / CoreLogic gross-yield-by-dwelling-type series as a market anchor) and
> `last_verified` updated. Until then the resolver surfaces the derived anchor as **decision-support /
> indicative**, never as a target the investor must adopt. (Mirrors the [[capital-growth-bands]]
> labelled-placeholder pattern, Son's call 2026-06-26.)

## Why a default at all

`target_gross_yield` is the investor's **threshold** — the gross yield below which a deal stops
meeting their thesis ([`kb.investor.yield-anchored-pricing`](yield-anchored-pricing.md) inverts it
into the max-price anchor). Conceptually it is a *stated* preference; but plan-first onboarding
captures mode / price / zone / intent, not a numeric yield target, so at base there is none. Rather
than leave the whole yield-anchored discipline dormant, `investment_strategy` derives a **sensible
default from the archetype** the agent assigns — every archetype already sits on the income-now vs
value-later axis ([`kb.investor.strategy-archetypes`](strategy-archetypes.md)), so the archetype
implies a yield posture. The investor's own stated target (a future refine input) overrides this.

## The defaults (to be replaced / confirmed)

Aligned to each archetype's yield-vs-growth posture — `cash_flow` demands the highest yield (the
anchor bites hardest there), `capital_growth` accepts the lowest, the rest sit between. `land_banking`
has **no** yield target (current yield is minimal/negative — the thesis is not yield-driven), so its
default is `null` and the anchor does not apply.

- `cash_flow` → ~5.5% · `dual_income` → ~5.0% · `value_add` → ~4.5% · `balanced` → ~4.0% ·
  `capital_growth` → ~3.0% · `land_banking` → none (`null`)

These are **indicative defaults**, not market measurements. The resolver reads them by archetype and
sets `strategy_thesis.target_gross_yield`; the figure stays **decision-support**, never advice.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The anchor has a defensible starting value.** Even before the investor names a yield target, the
  plan can show a yield-anchored price ceiling derived from their thesis archetype — a discipline aid,
  clearly an editable default rather than a fixed rule.
- **Override is the point.** A first investor who states "I want at least 5%" replaces the default;
  the default just keeps the discipline from being silent at base.
- **Decision-support, not advice.** A default target yield is a planning convention, not a
  recommendation to demand a particular return. Information, not advice (ASIC).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. Everything above is
`content_md`. This is a **labelled-placeholder reference doc** — it fills no outcome slot;
`target_gross_yield` is **resolver-derived** in `fh_engine_fill:merge_agent/3` from the agent-assigned
`archetype` via the defaults below (the archetype is the agent's, the mapping to a number is the
resolver's — the figure stays out of the LLM's reach, §98).

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "note": "TRUE — indicative planning defaults, NOT a measured yield series; re-ground/confirm before surfacing as authoritative (Son, 2026-06-26)" },
    "target_gross_yield_cash_flow":      { "type": "percentage", "value": 5.5,  "note": "PLACEHOLDER — cash-flow thesis demands the highest yield; NOT source-grounded" },
    "target_gross_yield_dual_income":    { "type": "percentage", "value": 5.0,  "note": "PLACEHOLDER — two income streams lift the yield target; NOT source-grounded" },
    "target_gross_yield_value_add":      { "type": "percentage", "value": 4.5,  "note": "PLACEHOLDER — manufactured-value thesis, mid yield target; NOT source-grounded" },
    "target_gross_yield_balanced":       { "type": "percentage", "value": 4.0,  "note": "PLACEHOLDER — deliberate middle; NOT source-grounded" },
    "target_gross_yield_capital_growth": { "type": "percentage", "value": 3.0,  "note": "PLACEHOLDER — growth thesis accepts the lowest yield; NOT source-grounded" },
    "target_gross_yield_land_banking":   { "type": "percentage", "value": null, "note": "NONE — land banking is not yield-driven; the yield anchor does not apply" }
  }
}
```
