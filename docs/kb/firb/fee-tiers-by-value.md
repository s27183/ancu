---
slug: kb.firb.fee-tiers-by-value
effective_from: 2025-07-01
last_verified: 2026-06-28
---

# How the FIRB fee is set by purchase value — the banding rule

This doc owns the **rule** that turns a purchase price into a FIRB application fee: the fee is a **single flat amount determined by the consideration band the acquisition value falls into**, not a percentage and not a continuous function. It owns the *selection semantics*; the **dollar amounts** are owned by [`kb.firb.fee-schedule-current`](fee-schedule-current.md). This doc asserts **no figure** (so it never goes stale at the 1 July reindex — only the schedule's numbers do). It is read by the `firb_workflow` resolver (component 4) to pick the right band, and grounds the cash-position estimate the buyer sees early.

## The banding rule

1. **Bands are value brackets, right-closed.** Each band is "$X or less" — the applicable band is the **smallest band whose ceiling is ≥ the consideration**. A $720,000 purchase falls in the `≤$1m` band; a $1.4m purchase falls in the `≤$2m` band.
2. **The fee is the flat amount for that band** — every purchase in a band pays the same fee, regardless of where in the band it sits. There is **no pro-rata** within a band, so a purchase just over a band boundary pays the next band's (higher) flat fee — a small price increase across a boundary can step the fee up.
3. **Consideration = the higher of purchase price and market value.** The band is chosen on the acquisition's consideration; for a standard arm's-length purchase that is the contract price.
4. **Which table applies depends on the property type.** A foreign person buying a permitted **new dwelling / near-new / vacant residential land** uses the **non-established** schedule (the Mode-B path). The **established-dwelling** schedule (tripled) applies only to the off-path exception cases, since established dwellings are otherwise banned ([`kb.firb.established-dwelling-ban`](established-dwelling-ban.md)).
5. **The fee scales with value, in steps.** Larger purchases pay more, but in discrete jumps; from the $2m band upward each additional $1m band adds the same increment (the increment itself is a figure — owned by the schedule).

## Why the band, not a rate

The fee is a **cost-recovery charge set by regulation** (the *Foreign Acquisitions and Takeovers Fees Imposition Regulations 2020*), banded by Parliament rather than levied as a percentage of value. That is why the resolver must **look up** the fee, not multiply by a rate — and why the buyer-facing estimate is exact once the price is known (no rate assumption), subject only to the annual reindex.

## Rules

Pure-reference (`fills: []`). The resolver `firb_workflow` applies this selection rule: `band := smallest band with ceiling ≥ consideration`, `table := non_established if property_type ∈ permitted-new-or-vacant else established`, then reads `fee := kb.firb.fee-schedule-current[table][band]`. The selection logic is deterministic; the amount is the schedule's. No figure asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "fee_is_banded_flat_not_percentage": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the fee is a flat amount per consideration band, not a % of value — the resolver looks it up, never multiplies by a rate." },
    "band_is_smallest_ceiling_ge_value": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "bands are right-closed ('$X or less'); the applicable band is the smallest whose ceiling >= consideration." },
    "no_pro_rata_within_band": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "every purchase in a band pays the same flat fee; crossing a boundary steps the fee up." },
    "consideration_is_higher_of_price_or_market_value": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the band is selected on consideration (generally the contract price for an arm's-length purchase)." },
    "table_selected_by_property_type": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "non-established schedule for permitted new/near-new/vacant (the Mode-B path); established schedule (tripled) only for the off-path exception cases." }
  }
}
```

Notes:

- **Single-owner split with the schedule.** This doc = the *rule* (how value → band → which table). [`kb.firb.fee-schedule-current`](fee-schedule-current.md) = the *amounts* (the per-band dollars + the reindex obligation). Splitting them keeps the **durable structure** separate from the **dated figures** ([[build-time-structure-vs-runtime-data]]): the reindex touches only the schedule, not this rule.
- **Property-type → table** defers to [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md) for *which* types are permitted (and therefore which table); this doc only states that the type chooses the table.
- **Decision-support, not advice.** The exact fee for a buyer is confirmed at application; this rule lets the plan show a grounded estimate, removed from the LLM's reach.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Fees* (the fee depends on the value and kind of investment; banded structure) — https://foreigninvestment.gov.au/guidance/general/fees
- Foreign Investment in Australia — *Schedule of Fees*, Version 6 (2 January 2026) — the banded tables this rule selects across — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2026-01/schedule-of-fees.pdf
- *Foreign Acquisitions and Takeovers Fees Imposition Regulations 2020* — the fee-setting instrument (fees set by consideration band) — https://www.legislation.gov.au/Details/F2020L00563
