---
slug: kb.lmi.providers
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.qbe.com/lmi
    retrieved: 2026-07-06
    path: docs/sources/qbe_lmi/qbe-lmi-guide.pdf
  - url: https://www.apra.gov.au/registers/list-general-insurance
    retrieved: 2026-10-27
    path: docs/sources/apra/register-general-insurers.txt
    note: "APRA's list of registered general insurers (updated 23 September 2026), \"Authorised to conduct new or renewal insurance business\": \"ANZ Lenders Mortgage Insurance Pty. Limited\", \"Arch Lenders Mortgage Indemnity Limited\", \"Helia Insurance Pty Limited (formerly Genworth Financial Mortgage Insurance Pty Limited)\", \"QBE Lenders' Mortgage Insurance Limited\"."
  - url: https://www.apra.gov.au/system/files/2023-07/Notice%20that%20general%20insurer%20or%20authorised%20NOHC%20has%20changed%20its%20name%20-%20Genworth%20to%20Helia.pdf
    retrieved: 2026-10-27
    path: docs/sources/apra/notice-genworth-to-helia-name-change.txt
    note: "APRA notice under s29(3) Insurance Act 1973: Genworth Financial Mortgage Insurance Pty Limited \"has changed its name to: Helia Insurance Pty Limited\" \"with effect from 15 November 2022\"."
  - url: https://investor.helia.com.au/DownloadFile.axd?file=%2FReport%2FComNews%2F20250324%2F02927792.pdf
    retrieved: 2026-10-27
    path: docs/sources/lmi/helia-asx-cba-contract-2025-03-24.txt
    note: "Helia Group ASX announcement, 24 March 2025: \"In June 2024, CBA issued a Request for Proposal (RFP) relating to its external Lenders Mortgage\" Insurance requirements; CBA \"entered into exclusive negotiations with an alternative provider\"; Helia \"anticipates that Helia's current Supply and Service contract with CBA will not be renewed beyond the current expiry on 31 December 2025.\""
  - url: https://www.helia.com.au/about-lmi
    retrieved: 2026-10-27
    path: docs/sources/lmi/helia-about-lmi.txt
    note: "Helia: \"LMI is insurance that protects credit providers, not home buyers, and cannot be provided directly to home buyers.\""
---

# LMI providers and the ways to avoid LMI

LMI is underwritten by a small number of insurers, and the borrower **does not choose** which one — the **lender** selects the insurer. What matters to the plan is therefore not "which LMI provider" but **whether LMI applies at all** and, if it does, that it is an unavoidable lender-side cost. This doc owns the **provider landscape and the routes that remove LMI** (FHG, profession waivers, 20% deposit); the premium mechanics live in [`kb.lmi.calculation`](calculation.md). It grounds `mortgage_finance`'s path comparison and lender shortlist — informationally, never as a steer to a particular insurer or lender.

## Who underwrites LMI

