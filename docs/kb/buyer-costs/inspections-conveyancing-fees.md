---
slug: kb.buyer-costs.inspections-conveyancing-fees
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://nswlrs.com.au/assets/f/1129775276948026/x/5fed3e7cd6/2026-2027_nsw-lrs-fees_final.pdf
    retrieved: 2026-10-16
    path: docs/sources/nsw/nsw-lrs-fees-2026-27.txt
    quotes:
      - "NSW LRS customer fees from 1 July 2026"
      - "Mortgage *166.60 182.73"
      - "Transfer (pursuant to section 46 Real Property Act) *166.60 182.73"
      - "Title searches (over the counter delivery) 17.00 18.70"
  - url: https://moneysmart.gov.au/home-loans/buying-a-house
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/moneysmart-buying-a-house.txt
    quotes:
      - "Before signing, ask a solicitor or conveyancer to review the contract before signing."
  - url: https://www.nab.com.au/important-information/personal/fees-charges/home-loan
    retrieved: 2026-10-27
    path: docs/sources/existing-home-sale/nab-home-loan-fees.txt
    quotes:
      - "A one-off fee payable when opening the loan NAB Base Variable Rate Home Loan $0"
      - "NAB Flexiplus Mortgage $600"
  - url: https://www.westpac.com.au/personal-banking/home-loans/fees/
    retrieved: 2026-10-16
    path: docs/sources/existing-home-sale/westpac-home-loan-fees.txt
    quotes:
      - "Lending establishment fee $0 $600"
      - "Property valuer fee (may be payable if a valuation is needed) Determined by external valuer's fee"
  - url: https://www.commbank.com.au/content/dam/commbank/personal/apply-online/download-printed-forms/003-750.pdf
    retrieved: 2026-10-27
    path: docs/sources/existing-home-sale/cba-mortgage-lending-fees-2026-07.txt
    quotes:
      - "Simple Home Loan when purchasing an established property Or $800 for"
  - url: https://www.consumer.vic.gov.au/housing/owners-corporations/finance-insurance-and-record-keeping/fees
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/cav-owners-corporation-fees.txt
    quotes:
      - "The value of a fee unit is $17.27 for 2026-27."
      - "Certificate within 6-10 business days 9.64 fee units"
  - url: https://www.consumerprotection.wa.gov.au/property-settlement
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/wa-cp-property-settlement.txt
    quotes:
      - "Unless you are a suitably qualified lawyer, you should use a licensed settlement agent or lawyer."
      - "Settlement agents must disclose their service fees in writing before any agreement."
  - url: https://www.consumerprotection.wa.gov.au/publications/deregulation-fees-settlement-agents-settlement-agents-bulletin-issue-53-january-2016
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/wa-cp-settlement-fee-deregulation.txt
    quotes:
      - "From Wednesday 3 February 2016, regulation of fees will cease."
---

# Buyer-side transaction costs — inspections, conveyancing, and registration fees

Beyond the deposit, [stamp duty](../stamp-duty/calc-by-state.md), and [LMI](../lmi/calculation.md), a buyer faces a cluster of smaller transaction costs at settlement — building & pest inspection, conveyancing, the lender's application fee, the state land-titles registration fees, utility connections, and moving. Individually modest, together they typically add **a few thousand dollars** to the cash needed at settlement. This doc owns the **typical ranges (one `fee_lines` entry per fee) and the regulated per-state registration fees** that ground every `other_buying_costs` line in `cash_position`. First-year building insurance is not a buy line here: it is an Own-phase per-year cost owned by the insurance fee line. It deliberately separates three kinds of figure — **regulated** (state-set, exact), **lender-policy** (varies, drifts), and **convention** (market ranges, not fixed) — because they age differently and the agent must present them differently.

## The regulated costs — land-titles registration fees (per state)

When the buyer takes title and the lender registers its mortgage, the state land-titles registry charges fixed fees. These are **statutory, set per state, and indexed annually (1 July)**. They are the one **exact** part of this doc.

