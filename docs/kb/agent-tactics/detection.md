---
slug: kb.agent-tactics.detection
effective_from: 2025-08-01
last_verified: 2026-07-06
sources:
  - url: https://www.consumer.vic.gov.au/underquoting
    retrieved: 2026-07-06
    note: "Consumer Affairs Victoria — underquoting rules (the regulated tactic this detection doc cross-refs; dummy bidding is owned by kb.auction.rules-by-state). The behavioural detection catalogue is consumer-protection/buyer's-agent convention. Moneysmart /property blocks automated fetch this session."
---

# Selling-agent tactics — detection and counters

The single fact that reframes every interaction at a sale: **the listing (selling) agent is engaged by and paid by the vendor.** Their professional duty runs to the seller, so every tactic — how the price is quoted, how urgency is created, how other buyers are described — is in service of a **higher price and a faster sale**. This is not dishonesty; it is whose side the agent is on. This doc owns the **behavioural detection of common selling-agent tactics and the counter for each**; it grounds the `buying_strategy` parameters `agent_tactics_watchlist.common_tactics_to_watch` (`array<{ tactic, counter }>`) and `agent_tactics_watchlist.agent_pressure_signals` (`array<string>`). It does **not** own the underlying *regulated* rules those tactics may breach — **underquoting / price disclosure** is owned by `kb.comparables.reading-the-room` and **dummy bidding / auction conduct** by `kb.auction.rules-by-state`; this doc cross-refs them and supplies the buyer-side **recognition + counter** framing. Provenance is **mixed**: where a tactic is an illegal practice the fact is **REGULATED** (cross-ref the owning doc); the detection cues and counters are **CONVENTION**.

## Whose agent is it

A buyer talking to the agent at an open home is talking to the **vendor's** agent. A separate actor — a **buyer's agent** — works for the buyer for a fee, but most first-home buyers do not engage one. The plan itself is the buyer's **decision support**: it does not negotiate for the buyer, but it equips the buyer to see the selling agent's tactics for what they are. The counter to almost every tactic reduces to the same discipline: **value independently, hold a walk-away number, and never sign without finance approval and due diligence** (`kb.negotiation.patterns-by-market-condition`, `kb.auction.rules-by-state`).

## Common tactics and their counters

- **Underquoting** — advertising a price below the real expectation to draw a crowd. *Counter:* value from comparables and ignore the quote; know your state's price-disclosure regime. **Illegal in NSW and VIC** — owned by `kb.comparables.reading-the-room`.
- **Phantom interest** — "we have another offer", "there's a lot of interest" with nothing in writing. *Counter:* genuine competing offers exist, but an unverifiable claim is not evidence; ask for competing offers in writing and otherwise hold your number.
- **False urgency / moving deadline** — "the vendor wants a decision tonight", a "best offers by" date that keeps shifting. *Counter:* a real deadline is fine; never let it push a signature before finance + building/pest + solicitor review. The cooling-off window and offer conditions exist precisely for this (private treaty; none at auction — `kb.cooling-off.by-state`).
- **Dummy bidding at auction** — un-announced vendor bids or non-genuine bids to inflate the price. *Counter:* know the one-announced-vendor-bid rule for your state; an un-announced or suspicious bid pattern is **illegal** and reportable. Owned by `kb.auction.rules-by-state`.
- **High anchor then "I'll get the vendor down"** — quoting high to make a near-asking outcome feel like a win. *Counter:* anchor on comparable evidence, not the agent's number (`kb.property.comparables-methodology`).
- **Pressure on terms** — pushing to drop conditions, lift the deposit, or shorten settlement to make the offer "stronger". *Counter:* settlement and deposit are negotiable levers; **subject-to-finance and subject-to-building/pest are not** for a Mode A buyer (`kb.negotiation.patterns-by-market-condition`).
- **Scarcity / FOMO framing** — "this suburb never comes up", "prices only go up here". *Counter:* check suburb data and days-on-market (`kb.property.suburb-risk-factors`, `kb.comparables.reading-the-room`); scarcity is a claim, not a valuation.
- **Rushing or withholding documents** — discouraging a building/pest inspection or solicitor review, or producing the contract / Section 32 / strata report late. *Counter:* never sign without the contract reviewed by your solicitor and inspections done (`kb.contract-of-sale.review-points-by-state`, `kb.s32.review-points`, `kb.strata.health-indicators`).

