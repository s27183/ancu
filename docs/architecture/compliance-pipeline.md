# The compliance pipeline — FIRB / ASIC / AML as a real gate, not a pass-through

> **Status: ACCEPTED — SHIPPED at 2b-4c.** Decision owner: Son. This is the *regulated layer*
> (Layer 2) that rides the structural seam validator
> ([`outcome-conformance.md`](outcome-conformance.md), Layer 1, shipped at 2b-4b). It makes
> [`engine-contract.md`](engine-contract.md) §6 real: `fh_engine_compliance:run/4` runs the three
> gates (FIRB → ASIC → AML) on every committed outcome, each producing a disposition
> (`clear|annotate|branch|block`); `fh_engine_turn:commit` writes one `audit_events` row per
> (component, gate) via the new `fh_engine_store:append_audit/6` — **even on a clear** — emits a
> `compliance_gate` event, and fails the turn on a `block`. ASIC **consumes** Layer 1's
> figure-type verdict (`verdict_refs`), never re-deriving §98. **Verified** (`seam_smoke.escript`
> vs Docker PG): the Mode-A healthy turn writes 15 audit rows (3 gates × 5 components), all
> `clear`, ASIC `decision_support_boundary_held` on the 2 advice-adjacent components
> (mortgage_finance, eligibility) and `no_advice_surface` on the arithmetic ones, the consumed
> Layer-1 `figure_type=conformed` recorded in `verdict_refs`, `deploy_commit_sha` + kb_versions
> stamped. Constraint #10 ("build the gate into the architecture, not as a disclaimer") is now
> met: a gate that produces no audit trail is still a disclaimer; this one produces the trail.
> This note defines what "real" means **for Mode A**, where each gate's enforcement body lives,
> and the trigger that turns the deferred Mode-B/D bodies on.

## 0. The problem: a wired-but-inert pipeline with no audit trail

The pipeline exists and is called (`fh_engine_turn` commit, the fold over `[firb, asic, aml]`),
but:

- every stage is `{Outcome, []}` — no gate fires, no disposition is recorded;
- `audit_events` (the table, `001_init_engine.sql:159`, with a `compliance_jsonb` column
  *intended for exactly this*) has **zero writers** — the regulated attribution trail §6
  promises ("each extension … writes an `audit_events` row") does not exist;
- so for a regulated product whose whole liability case rests on *informational / decision-
  support only*, there is no per-fill record that the boundary was checked and held.

"Real FIRB/ASIC/AML" is therefore two things, separable: **(a)** the audit trail — every gate
writes a row, clear or not; **(b)** the gate bodies — what each gate enforces. (a) is
mode-independent and unconditionally needed now. (b) is asymmetric across the three gates in
Mode A, which is the heart of the design.

## 1. The Mode-A asymmetry — define *which* gate has a body

The three gates are not symmetric in Wedge 1a (Mode A: domestic FHB, no foreign person, no
fund custody). Binding the predicate "what does this gate enforce?" *of each gate, in Mode A*:

| Gate | Mode-A enforcement body | Why | Real body's trigger |
|---|---|---|---|
| **FIRB** | **none** — `firb_required_any` is `false` (no foreign applicant) | There is no foreign person to branch; the established-dwelling ban / new-build-only filter keys on a foreign applicant | A foreign applicant appears → **Mode B/D** (`firb_required_any = true`) |
| **ASIC** | **substantive** — the decision-support boundary on the agent's output | The agent surfaces a lender shortlist, scheme stack, rate-structure reasoning — all of which must stay *information*, never licensed financial/credit *advice* | always on (Mode A's live gate) |
| **AML** | **none** — base turn has no fund custody and no money transfer | We are never custodian of funds; cross-border routing / VN capital-control guidance keys on a cross-border deposit | `funds_provenance.cross_border_transfer = true` → **Mode B/D** / a refine turn carrying deposit facts |

