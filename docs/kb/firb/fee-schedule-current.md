---
slug: kb.firb.fee-schedule-current
effective_from: 2025-07-01
last_verified: 2026-06-28
---

# FIRB application fees — the current dollar schedule

This doc owns the **current dollar amounts** of the foreign-investment application fee a foreign person pays to apply to buy residential land. The **rule that picks which amount applies** (the banding-by-value selection) is owned by [`kb.firb.fee-tiers-by-value`](fee-tiers-by-value.md); this doc owns the **figures the rule reads**. The fee is computed by the `firb_workflow` resolver (component 4) and **removed from the LLM's reach** — it is never asserted by the agent, only placed from this grounded schedule.

> ⚠ **Re-ground obligation — annual 1 July reindexation.** FIRB fees are **indexed every 1 July**. The amounts below are the **2025-26 financial year** schedule (*Schedule of Fees*, **Version 6, 2 January 2026**). The **2026-27** indexed schedule takes effect **1 July 2026**. After that date these figures are stale: re-verify against the then-current *Schedule of Fees* PDF, update the rows, and bump `last_verified`. `last_verified: 2026-06-28` is **three days before** the next reindex — treat this doc as on the edge of its validity window.

## The Mode-B fee path — residential land *other than* established dwellings

A foreign person (including a temporary resident) may buy only **new dwellings, near-new dwellings, and vacant residential land** ([`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md)), so the **notifiable-action** column of the **non-established residential** table is the one a Mode-B individual buyer actually pays. (FIRB *Schedule of Fees*, Table 2.)

| Consideration (purchase price) | Application fee (notifiable action) |
|---|---|
| Less than $75,000 | $4,500 |
| $1m or less | **$15,100** |
| $2m or less | **$30,300** |
| $3m or less | $60,600 |
| $4m or less | $90,900 |
| $5m or less | $121,200 |
| each additional $1m (to $40m) | **+$30,300** per band |
| More than $40m | $1,205,200 |

The step from `≤$1m` to `≤$2m` is the only irregular one (+$15,200); from `≤$2m` upward each $1m band adds a flat **$30,300**. The vast majority of Mode-B residential purchases fall in the **`≤$1m` ($15,100)** or **`≤$2m` ($30,300)** band.

## Established dwellings — off-path, fees tripled

For completeness: the **established-dwelling** schedule (*Schedule of Fees*, Table 3) is **exactly 3× the non-established amount** at every band (e.g. `≤$1m` = $45,300, `≤$2m` = $90,900). It is **off-path for the individual foreign buyer** — established dwellings are banned for foreign persons 1 Apr 2025 – 30 Jun 2029 ([`kb.firb.established-dwelling-ban`](established-dwelling-ban.md)) — and is recorded here only because this doc is the single owner of *all* FIRB residential fee figures, for the rare exception cases (commercial-scale, redevelopment) the ban doc enumerates.

## Rules

Pure-reference (`fills: []`). The fee is selected and placed by the `firb_workflow` resolver: it reads the **band-selection rule** from [`kb.firb.fee-tiers-by-value`](fee-tiers-by-value.md) and the **amount** from the lookup below. The agent never computes or states the fee (regulated figure — removed from reach). The fee is a **cash-position input** (a regulatory impost, owned downstream by the `cash_position` foreign variant), not asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "current_fy": { "type": "string", "value": "2025-26", "provenance": "REGULATED", "note": "Schedule of Fees Version 6 (2 Jan 2026); amounts relate to the 2025-26 financial year." },
    "reindexes_annually_on_1_july": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FIRB fees are indexed each 1 July; the 2026-27 schedule takes effect 1 Jul 2026 — re-ground this doc immediately after." },
    "established_dwelling_fee_multiplier": { "type": "number", "value": 3, "provenance": "REGULATED", "note": "established-dwelling fees are exactly 3x the non-established amount; off-path for the individual foreign buyer (banned)." }
  },
  "lookup": {
    "fee_schedule_residential_non_established_2025_26": {
      "keydim": ["consideration_band"],
      "provenance": "REGULATED (FIRB Schedule of Fees, Version 6, 2 Jan 2026, Table 2 — notifiable action)",
      "unit": "AUD",
      "rows": [
        { "consideration_band": "lt_75000",   "max_value_aud": 75000,    "fee_aud": 4500 },
        { "consideration_band": "le_1m",       "max_value_aud": 1000000,  "fee_aud": 15100 },
        { "consideration_band": "le_2m",       "max_value_aud": 2000000,  "fee_aud": 30300 },
        { "consideration_band": "le_3m",       "max_value_aud": 3000000,  "fee_aud": 60600 },
        { "consideration_band": "le_4m",       "max_value_aud": 4000000,  "fee_aud": 90900 },
        { "consideration_band": "le_5m",       "max_value_aud": 5000000,  "fee_aud": 121200 },
        { "consideration_band": "gt_40m",      "max_value_aud": null,     "fee_aud": 1205200 }
      ],
      "increment_rule": "from the $2m band upward, each additional $1m band adds $30,300, to the $40m band ($1,181,700); above $40m the flat fee is $1,205,200."
    }
  }
}
```

Notes:

- **Single-owner: figures here, selection rule next door.** This doc = the dated dollar amounts (and the reindex obligation). [`kb.firb.fee-tiers-by-value`](fee-tiers-by-value.md) = the rule that maps a purchase price to a band. The resolver composes the two; neither restates the other.
- **The figures are dated, not eternal.** `effective_from` is the FY start (1 Jul 2025); the schedule is on the edge of the next reindex (1 Jul 2026). The artifact records the deploy-time snapshot; a filled plan card records the figure it used + the deploy SHA (the regulated audit trail), so a later reindex does not silently rewrite a buyer's past plan.
- **Removed from the LLM's reach.** Regulated figure: resolver-computed, agent never asserts it ([[verify-regulated-figures-by-postcondition]], [[no-judge — ground the producer]]).

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Schedule of Fees*, Version 6 (2 January 2026), 2025-26 financial year — Table 2 (residential land other than established dwellings) and Table 3 (established dwellings) — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2026-01/schedule-of-fees.pdf
- Foreign Investment in Australia — *Fees* (fee depends on the value and kind of investment; annual 1 July indexation) — https://foreigninvestment.gov.au/guidance/general/fees
- *Foreign Acquisitions and Takeovers Fees Imposition Regulations 2020* — the fee-setting instrument (s 32 — residential exemption certificates) — https://www.legislation.gov.au/Details/F2020L00563
