---
slug: kb.contract-of-sale.review-points-by-state
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# Contract of sale — review points, by state

The **contract of sale** is the binding agreement to buy the property. Before signing, a buyer (through their conveyancer or solicitor) reviews it for the terms that bind them and the disclosures the vendor must make. What the vendor is **required to disclose**, and what attaches to the contract, is set by **state law** and differs across NSW, VIC and QLD. This doc owns **the standard contract-review points per state and the mandatory vendor-disclosure regime in each**; it grounds the `due_diligence` parameter `contract_of_sale_flags` (agent-reasoned, `reasoning_domain: document_significance`) — supplying the checklist of items the agent reasons over when a contract is uploaded, not a verdict on any one contract.

## NSW

- **Vendor-disclosure model: prescribed documents attached to the contract.** Under the **Conveyancing Act 1919 s52A(2)(a)** and **Conveyancing (Sale of Land) Regulation 2022, Schedule 1 Part 1**, the vendor must attach prescribed documents — a **planning certificate** for the land, a **sewerage diagram** from the recognised sewerage authority, a **property certificate and plan** issued by the Registrar-General (the title), and the **instruments creating any easements, profits à prendre, restrictions or positive covenants** on the land (with strata/community-scheme equivalents). A contract missing a prescribed document can give the buyer a right to rescind.
- **Review points.** Identify the **parties and the property** (title reference, inclusions/exclusions), the **price and deposit** (usually **10%**), the **settlement period**, any **special conditions**, easements/covenants/restrictions on title, and the **section 10.7 certificate** for zoning and planning constraints. Confirm the **cooling-off** treatment (see `kb.cooling-off.by-state`) and whether a s66W waiver is contemplated.
- **Gazumping risk.** Until contracts are exchanged, the vendor is not bound and may accept a higher offer; the plan flags the value of moving promptly to exchange.

## VIC

- **Vendor-disclosure model: the Section 32 vendor statement.** VIC's mandatory pre-contract disclosure is a **separate statutory document — the Section 32 statement** under the Sale of Land Act 1962 — given to the buyer **before** they sign. Its mandated contents and red flags are owned by `kb.s32.review-points`; the contract review and the s32 review are **two distinct steps** in VIC.
- **Review points (contract).** Parties and property, price and deposit, settlement date, special conditions, and inclusions (chattels). The bulk of the **disclosure** scrutiny in VIC happens on the s32, not the contract body — so the agent reasons over the s32 flags in parallel.

## QLD

- **Vendor-disclosure model: the mandatory Seller Disclosure Scheme (from 1 Aug 2025).** Under the **Property Law Act 2023 (Part 7, Division 4)**, from **1 August 2025** the seller must give the buyer a **disclosure statement (Form 2)** plus **prescribed certificates** **before** the buyer signs the contract (**s99**). If the seller fails to disclose or makes an inaccurate disclosure, the buyer may **terminate** the contract before settlement (**s104**), and the seller must repay amounts paid (**s105**). This is a recent, load-bearing change: a QLD contract signed on/after 1 Aug 2025 must be checked for a compliant disclosure statement.
- **Review points.** The contract is typically the **REIQ standard Contract for Houses and Residential Land**; confirm the **warning statement**, the **price and deposit**, the **finance and building/pest conditions**, the **settlement date**, and the **disclosure statement + certificates**. The contract gives **no warranty on structural soundness** — so a building/pest inspection is essential (see `kb.building-pest.interpretation`).

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Always reviewed by a conveyancer/solicitor before signing — never solo.** For a first-home buyer, especially one navigating a second-language contract, the plan's firm instruction is to have the contract (and in VIC the s32) reviewed by a licensed conveyancer or solicitor **before** signing, and to take a copy away rather than sign under pressure.
- **The disclosure regime differs by state — and QLD just changed.** A Mode A buyer in QLD on/after 1 Aug 2025 has a new statutory disclosure protection; a VIC buyer relies on the s32; a NSW buyer on the prescribed attached documents. The plan surfaces the right checklist for the buyer's state.
- **Information, not advice.** The plan lists the standard review points and disclosure requirements and directs the buyer to their legal professional; it does not give a legal opinion on a specific contract.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `contract_of_sale_flags` is **agent-reasoned** (`reasoning_domain: document_significance`) over an uploaded contract; this doc supplies the per-state review checklist and disclosure regime the agent reasons against, not a flag list.

