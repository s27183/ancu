---
slug: kb.terms.foreign
effective_from: 2026-10-17
last_verified: 2026-10-17
---

# Foreign buyer and cross-border terms — Thuật ngữ cho người mua nước ngoài và chuyển tiền

The terms that decide whether a buyer is foreign, what a foreign owner owes, and the checks money passes on its way from Vietnam to Australia. Each explanation rests on the KB doc its `kb` names, whose sources are the record.

## Terms

```jsonc
{
  "terms": [
    {
      "id": "firb",
      "abbr": "FIRB",
      "name": { "vi": "Phê duyệt đầu tư nước ngoài (FIRB)", "en": "Foreign Investment Review Board" },
      "forms": ["FIRB", "Foreign Investment Review Board", "foreign investment approval", "foreign-investment approval"],
      "meaning": {
        "vi": "FIRB là cơ quan xét duyệt đầu tư nước ngoài. Theo luật Úc, một \"người nước ngoài\" — người không cư trú thường xuyên tại Úc — phải được phê duyệt trước khi mua đất ở, và thường chỉ được mua nhà mới xây hoặc đất trống.",
        "en": "The Foreign Investment Review Board. Under Australian law a \"foreign person\" — someone not ordinarily resident in Australia — needs approval before buying residential land, and generally may buy only new dwellings or vacant land."
      },
      "why": {
        "vi": "Công dân Úc không cần phê duyệt dù sống ở đâu; còn người có visa tạm trú, hay thường trú nhân sống ở nước ngoài, thì phải xin trước khi ký hợp đồng vô điều kiện.",
        "en": "An Australian citizen needs no approval wherever they live; a temporary-visa holder, or a permanent resident living overseas, must get it before signing an unconditional contract."
      },
      "kb": "kb.firb.status-determination"
    },
    {
      "id": "pr",
      "abbr": "PR",
      "name": { "vi": "Thường trú nhân", "en": "Permanent resident" },
      "forms": ["PR", "permanent resident", "permanent residents", "permanent residency", "thường trú nhân"],
      "meaning": {
        "vi": "Người có visa thường trú của Úc — được ở Úc không giới hạn thời gian, dù chưa nhập quốc tịch.",
        "en": "Someone holding an Australian permanent visa — allowed to stay in Australia without a time limit, without being a citizen."
      },
      "why": {
        "vi": "Thường trú nhân sống ở Úc mua nhà như công dân, không cần FIRB; nhưng nếu ở Úc dưới 200 ngày trong 12 tháng qua, họ bị coi là người nước ngoài.",
        "en": "A PR living in Australia buys like a citizen, with no FIRB approval; one who spent fewer than 200 days in Australia in the past 12 months is a foreign person."
      },
      "kb": "kb.firb.status-determination"
    },
    {
      "id": "vacancy_fee",
      "abbr": null,
      "name": { "vi": "Phí bỏ trống", "en": "Vacancy fee" },
      "forms": ["vacancy fee", "vacancy fees", "phí bỏ trống"],
      "meaning": {
        "vi": "Khoản phí hằng năm đánh vào chủ sở hữu nước ngoài nếu căn nhà không có người ở và không thực sự được rao cho thuê ít nhất 183 ngày trong năm. Cho thuê ngắn hạn dưới 30 ngày không được tính.",
        "en": "An annual fee on a foreign owner whose home is neither lived in nor genuinely available to rent for at least 183 days of the year. Short stays of under 30 days do not count."
      },
      "why": {
        "vi": "Bạn phải nộp tờ khai trong 30 ngày sau mỗi năm tính phí; không nộp thì vẫn bị tính phí dù nhà có người ở, và mức phí đã tăng gấp đôi từ 9/4/2024.",
        "en": "You must lodge a return within 30 days of each vacancy year's end — not lodging makes the fee payable even if the home was occupied — and the fee doubled from 9 April 2024."
      },
      "kb": "kb.firb.vacancy-fee-rules-2026"
    },
    {
      "id": "frcgw",
      "abbr": "FRCGW",
      "name": { "vi": "Khấu trừ thuế lãi vốn của người không cư trú", "en": "Foreign resident capital gains withholding" },
      "forms": ["FRCGW", "foreign resident capital gains withholding", "foreign-resident capital gains withholding"],
      "meaning": {
        "vi": "Khi người không cư trú về thuế bán nhà ở Úc, người mua giữ lại 15% giá bán và nộp cho Sở Thuế Úc (ATO). Đây là khoản tạm nộp trước, không phải một loại thuế riêng.",
        "en": "When a foreign resident sells Australian property, the buyer holds back 15% of the price and pays it to the ATO. It is a prepayment, not a separate tax."
      },
      "why": {
        "vi": "Bạn nhận ít hơn 15% tiền bán ngay lúc hoàn tất giao dịch; khoản này được trừ vào thuế lãi vốn thật khi khai thuế, phần dư được hoàn lại.",
        "en": "You receive 15% less at settlement; it is credited against your actual capital gains tax when you lodge your return, and any excess is refunded."
      },
      "kb": "kb.non-resident-tax.foreign-resident-cgt-withholding"
    },
    {
      "id": "sbv",
      "abbr": "SBV",
      "name": { "vi": "Ngân hàng Nhà nước Việt Nam", "en": "State Bank of Vietnam" },
      "forms": ["SBV", "State Bank of Vietnam", "Ngân hàng Nhà nước Việt Nam", "Ngân hàng Nhà nước"],
      "meaning": {
        "vi": "Ngân hàng trung ương Việt Nam. Các quy định của SBV về ngưỡng chuyển tiền và mục đích khai báo phải được đáp ứng trước khi tiền mua nhà được chuyển ra khỏi Việt Nam.",
        "en": "Vietnam's central bank. Its rules on transfer thresholds and declared purpose must be met before money for a purchase can leave Vietnam."
      },
      "why": {
        "vi": "Bước thủ tục phía Việt Nam này thường là khâu chậm và khó đoán nhất, nên cần làm sớm để tiền đến Úc kịp ngày hoàn tất giao dịch.",
        "en": "This Vietnam-side step is often the slowest and least predictable, so starting it early is what gets the money to Australia before settlement."
      },
      "kb": "kb.cross-border-settlement.coordination-best-practices"
    },
    {
      "id": "fx_spread",
      "abbr": "FX",
      "name": { "vi": "Chênh lệch tỷ giá khi đổi tiền", "en": "FX spread" },
      "forms": ["FX", "FX spread", "chênh lệch tỷ giá"],
      "meaning": {
        "vi": "FX là đổi ngoại tệ, ở đây là đổi tiền đồng sang đô Úc. Chênh lệch tỷ giá là khoảng cách giữa tỷ giá bên chuyển tiền cho bạn và tỷ giá thị trường giữa các ngân hàng, cộng phí chuyển — chi phí thật của việc đổi tiền.",
        "en": "FX is foreign exchange — here, turning Vietnamese đồng into Australian dollars. The spread is the gap between the rate a provider gives you and the mid-market rate, plus any transfer fee: the real cost of the conversion."
      },
      "why": {
        "vi": "Chi phí này tính trên toàn bộ số tiền chuyển từ Việt Nam, và qua ngân hàng thường đắt hơn đáng kể so với các dịch vụ chuyển tiền chuyên biệt; con số chính xác chỉ có khi lấy báo giá thực tế.",
        "en": "It applies to the whole sum sent from Vietnam, and a bank transfer typically costs markedly more than a specialist provider; only a live quote gives the exact figure."
      },
      "kb": "kb.fx.typical-spreads-vnd-aud"
    },
    {
      "id": "ecdd",
      "abbr": "ECDD",
      "name": { "vi": "Thẩm định khách hàng tăng cường", "en": "Enhanced customer due diligence" },
      "forms": ["ECDD", "enhanced customer due diligence", "enhanced due diligence", "thẩm định tăng cường"],
      "meaning": {
        "vi": "Bước kiểm tra kỹ hơn mà ngân hàng Úc phải làm với giao dịch rủi ro cao — như một khoản tiền lớn từ nước ngoài hoặc từ người thứ ba — bằng cách hỏi nguồn gốc tiền và yêu cầu giấy tờ chứng minh.",
        "en": "The closer check an Australian bank must run on higher-risk transactions — such as a large transfer from overseas or from a third party — asking where the money came from and for evidence."
      },
      "why": {
        "vi": "Một khoản tiền cha mẹ ở Việt Nam gửi sang gần như chắc chắn sẽ bị thẩm định tăng cường; nếu chưa chuẩn bị giấy tờ, tiền có thể bị giữ lại và trễ ngày hoàn tất giao dịch.",
        "en": "A lump sum from parents in Vietnam is almost certain to trigger it; without the paperwork ready, funds can be held and miss settlement."
      },
      "kb": "kb.au-aml-ctf.bank-due-diligence-expectations"
    },
    {
      "id": "aml_ctf",
      "abbr": "AML/CTF",
      "name": { "vi": "Phòng chống rửa tiền và tài trợ khủng bố", "en": "Anti-money laundering and counter-terrorism financing" },
      "forms": ["AML/CTF", "anti-money laundering", "chống rửa tiền"],
      "meaning": {
        "vi": "Bộ luật buộc ngân hàng và đơn vị chuyển tiền ở Úc xác minh khách hàng, báo cáo các giao dịch chuyển tiền quốc tế và hỏi nguồn gốc của các khoản tiền rủi ro cao.",
        "en": "The law that requires Australian banks and money-transfer providers to identify customers, report international transfers and ask where higher-risk money came from."
      },
      "why": {
        "vi": "Các báo cáo là việc của ngân hàng, không phải của bạn; việc của bạn là có sẵn giấy tờ chứng minh nguồn tiền trước khi chuyển.",
        "en": "The reports are the bank's job, not yours; yours is to have the source-of-funds evidence ready before the money moves."
      },
      "kb": "kb.au-aml-ctf.bank-due-diligence-expectations"
    }
  ]
}
```