The discipline (don't build B/C/D structure speculatively, [[build-time-structure-vs-runtime-data]])
applies: FIRB's and AML's enforcement bodies are **structurally present but deferred to their
real trigger**. In Mode A they are not no-ops — they **assert their precondition and write a
`clear` audit row** ("FIRB checked: not required"; "AML checked: no cross-border transfer").
That positive attestation is the point: the audit trail must show the gate *ran and cleared*,
not that it was silently skipped.

**Boundary.** This asymmetry is a property *of Mode A*. The moment a foreign applicant or a
cross-border deposit enters, FIRB/AML flip from assert-and-clear to a real branch/block, and
this table's first and third rows are rewritten. The verdict "FIRB has no body" holds only
under the Mode-A binding; do not carry it into Mode B.

## 2. Two-layer composition — ASIC consumes, does not re-derive

The §98 hazard (the agent authoring a money figure — `expected_borrowing_capacity`, the
slice-2a bug) is already fixed *twice* before ASIC sees the outcome:

1. **generation time** — the agent's Pydantic schema (`planner.py` `LenderFitLeaves`) has no
   money/number field, so the LLM structurally cannot emit one;
2. **seam, Layer 1** — `validate(outcome, outcome_schema)`
   ([`outcome-conformance.md`](outcome-conformance.md)) checks the figure-type clause: a field
   typed as a figure is null-or-number, never a string. A violation **crashes the turn**,
   fail-closed, before Layer 2 runs.

So **ASIC does not re-derive §98** — it would be a second source of the same truth, drifting.
ASIC **consumes Layer 1's verdict**: given a Layer-1-conforming outcome (figures are figures,
localized text is bilingual), ASIC's job is the *regulated reading* of that conformance — the
attestation that the decision-support boundary held, plus a soft `annotate` for tone/framing
where the outcome is informational-but-could-read-as-advice. One source of truth ("this
outcome conforms"), two readers: the structural crash (Layer 1) and the regulated attestation
(ASIC).

```
commit(outcome):
  Layer 1  validate(outcome, outcome_schema)   -- structural, fail-closed CRASH on violation
           |                                      (localized_text · figure-type/§98 · enum)
           v
  Layer 2  firb(ctx) -> asic(ctx, layer1_verdict) -> aml(ctx)
           |   each: disposition + compliance_gate event + audit_events row
           v
  snapshot_component + emit(component_filled)
```

**Why this ordering.** Layer 1 is producer- and mode-agnostic and is a hard contract check
(a violation is a *bug*, crash). Layer 2 is regulated and mode-aware and produces *dispositions*
(a finding, recorded, sometimes blocking). Running Layer 1 first means Layer 2 always reasons
over a well-formed outcome — ASIC never has to defend against a money-string, because that
already crashed.

## 3. The three gates, defined

### FIRB — `firb(ComponentId, Ctx, Outcome)`
- **Reads:** `Ctx.firb_required_any` (the aggregate `buyer_profile` derives per-applicant, §11.9).
- **Mode A** (`false`): disposition `clear`, detail `not_required`, audit row. Outcome unchanged.
- **Deferred body** (`true`, Mode B/D): enforce the established-dwelling ban window
  (1 Apr 2025 – 30 Jun 2029) and the new-build-only filter; annotate surcharge + vacancy-fee
  obligations; disposition `branch` (detail `new_build_only`) or `block` (detail
  `established_dwelling_banned`). **Not built now** — no foreign applicant in Wedge 1a; the
  branch arm exists in the code with the body guarded behind `firb_required_any = true` and a
  `not_implemented` audit marker so an accidental Mode-B turn fails loudly, not silently.

### ASIC — `asic(ComponentId, Ctx, Outcome, Layer1Verdict)`
- **Reads:** `Layer1Verdict` (figure-type conformance) + the outcome's user-facing fields.
- **The boundary it enforces:** the agent may surface *options + reasoning* (lender shortlist,
  scheme stack, rate-structure trade-offs) but must not cross into *advice* — an imperative
  "you should take loan X from lender Y", a personal recommendation that presumes the user's
  full circumstances, or any figure the LLM authored as if it were a calculated entitlement.
- **Disposition logic:**
  - figure-type verdict failed → unreachable here (Layer 1 already crashed) — but ASIC records
    the *expectation* in its audit row so the trail shows §98 was in scope for this component;
  - outcome carries the decision-support markers (lender lists tagged `indicative` /
    `shortlist`, capacity `null`-or-resolver-authored, reasoning framed as information) →
    `clear`, detail `decision_support_boundary_held`;
  - a *soft* crossing (informational content phrased imperatively) → `annotate`, detail
    `reframed_as_information` — the gate **flags**, it does not silently rewrite the LLM's
    prose (rewriting model prose would itself be an un-audited content change).
- **Component scoping:** ASIC's substance is the components whose outcomes carry advice-adjacent
  content — `mortgage_finance` (lender fit), `eligibility` (scheme applicability). A pure
  arithmetic outcome (`cash_position` duty) has no advice surface → `clear` by construction,
  still audited.

### AML — `aml(ComponentId, Ctx, Outcome)`
- **Reads:** `Ctx` for any deposit/transfer facts (`funds_provenance.*`, absent at base).
- **Mode A** (no cross-border transfer): disposition `clear`, detail `no_fund_custody`, audit row.
- **Deferred body** (cross-border deposit present): assert money-transfer guidance routes only
  to licensed partners (Wise/OFX/partner banks); block any informal-channel route (VN capital
  controls — SBV-compliant only, never recommend informal routes); confirm we are never
  custodian. Disposition `annotate` (route to licensed) or `block` (informal route surfaced).
  **Not built now** — no deposit facts at base.

## 4. Dispositions and fail-closed semantics

`disposition ∈ clear | branch | block | annotate` (the §4 event taxonomy plus `clear`, which
the taxonomy implies but did not name — a gate that ran and found nothing still must audit):

| Disposition | Meaning | Effect on the turn |
|---|---|---|
| `clear` | gate ran, nothing to enforce | commit proceeds; **audit row written** |
| `annotate` | soft finding (tone, route-to-licensed) | commit proceeds; finding in the event + audit |
| `branch` | enforced a path constraint (FIRB new-build) | commit proceeds on the constrained path; audit |
| `block` | hard violation | **turn fails** (supervised) — the outcome is *not* committed |

**Fail-closed, two grades:**
- **Layer 1** non-conformance → **crash** (a bug; the OTP idiom — let it surface).
- **Layer 2** `block` → **`turn_failed`** (a regulated stop; the outcome must not persist).

Both mean: a non-compliant outcome never reaches `content_jsonb` or the `component_filled`
event. The distinction is *crash* (contract breach, unexpected) vs *fail* (regulated decision,
expected and recorded). In Mode A neither fires on a healthy turn — every gate clears — so the
healthy path is `clear×3` + three audit rows.

## 5. The audit trail — every gate, every fill

Each gate writes one `audit_events` row (the table already exists; this note adds the writer
`fh_engine_store:append_audit/N`). The row is **attribution, not cost** — no token/price fields
ever (metering lives in the `usage` event stream, §1; `audit_events` is the compliance trail):

```
audit_events row, per (component, gate):
  component_id        the blueprint component filled
  fill_path           'resolver' | 'two_path' | 'agent'   (the real commit-path domain)
  kb_versions_jsonb   [{slug, effective_from, last_verified}] active at fill (audit snapshot)
  compliance_jsonb    { gate, disposition, detail, verdict_refs }   <-- this gate's result
  deploy_commit_sha   reproducibility (constraint #6 — repo is SOT)
```

`compliance_jsonb.verdict_refs` carries the Layer-1 verdict ASIC consumed (so the trail shows
*what* ASIC attested to, not just that it cleared). The row is written **regardless of
disposition** — a `clear` is as much a part of the regulated trail as a `block`; "we checked
FIRB and it was not required, on this KB version, at this commit" is precisely the record an
auditor needs.

**Volume note (and its boundary):** three gates × N components = 3N audit rows per turn. That
is intended — the trail is per-(component, gate). It is **not** a cost concern (no metering),
but it *is* storage; if a turn ever fans to hundreds of components the row count is worth
revisiting. At Wedge-1a scale (≤9 base components) it is ~24 rows/turn — negligible. State the
boundary: the per-(component,gate) granularity is right for audit defensibility and wrong only
if component counts explode, which the base turn does not.

## 6. Context the pipeline reads

`run/3` already takes `Ctx = #{mode, intent, firb_required_any}`. The deferred bodies will
extend it (read-only — the pipeline never mutates upstream facts):

- FIRB body → `firb_required_any` (have it), plus per-applicant `firb_status` when branching
  on *which* applicant is foreign (Mode B);
- AML body → `funds_provenance.{cross_border_transfer, transfer_channel, deposit_source}` (from
  `buyer_profile`, absent at base — surfaces with a refine turn carrying deposit facts);
- ASIC → `Layer1Verdict` (passed in by the commit seam, not from `Ctx`).

No new upstream coupling now: Mode A reads only `firb_required_any` + the Layer-1 verdict.

## 7. Worked simulation (define → simulate)

Walk concrete turns through the pipeline; show each disposition and audit row.

| Scenario | FIRB | ASIC | AML | Audit rows |
|---|---|---|---|---|
| **Mode-A NSW $700k, healthy** (the smoke case) | `clear` not_required | `clear` boundary_held (consumed Layer-1: capacity null, shortlist `indicative`) | `clear` no_fund_custody | 3/component, all `clear` |
| **Agent emits a money-string in a figure field** (the §98 bug) | — | — | — | **none** — Layer 1 crashed the turn *before* the pipeline; the crash is the record |
| **Agent phrases a lender note imperatively** ("take the CBA loan") | `clear` | `annotate` reframed_as_information | `clear` | ASIC row carries the annotation |
| **(future) Mode-B foreign parent, established dwelling** | `block` established_dwelling_banned → `turn_failed` | not reached | not reached | FIRB `block` row; no `component_filled` |
| **(future) Mode-B deposit wired informally from VN** | `clear`/`branch` | `clear` | `block` informal_channel → `turn_failed` | AML `block` row |

The first three are Mode A (built now). The last two are the deferred bodies — recorded here so
the trigger and disposition are designed, not improvised when Mode B arrives. The second row is
the key composition check: a §98 violation is caught by Layer 1, not ASIC, so ASIC never has to
be the §98 enforcer — it attests to a verdict already rendered.

## 8. What this is NOT

- **Not** a re-implementation of §98 — ASIC *consumes* the Layer-1 figure-type verdict
  ([`outcome-conformance.md`](outcome-conformance.md) §2), one source of truth.
- **Not** commerce gating — the pipeline never decides whether work *proceeds based on money*
  (that is shell-owned; keeping it out of the engine is what keeps ASIC liability out of the
  agent loop, engine-contract §1). It gates on *compliance*, never on entitlement.
- **Not** the disclaimer — disclaimer *copy* and its placement are shell-owned (§6). This is
  the *gate that prevents a non-compliant recommendation path*, engine-owned.
- **Not** a content rewriter — ASIC flags (`annotate`), it does not silently rewrite LLM prose
  (an un-audited content mutation would defeat the trail).
- **Not** Mode-B FIRB/AML enforcement — those bodies are deferred to their real trigger, with a
  loud `not_implemented` marker so an accidental Mode-B turn fails rather than passes.

## 9. Situate in the engine

- **Spine reused:** the existing `fh_engine_compliance:run` fold at the `fh_engine_turn`
  commit seam (extended `run/3` → `run/4` to pass ASIC the Layer-1 verdict); the
  `compliance_gate` event (§4 taxonomy); the `audit_events` table (`001_init_engine.sql`,
  writer `fh_engine_store:append_audit/6` added here); `fh_engine_store` for persistence.
  **Implementation seam surfaced + reconciled:** `audit_events.fill_path`'s CHECK predated
  the two-path fill (slice 2f) and allowed only `{resolver, agent}`, so a `two_path`
  component's audit row (mortgage_finance) would have been rejected. Widened to
  `{resolver, two_path, agent}` via the forward-only `002_audit_fill_path_two_path.sql`
  (001 is checksum-locked — a new migration, not an edit).
- **Rides:** [`outcome-conformance.md`](outcome-conformance.md) — Layer 1, the structural seam
  validator ASIC consumes. Built together at 2b-4.
- **Relates to:** [`engine-contract.md`](engine-contract.md) §6 (the pipeline contract this
  realizes), §1 (metering-not-gating — why audit carries no cost), constraint #10 (the gate in
  the architecture); the four-mode table (the deferred FIRB/AML bodies are Mode B/D).
- **Index wiring (done):** [`structure-map.md`](structure-map.md) gained a **commit-seam
  compliance** inventory node (Layer 1 + Layer 2) + an `audit_events` entity in the Plane-4
  persistence ER + a Plane-3 cross-link. The `docs/README.md` table was deliberately left
  unextended (it indexes major docs, not the implementation design-note tier — see
  [`outcome-conformance.md`](outcome-conformance.md) §12 for the same decision).

## Resolved decisions (Son, at 2b-4)

1. **Mode-A scope** = audit trail (all gates) + ASIC body (decision-support seam
   post-condition) + FIRB/AML assert-and-audit-clear. Mode-B FIRB/AML bodies deferred to their
   real trigger — **not** built speculatively.
2. **ASIC consumes Layer 1's §98 verdict**, does not re-derive it (one source of truth).
3. **Dispositions:** hard violation → `block`/`turn_failed` (fail-closed); soft → `annotate`
   (flag, never silent rewrite); a clear gate still writes an audit row.
4. **Layer ordering:** structural validator (fail-closed crash) first, regulated pipeline
   second, on a conforming outcome.
