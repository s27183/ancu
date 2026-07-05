---
slug: kb.land-tax.dual-ownership-transition
effective_from: 2026-07-05
last_verified: 2026-07-05
---

# Land tax — dual-ownership treatment during a home-upgrade transition

A **Mode E** buyer (upsizer/downsizer/relocator) can end up **owning both their old and new home at once** for a period — the old home hasn't sold yet, or they haven't moved into the new one. Each state's principal-place-of-residence (PPOR) land-tax exemption ([`kb.land-tax.ppor-exemption`](ppor-exemption.md)) is written around **one** exempt home at a time, so this overlap is a genuine edge case: does the *second* property lose its exemption for the transition period, or is there a grace provision? **VIC's answer is already documented** in `kb.land-tax.ppor-exemption` (a named "dual-PPR exemption" — both properties exempt for the assessment year). This doc surveys the **other seven jurisdictions** — NSW, QLD, WA, SA, TAS, ACT, NT — none of which are covered by that doc's per-state section. It grounds the same `ownership_planning.annual_obligations.land_tax_check` outcome as `kb.land-tax.ppor-exemption`, specifically for the transition-year case.

## NSW — folded into the PPR test itself, no separate provision

Revenue NSW's PPR-exemption ruling (LT082v6) treats **both** the old and new home as the PPR for a taxing date (31 December) when the old home **hasn't sold yet** and the new home is owned with the intention of using it as the PPR — there is no separately-named "transitional exemption"; it is simply how the PPR test is applied when a sale is in progress. **Confirmed via search-engine snippet of the ruling; the full ruling page was not directly fetched this pass** (revenue.nsw.gov.au blocked direct retrieval).

## QLD — a named, dated provision: the Transitional Home Exemption

Queensland Revenue Office runs a **named** exemption for exactly this case: the **Transitional Home Exemption**. It applies when the owner occupied the old home on the **prior 30 June** and acquires the new home **within the following 12 months**. It requires lodging **Form LT21 (transitional)** alongside **Form LT12 (home exemption)** for the currently-occupied home — two separate forms for the two properties. QRO's own guidance for this exemption discusses a buyer needing **bridging finance** pending the old home's sale, which is directly on-point for the Mode E scenario this doc and `kb.bridging-finance.mechanics` jointly cover. **Confirmed directly** — https://qro.qld.gov.au/land-tax/relief/transitional-home-exemption/.

## WA — an exemption exists ("moving between residences"); duration/conditions not yet confirmed

WA's state government site names an exemption category for **"moving between residences"** — buying or building a new home while planning to sell the old one — confirming the *existence* of a transitional provision. The specific **duration and eligibility conditions were not found** on the fetched page. **This sub-fact stays a labelled gap, not a guess**: treat WA's transition window as `to_verify` until a follow-up lookup (the application form itself, or a direct RevenueWA/Department of Treasury enquiry) confirms the duration. — https://www.wa.gov.au/service/financial-management/taxation-and-duty/apply-land-tax-exemption.

## SA — a waiver, not an exemption, and financial-year-bound

RevenueSA's mechanism is structured differently: no automatic dual-exemption; instead a **waiver** is available for the financial year **if** the old home is sold within that same financial year **and neither home was rented** during the transition. The exact rule differs depending on whether the buyer moves into the new home before or after 30 June. **Confirmed via search-engine snippet; direct fetch blocked (403)** — https://revenuesa.sa.gov.au/landtax/exemption-waiver-relief/residential-home.

## TAS — a named rebate with fully specified conditions

State Revenue Office Tasmania runs the **"Two residences owned in transitional circumstances"** rebate: the new residence must be **≥50% owned** by the same owner(s) as the old one, purchased **on or after 1 April**, possession taken **before 1 October**, and **neither** property may be rented or otherwise income-producing during the transitional period. This is the most fully specified of the non-VIC provisions found. **Confirmed directly** — https://www.sro.tas.gov.au/land-tax/exemptions-and-rebates/Two-residences-owned-in-transitional-circumstances-rebate.

