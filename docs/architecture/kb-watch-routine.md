# kb-watch — the weekly KB and news routine

Regulated figures are grounded -> P-7 -> The KB -> a weekly routine proposes the KB update as one PR; the gate merges it when verified, else Son

**What this is.** The prompt of the Claude Code routine "ancu kb-watch" on Son's
claude.ai account (behavior 57, Son 2026-10-10). The routine runs weekly
(Sunday 19:00 UTC = Monday 06:00 AEDT / 05:00 AEST) against `s27183/ancu` and
walks [kb-update-runbook.md](kb-update-runbook.md) Track A phases 0, 1, 2, 4, 5,
stopping before phase 6: it opens a PR and never merges or deploys. This file is
the source of the routine's prompt. The block between the two `---8<---` lines is
sent as the routine's message verbatim; a change here is pushed to the routine with
`RemoteTrigger update` in the same behavior that changes it.

**Why a PR and not a commit.** The goal's figures must trace to a *verified*
source. The routine reads the primary and drafts. Behavior 57 made Son the verifying
reader. Behavior 74 (Son 2026-10-12) replaces him for what can be proven:
- every figure the routine changes carries a word-for-word quote from a saved copy
  of a primary (`path:` + `quotes:` on the source; tests/kb_quote_check.py);
- the independent kb-verify routine ([kb-verify-routine.md](kb-verify-routine.md))
  re-reads the sources and labels the PR;
- the kb-gate workflow (scripts/kb_gate.py) merges the PR when all of that holds,
  and holds it otherwise.

What only Son can decide — a could-not-verify, a kind-2/3 change — the routine files
as one issue assigned to him, so he never has to read the PR to find it.

---8<---
You are the weekly KB watch for the Mai An Cư project (repo s27183/ancu, cloned in your
working directory). Your output is exactly one pull request against `main`, or none. You
never merge, never push to `main`, never deploy, never touch a database, and never edit
anything outside `docs/kb/` and `docs/sources/`.

Read first, in this order, and follow them: `docs/design/invariants.md` (the goal: every
regulated figure traces to a verified, cited source; every news item bilingual),
`docs/architecture/kb-update-runbook.md` (Track A, phases 0–5), and one existing news note
in `docs/kb/news/` as the shape to copy.

1. Scope. Run `python3 tests/kb_freshness.py`. Take the 10 most overdue docs (largest
   overdue first; ties by slug). Skip `kb.copy.*`, `kb.bilingual.*`, `kb.journey.*`.

2. Re-verify each of the 10 against the primaries its own `sources:` list cites — open
   each URL now (curl or your web fetch). Never verify against another KB doc, a search
   snippet, or memory. For each doc decide exactly one:
   - unchanged: every figure still matches the primary. Bump `last_verified:` and each
     opened source's `retrieved:` to today. Nothing else.
   - changed: a figure moved. Change the figure in the body and in the `## Rules` block,
     and its bilingual copy under `docs/kb/copy/` where it is interpolated. Save the page
     you read it on with `python3 scripts/archive_source.py <url> <docs/sources/<area>/<name>.txt>`
     (a PDF too: save its extracted text as .txt). On that source in the doc's
     `sources:`, add `path:` (the saved copy) and `quotes:`, a list of sentences copied
     word for word from the saved copy that state each new figure, for example:
         - url: https://www.revenue.nsw.gov.au/...
           retrieved: <today>
           path: docs/sources/nsw-revenue/surcharge-purchaser-duty.txt
           quotes:
             - "Surcharge purchaser duty is 9% of the dutiable value"
     Every number you add to the doc's body must appear in one of its quotes, written
     the same way. Quote only a primary: a government site (*.gov.au) for a regulated
     figure, or the provider's own published price for its own fee: the lender's site
     for a lender policy or discharge fee, a bank's or transfer service's fee page for
     the FX docs, the land registry (nswlrs.com.au, titlesqld.com.au) for its
     registration fee (scripts/kb_gate.py PROVIDER_HOSTS). A figure whose only source is
     a broker, comparison or news site is still drafted, but it will be held for Son.
     For a first-visit fact (`docs/kb/facts/`), also make sure every `quotes` string the
     fact carries is found in the archive (GATE 12). Bump
     `last_verified:`; bump `effective_from:` only if the rule's own start date changed.
     Only a kind-1 point-figure change is drafted. A new rule, scheme or lifecycle phase
     (kind-2 or kind-3 in the runbook) is not drafted: list it in the PR body for a
     session with Son, and leave the doc unchanged.
   - could not verify: the source is down, moved, or no longer states the figure. Leave
     the doc unchanged and give the reason.

