---
slug: kb.visas.au-temporary-residency-classes
effective_from: 2024-12-07
last_verified: 2026-07-06
sources:
  - url: https://www.minterellison.com/articles/delays-to-governments-new-skills-in-demand-visa
    retrieved: 2026-07-06
    note: "SECONDARY (MinterEllison) — appeared in WebSearch 2026-07-06 and CONFIRMS the load-bearing date: the Skills in Demand (subclass 482) visa replaced the Temporary Skill Shortage (TSS) visa on 7 December 2024 (up to 4 years, three streams, PR pathway via subclass 186; corroborated by Lexology)."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482
    note: "POINTER (canonical Home Affairs page; not directly re-fetched this session) — Skills in Demand (subclass 482) detail."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485
    note: "POINTER (canonical Home Affairs page; not directly re-fetched this session) — Temporary Graduate (subclass 485): streams, duration by qualification, unrestricted work rights."
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-2-key-concepts-v3.pdf
    note: "POINTER (canonical Treasury/FIRB Guidance Note 2; not re-fetched this session) — temporary-resident definition (visa permitting >12 months' continuous stay, or bridging visa with pending PR = foreign person)."
---

# AU temporary-residency visa classes and their FIRB implications

This doc grounds the **`applicant.visa_class`** fact captured at `buyer_profile` for Mode B (and Mode D) — the finer-grained visa detail beneath the binary foreign-person test. It is read by **`mortgage_finance`** (non-resident / temporary-resident lending policy keys off the specific visa) and by **`firb_workflow`** (classification nuance). It does **not** decide foreign-person status — that derivation (the residency, not nationality, test) is owned once by [`kb.firb.status-determination`](../firb/status-determination.md); this doc owns the **per-class catalogue**: what each visa is, its work rights and duration, and what it means for FIRB and for lending.

The single load-bearing rule sits above the catalogue: **a temporary resident is a foreign person.** An individual on a temporary visa permitting a continuous stay of **more than 12 months** (regardless of time remaining), or on a bridging visa with a pending permanent-visa application, is a foreign person under the *Foreign Acquisitions and Takeovers Act 1975* — caught by the [established-dwelling ban](../firb/established-dwelling-ban.md) (new-build / vacant-land only) and required to obtain FIRB approval **before** an unconditional contract. Permanent-visa holders *ordinarily resident* in Australia, and citizens, are **not** foreign persons (they route to Mode A / Mode C).

## The classes (Mode B audience)

| Visa | What it is | Status for FIRB | Lending note |
|---|---|---|---|
| **Student (subclass 500)** | Study visa; limited work rights (capped hours during study). Continuous stay typically > 12 months. | **Temporary resident → foreign person.** | Hardest to finance: study-only or capped income; most non-resident lenders want AU PAYG income. Often funded by the VN parent ([`family_context`](../../blueprints/fhb-foreign-au.md)). |
| **Temporary Graduate (subclass 485)** | Post-study work visa; **unrestricted** work rights. Duration by qualification: ~2 yrs (Bachelor / coursework Masters), up to 3 yrs (research Masters / PhD), 18 mo (post-vocational stream). | **Temporary resident → foreign person.** | The most financeable temporary class: full work rights + AU PAYG income. Several lenders treat a 485 with stable AU employment close to a resident profile (still typically 20–30%+ deposit) — detail owned by [`kb.lender.485-visa-treatment`](../lender/485-visa-treatment.md). |
| **Skills in Demand (subclass 482)** | Employer-sponsored skilled visa; **replaced the Temporary Skill Shortage (TSS) visa on 7 December 2024**. Three salary-based streams; up to 4 years; full work rights in the sponsored occupation; direct PR pathway via subclass 186 after ~2 years. | **Temporary resident → foreign person** (while on the 482). | Strong: sponsored AU employment, longer runway. Non-resident / temp-resident lending policies apply — [`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md). |
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
    "temporary_resident_is_foreign_person": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FATA 1975 — a temporary resident (visa permitting >12mo continuous stay, or bridging with pending PR) is a foreign person. The decisive binary; classification owned by kb.firb.status-determination." },
    "continuous_stay_threshold_months": { "type": "integer", "value": 12, "provenance": "REGULATED", "note": "the visa-duration limb of 'temporary resident'; the ordinarily-resident test (200 days + no time limitation) is owned by kb.firb.status-determination." }
  },
  "lookup": {
    "visa_class_treatment": {
      "keydim": ["visa_class"],
      "provenance": "FACTUAL (Dept of Home Affairs) + REGULATED (FIRB status)",
      "rows": [
        { "visa_class": "student_500",        "permanent": false, "work_rights": "limited (capped hours during study)", "firb": "foreign_person", "lending_signal": "weak (study-only / capped income)" },
        { "visa_class": "graduate_485",       "permanent": false, "work_rights": "unrestricted",                         "firb": "foreign_person", "lending_signal": "strong (full work rights + AU PAYG)" },
        { "visa_class": "skilled_482",        "permanent": false, "work_rights": "full in sponsored occupation",         "firb": "foreign_person", "lending_signal": "strong (sponsored AU employment, ~4yr runway)" },
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

- Department of Home Affairs — *Temporary Graduate visa (subclass 485)* (streams, duration by qualification, work rights) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485
- Department of Home Affairs — *Skills in Demand visa (subclass 482)* (replaced the TSS visa 7 December 2024; three streams; up to 4 years; PR pathway) — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482
- Department of Home Affairs — *Student visa (subclass 500)* — https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 2: Key Concepts* (temporary resident definition — visa permitting >12 months' continuous stay, or bridging visa with pending PR) — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-2-key-concepts-v3.pdf
- ATO — *Are you a foreign person buying property in Australia?* (temporary resident / permanent resident / foreign person) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