## ACT — a different mechanism entirely (quarterly assessment, no annual dual-exemption)

The ACT assesses land tax **quarterly**, not annually, on non-PPR residential property — so the "transition year" framing used elsewhere doesn't directly apply. Two rules function as the practical bridge instead: **(a)** a newly bought home is exempt if the owner moves in within **3 months** of becoming owner and doesn't rent it in the meantime; **(b)** a home the owner moves **out** of stays exempt for **the first full quarter** after moving out (it may sit vacant or be listed for sale — but the exemption ends the moment it is rented). Together these can cover a typical upgrade transition without a named "dual-ownership" provision as such. **Confirmed via search-engine snippet; direct fetch blocked** — https://www.revenue.act.gov.au/land-tax/exemptions.

## NT — moot: no general land tax exists

The Northern Territory levies **no general land tax** on residential property, owner-occupied or investment — so the dual-ownership question does not arise there at all. **This rests on secondary/aggregator corroboration** (propertytaxtools.com.au, nfinityfinancials.com), not a directly-read Territory Revenue Office primary page (nt.gov.au blocked direct retrieval this pass) — it is nonetheless a widely and consistently reported fact, not a contested one. A follow-up direct check against treasury.nt.gov.au is recommended before this is cited as fully primary-verified, per [[kb-doc-authoring]]'s proportionate-verification discipline.

## Relevance for Vietnamese-AU next-home buyers (Mode E)

- **The transition risk varies sharply by state — this is not a uniform rule.** QLD and TAS have clean, dated, named provisions; NSW folds it into the ordinary PPR test; SA structures it as a conditional waiver; ACT's quarterly system sidesteps the annual framing; WA's provision exists but its duration is unconfirmed; NT doesn't have the tax at all. A Mode E plan must read the buyer's **state**, not assume VIC's dual-PPR pattern generalises.
- **The clean-transition condition recurs: don't rent either property.** QLD, SA, TAS, and ACT's provisions all hinge on **neither** home being rented/income-producing during the transition — the same trap `kb.land-tax.ppor-exemption` already names for the single-PPOR case, just applied to two properties at once.
- **Information, not advice.** The plan states each state's provision (or its absence/uncertainty) and points to the relevant revenue office to confirm; it does not compute a binding land-tax assessment for the transition period.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `land_tax_check` during a Mode E transition is **resolver-derived** per-state against these rules; `to_verify` (never a silent `exempt_ppor` default) wherever a provision's detail is unconfirmed (WA) or state-specific conditions (rental history, timing windows) aren't yet known.