3. News. Write a news note for each change a Vietnamese buyer of Australian property would
   care about: every "changed" doc from step 2, and any change published since the newest
   note's `authored_date` on these government sites: ato.gov.au, revenue.nsw.gov.au,
   sro.vic.gov.au, qro.qld.gov.au, revenuesa.sa.gov.au, finance.wa.gov.au (RevenueWA),
   treasury.gov.au and budget.gov.au, homeaffairs.gov.au, firb.gov.au,
   housingaustralia.gov.au, rba.gov.au, asic.gov.au. Government sources only: no news
   outlet, blog or aggregator. Skip anything already covered by an existing note. Each
   note is `docs/kb/news/<yyyy-mm>-<slug>.md`, frontmatter `slug: kb.news.<same>`,
   `category` (one of finance, market, property, scheme, tax, visa), `effective_from`, `authored_date: <today>`, `sources:` (url + retrieved
   today, a page you opened), and four sections: Headline (EN), Headline (VI), Summary
   (EN), Summary (VI). Vietnamese is natural Vietnamese for a buyer, with the same figures
   as the English. Information, not advice: no "you should". A `## Notes` section is for
   the reviewer; nothing a user reads goes there. Where the note concerns a KB doc, add
   `affected_kb_slugs:` as the existing notes do.

4. Gate. Set up with `uv sync --frozen` (install uv with pip if it is missing) and run
   each command below with `.venv/bin/python` in place of `python3`; fix what you wrote
   until all pass:
   `python3 tests/validate_build.py`, `python3 engine/build/kb_compiler.py`,
   `python3 tests/resolver_eval.py`, `python3 tests/eligibility_benefit_eval.py`,
   `python3 tests/cash_duty_eval.py`, `python3 tests/mortgage_eval.py`,
   `python3 tests/ownership_eval.py`, `python3 tests/bilingual_eval.py`,
   `python3 tests/outcome_validate.py`, `python3 tests/kb_quote_check.py`. Do not commit `engine/erlang/priv/kb/artifact.json`
   (it is untracked). If a check cannot run in your environment, say which and why in the
   PR body.

5. Publish. If nothing changed at all (no doc touched, no note written), open no PR and end
   with one line saying so. Otherwise: branch `kb-watch-<yyyy-mm-dd>` from `main`, one
   commit per doc and one per note, push, and open a PR titled `kb-watch <yyyy-mm-dd>`
   whose body has:
   - one line per doc taken in step 1: `<slug> — unchanged` / `<slug> — changed <old> →
     <new> (<source url>)` / `<slug> — could not verify: <why>`
   - the news notes added, each with its EN headline and source
   - kind-2/3 changes found and not drafted
   - any check that could not run
   The first line of the body says: "Opened by the weekly kb-watch routine (behaviors 57,
   74). The kb-gate check merges it when every change is verified; otherwise it waits
   for Son."
   Change nothing in the PR after the kb-verify routine has commented on it, unless a
   check failed.

6. Son's issue. If step 2 found any doc you could not verify or any kind-2/3 change,
   open one GitHub issue in s27183/ancu with your GitHub tools, assigned to `s27183`,
   titled `kb-watch <yyyy-mm-dd>: needs Son`. It lists one line per item:
   `<slug> — could not verify: <why> (<url>)` or `<slug> — kind-2/3: <what changed>
   (<url>)`, and links the PR (or says no PR was opened). If an open issue with that
   title already exists, add to it instead. If there is no such item, open no issue.
---8<---
