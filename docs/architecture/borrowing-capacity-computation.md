# Borrowing-capacity computation (mortgage_finance, mechanism B)

**Status:** define → simulate (the IC0 worked example reproduced to the dollar) → document. The code and KB already encode this (IC1–IC2); this doc is the standalone spec of the regulated core, the third leg of the define-simulate-document discipline — the companion to [`stamp-duty-concession-mechanics.md`](stamp-duty-concession-mechanics.md) (the `cash_position` resolver) and [`ongoing-costs-projection.md`](ongoing-costs-projection.md) (the holding-cost resolver).

This doc owns the **arithmetic** that fills `mortgage_finance.expected_borrowing_capacity` — the single figure that gates the entire full-horizon chain: `disposition.full_horizon_net_position ← net_proceeds ← loan_payout ← expected_borrowing_capacity`. It is the resolver half of a **two-path** component; the agent half (qualitative lender fit) is owned by [`mortgage-finance-two-path.md`](mortgage-finance-two-path.md), which defers the formula to here.

> **Regulated figure.** Capacity is a number a Mode-A buyer will plan their whole purchase against, and it is the sharpest ASIC surface in the base plan (no credit advice without an ACL — CLAUDE.md hard constraints). It is **resolver-computed and removed from the LLM's reach** ([agentic-boundary §98](agentic-boundary.md)). The correctness criterion is the same as its siblings: the verifiable inputs (the 2025-26 tax schedule, the Medicare levy, the APRA buffer, the HECS schedule) reproduce the official figures to the dollar; the genuinely-unsourced inputs (the HEM living-expenses band, the credit-card repayment band) are **labelled conventions**, and the output **band** is their surfaced uncertainty — never averaged away into a false point ([[verify-regulated-figures-by-postcondition]]).

---

## 1. Placement — what fills this leaf, and how

