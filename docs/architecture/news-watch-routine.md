# news-watch — the daily news routine

Regulated figures are grounded -> P-7 -> The KB -> a daily routine proposes the day's news as one PR; the gate merges it when verified, else Son

**What this is.** The prompt of the Claude Code routine "ancu news-watch" on Son's
claude.ai account (behavior 134, Son 2026-10-19: "our users are reading the news and
the facts daily"). It runs daily at 19:00 UTC (06:00 AEDT / 05:00 AEST) against
`s27183/ancu`. It does the news half of the weekly kb-watch run
([kb-watch-routine.md](kb-watch-routine.md) step 3): the Home Affairs visa check and
the government sites, nothing else. The weekly kb-watch keeps the fact re-checks and
writes news only for a doc whose figure it changed. The block between the two
`---8<---` lines is sent as the routine's message verbatim; a change here is pushed
to the routine with `RemoteTrigger update` in the same behavior that changes it.

**Why its own routine.** A news item read a week late is old news to a reader who
opens the app every day; a fact re-check is not urgent in the same way, and doing
30 of them daily would cost thirty times as much. Splitting them keeps the daily run
to a few minutes: measured 2026-10-19, the first forced run took 201 s and opened no
PR, because the one open kb-watch PR (#164) already covered the day's visa releases;
it restored `visa-watch.json` as step 2 says. It guessed four news-page addresses
wrong (404) or was refused (403), so step 2 names each page.

**Why a script lists the news (behavior 136, Son 2026-10-25: "there have been few
KB PRs but no news were detected").** Reading the pages by eye, PRs #168–170 took
QRO's and ASIC's script-rendered pages for quiet and skipped Treasury's 16 Oct
housing ministers' communiqué as "before the window" (the newest note's
`authored_date`). Step 2 now runs `scripts/news_watch.py`, which reads each source in
the form that carries its items (QRO's RSS, ASIC's newsroom JSON, the ministers'
dated lists) from a stored `since`, and the PR accounts for every line it prints.

**How it stays inside the gate.** Its branch is `kb-watch-news-<yyyy-mm-dd>`, so
scripts/kb_gate.py (`BRANCH_PREFIX = "kb-watch-"`) judges it as it judges kb-watch,
and kb-verify, now daily ([kb-verify-routine.md](kb-verify-routine.md)), re-reads
its notes against their sources. A day's PR may still be open the next morning (held
for Son, or not yet re-checked by kb-verify): the next run then skips what an
open `kb-watch-*` branch already covers, and leaves `visa-watch.json` to the PR that
already moves it, so two open PRs never change the same file.

---8<---
You are the daily news watch for the Mai An Cư project (repo s27183/ancu, cloned in your
working directory). Your output is exactly one pull request against `main`, or none. You
never merge, never push to `main`, never deploy, never touch a database, and never edit
anything outside `docs/kb/news/`, `docs/kb/terms/` and `docs/sources/`.

Read first, in this order, and follow them: `docs/design/invariants.md` (the goal: every
regulated figure traces to a verified, cited source; every news item bilingual), the
"Home Affairs visa check" section of `docs/architecture/kb-update-runbook.md`, and one
existing news note in `docs/kb/news/` as the shape to copy.

1. What is already covered. Run
   `git fetch origin main '+refs/heads/kb-watch-*:refs/remotes/origin/kb-watch-*'`
   (add `--unshallow` if the clone is shallow), then
   `git branch -r --no-merged origin/main --list 'origin/kb-watch-*'`. For each such
   branch B, list the news notes it adds:
   `git diff --name-only --diff-filter=A origin/main...B -- docs/kb/news`, and read
   their sources. Those, and every note already in `docs/kb/news/` on main, are covered:
   never write a second note for the same change. Note also whether any B changes
   `docs/sources/homeaffairs/visa-watch.json` or `docs/sources/news-watch.json`.

2. News. Run `python3 scripts/news_watch.py --update`. It reads every government
   source in `docs/sources/news-watch.json` (RBA, ASIC, ATO, Treasury and its
   ministers, Budget, Revenue NSW, SRO Vic, QRO, RevenueSA, WA, FIRB, Housing
   Australia) and prints, per source, each item dated on or after the file's `since`
   (`ITEM <date> <source> <title> <url>`), or `<source>: no items since <date>`, or
   `COULD NOT READ <source> …`; then it moves `since` to yesterday. Never narrow the
   window yourself: an item it prints is in the window, even if it is older than the
   newest note. Every `ITEM` line is a candidate: if a note on main or an open
   `kb-watch-*` branch from step 1 already covers it, say which; otherwise open it with
   curl (`-A Mozilla/5.0 -L`), and write a note if a Vietnamese buyer of Australian
   property would care, or give in one phrase why not (an enforcement action against
   one adviser, a payroll-tax login change). A `MORE` line means the source's list may
   go further back than its first page: open the page it names and treat each item on
   or after `since` there as an `ITEM`. An `OFF-LIST` line is a link off *.gov.au or a
   redirect off the source's host: never open it, and cite nothing from it.
   Government sources only: no news outlet, blog or aggregator. A source that prints
   `COULD NOT READ` is named unread in the PR body (or the final line), never taken as
   quiet and never replaced by a non-government page.
   Commit `docs/sources/news-watch.json` (its new `since`) only if no open branch from
   step 1 changes it; otherwise restore it
   (`git checkout -- docs/sources/news-watch.json`) and leave it to that PR.
   Visa news (Home Affairs and its ministers): run `python3 scripts/visa_watch.py
   --update`. Each `RELEASE` or `PAGE` line it prints is a candidate: open it with
   curl (never WebFetch, which Home Affairs refuses), read only what changed, and write
   a note if a buyer would care, as the runbook's "Home Affairs visa check" says —
   archive each page you cite with `scripts/archive_source.py`, short paragraphs,
   tables for quotas, plain visa names. A release about security, disasters or the arts
   is not visa news. Commit `docs/sources/homeaffairs/visa-watch.json` (its new `since`)
   only if no open branch from step 1 changes it; otherwise restore it
   (`git checkout -- docs/sources/homeaffairs/visa-watch.json`) and leave it to that PR.
   Each note is `docs/kb/news/<yyyy-mm>-<slug>.md`, frontmatter `slug: kb.news.<same>`,
   `category` (one of finance, market, property, scheme, tax, visa), `effective_from`,
   `authored_date: <today>`, `sources:` (url + retrieved today, a page you opened, with
   `path:` its saved copy), and four sections: Headline (EN), Headline (VI), Summary
   (EN), Summary (VI). Vietnamese is natural Vietnamese for a buyer, with the same figures
   as the English. Every number and date in a summary is stated on the page it cites.
   Information, not advice: no "you should". A `## Notes` section is for the reviewer;
   nothing a user reads goes there. Where the note concerns a KB doc, add
   `affected_kb_slugs:` as the existing notes do; never edit that doc (the weekly
   kb-watch re-checks docs).
   Every acronym in a headline or summary (ASIC, FHOG…) must be a term in
   `docs/kb/terms/*.md`, and so should a named rule a Vietnamese buyer may not know
   (Ministerial Direction): the reader taps it for an explanation. Add a missing one in the
   same PR, to the existing terms file of its area, shaped like its neighbours: `name`,
   `meaning` and `why` in Vietnamese and English, `forms` (the spellings the notes use),
   and the government page it rests on (`url`, or `kb` for a KB doc). A term explains; it
   states no figure — figures belong in the note.

3. Gate. Set up with `uv sync --frozen` (install uv with pip if it is missing) and run
   each command below with `.venv/bin/python` in place of `python3`; fix what you wrote
   until all pass:
   `python3 tests/validate_build.py`, `python3 engine/build/kb_compiler.py`,
   `python3 tests/bilingual_eval.py`, `python3 tests/kb_quote_check.py`,
   `python3 tests/terms_coverage.py` (it names any acronym with no term). Do not commit
   `engine/erlang/priv/kb/artifact.json` (it is untracked). If a check cannot run in your
   environment, say which and why in the PR body.

4. Publish. If you wrote no note and both `visa-watch.json` and `news-watch.json` are
   unchanged (or restored), open no PR and end with every line step 2's scripts printed,
   each with its outcome. Otherwise: branch `kb-watch-news-<yyyy-mm-dd>` from
   `main`, one commit per note (its source copies and terms with it) and one for
   the watch files that changed, push, and open a PR titled `news-watch <yyyy-mm-dd>`
   whose body has:
   - the news notes added, each with its EN headline and source
   - the news check: every `ITEM` line news_watch.py printed with its outcome (the note
     written, the reason none, or the note or open PR that already covers it), every
     `MORE` line with what its page held, every `OFF-LIST` line as printed, and every
     `COULD NOT READ` line as printed — never a summary in their place
   - the visa check: each `PAGE`/`RELEASE` line with what you did with it (a note, why
     none, or the open PR that already covers it), each `COULD NOT READ` line as printed,
     or the one line `Home Affairs visa check: no change since <date>`
   - any check that could not run
   The first line of the body says: "Opened by the daily news-watch routine (behaviors
   134, 136). The kb-gate check merges it when every note is verified; otherwise it waits for
   Son."
   Change nothing in the PR after the kb-verify routine has commented on it, unless a
   check failed.
---8<---