## Pressure signals (the watchlist)

Cues that the buyer is being worked rather than informed — surfaced as `agent_pressure_signals`:

- Reluctance to put a claimed competing offer **in writing**.
- A deadline that **moves** when the buyer doesn't act.
- **Discouraging** a building/pest inspection or solicitor review ("it's a waste of money / there's no time").
- Pushing to **waive cooling-off**, sign on the spot, or remove finance/inspection conditions.
- **Vagueness** about days-on-market, prior campaigns, or why an earlier contract fell through.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Highest-vulnerability buyer.** A second-language first-home buyer, unfamiliar with Australian sale norms and often culturally deferential to a salesperson, is the most exposed to pressure tactics. The plan names each tactic in plain language and pairs it with a concrete counter — turning an asymmetric encounter into an informed one.
- **Community word-of-mouth can be weaponised.** "Everyone in the community is buying here" is a scarcity/FOMO framing; the plan separates genuine Vietnamese-community proximity as a *liveability and demand* strength (`kb.property.suburb-risk-factors`) from its use as a sales-pressure line.
- **The counter is always the same discipline.** Value independently, hold a walk-away number, finance + due diligence before signing. The plan reinforces that no tactic changes those rules.
- **Information, not advice or accusation.** The plan teaches the buyer to recognise tactics and protect themselves; it does **not** accuse a specific agent of illegal conduct or give legal advice on reporting. Where a tactic is illegal (underquoting, dummy bidding) it points to the regulator (`kb.comparables.reading-the-room`, `kb.auction.rules-by-state`).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `agent_tactics_watchlist.common_tactics_to_watch` and `agent_pressure_signals` are populated by agent reasoning over this framework and the live campaign (`reasoning_domain: negotiation`); this doc supplies the tactic→counter catalogue the agent reasons against.

