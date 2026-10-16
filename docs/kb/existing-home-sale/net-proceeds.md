---
slug: kb.existing-home-sale.net-proceeds
effective_from: 2026-07-05
last_verified: 2026-10-16
sources:
  - url: https://www.mozo.com.au/home-loans/resources/guides/how-to-discharge-your-mortgage-and-what-it-means.html
    retrieved: 2026-07-06
  - url: https://www.finder.com.au/home-loans/home-loan-exit-fees
    retrieved: 2026-10-16
    path: docs/sources/existing-home-sale/finder-home-loan-discharge-fees.txt
    quotes:
      - "The average mortgage discharge fee is just over $300. Some lenders charge as much as $500 or as little as $150."
      - "CBA discharge fee: $350"
  - url: https://www.westpac.com.au/personal-banking/home-loans/fees/
    retrieved: 2026-10-16
    path: docs/sources/existing-home-sale/westpac-home-loan-fees.txt
    quotes:
      - "Loan discharge fee $350 per settlement activity"
  - url: https://nswlrs.com.au/assets/f/1129775276948026/x/5fed3e7cd6/2026-2027_nsw-lrs-fees_final.pdf
    retrieved: 2026-10-16
    path: docs/sources/nsw/nsw-lrs-fees-2026-27.txt
    quotes:
      - "Discharge of Mortgage *166.60 182.73"
  - url: https://www.titlesqld.com.au/fees-payments/
    retrieved: 2026-10-16
    path: docs/sources/qld/titles-registry-fees-fy-2026-27.txt
    quotes:
      - "(l) any other instrument 248.04"
---

# Existing-home sale — net proceeds funding the next purchase

