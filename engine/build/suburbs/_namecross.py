"""_namecross — the name→SAL crosswalk shared by the by-suburb enrichment adapters.

Several feeds publish pre-aggregated metrics keyed by THEIR OWN gazetted suburb list
(VPSR median price, BOCSAR crime, and the coming csa_vic / qps) — which is ≈ but ≠ the
ABS SAL gazette (suburb-data-foundation.md §5, "the one fiddly bit"). This is the single
reconciliation machine: index the census-spine SAL names for a state, then resolve each
source locality to a `sal_code`.

Both sides disambiguate a repeated base-name with an LGA qualifier:

    ABS SAL:  'Abbotsford (Vic.)'              bare or state-tagged
              'Ascot (Greater Bendigo - Vic.)' LGA-disambiguated
    source:   'ABBOTSFORD'  /  'ASCOT (GREATER BENDIGO)'

Resolution: a unique base wins; a multi-SAL base is disambiguated by the LGA qualifier;
otherwise `None` — the caller logs the drop, never guesses (§5,
[[enforce-invariants-not-workflows]]). Measured coverage: VPSR 96% (VIC), BOCSAR 100%
(NSW — the NSW gazette enforces name uniqueness, LGA-qualifying only the duplicate tail).

The factoring is deliberate: with ≥2 identical consumers (and two more crime states
coming), the crosswalk is the robust root, not a per-adapter copy ([[long-term-vs-patch-design]]).
"""
from __future__ import annotations

import re
from collections import defaultdict

# A source locality: 'BARE' or 'BARE (LGA)'.
_SRC_RE = re.compile(r"^(.*?)\s*\((.+)\)\s*$")


def _norm(s: object) -> str:
    return re.sub(r"\s+", " ", str(s).strip()).upper()


def _src_parse(locality: str) -> tuple[str, str | None]:
    """A source feed's locality → (base, lga|None)."""
    m = _SRC_RE.match(locality.strip())
    if m:
        return _norm(m.group(1)), _norm(m.group(2))
    return _norm(locality), None


class Crosswalk:
    """A built name→SAL index for one state. Construct via :func:`build`."""

    def __init__(self, idx: dict[str, list[tuple[str, str | None]]]):
        self._idx = idx

    def resolve(self, locality: str) -> str | None:
        """Source locality → sal_code, or None when absent/ambiguous (caller logs the drop)."""
        base, lga = _src_parse(locality)
        cands = self._idx.get(base)
        if not cands:
            return None
        if len(cands) == 1:
            return cands[0][0]
        hit = [sal for sal, clga in cands if clga is not None and clga == lga]
        return hit[0] if len(hit) == 1 else None


def build(conn, state: str, abs_tag: str) -> Crosswalk:
    """Index the census-spine names for `state` into a :class:`Crosswalk`.

    `abs_tag` is the ABS state abbreviation as it appears parenthesised in SAL names
    ('Vic.' for VIC, 'NSW' for NSW). ABS SAL name forms: 'Base', 'Base (TAG)', or
    'Base (LGA - TAG)'.
    """
    abs_re = re.compile(rf"^(.*?)\s*\((?:(.+?)\s*-\s*)?{re.escape(abs_tag)}\)\s*$")
    idx: dict[str, list[tuple[str, str | None]]] = defaultdict(list)
    with conn.cursor() as cur:
        cur.execute("SELECT sal_code, name FROM suburbs WHERE state = %s", (state,))
        for sal, name in cur.fetchall():
            m = abs_re.match(name)
            if m:
                base, lga = _norm(m.group(1)), (_norm(m.group(2)) if m.group(2) else None)
            else:
                base, lga = _norm(name), None
            idx[base].append((sal, lga))
    return Crosswalk(idx)
