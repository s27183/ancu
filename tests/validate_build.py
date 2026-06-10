#!/usr/bin/env python3
"""CI entry for whole-build validation — delegates to the artifact compiler.

This used to carry its own copy of the structural checks (slug==path, renderer
enum, pipeline acyclicity) and a second `RENDERER_ENUM`. Those moved into the
compiler ([`engine/build/kb_compiler.py`]) when it was promoted to the single
validator (grounding-checklist §4): the compiler runs the four structural gates
(mode-independent → over EVERY blueprint/doc) PLUS the semantic gates it added
— content_json parse, reference-integrity, coverage, type-compat (Mode-A
registry, per the scope call). Keeping a forked copy here would only reintroduce
the drift the whole grounding effort fights, so this file is now a thin shell.

CI runs it with `--no-emit`: the gates must be green, but emitting the artifact
(`engine/erlang/priv/kb/artifact.json`) is a deploy-time step, not a test. We
force `--no-emit` here so running the CI entry can never write the artifact.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "engine" / "build"))
import kb_compiler  # noqa: E402 — path injected above

if __name__ == "__main__":
    if "--no-emit" not in sys.argv:
        sys.argv.append("--no-emit")
    sys.exit(kb_compiler.main())
