---
slug: kb.lender.documentation-non-resident
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.bankwest.com.au/content/dam/bankwest/documents/legal-library/PDS_BWE-8017.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/bankwest-pds-bwe-8017.txt
    note: "Bankwest broker Application Submission Checklist (BWE-8017): \"Where an applicant is a Non-Australian Citizen a copy of their original passport and electronic visa (e-visa) must be provided.\"; \"Foreign Investment Review Board (FIRB) approval/exemption certificate for temporary Australian resident visa holders\""
  - url: https://brighten.com.au/home-loans/non-resident/
    retrieved: 2026-10-27
    path: docs/sources/lenders/brighten-non-resident-home-loan.txt
    note: "Brighten's non-resident document checklist: \"Certified copy of Passport; AND Certified copy of ID card\"; \"Personal Credit Report from the country of residence\"; \"3 months bank statements\"; employer-signed Employment Income Verification Form \"OR 2 consecutive payslips\"; \"Copy of Contract of Sale for purchase\""
  - url: https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-term-sheet.txt
    note: "La Trobe Financial term sheet, Non-Resident Loan: \"3 latest payslips translated into English by NAATI\", \"3 months bank statements\", \"Employment letter\"; \"all income documents provided to La Trobe Financial are to be translated into English by NAATI\"; \"FIRB approval is required\"; \"Copy of their credit report from their country\"; \"Evidence of funds to complete transaction held in an Australian bank in the name of applicant.\""
---

# Loan documentation for non-residents and temporary residents

This doc owns the **document pack and processing time** a foreign person or temporary resident faces when applying for an Australian mortgage — what the lender needs beyond the ordinary domestic application, and how much longer it takes. It grounds the `mortgage_finance` foreign-person variant (component 5), specifically the `pre_approval_workflow` block (`documents_required_for_non_resident`, `expected_processing_time_days`).

The **serviceability assessment** the documents feed is owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) and [`kb.lender.serviceability-basics`](serviceability-basics.md); the **AML/CTF source-of-funds** obligation that the source-of-funds evidence satisfies is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md). This doc owns only the **lending document checklist** and the timeline; it points to those for the substance behind each item.

## The document pack

A non-resident / temporary-resident application adds identity, visa, foreign-income and source-of-funds evidence on top of the ordinary pack. Each item below is stated on at least one lender's own checklist (Bankwest, Brighten, La Trobe Financial — named as the primaries, not as recommendations); the exact pack is the chosen lender's:

- **Visa grant and passport** — Bankwest: for a non-Australian citizen "a copy of their original passport and electronic visa (e-visa) must be provided"; Brighten: "Certified copy of Passport; AND Certified copy of ID card". The visa class and remaining tenure are load-bearing for the assessment ([`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md), [`kb.lender.485-visa-treatment`](485-visa-treatment.md)).
- **Employment and income evidence** — La Trobe Financial asks for "3 latest payslips", "3 months bank statements" and an "Employment letter", each translated into English by NAATI (self-employed: "2 years financials"); Brighten asks for 3 months bank statements and its employer-signed Employment Income Verification Form or "2 consecutive payslips". Overseas income is converted (La Trobe Financial counts "90% of foreign income") ([`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) owns the shading / acceptable-currency treatment).
- **Bank statements and funds to complete** — 3 months of statements at both lenders above; La Trobe Financial also requires "Evidence of funds to complete transaction held in an Australian bank in the name of applicant" (genuine savings: [`kb.lender.serviceability-basics`](serviceability-basics.md)).
- **Source-of-funds evidence** — where the deposit is a gift from an overseas parent (the common Mode-B structure), evidence of its origin. This is both a lender requirement and the bank's AML/CTF obligation; the substance is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) and the letter form by [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md).
- **Overseas credit report** — Brighten: "Personal Credit Report from the country of residence"; La Trobe Financial: "Copy of their credit report from their country".
- **FIRB approval** — La Trobe Financial: "FIRB approval is required"; Bankwest lists the "FIRB approval/exemption certificate" for temporary-resident visa holders. The No Objection Notification is provided to the lender for settlement ([`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md)).
- **Property details** — Brighten: "Copy of Contract of Sale for purchase".

## Processing time

No lender's own page publishes a processing time for a non-resident application. The plan's **~4–8 weeks** (versus **~2–4 weeks** domestic) is a `PLACEHOLDER`, to re-ground on a lender's published turnaround. What the lenders' pages do show is why it can take longer: overseas documents must be translated (La Trobe Financial: "all income documents … are to be translated into English by NAATI"), an overseas credit report obtained, and FIRB approval in hand — so the plan surfaces the pack early and flags translation needs.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The source-of-funds item is the pinch point.** A lump-sum parental gift from Vietnam must be evidenced for both the lender and AML/CTF; assembling this early is the single highest-leverage preparation step.
- **Overseas documents need lead time.** VN-issued income and bank evidence need certified English translation at the lenders that state it (La Trobe Financial: NAATI); any timeline assumes the pack is complete.
- **The FIRB reference ties the pack to the gate.** The approval letter appears here and in [`kb.lender.firb-approval-as-condition-precedent`](firb-approval-as-condition-precedent.md).

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver assembles `documents_required_for_non_resident` (marking each item's status against the profile) and sets `expected_processing_time_days` from the band below; this doc supplies the grounded checklist and timeline. No leaf asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "processing_time_days_non_resident_low": { "type": "int", "value": 28, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no lender's own page publishes a non-resident processing time; re-ground on a lender's published turnaround (La Trobe Financial or Brighten)." },
    "processing_time_days_non_resident_high": { "type": "int", "value": 56, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — upper end; same re-ground. Translation, the overseas credit report and FIRB approval (lender checklists) are what extend it." },
    "processing_time_days_domestic_reference": { "type": "int", "value": 21, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — ~2–4 weeks domestic baseline, for contrast only; re-ground on a lender's published turnaround." },
    "source_of_funds_evidence_required": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "overseas-sourced deposits (e.g. a VN parental gift) require source-of-funds evidence — a lender requirement AND the bank's AML/CTF obligation (kb.au-aml-ctf.source-of-funds-documentation)." },
    "overseas_documents_may_need_certified_translation": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "La Trobe Financial term sheet: all income documents translated into English by NAATI; Brighten asks for certified copies of passport and ID." },
    "firb_approval_letter_in_pack": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "La Trobe Financial: \"FIRB approval is required\"; Bankwest checklist: FIRB approval/exemption certificate for temporary-resident visa holders (kb.lender.firb-approval-as-condition-precedent)." }
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
- **Lender policy and placeholders.** Each checklist item is quoted from a lender's own checklist (`LENDER-POLICY`); the processing-time band has no lender primary and is `PLACEHOLDER`. Deferred to a broker; the lenders are named as primaries, not recommended.
- **The checklist references, does not duplicate.** Each item's detail lives in its owner; this doc is the *pack* layer.

## Sources

- Bankwest — *Application Submission Checklist* BWE-8017 (passport and e-visa for non-Australian citizens; FIRB approval/exemption certificate) — https://www.bankwest.com.au/content/dam/bankwest/documents/legal-library/PDS_BWE-8017.pdf
- Brighten — *Non-Resident Home Loans* (document checklist: certified passport and ID, overseas credit report, bank statements, payslips or employer form, contract of sale) — https://brighten.com.au/home-loans/non-resident/
- La Trobe Financial — *International Borrower term sheet* (NAATI-translated payslips, statements, employment letter; FIRB approval; overseas credit report; funds held in an Australian bank) — https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
