---
slug: kb.au-temp-residents.banking-and-tax-basics
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/coming-to-australia-or-going-overseas/your-tax-residency/foreign-and-temporary-residents
    retrieved: 2026-07-06
    note: "PRIMARY (ATO) — residency-for-tax categories; foreign residents have no tax-free threshold and no Medicare levy. Verified via WebSearch corroboration 2026-07-06 (ATO WebFetch 403 in-sandbox) — CONFIRMED."
  - url: https://classic.austlii.edu.au/au/legis/cth/consol_act/itaa1997240/s768.900.html
    note: "POINTER (not re-fetched this session; canonical home of the fact) — ITAA 1997 Subdiv 768-R (temporary-resident foreign-income exemption, except net capital gains). Settled law; re-verify anchor for the temporary-resident row."

# Banking and tax basics for AU temporary residents

This doc grounds the **`applicant.tax`** facts captured at `buyer_profile` for Mode B — `residency_for_tax`, `marginal_rate`, `jurisdiction` — and the AU-side banking context the cross-border funding path assumes. Its one load-bearing message:

> **Tax residency is a different question from FIRB status.** A buyer can be a **foreign person** under FIRB (caught by the established-dwelling ban, needs approval) *and at the same time* an **Australian resident for tax** (e.g. a 485 graduate living and working in Australia). The two tests have different rules and different consequences; the plan must not collapse them.

`firb_required` (foreign-person status) is owned by [`kb.firb.status-determination`](../firb/status-determination.md). **Tax** residency is owned here, and it has **three** values the profile records.

## The three tax-residency categories

| `residency_for_tax` | Who | What is taxed | Key features |
|---|---|---|---|
| **`resident`** | Meets an ATO residency test (resides / domicile / 183-day / superannuation test) — common for a 485 or 482 holder living and working in AU. | Worldwide income. | Tax-free threshold + resident marginal rates ([`kb.tax.income-tax-resident-2025-26`](../tax/income-tax-resident-2025-26.md)); Medicare levy applies (unless a foreign-resident exemption). |
| **`temporary_resident_for_tax`** | Holds a temporary visa (Migration Act) **and** is not an Australian resident in the social-security sense (and spouse not). | AU-source income + AU employment income; **most foreign-source income is exempt** (ITAA 1997 **Subdiv 768-R** — foreign ordinary + statutory income, *except net capital gains*, is non-assessable non-exempt). | Taxed broadly like a resident on AU income, but VN-source income is generally not assessable in AU. **Net capital gains are not exempt** — see CGT below. |
| **`non_resident`** (foreign resident for tax) | Does not meet a residency test — typically the **Vietnam-located funding parent**, or an applicant not living in AU. | **AU-source income only.** | **No tax-free threshold** — tax on every dollar of AU income, at foreign-resident rates; **no Medicare levy** (exemption for foreign-resident days). |

**CGT applies to the AU property regardless of tax residency.** Australian real property is *taxable Australian property* (TAP), so a capital gain on the AU dwelling is assessable for residents, temporary residents (CGT is the carve-out from the 768-R exemption), and foreign residents alike. The foreign-resident specifics — **no main-residence exemption** for foreign-resident periods, **no 50% CGT discount** for foreign-resident periods (from 2012), and **foreign-resident CGT withholding** on sale — are owned by the Cluster-X non-resident-tax docs (`kb.non-resident-tax.cgt-no-ppor-exemption`, `kb.non-resident-tax.foreign-resident-cgt-withholding`) and are not re-asserted here.

## Banking basics

- **A temporary resident can open an Australian bank account** (standard 100-point identification). An AU account is a practical prerequisite for receiving the cross-border transfer and settling.
- **Get a Tax File Number (TFN).** Without one, interest and salary are withheld at the top rate; a TFN lets income be taxed at the correct rate.
- **Non-resident / temporary-resident home lending is stricter** (higher deposit, smaller lender pool, income-currency haircuts) — owned by the Cluster-L lender docs; not a banking-basics fact.
- **Receiving a large cross-border deposit triggers bank source-of-funds / AML due diligence** — owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) and `kb.au-aml-ctf.bank-due-diligence-expectations`; the buyer should expect enhanced checks on the VN-origin funds.

## Rules

