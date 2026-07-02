---
slug: kb.au-aml-ctf.source-of-funds-documentation
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Source-of-funds documentation — evidencing an overseas-sourced deposit

This doc owns the **evidence a foreign person assembles to establish the legitimate origin of the deposit** — the substance the bank's enhanced due diligence and the lender both ask for. It grounds `cross_border_funding` (component 7) `au_aml_ctf_compliance.supporting_documents` and `source_of_funds_letter_prepared`, and it is the **owner** that [`kb.firb.documents-required`](../firb/documents-required.md) and [`kb.lender.documentation-non-resident`](../lender/documentation-non-resident.md) cross-reference for the "source-of-funds" item. It owns the **document standards**; the **letter itself** (its form and required clauses) is owned by [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md), and **what the bank does with the evidence** by [`kb.au-aml-ctf.bank-due-diligence-expectations`](bank-due-diligence-expectations.md).

## What "source of funds" means — a traced paper trail

The requirement is to show, document-by-document, **where the money came from** — not just that the buyer holds it. For the common Mode-B structure (a lump-sum gift from a Vietnamese parent), the trail has two legs:

1. **The parent's origin of funds** — how the *parent* accumulated the money: proceeds from selling a Vietnamese property (sale contract + title), long-term savings (bank statements over time), salary/business income (tax records, employment evidence), or an inheritance. This is the leg most often under-evidenced.
2. **The transfer to the buyer** — bank records showing the money moving from the parent to the buyer and into the deposit, corroborating the gift letter.

The distinction from the two *other* document gates is load-bearing: this is **neither** the FIRB application ([`kb.firb.documents-required`](../firb/documents-required.md), which does **not** ask for source of funds) **nor** merely the lender's pack — it is the **AML/CTF** obligation the bank (and, in parallel, the lender) must satisfy.

## The two disciplines that decide the outcome

- **Document the source *before* the money lands.** A contemporaneous paper trail assembled *before* transfer is worth far more than a reconstruction afterward; funds arriving un-evidenced are what get held ([`kb.au-aml-ctf.bank-due-diligence-expectations`](bank-due-diligence-expectations.md)).
- **Gift, not loan.** The deposit must be a **genuine, non-repayable gift**. A repayable family loan — even interest-free — is assessed by the lender as a **borrowed deposit**, changing serviceability and often the decision. The gift letter ([`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md)) states this explicitly; the supporting evidence must not contradict it.

Vietnam-issued documents (sale contracts, titles, bank statements, tax records) commonly need **certified English translation** — a frequent, avoidable cause of delay.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The parent's origin-of-funds leg is the pinch point.** Buyers reliably produce the transfer records but under-evidence *how the parent accumulated the money* — the exact leg ECDD probes.
- **One evidence set serves several gates.** The same pack satisfies the bank's AML/CTF check, the lender's source-of-funds requirement, and the settlement paper trail; assemble it once, early.
- **Translation lead time is real.** Budget for certified translation of VN-side documents inside the transfer buffer.
- **Decision-support, not legal advice.** The plan lists the evidence categories and the gift-vs-loan line; the buyer confirms exact requirements with the receiving bank and, where needed, a registered professional.

## Rules

Pure-reference (`fills: []`). The `cross_border_funding` resolver builds `supporting_documents` by marking each category's status against the profile, and sets `source_of_funds_letter_prepared` from the letter track. The *requirement to evidence source of funds* is `REGULATED` (flows from AML/CTF ECDD); the *specific document categories* are `CONVENTION` (bank/lender practice). No leaf asserted; no figure here.

```jsonc
{
  "fills": [],
  "parameters": {
    "source_of_funds_evidence_required": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "establishing the legitimate origin of the deposit is required under the bank's AML/CTF ECDD (kb.au-aml-ctf.bank-due-diligence-expectations); a lender requirement in parallel." },
    "trace_the_parents_origin_of_funds": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the highest-risk leg is HOW the parent accumulated the money (property sale / savings / income / inheritance), not just the transfer — the most under-evidenced part." },
    "document_before_funds_land": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "assemble a contemporaneous paper trail before transfer; funds arriving un-evidenced are what get held pending review." },
    "must_be_genuine_non_repayable_gift": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a repayable family loan (even interest-free) is assessed as a borrowed deposit, changing serviceability; the evidence must be consistent with a genuine gift." },
    "vn_documents_may_need_certified_translation": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "VN-issued sale contracts, titles, bank/tax records commonly need certified English translation; a frequent cause of delay." }
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

- AUSTRAC — *Customer due diligence* / core guidance (identify the customer and, in higher-risk cases, establish source of funds and wealth) — https://www.austrac.gov.au/business/core-guidance/customer-identification-and-verification
- Home Loan Experts — *Gift Letter Template / gifted deposit* (banks confirm the source of a deposit; overseas gifts need the source documented before the money lands, with a paper trail) — https://www.homeloanexperts.com.au/home-loan-documents/gift-letter-template/
- Home Loan Experts — *Proving Your Foreign Income When Applying For A Mortgage* (overseas evidence, certified translation, conservative conversion) — https://www.homeloanexperts.com.au/non-resident-mortgages/proving-foreign-income/
- Canstar — *Gifted Deposits: How They Work* (gift must be non-repayable; a repayable loan is treated as a borrowed deposit) — https://www.canstar.com.au/home-loans/gifted-deposits/
