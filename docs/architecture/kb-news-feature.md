# KB news feature — surfacing KB changes to the buyer they affect

**Status update (2026-07-09): the per-card ticker UI described below (tasks
27-34 — fetch, ticker, tap → detail sheet + tile highlight, dismiss, empty
state, mobile pass) was REMOVED from `PlanProjection.svelte`, shell-only, on
Son's call — the homepage's unfiltered ticker (below) is enough on its own;
the per-card fetch/render/dismiss UI added clutter for little payoff. The
backend is fully untouched and still live** (`GET`/`PATCH
/api/plan-cards/:id/news`, `fh_engine_kb:news_for_slugs/1`, GATE 11,
`affected_components` reverse-indexing, the `sources:`/`headline`/`category`
fields) — **and so is `lib/api.ts`'s `getNews`/`dismissNews` client**, just
currently uncalled. Re-wiring is a `PlanProjection.svelte`-only change if
wanted again. The section below is left as the historical record of what was
built and verified; treat every "live" / "closed" claim in it as "was true
as shipped, UI since removed," not current shell behavior.

**Status:** feature COMPLETE as of 2026-07-08 — backend built + live-verified
2026-07-07 (`news_smoke.escript`, all assertions pass against Docker PG).
Compiler reverse-indexes each note's `affected_components`, and every note
carries a `sources:` citation (both resolved 2026-07-07 — see below). Shell:
fetch (27), ticker (29), tap → detail sheet + tile highlight (28), dismiss
wiring (31), and empty state (33) all closed 2026-07-07 (svelte-check 0/0 +
autofixer clean each time). Task 28's `NewsDetailSheet.svelte` is the second
consumer that closes both 30 (bilingual pick) and 32 (source link) — see
their entries. Task 34 (mobile layout pass), the one item needing a real
browser rather than static checks, closed 2026-07-08 — live-verified at a
375px viewport against the full local stack. All 8 checklist items done.

**Extended 2026-07-08 with a homepage ticker** — a second, deliberately
different surface (see "Homepage ticker" below): the per-card ticker inside
`PlanProjection` stays exactly as built (relevance-filtered, dismissable);
the homepage adds an unfiltered, non-dismissable ambient strip. Backend
(`fh_engine_kb:all_news/0`, `GET /api/engine/news`, `GET /api/news` shell
proxy) and shell (`+page.svelte` mount, `NewsDetailSheet`'s now-optional
`onDismiss`) both live-verified 2026-07-08 (`news_smoke.escript` extended,
new `news_proxy_smoke.escript`, Playwright screenshots at desktop + 375px
mobile — see "Homepage ticker" for the full record).

**Extended again 2026-07-09 with a required headline field + a real marquee**
— the shipped homepage ticker rendered the full `summary_en/vi` paragraph in
a discrete swap-every-6s box, which looked like a static wrapped banner, not
a ticker, and only carried one item (a content gap — one KB news doc
authored, not a bug). Fix: a new required `## Headline (EN|VI)` news-note
field (<=100 chars, GATE 11 fail-closed) supplies short ticker copy,
preferred over `summary_en/vi` in both ticker variants; `NewsTicker.svelte`
gained a `variant: 'discrete' | 'marquee'` prop — `discrete` (per-card,
default) is byte-for-byte unchanged, `marquee` (homepage only) is a real
continuously-scrolling single-line strip (CSS `translateX(-50%)` loop over
two duplicated runs), with a pause/play control, hover/focus-pause,
`prefers-reduced-motion` fallback, and a non-moving `.sr-only` list for
keyboard/AT users. See "Homepage ticker" below for the full record.
Committed `730196f`. **Backend smoke-tested live against Docker PG
(`news_smoke.escript`, `news_proxy_smoke.escript`, both re-run clean); shell
validated (`svelte-autofixer`, `svelte-check` 0/0)**, and since visually
re-verified in-browser — see the 2026-07-09 ticker-polish entry below, whose
Playwright pass covered the marquee too.