```jsonc
{
  "fills": [],
  "parameters": {
    "nsw_dual_ownership_mechanism":  { "type": "string", "value": "folded into the ordinary PPR test — both old and new home treated as PPR at the taxing date while a sale is in progress and the new home is intended as the PPR", "provenance": "REGULATED (Revenue NSW Ruling LT082v6, snippet-confirmed, direct fetch blocked)" },
    "qld_transitional_home_exemption": { "type": "bool", "value": true, "provenance": "REGULATED (QRO, directly confirmed)", "note": "requires occupancy of the old home on the prior 30 June + new home acquired within 12 months; lodge Form LT21 (transitional) + Form LT12 (home exemption)" },
    "qld_transition_window_months":   { "type": "integer", "value": 12, "provenance": "REGULATED (QRO)" },
    "wa_moving_between_residences_exemption_exists": { "type": "bool", "value": true, "provenance": "REGULATED (existence confirmed), duration/conditions UNCONFIRMED", "note": "labelled gap — do not assert a specific duration or condition set for WA until a follow-up lookup confirms it; resolver must return to_verify, not a guessed window" },
    "sa_mechanism":                  { "type": "string", "value": "waiver (not exemption) for the financial year, conditional on selling the old home within that FY and neither home being rented; rule differs by move-in timing relative to 30 June", "provenance": "REGULATED (RevenueSA, snippet-confirmed, direct fetch blocked)" },
    "tas_transitional_rebate":       { "type": "bool", "value": true, "provenance": "REGULATED (SRO Tasmania, directly confirmed)", "note": "'Two residences owned in transitional circumstances' rebate — new residence ≥50% same ownership, purchased on/after 1 April, possession before 1 October, neither property rented during the transition" },
    "act_mechanism":                 { "type": "string", "value": "quarterly assessment (not annual); new home exempt if moved into within 3 months of ownership and not rented; vacated home stays exempt for the first full quarter after moving out unless rented", "provenance": "REGULATED (ACT Revenue Office, snippet-confirmed, direct fetch blocked)" },
    "nt_no_general_land_tax":        { "type": "bool", "value": true, "provenance": "secondary/aggregator-corroborated, NOT directly primary-fetched this pass", "note": "widely and consistently reported; recommend one direct confirmation pass against treasury.nt.gov.au before treating as fully primary-verified" },
    "common_condition_no_rental_during_transition": { "type": "bool", "value": true, "note": "QLD, SA, TAS, ACT all condition the transitional relief on neither property being rented/income-producing during the overlap — the resolver should flag this as the load-bearing shared trap across states" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `land_tax_check` during a Mode E transition is resolver-derived per-state — `to_verify` wherever a state's provision detail is unconfirmed (WA duration) rather than a silent `exempt_ppor` assumption; the doc supplies the per-state rules and their confidence level, not a verdict.
- **Confidence is mixed and explicitly labelled, not uniform REGULATED.** QLD and TAS were directly fetched and fully specified; NSW, SA, ACT were confirmed via search-engine snippet (the government sites blocked direct retrieval this pass) but are corroborated, named provisions, not guesses; WA's *existence* is confirmed but its *duration/conditions* are an open gap; NT's absence-of-tax rests on secondary corroboration only. This mixed-confidence labelling follows [[kb-doc-authoring]] and [[verify-regulated-figures-by-postcondition]] — state the verification method honestly rather than flattening everything to "REGULATED, verified."
- **Scope discipline.** This doc owns only the **dual-ownership transition** case. The single-PPOR exemption and its ordinary loss-trigger (moving out and renting, permanently) stay in `kb.land-tax.ppor-exemption` — not duplicated here. VIC is deliberately excluded (already covered there).
- **Follow-up recommended, not blocking.** WA's exemption duration and NT's no-land-tax status should get a direct-primary re-verification pass before this doc's `last_verified` is extended past a routine freshness check — named here so the gap isn't silently forgotten, per [[honest-deferral-not-rug]].

## Sources

**Canonical (state/territory revenue offices), directly fetched:**

- Queensland Revenue Office — *Transitional Home Exemption* — https://qro.qld.gov.au/land-tax/relief/transitional-home-exemption/
- State Revenue Office Tasmania — *Two residences owned in transitional circumstances rebate* — https://www.sro.tas.gov.au/land-tax/exemptions-and-rebates/Two-residences-owned-in-transitional-circumstances-rebate

**Canonical, confirmed via search-engine snippet (direct fetch blocked this pass — recommend re-fetch before extending `last_verified`):**

- Revenue NSW — Ruling LT082v6 (PPR exemption where a sale is in progress) — https://www.revenue.nsw.gov.au/help-centre/resources-library/rulings/land/lt082v6
- Government of Western Australia — *Apply for a land tax exemption* ("moving between residences") — https://www.wa.gov.au/service/financial-management/taxation-and-duty/apply-land-tax-exemption
- RevenueSA — *Residential home exemption, waiver and relief* — https://revenuesa.sa.gov.au/landtax/exemption-waiver-relief/residential-home
- ACT Revenue Office — *Land tax exemptions* — https://www.revenue.act.gov.au/land-tax/exemptions

**Secondary corroboration only (not a directly-read primary):**

- NT's no-general-land-tax status — propertytaxtools.com.au, nfinityfinancials.com (Territory Revenue Office / nt.gov.au blocked direct retrieval this pass).
