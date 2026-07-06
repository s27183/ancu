---
slug: kb.tax.cgt-50-percent-discount
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-discount
    retrieved: 2026-07-06
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/cgt-discount-for-foreign-residents
    retrieved: 2026-06-23
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/calculating-your-cgt/how-to-calculate-your-cgt
    retrieved: 2026-06-23
  - url: https://www.legislation.gov.au/C2026A00049/latest/text
    retrieved: 2026-07-06
    path: docs/sources/legislation/treasury-laws-amendment-tax-reform-no-1-act-2026-no49.pdf
  - url: https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=r7493
    retrieved: 2026-07-06
---

# CGT — the 50% discount (investor disposal)

The **CGT discount** reduces the taxable capital gain on an asset held for **at least 12 months** before the CGT event. For an **investor** (Mode C/D) the property is **not** a main residence, so the main-residence exemption ([`kb.tax.cgt-main-residence-exemption`](cgt-main-residence-exemption.md)) does **not** apply — the disposal is a taxable CGT event, and the discount is the load-bearing concession that halves the taxable gain for an individual or trust holding past 12 months. This doc owns **the discount rate by owning entity, the 12-month holding rule, the order of operations (capital losses before the discount), and the foreign-resident apportionment** so the `disposition` component's `cgt` figure (and `tax_structure`'s gearing/holding considerations) is **resolver-computed** for the investor case — never authored by the LLM. It is a statutory schedule to confirm with a registered tax agent or the ATO; informational, not tax or financial advice.

This is the **investor** slice the Mode-A main-residence doc explicitly defers ("the 50% discount for assets held > 12 months … authored design-first when those modes enter scope"). The two are complementary, not duplicative: main-residence owns *when CGT does not apply at all*; this doc owns *how a taxable gain is discounted once CGT does apply*. The cost-base side — what depreciation does to the gain — lives in [`kb.tax.depreciation-division-43-and-40`](depreciation-division-43-and-40.md); the income-year rate the discounted gain is then taxed at lives in [`kb.tax.income-tax-resident-2025-26`](income-tax-resident-2025-26.md).

## The discount rate — by owning entity

The discount percentage depends on **who owns the asset** — this is why entity choice ([`kb.tax.entity-comparison-personal-trust-company-smsf`](entity-comparison-personal-trust-company-smsf.md)) has a CGT consequence, surfaced as a consideration, never a recommendation:

| Owning entity | CGT discount | Effect on a $100,000 gain held > 12 months |
|---|---|---|
| **Individual** | **50%** | $50,000 taxable, then taxed at the individual's marginal rate |
| **Trust** | **50%** (the gain flows through to beneficiaries; the discount is applied/retained on distribution) | $50,000 taxable in the beneficiary's hands |
| **Complying super fund / SMSF** | **33⅓%** | ~$66,667 taxable, then at the fund's concessional rate |
| **Company** | **none** (companies cannot use the CGT discount) | $100,000 taxable at the company tax rate |

The discount is the single largest reason a buy-and-hold investor's *holding period* matters to after-tax return — and the reason a company structure, which forfeits it, is a genuine trade-off rather than a default.

## The 12-month holding rule

The asset must be **owned for at least 12 months** before the CGT event (the contract date of sale, not settlement) for the discount to apply. The 12 months is counted **excluding** the days of acquisition and disposal. A disposal inside 12 months gets **no discount** — the full nominal gain is taxable. This is the hinge the `disposition` full-horizon projection turns on: a sale modelled at, say, month 10 is taxed on the undiscounted gain; the same sale at month 13 halves the taxable gain for an individual holder.

## Order of operations — capital losses first, then the discount

The discount applies to the gain **after** capital losses (current-year and carried-forward) have been applied:

1. Compute the nominal capital gain = capital proceeds − cost base (the cost base reduced by any depreciation claimed — see Div 43/40 clawback).
2. **Apply capital losses** against the nominal gain.
3. **Apply the discount** (50% / 33⅓%) to what remains.
4. The discounted gain is added to assessable income and taxed at the entity's rate.

Losses are applied **before** the discount because applying them after would waste half of each loss dollar — the resolver follows this order so the modelled CGT is not overstated.

## Foreign / temporary residents — the discount is apportioned

The **full** discount is **not** available for the portion of a capital gain accruing to an individual while a **foreign or temporary resident** after **8 May 2012**. Where the owner had a period of **Australian residency** during ownership, an **apportioned** discount applies for that period. This is the diaspora-shaped trap that mirrors the main-residence doc's non-resident removal: a Vietnamese-Australian investor who holds while overseas (non-resident for tax) loses the discount for that span. Because the apportionment depends on day-counts and residency periods the plan does not fully capture, the resolver returns **`to_verify`** (deferring to a registered tax agent) once a non-resident period is in play, rather than estimating an apportioned figure.

