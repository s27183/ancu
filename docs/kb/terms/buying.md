---
slug: kb.terms.buying
effective_from: 2026-10-17
last_verified: 2026-10-17
---

# Buying terms — Thuật ngữ khi mua nhà

The words of the purchase itself: the duties paid on it, the legal transfer and its completion, the buyer's window to withdraw, the checks done on the property, and the professionals who help. Each explanation rests on the KB doc its `kb` names, whose sources are the record.

## Terms

```jsonc
{
  "terms": [
    {
      "id": "stamp_duty",
      "abbr": null,
      "name": { "vi": "Thuế trước bạ", "en": "Stamp duty" },
      "forms": ["stamp duty", "stamp-duty", "transfer duty", "land transfer duty", "thuế trước bạ"],
      "meaning": {
        "vi": "Thuế của tiểu bang đánh khi bạn mua nhà (còn gọi là transfer duty), tính theo biểu thuế lũy tiến trên giá mua hoặc giá thị trường, lấy số cao hơn.",
        "en": "A state tax on buying property (also called transfer duty), charged on a sliding scale on the price or the market value, whichever is higher."
      },
      "why": {
        "vi": "Với đa số người mua lần đầu, đây là khoản lớn nhất trong số tiền cần có khi hoàn tất giao dịch; nếu đủ điều kiện, bạn có thể được giảm hoặc miễn, tùy tiểu bang.",
        "en": "For most first home buyers it is the largest line in the cash needed at settlement; if you are eligible, a state concession can reduce or remove it."
      },
      "kb": "kb.stamp-duty.calc-by-state"
    },
    {
      "id": "foreign_purchaser_surcharge",
      "abbr": null,
      "name": { "vi": "Phụ phí người mua nước ngoài", "en": "Foreign purchaser surcharge" },
      "forms": ["foreign-buyer surcharge", "foreign buyer surcharge", "foreign purchaser surcharge", "foreign purchaser additional duty", "surcharge purchaser duty", "AFAD", "additional foreign acquirer duty", "phụ phí người mua nước ngoài", "phụ phí dành cho người mua nước ngoài"],
      "meaning": {
        "vi": "Khoản thuế trước bạ cộng thêm mà người nước ngoài trả một lần khi mua nhà ở, tính theo phần trăm giá trị căn nhà, nộp khi hoàn tất giao dịch cùng với thuế trước bạ thông thường.",
        "en": "An extra stamp duty a foreign person pays once when buying a home, a percentage of the property's value, due at settlement on top of the standard duty."
      },
      "why": {
        "vi": "Mức phụ phí khác nhau theo tiểu bang (ACT và NT không thu) và không được giảm bởi ưu đãi cho người mua nhà lần đầu, nên đây thường là khoản lớn nhất sau tiền đặt cọc với người mua nước ngoài.",
        "en": "The rate differs by state (ACT and NT charge none) and no first-home concession reduces it, so for a foreign buyer it is often the largest one-off cost after the deposit."
      },
      "kb": "kb.foreign-buyer-surcharge.by-state"
    },
    {
      "id": "conveyancing",
      "abbr": null,
      "name": { "vi": "Thủ tục chuyển nhượng (conveyancing)", "en": "Conveyancing" },
      "forms": ["conveyancing", "conveyancer", "conveyancers", "chuyên viên chuyển nhượng", "luật sư chuyển nhượng"],
      "meaning": {
        "vi": "Phần việc pháp lý của giao dịch mua bán — rà soát hợp đồng, tra cứu hồ sơ và lo thủ tục sang tên — do chuyên viên chuyển nhượng (conveyancer) có giấy phép hoặc luật sư đảm nhận.",
        "en": "The legal work of a purchase — reviewing the contract, searches and transferring the title — done by a licensed conveyancer or a solicitor."
      },
      "why": {
        "vi": "Bạn không tự làm settlement; người này điều phối nó. Ở QLD và ACT chỉ luật sư được làm, còn ở WA là settlement agent.",
        "en": "You do not run settlement yourself; they coordinate it — and in QLD and the ACT only a solicitor may act, while in WA a settlement agent does it."
      },
      "kb": "kb.buyer-costs.inspections-conveyancing-fees"
    },
    {
      "id": "settlement",
      "abbr": null,
      "name": { "vi": "Hoàn tất giao dịch (settlement)", "en": "Settlement" },
      "forms": ["settlement", "hoàn tất giao dịch"],
      "meaning": {
        "vi": "Thời điểm giao dịch mua hoàn tất về mặt pháp lý: phần tiền còn lại được trả cho người bán, khoản thế chấp được đăng ký và quyền sở hữu chuyển sang bạn.",
        "en": "The moment the purchase legally completes: the rest of the price is paid to the seller, the mortgage is registered and the title passes to you."
      },
      "why": {
        "vi": "Mọi việc — duyệt vay chính thức, chuyển tiền, kiểm tra — phải xong trước ngày này; ở QLD, trễ ngày settlement có thể khiến người bán hủy hợp đồng và giữ tiền cọc.",
        "en": "Finance, funds and checks must all be ready by this date; in QLD, missing it can let the seller end the contract and keep the deposit."
      },
      "kb": "kb.settlement.process-by-state"
    },
    {
      "id": "cooling_off",
      "abbr": null,
      "name": { "vi": "Thời gian cân nhắc rút lui", "en": "Cooling-off period" },
      "forms": ["cooling-off", "cooling-off period", "cooling off", "thời gian cân nhắc rút lui", "thời gian cân nhắc"],
      "meaning": {
        "vi": "Vài ngày làm việc ngắn ngủi sau khi ký hợp đồng mua theo thương lượng, trong đó bạn được rút lui và chỉ mất một khoản phạt nhỏ thay vì cả tiền cọc. Độ dài và mức phạt do luật từng tiểu bang quy định.",
        "en": "A short window of business days after signing a private-sale contract in which you may withdraw, losing only a small penalty rather than the deposit. Its length and penalty are set by each state's law."
      },
      "why": {
        "vi": "Mua đấu giá thì không có thời gian cân nhắc, nên mọi kiểm tra và việc duyệt vay phải xong trước khi trả giá.",
        "en": "There is none at auction, so every check and your finance must be done before you bid."
      },
      "kb": "kb.cooling-off.by-state"
    },
    {
      "id": "strata",
      "abbr": null,
      "name": { "vi": "Strata (nhà chung cư/khu nhà chung)", "en": "Strata" },
      "forms": ["strata", "strata scheme", "owners corporation", "body corporate"],
      "meaning": {
        "vi": "Hình thức sở hữu căn hộ hoặc nhà phố trong một khu chung: bạn sở hữu căn của mình, còn phần chung do ban quản trị (strata ở NSW, owners corporation ở VIC, body corporate ở QLD) quản lý bằng tiền phí các chủ nhà đóng.",
        "en": "Ownership of an apartment or townhouse in a shared scheme: you own your lot, and the common property is run by the scheme (strata in NSW, owners corporation in VIC, body corporate in QLD) from the levies owners pay."
      },
      "why": {
        "vi": "Nếu quỹ bảo trì của khu không đủ, chủ nhà có thể phải đóng thêm một khoản phí đặc biệt lớn; phí hằng kỳ thấp chưa chắc đã là điều tốt.",
        "en": "If the scheme's works fund is short, owners can face a large special levy, so a low regular levy is not automatically good."
      },
      "kb": "kb.strata.health-indicators"
    },
    {
      "id": "strata_report",
      "abbr": null,
      "name": { "vi": "Báo cáo strata", "en": "Strata report" },
      "forms": ["strata report", "strata reports", "strata search", "báo cáo strata"],
      "meaning": {
        "vi": "Bản rà soát hồ sơ của ban quản trị khu nhà — biên bản họp, tài chính, quỹ bảo trì, bảo hiểm và nội quy — làm trước khi mua.",
        "en": "A review of the scheme's records — meeting minutes, finances, the works fund, insurance and by-laws — done before you buy."
      },
      "why": {
        "vi": "Báo cáo cho thấy trước các khoản phí đặc biệt sắp tới, lỗi công trình, tranh chấp, hay nội quy cấm nuôi thú cưng hoặc cho thuê ngắn hạn.",
        "en": "It shows coming special levies, building defects, disputes, and by-laws that may limit pets, renovation or short-stay letting."
      },
      "kb": "kb.strata-report.red-flags"
    },
    {
      "id": "building_pest",
      "abbr": null,
      "name": { "vi": "Kiểm tra nhà và mối mọt", "en": "Building and pest inspection" },
      "forms": ["building and pest inspection", "building and pest inspections", "building and pest", "pest inspection", "pest inspections", "timber pest inspection", "kiểm tra nhà và mối mọt", "kiểm tra công trình và mối mọt", "kiểm tra nhà và mối", "kiểm tra nhà và kiểm tra mối"],
      "meaning": {
        "vi": "Hai lần kiểm tra bằng mắt riêng biệt: một về kết cấu và an toàn của căn nhà, một về mối và các loài hại gỗ. Báo cáo ghi nhận lỗi nhưng không báo giá sửa chữa.",
        "en": "Two separate visual inspections: one of the building's structure and safety, one for termites and other timber pests. The reports flag problems; they do not price repairs."
      },
      "why": {
        "vi": "Nhà đã qua sử dụng không có bảo hành của nhà thầu, nên các báo cáo này là lớp bảo vệ chính của bạn — cần làm trong thời gian cân nhắc, hoặc trước khi đấu giá.",
        "en": "An established home has no builder's warranty, so these reports are your main protection — done within the cooling-off period, or before an auction."
      },
      "kb": "kb.building-pest.interpretation"
    },
    {
      "id": "title_registration",
      "abbr": null,
      "name": { "vi": "Đăng bộ sang tên", "en": "Title registration" },
      "forms": ["title registration", "title registered", "đăng bộ"],
      "meaning": {
        "vi": "Việc cơ quan đăng ký đất đai của tiểu bang ghi nhận bạn là chủ sở hữu mới và ghi nhận khoản thế chấp của ngân hàng. Lệ phí do tiểu bang quy định và điều chỉnh mỗi năm.",
        "en": "The state land-titles office recording you as the new owner and recording the lender's mortgage. The fees are set by each state and indexed every year."
      },
      "why": {
        "vi": "Đây là phần chi phí mua chính xác duy nhất trong nhóm phí giao dịch nhỏ; ở NSW phí cố định, còn ở VIC và QLD tăng theo giá nhà.",
        "en": "It is the one exact figure among the smaller buying costs; NSW charges a flat fee, while VIC and QLD scale with the price."
      },
      "kb": "kb.buyer-costs.inspections-conveyancing-fees"
    },
    {
      "id": "buyers_agent",
      "abbr": null,
      "name": { "vi": "Đại lý mua nhà", "en": "Buyer's agent" },
      "forms": ["buyer's agent", "buyer’s agent", "buyers agent", "buyer's agents", "buyer's advocate", "đại lý mua nhà"],
      "meaning": {
        "vi": "Người bạn thuê để tìm nhà và thương lượng giá thay bạn (ở VIC gọi là buyer's advocate). Phí không do luật quy định mà được thỏa thuận — cố định hoặc theo phần trăm giá nhà.",
        "en": "A professional you hire to find a property and negotiate for you (a buyer's advocate in VIC). The fee is not set by law but agreed — a fixed fee or a percentage of the price."
      },
      "why": {
        "vi": "Khác với môi giới vay, bạn tự trả phí cho đại lý mua nhà, và việc dùng họ là tùy bạn.",
        "en": "Unlike a mortgage broker, you pay them yourself, and using one is entirely optional."
      },
      "kb": "kb.buyer-costs.broker-and-buyers-agent"
    }
  ]
}
```
