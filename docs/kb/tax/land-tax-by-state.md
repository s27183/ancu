---
slug: kb.tax.land-tax-by-state
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://qro.qld.gov.au/land-tax/calculate/individual/
    retrieved: 2026-07-06
  - url: https://www.sro.vic.gov.au/land-tax-current-rates
    retrieved: 2026-07-06
  - url: https://www.wa.gov.au/organisation/department-of-treasury-and-finance/land-tax-assessment
    retrieved: 2026-07-06
  - url: https://www.sro.tas.gov.au/land-tax/rates-of-land-tax
    retrieved: 2026-07-06
  - url: https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/understanding-land-tax/thresholds-and-rates
    retrieved: 2026-06-23
  - url: https://www.sro.tas.gov.au/land-tax/foreign-investor-land-tax-surcharge
    retrieved: 2026-06-28
  - url: https://www.revenuesa.sa.gov.au/land-tax/rates-and-thresholds
    retrieved: 2026-06-28
  - url: https://www.revenue.act.gov.au/rates-and-property-charges/land-tax/how-land-tax-is-calculated
    retrieved: 2026-06-28
---

# Land tax — by state (investment property)

**Land tax** is an annual **state/territory** tax on the **total taxable land value** an owner holds in that jurisdiction (the site / unimproved value, not the house, aggregated across all their land in the state), assessed at a key ownership date. An owner-occupier's **principal place of residence is generally exempt** — but **investment land is taxable** above the state's threshold. This doc owns **the per-state scales, thresholds, the trust and foreign/absentee surcharges, and the aggregation principle** as **audit-anchored reasoning context**: `tax_structure` records this anchor and grounds its structuring reasoning in these scales, and `ownership_planning_investor` surfaces the aggregation principle as a qualitative portfolio alert. **No resolver computes a land-tax dollar figure** — deliberately: a per-property estimate would mislead without the portfolio-wide aggregate land value, and a regulated computed figure is kept out of the agent's reach. The PPOR **exemption** itself is owned by [`kb.land-tax.ppor-exemption`](../land-tax/ppor-exemption.md) (not duplicated here); the portfolio-level aggregation projection is owned by [`kb.investor.land-tax-aggregation`](../investor/land-tax-aggregation.md) (which consumes this doc's scales). Land tax is a regulated state schedule — informational; confirm with the relevant state revenue office.

## The load-bearing investor principle — aggregation

The single fact that most surprises investors: the threshold applies to the **combined taxable value of all the land you own in a state**, not per property. So a second or third investment property **climbs the whole portfolio up the scale** — and can push an owner from **nil** land tax across the threshold into a recurring annual bill. This aggregation is intrinsic to each state's scale below; the portfolio projection that rolls it up across holdings is owned by `kb.investor.land-tax-aggregation`.

A second load-bearing point: the **assessment date differs by state** — NSW and VIC assess land held at **31 December**, QLD at **30 June**. Buying just before vs after the date can shift the first year's liability.

## By state — the scales

**Primary-verified (confirmed against the revenue office — NSW, VIC, QLD, WA, TAS):**

| State | Assess date | General threshold | Rate above threshold | Foreign/absentee surcharge |
|---|---|---|---|---|
| **NSW** | 31 Dec | **$1,075,000** | **$100 + 1.6%** of value above the threshold (a higher *premium* tier applies above the premium threshold, then 2%) | **5%** surcharge land tax (foreign persons), **no threshold** |
| **VIC** | 31 Dec | **$50,000** (the lowest — bites early) | general scale from $50,000 (a temporary COVID-debt levy adds a flat surcharge in the lower bands) | **4%** absentee owner surcharge, on top of general/trust rates |
| **QLD** | 30 Jun | **$600,000** (individuals) | **$500 + 1c per $1** above $600,000 (first band) | **3%** absentee surcharge on land ≥ $350,000 |
| **WA** | 30 Jun | **$300,000** | **$300** flat ($300k–$420k); **$300 + 0.25%** above $420k; **$1,750 + 0.9%** above $1M; **$8,950 + 1.8%** above $1.8M; **$66,550 + 2.0%** above $5M; **$186,550 + 2.67%** above $11M — **plus metro MRIT 0.14%** of value above $300,000 | **none** (WA levies no foreign/absentee land-tax surcharge) |
| **TAS** | 1 Jul | **$125,000** | **$50 + 0.45%** of value above $125,000 ($125k–$500k); **$1,737.50 + 1.5%** above $500,000 | **2%** Foreign Investor Land Tax Surcharge (FILTS) on residential General Land |

**Partial — load-bearing threshold confirmed, marginal detail pending (SA, ACT; primary sites bot-walled this pass):**

