---
slug: kb.facts.property-safeguards
effective_from: 2026-11-04
last_verified: 2026-11-04
sources:
  - url: https://www.registrargeneral.nsw.gov.au/title-guarantee
    retrieved: 2026-11-04
    path: docs/sources/nsw/registrar-general-title-guarantee-2026-11-04.txt
    note: "NSW Registrar General, Title Guarantee — the State guarantees the Torrens title register, backed by the Torrens Assurance Fund."
  - url: https://www.nsw.gov.au/housing-and-construction/land-values-nsw/how-to-find-property-sales-information
    retrieved: 2026-11-04
    path: docs/sources/nsw/how-to-find-property-sales-information-2026-11-04.txt
    note: "NSW Government (Valuer General), How to find property sales information — sale prices from the Notices of Sale, searchable back to 2001."
  - url: https://www.nsw.gov.au/housing-and-construction/property-professionals/supervising-an-agency/real-estate-trust-accounts-and-audit-requirements
    retrieved: 2026-11-04
    path: docs/sources/nsw/real-estate-trust-accounts-2026-11-04.txt
    note: "NSW Government (Fair Trading), Real estate trust accounts and audit requirements — licensees must hold clients' funds in a trust account."
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/contracts-and-deposits
    retrieved: 2026-11-01
    path: docs/sources/nsw/nswgov-contracts-and-deposits.txt
    note: "NSW Government, Contracts and deposits when buying property in NSW — the cooling-off period and electronic settlement."
  - url: https://foreigninvestment.gov.au/getting-started/investment-information/residential
    retrieved: 2026-10-10
    path: docs/sources/firb/residential-real-estate-2026-10-10.txt
    note: "Foreign Investment Review Board, Residential real estate — a foreign person applies before buying; citizens and permanent residents need not."
---

# Why Australia's property market can be trusted — safeguards for /market

The safeguards /market shows (behavior 151): each one sentence that says what its linked government page says, and no more. NSW is the worked example — each state runs its own register, sales records, agent licensing and cooling-off rules; the cooling-off period differs by state (kb.cooling-off.by-state owns the per-state figures). No safeguard is cited to a non-government page: where a state's own site refused an automated fetch (land.vic.gov.au and valuergeneral.nsw.gov.au answered 403, measured 2026-11-04), the NSW Government page that says the same is cited instead. The listing sites /market names are not here: they carry no figure, and are a fixed list in the page.

## Facts

