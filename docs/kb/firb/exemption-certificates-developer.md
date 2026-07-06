---
slug: kb.firb.exemption-certificates-developer
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/firb.gov.au/files/guidance-notes/08_GN_FIRB.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn8-new-near-new-dwelling-exemption-certificate.pdf
---

# FIRB — developer new-dwelling exemption certificate

This doc owns the **developer-held exemption-certificate pathway**: the route by which a foreign buyer of a **new (or near-new) dwelling** does **not** lodge an individual foreign-investment application because the **developer** holds a certificate covering the sale. It grounds the `firb_workflow` "do I even need to apply?" branch (component 4) — the simplest, fastest path, common for off-the-plan apartments. It does **not** own the individual application ([`kb.firb.application-process`](application-process.md)), the fee ([`kb.firb.fee-schedule-current`](fee-schedule-current.md)), or the eligible-types taxonomy ([`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md)).

## What it is

A property developer (Australian or foreign) can apply for a **New Dwelling Exemption Certificate** (or a **Near-New Dwelling Exemption Certificate**) to sell new/near-new dwellings in a specified development to foreign persons. **Where the developer holds the certificate, the individual foreign buyer is not required to seek their own foreign-investment approval** to buy a dwelling in that development.

- A **near-new dwelling** is one that has never been occupied/sold as a residence but is part of a development previously sold under an exemption certificate (the "advanced off-the-plan" case).
- The pathway exists because the policy goal — new housing supply — is already served at the development level, so per-buyer screening is unnecessary.

## The buyer-side limit — the $3M cap

The certificate exempts a foreign person from individually seeking approval to buy new dwellings **up to a cumulative total of $3 million** in the specified development. **Above $3 million cumulative, the certificate does not cover the purchase and the foreign person must apply for their own foreign-investment approval** ([`kb.firb.application-process`](application-process.md)). This is the single most load-bearing fact for the plan: the developer certificate is a clean path *only* under $3M cumulative; cross that line and the individual application (and its fee) re-enters.

## The developer-side conditions (context, not the buyer's obligation)

These bind the developer, not the buyer, but shape whether the path is available:

- The developer may sell **a maximum of 50% of the total dwellings** in the development to foreign persons under the certificate.
- The developer must **provide a copy of the certificate to each foreign purchaser** and **report sales + pay the applicable per-dwelling fee** each reporting period (six-monthly).

For the buyer, the practical check is: **ask the developer/agent whether a New Dwelling Exemption Certificate covers the dwelling** — if yes and the price is under the $3M cumulative cap, no individual FIRB application is needed (only confirmation and a copy of the certificate).

## Rules

Pure-reference (`fills: []`). The branch (`developer_certificate_covers → skip_individual_application`) is owned by the `firb_workflow` resolver; this doc supplies the grounded rule and the $3M cap the resolver gates on. No leaf asserted; the only figure — the $3M cap — is a regulated threshold placed by the resolver, not the agent.

```jsonc
{
  "fills": [],
  "parameters": {
    "developer_certificate_removes_individual_application": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "where the developer holds a New/Near-New Dwelling Exemption Certificate, the foreign buyer does not lodge an individual foreign-investment application for a covered dwelling." },
    "buyer_exemption_cap_aud": { "type": "integer", "value": 3000000, "provenance": "REGULATED", "note": "the certificate exempts a foreign person up to a cumulative $3,000,000 of new dwellings in the development; above this the buyer must apply individually (kb.firb.application-process)." },
    "developer_foreign_sale_cap_fraction": { "type": "number", "value": 0.5, "provenance": "REGULATED", "note": "the developer may sell at most 50% of total dwellings in the development to foreign persons under the certificate (developer-side condition; certificates received from 7:30pm AEST 9 May 2017)." },
    "near_new_dwelling_recognised": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a near-new dwelling (never occupied/sold, part of a development previously sold under a certificate) is covered by a Near-New Dwelling Exemption Certificate." }
  }
}
```

Notes:

- **This is a path-selector, not a separate process.** It sits *before* [`kb.firb.application-process`](application-process.md) in the resolver: certificate-covered + under $3M → no individual application; otherwise → the standard application path. The plan surfaces the question early because it changes the whole FIRB workload.
- **Single-owner.** The fee for an individual application (when the cap is exceeded) → [`kb.firb.fee-schedule-current`](fee-schedule-current.md); eligible property types → [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md); off-the-plan timing risk → [`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md). This doc owns only the **developer-certificate pathway + the $3M buyer cap**.
- **Decision-support framing.** Whether a specific development's certificate covers a specific dwelling is confirmed with the developer and the ATO; this is informational.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 8: Residential Real Estate — New (and Near-New) Dwelling Exemption Certificate* (developer-held certificate removes the individual buyer's application; near-new definition; 50% cap; per-dwelling fee + six-monthly reporting; buyer exempt to a cumulative $3 million) — https://foreigninvestment.gov.au/sites/firb.gov.au/files/guidance-notes/08_GN_FIRB.pdf
- ATO — *Exemption certificates for property developers* (foreign buyer of a covered new/near-new dwelling does not need to apply; developer fee per sale within 30 days of each six-month reporting period) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/exemption-certificates-for-property-developers
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025) — new dwellings; exemption-certificate route — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
