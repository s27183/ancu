# KB news feature — surfacing KB changes to the buyer they affect

**Status:** backend built + live-verified 2026-07-07 (`news_smoke.escript`, all
assertions pass against Docker PG). Compiler now reverse-indexes each note's
`affected_components`, and every note now carries a `sources:` citation
(both resolved 2026-07-07 — see below). Shell: fetch (27), ticker (29), and
tap → detail sheet + tile highlight (28) all built 2026-07-07 (svelte-check
0/0 + autofixer clean each time; no live browser walkthrough — see each
task's note). Task 28's `NewsDetailSheet.svelte` is the second consumer that
closes both 30 (bilingual pick) and 32 (source link) — see their entries.
Tasks 31, 33, 34 not started (33's default is already true, not yet closed
as its own line item).

## The problem

A KB update pass (`kb-update-runbook.md` Phase 1) changes a fact a buyer's plan
already depends on — a threshold, a cap, a rate. Today nothing tells the buyer;
the new figure only reaches them on their next full plan refresh
([`plan-card-refresh.md`](plan-card-refresh.md)), which is a separate,
currently dev-only mechanism. This feature closes that gap cheaply: whoever
runs the KB update pass already knows the diff at the moment they make it — no
new detection mechanism, no scraping, no LLM diffing step. See
`kb-update-runbook.md` "Authoring a news note" for the authoring workflow.

## What's built (backend)

- **Compiler** — `docs/kb/news/*.md` parsed as a distinct artifact class
  (`engine/build/kb_compiler.py`: `parse_news_doc`, `parse_frontmatter_list`,
  `markdown_section`), GATE 11 (`kb_slug`/`affected_kb_slugs` resolve,
  bilingual summary, diff block present, `sources:` non-empty — see below),
  compiled into `artifact["news"]`
  (never mixed into `artifact["kb"]` — no blueprint ever anchors a news slug).
  One real note landed as the worked example:
  `docs/kb/news/2026-07-hecs-thresholds-2026-27.md`.
- **Engine accessor** — `fh_engine_kb:news_for_slugs/1`: set-intersection of a
  card's consulted KB slugs against each note's `affected_kb_slugs`.
- **Engine primitive** — `GET`/`PATCH /api/engine/plan-cards/:id/news`
  (`fh_engine_h_news.erl`), tenant-scoped like `/checklist-status`. GET returns
  relevant, non-dismissed notes; PATCH `{"news_slug": "..."}` dismisses one.
- **Storage** — migration `007_news_dismissed.sql`:
  `plan_cards.dismissed_news_jsonb`, the same card-user-set-layer pattern as
  `checklist_status_jsonb` (005). Store functions: `card_kb_slugs/1`,
  `get_news_status/2`, `dismiss_news/2`.
- **Component-target mapping** — `kb_compiler.py`: `compute_affected_components`
  reverse-indexes each note's `affected_kb_slugs` against every blueprint's
  already-parsed `Component.anchors`, emitting `affected_components:
  {blueprint_slug: [component_name, ...]}` into `artifact["news"][slug]`
  (computed over every blueprint, not just in-scope, so a dormant B/D-mode
  match is ready the instant that mode activates). GATE 11 reports an INFO
  (not a fail) if a note's `affected_kb_slugs` match no component anchor
  anywhere — a real gap to notice, not a build blocker. `fh_engine_kb`/
  `fh_engine_h_news` pass the field straight through — no runtime change
  needed, it rides the existing `Entry` map. This was open design question #1;
  now resolved.
- **Source citation** — `kb_compiler.py`: news notes now carry `sources:`
  frontmatter (same `url`/`retrieved`/`path` shape as a KB fact doc, reusing
  `parse_sources_block`), required and FAIL-CLOSED at GATE 11 (same discipline
  as GATE 10 for fact docs — a news note is a user-facing claim, no exemption).
  This is **not** the fact doc's own `sources:` duplicated forward — it pins
  what the author actually had open when writing *this* diff. That never
  drifts, because a news note is immutable (unlike a fact doc's `sources:`,
  which tracks that doc's own next re-verify). Zero extra gathering cost: the
  Phase-1 author already has the primary open at authoring time
  (kb-update-runbook.md "Authoring a news note"). Emitted into
  `artifact["news"][slug]["sources"]`; `fh_engine_kb`/`fh_engine_h_news` pass
  it straight through, no runtime change. This was open design question #2
  (below the fold of #1's original numbering); now resolved.
- **Proof** — `engine/erlang/test/news_smoke.escript`: migration applies at
  boot, a fill's real `kb_versions` provenance correctly matches the compiled
  HECS note, GET/PATCH round-trip, `affected_components` names
  `buyer_profile` under `blueprints.fhb-domestic-au` in the GET response, the
  note carries a non-empty `sources` list, the `news_dismissed` audit/SSE
  event fires, and the fail-closed cases (missing field, no auth, wrong
  tenant, wrong method) all hold — against real Docker Postgres, not a mock.

## What's left (shell) — detailed checklist

UX direction settled 2026-07-07 (see "Resolved design questions" below): a
**sticky auto-sliding ticker strip** (top or bottom of the plan projection),
not per-tile badges — headlines wrap to the available width; the user can
advance/reverse by swipe or arrow buttons; tapping a headline opens a
popup sheet/modal with the full bilingual summary + diff + source link, AND
scrolls to/highlights the `affected_components` tile.

- [x] **Fetch layer** (2026-07-07). `PlanProjection.svelte`'s `load()` calls
      `getNews(cardId)` (fire-and-forget, `lib/api.ts`) once the card is
      `ready`, holding the result in a `news` state array consumed by task 29's
      ticker. This needed a NEW shell-backend proxy (none existed): `GET`/
      `PATCH /api/plan-cards/:id/news` (`fh_shell_h_plan_card.erl`, router
      entry in `fh_shell_http.erl`, `fh_shell_engine_client:get_news/2` +
      `dismiss_news/3`), same ownership-gate + zero-meter posture as
      `checklist-status`. Proven end-to-end against a stub engine
      (`plancard_proxy_smoke.escript`, 6 new assertions: relay, ownership 404,
      auth 401, for both GET and PATCH). `dismissNews` (frontend) is also
      built here since it's the same endpoint's other verb — task 31 wires it
      to a UI action.
- [x] **Ticker component (Svelte)** (2026-07-07). `NewsTicker.svelte`: a sticky
      strip (mounted above the lifecycle sub-tab rail inside a new shared
      `.pp-sticky-top` wrapper in `PlanProjection.svelte` — ONE sticky
      container rather than each element sticking independently, so the rail
      simply flows below the ticker with no magic offset math for that pairing,
      and the region is free to grow with the ticker's wrapped headline text).
      One headline visible at a time; auto-advances every 6s (paused/reset by
      manual nav); arrow buttons + swipe (touchstart/touchend, threshold 40px,
      `preventDefault` on a real swipe suppresses the trailing synthetic click)
      both work. Renders nothing for an empty `news` array (task 33's default,
      already true here). Tapping the headline calls an `onSelect` prop —
      currently unwired (task 28 will pass a real handler).

      **Regression caught by advisor review before commit, then fixed in the
      same slice:** the Budget tab's own nested sub-rail (`Tabs.svelte`) sticks
      just below the top-level sticky region via a `--tabrail-top` CSS var,
      previously a **hardcoded `2.2rem`** on `.pp-calc` calibrated to the bare
      `.pp-subtabs` rail's height alone. Wrapping the ticker into the same
      sticky region made that constant stale — whenever news is present (i.e.
      exactly when this feature is active, not an edge case), the budget rail
      would stick 2.2rem down when the real region was taller, hiding it behind
      the opaque header while scrolling. Fixed by measuring the region's real
      height (`bind:clientHeight` on `.pp-sticky-top` → `stickyTopHeight`
      state) and feeding it to `--tabrail-top` as an inline style on
      `.pp-subcontent`, replacing the hardcoded rem entirely. This is exactly
      the class of bug `svelte-check`/autofixer/the no-news path all structurally
      miss — worth remembering: **a CSS var hand-calibrated to one sibling's
      height goes stale the moment a NEW sibling is inserted above it in the
      same sticky region; prefer a measured height over a hardcoded rem for any
      such stacked-sticky offset.**

      Verified via `svelte-check` (0/0) and the Svelte MCP autofixer (no
      issues); **not** walked through in a live browser — the full stack (shell
      backend + engine + both Postgres instances + an authed session + a plan
      card whose consulted KB slugs match a real note) is disproportionate to
      stand up for a chrome-only layout change with no new backend dependency.
      Honest gap, not a claim of full verification.
- [x] **Bilingual rendering** (2026-07-07). Closes now that `NewsDetailSheet.svelte`
      (task 28) is the second real consumer: it reuses the exact same
      `$lang === 'vi' ? summary_vi : summary_en` (honest-partial fallback)
      ternary `NewsTicker.svelte` already had, not a reinvented mechanism.
- [x] **Tap → detail sheet + tile highlight** (2026-07-07). `NewsDetailSheet.svelte`
      (built on `Modal.svelte`, the existing drill-down surface — attach-
      property/settlement/lease all open into it — not `SuburbSheet.svelte`'s
      bespoke tab-bearing panel, since this is a "small popup with a few
      facts", not an outer container) renders the bilingual summary, a
      generic `JSON.stringify(diff, null, 2)` dump (no fixed schema — see
      below), and the source link (closes task 32 too — see its entry).
      `PlanProjection.svelte`: `NewsTicker`'s `onSelect` → `onNewsSelect` just
      opens the sheet (`selectedNews` state); a `data-component={componentId}`
      attribute was added to `ComponentCard.svelte`'s root `<section>` (no
      such DOM hook existed before) so a component can be found; `onNewsClose`
      (the sheet's `onClose`) does the actual work — looks up
      `note.affected_components[blueprintSlug]`, switches `sub` to whichever
      `uiTabs` entry contains the first named component, `await tick()`,
      `scrollIntoView({behavior:'smooth', block:'center'})`, and flashes a
      `.pp-card-highlight` class (a `highlighted` prop threaded into
      `ComponentCard.svelte`) for 3s (`clearTimeout`'d and re-armed on a rapid
      re-tap so an earlier timer can't clear a later highlight early).

      **Caught by advisor before commit: the scroll+highlight must fire on
      sheet DISMISSAL, not on open.** The first draft did the scroll +
      3s-flash inside `onNewsSelect`, at the same moment the sheet opens.
      `Modal.svelte` is a full-screen scrim overlay — the entire flash
      lifecycle would play out **behind** it while the user is still reading
      summary+diff+source (routinely >3s), so by the time they closed the
      sheet the highlight had already expired unseen — "tile highlight," a
      named half of this task's deliverable, would be silently dropped in the
      actual usage path even though `svelte-check`/autofixer both passed.
      Same class of bug as task 29's stacked-sticky regression: invisible to
      any static check, only manifests at realistic runtime dwell time. Fixed
      by moving the tab-switch/scroll/highlight into `onNewsClose` (the
      sheet's `onClose`) so the user sees it the instant they dismiss the
      sheet, not before.

      **Known-thin rendering, not yet revisited:** the diff is rendered as a
      raw `JSON.stringify` dump (e.g. the HECS note's `old_value`/`new_value`/
      `bands` blob verbatim) rather than a friendlier before→after line,
      because `diff` has no fixed schema today (`kb_compiler.py`'s
      `parse_news_doc` parses whatever JSON follows `## Diff`) — inventing a
      bespoke old/new-value UI would assume a shape no gate enforces. The
      `{old_value, new_value}` shape is the only one that exists in practice
      so far; worth a friendlier renderer if/when a second note's shape
      confirms it's the norm, not a one-off.

      Verified via `svelte-check` (0/0) and the Svelte MCP autofixer (no
      issues) on every touched file; **not** walked through in a live browser
      (same honest-gap reasoning as task 29 — full stack stand-up is
      disproportionate for shell-only wiring with no new backend dependency).
- [x] **Source link** (2026-07-07, via task 28). `NewsDetailSheet.svelte`
      renders `sources[0].url` (first entry only — a note may carry more than
      one corroborating source, but the sheet needs only the primary) as a
      link — no new backend, `sources` was already on the GET response.
- [ ] **Dismiss wiring.** On user dismissal, call
      `PATCH /api/engine/plan-cards/:id/news` with `{"news_slug": ...}`;
      optimistically remove from the local ticker rotation rather than
      waiting on a round-trip.
- [ ] **Empty state.** No relevant news → no ticker at all (already the API's
      default; the shell just needs to not render the strip for `[]`).
- [ ] **Mobile layout pass.** A persistent sticky strip claims vertical space
      on every viewport, more than a per-tile badge would — confirm it
      doesn't compete with or cover other plan-card UI on small viewports
      (the original ask this feature grew from).

## Resolved design questions

**Component-target mapping (resolved 2026-07-07).** A news note's
`affected_kb_slugs` names a *KB doc*, not a *blueprint component* — the shell
needs the latter to know which tile to badge. `kb_compiler.py`'s
`compute_affected_components` now reverse-indexes each note's
`affected_kb_slugs` against every blueprint's already-parsed
`Component.anchors` (computed once at compile time, over every blueprint —
not just in-scope), emitting `affected_components: {blueprint_slug:
[component_name, ...]}` into `artifact["news"][slug]`. A KB slug anchored by
more than one component (`multi-fill`, an already-known shape) lists every
matching name. GATE 11 reports an INFO (not a fail) when a note's
`affected_kb_slugs` match no component anywhere, so an unreachable note is
noticed at compile time, not silently shipped with nothing to badge.
`fh_engine_kb:news_for_slugs/1` and `fh_engine_h_news` pass the field straight
through (no runtime change) — verified in `news_smoke.escript`.

**Source citation (resolved 2026-07-07).** A news note originally carried no
`sources:` of its own — the reasoning was that `kb_slug`'s fact-doc `sources:`
is the citation of record, and duplicating it would drift out of sync at that
doc's next re-verify. That reasoning didn't hold: a news note is **immutable**,
so pinning it to what was actually checked for *this* diff is a historical
citation, not a live pointer — it can't drift because it never gets
re-evaluated against the fact doc's current state. `kb_compiler.py`'s
`parse_news_doc` now parses `sources:` (reusing `parse_sources_block`, the
same shape as a fact doc), GATE 11 fails the build if it's empty (same
fail-closed bar as GATE 10, no exemption — a news note is as user-facing as a
fact doc), and it's emitted into `artifact["news"][slug]["sources"]`. Zero new
gathering cost: the Phase-1 author already has the primary source open when
writing the note. The one existing note was backfilled with the same
ATO+corroborating URLs already cited by `kb.hecs.thresholds.md`.

**UX shape — ticker, not per-tile badges (resolved 2026-07-07).** Considered
and rejected: small dismissible badges inline per affected component tile.
Chosen instead: a single sticky auto-sliding ticker strip (top or bottom of
the plan projection) cycling through all relevant, non-dismissed notes,
swipe/arrow-navigable, tapping opens a detail sheet. This also resolves what
was previously an open "multi-item behavior" question (the carousel *is* the
answer to more-than-one-relevant-note). The `affected_components` mapping
isn't made redundant by this — it's repurposed from "which tile gets a badge"
to "which tile does tapping this headline scroll to and highlight," so the
compile-time work still does real work at read time.

## Open design questions (real gaps, not yet resolved)

**1. Push vs pull.** The engine primitive is pull-only (the shell calls GET).
There is no SSE push for "a news note just became relevant" the way
`component_filled`/`checklist_status_changed` are pushed — because a news note
is authored **offline, at deploy time**, not during a live turn. A card open
in a session when a deploy lands won't see the new note until the next GET
(page load / reconnect). This is an acceptable v1 gap (deploys are infrequent)
but is a deliberate limitation, not an oversight — noting it so it isn't
rediscovered as a "bug."

**2. Interaction on tap — do NOT wire to "refresh my plan" yet.** It's tempting
to make tapping a ticker headline trigger a real recompute via
[`plan-card-refresh.md`](plan-card-refresh.md). That mechanism is **dev-only
today** (`ENGINE_DEV_PROVISION`-gated, production policy deferred) and its
resolver-only sweep explicitly skips the agentic `mortgage_finance` leaf. Until
that mechanism has a real production trigger, the detail sheet should only show
the diff/explanation text + source link and the tile scroll/highlight — never
a "refresh now" action a production user could click.

## Related

[`kb-update-runbook.md`](kb-update-runbook.md) (the authoring workflow),
[`plan-card-refresh.md`](plan-card-refresh.md) (the separate recompute
mechanism this deliberately does NOT trigger yet),
[`wedge-build-sequence.md`](wedge-build-sequence.md) (aggregate status row).
