---
slug: kb.scheme.fhss
effective_from: 2024-09-15
last_verified: 2026-05-30
---

# First Home Super Saver scheme (FHSS)

The **First Home Super Saver** scheme lets a first home buyer save for a deposit **inside superannuation** and later withdraw those voluntary contributions (plus deemed earnings) to buy or build their first home. The benefit is tax: voluntary contributions made concessionally are taxed in super at 15% rather than at the saver's marginal rate, and the released amount attracts a 30% tax offset on withdrawal. It is administered by the **ATO**, not the super fund — the ATO issues the determination and authorises the release.

FHSS is a **savings vehicle**, not a guarantee or a grant. It does not change how a buyer borrows; it changes how efficiently they accumulate the deposit. It therefore sits alongside, and is independent of, the [First Home Guarantee](fhg.md) (`kb.scheme.fhg`).

## Eligibility

A person can request an FHSS release if they:

- Are **18 or older** at the time of the release request. (Voluntary contributions can be made before turning 18; only the *release request* has the age requirement.)
- Have **never owned property in Australia** — no prior relevant interest in Australian real property (including a home, investment property, vacant land, company-title interest, or a lease of land). Property owned **overseas does not count**; the test is Australian property interests only. Eligibility is assessed at the time of the FHSS determination.
- Have **not previously made an FHSS release** request — a person gets one valid release in their lifetime.
- Intend to **live in the home** as soon as practicable and for at least **6 of the first 12 months** of ownership.

Eligibility is assessed per person, so two eligible buyers purchasing together can each run their own FHSS.

## How much can be contributed and released

- Voluntary contributions count toward FHSS up to **$15,000 per financial year** and **$50,000 in total** across all years (counting contributions made from 1 July 2017).
- Of those counted contributions, **100% of non-concessional** (after-tax) contributions and **85% of concessional** (e.g. salary-sacrifice or personal-deductible) contributions are releasable. The 15% gap on concessional contributions is the contributions tax already paid in the fund.
- The release also includes **associated earnings** — a deemed earnings amount the ATO calculates on the eligible contributions (using a set rate), not the fund's actual investment return.
- Compulsory employer (SG) contributions and spouse contributions do **not** count toward FHSS.

## Tax treatment

