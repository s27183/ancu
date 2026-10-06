---
slug: kb.firb.approval-to-settlement-timeline
effective_from: 2021-01-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/sites/firb.gov.au/files/guidance-notes/GN_38-No_objection_notif.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn38-no-objection-notifications.pdf
---

# FIRB — approval-to-settlement validity window

This doc owns the **approval-validity window**: once a foreign-investment approval issues, how long it stays good to settle under. It grounds the `settlement_prep` component (9) and the `firb_workflow` compliance gate's settle-by check. It is the **second of the two FIRB clocks**: [`kb.firb.timelines-standard`](timelines-standard.md) owns *time to get the answer* (~30 days from full fee); this doc owns *time the answer stays valid* (~12 months). The plan reads both; neither restates the other.

## The validity window

A **no objection notification** (the specific-property approval) is **valid for 12 months** from the date of approval, **unless the Treasurer approves a longer period**. The foreign buyer must **complete the acquisition (settle) within that window**. If the purchase is not completed in time, the approval lapses and a **fresh application — and a fresh fee — is generally required** before settling.

The same 12-month window applies to **exemption certificates** (New/Near-New Dwelling and the streamlined variants): a certificate is generally valid for 12 months from the date of approval ([`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md)).

## Why the window is a planning input, not a footnote

For most established-timeline purchases the 12-month window is comfortable. The window becomes load-bearing in one situation the plan must flag:

- **Off-the-plan completion can outrun the window.** A FIRB approval starts its 12-month clock at approval, but an off-the-plan dwelling settles only on completion — which can slip past 12 months. The foreign-person-specific trap (time the FIRB application to the **realistic completion window, not the signed-contract date**) is owned by [`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md); this doc supplies the **window** that trap turns on. For a Mode B off-the-plan purchase the plan treats a long completion as a live risk to approval validity.

## Rules

Pure-reference (`fills: []`). The `settlement_prep` resolver/`firb_workflow` gate reads the approval date + the realistic settlement date and flags when settlement risks falling outside the window; this doc supplies the grounded window. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "no_objection_notification_validity_months": { "type": "int", "value": 12, "provenance": "REGULATED", "note": "a no objection notification is valid for 12 months from approval, unless the Treasurer approves a longer period (GN38)." },
    "treasurer_may_approve_longer_period": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 12-month window is the default; a longer period may be specified in the approval." },
    "must_settle_within_window": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the acquisition must complete within the validity window; if not, the approval lapses." },
    "lapsed_approval_needs_fresh_application_and_fee": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "an expired approval generally requires a fresh application and a fresh fee before settling." },
    "exemption_certificate_validity_months": { "type": "int", "value": 12, "provenance": "REGULATED", "note": "exemption certificates are generally valid for 12 months from approval (kb.firb.exemption-certificates-developer)." },
    "off_the_plan_completion_can_outrun_window": { "type": "bool", "value": true, "provenance": "REGULATED (interaction)", "note": "a slipped off-the-plan completion can land after the 12-month window → time the application to realistic completion; the trap itself is owned by kb.off-the-plan.risk-considerations." }
  }
}
```

Notes:

- **Two clocks, single owners.** *Time to get approval* (≈30 days from full fee) → [`kb.firb.timelines-standard`](timelines-standard.md); *time the approval stays valid to settle* (12 months) is owned here. The `firb_workflow` gate reads both.
- **Single-owner.** The application sequence that produces the approval → [`kb.firb.application-process`](application-process.md); the developer-certificate path and its own 12-month validity → [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md); the off-the-plan-completion trap → [`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md). This doc owns only the **validity window**.
- **Decision-support framing.** Informational; the buyer confirms the actual validity period stated on their own approval with their conveyancer.

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 38: No objection notifications* — a no objection notification is valid for 12 months unless a longer period is specified — https://foreigninvestment.gov.au/sites/firb.gov.au/files/guidance-notes/GN_38-No_objection_notif.pdf
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 4 (12 December 2025) — exemption certificates generally valid for 12 months from the date of approval — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-6-residential-land-v4.pdf
