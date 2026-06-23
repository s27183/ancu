# Mortgage-finance two-path — `mortgage_finance` resolver-math + agent lender-fit split

**Status:** DONE & verified — `fh_engine_mortgage` (+ turn two-path branch) +
`mortgage_eval.py`/`mortgage_conformance.escript` (15+23 lockstep green), full seam
smoke green with **real opus**: the model authored only the two leaves, `capacity` stayed
`null` (§98 held against a live LLM), a valid enum `rate`, and an FHG-panel-grounded
shortlist with `approval_likelihood: indicative` ("a firm read needs your income and
debts, still to be entered" — honest-partial honored by the model). Design pass below.

**One real-LLM finding (fixed):** the agent's first real run put PROSE into
`fixed_vs_variable` because the field was a bare `str` — the schema didn't constrain it.
The §98 belt-and-braces enum guard caught it (turn_failed, not a bad commit); the durable
fix is a Pydantic `Literal` so the five options land IN the JSON schema and the model must
pick one (reasoning goes in a lender's `reasoning`). Schema-as-constraint, not prompt-as-plea.
**Component:** `mortgage_finance` (component 4, `fhb-domestic-au`), outcome `mortgage_plan`.
**Mechanism:** **TWO-PATH** — the first base-scope component that is neither pure resolver
nor pure agent. Resolver (Erlang) computes/assembles every figure and the loan-path
structure; the agent (sidecar) fills only the two `lender_fit` qualitative leaves; Erlang
merges. Fixes the §98 finding carried from slice 2a (the LLM was authoring
`expected_borrowing_capacity` and the debt-optimisation money figures — a compliance hazard).

This doc fixes two load-bearing things before code: **(1) the two-path composition
mechanism** (how one component runs both paths and assembles a single outcome, the pattern
every future two-path component inherits), and **(2) the base-turn honest-partial boundary**
(income/debts are absent at onboarding → capacity is PENDING, same class as `cash_position`'s
deposit/loan and `ownership_planning`'s P&I). It builds on
[base-turn-honest-partial-output] and [verify-regulated-figures-by-postcondition].

---

## 1. Placement & grounding

| Surface | Binding |
|---|---|
| Blueprint | component 4 `mortgage_finance`, scope `both` (base estimate at onboarding; per-property refine when loan amount known) |
| Outcome | `mortgage_plan` — `{ recommended_path, expected_borrowing_capacity, debt_optimisations_to_action, recommended_lender_shortlist, loan_structure_recommendation, pre_approval_action_plan, pre_approval_expiry, reapplication_required, key_assumptions }` |
| `dag_reads` (engine-passed Upstream) | `["profile", "scheme_stack"]` — i.e. `buyer_profile.outcome` + `eligibility.outcome` (the compiled `dag_reads` is authoritative) |
| Agent leaves (artifact, both `lender_fit`) | `mortgage_finance.lender_synthesis.most_likely_approval_lenders`, `mortgage_finance.loan_structure.fixed_vs_variable` |
| Renderer | `summary-card` (+ `data-table`); fill returns `summary-card` |
| KB anchors | `kb.lender.serviceability-basics` (the 3.0pp APRA buffer + conventions), `kb.lender.fhg-panel-list` (panel facts for the shortlist), `kb.lmi.calculation` (80% threshold + indicative bands), `kb.lender.hecs-treatment-by-lender`, `kb.lender.credit-card-treatment`, `kb.lender.bnpl-treatment-2026` |

**KB-sanctioned split (verified against the live docs, not assumed).**
`serviceability-basics.md`: *"capacity is resolver/agent-computed from these parameters
(formula → code, per §11.9), not asserted"* and *"the only regulated constant is the buffer."*
`fhg-panel-list.md`: *"the per-borrower fit reasoning (rate, HECS treatment, approval
likelihood) is the **agent's**"* and *"`panel_lender_shortlist` … is agent-reasoned."* So the
boundary the artifact draws (2 `lender_fit` leaves agent, the rest resolver) is exactly the
boundary the KB authors drew. The agentic-boundary §98 hazard — *"Sending … borrowing
capacity … through the LLM … a compliance hazard (ASIC: figures must be computed, not
asserted)"* — is what makes capacity resolver, not agent.

---

## 2. The two-path composition mechanism (the engine decision)

Today the turn dispatches **binary**: `agent_leaves == []` → resolver in-process; else →
sidecar fills the *whole* outcome. A two-path component needs *both* paths and one merged
outcome. The chosen mechanism — **resolver-first, agent-second, Erlang merges**:

```
running step, two-path component:
  1. {ResolverOutcome, Renderer, Kb} = fh_engine_fill:resolver(Name, Args, Upstream)
         -- every figure + the loan-path structure; the two agent slots left as `pending`
  2. Port = start_fill_port(Comp, Data, ResolverOutcome)
         -- spawn the disposable sidecar; pass ResolverOutcome as READ-ONLY grounding
  3. park (pending = {two_path, Comp, ResolverOutcome, Renderer, Kb})

on sidecar component_filled (AgentValues = {recommended_lender_shortlist, fixed_vs_variable}):
  4. Final = fh_engine_fill:merge_agent(Name, ResolverOutcome, AgentValues)
         -- the component module folds the two named values into their outcome slots
  5. commit(Comp, fill_path = <<"two_path">>, Renderer, Kb, Final, Data)
```

**Why this and not "sidecar fills then resolver overwrites figures", or "agent returns the
whole outcome and Erlang trusts the figure fields":** the merge is **Erlang-side and
slot-scoped** — the agent's reply is a small typed object carrying *only* the two qualitative
values, so the LLM literally cannot author or overwrite a money figure. That makes the §98
property a **verifiable postcondition at the schema level** (the agent's output schema has no
money field), not an asserted behaviour. It is "prefer verifiable properties over asserted
ones" applied to the compliance boundary.

**The path predicate** (replaces today's binary `is_agent_component`):

| `agent_leaves` | resolver exists (`fh_engine_fill`) | path | `fill_path` |
|---|---|---|---|
| `[]` | yes | **resolver** (in-process, no sidecar, no `usage`) | `resolver` |
| non-empty | yes | **two_path** (resolver figures + agent leaves, Erlang-merged) | `two_path` |
| non-empty | no | **agent** (sidecar fills whole outcome) | `agent` |

In base scope only `mortgage_finance` is two_path (and it *has* a resolver). The pure-`agent`
row is the per-property valuation/negotiation/document components (later) — kept in the table
so the predicate is total, not a special-case.

**Generality.** The mechanism is the pattern for every future two-path component (Mode-C
investor `mortgage_finance` has 5 `lender_fit` leaves; `property_assessment` valuation;
`buying_strategy` negotiation). Each component module owns its `merge_agent/2` (it knows its
own outcome shape); the turn loop stays generic — it dispatches by the path predicate and
calls `fh_engine_fill:{resolver,merge_agent}` symmetrically.

---

## 3. The base-turn honest-partial boundary (the figure decision)

Serviceability is `capacity = f(assessable income, committed debts, buffered rate)`. At the
onboarding turn `buyer_profile` leaves **income and debts ABSENT** (its outcome carries
citizenship/age/ownership + `key_constraints: ["… income, savings, debts pending …"]`). With
the dominant inputs absent, **borrowing capacity is PENDING** — the same honest-partial call
as `ownership_planning`'s P&I (no firm loan/rate) and `cash_position`'s deposit/loan. The
resolver does **not** invent it.

| Outcome element | Base turn | Source / why |
|---|---|---|
| `expected_borrowing_capacity` | **PENDING** `null` | income/debts absent — and §98: never LLM-authored. The clean slot. |
| `debt_optimisations_to_action` | **PENDING** `[]` | needs the debt balances (HECS/cards/BNPL) — absent at base. |
| `recommended_path` | **DETERMINATE** `fhg_backed` if FHG in `scheme_stack` | read from `eligibility.scheme_stack` (FHG = `role: deposit_guarantee`); else `null` pending deposit %. |
| `loan_structure_recommendation.type` | **DETERMINATE** `principal_and_interest` | Mode-A FHB default (blueprint `value` constant, not `<initial>`). |
| `loan_structure_recommendation.rate` | **AGENT** (`fixed_vs_variable`) | `lender_fit` leaf — rate-environment read, indicative. |
| `recommended_lender_shortlist` | **AGENT** (`most_likely_approval_lenders`) | `lender_fit` leaf — FHG panel + target range + state, indicative; `approval_likelihood` flagged pending-serviceability. |
| `pre_approval_action_plan` | **DETERMINATE** | KB document list (serviceability docs required) — generic checklist. |
| `pre_approval_expiry` / `reapplication_required` | `null` / `false` | F11 — null until pre-approval granted (refine/event). |
| `key_assumptions` | **STAMPED** | the 3.0pp APRA buffer (regulated); income-shading ~80%, genuine-savings 5%/3mo, ≈6× DTI (conventions, flagged); "capacity confirms once income + debts entered." |

So the base output is real and honest: **the loan-path structure + FHG applicability + a P&I
default + an indicative FHG-panel shortlist + a rate read**, with capacity and the
debt-optimisation figures explicitly PENDING — never asserted from absent data. The capacity
*formula* itself (buffer-assessed) is a refine-turn concern (when income arrives); §98 then
keeps it resolver-computed. Its full define-simulate-document spec lives in
[`borrowing-capacity-computation.md`](borrowing-capacity-computation.md).

---

## 4. The agent's contract (the §98 enforcement)

The sidecar receives, in `fill_component.params`: `upstream` (the `dag_reads` outcomes:
`profile` + `scheme_stack`) **and** `resolver_outcome` (the figures + structure, READ-ONLY
grounding so the lender reasoning is grounded in the real path/FHG facts). It returns a small
typed object — **the only thing it authors**:

```jsonc
{ "recommended_lender_shortlist": [ { "lender", "reasoning", "approval_likelihood" } ],
  "fixed_vs_variable": "variable" | "fixed_1yr" | "fixed_2yr" | "fixed_3yr" | "split_fixed_variable" }
```

No money field exists in this schema → the LLM cannot author a figure (the §98 postcondition,
verifiable). The `lender_fit` system-prompt module changes accordingly: **delete** the
"compute borrowing capacity from the buffer" instruction (that is resolver now); **add** "the
capacity/path figures are computed for you in `<resolver_outcome>`; reason about lender FIT
and rate structure given those + the scheme stack; at base, income/debts are pending, so the
shortlist is the FHG panel relevant to the target range/state, flagged indicative — never
invent an approval outcome." Output schema = the two-leaf object.

---

## 5. Composition contract (field ← source)

```
recommended_path                = scheme_stack has FHG ? "fhg_backed" : null      ← eligibility
expected_borrowing_capacity     = null                                            (PENDING: income absent; §98)
debt_optimisations_to_action    = []                                              (PENDING: debts absent)
recommended_lender_shortlist    = «agent»  most_likely_approval_lenders           ← AGENT (FHG panel + target + state)
loan_structure_recommendation   = { type: "principal_and_interest",               ← resolver (Mode-A default)
                                    rate: «agent» fixed_vs_variable,               ← AGENT
                                    offset: null }                                 (PENDING)
pre_approval_action_plan        = [ KB document checklist ]                        ← serviceability KB
pre_approval_expiry             = null ; reapplication_required = false            (F11)
key_assumptions                 = [ "APRA buffer 3.0pp (regulated)", conventions, "capacity pending income+debts" ]
```

The only numeric constant in code is the KB-sourced APRA buffer label; every figure that
*would* be computed (capacity, LMI, uplift) is PENDING at base, so there is no base-turn
arithmetic to verify here — the verification target is **structural** (§6).

---

## 6. Verification discipline

Unlike `cash_position` (kind-1 regulated figures vs the official calculator) and
`ownership_planning` (kind-2 KB estimates vs the KB SOT), the base-turn `mortgage_finance`
produces **no computed figure** (all PENDING). So the conformance target is the **two-path
mechanism + the honest-partial structure**, asserted by postcondition:

- **§98 postcondition (the headline):** the agent's output schema contains **no money/number
  field**; `expected_borrowing_capacity` in the committed outcome is `null` (PENDING), never a
  value the LLM produced. Assert in the escript end-to-end (resolver-only path, no sidecar) +
  by inspecting the agent Pydantic model's fields.
- **Structural conformance (py + escript lockstep):** `recommended_path = fhg_backed` iff FHG
  in `scheme_stack`; `loan_structure_recommendation.type = principal_and_interest`;
  `expected_borrowing_capacity = null`; `debt_optimisations_to_action = []`; the agent slots
  are present-and-pending in the resolver outcome and replaced by `merge_agent/2`.
- **Merge conformance:** `merge_agent(mortgage_finance, ResolverOutcome, AgentValues)` places
  the shortlist into `recommended_lender_shortlist` and `fixed_vs_variable` into
  `loan_structure_recommendation.rate`, touching nothing else (assert the figure fields are
  byte-identical pre/post merge — the merge cannot move a figure).
- **Full seam smoke:** real-opus two-path run — `turn_started → … → component_filled
  (mortgage_finance, fill_path: two_path) → … → turn_completed`; assert the committed
  `mortgage_plan` has the agent shortlist + rate AND capacity `null`.

The py spec reads `artifact.json`; the escript calls the module → both locked to the structure
and each other (the cash/ownership shape).

---

## 7. Surfaced seams (flag, don't silently resolve)

- **(a) `is_agent_component` → three-way path predicate.** The turn's binary dispatch is
  replaced by the §2 table. The pure-`agent` branch (sidecar fills whole outcome) stays for
  the later per-property components; no base component uses it now. Engine change, scoped.
- **(b) `fill_component` gains `resolver_outcome`.** The sidecar protocol grows one param
  (read-only grounding). `planner_stub.py` must accept-and-ignore it to stay green
  (it already canned-fills); update it alongside `planner.py`.
- **(c) Slice-2a `MortgageFinanceOutcome` Pydantic model is retired.** The agent no longer
  produces the whole outcome — only the two leaves. The full-outcome model (with its money
  fields) is exactly the §98 surface being removed; replace with the two-leaf model.

---

## 8. Code shape & build plan

1. `engine/erlang/src/fh_engine_mortgage.erl` — `fill(Args, Upstream) -> {ResolverOutcome,
   <<"summary-card">>, KbVersions}` (the §5 structure, agent slots `pending`); `merge_agent(ResolverOutcome, AgentValues) -> Final`.
2. `engine/erlang/src/fh_engine_fill.erl` — add `resolver(<<"mortgage_finance">>, …)` →
   `fh_engine_mortgage:fill/2`; add `merge_agent/3` dispatch + `has_resolver/1`.
3. `engine/erlang/src/fh_engine_turn.erl` — replace `is_agent_component` with the three-way
   path predicate; add the two-path branch (resolver-first → spawn with `resolver_outcome` →
   merge on reply, `fill_path: two_path`); thread `ResolverOutcome` through `start_fill_port`
   and `pending`.
4. `engine/python/planner.py` — two-leaf `LenderFitLeaves` model; `fill_component` reads
   `resolver_outcome`; rewrite the `lender_fit` prompt module (capacity is given, fill the two
   leaves); return the two values.
5. `engine/python/planner_stub.py` — accept-and-ignore `resolver_outcome`; canned two-leaf reply.
6. `tests/mortgage_eval.py` + `engine/erlang/test/mortgage_conformance.escript` — §6 structural
   + merge + §98 postconditions, lockstep.
7. Recompile artifact (no change expected — agent_leaves already emitted), run resolver +
   cash-duty + ownership + mortgage conformance, full seam smoke (NSW $700k, FHG-eligible).

## 9. Boundaries (refine-turn / per-property — explicitly NOT base)

The buffer-assessed capacity formula (when income arrives — now specified in
[`borrowing-capacity-computation.md`](borrowing-capacity-computation.md)); the debt-optimisation uplifts
(when HECS/card/BNPL balances arrive); LMI-payable estimates and the FHG-vs-LMI cash crossover
(when loan amount known); `offset_strategy`; the F11 pre-approval dates. Each fills when its
facts arrive — never asserted at base. §98 keeps capacity resolver-computed at every turn.

---

**Sources.** KB: the six anchors in §1 (`docs/kb/...`). Upstream contract:
[`fh_engine_turn.erl`](../../engine/erlang/src/fh_engine_turn.erl) (`upstream_for`/`dag_reads`),
the compiled `agent_leaves`. Compliance: agentic-boundary §98. Pattern:
[stamp-duty-concession-mechanics.md](stamp-duty-concession-mechanics.md),
[ongoing-costs-projection.md](ongoing-costs-projection.md),
[base-turn-honest-partial-output], [verify-regulated-figures-by-postcondition].