## Enacted reform — Tax Reform No. 1 Act 2026 (takes effect 1 July 2027)

The 2026-27 Federal Budget (Budget night **7:30pm AEST, 12 May 2026**) announced a reform that **replaces the 50% discount** described above. It is now **law**: the *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (**Act No. 49 of 2026**) passed both Houses on **25 June 2026** (amended in the Senate that day) and received **Royal Assent on 26 June 2026**. It **takes effect 1 July 2027** — so the 50% discount **remains the applicable law for all disposals up to that date**. The specific mechanics below reflect the reform's announced design and the enacted Act's summary; because the Bill was amended in the Senate on 25 June 2026, the fine detail must be reconfirmed against the enacted Act text before it is relied on.

What the reform would do (for **individuals, trusts and partnerships**):

- **Replace the 50% discount with cost-base indexation** — tax on the *real* gain (the gain above inflation), not a flat 50% reduction.
- Introduce a **30% minimum tax rate** on real capital gains (income-support recipients / pensioners **exempt** — taxed at their marginal rate).
- **Split existing holdings at 1 July 2027**: the gain accrued **up to 1 July 2027** is taxed under the **old rules (50% discount)**; the gain accruing **after** is taxed under indexation + the 30% minimum.
- **New-build** investors may **choose** the 50%-discount regime *or* the indexation regime on the full gain.

This is **load-bearing for the wedge's target investor** — an established-property purchase **after** Budget night, held long-term: a disposal modelled past 1 July 2027 straddles two regimes. The regulated discipline (the reform is now enacted but not yet in effect, and it splits a long-hold gain): the resolver computes the **current 50% discount as the figure** for disposals up to 1 July 2027, **surfaces the enacted reform as a flagged caveat**, and returns **`to_verify`** for any post-1-July-2027 portion. Confirm the indexation mechanics against the enacted Act with a registered tax agent / the ATO.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The base case is a discounted gain, not an exemption.** Unlike the Mode-A first home, an investment property's disposal is taxable; the plan states the 50% discount plainly so the dispose-phase net proceeds are not modelled as if exempt.
- **Holding period is a lever, not a detail.** The discount makes the 12-month line a real decision input the `disposition` projection surfaces (sell pre- vs post-12-months changes the taxable gain by half for an individual).
- **Two diaspora traps.** (a) a **non-resident-for-tax** holding period apportions the discount away, and (b) **depreciation claimed** reduces the cost base and so *increases* the gain (Div 43/40 clawback) — both surfaced, neither silently assumed away.
- **Information, not advice.** The resolver computes the discounted gain from these statutory constants for the clean resident-individual case and returns `to_verify` once a non-resident period, trust/company structure nuance, or apportionment applies; it points to a registered tax agent and never issues a binding CGT assessment or an entity recommendation.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; `disposition.cgt` (investor) is **resolver-computed** from these constants against the holding period and entity, the discount applied to the net gain after losses (control flow → code, per §11.9). Every figure here is a regulated ATO constant.

