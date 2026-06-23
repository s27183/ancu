---
slug: kb.tax.entity-comparison-personal-trust-company-smsf
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Ownership entity — comparison for property investment

An investment property can be held in several **ownership structures**, each with different tax, loss, asset-protection, cost, and compliance consequences. This doc owns the **comparison** of those structures — personal (sole / joint), discretionary trust, unit trust, company, and SMSF (with or without an LRBA) — matching the `recommended_entity` enum. It is the comparison the **agent reasons over** to suggest a structure for `tax_structure.ownership_entity.recommended_entity` (an **agent-path** leaf, `reasoning_domain: entity_structuring`).

**This is the most regulated content in the wedge — the ASIC discipline is load-bearing and non-negotiable:**

- The plan **surfaces options + considerations** and may suggest a **starting structure with its reasoning**, explicitly **to take to a registered tax agent / accountant**. It **never** tells the user to "set up a trust," never asserts a structure is "best," and never presents the suggestion as advice.
- Choosing an ownership entity is **tax and (often) financial advice** — AFSL / tax-agent territory, with **personal liability** if crossed. The suggested `recommended_entity` is a **conversation-starter to confirm with a licensed professional**, not a directive.
- Regulated figures in the comparison (the CGT discount by entity) are **owned by [`kb.tax.cgt-50-percent-discount`](cgt-50-percent-discount.md)** and referenced here, not re-asserted. Negative-gearing treatment is owned by [`kb.tax.negative-gearing-mechanics`](negative-gearing-mechanics.md); land-tax treatment of trusts/entities by [`kb.tax.land-tax-by-state`](land-tax-by-state.md).

## The options at a glance (current law)