**Blueprint.** Component 4, `mortgage_finance` (`scope: both`), in [`blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md). The leaf this doc owns, from its outcome schema:

```
expected_borrowing_capacity : money_range | null   — banded; null until income is known
```

**Inputs.** Read from the **`profile` outcome** (the flat projection of `facts_jsonb.household_financials`, [fact-model-unification.md §97](fact-model-unification.md)), never from `mortgage_finance`'s own params (CLAUDE.md: profile holds facts, mortgage reasons about facts):

```
profile.assessable_income            : money         — shaded combined household income
profile.debts.hecs_balance           : money
profile.debts.credit_card_limits_total : money
profile.debts.personal_loans_balance : money
profile.debts.car_loan_balance       : money
profile.debts.buy_now_pay_later_balance : money
```

**KB anchors** (declared on the component): `kb.lender.serviceability-basics` (the APRA buffer + the rate/term/consumer-loan conventions), `kb.tax.income-tax-resident-2025-26` (the marginal schedule + Medicare), `kb.hecs.thresholds` (the income-contingent repayment schedule), `kb.lender.hem-living-expenses` (the placeholder living-expenses band), `kb.lender.credit-card-treatment` (the card-limit repayment band).

**Workflow.** `mortgage_finance` has a non-empty `agent_leaves` (the `lender_fit` leaf), so it is a **two-path** component. The resolver half — this computation — runs in-process on **every base-DAG walk** (`fh_engine_fill:resolver(<<"mortgage_finance">>, …)` → `fh_engine_mortgage:fill/2`), independent of whether the agent leaf is sourced from the sidecar (a `base` turn), a stored snapshot (a `base_resolver` refresh), or absent. This is the **resolver-half-always-fresh** invariant established in IC6 ([[preview-is-commit-minus-persistence]]): a §98 figure must equal `f(current facts)` at every turn kind; only the agent-leaf *source* varies.

**Which resolver mechanism.** The resolver is two mechanisms ([agentic-boundary §40/§98](agentic-boundary.md)): **(A)** the declarative rule interpreter for `content_json` criteria/lookup/parameter fills, and **(B)** per-component **formula code** for arithmetic the declarative kinds can't express. Capacity is **mechanism B**: progressive tax brackets, an income-contingent HECS schedule, a present-value annuity inversion, and a DTI cap — none expressible as `criteria` (bools) or a flat `lookup`. The KB supplies the data; `fh_engine_mortgage` supplies the arithmetic.

---

## 2. The computation

```
capacity = clamp0( min( surplus_monthly × PV_annuity(assessment_rate, term),  DTI_ceiling ) )

net_annual     = income − income_tax(income) − medicare_levy(income)        [HECS NOT here]
surplus_monthly = net_annual/12 − HEM − HECS_monthly − card_monthly − other_loan_monthly
assessment_rate = representative_product_rate_pct + apra_serviceability_buffer_pp
PV_annuity(r,N) = (1 − (1 + r/12)^(−N×12)) / (r/12)
DTI_ceiling     = high_dti_threshold × income − existing_consumer_balances
```

Component definitions, each from the live resolver (`fh_engine_mortgage.erl`):

| Term | Definition | Source |
|---|---|---|
| `income_tax(I)` | 2025-26 resident marginal schedule: `base_amount + marginal_rate% × (I − marginal_over)` for the band | `kb.tax` lookup |
| `medicare_levy(I)` | `I × 2%` | `kb.tax` param (regulated) |
| `HECS_monthly` | `hecs_repayment(income)/12` **only if** `hecs_balance > 0` (the drag scales with income, not balance); income-contingent marginal bands, 10%-flat top band | `kb.hecs` lookup |
| `card_monthly` | banded: `credit_card_limits_total × {3.0%, 3.8%}` — assessed on the **limit**, not the balance | `kb.lender.credit-card-treatment` |
| `other_loan_monthly` | `(personal + car + BNPL balances) × 2.5%` | `kb.lender.serviceability-basics` |
| `HEM` | banded: `{$1,800, $2,600}/mo` — **placeholder**, not source-grounded | `kb.lender.hem-living-expenses` |
| `assessment_rate` | `6.0% + 3.0pp = 9.0%` | `kb.lender.serviceability-basics` |
| `term` | 30 years | `kb.lender.serviceability-basics` |
| `DTI_ceiling` | `6 × income − (card limit + personal + car + BNPL)`; HECS excluded (income-contingent, not a balance-debt) | `kb.lender.serviceability-basics` |

Two seams worth stating explicitly, because both are easy to get wrong:

- **HECS is counted once, in the surplus — not in `net_annual` and not in the DTI ceiling.** It is an income-contingent commitment (a monthly drag on serviceability), not a balance-debt. Subtracting it from `net_annual` *and* the surplus would double-count it; including it in the DTI ceiling would mis-model it as a hard balance.
- **The assessment rate carries the APRA buffer; the disposition amortisation rate does not.** Capacity is *assessed* at the stressed `6.0% + 3.0pp = 9.0%` (how much a lender will advance under APRA's stress test). But `disposition.loan_payout` amortises the *actual* loan at the bare `6.0%` representative rate **without** the buffer (IC6 seam B) — because the buffer is a stress overlay for "can you service it", not the rate you actually pay. Same KB doc, two rates, two purposes. Don't unify them.

---

## 3. Verifiable vs labelled-convention — the input split

The discipline ([[verify-regulated-figures-by-postcondition]]): verify what's verifiable to the dollar, label the rest, and let the **band width** *be* the honesty about the unsourced half.

| Input | Kind | Ground truth |
|---|---|---|
| 2025-26 resident tax schedule | **Verifiable** | ATO schedule (web-corroborated; ATO bot-walls direct fetch) — `base_amount` $4,288 / $31,288 / $51,638 |
| Medicare levy 2% | **Verifiable / regulated** | ATO |
| APRA serviceability buffer 3.0pp | **Verifiable / regulated** | APRA (set 6 Oct 2021, reaffirmed Nov 2025) — the one hard regulatory constant; it sets capacity |
| HECS income-contingent schedule | **Verifiable** | `kb.hecs.thresholds` (2025-26 marginal bands) |
| DTI threshold 6× | **Convention** (macroprudential guidance) | APRA high-DTI flag; a conservative cap, not a hard limit |
| Representative product rate 6.0% | **Convention** (labelled) | re-groundable; a representative owner-occupier variable rate |
| Consumer-loan 2.5%-of-balance | **Convention** (labelled) | conservative; over-stating a commitment under-states capacity (the safe direction) |
| Credit-card 3.0–3.8%-of-limit | **Convention** (labelled, banded) | lender-specific |
| **HEM $1,800–$2,600/mo** | **PLACEHOLDER** (not source-grounded) | none — no public HEM series; the labelled-placeholder shape ([[kb-doc-authoring]]) |

The band is driven by the two banded conventions (HEM, card). The placeholder HEM is the dominant width contributor and the named re-grounding obligation.

---

## 4. The worked simulation — IC0, reproduced to the dollar

Fixture: **$95,000 assessable income, $20,000 HECS balance, $10,000 card limit**, no other debts.

```
income_tax(95,000)   = 19,288       (30% band: 4,288 + 30% × (95,000 − 45,000))
medicare(95,000)     =  1,900       (2% × 95,000)
net_annual           = 95,000 − 19,288 − 1,900 = 73,812
net_monthly          = 73,812 / 12  = 6,151.00

HECS_monthly         = hecs_repayment(95,000)/12 = 4,200/12 = 350.00   (balance > 0)
card_monthly (lo→hi) = 10,000 × {3.0%, 3.8%} = {300.00, 380.00}
other_loan_monthly   = 0
HEM (lo→hi)          = {1,800, 2,600}

surplus_hi (UPPER cap) = 6,151 − 1,800 − 350 − 300 − 0 = 3,701.00   (low expenses + low card)
surplus_lo (LOWER cap) = 6,151 − 2,600 − 350 − 380 − 0 = 2,821.00   (high expenses + high card)

PV_annuity(9.0%, 30yr) = (1 − 1.0075^−360) / 0.0075 = 124.28193

cap_hi = min(3,701.00 × 124.28193, DTI) = min(459,967, 560,000) = 459,967
cap_lo = min(2,821.00 × 124.28193, DTI) = min(350,599, 560,000) = 350,599
DTI    = 6 × 95,000 − 10,000 = 560,000   (not binding here)

expected_borrowing_capacity = [350,599, 459,967]
```

This is the IC0 anchor. It and four others (no-debt, below-HECS-threshold, top-tax-band, honest-partial null) are encoded as re-checkable postconditions in [`serviceability_conformance.escript`](../../engine/erlang/test/serviceability_conformance.escript) (22 anchors), with tax and HECS pinned to the dollar at the band boundaries.

---

## 5. Band semantics — why low inputs give the upper bound

The band is not a measurement error to average; it is the surfaced uncertainty of the placeholder/convention inputs. The mapping is deliberate and runs *opposite* to intuition:

- **Low** HEM + **low** card repayment → **maximum** surplus → **upper** capacity bound.
- **High** HEM + **high** card repayment → **minimum** surplus → **lower** (conservative) capacity bound.

So a wider band means *more* uncertainty about living expenses, and the lower end is the conservative figure a buyer should anchor on. Both ends are clamped at 0 (a negative surplus → 0 capacity, honest) and capped at the DTI ceiling.

---

## 6. The §98 postcondition — zero LLM in the lineage

Capacity is removed from the LLM's reach, and that is a **structural** property, not a behaviour checked after the fact:

1. The agent's `lender_fit` leaf **output schema carries no money/number field** — it produces qualitative lender fit only. `merge_agent/2` folds the leaf into the resolver outcome slot-scoped; capacity is byte-identical pre/post merge.
2. The resolver reads only `profile` facts + KB params — no agent value enters the computation.
3. The inverse, surfaced in IC6 seam B: a downstream consumer must not read an agent leaf *as an input* either. `disposition.loan_payout` now amortises at the KB representative rate, never `loan_structure_recommendation.rate` (which holds the agent's rate-**structure** enum). So `full_horizon_net_position` also has zero LLM in its lineage ([[verify-regulated-figures-by-postcondition]] — audit the whole lineage, not just the figure's slot).

"No LLM authored, and no LLM input upstream" is the verifiable postcondition.

---

## 7. Honest-partial contract

`expected_borrowing_capacity = null` whenever `assessable_income` is null, absent, or `≤ 0`. Income arrives only on a refine turn (IC3–IC5: the Budget-cockpit income/debts fields → `/profile` write → `base_resolver` recompute), never at onboarding. So:

- **At base / onboarding:** capacity is `null` (PENDING), in the same honest-partial class as `cash_position`'s figures before facts arrive ([[base-turn-honest-partial-output]]). The downstream `loan_payout` and `full_horizon_net_position` degrade to `null` too — the "Chưa có" state IC6 closed *once income is entered*, not before.
- **Debts absent but income present:** debts default to empty → capacity computes from income alone (the no-debt anchor `[441,325, 540,750]` for $95k). Missing debts only ever *raise* capacity, so this is the honest upper-leaning case, not a fabrication.

Never assert capacity from absent income. The band is the uncertainty of the *conventions*, not a stand-in for missing *facts*.

---

## 8. Boundaries (what this explicitly does **not** cover)

- **Lender-specific policy.** This is a representative assessment, not any one lender's serviceability calculator. The agent's `lender_fit` leaf surfaces *which* lenders are plausible; it never overrides this figure.
- **LMI, the deposit/LVR path, and the recommended financing lane** — owned elsewhere in `mortgage_finance` (`recommended_path`, `kb.lmi.calculation`); this doc is only `expected_borrowing_capacity`.
- **Two-earner income splitting** — the engine fact is a single `assessable_income`; any per-earner UX summing is an IC5 cockpit concern, not an engine input.
- **Foreign-sourced income shading** — `foreign_sourced_income_component` is carried on the profile but not yet differentially shaded here (Mode-A domestic is the wedge); a Mode-B/D refinement.
- **The disposition amortisation** (loan payout at the bare 6.0%) — owned by `fh_engine_disposition`; see §2's second seam and IC6.

---

## 9. Code shape & verification

- **Module:** [`fh_engine_mortgage.erl`](../../engine/erlang/src/fh_engine_mortgage.erl) — `borrowing_capacity/1` (the band), `income_tax/1`, `hecs_repayment/1`, `net_annual_income/1` exported for conformance; `capacity_band/2`, `pv_factor/0`, `dti_ceiling/2` internal.
- **KB data:** `kb.lender.serviceability-basics`, `kb.tax.income-tax-resident-2025-26`, `kb.hecs.thresholds`, `kb.lender.hem-living-expenses`, `kb.lender.credit-card-treatment` — all compiled into `artifact.json` (the `persistent_term` boot input).
- **Verification:** [`serviceability_conformance.escript`](../../engine/erlang/test/serviceability_conformance.escript) (22 anchors — tax/HECS to the dollar, the IC0 band exactly, honest-partial null, ordering/clamp/monotonicity/DTI bound). The full-horizon link is guarded end-to-end by [`full_horizon_integration.escript`](../../engine/erlang/test/full_horizon_integration.escript) (income set ⟹ capacity → loan_payout → net → full all non-null/banded/ordered; income absent ⟹ all null).

---

## Sources (primary)

- **ATO** — 2025-26 resident income-tax rates; Medicare levy 2%. (ATO bot-walls direct fetch; web-corroborated across secondary sources and cited in `kb.tax.income-tax-resident-2025-26`.)
- **APRA** — serviceability buffer 3.0pp (set 6 Oct 2021, reaffirmed Nov 2025); high-DTI (≥6×) macroprudential guidance.
- **ATO / StudyAssist** — HECS-HELP 2025-26 income-contingent repayment schedule (`kb.hecs.thresholds`).
- HEM band, representative product rate, consumer-loan and credit-card repayment percentages are **labelled conventions / a placeholder** — see the `note` fields in their KB docs and §3 above.
