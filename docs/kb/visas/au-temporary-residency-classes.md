---
slug: kb.visas.au-temporary-residency-classes
effective_from: 2024-12-07
last_verified: 2026-10-27
sources:
  - url: https://www.legislation.gov.au/F2024L01653/asmade/2024-12-13/es/original/pdf
    retrieved: 2026-10-27
    path: docs/sources/legislation/migration-amendment-f2024l01653-es.txt
    note: "Explanatory Statement, Migration Amendment (Labour Agreement Requirements (Subclass 186, 482 and 494 Visas)) Regulations 2024: \"The SID visa replaces the TSS visa on 7 December 2024 following the commencement of the\" Migration Amendment (2024 Measures No. 1) Regulations 2024."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482/core-skills-stream
    retrieved: 2026-10-27
    path: docs/sources/homeaffairs/skills-in-demand-482-core-skills-stream.txt
    note: "Home Affairs, Skills in Demand (subclass 482) Core Skills stream: \"work in Australia for your sponsor for up to 4 years\"; \"Your employer may be able to sponsor you for permanent residence through the:\" Employer Nomination Scheme (subclass 186); \"Usually you can only work for the business that sponsored you. If your sponsor is an Australian business, you can work for that business or one of its associated entities.\""
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/changes
    retrieved: 2026-10-18
    path: docs/sources/homeaffairs/temporary-graduate-485-changes-2026-10-18.txt
    note: "Home Affairs, Temporary Graduate (subclass 485) changes: Post-Higher Education Work stream \"Bachelor degree (including honours) – up to 2 years\", \"Masters (coursework and extended) – up to 2 years\", \"Masters (research) and doctoral degree (PhD) – up to 3 years\"; Post-Vocational Education Work stream \"Applicants may continue to stay for up to 18 months.\""
  - url: https://www.legislation.gov.au/C2004A01402/2025-12-05/2025-12-05/text/original/pdf
    retrieved: 2026-10-27
    path: docs/sources/legislation/fata-1975-compilation-35.txt
    note: "Foreign Acquisitions and Takeovers Act 1975, Compilation No. 35, s4 temporary resident: (a) holds a temporary visa that \"allows the individual to remain in Australia for a continuous\" period of more than 12 months (disregarding the amount of that period remaining); or (b) is residing in Australia, has applied for a permanent visa and holds a bridging visa until it is finally determined."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485
    retrieved: 2026-10-18
    path: docs/sources/homeaffairs/temporary-graduate-485-2026-10-18.txt
    note: "Home Affairs: \"A temporary visa that allows international students to live, study and work after you have finished your studies.\""
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500
    retrieved: 2026-10-27
    path: docs/sources/homeaffairs/student-500.txt
    note: "Home Affairs, Student visa (subclass 500): \"work up to 48 hours a fortnight when your course of study or training is in session\"."
  - url: https://foreigninvestment.gov.au/guidance/general/key-concepts
    retrieved: 2026-10-10
    path: docs/sources/firb/key-concepts-2026-10-10.txt
    note: "Foreign investment in Australia, Key concepts: \"Temporary residents, foreign non-residents, and New Zealand citizens not ordinarily resident in Australia are taken to be foreign investors for the purposes of the Act.\""
---

# AU temporary-residency visa classes and their FIRB implications

This doc grounds the **`applicant.visa_class`** fact captured at `buyer_profile` for Mode B (and Mode D) — the finer-grained visa detail beneath the binary foreign-person test. It is read by **`mortgage_finance`** (non-resident / temporary-resident lending policy keys off the specific visa) and by **`firb_workflow`** (classification nuance). It does **not** decide foreign-person status — that derivation (the residency, not nationality, test) is owned once by [`kb.firb.status-determination`](../firb/status-determination.md); this doc owns the **per-class catalogue**: what each visa is, its work rights and duration, and what it means for FIRB and for lending.

The single load-bearing rule sits above the catalogue: **a temporary resident is a foreign person.** An individual on a temporary visa permitting a continuous stay of **more than 12 months** (regardless of time remaining), or on a bridging visa with a pending permanent-visa application, is a foreign person under the *Foreign Acquisitions and Takeovers Act 1975* — caught by the [established-dwelling ban](../firb/established-dwelling-ban.md) (new-build / vacant-land only) and required to obtain FIRB approval **before** an unconditional contract. Permanent-visa holders *ordinarily resident* in Australia, and citizens, are **not** foreign persons (they route to Mode A / Mode C).

## The classes (Mode B audience)

