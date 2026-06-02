---
slug: kb.insurance.timing-of-risk-pass
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# When risk passes to the buyer, and when insurance must be in force

**Risk passing** is the moment responsibility for loss or damage to the property — fire, storm, flood, vandalism — shifts from the **vendor** to the **buyer**. It determines the single most consequential settlement-prep date: **the day from which the buyer must hold building insurance**. The trigger is set by **state law and the standard contract**, and it differs sharply across NSW, VIC and QLD. This doc owns **the per-state risk-passing rule and the insurance-binding timing**; it grounds the `settlement_prep` date `key_dates.building_insurance_effective_date` and the `milestones.insurance_bound` milestone. The risk-passing rules are **REGULATED**; the lender's insurance requirement is **LENDER-POLICY / CONVENTION**.

## By state

- **NSW (Conveyancing Act 1919, Div 7 of Pt 4, ss 66J–66M).** Risk **stays with the vendor**: it does **not** pass to the purchaser until the **earlier of (a) completion of the sale, or (b) a time the parties stipulate after the purchaser enters (or is entitled to enter) into possession** — whichever first occurs (**s66K(1)**). Possession includes occupation pending completion and receipt of income (s66K(2)). If the land is **substantially damaged** before risk passes, the purchaser may **rescind by written notice before completion, within 28 days** of becoming aware (**s66L**), or take an abatement of price (**s66M**); "substantially damaged" means rendered materially different from what was contracted for (s66J). So in NSW the buyer's building insurance need only be in force **from settlement** — but lender requirements and prudence put it on/before the settlement day.
- **VIC (Sale of Land Act 1962, Div 3 of Pt II — Insurance, ss 34–36).** Risk effectively **stays with the vendor until the purchaser becomes entitled to possession or to the receipt of rents and profits** (i.e. settlement). The Act bridges the gap: during the period between contract and that entitlement, **any insurance policy the vendor maintains enures for the benefit of the purchaser** (**s35**) to the extent the purchaser is not otherwise indemnified. If the dwelling is **so destroyed or damaged as to be unfit for occupation** before that entitlement, the purchaser may **rescind by written notice within 14 days** of becoming aware (**s34**); any contracting-out of s34 is **void** (s34(3)). So a VIC buyer binds their own building insurance **from settlement**, with the vendor's policy as a statutory backstop in the interim.
- **QLD (standard REIQ contract cl 8.1 + Property Law Act 2023, s77).** The opposite posture: under the standard contract, **risk passes to the buyer at 5pm on the first business day after the Contract Date** — *before* possession and *before* settlement. From that moment the buyer bears the risk of damage. The statutory backstop is narrow: **s77** of the Property Law Act 2023 lets the buyer **rescind only if the dwelling becomes "unfit for occupation"** (i.e. destroyed or near-destroyed) before the earlier of settlement, possession, or the seller restoring it — and it applies despite any agreement to the contrary (s77(6)). **Ordinary partial damage** (a storm-damaged roof, a kitchen fire short of "unfit") between contract and settlement is **the buyer's loss**. So a QLD buyer **must bind building insurance immediately after signing** — effectively from the day after the contract date.

## The asymmetry (the load-bearing fact)

| | NSW | VIC | QLD |
|---|---|---|---|
| Risk passes on | settlement (or stipulated post-possession time) | possession / settlement | **5pm the first business day after contract** |
| Statutory damage backstop | rescind ≤28 days if substantial (s66L) | rescind ≤14 days if unfit (s34); vendor's policy enures (s35) | rescind only if **unfit** (s77) |
| Buyer must insure from | settlement | settlement | **the day after contract** |