```jsonc
{
  "title": {"en": "Safeguards when you buy", "vi": "Những bảo đảm khi mua nhà"},
  "facts": [
    {
      "id": "title_register",
      "visual": "statement",
      "headline": {"en": "The state's title register records who owns the land, and the state guarantees it",
                   "vi": "Sổ đăng ký quyền sở hữu của bang ghi ai là chủ đất, và bang bảo đảm điều đó"},
      "caption": {"en": "In NSW, the State Government promises that the owners recorded in the Torrens title register are the true owners; a fund backed by that guarantee compensates loss from fraud or error in registration.",
                  "vi": "Ở NSW, Chính phủ bang cam kết người có tên trong sổ đăng ký Torrens là chủ sở hữu thật; một quỹ đứng sau cam kết đó bồi thường thiệt hại do gian lận hoặc sai sót khi đăng ký."},
      "as_of": "2026-11",
      "source": 0,
      "quotes": ["Under the Torrens title system, land title is guaranteed by the State Government.",
                 "In effect, the State Government promises that the registered land owners recorded in the NSW land title system are the true owners of their land.",
                 "The State guarantee of title is backed by the Torrens Assurance Fund (TAF), which provides compensation for any loss suffered as a result of fraud or error in registration."]
    },
    {
      "id": "published_sale_prices",
      "visual": "statement",
      "headline": {"en": "Sale prices are public records you can check yourself",
                   "vi": "Giá bán nhà là hồ sơ công khai, bạn tự tra được"},
      "caption": {"en": "In NSW, sale information comes from the Notices of Sale lodged with the land registry; anyone can search sales by suburb, street or property back to 2001.",
                  "vi": "Ở NSW, thông tin giao dịch lấy từ các Thông báo bán nhà nộp cho cơ quan đăng ký đất đai; ai cũng tra được giá bán theo khu, theo phố hoặc từng căn từ năm 2001."},
      "as_of": "2026-11",
      "source": 1,
      "quotes": ["NSW property sales information comes from Notices of Sale lodged with Land Registry Services",
                 "You can search for suburb, street, or individual property sales dating back to 2001."]
    },
    {
      "id": "licensed_agents_trust_accounts",
      "visual": "statement",
      "headline": {"en": "Licensed agents must keep clients' money in a trust account",
                   "vi": "Môi giới có giấy phép phải giữ tiền của khách trong tài khoản ủy thác"},
      "caption": {"en": "In NSW, agents licensed under the Property and Stock Agents Act 2002 must hold clients' funds in a trust account; the money can be used only for that client, paid out as the client directs.",
                  "vi": "Ở NSW, môi giới có giấy phép theo Luật Property and Stock Agents 2002 phải giữ tiền của khách trong tài khoản ủy thác; tiền đó chỉ dùng cho khách ấy và chỉ chi theo chỉ dẫn của khách."},
      "as_of": "2026-11",
      "source": 2,
      "quotes": ["Licensees under the Property and Stock Agents Act 2002 (the Act) must hold clients’ funds in a trust account.",
                 "Those funds cannot be used for any purpose other than for that client and must be disbursed as the client directs."]
    },
    {
      "id": "cooling_off",
      "visual": "statement",
      "headline": {"en": "A cooling-off period lets you pull out after signing",
                   "vi": "Thời gian cân nhắc cho phép bạn rút lui sau khi ký"},
      "caption": {"en": "In NSW, a buyer of a residential property has 5 business days after exchanging contracts to get out by written notice, paying the seller 0.25% of the price. It does not apply at auction.",
                  "vi": "Ở NSW, người mua nhà ở có 5 ngày làm việc sau khi trao đổi hợp đồng để rút lui bằng thông báo viết, trả người bán 0,25% giá mua. Không áp dụng khi mua đấu giá."},
      "as_of": "2026-11",
      "source": 3,
      "quotes": ["When you buy a residential property in NSW, you have a 5 business day cooling-off period after you exchange contracts.",
                 "During this period, you may get out of the contract as long as you give written notice.",
                 "you will have to pay the vendor 0.25% of the purchase price",
                 "A cooling-off period does not apply if you buy a property at auction"]
    },
    {
      "id": "electronic_settlement",
      "visual": "statement",
      "headline": {"en": "Settlement happens electronically, through a licensed professional",
                   "vi": "Thanh toán và sang tên làm điện tử, qua người hành nghề có giấy phép"},
      "caption": {"en": "In NSW, a lawyer or licensed conveyancer who subscribes to an Electronic Lodgment Network settles for you, after verifying your identity; cheques and paper documents are no longer used.",
                  "vi": "Ở NSW, luật sư hoặc chuyên viên chuyển nhượng (conveyancer) có giấy phép, là thành viên của mạng lưu hồ sơ điện tử, làm thủ tục cho bạn sau khi xác minh danh tính; không còn dùng séc và giấy tờ."},
      "as_of": "2026-11",
      "source": 3,
      "quotes": ["You must engage a lawyer or licensed conveyancer who is a subscriber to an Electronic Lodgment Network to perform the settlement electronically on your behalf.",
                 "so that your identity can be verified",
                 "Cheques and paper documents are no longer required for settlements in NSW."]
    },
    {
      "id": "firb_approval",
      "visual": "statement",
      "headline": {"en": "Foreign buyers apply for approval before they buy",
                   "vi": "Người mua nước ngoài phải xin phép trước khi mua"},
      "caption": {"en": "A foreign person lodges a residential property application with the ATO before buying a home or land; Australian citizens living abroad and permanent residents do not need one.",
                  "vi": "Người nước ngoài nộp đơn xin mua nhà ở cho ATO trước khi mua nhà hoặc đất; công dân Úc sống ở nước ngoài và thường trú nhân thì không cần."},
      "as_of": "2026-10",
      "source": 4,
      "quotes": ["Lodge a residential property application with ato.gov.au before you purchase residential real estate (housing) or land in Australia",
                 "Australian citizens living abroad",
                 "Holders of Australian permanent residency visas"]
    }
  ]
}
```
