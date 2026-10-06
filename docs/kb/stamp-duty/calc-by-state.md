---
slug: kb.stamp-duty.calc-by-state
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://qro.qld.gov.au/duties/transfer-duty/calculate/rates/
    retrieved: 2026-07-06
  - url: https://qro.qld.gov.au/duties/transfer-duty/calculate/concession-rates/
    retrieved: 2026-07-06
  - url: https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-transfer-duty-non-principal-place-residence-current-rates
    retrieved: 2026-07-06
  - url: https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-transfer-duty-principal-place-residence-current-rates
    retrieved: 2026-07-06
---

# Transfer (stamp) duty — the statutory rate scale, by state

Transfer duty (NSW, QLD) / land transfer duty (VIC) is the single largest line in `cash_position`'s settlement total for most Mode A buyers. Each state levies it on a **progressive marginal scale**: the dutiable value falls in a bracket, and the duty is a **base amount for that bracket plus a marginal rate on every dollar above the bracket's lower bound**. This doc owns the **statutory base scale** — the rate table the resolver computes "duty otherwise payable" from. It does **not** own the first-home concessions that reduce it: those live in the scheme docs ([NSW FHBAS](../scheme/nsw/fhbas.md), [VIC FHB duty](../scheme/vic/fhb-duty.md), [QLD FHC](../scheme/qld/fhc.md) / [FHNHC](../scheme/qld/fhnhc.md)) and in the to-be-authored owner-occupier concessions (QLD home concession). The resolver **composes**: base scale here − concession from the scheme doc = `cash_position.stamp_duty.after_concession`. "Computed, not asserted" — the doc supplies the bracket coefficients; the arithmetic is resolver code.

**Scope:** the three Wedge-1 target states — **NSW, VIC, QLD**. Other states/territories are deferred until a blueprint targets them.

## How the calculation works

