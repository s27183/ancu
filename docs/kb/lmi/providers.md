---
slug: kb.lmi.providers
effective_from: 2025-07-01
last_verified: 2026-06-01
---

# LMI providers and the ways to avoid LMI

LMI is underwritten by a small number of insurers, and the borrower **does not choose** which one — the **lender** selects the insurer (or self-insures). What matters to the plan is therefore not "which LMI provider" but **whether LMI applies at all** and, if it does, that it is an unavoidable lender-side cost. This doc owns the **provider landscape and the routes that remove LMI** (FHG, profession waivers, 20% deposit); the premium mechanics live in [`kb.lmi.calculation`](calculation.md). It grounds `mortgage_finance`'s path comparison and lender shortlist — informationally, never as a steer to a particular insurer or lender.

## Who underwrites LMI

- **Three specialist underwriters** cover virtually all residential LMI: **Helia** (the market leader, formerly **Genworth** — rebranded 2023), **QBE LMI** (second-largest; the LMI arm of diversified insurer QBE), and **Arch** (small share).
- **Some major banks self-insure** rather than buying cover from the three — **CommBank LMI, Westpac LMI, ANZ LMI**. The premium still falls on the borrower; the lender simply carries the risk in-house.
- **The lender picks the insurer.** From the borrower's side LMI is a take-it-or-leave-it cost attached to the loan, not a product to shop. (Market context, not load-bearing: CBA flagged in 2025 that it was unlikely to renew its Helia contract beyond **31 December 2025**, and some lenders are shifting underwriters — the *who* moves, the *mechanism* doesn't.)

## The routes that remove LMI

For a Mode A FHB the live question is **which no-LMI route applies**, in rough order of relevance:

1. **First Home Guarantee (FHG).** The government guarantee **stands in for LMI** — an eligible buyer borrows at 95% LVR (5% deposit) with **no LMI**. This is the primary route for Mode A and the reason the [FHG](../scheme/fhg.md) path usually beats the LMI-payable path. The avoided premium is `eligibility.fhg.lmi_savings_estimate`.
2. **Profession-based LMI waiver.** Many lenders waive LMI (commonly up to 90% LVR, sometimes higher) for **eligible professions** — historically medical/dental specialists, accountants and lawyers, and **now extended** to nurses and midwives, teachers, engineers, and others. **Lender-specific**, often with an **income floor** (e.g. some nurse waivers require income over ~$90,000), and the eligible-profession list varies by lender. Savings are typically **$10k–$30k**. This is a genuine alternative to FHG for a higher-deposit professional buyer.
3. **A 20%+ deposit.** At ≤80% LVR LMI simply does not apply (see [`kb.lmi.calculation`](calculation.md)).

## Relevance for Vietnamese-Australian buyers (Mode A)

- Many Mode A buyers are **salaried professionals** — so the **profession-waiver** route is often live alongside FHG, and the two should be compared: FHG allows a smaller (5%) deposit; a profession waiver may allow a better rate or larger loan without using an FHG place. The agent surfaces both; the buyer (with a broker) confirms eligibility.
- **Don't over-index on the provider.** Because the borrower can't choose the insurer, the plan should frame LMI as "applies / doesn't apply, and how to avoid it," not "which LMI company."
- **Information, not advice.** Surface that waivers exist for certain professions and that FHG removes LMI — but confirm eligibility with the lender/broker; do not direct the buyer to a specific lender's waiver (ASIC: no credit advice; independence preserved).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. Whether a no-LMI route applies to a given buyer is **agent-reasoned** in `mortgage_finance` from profile facts (FHG eligibility, profession/income, deposit) plus these landscape facts.

