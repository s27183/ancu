---
slug: kb.special-conditions.standard-set
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/making-an-offer-on-a-property
    retrieved: 2026-07-06
    note: "NSW Government — private-treaty offers can be made subject to conditions; ~10% deposit at exchange; auction purchases are unconditional with no cooling-off. The specific condition set and the typical 14-21 day finance window are contract-drafting convention."
---

# Special conditions — the standard set to request

When a buyer makes a **private-treaty offer**, they can ask for **special conditions** in the contract — terms that make the purchase **conditional** on something being satisfied (finance, inspections) or that govern what is delivered (inclusions, vacant possession). A condition that isn't met gives the buyer a right to **terminate or renegotiate** without forfeiting the deposit. This doc owns **the standard set of special conditions a buyer should consider requesting and what each protects against**; it grounds the `due_diligence` parameter `special_conditions_to_request` and the `buying_strategy` parameters `conditions_to_include_in_offer.{subject_to_finance, subject_to_building_pest, subject_to_satisfactory_strata_report, other_special_conditions}`. These are **CONVENTION** — standard market practice and contract drafting, not statutory requirements (with the regulatory backbone that they only attach to a **conditional** purchase, i.e. **not at auction**).

## The standard conditions

- **Subject to finance.** The purchase is conditional on the buyer obtaining **loan approval** (for a stated amount, from a lender, by a stated date — commonly 14–21 days). If finance is not approved by the date, the buyer can terminate and recover the deposit. **The single most important protection for a first-home buyer** — it is what stands between a failed loan and a forfeited deposit. (Grounds the serviceability picture in `kb.lender.serviceability-basics`.)
- **Subject to satisfactory building and pest inspection.** Conditional on a building and pest inspection by a stated date being satisfactory; lets the buyer terminate or renegotiate on material defects. Interpretation of what's "material" is owned by `kb.building-pest.interpretation`.
- **Subject to satisfactory strata / body-corporate records inspection.** For a strata property — conditional on the owners-corporation/body-corporate records being satisfactory (funds, levies, disputes, special levies). Set true for strata, not for a freestanding house. Red-flag interpretation is owned by `kb.strata-report.red-flags`.
- **Subject to review of the contract / disclosure.** A due-diligence condition giving the buyer's conveyancer/solicitor time to review the contract (and in VIC the s32) — less common in hot markets but a genuine protection.
- **Settlement period.** The time from contract to settlement (commonly 30–90 days), negotiated to suit the buyer's finance and the vendor.
- **Deposit terms.** The deposit amount (commonly ~10%), when payable, and that it is **held in trust** by the agent/conveyancer until settlement.
- **Inclusions and exclusions.** Which **chattels and fixtures** stay (appliances, window furnishings, fixed items) — spelled out to avoid dispute at settlement.
- **Vacant possession vs subject to tenancy.** Whether the property is delivered **vacant** or with an existing lease in place — material for an owner-occupier who needs to move in.

## The auction exception — why this is the load-bearing branch

**Special conditions cannot be attached to an auction purchase.** A successful auction bid forms an **unconditional contract** with **no subject-to-finance, no subject-to-inspection, and no cooling-off** (see `kb.cooling-off.by-state`). So the conditions above are available **only on a private-treaty offer**. This is the core trade-off the bid plan surfaces: a private-treaty offer can be made safer with conditions but is slower and may lose to an unconditional rival; an auction bid is competitive but strips every protection, which is why **unconditional finance pre-approval and completed inspections must precede an auction**.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Subject-to-finance is the deposit-saver.** For a Mode A first-home buyer, losing the deposit because finance fell through is a real and avoidable harm. On a private-treaty offer the plan strongly surfaces the subject-to-finance condition (with a realistic approval date). At auction, where it is unavailable, the plan front-loads unconditional pre-approval.
- **Unconditional offers are a competitive lever with transferred risk.** In a hot market a buyer may be tempted to waive conditions to win. The plan presents this as a genuine trade-off — stronger offer, but the buyer carries the finance and defect risk — and never as a recommendation to waive.
- **Information, not advice.** The conditions are drafted into the contract by the buyer's conveyancer/solicitor; the plan surfaces the standard set and what each protects, and directs the buyer to their legal professional to draft and lodge them.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `special_conditions_to_request` and the `conditions_to_include_in_offer` flags are **resolver/agent-set** from the transaction mode and property type against this standard set (e.g. strata-records condition only for a strata property; finance/inspection conditions only for a conditional offer).

