---
slug: kb.vietnamese-family.financial-patterns
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Vietnamese family financial patterns — how a cross-border purchase is funded, and where the pattern collides with the lender

This doc owns the **behavioural funding-pattern set** for a Vietnamese diaspora property purchase (Mode B — an AU-side buyer funded in whole or part from Vietnam). It grounds `family_context` (component 2) `contributors.*` (the `contribution_source` enums and `documentation_readiness`), `totals.*` (the AU/VN split), and the derived `funding_complexity_score` / `documentation_gaps` on the `family_funding_plan` outcome.

It supplies **vocabulary and prompts, never a prediction about this family.** The patterns below map onto the parameter enums so the plan can *offer the right options and ask the right questions*; the actual amounts, sources and split come from user input, and the plan must never assert that a given family pools funds, gifts, or expects repayment. A pattern is a prompt, not a forecast (honest-partial).

## The funding patterns (→ the `contribution_source` enums)

The common ways a Vietnamese family assembles the money map directly onto the component's source enums:

- **Parental gift from Vietnam** (`savings_vn`, `sale_of_asset`) — a parent draws on VND savings or sells a Vietnam asset (often property or land) to fund the AU child's deposit. The single largest cross-border leg.
- **Family pool** (`family_pool`) — several relatives (parents, aunts/uncles, siblings) each contribute; the "deposit" is an aggregate of many small transfers, sometimes across several people and accounts.
- **Repayable intra-family contribution** (`loan_from_au_member_to_be_repaid`, and its inverse — a VN contribution the child intends to repay) — money advanced with a cultural expectation of eventual repayment, but rarely documented as a formal loan.
- **AU-side savings** (`personal_savings_au`, `income_from_au`) — the AU member's own genuine savings, the one leg that behaves like a domestic purchase.

The plan surfaces these as selectable sources and computes the AU/VN split (`totals.au_side_percentage` / `vn_side_percentage`) from what the family enters — it does not assume a split.

## The load-bearing collision: the "family pool / repayable" pattern vs the lender's genuine-gift requirement

The pattern that most often breaks a plan is the **informal, repayable family contribution.** Culturally, a large family advance may carry an unspoken expectation of repayment (or of a reciprocal obligation) without ever being written down. But a lender reads any **repayable** contribution as a **loan, not a gift** — a borrowed deposit that fails the genuine-savings test and is added back as a liability in serviceability. The same money can therefore fund the purchase yet sink the loan.

This doc owns only the **cultural-pattern → funding-plan consequence** (that an informal repayable pool is likely, and must be clarified early). It does **not** restate the regulated handling, which is single-owned:

- **Genuine-gift-not-loan / source-of-funds evidence** → [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) (the two-leg paper trail; repayable = a borrowed deposit).
- **The genuine-gift letter anatomy** → [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md) (the genuine-gift clause is the decisive, most-rejected element).
- **The lender genuine-savings / cash-reserve gate** → [`kb.cash-reserve.lender-expectations`](../cash-reserve/lender-expectations.md) (the 1% rule; a gift that landed <3 months ago is excluded from genuine savings).
- **Moving the money out of Vietnam** → `kb.vn-capital-controls.*` (SBV outbound thresholds / declared purpose — labelled placeholders, VN-side regulated content pending).

So the plan's job here is to **detect the pattern and route it to the right regulated owner** — flag "is this a gift or a loan?" as a `documentation_gap` and drive the family to document it as a genuine gift *before* the funds move, not to give a structuring recommendation.

## What drives `funding_complexity_score` and `documentation_gaps`

The behavioural facts that raise complexity (surfaced, resolver-scored — never LLM-invented):

