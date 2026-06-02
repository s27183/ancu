---
slug: kb.building-pest.interpretation
effective_from: 2025-07-01
last_verified: 2026-06-02
---

# Interpreting building and pest inspection reports

A **building inspection** and a **timber pest inspection** are the buyer's primary protection against the condition risks a contract does not warrant. On an established home there is **no statutory builder warranty** — the reports are what stand between the buyer and an inherited structural or termite problem. This doc owns **how to interpret those reports**: what they cover, their inherent limits, and how to tell a deal-breaker from ordinary wear. It grounds the `due_diligence` parameters `building_flags` and `pest_flags` (both agent-reasoned, `reasoning_domain: document_significance`, building flags carrying an `estimated_repair_cost`) — supplying the interpretation framework the agent reasons against when reports are uploaded, not a verdict on any one report. Provenance is **CONVENTION** anchored to the Australian Standards; repair costs are **INDICATIVE**.

## What the reports cover — and what they don't

- **Building inspection (to AS 4349.1—2007, *Pre-purchase inspections — Residential buildings*).** A **visual, non-invasive** inspection of reasonably accessible areas — structure (footings/foundations, walls, roof framing and covering), moisture and rising damp, and safety hazards. The inspector does **not** cut into walls, lift carpets, or move stored goods, and areas with **no safe access** (subfloor, roof void) are recorded as **not inspected** — a limitation, not an all-clear. AS 4349.1 **excludes timber pests** unless a separate timber pest inspection is booked.
- **Timber pest inspection (to AS 4349.3—2010, *Timber pest inspections*).** Targets **subterranean and dampwood termites, borers of seasoned timber, and wood-decay fungi (rot)**, plus conditions conducive to them — also **visual and non-invasive**. **AS 3660** (Part 1 new building work; Part 2 in and around existing buildings) is the **termite-management** standard a barrier/treatment is built to.
- **Two separate inspections.** Because AS 4349.1 excludes timber pests, the building and pest inspections are **separate engagements** (often sold as a combined booking). The plan tells the buyer to commission **both**.

## Reading the building report

- **Major defect vs minor defect — the load-bearing distinction.** A **major defect** is one of **structural or safety significance** (footing/foundation movement, structural cracking, roof structural failure, unsafe wiring) — a **renegotiation lever or a withdraw trigger**. A **minor defect** is cosmetic or fair wear-and-tear, **expected in an established home** and not a deal-breaker. The agent's job is to separate the two, not to alarm at every noted item.
- **`estimated_repair_cost` is indicative.** The report **flags**, it does not **price**. Any repair figure is an estimate pending trade quotes; the agent presents it as a band and as a negotiation input, never as a settled cost.

## Reading the pest report

- **Active (live) termite activity** → **urgent**. Live termites mean an ongoing attack; the buyer should obtain a treatment quote and treat (or make the purchase conditional on treatment) **before committing**. A trigger to renegotiate or withdraw.
- **Old / inactive damage** → **assess the extent**. Past activity that is no longer live still requires a structural assessment — the damage may be superficial or may have compromised load-bearing timber.
- **Conducive conditions** (moisture, poor drainage, timber-to-soil contact, no or expired termite barrier) → **latent risk not yet realised**. Remediate the conditions and install/renew a barrier to AS 3660.
- **Termites are Australia's dominant structural timber pest**, with risk **highest in warm, humid zones (QLD and northern NSW)**. On an established home in those regions a clear, current timber pest report is non-negotiable.

## Timing (owned elsewhere — cross-ref)

Both inspections must be **completed during the cooling-off window** (private treaty) or **before bidding** (auction — where there is **no cooling-off and no subject-to-inspection condition**). The auction carve-out makes building + pest a **pre-bid** step. The window and the auction carve-out are owned by `kb.cooling-off.by-state`; the subject-to-inspection special condition by `kb.special-conditions.standard-set`. This doc owns only the **interpretation**.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The report is the only protection on an established home.** With no statutory builder warranty, a Mode-A buyer relies entirely on the building + pest reports — the plan frames them as essential spend, not optional.
- **Translate major-vs-minor and active-vs-old.** For a second-language buyer, a dense technical report is hard to weigh; the agent surfaces which findings are deal-breakers and which are normal, and lists the questions to put to the inspector.
- **Termite-prone suburbs get a flag.** In QLD / northern NSW the plan elevates the timber pest report and conducive-conditions findings.
- **At auction, you cannot make it conditional — do it first.** Because there is no cooling-off and no subject-to-inspection condition at auction, the plan front-loads building + pest **before** the auction date (cross-ref `kb.cooling-off.by-state`).
- **Information, not advice.** The plan explains how to read the reports and directs the buyer to the inspector and their conveyancer; it does not assess structural soundness or price repairs itself.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `building_flags` and `pest_flags` are **agent-reasoned** (`reasoning_domain: document_significance`) over uploaded reports; this doc supplies the interpretation framework the agent reasons against.