A **Mode E** buyer (upsizer/downsizer/relocator) typically funds their next purchase partly from **selling the home they currently own and live in**. This is a **different transaction from `disposition`** — `disposition` models the *future* exit of the property this plan is *for* (Modes A/C/D's eventual sale, years out); this doc models the **current** home being sold **now**, feeding the new purchase's `cash_position` as a cash source. The net figure is:

```
net_sale_proceeds = sale_price − loan_payout − selling_costs − cgt
```

Each term is either **reused from an existing KB doc** (selling costs, CGT — the same mechanics apply to a sale happening now as to a future one) or **new to this doc** (loan payout — the piece no existing component models, because no prior mode sells a currently-held property mid-plan).

## Loan payout — discharging the existing mortgage

Selling the home requires **discharging** (paying out and closing) any mortgage secured against it. Two components:

- **Outstanding principal balance** — the amount still owed, a fact from the buyer's own loan statement (not a KB estimate; the resolver takes it as user-attested input, same discipline as `<from_transaction>` facts elsewhere in this architecture — never inferred).
- **Discharge/settlement administration fee** — a lender-set fee to process the discharge, conventionally **$150–$500** (some lenders up to ~$795; reported averages cluster around $300–$330). This is a **market-set estimate**, not a regulated figure — no statutory fee schedule exists for it.

**If the loan is fixed-rate and being discharged before the fixed term ends**, a **break cost** (also called an early-repayment or break fee) applies. This is **not a fixed percentage or regulated figure** — it reflects the lender's own **economic loss** from the borrower exiting early (driven by how much interest rates have moved since the fixed rate was locked in; larger when rates have fallen more). The resolver surfaces this as a **`to_verify` flag** when the buyer's loan is fixed-rate, never an estimated dollar figure — the number can only come from the buyer's own lender.

**No exit-fee penalty on variable-rate loans.** For home loans written on or after **1 July 2011**, National Consumer Credit Protection Amendment Regulations 2011 prohibit a lender from charging a loan-termination fee **except** (a) a fixed-rate break cost reflecting the lender's genuine cost-of-funds change (above), or (b) a fee that only recovers the lender's **reasonable administrative costs** of ending the contract (the discharge fee, above). So a **variable-rate** loan payout today carries **only** the discharge admin fee — no early-exit penalty. (ASIC's Regulatory Guide 220, *"Early termination fees for residential loans,"* addresses this same rule; its exact wording was not independently re-parsed for this doc — treat the regulation as the primary citation and RG220 as a named, not yet directly-read, secondary confirmation. The regulation's precise amending-instrument number was also not pinned to a specific gazettal in this pass — see Sources.)

**Processing timeframe** — lenders commonly require **10–21 business days'** notice to process a discharge (NAB and ANZ: at least 10 business days; HSBC: up to 21). This is a **lender convention**, not a regulated timeframe; it matters for Mode E because it constrains how close to settlement the discharge request can be lodged, feeding the same settlement-timing question that triggers the bridging-finance flag below.

## Selling costs — reused, not duplicated

Agent commission, sale-side legal/conveyancing, and marketing are already modelled in [`kb.selling-costs.agent-legal`](../selling-costs/agent-legal.md) — the same bands apply whether the sale is a future `disposition` exit or (as here) the current home being sold now. This doc does not re-derive them; the resolver reuses that doc's `content_json` parameters directly.

## CGT — reused, not duplicated

The home being sold is (in the base case) the seller's **main residence**, so the same full-exemption conditions and loss-of-exemption traps in [`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md) apply: exempt (`cgt: null`) when it was the buyer's home for the whole ownership period, not rented, on ≤2ha, and the seller is an Australian resident for tax — `to_verify` once a rental period or non-resident status is in play. This doc does not re-derive the exemption rules; the resolver reuses that doc's `content_json` directly, applied to *this* sale rather than a future one.

## Settlement-timing mismatch → bridging finance

If the new purchase's settlement date falls **before** this sale settles (or the sale isn't yet confirmed), the buyer faces a funding gap between the two transactions. This doc does not model that gap — it is [`kb.bridging-finance.mechanics`](../bridging-finance/mechanics.md), a **labelled placeholder** (mode-e-wedge.md scoping decision #3). This doc's resolver only *detects* the timing mismatch (a plain date comparison) and hands off to that placeholder; it does not compute bridging economics itself.

## Relevance for Vietnamese-AU next-home buyers (Mode E)

- **The base case nets a clean figure.** A Mode E buyer selling their current PPOR with a variable-rate loan, no rental history, and matched settlement dates gets a straightforward `net_sale_proceeds = sale_price − outstanding_balance − discharge_fee − selling_costs` (CGT = exempt). The plan states this plainly rather than leaving the new purchase's cash position silently short of this input.
- **Three traps flip the clean case to `to_verify`:** a fixed-rate loan (break cost unknown until the lender quotes it), a rental history on the home (CGT partial exemption + the discharge fee is unaffected but CGT is not), and a settlement-timing mismatch (bridging finance, placeholder).
- **Information, not advice.** The plan states the components and bands and points to the buyer's own lender / a tax agent to confirm the payout figure and CGT position; it never asserts a binding net-proceeds number as advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the anticipated `existing_home_disposal` resolver (mode-e-wedge.md P2, not yet built) computes `net_sale_proceeds` from these rules plus the reused `kb.selling-costs.agent-legal` / `kb.tax.cgt-main-residence-exemption` parameters.

```jsonc
{
  "fills": [],
  "parameters": {
    "exit_fee_ban_from":      { "type": "string", "value": "1 July 2011", "provenance": "REGULATED", "note": "National Consumer Credit Protection Amendment Regulations 2011 — bans loan-termination fees on home loans written on/after this date EXCEPT a fixed-rate break cost (genuine cost-of-funds change) or a discharge fee recovering only reasonable admin costs. Exact amending-instrument gazettal number not independently re-verified this pass; ASIC RG220 is a named, not-yet-directly-read secondary confirming the same rule." },
    "break_cost_is_lender_calculated_not_fixed": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a fixed-rate break cost reflects the lender's own economic loss (interest-rate differential since the fixed rate was set) — NOT a fixed percentage or published figure; the resolver must never estimate a break-cost dollar amount, only flag to_verify when the loan is fixed-rate (MoneySmart glossary, 'break fee' — retrieved via search snippet, direct fetch blocked by the site)" },
    "discharge_processing_business_days_low":  { "type": "integer", "value": 10, "provenance": "CONVENTION", "note": "typical minimum lender notice period to process a discharge (NAB, ANZ) — lender convention, not regulated" },
    "discharge_processing_business_days_high": { "type": "integer", "value": 21, "provenance": "CONVENTION", "note": "upper end of typical notice period (HSBC) — lender convention, not regulated" },
    "reuses_selling_costs_doc": { "type": "string", "value": "kb.selling-costs.agent-legal", "note": "no duplication — the resolver reuses that doc's content_json parameters directly for this sale" },
    "reuses_cgt_doc":           { "type": "string", "value": "kb.tax.cgt-main-residence-exemption", "note": "no duplication — the resolver reuses that doc's content_json parameters directly, applied to this (current) sale rather than a future disposition" },
    "settlement_mismatch_hands_off_to": { "type": "string", "value": "kb.bridging-finance.mechanics", "note": "the resolver detects the timing fact (plain date comparison) and hands off; it does not compute bridging economics itself (placeholder, mode-e-wedge.md decision #3)" },
    "net_proceeds_formula": { "type": "string", "value": "sale_price − loan_payout(outstanding_balance + discharge_fee [+ break_cost if fixed-rate, to_verify]) − selling_costs − cgt", "note": "surfaced as a banded money_range (inherits the banding of selling_costs and, where applicable, sale_price projections) — never a single asserted figure" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "mortgage_discharge",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "LENDER-POLICY",
          "basis": "fixed",
          "low": 150,
          "high": 500,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label": {
            "vi": "Phí tất toán khoản vay (discharge fee) của ngân hàng",
            "en": "Lender's mortgage discharge fee"
          },
          "payer": {
            "vi": "Người bán trả cho ngân hàng khi trả hết khoản vay",
            "en": "The seller pays the lender when the loan is paid out"
          },
          "drivers": {
            "vi": "Do từng ngân hàng quy định; bốn ngân hàng lớn thường ~$350. Vay lãi suất cố định còn có thể chịu phí phá vỡ hợp đồng (break cost) — tính riêng.",
            "en": "Set by each lender; the major banks are typically ~$350. A fixed-rate loan can also carry a break cost — separate."
          },
          "source": "https://www.finder.com.au/home-loans/home-loan-exit-fees"
        },
        {
          "id": "mortgage_discharge_registration_nsw",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "REGULATED",
          "basis": "fixed",
          "low": 182.73,
          "high": 182.73,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": [
              "NSW"
            ],
            "property": "any"
          },
          "optional": false,
          "label": {
            "vi": "Lệ phí đăng ký giải chấp (discharge of mortgage) — NSW",
            "en": "Discharge of mortgage registration fee — NSW"
          },
          "payer": {
            "vi": "Người bán trả, thường qua luật sư khi settlement",
            "en": "The seller pays, usually through the conveyancer at settlement"
          },
          "drivers": {
            "vi": "Lệ phí cố định của cơ quan đăng ký đất đai NSW, áp dụng từ 1/7/2026.",
            "en": "A fixed NSW land registry fee, from 1 July 2026."
          },
          "source": "https://nswlrs.com.au/assets/f/1129775276948026/x/5fed3e7cd6/2026-2027_nsw-lrs-fees_final.pdf"
        },
        {
          "id": "mortgage_discharge_registration_qld",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "REGULATED",
          "basis": "fixed",
          "low": 248.04,
          "high": 248.04,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": [
              "QLD"
            ],
            "property": "any"
          },
          "optional": false,
          "note": "lodged as 'any other instrument' in the Titles Registry fee schedule FY2026-27",
          "label": {
            "vi": "Lệ phí đăng ký giải chấp (release of mortgage) — QLD",
            "en": "Release of mortgage registration fee — QLD"
          },
          "payer": {
            "vi": "Người bán trả, thường qua luật sư khi settlement",
            "en": "The seller pays, usually through the conveyancer at settlement"
          },
          "drivers": {
            "vi": "Lệ phí cố định của Titles Queensland cho năm tài chính 2026-27 (mục 'any other instrument').",
            "en": "A fixed Titles Queensland fee for FY2026-27 (the 'any other instrument' item)."
          },
          "source": "https://www.titlesqld.com.au/fees-payments/"
        },
        {
          "id": "mortgage_discharge_registration_vic",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "PLACEHOLDER",
          "basis": "fixed",
          "low": null,
          "high": null,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": [
              "VIC"
            ],
            "property": "any"
          },
          "optional": false,
          "note": "PLACEHOLDER — re-ground from Land Use Victoria's 'Guide to Transfer of Land Act fees' 2026-27 (land.vic.gov.au, fetch blocked 403 this session); the 2025-26 figure is stale",
          "label": {
            "vi": "Lệ phí đăng ký giải chấp (discharge of mortgage) — VIC",
            "en": "Discharge of mortgage registration fee — VIC"
          },
          "payer": {
            "vi": "Người bán trả, thường qua luật sư khi settlement",
            "en": "The seller pays, usually through the conveyancer at settlement"
          },
          "drivers": {
            "vi": "Lệ phí cố định của Land Use Victoria; mức 2026-27 chưa được xác minh.",
            "en": "A fixed Land Use Victoria fee; the 2026-27 figure is not yet verified."
          },
          "source": null
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `net_sale_proceeds` is resolver-computed from the buyer's attested loan balance + these bands + the two reused docs' parameters; the doc supplies the method and the bands, not a computed figure.
- **Loan-payout facts are MIXED provenance, honestly labelled.** The exit-fee ban and the break-cost mechanism are REGULATED (statutory/regulatory-guide backed); the discharge-fee dollar range and the processing timeframe are ESTIMATE/CONVENTION (market-set, lender-published, not a statute) — consistent with the verify-by-postcondition discipline (regulated figures cited to their instrument, estimates surfaced as ranges).
- **Verification caveat.** Several sources were confirmed via search-engine snippets rather than a direct page fetch (moneysmart.gov.au returned HTTP 403 to direct retrieval this pass) — the substantive rules are corroborated by multiple independent sources (lender pages, the regulation text, MoneySmart's own glossary snippet) but a follow-up direct-fetch verification pass is recommended before this doc's `last_verified` date is extended past a routine freshness check, per [[kb-doc-authoring]].
- **Scope discipline.** This is the **Mode E** slice — an owner-occupier's *current* PPOR sold *now*. It does not model an investor's disposal (that stays `disposition`'s Modes C/D path) and does not duplicate selling-costs or CGT mechanics already owned elsewhere.

## Sources

**Canonical (regulation + regulator):**

- National Consumer Credit Protection Amendment Regulations 2011 (bans home-loan termination fees except genuine fixed-rate break costs or reasonable-cost-recovery discharge fees, for loans written on/after 1 July 2011) — legislation.gov.au (exact amending-instrument number not pinned to a specific gazettal this pass; re-verify before treating as a precise citation).
- ASIC Regulatory Guide 220 — *Early termination fees for residential loans* — https://download.asic.gov.au/media/seubdgt4/rg220-published-09-november-2023.pdf (named as a corroborating secondary; PDF text not successfully parsed this pass — not independently re-read).
- MoneySmart (ASIC) — glossary entry, *"break fee"* — https://moneysmart.gov.au/glossary/break-fee (retrieved via search snippet; direct fetch blocked by the site, HTTP 403).

**Estimates — conventional market ranges (not a regulated primary):**

- Discharge/settlement admin fee range ($150–$500, some lenders to ~$795) — aggregator corroboration (Yard Home Loans, Canstar); re-verify against a primary lender fee schedule before treating as more than indicative.
- Discharge processing notice period (10–21 business days) — lender-published requirement pages: nab.com.au, anz.com.au, hsbc.com.au.