| Structure | CGT discount | Net rental loss | Asset protection | Cost / complexity | Key restriction |
|---|---|---|---|---|---|
| **Personal — sole** | 50% (individual) | deductible vs other income† | weak (held in own name) | lowest | none beyond ordinary rules |
| **Personal — joint** | 50% (each owner's share) | split by ownership share, vs each owner's other income† | weak | low | gains/losses follow legal ownership shares |
| **Discretionary (family) trust** | 50% (flows through to beneficiaries) | **trapped in the trust** — carried forward, **cannot** offset beneficiaries' other income | strong | moderate–high (setup + annual) | many states deny the land-tax threshold or impose a trust surcharge |
| **Unit trust** | 50% (flows through to unit holders) | trapped (same as above) | moderate | moderate–high | fixed entitlements; used for unrelated co-investors / SMSF co-ownership |
| **Company** | **none** (companies cannot use the CGT discount) | trapped; offset only vs company income | strong | moderate | rarely used to hold appreciating residential (loses the discount) |
| **SMSF** | 33⅓% (complying super fund) | stays in the fund; cannot offset personal income | strong (super law) | **high** (strict compliance) | sole-purpose test; **no member/related-party use**; can't acquire residential from a related party; arm's length |
| **SMSF with LRBA** | 33⅓% | stays in the fund | strong | **highest** | borrowing only via a Limited Recourse Borrowing Arrangement (single acquirable asset in a holding trust) |

† Negative-gearing deductibility against other income is **current law** and is subject to the announced 2026-27 Budget reform (limited to new builds from 1 July 2027, proposed, not yet law — see the reform note below).

## Personal ownership (sole / joint)

The simplest and cheapest structure: the property is held in the investor's own name (sole) or shared (joint). The individual 50% CGT discount applies; a net rental loss is deductible against the owner's other income (current law); income and gains follow the legal ownership shares. The trade-off is **weak asset protection** (the property is exposed to the owner's personal liabilities) and that gains stack on top of the owner's marginal income (potentially at the top rate). Joint ownership lets a couple split income and gains by share — relevant where one partner has a lower marginal rate, but the split is fixed by ownership, not chosen year-to-year.

## Discretionary (family) trust

A discretionary trust holds the property and **distributes** income and discounted gains among beneficiaries at the trustee's discretion — useful for **income-splitting** and **asset protection**. Two load-bearing drawbacks: (1) a **net rental loss is trapped in the trust** — it cannot be distributed to offset a beneficiary's other income, so the headline negative-gearing benefit is **lost** while the property is geared (the loss is carried forward against future trust income/gains); and (2) **land tax** — many states deny the tax-free threshold or apply a **surcharge** to trust-held land (the detail is owned by `kb.tax.land-tax-by-state`). Setup and annual administration cost more than personal ownership ([`kb.tax.entity-setup-costs`](entity-setup-costs.md)).

## Unit trust

A unit trust holds the property with **fixed** entitlements (units), rather than discretionary distributions. Used where **unrelated parties co-invest**, or to allow an SMSF to hold units alongside individuals. The 50% discount flows through to unit holders; losses are still trapped in the trust. More rigid than a discretionary trust (no distribution discretion) but clearer for co-ownership.

## Company

A company can hold the property and is taxed at the flat company rate, with **strong asset protection** — but a company **cannot use the CGT discount**, which is the decisive drawback for an appreciating residential asset (the full nominal gain is taxable). Losses are trapped and offset only against company income. For these reasons a company is **rarely** used to hold appreciating residential investment property directly (it is more often the *trustee* of a trust). The comparison surfaces this as a consideration, not a prohibition.

## SMSF (and SMSF with LRBA)

A self-managed super fund can hold investment property inside the concessional super environment (a 33⅓% CGT discount; concessional fund tax), but under **strict** super law:

- **Sole-purpose test** — the fund must be maintained solely to provide retirement benefits; the property is an investment for the fund, not for present use.
- **No member or related-party use** — neither the members nor their relatives may live in or use the residential property; the fund cannot acquire residential property from a related party; all dealings must be at **arm's length**.
- **Borrowing only via an LRBA** — if the fund borrows, it must use a **Limited Recourse Borrowing Arrangement**: the borrowed money buys a **single acquirable asset** held in a separate **holding trust**, and the lender's recourse is limited to that asset (the fund's other assets are protected). This is the `smsf_with_lrba` option.
- **Highest complexity and cost** — administration, audit, and compliance obligations are substantial, and breaches carry serious penalties.

Because SMSF tax and compliance are complex and member-specific, the plan **does not compute** an SMSF tax position — it surfaces the structure and its restrictions and defers the assessment to a licensed SMSF specialist.

## Announced reform — 2026-27 Federal Budget (proposed, not yet law)

The reform that replaces the **50% CGT discount with cost-base indexation + a 30% minimum tax** (individuals, trusts and partnerships) and **limits negative gearing to new builds** from **1 July 2027** (*Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* — introduced, not yet passed) **shifts this comparison** for any purchase after Budget night (7:30pm AEST 12 May 2026):

- The **CGT-discount advantage** of personal/trust ownership over a company narrows — the discount that distinguished them would become indexation for individuals/trusts/partnerships. (Company and SMSF treatment under the reform: confirm with a registered tax agent.)
- The **loss-offset advantage** of personal ownership over a trust narrows for **established** property — the wage offset is removed for established post-Budget purchases, leaving losses to carry forward (closer to the trust's already-trapped treatment).

The comparison above reflects **current law**; the agent flags the reform when it suggests a structure and defers the post-2027 implications to a registered tax agent.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Decision-support, always.** The plan suggests a starting structure *with reasoning* (e.g. "joint ownership for a couple with differing marginal rates," "a family trust where asset protection and distribution matter — weighed against trapped losses and land-tax cost") and routes the decision to a registered tax agent. It never issues a directive.
- **The common diaspora cases.** Personal/joint (simplest, most first investors), a family trust (asset protection + distribution, at the cost of trapped losses and land-tax surcharge), and SMSF (retirement-focused, strict) are the structures most often weighed — surfaced as a comparison, not a ranking.
- **The reform changes the weighting.** The 2027 reform narrows two of the classic distinctions; the plan reflects current law and flags the change rather than reasoning from a structure that may not hold post-2027.
- **Information, not advice** (echoing the blueprint disclaimer): entity selection, negative-gearing implications, depreciation, CGT, and land tax must be verified with a registered tax agent or accountant before commitment.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `tax_structure.ownership_entity.recommended_entity` is an **agent-path** leaf: the agent reasons over the comparison below and suggests a structure *with reasoning, as decision-support to confirm with a licensed adviser* — the KB supplies the comparison facts, never a verdict, and the regulated CGT-discount figures are referenced from their owner, not re-asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "recommended_entity_is_agent_path":  { "type": "bool", "value": true, "note": "tax_structure.recommended_entity is agent_reasoning_required (reasoning_domain: entity_structuring); this doc is the comparison the agent reasons over" },
    "recommended_entity_is_decision_support": { "type": "bool", "value": true, "note": "POLICY (ASIC line) — the agent suggests a starting structure WITH reasoning, to confirm with a registered tax agent; never a directive, never 'best', never 'set up a trust'" },
    "company_cgt_discount_available":    { "type": "bool", "value": false, "note": "REGULATED (ATO) — companies cannot use the CGT discount; the decisive drawback for holding appreciating residential. Rate owned by kb.tax.cgt-50-percent-discount" },
    "trust_losses_trapped":              { "type": "bool", "value": true, "note": "a net rental loss in a discretionary/unit trust is trapped (carried forward against future trust income/gains), not distributable to offset a beneficiary's other income — negates negative gearing while geared" },
    "smsf_sole_purpose_no_member_use":   { "type": "bool", "value": true, "note": "REGULATED (super law) — SMSF property must meet the sole-purpose test; no member/related-party use; no acquisition of residential from a related party; arm's length" },
    "smsf_borrowing_via_lrba_only":      { "type": "bool", "value": true, "note": "REGULATED (ATO) — an SMSF may borrow only via a Limited Recourse Borrowing Arrangement: a single acquirable asset in a holding trust, lender recourse limited to that asset" },
    "entity_selection_defer_to_adviser": { "type": "bool", "value": true, "note": "POLICY — SMSF/company/trust tax positions are not computed by the plan; defer the assessment to a licensed professional" }
  },
  "lookup": {
    "entity_comparison": {
      "note": "the comparison the agent reasons over to suggest recommended_entity; current law; cgt_discount references kb.tax.cgt-50-percent-discount as owner",
      "entries": [
        { "entity": "personal_sole",     "cgt_discount": "50%",  "loss_offset": "vs other income (current law)", "asset_protection": "weak",   "cost": "lowest",  "note": "simplest; gains stack on marginal rate" },
        { "entity": "personal_joint",    "cgt_discount": "50%",  "loss_offset": "split by share vs each owner's income", "asset_protection": "weak", "cost": "low", "note": "fixed split by ownership share" },
        { "entity": "discretionary_trust","cgt_discount": "50% (flows through)", "loss_offset": "trapped (carried forward)", "asset_protection": "strong", "cost": "moderate-high", "note": "distribution flexibility; land-tax surcharge in many states" },
        { "entity": "unit_trust",        "cgt_discount": "50% (flows through)", "loss_offset": "trapped", "asset_protection": "moderate", "cost": "moderate-high", "note": "fixed entitlements; co-investment / SMSF co-ownership" },
        { "entity": "company",           "cgt_discount": "none", "loss_offset": "trapped (vs company income)", "asset_protection": "strong", "cost": "moderate", "note": "loses the discount; rarely holds appreciating residential" },
        { "entity": "smsf",              "cgt_discount": "33⅓%", "loss_offset": "stays in fund", "asset_protection": "strong", "cost": "high", "note": "sole-purpose; no member use; arm's length" },
        { "entity": "smsf_with_lrba",    "cgt_discount": "33⅓%", "loss_offset": "stays in fund", "asset_protection": "strong", "cost": "highest", "note": "geared SMSF; borrowing via LRBA only" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** `recommended_entity` is filled on the **agent path**, not by a KB rule; this doc constrains *how* the agent reasons (decision-support, options + considerations, defer to a licensed adviser) and supplies the comparison content.
- **ASIC line enforced as policy parameters.** `recommended_entity_is_decision_support` and `entity_selection_defer_to_adviser` are the load-bearing guards: the agent suggests a structure with reasoning, never a directive — the single most important discipline in the wedge.
- **Single-owner discipline for regulated figures.** The CGT discount by entity is owned by `kb.tax.cgt-50-percent-discount` and referenced here; negative gearing by `kb.tax.negative-gearing-mechanics`; trust/entity land tax by `kb.tax.land-tax-by-state`. This doc does not re-assert those figures (place, don't recompute).
- **SMSF tax not computed.** The plan surfaces the structure and restrictions and defers the SMSF/company/trust tax assessment to a licensed professional — it computes no entity-specific tax figure.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *CGT discount* (50% individuals/trusts; 33⅓% complying super funds; companies cannot use the discount) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-discount
- ATO — *Limited recourse borrowing arrangements* (an SMSF may borrow only via an LRBA — a single acquirable asset held in a holding trust, limited recourse) — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/self-managed-super-funds-smsf/smsf-investing/restrictions-on-smsf-investments/smsf-borrowing-restrictions/limited-recourse-borrowing-arrangements
- ATO — *SMSF borrowing restrictions* (related-party acquisition restrictions; arm's-length dealing) — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/self-managed-super-funds-smsf/smsf-investing/restrictions-on-smsf-investments/smsf-borrowing-restrictions

**Announced reform (proposed, not yet law — verified 2026-06-23):**

- ATO — *Tax reform – Boosting home ownership – Reforming negative gearing and capital gains tax* (50% discount → indexation + 30% minimum tax; negative gearing limited to new builds from 1 July 2027; not yet law) — https://www.ato.gov.au/about-ato/new-legislation/in-detail/individuals/tax-reform-boosting-home-ownership-reforming-negative-gearing-and-capital-gains-tax