For a given **dutiable value** (in every state, the **greater of the price paid or the property's market value**), the resolver:

1. selects the state's scale and finds the bracket the dutiable value falls in;
2. applies `base + marginal_rate × (dutiable_value − bracket_lower_bound)` (the **marginal** case), **or** `flat_rate × dutiable_value` for the one VIC bracket that is charged flat on the whole value (noted below);
3. for **NSW and QLD**, the marginal step is charged "for each $100, **or part of $100**" above the lower bound — i.e. the excess is rounded **up** to the next whole $100 before the rate is applied (a few dollars; immaterial to planning but faithful to the statute). VIC applies straight percentages.

The result is the duty **before** any concession. The first-home concession (if eligible) is then subtracted by the scheme-doc resolver.

## NSW — transfer duty (Revenue NSW, *Duties Act 1997*)

A single standard scale; **the top two thresholds are indexed to CPI each 1 July**, so the figures below are the **2025–26** values and must be re-verified annually. **⚠ The 2026-07-06 verification pass could not confirm the 2026–27 indexed figures against the Revenue NSW primary (automated retrieval blocked); the two CPI-indexed top thresholds ($1,240,000 and $3,721,000) may have moved on 1 July 2026.** All Mode-A-relevant brackets (≤ $1,240,000 dutiable value — including the `$11,152 + 4.5% over $372,000` band that governs the typical FHB purchase) were corroborated as unchanged across current secondary NSW calculators; the QLD and VIC scales below were re-verified to the dollar against the QRO/SRO primaries this pass.

| Dutiable value | Duty |
|---|---|
| $0 – $17,000 | $1.25 per $100 (minimum $20) |
| $17,001 – $37,000 | $212 + $1.50 per $100 over $17,000 |
| $37,001 – $99,000 | $512 + $1.75 per $100 over $37,000 |
| $99,001 – $372,000 | $1,597 + $3.50 per $100 over $99,000 |
| $372,001 – $1,240,000 | $11,152 + $4.50 per $100 over $372,000 |
| $1,240,001 – $3,721,000 | $50,212 + $5.50 per $100 over $1,240,000 |
| Over $3,721,000 (premium) | $186,667 + $7.00 per $100 over $3,721,000 |

**Worked anchor:** an $800,000 home → $11,152 + 4.5% × ($800,000 − $372,000) = **$30,412** before concession. At $800,000 [FHBAS](../scheme/nsw/fhbas.md) gives a full exemption, so the net is **$0** — this is exactly the `before_concession` → `after_concession` spread the calculator shows.

## VIC — land transfer duty (State Revenue Office, *Duties Act 2000*)

VIC has **two** statutory scales. An owner-occupier buying a **principal place of residence (PPR) at $550,000 or under** uses the **PPR concessional scale**; everyone else (and any value above $550,000) uses the **general scale**. Both are published rate schedules, so both live here; the **first-home** exemption/concession ([VIC FHB duty](../scheme/vic/fhb-duty.md): full ≤ $600k, taper $600k–$750k) is a *further* reduction owned by that scheme doc and, for a Mode A FHB, usually **supersedes** the PPR rate in its range.

**General scale** (contracts on/after 1 Jul 2021):

| Dutiable value | Duty |
|---|---|
| $0 – $25,000 | 1.4% of dutiable value |
| $25,001 – $130,000 | $350 + 2.4% over $25,000 |
| $130,001 – $960,000 | $2,870 + 6% over $130,000 |
| $960,001 – $2,000,000 | **5.5% of the whole dutiable value** (flat — not marginal) |
| Over $2,000,000 | $110,000 + 6.5% over $2,000,000 |

**PPR concessional scale** (owner-occupier, dutiable value ≤ $550,000; contracts on/after 6 May 2008):

| Dutiable value | Duty |
|---|---|
| $0 – $25,000 | 1.4% of dutiable value |
| $25,001 – $130,000 | $350 + 2.4% over $25,000 |
| $130,001 – $440,000 | $2,870 + 5% over $130,000 |
| $440,001 – $550,000 | $18,370 + 6% over $440,000 |
| Over $550,000 | PPR concession does not apply → use the general scale |

**Worked anchor:** a $700,000 home is above the $550k PPR cliff, so general scale: $2,870 + 6% × ($700,000 − $130,000) = **$37,070** before concession (FHB concession then tapers in the $600k–$750k band).

## QLD — transfer duty (Queensland Revenue Office, *Duties Act 2001*)

One standard scale. QLD layers concessions **on top** of it: a **home concession** for owner-occupiers (a lower rate on the first $350,000 — `kb.scheme.qld.home-concession`, to be authored) and the **first-home** concessions ([FHC](../scheme/qld/fhc.md) established / [FHNHC](../scheme/qld/fhnhc.md) new). This doc owns only the **standard scale**; the concession layers are cross-referenced, not duplicated.

| Dutiable value | Duty |
|---|---|
| Not more than $5,000 | Nil |
| $5,001 – $75,000 | $1.50 per $100 over $5,000 |
| $75,001 – $540,000 | $1,050 + $3.50 per $100 over $75,000 |
| $540,001 – $1,000,000 | $17,325 + $4.50 per $100 over $540,000 |
| Over $1,000,000 | $38,025 + $5.75 per $100 over $1,000,000 |

**Worked anchor:** a $600,000 home → $17,325 + 4.5% × ($600,000 − $540,000) = **$20,025** at the standard rate, before the home concession and any first-home concession.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Duty is the cost the concessions exist to erase.** For an eligible Mode A FHB at the affordable end, the first-home concession often takes duty to **nil** (NSW ≤ $800k, VIC ≤ $600k) — so the plan's headline is usually the **`before_concession` figure as the "saving"**, not a cash outlay. The base scale here is what makes that saving computable.
- **State choice changes the number materially.** The same $700k purchase attracts different duty in each state, and the concession cliffs differ — surface the per-state comparison when a buyer is weighing target states (this composes with the favourable/unfavourable overseas-ownership tests already noted in the scheme docs).
- **Foreign-purchaser surcharge is *not* a Mode A cost.** Each state adds a surcharge for foreign persons (Mode B/D), on top of these rates. Mode A buyers (citizen/PR) do not pay it; it is deliberately **not tabled here** and belongs to the foreign-person blueprint work. Flagged so the calculator never applies it to a Mode A plan.
- **Information, not advice.** The calculator shows the duty and the concession transparently with its assumptions; it does not advise on structuring a purchase to minimise duty (that edges toward tax/legal advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference / formula-in-code doc** — it fills no slot. The `cash_position.stamp_duty.{before_concession, concession_applied, after_concession}` leaves are **resolver-computed**: this doc supplies the bracket scales; the scheme docs supply the concession; the resolver composes them.

```jsonc
{
  "fills": [],
  "parameters": {
    "states_covered":           { "type": "array<string>", "value": ["NSW", "VIC", "QLD"], "note": "Wedge-1 target states; other states/territories deferred until a blueprint targets them" },
    "dutiable_value_basis":     { "type": "string", "value": "greater_of_price_or_market_value", "note": "every state: duty is on the dutiable value = the higher of consideration (price) or unencumbered market value" },
    "scale_is_progressive_marginal": { "type": "bool", "value": true, "note": "duty = base for the bracket + marginal_rate × (dutiable_value − bracket lower bound); except the one VIC bracket flagged flat_on_total" },
    "nsw_top_thresholds_indexed_annually": { "type": "bool", "value": true, "note": "REGULATED — NSW indexes the $1,240,000 and $3,721,000 thresholds (and bracket bases) to CPI each 1 July; values here are 2025–26, re-verify annually (drives last_verified)" },
    "foreign_purchaser_surcharge_applies":  { "type": "bool", "value": true, "note": "each state adds a surcharge for FOREIGN persons (Mode B/D) on top of these rates; NOT a Mode A cost and deliberately not tabled here — belongs to the foreign-person blueprint" }
  },
  "lookup": {
    "nsw_standard_scale": {
      "note": "Revenue NSW standard transfer-duty scale, 2025–26. marginal_rate_pct charged 'for each $100 or part of $100' over lower_bound (round excess up to next $100). First bracket has a $20 minimum.",
      "rounds_marginal_to_part_of_100": true,
      "entries": [
        { "lower_bound": 0,       "upper_bound": 17000,   "base_duty": 0,      "marginal_rate_pct": 1.25, "calc_type": "marginal", "min_duty": 20, "note": "minimum duty $20 (data-driven; the kernel applies max(duty, min_duty))" },
        { "lower_bound": 17000,   "upper_bound": 37000,   "base_duty": 212,    "marginal_rate_pct": 1.5,  "calc_type": "marginal" },
        { "lower_bound": 37000,   "upper_bound": 99000,   "base_duty": 512,    "marginal_rate_pct": 1.75, "calc_type": "marginal" },
        { "lower_bound": 99000,   "upper_bound": 372000,  "base_duty": 1597,   "marginal_rate_pct": 3.5,  "calc_type": "marginal" },
        { "lower_bound": 372000,  "upper_bound": 1240000, "base_duty": 11152,  "marginal_rate_pct": 4.5,  "calc_type": "marginal" },
        { "lower_bound": 1240000, "upper_bound": 3721000, "base_duty": 50212,  "marginal_rate_pct": 5.5,  "calc_type": "marginal" },
        { "lower_bound": 3721000, "upper_bound": null,    "base_duty": 186667, "marginal_rate_pct": 7.0,  "calc_type": "marginal", "note": "premium property duty; threshold indexed annually" }
      ]
    },
    "vic_general_scale": {
      "note": "VIC SRO general land-transfer-duty scale (non-PPR / above $550k), contracts on/after 1 Jul 2021. Straight percentages, no part-of-$100 rounding.",
      "rounds_marginal_to_part_of_100": false,
      "entries": [
        { "lower_bound": 0,       "upper_bound": 25000,   "base_duty": 0,      "marginal_rate_pct": 1.4, "calc_type": "marginal" },
        { "lower_bound": 25000,   "upper_bound": 130000,  "base_duty": 350,    "marginal_rate_pct": 2.4, "calc_type": "marginal" },
        { "lower_bound": 130000,  "upper_bound": 960000,  "base_duty": 2870,   "marginal_rate_pct": 6.0, "calc_type": "marginal" },
        { "lower_bound": 960000,  "upper_bound": 2000000, "base_duty": 0,      "flat_rate_pct": 5.5,     "calc_type": "flat_on_total", "note": "QUIRK — charged at 5.5% of the WHOLE dutiable value, not marginally over the lower bound" },
        { "lower_bound": 2000000, "upper_bound": null,    "base_duty": 110000, "marginal_rate_pct": 6.5, "calc_type": "marginal" }
      ]
    },
    "vic_ppr_concessional_scale": {
      "note": "VIC SRO principal-place-of-residence concessional scale, owner-occupier, dutiable value ≤ $550,000, contracts on/after 6 May 2008. Above $550k it does not apply — use vic_general_scale. For a Mode A FHB the FHB exemption/concession (kb.scheme.vic.fhb-duty) usually supersedes this in its range.",
      "rounds_marginal_to_part_of_100": false,
      "applies_max_dutiable_value": 550000,
      "entries": [
        { "lower_bound": 0,      "upper_bound": 25000,  "base_duty": 0,     "marginal_rate_pct": 1.4, "calc_type": "marginal" },
        { "lower_bound": 25000,  "upper_bound": 130000, "base_duty": 350,   "marginal_rate_pct": 2.4, "calc_type": "marginal" },
        { "lower_bound": 130000, "upper_bound": 440000, "base_duty": 2870,  "marginal_rate_pct": 5.0, "calc_type": "marginal" },
        { "lower_bound": 440000, "upper_bound": 550000, "base_duty": 18370, "marginal_rate_pct": 6.0, "calc_type": "marginal" }
      ]
    },
    "qld_standard_scale": {
      "note": "QRO standard transfer-duty scale. marginal_rate_pct charged 'for each $100 or part of $100' over lower_bound. Owner-occupier home concession and first-home concessions layer on top — owned by the scheme docs, not here.",
      "rounds_marginal_to_part_of_100": true,
      "entries": [
        { "lower_bound": 0,       "upper_bound": 5000,    "base_duty": 0,     "marginal_rate_pct": 0,    "calc_type": "nil" },
        { "lower_bound": 5000,    "upper_bound": 75000,   "base_duty": 0,     "marginal_rate_pct": 1.5,  "calc_type": "marginal" },
        { "lower_bound": 75000,   "upper_bound": 540000,  "base_duty": 1050,  "marginal_rate_pct": 3.5,  "calc_type": "marginal" },
        { "lower_bound": 540000,  "upper_bound": 1000000, "base_duty": 17325, "marginal_rate_pct": 4.5,  "calc_type": "marginal" },
        { "lower_bound": 1000000, "upper_bound": null,    "base_duty": 38025, "marginal_rate_pct": 5.75, "calc_type": "marginal" }
      ]
    },
    "qld_home_concession_scale": {
      "note": "QRO home-concession rate schedule (owner-occupier) — a SECOND, lower QLD scale, NOT the standard one. It is the base the QLD first-home concession subtracts from: QRO computes 'duty at the home concession rate minus the additional [first-home] concession amount' (kb.scheme.qld.fhc). marginal_rate_pct charged 'for each $100 or part of $100' over lower_bound. The standalone home-concession ELIGIBILITY doc (kb.scheme.qld.home-concession) is still to author; this is only its rate SCALE, needed for the first-home arithmetic.",
      "rounds_marginal_to_part_of_100": true,
      "entries": [
        { "lower_bound": 0,       "upper_bound": 350000,  "base_duty": 0,     "marginal_rate_pct": 1.0,  "calc_type": "marginal" },
        { "lower_bound": 350000,  "upper_bound": 540000,  "base_duty": 3500,  "marginal_rate_pct": 3.5,  "calc_type": "marginal" },
        { "lower_bound": 540000,  "upper_bound": 1000000, "base_duty": 10150, "marginal_rate_pct": 4.5,  "calc_type": "marginal" },
        { "lower_bound": 1000000, "upper_bound": null,    "base_duty": 30850, "marginal_rate_pct": 5.75, "calc_type": "marginal" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `cash_position.stamp_duty.before_concession` is the resolver applying the state scale to the dutiable value; `concession_applied` comes from the eligible scheme doc; `after_concession` is the difference. The scheme docs' `duty_savings` leaves likewise read this scale. The doc is the **single owner of the base scale**; it asserts no duty figure for any specific purchase.
- **These are `lookup` tables, not `INDICATIVE`.** Unlike the [LMI rate matrix](../lmi/calculation.md) (proprietary, unpublished → indicative), duty scales are **published statutory schedules** — exact, regulated, ordered bands. They are real `lookup` data the resolver applies precisely, subject only to the per-$100 rounding rule and annual NSW indexation.
- **`calc_type` carries the arithmetic shape.** Almost every bracket is `marginal` (base + rate × excess). Two exceptions are encoded so the resolver doesn't mis-apply them: QLD's first bracket is `nil`, and VIC's $960k–$2M bracket is `flat_on_total` (5.5% of the entire dutiable value, a deliberate VIC quirk). `rounds_marginal_to_part_of_100` (true for NSW/QLD, false for VIC) carries the "or part of $100" rule.
- **VIC carries two scales by design.** The PPR concessional scale and the general scale are both SRO-published rate tables; which applies is control flow (owner-occupier? ≤ $550k?) → resolver code reading `applies_max_dutiable_value`. The FHB exemption is a third, separate layer owned by [`kb.scheme.vic.fhb-duty`](../scheme/vic/fhb-duty.md) — not re-derived here.
- **QLD carries two scales — standard and home-concession — both here.** Like VIC's two scales, both are published QRO rate schedules, so single-owner discipline puts both with the base scales: `qld_standard_scale` is "duty otherwise payable"; `qld_home_concession_scale` is the lower owner-occupier rate the **first-home** concession subtracts from (QRO: "home concession rate minus the additional concession amount"). The **first-home** concession *amount* (the stepped table) and FHC/FHNHC eligibility stay in their scheme docs; the standalone home-concession *eligibility* doc (`kb.scheme.qld.home-concession`) is still to author — only its rate scale is here, because the first-home arithmetic needs it. See [`stamp-duty-concession-mechanics.md`](../../architecture/stamp-duty-concession-mechanics.md) §3/§5.
- **Seam reconciliation (done).** Four concession docs previously pointed their `duty_savings` notes at speculative per-state `…-duty-rates` slugs authored before this doc existed; those named the data **this doc** now owns, so [fhbas.md](../scheme/nsw/fhbas.md), [fhb-duty.md](../scheme/vic/fhb-duty.md), [fhc.md](../scheme/qld/fhc.md) and [fhnhc.md](../scheme/qld/fhnhc.md) have been repointed here. (`kb.scheme.qld.home-concession` is a genuinely distinct doc still to author — left as-is.)

## Sources

- Queensland Revenue Office — *Transfer duty rates* (standard scale: nil ≤ $5,000; $1.50/$100 to $75,000; $1,050 + $3.50/$100 to $540,000; $17,325 + $4.50/$100 to $1,000,000; $38,025 + $5.75/$100 above; dutiable value = higher of consideration or market value) — https://qro.qld.gov.au/duties/transfer-duty/calculate/rates/
- State Revenue Office Victoria — *Land transfer duty – principal place of residence (current rates)* (PPR concessional scale to $550,000; does not apply above) — https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-transfer-duty-principal-place-residence-current-rates
- State Revenue Office Victoria — *Land transfer duty – non-principal place of residence (current rates)* (general scale, contracts on/after 1 Jul 2021; $960k–$2M flat 5.5%; $110,000 + 6.5% above $2M) — https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-transfer-duty-non-principal-place-residence-current-rates
- Revenue NSW — *Transfer duty* and *Calculate transfer duty* (standard scale and premium duty threshold) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/transfer-duty
- Revenue NSW — *How to calculate transfer duty* — the NSW 2025–26 standard scale ($1,597 + $3.50/$100 over $99,000; $11,152 + $4.50/$100 over $372,000; $50,212 + $5.50/$100 over $1,240,000; premium $186,667 + $7.00/$100 over $3,721,000) was confirmed against the Revenue NSW primary document (primary: `docs/sources/nsw/how_to_calculate_transfer_duty.pdf`) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/transfer-duty