```jsonc
{
  "fills": [],
  "parameters": {
    "standard_conditions": { "type": "array<string>", "value": ["subject_to_finance", "subject_to_building_pest", "subject_to_strata_records", "subject_to_contract_review", "settlement_period", "deposit_terms", "inclusions_exclusions", "vacant_possession"], "note": "CONVENTION — the standard set of special conditions to consider on a private-treaty offer; drafted into the contract by the buyer's conveyancer/solicitor" },
    "subject_to_finance_is_primary_protection": { "type": "bool", "value": true, "note": "CONVENTION — subject-to-finance is the single most important condition for a FHB; its absence is what makes a finance failure forfeit the deposit. Grounds the serviceability picture in kb.lender.serviceability-basics" },
    "conditions_unavailable_at_auction": { "type": "bool", "value": true, "note": "REGULATED-adjacent / load-bearing — an auction purchase is unconditional: no subject-to-finance, no subject-to-inspection, no cooling-off (see kb.cooling-off.by-state). Special conditions attach only to a private-treaty offer. The core branch for the bid plan." },
    "strata_condition_only_for_strata": { "type": "bool", "value": true, "note": "the subject-to-strata-records condition applies only when the property is strata/owners-corporation; not set for a freestanding house" },
    "typical_finance_condition_days": { "type": "integer", "value": 21, "note": "CONVENTION — a subject-to-finance condition commonly allows ~14–21 days to obtain loan approval; the exact period is negotiated and stated in the contract" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The conditions to request are resolver/agent-selected from the transaction mode and property type against this standard set; the doc supplies the set and what each protects, not a per-deal list.
- **CONVENTION, not statute.** Special conditions are contract-drafting practice; the one regulatory fact is that they only attach to a **conditional** purchase (not auction). Tagged so the agent presents them as "conditions to consider requesting," drafted by the buyer's legal professional — never as a guaranteed term or as advice to waive.
- **The auction exception is the load-bearing fact.** Lifted to an explicit parameter (`conditions_unavailable_at_auction`) because it drives the entire bid-plan sequencing and ties this doc to `kb.cooling-off.by-state`: at auction there is neither cooling-off nor any condition, so all protection must be front-loaded.
- **Single-owner across the cluster.** This doc owns the **set of conditions and what each protects**. The **interpretation** behind each condition lives in its own anchor — building/pest materiality in `kb.building-pest.interpretation`, strata red flags in `kb.strata-report.red-flags`, the finance/serviceability picture in `kb.lender.serviceability-basics`, the cooling-off right in `kb.cooling-off.by-state`, the contract/s32 review in `kb.contract-of-sale.review-points-by-state` / `kb.s32.review-points`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities — the conditional-vs-auction backbone and standard practice):**

- NSW Fair Trading — *Making an offer on a property* (private-treaty offers can be made subject to conditions; auction purchases are unconditional with no cooling-off) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/making-an-offer-on-a-property
- Consumer Affairs Victoria — *Buying property by private sale* (subject-to-finance and other conditions on a private sale; auction purchases have no cooling-off) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property/buying-property-by-private-sale
- Queensland Government — *Contract of sale for buying a home* (finance and building/pest conditions; no structural-soundness warranty without inspection) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/making-an-offer-on-a-home/contract-of-sale

**Convention** — the specific set of special conditions and the typical 14–21-day finance window are standard market/contract-drafting practice, not figures set by any authority; the binding terms are those drafted into the individual contract by the buyer's conveyancer/solicitor.