```jsonc
{
  "fills": [],
  "parameters": {
    "reports_are_visual_non_invasive": { "type": "bool", "value": true, "note": "CONVENTION (AS 4349.1—2007 / AS 4349.3—2010) — both inspections are visual and non-invasive; inaccessible areas (subfloor, roof void) are recorded as not inspected, which is a limitation, not an all-clear. The report is not a guarantee of condition." },
    "building_and_pest_are_separate_inspections": { "type": "bool", "value": true, "note": "CONVENTION (AS 4349.1 excludes timber pests) — the building inspection and the timber pest inspection are separate engagements; commission both." },
    "major_vs_minor_defect_distinction": { "type": "bool", "value": true, "note": "CONVENTION (the load-bearing interpretation) — a MAJOR defect has structural/safety significance (footing movement, structural cracking, roof failure, unsafe wiring) and is a renegotiation lever or withdraw trigger; a MINOR defect is cosmetic/wear and expected in an established home. The agent separates the two." },
    "active_vs_old_termite_distinction": { "type": "bool", "value": true, "note": "CONVENTION — live/active termite activity is urgent (treat/condition before committing); old/inactive damage requires a structural-extent assessment; conducive conditions (moisture, timber-soil contact, no/expired barrier) are latent risk to remediate (barrier to AS 3660)." },
    "termites_dominant_au_timber_pest": { "type": "bool", "value": true, "note": "CONVENTION — termites are Australia's dominant structural timber pest; risk is highest in QLD and northern NSW, where a clear current timber pest report is non-negotiable for an established home." },
    "estimated_repair_cost_is_indicative": { "type": "bool", "value": true, "note": "CONVENTION / INDICATIVE — the report flags defects, it does not price them; any repair cost is an estimate pending trade quotes and is presented as a band and a negotiation input, never a settled figure." }
  },
  "lookup": {
    "building_defect_severity": {
      "note": "CONVENTION — how the agent classifies a building-report finding and the typical action. Severity drives building_flags.severity and the negotiation/withdraw posture.",
      "entries": [
        { "severity": "major", "meaning": "structural or safety significance (footing/foundation movement, structural cracking, roof structural failure, unsafe wiring)", "typical_action": "obtain trade quotes; renegotiate price or withdraw" },
        { "severity": "minor", "meaning": "cosmetic or fair wear-and-tear, expected in an established home", "typical_action": "note for the maintenance budget; not a deal-breaker" }
      ]
    },
    "pest_finding_types": {
      "note": "CONVENTION — how the agent reads a timber pest finding and the typical action. Drives pest_flags.severity.",
      "entries": [
        { "finding": "active_live_activity", "meaning": "ongoing termite attack", "typical_action": "urgent — treatment quote; treat or make conditional before committing; renegotiate / withdraw trigger" },
        { "finding": "old_inactive_damage", "meaning": "past activity, no longer live", "typical_action": "structural-extent assessment — may be superficial or load-bearing" },
        { "finding": "conducive_conditions", "meaning": "moisture, poor drainage, timber-to-soil contact, no/expired barrier", "typical_action": "latent risk — remediate conditions; install/renew barrier to AS 3660" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `building_flags` / `pest_flags` (incl. `estimated_repair_cost`) are produced by agent reasoning over the uploaded reports; this doc is the **grounding framework** (coverage, limits, severity classification). Same pure-reference shape as the other `due_diligence` anchors.
- **CONVENTION anchored to the Australian Standards.** The interpretation framework is industry practice built on AS 4349.1—2007 (building), AS 4349.3—2010 (timber pest) and AS 3660 (termite management). The standards are the canonical concept anchors even though their full text is paywalled (Standards Australia); repair costs are INDICATIVE (market, quote-dependent).
- **Major-vs-minor is the load-bearing interpretation.** It determines whether a finding is a negotiation lever / withdraw trigger or a routine maintenance note — lifted into an explicit parameter and a lookup so the agent applies it consistently.
- **Single-owner.** This doc owns **report interpretation**. The **cooling-off window and the auction carve-out** (when inspections must be done) → `kb.cooling-off.by-state`; the **subject-to-inspection special condition** → `kb.special-conditions.standard-set`; **strata-report** reading → `kb.strata-report.red-flags`; the **risk profile by property type** → `kb.building-types.risk-by-type`; the **maintenance budget** a minor-defect note feeds → `kb.maintenance.budget-by-property-type`. Cross-ref, not duplicated.

## Sources

**Canonical (Australian Standards — the inspection framework):**

- *AS 4349.1—2007, Inspection of buildings — Part 1: Pre-purchase inspections — Residential buildings* — the benchmark for a pre-purchase building inspection (visual, non-invasive; excludes timber pests). Standards Australia (full text paywalled; cited by designation).
- *AS 4349.3—2010, Inspection of buildings — Part 3: Timber pest inspections* — the benchmark for a pre-purchase timber pest inspection (termites, borers, wood-decay fungi; visual, non-invasive). Standards Australia (paywalled; cited by designation).
- *AS 3660 (Part 1 new building work; Part 2 existing buildings), Termite management* — the standard a termite barrier/treatment is built to. Standards Australia (paywalled; cited by designation).

**Canonical (state consumer authorities — what an inspection is and why):**

- NSW Fair Trading — *Building and pest inspections* — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw
- Consumer Affairs Victoria — *Buying property: inspections* — https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property
- Queensland Government — *Building and pest inspections when buying a home* — https://www.qld.gov.au/law/housing-and-neighbours/buying-and-selling-a-property/buying-a-home

**Point-in-time / practice (INDICATIVE):**

- Repair-cost estimates are market figures dependent on trade quotes; no regulator publishes them. Treated as INDICATIVE and presented as a band, never a settled cost.
