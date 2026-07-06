---
slug: kb.investor.rental-appraisal-from-pm-agent
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://www.canstar.com.au/home-loans/how-much-rent-to-charge/
    retrieved: 2026-07-06
---

# Rental appraisal from a property manager

The single most load-bearing number in an investment thesis is the rent, and the most reliable source for a *specific* property is a property manager's written rental appraisal. This doc owns the **rental-appraisal-as-binding-rent** discipline — what a PM appraisal is, why it outranks a data-series estimate or a listing asking-rent, and how it feeds due diligence. It grounds `due_diligence.investor_specific_documents.rental_appraisal_from_pm_agent` and the binding rent that flows into [`kb.investor.rental-income-modelling`](rental-income-modelling.md) and the yield anchor ([`kb.investor.yield-anchored-pricing`](yield-anchored-pricing.md)). It is a **reference** doc — it asserts no rent figure; it names the authoritative source for one. Informational.

## What it is and why it binds

- **A written appraisal from a licensed property manager** who manages comparable stock in the suburb — an estimate of the achievable weekly rent for *this* property, in its current condition, in the current market. It typically comes with comparable lettings and a vacancy/demand read.
- **It outranks every other rent signal.** The provenance hierarchy ([`kb.property.rental-market-data-sources`](../property/rental-market-data-sources.md)) ranks rent sources *lodged-bond > published index > commercial estimate > listing*. A PM appraisal is property-specific and current — for a single property it is the binding figure, ahead of a suburb median or a portal asking-rent (asking ≠ achieved).
- **Get it before bidding.** The appraisal is a due-diligence input *and* a bid condition (`subject_to_satisfactory_rental_appraisal`, [`kb.investor.bid-discipline`](bid-discipline.md)). A thesis built on an optimistic rent that the market won't pay is a thesis built on sand — the appraisal is the reality check before the contract.
- **It's an estimate, not a guarantee.** A PM appraisal is a professional opinion, not a contracted rent; actual rent depends on the eventual tenant and market at letting. The plan treats it as the best available figure, not a certainty.

## How it feeds the plan

- The appraised weekly rent is the **binding `weekly_rent`** input to the income model ([`kb.investor.rental-income-modelling`](rental-income-modelling.md)) and therefore to gross yield, the yield-anchored price ceiling, and the whole cash-flow projection.
- A `rental_appraisal_significantly_below_expectation` flag (blueprint) fires when the appraisal undercuts the thesis — a direct prompt to re-examine the bid or walk away.
- The appraisal is distinct from the data-series *estimate* the agent uses pre-appraisal: before a property-specific appraisal exists, the plan models with a sourced range and labels it as an estimate; once the appraisal arrives, it replaces the estimate as the binding figure.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The rent number comes from someone who lets the street.** The plan treats a local PM's written appraisal as the binding rent — more trustworthy than a portal asking-rent or a suburb median.
- **Reality-check before the contract.** The plan makes the appraisal a bid condition, so an over-optimistic rent assumption is caught before committing.
- **Estimate now, appraisal binds later.** Before an appraisal exists the plan uses a clearly-labelled sourced estimate; the appraisal replaces it as the binding figure when obtained.
- **Still an opinion.** The plan presents the appraisal as the best available figure, not a guaranteed rent. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the appraisal is a due-diligence document and the binding rent input. This doc names the authoritative source; the figure itself is the appraisal's.

```jsonc
{
  "fills": [],
  "parameters": {
    "pm_appraisal_is_binding_rent": { "type": "bool", "value": true, "note": "a licensed PM's written rental appraisal is the binding per-property rent figure, ahead of a suburb median or a listing asking-rent; feeds kb.investor.rental-income-modelling and the yield anchor" },
    "provenance_owner": { "type": "string", "value": "kb.property.rental-market-data-sources", "note": "OWNED ELSEWHERE — the rent-source hierarchy (lodged-bond > index > commercial estimate > listing); a PM appraisal is the binding property-specific figure" },
    "get_it_before_bidding": { "type": "bool", "value": true, "note": "appraisal is a DD input AND a bid condition (subject_to_satisfactory_rental_appraisal, kb.investor.bid-discipline) — the reality check before the contract" },
    "appraisal_is_an_estimate_not_a_guarantee": { "type": "bool", "value": true, "note": "a professional opinion, not a contracted rent; actual rent depends on the eventual tenant and market at letting" },
    "estimate_replaced_by_appraisal": { "type": "bool", "value": true, "note": "before an appraisal exists, model with a sourced labelled estimate; the appraisal replaces it as the binding figure when obtained" }
  }
}
```

Notes:

- **No `fills`.** The appraisal is a DD document and the binding rent input; this doc names the authoritative source, the figure is the appraisal's own.
- **Single-owner via cross-ref.** Rent-source hierarchy → `kb.property.rental-market-data-sources`; income methodology → `kb.investor.rental-income-modelling`; bid condition → `kb.investor.bid-discipline`; yield anchor → `kb.investor.yield-anchored-pricing`. This doc owns the appraisal-as-binding-rent discipline.
- **Estimate vs appraisal.** The pre-appraisal data-series estimate is labelled as such; the PM appraisal binds once obtained — they are not the same figure.

## Sources

- ASIC Moneysmart — *Investing in property* (estimating rental income; getting a realistic rent figure) — https://moneysmart.gov.au/property-investment/investing-in-property
- NSW Fair Trading — *Property managers and agents* (the role and licensing of property managers) — https://www.nsw.gov.au/housing-and-construction/property-professionals
