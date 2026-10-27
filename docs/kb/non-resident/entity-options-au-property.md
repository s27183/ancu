---
slug: kb.non-resident.entity-options-au-property
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/self-managed-super-funds-smsf/setting-up-an-smsf/check-your-smsf-is-an-australian-super-fund
    retrieved: 2026-10-27
    path: docs/sources/ato/check-your-smsf-is-an-australian-super-fund.txt
    note: "ATO: \"The central management and control of the SMSF must be ordinarily in Australia.\"; it still meets this \"even if its central management and control is temporarily outside Australia for up to 2 years\"; \"The SMSF must either have no active members or active members who are Australian residents who hold at least 50% of either\" the market value of assets attributable to super interests or the amounts payable to active members."
  - url: https://foreigninvestment.gov.au/guidance/general/key-concepts
    retrieved: 2026-10-10
    path: docs/sources/firb/key-concepts-2026-10-10.txt
    note: "Foreign investment in Australia, Key concepts — foreign persons include \"a corporation, where a person not ordinarily resident in Australia, a foreign corporation or a foreign government holds a substantial interest\" and \"the trustee of a trust in which a person not ordinarily resident in Australia, a foreign corporation or a foreign government holds a substantial interest\"; \"To be ordinarily resident in Australia you must be in Australia during 200 or more days of the preceding 12-month period.\""
  - url: https://www.legislation.gov.au/C2004A01402/2025-12-05/2025-12-05/text/original/pdf
    retrieved: 2026-10-27
    path: docs/sources/legislation/fata-1975-compilation-35.txt
    note: "Foreign Acquisitions and Takeovers Act 1975 (Cth), Compilation No. 35 (5 December 2025). s4 foreign person (b)/(d): a corporation, or the trustee of a trust, in which an individual not ordinarily resident in Australia, a foreign corporation or a foreign government holds a substantial interest; (c)/(e): 2 or more such persons hold an aggregate substantial interest. s4 substantial interest: \"person holds an interest of at least 20% in the entity or\" partnership (trust: beneficial interest in at least 20% of income or property). s4 aggregate substantial interest: \"the persons hold an aggregate interest of at least\" 40% in the entity. s5(1)(a) ordinarily resident: \"actually been in Australia during 200 or\" more days in the preceding 12 months."
---

# Ownership entity — the non-resident-specific restrictions

This doc owns the **restrictions non-residency adds** on top of the base entity comparison. The comparison itself — personal, discretionary trust, unit trust, company, SMSF — is owned by [`kb.tax.entity-comparison-personal-trust-company-smsf`](../tax/entity-comparison-personal-trust-company-smsf.md) and is not duplicated here; this doc grounds the additional `tax_structure_non_resident.ownership_entity` reasoning a genuinely non-resident (Vietnam-located) investor needs that a domestic investor does not. It is read by the **agent path** (`reasoning_domain: entity_structuring`), same ASIC-line discipline as the base doc: the agent surfaces considerations, never a directive, always routed to a registered tax agent / licensed adviser.

## FIRB applies regardless of the entity — the look-through rule

Buying via a trust or company does **not** exit the foreign-investment regime. Under the *Foreign Acquisitions and Takeovers Act 1975* (s4, "foreign person"), a corporation or the trustee of a trust is itself a **foreign person** if:

- an individual not ordinarily resident in Australia, a foreign corporation or a foreign government holds a **substantial interest** — an interest of **at least 20%** in the entity (for a trust, a beneficial interest in at least 20% of its income or property); or
- two or more such persons hold an **aggregate substantial interest** — an aggregate interest of **at least 40%** in the entity (for a trust, at least 40% of its income or property).

An individual who is not an Australian citizen is *ordinarily resident* only if they have "actually been in Australia during 200 or" more days in the preceding 12 months (s5(1)(a)) — a Vietnam-located investor is not.

A Vietnam-located investor who is the beneficial owner of the entity does not escape FIRB by holding the property through an AU-registered trust or company — the entity itself becomes a "foreign person" and the same approval, fee, and established-dwelling-ban rules apply to the acquisition ([`kb.firb.status-determination`](../firb/status-determination.md), [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md)). The plan states this plainly so entity structuring is not mistaken for a FIRB-avoidance strategy.

## SMSF — generally impractical for a genuinely non-resident investor

The base entity-comparison doc lists SMSF's sole-purpose test and arm's-length restrictions as general facts; a non-resident investor faces an **additional, usually disqualifying** hurdle — **fund residency**:

- **The central management and control (CMC) test** requires the fund's high-level strategic decisions (investment strategy, performance review, benefit-payment decisions) to be **ordinarily made in Australia** — ATO: "The central management and control of the SMSF must be ordinarily in Australia." A fund whose CMC is **permanently** outside Australia fails this test; it still passes if CMC is "temporarily outside Australia for up to 2 years".
- **The active-member test** — ATO: "The SMSF must either have no active members or active members who are Australian residents who hold at least 50% of either" the market value of the fund's assets attributable to super interests or the amounts payable to active members if they left the fund.
- A person who is a **non-resident from the outset** — never having been an Australian resident directing the fund's strategy from Australia — cannot establish or maintain SMSF residency on ordinary facts: there is no Australian-based CMC to point to, and (for a single-member or family fund) the non-resident member(s) cannot satisfy the 50%-Australian-resident active-member threshold. **The practical result: an SMSF is not a realistic structure for a genuinely Vietnam-located, non-resident individual investor** — it is not that the law forbids a non-resident from being a member outright, but that a fund controlled from Vietnam will not meet the residency conditions a *complying* (concessionally taxed) super fund requires. A non-complying fund loses the concessional tax treatment that is SMSF's entire point.
- The plan surfaces this as a **structural exclusion, decision-support not a directive** — `recommended_entity` should not present `smsf` / `smsf_with_lrba` as a live option for a Vietnam-located investor without an existing Australian-resident-controlled fund, and the agent should flag the residency test rather than silently omitting SMSF from the comparison. **Resolves the wedge's open seam on SMSF exclusion.**

