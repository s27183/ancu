---
slug: kb.comparables.reading-the-room
effective_from: 2025-08-01
last_verified: 2026-07-06
sources:
  - url: https://www.consumer.vic.gov.au/underquoting
    retrieved: 2026-07-06
    note: "Consumer Affairs Victoria — Statement of Information: indicative price + 3 comparable sales + suburb median; range no more than 10%; qualifying words ('from', 'offers above', '+') banned"
  - url: https://www.legislation.qld.gov.au/view/pdf/inforce/current/act-2014-022
    retrieved: 2026-07-06
    path: docs/sources/qld/property_occupations_act_2014.pdf
    note: "QLD Property Occupations Act 2014 ss214(2)(c)/216(2)(c) — no price guide for an auction property, with electronic-listings carve-out ss214(4)-(5)/216(4)-(5); read via archived PDF, current as at 1 Aug 2025. NSW (Property and Stock Agents Act 2002) underquoting stays at Act-name granularity — legislation.nsw.gov.au 403s WebFetch."
---

# Reading the room — advertised price vs the real market

The advertised price is **not** the expected sale price. It is a marketing figure, constrained by underquoting law and chosen to attract buyers — and in a hot market the property sells well above it, in a cold one it sits unsold near it. "Reading the room" is the skill of pricing the **gap between what is advertised and what the property will actually fetch**, using the comparable-value estimate (from `kb.property.comparables-methodology`) read against **market signals** and the **regulated price-disclosure** each state mandates. This doc owns that read **in the context of an active offer** — it grounds the `buying_strategy` reasoning over the `comparables` block and the `price_envelope` (`reasoning_domain: negotiation`): turning comparables, the advertised price and the market temperature into a **bid posture** (`max_bid`, `walk_away_price`, `opening_bid_recommended`, `reserve_estimate_range`, `early_offer_vs_wait`). It does **not** own the valuation *method* or the first-pass `asking_price_vs_market` read (both `kb.property.comparables-methodology`, consumed earlier by `property_assessment`), the *conduct* of an auction (`kb.auction.rules-by-state`), the *negotiation patterns* a market condition calls for (`kb.negotiation.patterns-by-market-condition`), or the detection of behavioural agent manipulation (`kb.agent-tactics.detection`). Provenance is **mixed**: the price-disclosure regimes are **REGULATED**; the market-signal reads are **CONVENTION**.

## The advertised price is a regulated marketing figure, not a valuation

What an agent may advertise is constrained by state law, and the constraint differs by state — so the *same* advertised price means different things in NSW, VIC and QLD:

- **VIC — mandatory Statement of Information** (Estate Agents Act 1980; in force since **1 May 2017**). For every residential sale the agent must give a Statement of Information containing an **indicative selling price** (a single price or a range **no wider than 10%**), the **three most comparable recent sales**, and the **suburb median**. The indicative price **cannot be below** the agent's own estimate, the seller's asking price, or a rejected written offer. Qualifying words — "offers above", "from", "+" — are **banned**. This makes VIC the one state where the buyer is *handed* three comparables and a price floor for free.
- **NSW — underquoting prohibited** (Property and Stock Agents Act 2002). The advertised price (or the lower end of a range) **must not be less than the agent's estimated selling price** recorded in the agency agreement, and the agent must revise the estimate as the market moves. "Offers above / over" phrases are **banned**. Breach carries penalties up to **$22,000** and forfeiture of commission. NSW does **not** mandate a VIC-style Statement of Information.
- **QLD — no price guide at auction at all** (Property Occupations Act 2014, **ss 214(2)(c)** auctioneer and **216(2)(c)** real estate agent: for property offered for sale by auction, neither may disclose "a price guide for the offered property", max penalty 540 units). The only carve-out (ss 214(4)–(5), 216(4)–(5)) lets a price/price range go to an **electronic listings provider** purely to set search criteria, provided the listing shows no price and carries the prescribed statement (*"This property is being sold by auction or without a price and therefore a price guide cannot be provided."*). A price guide is permitted only for **private-treaty** (non-auction) sales. So a QLD auction buyer gets **no** advertised price and must value entirely from comparables.

