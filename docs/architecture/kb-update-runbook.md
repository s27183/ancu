# KB update runbook

**The canonical workflow for the periodic, offline "update the KB" job.** When the
maintainer says *"let's update the KB,"* this is the doc to open and walk top to
bottom. It is a **hub, not a duplicate**: each phase is a few lines and links out
to the doc that already owns the detail. The pieces existed before this doc; what
was missing was the *spine* tying them into one ordered sequence.

This is **offline, build-time work** — git is the source of truth, the engine
loads a compiled projection at boot ([engine-contract.md §9.1](engine-contract.md)).
None of it touches a running engine until a deploy.

## What this covers (and what it doesn't)

A KB update is **never only KB**. A scheme cap change ripples into the copy
template that interpolates it, possibly a blueprint, the compiled artifact, the
eval set, and the deploy provenance. This runbook covers that whole surface.

It does **not** cover the *suburb data* track — that is a separate cadence with a
separate trigger (data releases, not regulatory changes) and its own recipe in
[suburb-adapter-workflow.md](suburb-adapter-workflow.md). The two tracks are
called out as **Track A (regulatory KB)** and **Track B (suburb data)** below;
most "update the KB" asks are Track A.

## When it runs — triggers and cadence

Triggers and their cadences are defined in
[architecture.md §11.2](architecture.md) (the update-cadence table). In short:

| Cadence | What moves | Track |
|---|---|---|
| **Monthly** | Lender policy, RBA cash rate, FHG panel / participating lenders | A |
| **Quarterly** | Scheme structures, state duty schedules, FHOG, HECS thresholds, process knowledge, document templates | A |
| **Per-event** | Federal/State Budgets (May/June), Housing Australia rule changes, ASIC bulletins, FIRB regime changes — calendar / RSS triggered; **triggers a blueprint review** | A |
| **Per-release** | ABS Census/SEIFA (5-yearly), state price reports (quarterly), crime (quarterly), RBA FX (daily for Mode D) | B |

To find *what* is overdue without waiting for an external trigger, run the
freshness scanner (Phase 0).

---

## Track A — regulatory KB update

Walk these phases in order. Skip a phase only when nothing in scope touches it
(each says when it applies).

### Phase 0 — Scope: what's stale, what changed

```bash
python3 tests/kb_freshness.py          # advisory report, exit 0
python3 tests/kb_freshness.py --strict # exit 1 if anything is overdue
```

The scanner reads every `docs/kb/**.md` `last_verified` date and flags docs past
their per-cadence re-verification budget (budgets grounded in §11.2; see the
script header). Combine its output with the external trigger (a budget, a scheme
change, an ASIC bulletin) to fix the **set of docs in scope** for this pass.

**Curation-signal harvest — designed, not yet wired.** A maturing plan card
generates its *own* scope from the inside: when the runtime resolver hits a
**silent rule** (it had to escalate to the agent where a deterministic rule
should exist) or an upload carries a **no-home fact** (informative content the
blueprint schema does not track), each emits a *curation signal* that is meant to
feed exactly this offline pass — a silent rule → a new KB rule (Phase 1), a
no-home fact → a new blueprint slot (Phase 3) — so the next deploy closes the gap
and the next occurrence is deterministic ([agentic-flow.md §2](agentic-flow.md),
[architecture.md §11.9](architecture.md)). **This emission is documented design,
not built** — the engine does not persist these signals yet. When it does, Phase 0
also drains the accumulated signals; until then this is a forward note, not a step.

**Change-kind classifier — route by the depth of the change.** An "update" is not
one kind, and the kinds enter the system at different layers. Before routing into
the phases below, classify on two axes:

