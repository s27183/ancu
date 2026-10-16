---
slug: kb.investor.deposit-requirements-investment-loans
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/saving/save-for-a-house-deposit
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
    retrieved: 2026-07-06
  - url: https://www.apra.gov.au/prudential-practice-guide-apg-223-residential-mortgage-lending
    retrieved: 2026-07-06
    path: docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf
---

# Deposit requirements — investment loans

An investor's deposit requirement differs from a first-home buyer's: there are **no first-home-buyer schemes or grants**, **no FHB stamp-duty concessions**, and lenders treat investment lending more conservatively. This doc owns the **deposit bands** for an investment purchase so `cash_position` can compute the `deposit_ready_for_purchase` cash requirement. The figures are **banded** (lender policy, not regulated constants) except the 80% LMI boundary; the surrounding acquisition costs are owned by sibling docs and cross-referenced. Informational; a broker confirms the actual requirement (ACL line).

## The deposit bands

- **20% deposit** — the typical investor target: at **80% LVR no LMI** applies, the widest lender choice, and the best rates. The practical planning baseline.
- **10–12% deposit** — possible with **LMI** (loan above 80% LVR); LMI is **more expensive for investment loans** than owner-occupier, and lenders restrict investment lending above ~90% LVR. The plan surfaces the higher LMI cost as part of the cash picture.
- **No FHB schemes apply.** The First Home Guarantee, First Home Owner Grant, and FHB stamp-duty concessions are **owner-occupier first-home** measures — an investor cannot use them to reduce the deposit. The plan does not offer them on an investor card.

## Deposit is not the whole cash requirement

The cash needed at settlement is the deposit **plus** acquisition costs that an investor cannot reduce with concessions:

- **Stamp duty at the full rate** — no FHB concession (owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md)); but **no foreign-buyer surcharge** for a domestic (citizen/PR) investor.
- **LMI** if above 80% LVR (owned by [`kb.lmi.calculation`](../lmi/calculation.md)).
- **Investor cost adders** — conveyancing, building/pest, loan fees, and the investor-specific items (owned by [`kb.buyer-costs.investor-additional-costs`](../buyer-costs/investor-additional-costs.md)).
- **Entity setup cost** if buying via a trust/company/SMSF (owned by [`kb.tax.entity-setup-costs`](../tax/entity-setup-costs.md)) and a **QS report** (owned by [`kb.tax.quantity-surveyor-reports`](../tax/quantity-surveyor-reports.md)).

The plan sums the deposit and these adders into the total cash-at-purchase; this doc owns only the **deposit band**, the others own their figures.

## Relevance for Vietnamese-Australian investors (Mode C)

