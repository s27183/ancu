# Bilingual content — Vietnamese as a first-class engine output

> **Status: DONE & verified (all four base resolver components).** Mechanism built
> (`LocalizedText`, `fh_engine_i18n:subst/2`, `fh_engine_kb:copy/2`), copy docs authored
> for all four resolvers (`kb.copy.{mortgage,eligibility,cash,ownership}`), every resolver
> half + the agent half rewired, conformance green (45 escript / 48 py), full base turn
> emits bilingual to the `content_jsonb` snapshot (diacritics intact through Erlang→jsonb→PG;
> figures interpolate identically into both languages — single-source), and a **real-opus**
> turn produced register-appropriate, culturally-fluent Vietnamese for the agent's
> `lender_fit` reasoning (it surfaced the family-banking norm unprompted — trap #4 satisfied)
> with capacity staying `indicative` (§98 intact). The mortgage+eligibility subset shipped
> first (Son's call, §9); cash+ownership followed on the same mechanism once the trigger was
> met. Decision owner: Son. This doc is the load-bearing classification (define → simulate
> → document → apply) for *how the engine produces Vietnamese content*.

## 0. The two product calls this rests on

1. **Bilingual always (both).** Every user-facing content field carries `{vi, en}`.
   Not "the user's selected language" — *both*, so the Mode B cross-border family view
   (VN parent + AU child) reads the *same* artifact, each in their language.
2. **Vietnamese content is in Wedge 1a scope** — not merely "bilingual-ready". The base
   turn ships actual Vietnamese, authored with cultural register.

The corpus already commits to this intent: `04-ux-model.md` trap #4 ("the translation
trap") states Vietnamese means **cultural fluency** (family pooling, parent involvement,
formal vs informal register) — *not* word-for-word translation; and the geo-IP Vietnamese
UI default, the `"Phân tích bằng tiếng Việt"` extension button, and the bilingual
family-view artifacts all assume first-class Vietnamese. What was missing was any of it
plumbed into the *engine*: today there is **no language anywhere in the engine** — the
sidecar `_STYLE` only notes the reader "is often reading in a second language", which
yields English prose; the resolver halves emit hardcoded English (some already with
em-dash + `/utf8` literals — `fh_engine_eligibility.erl:268,290,304`).

## 1. The classification rule (content vs data)

> **A field is bilingual `{vi, en}` iff it is free-text authored for the user to read.
> Everything else is single-valued:** figures, booleans, enums, ids, dates, `null`s.

Why the boundary holds: enums and figures are **language-neutral machine values**; the
*shell* turns them into user-facing labels and locale-formatted numbers (constraint #7 —
the renderer vocabulary is shell-owned; constraint: VND/AUD formatting is shell-owned,
§contract). Only genuinely *authored prose* — a rationale, an assumption, an action step,
a rejection reason — has a Vietnamese that differs in *register*, not just in tokens. So
only prose gets `{vi, en}`. Where the boundary stops: a string that *looks* like prose
but is actually a status token (`eligibility_basis ∈ {ineligible, all_applicants_eligible}`)
is an **enum**, not content — it stays single-valued and the shell localizes its label.

### Simulation — the base-turn surface, partitioned

`mortgage_finance` (`fh_engine_mortgage` + agent `lender_fit`):

| Bilingual `{vi, en}` | Single-valued |
|---|---|
| `key_assumptions[]`, `pre_approval_action_plan[]` | `expected_borrowing_capacity` (num/null), `pre_approval_expiry` (date), `reapplication_required` (bool) |
| agent: lender-shortlist *rationale*, rate *basis* | `recommended_path`, `loan_structure.{type,rate}`, `fixed_vs_variable`, `approval_likelihood` (enums); lender proper-names |
| `debt_optimisations_to_action[].description` | the figures inside a debt-optimisation |

`eligibility` (`fh_engine_eligibility`):

| Bilingual `{vi, en}` | Single-valued |
|---|---|
| `applicable_schemes[].notes[]` | `applicable_schemes[].{name, benefit_value, role}` |
| `rejected_schemes[].reason` | `rejected_schemes[].name` |
| `stacking_constraints[]` | `eligibility_basis` (enum), `recommended_application_order[]` (scheme names), `total_benefit_value` |

The partition is clean — every field lands on exactly one side, and applying the rule
needs no per-field judgement. `cash_position` (`stamp_duty.notes`, `key_assumptions`) and
`ownership_planning` (`recurring_costs_estimate.notes`, the `alert_triggers_armed`
`{trigger, action}` prose pairs) are the same shape and were rewired on the same mechanism
(`kb.copy.cash`, `kb.copy.ownership`); their figures (duty, maintenance reserve, the land-tax
threshold) stay single-valued and interpolate identically into both languages.

## 2. Bilingual-always ⇒ the engine has NO language input

This is the simplification the "both" choice buys, and it supersedes an earlier
hypothesis (plumb a `language` attribute through the engine like FIRB status):

- The engine **always emits `{vi, en}`**. There is no per-turn language state, no
  language branch in the turn, no re-fill to "switch language".
- **Language is a shell *display* preference** — which side to show, or both side-by-side.
  The engine produces both; the shell chooses. This is strictly less engine state than the
  selected-language model, and it is what the family view structurally needs (both present
  in one artifact).

So content-language enters the engine as **output shape** (`LocalizedText`), never as input.

## 3. Two producers, one mechanism each

**(a) Agent-authored prose** — the `lender_fit` leaves. Each user-facing text field in the
agent's output schema becomes a `LocalizedText {vi, en}`; the agent authors **both in one
pass**. It is the only producer with the KB + buyer + cultural context to write
register-correct Vietnamese (trap #4), and doing it in-pass keeps both languages inside the
*same* fill-time KB snapshot (§7). §98 is untouched: the schema still carries **no money
field** — the rationale *describes* the resolver-given figures qualitatively, it does not
author them.

**(b) Resolver canned strings** — `key_assumptions`, `pre_approval_action_plan`,
eligibility `notes`/`reason`/`stacking_constraints`. **Decision: these move to bilingual
copy-templates in the KB artifact, not bilingual literals in Erlang.**

The clincher is the recurring **UTF-8 `>255` trap**. `io:format ~s` already crashes on a
single `—`; Vietnamese is *saturated* with `>255` codepoints (ầ, ư, ọ, ễ, …). Putting
Vietnamese prose into `.erl` `io_lib:format` strings walks straight into that trap at every
string. Templates in the artifact:

- keep Erlang free of Vietnamese literals — read as binaries, `{param}`-substituted,
  **never** `~s`-formatted (use binary substitution / `~ts`), so the trap can't fire;
- put the copy where a **Vietnamese-fluent reviewer can curate it** — git-authored KB,
  consistent with "git is SOT for content, the artifact is the projection" (§contract 9.1);
- make the audit snapshot of the copy fall out of the existing KB-snapshot machinery.

Erlang-literal Vietnamese is the patch; KB-template is the root. The resolver's job shrinks
to **parameter substitution**: a template `{vi, en}` pair with `{param}` placeholders +
a param map → two interpolated binaries.

**Placement — one copy-home per component.** Copy-templates live in a dedicated
`docs/kb/copy/<component>.md` (slug `kb.copy.<component>`), a `copy` block in its
`## Rules` `content_json`. (No compiler change: the compiler emits every KB doc's full
`content_json` verbatim, and rule-validation inspects only `fills` — a `copy` block rides
through; a copy doc is not a blueprint anchor, so it is reference-exempt, only slug==path +
parse gates apply.) This optimizes for the *actual goal* — **Vietnamese curation**: a
fluent reviewer reads/edits all of a component's Vietnamese in **one** doc, in narrative
order, rather than hunting it across fact docs. The numeric/label params it interpolates
still come from the fact docs (e.g. the APRA buffer from `serviceability-basics`), married
by the resolver — facts stay in fact docs, presentation copy in the copy doc.

**`subst/2` param kinds.** A `{param}` value is either (a) a **scalar** (binary/number) —
interpolated identically into both languages (e.g. a money figure, per the figure/locale
boundary above), or (b) a **bilingual `{vi, en}`** — interpolated per-language. Kind (b)
is what makes the eligibility `reason`/`confirm` frames work: those compose a label
fragment (`label_of`, a user-facing noun phrase) into a sentence frame
("Does not meet: {label}." / "Confirm {labels} to finalise."). For the Vietnamese to read
naturally, the *fragment* must be Vietnamese and drop into the Vietnamese *frame* — so
`label_of` returns `{vi, en}` too. The frames here are colon/list-style, where a noun
phrase drops in cleanly in both languages; a frame whose grammar won't survive fragment
interpolation is the signal to make it a single whole-sentence template instead.

## 4. The figure / locale boundary

Templates interpolate **bare** numbers (`"…rate + {buffer_pp} percentage points…"` →
`"…rate + 3.0 percentage points…"`). Numbers are language-neutral and interpolate
identically into both languages.

Where this stops: **fine-grained locale number formatting** (Vietnam swaps `.`/`,` from
en-AU; VND vs AUD symbols) is a **shell** concern, per §contract — the engine emits the bare
figure, the shell formats per display locale. **Trigger to revisit:** when the shell
renders figures embedded *inside* a bilingual prose string and the swapped separators read
wrong, lift the figure out of the template into a separate data field the renderer composes.
For Wedge 1a, bare interpolation is the honest, sufficient boundary.

Corollary (ties to §98 and the verbosity work, task 2b-5): prose templates should **not
embed a regulated figure as a literal** — they reference the figure's *basis* and let the
single-source data field carry the number, so a figure can never drift between the two
language strings or between prose and data.

## 5. Cultural register (trap #4)

Vietnamese is not a translation of the English string; it is the *same meaning in the
appropriate register*. Two levers:

- **Agent:** a Vietnamese `<style>` fragment — concise, plain, family-aware register;
  not a transliteration of the English. The agent has the context to choose register.
- **KB templates:** the Vietnamese copy is authored (and curated) for register, not
  machine-translated from the English half.

## 6. Audit trail

Both languages are produced **inside the same fill** — the agent authors both in one call;
the resolver substitutes both from the same KB-snapshotted template. So the existing
`component_filled.kb_versions` + `plan_cards.content_jsonb` snapshot covers `{vi, en}`
together, at the same `deploy_commit_sha`. No new audit surface; the bilingual content is
as reproducible as the English was.

## 7. Verification discipline (the eval)

Extend the py + escript conformance suites with three postconditions:

1. **Both present, non-empty** — every bilingual field has `vi` and `en`, both non-empty.
2. **`vi` is actually Vietnamese, not an English fallback** — a cheap detector (Vietnamese
   diacritic presence / `vi ≠ en`) so an English string silently copied into the `vi` slot
   fails the suite. (Deeper *register* quality is a human-curation loop, not a unit test —
   named honestly, not over-claimed.)
3. **Figures single-source** — a figure appears once (the data field), not duplicated per
   language; the `vi`/`en` prose carries no divergent number.

> **Durability — see [`outcome-conformance.md`](outcome-conformance.md).** The conformance
> here is attached to the current *workflow* (a hardcoded copy-doc list, hand-written cases),
> so it must be re-extended as producers/languages change. The long-term solution reframes
> bilingual as the **first clause** of a general *outcome-schema conformance* property,
> enforced at the two workflow-invariant points every fill crosses (the compiler at build,
> the `fh_engine_turn` serialization seam at runtime), driven off a `localized_text` type
> declared in `outcome_schema`. That note records the design and the sequencing (the
> build-time half is a down-payment doable now; the runtime half folds into 2c).

## 8. Contract amendment (surfaced drift, fixed not patched)

`engine-contract.md:145,178` parks *"locale"* wholesale on the shell side. That is now wrong
for **generated content**. The split to encode:

- **Engine-owned:** content-language — the agent/KB *produce* `{vi, en}`, snapshotted at
  fill time for the audit trail.
- **Shell-owned:** *display*-locale, VND/AUD number formatting, canned-chrome copy
  (disclaimers), enum→label maps, timezone.

## 9. Scope of the first pass — DONE, all four

Per Son: **mortgage + eligibility first** — validate the `LocalizedText` type, the agent
bilingual path, and the KB copy-template mechanism end-to-end on these two before authoring
the Vietnamese for `cash_position` and `ownership_planning`. The trigger (mortgage+eligibility
green end-to-end — real-opus smoke + conformance) was met, and cash/ownership followed on the
**same mechanism** with no design change: `kb.copy.cash` (7 templates: the duty notes,
the stamp-only/ceiling assumptions, the two pending notes) and `kb.copy.ownership` (8
templates: the recurring notes + the three lifecycle alerts' `{trigger, action}` prose).
All four base resolver components now emit `{vi, en}`; conformance covers every one
(`bilingual_conformance.escript` 45 anchors / `bilingual_eval.py` 48 checks).

## 10. What this is NOT

- **Not** a translation layer. There is no English→Vietnamese translation step anywhere —
  each language is *authored* (agent) or *curated* (KB). Translate-after-the-fact is the
  named trap #4 *and* it would break the fill-time audit (a translated rationale is a new,
  ungrounded generation).
- **Not** a language *input* to the engine. The engine always emits both; the shell picks.
- **Not** bilingual enums/figures. Those stay single-valued; the shell localizes labels and
  formats numbers.
- **Not** a §98 change. The agent's schema still has no money field; bilingual prose
  describes resolver figures, never authors them.