| State | Transfer registration | Mortgage registration | Notes |
|---|---|---|---|
| **NSW** (FY2026–27, eff 1 Jul 2026) | **$182.73** (flat, incl GST) | **$182.73** (flat, incl GST) | NSW LRS dealing fee — flat per dealing, does **not** scale with price |
| **VIC** (FY2025–26, electronic) | **$101.50 + $2.34 per whole $1,000** of consideration, **max $3,611** | **$125.70** | Land Use Victoria, electronic (PEXA) lodgement; paper lodgement is a few dollars higher |
| **QLD** (FY2026–27, eff 1 Jul 2026) | **$248.04 + $46.56 per $10,000** (or part) **over $180,000** | **$248.04** | Titles Queensland; transfer = base lodgement + value-based component |

**Worked anchors:** NSW is **$182.73 + $182.73 = $365.46** at any price. A **VIC $700,000** purchase: transfer $101.50 + $2.34 × 700 = **$1,739.50**, plus mortgage $125.70. A **QLD $600,000** purchase: transfer $248.04 + $46.56 × 42 = **$2,203.56** (42 = ($600,000 − $180,000) ÷ $10,000), plus mortgage $248.04.

## The lender-policy cost — loan application / establishment fee

Lenders charge an **application / establishment / settlement fee** of **$0 to ~$800**, from their own fee schedules: **NAB** charges a $0 application fee on most home loans and $600 on its Flexiplus Mortgage; **Westpac** a $0 lending establishment fee packaged or $600 without a package (plus a $100 document processing fee); **CommBank** a $300 establishment fee on a Simple Home Loan for an established property, or $800 off-the-plan. It is genuinely variable and **lender-specific** — the agent presents the range and notes it is often $0, never a fixed figure or a steer to a particular lender (ASIC: no credit advice).

The lender's **valuation** of the property is often part of the loan application; where a lender charges, Westpac's schedule says only that the fee is "Determined by external valuer's fee". The plan carries **$0–$300** as a **placeholder** — no lender's own schedule publishes a valuation dollar figure read for this doc.

## The convention costs — market ranges, not fixed amounts

These are **placeholder ranges**, not regulated or quoted figures — they vary by provider, property, and location, and no provider's own published price has been read for them yet. The resolver uses them for a base-scope estimate, labelled as placeholders; the actual figures come from the buyer's own quotes. Each is a `fee_lines` entry below whose note names the provider page to re-ground on (behavior 83). A comparison site, directory or blog never grounds them.