**Extended a third time 2026-07-09 with ticker polish + a two-layer News
overview sheet** — feedback on the marquee itself (looked plain, the pause
icon rendered as a blank box in some fonts, the detail popup showed raw
markdown asterisks and a JSON diff dump), plus a friend's suggestion (relayed
by Son) that tapping the ticker should open a categorized overview of every
note rather than jump straight to one. Fix: solid-band ticker chrome with a
"NEWS" label chip, an inline-SVG pause icon, a small markdown renderer for
the detail sheet's summary (`$lib/markdown.ts`), the diff dump dropped
entirely (audit content, not buyer-facing), a new `category` news-note field
(GATE 11 fail-closed), and `NewsListSheet.svelte` as a new layer-1 sheet.
Committed `c35639c`. **Live-verified in-browser** — see "Ticker polish + News
overview sheet" below for the full record.

**Extended a fourth time 2026-07-09 — per-card ticker moved to a sticky
footer, then restyled to match the homepage marquee's chrome.** Son asked to
move the in-plan (per-card, `PlanProjection`) ticker from the top of the
plan sheet to the bottom — top-of-sheet real estate goes to the lifecycle
sub-tab rail, news is a lower-urgency aside. Resolves the "top or bottom"
open question left in "What's left (shell)" since 2026-07-07.
`.pp-sticky-top` now holds only the sub-tab rail; a new `.pp-sticky-bottom`
(same `position: sticky` technique, opposite edge of the same `.sheet .body`
scroll region) holds `NewsTicker` at the bottom of `PlanProjection`, after
all tab content. Follow-up same day: Son asked for it to match the homepage
marquee's look — solid `var(--ink)`, full width, no border — instead of the
base `.pp-ticker` accent-soft chip. Since `.sheet .body` carries its own
padding, true edge-to-edge required the standard breakout trick (negative
margin cancelling the parent's padding, re-added as padding on the inner
ticker); `overflow: hidden` on `.sheet` clips it to the panel's rounded
corners on desktop for free. Homepage marquee (`+page.svelte`) untouched —
this is the per-card `discrete` variant only. `svelte-check` 0 errors/0
warnings, `svelte-autofixer` clean; **not live-verified in-browser** (Son had
just asked to free :8080/:8081 and opted to skip a restart-to-verify round
for this contained CSS/layout change — code-review + type-check only).

**Same day, scope note (not a KB-news change): the plan sheet's lifecycle
sub-tab rail was also decluttered.** Son separately asked to reduce
clustering in the sub-tab rail once glassy-effect styling was explicitly
dropped as a direction; `investor-foreign-au.md` alone declares 9 rail tabs
(10 incl. Q&A) — one flat scrollable pill row at that count. Fixed in
`PlanProjection.svelte` by grouping non-overview/qa tabs into the project's
buy/hold halves (`TAB_GROUP`, a static tab_id→group map grounded in each
blueprint's own component semantics) once `railTabs.length` exceeds
`RAIL_GROUP_THRESHOLD` (5) — under the threshold (Modes A/E) the rail is
byte-for-byte the original single row. Full detail — the grouping map, the
threshold reasoning, the pure-`$derived` fix after the autofixer flagged an
initial `$state`-in-`$effect` draft — is in code comments at the top of
`railTabs`'s declaration; not covered further here since it's outside this
doc's KB-news scope and isn't a blueprint/schema change (presentational
grouping over already-declared `ui_tabs`, shell-owned per engine-contract
§11).

**Extended a fifth time 2026-07-09 — the per-card ticker UI removed
entirely.** Son: "remove the news feed from the plan card (just the UI, not
the backend). The live ticker on the homepage is enough." Removed from
`PlanProjection.svelte`: the `news`/`selectedNews`/`highlightedComponents`
state, `loadNews`/`onNewsSelect`/`onNewsClose`/`onNewsDismiss`, the
`<NewsTicker>` footer and `<NewsDetailSheet>` render blocks, the `getNews`/
`dismissNews`/`NewsNote` imports, and the `.pp-sticky-bottom`/
`.pp-card-highlight` CSS those left behind (dead once their only caller was
gone). Also removed the single-purpose `highlighted` prop from the shared
`ComponentCard.svelte` — it existed only for this feature's tile-flash effect
and had no other caller. **Deliberately NOT touched:** `NewsTicker.svelte`,
`NewsDetailSheet.svelte`, `NewsListSheet.svelte`, their shared `.pp-ticker*`/
`.pp-news-*` CSS, and every `plan.news.*`/`home.news.*` i18n key — all still
load-bearing for the homepage marquee + two-layer overview sheet
(`+page.svelte`), which is completely unaffected. The backend (engine
primitive, shell proxy, migration, GATE 11) is untouched and still live, so
this is a clean, reversible shell-only removal — re-adding the per-card
ticker later is a `PlanProjection.svelte`-only change, not a re-plumbing job.
`svelte-check` 0/0, `svelte-autofixer` clean on both changed components.

