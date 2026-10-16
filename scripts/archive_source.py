#!/usr/bin/env python3
"""Archive a government web page as the text a fact or news note quotes.

    python3 scripts/archive_source.py <url> <docs/sources/...txt>

Regulated figures are grounded -> P-7 -> The KB compiler -> a fact doc quotes its archived primary
GATE 12 (kb_compiler.py facts_doc_fails) checks every `quotes` string against the file
under docs/sources/ that a fact's source names, so the page must be kept as searchable
text. This writes the form the first archives took by hand (country-profile-vietnam):
a Source / Retrieved / Extracted header (with the sha256 of the HTML as fetched), then
the visible page text — scripts, styles, navigation, header and footer removed,
whitespace collapsed to one line per block. Stdlib + curl; the fetch runs in the sandbox.
"""
from __future__ import annotations

import datetime
import hashlib
import html
import json
import re
import subprocess
import sys
from pathlib import Path

DROP = r"<(script|style|noscript|nav|header|footer|svg)\b.*?</\1>"
BLOCK = r"</?(p|div|li|h[1-6]|tr|td|th|table|section|article|br|dt|dd)\b[^>]*>"


def visible_text(raw: str) -> str:
    t = re.sub(DROP, " ", raw, flags=re.S | re.I)
    t = re.sub(BLOCK, "\n", t, flags=re.I)
    t = html.unescape(re.sub(r"<[^>]+>", " ", t))
    lines = (" ".join(line.split()) for line in t.split("\n"))
    return "\n".join(line for line in lines if line)


# Regulated figures are grounded -> P-7 · The KB -> The weekly kb-watch routine -> a Home Affairs visa page archives as text
# Behavior 104 (2026-10-17): a visa page under immi.homeaffairs.gov.au/visas/ is drawn by
# JavaScript from a JSON blob in a hidden input (`…PageSchemaHiddenField_Input`); its
# visible HTML holds 1.6 KB of a 1.3 MB page (864, measured 2026-10-17). So the blob's
# text — title, overview, cost, eligibility, steps, for applicants and sponsors — is
# appended in page order, and the cloud routine can archive and quote a visa page
# without a browser. Flags, ids and image paths are not text and are left out.
SCHEMA = r'<input[^>]*id="[^"]*PageSchemaHiddenField_Input"[^>]*value="([^"]*)"'
NOT_TEXT = {"collapsed", "hidden", "id", "currentActor", "multipleActors", "processMap",
            "hasCustomButton", "customButtonLink", "customButtonlink"}


def schema_text(raw: str) -> str:
    m = re.search(SCHEMA, raw)
    if not m:
        return ""
    try:
        data = json.loads(html.unescape(m.group(1)))
    except ValueError:
        return ""
    out: list[str] = []

    def walk(o, key=""):
        if isinstance(o, dict):
            for k, v in o.items():
                if k not in NOT_TEXT:
                    walk(v, k)
        elif isinstance(o, list):
            for v in o:
                walk(v, key)
        elif isinstance(o, str) and o.strip():
            t = visible_text(o) if "<" in o else " ".join(o.split())
            if t:
                out.append(t)

    walk(data)
    return "\n".join(out)


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    url, out = sys.argv[1], Path(sys.argv[2])
    # curl, not urllib: through the sandbox's egress proxy urllib's chunked reads end
    # in IncompleteRead (measured 2026-10-10 on foreigninvestment.gov.au); curl reads
    # the same pages whole.
    body = subprocess.run(["curl", "-fsSL", "-m", "60", "-A", "Mozilla/5.0 (archive_source)", url],
                          check=True, capture_output=True).stdout
    raw = body.decode("utf-8", errors="replace")
    title = re.search(r"<title>(.*?)</title>", raw, re.S | re.I)
    if title and re.search(r"not found|404", title.group(1), re.I):
        sys.exit(f"archive_source: {url} is a not-found page ({title.group(1).strip()!r})")
    head = (
        f"Source: {url}\n"
        f"Retrieved: {datetime.date.today().isoformat()}\n"
        "Extracted: visible page text (scripts and navigation removed); sha256 of the "
        f"fetched HTML {hashlib.sha256(body).hexdigest()}\n\n"
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    schema = schema_text(raw)
    if schema:
        head = head.replace("\n\n", "; then the page's own text from its PageSchemaHiddenField "
                            "JSON (the visa page draws itself from it)\n\n", 1)
    out.write_text(head + visible_text(raw) + ("\n" + schema if schema else "") + "\n")
    print(f"archived {url} -> {out}")


if __name__ == "__main__":
    main()