- Concessional contributions are taxed at **15%** on the way into super (versus the saver's marginal rate outside super) — this is where the benefit comes from.
- On release, the **assessable amount** (the concessional contributions released plus all associated earnings) is taxed at the saver's **marginal rate minus a 30% tax offset**. Non-concessional contributions released are not taxed again.
- Worked illustration of the offset only: a saver on a 34% marginal rate (incl. Medicare levy) pays 34% − 30% = **4%** on the assessable amount. This is illustrative, not advice — actual tax depends on the individual's circumstances.

## Release process and timing

1. **Determination** — request an FHSS determination from the ATO (online via myGov). This tells the saver their maximum releasable amount. A determination can be requested at any time and more than once before releasing.
2. **Release request** — when ready to buy, request the release. The ATO instructs the fund to release the money to the ATO, which pays it to the saver after withholding any tax. **Releases are not instant** — the end-to-end process typically takes **15–25 business days**; plan for the upper end (the blueprint's 25-business-day default), not same-week funds.
3. **The contract window** — for determinations made **on or after 15 September 2024**, the saver must sign a contract to buy or build within a window that starts **90 days before** the release request and ends **12 months after** it (the ATO can allow a longer period). Within this window they either sign a contract **or** recontribute the released amount to super.
4. **Notify the ATO** within **90 days** of signing the property contract (this is the window for determinations made on or after 15 September 2024; under the older regime it was 28 days).
5. **If they do not buy in time** — they can recontribute the released amount to super, **or** keep it and pay **FHSS tax of 20% of the assessable released amount**.

## Stacking with other support

FHSS combines naturally with the **First Home Guarantee**: FHSS builds the deposit tax-efficiently, then FHG lets the buyer use a 5%-deposit loan with no LMI. They are independent mechanisms with separate eligibility, so a Mode A buyer can use both. FHSS is also independent of **state First Home Owner Grants** and **stamp-duty concessions**.

## Relevance for Vietnamese-Australian buyers (Mode A)

- The "**never owned property in Australia**" test excludes only Australian interests — a buyer who previously owned a home **in Vietnam** can still be eligible.
- The benefit is largest for buyers with **taxable employment income** who can salary-sacrifice concessionally — common for employed citizens/PRs building a deposit over a few years.
- FHSS rewards **planning ahead**: because contributions are capped at $15,000/year, the full $50,000 benefit takes several financial years to build, so it is worth surfacing early in the base plan rather than at purchase time.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The `parameters{}` block holds the coefficients the resolver's (code) release-amount and tax formulas consume — `available_release_amount` and `tax_offset_estimate` are computed in resolver code, not filled by a rule here.

```jsonc
{
  // FHSS is an INDIVIDUAL scheme — each applicant holds their own super and releases
  // independently (resolver-semantics.md / eligibility-resolution.md decision 2, F13).
  // The eligibility component evaluates this scheme PER APPLICANT (eligible_applicants),
  // not ∀-joint. Absence of this marker ⇒ joint (the documented default; every other scheme).
  "resolution": "per_applicant",
  "fills": [
    { "leaf": "eligibility.fhss.eligible",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "applicant.age",                    "op": "gte", "value": 18 },     // at the release request
        { "field": "applicant.ever_owned_au_property", "op": "eq",  "value": false },   // never held an AU property interest
        { "field": "applicant.owner_occupier_intent",  "op": "eq",  "value": true },    // live in 6 of first 12 months
        { "field": "applicant.prior_fhss_release",     "op": "eq",  "value": false } ] } },  // one valid release per lifetime; field in the buyer_profile fact surface

    { "leaf": "eligibility.fhss.release_timeline_business_days",
      "rule": { "kind": "parameter", "type": "integer", "value": 25 } },             // plan for the upper end of the 15–25 range

    { "leaf": "eligibility.fhss.contract_window_months_after_release",
      "rule": { "kind": "parameter", "type": "integer", "value": 12 } }
  ],
  "parameters": {
    "annual_contribution_cap":             { "type": "money",      "value": 15000 },
    "total_contribution_cap":              { "type": "money",      "value": 50000 },
    "concessional_releasable_pct":         { "type": "percentage", "value": 85 },
    "non_concessional_releasable_pct":     { "type": "percentage", "value": 100 },
    "withdrawal_tax_offset_pct":           { "type": "percentage", "value": 30 },
    "unused_release_keep_tax_pct":         { "type": "percentage", "value": 20 },
    "contract_window_days_before_release": { "type": "integer",    "value": 90 },
    "ato_notify_days_after_contract":      { "type": "integer",    "value": 90 }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg"],   // state-concession edges are declared by the state doc (symmetric aggregation, §11.9); a federal scheme never enumerates state slugs
    "alternative_to": [],
    "order_hint": 10
  }
}
```

Notes:

- **`profile.prior_fhss_release`** (one valid release per lifetime) is now in the buyer_profile fact surface (`ownership_history` group — scheme-usage history, not property ownership), so this predicate passes reference-integrity. Resolved 2026-05-31 (task #14a).
- **`available_release_amount`** computation needs the contribution split (concessional vs non-concessional) + associated earnings; the profile currently captures only a single `fhss_contributions_to_date` figure, so the resolver can estimate but not compute exactly until that split is captured. Minor.
- `order_hint: 10` (lower than FHG's 20) — FHSS is acted on *earliest* (save over years before purchase).

## Sources

- ATO — *First home super saver scheme* — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/super/withdrawing-and-using-your-super/early-access-to-super/first-home-super-saver-scheme
- ATO — *Withdrawing FHSS amounts* (determination/release window for determinations on or after 15 Sep 2024) — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/super/withdrawing-and-using-your-super/early-access-to-super/first-home-super-saver-scheme/withdrawing-fhss-amounts
- Moneysmart (ASIC) — *First home super saver scheme* (20% FHSS tax on unused released amounts) — https://moneysmart.gov.au/saving/first-home-super-saver-scheme
