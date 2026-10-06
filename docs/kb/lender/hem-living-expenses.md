---
slug: kb.lender.hem-living-expenses
effective_from: 2026-06-22
last_verified: 2026-07-06
sources:
  - url: https://download.asic.gov.au/media/hyeofbni/rg209-published-9-december-2019-20250306.pdf
    retrieved: 2026-07-06
    path: docs/sources/asics/rg209-published-9-december-2019.pdf
    note: "ASIC RG 209 §142-147 — HEM is the most-commonly-used expense benchmark, published by the Melbourne Institute, must be adjusted for income and not merely reflect 'low end' spending; a benchmark is 'a substitute for making reasonable inquiries', NOT a required floor. Confirms the band here has no single public figure → deliberate placeholder stands."
---

# Living-expenses benchmark (HEM) — PLACEHOLDER convention band

> **⚠ PLACEHOLDER — NOT SOURCE-GROUNDED.** The monthly living-expenses band below is a deliberately conservative, **unverified placeholder** held so the borrowing-capacity resolver has a living-expenses figure to subtract. The **HEM (Household Expenditure Measure)** is a benchmark maintained by the **Melbourne Institute** and applied per-lender; it varies by income, location, and household composition and is **not a single public figure** ([`kb.lender.serviceability-basics`](serviceability-basics.md): *"HEM has no single value… if a HEM lookup is ever needed it gets its own doc"* — this is that doc). Before any capacity figure is cited as authoritative, re-ground this band against a named HEM series or a representative lender's expense floor and update `last_verified`. Until then the resolver surfaces capacity as a **banded estimate** with the living-expenses basis stated in `key_assumptions`, never as a precise figure. (Son's call, 2026-06-22: hold as a labelled convention band, flat for the wedge; household-scaling is a later refinement.)

A lender's serviceability test floors declared living expenses at the **HEM** benchmark — a borrower cannot inflate capacity by declaring implausibly low expenses. Living expenses are the **dominant** subtraction in the capacity calculation, so the honest uncertainty in capacity is mostly the uncertainty in this figure. This doc owns the **monthly living-expenses band** the `mortgage_finance` resolver subtracts from net income; the band's two ends produce the capacity band (low expenses → higher capacity, high expenses → lower).

## Why a band, not a number

HEM scales by income, location, and household size; a single asserted figure would be both wrong and falsely precise. A **band** — a conservative low/high monthly pair — surfaces the *range* of capacity outcomes with the assumption stated, which is information, not a promise. Capacity is therefore a `money_range`, and the band's width is the visible honesty about the least-grounded input.

## The placeholder band (to be replaced)

Pending a named HEM series, a conservative monthly band for a typical first-home-buyer household is held. It is intentionally wide so that, if used before re-grounding, it does not over-promise capacity:

- **Conservative low:** ~$1,800 / month
- **Conservative high:** ~$2,600 / month

These are **placeholders**. Real HEM for a single adult sits broadly in this region and rises materially with a partner and dependents, but **the specific figures here are not tied to a verified series** and must not be cited as such. The resolver subtracts the **high** end to produce the lower (conservative) capacity bound and the **low** end for the upper bound.

## Flat now; household-scaling later

The plan already captures `application.applicant_count` and `application.dependents_count`, so HEM *could* scale by household. For the wedge it is held **flat** (one band for all households) — a documented simplification, not an oversight. Scaling the band by household size is the first refinement when this doc is re-grounded; the resolver reads the band by key, so adding a per-household lookup later is a doc change, not a code change.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Conservative by design.** A high expense floor keeps the capacity (and therefore the full-horizon net position it feeds) honest; an optimistic HEM would inflate the loan, the dispose-phase loan payout, and the graduation story.
- **Multi-generational households** common in the diaspora may have living-expense patterns the flat band does not capture — another reason the figure is surfaced as a labelled convention, not a verdict, and re-grounding is tracked.
- **Re-grounding is a tracked obligation.** Like [`kb.property.capital-growth-bands`](../property/capital-growth-bands.md), this doc is **stale-by-construction** until a named series replaces the band; the freshness pass treats it as such.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. Everything above is `content_md`. This is a **reference doc** — it fills no slot; `mortgage_finance.expected_borrowing_capacity` is **resolver-computed** by subtracting this band (with tax and debt commitments) from net income and capitalising the surplus. The doc supplies the band, not a figure.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder":              { "type": "bool",  "value": true,  "note": "TRUE — these living-expense figures are an unverified placeholder, NOT a HEM series; re-ground before surfacing any capacity figure (Son, 2026-06-22)" },
    "monthly_living_expenses_low":  { "type": "money", "value": 1800, "note": "PLACEHOLDER — conservative low monthly living expenses; NOT source-grounded; subtracted to produce the UPPER capacity bound" },
    "monthly_living_expenses_high": { "type": "money", "value": 2600, "note": "PLACEHOLDER — conservative high monthly living expenses; NOT source-grounded; subtracted to produce the LOWER (conservative) capacity bound" },
    "scaling":                     { "type": "string", "value": "flat — one band for all households for the wedge; scale by applicant_count + dependents_count on re-grounding", "note": "documented simplification (Son, 2026-06-22)" },
    "surface_as":                  { "type": "string", "value": "the living-expenses basis stated in key_assumptions; capacity surfaced as a banded estimate, never a precise figure", "note": "ASIC discipline — decision-support, not credit advice" },
    "reground_against":            { "type": "string", "value": "Melbourne Institute HEM series | a representative lender's expense floor | ABS Household Expenditure Survey", "note": "candidate sources to replace the placeholder; update last_verified on re-grounding" }
  }
}
```

Notes:

- **No `fills`.** `expected_borrowing_capacity` is **resolver-computed** from this band plus the tax schedule and debt commitments — a formula, kept in code per §11.9. The doc supplies the band and the method note, not a figure.
- **PLACEHOLDER, not verified.** Unlike the regulated docs in this set (`kb.lender.serviceability-basics` buffer, `kb.tax.income-tax-resident-2026-27`), the figures here are **deliberately unverified** and labelled throughout — an honest placeholder, the sibling of `kb.property.capital-growth-bands`.
- **The band IS the capacity band.** The two ends are not a measurement error to be averaged away — they are the surfaced uncertainty; the resolver reports both bounds.

## Sources

**None yet — placeholder.** Candidate sources to ground against (not yet incorporated): Melbourne Institute HEM benchmark; ABS Household Expenditure Survey; a representative lender's published serviceability expense floor.