In NSW and VIC the vendor carries the risk to settlement (VIC even routes the vendor's own policy to the buyer in the gap). In QLD the buyer carries it from the day after signing. A QLD Mode-A buyer who waits until settlement to arrange insurance is **uninsured through the entire contract-to-settlement window** for any damage short of total destruction.

## The lender's overlay (every state)

Independently of who bears statutory risk, a **lender will not release loan funds at settlement without evidence of building insurance** — a **certificate of currency** naming the lender as an interested/mortgagee party. So building insurance must be **in force by the settlement day in every state** for the loan to complete; QLD simply requires it much earlier. (This is lender policy, not statute — confirm the exact certificate requirement with the lender.)

## Relevance for Vietnamese-Australian buyers (Mode A)

- **QLD buyers — insure the day you sign.** The plan front-loads the `insurance_bound` milestone to the day after the contract date, not settlement, and names it as a hard, immediate action. This is the most common uninsured-gap trap and it is QLD-specific.
- **NSW / VIC buyers — insure by settlement; the lender will insist anyway.** Risk sits with the vendor until settlement, but the loan cannot complete without a certificate of currency, so the milestone lands on/just before settlement.
- **Buying a strata apartment? The building is insured by the body corporate.** For a strata lot, the **owners corporation / body corporate carries the building insurance** (cross-ref `kb.strata-report.red-flags` — confirm the strata policy is current and adequate). The buyer arranges **contents insurance only**, not a building policy. The risk-passing analysis still matters for the building, but it is the strata policy that responds.
- **Information, not advice.** The plan states the statutory risk-passing rule and the insurance timing, and directs the buyer to their insurer and conveyancer; it does not recommend an insurer or give a coverage opinion.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `building_insurance_effective_date` is **resolver-derived** from the buyer's state against the lookup below: QLD → contract_signed_date + 1 business day; NSW/VIC → settlement_date.

```jsonc
{
  "fills": [],
  "parameters": {
    "qld_risk_passes_day_after_contract": { "type": "bool", "value": true, "note": "REGULATED (QLD, standard REIQ contract cl 8.1; statutory backstop Property Law Act 2023 s77) — risk passes to the buyer at 5pm on the first business day after the Contract Date, before possession or settlement; s77 lets the buyer rescind only if the dwelling becomes UNFIT for occupation, so ordinary partial damage is the buyer's loss. The load-bearing fact: a QLD buyer must bind building insurance immediately after signing." },
    "nsw_vic_risk_passes_at_settlement": { "type": "bool", "value": true, "note": "REGULATED (NSW Conveyancing Act 1919 s66K; VIC Sale of Land Act 1962 ss34–35) — risk stays with the vendor until completion/possession; the buyer's own building insurance need only be in force from settlement. VIC additionally routes the vendor's insurance to the buyer in the interim (s35)." },
    "lender_requires_insurance_before_settlement": { "type": "bool", "value": true, "note": "LENDER-POLICY / CONVENTION — a lender will not release loan funds at settlement without a certificate of currency for building insurance naming the lender; so insurance must be in force by the settlement day in every state regardless of who bears statutory risk. Confirm the exact requirement with the lender." },
    "strata_building_insured_by_body_corporate": { "type": "bool", "value": true, "note": "REGULATED / CONVENTION — for a strata lot the owners corporation / body corporate insures the building; the buyer needs CONTENTS insurance only, not a building policy. See kb.strata-report.red-flags to confirm the strata policy is current and adequate." }
  },
  "lookup": {
    "risk_passing_by_state": {
      "note": "REGULATED — when risk passes from vendor to buyer, and from when the buyer must hold building insurance, per state. building_insurance_effective_date is resolver-derived from this: QLD = contract_signed_date + 1 business day; NSW/VIC = settlement_date.",
      "entries": [
        { "state": "NSW", "statute": "Conveyancing Act 1919, ss 66J–66M", "risk_passes_on": "completion of sale, or a stipulated time after possession, whichever first (s66K)", "buyer_insures_from": "settlement", "damage_backstop": "rescind by notice before completion, ≤28 days of awareness if substantially damaged (s66L); or abatement (s66M)", "note": "REGULATED — vendor bears risk until completion/possession" },
        { "state": "VIC", "statute": "Sale of Land Act 1962, ss 34–36", "risk_passes_on": "purchaser becomes entitled to possession or to rents/profits (settlement)", "buyer_insures_from": "settlement", "damage_backstop": "rescind ≤14 days if dwelling unfit for occupation (s34, non-excludable); vendor's policy enures for the buyer in the interim (s35)", "note": "REGULATED — vendor bears risk until possession; s35 statutory insurance bridge" },
        { "state": "QLD", "statute": "standard REIQ contract cl 8.1; Property Law Act 2023 s77", "risk_passes_on": "5pm on the first business day after the Contract Date", "buyer_insures_from": "the day after the contract date (immediately on signing)", "damage_backstop": "rescind under s77 ONLY if the dwelling becomes unfit for occupation before settlement/possession/restoration; partial damage is the buyer's risk", "note": "REGULATED — buyer bears risk from the day after contract; the QLD-specific uninsured-gap trap" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `building_insurance_effective_date` is resolver-derived from the buyer's state against the lookup (QLD = contract + 1 business day; NSW/VIC = settlement); the `insurance_bound` milestone due-date follows. Business-day arithmetic is resolver code (shared with `kb.cooling-off.by-state`).
- **REGULATED — all three states read against the primary Acts.** NSW (Conveyancing Act 1919 ss66J–66M) and VIC (Sale of Land Act 1962 ss34–36) were read from the authorised PDFs in `docs/sources/` (both legislation sites block automated fetch); QLD s77 was read from the authorised `legislation.qld.gov.au` PDF (current as at 28 Apr 2026), and the 5pm-next-business-day rule is the standard REIQ contract clause 8.1, confirmed against QLD government and conveyancing sources.
- **The asymmetry is the load-bearing fact.** QLD flips risk to the buyer at contract; NSW/VIC keep it with the vendor to settlement. It is captured as two top-level parameters and on every lookup row because it changes the timing of a hard, money-exposed action.
- **Seam flagged, not patched.** The `settlement_prep` blueprint declares `key_dates.building_insurance_effective_date` as `derived_from: key_dates.settlement_date`. That default is correct for NSW/VIC but **wrong for QLD**, where risk passes the day after contract — deriving the insurance date from settlement would leave a QLD buyer uninsured for the whole contract-to-settlement window. The resolver must branch on state per the lookup above; the blueprint's single `derived_from` hint should be reconciled to a state-conditional derivation. Surfaced for a separate blueprint fix.
- **Single-owner.** This doc owns **risk-passing and insurance timing**. The **cooling-off** window → `kb.cooling-off.by-state`; the **strata building policy** → `kb.strata-report.red-flags`; the **settlement timeline and milestones generally** → `kb.settlement.process-by-state`; the **lender document timeline** → `kb.lender-docs.standard-timeline`. Cross-ref, not duplicated.

## Sources

**Canonical (state authorities / legislation):**

- *Conveyancing Act 1919* (NSW), **ss 66J–66M** (s66K risk passes at completion or stipulated post-possession time; s66L 28-day rescission for substantial damage; s66M abatement; s66J "substantially damaged" definition). Authorised version, current for 15 Aug 2025 — `docs/sources/nsw/conveyancing_act_1919_no_6.pdf`
- *Sale of Land Act 1962* (Vic), **ss 34–36** (s34 14-day rescission if dwelling unfit, non-excludable; s35 vendor's insurance enures for the buyer between contract and possession). Authorised Version No. 172, incorporating amendments as at 25 November 2025 — `docs/sources/vic/sales_of_land_act_1962.pdf`
- *Property Law Act 2023* (Qld), **s 77** ("Buyer may rescind contract if residential dwelling unfit for occupation" — rescind before the earliest of settlement, possession, or the seller restoring the dwelling; refund on rescission; applies despite any agreement to the contrary). Act No. 27 of 2023, authorised PDF current as at 28 Apr 2026 — https://www.legislation.qld.gov.au/view/pdf/inforce/current/act-2023-027
- Queensland Government / conveyancing guidance — *risk passes to the buyer at 5pm on the first business day after the Contract Date* under the standard REIQ contract (cl 8.1); buyers should arrange insurance immediately after signing — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home

**Point-in-time / practice (lender requirement — confirm with the lender):**

- Lender practice: loan funds are not released at settlement without a certificate of currency for building insurance naming the lender as mortgagee. This is lender policy and varies by lender; treated as CONVENTION/LENDER-POLICY and surfaced as "confirm with your lender," never as a fixed rule.
