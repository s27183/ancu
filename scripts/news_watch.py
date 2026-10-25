#!/usr/bin/env python3
"""List what the government news sources published since the last news-watch run.

    python3 scripts/news_watch.py            # report every item dated on or after `since`
    python3 scripts/news_watch.py --update   # the same, then move `since` to yesterday
    python3 scripts/news_watch.py --self-test

Regulated figures are grounded -> P-7 · The KB -> The daily news-watch routine -> every listed source read, nothing between two runs missed
Behavior 136 (Son 2026-10-25: "there have been few KB PRs but no news were detected"):
the routine used to read each news page by eye and judged a window from the newest
note's authored_date; it passed over QRO and ASIC (pages rendered by script) as quiet and
skipped Treasury's 16 Oct communiqué as "before the window". This script, the shape of
visa_watch.py (behavior 104), names what each source published; the routine judges each
line and accounts for every one in its PR (news-watch-routine.md step 2).
Holds:   the sources and the window in docs/sources/news-watch.json, each source read in
         the form that carries its items, as measured 2026-10-25:
         - `rss`: an RSS feed (QRO, whose news page is script-rendered; RBA);
         - `asic-json`: the JSON asic.gov.au's own newsroom script loads (fields name,
           publishedDate, url relative to asic.gov.au);
         - `html`: a dated list in the HTML as served — `item` (a regex) starts each
           entry, `link` (a regex with groups url and title) finds its link, and the
           date is the first `datetime="…"`/`data-date="…"` or `24 October 2026` text —
           in `date`'s group 1 where the source names one (Revenue NSW's titles carry
           dates: "Lodge by 31 October 2026", listed 24 July);
         - `page`: one page whose Last-Modified header dates it (budget.gov.au, which
           changes a few times a year).
         Every source prints exactly one of: its ITEM lines (and OFF-LIST ones), the
         line `<source>: no items since <since>`, or a COULD NOT READ line — a 200 page
         from which no item parses is COULD NOT READ, never quiet (R-1). A source whose
         every listed item is on or after `since` also prints MORE: its list may hold
         older ones on a next page, which the routine opens.
         On-or-after, and `--update` sets `since` to the day before the run, so an item
         dated in a time zone a day behind, or published the evening of a run, is listed
         again rather than missed; the routine skips what a note already covers.
         Dates: an RSS pubDate is taken in Sydney time; an ISO date in a page or JSON as
         written (Drupal's `2026-10-16T12:00:00Z` is the page's 16 October).
Guards:  only https, only *.gov.au. A source is fetched hop by hop (no curl -L): a
         redirect off its own host, or off https, is reported OFF-LIST and not followed.
         An item whose link is not https on a *.gov.au host (another site, a look-alike,
         userinfo, http:, javascript:) prints OFF-LIST, and the routine never opens it.
         The script never fetches an item link — only the source URLs in the JSON.
         One request at a time with a pause, curl with a browser UA (visa_watch.py's
         block: a burst got a browser blocked by Home Affairs, 2026-10-16).
"""
from __future__ import annotations

import datetime
import email.utils
import html
import json
import random
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urljoin, urlsplit

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "docs/sources/news-watch.json"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")
PAUSE_S = 3
MAX_HOPS = 5
try:
    from zoneinfo import ZoneInfo
    SYDNEY = ZoneInfo("Australia/Sydney")
except Exception:  # no tz database: AEST, a day boundary at most an hour off
    SYDNEY = datetime.timezone(datetime.timedelta(hours=10))