| Visa | What it is | Status for FIRB | Lending note |
|---|---|---|---|
| **Student (subclass 500)** | Study visa; may "work up to 48 hours a fortnight when your course of study or training is in session" (Home Affairs). Continuous stay typically > 12 months. | **Temporary resident → foreign person.** | Hardest to finance: study-only or capped income; most non-resident lenders want AU PAYG income. Often funded by the VN parent ([`family_context`](../../blueprints/fhb-foreign-au.md)). |
| **Temporary Graduate (subclass 485)** | Post-study visa "that allows international students to live, study and work after you have finished your studies" (Home Affairs). Duration by qualification (Post-Higher Education Work stream): up to 2 yrs (Bachelor / coursework Masters), up to 3 yrs (research Masters / PhD); up to 18 months (Post-Vocational Education Work stream). | **Temporary resident → foreign person.** | The most financeable temporary class: work rights + AU PAYG income. Several lenders treat a 485 with stable AU employment close to a resident profile (still typically 20–30%+ deposit) — detail owned by [`kb.lender.485-visa-treatment`](../lender/485-visa-treatment.md). |
| **Skills in Demand (subclass 482)** | Employer-sponsored skilled visa; "The SID visa replaces the TSS visa on 7 December 2024" (Explanatory Statement, F2024L01653). Core Skills stream: work "for your sponsor for up to 4 years"; "Usually you can only work for the business that sponsored you" (or its associated entities); the employer may sponsor permanent residence through the Employer Nomination Scheme (subclass 186). | **Temporary resident → foreign person** (while on the 482). | Strong: sponsored AU employment, longer runway. Non-resident / temp-resident lending policies apply — [`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md). |
| **Partner (provisional/temporary) — subclasses 309 (offshore) / 820 (onshore)** | Provisional partner visa pending the permanent partner visa (100 / 801). Full work rights. | **Temporary resident → foreign person** — **but** where the partner is the spouse/de-facto of an Australian citizen, PR, or NZ citizen and the couple acquires **as joint tenants**, the FIRB **spouse carve-out** can remove the approval requirement (resolved upstream at [`kb.firb.status-determination`](../firb/status-determination.md)). | Financeable on AU income; the joint-tenant carve-out, when it applies, also reframes the purchase as non-foreign. |
| **Employer Nomination Scheme (subclass 186)** | **Permanent** visa. | **Not a foreign person** when *ordinarily resident* in Australia. | A 186 holder is a Mode A / Mode C buyer, **not** Mode B — included here only because applicants self-describe by visa; on grant, the plan card signals a [mode switch](../../blueprints/fhb-foreign-au.md). |

Other temporary classes (e.g. subclass 188/888 business-innovation, working-holiday, bridging) follow the same rule: **> 12-month continuous-stay visa, or bridging-with-pending-PR ⇒ temporary resident ⇒ foreign person.** When the specific class is unknown, the agent reasons from the binary (temporary vs permanent vs citizen), not from a guessed subclass.

## Why the class matters beyond the binary

Foreign-person status (the binary) decides the **FIRB gate** and the **established-dwelling ban** — both owned elsewhere. The *class* matters for the **lending** path, which is why `mortgage_finance` reads it: work rights and visa runway drive which non-resident-friendly lenders will consider the applicant, the deposit floor, and whether AU PAYG income can be assessed. A 485 graduate with full-time AU employment and a student on capped hours are both foreign persons under FIRB, yet sit at opposite ends of the lending spectrum. The lending consequences are owned by the Cluster-L lender docs; this doc supplies only the **class → status + financeability-signal** mapping.

## Rules

Pure-reference (`fills: []`) — this doc grounds the agent/resolver on the visa catalogue; it asserts no leaf. Foreign-person status is derived once by [`kb.firb.status-determination`](../firb/status-determination.md) (the >12-month / ordinarily-resident test); the per-class data below is what `mortgage_finance` and `firb_workflow` read as context.

```jsonc
{
  "fills": [],
  "parameters": {
    "temporary_resident_is_foreign_person": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FATA 1975 s4 (temporary resident: visa allowing a continuous stay of more than 12 months, or bridging with pending PR) + Key concepts: temporary residents \"are taken to be foreign investors for the purposes of the Act\". The decisive binary; classification owned by kb.firb.status-determination." },
    "continuous_stay_threshold_months": { "type": "integer", "value": 12, "provenance": "REGULATED", "note": "FATA 1975 s4 temporary resident (a): a temporary visa that \"allows the individual to remain in Australia for a continuous\" period of more than 12 months (disregarding the amount of that period remaining) — the visa-duration limb; the ordinarily-resident test (200 days + no time limitation) is owned by kb.firb.status-determination." }
  },
  "lookup": {
    "visa_class_treatment": {
      "keydim": ["visa_class"],
      "provenance": "REGULATED (Dept of Home Affairs visa pages; FATA 1975 s4 for FIRB status)",
      "rows": [
        { "visa_class": "student_500",        "permanent": false, "work_rights": "limited (48 hours a fortnight while course in session)", "firb": "foreign_person", "lending_signal": "weak (study-only / capped income)" },
        { "visa_class": "graduate_485",       "permanent": false, "work_rights": "live, study and work after studies",   "firb": "foreign_person", "lending_signal": "strong (work rights + AU PAYG)" },
        { "visa_class": "skilled_482",        "permanent": false, "work_rights": "employer-tied (sponsor or associated entity)", "firb": "foreign_person", "lending_signal": "strong (sponsored AU employment, up to 4yr runway)" },
        { "visa_class": "skilled_186",        "permanent": true,  "work_rights": "unrestricted",                         "firb": "not_foreign_if_ordinarily_resident", "lending_signal": "resident profile — routes to Mode A/C" },
        { "visa_class": "spouse_309",         "permanent": false, "work_rights": "unrestricted",                         "firb": "foreign_person_unless_joint_tenant_spouse_carveout", "lending_signal": "financeable on AU income" },
        { "visa_class": "spouse_820",         "permanent": false, "work_rights": "unrestricted",                         "firb": "foreign_person_unless_joint_tenant_spouse_carveout", "lending_signal": "financeable on AU income" },
        { "visa_class": "other_temporary",    "permanent": false, "work_rights": "varies",                              "firb": "foreign_person", "lending_signal": "case-by-case" },
        { "visa_class": "non_resident",       "permanent": false, "work_rights": "n/a (not in AU)",                     "firb": "foreign_person", "lending_signal": "non-resident lending only" },
        { "visa_class": "permanent_resident", "permanent": true,  "work_rights": "unrestricted",                         "firb": "not_foreign_if_ordinarily_resident", "lending_signal": "resident profile — Mode A/C" },
        { "visa_class": "citizen",            "permanent": true,  "work_rights": "unrestricted",                         "firb": "never_foreign", "lending_signal": "resident profile — Mode A/C" }
      ]
    }
  }
}
```

Notes:

- **Single-owner.** The foreign-person derivation (the > 12-month / ordinarily-resident test, the 200-day limb, the carve-outs) is owned by [`kb.firb.status-determination`](../firb/status-determination.md). The new-build / vacant-land prohibition is owned by [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md). The lending consequences are owned by the Cluster-L lender docs. This doc owns only the **per-class catalogue** and cross-references the rest.
- **`skilled_186` and `permanent_resident`/`citizen` are not Mode B buyers.** They appear in the enum because applicants self-describe by visa; the catalogue records that they are not foreign persons when ordinarily resident, so a Mode B card created on one of them is a mis-mode and should switch to Mode A / Mode C.
- **The spouse carve-out is conditional, not a class property.** A 309/820 partner is a foreign person *unless* the joint-tenant-spouse-of-citizen/PR/NZ-citizen carve-out applies — that condition is evaluated upstream at status-determination, not asserted here as a flat class fact.
- **`firb` and `lending_signal` are context strings, not verdicts.** The resolver does not read a verdict from this lookup; the agent and the lender/FIRB resolvers use it as grounding. No regulated figure is asserted here (the ASIC/credit line: visa class is informational context for lender fit, never a lender recommendation).

## Sources

- Department of Home Affairs — *Temporary Graduate visa (subclass 485)* (live, study and work after finishing studies) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485 (archived: `docs/sources/homeaffairs/temporary-graduate-485-2026-10-18.txt`)
- Department of Home Affairs — *Temporary Graduate visa (subclass 485) — changes* (stream renames; stay by qualification: up to 2 / 3 years, up to 18 months) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/changes (archived: `docs/sources/homeaffairs/temporary-graduate-485-changes-2026-10-18.txt`)
- Department of Home Affairs — *Skills in Demand visa (subclass 482) — Core Skills stream* (up to 4 years for the sponsor; usually only for the sponsoring business or its associated entities; PR through subclass 186) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482/core-skills-stream (archived: `docs/sources/homeaffairs/skills-in-demand-482-core-skills-stream.txt`)
- Explanatory Statement, F2024L01653 — *Migration Amendment (Labour Agreement Requirements (Subclass 186, 482 and 494 Visas)) Regulations 2024* (the SID visa replaces the TSS visa on 7 December 2024) — https://www.legislation.gov.au/F2024L01653/asmade/2024-12-13/es/original/pdf (archived: `docs/sources/legislation/migration-amendment-f2024l01653-es.txt`)
- Department of Home Affairs — *Student visa (subclass 500)* (work up to 48 hours a fortnight while the course is in session) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500 (archived: `docs/sources/homeaffairs/student-500.txt`)
- *Foreign Acquisitions and Takeovers Act 1975* (Cth), Compilation No. 35 — s4 temporary resident (visa allowing a continuous stay of more than 12 months, or bridging visa with a pending permanent visa) — https://www.legislation.gov.au/C2004A01402/2025-12-05/2025-12-05/text/original/pdf (archived: `docs/sources/legislation/fata-1975-compilation-35.txt`)
- Foreign Investment in Australia — *Key concepts* (temporary residents are taken to be foreign investors) — https://foreigninvestment.gov.au/guidance/general/key-concepts (archived: `docs/sources/firb/key-concepts-2026-10-10.txt`)
- ATO — *Are you a foreign person buying property in Australia?* (temporary resident / permanent resident / foreign person) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
