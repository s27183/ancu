"""Behavior 140, Expect 1 — every model call in planner.py is confined.

R-4 · Reasoning within its runtime -> The sidecar -> the planner model can only answer
Offline (no model, no network): reads engine/python/planner.py with `ast` and fails when
  - ClaudeAgentOptions is called anywhere but inside _model_options, or
  - _model_options stops setting tools=[], setting_sources=[], cwd, max_turns, env and
    the no-session-persistence extra arg, or
  - a caller of _model_options passes one of those itself, or passes no max_turns.
A self-test runs the same checks on planted sources (a bare ClaudeAgentOptions call, a
helper without tools=[]) and fails if they pass.

  .venv/bin/python tests/sidecar_options_check.py
"""
import ast
import sys
from pathlib import Path

PLANNER = Path(__file__).resolve().parents[1] / "engine" / "python" / "planner.py"
HELPER = "_model_options"
CONFINED = ("tools", "setting_sources", "cwd", "env", "extra_args", "permission_mode")


def _name(func):
    if isinstance(func, ast.Name):
        return func.id
    if isinstance(func, ast.Attribute):
        return func.attr
    return None


def problems(source):
    tree = ast.parse(source)
    found = []
    helper = None
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == HELPER:
            helper = node
    if helper is None:
        return [f"no {HELPER} function"]
    inside = {id(n) for n in ast.walk(helper)}

    helper_calls = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        name = _name(node.func)
        if name == "ClaudeAgentOptions" and id(node) not in inside:
            found.append(f"line {node.lineno}: ClaudeAgentOptions called outside {HELPER}")
        if name == "ClaudeAgentOptions" and id(node) in inside:
            helper_calls.append(node)
        if name == HELPER:
            kws = {k.arg for k in node.keywords}
            for k in CONFINED:
                if k in kws:
                    found.append(f"line {node.lineno}: caller sets {k} (the helper's to set)")
            if "max_turns" not in kws:
                found.append(f"line {node.lineno}: {HELPER} call without max_turns")

    if len(helper_calls) != 1:
        found.append(f"{HELPER} must build exactly one ClaudeAgentOptions, builds {len(helper_calls)}")
    else:
        kw = {k.arg: k.value for k in helper_calls[0].keywords}
        if not (isinstance(kw.get("tools"), ast.List) and not kw["tools"].elts):
            found.append(f"{HELPER}: tools must be the literal []")
        if not (isinstance(kw.get("setting_sources"), ast.List) and not kw["setting_sources"].elts):
            found.append(f"{HELPER}: setting_sources must be the literal []")
        for k in ("cwd", "max_turns", "env"):
            if k not in kw:
                found.append(f"{HELPER}: {k} not set")
        extra = kw.get("extra_args")
        if not (isinstance(extra, ast.Dict)
                and any(isinstance(k, ast.Constant) and k.value == "no-session-persistence"
                        for k in extra.keys)):
            found.append(f"{HELPER}: extra_args lacks no-session-persistence")
        if "permission_mode" in kw:
            found.append(f"{HELPER}: permission_mode set (with no tools there is nothing to permit)")
    return found


GOOD_HELPER = '''
def _model_options(*, max_turns, **kw):
    return ClaudeAgentOptions(tools=[], setting_sources=[], cwd=d(), max_turns=max_turns,
                              extra_args={"no-session-persistence": None}, env=e(), **kw)
'''

PLANTED = {
    "a bare ClaudeAgentOptions call": GOOD_HELPER + '''
def leaf():
    options = ClaudeAgentOptions(model="opus", allowed_tools=[])
''',
    "a helper without tools=[]": GOOD_HELPER.replace("tools=[], ", "") + '''
def leaf():
    options = _model_options(model="opus", max_turns=4)
''',
    "a helper that persists sessions": GOOD_HELPER.replace(
        '{"no-session-persistence": None}', "{}") + '''
def leaf():
    options = _model_options(model="opus", max_turns=4)
''',
    "a caller that sets cwd": GOOD_HELPER + '''
def leaf():
    options = _model_options(model="opus", max_turns=4, cwd="/app")
''',
    "a caller without max_turns": GOOD_HELPER + '''
def leaf():
    options = _model_options(model="opus")
''',
}


def main():
    failed = False
    good = problems(GOOD_HELPER + "\ndef leaf():\n    options = _model_options(model='o', max_turns=4)\n")
    if good:
        print(f"FAIL self-test: the good fixture was flagged: {good}")
        failed = True
    for label, src in PLANTED.items():
        if not problems(src):
            print(f"FAIL self-test: {label} passed the check")
            failed = True
    source = PLANNER.read_text()
    found = problems(source)
    calls = sum(1 for n in ast.walk(ast.parse(source))
                if isinstance(n, ast.Call) and _name(n.func) == HELPER)
    for p in found:
        print(f"FAIL planner.py {p}")
    if found or failed:
        return 1
    print(f"ok   planner.py: {calls} model calls, all through {HELPER} "
          f"(tools=[], empty cwd, no session persistence, max_turns); "
          f"self-test: {len(PLANTED)} planted sources caught")
    return 0


if __name__ == "__main__":
    sys.exit(main())
