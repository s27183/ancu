---
slug: kb.lender.investment-loan-policies
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Investment-loan policies — lender constraints

Beyond serviceability (how much a lender will lend, owned by [`kb.lender.serviceability-investment-loans`](serviceability-investment-loans.md)), lenders apply **policy constraints** specific to investment lending: maximum LVR, interest-only availability and term, acceptable security, borrower-entity acceptance, and category exposure caps. This doc owns the **framework of policy levers** that vary by lender so `mortgage_finance` can frame which constraints to check and flag where an investor's situation (a trust borrower, a high-density apartment, an off-the-plan purchase) narrows the available lenders. It is a **reference** doc — the constraints are policy, not regulated constants; the precise per-lender values are confirmed with a broker. Informational; no lender recommendation (ACL line).

## Maximum LVR for investment

Investment loans are typically capped at a **lower maximum LVR** than owner-occupier loans. Above **80% LVR**, lenders mortgage insurance (LMI) applies and is **more expensive** for investment loans; above **90% LVR**, investment lending is restricted and many lenders will not write it. The practical planning assumption is a **20% deposit** to avoid LMI, with **10–12%** possible at a higher LMI cost (cross-ref [`kb.investor.deposit-requirements-investment-loans`](../investor/deposit-requirements-investment-loans.md)).

## Interest-only availability and term

IO is more freely available for investment than owner-occupier loans (the regulatory IO benchmark was removed in 2019), but lenders cap the **initial IO term** — commonly **up to 5 years**, sometimes extendable on reassessment (a fresh serviceability test). At the end of the IO period the loan reverts to P&I over the **residual** term (the payment-shock and serviceability consequence is owned by [`kb.loan.interest-only-vs-pi-investor`](../loan/interest-only-vs-pi-investor.md)).

## Acceptable security and category exposure

Lenders apply **security-category** policies that can restrict or exclude:

- **High-density apartments** — many lenders cap LVR (e.g. 70–80%) or require a larger deposit for apartments in large complexes, and some maintain **postcode exposure caps** (a list of suburbs/buildings where they limit lending).
- **Small or unusual dwellings** — studios, serviced apartments, or sub-minimum floor areas (often <40–50 m²) are restricted.
- **Off-the-plan / construction** — separate policy (valuation at completion risk; staged drawdowns).
- **Rural / lifestyle / high-land-value** — tighter LVR.

These are why the available-lender set narrows for certain properties — the plan flags the category, not a specific lender's list.

## Borrower-entity acceptance

Not every lender lends to every ownership structure. **Company and trust** borrowers (relevant to the entity choice in [`kb.tax.entity-comparison-personal-trust-company-smsf`](../tax/entity-comparison-personal-trust-company-smsf.md)) are accepted by fewer lenders and often on tighter terms (personal guarantees from directors/trustees, higher rates). **SMSF lending** (via a limited-recourse borrowing arrangement) is a specialist product offered by a small subset of lenders at lower max LVR (commonly ~70–80%) and higher rates. The plan flags that the entity choice constrains the lender set — a key interaction between the tax and finance clusters.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The structure narrows the lenders.** Choosing a trust or SMSF for tax reasons shrinks the lender set and tightens terms — the plan surfaces this trade-off so the entity decision is made with the financing consequence in view.
- **Apartment exposure caps matter in target suburbs.** High-density inner-suburb apartments (a common diaspora target) can hit LVR caps or postcode restrictions — flagged at property assessment.
- **IO term is finite.** The plan notes the IO period ends and reverts to P&I over a shorter term — no open-ended IO.
- **Information, not advice.** Policy values are lender-specific and change; the plan points to a broker and never recommends a lender (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; it supplies the policy-lever framework and representative bands the agent uses to flag which constraints a given property/entity triggers. The bands are CONVENTIONS (lender policy), not regulated constants; the 80%/90% LVR/LMI thresholds are the regulated capital-treatment boundaries (cross-ref `kb.lmi.calculation`).

```jsonc
{
  "fills": [],
  "parameters": {
    "lmi_threshold_lvr_pct":        { "type": "percentage", "value": 80, "note": "above 80% LVR LMI applies (more expensive for investment loans); regulated capital-treatment boundary — LMI calc owned by kb.lmi.calculation" },
    "investment_lvr_ceiling_pct":   { "type": "percentage", "value": 90, "note": "CONVENTION — above ~90% LVR investment lending is restricted; many lenders will not write it" },
    "io_initial_term_years_typical":{ "type": "integer", "value": 5, "note": "CONVENTION — typical maximum initial interest-only term (sometimes extendable on reassessment); reverts to P&I over the residual term thereafter" },
    "smsf_lrba_max_lvr_pct_typical":{ "type": "percentage", "value": 80, "note": "CONVENTION — SMSF limited-recourse borrowing offered by few lenders at lower max LVR (commonly ~70–80%) and higher rates" },
    "entity_borrower_narrows_lender_set": { "type": "bool", "value": true, "note": "company/trust/SMSF borrowers are accepted by fewer lenders on tighter terms — the entity choice constrains financing; surfaced as a tax↔finance interaction, never as a recommendation" }
  },
  "lookup": {
    "security_category_policy": {
      "note": "CONVENTION — representative lender security-category restrictions; resolver flags the category, never a specific lender's list",
      "entries": [
        { "category": "high_density_apartment", "constraint": "LVR cap ~70–80%, postcode exposure caps possible", "tier": "CONVENTION" },
        { "category": "small_dwelling_studio",  "constraint": "restricted below ~40–50 m²",                       "tier": "CONVENTION" },
        { "category": "off_the_plan_construction","constraint": "separate policy; completion-valuation risk",     "tier": "CONVENTION" },
        { "category": "rural_lifestyle",         "constraint": "tighter LVR",                                     "tier": "CONVENTION" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The doc supplies the policy-lever framework and representative bands; the agent applies them to flag which constraints a property/entity triggers and the resolver places no figure of its own here (capacity is owned by the serviceability doc, LMI by `kb.lmi.calculation`).
- **Policy, not regulated constants.** The IO term, LVR ceilings, security-category and SMSF-LRBA bands are lender CONVENTIONS that vary and change; only the 80% LMI boundary is a regulated capital-treatment line. Flagged accordingly to stay on the information side of the ACL line.
- **Tax↔finance interaction owned here.** That the entity choice narrows the lender set is stated here (finance consequence) and cross-referenced from the entity-comparison doc (the choice). No duplication.

## Sources

- APRA — *APG 223 Residential Mortgage Lending* (LVR, interest-only, exception monitoring) — https://handbook.apra.gov.au/ppg/apg-223
- APRA — *APRA to remove interest-only benchmark for residential mortgage lending* (2018/2019; IO benchmark removed, oversight retained) — https://www.apra.gov.au/news-and-publications/apra-to-remove-interest-only-benchmark-for-residential-mortgage-lending
- ASIC Moneysmart — *Lenders mortgage insurance (LMI)* (applies above 80% LVR) — https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi
- ASIC Moneysmart — *Loan to value ratio (LVR)* — https://moneysmart.gov.au/glossary/loan-to-value-ratio-lvr
