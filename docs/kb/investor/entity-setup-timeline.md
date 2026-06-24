---
slug: kb.investor.entity-setup-timeline
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Entity setup — timeline and sequencing

If an investor is buying through a structure — a trust, company, or SMSF rather than personal name — the entity must exist *before* it can contract to buy. This doc owns the **timeline and sequencing** of entity setup against the purchase: when it must be done, why it can't be retrofitted, and the milestone it creates in settlement prep. The **cost** of setup is owned by [`kb.tax.entity-setup-costs`](../tax/entity-setup-costs.md); **which entity** to use (and its tax/asset-protection trade-offs) by [`kb.tax.entity-comparison-personal-trust-company-smsf`](../tax/entity-comparison-personal-trust-company-smsf.md). This doc owns only the *timing*. It grounds `settlement_prep.investor_specific_milestones.entity_setup_completed_if_applicable`. It is a **reference** doc — it asserts no figure. Informational; not legal or tax advice — structuring needs a professional.

## The sequencing rule

- **The buyer on the contract must be the final owner.** The entity that will own the property must be the named purchaser on the contract of sale. Setting up the structure *after* signing, or buying personally then transferring in, generally triggers **a second round of stamp duty and a CGT event** on the transfer — an expensive mistake. The entity must be established and able to contract before the offer.
- **Decide the structure before house-hunting in earnest.** Because the decision binds the contract, the entity question is settled at the *strategy* stage, not at settlement. By the time a property is found, the structure should already be chosen (entity-comparison doc) and ideally established.
- **Establishment takes lead time.** A discretionary trust can be established quickly; a company trustee, an SMSF, or a bare trust for an SMSF purchase takes longer (ABN/TFN registration, bank accounts, deeds, possibly an SMSF audit/compliance setup). SMSF property purchases in particular have strict sequencing and a limited-recourse borrowing arrangement (LRBA) that must be in place first.
- **Lender alignment.** The loan must be approved *in the entity's name* — entity lending has different serviceability and documentation ([`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)); finance pre-approval and the entity must line up before the offer.

## The settlement-prep milestone

`entity_setup_completed_if_applicable` is a *gating* milestone: if the structure is in scope, its completion is a precondition for signing the contract, not a settlement task. The plan surfaces it early so it isn't discovered as a blocker at offer time.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Decide and build the structure first.** The plan settles the entity question at the strategy stage and flags that the entity must exist before the contract — avoiding a costly buy-then-transfer.
- **SMSF and company structures need lead time.** The plan allows for the longer setup of an SMSF (LRBA) or company-trustee structure so it doesn't block an offer.
- **The loan must match the entity.** The plan aligns finance pre-approval with the buying entity.
- **Structuring needs a professional.** The plan flags entity setup as requiring a tax/legal adviser; it does not advise a structure. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the entity milestone is a settlement-prep gate. This doc owns the timing; cost and entity-choice are cross-ref'd.

```jsonc
{
  "fills": [],
  "parameters": {
    "entity_must_exist_before_contract": { "type": "bool", "value": true, "note": "the owning entity must be the named purchaser on the contract; buying personally then transferring in generally triggers a SECOND stamp duty + a CGT event — establish before the offer" },
    "decide_structure_at_strategy_stage": { "type": "bool", "value": true, "note": "the entity decision binds the contract, so it's settled at strategy, not at settlement; by offer time the structure should be chosen and ideally established" },
    "smsf_company_need_lead_time": { "type": "bool", "value": true, "note": "trust = quick; company trustee / SMSF (LRBA) = longer (registrations, deeds, accounts, compliance); SMSF purchases have strict sequencing" },
    "loan_must_be_in_entity_name": { "type": "bool", "value": true, "note": "entity lending differs (kb.lender.serviceability-investment-loans); finance pre-approval and the entity must align before the offer" },
    "setup_cost_owner": { "type": "string", "value": "kb.tax.entity-setup-costs", "note": "OWNED ELSEWHERE — the dollar cost of establishing the structure" },
    "entity_choice_owner": { "type": "string", "value": "kb.tax.entity-comparison-personal-trust-company-smsf", "note": "OWNED ELSEWHERE — which entity + the tax/asset-protection trade-offs" },
    "milestone_is_a_gate_not_a_task": { "type": "bool", "value": true, "note": "entity_setup_completed_if_applicable gates contract-signing; surfaced early so it isn't discovered as a blocker at offer time" }
  }
}
```

Notes:

- **No `fills`.** The entity milestone is a settlement-prep gate; this doc owns the timing.
- **Single-owner via cross-ref.** Setup cost → `kb.tax.entity-setup-costs`; entity choice/trade-offs → `kb.tax.entity-comparison-personal-trust-company-smsf`; entity lending → `kb.lender.serviceability-investment-loans`. This doc owns the sequencing/timeline.
- **Gate, not a task.** Entity setup is a precondition to signing, not a settlement to-do — surfaced early.
- **Not legal/tax advice.** Structuring requires a professional; the plan flags the timing, not the choice.

## Sources

- ATO — *Trusts*, *Companies*, and *SMSFs and property* (the entity must own the asset; SMSF LRBA sequencing) — https://www.ato.gov.au/businesses-and-organisations/super-for-employers/setting-up-super/self-managed-super-funds
- ASIC Moneysmart — *Property investment* and *SMSFs* (buying property in a structure; the upfront sequencing) — https://moneysmart.gov.au/property-investment
