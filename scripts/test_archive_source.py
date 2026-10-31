"""archive_source.py's URL gate, as a seeded property (behavior 145, Expect 3 of its first form).

Regulated figures are grounded -> R-3 -> The KB update -> archive_source fetches only https on a KB source host
Invariant: archive_source.py runs curl only for an https URL on a host kb_compiler counts as
  a primary, and writes nothing when curl ends on any other page; every other URL a page or
  an agent could hand it exits 2 before curl runs.
Mechanism: seeded draws (seed 145, 400 cases) of good URLs (subdomains, :443, paths, query,
  fragment) and bad ones (http, file://, data:, ftp:, userinfo and backslash-@, %2f, look-alike
  prefixes and suffixes, other ports, an IDN, case, a leading space, protocol-relative,
  javascript:), plus good URLs whose fetch ends off-list; archive_source.py runs with a stub
  curl first on PATH that records whether it was called.
Capability: `.venv/bin/python scripts/test_archive_source.py` → `ok …` and exit 0, or
  `FAIL …` with the first counterexample and exit 1. On architecture.md's `checks:` line.
"""
from __future__ import annotations

import random
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "engine" / "build"))
import kb_compiler  # noqa: E402

SEED, N = 145, 400
TMP = Path(tempfile.mkdtemp(prefix="archive-source-test-"))
FAILS: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"{'ok  ' if ok else 'FAIL'} {name}" + (f" — {detail}" if detail and not ok else ""))
    if not ok:
        FAILS.append(name)


class A:  # the one helper the property needs, as archive_source.allowed reads it
    @staticmethod
    def source_hosts() -> list[str]:
        hosts = set(kb_compiler.PRIMARY_GOV_LAW_HOSTS)
        for hs in kb_compiler.PRIMARY_PROVIDER_HOSTS.values():
            hosts.update(hs)
        return sorted(hosts)


STUB = """#!/bin/sh
echo called >> "$STUB_LOG"
for a; do last=$a; done
printf '<html><title>t</title><p>page</p></html>\\n%s' "${STUB_FINAL:-$last}"
"""


def url_property() -> None:
    rng = random.Random(SEED)
    hosts = A.source_hosts()
    stubdir = TMP / "stub"
    stubdir.mkdir()
    (stubdir / "curl").write_text(STUB)
    (stubdir / "curl").chmod(0o755)

    def good():
        h = rng.choice(hosts)
        sub = rng.choice(["", "www.", "immi.", "a-b.c."])
        port = rng.choice(["", "", ":443"])
        path = rng.choice(["/", "/x/y.html", "/a?b=c&d=e", "#f", "/news/2026-10"])
        return f"https://{sub}{h}{port}{path}"

    def bad():
        h = rng.choice(hosts)
        return rng.choice([
            f"http://{h}/", "file:///Users/son/.config/gh/hosts.yml",
            f"file://{h}/etc/passwd", "data:text/html,<p>x</p>", f"ftp://{h}/x",
            f"https://evil.com\\@{h}/", f"https://evil.com@{h}/", f"https://{h}@evil.com/",
            f"https://{h}%2f@evil.com/", f"https://evil.com%2f{h}/", f"https://evil-{h}/",
            f"https://{h}.evil.com/", f"https://x{h}/", f"https://{h}:8443/",
            f"https://{h}:80/", f"https://аto.gov.au/", f"https://{h.upper()}/",
            f"HTTPS://{h}/", f" https://{h}/", f"https://{h}\\x/", "https:///x",
            f"//{h}/x", f"https://{h}:443@evil.com/", "javascript:alert(1)"])

    cases = []
    for case in range(N):
        is_good = rng.random() < 0.4
        url = good() if is_good else bad()
        cases.append((case, url, is_good, is_good and rng.random() < 0.25))
    (TMP / "arch").mkdir()

    def run(c):
        case, url, is_good, redirect_off = c
        log, out = TMP / "arch" / f"stub-{case}.log", TMP / "arch" / f"x-{case}.txt"
        env = {"PATH": f"{stubdir}:/usr/bin:/bin", "STUB_LOG": str(log), "HOME": str(TMP)}
        if redirect_off:
            env["STUB_FINAL"] = "https://evil.example/landing"
        r = subprocess.run([sys.executable, str(ROOT / "scripts/archive_source.py"), url, str(out)],
                           capture_output=True, text=True, env=env)
        called = log.is_file()
        if is_good and not redirect_off:
            ok = r.returncode == 0 and called and out.is_file()
        elif redirect_off:
            ok = r.returncode == 2 and not out.is_file()
        else:
            ok = r.returncode == 2 and not called and not out.is_file()
        return None if ok else (f"case {case} {url!r} good={is_good} redirect_off={redirect_off}: "
                                f"rc {r.returncode}, curl called {called}, {r.stderr.strip()[-200:]}")

    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(8) as ex:
        bad_cases = [b for b in ex.map(run, cases) if b]
    check(f"archive_source URL property: {N} cases, seed {SEED}", not bad_cases,
          f"{len(bad_cases)} counterexamples, first: {bad_cases[0] if bad_cases else ''}")


if __name__ == "__main__":
    url_property()
    sys.exit(1 if FAILS else 0)
