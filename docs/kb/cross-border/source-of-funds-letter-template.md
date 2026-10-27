---
slug: kb.cross-border.source-of-funds-letter-template
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/gift_loan_declaration.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-gift-loan-declaration.txt
    note: "Macquarie's own Gift and Loan Declaration form (footer 07/17): donor name and address, amount, recipient name and address, purpose, \"That the funds are a gift and not repayable\" or the repayment conditions, donor signature and date"
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
---

# Source-of-funds / gift letter — required elements (anatomy, not drafting)

This doc owns the **anatomy of the source-of-funds / gift letter** the funding parent signs — the elements it must contain for an Australian bank and lender to accept a gifted overseas deposit. It grounds `due_diligence` (component 9) `documents_required.source_of_funds_letter` and `cross_border_funding` (component 7) `au_aml_ctf_compliance.source_of_funds_letter_prepared`. It owns the **letter's required content**; the **evidence behind it** (the paper trail proving origin) is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md), and **what the bank does with it** by [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md).

Like [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md), this doc owns the **anatomy, not the drafting**: it lists what a compliant letter must state so the plan can surface a checklist and flag gaps — it does **not** draft the letter or provide legal wording. Many lenders and banks publish their own gift-letter or statutory-declaration templates, and a **statutory declaration** may need to be witnessed; the buyer uses the receiving institution's template and, where a declaration is required, a registered professional.

## The required elements

The elements below follow a lender's own published form — Macquarie's *Gift and Loan Declaration* — and Macquarie's credit guidelines, which require "written confirmation … from the donor of the funds confirming the amount and that funds are not repayable". Other lenders use their own forms; use the receiving lender's.

- **The parties** — the **donor's** name and address and the **recipient's** name and address (Macquarie's form). Stating the **relationship** is not on that form; some lenders ask for it.
- **The amount** — "am giving $ [insert amount]". The form is in AUD; a gift sent in VND is stated at the amount received.
- **Gift or loan** — the donor declares either "That the funds are a gift and not repayable" or that they are repayable, with the repayment due date, interest payable and other conditions. A repayable arrangement is a loan, and the lender assesses it as one (→ [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md)).
- **The purpose** — "to assist with the purchase of a property".
- **The source of the gifted funds** — not on Macquarie's form; the evidence of where the money came from is a separate pack ([`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md)). Some lenders ask for it in the letter.
- **Signature and date** — signed and dated by the donor. Whether the declaration must be witnessed (a statutory declaration) depends on the lender's form.

## Language and translation

The letter is read by the **Australian** bank/lender, so it is prepared in **English**; where the parent signs a Vietnamese-language version, a translation accompanies it — Macquarie, for example, requires income documents "in English or translated into English with appropriate translation certificate from a registered licensed translation service domiciled in Australia". The plan surfaces both the required elements and the translation need so the parent understands exactly what they are attesting (bilingual coordination — [`kb.bilingual.coordination-norms`](../bilingual/coordination-norms.md)).

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The gift-or-loan declaration is decisive.** It is what the lender reads to decide whether the money is the buyer's own; getting it unambiguous first time avoids a re-signing round-trip across two countries.
- **Consistency with the evidence.** The stated source must match the source-of-funds paper trail; a mismatch triggers more questions, not fewer.
- **Anatomy, not drafting.** The plan lists what the letter must contain and flags what is missing; it does **not** write the letter — the buyer uses the institution's template and a registered professional for any statutory declaration.

## Rules

Pure-reference (`fills: []`). The `due_diligence` resolver marks `source_of_funds_letter` present/complete by checking the letter against the required elements below and flags gaps; `cross_border_funding` reads the same to set `source_of_funds_letter_prepared`. `LENDER-POLICY` where a lender's own form or guideline states it (Macquarie), `PLACEHOLDER` where none does. No leaf asserted; no wording drafted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "owns_anatomy_not_drafting": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc lists required elements so the plan can checklist/flag gaps; it does not draft the letter or provide legal wording." },
    "genuine_gift_clause_is_decisive": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — Macquarie credit guidelines v15.0 require the donor to confirm the amount and that the funds are not repayable; its Gift and Loan Declaration asks the donor to declare gift or loan. That lenders most often reject this clause is a PLACEHOLDER — no lender states it." },
    "prepared_in_english_translation_if_vn": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — Macquarie credit guidelines v15.0: documents in English or translated with a certificate from a registered licensed translation service domiciled in Australia." },
    "use_institution_template_and_professional_for_stat_dec": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "many banks/lenders publish their own gift-letter/statutory-declaration templates; a statutory declaration may need witnessing — use the institution's form and a registered professional." }
  },
  "lookup": {
    "required_elements": {
      "note": "the content a compliant source-of-funds/gift letter must state; the resolver checks each against the uploaded letter and flags gaps.",
      "entries": [
        { "element": "parties_and_relationship", "required": true, "note": "donor and recipient names and addresses (Macquarie Gift and Loan Declaration); relationship: PLACEHOLDER — not on that form, re-ground on another lender's own gift-letter form" },
        { "element": "amount_and_currency", "required": true, "note": "the amount, in AUD on Macquarie's form" },
        { "element": "genuine_gift_clause", "required": true, "note": "\"That the funds are a gift and not repayable\" — or, for a loan, the repayment due date, interest and other conditions (Macquarie form)" },
        { "element": "source_of_gifted_funds", "required": true, "note": "PLACEHOLDER — not on Macquarie's form; re-ground on another lender's own gift-letter form. The evidence itself is kb.au-aml-ctf.source-of-funds-documentation" },
        { "element": "signature_and_date", "required": true, "note": "donor's signature and date (Macquarie form); witnessing only where the lender's form is a statutory declaration" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; an anatomy doc.** It owns the *required elements*; the *evidence behind the stated source* → [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md); the *bank's handling* → [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md).
- **Anatomy, not drafting** (mirrors [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md)): the plan checklists the elements and flags gaps; it does not produce the legal document.
- **Decision-support framing.** Exact wording and whether a statutory declaration is required are set by the receiving institution; the buyer uses its template and a registered professional where needed.

## Sources

- Macquarie Bank — *Gift and Loan Declaration* (the lender's own form: donor, amount, recipient, purpose, gift-or-loan declaration, signature, date) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/gift_loan_declaration.pdf
- Macquarie Bank — *Residential Home Loans Credit Guidelines* v15.0 (gifts and related-party loans; translation of documents) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
