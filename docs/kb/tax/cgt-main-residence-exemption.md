---
slug: kb.tax.cgt-main-residence-exemption
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/property-and-capital-gains-tax/your-main-residence-home
    retrieved: 2026-06-21
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/main-residence-exemption-for-foreign-residents
    retrieved: 2026-06-21
---

# CGT — the main residence exemption

**Capital gains tax (CGT)** is the tax on the gain when you dispose of an asset, including property. For a **Mode A owner-occupier first-home buyer**, the dwelling they buy to live in is their **main residence**, and a main residence is generally **exempt from CGT** — so on the disposal (`dispose`) phase of the lifecycle the Mode A answer is almost always **`cgt: null` (exempt)**. This doc owns **the full-exemption conditions, the triggers that reduce it to a partial exemption, the 6-year absence rule, and the foreign-resident-for-tax loss of the exemption**. It grounds the `disposition` component's `cgt` figure (and its `key_assumptions.exemption_basis`) — informationally; the exemption is a statutory fact to confirm with a registered tax agent or the ATO, never financial or tax advice.

This is the **Mode A** (owner-occupier, resident-for-tax) slice. The **investor** CGT treatment — the 50% discount for assets held > 12 months, the cost-base / depreciation interplay, and partial-exemption apportionment for a rented dwelling — is the same disposal structure populated for **Modes C/D** and is authored design-first when those modes enter scope (lifecycle-simulation-model §8.7). It is **not** duplicated here.

## The full exemption — when CGT does not apply

A dwelling is **fully exempt** from CGT on disposal when **all** of these hold for the whole ownership period:

- You are an **Australian resident for tax purposes** (distinct from citizenship / FIRB status — a citizen living overseas can be a *non-resident for tax*; see "Foreign resident" below and `buyer_profile` F2 `tax_residency`).
- The dwelling was the **home of you (and your partner / dependants) for the whole period you owned it**.
- It was **not used to produce income** (not rented out, not run as a business or home office claimed against income).
- The land it sits on is **2 hectares or less**. (Above 2 ha, you may choose which part is exempt; the excess is not exempt.)

For the Mode A base case — a first home, lived in continuously, on a normal residential block, not rented — the disposal is **CGT-exempt** and `disposition.cgt` is `null`. The value of the dispose phase is then the **equity realised at sale → the next purchase** (the graduation / upgrade story), not a tax liability.

## Partial exemption — when only part of the gain is exempt

The exemption is **reduced to a partial exemption** (a proportion of the gain becomes taxable) when, during ownership, the dwelling was **not your main residence for the whole period** or was **used to produce income**:

- **Used to produce income** (e.g. rented a room, whole-home rental for a period, or a deductible home-office/business area). If **any part of the land is used to produce income, that part is not exempt even when the total area is under 2 ha**. This is the lifecycle hook to `buyer_profile.intended_occupancy_use`: `partial_rental` / `granny_flat` flips the dwelling out of the clean full-exemption case (the same flag that flips the land-tax PPOR exemption, `kb.land-tax.ppor-exemption`).
- **Main residence for only part of ownership** (e.g. it was an investment first, or you moved out without the absence rule below).

## The 6-year absence rule

If a dwelling **was** your main residence and you then **move out and rent it**, you can **continue to treat it as your main residence for up to 6 years** while it produces income (and indefinitely if it does not produce income). Re-establishing it as your main residence resets the 6-year period. This is the rule that keeps a Mode A owner's *first home* CGT-exempt across a typical move-out-and-rent period — and the precise hinge a future **mode switch to investor** turns on (the same mode-switch the land-tax alert watches).

## Foreign resident for tax purposes — the exemption is removed

For disposals from **7:30pm AEST on 9 May 2017**, the main residence exemption is **no longer available** to an individual who is a **foreign resident for tax purposes at the time of the disposal** — unless they satisfy the **life events test** (foreign resident for a continuous period of **6 years or less** and a listed life event, e.g. a relationship breakdown). A transitional rule allowed pre-**30 June 2020** disposals of property held before the announcement. This is why `tax_residency` is a first-class `buyer_profile` fact (F2): a Vietnamese-Australian owner who has moved overseas and become a non-resident for tax can **lose** the exemption on the very home this plan treats as exempt.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The base case is exempt.** A Mode A FHB buying a home to live in and selling it as their home pays **no CGT** — the plan states this plainly so the dispose-phase net proceeds are not silently haircut by a tax that does not apply.
- **The two traps are the lifecycle moves.** (a) **Renting it out** (partial exemption / the 6-year clock) and (b) **moving overseas and becoming a non-resident for tax** (exemption removed). Both are exactly the diaspora lifecycle. The plan surfaces the exemption *and* names the triggers, rather than asserting a clean exemption that a later move quietly breaks.
- **Information, not advice.** The plan states the exemption and the triggers and points to a registered tax agent / the ATO to confirm; it never computes a binding CGT assessment. For Mode A the resolver returns **exempt (`cgt: null`)** for the clean owner-occupier case and **`to_verify`** (deferring to a professional) once a trap is in play — it does not estimate a taxable gain.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `disposition.cgt` is **resolver-derived**: `null` (exempt) for the clean Mode A owner-occupier case, `to_verify` once a partial-exemption / non-resident trap applies; the resolver never authors a taxable-gain figure for Mode A.

