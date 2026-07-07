# KB news feature — surfacing KB changes to the buyer they affect

**Status:** backend built + live-verified 2026-07-07 (`news_smoke.escript`, all
assertions pass against Docker PG). Shell rendering not started.

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
  bilingual summary, diff block present), compiled into `artifact["news"]`
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
- **Proof** — `engine/erlang/test/news_smoke.escript`: migration applies at
  boot, a fill's real `kb_versions` provenance correctly matches the compiled
  HECS note, GET/PATCH round-trip, the `news_dismissed` audit/SSE event fires,
  and the fail-closed cases (missing field, no auth, wrong tenant, wrong
  method) all hold — against real Docker Postgres, not a mock.

## What's left (shell) — detailed checklist

- [ ] **Fetch layer.** Call `GET /api/engine/plan-cards/:id/news` when the plan
      projection loads (and/or on SSE reconnect — see the push-vs-pull open
      question below).
- [ ] **Placement.** Decide how a returned news item maps to a specific
      plan-card component to badge (see "Open question: component-target
      mapping" below — this likely needs a small compiler addition before the
      shell can do this cleanly).
- [ ] **Badge component (Svelte).** Small, dismissible indicator inline in the
      plan projection — not a separate feed screen (per the map-first-home /
      plan-card-as-central-artifact constraints). Expandable on tap to show
      the `summary_en`/`summary_vi` text.
- [ ] **Bilingual rendering.** Pick `summary_en` vs `summary_vi` by the active
      locale, reusing the existing i18n picker pattern (no new mechanism).
- [ ] **Dismiss wiring.** On user dismissal, call
      `PATCH /api/engine/plan-cards/:id/news` with `{"news_slug": ...}`;
      optimistically remove from the local view rather than waiting on a
      round-trip.
- [ ] **Multi-item behavior.** Decide the stacking UI when more than one
      relevant, non-dismissed note attaches to the same component (a count
      badge? most-recent-only? a small list?) — not decided.
- [ ] **Empty state.** No relevant news → no UI at all (already the API's
      default; the shell just needs to not render a badge for `[]`).
- [ ] **Mobile layout pass.** Confirm the badge doesn't compete with or cover
      other plan-card UI on small viewports (the original ask this feature
      grew from).

## Open design questions (real gaps, not yet resolved)

**1. Component-target mapping.** A news note's `affected_kb_slugs` names a
*KB doc*, not a *blueprint component* — but the shell needs to know which
component tile to badge. A KB slug can be anchored by more than one component
(`multi-fill` is already a known shape, `kb_compiler.py`'s reg.leaves), so this
isn't a 1:1 lookup the shell can hardcode. The clean fix is a **small compiler
addition**: `kb_compiler.py` already parses each component's `**KB anchors:**`
during blueprint parsing (`Component.anchors`) — GATE 11 (or `build_artifact`)
could reverse-index this into each news item's `affected_components:
{blueprint_slug: [component_name, ...]}`, computed once at compile time from
data already in hand. Not built — flagged here rather than having the shell
improvise a client-side lookup against the raw KB anchors.

**2. Push vs pull.** The engine primitive is pull-only (the shell calls GET).
There is no SSE push for "a news note just became relevant" the way
`component_filled`/`checklist_status_changed` are pushed — because a news note
is authored **offline, at deploy time**, not during a live turn. A card open
in a session when a deploy lands won't see the new note until the next GET
(page load / reconnect). This is an acceptable v1 gap (deploys are infrequent)
but is a deliberate limitation, not an oversight — noting it so it isn't
rediscovered as a "bug."

**3. Interaction on tap — do NOT wire to "refresh my plan" yet.** It's tempting
to make tapping a news badge trigger a real recompute via
[`plan-card-refresh.md`](plan-card-refresh.md). That mechanism is **dev-only
today** (`ENGINE_DEV_PROVISION`-gated, production policy deferred) and its
resolver-only sweep explicitly skips the agentic `mortgage_finance` leaf. Until
that mechanism has a real production trigger, the badge should only show the
diff/explanation text — never a "refresh now" action a production user could
click.

## Related

[`kb-update-runbook.md`](kb-update-runbook.md) (the authoring workflow),
[`plan-card-refresh.md`](plan-card-refresh.md) (the separate recompute
mechanism this deliberately does NOT trigger yet),
[`wedge-build-sequence.md`](wedge-build-sequence.md) (aggregate status row).
