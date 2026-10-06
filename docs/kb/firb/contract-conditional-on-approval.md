---
slug: kb.firb.contract-conditional-on-approval
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/getting-started/where-to-submit
    retrieved: 2026-07-06
---

# Buying strategy — the contract conditional on FIRB approval

This doc owns the **strategy decision**: *when and why* a foreign buyer signs a contract **conditional on receiving foreign-investment approval**, rather than waiting for approval before signing. It grounds the `buying_strategy` component (7) for a foreign person. It owns the *decision*, not the clause text — the **anatomy of the condition** is owned by [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md), and the **pre-signing verification checklist** by [`kb.firb.contract-clauses-required`](contract-clauses-required.md). The underlying regulatory rule (must not settle before approval) is owned by [`kb.firb.application-process`](application-process.md).

## The dilemma it resolves

A foreign person faces two pressures that pull against each other:

- **The must-not-act rule.** Under FATA, a foreign person **must not take the notifiable action (settle) until approval is received** ([`kb.firb.application-process`](application-process.md)). Settling first is a breach with real penalties ([`kb.firb.penalties-non-compliance`](penalties-non-compliance.md)).
- **The competition risk.** Approval takes up to 30 days from full fee payment ([`kb.firb.timelines-standard`](timelines-standard.md)); a desirable property may be sold to someone else in that window.

The **conditional contract** is the standard way to hold both: the buyer **secures the property by signing now**, but the contract **cannot complete until approval issues** — so the must-not-act rule is not breached.

## The two timing-safe routes (and when each fits)

This doc owns route choice; [`kb.firb.application-process`](application-process.md) records that both exist.

1. **Approve-then-sign.** Apply, obtain the No Objection Notification, *then* sign an unconditional contract. **Fits** when there is no competition for the property (e.g. an off-the-plan release with stock available, or a developer-exemption-certificate dwelling where no individual approval is even needed — [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md)). Cleanest, lowest contract risk.
2. **Sign-conditional-then-apply.** Sign a contract **conditional on FIRB approval**, then lodge the application. **Fits** when the buyer fears losing the property to another bidder. It is the route most foreign owner-occupier/funded purchases take in a competitive market.

## What the strategy must account for

- **The condition must actually be in the contract** before signing — verified pre-signature ([`kb.firb.contract-clauses-required`](contract-clauses-required.md)); its mechanics (approval-by date, termination right, deposit treatment) are owned by [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md).
- **Apply immediately on signing**, because the 30-day decision clock only starts on full fee payment ([`kb.firb.timelines-standard`](timelines-standard.md)) — a conditional contract does not pause the competition for time; it just protects against breach.
- **Auction is the trap.** Bidding at auction generally produces an **unconditional** contract on the fall of the hammer — there is no opportunity to make it conditional. A foreign person should generally **obtain approval (or a developer-certificate dwelling / exemption certificate) before bidding at auction**, or buy by private treaty where a condition can be negotiated.
- **This is a legal decision.** The buyer's conveyancer or solicitor drafts and reviews the condition; this doc frames the *choice*, not the drafting.

## Rules

Pure-reference (`fills: []`). The `buying_strategy` resolver/agent selects the route from the buyer's situation (competition, auction-vs-private-treaty, developer certificate present) and the FIRB state; this doc supplies the grounded decision rule. No leaf asserted; no figure here (timing/penalties live in their owners).

```jsonc
{
  "fills": [],
  "parameters": {
    "conditional_contract_resolves_must_not_act_vs_competition": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a contract conditional on FIRB approval secures the property without breaching the must-not-settle-before-approval rule (FATA); owner of the rule is kb.firb.application-process." },
    "route_approve_then_sign_fits_no_competition": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "approve-then-sign is cleanest where there is no competition (e.g. exemption-certificate dwelling, available off-the-plan stock)." },
    "route_conditional_then_apply_fits_competition": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "sign-conditional-then-apply protects a buyer who fears losing the property to another bidder in the ~30-day decision window." },
    "auction_generally_unconditional": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "an auction sale is generally unconditional on the fall of the hammer — no opportunity for a FIRB condition; obtain approval (or buy a certificate-covered dwelling) before bidding, or buy by private treaty." },
    "drafting_is_a_legal_decision": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the condition is drafted/reviewed by the buyer's conveyancer or solicitor; this doc frames the strategy choice, not the drafting." }
  }
}
```

Notes:

- **Single-owner.** The regulatory must-not-act rule → [`kb.firb.application-process`](application-process.md); the clause anatomy → [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md); the pre-signing checklist → [`kb.firb.contract-clauses-required`](contract-clauses-required.md); decision timing → [`kb.firb.timelines-standard`](timelines-standard.md). This doc owns only the **route decision**.
- **Decision-support, not legal advice.** The strategy is framed for the buyer's understanding; the contract itself is a matter for the buyer's conveyancer/solicitor. No clause is drafted here.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025), footnote 3 — a foreign person who fears losing a property before approval can enter a contract conditional on receiving foreign-investment approval — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
- ATO — *Residential property application for foreign investors* (apply before acquiring; approval needed before the action completes) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
