---
slug: kb.building-types.risk-by-type
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# Risk profiles by property type

Every dwelling type carries a **different risk profile** — what can go wrong, what protects the buyer, and what the buyer takes on. An established house puts the full structural and maintenance burden on the owner; an apartment lives or dies by the health of its body corporate; an off-the-plan purchase exposes the buyer to a completion valuation gap and developer risk. This doc owns **the per-property-type risk profile**; it grounds the `property_assessment` reasoning over `basics.property_type` — supplying the dominant risks and key protections the agent surfaces as `key_concerns` / `key_strengths` and folds into the `viability_verdict`. It does **not** value the property (that is `property_assessment`'s `valuation` reasoning) or assess a specific strata scheme (that is the strata docs). Provenance is mixed: statutory thresholds and sunset-clause regimes are **REGULATED**; the valuation-gap, maintenance-burden and defect-prevalence points are **CONVENTION**.

## By property type

- **`established_house`.** No body corporate — the owner carries the **full structural maintenance and building-insurance burden** alone (cross-ref `kb.maintenance.budget-by-property-type`). Age-related structural risk (footings/foundations movement, roof, rising damp, ageing wiring/plumbing) and **termite exposure** (highest in QLD and northern NSW). There is **no statutory builder warranty** on old work, so the **building + pest inspection is the buyer's only protection** (cross-ref `kb.building-pest.interpretation`). Strengths: a land component that holds value, no strata fees or special levies, full control over the property.
- **`established_apartment`.** The **health of the body corporate / owners corporation is the dominant risk** — sinking-fund adequacy, special levies, disputes, by-laws (cross-ref `kb.strata.health-indicators` and `kb.strata-report.red-flags`). **Combustible cladding** is a live cost-and-safety flag on towers built/clad in the relevant era, with state rectification programs (NSW Project Remediate, Cladding Safety Victoria, QLD Safer Buildings). The **building is insured by the owners corporation** (the buyer needs contents only). Lower land component; defects more likely in recently-built towers (waterproofing, cladding, structural).
- **`new_house` / `new_apartment`.** Covered by **statutory home-warranty insurance** (NSW Home Building Compensation **$20,000+** work; VIC Domestic Building Insurance **$16,000+**; QLD Queensland Home Warranty Scheme **$3,300+**) — which responds for incomplete or defective work if the builder dies, disappears, becomes insolvent, or has their licence cancelled — plus **statutory implied warranties and defect-liability periods**. Risks: **builder solvency**, and **defects in newly-built apartments** (waterproofing, cladding, structural) that surface in the first years.
- **`off_the_plan`.** The highest-variance profile, and the **load-bearing Mode-A risk cluster**:
  - **Completion valuation gap.** At completion the lender re-values the property; if it values **below the contract price**, the buyer must fund the shortfall **in cash**, and LMI / FHG are recalculated on the **lower** figure. The biggest off-the-plan finance trap for a leveraged first-home buyer.
  - **Long settlement.** Months or years between signing and completion → interest-rate and serviceability **drift**; a pre-approval at signing may not hold at completion.
  - **Developer insolvency** and **unknown build quality** — the buyer commits before the dwelling exists.
  - **Sunset clauses — now buyer-protective.** A vendor can no longer freely rescind under a sunset clause to re-sell at a higher price: in **NSW** (Conveyancing Act 1919 **s66ZS**) and **VIC** (Sale of Land Act 1962 **ss10A–10F**) the vendor may rescind under a sunset clause **only with every purchaser's written consent or a Supreme Court order**, on 28 days' notice, and contracting-out is void. (QLD has **no** equivalent statutory sunset-clause restriction — protection there is contractual; review the contract.)
- **`house_and_land`.** Typically a **split contract** (land purchase + a separate building contract) with **progress payments** through the build and **fixed-price build risk**; statutory home-warranty insurance applies to the build component (per the state thresholds above).

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Off-the-plan valuation gap is the trap to plan for.** A leveraged FHB committing off-the-plan should hold a **finance buffer** for a completion shortfall and understand that **FHG / LMI are recalculated on the lower of contract price or valuation** at completion. The plan surfaces this before the buyer signs, not after.
- **Established house = the full maintenance burden is yours.** No body corporate to share structural costs (cross-ref `kb.maintenance.budget-by-property-type` — and note the no-double-count with strata levies does not arise here).
- **Apartment = strata health makes or breaks it.** The plan routes an apartment buyer straight to the strata-report review; cladding-rectification status on an affected tower is a real future-cost and safety flag.
- **Sunset-clause protection is reassurance, not a worry.** A Mode-A off-the-plan buyer in NSW or VIC is statutorily protected against a developer cancelling to re-sell — the plan states this plainly so the buyer is not deterred by an outdated fear.
- **Information, not advice.** The plan describes the risk profile by type and directs the buyer to a building/pest inspector, conveyancer and (for the build) the warranty scheme; it does not value the property or recommend a builder/developer.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. It supplies the per-type risk profile the `property_assessment` agent reasons over to produce `key_concerns` / `viability_verdict`.

```jsonc
{
  "fills": [],
  "parameters": {
    "off_the_plan_valuation_gap_risk": { "type": "bool", "value": true, "note": "CONVENTION (the load-bearing param) — at completion the lender re-values the property; if it values below the contract price the buyer funds the shortfall in cash and LMI/FHG are recalculated on the lower figure. The single biggest off-the-plan finance trap for a leveraged FHB; the plan holds a finance buffer for it." },
    "established_house_no_body_corporate": { "type": "bool", "value": true, "note": "CONVENTION — an established house has no body corporate, so the full structural maintenance and building-insurance burden sits with the owner; the building+pest inspection is the only protection (no statutory builder warranty on old work). See kb.maintenance.budget-by-property-type." },
    "strata_building_insured_by_oc": { "type": "bool", "value": true, "note": "CONVENTION / REGULATED — for an apartment the owners corporation insures the building; the buyer needs contents insurance only. Strata health is the dominant apartment risk — see kb.strata.health-indicators, kb.strata-report.red-flags." },
    "sunset_clause_buyer_protection": { "type": "bool", "value": true, "note": "REGULATED (NSW Conveyancing Act 1919 s66ZS; VIC Sale of Land Act 1962 ss10A–10F) — for residential off-the-plan, a vendor may rescind under a sunset clause only with every purchaser's written consent or a Supreme Court order, on 28 days' notice; contracting-out is void. No equivalent statutory restriction in QLD (contractual only)." },
    "combustible_cladding_is_a_flag": { "type": "bool", "value": true, "note": "REGULATED (state programs: NSW Project Remediate, Cladding Safety Victoria, QLD Safer Buildings) — combustible cladding on towers of the relevant era is a cost-and-safety flag; check the building's rectification status. Applies to established_apartment / new_apartment." }
  },
  "lookup": {
    "risk_profile_by_property_type": {
      "note": "Dominant risks and the key protection per property_type enum value, for property_assessment to reason over. Most points are CONVENTION; the statutory items are tagged in the prose.",
      "entries": [
        { "property_type": "established_house", "dominant_risks": ["age-related structural defects", "termites (esp. QLD / northern NSW)", "full maintenance burden — no body corporate"], "key_protection": "building + pest inspection (no statutory builder warranty)", "note": "land value + full control are the strengths" },
        { "property_type": "established_apartment", "dominant_risks": ["body-corporate / sinking-fund health", "special levies", "combustible cladding (era-dependent)"], "key_protection": "strata report review; building insured by the owners corporation", "note": "see kb.strata.health-indicators, kb.strata-report.red-flags" },
        { "property_type": "new_house", "dominant_risks": ["builder solvency", "early-life defects"], "key_protection": "statutory home-warranty insurance + implied warranties + defect-liability period", "note": "warranty insurance thresholds in home_warranty_insurance_by_state" },
        { "property_type": "new_apartment", "dominant_risks": ["builder solvency", "waterproofing / cladding / structural defects", "body-corporate set-up"], "key_protection": "statutory home-warranty insurance; defect-liability period", "note": "newer towers carry higher early defect risk" },
        { "property_type": "off_the_plan", "dominant_risks": ["completion valuation gap (finance shortfall)", "long settlement → rate/serviceability drift", "developer insolvency", "unknown build quality"], "key_protection": "buyer-protective sunset-clause regime (NSW s66ZS / VIC ss10A–10F); a finance buffer for the valuation gap", "note": "the load-bearing Mode-A risk cluster" },
        { "property_type": "house_and_land", "dominant_risks": ["split contract", "progress-payment exposure", "fixed-price build risk"], "key_protection": "statutory home-warranty insurance on the build component", "note": "land + separate building contract" }
      ]
    },
    "home_warranty_insurance_by_state": {
      "note": "REGULATED — value of residential building work above which statutory home-warranty / builder insurance is mandatory. Responds for incomplete or defective work if the builder dies, disappears, becomes insolvent, or has their licence cancelled. Thresholds are stable but state-set; FY-stamped.",
      "entries": [
        { "state": "NSW", "scheme": "Home Building Compensation (HBC)", "regulator": "SIRA", "threshold_aud": 20000, "fy": "2025-26", "note": "REGULATED — cover required for residential building work valued at $20,000 or more (regulator-confirmed; SIRA page blocks automated fetch, figure long-standing)" },
        { "state": "VIC", "scheme": "Domestic Building Insurance (DBI)", "regulator": "VBA / VMIA", "threshold_aud": 16000, "fy": "2025-26", "note": "REGULATED — DBI required for domestic building work over $16,000; cover up to $300,000 for policies issued after 1 Jul 2014 (VBA/VMIA-confirmed)" },
        { "state": "QLD", "scheme": "Queensland Home Warranty Scheme", "regulator": "QBCC", "threshold_aud": 3300, "fy": "2025-26", "note": "REGULATED — compulsory for residential construction work valued over $3,300 (incl. materials, labour and GST); excludes residential buildings over three storeys. Primary-confirmed against QBCC." }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The doc grounds `property_assessment`'s agent reasoning (`reasoning_domain: valuation` / viability) over `basics.property_type`; the dominant-risk list feeds `key_concerns` and the `viability_verdict`. Same pure-reference shape as the other `property_assessment` anchors — confirming the shape rule: `property_assessment` outputs are agent/resolver-computed, so its KB anchors fill nothing.
- **The off-the-plan valuation gap is the load-bearing param.** Like the genuine-savings 1% rule, the doc's reason-to-exist is lifted out of prose into an explicit parameter so the agent reasons over it rather than burying it.
- **Mixed provenance, tagged per fact.** REGULATED: the home-warranty thresholds and the sunset-clause regimes (read against / confirmed to the primary Acts). CONVENTION: the valuation gap, maintenance burden, and defect-prevalence points. The agent presents the statutory items as the law and the rest as standard guidance.
- **Verification-status honesty.** QLD's $3,300 threshold was read against QBCC; VIC's $16,000 was confirmed against VBA/VMIA; NSW's $20,000 is regulator-named and consistent across sources but the SIRA page blocked automated fetch — it is long-standing and recorded as regulator-confirmed pending a primary read. NSW (s66ZS) and VIC (ss10A–10F) sunset sections were read from the authorised Act PDFs in `docs/sources/`.
- **Single-owner across the property cluster.** This doc owns the **risk profile by type**. **Strata health** → `kb.strata.health-indicators` / `kb.strata-report.red-flags`; **building/pest interpretation** → `kb.building-pest.interpretation`; **maintenance budgeting** → `kb.maintenance.budget-by-property-type`; **contract / disclosure** → `kb.contract-of-sale.review-points-by-state`; **insurance timing** → `kb.insurance.timing-of-risk-pass`; **FIRB** (foreign buyers and new/off-the-plan stock) → `kb.firb.status-determination`. Cross-ref, not duplicated.

## Sources

**Canonical (regulators / legislation):**

- *Conveyancing Act 1919* (NSW), **s 66ZS** (rescission under sunset clauses — vendor may rescind only with every purchaser's written consent or a Supreme Court order; 28-day notice; sunset event = creation of the subject lot, issue of the occupation certificate, or registration of the plan). Authorised version, current for 15 Aug 2025 — `docs/sources/nsw/conveyancing_act_1919_no_6.pdf`
- *Sale of Land Act 1962* (Vic), **ss 10A–10F** (residential off-the-plan sunset clauses — s10B consent-or-court; s10C inconsistent provision of no effect; s10D purported rescission a breach; s10E Supreme Court order; inserted by the Sale of Land Amendment Act 2019, No. 14/2019). Authorised Version No. 172, incorporating amendments as at 25 November 2025 — `docs/sources/vic/sales_of_land_act_1962.pdf`
- Queensland Building and Construction Commission (QBCC) — *Queensland Home Warranty Scheme* (compulsory for residential construction work over $3,300 incl. materials, labour and GST; excludes residential buildings over three storeys) — https://www.qbcc.qld.gov.au/home-owner-hub/queensland-home-warranty-scheme/what-home-warranty-insurance
- State Insurance Regulatory Authority (SIRA, NSW) — *Home Building Compensation* (HBC cover required for residential building work valued at $20,000 or more) — https://www.sira.nsw.gov.au/home-building-compensation
- Victorian Building Authority (VBA) — *Understanding domestic building insurance* (DBI required for domestic building work over $16,000) — https://www.vba.vic.gov.au/consumers/understanding-domestic-building-insurance-and-why-it-is-important
- Domestic Building Insurance (VMIA, Vic) — official DBI scheme (cover up to $300,000 for policies issued after 1 Jul 2014) — https://www.dbi.vmia.vic.gov.au/

**Canonical (cladding rectification programs):**

- Cladding Safety Victoria — https://www.vic.gov.au/cladding-safety-victoria
- NSW Project Remediate / cladding — https://www.nsw.gov.au/departments-and-agencies/building-commission-nsw
- QLD Safer Buildings — https://www.saferbuildings.qld.gov.au/

**Point-in-time / practice (INDICATIVE):**

- The completion **valuation gap** is lender practice, not a published figure: lenders value off-the-plan property at completion and may value below the contract price. Treated as CONVENTION/INDICATIVE and surfaced as a planning risk, never as a quantified prediction. See Moneysmart, *Buying off the plan* — https://moneysmart.gov.au/buying-a-home
