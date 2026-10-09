---
slug: kb.vn-pdp.cross-border-data-transfer
effective_from: 2026-07-03
last_verified: 2026-07-06
sources:
  - url: https://www.dlapiper.com/en-us/insights/publications/crossroads-icr-insights/2023/vietnam-decree-13-and-the-new-regulations-on-personal-data-protection
    retrieved: 2026-07-06
    note: "SECONDARY (DLA Piper) — verifies the BOUNDARY facts only: Decree 13/2023/ND-CP took effect 1 July 2023; cross-border transfer of Vietnamese personal data requires a Transfer Impact Assessment dossier submitted to the Ministry of Public Security (A05) and is subject to notification/inspection. The platform-specific application (whether the platform's VN-funder data handling triggers the Decree, and the resulting obligation) REMAINS a labelled placeholder — deferred to the Wedge-2 data-residency review + VN counsel; this citation does not de-placeholder that."
  - url: https://eurochamvn.org/wp-content/uploads/2023/02/Decree-13-2023-PDPD_EN_clean.pdf
    retrieved: 2026-07-06
    note: "PRIMARY (official English translation of Decree 13/2023/ND-CP) — re-verify anchor for the Decree's cross-border-transfer + impact-assessment mechanism."
---

# ⚠ PLACEHOLDER — Vietnamese PDP (Decree 13/2023) cross-border data transfer (NOT SOURCE-GROUNDED)

**This doc's operational content is a labelled placeholder**, and it differs from its two `vn-capital-controls.*` siblings in one respect: the open question here is not only a *buyer-facing* fact but the **platform's own compliance posture** — a decision this project has already, explicitly, deferred. It grounds `cross_border_funding` (component 7)'s awareness of Vietnamese Personal Data Protection (PDP) law where a Vietnam-located party (the VN-side funder/parent) participates in the plan.

## What can be stated now (the standing project decision, not new research)

This is not a new finding — it restates the working agreement already recorded in the project's own governing constraints (CLAUDE.md, "Hard regulatory constraints" + "Don't"):

- **Vietnam's Decree 13/2023 (the PDP Decree)** applies to the personal data of Vietnam-located individuals — which includes a VN-side funder/parent who participates in a Mode-B plan (uploads identity documents, source-of-funds evidence, or otherwise has personal data processed by the platform).
- **Cross-border transfer of that data requires a Data Protection Impact Assessment + government notification** under the Decree — a real, named compliance mechanism, not a generic "be careful with data" caveat.
- **The project's own standing constraint is: do not store Vietnam-located user data outside Vietnam without a Decree 13 compliance review, and data residency for VN-located users is explicitly planned for Wedge 2**, not built in Wedge 1a. This doc does not change that scope — it surfaces the same deferral to the Mode-B KB layer rather than inventing a new one.

## What is PENDING (the placeholder — and why it stays a placeholder, not an assertion)

- **Whether/how the current engine's handling of a VN-side funder's documents (identity, source-of-funds evidence, uploaded under `family_context`/`cross_border_funding`) constitutes a "cross-border transfer" under the Decree**, and if so, what the Impact Assessment / notification obligation looks like for the platform specifically. This is a legal-compliance determination, not something a KB doc can assert.
- **The data-residency architecture** for VN-located user data (where it is collected, processed, and stored) — named as a Wedge-2 item in CLAUDE.md, not yet decided.
- Asserting "here is how the platform handles your data" before that review would **bury an unmade compliance decision** behind KB content ([[honest-deferral-not-rug]]) — this doc deliberately does not do that.

## Named re-ground obligation

- The **Wedge-2 VN-side data-residency compliance review** already named in CLAUDE.md (identity-layer unification trigger) — this doc's operational content activates when that review lands.
- **VN legal/data-privacy counsel** — the same Mode-B counsel-gated blocker (strategy §9) as the capital-controls siblings, extended to data protection.

## Buyer / funder pointer (what the plan says today)

The plan discloses to a Vietnam-located participant (funder/parent) — in plain, bilingual language, not legalese — that: their personal data (identity, financial documents) may be collected and processed as part of the family's plan, some of that processing may occur outside Vietnam, and Vietnamese law (Decree 13/2023) may give them rights over that data; the platform's specific cross-border data-handling practices are under active compliance review (Wedge 2) rather than finalised. It does not claim a specific data-residency guarantee it has not yet built.

## Rules

Pure-reference (`fills: []`), and — like `kb.fx.loan-currency-considerations` — largely **figure-free**: this doc's job is to state the boundary (a real Decree exists, a real obligation may attach, the platform's own answer is not yet built) rather than assert operational content that doesn't exist yet.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — this doc's operational content (whether/how the engine's VN-funder data handling triggers Decree 13, and the resulting Impact Assessment scope) is not sourced; structure built, decision pending." },
    "decree_13_applies_to_vn_located_participants": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "Vietnam's Decree 13/2023 (PDP) applies to the personal data of Vietnam-located individuals, including a VN-side funder/parent participating in a Mode-B plan — restates CLAUDE.md's standing hard-regulatory-constraint, not new research." },
    "cross_border_transfer_requires_impact_assessment_and_notification": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "Decree 13 requires a Data Protection Impact Assessment + government notification for cross-border transfer of covered personal data — the named mechanism, restated from the project's standing constraint." },
    "vn_data_residency_is_a_wedge_2_item_not_built_now": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the platform's own compliance posture (data residency architecture, whether current handling triggers the Decree) is explicitly out of Wedge 1a scope per CLAUDE.md's Don't-list; this doc surfaces that deferral into the Mode-B KB layer rather than deciding it here." },
    "no_data_residency_guarantee_asserted_to_buyer": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the buyer-facing disclosure states that data-handling practices are under active compliance review, and never asserts a specific residency/handling guarantee the platform has not yet built — avoids burying an unmade compliance decision behind KB content." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder + boundary doc.** The REGULATED-tier facts here (the Decree exists; it can require an Impact Assessment + notification) are restatements of CLAUDE.md's own already-verified working agreement, not new primary-sourced research this session — flagged REGULATED because the *existence* of the mechanism is not in doubt, while the *application to this platform's specific data flows* is the pending piece.
- **This is the one VN-side placeholder that is also a platform-architecture deferral, not only a buyer-facing information gap.** Its re-ground trigger is explicitly the Wedge-2 data-residency review already named in CLAUDE.md — don't build ahead of that review by inventing a data-handling answer here.
- **Consumer:** `family_context` / `cross_border_funding` (component 7) — grounds the agent's data-handling disclosure to a VN-located participant; no specific outcome field consumes a value (a boundary/awareness doc, like `kb.fx.loan-currency-considerations`).

## Sources

None yet — placeholder for the platform-specific application. The Decree's existence and the Impact-Assessment/notification mechanism are restated from this project's own governing document (CLAUDE.md, "Hard regulatory constraints" — VN PDP), itself pending primary-source (Decree 13/2023 text) verification and VN legal counsel review at the Wedge-2 trigger.
