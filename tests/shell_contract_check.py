#!/usr/bin/env python3
"""P-6's check: the shells reach the engine only through its registered HTTP surface.

Reproducible -> P-6 · Shells reach the engine only through the contract -> Mechanisms -> shell sources vs the engine's route table and tables
Falsifier (invariants.md P-6): a shell module reading `ENGINE_DATABASE_URL` or an engine
table, or calling an `/api/engine/*` path the engine does not register. This reads the
real sources, no stack:

- the engine's routes from `fh_engine_http:routes/0` (`:binding` segments match any one
  segment) and its tables from `CREATE TABLE` in engine/erlang/priv/migrations, less any
  name the shell's own migrations also create;
- every tracked shell source (.erl .hrl .ts .js .svelte .sql, under shell/), test/
  excluded — the test escripts boot an engine on purpose — with comments stripped;
- flags `ENGINE_DATABASE_URL`, an SQL keyword followed by an engine table, and every
  engine path the shell builds (`base_url() ++ ...` / `engine_base_url() ++ ...` in
  Erlang, a literal `/api/engine/...` anywhere) that matches no route.

It fails too if it finds no engine call at all, so a refactor that hides the calls from
it cannot pass silently. Then it plants one of each violation in a scratch copy of the
shell and requires each to be caught, naming file and line; a check that stopped
biting fails here, not later.

    .venv/bin/python tests/shell_contract_check.py [--root <repo>]
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

SRC_EXT = (".erl", ".hrl", ".ts", ".js", ".svelte", ".sql")
SQL_KW = r"\b(?:from|join|into|update|table|truncate)\s+(?:public\.)?"


def engine_routes(root):
    src = open(os.path.join(root, "engine/erlang/src/fh_engine_http.erl")).read()
    body = src[src.index("\nroutes() ->"):]
    body = body[: body.index("}].") + 3]
    pats = []
    for path in re.findall(r'\{"(/api/engine[^"]*)"', body):
        rx = re.sub(r":[a-z_]+", "[^/]+", path)
        pats.append((path, re.compile("^" + rx + "$")))
    return pats


def tables(root, rel):
    names = set()
    d = os.path.join(root, rel)
    for f in sorted(os.listdir(d)):
        if f.endswith(".sql"):
            sql = open(os.path.join(d, f)).read()
            names |= {n.lower() for n in re.findall(
                r"(?i)create\s+table\s+(?:if\s+not\s+exists\s+)?([a-z_][a-z0-9_]*)", sql)}
    return names


def shell_files(root):
    out = subprocess.run(["git", "ls-files", "shell"], cwd=root, capture_output=True,
                         text=True).stdout.split()
    if not out:  # a scratch copy is not a git repo: walk it
        for dp, dns, fns in os.walk(os.path.join(root, "shell")):
            dns[:] = [d for d in dns if d not in ("_build", "node_modules", ".svelte-kit")]
            out += [os.path.relpath(os.path.join(dp, f), root) for f in fns]
    return sorted(f for f in out
                  if f.endswith(SRC_EXT) and "/test/" not in f and "/node_modules/" not in f)


def strip_comments(text, ext):
    """Blank comments, keep strings and line numbers. Erlang/SQL by line; JS-family by state."""
    if ext in (".erl", ".hrl"):
        return "\n".join(_cut(l, "%") for l in text.split("\n"))
    if ext == ".sql":
        return "\n".join(_cut(l, "--") for l in text.split("\n"))
    out, i, n, q = [], 0, len(text), None
    while i < n:
        c = text[i]
        if q:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1]); i += 2; continue
            if c == q:
                q = None
        elif c in "\"'`":
            q = c; out.append(c)
        elif text.startswith("//", i):
            j = text.find("\n", i); j = n if j < 0 else j
            i = j; continue
        elif text.startswith("/*", i) or text.startswith("<!--", i):
            end = "*/" if text[i] == "/" else "-->"
            j = text.find(end, i + 2); j = n if j < 0 else j + len(end)
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j; continue
        else:
            out.append(c)
        i += 1
    return "".join(out)


def _cut(line, mark):
    q = None
    for i, c in enumerate(line):
        if q:
            if c == "\\":
                continue
            if c == q:
                q = None
        elif c == '"':
            q = c
        elif line.startswith(mark, i):
            return line[:i]
    return line


def erl_engine_paths(code):
    """Each `base_url() ++ ...` expression, as (offset, path): literal pieces kept, a
    non-literal right after a '/' is one path segment, any other non-literal (a query
    helper) and everything from a '?' on is dropped."""
    found = []
    for m in re.finditer(r"\b(?:engine_)?base_url\(\)\s*\+\+", code):
        rest = code[m.end():]
        stmt = re.split(r",\s*\n|\.\s*\n", rest, maxsplit=1)[0]
        path = ""
        for piece in re.split(r"\+\+", stmt):
            piece = piece.strip()
            lit = re.fullmatch(r'"([^"]*)"', piece)
            if lit:
                path += lit.group(1)
            elif path.endswith("/"):
                path += "X"
            else:
                break
            if "?" in path:
                break
        found.append((m.start(), "/api/engine" + path.split("?")[0]))
    return found


def check(root):
    routes = engine_routes(root)
    eng_tables = tables(root, "engine/erlang/priv/migrations") - tables(
        root, "shell/web/backend/priv/migrations")
    tbl_rx = re.compile(SQL_KW + r"(" + "|".join(sorted(eng_tables)) + r")\b", re.I)
    lit_rx = re.compile(r"/api/engine(/[A-Za-z0-9_\-/:${}.]*)?")
    problems, calls = [], 0

    def line_of(text, off):
        return text.count("\n", 0, off) + 1

    for rel in shell_files(root):
        raw = open(os.path.join(root, rel), encoding="utf-8").read()
        code = strip_comments(raw, os.path.splitext(rel)[1])
        for m in re.finditer(r"ENGINE_DATABASE_URL", code):
            problems.append(f"{rel}:{line_of(code, m.start())}: reads ENGINE_DATABASE_URL")
        for m in tbl_rx.finditer(code):
            problems.append(f"{rel}:{line_of(code, m.start())}: names engine table "
                            f"`{m.group(1)}` ({m.group(0).strip()})")
        paths = erl_engine_paths(code) if rel.endswith((".erl", ".hrl")) else []
        for m in lit_rx.finditer(code):
            if m.group(1) and len(m.group(1)) > 1:  # a bare base URL is not a call
                p = re.sub(r"\$\{[^}]*\}", "X", m.group(0)).rstrip("/")
                paths.append((m.start(), p))
        for off, p in paths:
            calls += 1
            if not any(rx.match(p) for _, rx in routes):
                problems.append(f"{rel}:{line_of(code, off)}: calls {p}, "
                                f"which fh_engine_http:routes/0 does not register")
    if calls == 0:
        problems.append("no engine call found in the shell sources: the check is blind")
    return problems, calls, len(routes), sorted(eng_tables)


PLANTS = [
    ("shell/web/backend/src/fh_shell_store.erl",
     '\nplanted_contract_breach() -> pgo:query("SELECT count(*) FROM plan_card_events", []).\n',
     "engine table `plan_card_events`"),
    ("shell/web/backend/src/fh_shell_db.erl",
     '\nplanted_contract_breach() -> os:getenv("ENGINE_DATABASE_URL").\n',
     "reads ENGINE_DATABASE_URL"),
    ("shell/web/backend/src/fh_shell_engine_client.erl",
     '\nplanted_contract_breach() ->\n    Url = base_url() ++ "/plan-cards/" ++ "x" ++ "/export",\n    Url.\n',
     "/api/engine/plan-cards/x/export"),
]


def self_test(root):
    """Plant each violation in its own scratch copy; each must be caught at its line."""
    failures = []
    for rel, code, needle in PLANTS:
        with tempfile.TemporaryDirectory() as tmp:
            for part in ("engine/erlang/src/fh_engine_http.erl",):
                os.makedirs(os.path.join(tmp, os.path.dirname(part)), exist_ok=True)
                shutil.copy(os.path.join(root, part), os.path.join(tmp, part))
            for d in ("engine/erlang/priv/migrations", "shell/web/backend/priv/migrations"):
                shutil.copytree(os.path.join(root, d), os.path.join(tmp, d))
            for f in shell_files(root):
                os.makedirs(os.path.join(tmp, os.path.dirname(f)), exist_ok=True)
                shutil.copy(os.path.join(root, f), os.path.join(tmp, f))
            target = os.path.join(tmp, rel)
            line = open(target).read().count("\n") + 2
            with open(target, "a") as fh:
                fh.write(code)
            problems, _, _, _ = check(tmp)
            hit = [p for p in problems if p.startswith(f"{rel}:") and needle in p]
            if hit:
                print(f"  self-test ok: planted in {rel} → {hit[0]}")
            else:
                failures.append(f"planted violation in {rel} near line {line} not caught "
                                f"(wanted '{needle}'; got {problems})")
    return failures


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    root = ap.parse_args().root
    problems, calls, nroutes, eng = check(root)
    print(f"shell_contract_check: {nroutes} engine routes, {len(eng)} engine-only tables, "
          f"{calls} engine calls in the shell sources")
    for p in problems:
        print("FAIL " + p)
    if problems:
        return 1
    failures = self_test(root)
    for f in failures:
        print("FAIL self-test: " + f)
    if failures:
        return 1
    print("PASS — no shell source reaches the engine around its registered surface")
    return 0


if __name__ == "__main__":
    sys.exit(main())