- **SCOPE — which active mode does it touch?** In-scope (Mode A / Wedge-1a) →
  author + compile + deploy now. Out-of-scope (Modes B/C/D, unbuilt) → record
  **design-first**, trigger-gated to when that mode ships (the structure/mechanism
  is built now; the mode's *content* waits). The structural gates still run over
  every blueprint, so an out-of-scope change must keep renderers in-enum and the
  pipeline acyclic even while its KB anchors dangle.
- **KIND — how deep does it cut?** This decides the *entry layer*, and getting it
  wrong is the classic mistake (entering a model-deep change at the blueprint):
  - **kind-1 · point-figure** — a value changed (a fee, rate, cap, threshold).
    Entry: the **KB doc** (Phase 1) → recompile (Phase 4). No blueprint or model
    change. The bulk of regulatory updates.
  - **kind-2 · foundation-computation** — a new rule or computation (a new scheme,
    a new formula, a new predicate). Entry: a **KB doc + the consuming component /
    resolver** (Phases 1 + 3). The blueprint's pipeline may gain a slot or an
    anchor, but the *lifecycle model* is unchanged.
  - **kind-3 · temporal-structure** — a policy that acts on a part of the lifecycle
    **the model does not yet have** (a phase, a horizon, a figure-owner). Entry: the
    **conceptual anchor** ([`lifecycle-simulation-model.md`](lifecycle-simulation-model.md)),
    *not* the blueprint. You **grow the model first**, then let it ripple outward
    through the contracts in order — anchor → `engine-contract.md` / `architecture.md`
    §11.9 → the conforming blueprints (which must compile) → KB → `04-ux-model.md`
    → the index (`structure-map.md` / this runbook) — one doc at a time, foundation-first
    ([foundation-first-for-cross-contract-reframe]). Entering at the blueprint would
    force the new policy into a phase that isn't there, producing a homeless figure
    (one with no phase, no event, no owner).

  > **Worked kind-3 instance — the full temporal flow (2026-06).** The AU-2026-budget
  > test case (negative gearing + CGT) had *nowhere to land*: both are post-acquisition
  > rules, but the lifecycle ended at `Own`. It was **not** a blueprint edit — it grew
  > the model: a terminal `dispose` phase + a hold horizon `H` + a `disposition`
  > figure-owner entered at the conceptual anchor (§8), then rippled through the
  > contracts, the four blueprints, the Mode-A KB, the UX, and this index — the exact
  > cascade tracked as **grounding-checklist item 10**. The pre-existing investor
  > `cgt_projection` placeholder (a figure with no phase/event/owner) was precisely the
  > symptom of a kind-3 change that had earlier been (mis)entered at the blueprint.

### Phase 1 — Curate the fact docs

For each in-scope `docs/kb/<area>/<slug>.md`:

- **Re-verify every fact against its primary source** — the official scheme page,
  the state revenue office, the regulator. Never re-verify a KB doc against
  another KB doc or against memory; the primary source is the only ground.
- Edit the markdown body and the `## Rules` JSONC block to match.
- Bump frontmatter: `last_verified:` to today always; `effective_from:` only when
  the *rule itself* changed effective date.
- Keep the **slug == path** invariant (the compiler enforces it; don't rename a
  file without renaming the slug, and vice-versa).

**Regulated figures discipline:** a duty/grant/threshold figure that a user acts
on must be verified to the dollar against the official calculator, or kept out of
the LLM's reach entirely (resolver-filled from the KB rule). KB *estimates*
(ranges) are surfaced as ranges. Don't let a verified figure regress into prose
the agent paraphrases.

### Phase 2 — Co-update the bilingual copy (when a figure or note changed)

*Applies when a ruled component's facts changed.* The VI/EN copy templates live in
`docs/kb/copy/<component>.md` (`kb.copy.{eligibility,cash,mortgage,ownership,profile}`)
and interpolate resolver-computed values via `{param}` placeholders — see
[bilingual-content.md](bilingual-content.md). If you changed an FHG cap, a duty
threshold, or an eligibility note in Phase 1, check the paired copy doc: the
compiler's bilingual gate forces both `vi` and `en` to be present and non-empty,
but it cannot tell you the *number in the sentence* is now wrong. The freshness
scanner treats copy docs as quarterly safety-net, but their real trigger is
"the paired fact doc moved" — so re-verify them whenever their fact doc changes.

### Phase 3 — Curate blueprints (only on a structural change)

*Applies only when the transaction structure changes* — a new phase, a new
component, a new outcome type, a changed renderer. This is rare and law/mechanism
driven (a per-event trigger, or a harvested no-home-fact signal once Phase 0's
loop is wired). A pure fact change (a new cap on an existing scheme) does **not**
touch blueprints — only the fact doc + copy. Blueprint model:
[architecture.md §11.9](architecture.md).

Editing `docs/blueprints/*.md` is the *spec* edit, but a structural change ripples
across layers — this is the offline ops the plan card's *construction* (as opposed
to its runtime fill) actually requires:

- **KB anchors** — keep every `**KB anchors:**` slug resolvable (compiler gate).
- **Outcome schema** — a changed `outcome_schema` *is* the typed fact surface
  downstream components read via the resolver-input registry (§11.9); confirm
  every downstream `field`/`ref` still resolves (the compiler's reference-integrity
  + coverage gates catch breaks).
- **Renderer vocabulary** — a *new* renderer is a deliberate, reviewed addition in
  three places: the §11.9 vocabulary table, the compiler's `RENDERER_ENUM`, **and**
  the Svelte component under `shell/web/frontend/src/lib/renderers/`. The compiler
  *gates* renderer-in-enum (a blueprint may **compose** two renderers — it
  validates the pair) but cannot build the component; the shell side is a separate
  edit. Prefer extending an existing renderer's *outcome shape* over adding a
  renderer (the two-spines model added zero renderers — §11.9).

### Phase 4 — Compile, gate, and prove

```bash
python3 tests/validate_build.py        # all gates, no emit (CI-equivalent)
python3 engine/build/kb_compiler.py    # gates + EMIT artifact.json
```

The compiler ([engine/build/kb_compiler.py](../../engine/build/kb_compiler.py)) runs
the structural gates (slug==path uniqueness, renderer enum, pipeline acyclicity)
and the semantic gates (content_json parse, reference-integrity, coverage,
type-compat, bilingual structure, `agent_leaves` classification), then emits
`engine/erlang/priv/kb/artifact.json` (the projection the engine loads into
`persistent_term` at boot).

