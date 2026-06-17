# Suburb adapter workflow — the repeatable recipe

**What this is.** The *method* for adding a new per-state suburb-data adapter (a gov
feed → `suburbs.facts_jsonb`). It is the **how**; [`suburb-data-foundation.md`](suburb-data-foundation.md)
is the **what/why** (the `suburb.*` surface, the schema, the per-adapter decisions). This
recipe is extracted from the six adapters built so far — `abs_census_2021`, `abs_seifa_2021`,
`abs_asgs_2021` (the spine), `vic_vpsr` (price), `bocsar` + `csa_vic` (crime) — at the point a
2nd crime instance made the shared shape worth codifying ([[decompose-build-unit-by-mechanism]]).
Follow it state by state; the worked classifications below are the reference.

All adapters live in `engine/build/suburbs/`, run as `python -m suburbs.<name>`, are
**sync psycopg3** batch jobs (offline ingest, not the runtime serving tier — [[firsthomey-build-adapter-driver]]),
and share `db.py` (upsert/provenance/source-register) + `_namecross.py` (name→SAL).

---

## Step 0 — Classify the source on three axes (this decides everything)

Answer these **before** writing code. The classification, not the field name, is the build unit.

### A. Metric kind — how the value enters the system
- **sourced** — the publisher emits the official band/decile; store it **directly**, do not
  re-threshold (`seifa_irsad_decile` = ABS `RWAD`).
