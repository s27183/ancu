---
slug: kb.investor.experience-levels
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Investor experience levels

How experienced an investor is shapes how much scaffolding the plan provides, which risks need spelling out, and how complex a strategy is realistic. This doc owns the **experience-level bands** — the persistent investor trait `investor_profile.traits.experience_level`, what each band means, and how the plan adapts to it. It is the *persistent disposition* (accumulates across journeys), distinct from the per-journey `plan.risk_tolerance`. It is a **reference (bands)** doc — it asserts no figure; the band is a profile fact, and the plan's depth adapts to it. Informational; not a gate on what an investor may do.

## The bands

`experience_level` is a small ordered enum capturing where the investor sits on the learning curve:

- **`first_time`** — no prior investment property (may be a current or former owner-occupier). Needs the full framework explained: gearing, yield, CGT, depreciation, land tax, the difference between an investment loan and an owner-occupier loan. The plan errs toward more explanation, conservative gearing framing, and explicit risk surfacing. The deal-breaker fields ([`kb.investor.strategy-archetypes`](strategy-archetypes.md)) matter most here.
- **`established`** — owns one or a few investment properties; understands the core mechanics. The plan can be more concise, focuses on what's specific to *this* deal and the **portfolio interactions** — land-tax aggregation ([`kb.investor.land-tax-aggregation`](land-tax-aggregation.md)), serviceability across the portfolio ([`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)), scale-up sequencing ([`kb.investor.scale-up-using-equity`](scale-up-using-equity.md)).
- **`sophisticated`** — a substantial portfolio and/or structured holdings (trusts, SMSF, company). The plan assumes fluency, foregrounds structural and tax-optimisation nuance, and defers more to the investor's own advisers — but still surfaces the regulated facts and the ASIC/ACL line. Entity structuring ([`kb.tax.entity-comparison-personal-trust-company-smsf`](../tax/entity-comparison-personal-trust-company-smsf.md)) is more likely in scope.

## What the band changes — and what it doesn't

- **It changes depth and tone, not entitlement.** The band adjusts how much the plan explains and which interactions it foregrounds. It does **not** restrict what strategy an investor may pursue — a first-timer can pursue any archetype; the plan just explains more and flags risk more explicitly.
- **It is persistent, not per-journey.** Experience accumulates across journeys and sits in `traits`; the *appetite for risk on this particular plan* is `plan.risk_tolerance`, a separate per-journey field. A sophisticated investor can run a conservative plan, and vice versa.
- **It never lowers the regulated bar.** No band removes the ASIC/ACL framing, the regulated-figure discipline, or the adviser-in-the-loop requirement. Sophistication changes emphasis, not the compliance floor.

## Relevance for Vietnamese-Australian investors (Mode C)

- **First-time investors get the full picture.** For a household making its first move beyond the family home, the plan explains the investment-specific mechanics in plain bilingual terms rather than assuming fluency.
- **Established investors get portfolio-level focus.** The plan shifts to land-tax aggregation, cross-portfolio serviceability, and scale-up sequencing — the things that bite once there's more than one property.
- **Sophistication adjusts emphasis, not the floor.** The regulated facts and the no-advice line hold at every level. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference (bands)** doc — it fills no slot; `experience_level` is a profile trait, and the plan's depth/emphasis adapt to it. It gates nothing.

```jsonc
{
  "fills": [],
  "lookup": {
    "experience_levels": {
      "note": "the experience_level enum (persistent trait) and how the plan adapts — depth/emphasis only, never entitlement",
      "entries": [
        { "level": "first_time", "meaning": "no prior investment property", "plan_adapts": "full framework explained; conservative gearing framing; explicit risk surfacing; deal-breakers foregrounded" },
        { "level": "established", "meaning": "one or a few investment properties", "plan_adapts": "concise; focus on this deal + portfolio interactions (land-tax aggregation, cross-portfolio serviceability, scale-up sequencing)" },
        { "level": "sophisticated", "meaning": "substantial / structured portfolio", "plan_adapts": "assumes fluency; foregrounds structural + tax-optimisation nuance; defers more to own advisers; regulated facts + ASIC/ACL line still surfaced" }
      ]
    }
  },
  "parameters": {
    "level_changes_depth_not_entitlement": { "type": "bool", "value": true, "note": "the band adjusts explanation depth and emphasis; it does NOT restrict which strategy an investor may pursue" },
    "experience_is_persistent_not_per_journey": { "type": "bool", "value": true, "note": "experience_level is a persistent trait (accumulates across journeys); per-journey risk appetite is plan.risk_tolerance, a separate field" },
    "band_never_lowers_the_regulated_bar": { "type": "bool", "value": true, "note": "no band removes the ASIC/ACL framing, regulated-figure discipline, or adviser-in-the-loop requirement" }
  }
}
```

Notes:

- **No `fills`.** `experience_level` is a profile trait; the plan's depth and emphasis adapt to it. This doc supplies the band definitions.
- **Persistent vs per-journey.** `traits.experience_level` (persistent disposition) is distinct from `plan.risk_tolerance` (per-journey posture) — the two are independent.
- **Single-owner via cross-ref.** Portfolio interactions → `kb.investor.land-tax-aggregation`, `kb.lender.serviceability-investment-loans`, `kb.investor.scale-up-using-equity`; structuring → `kb.tax.entity-comparison-personal-trust-company-smsf`. This doc owns only the experience bands.

## Sources

- ASIC Moneysmart — *Investing in property* (the learning curve; first-time vs experienced investor considerations) — https://moneysmart.gov.au/property-investment/investing-in-property
