---
slug: kb.tax.entity-setup-costs
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Entity setup costs — by ownership structure

Holding an investment property in a **trust, company, or SMSF** (rather than personally) carries **establishment** and **ongoing administration** costs that personal ownership does not. This doc owns the **cost bands** for setting up and running each structure so `cash_position` can include the setup cost in the acquisition cash requirement and `settlement_prep` can sequence the entity setup as a milestone. It is the **cost** companion to [`kb.tax.entity-comparison-personal-trust-company-smsf`](entity-comparison-personal-trust-company-smsf.md) (which owns the *choice*); the figures are **INDICATIVE market ranges** (no regulator publishes service-provider fees) except the **ASIC / ATO statutory fees**, which are regulated. Informational; confirm exact quotes with a registered tax agent / accountant.

## Setup and ongoing cost bands

| Structure | First-year setup (indicative) | Ongoing annual (indicative) | Statutory fees (regulated) |
|---|---|---|---|
| **Personal — sole / joint** | ~nil (no entity) | ~nil beyond ordinary tax return | — |
| **Discretionary / unit trust** | **$1,500–$4,000** (deed $1,200–$3,000 + state deed stamping (varies, ~$500 NSW) + optional corporate trustee) | **$1,000–$3,500+** (accounting, trust tax return) | ASIC company registration if corporate trustee (indexed) |
| **Company** | setup + ASIC registration | accounting + ASIC annual review | ASIC registration + annual review fee (indexed) |
| **SMSF (corporate trustee)** | **$400–$2,000** (commonly ~$1,500 incl. ASIC company reg) | **accounting + independent audit** (varies widely) | ATO supervisory levy; ASIC special-purpose company review fee |

The bands are wide because they depend on provider, complexity, and state — they are an **order-of-magnitude planning input**, not a quote. The structure choice (and whether the cost is justified) is owned by the entity-comparison doc; this doc only sizes the cash.

## The regulated statutory fees

A handful of components are **government fees**, not service charges, and are **indexed annually (1 July)** — confirm the current figure:

- **ASIC company registration** — a one-off fee to register a company (relevant for a corporate trustee or a company owner); ~$611 (FY2025-26), indexed.
- **ASIC annual review** — for a company; a **special-purpose company** (e.g. an SMSF corporate trustee) pays a reduced review fee (~$67), an ordinary company more.
- **ATO SMSF supervisory levy** — ~$259 per year for an SMSF.

These are the **EXACT** regulated portion; the surrounding accounting/deed/audit charges are the indicative market portion.

## Deductibility — setup is capital

Entity **establishment** costs are **capital expenses** and are generally **not deductible** (they form part of the cost of the structure, not an income-year expense). Ongoing administration (accounting, tax return, audit) is generally deductible against the entity's income. This is why the setup cost lands in `cash_position` (an upfront cash requirement) rather than reducing the holding-phase tax — the plan places it on the acquisition side, not the deduction side.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The setup cost is real acquisition cash.** A trust or SMSF structure adds $1,500–$4,000+ upfront that personal ownership avoids — surfaced in the cash requirement so the deposit-plus-costs picture is complete.
- **Ongoing cost is a recurring drag.** Trust/SMSF administration recurs annually; the plan flags it so the structure's benefit is weighed against its running cost (the comparison doc owns that trade-off).
- **Setup is capital, not a deduction.** The plan places setup cost as upfront cash, not as a tax saving — it does not let the structure appear to "pay for itself" via a deduction it doesn't generate.
- **Information, not advice.** Bands are indicative; the plan points to a registered tax agent for an actual quote and never recommends incurring the cost.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the setup cost is **placed by the resolver** into `cash_position` / `settlement_prep` as a banded figure from these ranges, derived_from the chosen `recommended_entity`. Market bands are INDICATIVE; ASIC/ATO fees are regulated.

```jsonc
{
  "fills": [],
  "parameters": {
    "setup_cost_is_capital_not_deductible": { "type": "bool", "value": true, "note": "REGULATED (ATO) — entity establishment costs are capital expenses, generally not deductible; placed as upfront cash, not a deduction" },
    "asic_company_registration_fee":        { "type": "money", "value": 611, "note": "REGULATED (ASIC) — one-off company registration fee; ~$611 FY2025-26, INDEXED annually 1 July — confirm current. Relevant for a corporate trustee or company owner" },
    "asic_special_purpose_company_review":  { "type": "money", "value": 67, "note": "REGULATED (ASIC) — reduced annual review fee for a special-purpose company (e.g. SMSF corporate trustee); indexed — confirm current" },
    "ato_smsf_supervisory_levy":            { "type": "money", "value": 259, "note": "REGULATED (ATO) — annual SMSF supervisory levy; confirm current" }
  },
  "lookup": {
    "entity_setup_cost_bands": {
      "note": "INDICATIVE first-year setup + ongoing annual bands by structure (market, no regulator publishes service-provider fees); resolver places a banded figure, never a point quote",
      "entries": [
        { "entity": "personal_sole",      "setup_first_year": "~0",        "ongoing_annual": "~0",          "tier": "n/a" },
        { "entity": "personal_joint",     "setup_first_year": "~0",        "ongoing_annual": "~0",          "tier": "n/a" },
        { "entity": "discretionary_trust","setup_first_year": "1500-4000", "ongoing_annual": "1000-3500+",  "tier": "INDICATIVE" },
        { "entity": "unit_trust",         "setup_first_year": "1500-4000", "ongoing_annual": "1000-3500+",  "tier": "INDICATIVE" },
        { "entity": "company",            "setup_first_year": "611+",      "ongoing_annual": "review fee + accounting", "tier": "INDICATIVE (ASIC fee regulated)" },
        { "entity": "smsf",               "setup_first_year": "400-2000",  "ongoing_annual": "accounting + audit + levies", "tier": "INDICATIVE (levies regulated)" },
        { "entity": "smsf_with_lrba",     "setup_first_year": "400-2000 + LRBA/holding-trust setup", "ongoing_annual": "accounting + audit + levies", "tier": "INDICATIVE" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The setup cost is placed by the resolver into the acquisition cash / settlement milestone from these bands, derived from the chosen entity; the doc supplies the ranges and the regulated fees, not a filled leaf.
- **Two provenance tiers in one doc.** ASIC/ATO statutory fees are REGULATED (indexed annually — confirm current); deed/accounting/audit charges are INDICATIVE market bands (no regulator publishes them). The lookup tags each entry's tier.
- **Setup is capital (single-owner cross-ref).** Deductibility/capital treatment of the structure interacts with [`kb.tax.depreciation-division-43-and-40`](depreciation-division-43-and-40.md) and the entity choice in `kb.tax.entity-comparison-personal-trust-company-smsf`; this doc owns only the cost sizing.
- **Bands not quotes.** Wide ranges are deliberate — an order-of-magnitude planning input; the plan points to a registered tax agent for an actual quote.

## Sources

**Canonical (regulator):**

- ASIC — *Fees for commonly lodged documents* (company registration; annual review; special-purpose company reduced fee; indexed annually 1 July) — https://asic.gov.au/for-business/payments-fees-and-invoices/asic-fees/
- ATO — *SMSF supervisory levy* — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/self-managed-super-funds-smsf/administering-and-reporting/paying-the-smsf-supervisory-levy

**Indicative market ranges (point-in-time, labelled INDICATIVE — verified 2026-06-23):**

- Service-provider published fee schedules and market guides for trust/SMSF setup and ongoing administration (e.g. SMSF establishment ~$1,495 incl. ASIC; family-trust first-year $1,500–$4,000) — bands only; confirm a current quote with a registered tax agent / accountant.
