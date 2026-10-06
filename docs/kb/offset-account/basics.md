---
slug: kb.offset-account.basics
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.commbank.com.au/home-loans/interest-offset.html
    retrieved: 2026-07-06
    note: "CommBank Everyday Offset — a transaction account linked to an eligible variable-rate home loan whose balance reduces the amount interest is charged on (100% offset), fully accessible. Confirms the offset mechanism, the variable-rate pairing, and the offset-vs-redraw framing."
---

# Offset accounts — how they work and the offset-vs-redraw choice

An **offset account** is a transaction account linked to a home loan whose balance is netted against the loan balance before interest is charged — so money sitting in it reduces interest without being a repayment. Whether to take one is a **loan-structure** decision, not a separate product to shop. This doc owns **what an offset is, how it saves interest, how it differs from redraw, and the package-fee trade-off**; it grounds `mortgage_finance.loan_structure.offset_account_included` and `loan_structure.offset_strategy` — informationally, never as a steer to a particular lender's package.

## How an offset account works

- **It's a 100% offset transaction account linked to the loan**, generally available **with a variable-rate loan**. It behaves like an everyday account — the money stays the borrower's and stays accessible.
- **Interest is calculated daily, with the offset balance subtracted from the loan balance first.** Each day the lender works out interest on (loan balance − offset balance). So **$30k sitting in offset against a $500k loan means interest is charged on $470k** — dollar-for-dollar.
- **You earn no interest on the offset balance.** The benefit is the **loan interest you avoid**, not interest earned. Because avoided loan interest is not income, the benefit is **effectively tax-free** — which is why an offset usually beats holding the same cash in a (taxed) savings account.

## Offset vs redraw — they look similar, they aren't

- **Redraw** holds the **extra repayments** you've made *against* the loan; you may be able to withdraw them, but **access depends on the loan's terms** (minimum amounts, per-withdrawal fees, and at the lender's discretion). The money has legally been paid onto the loan.
- **Offset** is a **separate transaction account**; the balance is the borrower's own funds with everyday access, never "paid onto" the loan. For keeping a **liquid buffer**, offset is the cleaner instrument.
- **Deductibility nuance (matters later, not now).** Because redrawn funds are *new borrowings*, redrawing for a non-property purpose can muddy a loan's deductible character if the home later becomes an investment; drawing down an offset doesn't alter the loan. This is a structural fact, light for a Mode A owner-occupier — the investor mechanics are owned by the investor blueprint's `kb.loan.offset-vs-redraw-investor`. Confirm any tax position with a professional.

## The package-fee trade-off

- An offset is often bundled into a **"professional" / package home loan** carrying an **annual package fee** (indicatively **~$300–$400/yr**) or a marginally higher rate. It pays off only when the **offset balance is large enough that interest saved exceeds the fee** — a near-empty offset is a cost, not a saving. Some basic/online loans now offer an offset with **no package fee**, so the fee is a product variable to check, not a given.
- **Partial vs 100% offset.** A **100% offset** nets dollar-for-dollar; a **partial offset** only offsets a fraction of the balance. **Fixed-rate loans** commonly allow only a limited/partial offset, or none — read the specific product.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The post-settlement reserve buffer belongs in an offset.** The ~3-month buffer from [`kb.cash-reserve.lender-expectations`](../cash-reserve/lender-expectations.md) stays fully liquid *and* cuts loan interest tax-free when parked in offset — the natural home for it rather than a separate savings account.
- **Family-gift or FHSS funds awaiting deployment** can sit in offset earning an effective tax-free return while plans firm up, instead of in a taxed account.
- **Information, not advice.** Surface that an offset exists, how the fee break-even works, and that the buffer is best held there — but the buyer (with a broker) picks the product; do not direct them to a specific lender's package (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. Whether an offset suits a given buyer (`loan_structure.offset_account_included`) and the `offset_strategy` are **agent-reasoned** in `mortgage_finance` from profile facts (buffer size, fixed-vs-variable choice, package fee) against these mechanism facts.

```jsonc
{
  "fills": [],
  "parameters": {
    "offset_type_default":            { "type": "string",  "value": "100_percent", "note": "CONVENTION — a full (100%) offset is the standard; partial offsets net only a fraction, fixed-rate loans often allow limited/no offset" },
    "generally_variable_rate":        { "type": "bool",    "value": true,  "note": "CONVENTION — offset is generally available on variable-rate loans; fixed loans commonly restrict or exclude it" },
    "interest_calculated_daily":      { "type": "bool",    "value": true,  "note": "lender mechanic — interest charged daily on (loan balance − offset balance); offset reduces the interest-bearing principal dollar-for-dollar" },
    "offset_balance_earns_interest":  { "type": "bool",    "value": false, "note": "no interest earned on the offset balance; the benefit is avoided loan interest, which (being not income) is effectively tax-free vs a taxed savings account" },
    "redraw_access_at_lender_discretion": { "type": "bool", "value": true, "note": "CONVENTION — redraw (extra repayments) withdrawal depends on loan terms/minimums/fees and lender discretion, unlike an offset's everyday access — the two are not interchangeable" },
    "typical_package_annual_fee_aud_low":  { "type": "money", "value": 300, "note": "LENDER POLICY/indicative — annual package fee on offset-bundled loans; break-even = offset balance where interest saved > fee; varies, some loans offer offset fee-free" },
    "typical_package_annual_fee_aud_high": { "type": "money", "value": 400, "note": "LENDER POLICY/indicative — upper end of the typical package fee range; confirm per product" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The include-an-offset decision and the `offset_strategy` are agent-reasoned in `mortgage_finance`; the doc supplies the mechanism and the fee break-even, not a verdict.
- **All figures CONVENTION or LENDER POLICY — none regulated.** The offset mechanism is a product feature, not a statutory rule; the package fee is lender-set and indicative. Tagged so the agent presents "a 100% offset works like this / a package typically costs ~$300–400," never as law or a fixed price.
- **Offset-vs-redraw kept distinct.** They save interest by different mechanisms with different access and tax characteristics — documented apart so the agent never conflates a buffer-in-offset with extra-repayments-in-redraw. The investor-specific offset/redraw structuring is owned by the investor blueprint (`kb.loan.offset-vs-redraw-investor`), not re-derived here.
- **The buffer↔offset link is a cross-ref, not a re-derivation.** The reserve-buffer figure is owned by [`kb.cash-reserve.lender-expectations`](../cash-reserve/lender-expectations.md); this doc only notes the offset is where that buffer should sit.

## Sources

**Canonical (regulator — ASIC Moneysmart):**

- ASIC Moneysmart — *Mortgage offset accounts* (an offset is a transaction account linked to the loan, generally with a variable rate; the balance reduces the loan amount charged interest; interest is calculated daily with the offset balance subtracted before charging; you earn no interest on the offset, you save by paying less loan interest) — https://moneysmart.gov.au/home-loans/mortgage-offset-accounts
- ASIC Moneysmart — *offset account* / *redraw facility* (glossary definitions) — https://moneysmart.gov.au/glossary/offset-account · https://moneysmart.gov.au/glossary/redraw-facility
- ASIC Moneysmart — *Pay off your mortgage faster* (extra repayments and redraw vs offset; both can save interest but work differently — check fees, rate and access rules) — https://moneysmart.gov.au/home-loans/pay-off-your-mortgage-faster
- ASIC Moneysmart — *Choosing a home loan* (package/professional loans and their ongoing fees; the basis for the package-fee break-even) — https://moneysmart.gov.au/home-loans/choosing-a-home-loan
