---
slug: kb.cross-border.source-of-funds-letter-template
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Source-of-funds / gift letter — required elements (anatomy, not drafting)

This doc owns the **anatomy of the source-of-funds / gift letter** the funding parent signs — the elements it must contain for an Australian bank and lender to accept a gifted overseas deposit. It grounds `due_diligence` (component 9) `documents_required.source_of_funds_letter` and `cross_border_funding` (component 7) `au_aml_ctf_compliance.source_of_funds_letter_prepared`. It owns the **letter's required content**; the **evidence behind it** (the paper trail proving origin) is owned by [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md), and **what the bank does with it** by [`kb.au-aml-ctf.bank-due-diligence-expectations`](../au-aml-ctf/bank-due-diligence-expectations.md).

Like [`kb.foreign-buyer.subject-to-firb-clauses`](../foreign-buyer/subject-to-firb-clauses.md), this doc owns the **anatomy, not the drafting**: it lists what a compliant letter must state so the plan can surface a checklist and flag gaps — it does **not** draft the letter or provide legal wording. Many lenders and banks publish their own gift-letter or statutory-declaration templates, and a **statutory declaration** may need to be witnessed; the buyer uses the receiving institution's template and, where a declaration is required, a registered professional.

## The required elements

A letter/declaration the bank will accept typically must state, unambiguously:

- **The parties** — the full name of the **giver** (the parent) and the **recipient** (the buyer), and their **relationship**.
- **The amount and currency** — the exact gift amount (and currency, if given in VND with an AUD equivalent).
- **That it is a genuine gift** — the load-bearing clause: the funds are **unconditional, non-repayable, and non-refundable**, with **no interest and no expectation of repayment or ownership stake**. A repayable arrangement is a loan, assessed as a borrowed deposit (→ [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md)).
- **The source of the gifted funds** — a short statement of how the parent accumulated the money (e.g. proceeds of a property sale, long-term savings), consistent with the supporting evidence.
- **Signature and date** — signed and dated by the giver; **witnessed** where the institution requires a statutory declaration.

## Language and translation

The letter is read by the **Australian** bank/lender, so it is prepared in **English**; where the parent signs a Vietnamese-language version, a **certified English translation** accompanies it. The plan surfaces both the required elements and the translation need so the parent understands exactly what they are attesting (bilingual coordination — [`kb.bilingual.coordination-norms`](../bilingual/coordination-norms.md)).

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The "genuine gift" clause is decisive.** It is the single element lenders most often send back for amendment; getting it unambiguous first time avoids a re-signing round-trip across two countries.
- **Consistency with the evidence.** The stated source must match the source-of-funds paper trail; a mismatch triggers more questions, not fewer.
- **Anatomy, not drafting.** The plan lists what the letter must contain and flags what is missing; it does **not** write the letter — the buyer uses the institution's template and a registered professional for any statutory declaration.

## Rules

Pure-reference (`fills: []`). The `due_diligence` resolver marks `source_of_funds_letter` present/complete by checking the letter against the required elements below and flags gaps; `cross_border_funding` reads the same to set `source_of_funds_letter_prepared`. All `CONVENTION` (a document form / bank practice). No leaf asserted; no wording drafted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "owns_anatomy_not_drafting": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc lists required elements so the plan can checklist/flag gaps; it does not draft the letter or provide legal wording." },
    "genuine_gift_clause_is_decisive": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the unconditional/non-repayable/non-refundable clause is the element lenders most often reject; it distinguishes a gift from a borrowed deposit." },
    "prepared_in_english_translation_if_vn": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the AU bank reads English; a Vietnamese-signed version needs a certified English translation." },
    "use_institution_template_and_professional_for_stat_dec": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "many banks/lenders publish their own gift-letter/statutory-declaration templates; a statutory declaration may need witnessing — use the institution's form and a registered professional." }
  },
  "lookup": {
    "required_elements": {
      "note": "the content a compliant source-of-funds/gift letter must state; the resolver checks each against the uploaded letter and flags gaps.",
      "entries": [
        { "element": "parties_and_relationship", "required": true, "note": "giver (parent) + recipient (buyer) full names + relationship" },
        { "element": "amount_and_currency", "required": true, "note": "exact gift amount (+ AUD equivalent if given in VND)" },
        { "element": "genuine_gift_clause", "required": true, "note": "unconditional, non-repayable, non-refundable, no interest, no ownership stake" },
        { "element": "source_of_gifted_funds", "required": true, "note": "how the parent accumulated the money; consistent with the evidence (kb.au-aml-ctf.source-of-funds-documentation)" },
        { "element": "signature_and_date", "required": true, "note": "signed + dated by the giver; witnessed if a statutory declaration is required" }
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

- Home Loan Experts — *Gift Letter Template | Proof Of Your Gifted Deposit* (required content: names, amount, unconditional/non-repayable statement; lenders send back non-compliant letters) — https://www.homeloanexperts.com.au/home-loan-documents/gift-letter-template/
- Canstar — *Gifted Deposits: How They Work* (gift letter or statutory declaration confirming the money is non-repayable) — https://www.canstar.com.au/home-loans/gifted-deposits/
- Macquarie — *Gift and Loan Declaration* (institution-published declaration form; gift vs loan) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/gift_loan_declaration.pdf