- **Building & pest inspection** — placeholder **$450–$1,000** combined; larger, older or inner-city homes cost more, building-only on a unit less. Skippable on a new build, which the agent should flag.
- **Conveyancing / legal** — placeholder **$800–$2,500** professional fee. Searches and certificates are added as disbursements; some are regulated — a NSW title search is $18.70 incl GST over the counter (NSW LRS 2026-27) — and the land-titles registration fees are the separate lookup above. QLD and the ACT are solicitor-only. **Not WA** — see the next line.
- **WA settlement agent** — in Western Australia a licensed **settlement agent** (or a lawyer) does the conveyancing; fees have been deregulated since 3 February 2016 and must be disclosed in writing before appointment. Placeholder **$700–$1,500**.
- **Strata report** — for a strata apartment/townhouse, an inspection-style report on the owners corporation's records, placeholder **$250–$500**. Distinct from the **state-set certificate**: in VIC the owners corporation certificate is capped at 9.64 fee units (fee unit $17.27 in 2026-27, so about $166 before GST, more for a faster issue); NSW's s184 strata information certificate fee is also regulated (Strata Schemes Management Regulation 2016, Sch 4) but was not archived this pass.
- **First-year building insurance** — not a settlement fee line. Lenders require cover from settlement, but it is an Own-phase per-year cost, owned by the insurance fee line elsewhere; for **strata**, building cover sits in the body-corporate levy (`kb.ongoing-costs.rates-water-strata`). Don't double-count.
- **Utility connections** — the move-in (re)connection fee is set by the area's electricity and gas distributor, not the retailer. The plan carries **$0–$210** (electricity plus gas) as a **placeholder** until it is re-grounded on the distributors' own AER-approved fee schedules. Internet set-up and urgent connections are extra.
- **Moving costs** — placeholder **$300–$3,000** for a same-state move depending on volume, distance, and whether professional removalists are used.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **These are the "hidden" costs that surprise first home buyers** — the deposit and stamp duty dominate the conversation, but the cluster above can be **$3,000–$8,000** that a first-timer hasn't budgeted. Surfacing them explicitly in the cash calculator is exactly the planning value, and several are **avoidable or reducible** (skip the building inspection on a new build; shop conveyancing; many lenders waive the application fee) — presented as information, the buyer decides.
- **State choice shifts the registration fees too** — small next to duty, but the per-state structure (NSW flat, VIC/QLD value-scaled) compounds the duty difference when comparing target states.
- **Information, not advice.** Ranges and the regulated fees are shown transparently with assumptions; the doc does not recommend a specific conveyancer, inspector, insurer, or lender.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The `cash_position.other_buying_costs.*` leaves are **resolver-estimated** from the `fee_lines` entries and the per-state registration lookup; the binding figures are the buyer's own quotes and the registry fee at lodgement.

