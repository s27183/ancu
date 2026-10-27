"""Behavior 143 — an applied migration never changes.

P-2 · The database is the single source of truth -> the engine and shell databases ->
each migration's bytes are frozen once it is applied.
Both runners (fh_engine_migrations, fh_shell_migrations) record a sha256 per applied
file and refuse to boot when an applied file's bytes change. On 2026-10-27 a reworded
comment in engine 001_init_engine.sql stopped four production engine deploys; only
DigitalOcean's rollback kept the site up. This check catches that in CI instead.

Each migrations folder carries SHA256SUMS (`shasum -a 256 *.sql` format). It fails when
  - a listed file is missing, renamed, or its bytes no longer hash to its line, or
  - a .sql file is not listed (a new migration adds its own line, once:
    `shasum -a 256 NNN_name.sql >> SHA256SUMS`).
--self-test plants edits in a scratch copy (property: 300 cases, seed 143) and fails if
any edit passes or the untouched copy fails.

  .venv/bin/python tests/migrations_frozen.py [--self-test]
"""
import hashlib
import random
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDERS = ("engine/erlang/priv/migrations", "shell/web/backend/priv/migrations")
SUMS = "SHA256SUMS"


def problems(folder: Path) -> list[str]:
    found = []
    sums = folder / SUMS
    if not sums.is_file():
        return [f"{folder.name}: no {SUMS}"]
    listed = {}
    for n, line in enumerate(sums.read_text().splitlines(), 1):
        if not line.strip():
            continue
        digest, _, name = line.partition("  ")
        if len(digest) != 64 or not name:
            found.append(f"{sums}: line {n} is not `<sha256>  <file>`")
            continue
        listed[name] = digest
    for name, digest in sorted(listed.items()):
        f = folder / name
        if not f.is_file():
            found.append(f"{f}: applied migration is missing (deleted or renamed)")
        elif hashlib.sha256(f.read_bytes()).hexdigest() != digest:
            found.append(f"{f}: applied migration changed (sha256 differs from {SUMS}); "
                         "add a new migration instead")
    for f in sorted(folder.glob("*.sql")):
        if f.name not in listed:
            found.append(f"{f}: not in {SUMS} (a new migration adds its line: "
                         f"shasum -a 256 {f.name} >> {SUMS})")
    return found


def check(root: Path) -> list[str]:
    return [p for d in FOLDERS for p in problems(root / d)]


EDITS = ("byte", "append", "comment", "crlf", "delete", "rename", "unlisted")


def plant(folder: Path, rng: random.Random, edit: str) -> str:
    """Make one edit in folder; return the file name the failure must name."""
    files = sorted(folder.glob("*.sql"))
    f = rng.choice(files)
    b = f.read_bytes()
    if edit == "byte":
        i = rng.randrange(len(b))
        f.write_bytes(b[:i] + bytes([(b[i] + rng.randrange(1, 256)) % 256]) + b[i + 1:])
    elif edit == "append":
        f.write_bytes(b + b"\n")
    elif edit == "comment":
        f.write_bytes(b"-- reworded\n" + b)
    elif edit == "crlf":
        f.write_bytes(b.replace(b"\n", b"\r\n"))
    elif edit == "delete":
        f.unlink()
    elif edit == "rename":
        f.rename(folder / ("x" + f.name))
    elif edit == "unlisted":
        f = folder / f"999_new_{rng.randrange(10**6)}.sql"
        f.write_text("SELECT 1;\n")
    return f.name


def self_test(n: int = 300, seed: int = 143) -> list[str]:
    rng = random.Random(seed)
    bad = []
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp) / "base"
        for d in FOLDERS:
            shutil.copytree(ROOT / d, base / d)
        if check(base):
            return [f"untouched copy fails: {check(base)}"]
        for k in range(n):
            case = Path(tmp) / f"c{k}"
            shutil.copytree(base, case)
            folder = case / rng.choice(FOLDERS)
            edit = EDITS[k % len(EDITS)]
            name = plant(folder, rng, edit)
            found = check(case)
            if not any(name in p for p in found):
                bad.append(f"{edit} on {name} passed")
            shutil.rmtree(case)
    print(f"self-test: {n} cases, seed {seed}: counterexamples {bad}")
    return bad


def main() -> int:
    if "--self-test" in sys.argv:
        return 1 if self_test() else 0
    found = check(ROOT)
    for p in found:
        print("FAIL", p)
    if found:
        return 1
    counts = [len(list((ROOT / d).glob("*.sql"))) for d in FOLDERS]
    print(f"ok   migrations frozen: engine {counts[0]}, shell {counts[1]}, each matches {SUMS}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
