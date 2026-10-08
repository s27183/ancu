#!/usr/bin/env python3
"""Stand FirstHomey up on DigitalOcean from the repo's `.env`, printing no secret.

    python3 scripts/do_deploy.py apply engine|shell
    python3 scripts/do_deploy.py register-tenant

(run through scripts/do_apply.sh and scripts/do_register_tenant.sh, the commands
Son's confirm of behavior 33 grants outside the sandbox.)

reproducible -> P-6 -> deploy scripts -> fill a DO app spec's SECRET entries
  from .env + the ancu-pg cluster, validate, create-or-update; register the
  shell's tenant public key in ancu_engine (deployment.md §4 steps 3-6).
  Why a script: deployment.md §4 is a hand runbook whose every secret step
  ("inject it into a temp copy of app.yaml") would put a value on screen; here
  the values go .env -> a 0700 temp dir -> doctl and nowhere else. stdout
  carries names, ids, ingress URLs and the tenant PUBLIC key only; any doctl
  output is redacted of every value read before it is shown.
  Stdlib only (the repo venv has no PyYAML, measured 2026-10-08), so the spec
  is filled by line: a `- key: NAME` followed by `type: SECRET` gains a
  `value:` line (JSON-quoted, which YAML reads as a double-quoted scalar); an
  optional secret .env lacks is dropped from the spec rather than sent empty.
  Measured 2026-10-08 (`doctl apps list`, `doctl databases list`): no ancu-*
  app and no ancu-pg cluster existed; aleap-pg (sgp1) is aleap's, untouched.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import NoReturn
from urllib.parse import unquote, urlsplit, urlunsplit

ROOT = Path(__file__).resolve().parents[1]
CLUSTER = "ancu-pg"

APPS = {
    "engine": {
        "spec": ROOT / "engine" / "app.yaml",
        "name": "ancu-engine",
        "db": "ancu_engine",
        "db_var": "ENGINE_DATABASE_URL",
        "required": ["CLAUDE_CODE_OAUTH_TOKEN"],
    },
    "shell": {
        "spec": ROOT / "shell" / "web" / "app.yaml",
        "name": "ancu-shell",
        "db": "ancu_shell",
        "db_var": "SHELL_DATABASE_URL",
        "required": ["SHELL_JWT_SECRET", "SHELL_TENANT_ID", "SHELL_TENANT_PRIVKEY",
                     "RESEND_API_KEY"],
    },
}
# Plain config the spec commits empty and the Dashboard would fill (deployment.md §3):
# taken from .env when it holds one, so the deploy needs no Dashboard visit.
CONFIG_FROM_ENV = {"ADMIN_EMAILS"}

SECRETS: list[str] = []          # every value read, for redaction


def die(msg: str) -> NoReturn:
    print(f"do_deploy: {msg}", file=sys.stderr)
    sys.exit(1)


def redact(text: str) -> str:
    for v in sorted(SECRETS, key=len, reverse=True):
        if len(v) >= 6:
            text = text.replace(v, "«redacted»")
    return text


def read_env() -> dict[str, str]:
    """KEY=VALUE lines as python-dotenv / `source` read them: last one wins."""
    p = Path(os.environ.get("DO_DEPLOY_ENV_FILE") or ROOT / ".env")  # override: tests only
    if not p.exists():
        die(".env not found at the repo root")
    env: dict[str, str] = {}
    for raw in p.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        k, sep, v = line.partition("=")
        if not sep or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", k.strip()):
            continue
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
            v = v[1:-1]
        else:
            v = re.split(r"\s+#", v, maxsplit=1)[0].strip()
        env[k.strip()] = v
    for v in env.values():
        if v:
            SECRETS.append(v)
    return env


def doctl(*args: str, check: bool = True) -> subprocess.CompletedProcess:
    p = subprocess.run(["doctl", *args], capture_output=True, text=True)
    if check and p.returncode != 0:
        die(f"`doctl {args[0]} {args[1] if len(args) > 1 else ''}` failed:\n"
            + redact(p.stderr or p.stdout))
    return p


def doctl_json(*args: str):
    out = doctl(*args, "-o", "json").stdout
    return json.loads(out) if out.strip() else []


def cluster() -> dict:
    for c in doctl_json("databases", "list"):
        if c.get("name") == CLUSTER:
            if c.get("status") != "online":
                die(f"{CLUSTER} is {c.get('status')}; wait for online")
            return c
    die(f"no {CLUSTER} cluster — run `doctl databases create {CLUSTER} --engine pg "
        "--version 16 --size db-s-1vcpu-1gb --num-nodes 1 --region sgp1` first")


def db_url(c: dict, db: str) -> str:
    """The doadmin URL for database `db`, creating the database when absent."""
    names = {d.get("name") for d in doctl_json("databases", "db", "list", c["id"])}
    if db not in names:
        doctl("databases", "db", "create", c["id"], db)
        print(f"created database {db} on {CLUSTER}")
    conn = doctl_json("databases", "connection", c["id"])
    uri = (conn[0] if isinstance(conn, list) else conn)["uri"]
    SECRETS.append(uri)
    parts = urlsplit(uri)
    if parts.password:
        SECRETS.append(unquote(parts.password))
    q = parts.query or "sslmode=require"
    url = urlunsplit((parts.scheme, parts.netloc, "/" + db, q, ""))
    SECRETS.append(url)
    return url


def app_by_name(name: str) -> dict | None:
    for a in doctl_json("apps", "list"):
        if a.get("spec", {}).get("name") == name:
            return a
    return None


def engine_base_url() -> str:
    """engine.ancu.ai once it serves /health, else the engine app's DO ingress
    (deployment.md §4 step 6: override before DNS, revert after)."""
    try:
        with urllib.request.urlopen("https://engine.ancu.ai/health", timeout=8) as r:
            if r.status == 200:
                return "https://engine.ancu.ai"
    except (urllib.error.URLError, OSError, ValueError):
        pass
    a = app_by_name("ancu-engine")
    if not a or not a.get("default_ingress"):
        die("ancu-engine has no ingress yet — apply the engine first and let it deploy")
    return a["default_ingress"].rstrip("/")


def fill_spec(text: str, values: dict[str, str], drop: set[str]) -> str:
    """Give each `- key: NAME` its value: SECRET entries gain a `value:` line, a
    committed `value:` is replaced; entries named in `drop` are removed."""
    lines = text.splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)- key: ([A-Z0-9_]+)\s*$", lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        indent, key = m.group(1), m.group(2)
        body = []
        j = i + 1
        while j < len(lines) and re.match(rf"^{indent}  \S", lines[j]) \
                and not lines[j].lstrip().startswith("#"):
            body.append(lines[j])
            j += 1
        if key in drop:
            i = j
            continue
        if key in values:
            body = [b for b in body if not b.lstrip().startswith("value:")]
            body.append(f"{indent}  value: {json.dumps(values[key])}")
        out.append(lines[i])
        out.extend(body)
        i = j
    return "\n".join(out) + "\n"


def secret_keys(text: str) -> list[str]:
    return re.findall(r"^\s*- key: ([A-Z0-9_]+)\s*\n\s*type: SECRET", text, re.M)


def apply(which: str) -> None:
    cfg = APPS[which]
    env = read_env()
    missing = [k for k in cfg["required"] if not env.get(k)]
    if missing:
        die(".env lacks " + ", ".join(missing) + " — nothing was changed on DO")
    text = cfg["spec"].read_text()
    c = cluster()
    values: dict[str, str] = {cfg["db_var"]: db_url(c, cfg["db"])}
    drop: set[str] = set()
    for k in secret_keys(text):
        if k == cfg["db_var"]:
            continue
        if env.get(k):
            values[k] = env[k]
        else:
            drop.add(k)
    for k in CONFIG_FROM_ENV:
        if env.get(k) and re.search(rf"^\s*- key: {k}\s*$", text, re.M):
            values[k] = env[k]
    if which == "shell":
        values["ENGINE_BASE_URL"] = engine_base_url()
    tmp = Path(tempfile.mkdtemp(prefix="ancu-spec-"))
    try:
        os.chmod(tmp, 0o700)
        spec = tmp / "app.yaml"
        spec.write_text(fill_spec(text, values, drop))
        os.chmod(spec, 0o600)
        doctl("apps", "spec", "validate", "--spec", str(spec), "--schema-only")
        existing = app_by_name(cfg["name"])
        if existing:
            res = doctl_json("apps", "update", existing["id"], "--spec", str(spec))
            verb = "updated"
        else:
            res = doctl_json("apps", "create", "--spec", str(spec))
            verb = "created"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    a: dict = res[0] if isinstance(res, list) and res else res
    print(f"{verb} {cfg['name']} id={a.get('id')} "
          f"ingress={a.get('default_ingress') or '(pending)'}")
    print("set:     " + ", ".join(sorted(values)))
    if drop:
        print("not set: " + ", ".join(sorted(drop)) + " (absent from .env)")
    if which == "shell":
        print(f"ENGINE_BASE_URL={values['ENGINE_BASE_URL']}")


def tenant_pubkey(priv_b64: str) -> str:
    """The ed25519 public half of SHELL_TENANT_PRIVKEY (base64 of the raw private
    key, fh_shell_engine_jwt), derived by OTP's crypto as the shell signs with it.
    The private key reaches erl through its environment, never argv."""
    expr = ('P=base64:decode(os:getenv("FH_PRIV")),'
            '{Pub,_}=crypto:generate_key(eddsa,ed25519,P),'
            'io:format("~s",[base64:encode(Pub)]),halt().')
    p = subprocess.run(["erl", "-noshell", "-eval", expr],
                       env={**os.environ, "FH_PRIV": priv_b64},
                       capture_output=True, text=True)
    if p.returncode != 0 or not p.stdout.strip():
        die("SHELL_TENANT_PRIVKEY does not decode to an ed25519 key:\n" + redact(p.stderr))
    return p.stdout.strip()


def register_tenant() -> None:
    env = read_env()
    missing = [k for k in ("SHELL_TENANT_ID", "SHELL_TENANT_PRIVKEY") if not env.get(k)]
    if missing:
        die(".env lacks " + ", ".join(missing))
    tid = env["SHELL_TENANT_ID"]
    if not re.fullmatch(r"[0-9a-fA-F-]{36}", tid):
        die("SHELL_TENANT_ID is not a uuid")
    pub = tenant_pubkey(env["SHELL_TENANT_PRIVKEY"])
    url = db_url(cluster(), "ancu_engine")
    u = urlsplit(url)
    pg = {**os.environ, "PGHOST": u.hostname or "", "PGPORT": str(u.port or 25060),
          "PGUSER": unquote(u.username or ""), "PGPASSWORD": unquote(u.password or ""),
          "PGDATABASE": "ancu_engine", "PGSSLMODE": "require"}

    def psql(sql: str, *vars_: tuple[str, str]) -> str:
        args = ["psql", "-X", "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1"]
        for k, v in vars_:
            args += ["-v", f"{k}={v}"]
        p = subprocess.run(args, input=sql, env=pg, capture_output=True, text=True)
        if p.returncode != 0:
            die("psql failed:\n" + redact(p.stderr))
        return p.stdout.strip()

    if psql("SELECT to_regclass('public.tenant_signing_keys') IS NOT NULL;") != "t":
        die("ancu_engine has no tenant_signing_keys yet — let ancu-engine boot "
            "(its migrations make the tables) first")
    psql("INSERT INTO tenants (tenant_id, name) VALUES (:'tid'::uuid, 'ancu-shell') "
         "ON CONFLICT (tenant_id) DO NOTHING;", ("tid", tid))
    n = psql("INSERT INTO tenant_signing_keys (tenant_id, public_key, algo) "
             "SELECT :'tid'::uuid, :'pub', 'ed25519' WHERE NOT EXISTS ("
             "SELECT 1 FROM tenant_signing_keys WHERE tenant_id = :'tid'::uuid "
             "AND public_key = :'pub' AND status = 'active') RETURNING key_id;",
             ("tid", tid), ("pub", pub))
    print(("registered" if n else "already registered")
          + f" the shell tenant's ed25519 public key {pub} in ancu_engine")


def main(argv: list[str]) -> None:
    if len(argv) == 2 and argv[0] == "apply" and argv[1] in APPS:
        apply(argv[1])
    elif argv == ["register-tenant"]:
        register_tenant()
    else:
        die("usage: do_deploy.py apply engine|shell | register-tenant")


if __name__ == "__main__":
    main(sys.argv[1:])
