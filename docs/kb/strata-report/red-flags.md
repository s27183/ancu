---
slug: kb.strata-report.red-flags
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/strata/strata-publications/section-184-certificate-strata-schemes
    retrieved: 2026-07-06
    note: "NSW Government — s184 strata information certificate (Strata Schemes Management Act 2015 s184); the buyer's window into the scheme's financial and governance records. Form last updated 19 Mar 2026 (extra mandated content from 1 Apr 2026)."
  - url: https://www.consumer.vic.gov.au/housing/owners-corporations/finance-insurance-and-record-keeping/records
    retrieved: 2026-07-06
    note: "Consumer Affairs Victoria — owners corporation certificate under Owners Corporations Act 2006 s151 discloses fees, funds, insurance and disputes to a prospective purchaser"
---

# Strata report — red flags and what they mean

A **strata report** (strata search / inspection report) is a review of a scheme's **owners-corporation / body-corporate records** — meeting minutes, financial statements, the capital-works/sinking-fund position, insurance, by-laws and registers — commissioned before purchase, usually through a strata-search professional or the buyer's conveyancer. The underlying records are **regulated disclosures** the buyer can obtain: a **section 184 strata information certificate** (NSW), an **owners corporation certificate under s151** (VIC), or a **body-corporate records search** (QLD). This doc owns **the red flags a buyer reads a strata report for, what each means, and the action it triggers**; it grounds the `due_diligence` parameter `strata_flags` (agent-reasoned, `reasoning_domain: document_significance`). The health framework these flags are read against — fund adequacy and what "healthy" looks like — is owned by `kb.strata.health-indicators`.

## The red flags

Each flag is paired with what it signals and the action it triggers (the agent assigns severity per the specific report):

- **Under-funded capital-works / sinking fund.** The fund balance is thin relative to the building's age and the forward plan (NSW 10-yr plan, QLD ≥9-yr forecast — see `kb.strata.health-indicators`). **Means:** a special levy is likely. **Action:** estimate the likely special levy and factor it, or use it to renegotiate.
- **Pending or recent special levies.** A special levy already raised or flagged in minutes. **Means:** an unexpected lump-sum cost. **Action:** clarify the amount, timing, and whether the **vendor or buyer** bears a levy struck near settlement.
- **Building defects — especially combustible cladding and waterproofing.** Defect reports, rectification orders, or cladding on the register (newer buildings). **Means:** large latent cost and possible safety/insurance issues. **Action:** obtain the defect/cladding details; treat as high-severity.
- **Litigation or active disputes.** Minutes referencing legal action (against a builder, an owner, or the OC). **Means:** unresolved problems and legal cost. **Action:** get specifics and likely exposure.
- **Insufficient or lapsed insurance.** Building insurance not current or below replacement value. **Means:** uninsured risk borne by owners. **Action:** confirm a current policy to replacement value before proceeding.
- **High owner arrears.** A material share of owners behind on levies. **Means:** cash-flow stress; the funds may not meet obligations. **Action:** weigh against fund adequacy.
- **Deferred major works in the minutes.** Roof, lifts, repainting, structural works discussed but not funded. **Means:** a looming special levy. **Action:** match against the fund balance.
- **Restrictive by-laws.** Rules on pets, **short-stay letting**, renovations, parking or flooring. **Means:** limits on the buyer's use of their own lot. **Action:** check against the buyer's needs (e.g. a pet, future renovation).
- **Governance instability.** Frequent strata-manager turnover, self-management struggles, or no functioning committee. **Means:** the scheme may be poorly run, compounding the above. **Action:** weigh as a contextual risk.

## How the report fits the buying sequence

- **Obtain it during due diligence — and protect it with a condition on private treaty.** On a private-treaty offer the buyer can make the contract **subject to a satisfactory strata report** (see `kb.special-conditions.standard-set`); the report is then reviewed within the condition's window. **At auction this condition is unavailable** — the strata report must be reviewed **before** bidding (see `kb.cooling-off.by-state`).
- **In VIC the owners-corporation certificate is attached to the Section 32.** So part of the strata disclosure arrives with the vendor statement (see `kb.s32.review-points`); a fuller strata search adds the minutes and financial detail.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The special levy is the trap.** A modestly-priced first apartment with a healthy-looking quarterly levy can still carry a **$20k special levy two AGMs away** if the sinking fund is under-funded or a defect program is pending. The agent reads the report and surfaces this as a high-severity flag rather than letting it ambush the buyer after settlement.
- **By-laws can defeat the plan.** A Mode A buyer planning to keep a pet, renovate, or let the property may be blocked by by-laws — surfaced as a fit issue, not just a financial one.
- **Information, not advice.** The plan flags what the report shows and what to ask; the report itself is obtained through a strata-search professional or the buyer's conveyancer, and material findings are matters for that professional.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `strata_flags` is **agent-reasoned** over the uploaded report; this doc supplies the red-flag catalogue and the action each triggers, not a flag list for a specific scheme.

