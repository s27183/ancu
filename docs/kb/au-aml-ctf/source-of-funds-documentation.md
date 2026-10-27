---
slug: kb.au-aml-ctf.source-of-funds-documentation
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.austrac.gov.au/industry-and-business/obligations-and-guidance/your-amlctf-program/customer-due-diligence/enhanced-customer-due-diligence
    retrieved: 2026-10-27
    path: docs/sources/austrac/enhanced-customer-due-diligence.txt
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
---

# Source-of-funds documentation — evidencing an overseas-sourced deposit

This doc owns the **evidence a foreign person assembles to establish the legitimate origin of the deposit** — the substance the bank's enhanced due diligence and the lender both ask for. It grounds `cross_border_funding` (component 7) `au_aml_ctf_compliance.supporting_documents` and `source_of_funds_letter_prepared`, and it is the **owner** that [`kb.firb.documents-required`](../firb/documents-required.md) and [`kb.lender.documentation-non-resident`](../lender/documentation-non-resident.md) cross-reference for the "source-of-funds" item. It owns the **document standards**; the **letter itself** (its form and required clauses) is owned by [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md), and **what the bank does with the evidence** by [`kb.au-aml-ctf.bank-due-diligence-expectations`](bank-due-diligence-expectations.md).

## What "source of funds" means — a traced paper trail

The requirement is to show, document-by-document, **where the money came from** — not just that the buyer holds it. For the common Mode-B structure (a lump-sum gift from a Vietnamese parent), the trail has two legs:

1. **The parent's origin of funds** — how the *parent* accumulated the money: proceeds from selling a Vietnamese property (sale contract + title), long-term savings (bank statements over time), salary/business income (tax records, employment evidence), or an inheritance. This is the leg most often under-evidenced.
2. **The transfer to the buyer** — bank records showing the money moving from the parent to the buyer and into the deposit, corroborating the gift letter.

The distinction from the two *other* document gates is load-bearing: this is **neither** the FIRB application ([`kb.firb.documents-required`](../firb/documents-required.md), which does **not** ask for source of funds) **nor** merely the lender's pack — it is the **AML/CTF** obligation the bank (and, in parallel, the lender) must satisfy.

## The two disciplines that decide the outcome

- **When AUSTRAC requires it.** A bank "must establish the customer's source of funds and source of wealth on reasonable grounds as part of initial CDD, if it's relevant to the nature of their high ML/TF risk" (AUSTRAC, enhanced customer due diligence). A large inbound transfer from overseas for a property purchase is the kind of case a bank may treat as higher risk; how it treats it is its own call ([`kb.au-aml-ctf.bank-due-diligence-expectations`](bank-due-diligence-expectations.md)).
- **Document the source early.** Assembling the paper trail before the transfer is common-sense preparation, not a published rule; no bank publishes how it handles un-evidenced funds.
- **Gift, not loan — the lender asks which.** For a gift, Macquarie requires "written confirmation … from the donor of the funds confirming the amount and that funds are not repayable"; for a family loan, confirmation of "the amount, any conditions and repayment terms" (Macquarie credit guidelines v15.0). The gift letter ([`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md)) states which it is; the supporting evidence must not contradict it.

Lenders ask for foreign documents in English: Macquarie requires income documents "in English or translated into English with appropriate translation certificate from a registered licensed translation service domiciled in Australia".

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The parent's origin-of-funds leg is the pinch point.** Buyers reliably produce the transfer records but under-evidence *how the parent accumulated the money* — the exact leg ECDD probes.
- **One evidence set serves several gates.** The same pack satisfies the bank's AML/CTF check, the lender's source-of-funds requirement, and the settlement paper trail; assemble it once, early.
- **Translation lead time is real.** Budget for certified translation of VN-side documents inside the transfer buffer.
- **Decision-support, not legal advice.** The plan lists the evidence categories and the gift-vs-loan line; the buyer confirms exact requirements with the receiving bank and, where needed, a registered professional.

## Rules

Pure-reference (`fills: []`). The `cross_border_funding` resolver builds `supporting_documents` by marking each category's status against the profile, and sets `source_of_funds_letter_prepared` from the letter track. The *requirement to evidence source of funds* is `REGULATED` where the bank rates the customer high-risk (AUSTRAC ECDD); the *specific document categories* are `CONVENTION` (bank/lender practice). No leaf asserted; no figure here.

```jsonc
{
  "fills": [],
  "parameters": {
    "source_of_funds_evidence_required": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "AUSTRAC ECDD: a reporting entity must establish source of funds and source of wealth on reasonable grounds where relevant to the customer’s high ML/TF risk (kb.au-aml-ctf.bank-due-diligence-expectations); lenders ask for evidence of the deposit in parallel." },
    "trace_the_parents_origin_of_funds": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the highest-risk leg is HOW the parent accumulated the money (property sale / savings / income / inheritance), not just the transfer — the most under-evidenced part." },
    "document_before_funds_land": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — no primary states this; re-ground on a lender’s or bank’s own gifted-deposit or international-transfer policy page." },
    "must_be_genuine_non_repayable_gift": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — Macquarie credit guidelines v15.0: a gift needs the donor’s written confirmation that the funds are not repayable; a family loan needs the lender’s confirmation of amount, conditions and repayment terms. How a family loan changes serviceability is each lender’s own assessment." },
    "vn_documents_may_need_certified_translation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "LENDER-POLICY — Macquarie credit guidelines v15.0: income documents in English or translated with a translation certificate from a registered licensed translation service domiciled in Australia." }
  },
  "lookup": {
    "source_of_funds_evidence_categories": {
      "note": "the evidence set that establishes origin; each item's status is marked against the profile at runtime. Categories, not a fixed list — the receiving bank sets exact requirements.",
      "entries": [
        { "category": "parent_property_sale_proceeds", "leg": "parents_origin", "note": "VN property sale contract + title; the common origin" },
        { "category": "parent_long_term_savings", "leg": "parents_origin", "note": "dated bank statements showing accumulation over time" },
        { "category": "parent_income_evidence", "leg": "parents_origin", "note": "salary/business income + VN tax records" },
        { "category": "parent_inheritance_or_other", "leg": "parents_origin", "note": "documented where applicable" },
        { "category": "transfer_records_parent_to_buyer", "leg": "transfer", "note": "bank records of the money moving to the buyer / deposit" },
        { "category": "gift_letter_or_statutory_declaration", "leg": "attestation", "owner": "kb.cross-border.source-of-funds-letter-template" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; a document-standards doc.** It owns the *evidence categories + the two disciplines* (document-before-landing, gift-not-loan). The *letter form* → [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md); the *bank's handling* → [`kb.au-aml-ctf.bank-due-diligence-expectations`](bank-due-diligence-expectations.md).
- **Owner for the shared "source-of-funds" item.** [`kb.firb.documents-required`](../firb/documents-required.md) and [`kb.lender.documentation-non-resident`](../lender/documentation-non-resident.md) both point here rather than restating — single-owner.
- **Not a FIRB field.** Source of funds is an AML/CTF obligation, explicitly **not** part of the FIRB application; the plan tracks the gates separately.

## Sources

- AUSTRAC — *Enhanced customer due diligence* (source of funds and source of wealth established where relevant to a customer's high ML/TF risk) — https://www.austrac.gov.au/industry-and-business/obligations-and-guidance/your-amlctf-program/customer-due-diligence/enhanced-customer-due-diligence
- Macquarie Bank — *Residential Home Loans Credit Guidelines* v15.0 (gifts and related-party loans; English translation of income documents) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