- **More contributors, more accounts, more countries** — a many-relative family pool is harder to evidence than a single parental gift.
- **A repayable / ambiguous contribution** — the gift-vs-loan question unresolved.
- **Documentation not started** (`documentation_readiness = not_started`) on the VN leg — the under-evidenced pinch point (the parent's *origin* of funds, not just the transfer record).
- **Currency-origin spread** (`contribution_currency_origin = mixed` / `VND`) — a VND leg carries the cross-border transfer + FX cost and the SBV outbound step.

Each gap is a *prompt to act*, keyed to the regulated owner above — not a verdict on the family.

## Relevance for the Vietnam-parent-funded buyer (Mode B)

- **The money exists; the paperwork is the risk.** The Vietnamese family funding pattern usually makes the *deposit* achievable — the failure mode is evidentiary (source-of-funds, gift-vs-loan, VN outbound), not capacity. Surface that inversion early.
- **Prompt, don't profile.** The plan offers the pooling/gift/loan options and asks the family to specify — it never states that "Vietnamese families do X."
- **Information, not advice.** The plan names the patterns, flags the gift-vs-loan question, and points to the regulated owners (AML source-of-funds, the letter template, the lender gate, VN capital controls) — it never recommends how to structure family money.

## Rules

Pure-reference (`fills: []`). `family_context` reasons over these behavioural patterns to select the offered `contribution_source` options, prompt the gift-vs-loan clarification, and drive `funding_complexity_score` / `documentation_gaps` — each gap cross-referenced to its regulated owner. All parameters are `CONVENTION` (behavioural pattern), surfaced as decision-support prompts; the regulated consequences are owned elsewhere and only pointed to.

```jsonc
{
  "fills": [],
  "parameters": {
    "funding_patterns_are_prompts_not_predictions": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the patterns map to the contribution_source options and prompt the family; the plan never asserts a given family pools/gifts/expects repayment — amounts and split come from user input (honest-partial)." },
    "repayable_family_contribution_reads_as_a_loan": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the load-bearing collision — an informal repayable family pool reads to a lender as a borrowed deposit (fails genuine savings, added as a liability); the gift-vs-loan question is a documentation_gap. Regulated handling owned by kb.au-aml-ctf.source-of-funds-documentation / kb.cash-reserve.lender-expectations, not restated here." },
    "vn_leg_origin_is_the_under_evidenced_pinch_point": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the parent's ORIGIN of funds (not just the transfer record) is the hardest leg to evidence; documentation_readiness=not_started on the VN side is the top complexity driver. Evidence standards owned by kb.au-aml-ctf.source-of-funds-documentation." },
    "many_contributor_pool_raises_complexity": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "more contributors / accounts / countries raises funding_complexity_score and the evidentiary burden — a many-relative pool is harder to document than a single parental gift." },
    "deposit_achievable_paperwork_is_the_risk": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the Vietnamese family funding pattern usually makes the deposit achievable; the failure mode is evidentiary (source-of-funds / gift-vs-loan / VN outbound), not capacity — surface the inversion early." }
  }
}
```

Notes:

- **No `fills`; a behavioural-pattern doc.** It owns the *funding-pattern → funding-plan consequence*; the regulated handling of the money is single-owned elsewhere (AML source-of-funds, the gift letter, the lender gate, VN capital controls) and cross-referenced, never restated.
- **Patterns are prompts.** Every parameter is a decision-support prompt the plan surfaces to the family, not an assertion about the family — the honest-partial discipline applied to cultural behaviour.
- **The gift-vs-loan question is the keeper.** The one pattern that most often breaks a plan (a repayable pool read as a borrowed deposit) is lifted to a parameter and routed to its regulated owner.

## Sources

Behavioural / reference doc — no regulator publishes family funding patterns. The regulated consequences each patterns triggers are sourced in their single owners:

- [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) — source-of-funds evidence standards, genuine-gift-not-loan (AUSTRAC-anchored).
- [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md) — the genuine-gift letter anatomy.
- [`kb.cash-reserve.lender-expectations`](../cash-reserve/lender-expectations.md) — genuine savings / the 1% rule (APRA APG 223).
