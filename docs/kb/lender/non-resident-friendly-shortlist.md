---
slug: kb.lender.non-resident-friendly-shortlist
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://asic.gov.au/for-finance-professionals/credit-licensees/
    retrieved: 2026-07-06
    note: "ASIC — credit assistance / recommending a credit product requires an Australian Credit Licence. Grounds the ACL boundary (criteria + reasoning, user picks, no named recommendation)"
  - url: https://www.canstar.com.au/home-loans/non-resident-home-loans/
    retrieved: 2026-07-06
    note: "Restricted non-resident lender set (mostly non-banks), higher rates, foreign-income criteria. The \"non-resident-friendly\" criteria framing is FirstHomey editorial judgment"
---

# Non-resident-friendly lender shortlist — selection criteria

When a foreign person or temporary resident needs financing, lenders differ sharply in whether — and on what terms — they will lend. This doc owns the **criteria that make a lender "non-resident-friendly"** so `mortgage_finance` (component 5) can produce a **shortlist with reasoning** the user evaluates — it does **not** name or rank specific lenders. The agent applies these criteria to the buyer's situation and surfaces *which kinds of policy* fit (and why); the **user picks, with a licensed mortgage broker.** This is the Mode-B analogue of [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md) and, like it, the most ACL-sensitive doc in the finance cluster: naming a lender as "recommended" crosses from information into **credit advice** (ACL territory; personal liability). The boundary is built into the doc — criteria and reasoning, never a recommendation.

## What "non-resident-friendly" means — the criteria

A lender's fit for a foreign / temporary-resident borrower turns on a handful of policy levers, each owned in detail by a sibling doc:

- **Foreign-income acceptance and shading generosity** — whether the lender counts overseas income at all, the accepted-currency list (does it accept VND?), and how heavily it shades (the ~10–40% band). More generous → higher assessed capacity. (Owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md).)
- **Residency / visa appetite** — whether the lender writes non-resident loans, and its treatment of the specific visa class (e.g. the favourable 485-with-AU-income branch). (Owned by [`kb.lender.485-visa-treatment`](485-visa-treatment.md), [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md).)
- **Deposit / LVR appetite** — the maximum LVR offered to the borrower's profile (60–70% non-resident vs 80–95% AU-income / joint). (Owned by [`kb.lender.foreign-buyer-deposit-requirements`](foreign-buyer-deposit-requirements.md).)
- **FIRB-conditional handling** — whether the lender will issue a loan offer conditional on FIRB approval and settle only after it. (Owned by [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).)
- **Documentation capability for non-residents** — whether the lender can process overseas-sourced income, identity and source-of-funds evidence, and its processing time. (Owned by [`kb.lender.documentation-non-resident`](documentation-non-resident.md).)
- **Rate and fees** — the non-resident rate premium (typically **~50–150 bp** above domestic owner-occupier) and ongoing fees — one input among several, never the only one.

## How the shortlist is produced — and what it is not

The agent **matches the buyer's situation** (income currency, visa class, deposit, target property) **against these criteria** and surfaces a shortlist of *policy profiles that fit*, each with reasoning ("a lender that accepts AUD-only assessment for a 485 holder and issues FIRB-conditional offers suits this AU-employed temporary-resident buyer"). The shortlist is **decision-support**: it explains the trade-offs so the user — with a licensed broker — chooses. It is explicitly **not**:

- a recommendation of a named lender ("use Lender X");
- a ranking that implies one lender is best for the user;
- a substitute for a broker's whole-of-market assessment.

The plan always closes with "confirm with a licensed mortgage broker," and the figures driving the comparison (capacity, rates, deposit) are resolver-grounded, not asserted by the agent.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The income-currency profile shrinks the fitting set.** A VN-income buyer needs a lender that both accepts foreign income and accepts VND — a narrow subset; the criteria surface this so the buyer sees the financing consequence of the funding structure.
- **The 485-with-AU-income buyer has a much wider set.** Being assessed near-domestic changes which criteria bind; the shortlist reflects that.
- **A broker is the right channel.** The plan points to a broker for the actual selection from the small non-resident panel (whole-of-market, current policy), keeping the platform informational.
- **Information, not credit advice.** The shortlist is reasoning over policy criteria; the user picks (ACL line).

## Rules

Pure-reference (`fills: []`). This is a decision-support doc — it fills no slot; the agent produces the shortlist by reasoning over these criteria against the buyer's situation, and the policy flags below enforce the ACL boundary (criteria + reasoning, user picks, no named recommendation). The rate-premium band is a `CONVENTION`; the boundary flags mirror [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md).

```jsonc
{
  "fills": [],
  "parameters": {
    "shortlist_is_decision_support": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the shortlist surfaces fitting policy profiles + reasoning; it is decision-support, NOT a recommendation." },
    "lender_shortlist_user_picks": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the user selects, with a licensed broker; the plan never selects a lender for the user." },
    "no_named_lender_recommendation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "ACL boundary — the doc owns CRITERIA, not a named/ranked lender list; naming a 'recommended' lender crosses into credit advice (ACL)." },
    "defer_lender_selection_to_broker": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "actual whole-of-market selection from the small non-resident panel is deferred to a licensed mortgage broker — the platform stays informational." },
    "non_resident_rate_premium_bp_low": { "type": "int", "value": 50, "provenance": "CONVENTION", "note": "lower end of the typical non-resident rate premium above domestic owner-occupier." },
    "non_resident_rate_premium_bp_high": { "type": "int", "value": 150, "provenance": "CONVENTION", "note": "upper end of the typical non-resident rate premium; one input among several, never the only criterion." }
  },
  "lookup": {
    "non_resident_friendly_criteria": {
      "note": "the policy levers the agent reasons over to build a fitting-profile shortlist; each detail is owned by a sibling doc (cross-ref), not duplicated here.",
      "entries": [
        { "criterion": "foreign_income_acceptance_and_shading", "owner": "kb.lender.temp-resident-lending-policies" },
        { "criterion": "residency_visa_appetite", "owner": "kb.lender.485-visa-treatment" },
        { "criterion": "deposit_lvr_appetite", "owner": "kb.lender.foreign-buyer-deposit-requirements" },
        { "criterion": "firb_conditional_handling", "owner": "kb.lender.firb-approval-as-condition-precedent" },
        { "criterion": "documentation_capability_non_resident", "owner": "kb.lender.documentation-non-resident" },
        { "criterion": "rate_and_fees", "owner": "kb.lender.temp-resident-lending-policies" }
      ]
    }
  }
}
```

Notes:

- **No `fills`, no named lenders.** The doc owns the *criteria* the agent reasons over; it deliberately holds no lender names or ranking. The shortlist is produced at runtime as fitting *policy profiles* + reasoning, and the user picks.
- **ACL boundary as data.** The four policy flags make the boundary machine-checkable (decision-support, user-picks, no-named-recommendation, defer-to-broker) — the Mode-B mirror of [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md).
- **Criteria reference siblings, not duplicate.** Each criterion's detail is owned by the sibling doc named in the lookup; this doc is the *selection-criteria* layer that composes them.

## Sources

- ASIC — *Credit and finance: Australian credit licence* (credit assistance / recommendation requires an ACL) — https://asic.gov.au/for-finance-professionals/credit-licensees/
- ASIC Moneysmart — *Using a mortgage broker* (broker role; credit assistance is a licensed activity) — https://moneysmart.gov.au/home-loans/using-a-mortgage-broker
- Canstar — *Non-Resident Home Loans in Australia* (restricted lender set, non-resident rate premium, foreign-income criteria) — https://www.canstar.com.au/home-loans/non-resident-home-loans/
