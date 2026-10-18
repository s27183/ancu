#!/usr/bin/env python3
"""List what Home Affairs and its ministers published about visas since the last check.

    python3 scripts/visa_watch.py            # report what moved since `since`
    python3 scripts/visa_watch.py --update   # the same, then set `since` to today
    python3 scripts/visa_watch.py --self-test

Regulated figures are grounded -> P-7 · The KB -> The daily news-watch routine -> visa changes reach the news without Son's machine
Behavior 104 (Son 2026-10-17): a cloud routine writes the visa news the seat on Son's
machine used to write — the weekly kb-watch until behavior 134 (Son 2026-10-19), the
daily news-watch since. This script is its trigger, not its reader: it
names what moved, and the routine opens each named page, archives it and writes the note
(kb-update-runbook.md "Home Affairs visa check").
Holds:   two kinds of signal, kept in docs/sources/homeaffairs/visa-watch.json —
         - the ministers' RSS feeds: a release dated on or after `since` (announcements,
           often before any visa page changes; the feeds also carry security and arts
           releases, which the routine ignores);
         - a fixed list of Home Affairs pages: one whose "Last updated" date
           (<span id="pageModified">dd/mm/yyyy …</span>, in the HTML as served) is on or
           after `since` (a rule that took effect: a new Direction, planning levels,
           a visa's conditions).
         On-or-after, so a change on the day of the last check is listed again rather
         than missed; the routine skips what an existing note already covers.
         One request at a time with a pause: a burst of ~25 parallel fetches got a
         browser blocked by Home Affairs (2026-10-16). A page that cannot be read is
         reported, never skipped silently. curl, not urllib (archive_source.py's block).
"""
from __future__ import annotations

import datetime
import email.utils
import json
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "docs/sources/homeaffairs/visa-watch.json"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")
PAUSE_S = 3


def fetch(url: str) -> tuple[int, str]:
    r = subprocess.run(
        ["curl", "-sL", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
        capture_output=True, text=True, errors="replace")
    body, _, code = r.stdout.rpartition("\n")
    return (int(code) if code.isdigit() else 0), body


def page_modified(html: str) -> datetime.date | None:
    m = re.search(r'id="pageModified"[^>]*>\s*(\d{1,2})/(\d{1,2})/(\d{4})', html)
    return datetime.date(int(m[3]), int(m[2]), int(m[1])) if m else None


def feed_items(xml: str) -> list[dict]:
    out = []
    for it in ET.fromstring(xml).iter("item"):
        when = email.utils.parsedate_to_datetime(it.findtext("pubDate") or "")
        out.append({"date": when.date(), "title": (it.findtext("title") or "").strip(),
                    "link": (it.findtext("link") or "").strip()})
    return out


def moved(state: dict, get=fetch, pause=PAUSE_S) -> list[str]:
    """One line per release or page that moved on or after state['since']; one per
    source that could not be read."""
    since = datetime.date.fromisoformat(state["since"])
    lines = []
    for i, url in enumerate(state["feeds"] + state["pages"]):
        if i and pause:
            time.sleep(pause)
        code, body = get(url)
        if code != 200:
            lines.append(f"COULD NOT READ {url} — HTTP {code}")
            continue
        if url in state["feeds"]:
            try:
                items = feed_items(body)
            except ET.ParseError as e:
                lines.append(f"COULD NOT READ {url} — not RSS ({e})")
                continue
            for it in items:
                if it["date"] >= since:
                    lines.append(f"RELEASE {it['date']} {it['title']} — {it['link']}")
        else:
            d = page_modified(body)
            if d is None:
                lines.append(f"COULD NOT READ {url} — no Last updated date in the page")
            elif d >= since:
                lines.append(f"PAGE {d} {url}")
    return lines


def self_test() -> int:
    rss = ("<rss><channel>"
           "<item><title>Old</title><link>https://x.gov.au/old</link>"
           "<pubDate>Mon, 01 Sep 2026 10:00:00 +1000</pubDate></item>"
           "<item><title>Planted release</title><link>https://x.gov.au/new</link>"
           "<pubDate>Fri, 16 Oct 2026 10:00:00 +1000</pubDate></item>"
           "</channel></rss>")
    pages = {
        "https://p.gov.au/moved": '<span id="pageModified" class="hide">16/10/2026 9:00 AM</span>',
        "https://p.gov.au/still": '<span id="pageModified" class="hide">2/10/2026 12:00 PM</span>',
        "https://p.gov.au/broken": "<html>no date</html>",
    }
    state = {"since": "2026-10-10", "feeds": ["https://f.gov.au/rss"], "pages": list(pages) + ["https://p.gov.au/403"]}

    def get(url):
        if url == "https://f.gov.au/rss":
            return 200, rss
        if url in pages:
            return 200, pages[url]
        return 403, ""

    got = moved(state, get=get, pause=0)
    want = [
        "RELEASE 2026-10-16 Planted release — https://x.gov.au/new",
        "PAGE 2026-10-16 https://p.gov.au/moved",
        "COULD NOT READ https://p.gov.au/broken — no Last updated date in the page",
        "COULD NOT READ https://p.gov.au/403 — HTTP 403",
    ]
    if got != want:
        print("FAIL — visa_watch self-test\n  got:  " + "\n        ".join(got)
              + "\n  want: " + "\n        ".join(want))
        return 1
    print("PASS — a planted release, a moved page and two unreadable sources are reported; "
          "old ones are not")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    state = json.loads(STATE.read_text())
    lines = moved(state)
    for line in lines:
        print(line)
    if not any(l.startswith(("RELEASE", "PAGE")) for l in lines):
        print(f"Home Affairs visa check: no change since {state['since']}")
    if "--update" in sys.argv:
        state["since"] = datetime.date.today().isoformat()
        STATE.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