| State | Confirmed (primary) | Pending |
|---|---|---|
| **SA** | general threshold **$833,000** (RevenueSA 2025-26; trust threshold $25,000); assess 30 Jun | full marginal bracket scale + foreign-surcharge confirmation — RevenueSA HTML/PDF returned 403; confirm the bands against RevenueSA |
| **ACT** | **no tax-free threshold** for investment land; assessed **quarterly**; fixed charge + marginal on Average Unimproved Value (AUV, 5-year averaged; $1M AUV threshold from 2024; marginal rates unchanged 2025-26) | exact fixed-charge dollar amount + marginal AUV rate brackets + foreign-surcharge — ACT Revenue HTML returned 403; confirm against ACT Revenue Office |

**No land tax:**

- **NT** — the Northern Territory **does not levy land tax** (a clean, load-bearing fact: land tax is nil for NT land).

Each state's **threshold** (the aggregation trigger — the load-bearing fact) is now primary-confirmed. WA and TAS additionally carry full primary-verified scales; **SA's marginal scale and ACT's exact figures remain `to_verify`** (the primary sites bot-walled this pass) — the resolver does not assert an exact figure from a secondary source for those two.

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
- **NT is nil; WA/TAS now primary-verified; SA/ACT detail deferred.** The plan states NT has no land tax, carries primary-verified scales for WA and TAS, and returns `to_verify` for SA's marginal scale and ACT's exact figures pending primary verification — it does not fabricate a scale.
- **Information, not advice.** The plan surfaces the per-state threshold, scale and aggregation principle from the verified schedules and points to the state revenue office; it computes no land-tax figure and issues no binding assessment.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot and **no resolver computes a land-tax figure** from it: the scales are audit-anchored reasoning context (`tax_structure` records the anchor; `ownership_planning_investor` surfaces the aggregation principle qualitatively), not a computed leaf. A per-property estimate is deliberately withheld — it needs the portfolio-wide aggregate value a single-property turn lacks, and a regulated figure stays out of the agent's reach. NSW/VIC/QLD/WA/TAS scales are REGULATED primary-verified; SA's threshold and ACT's no-threshold structure are primary-verified with their marginal detail pending (`to_verify`); NT is nil.

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
      "note": "per-state land-tax scales — reasoning context, not a computed leaf; no resolver derives a land-tax figure from these (a per-property estimate needs the portfolio-wide aggregate value and is withheld). Pending states carry verification:to_verify; never assert a secondary-source scale as exact",
      "entries": [
        { "state": "NSW", "assess_date": "31_dec", "general_threshold": 1075000, "rate_note": "$100 + 1.6% above threshold; premium tier then 2%", "foreign_surcharge_pct": 5, "verification": "PRIMARY (Revenue NSW)" },
        { "state": "VIC", "assess_date": "31_dec", "general_threshold": 50000,   "rate_note": "general scale from $50k; trust surcharge +0.375% from $25k; absentee +4%", "foreign_surcharge_pct": 4, "verification": "PRIMARY (SRO VIC)" },
        { "state": "QLD", "assess_date": "30_jun", "general_threshold": 600000,  "rate_note": "$500 + 1c/$ above $600k (first band); company/trust threshold $350k", "foreign_surcharge_pct": 3, "verification": "PRIMARY (QRO)" },
        { "state": "SA",  "assess_date": "30_jun", "general_threshold": 833000,  "rate_note": "general threshold $833k (trust threshold $25k); marginal bracket scale to_verify — RevenueSA primary site 403 this pass", "foreign_surcharge_pct": null, "verification": "PRIMARY (threshold; RevenueSA 2025-26) — scale to_verify" },
        { "state": "WA",  "assess_date": "30_jun", "general_threshold": 300000,  "rate_note": "$300 flat $300k-$420k; $300 + 0.25% above $420k; $1,750 + 0.9% above $1M; $8,950 + 1.8% above $1.8M; $66,550 + 2.0% above $5M; $186,550 + 2.67% above $11M; + metro MRIT 0.14% above $300k", "foreign_surcharge_pct": null, "verification": "PRIMARY (Treasury & Finance WA)" },
        { "state": "TAS", "assess_date": "01_jul", "general_threshold": 125000,  "rate_note": "$50 + 0.45% above $125k ($125k-$500k); $1,737.50 + 1.5% above $500k", "foreign_surcharge_pct": 2, "verification": "PRIMARY (SRO Tasmania, FILTS guideline 2025-12)" },
        { "state": "ACT", "assess_date": "quarterly", "general_threshold": 0,    "rate_note": "no tax-free threshold for investment land; fixed charge + marginal on AUV (5-yr averaged, $1M AUV threshold); exact fixed-charge + marginal rates to_verify — ACT Revenue primary site 403 this pass", "foreign_surcharge_pct": null, "verification": "PRIMARY (no-threshold structure; ACT Revenue) — figures to_verify" },
        { "state": "NT",  "assess_date": "n/a",    "general_threshold": null,    "rate_note": "no land tax", "foreign_surcharge_pct": null, "verification": "PRIMARY (nil)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`, and no computed figure.** No resolver derives a land-tax dollar figure from these scales — they are audit-anchored reasoning context (`tax_structure` records the anchor; `ownership_planning_investor` raises the aggregation principle as a qualitative alert). A per-property estimate is deliberately withheld (it needs the portfolio-wide aggregate value; a regulated figure stays out of the agent's reach). The doc supplies the scales, not a filled leaf or a computed assessment. Pending states carry `verification: to_verify`.
- **Verification tiers, explicitly tagged.** NSW/VIC/QLD/WA/TAS are **PRIMARY** (Revenue NSW / SRO VIC / QRO verified 2026-06-23; Treasury & Finance WA / SRO Tasmania verified 2026-06-28 against the live primary). **Re-verified 2026-07-06:** VIC ($50k), QLD ($600k), WA ($300k) and TAS ($125k) thresholds/scales were re-confirmed against the live primary (their revenue-office pages were reachable), unchanged after the 1 July 2026 reset; NSW ($1,075,000, assessed 31 Dec — already settled) was not reachable this pass (403), so its 2026-06-23 verification is carried. SA's **threshold** is **PRIMARY** ($833,000, RevenueSA 2025-26) but its marginal scale is **to_verify**; ACT's **no-threshold structure** is **PRIMARY** but its exact figures are **to_verify** — RevenueSA and ACT Revenue both returned HTTP 403 to direct fetch this pass (bot-walled), so the marginal detail could not be confirmed against the primary. NT is **nil** (primary). **Re-ground obligation (residual):** confirm SA's bracket scale + surcharge against RevenueSA and ACT's fixed-charge + marginal AUV rates against ACT Revenue Office (a freshness-pass trigger) — the bot-wall means a manual/authenticated fetch, not WebFetch.
- **Annual indexation.** Thresholds and bands are re-set annually (NSW per the 2026 land tax year; QLD per FY; SA gazetted annually) — `last_verified` is the freshness anchor; re-confirm on the annual pass.
- **Single-owner cross-refs.** PPOR exemption → `kb.land-tax.ppor-exemption`; portfolio aggregation projection → `kb.investor.land-tax-aggregation`; trust land-tax cost → `kb.tax.entity-comparison-personal-trust-company-smsf`; foreign-person status → `kb.firb.*`. This doc owns only the per-state scales + surcharge rates + the aggregation principle.
- **No federal-reform note.** The 2026-27 Budget CGT/negative-gearing reform is a *federal* change; land tax is a *state* tax and is unaffected by it.

## Sources

**Canonical (state revenue offices) — primary-verified NSW/VIC/QLD (2026-06-23):**

- Revenue NSW — *Land tax thresholds and rates* (general threshold $1,075,000; $100 + 1.6% above; aggregation across all land) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/understanding-land-tax/thresholds-and-rates
- Revenue NSW — *Surcharge land tax* (5% for foreign persons, no threshold) — https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/surcharge-land-tax
- State Revenue Office Victoria — *Land tax (current rates)* (general threshold $50,000; trust surcharge; absentee owner 4%) — https://www.sro.vic.gov.au/about-us/rates-and-statistics/current-rates/land-tax-current-rates
- Queensland Revenue Office — *Land tax rates for individuals* ($600,000 threshold; $500 + 1c/$ above) and *for absentees* (3% surcharge ≥ $350,000) — https://qro.qld.gov.au/land-tax/calculate/individual/

**Canonical (state revenue offices) — primary-verified WA/TAS (2026-06-28):**

- Department of Treasury and Finance WA — *Land tax assessment* (threshold $300,000; full bracket scale; MRIT 0.14% above $300,000; no foreign/absentee surcharge) — https://www.wa.gov.au/organisation/department-of-treasury-and-finance/land-tax-assessment
- State Revenue Office Tasmania — *Rates of land tax* (threshold $125,000; $50 + 0.45% then $1,737.50 + 1.5%) — https://www.sro.tas.gov.au/land-tax/rates-of-land-tax ; *Foreign Investor Land Tax Surcharge guideline* (2% on residential General Land, updated 2025-12) — https://www.sro.tas.gov.au/land-tax/foreign-investor-land-tax-surcharge

**Partial — threshold/structure primary-confirmed, marginal detail to_verify (2026-06-28; primary sites returned HTTP 403 to direct fetch — bot-walled):**

- RevenueSA — *Rates and thresholds* (general threshold **$833,000**, trust threshold $25,000, 2025-26 — confirmed; full bracket scale + surcharge not retrievable via WebFetch, 403) — https://www.revenuesa.sa.gov.au/land-tax/rates-and-thresholds
- ACT Revenue Office — *How land tax is calculated* (no tax-free threshold, quarterly, fixed charge + marginal AUV 5-yr averaged with $1M AUV threshold — confirmed; exact fixed-charge + marginal rates not retrievable via WebFetch, 403) — https://www.revenue.act.gov.au/rates-and-property-charges/land-tax/how-land-tax-is-calculated
