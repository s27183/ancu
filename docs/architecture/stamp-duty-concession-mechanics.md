# Stamp-duty concession mechanics (cash_position, mechanism B)

**Status:** design pass — define → simulate (verified against the official calculators) → document. Awaiting sign-off before encoding the KB tables + the Erlang formula code.

This doc owns the **arithmetic** that composes a state's statutory transfer-duty scale with its first-home concession into the three `cash_position.stamp_duty.*` leaves. It is the `cash_position`-side companion to [`eligibility-resolution.md`](eligibility-resolution.md) (which decides *whether* a concession applies) and [`resolver-semantics.md`](resolver-semantics.md) (three-valued partial-knowledge resolution). Where eligibility answers **"which scheme, and is the buyer in the band?"**, this doc answers **"what dollar duty, before and after, and what saving?"**

> **Regulated figures.** These are transfer-duty numbers a Mode-A buyer will budget against. Getting them wrong is real harm (CLAUDE.md hard constraints: ASIC decision-support line; "information, not advice"). Every formula below is **verified by postcondition** — it reproduces the relevant state revenue office's own calculator output to the dollar at named anchor points. That reproduction *is* the correctness criterion (the "prefer verifiable properties over asserted ones" principle), not the algebra in isolation.

---

## 1. Placement — what fills these leaves, and how

