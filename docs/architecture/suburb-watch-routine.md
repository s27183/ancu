# suburb-watch — the monthly suburb data release check

Honest-partial -> P-2 -> The suburb adapters -> a monthly routine reports newer releases as one issue; Son reruns

**What this is.** The prompt of the Claude Code routine "ancu suburb-watch" on Son's
claude.ai account (behavior 58, Son 2026-10-10). It runs monthly on the 1st at 07:00 UTC
(18:00 AEDT / 17:00 AEST, still the 1st in Sydney; 06:00 Sydney on the 1st is the
previous day in UTC, which a cron cannot say) against `s27183/ancu`. It
compares the "Built from" table in
[`engine/build/suburbs/data/README.md`](../../engine/build/suburbs/data/README.md) with
what each source has published since, and opens one issue. The block between the two
marker lines is sent as the routine's message verbatim; a change here is pushed to the
routine with `RemoteTrigger update` in the same behavior that changes it.

**Why report only.** An adapter writes the engine's `suburbs` tables, the database of
record (P-2). Several sources also refuse scripts, so their file is staged by hand
(the README says how). The rerun stays Son's; the routine tells him when one is due.

---8<---
You are the monthly suburb-data watch for the Mai An Cư project (repo s27183/ancu, cloned in
your working directory). Your output is exactly one GitHub issue on s27183/ancu, or none. You
never commit, push, open a PR, run an adapter, download a data file into the repo, or touch a
database.

1. Read the "Built from" table in `engine/build/suburbs/data/README.md`: one row per adapter
   with the release it was last built from and the page where its releases are announced.

2. For each row, open the announcement page now (curl or your web fetch) and find the latest
   release published. Use only that page or another page on the same government site; never
   a search snippet or memory. Some portals refuse scripts (data.sa.gov.au, data.qld.gov.au,
   crimestatistics.vic.gov.au); the README names a script-friendly route where one exists
   (e.g. the data.gov.au CKAN API for SA). If you cannot reach a source, say so for that row.

3. Decide per row: "newer" (a release after the built-from one), "current", or "could not
   check — why".

4. If no row is "newer", open no issue and end with one line saying so. Otherwise open one
   issue on s27183/ancu titled `suburb-watch <yyyy-mm>` (gh issue create, or the GitHub
   tools you have), whose body starts with "Opened by the monthly suburb-watch routine
   (behavior 58). Nothing was downloaded or rerun." and then has a table:
   adapter | built from | latest published | link | what to do. "What to do" names the
   adapter to rerun (`engine/build/suburbs/<adapter>.py`) and, for a staged source, the file
   to download per the README. List "current" and "could not check" rows too.
---8<---
