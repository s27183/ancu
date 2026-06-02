---
slug: kb.cooling-off.by-state
effective_from: 2025-07-01
last_verified: 2026-06-02
---

# Cooling-off periods, by state and transaction mode

A **cooling-off period** is a short, statutory window after a buyer signs a contract during which they may **withdraw** from the purchase, forfeiting only a small capped penalty rather than the full deposit. It exists for **private-treaty** purchases and **does not apply when a property is bought at auction**. The period length, the penalty, and the start trigger are set by **state statute** and differ across NSW, VIC and QLD. This doc owns **the cooling-off rules per state and transaction mode**; it grounds the `buying_strategy` parameters `transaction_mode.cooling_off_applies` (derived from `transaction_mode.type`) and `cooling_off_days`, and the `settlement_prep` derived date `cooling_off_end_date`. The figures are **REGULATED and EXACT** — they are statutory, not indicative.

## By state

- **NSW (Conveyancing Act 1919, Division 8 of Part 4).** A cooling-off period applies to every contract for the sale of residential property (**s66S**); it commences when the contract is made and ends at **5pm on the 5th business day** (s66S(3)(b)) — or the **10th business day for an off-the-plan contract** (s66S(3)(a)). The purchaser may rescind by written notice during the period (**s66U**), forfeiting **0.25% of the purchase price** to the vendor (**s66V(2)**). The period is **waived** if the purchaser gives a **section 66W certificate** — in writing, signed by a **solicitor or barrister independent of the vendor** — and there is also **no cooling-off** where the property is **sold by public auction** or the contract is made the **same day** as a passed-in auction, or on exercise of an option (**s66T**).
- **VIC (Sale of Land Act 1962, s31).** **3 clear business days** for a private sale of residential or small rural land, starting when the buyer signs. If the buyer withdraws they get a full refund **less the greater of $100 or 0.2% of the purchase price**. **No cooling-off** where the property is bought at a public auction **or within 3 clear business days before or after** a public auction, where it is mainly commercial/industrial, where it is farming land over 20 hectares, where the buyer had already signed an identical contract for the same land, or where the buyer is an estate agent or a corporate body.
- **QLD (Property Occupations Act 2014, ss 166–168).** **5 business days** (s166), starting the day the buyer **receives a copy of the contract signed by both parties** (or the next business day if received on a non-business day), ending at **5pm on the 5th business day**. The buyer waives or shortens it by **written notice** (s167); on termination during the period the seller may deduct a penalty of **0.25% of the purchase price** (s168). **No cooling-off** for a property bought at auction. *(Cooling-off is in the Property Occupations Act 2014 — not the Property Law Act 2023, which separately introduced the seller-disclosure scheme; see `kb.contract-of-sale.review-points-by-state`.)*

## The auction carve-out (universal)

