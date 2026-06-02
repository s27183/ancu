---
slug: kb.auction.rules-by-state
effective_from: 2025-08-01
last_verified: 2026-06-02
---

# Auction conduct rules, by state

An auction is the one transaction mode where the buyer is **immediately and unconditionally bound on the fall of the hammer** — there is no subject-to-finance condition, no subject-to-building/pest condition, and (cross-ref `kb.cooling-off.by-state`) no cooling-off escape. The conduct of the auction itself — **who may bid and how they register, whether and how the vendor may bid, the ban on dummy bidding, and what the auctioneer must declare** — is set by **state statute** and differs across NSW, VIC and QLD. This doc owns those **auction-conduct rules per state**; it grounds the `buying_strategy` parameters `transaction_mode` (when `type == auction`), the `bid_tactics` block (`increment_size_recommended`, `drop_out_signal`), and the agent's framing of `price_envelope` for an auction. It does **not** own the cooling-off right or its auction carve-out (`kb.cooling-off.by-state`), the price-disclosure / no-price-guide-at-auction rule (`kb.comparables.reading-the-room`), the negotiation patterns a market calls for (`kb.negotiation.patterns-by-market-condition`), or behavioural agent manipulation (`kb.agent-tactics.detection`). Provenance is **mixed**: the per-state conduct rules are **REGULATED**; the reserve / passed-in / deposit mechanics are **CONVENTION** (market practice over the top of the statute).

## The auction is unconditional — the load-bearing fact

On the fall of the hammer the highest bidder is **immediately bound to an unconditional contract** and must pay the deposit on the day. Unlike a private-treaty offer, an auction bid **cannot** be made "subject to finance" or "subject to building and pest", and there is **no cooling-off** afterwards (`kb.cooling-off.by-state`). Everything a private-treaty buyer can do *after* signing — arrange finance, inspect, review the contract — an auction buyer must do **before** raising a paddle:

- **Unconditional finance approval**, not just pre-approval — the bid is not conditional on the loan.
- **Building and pest inspection** complete (and, for strata, the strata report — `kb.strata.health-indicators`).
- **Contract / Section 32 reviewed** by the buyer's solicitor before auction day.

This reverses the whole due-diligence sequence for a Mode A buyer who chooses to bid, and it is the reason `buying_strategy` front-loads finance and inspections when `transaction_mode.type == auction`.

## By state

- **NSW (Property and Stock Agents Act 2002 + Property and Stock Agents Regulation 2022).** **Bidder registration is mandatory**: to bid at an auction of residential or rural land you must give the agent your name and address and **show proof of identity**; you are entered in the **Bidders Record** and given a **bidder number**. The Bidders Record is confidential — only NSW Fair Trading may inspect it. The seller is entitled to **one** bid made on their behalf by the auctioneer, which the auctioneer **must announce as a vendor bid**. **Dummy bidding is illegal** — a non-genuine bid to inflate the price exposes the bidder, the seller, the agent and the auctioneer each to penalties of **up to $55,000**.
- **VIC (Sale of Land Act 1962, ss 37–47).** **No mandatory bidder registration.** **Dummy bidding is prohibited**: a vendor must not bid (s 38(1)), and a person must not bid knowing it is on behalf of the vendor (s 38(2)); procuring a dummy bid is a separate offence (s 40), as is falsely acknowledging a bid (s 42). A **vendor bid is permitted only** if (a) the auction conditions permit it, (b) the auctioneer **orally declares before bidding starts** that the conditions permit a vendor bid, and (c) the auctioneer **audibly states "vendor bid"** as each one is made (s 41) — stating only the vendor's name is **not** sufficient (s 41(3)). The auctioneer must not accept a known vendor/dummy bid or acknowledge a bid that was not made (s 39). A copy of the **conditions of the auction must be available for inspection** at the auction location before it starts (s 43; the *Sale of Land (Public Auctions) Regulations 2024* prescribe the rules and the not-less-than-30-minutes-before display).
- **QLD (Property Occupations Act 2014 + Property Occupations Regulation 2014).** **Bidder registration is required** — a *registered bidder* is one registered "as prescribed under a regulation" for the auction (s 159 definition; the Property Occupations Regulation 2014 prescribes the registration). A **vendor (seller) bid is permitted only** if the **conditions of sale notified to prospective bidders include a condition that the sale is subject to the seller's right to bid** (s 229A(2)); if the property is sold in contravention, the **contract is voidable by the buyer before settlement** (s 229A(3)). The auctioneer must **not disclose the reserve or any price guide** for an auction property (s 214; price-disclosure detail → `kb.comparables.reading-the-room`).

