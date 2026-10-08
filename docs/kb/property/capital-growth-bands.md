---
slug: kb.property.capital-growth-bands
effective_from: 2026-09-08
last_verified: 2026-10-07
sources:
  - url: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/latest-release
    retrieved: 2026-10-07
    note: "ABS 6432.0 Total Value of Dwellings, June Quarter 2026 (released 8/09/2026; next release 1/12/2026). Table 2 'Median price and number of transfers (capital city and rest of state)' — previously published under 6416.0 Residential Property Price Indexes: Eight Capital Cities (RPPI ceased after Dec 2021)."
  - url: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/jun-quarter-2026/643202.xlsx
    retrieved: 2026-10-07
    path: docs/sources/abs/643202-total-value-dwellings-jun-qtr-2026-table2.xlsx
    note: "6432.0 Table 2 (sha256 59c36ca04559cf83659bf817be380a30263260baf1bc3cd0a7973b43b40f77ac) — the 16 capital-city median-price series (established houses + attached dwellings, unstratified, $'000, quarterly) the band is derived from; derivation in the doc body."
---

# Capital growth assumption bands — 3–6% p.a. nominal (ABS Total Value of Dwellings)

When a property is held over a multi-year horizon `H` and then sold, the **sale proceeds** depend on projected **capital growth** over `H`. This is the one genuinely *uncertain* input the temporal flow introduces (lifecycle-simulation-model §8.4). It is handled by the disciplines already in force for any estimate: **banded, never a point**; **resolver-computed, removed from the LLM's reach**; **decision-support, never a forecast or advice**. This doc owns the **growth band** the `disposition` resolver applies to project `sale_proceeds` over `H`.

**Honesty tier: CONVENTION** (invariants.md, *honesty tiers*). The band is a labelled convention derived from a named public series — ABS Total Value of Dwellings — not a regulated figure and not a forecast. It replaces the unsourced 2–5% PLACEHOLDER held from 2026-06-21 to 2026-10-07 (behavior 12).

## Why a band, not a number

A single growth rate asserted as "your home will be worth $X in 10 years" is both **wrong** (no one can know) and an **ASIC risk** (it reads as a financial forecast). A **band** — a conservative low / high pair compounded over `H` — surfaces the *range* of outcomes with the assumption stated, which is information, not prediction. The dispose-phase `sale_proceeds` is therefore a `money_range`, and an unparameterised projection renders **PENDING**, never a fabricated point.

## The band: 3% to 6% p.a. nominal

- **Low:** 3% p.a. nominal
- **High:** 6% p.a. nominal

The resolver compounds the band over `H` (`value_at_H = purchase_price × (1 + rate)^H`, applied at both ends) to produce the `sale_proceeds` range. At $800,000 over 10 years that is $1,075,133 – $1,432,678.

### Derivation (reproducible from the archived Table 2)

