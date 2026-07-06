---
slug: kb.firb.penalties-non-compliance
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-14-residential-compliance-v4.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn14-residential-compliance-v4.pdf
---

# FIRB — penalties for non-compliance

This doc owns the **consequences of breaching the foreign-investment law** for residential land: criminal penalties, civil penalties, the tiered infringement-notice scale, and the disposal-order / self-disclosure machinery. It grounds the `firb_workflow` risk surface (component 4) — the engine surfaces *why* the FIRB gate is hard, not as a disclaimer but as a quantified consequence. It does **not** own the **approval process** ([`kb.firb.application-process`](application-process.md)), the **conditions** whose breach triggers some of these penalties ([`kb.firb.approval-conditions-typical`](approval-conditions-typical.md)), or the **established-dwelling ban** itself ([`kb.firb.established-dwelling-ban`](established-dwelling-ban.md)).

## Penalties are expressed in penalty units (not dollars)

Penalty amounts in the *Foreign Acquisitions and Takeovers Act 1975* (FATA) are set in **penalty units** — the stable regulated constant. The **dollar value of one penalty unit** is set by **s4AA(1) of the *Crimes Act 1914*** and is **periodically indexed** (CPI, on a roughly three-yearly cadence). This doc records penalties in **penalty units**; the dollar conversion is the resolver's job at fill time, against the current s4AA value (as at 2025, one penalty unit was ≈ A$330 — ⚠ **the penalty-unit value is CPI-indexed on a ~3-yearly 1 July cadence and a triennial indexation took effect 1 July 2026, so the ≈A$330 figure is now stale; re-ground the current s4AA value against a primary source before quoting any dollar amount**). Recording in penalty units keeps the regulated figure correct across indexations; only the conversion factor ages.

## Criminal penalties — the headline

For the core acquisition breaches (failing to notify before acquiring an interest — **s84**; acquiring after notifying but before approval — **s85**; breaching a condition / disposal order — **s86–s88**):

- **Maximum criminal penalty: imprisonment for 10 years, or 15,000 penalty units (150,000 penalty units for a corporation), or both.**

These were substantially increased under the 2023–2024 foreign-investment reforms; the figures above are the current maxima.

## Civil penalties — value-linked

For the same residential acquisition breaches, the maximum **civil** penalty (**s94**) is **the greatest of**:

- **double the capital gain** made (or that would be made) on disposal of the land;
- **50% of the consideration**; and
- **50% of the market value** of the relevant residential land.

So the civil exposure scales with the property — it is not a flat figure. (Different sections apply slightly different value-linked formulae for order-contravention breaches; the residential-acquisition formula above is the one the plan surfaces.)

## Infringement notices — the tiered, lower-stakes scale

For less serious or self-disclosed breaches the ATO may issue an infringement notice (**s100**), tiered:

- **Tier 1** (self-disclosed): **12 penalty units** (60 for a corporation);
- **Tier 2** (land value **< $5 million**): **60 penalty units** (300 for a corporation);
- **Tier 3** (land value **> $5 million**): **300 penalty units** (1,500 for a corporation).

## Self-disclosure lowers the penalty

A foreign person who discovers a breach is **encouraged to self-disclose** (via the ATO tip-off form). **Self-disclosure can move a breach into the Tier 1 infringement band** rather than civil/criminal pursuit. The plan's framing for a buyer who fears they have breached is: **self-disclose early and get professional advice**, not conceal.

## Disposal orders and retrospective approval

Beyond fines, the Government can require a foreign person to **dispose of an interest** acquired in breach (a disposal order), and may grant a **retrospective approval** in some cases. The point for the plan: a breach is not just a fine — it can **unwind the purchase**.

## Rules

Pure-reference (`fills: []`). Every penalty figure here is a **regulated constant removed from the agent's reach**: the agent never asserts a penalty; the `firb_workflow` resolver places the applicable figure (converting penalty units to dollars against the current s4AA value) when surfacing the risk. The penalty-unit amounts are stable in FATA; only the dollar conversion indexes.