## Foreign/absentee entity surcharges stack on top

Where a trust does hold the property, the **foreign-beneficiary surcharge** land-tax rules already owned by [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) apply on top of the trust's ordinary land-tax position (e.g. NSW's surcharge land tax for a trust with a foreign beneficiary) — not restated here, cross-referenced.

## Relevance for Vietnam-located investors (Mode D)

- **Structuring does not bypass FIRB.** A trust or company that is majority/substantially foreign-owned is itself a foreign person; the acquisition path (approval, fee tier, established-dwelling ban) is unchanged by the entity choice.
- **SMSF is realistically off the table** for a genuinely non-resident investor without an existing Australian-controlled fund — the agent should not surface it as a live comparison option, and should say why if the investor raises it.
- **Personal or a company are the practically live options**, each carrying the base doc's ordinary trade-offs (company loses the CGT discount entirely — compounding, not replacing, the non-resident discount removal already in effect) — the agent reasons over the base comparison with these restrictions layered on.
- **Information, not advice.** Entity selection is a registered-tax-agent decision; this doc narrows what the agent should even consider, it does not choose for the investor.

## Rules

Pure-reference (`fills: []`). The `tax_structure_non_resident` agent-path leaf (`reasoning_domain: entity_structuring`) reads this doc alongside the base comparison; the structural exclusions below are hard constraints on the comparison set the agent reasons over, not agent judgment calls.

```jsonc
{
  "fills": [],
  "parameters": {
    "firb_foreign_person_substantial_interest_pct": { "type": "percentage", "value": 20, "provenance": "REGULATED", "note": "FATA 1975 s4 (Compilation No. 35): a corporation or trustee of a trust is a foreign person if an individual not ordinarily resident in Australia, a foreign corporation or a foreign government holds a substantial interest — an interest of at least 20% in the entity (trust: at least 20% of income or property)." },
    "firb_foreign_person_aggregate_interest_pct": { "type": "percentage", "value": 40, "provenance": "REGULATED", "note": "FATA 1975 s4: or if 2 or more such persons hold an aggregate substantial interest — an aggregate interest of at least 40% in the entity (trust: at least 40% of income or property)." },
    "entity_does_not_bypass_firb": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "FATA 1975 s4 foreign person (b)–(e): buying via a trust/company does not exit the foreign-investment regime — the entity itself is a foreign person under the look-through rule; the same approval/fee/ban rules apply." },
    "smsf_cmc_test_ordinarily_in_australia": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO, Check your SMSF is an Australian super fund: \"The central management and control of the SMSF must be ordinarily in Australia.\" Permanent CMC offshore fails; temporarily outside Australia for up to 2 years still meets it." },
    "smsf_active_member_test_50pct_resident": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO: \"The SMSF must either have no active members or active members who are Australian residents who hold at least 50% of either\" the assets attributable to super interests or the amounts payable to active members." },
    "smsf_generally_impractical_for_genuine_non_resident": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a fund controlled from Vietnam by a person who was never an AU resident cannot ordinarily satisfy CMC or the active-member threshold — a structural exclusion the agent should surface, not a per-case judgment; resolves the wedge's SMSF open seam." },
    "smsf_excluded_from_agent_recommended_entity_comparison": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "recommended_entity's agent-path comparison should not present smsf / smsf_with_lrba as a live option for a Vietnam-located investor absent an existing Australian-resident-controlled fund." }
  }
}
```

Notes:

- **No `fills`.** `recommended_entity` remains agent-path; this doc narrows the comparison set with hard structural exclusions (FIRB look-through, SMSF residency) rather than adding new agent judgment.
- **Single-owner via cross-ref.** The base entity comparison (rates, trade-offs) → `kb.tax.entity-comparison-personal-trust-company-smsf`; foreign/absentee land-tax surcharges → `kb.tax.land-tax-by-state`; FIRB status determination → `kb.firb.status-determination`.
- **REGULATED — verified against the Act and the ATO.** The FIRB substantial-interest thresholds (20%/40%) are read from the FATA 1975 compilation text (s4) and the SMSF CMC/active-member residency tests from the ATO's own page, both archived 2026-10-27.

## Sources

- ATO — *Check your SMSF is an Australian super fund* (central management and control ordinarily in Australia, temporarily outside up to 2 years; active-member test — no active members or AU-resident active members holding at least 50%) — https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/self-managed-super-funds-smsf/setting-up-an-smsf/check-your-smsf-is-an-australian-super-fund (archived: `docs/sources/ato/check-your-smsf-is-an-australian-super-fund.txt`)
- Foreign Investment in Australia — *Key concepts* (corporations and trustees of trusts in which a person not ordinarily resident in Australia, a foreign corporation or a foreign government holds a substantial interest are foreign persons; ordinarily resident = 200 or more days in the preceding 12 months) — https://foreigninvestment.gov.au/guidance/general/key-concepts (archived: `docs/sources/firb/key-concepts-2026-10-10.txt`)
- *Foreign Acquisitions and Takeovers Act 1975* (Cth), Compilation No. 35 (5 December 2025) — s4 foreign person, substantial interest (at least 20%), aggregate substantial interest (at least 40%); s5 ordinarily resident (200 or more days in 12 months) — https://www.legislation.gov.au/C2004A01402/2025-12-05/2025-12-05/text/original/pdf (archived: `docs/sources/legislation/fata-1975-compilation-35.txt`; current version: https://www.legislation.gov.au/C2004A01402/latest/text)
