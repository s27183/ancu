---
slug: kb.au-aml-ctf.bank-due-diligence-expectations
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# AU bank AML/CTF due-diligence expectations — inbound cross-border funds

This doc owns **what the Australian receiving bank does under AML/CTF when a large cross-border lump sum arrives** — so `cross_border_funding` (component 7) can set the expectation and pre-engagement steps: it grounds `au_aml_ctf_compliance.expected_enhanced_due_diligence` (default `true`) and `au_aml_ctf_compliance.bank_pre_engagement_completed`. It owns the **bank-side regime and what to expect**, not the **evidence the buyer assembles** (that is [`kb.au-aml-ctf.source-of-funds-documentation`](source-of-funds-documentation.md)) nor the **letter form** ([`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md)). The **VN-side outbound process** (SBV thresholds, declared purpose) is owned by the VN placeholders [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) and [`kb.vn-capital-controls.declared-purpose-categories`](../vn-capital-controls/declared-purpose-categories.md).

## The regime — who reports, and what

The **bank (or licensed money-transfer provider) is the reporting entity** under the AML/CTF Act, not the buyer and **never this platform** — the platform is never a custodian of funds (AUSTRAC constraint, principle: money movement goes through licensed partners). Two bank obligations shape the buyer's experience:

- **Customer due diligence (CDD), escalating to enhanced CDD (ECDD).** The bank must identify the customer and, in **higher-risk** situations — a large inbound international transfer, funds from a third party (an overseas parent), a first large transaction on a new account — apply **enhanced** due diligence: asking *where the money came from* and requiring evidence. A Mode-B parental gift ticks several higher-risk markers, so ECDD should be **assumed, not hoped against**.
- **Automatic transaction reporting (the bank files these, not the buyer).** The bank lodges an **International Funds Transfer Instruction (IFTI)** report for a transfer of **any value** into Australia (within 10 business days), and a **Threshold Transaction Report (TTR)** if the transaction involves **physical cash of A$10,000 or more** (or foreign-currency equivalent). These are the bank's filings; they are routine, not an accusation — but they are why the bank asks for source-of-funds substantiation up front.

## What to expect — and why pre-engagement pays

Because ECDD is near-certain on a large inbound gift, the plan's highest-leverage step is to **engage the receiving bank before the money moves** and confirm exactly what it wants to see. The failure mode is funds arriving and then being **held pending source-of-funds review** — missing a settlement date. Pre-engagement converts an unknown post-arrival delay into a known pre-arrival checklist (`bank_pre_engagement_completed`).

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Enhanced due diligence is the base case, not the exception.** A lump-sum gift from a Vietnamese parent to an AU-side child, then into a property purchase, is exactly the pattern ECDD targets — so the plan treats `expected_enhanced_due_diligence` as `true` by default and prepares the evidence early.
- **The bank's reports are not the buyer's job.** IFTI/TTR are the bank's filings; the buyer's job is the *source-of-funds evidence* the bank asks for ([`kb.au-aml-ctf.source-of-funds-documentation`](source-of-funds-documentation.md)).
- **Timing is the real risk.** A held transfer can miss settlement; pre-engaging the bank and assembling the paper trail *before* the transfer is the mitigation, coordinated in [`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md).
- **The platform never touches the money.** All transfer and holding is via the licensed bank / provider; the platform is informational.

## Rules

Pure-reference (`fills: []`). The `cross_border_funding` resolver sets `expected_enhanced_due_diligence` from `ecdd_expected_on_large_inbound_gift` and drives the `bank_pre_engagement_completed` checklist item from `pre_engage_bank_before_transfer`. The regime facts (reporting entity, ECDD, IFTI/TTR) are `REGULATED`; the practice expectations are `CONVENTION`. No leaf asserted; no figure computed here.

```jsonc
{
  "fills": [],
  "parameters": {
    "bank_is_the_reporting_entity_not_the_buyer": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the bank/licensed provider is the AML/CTF reporting entity; the buyer is not, and the platform is never a custodian of funds (AUSTRAC)." },
    "ecdd_expected_on_large_inbound_gift": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "AML/CTF Act requires enhanced customer due diligence in higher-risk situations; a large inbound cross-border third-party gift qualifies — seeds expected_enhanced_due_diligence=true." },
    "ifti_reported_by_bank_any_value": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the bank lodges an International Funds Transfer Instruction (IFTI) report for a transfer of ANY value into/out of Australia, within 10 business days." },
    "ttr_reported_by_bank_cash_over_10k_aud": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a Threshold Transaction Report (TTR) is lodged by the bank for physical cash of A$10,000 or more (or foreign-currency equivalent), within 10 business days — distinct from the IFTI (which has no threshold)." },
    "pre_engage_bank_before_transfer": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "engage the receiving bank before the money moves to confirm its source-of-funds requirements; converts a post-arrival hold risk into a pre-arrival checklist (bank_pre_engagement_completed)." },
    "held_pending_review_is_the_failure_mode": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the risk is funds arriving then held pending source-of-funds review, missing settlement; pre-engagement + early evidence is the mitigation." }
  }
}
```

Notes:

- **No `fills`; a regime + expectation doc.** It owns *what the bank does and what to expect*; the *evidence the buyer supplies* → [`kb.au-aml-ctf.source-of-funds-documentation`](source-of-funds-documentation.md); the *letter form* → [`kb.cross-border.source-of-funds-letter-template`](../cross-border/source-of-funds-letter-template.md); the *end-to-end timing* → [`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md).
- **Never a custodian.** The platform emits information only; every transfer, hold, and report is the licensed bank's / provider's — the AUSTRAC line is architectural, not a disclaimer.
- **Decision-support framing.** Exact requirements vary by bank; the authoritative source is the receiving bank's own onboarding/ECDD process, which the buyer confirms directly.

## Sources

- AUSTRAC — *International funds transfer instruction (IFTI) reports* (report a transfer of any value into/out of Australia; IFTI-E lodged by financial institutions; within 10 business days) — https://www.austrac.gov.au/business/core-guidance/reporting/money-transferred-and-overseas-international-funds-transfer-instruction-ifti-reports
- AUSTRAC — *Threshold transaction reports* (A$10,000 or more in cash or foreign-currency equivalent; within 10 business days) — https://www.austrac.gov.au/industry-and-business/obligations-and-guidance/your-amlctf-program/reporting-us/threshold-transaction-reports
- AUSTRAC — *Reporting to us* (reporting-entity obligations; core guidance) — https://www.austrac.gov.au/business/core-guidance/reporting
- ASIC Moneysmart — *International money transfers* (use licensed providers; expect identity and source checks) — https://moneysmart.gov.au/banking/international-money-transfers
