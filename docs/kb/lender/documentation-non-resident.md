---
slug: kb.lender.documentation-non-resident
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Loan documentation for non-residents and temporary residents

This doc owns the **document pack and processing time** a foreign person or temporary resident faces when applying for an Australian mortgage — what the lender needs beyond the ordinary domestic application, and how much longer it takes. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically the `pre_approval_workflow` block (`documents_required_for_non_resident`, `expected_processing_time_days`).

The **serviceability assessment** the documents feed is owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) and [`kb.lender.serviceability-basics`](serviceability-basics.md); the **AML/CTF source-of-funds** obligation that the source-of-funds evidence satisfies is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md). This doc owns only the **lending document checklist** and the timeline; it points to those for the substance behind each item.

## The document pack

A non-resident / temporary-resident application adds identity, visa, foreign-income and source-of-funds evidence on top of the ordinary pack. Typical requirements:

- **Visa grant and passport** — the visa class and remaining tenure are load-bearing for the assessment ([`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md), [`kb.lender.485-visa-treatment`](485-visa-treatment.md)).
- **Employment and income evidence** — an employer letter (position, salary, tenure) plus recent payslips and/or the last **2–3 years of tax returns**; for **overseas** income, the equivalent foreign-jurisdiction evidence, converted at a conservative rate ([`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) owns the shading / acceptable-currency treatment).
- **Bank statements** — Australian **and** international, evidencing income flow and the deposit; 3–6 months to demonstrate genuine savings ([`kb.lender.serviceability-basics`](serviceability-basics.md)).
- **Source-of-funds evidence** — where the deposit is a gift from an overseas parent (the common Mode-B structure), evidence of its origin. This is both a lender requirement and the bank's AML/CTF obligation; the substance is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) and the letter form by [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md).
- **Credit history** — Australian and, where relevant, international.
- **FIRB approval reference / letter** — the No Objection Notification, provided to the lender for settlement ([`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md)).
- **Property details** — address and purchase price / contract of sale.

## Processing time

A non-resident application typically takes **longer** than a domestic one — commonly **~4–8 weeks** versus **~2–4 weeks** — because the lender verifies overseas documents, converts foreign income, and works within the smaller non-resident lender panel ([`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)). Incomplete or untranslated overseas paperwork is the main cause of delay, so the plan surfaces the pack early and flags certified-translation needs.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The source-of-funds item is the pinch point.** A lump-sum parental gift from Vietnam must be evidenced for both the lender and AML/CTF; assembling this early is the single highest-leverage preparation step.
- **Overseas documents need lead time.** VN-issued income and bank evidence often need certified English translation; the ~4–8-week window assumes the pack is complete.
- **The FIRB reference ties the pack to the gate.** The approval letter appears here and in [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver assembles `documents_required_for_non_resident` (marking each item's status against the profile) and sets `expected_processing_time_days` from the band below; this doc supplies the grounded checklist and timeline. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "processing_time_days_non_resident_low": { "type": "int", "value": 28, "provenance": "CONVENTION", "note": "lower end (~4 weeks) for a complete non-resident application." },
    "processing_time_days_non_resident_high": { "type": "int", "value": 56, "provenance": "CONVENTION", "note": "upper end (~8 weeks); overseas-document verification and the smaller lender panel extend it." },
    "processing_time_days_domestic_reference": { "type": "int", "value": 21, "provenance": "CONVENTION", "note": "~2–4 weeks domestic baseline, for contrast only; owned in spirit by the general lender-docs timeline." },
    "source_of_funds_evidence_required": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "overseas-sourced deposits (e.g. a VN parental gift) require source-of-funds evidence — a lender requirement AND the bank's AML/CTF obligation (kb.au-aml-ctf.source-of-funds-documentation)." },
    "overseas_documents_may_need_certified_translation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "VN-issued income/bank/identity documents commonly need certified English translation; a frequent cause of delay." },
    "firb_approval_letter_in_pack": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the FIRB No Objection Notification reference/letter is part of the settlement pack (kb.lender.firb-approval-as-condition-precedent)." }
  },
  "lookup": {
    "non_resident_document_checklist": {
      "note": "the lending document pack; each item's substance is owned by the cross-referenced doc, not duplicated here.",
      "entries": [
        { "document": "visa_grant_and_passport", "owner": "kb.lender.temp-resident-lending-policies" },
        { "document": "employment_and_income_evidence", "owner": "kb.lender.temp-resident-lending-policies" },
        { "document": "bank_statements_au_and_international", "owner": "kb.lender.serviceability-basics" },
        { "document": "source_of_funds_evidence", "owner": "kb.au-aml-ctf.source-of-funds-documentation" },
        { "document": "credit_history_au_and_international", "owner": "kb.lender.serviceability-basics" },
        { "document": "firb_approval_reference", "owner": "kb.lender.firb-approval-as-condition-precedent" },
        { "document": "property_details_contract_of_sale", "owner": "kb.lender.serviceability-basics" }
      ]
    }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *document checklist + timeline*. The assessment those documents feed → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); the AML source-of-funds substance → [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md); the FIRB letter → [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).
- **Conventions.** Every figure is lender practice, flagged `CONVENTION`, presented as a band, deferred to a broker.
- **The checklist references, does not duplicate.** Each item's detail lives in its owner; this doc is the *pack* layer.

## Sources

- Wise — *Australian mortgages and home loans for non-residents* (document pack: visa, employment verification, AU + international bank statements, FIRB approval letter; process takes longer for non-residents) — https://wise.com/us/blog/getting-a-mortgage-in-australia
- Odin Mortgage — *Mortgage Documents Required In Australia For Non Residents* (visa/passport, income evidence, deposit proof, credit history AU + international) — https://www.odinmortgage.com/resources/mortgage-documents-for-non-residents/
- Home Loan Experts — *Proving Your Foreign Income When Applying For A Mortgage* (overseas income evidence, translation, conservative conversion) — https://www.homeloanexperts.com.au/non-resident-mortgages/proving-foreign-income/