```jsonc
{
  "fills": [],
  "parameters": {
    "underwriters":                 { "type": "array<string>", "value": ["Helia", "QBE LMI", "Arch"], "note": "the three specialist LMI underwriters covering virtually all residential LMI; Helia = formerly Genworth (rebranded 2023)" },
    "self_insuring_majors":         { "type": "array<string>", "value": ["CommBank LMI", "Westpac LMI", "ANZ LMI"], "note": "majors that self-insure rather than buying cover from the three; borrower still pays" },
    "borrower_chooses_provider":    { "type": "bool", "value": false, "note": "the LENDER selects the insurer (or self-insures); LMI is not a product the borrower shops — frame as applies/avoid, not which insurer" },
    "fhg_removes_lmi":              { "type": "bool", "value": true,  "note": "the FHG government guarantee replaces LMI entirely for eligible buyers — primary Mode A no-LMI route (see kb.scheme.fhg)" },
    "profession_waiver_available":  { "type": "bool", "value": true,  "note": "LENDER POLICY — many lenders waive LMI (often up to 90% LVR) for eligible professions (medical, legal, accounting; now nurses/teachers/engineers etc.); income floors and eligible lists vary; confirm at application" },
    "no_lmi_at_or_below_lvr_pct":   { "type": "percentage", "value": 80, "note": "a 20%+ deposit (≤80% LVR) avoids LMI without any scheme/waiver — see kb.lmi.calculation" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The no-LMI-route determination and any waiver eligibility are **agent-reasoned** in `mortgage_finance`; the FHG *eligibility* verdict that route 1 depends on is owned by [`kb.scheme.fhg`](../scheme/fhg.md) (single-owner — this doc does not re-derive it). The doc supplies the landscape and the routes.
- **Provider identity is context, the mechanism is the fact.** Which underwriter a lender uses (and the CBA/Helia churn) moves with commercial deals; it is recorded for orientation but flagged non-load-bearing. The stable facts are: three underwriters + self-insuring majors, **borrower doesn't choose**, and the three no-LMI routes.
- **Profession waivers are lender policy, tagged.** `profession_waiver_available` is true as a market fact, but the eligible-profession list, LVR ceiling and income floors are **lender-specific and shifting** — flagged so the agent presents waivers as "available for some professions, confirm with the lender," not as a fixed entitlement or a steer to one lender. Same ASIC-line discipline as the [lender-treatment docs](../lender/hecs-treatment-by-lender.md).
- **FHG-as-alternative is a cross-ref, not a stacking edge.** LMI is not a scheme, so the FHG↔LMI relationship is expressed as prose + a link, not a `stacking` block (which is reserved for scheme-to-scheme combination in the eligibility docs). Keeps the stacking vocabulary clean (no non-scheme tokens).

## Sources

**Canonical (the three APRA-authorised LMI insurers' own pages + APRA):**

- Helia — *Australia's leading Lenders Mortgage Insurance (LMI) provider* (market-leading underwriter; formerly Genworth) — https://www.helia.com.au/about-lmi
- QBE — *Lenders' Mortgage Insurance (Australia)* (second-largest LMI underwriter) — https://www.qbe.com/lmi
- QBE — *LMI Guide* (April 2026) — primary (the insurer's own underwriting guide): three products (lmiFirst Home™ / lmiHome™ / lmiInvest™); max 95% LVR (100% incl capitalised premium); max $5m insured per borrower; the lender (not the borrower) selects and applies for the cover; rates obtained by the lender from QBE, not published — https://www.qbe.com/lmi (primary: `docs/sources/qbe_lmi/qbe-lmi-guide.pdf`)
- Arch Mortgage — *Australia LMI* (the third underwriter; Arch LMI authorised by APRA in 2019, acquired Westpac LMI in 2021) — https://mortgage.archgroup.com/australia-lmi/
- APRA — *Arch LMI Pty Ltd authorisation* (instrument confirming APRA authorises LMI insurers as general insurers) — https://www.apra.gov.au/sites/default/files/arch_lmi_pty_ltd_authorisation_0.pdf

**Industry detail** — lender/insurer policy and market structure, not regulator-published:

- Canstar — *LMI Waiver For Professionals* (indicative — lender/insurer-specific waivers up to 90% LVR for eligible professions; income thresholds) — https://www.canstar.com.au/home-loans/lmi-waiver-for-professionals/
- Insurance Business — *Helia: CBA unlikely to renew LMI contract beyond 31 December 2025* (trade press — provider-churn / market-structure context) — https://www.insurancebusinessmag.com/au/news/breaking-news/labor-policy-to-slug-qbe-helia-arch-545825.aspx
