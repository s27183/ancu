---
slug: kb.lender.investor-friendly-shortlist
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Investor-friendly lender shortlist — selection criteria

When an investor needs financing, lenders differ in how well their policy fits an investment strategy. This doc owns the **criteria that make a lender "investor-friendly"** so `mortgage_finance` can produce a **shortlist with reasoning** the user evaluates — it does **not** name or rank specific lenders. The agent applies these criteria to a buyer's situation and surfaces *which kinds of policy* suit it (and why); the **user picks**, with a broker. This is the single most ACL-sensitive doc in the finance cluster: naming a lender as "recommended" crosses from information into **credit advice** (ACL territory; personal liability). The boundary is built into the doc — criteria and reasoning, never a recommendation.

## What "investor-friendly" means — the criteria

A lender's fit for an investor turns on a handful of policy levers (each owned in detail by a sibling doc):

- **Rental-income treatment** — how generously gross rent is counted (the ~80% shading convention, net-rental method, treatment of short-stay income). More generous → higher assessed capacity. (Owned by [`kb.lender.serviceability-investment-loans`](serviceability-investment-loans.md).)
- **Interest-only availability and term** — whether IO is offered, the maximum term, and whether it extends without a full reassessment. (Owned by [`kb.loan.interest-only-vs-pi-investor`](../loan/interest-only-vs-pi-investor.md).)
- **Offset on investment / IO loans** — whether a full offset is available on an IO investment loan (preserves deductibility, cross-ref [`kb.loan.offset-vs-redraw-investor`](../loan/offset-vs-redraw-investor.md)).
- **Portfolio appetite** — tolerance for multiple properties, high aggregate debt, and the DTI cap; whether they accept other lenders' debt at actual vs buffered rate.
- **Entity lending** — whether they lend to trusts, companies, or SMSFs and on what terms. (Owned by [`kb.lender.investment-loan-policies`](investment-loan-policies.md).)
- **Security categories** — apartment/postcode/off-the-plan policy fit for the target property.
- **Rate and fees** — the investment-rate premium and ongoing fees (one input among several, never the only one).

## How the shortlist is produced — and what it is not

The agent **matches the buyer's situation** (strategy, entity, target property category, portfolio size) **against these criteria** and surfaces a shortlist of *policy profiles that fit*, each with the reasoning ("an IO-friendly lender that offsets on investment loans suits this negative-gearing, cash-flow-management strategy"). The shortlist is **decision-support**: it explains the trade-offs so the user — with a licensed broker — chooses. It is explicitly **not**:

- a recommendation of a named lender ("use Lender X");
- a ranking that implies one lender is best for the user;
- a substitute for a broker's whole-of-market assessment.

The plan always closes with "confirm with a licensed mortgage broker," and the figures driving the comparison (capacity, rates) are resolver-grounded, not asserted by the agent.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The entity choice and the lender choice are coupled.** A trust or SMSF strategy shrinks the fitting-lender set — the shortlist criteria surface this so the buyer sees the financing consequence of a tax decision.
- **Cash-flow strategy drives the criteria.** An investor managing cash flow through IO + offset needs a lender whose policy supports both — the criteria make that explicit without naming one.
- **A broker is the right channel.** The plan points to a broker for the actual selection (whole-of-market, current policy), keeping the platform informational.
- **Information, not credit advice.** The shortlist is reasoning over policy criteria; the user picks (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference / decision-support** doc — it fills no slot; the agent produces the shortlist by reasoning over these criteria against the buyer's situation, and the policy flags below enforce the ACL boundary (criteria + reasoning, user picks, no named recommendation).

```jsonc
{
  "fills": [],
  "parameters": {
    "shortlist_is_decision_support":  { "type": "bool", "value": true, "note": "the shortlist surfaces fitting policy profiles + reasoning; it is decision-support, NOT a recommendation" },
    "lender_shortlist_user_picks":    { "type": "bool", "value": true, "note": "the user selects, with a licensed broker; the plan never selects a lender for the user" },
    "no_named_lender_recommendation": { "type": "bool", "value": true, "note": "ACL boundary — the doc owns CRITERIA, not a named/ranked lender list; naming a 'recommended' lender crosses into credit advice (ACL)" },
    "defer_lender_selection_to_broker": { "type": "bool", "value": true, "note": "actual whole-of-market selection is deferred to a licensed mortgage broker — the platform stays informational" }
  },
  "lookup": {
    "investor_friendly_criteria": {
      "note": "the policy levers the agent reasons over to build a fitting-profile shortlist; each detail is owned by a sibling doc (cross-ref), not duplicated here",
      "entries": [
        { "criterion": "rental_income_treatment", "owner": "kb.lender.serviceability-investment-loans" },
        { "criterion": "interest_only_availability_term", "owner": "kb.loan.interest-only-vs-pi-investor" },
        { "criterion": "offset_on_io_investment", "owner": "kb.loan.offset-vs-redraw-investor" },
        { "criterion": "portfolio_appetite_dti", "owner": "kb.lender.serviceability-investment-loans" },
        { "criterion": "entity_lending", "owner": "kb.lender.investment-loan-policies" },
        { "criterion": "security_category_fit", "owner": "kb.lender.investment-loan-policies" },
        { "criterion": "rate_and_fees", "owner": "kb.lender.serviceability-investment-loans" }
      ]
    }
  }
}
```

Notes:

- **No `fills`, no named lenders.** The doc owns the *criteria* the agent reasons over; it deliberately holds no lender names or ranking. The shortlist is produced at runtime as fitting *policy profiles* + reasoning, and the user picks.
- **ACL boundary as data.** The four policy flags make the boundary machine-checkable (decision-support, user-picks, no-named-recommendation, defer-to-broker) — the finance-cluster analog to the entity-comparison doc's ASIC flags.
- **Criteria reference siblings, not duplicate.** Each criterion's detail is owned by the sibling doc named in the lookup; this doc is the *selection-criteria* layer that composes them.

## Sources

- ASIC Moneysmart — *Using a mortgage broker* (broker role; credit assistance is a licensed activity) — https://moneysmart.gov.au/home-loans/using-a-mortgage-broker
- ASIC — *Credit and finance: Australian credit licence* (credit assistance / recommendation requires an ACL) — https://asic.gov.au/for-finance-professionals/credit-licensees/
- ASIC Moneysmart — *Borrowing to invest* (investment-loan considerations) — https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