- **20% is the planning baseline.** The plan bands the deposit at 20% to avoid LMI, with 10–12%+LMI as the higher-cost alternative — and shows the LMI premium so the trade-off is visible.
- **No first-home help.** The plan makes clear an investor gets no FHB schemes, grants, or stamp-duty concessions — avoiding a false expectation carried over from owner-occupier planning.
- **No foreign-buyer surcharge for a domestic investor.** A citizen/PR investor pays full ordinary stamp duty but not the foreign surcharge — the plan reflects this correctly.
- **Banded, broker confirms.** Deposit policy varies by lender and property; the plan bands it and points to a broker (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the `deposit_ready_for_purchase` cash requirement is **resolver-computed** by placing the banded deposit (from these bands, against the purchase price) plus the acquisition-cost adders owned by the sibling docs. Bands are CONVENTIONS; the 80% LMI boundary is the regulated capital-treatment line.

```jsonc
{
  "fills": [],
  "parameters": {
    "deposit_no_lmi_pct":        { "type": "percentage", "value": 20, "note": "CONVENTION — typical investor deposit to reach 80% LVR and avoid LMI; the planning baseline" },
    "deposit_min_with_lmi_pct":  { "type": "percentage", "value": 10, "note": "CONVENTION — minimum deposit with LMI (loan above 80% LVR); LMI is more expensive for investment loans; investment lending restricted above ~90% LVR" },
    "lmi_threshold_lvr_pct":     { "type": "percentage", "value": 80, "note": "above 80% LVR LMI applies (regulated capital-treatment boundary); LMI calc owned by kb.lmi.calculation" },
    "no_fhb_schemes_for_investor": { "type": "bool", "value": true, "note": "First Home Guarantee / FHOG / FHB stamp-duty concessions are owner-occupier first-home measures — NOT available to an investor; the plan does not offer them on an investor card" },
    "no_foreign_surcharge_domestic_investor": { "type": "bool", "value": true, "note": "a domestic (citizen/PR) investor pays full ordinary stamp duty but NOT the foreign-buyer surcharge (cross-ref kb.stamp-duty.calc-by-state)" }
  },
  "lookup": {
    "line_details": {
      "note": "one entry per statement line this doc's figure is placed on (not a fee line); the engine attaches it as the line's detail, filling {params} with the figures it computed (fh_engine_line_detail, behavior 93)",
      "entries": [
        {
          "id": "deposit_chosen",
          "tier": "LENDER-POLICY",
          "how": {
            "vi": "{amount} — mức đặt cọc bạn chọn ({pct}% giá nhà), trả khi ký hợp đồng. Mức thấp nhất kế hoạch chấp nhận là {min_pct}%; bạn có thể đặt đến toàn bộ giá nhà (mua đứt, không vay).",
            "en": "{amount} — the deposit you chose ({pct}% of the price), paid when you sign the contract. The smallest this plan accepts is {min_pct}%; you can put down up to the whole price (buying outright, with no loan)."
          },
          "payer": {
            "vi": "Bạn trả từ tiền của mình; khoản này được giữ trong tài khoản ủy thác (trust) đến ngày settlement.",
            "en": "You, from your own money; it is held in trust until settlement."
          },
          "drivers": {
            "vi": "Đặt cọc nhiều hơn thì khoản vay nhỏ hơn và tiền lãi ít hơn; từ 20% giá nhà trở lên thì không phải trả bảo hiểm khoản vay (LMI).",
            "en": "A larger deposit means a smaller loan and less interest; from 20% of the price there is no lenders mortgage insurance (LMI)."
          },
          "note": {
            "vi": "Bạn đổi được con số này trong “Tài chính của bạn”.",
            "en": "You can change this in “Your finances”."
          },
          "source": 2
        },
        {
          "id": "deposit",
          "tier": "CONVENTION",
          "how": {
            "vi": "{pct}% của {price} — mức đặt cọc giữ khoản vay ở 80% giá nhà; vay cao hơn mức này, ngân hàng tính thêm bảo hiểm khoản vay (LMI).",
            "en": "{pct}% of {price} — the deposit that keeps the loan at 80% of the price; above that, lenders add mortgage insurance (LMI)."
          },
          "payer": {
            "vi": "Bạn trả khi ký hợp đồng, từ tiền tiết kiệm hoặc từ phần vốn (equity) trong một bất động sản khác.",
            "en": "You, when you sign the contract — from savings or equity in another property."
          },
          "drivers": {
            "vi": "Số tiền bạn vay: có thể đặt cọc 10% nhưng sẽ phải trả LMI, và LMI cho khoản vay đầu tư đắt hơn.",
            "en": "How much you borrow: a 10% deposit is possible but adds LMI, which costs more on an investment loan."
          },
          "note": {
            "vi": "Mức dùng để lập kế hoạch — bạn có thể đặt cọc nhiều hoặc ít hơn.",
            "en": "A planning baseline — you can put down more or less."
          },
          "source": 2
        },
        {
          "id": "lmi_none",
          "tier": "CONVENTION",
          "how": {
            "vi": "Không có: với mức đặt cọc {pct}%, khoản vay ở mức 80% giá nhà, và ngân hàng chỉ tính bảo hiểm khoản vay (LMI) khi vay trên 80%.",
            "en": "None: with a {pct}% deposit the loan is 80% of the price, and lenders add mortgage insurance (LMI) only above 80%."
          },
          "payer": {
            "vi": "Nếu có, bạn trả một lần khi settlement (có thể cộng vào khoản vay).",
            "en": "If it applied, you would pay it once, at settlement (it can be added to the loan)."
          },
          "drivers": {
            "vi": "Đặt cọc ít hơn: khi vay trên 80% giá nhà, phí bảo hiểm tăng theo tỷ lệ vay và số tiền vay.",
            "en": "A smaller deposit: above 80% of the price, the premium rises with the share borrowed and the loan size."
          },
          "source": 1
        }
      ]
    },
    "investment_deposit_bands": {
      "note": "CONVENTION — investor deposit bands as % of purchase price; resolver places the cash requirement against the price, adds the sibling-owned acquisition costs",
      "entries": [
        { "scenario": "no_lmi_baseline", "deposit_pct": 20, "lvr_pct": 80, "lmi": "none",                 "tier": "CONVENTION" },
        { "scenario": "with_lmi",        "deposit_pct": "10-12", "lvr_pct": "88-90", "lmi": "applies (higher cost for investment)", "tier": "CONVENTION" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** `deposit_ready_for_purchase` is resolver-computed by placing the banded deposit against the purchase price and summing the acquisition-cost adders owned by the sibling docs — a formula §11.9 keeps in code. This doc owns only the deposit band.
- **Banded, with one regulated boundary.** The deposit bands are lender CONVENTIONS; only the 80% LMI threshold is a regulated capital-treatment line. Flagged accordingly (ACL line — no credit advice).
- **Cross-refs, not duplicates.** Stamp duty, LMI, investor cost adders, entity setup, and the QS report are each owned by their own doc and summed by the resolver; this doc owns the deposit band. The no-FHB-schemes and no-foreign-surcharge facts are owned here as the investor-deposit framing.

## Sources

- ASIC Moneysmart — *Save for a house deposit* (deposit size; 20% to avoid LMI) — https://moneysmart.gov.au/saving/save-for-a-house-deposit
- ASIC Moneysmart — *Lenders mortgage insurance (LMI)* (applies above 80% LVR; one-off cost) — https://moneysmart.gov.au/glossary/lenders-mortgage-insurance-lmi
- ASIC Moneysmart — *Borrowing to invest* (investment-loan deposit and risk considerations) — https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