## Universal mechanics (market practice over the statute)

- **Reserve price.** The seller sets a confidential **minimum** (the reserve). If bidding does not reach it the property is **"passed in"** — not sold under the hammer; the **highest bidder is usually given the first right to negotiate** with the vendor immediately after. (In QLD a contract entered into within 5pm on the second clear business day after a property is passed in, with a *registered bidder*, also falls **outside** cooling-off — `kb.cooling-off.by-state`.)
- **Deposit on the day.** On the fall of the hammer the buyer signs the contract and pays the **deposit immediately** — commonly **10%**, but the percentage is by agreement and set in the contract. The buyer needs the deposit funds available on auction day.
- **Australian Consumer Law** prohibits misleading or deceptive conduct (including misrepresenting interest in a property) over the top of each state's auction regime — see `kb.agent-tactics.detection`.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The "no escape" rule is the single most important auction fact.** A second-language first-home buyer is most exposed to bidding at auction without unconditional finance or a completed building/pest inspection, then being bound with no cooling-off. The plan makes the unconditional-contract consequence explicit and front-loads every check.
- **Know whether you must register.** NSW and QLD require registration with proof of ID before you can bid; VIC does not. The plan tells the buyer what to bring on the day.
- **A vendor bid is not another buyer.** The plan explains that a lawful, *announced* vendor bid (one in NSW; declared up-front in VIC; condition-of-sale in QLD) is the seller pushing the price toward the reserve — not competition — so the buyer does not over-react to it. An **un-announced** vendor bid or a suspicious phantom bid is illegal dummy bidding → `kb.agent-tactics.detection`.
- **Passed in is an opportunity.** If the property passes in and the buyer is the highest bidder, they hold the first right to negotiate — often the best moment to buy below a hot-auction price.
- **Information, not advice.** The plan explains the rules and the risk posture; it does not instruct the buyer whether or how much to bid (`reasoning_domain: negotiation`, owned by `kb.comparables.reading-the-room` and `kb.negotiation.patterns-by-market-condition`).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The `buying_strategy` `transaction_mode`, `bid_tactics` and `price_envelope` are produced by agent reasoning over these rules + the comparables + the market read; this doc supplies the **conduct framework** the agent reasons against.

