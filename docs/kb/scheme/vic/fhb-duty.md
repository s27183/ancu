---
slug: kb.scheme.vic.fhb-duty
effective_from: 2017-07-01
last_verified: 2026-06-01
---

# Victoria First Home Buyer Duty Exemption / Concession

The **First Home Buyer Duty Exemption or Concession** is a Victorian **land transfer (stamp) duty** benefit for first home buyers, administered by the **State Revenue Office (SRO)**. Like the QLD and NSW concessions it reduces a **settlement cost** — the duty otherwise payable on the transfer — and, like NSW (but unlike QLD's split), **a single scheme covers both new and established homes** (and vacant land to build on), with the benefit determined by **dutiable value**. It is independent of the federal [First Home Guarantee](../fhg.md) and [First Home Super Saver](../fhss.md).

Since **1 July 2017**: a home with a **dutiable value of $600,000 or less is fully exempt** from duty; from **$600,001 to $750,000** a **concession applies on a sliding scale** (the closer to $600,000, the larger the concession); above **$750,000** there is no first-home benefit.

## Eligibility

To claim the exemption or concession, the buyer must:

- Have **never owned residential property in Australia** (the buyer and spouse/partner) and never received this benefit before. ⚠ This is an **Australia-only** test — a prior home **overseas does not disqualify** — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a).
- Be an **Australian citizen or permanent resident**, **aged 18 or over**. (The duty benefit follows the First Home Owner Grant residency criteria.)
- Buy a **new or established home, or vacant land to build on**, with a dutiable value **at or under $750,000**.
- **Live in the home** as the principal place of residence for at least **12 continuous months**, starting **within 12 months** of settlement. (For vacant land: move in within 12 months of the occupancy certificate or 36 months of settlement, whichever is first.)

## Concession amount

The benefit is value-banded:

- **$600,000 or under** — **full exemption** (no duty).
- **Over $600,000 to $750,000** — a **sliding-scale concession**; the reduction shrinks as value rises toward $750,000.
- **Over $750,000** — no first-home duty benefit.

The **dollar saving** for a given purchase is the duty otherwise payable (full exemption) or the difference between full and concessional duty (partial) — computed from the Victorian land-transfer-duty rate schedule against the dutiable value (resolver arithmetic; see Notes).

## Stacking with other support

This is a **state duty concession**, independent of the federal schemes: it can apply alongside an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal. For an eligible **new** home it also **combines with the [Victorian First Home Owner Grant](fhog.md)** ($10,000) — one reduces duty, the other is a cash payment. Because the duty benefit covers established homes too, it is the broader of the two and applies where the new-homes-only grant does not.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The overseas-ownership test is favourable here — like NSW and the federal schemes, the opposite of Queensland.** Victoria tests only **Australian** property history, so a Vietnamese-Australian buyer who once owned (or still owns) a home **in Vietnam** is **not disqualified** on that basis. Surface the state difference when comparing target states — the same prior-Vietnam-home fact that kills the QLD concession is harmless in Victoria.
- **The $600,000 full-exemption threshold and $750,000 ceiling** define where the benefit is full, partial, or nil — the target price range determines which. Melbourne medians sit near the top of the concession band for houses, so the benefit is often partial rather than full.
- **Covers established homes**, which dominate the affordable diaspora-targeted stock — so unlike a new-homes-only grant, the duty benefit is available on the typical Mode A established purchase.
- **Citizenship or PR qualifies**, so a Vietnamese-Australian PR is eligible (unlike `kb.scheme.help-to-buy`, citizens only).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The dollar `duty_savings` and the value-banded `concession_type` are **computed** by the resolver from the dutiable value against the Victorian duty schedule and the thresholds below (not asserted here), so only the eligibility predicate and the scheme name are filled.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.state_concession.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",             "op": "eq",  "value": "VIC" },
        { "field": "applicant.ever_owned_au_property", "op": "eq",  "value": false },            // AU-only test — overseas ownership does NOT disqualify (favourable; opposite of QLD)
        { "field": "applicant.age",                    "op": "gte", "value": 18 },
        { "field": "applicant.citizenship_status",     "op": "in",  "value": ["citizen", "permanent_resident"] },
        { "field": "applicant.owner_occupier_intent",  "op": "eq",  "value": true },             // live 12 continuous months, starting within 12 months of settlement
        { "field": "property_fit.price",             "op": "lte", "value": 750000 } ] } },     // outer bound; ≤$600k exempt, $600k–$750k sliding concession, above → none. Covers new AND established (no property_type restriction)
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.state_concession.scheme_name",
      "rule": { "kind": "parameter", "type": "string", "value": "Victoria First Home Buyer Duty Exemption/Concession" } }
  ],
  "parameters": {
    "exemption_threshold":                    { "type": "money",   "value": 600000 },          // at/under → duty nil
    "concession_cap":                         { "type": "money",   "value": 750000 },          // $600k–$750k sliding partial; above → none
    "move_in_window_months_after_settlement": { "type": "integer", "value": 12 },
    "min_continuous_occupancy_months":        { "type": "integer", "value": 12 }               // VIC requires 12 continuous months (cf. NSW 6)
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy"],   // state doc declares federal↔state edges (symmetric, §11.9); Help to Buy explicitly allows stacking stamp-duty concessions. The VIC FHOG↔duty edge is declared on fhog.md.
    "order_hint": 30   // duty concession — claimed at settlement, latest in the buyer's timeline
  }
}
```

Notes:

- **`duty_savings`** (the `eligibility.state_concession.duty_savings` leaf) is **not** filled here — resolver arithmetic against the Victorian land-transfer-duty rate schedule ([`kb.stamp-duty.calc-by-state`](../../stamp-duty/calc-by-state.md)) on the dutiable value. Same pattern as the QLD/NSW concessions.
- **`concession_type`** is **resolver-derived**, not a flat parameter: `full_exemption` at or under `exemption_threshold` ($600k), `partial_concession` up to `concession_cap` ($750k), else `no_concession`. Banded selection is control flow → resolver code, document-supplied numbers.
- **No `property_type` restriction** — the duty benefit covers new **and** established homes (and vacant land). This contrasts with QLD (separate new/established concessions) and is the reason there is no `alternative_to` within Victoria for the duty slot.
- **`ever_owned_au_property` only** — Australia-only test, so `prior_overseas_property_ownership` is deliberately not consulted (the same neutral fact that disqualifies under QLD is not in this predicate).
- **The "previously received this benefit" gate and spouse history are not encoded** as hard predicates (no such facts on the surface); rare for a fresh Mode A FHB, documented rather than dangled — same treatment as the NSW and QLD docs.

## Sources

- State Revenue Office Victoria — *First home buyer duty exemption or concession* ($600k exemption / $600k–$750k sliding concession; new + established + vacant land; citizen/PR aged 18+; 12 continuous months within 12 months; Australia-only prior-ownership) — https://www.sro.vic.gov.au/buying-property/land-transfer-stamp-duty/concessions-exemptions-and-waivers/first-home-buyers/first-home-buyer-duty-exemption-or-concession
- vic.gov.au — *Support for first home buyers* — https://www.vic.gov.au/support-first-home-buyers
