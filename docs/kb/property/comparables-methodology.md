---
slug: kb.property.comparables-methodology
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# Comparable-sales methodology

A property is worth what a willing buyer pays a willing seller — and the only evidence of that, before the sale, is what **similar properties recently sold for**. The **direct-comparison approach** is the method every valuer, agent and buyer uses to turn that evidence into a number: select comparable sales, adjust each for its differences from the subject property, and triangulate to a value range. This doc owns **how to read comparable sales into a value** — it grounds the `property_assessment` `market_position` reasoning (`comparable_sales`, `estimated_market_value_range`, both `agent_reasoning_required`, `reasoning_domain: valuation`), where the estimate is produced. (`buying_strategy` re-uses that estimate via `property_assessment.outcome` and reads it against market signals through `kb.comparables.reading-the-room`; it does not re-derive the valuation.) It supplies the method the agent reasons with, not a valuation of any one property. It does **not** read the *market signals* around the advertised price (that is `kb.comparables.reading-the-room`) or the per-type risk profile (`kb.building-types.risk-by-type`). Provenance is **CONVENTION** (Australian Property Institute valuation practice); every value it produces is **INDICATIVE**.

## What makes a sale comparable

A comparable sale is only useful to the degree it resembles the subject property and the resemblance is recent. Three axes:

- **Likeness.** Same `property_type`, similar bedrooms / bathrooms / car spaces, similar land size, similar condition and age, similar position (aspect, slope, frontage). A renovated 3-bed house is not comparable to an unrenovated one without adjustment.
- **Proximity.** Same suburb, ideally the same pocket / street profile; an adjoining suburb only if the market is genuinely continuous. Different school catchment, flood zone or transport access on the next street can move value materially.
- **Recency.** Sold within roughly the **last 3–6 months** — fresher in a fast-moving market. A sale from a year ago reflects a different market and needs a market-movement adjustment (or should be set aside).
- **Arm's-length.** Exclude related-party, distressed, or off-market transfers that didn't test the open market.

## Adjusting and triangulating

- **Adjust, don't average blindly.** Each comparable is adjusted **up or down** for its differences from the subject (an extra bedroom, a bigger block, a renovation, a worse aspect) before it informs the estimate. This is the core of the direct-comparison approach.
- **Use at least three.** Triangulate across **≥3** adjusted comparables so a single outlier (an over- or under-paid sale) doesn't drive the estimate. Three is also the floor a VIC Statement of Information and an agent's written appraisal must disclose (cross-ref `kb.comparables.reading-the-room`).
- **Output a range, not a point.** The result is an `estimated_market_value_range` (`money_range`) — a point estimate overstates precision the evidence doesn't support. The width of the range reflects how thin or scattered the comparable evidence is.

## Agent appraisal vs bank valuation — the load-bearing distinction

The **estate-agent appraisal and the lender's valuation are different numbers produced for different purposes**, and for a leveraged first-home buyer the **bank valuation is the one that governs the loan**:

- An **agent appraisal** is a selling estimate — and the advertised price is further constrained by underquoting law, not a valuation (cross-ref `kb.comparables.reading-the-room`).
- A **bank valuation** is a conservative, lender-instructed valuation that sets the **LVR, the LMI premium, and how much the lender will actually advance**. If it comes in **below the contract price**, the buyer funds the gap **in cash** and LMI / FHG are recalculated on the **lower** figure — the same trap as the off-the-plan completion gap (cross-ref `kb.building-types.risk-by-type`, `kb.lender.serviceability-basics`).

So the comparable-sales estimate is a **planning input**, not the financeable figure: the buyer should not assume the asking price, the agent appraisal, or even this estimate equals what the bank will lend against.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Build the buyer's own evidence base.** The plan shows the buyer how to read recent comparable sales (free state sources below) so they enter negotiation or auction with an independent value range, not the agent's framing.
- **The bank's number is the one that bites.** A second-language first-home buyer is most exposed to the appraisal-vs-bank-valuation gap; the plan states plainly that the bank valuation governs the loan and a low valuation means cash.
- **A range, with its width explained.** The agent presents an estimated range and says how confident the comparable evidence makes it — wide and tentative where sales are thin, tighter where the suburb turns over often.
- **Information, not advice.** The plan explains the method and points the buyer to recent sales data and, where the stakes warrant, an independent valuer; it does not itself certify a valuation or guarantee a bank's figure.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `comparable_sales` and `estimated_market_value_range` are **agent-reasoned** (`reasoning_domain: valuation`); this doc supplies the methodology the agent reasons with.

