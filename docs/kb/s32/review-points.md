---
slug: kb.s32.review-points
effective_from: 2020-03-01
last_verified: 2026-06-02
---

# Section 32 vendor statement — review points (VIC)

In **Victoria**, before a buyer signs a contract the vendor must give them a **Section 32 vendor statement** (the "section 32" or "vendor's statement") under the **Sale of Land Act 1962 (Vic)**. It is a **separate statutory document** from the contract of sale, and it sets out the matters and attaches the documents the vendor is legally required to disclose. It is the **VIC equivalent of NSW's prescribed attached documents and QLD's seller-disclosure statement** — but it is its own standalone instrument. This doc owns **what a Section 32 must contain and the red flags a buyer reviews it for**; it grounds the `due_diligence` parameters `s32_flags` (agent-reasoned, `reasoning_domain: document_significance`) and the VIC-conditional `documents_required.section_32_vendor_statement.required`. The mandated contents are **REGULATED**; whether a given statement is complete/accurate is an agent-reasoned judgement, not a KB verdict.

## What a Section 32 must contain

Under s32 of the Sale of Land Act 1962, the vendor statement must disclose, before the buyer signs:

- **Title.** Particulars of title — a copy of the **register search statement** and the **plan/diagram**, and any **mortgages or charges** over the land (to be discharged at settlement), plus **easements, covenants and restrictions** on the title.
- **Financial matters.** **Rates, taxes, charges and other outgoings** (and any interest payable), and any amounts owing — so the buyer knows the recurring liabilities (see also `kb.ongoing-costs.rates-water-strata`).
- **Planning and land use.** The **planning scheme / zoning** that applies, the responsible authority, and whether the land is in a **designated bushfire-prone area**.
- **Notices.** Any **notice, order, declaration, report or recommendation** of a public authority or government department affecting the land (e.g. road-widening, compulsory acquisition, building orders).
- **Building permits.** Particulars of any **building permit issued in the last 7 years** (relevant to owner-builder work), and any **owner-builder insurance / warranty**.
- **Services (s32H).** Disclosure of which of the main services — electricity, gas, water, sewerage, telephone — are **not connected** to the land, so the buyer knows what is missing.
- **Owners corporation.** If the land is affected by an **owners corporation**, an **owners corporation certificate** and prescribed information (current fees, financial statements, insurance, rules, any special levies or disputes) — the strata-equivalent disclosure for VIC.
- **Growth Areas Infrastructure Contribution (GAIC).** If the land is in a GAIC area, disclosure of any liability.

## Red flags on review

- **Incomplete or inaccurate disclosure is itself the protection.** If the s32 contains **false, incorrect or insufficient information**, the buyer may be entitled to **withdraw from the sale** or take legal action. So the review is not just informational — material omissions are a lever.
- **Specific items to scrutinise.** Undisclosed **easements/covenants** that constrain building; **planning overlays** (heritage, flood, bushfire) that limit use; **notices** of works or acquisition; an **owners corporation** with low funds, special levies or active disputes; **owner-builder work** in the last 7 years without proper warranty insurance.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **VIC-only — branch on the buyer's state.** The s32 step exists only for VIC purchases; for NSW the equivalent is the prescribed documents attached to the contract and for QLD the seller-disclosure statement (both owned by `kb.contract-of-sale.review-points-by-state`). The plan surfaces the s32 review only when the property is in VIC.
- **Reviewed by a conveyancer/solicitor — never solo.** For a Mode A first-home buyer the s32 is dense and legal; the firm instruction is professional review **before** signing, and the agent surfaces the red-flag categories so the buyer knows what questions to ask.
- **Information, not advice.** The plan explains what the s32 must contain and what to scrutinise, and directs the buyer to their legal professional; it does not give a legal opinion on a specific statement.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `s32_flags` is **agent-reasoned** (`reasoning_domain: document_significance`) over an uploaded statement; this doc supplies the mandated-contents checklist and red-flag categories the agent reasons against.

```jsonc
{
  "fills": [],
  "parameters": {
    "applies_state": { "type": "string", "value": "VIC", "note": "REGULATED (VIC, Sale of Land Act 1962) — the Section 32 vendor statement is a Victorian requirement only; NSW/QLD use their own disclosure regimes (see kb.contract-of-sale.review-points-by-state)" },
    "separate_document_from_contract": { "type": "bool", "value": true, "note": "REGULATED — the s32 is a standalone statutory statement given before signing, distinct from the contract of sale; review is a separate due-diligence step" },
    "mandated_contents": { "type": "array<string>", "value": ["financial_matters_rates_outgoings_charges", "insurance_details", "land_use_easements_covenants_planning_bushfire", "authority_notices_orders", "building_permits_last_7_years", "owners_corporation_information", "gaic_if_applicable", "services_not_connected", "evidence_of_title"], "note": "REGULATED (VIC, Sale of Land Act 1962) — the head section s32 plus subsections: s32A financial matters; s32B insurance; s32C land use (easements, covenants, planning/zoning, designated bushfire-prone area); s32D notices; s32E building permits (last 7 years); s32F owners corporation; s32G GAIC; s32H services NOT connected; s32I evidence of title. Verified against the authorised Act PDF" },
    "false_or_insufficient_gives_withdrawal_right": { "type": "bool", "value": true, "note": "REGULATED (VIC, Sale of Land Act 1962 s32M; false-info offence s32K/s32L) — if the s32 is false, incorrect or insufficient the buyer may rescind before settlement; the agent flags material omissions as high-severity" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `s32_flags` is produced by agent reasoning over the uploaded statement; this doc is the grounding checklist. `section_32_vendor_statement.required` is resolver-set true only when the property's state is VIC.
- **REGULATED — the mandated contents are statutory.** The s32 content list is set by the Sale of Land Act 1962 (Vic) and was verified against Consumer Affairs Victoria and the Act. The `effective_from` reflects the modern s32 regime as reshaped by the **Sale of Land Amendment Act 2019** (commenced 1 March 2020).
- **Single-owner — VIC disclosure document vs the contract.** This doc owns the **VIC Section 32** contents and review. The **contract** review points and the **NSW/QLD** disclosure regimes → `kb.contract-of-sale.review-points-by-state`. The **owners corporation / strata health** interpretation → `kb.strata-report.red-flags` (the s32 attaches the OC certificate; reading whether the scheme is healthy is the strata doc's job). The **recurring outgoings** themselves → `kb.ongoing-costs.rates-water-strata`. Cross-ref, not duplicated.

## Sources

**Canonical (state authority / legislation):**

- Consumer Affairs Victoria — *Conveyancing and contracts for sellers* (the vendor statement must contain the matters and attach the documents specified in the Act; false/incorrect/insufficient information may let the buyer withdraw or take legal action) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/selling-property/conveyancing-and-contracts-for-sellers
- *Sale of Land Act 1962* (Vic), **ss 32–32I** — the statute prescribing the vendor-statement contents (s32 head; s32A financial; s32B insurance; s32C land use; s32D notices; s32E building permits; s32F owners corporation; s32G GAIC; s32H non-connected services; s32I title), with **ss 32K–32M** giving the purchaser a right to rescind for false/incomplete information. Read from the authorised Act PDF — `docs/sources/vic/sales_of_land_act_1962.pdf` (landing page: https://www.legislation.vic.gov.au/in-force/acts/sale-land-act-1962)
- *Sale of Land Amendment Act 2019* (Vic) — the reform (commenced 1 March 2020) that reshaped the modern s32 disclosure regime and added the buyer due-diligence checklist — https://www.consumer.vic.gov.au/latest-news/sale-of-land-amendment-act-2019-legislation-update