```jsonc
{
  "fills": [],
  "parameters": {
    "registration_fees_indexed_annually":   { "type": "bool",  "value": true, "note": "REGULATED — state land-titles registration fees are reset each 1 July; figures in the lookup are FY-stamped, re-verify annually (drives last_verified)" }
  },
  "lookup": {
    "line_details": {
      "note": "one entry per statement line this doc's figure is placed on (not a fee line); the engine attaches it as the line's detail, filling {params} with the figures it computed (fh_engine_line_detail, behavior 93)",
      "entries": [
        {
          "id": "registration",
          "tier": "REGULATED",
          "how": {
            "vi": "Lệ phí của cơ quan đăng ký đất đai bang {state} để đăng bộ sang tên và đăng ký thế chấp, tính trên {price}.",
            "en": "{state}'s land-titles fees to register the transfer and your mortgage, on {price}."
          },
          "payer": {
            "vi": "Bạn (người mua) trả khi settlement; conveyancer của bạn nộp hồ sơ.",
            "en": "You, the buyer, at settlement; your conveyancer lodges the papers."
          },
          "drivers": {
            "vi": "Bang, và ở VIC, QLD thì cả giá nhà; lệ phí được điều chỉnh mỗi ngày 1/7.",
            "en": "The state, and in VIC and QLD the price; the fees are reset every 1 July."
          },
          "source": {
            "NSW": 0
          }
        }
      ]
    },
    "state_registration_fees": {
      "note": "REGULATED — statutory land-titles registration fees, per state. NSW is flat; VIC and QLD add a value-based component to a base. FY stamped per state (NSW and QLD FY2026-27 effective 1 Jul 2026; VIC FY2025-26, not yet re-grounded for 2026-27). Resolver computes the transfer fee per state's formula.",
      "entries": [
        { "state": "NSW", "fy": "2026-27", "effective_from": "2026-07-01", "gst_inclusive": true,
          "transfer_registration_flat": 182.73,
          "mortgage_registration_flat": 182.73,
          "transfer_scales_with_value": false,
          "note": "NSW LRS dealing fee — flat $182.73 incl GST ($166.60 excl) per dealing from 1 July 2026, independent of price" },
        { "state": "VIC", "fy": "2025-26", "basis": "electronic_pexa_lodgement",
          "transfer_registration_base": 101.50,
          "transfer_registration_per_1000_consideration": 2.34,
          "transfer_registration_max": 3611,
          "mortgage_registration_flat": 125.70,
          "transfer_scales_with_value": true,
          "note": "Land Use Victoria; transfer = 101.50 + 2.34 per whole $1,000 of consideration, capped $3,611 (electronic). Paper lodgement ~$10 higher" },
        { "state": "QLD", "fy": "2026-27", "effective_from": "2026-07-01",
          "transfer_lodgement_base": 248.04,
          "transfer_additional_per_10000_over_threshold": 46.56,
          "transfer_additional_threshold": 180000,
          "mortgage_registration_flat": 248.04,
          "transfer_scales_with_value": true,
          "note": "Titles Queensland; transfer = 248.04 + 46.56 per $10,000 (or part) of consideration over $180,000; mortgage = standard instrument lodgement 248.04" }
      ]
    },
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "conveyancing_buy",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 800, "high": 2500,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on several licensed conveyancers' and solicitors' own published fixed fees for a residential purchase (a firm's own fee page), per state.",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": ["NSW", "VIC", "QLD", "SA", "TAS", "ACT", "NT"],
            "property": "any"
          },
          "optional": false,
          "label":   { "vi": "Phí luật sư / chuyển nhượng (conveyancing)", "en": "Conveyancing / legal" },
          "payer":   { "vi": "Người mua trả cho luật sư hoặc chuyên viên chuyển nhượng (conveyancer) của mình", "en": "The buyer pays their own conveyancer or solicitor" },
          "drivers": { "vi": "Conveyancer có giấy phép thường rẻ hơn luật sư (solicitor); QLD và ACT chỉ luật sư được làm. Nhà strata, mua trên giấy (off-the-plan) hoặc hợp đồng phức tạp đắt hơn. Các phí tra cứu và chứng nhận (disbursements) có thể cộng thêm vài trăm đô; phí đăng ký quyền sở hữu của bang được tính riêng.", "en": "A licensed conveyancer is usually cheaper than a solicitor; in QLD and the ACT only solicitors act. Strata, off-the-plan or complex contracts cost more. Searches and certificates (disbursements) can add a few hundred dollars; the state land-titles registration fees are counted separately." },
          "source": null
        },
        {
          "id": "settlement_agent_wa",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 700, "high": 1500,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on several WA licensed settlement agents' own published fees. WA Consumer Protection grounds the role, the 2016 deregulation and the written fee disclosure, not the band.",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": ["WA"],
            "property": "any"
          },
          "optional": false,
          "label":   { "vi": "Phí đại lý thanh toán (settlement agent) — WA", "en": "Settlement agent (WA)" },
          "payer":   { "vi": "Người mua trả cho đại lý thanh toán (settlement agent) hoặc luật sư của mình", "en": "The buyer pays their own settlement agent or lawyer" },
          "drivers": { "vi": "Ở WA, settlement agent làm thay conveyancer. Phí không còn bị quy định từ 3/2/2016; đại lý phải báo phí tối đa bằng văn bản trước khi nhận việc. Strata, mua trên giấy hoặc giao dịch phức tạp đắt hơn; tra cứu Landgate và phí PEXA có thể cộng thêm.", "en": "In WA a settlement agent does the conveyancing. Fees are deregulated since 3 February 2016; the agent must disclose its maximum fee in writing before appointment. Strata, off-the-plan or complex matters cost more; Landgate searches and PEXA fees can add to it." },
          "source": "https://www.consumerprotection.wa.gov.au/property-settlement"
        },
        {
          "id": "building_pest_inspection",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 450, "high": 1000,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on several building and pest inspectors' own published prices for a pre-purchase combined inspection.",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label":   { "vi": "Kiểm tra nhà và mối mọt (building & pest inspection)", "en": "Building & pest inspection" },
          "payer":   { "vi": "Người mua trả, thường trước khi hợp đồng ràng buộc", "en": "The buyer pays, usually before the contract binds" },
          "drivers": { "vi": "Thành phố lớn (nhất là nội đô Sydney), nhà cũ, nhà rộng hoặc khó tiếp cận thì đắt hơn; căn hộ chỉ kiểm tra kết cấu thì rẻ hơn. Có thể bỏ qua với nhà mới xây.", "en": "Capital-city metro (inner Sydney most), older, larger or hard-to-access homes cost more; a building-only check on a unit costs less. Skippable on a new build." },
          "source": null
        },
        {
          "id": "strata_report",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 250, "high": 500,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on several strata inspection report providers' own published prices. Consumer Affairs Victoria grounds only the separate, regulated VIC owners corporation certificate fee (9.64 fee units at $17.27, 2026-27).",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "strata"
          },
          "optional": false,
          "label":   { "vi": "Báo cáo strata (strata report)", "en": "Strata report" },
          "payer":   { "vi": "Người mua trả", "en": "The buyer pays" },
          "drivers": { "vi": "Tòa nhà lớn, có thang máy, hồ bơi hoặc trên 50 căn thì đắt hơn; cần gấp thì tốn thêm. Khác với giấy chứng nhận của ban quản trị (VIC: owners corporation certificate; NSW: s184 certificate), có phí do bang quy định.", "en": "Larger schemes, lifts, pools or 50+ lots cost more; urgent delivery costs extra. Separate from the owners corporation's certificate (VIC owners corporation certificate, NSW s184 certificate), whose fee the state sets." },
          "source": "https://www.consumer.vic.gov.au/housing/owners-corporations/finance-insurance-and-record-keeping/fees"
        },
        {
          "id": "loan_application_fee",
          "phase": "settle", "timing": "one_off", "tier": "LENDER-POLICY", "basis": "fixed",
          "low": 0, "high": 800,
          "note": "LENDER-POLICY band \u2014 NAB: $0 application fee (Base Variable, Tailored, Choice Package), $600 (Flexiplus Mortgage); Westpac: lending establishment fee $0 packaged, $600 without package; CommBank: establishment fee $300 (Simple Home Loan, established property) or $800 (off-the-plan).",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any", "loan": true
          },
          "optional": false,
          "label":   { "vi": "Phí hồ sơ / thiết lập khoản vay (application / establishment fee)", "en": "Loan application / establishment fee" },
          "payer":   { "vi": "Người vay trả cho ngân hàng; thường được miễn", "en": "The borrower pays the lender; often waived" },
          "drivers": { "vi": "Tùy ngân hàng và sản phẩm: NAB thu $0 với đa số khoản vay và $600 với Flexiplus; Westpac $0 nếu có gói (package) hoặc $600 nếu không; CommBank $300, hoặc $800 khi mua nhà trên giấy (off-the-plan).", "en": "Lender- and product-specific: NAB charges $0 on most home loans and $600 on Flexiplus; Westpac $0 packaged or $600 without; CommBank $300, or $800 off-the-plan." },
          "source": "https://www.commbank.com.au/content/dam/commbank/personal/apply-online/download-printed-forms/003-750.pdf"
        },
        {
          "id": "lender_valuation",
          "phase": "settle", "timing": "one_off", "tier": "LENDER-POLICY", "basis": "fixed",
          "low": 0, "high": 300,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on lenders' own fee schedules that publish a valuation fee (Westpac's says only 'Determined by external valuer's fee').",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any", "loan": true
          },
          "optional": false,
          "label":   { "vi": "Phí định giá của ngân hàng (valuation)", "en": "Lender valuation" },
          "payer":   { "vi": "Thường nằm trong hồ sơ vay và miễn phí; nếu thu thì người vay trả", "en": "Usually included free with the loan application; where charged, the borrower pays" },
          "drivers": { "vi": "Thường đã gồm trong hồ sơ vay; nếu thu thì ngân hàng chuyển phí của người định giá bên ngoài sang người vay. Nhà ở nông thôn, vùng xa hoặc giá trị cao có thể tốn hơn.", "en": "Often included with the application; where charged, the lender passes on the external valuer's fee. Rural, remote or high-value properties can cost more." },
          "source": null
        },
        {
          "id": "utility_connections",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 0, "high": 210,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on the electricity and gas distributors' own AER-approved fee schedules for a move-in (re)connection (e.g. a distributor's annual ancillary-services price list, or the AER's approved pricing).",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label":   { "vi": "Phí kết nối điện, gas khi dọn vào", "en": "Utility connections" },
          "payer":   { "vi": "Người ở trả, qua hóa đơn đầu tiên", "en": "The occupant pays, on the first bill" },
          "drivers": { "vi": "Phí do công ty phân phối điện/gas của khu vực đặt, không phụ thuộc nhà cung cấp bạn chọn; kết nối từ xa qua đồng hồ thông minh có thể miễn phí. Internet và kết nối gấp tính thêm.", "en": "Set by the area's electricity and gas distributor, not the retailer you pick; a remote smart-meter connection can cost nothing. Internet set-up and urgent connections are extra." },
          "source": null
        },
        {
          "id": "moving_costs",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "fixed",
          "low": 300, "high": 3000,
          "note": "PLACEHOLDER \u2014 no primary states this band; re-ground on several removalists' own published prices for a same-state move.",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label":   { "vi": "Chi phí dọn nhà (removalist)", "en": "Moving costs" },
          "payer":   { "vi": "Người mua trả", "en": "The buyer pays" },
          "drivers": { "vi": "Số phòng và đồ đạc, khoảng cách, cầu thang hoặc chỗ đậu xe khó, và có thuê đóng gói hay không. Chuyển liên bang đắt hơn nhiều.", "en": "Number of rooms and volume, distance, stairs or hard parking, and whether packing is hired. An interstate move costs far more." },
          "source": null
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. Each `cash_position.other_buying_costs.*` line is a resolver estimate from these figures; the doc supplies the ranges and the regulated per-state fees, asserting no buyer-specific total.
- **Three provenance tiers, deliberately separated.** The per-state registration fees are **REGULATED** (statutory, exact, indexed annually — the one part the agent can state as fact); `loan_application_fee` and `lender_valuation` are **LENDER POLICY** (vary, often waived — present as a range, never a steer); the inspection/conveyancing/settlement-agent/strata-report/utility/moving lines are **CONVENTION** in kind but their bands are **PLACEHOLDERS** (no provider's own price grounds them yet; each note names the page to re-ground on), as is the `lender_valuation` band. Same tagging discipline as the [lender-treatment docs](../lender/credit-card-treatment.md).
- **Registration-fee FY mismatch is stamped.** NSW (re-grounded 2026-10-16 against the NSW LRS 2026-27 schedule, `docs/sources/nsw/nsw-lrs-fees-2026-27.txt`) and QLD are FY2026–27, effective 1 Jul 2026; VIC is still FY2025–26 (its 2026–27 schedule could not be fetched on 2026-10-16: land.vic.gov.au answered 403). Each entry carries its `fy`/`effective_from`, and `registration_fees_indexed_annually` flags that all three reset each July.
- **VIC 2026-27 is not yet re-grounded.** The VIC entry is still the FY2025–26 Land Use Victoria guide; land.vic.gov.au could not be fetched this pass, so the 2026-27 transfer and mortgage fees are unverified and the FY2025–26 figures stand until the 2026-27 guide is archived and quoted.
- **Building insurance is not here.** It is an Own-phase per-year cost with its own fee line; for strata the building cover is inside the body-corporate levy owned by `kb.ongoing-costs.rates-water-strata`. Single-owner discipline keeps both out of the buy side.
- **`fee_lines` are the one owner of each band (behavior 83).** Each fee a buyer only learns from a quote is a `fee_lines` entry with its band, tier, payer, drivers and source; a band is either drawn from named providers' own published prices (the loan application fee, from NAB, Westpac and CommBank) or a PLACEHOLDER whose note names the primary to re-ground on. The engine reads buy fees only from `fee_lines`, so the old `*_low`/`*_high` parameters that duplicated them are gone; the only parameter left is `registration_fees_indexed_annually`, which flags the regulated lookup. In WA `settlement_agent_wa` replaces `conveyancing_buy`. Utility connections and moving apply to the buyers who move in (modes A, B, E), not to the investor modes.
- **NSW registration is GST-inclusive; VIC/QLD figures are the fee payable.** NSW LRS (a privatised registry) charges GST, so $182.73 is the incl-GST amount the buyer pays. The figure the calculator shows is in each case the amount payable.

## Sources

**Registry fees (REGULATED — confirmed against primary documents in `docs/sources/`):**

- NSW Land Registry Services — *NSW LRS customer fees from 1 July 2026* (Transfer pursuant to s46 RPA and Mortgage each $166.60 excl / $182.73 incl GST) — https://nswlrs.com.au/assets/f/1129775276948026/x/5fed3e7cd6/2026-2027_nsw-lrs-fees_final.pdf (archived text: `docs/sources/nsw/nsw-lrs-fees-2026-27.txt`). Previously FY2025–26: $160.19 excl / $175.70 incl GST.
- Land Use Victoria — *Guide to Transfer of Land Act fees 2025–26* (Transfer on sale s45 electronic: 101.50 + 2.34 per whole $1,000, max 3,611; Mortgage or charge s74 electronic: 125.70) — https://www.land.vic.gov.au/land-registration/fees-guides-and-forms/2025-26-fees (primary: `docs/sources/vic/Guide-to-TLA-fees-2025-2026.docx`)
- Titles Queensland — *FY2026/27 Fees* (Land Title Act 1994: lodging a transfer of ownership for 1 lot $248.04; additional $46.56 per $10,000 or part over $180,000 consideration; any other instrument (e.g. mortgage) $248.04) — https://www.titlesqld.com.au/fees-payments/ (primary: `docs/sources/qld/Titles-Registry-Fees_FY-2026-to-2027.pdf`)

**Fee-line bands — each lender's own fee schedule (LENDER-POLICY):**

- Loan application / establishment fee — NAB, *Home loan and line of credit fees and charges* — https://www.nab.com.au/important-information/personal/fees-charges/home-loan ($0 on most loans; $600 Flexiplus); Westpac, *Home loan fees* — https://www.westpac.com.au/personal-banking/home-loans/fees/ ($0 packaged, $600 without); CommBank, *Fees we charge for consumer mortgage lending products* (003-750, July 2026) — https://www.commbank.com.au/content/dam/commbank/personal/apply-online/download-printed-forms/003-750.pdf ($300; $800 off-the-plan)

**Regulators (the role and the regulated parts, not the bands):**

- ASIC Moneysmart — *Buying a house* (confirms the cost categories: conveyancer/solicitor contract review, building & pest inspection) — https://moneysmart.gov.au/home-loans/buying-a-house
- WA Consumer Protection — *Property settlement*; *Deregulation of fees for settlement agents* (bulletin 53) — the settlement agent's role, the deregulated fee and its written disclosure
- Consumer Affairs Victoria — *Owners corporation fees* — the regulated VIC owners corporation certificate cap
- NSW Land Registry Services 2026-27 fees — the regulated NSW title search ($18.70 incl GST over the counter)

**PLACEHOLDER bands (no primary yet; re-ground on the named provider pages):**

- Conveyancing ($800–$2,500) and WA settlement agent ($700–$1,500) — conveyancers', solicitors' and settlement agents' own published fixed fees
- Building & pest ($450–$1,000) — inspectors' own published prices
- Strata report ($250–$500) — strata report providers' own published prices
- Lender valuation ($0–$300) — a lender's own fee schedule that publishes a valuation fee
- Utility connections ($0–$210) — the distributors' own AER-approved (re)connection fee schedules
- Moving ($300–$3,000) — removalists' own published prices