Across all three states the cooling-off right **does not apply to an auction purchase**. This is the single most consequential branch for the bid plan: a buyer who succeeds at auction is **immediately and unconditionally bound** — there is no finance condition, no building/pest condition, and no cooling-off escape. All due diligence (finance pre-approval, building/pest, contract/s32 review) must therefore be **complete before** the buyer raises a paddle. For private treaty, the cooling-off window is a (short, penalty-bearing) safety net; for auction there is none.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The transaction mode changes the whole risk posture.** A Mode A buyer planning to bid at auction must understand there is **no cooling-off and no subject-to-finance** — the plan front-loads unconditional finance approval and all inspections. The same buyer making a private-treaty offer has a 3–5 business-day window and can insert conditions (see `kb.special-conditions.standard-set`).
- **The penalty is small but real.** Withdrawing in the cooling-off window costs 0.25% (NSW/QLD) or the greater of $100/0.2% (VIC) of the price — on a $700k purchase, ~$1,400–$1,750. The plan states this plainly so it isn't mistaken for "free to walk away."
- **Information, not advice.** The plan states the statutory right and points the buyer to their conveyancer/solicitor to exercise it (a NSW **s66W waiver certificate must be signed by a solicitor or barrister** independent of the vendor — not a conveyancer — so waiving is a legal step taken on advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `cooling_off_applies` and `cooling_off_days` are **resolver-derived** from `transaction_mode.type` and the buyer's state against this lookup: auction (and the VIC near-auction window) → not applicable; private treaty → the per-state period.

```jsonc
{
  "fills": [],
  "parameters": {
    "no_cooling_off_at_auction": { "type": "bool", "value": true, "note": "REGULATED — universal across NSW/VIC/QLD: a property bought at auction has NO cooling-off period; an auction buyer is immediately and unconditionally bound. The load-bearing branch for the bid plan." },
    "private_treaty_has_cooling_off": { "type": "bool", "value": true, "note": "REGULATED — private-treaty / private-sale purchases carry the statutory cooling-off window per the by-state lookup below" }
  },
  "lookup": {
    "cooling_off_by_state": {
      "note": "REGULATED, EXACT — statutory cooling-off rules per state for a residential private-treaty purchase. period_business_days and penalty are set by state statute. For transaction_mode == auction, cooling_off_applies = false in every state (see no_cooling_off_at_auction).",
      "entries": [
        { "state": "NSW", "statute": "Conveyancing Act 1919, Div 8 of Pt 4", "period_business_days": 5, "off_the_plan_period_business_days": 10, "starts_on": "when the contract is made", "ends_at": "5pm on the 5th business day (10th for off-the-plan)", "penalty_pct_of_price": 0.25, "penalty_min_aud": null, "waivable_by": "section 66W certificate (solicitor or barrister independent of the vendor)", "auction_excluded": true, "note": "REGULATED — period s66S, no-cooling-off cases s66T (incl. public auction / passed-in-auction same day / option), rescission s66U, 0.25% forfeiture s66V(2), certificate s66W. Off-the-plan period is 10 business days (s66S(3)(a))" },
        { "state": "VIC", "statute": "Sale of Land Act 1962, s31", "period_business_days": 3, "period_basis": "clear business days", "starts_on": "buyer signs the contract", "penalty_pct_of_price": 0.2, "penalty_min_aud": 100, "penalty_rule": "greater of $100 or 0.2% of the purchase price", "auction_excluded": true, "note": "REGULATED — s31: terminate within 3 clear business days of signing (s31(2)); retain $100 or 0.2% whichever greater (s31(4)); exclusions s31(5) — publicly advertised auction, sale within 3 clear business days before/on/after such an auction, commercial/industrial land, farming land >20ha, an identical prior contract, or a buyer that is an estate agent/corporate body" },
        { "state": "QLD", "statute": "Property Occupations Act 2014, ss 166–168", "period_business_days": 5, "starts_on": "buyer receives a copy of the contract signed by both parties (or next business day)", "ends_at": "5pm on the 5th business day", "penalty_pct_of_price": 0.25, "penalty_min_aud": null, "terminate_by": "written notice", "auction_excluded": true, "note": "REGULATED — period s166, waive/shorten s167, 0.25% termination penalty s168. Cooling-off is under the Property Occupations Act 2014, NOT the Property Law Act 2023 (which separately added seller disclosure from 1 Aug 2025)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `cooling_off_applies`/`cooling_off_days` are resolver-derived from transaction mode + state against the lookup; the settlement `cooling_off_end_date` is then computed from `contract_signed_date` + the per-state period (business-day arithmetic in resolver code). The doc supplies the statutory rules, not a date.
- **REGULATED and EXACT — all three states verified against the primary Acts.** NSW (Conveyancing Act 1919, Div 8 of Pt 4, ss66S–66W), VIC (Sale of Land Act 1962, s31) and QLD (Property Occupations Act 2014, ss166–168) were each read from the authorised legislation (the NSW/VIC PDFs in `docs/sources/`, since both sites block automated fetch; the QLD PDF from `legislation.qld.gov.au`). Periods, forfeiture amounts and exclusions are quoted from the section text. Unlike the indicative cost bands, these are statutory constants the resolver applies precisely.
- **The auction carve-out is the load-bearing fact.** It is captured as a top-level parameter (`no_cooling_off_at_auction`) and on every lookup row because it changes the entire due-diligence sequencing: auction → all inspections and unconditional finance **before** bidding; private treaty → a short penalty-bearing safety net after signing.
- **Single-owner — period vs the conditions you insert.** This doc owns the cooling-off right. The **conditions** a buyer inserts in a private-treaty offer (subject to finance, building/pest, strata) are owned by `kb.special-conditions.standard-set`; the **auction rules** themselves (registration, bidding, vendor bids) are owned by `kb.auction.rules-by-state`. Cross-ref, not duplicated.
- **Business-day arithmetic is resolver code.** The KB supplies the count and start trigger; computing the actual end date (skipping weekends and public holidays per jurisdiction) is resolver logic, not a KB number.

## Sources

**Canonical (state authorities):**

- *Conveyancing Act 1919* (NSW), **ss 66S–66W** (s66S period: 5 business days, 10 for off-the-plan; s66T no-cooling-off cases incl. public auction; s66U rescission notice; s66V(2) 0.25% forfeiture; s66W certificate by a solicitor or barrister independent of the vendor). Authorised version, current for 15 Aug 2025 — `docs/sources/nsw/conveyancing_act_1919_no_6.pdf`
- NSW Fair Trading — *Making an offer on a property* (consumer-facing summary) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/making-an-offer-on-a-property
- *Sale of Land Act 1962* (Vic), **s31** (terminate within 3 clear business days of signing, s31(2); retain $100 or 0.2% whichever greater, s31(4); exclusions s31(5) incl. publicly advertised auction and the before/on/after-auction windows). Authorised Version No. 172, incorporating amendments as at 25 November 2025 — `docs/sources/vic/sales_of_land_act_1962.pdf`
- Consumer Affairs Victoria — *Buying property by private sale* (consumer-facing summary) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property/buying-property-by-private-sale
- Queensland Government — *Cooling-off period for residential property contracts* (5 business days from receipt of the signed contract; up to 0.25% penalty; written notice; none at auction) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/making-an-offer-on-a-home/cooling-off-period
- *Property Occupations Act 2014* (Qld), **ss 166–168** — the statute establishing the QLD residential cooling-off period (s166 5 business days; s167 waive/shorten; s168 0.25% termination penalty). Verified against the authorised PDF, current as at 1 Aug 2025 — https://www.legislation.qld.gov.au/view/pdf/inforce/current/act-2014-022
