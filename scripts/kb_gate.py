#!/usr/bin/env python3
"""Decide whether a kb-watch PR may merge itself, and say why not if it may not.

    python3 scripts/kb_gate.py --base <ref> --head <ref> --branch <head branch>
        [--labels a,b] [--checks-ok yes|no] [--out <dir>]

Regulated figures are grounded -> P-7 -> The KB update -> a verified KB update publishes itself; the rest is held for Son
Behavior 74 (Son 2026-10-12: too much to review by hand). A kb-watch PR (the weekly
kb-watch-<date>, or since behavior 134 news-watch's daily kb-watch-news-<date>)
merges itself only when each thing it changes is one of these:
  - date-only: in a docs/kb doc, only `last_verified:` / `retrieved:` /
    `next_edition:` lines moved;
  - a new news note (docs/kb/news/, added; a note is never edited);
  - a figure change that passed two independent checks: every number the PR adds
    to a doc's text appears in a word-for-word quote on that doc's sources, each
    quote is found in its saved copy (tests/kb_quote_check.py), and each quoting
    source is a primary — a government host (*.gov.au) or, for a provider's fee, the
    provider's own site (PROVIDER_HOSTS, per doc: lenders, FX providers, land
    registries; behavior 85) — and the independent kb-verify routine
    has labelled the PR `kb-verified` after re-reading the sources itself.
Anything else holds the whole PR, with one reason per held item: a path outside
docs/kb and docs/sources, a new or deleted doc (a new rule or scheme is kind-2/3,
a session with Son), an edited news note, a number no quote states, a quote from
a broker, comparison or other secondary site, a quote missing from its copy, no
`kb-verified` label, a `kb-hold` label (kb-verify disagreed), or done checks not
passed. Fail-closed: whatever this cannot classify is held. One PR, all or nothing
— a held item keeps the date-only part waiting too (concluded: splitting a PR
here would mean rewriting the routine's branch; the routine can split later).

Writes <out>/decision.json ({"decision": "merge"|"hold"|"skip", "reasons": [...],
"items": [...]}), <out>/comment.md and, on a hold, <out>/issue.md: the body of the one
issue assigned to Son that the workflow opens or updates when live (a dry run only
says it would). kb-watch files its own could-not-verify and kind-2/3 findings, which
never reach the diff; this issue carries what the gate held.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tests"))
from kb_quote_check import archived_text, doc_fails, parse_sources  # noqa: E402

BRANCH_PREFIX = "kb-watch-"
ALLOWED_ROOTS = ("docs/kb/", "docs/sources/")
# `next_edition:` is when the next yearly edition is due (behavior 134,
# tests/kb_freshness.py): a date kb-watch moves on, not a figure a reader sees.
DATE_FIELDS = re.compile(r"^\s*-?\s*(last_verified|retrieved|next_edition):\s*\S+\s*$")
# Lines that only add or move the support for a figure (a source's saved copy and
# quotes) — not themselves a figure change.
SUPPORT_LINE = re.compile(r"^\s*(-\s*url:|path:|quotes:|-\s*[\"'])")
GOV_SUFFIX = ".gov.au"
# A lender's own site is the primary for its own policy (LENDER-POLICY tier,
# invariants.md); comparison and broker sites never are.
PRIMARY_LENDER_HOSTS = (
    "commbank.com.au", "nab.com.au", "anz.com.au", "westpac.com.au",
    "stgeorge.com.au", "banksa.com.au", "bankofmelbourne.com.au", "macquarie.com.au",
    "ing.com.au", "suncorp.com.au", "bankwest.com.au", "boq.com.au",
    "bendigobank.com.au", "amp.com.au", "hsbc.com.au", "citi.com.au",
)
# A provider's own published price is the primary for its own fee (behavior 85, Son
# 2026-10-16): a bank's or transfer service's fee schedule for the FX doc, a lender's
# for its discharge fee, a land registry's for its registration fee. Per doc (or doc
# folder): a provider's site proves nothing about another doc's figures, and a
# comparison or broker site is never a provider.
FX_PROVIDER_HOSTS = PRIMARY_LENDER_HOSTS + (
    "wise.com", "ofx.com", "westernunion.com", "remitly.com",
    "vietcombank.com.vn", "techcombank.com", "techcombank.com.vn", "bidv.com.vn",
    "vietinbank.vn", "acb.com.vn",
)
REGISTRY_HOSTS = ("nswlrs.com.au", "titlesqld.com.au")
PROVIDER_HOSTS = {
    "docs/kb/lender/": PRIMARY_LENDER_HOSTS,
    "docs/kb/fx/typical-spreads-vnd-aud.md": FX_PROVIDER_HOSTS,
    "docs/kb/fx-providers/": FX_PROVIDER_HOSTS,
    "docs/kb/existing-home-sale/net-proceeds.md": PRIMARY_LENDER_HOSTS + REGISTRY_HOSTS,
    "docs/kb/buyer-costs/inspections-conveyancing-fees.md": REGISTRY_HOSTS,
}
DERIVED = ("docs/kb/copy/", "docs/kb/bilingual/", "docs/kb/journey/")
LABEL_OK = "kb-verified"
LABEL_HOLD = "kb-hold"

NUM = re.compile(r"\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?|\d+(?:[.,]\d+)?")


def numbers(text: str) -> set[str]:
    """Numbers in text, normalised: thousands separators dropped (1,000 / 1.000 →
    1000), a decimal comma read as a point; a fraction under 1 also as its percent."""
    out = set()
    for m in NUM.findall(text):
        if re.fullmatch(r"\d{1,3}(?:[.,]\d{3})+", m):
            n = re.sub(r"[.,]", "", m)
        else:
            n = m.replace(",", ".")
        try:
            v = float(n)
        except ValueError:
            continue
        out.add(f"{v:g}")
        if 0 < v < 1:
            out.add(f"{round(v * 100, 6):g}")
    return out


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def host_ok(url: str, path: str) -> bool:
    host = (urllib.parse.urlsplit(url or "").hostname or "").lower()
    if host.endswith(GOV_SUFFIX):
        return True
    hosts = next((hs for where, hs in PROVIDER_HOSTS.items() if path.startswith(where)), ())
    return any(host == h or host.endswith("." + h) for h in hosts)


def changed_lines(base: str, head: str, path: str) -> tuple[list[str], list[str], list[str], list[str]]:
    """(+frontmatter, -frontmatter, +body, -body) lines of the PR's diff of one doc,
    told apart by line number against each side's closing '---'."""
    old = git("show", f"{base}:{path}") if path_exists(base, path) else ""
    new = git("show", f"{head}:{path}")

    def fm_end(text: str) -> int:
        ms = [i for i, line in enumerate(text.splitlines(), 1) if re.match(r"^---\s*$", line)]
        return ms[1] if len(ms) > 1 and ms[0] == 1 else 0

    old_end, new_end = fm_end(old), fm_end(new)
    diff = git("diff", "-U0", f"{base}...{head}", "--", path)
    add_fm, del_fm, add_body, del_body = [], [], [], []
    o = n = 0
    for line in diff.splitlines():
        m = re.match(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if m:
            o, n = int(m.group(1)), int(m.group(2))
            continue
        if line.startswith(("+++", "---")):
            continue
        if line.startswith("-"):
            (del_fm if o <= old_end else del_body).append(line[1:])
            o += 1
        elif line.startswith("+"):
            (add_fm if n <= new_end else add_body).append(line[1:])
            n += 1
    return add_fm, del_fm, add_body, del_body


def copy_at(ref: str, path: str) -> str | None:
    """A saved copy's searchable text as `ref` has it (archived_text, from git)."""
    if not path_exists(ref, path):
        return None
    raw = subprocess.run(["git", "show", f"{ref}:{path}"], cwd=ROOT, check=True,
                         capture_output=True).stdout
    with tempfile.TemporaryDirectory() as d:
        f = Path(d) / Path(path).name
        f.write_bytes(raw)
        return archived_text(f)


def path_exists(ref: str, path: str) -> bool:
    return subprocess.run(["git", "cat-file", "-e", f"{ref}:{path}"], cwd=ROOT,
                          capture_output=True).returncode == 0


def decide(base: str, head: str, branch: str, labels: set[str], checks_ok: bool) -> dict:
    if not branch.startswith(BRANCH_PREFIX):
        return {"decision": "skip", "reasons": [f"{branch} is not a kb-watch branch"], "items": []}
    reasons: list[str] = []
    items: list[str] = []
    needs_verify: list[str] = []
    quote_pool: set[str] = set()
    pending_derived: list[tuple[str, set[str]]] = []

    for row in git("diff", "--name-status", f"{base}...{head}").splitlines():
        status, *paths = row.split("\t")
        path = paths[-1]
        if not path.startswith(ALLOWED_ROOTS):
            reasons.append(f"`{path}`: outside docs/kb and docs/sources")
            continue
        if path.startswith("docs/sources/"):
            items.append(f"`{path}`: saved source copy")
            continue
        if not path.endswith(".md"):
            reasons.append(f"`{path}`: not a KB doc")
            continue
        if path.startswith("docs/kb/news/"):
            if status == "A":
                items.append(f"`{path}`: new news note")
            else:
                reasons.append(f"`{path}`: a news note is never edited (status {status})")
            continue
        if status != "M":
            reasons.append(f"`{path}`: {'new' if status == 'A' else 'removed'} doc — a new rule or scheme is kind-2/3, for a session with Son")
            continue
        add_fm, del_fm, add_body, del_body = changed_lines(base, head, path)
        fm_moves = [line for line in add_fm + del_fm if not DATE_FIELDS.match(line)]
        if not add_body and not del_body and not fm_moves:
            items.append(f"`{path}`: date-only")
            continue
        support_only = all(SUPPORT_LINE.match(line) for line in fm_moves if line.strip())
        new_nums = numbers("\n".join(add_body)) - numbers("\n".join(del_body))
        text = git("show", f"{head}:{path}")
        srcs = parse_sources(text)
        if path.startswith(DERIVED):
            pending_derived.append((path, new_nums))
            items.append(f"`{path}`: copy change, numbers {sorted(new_nums) or 'none'}")
            needs_verify.append(path)
            continue
        quoted = [s for s in srcs if s.get("quotes")]
        stated = set().union(*(numbers(" ".join(s["quotes"])) for s in quoted)) if quoted else set()
        quote_pool |= stated
        missing = sorted(new_nums - stated)
        if missing:
            reasons.append(f"`{path}`: {', '.join(missing)} {'is' if len(missing) == 1 else 'are'} in the change but in no quote on its sources")
        for s in quoted:
            if not host_ok(s.get("url", ""), path):
                host = urllib.parse.urlsplit(s.get("url", "")).hostname or s.get("url")
                reasons.append(f"`{path}`: quoted source {host} is not a primary (a government site, or the provider's own for this doc's fee) — secondary source")
        for f in doc_fails(Path(path), text, lambda sp: copy_at(head, sp)):
            reasons.append(f"`{path}`: " + f.split(": ", 1)[1])
        if not add_body and not del_body and support_only:
            items.append(f"`{path}`: sources re-saved and quoted, no figure moved")
        else:
            items.append(f"`{path}`: figure change, new numbers {sorted(new_nums) or 'none'}")
        needs_verify.append(path)

    for path, nums in pending_derived:
        missing = sorted(nums - quote_pool)
        if missing:
            reasons.append(f"`{path}`: {', '.join(missing)} not stated by any quote in this PR")

    if needs_verify and LABEL_OK not in labels:
        reasons.append(f"no `{LABEL_OK}` label: kb-verify has not re-checked {len(needs_verify)} changed doc(s)")
    if LABEL_HOLD in labels:
        reasons.append(f"`{LABEL_HOLD}` label: kb-verify disagreed (see its comment)")
    if not checks_ok:
        reasons.append("done checks have not passed")
    return {"decision": "hold" if reasons else "merge", "reasons": reasons, "items": items}


def comment(d: dict, live: bool) -> str:
    mode = "" if live else " (dry run — nothing is merged)"
    head = {
        "merge": f"**kb-gate{mode}: {'merging' if live else 'would merge'}** — every change is date-only, a new news note, or a verified, quoted figure from a primary.",
        "hold": f"**kb-gate{mode}: held for Son** — {len(d['reasons'])} reason(s), {'filed' if live else 'would be filed'} as an issue assigned to him:",
        "skip": f"kb-gate{mode}: not a kb-watch PR.",
    }[d["decision"]]
    lines = [head, ""]
    lines += [f"- {r}" for r in d["reasons"]]
    if d["items"]:
        lines += ["", "<details><summary>What the PR changes</summary>", ""]
        lines += [f"- {i}" for i in d["items"]]
        lines += ["", "</details>"]
    lines += ["", "<!-- kb-gate -->"]
    return "\n".join(lines) + "\n"


def issue(d: dict, pr: str) -> str:
    """The body of Son's issue for a held PR: each reason, and the PR to act on."""
    lines = [f"kb-gate held #{pr}, so it did not publish itself. Each reason is something to decide or fix:", ""]
    lines += [f"- [ ] {r}" for r in d["reasons"]]
    lines += ["", f"Merge #{pr} yourself once these are settled, or close it. (behavior 74)", "", "<!-- kb-gate-issue -->"]
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--head", required=True)
    ap.add_argument("--branch", required=True)
    ap.add_argument("--labels", default="")
    ap.add_argument("--checks-ok", default="no")
    ap.add_argument("--live", default="no")
    ap.add_argument("--out", default=".")
    ap.add_argument("--pr", default="?")
    a = ap.parse_args()
    d = decide(a.base, a.head, a.branch, {x for x in a.labels.split(",") if x},
               a.checks_ok == "yes")
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "decision.json").write_text(json.dumps(d, indent=2) + "\n")
    c = comment(d, a.live == "yes")
    (out / "comment.md").write_text(c)
    if d["decision"] == "hold":
        (out / "issue.md").write_text(issue(d, a.pr))
    print(c)
    return 0


if __name__ == "__main__":
    sys.exit(main())
