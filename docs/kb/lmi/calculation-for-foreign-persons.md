---
slug: kb.lmi.calculation-for-foreign-persons
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.helia.com.au/media/tg4jxazi/lmi-underwriting-standards-and-guidelines-2026-aug-10.pdf
    retrieved: 2026-10-27
    path: docs/sources/lmi/helia-lmi-underwriting-standards-2026-08.txt
    note: "Helia's own LMI underwriting standards and guidelines (Australia, effective 10 August 2026). §3.3 \"Unacceptable borrowers\" lists Non-Residents and \"Temporary visa holders\", each except where the borrower is the spouse or de facto partner of an Australian citizen (resident in Australia or New Zealand, or an expatriate) or of an Australian or New Zealand permanent resident (resident in Australia or New Zealand). §3.1 acceptable borrowers: citizens or permanent residents of Australia or New Zealand resident there, and Australian citizen expatriates. §4.1: owner-occupied purchase, Standard LMI, 95%."
  - url: https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi
    retrieved: 2026-10-27
    path: docs/sources/lmi/moneysmart-glossary-lmi.txt
    note: "ASIC Moneysmart glossary: LMI is \"payable when the amount borrowed exceeds 80% of the value of the property. LMI does not benefit the borrower, it only protects the lender.\""
---

# LMI for foreign persons — the availability delta

This doc owns the **foreign-person availability delta** for Lenders Mortgage Insurance: *whether LMI is even on the table* for a foreign person or temporary resident, and on what terms. It grounds two components — `mortgage_finance` (component 5, the deposit path) and `cash_position` (component 6, the `other_buying_costs.lmi_if_lvr_above_80` line).

