---
slug: kb.tax.land-tax-by-state
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Land tax — by state (investment property)

**Land tax** is an annual **state/territory** tax on the **total taxable land value** an owner holds in that jurisdiction (the site / unimproved value, not the house, aggregated across all their land in the state), assessed at a key ownership date. An owner-occupier's **principal place of residence is generally exempt** — but **investment land is taxable** above the state's threshold. This doc owns **the per-state scales, thresholds, the trust and foreign/absentee surcharges, and the aggregation principle** so `tax_structure` can compute a land-tax estimate and `ownership_planning_investor` can reason about land tax across a growing portfolio. The PPOR **exemption** itself is owned by [`kb.land-tax.ppor-exemption`](../land-tax/ppor-exemption.md) (not duplicated here); the portfolio-level aggregation projection is owned by [`kb.investor.land-tax-aggregation`](../investor/land-tax-aggregation.md) (which consumes this doc's scales). Land tax is a regulated state schedule — informational; confirm with the relevant state revenue office.

## The load-bearing investor principle — aggregation

The single fact that most surprises investors: the threshold applies to the **combined taxable value of all the land you own in a state**, not per property. So a second or third investment property **climbs the whole portfolio up the scale** — and can push an owner from **nil** land tax across the threshold into a recurring annual bill. This aggregation is intrinsic to each state's scale below; the portfolio projection that rolls it up across holdings is owned by `kb.investor.land-tax-aggregation`.

A second load-bearing point: the **assessment date differs by state** — NSW and VIC assess land held at **31 December**, QLD at **30 June**. Buying just before vs after the date can shift the first year's liability.

## By state — the scales

**Primary-verified (the wedge's core states — NSW, VIC, QLD):**

| State | Assess date | General threshold | Rate above threshold | Foreign/absentee surcharge |
|---|---|---|---|---|
| **NSW** | 31 Dec | **$1,075,000** | **$100 + 1.6%** of value above the threshold (a higher *premium* tier applies above the premium threshold, then 2%) | **5%** surcharge land tax (foreign persons), **no threshold** |
| **VIC** | 31 Dec | **$50,000** (the lowest — bites early) | general scale from $50,000 (a temporary COVID-debt levy adds a flat surcharge in the lower bands) | **4%** absentee owner surcharge, on top of general/trust rates |
| **QLD** | 30 Jun | **$600,000** (individuals) | **$500 + 1c per $1** above $600,000 (first band) | **3%** absentee surcharge on land ≥ $350,000 |

**Indicative — pending primary verification (SA, WA, TAS, ACT; secondary sources only, not yet confirmed against the revenue office):**

| State | General threshold (indicative) | Note |
|---|---|---|
| **SA** | ~$833,000 (RevenueSA, adjusted annually) | resolver → `to_verify`; confirm against RevenueSA |
| **WA** | ~$300,000 (+ metro MRIT 0.14%) | resolver → `to_verify`; confirm against RevenueWA |
| **TAS** | ~$125,000 | resolver → `to_verify`; confirm against SRO Tasmania |
| **ACT** | **no tax-free threshold** for investment land (fixed charge + marginal on Average Unimproved Value) | resolver → `to_verify`; confirm against ACT Revenue Office |

**No land tax:**

- **NT** — the Northern Territory **does not levy land tax** (a clean, load-bearing fact: land tax is nil for NT land).

The resolver **computes** a land-tax estimate for NSW/VIC/QLD from the verified scales and returns **`to_verify`** (with the indicative threshold noted) for SA/WA/TAS/ACT until those scales are primary-verified — it does not assert an exact figure from a secondary source.

## Trusts and foreign / absentee surcharges

Holding investment land in a **trust** typically **changes the land-tax position** — a cost the entity-comparison doc weighs:

- **NSW** — a **special trust** does **not** get the general threshold and is taxed at a flat **1.6%** (up to the premium threshold, then **2%**). A trust with any foreign beneficiary can attract **surcharge land tax**.
- **VIC** — a **trust surcharge** rate (an extra **0.375%**, from a lower **$25,000** threshold) applies on top of the general rate; an **absentee owner** surcharge of **4%** applies on top again.
- **QLD** — companies and trustees have a lower **$350,000** threshold; an **absentee** surcharge of **3%** applies to land ≥ $350,000.

The **foreign/absentee** surcharges are the diaspora hook: a Vietnamese-Australian investor who is a **foreign person / absentee for the state's test** (often tied to residency, distinct from FIRB — see [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md)) pays the surcharge on top of ordinary land tax. The trust surcharges are why a trust's asset-protection benefit ([`kb.tax.entity-comparison-personal-trust-company-smsf`](entity-comparison-personal-trust-company-smsf.md)) is weighed against a higher annual land-tax cost.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Aggregation is the portfolio trap.** Each new property climbs the whole holding up the state's scale; the plan surfaces the combined-value basis so the second purchase's land tax is not modelled as if the property stood alone.
- **VIC bites early.** At a **$50,000** threshold, Victorian investment land attracts land tax almost immediately — the sharpest per-state trap (also the trap that flips a former VIC home into taxable land once rented, owned by `kb.land-tax.ppor-exemption`).
- **Trust and foreign surcharges add up.** A trust structure or absentee status adds a recurring annual surcharge — surfaced so the entity choice and residency are weighed against the land-tax cost.
- **NT is nil; the smaller states are deferred.** The plan states NT has no land tax and returns `to_verify` for SA/WA/TAS/ACT pending primary verification — it does not fabricate a scale.
- **Information, not advice.** The plan estimates land tax from the verified state schedules and points to the state revenue office; it issues no binding assessment.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the land-tax figure is **resolver-computed** from these per-state scales against the property's state and the aggregated holding value (control flow → code, per §11.9), `to_verify` for the pending states. NSW/VIC/QLD scales are REGULATED primary-verified; SA/WA/TAS/ACT are INDICATIVE pending-primary; NT is nil.

```jsonc
{
  "fills": [],
  "parameters": {
    "land_tax_basis":                 { "type": "string", "value": "annual state tax on total taxable (site/unimproved) land value aggregated across all land held in the state, at the state's assessment date; PPOR generally exempt; investment land taxable above the threshold", "note": "REGULATED — the structural basis common to all land-tax states" },
    "aggregation_is_combined_value":  { "type": "bool", "value": true, "note": "REGULATED — the threshold applies to the COMBINED value of all land owned in the state, not per property; the portfolio roll-up is owned by kb.investor.land-tax-aggregation" },
    "nsw_general_threshold":          { "type": "money", "value": 1075000, "note": "REGULATED (Revenue NSW, 2026 land tax year) — general threshold; rate $100 + 1.6% above. Assess date 31 Dec" },
    "nsw_foreign_surcharge_pct":      { "type": "percentage", "value": 5, "note": "REGULATED (Revenue NSW) — surcharge land tax for foreign persons, no threshold" },
    "vic_general_threshold":          { "type": "money", "value": 50000, "note": "REGULATED (SRO VIC) — general threshold (lowest; bites early). Assess date 31 Dec. A temporary COVID-debt levy adds a flat surcharge in lower bands" },
    "vic_trust_surcharge_pct":        { "type": "percentage", "value": 0.375, "note": "REGULATED (SRO VIC) — trust surcharge rate on top of general, from a $25,000 trust threshold" },
    "vic_absentee_surcharge_pct":     { "type": "percentage", "value": 4, "note": "REGULATED (SRO VIC) — absentee owner surcharge on top of general/trust rates" },
    "qld_individual_threshold":       { "type": "money", "value": 600000, "note": "REGULATED (QRO) — individual threshold; rate $500 + 1c/$ above $600k (first band). Assess date 30 Jun. Company/trust threshold $350,000" },
    "qld_absentee_surcharge_pct":     { "type": "percentage", "value": 3, "note": "REGULATED (QRO) — absentee surcharge on land ≥ $350,000" },
    "nt_has_no_land_tax":             { "type": "bool", "value": true, "note": "REGULATED — the Northern Territory does not levy land tax (land tax = nil for NT land)" }
  },
  "lookup": {
    "land_tax_by_state": {
      "note": "per-state land-tax scales; resolver computes for verified states and returns to_verify for pending states (never asserts a secondary-source scale as exact)",
      "entries": [
        { "state": "NSW", "assess_date": "31_dec", "general_threshold": 1075000, "rate_note": "$100 + 1.6% above threshold; premium tier then 2%", "foreign_surcharge_pct": 5, "verification": "PRIMARY (Revenue NSW)" },
        { "state": "VIC", "assess_date": "31_dec", "general_threshold": 50000,   "rate_note": "general scale from $50k; trust surcharge +0.375% from $25k; absentee +4%", "foreign_surcharge_pct": 4, "verification": "PRIMARY (SRO VIC)" },
        { "state": "QLD", "assess_date": "30_jun", "general_threshold": 600000,  "rate_note": "$500 + 1c/$ above $600k (first band); company/trust threshold $350k", "foreign_surcharge_pct": 3, "verification": "PRIMARY (QRO)" },
        { "state": "SA",  "assess_date": "30_jun", "general_threshold": 833000,  "rate_note": "indicative — confirm against RevenueSA", "foreign_surcharge_pct": null, "verification": "INDICATIVE — to_verify" },
        { "state": "WA",  "assess_date": "30_jun", "general_threshold": 300000,  "rate_note": "indicative; + metro MRIT 0.14% — confirm against RevenueWA", "foreign_surcharge_pct": null, "verification": "INDICATIVE — to_verify" },
        { "state": "TAS", "assess_date": "01_jul", "general_threshold": 125000,  "rate_note": "indicative — confirm against SRO Tasmania", "foreign_surcharge_pct": null, "verification": "INDICATIVE — to_verify" },
        { "state": "ACT", "assess_date": "quarterly", "general_threshold": 0,    "rate_note": "no tax-free threshold for investment land; fixed charge + marginal on AUV — confirm against ACT Revenue", "foreign_surcharge_pct": null, "verification": "INDICATIVE — to_verify" },
        { "state": "NT",  "assess_date": "n/a",    "general_threshold": null,    "rate_note": "no land tax", "foreign_surcharge_pct": null, "verification": "PRIMARY (nil)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The land-tax figure is resolver-computed from the per-state scale against the property's state and the aggregated holding value; `to_verify` for the pending states. The doc supplies the scales, not a filled leaf.
- **Two verification tiers, explicitly tagged.** NSW/VIC/QLD are **PRIMARY** (Revenue NSW / SRO VIC / QRO, verified 2026-06-23); SA/WA/TAS/ACT are **INDICATIVE pending-primary** (secondary aggregators only — the resolver returns `to_verify` for them, per the secondary-aggregators-unreliable-on-exact-figures discipline); NT is **nil** (primary). **Re-ground obligation:** verify SA/WA/TAS/ACT scales against RevenueSA / RevenueWA / SRO Tasmania / ACT Revenue (a freshness-pass trigger).
- **Annual indexation.** Thresholds and bands are re-set annually (NSW per the 2026 land tax year; QLD per FY; SA gazetted annually) — `last_verified` is the freshness anchor; re-confirm on the annual pass.
- **Single-owner cross-refs.** PPOR exemption → `kb.land-tax.ppor-exemption`; portfolio aggregation projection → `kb.investor.land-tax-aggregation`; trust land-tax cost → `kb.tax.entity-comparison-personal-trust-company-smsf`; foreign-person status → `kb.firb.*`. This doc owns only the per-state scales + surcharge rates + the aggregation principle.
- **No federal-reform note.** The 2026-27 Budget CGT/negative-gearing reform is a *federal* change; land tax is a *state* tax and is unaffected by it.

## Sources

**Canonical (state revenue offices) — primary-verified (NSW/VIC/QLD), 2026-06-23:**

- Revenue NSW — *Land tax thresholds and rates* (general threshold $1,075,000; $100 + 1.6% above; aggregation across all land) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/understanding-land-tax/thresholds-and-rates
- Revenue NSW — *Surcharge land tax* (5% for foreign persons, no threshold) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/surcharge-land-tax
- State Revenue Office Victoria — *Land tax (current rates)* (general threshold $50,000; trust surcharge; absentee owner 4%) — https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-tax-current-rates
- Queensland Revenue Office — *Land tax rates for individuals* ($600,000 threshold; $500 + 1c/$ above) and *for absentees* (3% surcharge ≥ $350,000) — https://qro.qld.gov.au/land-tax/calculate/individual/

**Indicative (secondary, pending primary verification — labelled INDICATIVE, verified 2026-06-23):**

- Secondary land-tax guides for SA (~$833,000), WA (~$300,000 + MRIT), TAS (~$125,000), ACT (no threshold) — thresholds only; resolver returns `to_verify`; confirm against RevenueSA / RevenueWA / SRO Tasmania / ACT Revenue Office before asserting an exact scale.
