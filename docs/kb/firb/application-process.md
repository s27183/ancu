---
slug: kb.firb.application-process
effective_from: 2025-04-01
last_verified: 2026-07-06
sources:
  - url: https://foreigninvestment.gov.au/getting-started/where-to-submit
    retrieved: 2026-07-06
---

# Applying for FIRB approval — the process

This doc owns the **process** a foreign person follows to obtain foreign-investment approval to buy residential land: where to apply, when to apply relative to the contract, the fee step, and the decision. It grounds the `firb_workflow` resolver's state machine (component 4); the resolver, not the agent, drives the sequence. It does **not** own the **dollar fee** ([`kb.firb.fee-schedule-current`](fee-schedule-current.md)), the **document checklist** ([`kb.firb.documents-required`](documents-required.md)), the **timing** ([`kb.firb.timelines-standard`](timelines-standard.md)), or the **conditions on an approval** (`kb.firb.approval-conditions-typical`, Cluster R3) — each is its own owner; this doc is the spine that references them.

## The core rule — approval *before* the action

Under the *Foreign Acquisitions and Takeovers Act 1975*, a foreign person **must notify the Treasurer and must not take the notifiable action (settle the acquisition) until they have received foreign investment approval.** Acquiring an interest in residential land is a notifiable action. Approval is a **No Objection Notification** (NON), generally issued with conditions.

There are **two timing-safe ways** to buy without breaching this:

1. **Apply, get approval, then sign an unconditional contract / settle.** The clean path when there is no competition for the property.
2. **Sign a contract that is *conditional on receiving foreign investment approval*, then apply.** This protects a buyer who fears the property selling first, without breaching the must-not-act rule (the contract cannot complete until approval issues). The mechanics of the conditional clause are owned by [`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md) (Cluster R3); this doc records only that it is the second timing-safe route.

## The steps

1. **Confirm the buyer is a foreign person** ([`kb.firb.status-determination`](status-determination.md)) and the **property type is eligible** ([`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md)). An established dwelling is a hard stop ([`kb.firb.established-dwelling-ban`](established-dwelling-ban.md)).
2. **Lodge the application** through **Online Services for Foreign Investors** on the ATO website (residential-land applications are generally processed by the ATO). Supply the required information ([`kb.firb.documents-required`](documents-required.md)).
3. **Pay the application fee.** The fee is per [`kb.firb.fee-schedule-current`](fee-schedule-current.md). **The 30-day statutory decision clock does not start until the correct fee is paid in full** — an underpaid fee delays everything ([`kb.firb.timelines-standard`](timelines-standard.md)).
4. **Screening against the national interest.** The application is assessed; for residential land this is generally a standard screening unless national-security land is involved.
5. **Decision.** A **No Objection Notification** (usually with conditions — owned by `kb.firb.approval-conditions-typical`) or a refusal. Approval must be in hand **before** the action completes.
6. **Settle within the approval's validity window** and comply with the conditions (e.g. vacancy fee, construction timeframe for vacant land). The approval-to-settlement window is owned by [`kb.firb.approval-to-settlement-timeline`](approval-to-settlement-timeline.md) (Cluster R4).

For a development sold by a developer holding a **new-dwelling exemption certificate**, the buyer may not need an individual application — the certificate covers them ([`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md), Cluster R3). This is the simplest path and is common for large off-the-plan projects.

## Rules

Pure-reference (`fills: []`). The state machine (`notify → fee_paid → screening → decision → settle`) and the `blocking_for_contract` gate are owned by the `firb_workflow` resolver; this doc supplies the grounded sequence and the must-act-only-after-approval rule the resolver encodes. No leaf asserted; no figure here.

```jsonc
{
  "fills": [],
  "parameters": {
    "approval_required_before_action": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a foreign person must not take the notifiable action (settle) until foreign investment approval is received (FATA 1975)." },
    "conditional_contract_is_timing_safe": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a contract conditional on FIRB approval lets a buyer secure a property without breaching the must-not-act rule; mechanics owned by kb.firb.contract-conditional-on-approval." },
    "lodge_via_ato_online_services_foreign_investors": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "residential-land applications are lodged through Online Services for Foreign Investors and generally processed by the ATO." },
    "decision_clock_starts_on_full_fee_payment": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 30-day statutory decision period does not start until the correct fee is paid in full; timing owned by kb.firb.timelines-standard." },
    "approval_is_no_objection_notification": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "approval is a No Objection Notification, generally issued with conditions (owned by kb.firb.approval-conditions-typical)." },
    "exemption_certificate_can_remove_individual_application": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a developer's new-dwelling exemption certificate can cover the buyer; owned by kb.firb.exemption-certificates-developer." }
  }
}
```

Notes:

- **Single-owner spine.** This doc references — never restates — the fee ([`fee-schedule-current`](fee-schedule-current.md)), documents ([`documents-required`](documents-required.md)), timing ([`timelines-standard`](timelines-standard.md)), conditions (`approval-conditions-typical`, R3), conditional contract (`contract-conditional-on-approval`, R3), developer certificate (`exemption-certificates-developer`, R3), and the settle-by window (`approval-to-settlement-timeline`, R4). It owns the **sequence** and the **act-only-after-approval rule**.
- **Hard gate, not a disclaimer.** Eligibility (foreign-person + property type) gates the whole process; an established dwelling stops it (constraint 10). The resolver issues the authoritative verdict; the agent surfaces only a non-authoritative early warning.
- **Decision-support framing.** Process information only; a buyer's specific application is confirmed via the ATO portal / a registered migration or legal professional.

## Sources

- ATO — *Apply to buy residential property as a foreign person* / *Residential property application for foreign investors* (apply via Online Services for Foreign Investors; information required) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 3 (14 March 2025) — must not take a notifiable action until approval received; conditional-contract route (footnote 3); applications generally processed by the ATO — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-6-residential-land-v3.pdf
- Foreign Investment in Australia — *Where to submit / How to submit an investment proposal* (the Application Portal / Online Services for Foreign Investors) — https://foreigninvestment.gov.au/getting-started/where-to-submit