**Prove the change is in the loaded artifact — "build green" ≠ "artifact current."**
After emit, confirm the changed entry is actually present in `artifact.json`
(grep the new figure / the new slug). A silent no-op in the compiler can leave a
not-yet-compiled entry out while still reporting green; the only proof is
selecting the changed value back out of the emitted artifact.

### Phase 5 — Re-run the eval suite

```bash
python3 tests/resolver_eval.py
python3 tests/eligibility_benefit_eval.py
python3 tests/cash_duty_eval.py
python3 tests/mortgage_eval.py
python3 tests/ownership_eval.py
python3 tests/bilingual_eval.py
python3 tests/outcome_validate.py
```

These check rule semantics and outcome conformance against worked examples. **Grow
the eval set** when a change introduces a new rule shape, a new field, or a new
edge case — the eval is the regression net for the next update, so a change that
isn't represented in an eval is a gap. A **new component** (Phase 3) takes a new
per-component eval harness — the `eligibility` / `cash_duty` / `mortgage` /
`ownership` evals are one-per-component; a structural addition without one ships
unguarded.

### Phase 6 — Commit and deploy

Commit the markdown edits **and the re-emitted `artifact.json`** together (the
artifact is a checked-in projection; a commit that edits a fact doc without the
matching artifact re-emit is inconsistent). Deploy bakes the artifact into the
engine image; boot loads it into `persistent_term` and records the
`deploy_commit_sha`. Deploy topology + sequence: [deployment.md](deployment.md).

### Phase 7 — Reproducibility and existing cards

Existing filled plan cards are **immutable snapshots** — each recorded the
`deploy_commit_sha` + the `kb_versions` (slug + effective_from + last_verified)
active when it was filled ([engine-contract.md §9.1](engine-contract.md)), so an
old card stays reproducible against the old KB. After a deploy that changes a
figure, existing cards do **not** silently change; they get an **opt-in refresh**
(re-run the base turn against the current artifact), which appends new events
stamped with the new SHA + KB and reports the drift. Mechanism + policy:
[plan-card-refresh.md](plan-card-refresh.md).

---

## Track B — suburb data update

Separate cadence, separate trigger (a data release, not a regulatory change). The
repeatable per-adapter recipe lives in
[suburb-adapter-workflow.md](suburb-adapter-workflow.md); the source register and
cadences are in [suburb-data-foundation.md §6](suburb-data-foundation.md). In
brief: run the affected adapter under `engine/build/suburbs/`, which writes the
`suburbs` + `suburb_sources` tables; respect the per-source licence (free to
download ≠ free to use). This track does **not** recompile the KB artifact — the
suburb data is runtime DB state, not part of the compiled projection.

---

## Quick reference — the Track A command sequence

```bash
# 0. scope
python3 tests/kb_freshness.py

# (edit docs/kb/**.md fact docs + docs/kb/copy/*.md + docs/blueprints/*.md as needed)

# 4. compile + gate + emit
python3 tests/validate_build.py
python3 engine/build/kb_compiler.py
#    then grep artifact.json to prove the change landed

# 5. evals
python3 tests/resolver_eval.py && \
python3 tests/eligibility_benefit_eval.py && \
python3 tests/cash_duty_eval.py && \
python3 tests/mortgage_eval.py && \
python3 tests/ownership_eval.py && \
python3 tests/bilingual_eval.py && \
python3 tests/outcome_validate.py

# 6. commit the markdown + the re-emitted artifact.json together, then deploy
```

## What an update touches — the surface at a glance

| Artifact | When | Owner doc |
|---|---|---|
| `docs/kb/<area>/<slug>.md` fact docs | The trigger (always, Track A) | this doc, Phase 1 |
| `docs/kb/copy/*.md` bilingual templates | When a figure/note changed | [bilingual-content.md](bilingual-content.md) |
| `docs/blueprints/*.md` | Only on a structural change | [architecture.md §11.9](architecture.md) |
| Renderer enum (`RENDERER_ENUM` + §11.9 table) **and** `shell/.../renderers/*.svelte` | Only when a blueprint adds a renderer | this doc, Phase 3 |
| `engine/erlang/priv/kb/artifact.json` | Always (re-emit + prove) | [engine-contract.md §9.1](engine-contract.md) |
| `tests/*_eval.py`, `outcome_validate.py` | Grow when a new shape / new component appears | this doc, Phase 5 |
| `deploy_commit_sha` + `kb_versions` provenance | Automatic at deploy/fill | [engine-contract.md §9.1](engine-contract.md) |
| Curation signals (silent rule → KB rule; no-home fact → blueprint slot) | Phase-0 input — **designed, not yet wired** | [agentic-flow.md §2](agentic-flow.md) |
| `suburbs` / `suburb_sources` tables | Track B, per data release | [suburb-adapter-workflow.md](suburb-adapter-workflow.md) |
