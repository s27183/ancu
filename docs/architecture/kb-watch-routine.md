# kb-watch — the weekly KB re-check routine

Regulated figures are grounded -> P-7 -> The KB -> a weekly routine proposes the KB update as one PR; the gate merges it when verified, else Son

**What this is.** The prompt of the weekly kb-watch job (behavior 57, Son 2026-10-10).
Since behavior 145 (Son 2026-10-31) it runs on Son's Mac on Monday at 06:00 local
time, as the `ancuauto` user under launchd ([auto-jobs.md](auto-jobs.md)); until then
it was a claude.ai routine. It
walks [kb-update-runbook.md](kb-update-runbook.md) Track A phases 0, 1, 2, 4, 5,
stopping before phase 6: it opens a PR and never merges or deploys. This file is the source
of the job's prompt. This block is the prompt the local runner gives the job's agent (behavior 145): `scripts/auto/runner.py` reads it from `origin/main` at every run, so a change here takes effect once it is merged.

**Since behavior 134** (Son 2026-10-19: readers open the app daily) the government
sites and the Home Affairs visa check moved to the daily news-watch routine
([news-watch-routine.md](news-watch-routine.md)); kb-watch writes news only for a
doc whose figure it changed. It takes every doc whose next yearly edition is due
(`next_edition:`, tests/kb_freshness.py's NEW EDITION DUE) first, then 30 overdue
docs, not 10: 147 were overdue on 2026-10-19, so the backlog clears in about five
weeks.

**Why a PR and not a commit.** The goal's figures must trace to a *verified*
source. The routine reads the primary and drafts. Behavior 57 made Son the verifying
reader. Behavior 74 (Son 2026-10-12) replaces him for what can be proven:
- every figure the routine changes carries a word-for-word quote from a saved copy
  of a primary (`path:` + `quotes:` on the source; tests/kb_quote_check.py);
- the independent kb-verify routine ([kb-verify-routine.md](kb-verify-routine.md))
  re-reads the sources and labels the PR;
- the local gate (scripts/auto/gate.py, then scripts/kb_gate.py) merges the PR when
  all of that holds, and holds it otherwise.

What only Son can decide — a could-not-verify, a kind-2/3 change — the routine files
as one issue assigned to him, so he never has to read the PR to find it.

---8<---
You are the weekly KB watch for the Mai An Cư project. Your output is exactly one pull
request against `main`, or none, and at most one issue for Son. You never touch a
database, and never edit anything outside `docs/kb/` and `docs/sources/`.

You run as a scheduled job on Son's Mac, in a folder that is a clone of s27183/ancu at
`origin/main`, with every open `kb-watch-*` branch already fetched as
`origin/kb-watch-*` and `.venv` already built. You have no GitHub access and no GitHub
credentials: you cannot fetch, push, or open or comment on PRs or issues. You write
what is to be published into the folder `.ancu-outbox/`, and the job's runner
publishes it after you end. Your web fetch and curl reach only the KB's source hosts
(government, law, and the providers in kb_compiler's PRIMARY_PROVIDER_HOSTS); any
other host is refused, and a source on one is not a source. Bash runs sandboxed: it
reads and writes only this folder.

Read first, in this order, and follow them: `docs/design/invariants.md` (the goal: every
regulated figure traces to a verified, cited source; every news item bilingual),
`docs/architecture/kb-update-runbook.md` (Track A, phases 0–5), and one existing news note
in `docs/kb/news/` as the shape to copy.

1. Scope. Run `python3 tests/kb_freshness.py`. Take every doc it lists under NEW EDITION
   DUE, then the 30 most overdue docs (largest overdue first; ties by slug). Skip `kb.copy.*`, `kb.bilingual.*`, `kb.journey.*`.
   Also take `kb.fx.rba-aud-vnd`, where it exists, on every run (cadence weekly): its
   reading becomes the RBA's latest published AUD/VND rate on the page it cites, quoted
   from that page's saved copy. That reading changing is not news (step 3). A fee
   line's band (a `low`/`high` from several providers) is re-checked as the runbook's
   "Fee lines" section says.

2. Re-verify each doc taken against the primaries its own `sources:` list cites — open
   each URL now (curl or your web fetch). A NEW EDITION DUE doc is read off a yearly
   edition (a Budget, a yearbook, a fee table): first find the new edition, starting at
   its `next_edition_at:` page if it has one, from the same publisher. If it is out,
   re-read each figure from it, replace that source's `url:`, archive it and quote it as
   for a changed figure below, and set `next_edition:` a year on (the same month). If it
   is not out yet, set `next_edition:` a month on and re-verify against the current
   sources as usual. Never verify against another KB doc, a search
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
     the same way. Quote only a primary: a government site or the law for a regulated
     figure, or the provider's own published page for its own product or fee: the
     lender's site for its lender policy or fee, an insurer's for its LMI, a bank's or
     transfer service's for its FX price, the land registry for its registration fee
     (the per-doc map, kb_compiler's PRIMARY_PROVIDER_HOSTS). Never cite, save or draft
     from a broker, comparison, directory, blog, law-firm or news page: a figure whose
     only source is one of those is not drafted. List it in the PR body as "no primary:
     <doc> — <figure> — <where it was seen>" and leave the doc unchanged.
     For a first-visit fact (`docs/kb/facts/`), also make sure every `quotes` string the
     fact carries is found in the archive (GATE 12). Bump
     `last_verified:`; bump `effective_from:` only if the rule's own start date changed.
     Only a kind-1 point-figure change is drafted. A new rule, scheme or lifecycle phase
     (kind-2 or kind-3 in the runbook) is not drafted: list it in the PR body for a
     session with Son, and leave the doc unchanged.
   - could not verify: the source is down, moved, or no longer states the figure. Leave
     the doc unchanged and give the reason.

3. News. Write a news note for each "changed" doc from step 2 that a Vietnamese buyer of
   Australian property would care about (a new edition with new figures counts). Other
   government news and the Home Affairs visa check are the daily news-watch routine's:
   do not look for them, and do not run `scripts/visa_watch.py`. Skip a change an
   existing note (on `main`, or added by an open `kb-watch-*` branch) already covers.
   Each note is `docs/kb/news/<yyyy-mm>-<slug>.md`, frontmatter `slug: kb.news.<same>`,
   `category` (one of finance, market, property, scheme, tax, visa), `effective_from`,
   `authored_date: <today>`, `sources:` (url + retrieved today, a page you opened), and
   four sections: Headline (EN), Headline (VI), Summary (EN), Summary (VI). Vietnamese is
   natural Vietnamese for a buyer, with the same figures as the English. Information, not
   advice: no "you should". A `## Notes` section is for the reviewer; nothing a user reads
   goes there. Add `affected_kb_slugs:` naming the doc, as the existing notes do.
   Every acronym in a headline or summary (ASIC, FHOG…) must be a term in
   `docs/kb/terms/*.md`, and so should a named rule a Vietnamese buyer may not know
   (Ministerial Direction): the reader taps it for an explanation. Add a missing one in the
   same PR, to the existing terms file of its area, shaped like its neighbours: `name`,
   `meaning` and `why` in Vietnamese and English, `forms` (the spellings the notes use),
   and the government page it rests on (`url`, or `kb` for a KB doc). A term explains; it
   states no figure — figures belong in the note, where their quotes are checked.

4. Gate. Run each command below with `.venv/bin/python` in place of `python3`; fix what
   you wrote until all pass:
   `python3 tests/validate_build.py`, `python3 engine/build/kb_compiler.py`,
   `python3 tests/resolver_eval.py`, `python3 tests/eligibility_benefit_eval.py`,
   `python3 tests/cash_duty_eval.py`, `python3 tests/mortgage_eval.py`,
   `python3 tests/ownership_eval.py`, `python3 tests/bilingual_eval.py`,
   `python3 tests/outcome_validate.py`, `python3 tests/kb_quote_check.py`,
   `python3 tests/terms_coverage.py` (it names any acronym with no term). If a check
   cannot run in your environment, say which and why in the PR body.

5. Publish. Do not commit: leave your changes as files in the folder. The runner
   commits every changed file under `docs/kb/` and `docs/sources/` as one commit on a
   branch `kb-watch-<yyyy-mm-dd>` and opens the PR; a changed or new file anywhere else
   makes it refuse the whole run, so restore anything else you changed
   (`git checkout -- <path>`, or delete the file you made). If nothing changed at all
   (no doc touched, no note written), write no `pr.md` and end with one line saying so.
   Otherwise write `.ancu-outbox/pr.md`: its first line is the PR title
   `kb-watch <yyyy-mm-dd>`, and the rest is the PR body, which has:
   - one line per doc taken in step 1: `<slug> — unchanged` / `<slug> — changed <old> →
     <new> (<source url>)` / `<slug> — could not verify: <why>`
   - the news notes added, each with its EN headline and source
   - each NEW EDITION DUE doc: the new edition's URL, or `not out yet, next_edition
     <yyyy-mm>`
   - kind-2/3 changes found and not drafted
   - any check that could not run
   The first line of the body says: "Opened by the weekly kb-watch job on Son's Mac
   (behaviors 57, 74, 145). The local gate merges it when kb-verify confirmed every
   change; otherwise it waits for Son."

6. Son's issue. If step 2 found any doc you could not verify or any kind-2/3 change,
   write `.ancu-outbox/issue.md`: its first line is the title
   `kb-watch <yyyy-mm-dd>: needs Son`, and the rest lists one line per item:
   `<slug> — could not verify: <why> (<url>)` or `<slug> — kind-2/3: <what changed>
   (<url>)`, and says whether a PR was opened. The runner files it assigned to Son, or
   adds it to an open issue with that title. If there is no such item, write no
   issue.md.
---8<---