MONTHS = {m: i + 1 for i, m in enumerate(
    ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"])}
TEXT_DATE = re.compile(
    r"\b(\d{1,2})(?:\s|&nbsp;)+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)"
    r"[a-z]*\.?(?:\s|&nbsp;)+(\d{4})\b")
ISO_ATTR = re.compile(r'(?:datetime|data-date)="(\d{4})-(\d{2})-(\d{2})')


# --- what may be read and cited -------------------------------------------------------

def gov_url(url: str) -> bool:
    """https on a *.gov.au host, with nothing in the authority but the host."""
    try:
        u = urlsplit(url.strip())
    except ValueError:
        return False
    host = u.hostname or ""
    return (u.scheme == "https" and u.netloc == host
            and re.fullmatch(r"[a-z0-9.-]+", host) is not None
            and (host == "gov.au" or host.endswith(".gov.au")))


# --- fetching, one hop at a time --------------------------------------------------------

def curl_hop(url: str) -> tuple[int, dict, str, str]:
    """One request, no redirect followed: (status, headers, body, Location)."""
    with tempfile.TemporaryDirectory() as d:
        hdr, body = Path(d) / "h", Path(d) / "b"
        r = subprocess.run(
            ["curl", "-s", "--max-time", "30", "--proto", "=https", "-A", UA,
             "-D", str(hdr), "-o", str(body), "-w", "%{http_code} %{redirect_url}", url],
            capture_output=True, text=True, errors="replace")
        code, _, loc = r.stdout.partition(" ")
        headers = {}
        if hdr.exists():
            for line in hdr.read_text(errors="replace").splitlines():
                k, sep, v = line.partition(":")
                if sep:
                    headers[k.strip().lower()] = v.strip()
        text = body.read_text(errors="replace") if body.exists() else ""
    return (int(code) if code.isdigit() else 0), headers, text, loc.strip()


def fetch(url: str, hop=curl_hop) -> tuple[int, dict, str, str]:
    """Follow redirects only on the source's own host over https: (status, headers,
    body, final url). A redirect elsewhere returns status -1 and the refused url."""
    host = urlsplit(url).hostname
    for _ in range(MAX_HOPS):
        code, headers, body, loc = hop(url)
        if code not in (301, 302, 303, 307, 308):
            return code, headers, body, url
        nxt = urljoin(url, loc or headers.get("location", ""))
        if not gov_url(nxt) or urlsplit(nxt).hostname != host:
            return -1, {}, "", nxt
        url = nxt
    return 0, {}, "", url


# --- parsing --------------------------------------------------------------------------

def clean(s: str) -> str:
    return " ".join(html.unescape(re.sub(r"<[^>]+>", " ", s)).split())


def text_date(s: str) -> datetime.date | None:
    m = ISO_ATTR.search(s)
    if m:
        return datetime.date(int(m[1]), int(m[2]), int(m[3]))
    m = TEXT_DATE.search(re.sub(r"<[^>]+>", " ", s))
    if m:
        return datetime.date(int(m[3]), MONTHS[m[2][:3].lower()], int(m[1]))
    return None


def rss_items(body: str, base: str) -> list[dict]:
    out = []
    for it in ET.fromstring(body.lstrip()).iter("item"):
        when = email.utils.parsedate_to_datetime(it.findtext("pubDate") or "")
        if when.tzinfo is not None:
            when = when.astimezone(SYDNEY)
        out.append({"date": when.date(), "title": clean(it.findtext("title") or ""),
                    "url": urljoin(base, (it.findtext("link") or "").strip())})
    return out


def asic_items(body: str, base: str) -> list[dict]:
    out = []
    for r in json.loads(body):
        out.append({"date": datetime.date.fromisoformat(r["publishedDate"][:10]),
                    "title": clean(r.get("name") or ""),
                    "url": urljoin("https://asic.gov.au/", r.get("url") or "")})
    return out


def html_items(body: str, base: str, src: dict) -> list[dict]:
    starts = [m.start() for m in re.finditer(src["item"], body)]
    out = []
    for a, b in zip(starts, starts[1:] + [len(body)]):
        chunk = body[a:b]
        link = re.search(src["link"], chunk, re.S)
        dated = re.search(src["date"], chunk, re.S) if "date" in src else None
        when = text_date(dated[1] if dated else chunk)
        if link and when:
            out.append({"date": when, "title": clean(link["title"]),
                        "url": urljoin(base, html.unescape(link["url"].strip()))})
    return out


def page_item(body: str, headers: dict, base: str) -> list[dict]:
    lm = headers.get("last-modified")
    title = re.search(r"<title[^>]*>(.*?)</title>", body, re.S)
    if not lm or not title:
        return []
    when = email.utils.parsedate_to_datetime(lm).astimezone(SYDNEY).date()
    return [{"date": when, "title": clean(title[1]), "url": base}]


def parse(src: dict, code_headers_body_url) -> list[dict]:
    _, headers, body, final = code_headers_body_url
    kind = src["kind"]
    if kind == "rss":
        return rss_items(body, final)
    if kind == "asic-json":
        return asic_items(body, final)
    if kind == "html":
        return html_items(body, final, src)
    if kind == "page":
        return page_item(body, headers, final)
    raise ValueError(f"unknown kind {kind}")


# --- the watch --------------------------------------------------------------------------

def watch(state: dict, hop=curl_hop, pause=PAUSE_S) -> list[str]:
    """One or more lines per source, in the order listed."""
    since = datetime.date.fromisoformat(state["since"])
    lines = []
    for i, src in enumerate(state["sources"]):
        name, url = src["name"], src["url"]
        if not gov_url(url):
            lines.append(f"OFF-LIST {name} source url {url} — not fetched")
            continue
        if i and pause:
            time.sleep(pause)
        got = fetch(url, hop)
        code, final = got[0], got[3]
        if code == -1:
            lines.append(f"OFF-LIST {name} redirect to {final} — not followed")
            continue
        if code != 200:
            lines.append(f"COULD NOT READ {name} {code} {url}")
            continue
        try:
            items = parse(src, got)
        except (ET.ParseError, ValueError, KeyError, TypeError) as e:
            lines.append(f"COULD NOT READ {name} not parsed ({type(e).__name__}) {url}")
            continue
        if not items:
            lines.append(f"COULD NOT READ {name} no items parsed {url}")
            continue
        new = sorted((it for it in items if it["date"] >= since),
                     key=lambda it: it["date"], reverse=True)
        for it in new:
            tag = "ITEM" if gov_url(it["url"]) else "OFF-LIST"
            lines.append(f"{tag} {it['date']} {name} {it['title']} {it['url']}")
        if not new:
            lines.append(f"{name}: no items since {since}")
        elif len(new) == len(items) and src["kind"] != "page":
            lines.append(f"MORE {name} all {len(items)} listed items are on or after {since};"
                         f" older ones may be on a next page of {final}")
    return lines


# --- self-test --------------------------------------------------------------------------

HOSTILE_HOSTS = ["example.com", "gov.au.example.com", "xgov.au", "gov.au.evil.net",
                 "news.com.au", "abc.net.au", "asic.gov.au.attacker.io", "govau.com"]


def hostile_link(rng: random.Random) -> str:
    """A link an attacker controlling a listed page might plant."""
    path = "/" + "".join(rng.choice("abcxyz019-/") for _ in range(rng.randint(0, 12)))
    gov = rng.choice(["asic.gov.au", "treasury.gov.au", "qro.qld.gov.au", "gov.au"])
    return rng.choice([
        lambda: f"https://{rng.choice(HOSTILE_HOSTS)}{path}",
        lambda: f"http://{gov}{path}",
        lambda: f"javascript:alert({rng.randint(0, 99)})",
        lambda: f"JavaScript:fetch('//{rng.choice(HOSTILE_HOSTS)}')",
        lambda: f"https://{gov}@{rng.choice(HOSTILE_HOSTS)}{path}",
        lambda: f"https://{rng.choice(HOSTILE_HOSTS)}\\@{gov}{path}",
        lambda: f"https://{gov}:8443{path}",
        lambda: f"//{rng.choice(HOSTILE_HOSTS)}{path}",
        lambda: f"data:text/html,{path}",
        lambda: f"ftp://{gov}{path}",
    ])()


def self_test() -> int:
    rss = ("<?xml version='1.0'?><rss><channel>"
           "<item><title>Old release</title><link>https://r.gov.au/old</link>"
           "<pubDate>Mon, 01 Sep 2026 10:00:00 +1000</pubDate></item>"
           "<item><title>Planted &amp; RSS</title><link>https://r.gov.au/new</link>"
           "<pubDate>Fri, 16 Oct 2026 04:27:37 +0000</pubDate></item>"
           "<item><title>Feed off-list</title><link>https://example.com/x</link>"
           "<pubDate>Fri, 16 Oct 2026 04:27:37 +0000</pubDate></item>"
           "</channel></rss>")
    asic = json.dumps([
        {"name": "26-256MR Planted JSON", "publishedDate": "2026-10-23T15:40:00Z",
         "url": "/about-asic/26-256mr"},
        {"name": "26-200MR Old JSON", "publishedDate": "2026-09-01T00:00:00Z",
         "url": "/about-asic/26-200mr"}])
    item = ('<li class="results__item"><a href="{u}"><h3 class="results__title">{t}</h3>'
            '<div class="results__date"> {d} </div></a></li>')
    page = "<ul>" + "".join([
        item.format(u="/news/planted", t="Planted HTML", d="24 October 2026"),
        item.format(u="/news/due", t="Old, lodge by 31 October 2026", d="24 July 2026"),
        item.format(u="https://xgov.au/n", t="Look-alike", d="24 Oct 2026"),
        item.format(u="http://h.gov.au/n", t="Plain http", d="23 October 2026"),
        item.format(u="javascript:alert(1)", t="Script link", d="22 October 2026"),
        item.format(u="/news/old", t="Old HTML", d="30 September 2026"),
    ]) + "</ul>"
    link = r'href="(?P<url>[^"]+)".*?results__title">(?P<title>.*?)</h3>'
    html_src = {"kind": "html", "item": r'<li class="results__item"', "link": link,
                "date": r'results__date">(.*?)</div>'}
    state = {"since": "2026-10-15", "sources": [
        {"name": "rss", "kind": "rss", "url": "https://r.gov.au/feed/"},
        {"name": "json", "kind": "asic-json", "url": "https://download.j.gov.au/mr.json"},
        dict(html_src, name="html", url="https://h.gov.au/news"),
        {"name": "page", "kind": "page", "url": "https://b.gov.au/"},
        dict(html_src, name="forbidden", url="https://f.gov.au/news"),
        dict(html_src, name="empty", url="https://e.gov.au/news"),
        dict(html_src, name="quiet", url="https://q.gov.au/news"),
        dict(html_src, name="away", url="https://a.gov.au/news"),
        dict(html_src, name="moved", url="https://m.gov.au/news"),
        dict(html_src, name="all-new", url="https://n.gov.au/news"),
    ]}
    served = {
        "https://r.gov.au/feed/": (200, {}, rss, ""),
        "https://download.j.gov.au/mr.json": (200, {}, asic, ""),
        "https://h.gov.au/news": (200, {}, page, ""),
        "https://b.gov.au/": (200, {"last-modified": "Wed, 21 Oct 2026 02:19:36 GMT"},
                              "<title>Budget 2026&ndash;27</title>", ""),
        "https://f.gov.au/news": (403, {}, "Forbidden", ""),
        "https://e.gov.au/news": (200, {}, "<div id=app></div><script>render()</script>", ""),
        "https://q.gov.au/news": (200, {}, item.format(u="/o", t="Old", d="1 October 2026"), ""),
        "https://a.gov.au/news": (302, {}, "", "https://a.gov.au.example.com/news"),
        "https://m.gov.au/news": (301, {}, "", "/about/news"),
        "https://m.gov.au/about/news": (200, {}, item.format(u="/m", t="Moved", d="16 Oct 2026"), ""),
        "https://n.gov.au/news": (200, {}, item.format(u="/n", t="All new", d="20 Oct 2026"), ""),
    }
    asked = []

    def hop(url):
        asked.append(url)
        return served.get(url, (404, {}, "", ""))

    got = watch(state, hop=hop, pause=0)
    want = [
        "ITEM 2026-10-16 rss Planted & RSS https://r.gov.au/new",
        "OFF-LIST 2026-10-16 rss Feed off-list https://example.com/x",
        "ITEM 2026-10-23 json 26-256MR Planted JSON https://asic.gov.au/about-asic/26-256mr",
        "ITEM 2026-10-24 html Planted HTML https://h.gov.au/news/planted",
        "OFF-LIST 2026-10-24 html Look-alike https://xgov.au/n",
        "OFF-LIST 2026-10-23 html Plain http http://h.gov.au/n",
        "OFF-LIST 2026-10-22 html Script link javascript:alert(1)",
        "ITEM 2026-10-21 page Budget 2026–27 https://b.gov.au/",
        "COULD NOT READ forbidden 403 https://f.gov.au/news",
        "COULD NOT READ empty no items parsed https://e.gov.au/news",
        "quiet: no items since 2026-10-15",
        "OFF-LIST away redirect to https://a.gov.au.example.com/news — not followed",
        "ITEM 2026-10-16 moved Moved https://m.gov.au/m",
        "MORE moved all 1 listed items are on or after 2026-10-15; older ones may be on a"
        " next page of https://m.gov.au/about/news",
        "ITEM 2026-10-20 all-new All new https://n.gov.au/n",
        "MORE all-new all 1 listed items are on or after 2026-10-15; older ones may be on a"
        " next page of https://n.gov.au/news",
    ]
    fails = []
    if got != want:
        fails.append("planted sources\n  got:  " + "\n        ".join(got)
                     + "\n  want: " + "\n        ".join(want))
    if any(not gov_url(u) for u in asked):
        fails.append(f"fetched an off-list url: {[u for u in asked if not gov_url(u)]}")

    # property (Expect 9): for all hostile links a listed page may carry, and redirects
    # off its host, the line is OFF-LIST and nothing but the source url is fetched.
    rng, cases = random.Random(136), 200
    for n in range(cases):
        bad = hostile_link(rng)
        asked.clear()
        if n % 2:
            body = item.format(u=html.escape(bad), t="Hostile", d="20 October 2026")
            served["https://p.gov.au/news"] = (200, {}, body, "")
        else:
            served["https://p.gov.au/news"] = (rng.choice([301, 302, 303, 307, 308]), {}, "", bad)
        lines = watch({"since": "2026-10-15",
                       "sources": [dict(html_src, name="p", url="https://p.gov.au/news")]},
                      hop=hop, pause=0)
        if (not lines or not lines[0].startswith("OFF-LIST")
                or any(l.startswith("ITEM") for l in lines) or asked != ["https://p.gov.au/news"]):
            fails.append(f"property case {n}: {bad!r} -> {lines}, fetched {asked}")
            break
    if fails:
        print("FAIL — news_watch self-test\n" + "\n".join(fails))
        return 1
    print("PASS — planted RSS, JSON, HTML and page items on or after `since` are listed and "
          "older ones not; a 403 and a page with no items are COULD NOT READ; off-list links "
          f"and redirects are OFF-LIST and unfetched ({cases} hostile cases, seed 136)")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    state = json.loads(STATE.read_text())
    for line in watch(state):
        print(line, flush=True)
    if "--update" in sys.argv:
        state["since"] = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
        STATE.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