```jsonc
{
  "fills": [],
  "parameters": {
    "always_legal_review_before_signing": { "type": "bool", "value": true, "note": "CONVENTION (strong) — the contract (and in VIC the s32) should be reviewed by a licensed conveyancer/solicitor before signing; the platform stays in information/decision-support, never gives a legal opinion on a contract" },
    "typical_deposit_pct": { "type": "percentage", "value": 10, "note": "CONVENTION — a ~10% deposit on exchange/signing is standard practice; the exact figure is negotiable and set in the contract" },
    "nsw_prescribed_documents_attached": { "type": "array<string>", "value": ["planning_certificate", "sewerage_diagram", "property_certificate_and_plan", "easement_covenant_instruments"], "note": "REGULATED (NSW, Conveyancing Act 1919 s52A(2)(a) + Conveyancing (Sale of Land) Regulation 2022, Sch 1 Pt 1) — prescribed documents the vendor must attach to the contract; omission can give a rescission right" },
    "vic_disclosure_is_section_32": { "type": "bool", "value": true, "note": "REGULATED (VIC, Sale of Land Act 1962) — VIC pre-contract disclosure is the separate Section 32 vendor statement; its contents/red-flags are owned by kb.s32.review-points, not here" },
    "qld_seller_disclosure_scheme_from": { "type": "string", "value": "2025-08-01", "note": "REGULATED (QLD, Property Law Act 2023 — Act No. 27 of 2023 — Part 7 Div 4: s99 give disclosure before signing, s104 buyer may terminate for failure/inaccurate disclosure, s105 seller repays) — mandatory seller disclosure statement (Form 2) + prescribed certificates before the buyer signs, commenced 1 Aug 2025" },
    "qld_contract_no_structural_warranty": { "type": "bool", "value": true, "note": "REGULATED (QLD) — the contract gives no warranty on structural soundness; a building/pest inspection is the buyer's protection (see kb.building-pest.interpretation)" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `contract_of_sale_flags` is produced by agent reasoning over the uploaded contract; this doc is the **grounding checklist** (per-state review points + disclosure regime) the agent reasons against. Same pure-reference shape as the other `due_diligence` anchors.
- **Provenance is mixed — REGULATED disclosure regimes + CONVENTION practice.** The disclosure models (NSW prescribed documents, VIC s32, QLD Form 2) are REGULATED and state-specific; the ~10% deposit and "always have it reviewed" are CONVENTION. Tagged so the agent presents the disclosure requirements as the law and the practice points as standard guidance.
- **QLD's Seller Disclosure Scheme is the load-bearing recent change.** Commenced 1 Aug 2025 under the Property Law Act 2023 — verified live because it post-dates the model snapshot. A QLD contract from that date must carry a compliant disclosure statement, and the agent flags its absence as high-severity.
- **Single-owner across the due-diligence cluster.** This doc owns the **contract** review points and the **disclosure regime per state**. The VIC **s32 contents** → `kb.s32.review-points`. The **special conditions** a buyer requests → `kb.special-conditions.standard-set`. **Building/pest** interpretation → `kb.building-pest.interpretation`; **strata records** → `kb.strata-report.red-flags`. **Cooling-off** → `kb.cooling-off.by-state`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities / legislation):**

- *Conveyancing (Sale of Land) Regulation 2022* (NSW), **Schedule 1 Part 1** (prescribed documents — planning certificate, sewerage diagram, property certificate + plan, easement/covenant instruments) made under *Conveyancing Act 1919* **s52A(2)(a)** — `docs/sources/nsw/conveyancing_regulation_2022_act.pdf`
- NSW Fair Trading — *Making an offer on a property* (consumer-facing summary; ~10% deposit; review the contract before signing) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/making-an-offer-on-a-property
- Consumer Affairs Victoria — *Conveyancing and contracts for sellers* (the Section 32 vendor statement is the VIC pre-contract disclosure document) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/selling-property/conveyancing-and-contracts-for-sellers
- Queensland Government — *Seller disclosure scheme* (mandatory disclosure statement + prescribed certificates before signing, from 1 Aug 2025; non-compliance may allow termination) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/seller-disclosure-scheme
- Queensland Government — *Contract of sale for buying a home* (REIQ standard contract; no structural-soundness warranty; review with a solicitor before signing) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/making-an-offer-on-a-home/contract-of-sale
- *Property Law Act 2023* (Qld), **Part 7 Division 4, ss 99–105** (s99 seller must give disclosure documents before signing; s104 buyer may terminate for failure/inaccurate disclosure; s105 seller must repay on termination). Act No. 27 of 2023, verified against the authorised PDF current as at 1 Aug 2025 — https://www.legislation.qld.gov.au/view/pdf/inforce/current/act-2023-027