- **Four APRA-authorised LMI insurers write new business.** APRA's register of general insurers authorised to conduct new or renewal business lists **Helia Insurance Pty Limited** (formerly Genworth Financial Mortgage Insurance Pty Limited — renamed "with effect from 15 November 2022", per APRA's notice), **QBE Lenders' Mortgage Insurance Limited**, **Arch Lenders Mortgage Indemnity Limited**, and **ANZ Lenders Mortgage Insurance Pty. Limited**.
- **ANZ insures in-house.** ANZ Lenders Mortgage Insurance is the one bank-group LMI insurer on APRA's current list. **CommBank buys external cover:** Helia's ASX announcement of 24 March 2025 records that CBA ran a Request for Proposal for its "external Lenders Mortgage" Insurance requirements, entered "exclusive negotiations with an alternative provider", and that Helia's contract with CBA was not expected to be renewed beyond 31 December 2025. No Westpac-group LMI insurer appears on APRA's current list.
- **The lender picks the insurer.** Helia: LMI "protects credit providers, not home buyers, and cannot be provided directly to home buyers"; QBE's guide has the lender apply for cover and obtain rates. From the borrower's side LMI is a take-it-or-leave-it cost attached to the loan, not a product to shop. (Which insurer a lender uses moves with commercial deals — the CBA tender is an example; the *mechanism* doesn't move.)

## The routes that remove LMI

For a Mode A FHB the live question is **which no-LMI route applies**, in rough order of relevance:

1. **First Home Guarantee (FHG).** The government guarantee **stands in for LMI** — an eligible buyer borrows at 95% LVR (5% deposit) with **no LMI**. This is the primary route for Mode A and the reason the [FHG](../scheme/fhg.md) path usually beats the LMI-payable path. The avoided premium is `eligibility.fhg.lmi_savings_estimate`.
2. **Profession-based LMI waiver.** Some lenders waive LMI for **eligible professions**, with lender-specific profession lists, LVR ceilings and income floors. **No primary for this is cited in this doc yet** — the lenders' own waiver pages are not on this doc's primary-host list — so the route is a `PLACEHOLDER`: surface that such waivers exist at some lenders and tell the buyer to confirm with the lender; state no LVR ceiling, income floor or dollar saving.
3. **A 20%+ deposit.** At ≤80% LVR LMI simply does not apply (see [`kb.lmi.calculation`](calculation.md)).

## Relevance for Vietnamese-Australian buyers (Mode A)

- Many Mode A buyers are **salaried professionals** — so a **profession waiver** may be live alongside FHG, and the two should be compared: FHG allows a smaller (5%) deposit; a profession waiver may allow a larger loan without using an FHG place. The agent surfaces both; the buyer (with a broker) confirms eligibility.
- **Don't over-index on the provider.** Because the borrower can't choose the insurer, the plan should frame LMI as "applies / doesn't apply, and how to avoid it," not "which LMI company."
- **Information, not advice.** Surface that waivers exist for certain professions and that FHG removes LMI — but confirm eligibility with the lender/broker; do not direct the buyer to a specific lender's waiver (ASIC: no credit advice; independence preserved).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. Whether a no-LMI route applies to a given buyer is **agent-reasoned** in `mortgage_finance` from profile facts (FHG eligibility, profession/income, deposit) plus these landscape facts.

```jsonc
{
  "fills": [],
  "parameters": {
    "underwriters":                 { "type": "array<string>", "value": ["Helia", "QBE LMI", "Arch"], "provenance": "REGULATED", "note": "the three specialist LMI insurers on APRA's register of general insurers authorised for new business (Helia Insurance Pty Limited, QBE Lenders' Mortgage Insurance Limited, Arch Lenders Mortgage Indemnity Limited); Helia = formerly Genworth Financial Mortgage Insurance, renamed with effect from 15 November 2022 (APRA notice)" },
    "self_insuring_majors":         { "type": "array<string>", "value": ["ANZ LMI"], "provenance": "REGULATED", "note": "ANZ Lenders Mortgage Insurance Pty. Limited is the only bank-group LMI insurer on APRA's current register; CBA tendered its external LMI requirements (Helia ASX announcement, 24 March 2025), so it does not self-insure; no Westpac-group LMI insurer is on the register. Was [CommBank LMI, Westpac LMI, ANZ LMI]. Borrower still pays." },
    "borrower_chooses_provider":    { "type": "bool", "value": false, "provenance": "LENDER-POLICY", "note": "Helia: LMI \"protects credit providers, not home buyers, and cannot be provided directly to home buyers\"; QBE LMI Guide: the lender applies for cover and obtains rates. Frame as applies/avoid, not which insurer" },
    "fhg_removes_lmi":              { "type": "bool", "value": true,  "note": "the FHG government guarantee replaces LMI entirely for eligible buyers — primary Mode A no-LMI route (see kb.scheme.fhg, which owns its sources)" },
    "profession_waiver_available":  { "type": "bool", "value": true,  "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no primary cited in this doc states it; re-ground on a lender's own LMI-waiver page (e.g. Westpac's Healthcare LMI waiver page on westpac.com.au — that host is not a primary for docs/kb/lmi/ in PRIMARY_PROVIDER_HOSTS yet). Present as 'some lenders waive LMI for some professions, confirm with the lender'; no LVR ceiling, income floor or saving asserted" },
    "no_lmi_at_or_below_lvr_pct":   { "type": "percentage", "value": 80, "provenance": "REGULATED", "note": "a 20%+ deposit (≤80% LVR) avoids LMI without any scheme/waiver — Moneysmart: LMI payable above 80%; see kb.lmi.calculation" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The no-LMI-route determination and any waiver eligibility are **agent-reasoned** in `mortgage_finance`; the FHG *eligibility* verdict that route 1 depends on is owned by [`kb.scheme.fhg`](../scheme/fhg.md) (single-owner — this doc does not re-derive it). The doc supplies the landscape and the routes.
- **Provider identity is context, the mechanism is the fact.** Which insurer a lender uses (and the CBA tender) moves with commercial deals; it is recorded for orientation from APRA's register and Helia's own announcement, and flagged non-load-bearing. The stable facts are: a few APRA-authorised LMI insurers, **borrower doesn't choose**, and the three no-LMI routes.
- **Profession waivers are a PLACEHOLDER.** The broker and comparison pages that grounded the old "up to 90% LVR", "~$90,000 income" and "$10k–$30k savings" figures were removed (behavior 138); a lender's own waiver page is the primary, and lender hosts are not yet primaries for this folder. Same ASIC-line discipline as the [lender-treatment docs](../lender/hecs-treatment-by-lender.md).
- **FHG-as-alternative is a cross-ref, not a stacking edge.** LMI is not a scheme, so the FHG↔LMI relationship is expressed as prose + a link, not a `stacking` block (which is reserved for scheme-to-scheme combination in the eligibility docs). Keeps the stacking vocabulary clean (no non-scheme tokens).

## Sources

- APRA — *List of registered general insurers* (LMI insurers authorised for new business: ANZ Lenders Mortgage Insurance, Arch Lenders Mortgage Indemnity, Helia Insurance (formerly Genworth Financial Mortgage Insurance), QBE Lenders' Mortgage Insurance) — https://www.apra.gov.au/registers/list-general-insurance (archived: `docs/sources/apra/register-general-insurers.txt`)
- APRA — *Notice that general insurer or authorised NOHC has changed its name — Genworth to Helia* (with effect from 15 November 2022) — https://www.apra.gov.au/system/files/2023-07/Notice%20that%20general%20insurer%20or%20authorised%20NOHC%20has%20changed%20its%20name%20-%20Genworth%20to%20Helia.pdf (archived: `docs/sources/apra/notice-genworth-to-helia-name-change.txt`)
- Helia Group — *Update on CBA Supply and Service contract* (ASX announcement, 24 March 2025: CBA's RFP for its external LMI requirements; contract not expected to be renewed beyond 31 December 2025) — https://investor.helia.com.au/DownloadFile.axd?file=%2FReport%2FComNews%2F20250324%2F02927792.pdf (archived: `docs/sources/lmi/helia-asx-cba-contract-2025-03-24.txt`)
- Helia — *About LMI* (LMI protects credit providers and cannot be provided directly to home buyers) — https://www.helia.com.au/about-lmi (archived: `docs/sources/lmi/helia-about-lmi.txt`)
- QBE — *LMI Guide* (April 2026) — the insurer's own underwriting guide: three products (lmiFirst Home™ / lmiHome™ / lmiInvest™); max 95% LVR (100% incl capitalised premium); $5,000,000 maximum insured per borrower; the lender applies for the cover and contacts QBE LMI for rates — https://www.qbe.com/lmi (archived: `docs/sources/qbe_lmi/qbe-lmi-guide.pdf`)
