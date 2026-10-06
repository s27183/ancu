---
slug: kb.investor.property-management-vs-self-managed
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://www.fairtrading.nsw.gov.au/housing-and-property/property-professionals/managing-a-property
    retrieved: 2026-07-06
---

# Property management vs self-managed

An investor either pays a professional to manage the tenancy or does it themselves — a decision that trades a slice of yield for time, expertise, and risk transfer. This doc owns the **management-model decision framework** — what each model involves, the trade-offs, and when each fits. The PM **fee/cost** is owned by [`kb.investor.property-management-fees`](property-management-fees.md); this doc owns the *decision*. It grounds `ownership_planning_investor.property_management.management_mode` (`self_managed | professional_pm | hybrid`). It is a **decision-support** doc — it asserts no figure; it lays out the trade-offs. Informational; no advice on which to choose.

## The two models (and the hybrid)

- **Professional PM (`professional_pm`)** — a licensed agent handles letting, rent collection, inspections, repairs coordination, arrears, and the legal compliance of the tenancy (notices, bond, tribunal). Costs a management fee (% of rent) plus a letting fee — owned by [`kb.investor.property-management-fees`](property-management-fees.md). Buys time, expertise, arms-length tenant relations, and **compliance risk transfer**.
- **Self-managed (`self_managed`)** — the investor does it all: advertising, screening, the lease, bond lodgement, rent collection, inspections, repairs, and — critically — staying current with the state's tenancy law (including the minimum rental standards, [`kb.buyer-costs.investor-additional-costs`](../buyer-costs/investor-additional-costs.md)). Saves the fee (lifts net yield by ~the fee %), costs time and exposes the investor to compliance error.
- **Hybrid (`hybrid`)** — e.g. self-manage an existing good tenant but use an agent for letting, or use a "let-only" service. A middle that captures some saving while outsourcing the hardest parts.

## The trade-offs

- **Yield vs time.** Self-managing recovers the management fee directly into net yield — material on a thin-yield property — but the investor's time has a value, and tenancy admin is real work.
- **Compliance risk.** Tenancy law is detailed and state-specific and changing (minimum standards, notice grounds, bond rules). A professional carries that knowledge; a self-manager carries the **personal liability** for getting it wrong. This weighs heavily for a first-time or remote investor.
- **Distance.** Managing a property in another state — or from overseas — makes professional management close to necessary. Relevant where a Vietnamese-Australian investor diversifies interstate ([`kb.investor.scale-up-using-equity`](scale-up-using-equity.md)).
- **Tenant relations.** An agent is an arms-length buffer; self-management is direct, which some prefer and others find fraught.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The fee is a yield decision, not a default.** The plan shows the management fee as a yield line and frames self-managing as recovering it — against the time and compliance cost.
- **Compliance risk is real and personal.** The plan flags that a self-manager carries personal liability for tenancy-law compliance (minimum standards, notices, bond), which weighs toward professional management for first-timers.
- **Distance favours a PM.** For an interstate or overseas-adjacent holding, the plan leans toward professional management as practically necessary.
- **No recommendation.** The plan lays out the trade-offs; the investor chooses. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **decision-support** doc — it fills no slot; `management_mode` is an investor decision and the fee impact is computed by `yield_modelling` (the fee owned by the fees doc). This doc supplies the decision framework.

```jsonc
{
  "fills": [],
  "lookup": {
    "management_models": {
      "note": "the management_mode enum and each model's trade-offs — decision-support, not a recommendation",
      "entries": [
        { "model": "professional_pm", "involves": "agent handles letting, rent, inspections, repairs, compliance", "buys": "time, expertise, arms-length relations, compliance risk transfer", "costs": "management fee % + letting fee (kb.investor.property-management-fees)" },
        { "model": "self_managed", "involves": "investor does everything incl. staying current with tenancy law", "buys": "recovers the fee into net yield", "costs": "time + personal compliance liability (minimum standards, notices, bond)" },
        { "model": "hybrid", "involves": "e.g. let-only service or self-manage a good existing tenant", "buys": "partial saving + outsource the hardest parts", "costs": "partial fee" }
      ]
    }
  },
  "parameters": {
    "fee_is_a_yield_decision": { "type": "bool", "value": true, "note": "self-managing recovers the management fee into net yield — material on a thin-yield property — against the time + compliance cost" },
    "self_manager_carries_compliance_liability": { "type": "bool", "value": true, "note": "tenancy law is detailed, state-specific, and changing; a self-manager carries PERSONAL liability for getting it wrong — weighs toward a PM for first-time/remote investors" },
    "distance_favours_professional_pm": { "type": "bool", "value": true, "note": "managing interstate / from overseas makes professional management close to necessary (relevant to interstate diversification, kb.investor.scale-up-using-equity)" },
    "fee_owner": { "type": "string", "value": "kb.investor.property-management-fees", "note": "OWNED ELSEWHERE — the management fee, letting fee, sundries; this doc owns the decision, not the cost" }
  }
}
```

Notes:

- **No `fills`.** `management_mode` is an investor decision; the fee impact is computed by `yield_modelling`. This doc supplies the framework.
- **Single-owner via cross-ref.** Fee/cost → `kb.investor.property-management-fees`; compliance bar → `kb.buyer-costs.investor-additional-costs`; interstate diversification → `kb.investor.scale-up-using-equity`. This doc owns the PM-vs-self decision.
- **Decision-support.** Trade-offs only; no recommendation on which model to use.

## Sources

- ASIC Moneysmart — *Investing in property* (using a property manager vs managing yourself; the management fee) — https://moneysmart.gov.au/property-investment/investing-in-property
- NSW Fair Trading — *Managing your own rental property* and *minimum standards* (the compliance obligations a self-manager carries) — https://www.nsw.gov.au/housing-and-construction/renting
