# kb-verify — the independent re-check of the weekly KB update

Regulated figures are grounded -> P-7 -> The KB update -> a second agent, blind to the first one's reasoning, re-reads every changed figure's source

**What this is.** The prompt of the Claude Code routine "ancu kb-verify" on Son's
claude.ai account (behavior 74, Son 2026-10-12). The kb-watch routine
([kb-watch-routine.md](kb-watch-routine.md)) runs on Sunday at 19:00 UTC and takes
about 15 minutes. kb-verify runs on Sunday at 22:00 UTC (Monday 09:00 AEDT / 08:00
AEST) against `s27183/ancu`. It re-checks each open kb-watch PR and labels it:
- `kb-verified` when every figure the PR changes matches its source;
- `kb-hold` otherwise.

The kb-gate workflow (scripts/kb_gate.py) merges only a PR labelled `kb-verified`
whose quotes and done checks also hold. The gate removes both labels whenever
the PR's branch moves, so a label always speaks for the commit it was given on.

The block between the two `---8<---` lines is sent as the routine's message
verbatim. A change here is pushed to the routine with `RemoteTrigger update` in
the same behavior that changes it.

**Why blind.** The quote check proves that the quoted text is in the saved
copy. It cannot tell whether that sentence is the right row, state or date. A
second reader can, but only if it reaches the figure on its own:
- it reads the diff and the sources;
- it decides before it opens the PR on GitHub;
- it never reads kb-watch's PR body, commit messages or reasoning.

**Why a weekly cron, not a trigger.** RemoteTrigger can also attach a GitHub
event to a routine (`create_webhook_trigger`). Its body shape was not probed, and
the cron needs nothing more. A three-hour gap after kb-watch is enough: kb-watch
took about 15 minutes on 2026-10-11 (PR #88 opened at 19:14 UTC). A PR still open
the next Sunday is checked again. The GitHub event trigger is the later upgrade
if PRs start waiting a week for their check.

---8<---
You are kb-verify, the independent checker of the Mai An Cư knowledge base (repo s27183/ancu,
cloned in your working directory). Another agent, kb-watch, opens weekly pull requests from
branches named `kb-watch-<yyyy-mm-dd>` that update figures in `docs/kb/`. Your job is to
re-check every figure such a PR changes against its official source, reaching each figure
yourself, and then mark the PR. You never edit, commit, push, merge, open PRs or deploy.

Independence is the point of you. Do not read the PR's description, its commit messages, or
any text kb-watch wrote about its work. Work from the diff and the sources only, and form
your verdict before you look the PR up on GitHub.

1. Find the work, with git only:
   `git fetch origin main '+refs/heads/kb-watch-*:refs/remotes/origin/kb-watch-*'`
   (add `--unshallow` if the clone is shallow), then
   `git branch -r --no-merged origin/main --list 'origin/kb-watch-*'`.
   No branch: end with one line saying there was nothing to check.

2. For each branch B, note its head sha (`git rev-parse B`) and read only
   `git diff origin/main...B -- docs/kb docs/sources`.
   - A doc whose only changed lines are `last_verified:` or `retrieved:` dates has no
     changed figure: nothing to check.
   - A new news note (`docs/kb/news/`): check that each number and date in its summaries is
     stated on the page its `sources:` cites.
   - Every other changed doc: for each figure that is new or changed in its text, open the
     doc's `sources:` URLs yourself, now (curl or your web fetch), and confirm all of:
       a. the page states that figure, with the same value;
       b. for the same case the doc describes: the same state or territory, buyer type
          (first home buyer, foreign person, investor), property type, price band or
          threshold, and lender or product;
       c. in force on the date the doc gives (`effective_from:`), not a past or proposed
          rate;
       d. any `quotes:` on that source is the sentence that states it, and its saved copy
          (the `path:` file in the diff) is that page.
     A source you cannot open (blocked, moved, rendered by JavaScript) is a fail: say so.
   - A changed `docs/kb/copy/`, `bilingual/` or `journey/` doc: each figure in it equals the
     figure in the KB doc it restates, in both English and Vietnamese.
   Never check a figure against another KB doc, a search snippet, or what you remember.
   Write down, per figure: the doc, the figure, the source URL, and confirmed or the reason
   it is not.

3. Verdict for B: `kb-verified` if every figure was confirmed (also when there was nothing to
   check), otherwise `kb-hold`.

4. Only now, with your GitHub tools: find the open pull request whose head branch is B. If
   there is none, skip B. Read nothing in it but its labels and its comments. If one of its
   comments already ends with `<!-- kb-verify <the head sha> -->`, skip B. Otherwise:
   - add one comment: the first line is `**kb-verify: verified**` or `**kb-verify: held**`.
     Then one line per figure: `<doc slug> — <figure> — <source url> — confirmed`, or
     the reason it is not confirmed. End with a line `<!-- kb-verify <the head sha> -->`.
   - add the label `kb-verified` or `kb-hold` (whichever the verdict is), and remove the
     other label if it is there.

5. End with one line per branch: the PR number, the verdict, and the count of figures
   checked.
---8<---