```jsonc
{
  "fills": [],
  "parameters": {
    "discount_pct_individual":        { "type": "percentage", "value": 50,   "note": "REGULATED (ATO, Div 115 ITAA 1997) — CGT discount for an individual on an asset held ≥ 12 months" },
    "discount_pct_trust":             { "type": "percentage", "value": 50,   "note": "REGULATED (ATO) — trusts get the 50% discount; the discounted gain flows through to beneficiaries" },
    "discount_pct_super_fund":        { "type": "percentage", "value": 33.33,"note": "REGULATED (ATO) — complying super funds / SMSFs get a 33⅓% discount" },
    "discount_pct_company":           { "type": "percentage", "value": 0,    "note": "REGULATED (ATO) — companies cannot use the CGT discount" },
    "min_holding_months":             { "type": "integer",    "value": 12,   "note": "REGULATED (ATO) — asset must be owned ≥ 12 months before the CGT event (contract date), excluding acquisition and disposal days; a disposal inside 12 months gets no discount" },
    "losses_before_discount":         { "type": "bool",       "value": true, "note": "REGULATED (ATO) — apply current-year and carried-forward capital losses to the nominal gain BEFORE applying the discount" },
    "foreign_resident_full_discount_removed_from": { "type": "string", "value": "8 May 2012", "note": "REGULATED (ATO) — the full discount is not available for the gain accruing while a foreign/temporary resident after 8 May 2012; an apportioned discount applies for any period of Australian residency. Hooks to profile.tax_residency (F2)" },
    "investor_cgt_disposition":       { "type": "string", "value": "discounted taxable gain (50% individual/trust, 33⅓% super, nil company) for the clean resident case held > 12 months; to_verify once a non-resident period, apportionment, or entity nuance applies", "note": "the resolver verdict surface for disposition.cgt in Modes C/D — a discounted gain for the clean case, to_verify (defer to a tax agent) once a trap applies; never an entity recommendation" },
    "announced_reform_not_yet_law":   { "type": "string", "value": "2026-27 Budget (12 May 2026): replacement of the 50% discount with cost-base indexation + a 30% minimum tax from 1 July 2027 — now ENACTED as Treasury Laws Amendment (Tax Reform No. 1) Act 2026 (Act No. 49 of 2026), passed both Houses 25 Jun 2026 (amended in the Senate that day), assented 26 Jun 2026, effective 1 July 2027; existing holdings split at 1 July 2027 (pre = 50% discount, post = indexation + 30% min); new builds may choose either regime; income-support recipients exempt from the 30% minimum", "note": "ENACTED (Act No. 49 of 2026) but not yet in effect — the 50% discount remains the applicable law for disposals up to 1 July 2027. Resolver computes current law and flags the enacted reform; any post-1-July-2027 portion → to_verify. Specific mechanics reflect the announcement + enacted-Act summary; the Bill was amended in the Senate 25 Jun 2026 — reconfirm the fine detail against the enacted Act text (key name retained for reference stability; the reform is no longer merely 'announced')." }
  },
  "lookup": {
    "cgt_discount_by_entity": {
      "note": "discount percentage keyed by owning entity; resolver selects by tax_structure.entity and applies (1 − discount_pct/100) to the net gain after losses for assets held ≥ min_holding_months",
      "entries": [
        { "entity": "individual", "discount_pct": 50 },
        { "entity": "trust",      "discount_pct": 50 },
        { "entity": "super_fund", "discount_pct": 33.33 },
        { "entity": "company",    "discount_pct": 0 }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.cgt` (investor) is resolver-derived: the discount constants applied to the net gain after losses for a holding ≥ 12 months, `to_verify` once a non-resident period / apportionment / entity nuance applies. The doc supplies the rate schedule and the order of operations, not a computed gain.
- **REGULATED — verified against the ATO.** The discount percentages (50% / 33⅓% / nil), the 12-month holding rule, the losses-before-discount order, and the 8 May 2012 foreign-resident change were confirmed against the ATO *CGT discount* and *CGT discount for foreign residents* pages (verified 2026-06-23).
- **`lookup` for the by-entity rate** because it is a table the resolver indexes by `tax_structure.entity` (the vocabulary's intended use); the scalar rates are duplicated as `parameter`s for direct reference, mirroring `kb.tax.income-tax-resident-2025-26`.
- **Complements, does not duplicate, the main-residence doc.** Main-residence owns *when CGT does not apply*; this doc owns *how a taxable gain is discounted once it does*. The cost-base interplay (depreciation clawback) is owned by `kb.tax.depreciation-division-43-and-40`; the marginal rate the discounted gain is taxed at is owned by `kb.tax.income-tax-resident-2025-26`.
- **The two load-bearing traps are diaspora-shaped.** A non-resident-for-tax holding period (apportions the discount) and depreciation claimed (clawed back into the gain) — both surfaced so the dispose-phase figure is not modelled as a clean discounted gain when it is not.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *CGT discount* (50% for individuals and trusts; 33⅓% for complying super funds; companies cannot use the discount; asset owned ≥ 12 months before the CGT event) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-discount
- ATO — *CGT discount for foreign residents* (full discount not available for gains accruing while a foreign/temporary resident after 8 May 2012; apportioned discount for periods of Australian residency) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/cgt-discount-for-foreign-residents
- ATO — *How to calculate your CGT* (apply capital losses before applying the discount; the discount method) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/calculating-your-cgt/how-to-calculate-your-cgt

**Enacted reform (now law — verified 2026-07-06):**

- Federal Register of Legislation — *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (**Act No. 49 of 2026**, registered 26 June 2026; replaces the 50% discount with cost-base indexation + 30% minimum tax for individuals/trusts/partnerships from 1 July 2027) — https://www.legislation.gov.au/C2026A00049/latest/text (archived: `docs/sources/legislation/treasury-laws-amendment-tax-reform-no-1-act-2026-no49.pdf`)
- Parliament of Australia — *Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* (progress: passed both Houses 25 Jun 2026, amended in the Senate that day; assent 26 Jun 2026, Act No. 49, 2026) — https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=r7493
- ATO — *Tax reform – Boosting home ownership – Reforming negative gearing and capital gains tax* (50% discount → cost-base indexation + 30% minimum tax from 1 July 2027) — https://www.ato.gov.au/about-ato/new-legislation/in-detail/individuals/tax-reform-boosting-home-ownership-reforming-negative-gearing-and-capital-gains-tax (verified 2026-06-23; ATO blocks automated fetch)