```jsonc
{
  "fills": [],
  "parameters": {
    "agent_appraisal_differs_from_bank_valuation": { "type": "bool", "value": true, "note": "CONVENTION (the load-bearing param) — the estate-agent appraisal / advertised price and the lender's valuation are different numbers; the BANK valuation governs the loan (LVR, LMI, amount advanced). If the bank values below contract price the buyer funds the shortfall in cash and LMI/FHG recalculate on the lower figure. The comparable-sales estimate is a planning input, not the financeable figure. See kb.building-types.risk-by-type, kb.lender.serviceability-basics." },
    "comparable_recency_window_months": { "type": "integer", "value": 6, "note": "CONVENTION — comparables are most reliable when sold within ~3–6 months; older sales need a market-movement adjustment or should be set aside. Indicative window, not a regulated figure." },
    "minimum_comparables": { "type": "integer", "value": 3, "note": "CONVENTION — triangulate across at least 3 adjusted comparables so a single outlier doesn't drive the estimate. (Also the disclosure floor for a VIC Statement of Information and an agent's written appraisal — see kb.comparables.reading-the-room.)" },
    "estimate_is_a_range_not_a_point": { "type": "bool", "value": true, "note": "CONVENTION — output an estimated_market_value_range, not a single figure; range width reflects how thin/scattered the comparable evidence is. A point estimate overstates precision." },
    "direct_comparison_requires_adjustment": { "type": "bool", "value": true, "note": "CONVENTION (the direct-comparison approach) — each comparable is adjusted up/down for its differences from the subject (beds, land, condition, position, market movement) before informing the estimate; never a blind average of raw sale prices." }
  },
  "lookup": {
    "comparable_strength": {
      "note": "CONVENTION — how the agent weights a candidate comparable. Strength = likeness × proximity × recency × arm's-length. Drives how much each sale moves the estimate.",
      "entries": [
        { "strength": "strong", "criteria": "same property_type and close on beds/baths/land/condition; same suburb pocket; sold within ~3 months; arm's-length", "weighting": "anchors the estimate" },
        { "strength": "moderate", "criteria": "similar type with adjustable differences; same/adjoining suburb; sold within ~3–6 months", "weighting": "informs after adjustment" },
        { "strength": "weak", "criteria": "different type/condition or pocket; sale older than ~6 months; or non-arm's-length", "weighting": "context only — set aside or heavily discount" }
      ]
    },
    "adjustment_dimensions": {
      "note": "CONVENTION — the differences a comparable is adjusted for before it informs the subject's estimate.",
      "entries": [
        { "dimension": "accommodation", "examples": "extra/fewer bedrooms, bathrooms, car spaces, internal area" },
        { "dimension": "land", "examples": "block size, frontage, usable land, subdivision potential" },
        { "dimension": "condition", "examples": "renovated vs original, age, structural/defect status" },
        { "dimension": "position", "examples": "aspect, slope, outlook, busy road vs quiet street, flood zone" },
        { "dimension": "market_movement", "examples": "time between the comparable sale and now, in a rising/falling market" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `comparable_sales` and `estimated_market_value_range` are produced by agent reasoning (`reasoning_domain: valuation`); this doc is the **method** the agent applies. Same pure-reference shape as the other `property_assessment` anchors (`kb.building-types.risk-by-type`, `kb.strata.health-indicators`) — confirming the rule that `property_assessment` outputs are agent-computed, so its KB anchors fill nothing.
- **Appraisal-vs-bank-valuation is the load-bearing param.** Like the off-the-plan valuation gap and the genuine-savings 1% rule, the doc's reason-to-exist is lifted out of prose into an explicit parameter so the agent reasons over it rather than burying it.
- **CONVENTION throughout; values INDICATIVE.** The direct-comparison approach is Australian Property Institute valuation practice, not a regulated formula; the recency window and range-width are judgment, not statute. Every number the method produces is an estimate, never a certified valuation or a guaranteed bank figure.
- **Single-owner across the valuation cluster.** This doc owns the **method**. The **market signals and the regulated price-disclosure regime** (Statement of Information / underquoting / no-price-guide-at-auction, and `asking_price_vs_market`) → `kb.comparables.reading-the-room`; **suburb-level risk/amenity** → `kb.property.suburb-risk-factors`; **per-type risk** → `kb.building-types.risk-by-type`; the **bank valuation's loan consequences** → `kb.lender.serviceability-basics` / the LMI pair. Cross-ref, not duplicated.

## Sources

**Canonical (regulators / industry — the method and the data):**

- Queensland Government — *Property valuations for buyers* (a valuer examines sales of similar properties and, after adjusting for differences, places a value on the subject; an agent's valuation must list at least 3 recent comparable sales) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/before-you-start-looking/property-valuations
- NSW Government — *How to find property sales information* (where recent comparable sales data comes from) — https://www.nsw.gov.au/housing-and-construction/land-values-nsw/how-to-find-property-sales-information
- Australian Property Institute — *direct-comparison approach* to market valuation (the professional standard for residential valuation; cited by designation — API practice standards).

**Point-in-time / practice (INDICATIVE):**

- The **comparable recency window** (~3–6 months) and **range width** are valuation judgment, not published figures — treated as CONVENTION/INDICATIVE.
- The **agent-appraisal-vs-bank-valuation** gap is lender practice, not a published number; surfaced as a planning risk, never a quantified prediction. See Moneysmart, *Buying a home* — https://moneysmart.gov.au/buying-a-home