- **Series.** ABS 6432.0 *Total Value of Dwellings*, June Quarter 2026, **Table 2** — the median price of established house transfers and of attached dwelling transfers (unstratified, $'000), for each of the **eight capital cities**: 16 series. Rest-of-state series are excluded (the projection is a capital-city band). ABS ceased the RPPI after December 2021; Table 2 continues its median-price series, so the window reaches back to 2002.
- **Window.** 20 years: June quarter 2006 → June quarter 2026 (the latest release).
- **Method.** For each series, the compound annual growth rate `CAGR = (median_Jun2026 / median_Jun2006)^(1/20) − 1`, nominal.
- **Band.** The low end is the lowest capital-city CAGR rounded **down** to a whole percent; the high end is the highest rounded **down** to a whole percent. Both ends round toward under-promising: the band sits inside the observed spread, so the projection never claims more growth than every capital city achieved.

| Capital city | Houses: Jun 2006 → Jun 2026 ($'000) | CAGR | Attached: Jun 2006 → Jun 2026 ($'000) | CAGR |
|---|---|---|---|---|
| Sydney    | 495.0 → 1,487.6 | 5.66% | 390.0 → 840.0 | 3.91% |
| Melbourne | 345.0 → 850.0   | 4.61% | 306.6 → 590.0 | 3.33% |
| Brisbane  | 330.0 → 1,155.0 | 6.46% | 295.0 → 830.1 | 5.31% |
| Adelaide  | 286.0 → 975.0   | 6.32% | 235.0 → 725.0 | 5.79% |
| Perth     | 415.0 → 1,010.0 | 4.55% | 332.5 → 730.0 | 4.01% |
| Hobart    | 270.0 → 750.0   | 5.24% | 229.0 → 600.0 | 4.93% |
| Darwin    | 349.5 → 752.5   | 3.91% | 245.0 → 445.5 | 3.03% |
| Canberra  | 399.5 → 1,030.0 | 4.85% | 325.0 → 615.0 | 3.24% |

- **Spread observed:** 3.03% (Darwin, attached) to 6.46% (Brisbane, houses). Houses 3.91–6.46%; attached 3.03–5.79%.
- **Rounded band:** 3% (⌊3.03⌋) to 6% (⌊6.46⌋). 14 of the 16 series lie inside it; Brisbane houses (6.46%) and Adelaide houses (6.32%) grew faster than the high end.
- **Endpoint check.** A single quarter's median is noisy. Averaging the four quarters at each end (Sep 2005–Jun 2006 vs Sep 2025–Jun 2026) gives 3.27% to 6.38%, so the rounded band is the same.

### What the band is not

- **Historical, not a forecast.** It describes what capital-city medians did over 2006–2026. Nothing says the next 20 years repeat it, and the user-facing assumption line says so.
- **Medians, not a quality-adjusted index.** A median moves with the mix of what sold as well as with prices, so a single series can over- or under-state like-for-like growth.
- **One national band.** It is not per state or per dwelling type. Mode A has no property type at base, and a per-state band needs resolver plumbing; both are a later behavior if Son wants them. A buyer in a city at the band's edge (Darwin, Brisbane) sits in a range whose low or high end the city's own history did not reach.
- **Nominal.** Not inflation-adjusted.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The projection is a planning aid, not a promise.** A Mode A owner asking "if I hold 10 years and sell, where do I stand?" gets a *banded* equity-at-sale estimate with the growth basis stated — enough to compare holding horizons, not a guarantee.
- **Conservative by design.** Rounding both ends down keeps the dispose-phase net position honest; over-optimistic growth would inflate the graduation/upgrade story this figure feeds.
- **Re-verify each release.** ABS publishes Total Value of Dwellings quarterly (next: 1 December 2026). Re-running the derivation on a new release and updating `last_verified` is the freshness obligation; the band changes only if a rounded end moves.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. Everything above is `content_md`. This is a **reference doc** — it fills no slot; `disposition.sale_proceeds` is **resolver-computed** by compounding the band over the hold horizon `H`.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder":                 { "type": "bool", "value": false, "note": "FALSE — the band is derived from a named series (ABS 6432.0 Total Value of Dwellings, Table 2), behavior 12, 2026-10-07; the disposition resolver picks the sourced assumption line (kb.copy.disposition assumption_growth_sourced) on this flag" },
    "tier":                           { "type": "string", "value": "CONVENTION", "note": "honesty tier (invariants.md): a labelled band derived from a named public series — not regulated, not a forecast" },
    "growth_band_low_pct_pa_nominal": { "type": "percentage", "value": 3, "note": "lowest 20-year (Jun 2006 → Jun 2026) capital-city median-price CAGR in 6432.0 Table 2 = 3.03% (Darwin attached), rounded down" },
    "growth_band_high_pct_pa_nominal":{ "type": "percentage", "value": 6, "note": "highest 20-year (Jun 2006 → Jun 2026) capital-city median-price CAGR in 6432.0 Table 2 = 6.46% (Brisbane houses), rounded down" },
    "is_nominal":                     { "type": "bool", "value": true, "note": "bands are NOMINAL (not real / inflation-adjusted); state this in key_assumptions when surfaced" },
    "compounding":                    { "type": "string", "value": "value_at_H = purchase_price × (1 + rate)^H, applied at both band ends to yield a sale_proceeds money_range", "note": "the resolver's projection method over the hold horizon H" },
    "surface_as":                     { "type": "string", "value": "banded money_range with the growth basis stated in key_assumptions; PENDING when H or price unparameterised; never a point forecast", "note": "ASIC discipline — decision-support, not a forecast or advice" },
    "source_series":                  { "type": "string", "value": "ABS 6432.0 Total Value of Dwellings, Table 2 — median price of established house and attached dwelling transfers, 8 capital cities, Jun Qtr 2006 → Jun Qtr 2026", "note": "the series and window the band is derived from; re-run the derivation on each quarterly release and update last_verified" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.sale_proceeds` is resolver-computed by compounding the band over `H`; the doc supplies the band and the method, not a figure.
- **`is_placeholder` drives the user-facing label.** The resolver reads it and picks the copy line: sourced (names ABS Total Value of Dwellings, *historical, not a forecast*) when false, the PLACEHOLDER warning when true. Setting it back to true is the way to withdraw the source claim without an engine change.
- **One owner.** This doc owns the numeric growth band. `kb.property.growth-corridors-au` owns the qualitative outlook and `kb.property.rental-market-data-sources` the provenance map; both cross-reference here.

## Sources

- ABS — *Total Value of Dwellings*, June Quarter 2026 (cat. 6432.0, released 8 September 2026), Table 2 *Median price and number of transfers (capital city and rest of state)* — retrieved 2026-10-07, archived at `docs/sources/abs/643202-total-value-dwellings-jun-qtr-2026-table2.xlsx`.