- **projected** — raw value + a FirstHomey KB threshold cut at the resolver's `<from_suburb>`
  lookup; the adapter stores only the **raw** metric (`vietnamese_ancestry_pct` → the coarse
  `vietnamese_community_proximity` band is resolver-side, not the adapter's).
- **unbanded / map-only** — a real metric with **no** resolver band, ever (`crime_*`).
  See axis B for why.

  Plus a verification grade: **regulated figure** (verify to the dollar vs the official
  calculator — stamp duty, LMI) vs **KB-curated estimate** (verify vs the KB SOT, surface as a
  range). Most `suburb.*` metrics are descriptive stats (count/rate/decile), not regulated.

### B. Plan consumer — does anything in the plan DAG read it? (the admission question)
A metric can be **map-worthy yet plan-invalid** ([[valuable-to-show-not-valid-to-decide]]).
Before giving a metric any resolver field, ask: (1) does an eligibility/cash/mortgage/ownership
component read it? (2) would coercing it to a band force a verdict that misleads or inverts the
product's value? **Fail either → keep it raw on the map, no `suburb.*` field.** Crime is the
canonical fail: no DAG reads it, and a band would stamp "high crime" on the Vietnamese hubs
(Cabramatta 151/1000, Footscray ~207, Springvale 146 — commercial-strip inflation), inverting
the killer community-proximity layer. So crime is **unbanded**.

### C. Fetch mechanism — the **bot-wall axis decides**, not cadence
- **live-pull** — a reachable HTTP/blob endpoint, no wall (`bocsar` Azure blob; ABS REST/CSV).
  Pull it in the adapter.
- **human-staged** — bot-walled (Cloudflare JS challenge, login, CAPTCHA). A human downloads
  the file to `engine/build/suburbs/data/`; the adapter reads the staged file. Quarterly/annual
  cadence makes a manual drop legitimate.
  - **Reproducibility:** commit the staged file **only if it is also non-refetchable**
    (`vpsr-*.xls` — Cloudflare-walled, small → committed). If the file *host* is reachable even
    though the index is walled (CSA: UA-filtered HTML, open file CDN), **gitignore it + record
    the refetch URL** in `data/README.md` (don't carry 18 MB git can't dedup).
- **closed / paid → null** — no free feed (QLD price). Store nothing; the field stays `null`
  (honest-partial), recorded as deferred in the design doc §11.

> The axis genuinely discriminates: VPSR and BOCSAR are **both quarterly** yet landed on opposite
> mechanisms (VPSR Cloudflare-walled → human-staged; BOCSAR open blob → live-pull). A classifier
> that always says "human-staged" is a rationalisation — test the wall, not the cadence.

**The six built adapters, classified:**

| Adapter | Metric kind (A) | Plan consumer (B) | Fetch (C) |
|---|---|---|---|
| `abs_census_2021` | raw (ancestry %) → projected band | yes (proximity band) | live-pull (ABS REST) |
| `abs_seifa_2021` | **sourced** (decile = `RWAD`) | yes (SEIFA) | live-pull (ABS CSV) |
| `abs_asgs_2021` | n/a (geometry) | n/a (map placement) | live-pull (ABS ArcGIS) |
| `vic_vpsr` | raw (median) | no (decoration) | **human-staged** (Cloudflare) → committed |
| `bocsar` (NSW crime) | **unbanded** | **no** | live-pull (Azure blob) |
| `csa_vic` (VIC crime) | **unbanded** | **no** | **human-staged** (UA-filtered) → gitignored |

---

## Step 1 — Ground the live contract (before any code)
Verify host, format, grain against the **live** source, not memory or this repo's docs
([[reason-from-materialized-ground]]). Grounding has overturned a doc assumption almost every
time: the ABS API host moved (`api.data.abs.gov.au` → `data.api.abs.gov.au/rest`); VPSR's
"free/easy" was a Cloudflare wall; SEIFA's decile is publisher-sourced; CSA's suburb grain lives
in one specific sheet (`Table 03`). A 15-minute `WebFetch`/`curl` here saves a rebuild.

## Step 2 — Pick the row role
- **spine** (`db.upsert_facts`, carries `name`/`state`) — seeds rows. Only the census/ASGS
  spine does this.
- **enrichment** (`db.update_facts` for `facts_jsonb`, or `db.update_columns` for real columns)
  — **UPDATE-only** against the existing spine; returns the crosswalk misses. Everything after
  the spine is enrichment (seifa, vpsr, bocsar, csa).

## Step 3 — Crosswalk to SAL (the join grain)
SAL is the grain. Three cases:
- **direct-SAL** — the feed is keyed by SAL code (census, seifa). No crosswalk.
- **name→SAL** — `xw = _namecross.build(conn, STATE, ABS_TAG)` then `xw.resolve("Name (LGA)")`.
  The LGA in parens disambiguates duplicate base names; a unique base wins outright; otherwise
  the drop is logged, never guessed. Feed it `f"{suburb} ({lga})"` when the source has separate
  suburb + LGA columns (CSA) — a clean LGA column beats a paren-qualifier (CSA 99.96% > VPSR 96%).
  `ABS_TAG` is the state's parenthetical SAL tag (`"Vic."`, `"NSW"`).
- **point→SAL / area-correspondence** — needs the deferred SAL polygons or the MB allocation
  sub-build (NSW price, `lga_name`). Defer until that mechanism lands.

## Step 4 — Measure coverage; be honest-partial
Log every dropped locality and every matched-SAL-without-population; **never invent** a value.
Report the numbers (no silent truncation — [[enforce-invariants-not-workflows]]). Coverage
benchmarks to compare against: census 100%, SEIFA (15,345 − 7 out-of-scope), centroids
15,329/15,345, VPSR 96%, BOCSAR 100%, CSA 99.96%.

## Step 5 — Upsert + provenance + license
- Build rows `{"sal_code", "facts": {...}, "prov": {field: {source_id, as_of}}}` (or columns).
- `db.ensure_source(conn, SOURCE)` — one `suburb_sources` row per feed (publisher, **license**,
  attribution, redistribution, url). This is the §6.1 license-compliance artifact, not a footnote;
  the map's attribution strip renders it.
- `conn.commit()`.

## Step 6 — The crime sub-pattern (the template for the remaining states)
Crime adapters share one shape; only fetch + parse + crosswalk differ per state:
1. Sum **all** offence counts over the **latest annual window** per suburb (least-interpretive
   composite — privileges no offence category).
2. `crime_incidents_per_1000 = annual ÷ census_total_persons × 1000` (the denominator the census
   adapter stored for exactly this).
3. Store `crime_incidents_annual` + `crime_period` too — the count + window give the map's small-n
   honesty (a near-zero-residential commercial zone reads absurdly high per-capita).
4. **Map-only, no band.** No `crime_safety_band`, ever (Step 0B).

`bocsar` (live-pull wide CSV, monthly columns → trailing-12 sum) and `csa_vic` (human-staged
`.xlsx`, pre-annualised `Table 03` rows → latest-year sum) are the two worked instances. QLD/WA/
SA/TAS/NT reuse this; expect each state's offence taxonomy + geography to differ, so re-ground
(Step 1) per state.

## Step 7 — Run + verify
```
cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.<name>
```
Then confirm in the DB: the populated count (vs the prior 0), a hub sanity check (does the value
look right for a known suburb?), the `suburb_sources` row, and the provenance stamp on a sample
field.

---

## New-adapter checklist
- [ ] **Classify** (Step 0): metric kind A, plan-consumer B, fetch mechanism C.
- [ ] **Ground** the live contract (Step 1) — host, format, grain, license.
- [ ] **Role**: spine or enrichment (Step 2).
- [ ] **Crosswalk**: direct / name→SAL / deferred (Step 3).
- [ ] **`SOURCE`** dict (Step 5) — publisher, license, attribution, url, notes.
- [ ] **Coverage** measured + misses logged (Step 4).
- [ ] **Staged file?** → `data/.gitignore` + `data/README.md` decision (Step 0C).
- [ ] **Run + verify** in dev PG (Step 7).
- [ ] **Reconcile** `suburb-data-foundation.md` §6 (mark the row done) + this doc if the recipe shifted.