```jsonc
{
  "fills": [],
  "parameters": {
    "penalty_unit_value_indexes": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the dollar value of a penalty unit is set by s4AA(1) Crimes Act 1914 and is periodically CPI-indexed (~3-yearly); penalties here are in penalty units, dollars converted at fill time. RE-GROUND the s4AA value before quoting dollars." },
    "criminal_max_imprisonment_years": { "type": "integer", "value": 10, "provenance": "REGULATED", "note": "max criminal penalty for the core acquisition breaches (s84/s85/s86–88): imprisonment for 10 years, or the penalty units below, or both." },
    "criminal_max_penalty_units_individual": { "type": "integer", "value": 15000, "provenance": "REGULATED", "note": "max criminal financial penalty for an individual on the core acquisition breaches (150,000 penalty units for a corporation)." },
    "civil_max_is_greatest_of_value_linked": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "max civil penalty (s94, residential acquisition) is the GREATEST of: double the capital gain; 50% of the consideration; 50% of the market value — value-linked, not flat." },
    "infringement_tier1_penalty_units_individual": { "type": "integer", "value": 12, "provenance": "REGULATED", "note": "Tier 1 infringement (self-disclosed): 12 penalty units individual / 60 corporation (s100)." },
    "infringement_tier2_penalty_units_individual": { "type": "integer", "value": 60, "provenance": "REGULATED", "note": "Tier 2 infringement (land value < $5m): 60 penalty units individual / 300 corporation." },
    "infringement_tier3_penalty_units_individual": { "type": "integer", "value": 300, "provenance": "REGULATED", "note": "Tier 3 infringement (land value > $5m): 300 penalty units individual / 1,500 corporation." },
    "self_disclosure_lowers_penalty": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "self-disclosure (ATO tip-off form) can move a breach into the Tier 1 band rather than civil/criminal pursuit; encouraged." },
    "disposal_order_possible": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the Government can order disposal of an interest acquired in breach; a retrospective approval may be available in some cases. A breach can unwind the purchase, not just fine it." }
  }
}
```

Notes:

- **This doc is why the FIRB gate is hard, not a disclaimer.** The established-dwelling ban ([`kb.firb.established-dwelling-ban`](established-dwelling-ban.md)) and the must-act-only-after-approval rule ([`kb.firb.application-process`](application-process.md)) carry *these* consequences; the engine surfaces the quantified risk so the gate reads as real ([[verify-regulated-figures-by-postcondition]]).
- **Penalty units, not dollars, are the durable record** — the s4AA dollar value indexes on a known cadence, exactly like the FIRB fee schedule ([`kb.firb.fee-schedule-current`](fee-schedule-current.md)). A filled plan card records the penalty-unit figure + the s4AA value + the deploy SHA, so a later indexation never rewrites a past plan.
- **Decision-support framing.** This is informational; an actual or feared breach is handled with a registered legal professional and (where applicable) self-disclosure to the ATO — never concealment.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 14: Compliance and Penalties (Residential Land)*, Version 4 (14 March 2025) — criminal maxima (s84/s85: 10 years or 15,000 penalty units / 150,000 corporation); civil maxima (s94: greatest of double the capital gain, 50% consideration, 50% market value); tiered infringement notices (s100: 12/60/300 penalty units, land-value tiers, self-disclosure); disposal orders; penalty-unit value per s4AA Crimes Act — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-14-residential-compliance-v4.pdf
- ATO — *Foreign investment in residential assets — our compliance approach* (self-disclosure encouraged; lower penalties may apply; ATO tip-off form) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/how-we-ensure-compliance-by-a-foreign-person/foreign-investment-in-residential-assets-our-compliance-approach
- *Crimes Act 1914* (Cth) s4AA — value of a penalty unit (periodically indexed) — https://www.legislation.gov.au/C1914A00012/latest/text
