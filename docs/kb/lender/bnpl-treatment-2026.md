---
slug: kb.lender.bnpl-treatment-2026
effective_from: 2025-06-10
last_verified: 2026-07-06
sources:
  - url: https://www.asic.gov.au/regulatory-resources/credit/buy-now-pay-later-credit-contracts-credit-licensing/
    retrieved: 2026-07-06
    note: "ASIC — from 10 June 2025 anyone in credit activities involving BNPL contracts must hold an Australian Credit Licence and become an AFCA member"
  - url: https://www.asic.gov.au/about-asic/news-centre/find-a-media-release/2025-releases/25-069mr-asic-releases-new-regulatory-guidance-to-support-buy-now-pay-later-industry-reforms/
    retrieved: 2026-07-06
    note: "ASIC 25-069MR (8 May 2025) — releases Regulatory Guide 281 Low cost credit contracts"
  - url: https://download.asic.gov.au/media/2sgcg0y5/rg281-published-8-may-2025.pdf
    retrieved: 2026-07-06
    path: docs/sources/asics/rg281-published-8-may-2025.pdf
    note: "RG 281 — LCCC regime; rebuttable presumption an LCCC with a credit limit ≤$2,000 is 'not unsuitable'"
---

# Buy-now-pay-later treatment in serviceability (2026)

Buy-now-pay-later (BNPL — Afterpay, Zip, and similar) used to sit largely outside credit regulation and outside most lenders' serviceability calculations. **From 10 June 2025 that changed**: BNPL is now regulated credit, and it is now visible to and counted by mortgage lenders. This doc owns the **post-reform treatment** — what changed, and how active BNPL now affects borrowing capacity — grounding `mortgage_finance.debt_optimisation_recommendations.bnpl`. (The slug carries `2026` because the treatment is dated to this reform window and is expected to keep settling as lender policy matures.)

## The 10 June 2025 reform

The *Treasury Laws Amendment (Responsible Buy Now Pay Later and Other Measures) Act 2024* brought BNPL under the **National Consumer Credit Protection Act 2009** from **10 June 2025**, regulating BNPL contracts as a new category of **low-cost credit contract (LCCC)**. ASIC's **Regulatory Guide 281 (RG 281)** sets the guidance. The effect:

- **BNPL providers must hold an Australian Credit Licence**, join **AFCA**, and **report defaults** — so BNPL accounts and conduct now appear on **credit reports**.
- **Modified responsible-lending obligations** apply: a provider may elect into a lighter-touch regime with a **rebuttable presumption that a contract with a limit of $2,000 or less is "not unsuitable"**, reducing (not removing) the inquiries required; otherwise the standard obligations apply. **Fee caps** apply in aggregate per debtor.
- Applies to BNPL contracts entered **before, on, or after** commencement (with limited carve-outs for pre-commencement responsible-lending duties).

## What it means for a home-loan application

Because BNPL is now licensed credit and surfaces on credit files and bank statements, **mortgage lenders now factor it into serviceability and DTI** — where many previously ignored it. Treatment **varies by lender**, assessed via some combination of:

- the **committed repayment** (a regular BNPL instalment is treated like any other recurring commitment, trimming assessable surplus);
- **account conduct and bank-statement behaviour** (frequent or multiple BNPL accounts read as budget-stretching);
- **credit-enquiry pattern** (BNPL enquiries now appear and add up).

Even modest BNPL — on the order of a couple of hundred dollars a month — can reduce borrowing power by **tens of thousands of dollars**, and **multiple active BNPL services** invite extra scrutiny.

## The optimisation

Parallel to credit cards: **close or pay out BNPL accounts before applying**, and avoid opening new ones in the lead-up. This is the substance of `mortgage_finance.debt_optimisation_recommendations.bnpl.close_before_application_recommended` and `accounts_affected`. Unlike a credit-card limit (assessed even when unused), BNPL bites mainly through **active use and conduct**, so ceasing use ahead of application and letting it drop off statements is the lever.

## Relevance for Vietnamese-Australian buyers (Mode A)

