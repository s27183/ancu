---
slug: kb.investor.property-management-appointment-timeline
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Property management appointment — timeline

If an investor is using a professional property manager, the PM should be appointed *around* settlement so the property can earn from day one. This doc owns the **PM appointment timeline** — when to appoint, why it's settlement-adjacent, and the milestone it creates. The PM **fee/cost** is owned by [`kb.investor.property-management-fees`](property-management-fees.md); the **PM-vs-self-managed decision** by [`kb.investor.property-management-vs-self-managed`](property-management-vs-self-managed.md). This doc owns only the *timing*. It grounds `settlement_prep.investor_specific_milestones.property_management_appointed`. It is a **reference** doc — it asserts no figure. Informational.

## The timeline

- **Appoint before or at settlement (if let from day one).** To avoid a letting void, the PM is appointed in the weeks before settlement so marketing/tenant-search can begin (subject to access) and the property is ready to let — or, if tenanted in situ, so management transfers seamlessly at settlement. Every vacant week is lost income the cash-flow model assumed.
- **Tenant in situ → seamless transfer.** If buying tenanted ([`kb.investor.tenancy-in-situ-considerations`](tenancy-in-situ-considerations.md)), the PM appointment is really a *handover* — the existing manager (or the new PM) takes over the lease, bond, and rent ledger at settlement; the milestone is "management arranged for settlement day".
- **Get the appraisal and the agency agreement aligned.** The PM who gave the binding rental appraisal ([`kb.investor.rental-appraisal-from-pm-agent`](rental-appraisal-from-pm-agent.md)) is often the one appointed; the management agency agreement (fee, letting fee, scope) is signed around appointment — the fee terms owned by the fees doc.
- **Self-managed → no PM milestone.** If the investor self-manages, this milestone is N/A; the operational obligations shift to the investor (the decision and its trade-offs owned by the PM-vs-self-managed doc).

## The settlement-prep milestone

`property_management_appointed` is a *task* milestone timed to settlement — it doesn't gate settlement, but a late appointment risks a letting void and lost rent. The `landlord_insurance_bound` milestone (blueprint) is its natural companion: cover in place from settlement.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Earn from day one.** The plan times the PM appointment to settlement so a vacant property is ready to let immediately — no avoidable letting void.
- **Seamless handover if tenanted.** For an in-situ tenant, the plan treats the appointment as a management handover at settlement (lease, bond, ledger).
- **The appraising PM is often the appointed PM.** The plan aligns the rental appraisal, the agency agreement, and the fee terms.
- **Self-managed skips it.** If self-managing, the milestone is N/A and obligations shift to the investor. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the PM-appointed milestone is a settlement-prep task. This doc owns the timing; fee and the PM-vs-self decision are cross-ref'd.

```jsonc
{
  "fills": [],
  "parameters": {
    "appoint_before_or_at_settlement": { "type": "bool", "value": true, "note": "appoint in the weeks before settlement so a vacant property is ready to let from day one — every vacant week is income the cash-flow model assumed" },
    "tenant_in_situ_is_a_handover": { "type": "bool", "value": true, "note": "if buying tenanted (kb.investor.tenancy-in-situ-considerations), the appointment is a management handover at settlement — lease, bond, ledger" },
    "align_appraisal_and_agency_agreement": { "type": "bool", "value": true, "note": "the PM who gave the binding appraisal (kb.investor.rental-appraisal-from-pm-agent) is often appointed; the agency agreement (fee/letting fee/scope) is signed around appointment" },
    "self_managed_skips_milestone": { "type": "bool", "value": true, "note": "if self-managing, property_management_appointed is N/A; obligations shift to the investor (decision owned by kb.investor.property-management-vs-self-managed)" },
    "fee_owner": { "type": "string", "value": "kb.investor.property-management-fees", "note": "OWNED ELSEWHERE — the management fee, letting fee, and sundry costs" },
    "milestone_is_a_task_not_a_gate": { "type": "bool", "value": true, "note": "property_management_appointed is a task milestone (doesn't gate settlement) — a late appointment risks a letting void; landlord_insurance_bound is its companion" }
  }
}
```

Notes:

- **No `fills`.** The PM-appointed milestone is a settlement-prep task; this doc owns the timing.
- **Single-owner via cross-ref.** Fee/cost → `kb.investor.property-management-fees`; PM-vs-self decision → `kb.investor.property-management-vs-self-managed`; binding appraisal → `kb.investor.rental-appraisal-from-pm-agent`; in-situ handover → `kb.investor.tenancy-in-situ-considerations`. This doc owns the appointment timeline.
- **Task, not a gate.** Doesn't block settlement, but a late appointment costs rent.

## Sources

- NSW Fair Trading — *Property managers and agents* (appointing a managing agent; the agency agreement) — https://www.nsw.gov.au/housing-and-construction/property-professionals
- ASIC Moneysmart — *Investing in property* (property management as an ongoing cost and decision) — https://moneysmart.gov.au/property-investment/investing-in-property