The **universal LMI mechanics** — the 80% LVR trigger, how the premium is sized (the insurer's proprietary LVR × loan-size rate table), capitalisation, GST + state duty, refund window — are owned by [`kb.lmi.calculation`](calculation.md), which declares itself owner of "how the premium is sized and structured", and the insurer landscape by [`kb.lmi.providers`](providers.md). This doc owns **only what changes for a foreign borrower** and points back to those for the universal core rather than restating it — the same split-by-axis discipline as [`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md) relative to serviceability-basics.

## The delta: LMI is usually not available to a foreign borrower

For a domestic FHB, LMI is the standard way to borrow above 80% LVR with a small deposit — ASIC's Moneysmart: LMI is "payable when the amount borrowed exceeds 80% of the value of the property". For a foreign person, it mostly **is not an option**:

- **The market-leading insurer will not cover a non-resident or a temporary visa holder.** Helia's own underwriting guidelines (August 2026) list Non-Residents and "Temporary visa holders" among its "Unacceptable borrowers" (§3.3). The one exception is a borrower who is the spouse or de facto partner of an Australian citizen or of an Australian / New Zealand permanent resident (see below). Its acceptable borrowers (§3.1) are citizens and permanent residents of Australia or New Zealand living there, and Australian citizens living abroad. QBE LMI and Arch have not been checked on this point; their own underwriting guidelines are the pages to re-ground on.
- **Non-resident lending sits at or under 80% LVR at the lenders that publish it** ([`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md), which owns those bands) — so LMI does not arise; the larger deposit is required *instead of*, not *alongside*, LMI.
- **Consequence:** for the standard non-resident (foreign-income) buyer, plan on the **deposit floor**, not on LMI bridging a small deposit. The `lmi_if_lvr_above_80` line is **$0** for this profile because the LVR is held at/under 80%.

## Where LMI *does* re-enter

- **Buying with an Australian citizen / PR partner.** Helia's §3.3 exception: a non-resident or temporary visa holder who is the spouse or de facto partner of an Australian citizen (resident in Australia or New Zealand, or an expatriate), or of an Australian or New Zealand permanent resident (resident in Australia or New Zealand), is not an unacceptable borrower. The purchase then meets **LMI as it would for any local** high-LVR loan (Helia's standard owner-occupied purchase limit is 95% LVR, §4.1) — sized per [`kb.lmi.calculation`](calculation.md). This is the main route by which a Mode-B buyer meets LMI at all.
- **Temporary resident earning AUD in Australia, buying alone.** Helia's guidelines put a temporary visa holder outside its cover unless the spouse exception applies, so this doc does **not** model an LMI path for a sole temporary resident. Whether another insurer (QBE LMI, Arch) covers that profile is unconfirmed — a `PLACEHOLDER` until their own guidelines are read; a lender that lends above 80% to that profile names its insurer at application ([`kb.lender.485-visa-treatment`](../lender/485-visa-treatment.md)).

In the re-entry case the **premium is sized by the universal doc, not here** — this doc only determines *whether* LMI applies to the profile.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Don't model LMI for the standard foreign-income buyer.** The deposit floor is the binding constraint; LMI is generally unavailable, so the cash plan carries the deposit rather than an LMI premium.
- **Do model LMI on the joint-purchase path.** There it behaves like a domestic high-LVR loan; size it via [`kb.lmi.calculation`](calculation.md).
- **The cash-calculator line is conditional.** `lmi_if_lvr_above_80` is $0 unless the profile is the re-entry case — the resolver decides which, this doc supplies the rule.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` and `cash_position` resolvers use the availability rule below to decide **whether** LMI applies to the profile; when it does, the premium is computed by [`kb.lmi.calculation`](calculation.md)'s parameters, not here. No leaf asserted; no premium figure duplicated.

```jsonc
{
  "fills": [],
  "parameters": {
    "lmi_generally_unavailable_for_foreign_income_borrower": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "LENDER-POLICY band — Helia: Non-Residents and temporary visa holders are \"Unacceptable borrowers\" (LMI underwriting standards and guidelines, Aug 2026, §3.3) except as spouse/de facto of an AU citizen or AU/NZ permanent resident. One insurer only; QBE LMI and Arch not yet read — re-ground on their own underwriting guidelines." },
    "non_resident_lvr_at_or_under_80_so_no_lmi": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "LMI is payable only above 80% LVR (Moneysmart glossary); the non-resident LVR caps that put the loan at/under 80% are owned by kb.lender.foreign-buyer-deposit-requirements, which cites the lenders' own pages. lmi_if_lvr_above_80 is $0 for the standard foreign-income profile." },
    "lmi_applies_for_temp_resident_au_income_above_80": { "type": "bool", "value": false, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no primary states that a sole temporary resident can get LMI. Helia lists \"Temporary visa holders\" as unacceptable borrowers (§3.3), except a spouse/de facto of an AU citizen or AU/NZ PR (that case is lmi_applies_for_joint_purchase_with_au_partner). Was true (broker source, removed). Re-ground on QBE LMI's and Arch's own underwriting guidelines." },
    "lmi_applies_for_joint_purchase_with_au_partner": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "LENDER-POLICY band — Helia: a non-resident or temporary visa holder who is the spouse or de facto partner of an AU citizen or AU/NZ permanent resident is excepted from the unacceptable-borrower list (§3.3); standard owner-occupied purchase limit 95% LVR (§4.1). Premium sized by kb.lmi.calculation." },
    "premium_sizing_owned_by_universal_lmi_doc": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "when LMI applies, the premium (80% trigger, LVR × loan-size rate table, capitalisation, GST + state duty, refund) is owned by kb.lmi.calculation — this doc only decides applicability." }
  }
}
```

Notes:

- **Single-owner via split-by-axis.** This doc owns *foreign-person LMI availability*; the premium sizing stays with [`kb.lmi.calculation`](calculation.md) and the insurer landscape with [`kb.lmi.providers`](providers.md). No premium mechanics restated.
- **Consumed by two components.** `mortgage_finance` (deposit path) and `cash_position` (the LMI cash line) both read this applicability rule; the deposit bands themselves are owned by [`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md).
- **Insurer policy, one insurer read.** Availability is the LMI insurer's own policy (`LENDER-POLICY`), grounded on Helia's underwriting guidelines; QBE LMI's and Arch's guidelines are the pages to read next. Deferred to a broker at application.

## Sources

- Helia — *LMI underwriting standards and guidelines — Australia* (effective 10 August 2026): §3.1 acceptable borrowers; §3.3 unacceptable borrowers (Non-Residents, Temporary visa holders, with the spouse / de facto exception); §4.1 owner-occupied purchase 95% — https://www.helia.com.au/media/tg4jxazi/lmi-underwriting-standards-and-guidelines-2026-aug-10.pdf (archived: `docs/sources/lmi/helia-lmi-underwriting-standards-2026-08.txt`)
- ASIC Moneysmart — *lenders mortgage insurance (LMI)* glossary (payable above 80% of the property's value; protects the lender only) — https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi (archived: `docs/sources/lmi/moneysmart-glossary-lmi.txt`)