```jsonc
{
  "fills": [],
  "parameters": {
    "red_flags": { "type": "array<{ flag, means, action }>", "value": [
      { "flag": "underfunded_capital_works_sinking_fund", "means": "special levy likely", "action": "estimate and factor the likely special levy, or renegotiate" },
      { "flag": "pending_or_recent_special_levy", "means": "unexpected lump-sum cost", "action": "clarify amount/timing and whether vendor or buyer bears a levy struck near settlement" },
      { "flag": "building_defects_cladding_waterproofing", "means": "large latent cost; safety/insurance risk", "action": "obtain defect/cladding details; high-severity" },
      { "flag": "litigation_or_active_disputes", "means": "unresolved problems and legal cost", "action": "get specifics and likely exposure" },
      { "flag": "insufficient_or_lapsed_insurance", "means": "uninsured risk borne by owners", "action": "confirm current policy to replacement value" },
      { "flag": "high_owner_arrears", "means": "cash-flow stress; funds may not meet obligations", "action": "weigh against fund adequacy" },
      { "flag": "deferred_major_works_in_minutes", "means": "looming special levy", "action": "match against the fund balance" },
      { "flag": "restrictive_by_laws", "means": "limits on the buyer's use (pets, short-stay letting, renovations, parking)", "action": "check against the buyer's needs" },
      { "flag": "governance_instability", "means": "scheme may be poorly run, compounding other risks", "action": "weigh as contextual risk" }
    ], "note": "the red-flag catalogue the agent reasons over when a strata report is uploaded; severity is assigned per the specific report (document_significance reasoning)" },
    "obtain_via": { "type": "array<string>", "value": ["nsw_section_184_certificate", "vic_owners_corporation_certificate_s151", "qld_body_corporate_records_search", "strata_search_professional"], "note": "REGULATED disclosure mechanisms by which the buyer obtains the records the report is built from" },
    "special_levy_is_the_load_bearing_trap": { "type": "bool", "value": true, "note": "load-bearing Mode-A fact — the most common post-settlement surprise: a healthy-looking levy hiding an imminent special levy from an under-funded fund or pending works; flagged high-severity" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `strata_flags` is produced by agent reasoning over the uploaded report; this doc is the red-flag catalogue the agent reasons against, with severity assigned per the specific report.
- **Catalogue is CONVENTION; obtain-via mechanisms are REGULATED.** The red-flag list and recommended actions are professional/inspection practice; the certificate mechanisms (NSW s184, VIC s151 OC certificate, QLD records search) are statutory disclosure routes. Tagged so the agent presents the flags as "things to check / ask about," never as a verdict on the scheme.
- **The special levy is the load-bearing trap.** Lifted to an explicit parameter because it is the single most common way a first-home apartment buyer is surprised after settlement — a healthy-looking levy masking an imminent special levy.
- **Single-owner — report flags vs the adequacy rubric vs the condition vs the cost.** This doc owns **the red flags and their actions**. The **definition of fund adequacy / what healthy looks like** → `kb.strata.health-indicators` (read against, not redefined here). The **"subject to satisfactory strata report" condition** → `kb.special-conditions.standard-set`. The **levy as a recurring cost** → `kb.ongoing-costs.rates-water-strata`. The **VIC OC certificate's place in the s32** → `kb.s32.review-points`. The **auction "no condition" branch** → `kb.cooling-off.by-state`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities / legislation):**

- NSW Government — *Section 184 certificate – strata schemes* (the strata information certificate a buyer requests to obtain the scheme's financial and governance records) — https://www.nsw.gov.au/housing-and-construction/strata/strata-publications/section-184-certificate-strata-schemes
- Consumer Affairs Victoria — *Records – owners corporations* (the owners corporation certificate under **s151 of the Owners Corporations Act 2006** + Reg 16, OC Regulations 2018, discloses fees, funds, insurance and disputes to a prospective purchaser) — https://www.consumer.vic.gov.au/housing/owners-corporations/finance-insurance-and-record-keeping/records
- Queensland Government — *Funds for managing a body corporate* (administrative + sinking fund; records available via a body-corporate records search) — https://www.qld.gov.au/law/housing-and-neighbours/body-corporate/finance-insurance/funds
- ASIC Moneysmart — *Strata levy* (glossary: a fee owners pay for management of the common property of a strata-titled building) — https://moneysmart.gov.au/glossary/strata-levy

**Convention** — the specific red-flag catalogue and recommended actions are strata-search / inspection practice and professional judgement, not figures set by any authority; material findings are matters for the buyer's conveyancer and the strata-search professional.