```jsonc
{
  "fills": [],
  "parameters": {
    "main_residence_exempt_default":      { "type": "bool", "value": true, "note": "REGULATED (ATO) — a dwelling that is the owner's main residence for the whole ownership period, on land ≤ 2 ha, not used to produce income, owned by an Australian resident for tax, is exempt from CGT; the Mode A owner-occupier default is exempt (disposition.cgt = null)" },
    "land_area_cap_hectares":             { "type": "number", "value": 2, "note": "REGULATED (ATO) — full exemption applies to land of 2 hectares or less; above 2 ha the owner chooses which part is exempt and the excess is taxable" },
    "income_production_breaks_exemption": { "type": "bool", "value": true, "note": "REGULATED (ATO) — using the dwelling (or any part of the land) to produce income reduces the exemption to a partial exemption; any income-producing land part is not exempt even when total area < 2 ha. Hooks to buyer_profile.intended_occupancy_use (partial_rental / granny_flat)" },
    "absence_rule_years_if_income":       { "type": "integer", "value": 6, "note": "REGULATED (ATO) — the '6-year rule': a former main residence rented out can continue to be treated as the main residence for up to 6 years (indefinitely if not income-producing); re-establishing residence resets the period" },
    "foreign_resident_exemption_removed_from": { "type": "string", "value": "7:30pm AEST 9 May 2017 (transitional disposals to 30 June 2020)", "note": "REGULATED (ATO) — the main residence exemption is unavailable to an individual who is a foreign resident for tax at the time of disposal, unless the life-events test is met (foreign resident ≤ 6 continuous years + a listed life event). Hooks to buyer_profile.tax_residency (F2)" },
    "mode_a_cgt_disposition":             { "type": "string", "value": "exempt (cgt = null) for the clean owner-occupier case; to_verify once rented / non-resident / >2ha applies", "note": "the resolver verdict surface for disposition.cgt in Mode A — never an estimated taxable gain; the investor CGT computation (50% discount, cost base, apportionment) is Modes C/D, design-first" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.cgt` is resolver-derived from main-residence status against these rules — `null` (exempt) for the Mode A base case, `to_verify` once a trap applies. The doc supplies the conditions and the loss-of-exemption triggers, not a computed gain.
- **REGULATED — verified against the ATO.** The full-exemption conditions, the 2-hectare cap, the income-production rule, the 6-year absence rule, and the foreign-resident removal were confirmed against the ATO directly (see Sources, verified 2026-06-21). The core eligibility conditions (2-hectare cap, income-production rule) were **re-confirmed 2026-07-06** via the archived snapshot of the ATO eligibility page (unchanged); ATO blocks automated fetch, so the 6-year-rule and foreign-resident pages carry the 2026-06-21 verification.
- **Scope discipline.** The owner-occupier exemption and its loss-triggers are owned here (what a Mode A owner needs). The **investor CGT mechanics** — the 50% discount for assets held > 12 months, cost-base / depreciation, partial-exemption apportionment math — are out of scope for Mode A and belong to the investor blueprints, authored design-first (lifecycle-simulation-model §8.7); not duplicated here.
- **The two load-bearing traps are diaspora-shaped.** Renting the first home (6-year clock / partial exemption) and moving overseas (non-resident removal) are exactly the Vietnamese-Australian lifecycle — captured explicitly so a future mode switch surfaces the CGT consequence rather than letting a "clean exemption" assertion mislead.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *Your main residence – home* (overview of the main residence exemption) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/property-and-capital-gains-tax/your-main-residence-home
- ATO — *Eligibility for main residence exemption* (Australian resident; home for the whole ownership period; not used to produce income; 2-hectare cap; income-producing land not exempt) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/property-and-capital-gains-tax/your-main-residence---home/eligibility-for-main-residence-exemption
- ATO — *Treating former home as main residence* (the 6-year absence rule — up to 6 years while income-producing, indefinite if not) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/property-and-capital-gains-tax/your-main-residence---home/treating-former-home-as-main-residence
- ATO — *Main residence exemption for foreign residents* (removed for disposals from 7:30pm AEST 9 May 2017 unless the life-events test is met; transitional to 30 June 2020) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/main-residence-exemption-for-foreign-residents
