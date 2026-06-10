---
slug: kb.firb.status-determination
effective_from: 2015-12-01
last_verified: 2026-06-01
---

# Determining FIRB status — is the buyer a foreign person?

**FIRB status** is the single fact every flow branches on (constraint #10): whether a buyer is a **foreign person** under the *Foreign Acquisitions and Takeovers Act 1975* (FATA). The classification decides which mode applies — a non-foreign buyer (Mode A / C) is unaffected by the foreign-investment framework, while a foreign person (Mode B / D) must obtain approval **before** signing an unconditional contract and is caught by the [established-dwelling ban](established-dwelling-ban.md). This doc owns the *classification* (who is a foreign person); the ban doc owns the *prohibition* (what a foreign person may then buy).

The test is **residency, not nationality**: a **foreign person** is a natural person who is **not ordinarily resident in Australia**. An Australian citizen is never a foreign person. Everyone else is classified by the **ordinarily-resident** test.

## The ordinarily-resident test

A non-citizen is **ordinarily resident in Australia** at a given time only if **both** hold:

1. they have been **physically in Australia for 200 or more days** of the preceding 12-month period; **and**
2. their continued presence is **not subject to any limitation as to time** imposed by law (i.e. not restricted by a visa's time limit).

The second limb is what separates permanent from temporary residents:

- **Australian citizen** — **never** a foreign person, regardless of where they live. No FIRB.
- **Permanent resident** (permanent-entry visa) — **not** subject to a time limitation, so if ordinarily resident (200-day limb) they are **not** a foreign person. A PR who is *not* ordinarily resident (e.g. living overseas, fewer than 200 days in Australia) **can** still be a foreign person.
- **Temporary resident** (a temporary visa permitting a continuous stay of more than 12 months, or a bridging visa with a pending permanent-visa application) — their presence **is** time-limited, so they fail the second limb and **are foreign persons** even if physically present 200+ days. This is the counter-intuitive result that catches many AU-based temporary-visa holders (Mode B).
- **Non-resident** (living overseas, no Australian visa entitlement) — a foreign person.

> A foreign-owned **company or trust** is also a foreign person (broadly ≥20% single or ≥40% aggregate foreign interest), but that is out of scope for the individual-buyer modes this blueprint covers.

## Status-level carve-outs (Modes B / D)

Two carve-outs change a buyer from *foreign person requiring approval* to *not a foreign person* — they resolve **here**, upstream of the ban, by setting the carved-out applicant's `applicant.firb_required = false`, which propagates to the aggregate `profile.firb_required_any` that the [established-dwelling ban](established-dwelling-ban.md)'s purchase predicate reads:

- **New Zealand citizens / Special Category Visa (subclass 444) holders** — do not require foreign-investment approval and are treated as outside the foreign-person framework for residential purchases.
- **Spouse of an Australian citizen, permanent resident, or NZ citizen** — where the couple acquires the property **as joint tenants**, the foreign spouse is carved out of foreign-person treatment for that acquisition.

Both turn on facts not yet on the Mode A profile surface (there is no NZ-citizen option in `citizenship_status`, and no `spouse_is_citizen_pr` / `buying_as_joint_tenants` fact). They are **documented here and agent-surfaced**; their backing facts are added to the surface when the Mode B / D blueprints are built (Wedge 2+). For Mode A they never bind — see Notes.

## Relevance for Vietnamese-Australian buyers

- **Mode A (citizen / PR ordinarily resident in Australia): not a foreign person.** `applicant.firb_required` resolves to **false** (and so the aggregate `profile.firb_required_any`); do not surface FIRB as a constraint — it only confuses. This is the common diaspora case (naturalised citizens and settled PRs).
- **Mode B (Vietnam-parent funding an AU child; AU temporary resident): the child on a student / graduate / skilled *temporary* visa IS a foreign person**, even living in Australia full-time — the time-limited visa fails the ordinarily-resident test. They need approval and are caught by the established-dwelling ban (new-build / vacant-land only) unless the spouse-joint-tenant carve-out applies.
- **Mode D (Vietnam-located investor): a foreign person** (non-resident). Approval required; new-build / vacant-land only.
- **PR living in Vietnam:** a permanent resident who has spent fewer than 200 days in Australia in the past year is **not ordinarily resident** and can be a foreign person despite holding PR — relevant where a diaspora buyer holds AU PR but lives in Vietnam (a Mode-D-shaped case).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This doc is the **single owner** of the `applicant.firb_required` derivation — per-applicant (mapped over `profile.applicants`), with the application-scoped aggregate `profile.firb_required_any` published by `buyer_profile` (constraint #10 — the gate lives in the architecture, not in a disclaimer). The classification rule fills the derived bool; the 200-day test and the carve-outs are parameters/agent-surfaced (see Notes).

```jsonc
{
  "fills": [
    // firb_required = the buyer IS a foreign person. TRUE iff a temporary or non-resident; citizen and
    // (ordinarily-resident) PR are not foreign. This is the derivation behind firb_status's
    // `derived_from: citizenship_status` in buyer_profile. The PR-not-ordinarily-resident edge and the
    // NZ / spouse carve-outs are NOT in this predicate (no backing facts on the Mode A surface) — see Notes.
    { "leaf": "applicant.firb_required",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "applicant.citizenship_status", "op": "in", "value": ["temporary_resident", "non_resident"] } ] } }
  ],
  "parameters": {
    "ordinarily_resident_min_days":   { "type": "integer", "value": 200, "note": "physically in Australia ≥200 of the preceding 365 days — limb 1 of the ordinarily-resident test" },
    "ordinarily_resident_requires_no_time_limit": { "type": "bool", "value": true, "note": "limb 2 — continued presence not subject to a visa time limit; the limb temporary residents fail" },
    "foreign_person_citizenship_statuses": { "type": "array<string>", "value": ["temporary_resident", "non_resident"], "note": "the citizenship_status values that resolve firb_required=true for Mode A's surface" },
    "not_foreign_person_citizenship_statuses": { "type": "array<string>", "value": ["citizen", "permanent_resident"], "note": "PR assumes ordinarily-resident (Mode A); a non-ordinarily-resident PR is the documented edge case" },
    "status_level_carveouts": { "type": "array<string>", "value": [
      "New Zealand citizen / Special Category Visa (subclass 444) holder — no foreign-investment approval required",
      "Spouse of an Australian citizen, PR, or NZ citizen acquiring the property as joint tenants"
    ], "note": "resolve to firb_required=false upstream of the ban; agent-surfaced for Mode A — no backing facts on the surface yet (Wedge 2+)" }
  }
}
```

Notes:

- **`firb_required` is filled here, not in `buyer_profile` logic.** `buyer_profile` collects the raw `citizenship_status` fact; this doc supplies the *rule* that derives `firb_required` from it (the blueprint marks `firb_status` as `derived_from: citizenship_status`). Giving the regulated classification exactly one home is the same single-owner discipline as the ban window living once in [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md).
- **The predicate treats PR as not-foreign — a Mode A simplification.** The strict test also requires the PR to be *ordinarily resident* (the 200-day limb). For Mode A (a PR settled in Australia) that always holds, so the predicate uses `citizenship_status` alone. The PR-not-ordinarily-resident case (PR living in Vietnam) is real but is a **Mode D-shaped** edge — promote a `days_in_australia_last_12mo` / `ordinarily_resident` fact to the surface only when the foreign-person blueprints need it. Documented, not dangled (same treatment as the ban doc's commercial-scale exceptions).
- **`ordinarily_resident_min_days` is a parameter, not a `criteria` field.** There is no day-count fact on the Mode A surface and the comparison would be control flow; per §11.9 the 200-day test, when it becomes load-bearing (B / D), is **resolver code** consuming this number — not a declarative rule. Same pattern as the ban-window date comparison.
- **The carve-outs are not `fills`.** They would set `firb_required=false` but turn on facts absent from the Mode A surface (NZ citizenship is not a `citizenship_status` option; no spouse / joint-tenancy facts). Encoding them now would dangle unbacked references. They are recorded as a parameter for the agent to surface and wired into the predicate when the B / D surface exists.
- **No `firb_status` enum fill.** The blueprint carries both `firb_status` (enum `not_foreign_person` / `foreign_person`) and `firb_required` (bool) as two views of one classification. The bool is the resolver-consumed form (it is what the ban predicate and every downstream branch read), so only `firb_required` is filled; the enum is its presentational mirror.

## Sources

- Foreign Investment in Australia (Treasury / FIRB) — *Key concepts* (foreign person = not ordinarily resident; ordinarily-resident 200-day test; temporary residents are foreign persons) — https://foreigninvestment.gov.au/guidance/general/key-concepts
- Australian Taxation Office — *Are you a foreign person buying property in Australia?* (citizen / permanent resident / temporary resident definitions) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
- *Foreign Acquisitions and Takeovers Act 1975* (Cth) s 4, s 5 — foreign person and ordinarily-resident definitions (current framework commenced 1 December 2015) — https://www.legislation.gov.au/C1975A00092/latest/text
- Foreign Investment in Australia — *Residential land* (NZ-citizen / SCV and spouse-as-joint-tenants carve-outs) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
