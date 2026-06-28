---
slug: kb.firb.documents-required
effective_from: 2025-04-01
last_verified: 2026-06-28
---

# FIRB application — information and documents required

This doc owns the **checklist** of information and documents a foreign person supplies when applying for foreign-investment approval to buy residential land through Online Services for Foreign Investors. It grounds the `firb_workflow` "what do I need to gather" surface and the early readiness check; it does **not** own the **process sequence** ([`kb.firb.application-process`](application-process.md)), the **fee** ([`kb.firb.fee-schedule-current`](fee-schedule-current.md)), or the **bank-side source-of-funds** evidence (that is AML/CTF, owned by `kb.au-aml-ctf.source-of-funds-documentation`, Cluster X — a *separate* obligation from the FIRB application).

## What the application asks for

- **Applicant identity** — the foreign person's identity details (and an ATO/foreign-investor account to lodge through).
- **Visa details** — the applicant's **relevant visa** (the visa class establishes temporary-resident status; classes catalogued in [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md)). If a contract has been signed, the visa is attached with it.
- **Property type** — whether the acquisition is a **new dwelling**, **vacant land**, or an established dwelling (the latter only for the narrow exception purposes; otherwise banned). The type selects the fee table ([`kb.firb.fee-tiers-by-value`](fee-tiers-by-value.md)) and the eligibility path ([`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md)).
- **State or territory** of the property.
- **Expected purchase price** (the consideration) — sets the fee band.
- **Ownership structure** — the relationship between purchasers: **sole purchaser**, **joint tenants**, or **tenants in common** (with each owner's **percentage** if tenants in common).
- **The contract of sale, if signed** — attached to the application (typically a contract **conditional on FIRB approval**, owned by [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md), Cluster R3).

## What is *not* part of the FIRB application (but is needed elsewhere)

- **Source-of-funds evidence** is a **bank / AML-CTF** requirement on the cross-border transfer, **not** a FIRB application field — owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) (Cluster X). The two are separate obligations; the plan must not conflate "documents for FIRB" with "documents for the bank."
- **Finance approval** is a lender process (Cluster L), not a FIRB input — though a foreign-person loan is itself often conditional on FIRB approval ([`kb.lender.firb-approval-as-condition-precedent`](../lender/firb-approval-as-condition-precedent.md), Cluster L).

## Rules

Pure-reference (`fills: []`). The checklist grounds the resolver's readiness surface and the agent's "what to gather" guidance; nothing is asserted as a leaf, and no figure appears here.

```jsonc
{
  "fills": [],
  "parameters": {
    "visa_required_in_application": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the applicant's relevant visa is required (attached with the contract if signed); classes catalogued in kb.visas.au-temporary-residency-classes." },
    "contract_attached_if_signed": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "if a contract of sale has been signed it is attached to the application (typically conditional on FIRB approval)." },
    "ownership_structure_required": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "relationship between purchasers (sole / joint tenants / tenants in common, with % for tenants in common) is required." },
    "source_of_funds_is_aml_not_firb": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "source-of-funds evidence is a bank/AML-CTF requirement (kb.au-aml-ctf.source-of-funds-documentation), a separate obligation from the FIRB application — do not conflate." }
  },
  "lookup": {
    "firb_application_fields": {
      "keydim": ["field"],
      "provenance": "REGULATED (ATO — residential property application for foreign investors)",
      "rows": [
        { "field": "applicant_identity",     "required": true,  "note": "identity + foreign-investor account" },
        { "field": "visa",                   "required": true,  "note": "relevant visa class" },
        { "field": "property_type",          "required": true,  "note": "new dwelling / vacant land / established (exception only)" },
        { "field": "state_or_territory",     "required": true,  "note": "location of the property" },
        { "field": "expected_purchase_price","required": true,  "note": "the consideration — sets the fee band" },
        { "field": "ownership_structure",    "required": true,  "note": "sole / joint tenants / tenants in common (+ % if TIC)" },
        { "field": "contract_of_sale",       "required": false, "note": "attached if signed; typically conditional on FIRB approval" }
      ]
    }
  }
}
```

Notes:

- **Single-owner.** Visa catalogue → [`kb.visas.au-temporary-residency-classes`](../visas/au-temporary-residency-classes.md); property-type eligibility → [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md); fee → [`kb.firb.fee-schedule-current`](fee-schedule-current.md); the conditional contract → [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md) (R3); source-of-funds → AML doc (X). This doc owns only the **application field list** + the FIRB-vs-AML separation.
- **FIRB documents ≠ bank documents** is the load-bearing distinction (mirrors the tax≠FIRB distinction in [`kb.au-temp-residents.banking-and-tax-basics`](../au-temp-residents/banking-and-tax-basics.md)): a foreign buyer faces *two* document gates — the FIRB application and the bank's AML/source-of-funds checks — and the plan tracks them separately.
- **Decision-support framing.** The authoritative field set is the live ATO portal; this is an informational checklist.

## Sources

- ATO — *Residential property application for foreign investors* / *Apply to buy residential property as a foreign person* (information required: property type, relationship between purchasers, state/territory, expected purchase price, tenant-in-common %, signed contract + visa) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
- ATO — *How to apply or vary an approval to buy residential property* — https://www.ato.gov.au/online-services/foreign-investors/residential-application
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 3 (14 March 2025) — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-6-residential-land-v3.pdf
