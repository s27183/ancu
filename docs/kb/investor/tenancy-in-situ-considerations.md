---
slug: kb.investor.tenancy-in-situ-considerations
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Tenancy-in-situ considerations

Buying an investment property that already has a tenant ("tenanted" or "with a tenant in situ") is different from buying vacant: the lease, the rent, the bond, and the tenant's rights come with the property. This doc owns the **implications** of buying tenanted — what binds the new owner, what to review, and how it constrains the plan. The investor-specific **lease-review cost** is owned by [`kb.buyer-costs.investor-additional-costs`](../buyer-costs/investor-additional-costs.md); this doc owns the *considerations*, not the cost. It grounds `due_diligence.investor_specific_documents.current_tenancy_lease_if_tenanted` and the `current_tenancy_unfavourable_terms` flag. It is a **reference** doc — it asserts no figure. State-specific notice periods/grounds are `to_verify`. Informational; not legal advice.

## What binds the new owner

- **A fixed-term lease transfers with the property.** When a tenanted property sells, the **existing fixed-term lease binds the new owner** — the tenant has the right to stay, on the existing terms (rent, end date, special conditions), until the fixed term expires. The buyer steps into the landlord's shoes; they cannot unilaterally raise the rent, change terms, or evict mid-fixed-term beyond what the lease and the state's tenancy law allow.
- **Rent is locked to the lease.** The rent is whatever the current lease sets, until its review/renewal date — relevant if the appraised market rent ([`kb.investor.rental-appraisal-from-pm-agent`](rental-appraisal-from-pm-agent.md)) is higher; the uplift can't be captured until the lease allows.
- **The bond transfers.** The tenant's bond (held by the state bond authority) is transferred to the new owner / managing agent; confirm the lodged amount and the transfer at settlement.
- **Vacant possession vs subject-to-tenancy.** The **contract** specifies whether the property is sold with **vacant possession** or **subject to the existing tenancy** — a load-bearing contract term the conveyancer must confirm matches the buyer's intent.

## What to review

- **The lease itself** — term, end date, rent, review clauses, special conditions, any options to renew.
- **The rent ledger / arrears history** — is the tenant paying on time? Arrears or a poor ledger is a `current_tenancy_unfavourable_terms` flag.
- **Below-market rent on a long fixed term** — locks in under-market income until expiry; a real thesis constraint, not just a detail.
- **Notice periods and grounds to end a tenancy** vary by state and have been **subject to recent reform** (e.g. ending no-grounds terminations) — confirm per state; treated as `to_verify` rather than asserted.

## How it constrains the plan

- **Wanting to move in or renovate?** A tenant on a long fixed lease blocks a `convert_to_ppor` exit ([`kb.investor.exit-strategy-options`](exit-strategy-options.md)) or a `value_add` renovation until the lease ends or the tenant agrees.
- **Wanting market rent now?** Below-market in-situ rent defers the yield the thesis assumes until the lease review.
- **Upside:** a good tenant in situ means **immediate income from settlement** (no letting void, no initial letting fee) — a genuine plus for cash flow.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The lease comes with the keys.** The plan flags that an existing fixed-term lease binds the new owner — the rent, terms, and tenant rights transfer, and can't be changed mid-term.
- **Check vacant possession vs tenanted in the contract.** The plan makes the conveyancer confirm the settlement basis matches the investor's intent (move in, renovate, or hold tenanted).
- **In-situ income is a plus; below-market rent is a constraint.** The plan weighs immediate-income-from-settlement against rent locked below market until review.
- **State rules vary; confirm per state.** Notice periods and grounds are flagged `to_verify`, not asserted. Information, not legal advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the lease is a DD document, `current_tenancy_unfavourable_terms` is agent-reasoned (`reasoning_domain: lease_interpretation`). This doc supplies the considerations; the lease-review cost is owned elsewhere.

```jsonc
{
  "fills": [],
  "parameters": {
    "fixed_term_lease_binds_new_owner": { "type": "bool", "value": true, "note": "REGULATED principle — an existing fixed-term lease transfers to the buyer; the tenant stays on existing terms until expiry; the buyer cannot unilaterally raise rent / change terms / evict mid-fixed-term beyond the lease + state law" },
    "rent_locked_to_lease_until_review": { "type": "bool", "value": true, "note": "rent is the lease rate until its review/renewal; market uplift (kb.investor.rental-appraisal-from-pm-agent) can't be captured until the lease allows" },
    "bond_transfers_to_new_owner": { "type": "bool", "value": true, "note": "the tenant's lodged bond transfers to the new owner / managing agent; confirm amount + transfer at settlement" },
    "vacant_possession_vs_subject_to_tenancy": { "type": "bool", "value": true, "note": "the CONTRACT specifies vacant possession vs subject-to-existing-tenancy — a load-bearing term the conveyancer confirms matches intent" },
    "lease_review_cost_owner": { "type": "string", "value": "kb.buyer-costs.investor-additional-costs", "note": "OWNED ELSEWHERE — the investor-specific conveyancing lease-review add-on cost; this doc owns the considerations, not the cost" },
    "in_situ_tenant_constrains_convert_or_reno": { "type": "bool", "value": true, "note": "a long fixed lease blocks a convert_to_ppor exit or a value_add reno until expiry/agreement (kb.investor.exit-strategy-options)" },
    "in_situ_income_from_settlement": { "type": "bool", "value": true, "note": "a good in-situ tenant means immediate income from settlement — no letting void / initial letting fee; a cash-flow plus" }
  },
  "lookup": {
    "tenancy_in_situ_to_verify": {
      "note": "state-specific items NOT asserted — confirm per state (recent reform; e.g. ending no-grounds terminations)",
      "entries": [
        { "item": "notice periods to end a tenancy", "status": "to_verify — varies by state, recently reformed" },
        { "item": "grounds required to end a tenancy", "status": "to_verify — varies by state (no-grounds terminations being phased out in several states)" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The lease is a DD document; `current_tenancy_unfavourable_terms` is agent-reasoned. This doc supplies the considerations.
- **Single-owner via cross-ref.** Lease-review cost → `kb.buyer-costs.investor-additional-costs`; market rent → `kb.investor.rental-appraisal-from-pm-agent`; exit constraint → `kb.investor.exit-strategy-options`. This doc owns the tenancy-in-situ implications.
- **State rules `to_verify`.** Notice periods and grounds vary by state and are under reform — flagged, not asserted (the same honest-partial move as the per-state regulated schedules). The binding principle (a fixed lease transfers to the buyer) is national and stable.
- **Not legal advice.** A conveyancer reviews the lease and confirms the contract's possession basis.

## Sources

- NSW Fair Trading — *Buying or selling a tenanted property* (the lease continues with the new owner; bond transfer) — https://www.nsw.gov.au/housing-and-construction/renting/during-tenancy/selling-a-tenanted-property
- Consumer Affairs Victoria — *Buying or selling a rental property* (the existing rental agreement continues; vacant possession vs sold with tenant) — https://www.consumer.vic.gov.au/housing/renting
- Residential Tenancies Authority (QLD) — *Selling or buying a tenanted property* (lease continues; bond transfer) — https://www.rta.qld.gov.au