**Blueprint.** Component 5, `cash_position` (`scope: both`), in [`blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md). The three leaves this doc owns, from its §11.9 parameter block:

```
stamp_duty.before_concession   : money   — duty otherwise payable (no first-home benefit)
stamp_duty.concession_applied  : money   — the dollar saving (before − after)
stamp_duty.after_concession    : money   — duty actually payable
```

**KB anchors** (already declared on the component): `kb.stamp-duty.calc-by-state` (the statutory base scales) + the eligible scheme doc (`kb.scheme.nsw.fhbas` / `kb.scheme.vic.fhb-duty` / `kb.scheme.qld.fhc`).

**Workflow.** `cash_position` has **empty `agent_leaves`** → it is a **resolver** component: `fh_engine_turn` fills it in-process during the base-DAG walk (`fill_path: resolver`, no sidecar, no `usage`), via `fh_engine_fill:resolver(<<"cash_position">>, Args, Upstream)`. Today that dispatch returns a `_provisional` placeholder; this design replaces it with a real fill in a new `fh_engine_cash` module (mirroring how `eligibility` got `fh_engine_eligibility`).

**Which resolver mechanism.** The resolver is two mechanisms ([agentic-boundary §40/§98](agentic-boundary.md); [[engine-seam-build-discipline]]): **(A)** the declarative rule interpreter (`fh_engine_resolver`) for `content_json` criteria/lookup/parameter fills, and **(B)** per-component **formula code** for arithmetic the declarative kinds can't express. Duty is **mechanism B**: progressive marginal brackets with per-$100 rounding, a flat-on-total quirk, a second concessional scale, and three structurally different taper shapes — none expressible as `criteria` (which yield bools) or a flat `lookup`. This is exactly the boundary `calc-by-state.md` already names: *"the doc supplies the bracket coefficients; the arithmetic is resolver code."*

---

## 2. The composition contract

For a dutiable value `V` (every state: the greater of price or market value) and the buyer's state:

```
before_concession  = standard_duty(V, state)                  ── owned by calc-by-state.md
after_concession   = concessional_duty(V, state)              ── this doc's per-state function
concession_applied = before_concession − after_concession     ── the saving
```

**Single-owner discipline** (who supplies which datum):

| Datum | Owner | Status |
|---|---|---|
| Statutory base scales (NSW standard, VIC general/PPR, QLD standard) | `kb.stamp-duty.calc-by-state` | **present** |
| QLD **home-concession scale** (second, lower scale) | `kb.stamp-duty.calc-by-state` | **TO ADD** (§5) |
| Concession thresholds (NSW 800k/1M, VIC 600k/750k, QLD 700k/800k) | the scheme docs' `parameters` | **present** |
| QLD **stepped first-home concession-amount table** | `kb.scheme.qld.fhc` | **TO ADD** (§5) |
| The taper **arithmetic** (the three functions in §3) | this doc → `fh_engine_cash` | **TO ADD** (code) |

NSW and VIC need **no new KB data** — their taper functions read only the existing base scale + the two threshold params (and the divisors are *derived* from those params, §3). Only QLD needs new lookup data, because its taper is table-driven, not formulaic.

---

## 3. The verified per-state mechanics

A shared **marginal-bracket kernel** `duty(V, Scale)` underlies all four scales (NSW standard, VIC general, QLD standard, QLD home-concession):

```
duty(V, Scale):
  pick bracket B: B.lower_bound < V ≤ B.upper_bound  (open top bracket: V > lower_bound)
  case B.calc_type:
    "nil"           → 0
    "flat_on_total" → B.flat_rate_pct% × V                       # VIC $960k–$2M quirk
    "marginal"      → excess = V − B.lower_bound
                      if Scale.rounds_marginal_to_part_of_100:    # NSW, QLD: "or part of $100"
                          excess = ceil(excess / 100) × 100
                      B.base_duty + B.marginal_rate_pct% × excess
  then apply any first-bracket minimum (NSW $20)
```

The three states then differ **structurally** in how the concession reshapes `duty`:

### NSW FHBAS — *phase out a threshold-pegged concession* (Duties Act 1997 s.78A(2))

```
nsw_after(V):
  if V ≤ 800000:     0                                              # full exemption
  elif V < 1000000:  duty(V, nsw_standard)
                       − duty(800000, nsw_standard) × (1000000 − V) / 200000
  else:              duty(V, nsw_standard)                          # no concession
```

The concession starts at the *full duty on $800k* and phases linearly to zero across the $200k band. The divisor `200000 = home_concession_cap − home_exemption_threshold` (both params on `fhbas.md`) — derived, not a literal, so it tracks a threshold change.

**Simulate — $850,000:**
- `duty(800000, nsw_standard)` = 11,152 + 4.5%×(800,000−372,000) = **$30,412** *(= calc-by-state.md's own $800k anchor ✓)*
- `duty(850000)` = 11,152 + 4.5%×478,000 = $32,662
- concession = 30,412 × (1,000,000−850,000)/200,000 = 30,412 × 0.75 = **$22,809**
- `after` = 32,662 − 22,809 = **$9,853**

Revenue NSW sources: saving **"$22,809"** (exact) and duty **"around $10,000"** (✓).

### VIC FHB duty — *phase in the duty by a linear fraction* (Duties Act 2000 s.57JA)

```
vic_after(V):
  if V ≤ 600000:     0                                              # full exemption
  elif V ≤ 750000:   duty(V, vic_general) × (V − 600000) / 150000
  else:              duty(V, vic_general)                           # no concession
```

`B` in the statute ("duty paid or payable but for this section") is the **general-scale** duty — the whole concession band ($600k–$750k) sits above VIC's $550k PPR cliff, so the PPR concessional scale never applies here. Divisor `150000 = concession_cap − exemption_threshold` (params on `fhb-duty.md`).

**Simulate — $700,000:**
- `duty(700000, vic_general)` = 2,870 + 6%×(700,000−130,000) = **$37,070**
- `after` = 37,070 × (700,000−600,000)/150,000 = 37,070 × 0.66667 = **$24,713**
- saving = 37,070 − 24,713 = **$12,357**

SRO worked example: **"$24,713 … a saving of $12,357"** — exact, both figures.

### QLD FHC — *second scale minus a stepped table* (QRO)

QLD is **not** a formula — it subtracts a published, $10k-banded concession amount from a **separate, lower "home-concession" scale**:

```
qld_after(V):
  if V > 800000:  duty(V, qld_standard)                            # first-home gone (see boundary §7)
  else:           max(0, duty(V, qld_home_concession) − fhc_amount(V))
```

The `max(0, …)` floor is load-bearing: it produces the **full exemption at ≤ $700k for free** (there `home-concession duty ≤ fhc_amount`, so the difference floors to 0) — no separate threshold branch, "computed not asserted." `fhc_amount(V)` is the stepped table (§5).

**Simulate — $730,000:**
- `duty(730000, qld_home_concession)` = 10,150 + 4.5%×(730,000−540,000) = **$18,700**
- `fhc_amount($730k band)` = **$12,145**
- `after` = 18,700 − 12,145 = **$6,555**

QRO worked example: **"$18,700 … further concession $12,145 … $6,555 payable"** — exact, every step. (And `before` = `duty(730000, qld_standard)` = 17,325 + 4.5%×190,000 = $25,875 → saving $19,320, ≤ the $24,525 max ✓.)

---

## 4. The structural finding (why three functions, not one)

The three states are **three different taper mechanisms**: NSW phases *out a fixed concession* pegged to duty-at-threshold; VIC phases *in the duty* by a linear fraction; QLD subtracts a *stepped lookup* from a *second scale*. There is no generic taper — any attempt to unify them would be a false abstraction that obscures three distinct statutes. So: **one shared `duty(V, Scale)` kernel, three per-state `*_after(V)` functions.** This is the irreducible per-state arithmetic mechanism B exists for ([[son-reserve-agent-for-irreducible]] applied to formula code: share what's genuinely shared — the bracket kernel — and keep distinct what's genuinely distinct — the taper shapes).

---

## 5. KB changes (the only new data)

**(a) `kb.stamp-duty.calc-by-state` — add the QLD home-concession scale.** It is a published QRO statutory rate schedule (the base for the first-home concession arithmetic: QRO — *"duty is calculated at the home concession rate minus the additional concession amount"*), so it belongs with the other base scales under single-owner discipline. New `lookup` entry:

```jsonc
"qld_home_concession_scale": {
  "note": "QRO home-concession rate schedule (owner-occupier) — the base the QLD first-home concession subtracts from. Lower than qld_standard_scale on the first $540k. part-of-$100 rounding.",
  "rounds_marginal_to_part_of_100": true,
  "entries": [
    { "lower_bound": 0,       "upper_bound": 350000,  "base_duty": 0,     "marginal_rate_pct": 1.0,  "calc_type": "marginal" },
    { "lower_bound": 350000,  "upper_bound": 540000,  "base_duty": 3500,  "marginal_rate_pct": 3.5,  "calc_type": "marginal" },
    { "lower_bound": 540000,  "upper_bound": 1000000, "base_duty": 10150, "marginal_rate_pct": 4.5,  "calc_type": "marginal" },
    { "lower_bound": 1000000, "upper_bound": null,    "base_duty": 30850, "marginal_rate_pct": 5.75, "calc_type": "marginal" }
  ]
}
```
*(Continuity self-checks: $350k→$3,500; $540k→$10,150; $1M→$30,850 — each equals the next band's base ✓.)*

**(b) `kb.scheme.qld.fhc` — add the stepped first-home concession-amount table.** Scheme-specific reduction → lives on the scheme doc (not `calc-by-state`). New `lookup`:

```jsonc
"first_home_concession_amount": {
  "note": "QRO first-home concession amount by value band, contracts on/after 9 Jun 2024. Subtracted from qld_home_concession_scale duty; the max(0,…) floor yields full exemption ≤ $700k. Nil ≥ $800k.",
  "entries": [
    { "max_value": 709999.99, "amount": 17350 },
    { "max_value": 719999.99, "amount": 15615 },
    { "max_value": 729999.99, "amount": 13880 },
    { "max_value": 739999.99, "amount": 12145 },
    { "max_value": 749999.99, "amount": 10410 },
    { "max_value": 759999.99, "amount": 8675 },
    { "max_value": 769999.99, "amount": 6940 },
    { "max_value": 779999.99, "amount": 5205 },
    { "max_value": 789999.99, "amount": 3470 },
    { "max_value": 799999.99, "amount": 1735 },
    { "max_value": null,      "amount": 0 }
  ]
}
```
The existing `max_first_home_saving: 24525` param is the **saving at $700k** (= standard duty there), a *different quantity* from these concession **amounts** (max $17,350 = home-concession duty at $700k). Both are correct and now both documented — I'll add a Note making the distinction explicit so the two figures don't read as a contradiction.

NSW/VIC: **no KB change.** Their `*_after` functions read the existing `nsw_standard_scale` / `vic_general_scale` plus the threshold params already on `fhbas.md` / `fhb-duty.md`.

---

## 6. The base-turn application — the price *range* and non-monotonicity

At the **base/onboarding turn** the input is `target_price_range` (a `money_range`), not a scalar `V` ([[base-turn-honest-partial-output]]; constraint #1 plan-first). The `stamp_duty.*` leaves are scalar `money`, so the fill must collapse the range to a scalar.

**The catch:** `after_concession` is **non-monotonic** in `V` across the cliffs — a low price is fully exempt ($0), a high price has no concession (full duty). So neither "duty at the floor" nor a midpoint is the honest conservative figure for **cash required at settlement** (the verdict the user budgets against).

**Rule: evaluate the entire stamp-duty mechanic at the range *ceiling*.** At the ceiling you get the **highest `before_concession` and the smallest (or zero) concession simultaneously** → the largest `after_concession` → the most conservative `total_cash_required`. It is doubly conservative *and* needs no optimistic eligibility assumption — the honest-partial "conservative scalar" discipline applied correctly to a non-monotonic quantity. A `key_assumptions` line states "duty computed at the top of your target range, $X".

**Consistency with eligibility.** The `eligibility` component already bands the *same* price criterion three ways — within / straddle (`max_eligible_price`) / above (decision 5 / F7 in [`eligibility-resolution.md`](eligibility-resolution.md)). cash_position's ceiling rule is the cash-side projection of that banding: if the range straddles a concession cliff, eligibility shows "eligible up to `max_eligible_price`" while cash_position quotes the conservative ceiling cost — two faces of the one banded fact, not a contradiction. The three leaves stay **separate** (the schema splits them) so the `calculator` renderer can show the full `before → saving → after` spread.

**Eligibility coupling — `scheme_stack` is the gate, not a private state→scheme map.** cash_position takes `eligibility.scheme_stack` as a DAG input (`cash_position ◄── eligibility`). It applies a state concession **iff that outcome carries one as applicable/pending**, and computes duty for *that* scheme's state. cash_position holds no state→scheme catalog of its own — eligibility is the single owner of "which concession, for whom." Three consequences, all desirable:

- For a clean Mode-A lead the state concession's profile criteria resolve true (citizenship `{citizen,PR}` ⊨ `in[citizen,PR]`; owner-occupier intent; FHB) with the price criterion banded → the concession applies, carrying the same "confirm X" notes eligibility surfaced.
- If eligibility resolves it **rejected** (price ceiling above the cap), there's no applicable concession → `after = before` automatically (and the ceiling already sits in the no-concession band, so the arithmetic agrees).
- If eligibility **didn't assess** the state (today: VIC/QLD, where `state_catalog/1` returns `[]`), `scheme_stack` carries no `state_concession` → cash_position applies none and inherits eligibility's *"not yet assessed for your state"* note. So the §3 tapers can all be **encoded now and stay dormant** until eligibility's `state_catalog` covers VIC/QLD — the two components turn on together, never disagreeing. This is why "encode all three, base turn exercises the user's state" is safe: the gate is eligibility's coverage, read from the outcome, not a second source of truth here.

---

## 7. Boundaries (what this explicitly does **not** cover)

- **Foreign-purchaser surcharge** — a Mode B/D cost, deliberately not in any scale (`calc-by-state.md` already flags this). Never applied to a Mode-A plan.
- **Vacant land** — NSW/VIC/QLD all have lower vacant-land bands, but `property_fit.property_type` is unknown at base (no property attached). Out of base scope; a per-property refine concern. The home-band functions above assume a home.
- **QLD above $800k** — the *first-home* concession is gone; the general **home concession** (owner-occupier) may still reduce duty, but its eligibility doc (`kb.scheme.qld.home-concession`) is unauthored. So `qld_after(V>800k) = duty(V, qld_standard)` — conservative (claims no benefit we haven't grounded), with a note that the home concession may further reduce it. No silent cap (matches `eligibility.erl`'s `maybe_state_note` discipline).
- **VIC new-home / off-the-plan** and **NSW/VIC "previously received this benefit" gates** — unencoded (no backing fact), documented on the scheme docs, not silently assumed away.
- **The rest of `cash_position`** — `other_buying_costs`, `reserve_buffer`, `deposit`, `totals`, and `genuine_savings_verdict` are separate fills (some need income/savings facts → pending at base). This doc is *only* the `stamp_duty.*` sub-tree. They share the `fh_engine_cash` module but are scoped separately.

---

## 8. Code shape & verification

**Module.** New `fh_engine_cash` (peer of `fh_engine_eligibility`), dispatched from `fh_engine_fill:resolver(<<"cash_position">>, …)` replacing the `_provisional` stub.

- `duty(V, Scale)` — the shared bracket kernel (§3), reading a scale `lookup` from `fh_engine_kb:kb_rules(<<"kb.stamp-duty.calc-by-state">>)`.
- `nsw_after/1`, `vic_after/1`, `qld_after/1` — the three taper functions, reading threshold params + (QLD) the two new tables via `kb_rules/1`.
- `stamp_duty(State, Ceiling)` → `#{before_concession, concession_applied, after_concession}`.
- Reuses `money/1` + `group_thousands/1` (currently private in `fh_engine_eligibility`) — extract to a shared `fh_engine_money` util as a small, separate refactor (flagged, not bundled into this change).

**Verification (the §3 anchors become the test suite).** Like the resolver's cross-language conformance ([[engine-seam-build-discipline]]): a small Python spec `tests/cash_duty_eval.py` encodes the kernel + three tapers + the named anchors, and an Erlang `cash_duty_conformance.escript` runs the same anchors against `fh_engine_cash` for lockstep. The anchors are the **official-calculator postconditions** — NSW $850k → after $9,853 / saving $22,809; VIC $700k → after $24,713 / saving $12,357; QLD $730k → after $6,555; plus the exemption-boundary cases (≤$800k NSW → $0, ≤$600k VIC → $0, ≤$700k QLD → $0 via the floor) and the no-concession cases (≥$1M NSW, >$750k VIC, >$800k QLD → full standard duty). Cross-checking against the revenue offices' own calculators is the correctness criterion.

---

## Sources (primary, verified this pass)

- QRO — *Transfer duty concession rates* (home-concession scale + the first-home concession-amount stepped table, contracts on/after 9 Jun 2024) — https://qro.qld.gov.au/duties/transfer-duty/calculate/concession-rates/
- QRO — *First home concession* ($700k nil / $800k cap / $24,525 max saving; $730k worked example) — https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home/
- VIC SRO — *First home buyer duty exemption or concession* ($600k exemption / $600k–$750k sliding; $700k → $24,713 worked example) + Duties Act 2000 s.57JA (B = full duty) — https://www.sro.vic.gov.au/buying-property/land-transfer-stamp-duty/concessions-exemptions-and-waivers/first-home-buyers/first-home-buyer-duty-exemption-or-concession
- Revenue NSW — *First Home Buyers Assistance scheme* (full ≤$800k / concession $800k–$1M) + Duties Act 1997 s.78A(2) (concession = duty(800k) × (1M − V)/200k; $850k → saving $22,809) — https://www.revenue.nsw.gov.au/grants-schemes/assistance-scheme
- All base scales cross-referenced to [`kb.stamp-duty.calc-by-state`](../kb/stamp-duty/calc-by-state.md), whose own primary sources are listed there.