```jsonc
{
  "fills": [],
  "parameters": {
    "the_agent_works_for_the_vendor": { "type": "bool", "value": true, "note": "CONVENTION (the load-bearing param) — the listing/selling agent is engaged by and paid by the vendor; their duty runs to the seller, so every tactic serves a higher price / faster sale. Not dishonesty — whose side they are on. Reframes every open-home and negotiation interaction. A buyer's agent (separate, buyer-paid actor) is the contrast; the plan itself is the buyer's decision support, not a buyer's agent." },
    "unverifiable_claims_are_not_evidence": { "type": "bool", "value": true, "note": "CONVENTION — phantom-interest and false-urgency claims ('another offer', 'decision by tonight') are not evidence unless in writing; the buyer asks for competing offers in writing and otherwise holds the walk-away number (kb.negotiation.patterns-by-market-condition). Genuine competing offers and deadlines do exist — the tactic is the unverifiable version." },
    "never_sign_under_pressure_without_dd": { "type": "bool", "value": true, "note": "CONVENTION + safety — no deadline, scarcity or competing-offer pressure justifies signing without finance approval + building/pest + solicitor review (private treaty), or bidding at auction without unconditional finance + inspections (kb.auction.rules-by-state). The counter to almost every tactic." },
    "regulated_tactics_are_cross_referenced_not_owned": { "type": "bool", "value": true, "note": "REGULATED (by reference) — underquoting (illegal NSW/VIC) is owned by kb.comparables.reading-the-room; dummy bidding (illegal all states) is owned by kb.auction.rules-by-state. This doc supplies the buyer-side detection + counter framing and points to the owning doc/regulator; it does NOT restate the regulated rule. Single-owner discipline." }
  },
  "lookup": {
    "tactic_counter_catalogue": {
      "note": "CONVENTION (+ REGULATED where noted) — common selling-agent tactics and the buyer counter. Populates buying_strategy.agent_tactics_watchlist.common_tactics_to_watch (array<{tactic, counter}>).",
      "entries": [
        { "tactic": "underquoting", "what": "advertised price below the real expectation to draw a crowd", "counter": "value from comparables; ignore the quote; know your state's price-disclosure regime", "regulated": "ILLEGAL NSW/VIC — owned by kb.comparables.reading-the-room" },
        { "tactic": "phantom interest", "what": "'another offer' / 'lots of interest' with nothing in writing", "counter": "ask for competing offers in writing; otherwise hold your number", "regulated": "ACL prohibits misleading conduct" },
        { "tactic": "false urgency / moving deadline", "what": "'decision tonight' or a 'best offers by' date that keeps shifting", "counter": "never sign before finance + building/pest + solicitor review; conditions and cooling-off exist for this (private treaty)", "regulated": "CONVENTION" },
        { "tactic": "dummy bidding", "what": "un-announced vendor or non-genuine bids to inflate the auction price", "counter": "know the one-announced-vendor-bid rule; suspicious bidding is reportable", "regulated": "ILLEGAL all states — owned by kb.auction.rules-by-state" },
        { "tactic": "high anchor then 'get the vendor down'", "what": "quoting high so a near-asking result feels like a win", "counter": "anchor on comparable evidence, not the agent's number (kb.property.comparables-methodology)", "regulated": "CONVENTION" },
        { "tactic": "pressure on terms", "what": "push to drop conditions / lift deposit / shorten settlement", "counter": "settlement + deposit are negotiable; subject-to-finance and building/pest are PROTECTED (kb.negotiation.patterns-by-market-condition)", "regulated": "CONVENTION" },
        { "tactic": "scarcity / FOMO framing", "what": "'this suburb never comes up', 'prices only go up'", "counter": "check suburb data + days-on-market (kb.property.suburb-risk-factors); scarcity is a claim, not a valuation", "regulated": "CONVENTION" },
        { "tactic": "rushing / withholding documents", "what": "discouraging inspection/solicitor review or producing contract/s32/strata report late", "counter": "never sign without solicitor review + inspections (kb.contract-of-sale.review-points-by-state, kb.s32.review-points, kb.strata.health-indicators)", "regulated": "CONVENTION" }
      ]
    },
    "pressure_signals": {
      "note": "CONVENTION — cues the buyer is being worked, not informed. Populates buying_strategy.agent_tactics_watchlist.agent_pressure_signals (array<string>).",
      "entries": [
        { "signal": "won't put a claimed competing offer in writing" },
        { "signal": "a deadline that moves when the buyer doesn't act" },
        { "signal": "discourages a building/pest inspection or solicitor review" },
        { "signal": "pushes to waive cooling-off, sign on the spot, or drop finance/inspection conditions" },
        { "signal": "vague about days-on-market, prior campaigns, or why an earlier contract fell through" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `agent_tactics_watchlist.common_tactics_to_watch` and `agent_pressure_signals` are populated by agent reasoning over this catalogue + the live campaign; this doc is the **framework** the agent reasons against. Same pure-reference shape as the other `buying_strategy` anchors.
- **The whose-side-is-the-agent-on param is load-bearing.** It is the doc's reason to exist — the one fact that reframes every tactic, lifted into an explicit parameter so the plan presents the catalogue from the buyer's side.
- **Mixed provenance, single-owner discipline.** Where a tactic is an illegal practice (underquoting, dummy bidding) the **regulated rule is owned elsewhere** (`kb.comparables.reading-the-room`, `kb.auction.rules-by-state`) and this doc only supplies the detection + counter and points to the regulator — it does **not** restate the law. The detection cues and counters are CONVENTION, presented as standard buyer guidance.
- **Information, not advice or accusation.** The plan equips the buyer to recognise and counter tactics; it does not accuse a named agent of illegal conduct or advise on reporting. The ASIC information-not-advice line holds: general recognition framework, not a legal opinion on a specific interaction.

## Sources

**Practice (CONVENTION / INDICATIVE):**

- The tactic catalogue, counters and pressure signals are standard **consumer-protection and buyer's-agent guidance**, presented as a general recognition framework — not a regulated rule and not a legal opinion on any specific agent.
- Moneysmart (ASIC) — *Buying property* (buyer guidance on offers, auctions and pressure selling) — https://moneysmart.gov.au/property

**Cross-referenced (the regulated tactics — owned elsewhere):**

- Underquoting / price disclosure (illegal NSW/VIC) — `kb.comparables.reading-the-room`.
- Dummy bidding / auction conduct (illegal all states) — `kb.auction.rules-by-state`.
- Australian Consumer Law prohibition on misleading or deceptive conduct sits over the top of all of the above (cross-ref the two owning docs).
