---
slug: kb.property.capital-growth-bands
effective_from: 2026-06-21
last_verified: 2026-06-21
---

# Capital growth assumption bands — PLACEHOLDER (pending authoritative source)

> **⚠ PLACEHOLDER — NOT SOURCE-GROUNDED.** The growth bands below are a deliberately conservative, **unverified placeholder** held so the `disposition` component compiles and the dispose-phase projection has a shape to fill. They are **not** drawn from an authoritative series yet. Before this doc is used to surface any figure to a user, the band **must** be re-grounded against a named series (candidates: **ABS Residential Property Price Index (RPPI)** for capital-city long-run growth; **CoreLogic Home Value Index** long-run; or a state Valuer-General median series), and `last_verified` updated. Until then the resolver surfaces the projection as **PENDING / banded estimate** with the placeholder basis stated in `key_assumptions`, never as a forecast. (Son's call, 2026-06-21: hold as a labelled placeholder.)

When a property is held over a multi-year horizon `H` and then sold, the **sale proceeds** depend on projected **capital growth** over `H`. This is the one genuinely *uncertain* input the temporal flow introduces (lifecycle-simulation-model §8.4). It is handled by the disciplines already in force for any estimate: **banded, never a point**; **resolver-computed, removed from the LLM's reach**; **decision-support, never a forecast or advice**. This doc owns the **growth band** the `disposition` resolver applies to project `sale_proceeds` over `H`.

## Why a band, not a number

A single growth rate asserted as "your home will be worth $X in 10 years" is both **wrong** (no one can know) and an **ASIC risk** (it reads as a financial forecast). A **band** — a conservative low / high pair compounded over `H` — surfaces the *range* of outcomes with the assumption stated, which is information, not prediction. The dispose-phase `sale_proceeds` is therefore a `money_range`, and an unparameterised projection renders **PENDING**, never a fabricated point.

## The placeholder band (to be replaced)

Pending the authoritative series, a conservative nominal band is held. It is intentionally wide and low-anchored so that, if used before re-grounding, it under-promises rather than over-promises:

- **Conservative low:** ~2% p.a. nominal
- **Conservative high:** ~5% p.a. nominal

These are **placeholders**. Long-run Australian capital-city dwelling growth has historically been discussed in a broad nominal range, but **the specific figures here are not yet tied to a verified series** and must not be cited as such. The resolver compounds the band over `H` (`value_at_H = purchase_price × (1 + rate)^H`, applied at both ends of the band) to produce the `sale_proceeds` range.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The projection is a planning aid, not a promise.** A Mode A owner asking "if I hold 10 years and sell, where do I stand?" gets a *banded* equity-at-sale estimate with the growth assumption stated — enough to compare holding horizons, not a guarantee.
- **Conservative by design.** A low-anchored band keeps the dispose-phase net position honest; over-optimistic growth would inflate the graduation/upgrade story this figure feeds.
- **Re-grounding is a tracked obligation.** Because this doc is a labelled placeholder, the freshness/curation pass treats it as **stale-by-construction** until a named series replaces the band.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. Everything above is `content_md`. This is a **reference doc** — it fills no slot; `disposition.sale_proceeds` is **resolver-computed** by compounding the band over the hold horizon `H`.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder":                 { "type": "bool", "value": true, "note": "TRUE — these bands are an unverified placeholder, NOT drawn from an authoritative series; re-ground before surfacing any figure (Son, 2026-06-21)" },
    "growth_band_low_pct_pa_nominal": { "type": "percentage", "value": 2, "note": "PLACEHOLDER — conservative low nominal capital growth p.a.; NOT source-grounded; replace with a named series (ABS RPPI / CoreLogic / state Valuer-General)" },
    "growth_band_high_pct_pa_nominal":{ "type": "percentage", "value": 5, "note": "PLACEHOLDER — conservative high nominal capital growth p.a.; NOT source-grounded; replace with a named series" },
    "is_nominal":                     { "type": "bool", "value": true, "note": "bands are NOMINAL (not real / inflation-adjusted); state this in key_assumptions when surfaced" },
    "compounding":                    { "type": "string", "value": "value_at_H = purchase_price × (1 + rate)^H, applied at both band ends to yield a sale_proceeds money_range", "note": "the resolver's projection method over the hold horizon H" },
    "surface_as":                     { "type": "string", "value": "banded money_range with the growth assumption stated in key_assumptions; PENDING when H or price unparameterised; never a point forecast", "note": "ASIC discipline — decision-support, not a forecast or advice" },
    "reground_against":               { "type": "string", "value": "ABS Residential Property Price Index (RPPI) | CoreLogic Home Value Index long-run | state Valuer-General median series", "note": "candidate authoritative series to replace the placeholder; update last_verified on re-grounding" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.sale_proceeds` is resolver-computed by compounding the band over `H`; the doc supplies the band and the method, not a figure.
- **PLACEHOLDER, not verified.** Unlike the regulated docs in this set (`kb.tax.cgt-main-residence-exemption`, `kb.land-tax.ppor-exemption`), the figures here are **deliberately unverified** and labelled as such throughout. This is an honest placeholder, not an asserted estimate.
- **Re-grounding obligation.** Replace the band with a named series and update `last_verified`; the freshness pass should treat this doc as stale-by-construction until then.

## Sources

**None yet — placeholder.** Candidate authoritative series to ground against (not yet incorporated):

- ABS — *Residential Property Price Indexes* (capital-city dwelling price growth) — to be incorporated.
- CoreLogic — *Home Value Index* (long-run growth) — to be incorporated.
- State Valuer-General median price series — to be incorporated per state.