In every state, the **Australian Consumer Law** prohibits false or misleading price representations ("bait advertising") over the top of the state regime.

## Market signals — pricing the gap, then setting the bid

The advertised price read against the comparable estimate and these signals tells the buyer where the realistic number sits — which sets the `price_envelope` (max bid, walk-away, opening bid) and the `early_offer_vs_wait` posture:

- **Days on market (`days_on_market`).** Compared to the suburb norm: **well above** the norm signals weak demand → negotiation room (a lower anchor, room to wait); **well below**, or a pre-auction sale, signals heat → expect competition (bid to a pre-set ceiling, don't expect to negotiate down).
- **Auction clearance rate.** A high suburb/city clearance rate is a **seller's market** — expect bidding to push past any guide; a low rate is a **buyer's market** with room to negotiate post-pass-in.
- **Vendor signals.** Price reductions, a re-listed property, an extended campaign, or a vendor's stated motivation (deceased estate, relocation, divorce) all shift the realistic number below the advertised figure.
- **Method of sale.** Auction campaigns systematically advertise *conservatively* (especially where a guide is given) to build a crowd; private-treaty asking prices tend to sit at or slightly above the vendor's real floor.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Don't read the sticker price at face value.** A second-language first-home buyer is most at risk of anchoring on the advertised number. The plan teaches the state's disclosure regime (VIC hands you comparables; NSW caps how low the ad can go; QLD auctions show nothing) and the gap to expect.
- **Use the VIC Statement of Information as a free starting point** — three comparables and a price floor, supplied by law — then validate against the buyer's own comparable evidence (`kb.property.comparables-methodology`).
- **A QLD auction shows no price — value from comparables, set a ceiling, and bid to it.** With no guide and (cross-ref) no cooling-off at auction, the buyer must walk in with an independent number and a hard limit.
- **High days-on-market is leverage; a fast/hot campaign is not.** The plan reads the suburb's pace and tells the buyer where negotiation room realistically exists.
- **Information, not advice.** The plan explains how to read the advertised price against the market; it does not predict the sale price or instruct the buyer what to bid.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `asking_price_vs_market` is **agent-reasoned** (`reasoning_domain: valuation`); this doc supplies the signal-and-disclosure framework the agent reasons against.

```jsonc
{
  "fills": [],
  "parameters": {
    "advertised_price_is_not_expected_sale_price": { "type": "bool", "value": true, "note": "REGULATED + CONVENTION (the load-bearing param) — the advertised price/guide is a marketing figure constrained by underquoting law, not a valuation; in a hot market the sale lands above it. The buyer reads the advertised price against the comparable estimate (kb.property.comparables-methodology) and the market signals, never at face value." },
    "vic_statement_of_information_mandatory": { "type": "bool", "value": true, "note": "REGULATED (VIC, Estate Agents Act 1980; in force 1 May 2017) — agent must supply a Statement of Information: indicative selling price (single or range ≤10% wide), the 3 most comparable recent sales, and the suburb median; the indicative price cannot be below the agent's estimate / asking price / a rejected written offer; 'offers above/from/+' qualifiers banned." },
    "nsw_underquoting_prohibited": { "type": "bool", "value": true, "note": "REGULATED (NSW, Property and Stock Agents Act 2002) — advertised price must not be less than the agent's estimated selling price in the agency agreement; estimate must be revised with the market; 'offers above/over' banned; penalties up to $22,000 + loss of commission. No mandated Statement of Information." },
    "qld_no_price_guide_at_auction": { "type": "bool", "value": true, "note": "REGULATED (QLD, Property Occupations Act 2014 ss 214(2)(c) / 216(2)(c)) — for a property offered for sale by auction, neither the auctioneer nor the real estate agent may disclose a price guide (max 540 penalty units); only carve-out is a no-price listing to an electronic listings provider carrying the prescribed 'no price guide' statement (ss 214(4)–(5), 216(4)–(5)). A price guide is permitted only for private-treaty sales. A QLD auction buyer must value entirely from comparables. Primary-confirmed against the authorised Act PDF (current as at 1 Aug 2025)." },
    "acl_misleading_price_prohibited": { "type": "bool", "value": true, "note": "REGULATED (Australian Consumer Law, all states) — false or misleading price representations ('bait advertising') are prohibited over the top of each state's disclosure regime." },
    "days_on_market_is_a_demand_signal": { "type": "bool", "value": true, "note": "CONVENTION — days_on_market read against the suburb norm: well above = weak demand / negotiation room; well below or pre-auction = heat / competition. Drives the bid posture (price_envelope, early_offer_vs_wait)." }
  },
  "lookup": {
    "price_disclosure_by_state": {
      "note": "REGULATED — what the law lets an agent advertise, by state. Determines what the advertised price means and what evidence the buyer is handed for free.",
      "entries": [
        { "state": "VIC", "regime": "mandatory Statement of Information", "buyer_gets": "indicative price (range ≤10%) + 3 comparable sales + suburb median; floor at agent estimate/asking/rejected offer", "statute": "Estate Agents Act 1980 (since 1 May 2017)" },
        { "state": "NSW", "regime": "underquoting prohibited", "buyer_gets": "advertised price ≥ agent's estimated selling price; no 'offers above/over'; no mandated SOI", "statute": "Property and Stock Agents Act 2002 (penalty to $22,000)" },
        { "state": "QLD", "regime": "no price guide at auction", "buyer_gets": "nothing for auction stock (prescribed no-guide statement); a price guide only for private-treaty sales", "statute": "Property Occupations Act 2014 ss 214(2)(c) / 216(2)(c)" }
      ]
    },
    "market_temperature_read": {
      "note": "CONVENTION — combining signals into a read on where the sale lands vs the advertised price, feeding the price_envelope / bid posture.",
      "entries": [
        { "temperature": "hot_sellers_market", "signals": "high auction clearance rate, low days_on_market, multiple-offer / pre-auction sales", "expect": "sale above guide; little negotiation room; bid to a pre-set ceiling" },
        { "temperature": "balanced", "signals": "clearance ~midrange, days_on_market near suburb norm", "expect": "sale near a fair comparable value; moderate negotiation room" },
        { "temperature": "cold_buyers_market", "signals": "low clearance rate, high days_on_market, price reductions / re-listings", "expect": "negotiation room below the advertised price; leverage on a passed-in or stale listing" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The `buying_strategy` `price_envelope` (`max_bid`, `walk_away_price`, `opening_bid_recommended`, `reserve_estimate_range`) and `early_offer_vs_wait` are produced by agent reasoning (`reasoning_domain: negotiation`) over the comparables + advertised price + these signals; this doc is the **framework** the agent reasons against. Same pure-reference shape as the other `buying_strategy` anchors.
- **The advertised-price-is-not-the-sale-price param is load-bearing.** It is the doc's reason to exist, lifted into an explicit parameter so the agent reasons over the gap rather than anchoring on the sticker.
- **Mixed provenance, tagged per fact.** REGULATED: the three state price-disclosure regimes + the ACL prohibition (read from regulator pages; statute attribution by Act name — see verification note). CONVENTION: the days-on-market, clearance-rate and market-temperature reads. The agent presents the law as the law and the signal-reads as standard guidance.
- **Verification-status honesty (per state).** **QLD is primary-confirmed**: ss 214(2)(c) / 216(2)(c) and the electronic-listings carve-out (ss 214(4)–(5), 216(4)–(5)) were read verbatim from the authorised *Property Occupations Act 2014* PDF (current as at 1 Aug 2025, self-served to `docs/sources/qld/`). **NSW and VIC remain at Act-name granularity**: both legislation sites block automated fetch (`legislation.nsw.gov.au` 403s; `legislation.vic.gov.au` exposes only a version-history table, not the authorised PDF), so the NSW underquoting offence sections (Property and Stock Agents Act 2002) and the VIC Statement-of-Information provisions (Estate Agents Act 1980 + Estate Agents (Professional Conduct) Regulations 2018) are confirmed against the regulators' `.gov.au` pages but **not yet pinpointed to section** — upgrade once the two Act/Reg PDFs are dropped into `docs/sources/{nsw,vic}/`, per the source-hardening discipline. Section numbers are deliberately **not** guessed from recall.
- **Single-owner across the valuation + buying cluster.** This doc owns the **price-disclosure regime + market-signal read, applied to the bid**. The **valuation method and the first-pass `asking_price_vs_market` read** (consumed earlier by `property_assessment`) → `kb.property.comparables-methodology`; the **negotiation patterns** a market condition calls for → `kb.negotiation.patterns-by-market-condition` (this doc reads *where the price sits*; that doc owns *what to do about it*); **auction conduct** (registration, dummy-bidding ban, vendor bids, no cooling-off) → `kb.auction.rules-by-state`; **behavioural agent tactics** (fake interest, deadline pressure, phantom buyers) → `kb.agent-tactics.detection`; the **cooling-off / auction carve-out** → `kb.cooling-off.by-state`. Cross-ref, not duplicated.

## Sources

**Canonical (regulators — the price-disclosure regimes):**

- Consumer Affairs Victoria — *Understanding property prices and underquoting (for buyers)* (Statement of Information: indicative price, 3 comparable sales, suburb median; range ≤10%; banned qualifying words; in force 1 May 2017) — https://www.consumer.vic.gov.au/underquoting
- Consumer Affairs Victoria — *Property sales method and price* — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/selling-property/property-sales-method-and-price
- NSW Government — *Price estimation and underquoting when selling a property* (advertised price must not be below the agent's estimated selling price; banned phrases; penalties) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/selling-a-property/price-estimation-and-underquoting
- NSW Fair Trading — *Underquoting guidelines for residential property* — https://www.fairtrading.nsw.gov.au/__data/assets/pdf_file/0010/613891/Underquoting_Guidelines.pdf
- Queensland Government — *Buying property at auction* (it is illegal for a seller or agent to give a price guide for an auction property; prescribed no-guide statement) — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home/ways-to-buy-your-home/buying-at-auction
- Queensland Government — *Property advertising* (Property Occupations Act 2014; ACL bait-advertising prohibition) — https://www.qld.gov.au/law/laws-regulated-industries-and-accountability/queensland-laws-and-regulations/regulated-industries-and-licensing/regulated-industries-licensing-and-legislation/property-industry-regulation/best-practice-for-the-property-industry/property-advertising

**Canonical (legislation):**

- *Property Occupations Act 2014* (Qld), **ss 214(2)(c)** (auctioneer not to disclose a price guide for property offered by auction) and **216(2)(c)** (real estate agent, same), with the electronic-listings carve-out at ss 214(4)–(5) / 216(4)–(5) requiring the prescribed no-guide statement. Authorised version, current as at 1 Aug 2025 — `docs/sources/qld/property_occupations_act_2014.pdf` (read via WebFetch-to-disk + `pdftotext`).
- *Estate Agents Act 1980* (Vic) + *Estate Agents (Professional Conduct) Regulations 2018* (the Statement of Information regime) — cited by Act name; sections **pending a primary read** (`legislation.vic.gov.au` exposes only a version-history table — needs the authorised PDF dropped into `docs/sources/vic/`).
- *Property and Stock Agents Act 2002* (NSW) (the underquoting regime) — cited by Act name; sections **pending a primary read** (`legislation.nsw.gov.au` 403s WebFetch — needs the authorised PDF dropped into `docs/sources/nsw/`).

**Point-in-time / practice (INDICATIVE):**

- Auction clearance rates, days-on-market norms and market-temperature reads are market data (CoreLogic / agent reporting), not regulated figures — treated as CONVENTION/INDICATIVE and read against the suburb, never as a sale-price prediction.