- BNPL is common among younger Mode A buyers and was, until recently, an **invisible** drag — buyers often don't think of it as debt. The key message: since June 2025 it **is** debt the lender sees, so it should be wound down before applying, like credit-card limits.
- Surface it as **information**: show that active BNPL reduces capacity and that closing it ahead of application helps. The buyer decides; no direction to a specific lender or product (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The capacity impact of `profile.buy_now_pay_later_balance` and the close-before-applying recommendation are **agent-reasoned** in `mortgage_finance`, not asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "regulated_under_nccp_from":        { "type": "date", "value": "2025-06-10", "note": "REGULATED — BNPL brought under the National Consumer Credit Protection Act 2009 as a low-cost credit contract (Treasury Laws Amendment (Responsible BNPL) Act 2024)" },
    "acl_required":                     { "type": "bool", "value": true,  "note": "REGULATED — BNPL providers must hold an Australian Credit Licence and join AFCA" },
    "appears_on_credit_report":         { "type": "bool", "value": true,  "note": "consequence of regulation — BNPL accounts, conduct and defaults now report to credit files, so mortgage lenders can see them" },
    "lccc_not_unsuitable_presumption_limit": { "type": "money", "value": 2000, "note": "REGULATED (RG 281) — rebuttable presumption that an LCCC with a limit ≤$2,000 is 'not unsuitable'; lighter-touch responsible-lending, provider must elect in" },
    "counted_in_serviceability":        { "type": "bool", "value": true,  "note": "CONVENTION/lender-policy — lenders now factor active BNPL into serviceability/DTI; exact treatment varies (committed repayment, conduct, enquiries)" },
    "close_before_application_lever":   { "type": "bool", "value": true,  "note": "ceasing BNPL use ahead of application and letting it drop off statements lifts assessable surplus — the BNPL analogue of reducing a credit-card limit" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The capacity impact and the close-before-applying call are agent-reasoned in `mortgage_finance` from `profile.buy_now_pay_later_balance` (and, where available, conduct). The doc supplies the regulatory facts and the lever.
- **Regulated vs lender-policy, tagged.** The reform facts (`regulated_under_nccp_from`, `acl_required`, `lccc_not_unsuitable_presumption_limit`) are regulatory constants. **How** a mortgage lender weighs BNPL (`counted_in_serviceability`) is post-reform **lender practice that is still settling** — flagged so the agent presents it as "lenders now generally count this; treatment varies," not as a fixed rule. Same ASIC-line discipline as the sibling lender docs.
- **`2026` in the slug is intentional.** The treatment is pinned to a moving reform window (regulation commenced mid-2025; lender practice is maturing through 2026). The date in the slug flags that this doc is the most time-sensitive of the lender set and should be re-verified soonest — distinct from the stable principle docs.
- **Distinct lever from credit cards.** A credit-card *limit* is assessed even at zero balance; BNPL bites mainly through **active use and conduct**, so the optimisation is to stop using it ahead of application rather than to "reduce a limit." Documented so the agent does not conflate the two debt types.

## Sources

- Federal Register of Legislation — *Treasury Laws Amendment (Responsible Buy Now Pay Later and Other Measures) Act 2024 (C2024A00138)* (extends a modified National Credit Code to BNPL as low-cost credit contracts; royal assent 10 December 2024; the primary instrument behind the 10 June 2025 commencement) — https://www.legislation.gov.au/C2024A00138/asmade/text
- ASIC — *Regulatory Guide 281 Low cost credit contracts* (May 2025) — primary; confirms the LCCC regime, modified responsible-lending obligations, the **rebuttable presumption that an LCCC with a credit limit of $2,000 or less is 'not unsuitable'** (s128–129 NCC), and the per-debtor fee caps over a 12-month fee period (reg 69G) — https://download.asic.gov.au/media/2sgcg0y5/rg281-published-8-may-2025.pdf (primary: `docs/sources/asics/rg281-published-8-may-2025.pdf`)
- ASIC — *Buy now pay later credit contracts: Credit licensing* (BNPL regulated under the NCCP Act from 10 June 2025; ACL required; AFCA membership; default reporting) — https://www.asic.gov.au/regulatory-resources/credit/buy-now-pay-later-credit-contracts-credit-licensing/
- ASIC — *25-069MR ASIC releases new regulatory guidance to support buy now pay later industry reforms* (release of RG 281) — https://www.asic.gov.au/about-asic/news-centre/find-a-media-release/2025-releases/25-069mr-asic-releases-new-regulatory-guidance-to-support-buy-now-pay-later-industry-reforms/
