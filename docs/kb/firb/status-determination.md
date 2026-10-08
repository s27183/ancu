---
slug: kb.firb.status-determination
effective_from: 2015-12-01
last_verified: 2026-10-07
sources:
  - url: https://foreigninvestment.gov.au/guidance/general/key-concepts
    retrieved: 2026-10-07
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-2-key-concepts-v5.pdf
    retrieved: 2026-10-07
  - url: https://www.legislation.gov.au/F2015L01854/latest/text
    retrieved: 2026-10-07
---

# Determining FIRB status — does the buyer need foreign-investment approval?

**FIRB status** is the single fact every flow branches on (constraint #10): whether a buyer's acquisition of residential land **requires foreign-investment approval** under the *Foreign Acquisitions and Takeovers Act 1975* (FATA). The classification decides which mode applies — a buyer who needs no approval (Mode A / C / E) is unaffected by the foreign-investment framework, while a buyer who does (Mode B / D) must obtain approval **before** signing an unconditional contract and is caught by the [established-dwelling ban](established-dwelling-ban.md). This doc owns the *classification* (who needs approval); the ban doc owns the *prohibition* (what such a buyer may then buy).

Two questions combine here, and they are kept apart:

1. **Is the buyer a foreign person?** The test is **residency, not nationality**: a foreign person is a natural person who is **not ordinarily resident in Australia** (FATA s 4).
2. **Does an exemption take the acquisition outside the approval provisions anyway?** For an **Australian citizen**, yes: *Foreign Acquisitions and Takeovers Regulation 2015* (FATR) **reg 35(1)(a)** provides that the excluded provisions — the significant-action and notifiable-action provisions that require approval — "do not apply in relation to an acquisition of an interest in Australian land by … **an Australian citizen not ordinarily resident in Australia**".

So an Australian citizen needs no approval to buy Australian land **wherever they live**: if ordinarily resident they are not a foreign person at all; if not ordinarily resident they may be a foreign person, but reg 35(1)(a) exempts their land acquisition. A permanent resident has **no** such exemption — PR status protects only while they remain ordinarily resident.

## The ordinarily-resident test

A non-citizen is **ordinarily resident in Australia** at a given time only if **both** hold:

1. they have been **physically in Australia for 200 or more days** of the preceding 12-month period; **and**
2. their continued presence is **not subject to any limitation as to time** imposed by law (i.e. not restricted by a visa's time limit) — or, if they are overseas at that time, it was not so limited immediately before they last left.

The second limb is what separates permanent from temporary residents; the first is what catches a permanent resident who lives abroad.

- **Australian citizen** — **no approval needed, regardless of where they live.** Ordinarily resident → not a foreign person. Not ordinarily resident (e.g. settled in Vietnam) → possibly a foreign person under FATA s 4 (FIRB: a citizen living overseas "may be a foreign person"; there is no specific statutory rule for when a citizen is ordinarily resident), but the land acquisition is exempt under **FATR reg 35(1)(a)**. Either way `applicant.firb_required` is **false**, and that value is exact for citizens, not an approximation.
- **Permanent resident** (permanent-entry visa) — not subject to a time limitation, so if ordinarily resident (200-day limb) they are **not** a foreign person and need no approval. A PR who is **not** ordinarily resident (e.g. living in Vietnam, fewer than 200 days in Australia in the past year) **is** a foreign person: they need approval and are caught by the [established-dwelling ban](established-dwelling-ban.md) (new dwellings / vacant land only). reg 35(1)(a) covers citizens only.
- **Temporary resident** (a temporary visa permitting a continuous stay of more than 12 months, or a bridging visa with a pending permanent-visa application) — their presence **is** time-limited, so they fail the second limb and **are foreign persons** even if physically present 200+ days. This is the counter-intuitive result that catches many AU-based temporary-visa holders (Mode B).
- **Non-resident** (living overseas, no Australian visa entitlement) — a foreign person.

> A foreign-owned **company or trust** is also a foreign person (broadly ≥20% single or ≥40% aggregate foreign interest), but that is out of scope for the individual-buyer modes this blueprint covers. (reg 35(1)(b)–(c) extend the citizen exemption to Australian corporations and resident trusts that are foreign only through non-resident citizens; not modelled.)

## Status-level carve-outs (Modes B / D)

Two carve-outs change a buyer from *requiring approval* to *not requiring approval* — they resolve **here**, upstream of the ban, by setting the carved-out applicant's `applicant.firb_required = false`, which propagates to the aggregate `profile.firb_required_any` that the [established-dwelling ban](established-dwelling-ban.md)'s purchase predicate reads:

- **New Zealand citizens / Special Category Visa (subclass 444) holders** — do not require foreign-investment approval for residential land.
- **Spouse of an Australian citizen, permanent resident, or NZ citizen** — where the couple acquires the property **as joint tenants**, the foreign spouse is carved out of foreign-person treatment for that acquisition (FATR reg 38(3) for residential land).

Both turn on facts not yet on the Mode A profile surface (there is no NZ-citizen option in `citizenship_status`, and no `spouse_is_citizen_pr` / `buying_as_joint_tenants` fact). They are **documented here and agent-surfaced**; their backing facts are added to the surface when the Mode B / D blueprints are built (Wedge 2+). For Mode A they never bind — see Notes.

## Relevance for Vietnamese-Australian buyers

- **Citizen, in Australia or in Vietnam: no approval.** `applicant.firb_required` resolves to **false** (and so the aggregate `profile.firb_required_any`); do not surface FIRB as a constraint — it only confuses. A dual Vietnamese-Australian citizen settled in Vietnam for years is covered by reg 35(1)(a) and needs no approval to buy Australian land. (Living overseas can still change their **tax** position — non-resident for tax, no CGT main-residence exemption, possible state surcharges — which `tax_residency` carries, separately from FIRB.)
- **PR ordinarily resident in Australia (Mode A / C / E): no approval.** The settled-PR diaspora case.
- **PR living in Vietnam: approval required, established dwellings barred.** A permanent resident who has spent fewer than 200 days in Australia in the past year is not ordinarily resident and is a foreign person despite holding PR. Onboarding asks only "citizen or PR?" — not where the buyer lives — so a domestic plan whose household may include a PR **states that it assumes the PR lives in Australia** (`buyer_profile.key_assumptions`, copy `assume_pr_ordinarily_resident` in [`kb.copy.profile`](../copy/profile.md)), naming the consequence if they do not.
- **Mode B (Vietnam-parent funding an AU child; AU temporary resident): the child on a student / graduate / skilled *temporary* visa IS a foreign person**, even living in Australia full-time — the time-limited visa fails the ordinarily-resident test. They need approval and are caught by the established-dwelling ban (new-build / vacant-land only) unless the spouse-joint-tenant carve-out applies.
- **Mode D (Vietnam-located investor): a foreign person** (non-resident). Approval required; new-build / vacant-land only.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This doc is the **single owner** of the `applicant.firb_required` derivation — per-applicant (mapped over `profile.applicants`), with the application-scoped aggregate `profile.firb_required_any` published by `buyer_profile` (constraint #10 — the gate lives in the architecture, not in a disclaimer). The classification rule fills the derived bool; the 200-day test and the carve-outs are parameters/agent-surfaced (see Notes).

```jsonc
{
  "fills": [
    // firb_required = the buyer's acquisition REQUIRES foreign-investment approval. TRUE iff a
    // temporary or non-resident. Citizen → false wherever they live (not a foreign person, or
    // exempt under FATR reg 35(1)(a)). Permanent resident → false on the assumption they are
    // ordinarily resident; a PR living abroad needs approval — not decidable from
    // citizenship_status alone, so buyer_profile states the assumption (key_assumptions).
    // This is the derivation behind firb_status's `derived_from: citizenship_status` in buyer_profile.
    // The NZ / spouse carve-outs are NOT in this predicate (no backing facts on the Mode A surface) — see Notes.
    { "leaf": "applicant.firb_required",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "applicant.citizenship_status", "op": "in", "value": ["temporary_resident", "non_resident"] } ] } }
  ],
  "parameters": {
    "ordinarily_resident_min_days":   { "type": "integer", "value": 200, "note": "physically in Australia ≥200 of the preceding 365 days — limb 1 of the ordinarily-resident test; the limb a PR living abroad fails" },
    "ordinarily_resident_requires_no_time_limit": { "type": "bool", "value": true, "note": "limb 2 — continued presence not subject to a visa time limit; the limb temporary residents fail" },
    "approval_required_citizenship_statuses": { "type": "array<string>", "value": ["temporary_resident", "non_resident"], "note": "the citizenship_status values that resolve firb_required=true" },
    "no_approval_citizenship_statuses": { "type": "array<string>", "value": ["citizen", "permanent_resident"], "note": "citizen: exact wherever they live (FATR reg 35(1)(a) exempts a citizen not ordinarily resident); permanent_resident: assumes ordinarily resident — stated to the buyer as a key_assumption" },
    "citizen_land_exemption": { "type": "string", "value": "FATR 2015 reg 35(1)(a) — the excluded provisions do not apply to an acquisition of an interest in Australian land by an Australian citizen not ordinarily resident in Australia", "note": "why citizen → false is exact, not an approximation" },
    "status_level_carveouts": { "type": "array<string>", "value": [
      "New Zealand citizen / Special Category Visa (subclass 444) holder — no foreign-investment approval required",
      "Spouse of an Australian citizen, PR, or NZ citizen acquiring the property as joint tenants"
    ], "note": "resolve to firb_required=false upstream of the ban; agent-surfaced for Mode A — no backing facts on the surface yet (Wedge 2+)" }
  }
}
```

Notes:

- **`firb_required` is filled here, not in `buyer_profile` logic.** `buyer_profile` collects the raw `citizenship_status` fact; this doc supplies the *rule* that derives `firb_required` from it (the blueprint marks `firb_status` as `derived_from: citizenship_status`). Giving the regulated classification exactly one home is the same single-owner discipline as the ban window living once in [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md).
- **`firb_required` means "requires approval", not "is a foreign person".** The two differ for exactly one buyer this blueprint meets: a citizen not ordinarily resident, who may be a foreign person under FATA s 4 yet needs no approval (FATR reg 35(1)(a)). Every downstream reader — the compliance gate, the ban predicate, mode routing — branches on whether approval is needed, so that is what the leaf carries. The blueprint's `firb_status` enum (`not_foreign_person` / `foreign_person`) is its presentational mirror and shares this reading.
- **Permanent resident → false rests on an assumption the plan states.** The strict test requires *ordinarily resident* (the 200-day limb) for a PR. Onboarding asks only "citizen or PR?" and nothing asks where the buyer lives, so the predicate cannot see a PR living abroad. Rather than ask a residence question and route that buyer into a not-yet-launched foreign mode, `buyer_profile` states the assumption whenever the household may include a PR: the plan assumes they live in Australia; a PR living abroad is a foreign person who needs approval and cannot buy an established dwelling. Promote a `days_in_australia_last_12mo` / `ordinarily_resident` fact to the surface when the foreign-person blueprints need it. (Corrected 2026-10-07: the previous version treated citizen → false as an approximation of the same kind as the PR case; FATR reg 35(1)(a) makes it exact.)
- **`ordinarily_resident_min_days` is a parameter, not a `criteria` field.** There is no day-count fact on the Mode A surface and the comparison would be control flow; per §11.9 the 200-day test, when it becomes load-bearing (B / D), is **resolver code** consuming this number — not a declarative rule. Same pattern as the ban-window date comparison.
- **The carve-outs are not `fills`.** They would set `firb_required=false` but turn on facts absent from the Mode A surface (NZ citizenship is not a `citizenship_status` option; no spouse / joint-tenancy facts). Encoding them now would dangle unbacked references. They are recorded as a parameter for the agent to surface and wired into the predicate when the B / D surface exists.
- **No `firb_status` enum fill.** The blueprint carries both `firb_status` (enum `not_foreign_person` / `foreign_person`) and `firb_required` (bool) as two views of one classification. The bool is the resolver-consumed form (it is what the ban predicate and every downstream branch read), so only `firb_required` is filled; the enum is its presentational mirror.

## Sources

- *Foreign Acquisitions and Takeovers Regulation 2015* (Cth) reg 35(1)(a) — "Acquisitions by persons with a close connection to Australia": the excluded provisions do not apply to an acquisition of an interest in Australian land by an Australian citizen not ordinarily resident in Australia (compilation No. 20, 1 November 2025; read 2026-10-07); reg 38(3) — spouse joint-tenant exemption for residential land — https://www.legislation.gov.au/F2015L01854/latest/text
- Foreign Investment in Australia (Treasury / FIRB) — *Guidance Note 2: Key concepts*, v5 (12 December 2025) — section 35 exemption for land acquisitions by Australian citizens not ordinarily resident — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-12/guidance-note-2-key-concepts-v5.pdf
- Foreign Investment in Australia (Treasury / FIRB) — *Key concepts* (foreign person = not ordinarily resident; 200-day ordinarily-resident test; temporary residents are foreign persons; "an Australian citizen who is living overseas may be a foreign person") — https://foreigninvestment.gov.au/guidance/general/key-concepts
- Australian Taxation Office — *Are you a foreign person buying property in Australia?* (citizen / permanent resident / temporary resident definitions) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
- *Foreign Acquisitions and Takeovers Act 1975* (Cth) s 4, s 5 — foreign person and ordinarily-resident definitions (current framework commenced 1 December 2015) — https://www.legislation.gov.au/C1975A00092/latest/text
- Foreign Investment in Australia — *Residential land* (NZ-citizen / SCV and spouse-as-joint-tenants carve-outs) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