Pure-reference (`fills: []`). The profile's `residency_for_tax` is a user/agent-captured enum; `marginal_rate` is resolver-computed from `taxable_income_aud` against the rate tables owned by the income-tax doc (resident) / the Cluster-X non-resident docs (foreign resident). This doc supplies the framework the resolver and agent reason over.

```jsonc
{
  "fills": [],
  "parameters": {
    "tax_residency_distinct_from_firb_status": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FIRB foreign-person status (FATA 1975) and tax residency (ITAA 1997) are separate tests — a foreign person can be an AU tax resident. The doc's reason to exist." },
    "temporary_resident_foreign_income_exempt": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ITAA 1997 Subdiv 768-R — foreign ordinary + statutory income (except net capital gains) of a temporary resident is non-assessable non-exempt." },
    "foreign_resident_no_tax_free_threshold": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a foreign resident is taxed from the first dollar of AU income at foreign-resident rates; rate table owned by the income-tax / non-resident-tax docs." },
    "foreign_resident_medicare_levy_exempt": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "no Medicare entitlement → exemption for foreign-resident days." },
    "au_real_property_is_taxable_australian_property": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "CGT on the AU dwelling applies regardless of tax residency; foreign-resident CGT specifics owned by Cluster-X non-resident-tax docs." },
    "tfn_recommended": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "without a TFN, income is withheld at the top rate." }
  },
  "lookup": {
    "tax_residency_categories": {
      "keydim": ["residency_for_tax"],
      "provenance": "REGULATED (ATO / ITAA 1997)",
      "rows": [
        { "residency_for_tax": "resident",                    "taxed_on": "worldwide income", "tax_free_threshold": true,  "medicare_levy": true,  "rate_owner": "kb.tax.income-tax-resident-2025-26" },
        { "residency_for_tax": "temporary_resident_for_tax",  "taxed_on": "AU-source + AU employment income; most foreign-source income exempt (Subdiv 768-R, except net capital gains)", "tax_free_threshold": true, "medicare_levy": true, "rate_owner": "kb.tax.income-tax-resident-2025-26" },
        { "residency_for_tax": "non_resident",                "taxed_on": "AU-source income only", "tax_free_threshold": false, "medicare_levy": false, "rate_owner": "foreign-resident rates (Cluster-X / income-tax doc)" }
      ]
    }
  }
}
```

Notes:

- **Single-owner.** FIRB status → [`kb.firb.status-determination`](../firb/status-determination.md). Resident rate table → [`kb.tax.income-tax-resident-2025-26`](../tax/income-tax-resident-2025-26.md). Foreign-resident CGT / withholding / no-PPOR-exemption → the Cluster-X `kb.non-resident-tax.*` docs (authored in Cluster X; referenced as code-span slugs until then). Lending → Cluster-L. AML source-of-funds → Cluster-X `kb.au-aml-ctf.*`. This doc owns only the **tax-residency framework + the FIRB-vs-tax distinction** and the banking-prerequisite basics.
- **`residency_for_tax` is captured, not derived here.** The ATO residency tests (resides / domicile / 183-day / superannuation) are applied by the agent/resolver to the applicant's facts; this doc grounds what each resulting category *means*, it does not run the test.
- **No financial/tax advice (ASIC line).** This is informational framework only; an individual's residency and liability are confirmed with a registered tax agent. No figure is asserted here — the rates live in their owning docs.

## Sources

- ATO — *Foreign and temporary residents* (residency-for-tax categories; temporary-resident foreign-income exemption) — https://www.ato.gov.au/individuals-and-families/coming-to-australia-or-going-overseas/your-tax-residency/foreign-and-temporary-residents
- ATO — *Foreign and temporary resident income* (Subdiv 768-R; what a temporary resident must declare) — https://www.ato.gov.au/individuals-and-families/income-deductions-offsets-and-records/income-you-must-declare/foreign-and-worldwide-income/foreign-and-temporary-resident-income
- *Income Tax Assessment Act 1997* — Subdivision 768-R (s 768-900 ff., temporary-resident foreign-income exemption) — https://classic.austlii.edu.au/au/legis/cth/consol_act/itaa1997240/s768.900.html
- ATO — *Foreign residents and the Medicare levy exemption* — https://www.ato.gov.au/individuals-and-families/medicare-and-private-health-insurance/medicare-levy/medicare-levy-exemption/foreign-residents-exemption-from-medicare-levy
- ATO — *Are you a foreign person buying property in Australia?* (foreign-person vs tax-residency framing) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