**Extended a sixth time 2026-07-09 — the "only one item" content gap closed
(`b31e226`).** Son: "it's time to expand the news content." Rather than
author filler, this pass ran a real `kb-update-runbook.md` Track A cycle:
scanned the KB for genuine, verifiable regulatory diffs, found the resident
income-tax second bracket cut (16%→15% from 1 Jul 2026 — the outgoing
`kb.tax.income-tax-resident-2025-26` doc had already flagged and deferred
this exact change) was overdue and load-bearing (feeds `mortgage_finance`'s
net-income calc for Modes A/C/E), and treated it as the kind-1 point-figure
update it is: new `kb.tax.income-tax-resident-2026-27.md` (verified against
two secondary sources, ATO itself 403s), re-anchored the 3 domestic
blueprints **and** `fh_engine_mortgage.erl`'s hardcoded `?TAX`
slug/`resident_rates_2025_26` lookup key (re-anchoring the blueprint alone
would not have picked up the new schedule — the resolver macro is a second,
independent pointer), re-verified `serviceability_conformance.escript`'s
tax/capacity fixtures against live resolver output, all Track-A evals green.
Plus 2 zero-new-research notes reusing already-verified in-repo facts: the
FHG's 1 Oct 2025 expansion and FIRB's vacancy-fee doubling from 9 Apr 2024
(dormant until Mode B/D activate). Four notes now compiled (was one).
**Incidentally surfaced, left alone (out of this pass's scope):** two
`serviceability_conformance.escript` HECS-repayment fixtures ($95k/$125k
cases) are stale against `kb.hecs.thresholds`' current ($69,528 threshold)
schedule — a pre-existing drift from the earlier HECS-news-feature work,
confirmed present before this pass too (`git stash`-verified), flagged
inline in the escript for a future pass.

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
- [x] **Dismiss wiring** (2026-07-07). `NewsDetailSheet.svelte` gained an
      explicit "Got it, dismiss" button (`.primary`, the shared full-width
      affirmative-action style) alongside the existing ✕/backdrop/Escape
      close. `PlanProjection.svelte`'s `onNewsDismiss`: removes the note from
      the local `news` array immediately (no round-trip wait — the task's own
      wording), then PATCHes `{"news_slug": ...}` in the background and
      restores the note on any non-`ok` outcome — the same optimistic-then-
      reconcile posture as `toggleChecklist`. `NewsTicker.svelte`'s `safeIdx`
      already wraps a shrinking array cleanly (task 29's design), so no extra
      index-clamping was needed on top.

      **Caught by advisor before commit: dismiss must NOT reuse `onNewsClose`'s
      tab-switch.** The first draft called `onNewsClose()` from inside
      `onNewsDismiss` to get the existing scroll/highlight "for free." Async
      correctness was fine — but `onNewsClose` also does `sub =
      targetTab.tab_id`, i.e. it can switch the user to a *different lifecycle
      tab*. That's the right reaction to "closed without deciding anything"
      (task 28), but the wrong one for "I explicitly dismissed this" — being
      yanked to another tab as a side effect of an unrelated decision is
      unrequested motion. `advisor()` flagged this as a UX call worth making
      deliberately rather than inheriting from code reuse. Fixed: `onNewsDismiss`
      no longer calls `onNewsClose` at all — it closes the sheet quietly
      (`selectedNews = null`) with no tab-switch/scroll/highlight. Renamed the
      overloaded language in `onNewsClose`'s own comment (it said "on
      dismissing the sheet," which now collides with the task-31 dismiss
      action) to "on closing the sheet," with an explicit note that dismiss
      has its own handler and does not call it.

      **General lesson, a variant of task 28's:** reusing another handler for
      its side effect is only safe if ALL of that handler's side effects are
      wanted at the new call site — check the full list, not just the one you
      came for.

      Verified via `svelte-check` (0/0) and the Svelte MCP autofixer (clean)
      after both the initial implementation and the advisor-caught fix; no
      live browser walkthrough (same honest-gap reasoning as tasks 28/29).
- [x] **Empty state (confirmed 2026-07-07, no code change).** Verified rather
      than built: `NewsTicker.svelte`'s `{#if news.length > 0}` guard (task 29)
      already suppresses the entire strip for `[]`, and `.pp-sticky-top`
      (`app.css`) carries no margin/padding of its own — it's pure
      `position/z-index/background`, so with the ticker rendering nothing the
      container collapses to just the sub-tab rail's height. `stickyTopHeight`
      (`bind:clientHeight` on `.pp-sticky-top`, feeding `--tabrail-top`) tracks
      that collapse automatically, so the Budget tab's nested sub-rail doesn't
      leave a gap either. No dead space, no separate empty-state branch was
      ever needed.
- [x] **Mobile layout pass (2026-07-08, live-verified).** Confirmed in a real
      browser, not statically: stood up the full local stack (`docs/local-dev.md`
      — engine + shell backend + frontend, each in its own tmux session so
      `rebar3 shell` gets a real TTY) and drove it headless with Playwright at a
      375×812 viewport. Signed in via the dev-exposed magic link, then seeded a
      Mode-A plan card whose `audit_events.kb_versions_jsonb` provenance matches
      the compiled HECS note (cloned from an existing dev-DB fixture's
      `profiles`/`plan_cards`/`audit_events` rows onto a fresh test user +
      `plan_card_views` title — the news relevance test needs real provenance
      rows, not just `content_jsonb`; a first attempt that only cloned
      `content_jsonb` produced an empty `GET .../news`, tracing to
      `fh_engine_store:card_kb_slugs/1` reading `audit_events`, not the card's
      own JSON). Walked the real UI path (map → suburb search → suburb sheet →
      Plan tab, not a direct URL — this shell has no per-card route) and
      screenshotted four states: ticker at rest, ticker scrolled (inside
      `.sheet .body`, the sheet's actual scroll region — `window` doesn't
      scroll here), the Budget tab's nested sub-rail stacked under the ticker+
      outer rail, and that same nested state scrolled. All four: the ticker,
      the outer sub-tab rail, and the Budget tab's nested sub-rail stack
      cleanly with no overlap, no dead space, and no collision with the sheet
      header — confirming task 29's `stickyTopHeight`/`--tabrail-top` measured-
      offset fix holds at a real small-viewport width, not just in reasoning.
      Tapping the ticker headline also opens `NewsDetailSheet` cleanly as a
      full overlay with no layout collision. No console errors from the news
      UI itself (one unrelated `pmtiles.js` 404 — local dev has no real map
      tile data, pre-existing and orthogonal to this feature).

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

## Homepage ticker (added 2026-07-08)

**The gap this closes.** The shipped feature (tasks 27-34) was always
relevance-filtered and per-card: `GET /api/engine/plan-cards/:id/news`
intersects a note's `affected_kb_slugs` against the KB slugs *that specific
card* has consulted (`audit_events.kb_versions_jsonb`). Opening a saved card
only ever shows news that card's own fills touched — e.g. a Mode-A card whose
fill touched `kb.hecs.thresholds` shows the HECS note and nothing else. Son
flagged this didn't match his mental model of a homepage ticker showing "a
variety of news from the latest KB run," not a single card's dependency.

**Two independent axes, resolved separately:**

- **Location:** the per-card ticker stays exactly as built, unchanged. A
  *second*, separate ticker now also renders on the map-first home
  (`+page.svelte`), visible pre-login. This does not reopen the original
  "not a separate feed screen" call from the feature's first draft
  (`c14fd9a`) — that rejected a dedicated, navigable news *page*; a floating
  ambient *strip* (identical chrome to the per-card ticker) is the same kind
  of surface already shipped, just relocated, not a new navigation target.
- **Filtering:** the homepage ticker is deliberately **unfiltered** — every
  compiled news note, regardless of any card's relevance. This is a
  genuinely different read from the per-card one, not a relaxed version of
  it: "what's new in the KB lately" (ambient, buyer-agnostic) vs. "what
  changed that affects *your* plan" (targeted, per-card). Both stay live
  side by side; neither replaces the other.

**Dismiss does NOT apply to the homepage ticker — resolved, not deferred.**
The ticker strip itself is never dismissed (it's always there when there's
news, same `{#if news.length > 0}` empty-state posture as the per-card one).
What the per-card feature calls "dismiss" (task 31) was already narrower
than it sounds: `NewsDetailSheet.svelte`'s `onClose` (✕/backdrop/Escape) just
closes the popup, ephemeral, nothing persisted; a separate, explicit
"Dismiss" button inside the modal is the only thing that writes state — it
retires one note from *that card's* future rotation
(`plan_cards.dismissed_news_jsonb`, migration 007). The homepage ticker has
no card to retire a note *from*, so `NewsDetailSheet`'s `onDismiss` prop is
now optional — the homepage passes none, and the Dismiss button simply
doesn't render. No new storage, no per-user global dismiss layer.

**What's built:**

- **Engine:** `fh_engine_kb:all_news/0` — every note from `artifact["news"]`,
  sorted `authored_date` desc, no card/tenant filter (mirrors `rules/0`'s
  posture: global KB content). `GET /api/engine/news`
  (`fh_engine_h_news_feed.erl`) — authenticates the tenant JWT but does NOT
  scope by it, same pattern as `fh_engine_h_suburbs` (global reference data).
  No PATCH — no dismiss primitive at this level.
- **Shell:** `GET /api/news` (`fh_shell_h_news.erl`,
  `fh_shell_engine_client:list_all_news/0`) — PUBLIC, no user JWT, mints the
  anonymous system principal (`?ANON_USER_ID`), identical posture to
  `/api/suburbs`. `getAllNews()` in `lib/api.ts` — returns `[]` on any
  failure rather than a discriminated outcome type (this is ambient
  chrome, not load-bearing, same "nice-to-know" posture already established
  for the per-card ticker's empty state).
- **Shell UI:** `+page.svelte` fetches on `onMount`, mounts `NewsTicker.svelte`
  (at the time, unmodified — see "Headline + marquee" below for the
  2026-07-09 `variant` prop addition) inside a new `.home-news-band` wrapper
  (full-width, floating just below the fixed header). Tapping a headline
  opens the existing `NewsDetailSheet` with no `onDismiss`. The band's real
  height is measured (`bind:clientHeight` → `newsBandHeight` →
  `--home-news-h` CSS var) and fed into `.controls-cluster`/`.signin-banner`'s
  `top` offset (`calc(var(--header-h) + var(--home-news-h, 0px) + 0.75rem)`)
  so they shift down when the band is present — never a hardcoded constant.
  This mirrors the exact discipline task 29's regression already taught this
  codebase once (a hardcoded offset silently goes stale the moment the
  sticky region's real height changes).

**Proof (2026-07-08):**
- `news_smoke.escript` extended: `GET /api/engine/news` returns the HECS
  note unfiltered; unauthenticated → 401; and — the load-bearing assertion —
  the note **still appears in the homepage feed after the per-card ticker
  dismissed it**, proving the two reads are genuinely decoupled, not the
  same data filtered twice.
- New `news_proxy_smoke.escript` (mirrors `suburbs_proxy_smoke.escript`):
  drives the real cowboy handler over HTTP, confirms the public (no-JWT)
  relay and the bilingual summary survive the proxy hop, POST → 405.
- Playwright screenshots at 1280px and 375px against the full local stack
  (tmux-launched engine + shell, pre-existing vite): the band renders
  full-width directly below the header with no overlap with
  `.controls-cluster` (shifted correctly via `--home-news-h`) or the legend;
  tapping the headline opens the detail sheet with **zero** `.pp-news-dismiss`
  buttons present (confirmed via DOM count, not just visual read).

**Headline + marquee (added 2026-07-09).** After the above shipped, Son looked
at it and flagged two things: only one item showed, and it didn't look or
move like a ticker — it read as a static wrapped green banner.

- **Only one item: a content gap, not a bug.** The feed is unfiltered by
  design; exactly one `docs/kb/news/*.md` doc existed
  (`kb.news.2026-07-hecs-thresholds-2026-27`). More KB news docs → more
  ticker items automatically, no code change.
- **The look/motion complaint was real.** `.pp-ticker-headline` used
  `white-space: normal` and rendered `summary_en/summary_vi` — a full
  4-sentence paragraph authored for the detail sheet — inside a discrete
  swap-every-6s box built for a narrow per-card sidebar strip. Full-width on
  the homepage, that wrapped to several lines and never visibly "moved" with
  only one item to swap to.
- **New required news-note field: `## Headline (EN|VI)`.** Short ticker copy
  (<=100 chars, `NEWS_HEADLINE_MAX_CHARS` in `kb_compiler.py`), GATE 11
  fail-closed, bilingual-well-formed via the same `check_copy_template` used
  for Summary. `## Summary (EN|VI)` is unchanged — still the full explanation,
  read only in the detail sheet. Applied to **both** ticker variants
  (headline now preferred over summary everywhere) since it matches
  `NewsTicker.svelte`'s own original design intent ("chrome... one headline
  visible") without touching either variant's interaction model.
- **`NewsTicker.svelte` gained a `variant: 'discrete' | 'marquee'` prop**
  rather than being redesigned in place. `discrete` (default, per-card) is
  byte-for-byte the task-29/31 behavior — deliberately untouched, since Son's
  complaint was scoped to the homepage surface and changing the already-tested
  per-card model would have been unrequested scope creep. `marquee`
  (homepage only) is a real continuous single-line scroll: every headline
  concatenated into one strip, rendered twice back to back and looped via a
  CSS `translateX(-50%)` keyframe animation (the standard seamless-marquee
  technique) — reading speed is a length-based heuristic
  (`marqueeDurationS`), not a measured value. Accessibility: an explicit
  pause/play button plus CSS hover/focus-pause (WCAG 2.2.2 — auto-moving
  content lasting >5s needs a non-hover-only stop control), a
  `prefers-reduced-motion` override more specific than the app's existing
  blanket `* { animation-duration: 0.01ms }` catch-all (so it actually stops
  rather than flickering near-instantly), and a non-moving `.sr-only <ul>` of
  the same headlines as the real keyboard/AT-reachable path (the moving copy
  is `aria-hidden`).

**Proof (2026-07-09):** `kb_compiler.py` re-run clean with the new GATE 11
check (`PASS — artifact emitted`, `headline_en`/`headline_vi` present in
`artifact.json`); `svelte-autofixer` clean on `NewsTicker.svelte` and
`+page.svelte`; `svelte-check` 0 errors/0 warnings; `rebar3 compile` clean
(engine + shell); both `news_smoke.escript` and `news_proxy_smoke.escript`
re-run live against Docker PG, all assertions passing with the rebuilt
artifact. Visually re-verified in-browser in the next round below (the same
Playwright pass covers both extensions, since by the time it ran both had
landed).

**Ticker polish + News overview sheet (added 2026-07-09, commit `c35639c`).**
Three independent fixes plus one new feature, landed together:

- **Ticker chrome, modernized.** `.pp-ticker-marquee` is now a solid
  `var(--ink)` band with no border (previously `--accent-soft` background +
  a 1px `--accent` border, which read as a form field, not a news strip), a
  small rounded "NEWS"/"TIN TỨC" label chip ahead of the scrolling text
  (CNBC-style), and white text/separators instead of ink-on-light.
- **Pause icon: a real bug, not just a style nit.** The pause/play control
  used the Unicode glyphs `❚❚`/`▶` — confirmed via a headless-Chromium
  screenshot to render as a blank tofu box (no font fallback covers those
  code points reliably). Replaced with a small inline SVG (two bars / a
  triangle), which also let it be restyled as a subtle end-of-strip icon
  rather than a headline-weight element. The control itself stays — it is
  the WCAG 2.2.2 non-hover-only stop for continuously-moving content, needed
  because touch/keyboard users have no hover state to trigger the CSS-only
  pause.
- **Detail-sheet markdown, actually rendered.** `NewsDetailSheet.svelte` was
  interpolating `summary_en/vi` as plain text, so a KB-authored `**bold**`
  showed as literal asterisks (confirmed against the live HECS note, whose
  summary bolds the two dollar figures). New `$lib/markdown.ts`:
  HTML-escapes first, then converts a small inline subset
  (`**bold**`/`*italic*`/`` `code` ``/`[text](url)`, http(s)-only hrefs) to
  safe tags, rendered via `{@html}`. Deliberately not a markdown library
  dependency — these fields are single-paragraph prose, never block content
  (headers/lists/code fences), so four inline patterns is the actual
  surface area, not a placeholder for more.
- **Raw JSON diff dump, removed from the sheet.** `note.diff` is
  `kb_compiler.py`'s build-time audit artifact for what a note changed
  (`old_value`/`new_value`, no fixed schema) — authored for KB QA, not for a
  buyer to read. The sheet no longer renders it at all (the human-readable
  version is already the summary above it); `.pp-news-diff`/
  `.pp-news-subhead` CSS and the `plan.news.diff_heading` i18n key were dead
  after the removal and were deleted, not left as unused scaffolding.
  `note.diff` itself is untouched in the data model — only the display was
  cut.
- **New: the News overview sheet (a friend's suggestion, relayed by Son).**
  Previously tapping any homepage ticker headline opened `NewsDetailSheet`
  directly for *that* note. Now it opens `NewsListSheet.svelte` — every
  current note (reuses the already-fetched, unfiltered `homeNews` array, no
  new API call) grouped into category sections, scrollable via `Modal`'s
  existing `.mo-body`. Tapping a headline inside it opens the same
  `NewsDetailSheet` as before (layer 2, unchanged). Backed by a new
  `category` frontmatter field on `docs/kb/news/*.md` — a small closed enum
  (`visa | finance | scheme | tax | property | market`, `NEWS_CATEGORIES` in
  `kb_compiler.py`), GATE 11 fail-closed same as `headline`, **explicit and
  authored, not derived from `docs/kb/`'s slug namespace** (~40 namespaces,
  too fine-grained and not grouped into user-facing buckets). **Scope:
  homepage ticker only** — the per-card ticker in `PlanProjection` (discrete
  variant) keeps its exact tested direct-tap-to-detail + dismiss flow;
  changing it wasn't requested and dismiss doesn't belong in a general
  browse-everything list.

**Proof:** `svelte-check` 0 errors/0 warnings and `svelte-autofixer` clean on
every touched/new component; `kb_compiler.py` re-run clean
(`PASS — artifact emitted`, `category: "finance"` present in
`artifact.json`); confirmed `fh_engine_kb.erl`'s news accessors need no
functional change (the entry map is a generic pass-through, no field
whitelist). **Live-verified in-browser via Playwright** against the full
local stack (engine/shell/frontend restarted under tmux — the prior
foreground-terminal processes had stopped): the pause icon renders correctly
(previously confirmed as a tofu box, now two clean SVG bars); tapping a
ticker headline opens the overview sheet showing a "TÀI CHÍNH" (Finance)
section header with the HECS note; tapping that headline swaps to the
detail sheet, which renders `**67.000 đô la**`/`**69.528 đô la**` as real
bold text and shows no diff block (`.pp-news-diff` DOM count: 0).

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