```jsonc
{
  "fills": [],
  "parameters": {
    "auction_purchase_is_unconditional": { "type": "bool", "value": true, "note": "REGULATED + CONVENTION (the load-bearing param) — on the fall of the hammer the highest bidder is immediately bound to an UNCONDITIONAL contract and pays the deposit on the day. An auction bid cannot be made subject to finance or building/pest, and there is no cooling-off (cross-ref kb.cooling-off.by-state.no_cooling_off_at_auction). Therefore unconditional finance approval + building/pest + strata + contract/s32 review must ALL be complete before bidding. Reverses the due-diligence sequence vs private treaty." },
    "bidder_registration_required": { "type": "bool", "value": true, "note": "REGULATED — required in NSW (Property and Stock Agents Act 2002: name + address + proof of ID → Bidders Record → bidder number) and QLD (Property Occupations Act 2014 s159 'registered bidder', registration prescribed by the Property Occupations Regulation 2014). NOT required in VIC. State-varying — see auction_rules_by_state.", "varies_by_state": true },
    "vendor_bidding_is_regulated_not_banned": { "type": "bool", "value": true, "note": "REGULATED — a vendor/seller bid is LAWFUL but tightly constrained, differently per state: NSW one bid, announced as a vendor bid; VIC permitted only if conditions permit + auctioneer orally declares before bidding + audibly states 'vendor bid' each time (Sale of Land Act 1962 s41); QLD permitted only if the notified conditions of sale reserve the seller's right to bid (Property Occupations Act 2014 s229A), else the contract is voidable by the buyer before settlement. A lawful announced vendor bid is the seller lifting price toward reserve, not a competing buyer." },
    "dummy_bidding_is_illegal": { "type": "bool", "value": true, "note": "REGULATED — a non-genuine bid to inflate price is illegal in every state: VIC Sale of Land Act 1962 s38 (vendor must not bid; person must not bid knowing it is for the vendor; 240/600 penalty units) + s40 (procuring) + s42 (false acknowledgement); NSW up to $55,000 each for bidder/seller/agent/auctioneer; QLD enforced via the s229A vendor-bid disclosure regime + ACL. Distinct from a lawful ANNOUNCED vendor bid. Behavioural detection → kb.agent-tactics.detection." },
    "deposit_payable_on_the_day": { "type": "bool", "value": true, "note": "CONVENTION — on the fall of the hammer the buyer signs and pays the deposit immediately, commonly 10% but set by the contract by agreement. The buyer must have the deposit funds available on auction day; this is a cash-timing fact for cash_position, not a regulated figure." },
    "passed_in_gives_highest_bidder_first_right": { "type": "bool", "value": true, "note": "CONVENTION — if bidding does not reach the seller's confidential reserve the property is 'passed in' (not sold); the highest bidder is usually given the first right to negotiate with the vendor immediately after. Often the best moment to buy below a hot-auction price. (QLD: a post-pass-in contract with a registered bidder by 5pm the 2nd clear business day is also outside cooling-off — kb.cooling-off.by-state.)" }
  },
  "lookup": {
    "auction_rules_by_state": {
      "note": "REGULATED — auction-conduct rules per state. cooling-off is cross-ref (owned by kb.cooling-off.by-state); price-guide-at-auction is cross-ref (owned by kb.comparables.reading-the-room).",
      "entries": [
        { "state": "NSW", "statute": "Property and Stock Agents Act 2002 + Property and Stock Agents Regulation 2022", "bidder_registration": "mandatory — name + address + proof of ID; Bidders Record (confidential, NSW Fair Trading only) + bidder number", "vendor_bid": "one permitted, must be announced as a vendor bid", "dummy_bidding": "illegal — up to $55,000 each (bidder/seller/agent/auctioneer)", "verification": "regulator .gov.au pages (NSW Fair Trading Bidder's Guide); section pinpoint pending the Act PDF" },
        { "state": "VIC", "statute": "Sale of Land Act 1962 ss 37–47 (+ Sale of Land (Public Auctions) Regulations 2024)", "bidder_registration": "not required", "vendor_bid": "permitted only if conditions permit + auctioneer orally declares before bidding + audibly states 'vendor bid' each time (s41)", "dummy_bidding": "prohibited — s38 (vendor/known-agent bid; 240/600 penalty units), s40 (procuring), s42 (false acknowledgement); auctioneer offences s39", "verification": "PRIMARY-CONFIRMED — authorised Sale of Land Act 1962 PDF, ss 37–47" },
        { "state": "QLD", "statute": "Property Occupations Act 2014 (+ Property Occupations Regulation 2014)", "bidder_registration": "required — 'registered bidder' (s159), registration prescribed by the Regulation", "vendor_bid": "permitted only if the notified conditions of sale reserve the seller's right to bid (s229A(2)); else contract voidable by buyer before settlement (s229A(3))", "dummy_bidding": "no lawful vendor bid without s229A disclosure; ACL over the top", "no_price_guide": "auctioneer must not disclose reserve or a price guide (s214) — see kb.comparables.reading-the-room", "verification": "PRIMARY-CONFIRMED — authorised Property Occupations Act 2014 PDF (current as at 1 Aug 2025), s229A" }
      ]
    },
    "auction_day_buyer_readiness": {
      "note": "CONVENTION — what an auction buyer must have in place BEFORE bidding, because the contract is unconditional with no cooling-off. Drives buying_strategy sequencing.",
      "entries": [
        { "item": "unconditional finance approval", "why": "the bid is not subject to finance; a low bank valuation after the hammer falls is the buyer's cash-shortfall problem (kb.property.comparables-methodology)" },
        { "item": "building and pest inspection complete", "why": "no subject-to-building/pest condition at auction" },
        { "item": "strata report reviewed (if strata)", "why": "no condition to fall back on — kb.strata.health-indicators" },
        { "item": "contract / Section 32 reviewed by solicitor", "why": "binding on the fall of the hammer; review must precede auction day" },
        { "item": "deposit funds available (≈10%)", "why": "payable immediately on the day, set by the contract" },
        { "item": "registration done (NSW/QLD)", "why": "cannot bid without it; bring photo ID" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The `buying_strategy` `transaction_mode` / `bid_tactics` / `price_envelope` are produced by agent reasoning (`reasoning_domain: negotiation`) over these conduct rules plus the comparables and market read; this doc is the **framework** the agent reasons against. Same pure-reference shape as the other `buying_strategy` anchors.
- **The unconditional-contract param is load-bearing.** It is the doc's reason to exist for Mode A — lifted into an explicit parameter so the plan front-loads finance and inspections rather than treating an auction like a private-treaty offer with an escape hatch.
- **Mixed provenance, tagged per fact.** REGULATED: bidder registration, the vendor-bid regimes, the dummy-bidding bans (each pinned to statute where a primary read exists). CONVENTION: reserve / passed-in / deposit-on-the-day mechanics — market practice over the top of the statute, presented as standard practice not law.
- **Single-owner across the buying cluster.** This doc owns **auction conduct** (registration, vendor bids, dummy-bidding ban, auctioneer declarations, reserve/passed-in mechanics). The **cooling-off right and its auction carve-out** → `kb.cooling-off.by-state` (cross-ref, not duplicated — `no_cooling_off_at_auction` lives there; this doc only *relies* on it for the unconditional-purchase consequence). The **no-price-guide-at-auction** disclosure rule → `kb.comparables.reading-the-room`. The **negotiation patterns** a market calls for → `kb.negotiation.patterns-by-market-condition`. **Behavioural agent tactics** (phantom bidders, deadline pressure) → `kb.agent-tactics.detection`.
- **Verification-status honesty (per state).** **VIC and QLD are primary-confirmed**: VIC ss 37–47 read verbatim from the authorised *Sale of Land Act 1962* PDF; QLD s 229A (and s 214 no-price-guide, s 159 registered-bidder) from the authorised *Property Occupations Act 2014* PDF (current as at 1 Aug 2025). **NSW remains at regulator-page granularity** — the bidder-registration, one-announced-vendor-bid and $55,000 dummy-bidding figures are confirmed against NSW Fair Trading's `.gov.au` Bidder's Guide and agent-obligations pages, but the *Property and Stock Agents Act 2002* sections are **not yet pinpointed** (`legislation.nsw.gov.au` 403s automated fetch). Upgrade once the Act PDF is dropped into `docs/sources/nsw/`. Section numbers are deliberately **not** guessed from recall.

## Sources

**Canonical (regulators):**

- NSW Government — *Bidder's guide* (registration: name + address + proof of ID, Bidders Record, bidder number; one announced vendor bid; dummy bidding illegal up to $55,000) — https://www.nsw.gov.au/housing-and-construction/property-professionals/bidders-guide
- NSW Fair Trading — *Auctions – responsibilities for property agents* (auction laws and conditions) — https://www.fairtrading.nsw.gov.au/housing-and-property/property-professionals/working-as-a-property-agent/auction-laws-and-conditions
- Consumer Affairs Victoria — *Buying property at auction* (vendor bids must be declared and announced; dummy bidding prohibited; no cooling-off at auction) — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property/buying-property-at-auction
- Consumer Affairs Victoria — *Conducting a real estate auction – estate agent obligations* — https://www.consumer.vic.gov.au/licensing-and-registration/estate-agents/running-your-business/professional-conduct/conducting-a-real-estate-auction
- Queensland Government — *Buying property at auction* (bidder registration; no price guide; binding on the fall of the hammer) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/ways-to-buy-your-home/buying-at-auction

**Canonical (legislation):**

- *Sale of Land Act 1962* (Vic), **ss 37–47** (Division 4 — Public auctions: s 38 dummy bidding prohibited; s 39 auctioneer offences; s 40 procuring a dummy bid; s 41 permissible vendor bid — conditions permit + oral declaration before bidding + audible "vendor bid"; s 42 false acknowledgement; s 43 conditions available for inspection before the auction). Authorised Version No. 172, incorporating amendments as at 25 November 2025 — `docs/sources/vic/sales_of_land_act_1962.pdf` (read via `pdftotext`). The Public auctions Division (ss 37–47) was inserted by the *Sale of Land (Amendment) Act 2003* No. 41/2003, with the co-owner vendor-bid exception added by No. 103/2004 — i.e. the auction rules are 2003–2004 law sitting in a 1962-titled Act. The conduct rules and the ≥30-minutes-before display are prescribed in the *Sale of Land (Public Auctions) Regulations 2024*.
- *Property Occupations Act 2014* (Qld), **s 229A** (disclosure of seller's right to bid at auction — vendor bid only if the notified conditions of sale reserve that right; contract voidable by the buyer before settlement if breached), **s 214** (auctioneer not to disclose reserve or a price guide), **s 159** ("registered bidder" defined; registration prescribed by regulation). Authorised version, current as at 1 Aug 2025 — `docs/sources/qld/property_occupations_act_2014.pdf` (read via WebFetch-to-disk + `pdftotext`).
- *Property and Stock Agents Act 2002* (NSW) + *Property and Stock Agents Regulation 2022* (bidder registration / Bidders Record; vendor-bid and dummy-bidding offences) — cited by Act/Regulation name; sections **pending a primary read** (`legislation.nsw.gov.au` 403s WebFetch — needs the authorised PDF in `docs/sources/nsw/`).

**Point-in-time / practice (INDICATIVE):**

- Deposit percentage (commonly 10%), reserve-setting and passed-in negotiation are market practice set by the individual contract / campaign, not regulated figures — treated as CONVENTION and read against the specific auction.
