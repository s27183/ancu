---
slug: kb.terms.loan
effective_from: 2026-10-17
last_verified: 2026-10-17
---

# Loan terms — Thuật ngữ về khoản vay

The home-loan words the plan uses: what the lender insures, how it tests what you can borrow, how the loan is structured, the debts that count against you, and the people and steps around the loan. Each explanation rests on the KB doc its `kb` names, whose sources are the record.

## Terms

```jsonc
{
  "terms": [
    {
      "id": "lmi",
      "abbr": "LMI",
      "name": { "vi": "Bảo hiểm khoản vay", "en": "Lenders mortgage insurance" },
      "forms": ["LMI", "lenders mortgage insurance", "lender's mortgage insurance", "bảo hiểm khoản vay", "bảo hiểm thế chấp"],
      "meaning": {
        "vi": "Khoản phí bảo hiểm trả một lần khi bạn vay trên 80% giá trị căn nhà. Phí tăng theo tỷ lệ vay và số tiền vay, và thường có thể cộng vào khoản vay.",
        "en": "A one-off insurance premium charged when you borrow more than 80% of the property's value. It rises with the share you borrow and the loan size, and can usually be added to the loan."
      },
      "why": {
        "vi": "Bảo hiểm này bảo vệ ngân hàng, không phải bạn; bạn trả khi vay trên 80% giá nhà.",
        "en": "It protects the lender, not you, yet you pay it whenever you borrow more than 80% of the price."
      },
      "kb": "kb.lmi.calculation"
    },
    {
      "id": "lvr",
      "abbr": "LVR",
      "name": { "vi": "Tỷ lệ vay trên giá trị", "en": "Loan-to-value ratio" },
      "forms": ["LVR", "loan-to-value ratio", "loan-to-value", "tỷ lệ vay trên giá trị", "tỷ lệ vay"],
      "meaning": {
        "vi": "Số tiền bạn còn nợ chia cho giá trị căn nhà. Khi bạn trả nợ dần và giá nhà tăng, tỷ lệ này giảm xuống.",
        "en": "Your loan balance divided by the property's value. It falls as you repay the loan and as the property's value rises."
      },
      "why": {
        "vi": "Mốc 80% là ranh giới: trên 80% thì phải trả LMI; khi xuống dưới 80%, không ngân hàng nào đòi LMI nữa và bảo lãnh FHG cũng hết vai trò.",
        "en": "80% is the line: above it you pay LMI; once it drops below 80%, no lender charges LMI and a First Home Guarantee has done its job."
      },
      "kb": "kb.graduation.lvr80"
    },
    {
      "id": "serviceability",
      "abbr": null,
      "name": { "vi": "Khả năng trả nợ", "en": "Serviceability" },
      "forms": ["serviceability", "serviceability test", "khả năng trả nợ"],
      "meaning": {
        "vi": "Phép thử của ngân hàng xem bạn có trả nổi khoản vay không: thu nhập được tính, trừ chi phí sinh hoạt và các khoản nợ khác, phải đủ trả góp ở mức lãi suất đã cộng thêm biên an toàn.",
        "en": "The lender's test of whether you can afford the loan: your counted income, less living costs and other debts, must cover the repayments at a buffered interest rate."
      },
      "why": {
        "vi": "Chính phép thử này quyết định bạn vay được bao nhiêu — thường chặt hơn cả số tiền đặt cọc bạn có.",
        "en": "This test, more often than your deposit, decides how much you can borrow."
      },
      "kb": "kb.lender.serviceability-basics"
    },
    {
      "id": "borrowing_capacity",
      "abbr": null,
      "name": { "vi": "Khả năng vay", "en": "Borrowing capacity" },
      "forms": ["borrowing capacity", "borrowing power", "khả năng vay"],
      "meaning": {
        "vi": "Số tiền tối đa một ngân hàng sẵn sàng cho bạn vay, tính từ thu nhập, chi phí sinh hoạt và các khoản nợ hiện có qua phép thử khả năng trả nợ (serviceability).",
        "en": "The most a lender is willing to lend you, worked out from your income, living costs and existing debts through its serviceability test."
      },
      "why": {
        "vi": "Con số này khác nhau giữa các ngân hàng và thường thấp hơn bạn nghĩ, vì ngân hàng tính ở lãi suất cao hơn lãi suất thật và trừ cả HECS, hạn mức thẻ tín dụng.",
        "en": "It differs between lenders and is often lower than expected, because lenders test at a higher rate than you will pay and count HECS and credit-card limits."
      },
      "kb": "kb.lender.serviceability-basics"
    },
    {
      "id": "apra_buffer",
      "abbr": "APRA",
      "name": { "vi": "Biên đệm lãi suất của APRA", "en": "APRA serviceability buffer" },
      "forms": ["APRA", "APRA serviceability buffer", "serviceability buffer", "biên đệm khả năng trả nợ"],
      "meaning": {
        "vi": "APRA là cơ quan quản lý ngân hàng của Úc. Quy định của APRA buộc ngân hàng xét hồ sơ vay ở lãi suất cao hơn lãi suất sản phẩm ít nhất 3 điểm phần trăm — ví dụ lãi suất 6% thì được xét như 9%.",
        "en": "APRA is Australia's banking regulator. Its rule makes lenders assess a loan at least 3 percentage points above the product rate — a 6% loan is assessed as if it were 9%."
      },
      "why": {
        "vi": "Biên đệm này, chứ không phải lãi suất bạn thực trả, đặt ra mức bạn vay được; lãi suất giảm cũng không tự làm bạn vay được nhiều hơn.",
        "en": "The buffer, not the rate you actually pay, sets how much you can borrow, so a rate cut does not by itself lift it."
      },
      "kb": "kb.lender.serviceability-basics"
    },
    {
      "id": "dti",
      "abbr": "DTI",
      "name": { "vi": "Tỷ lệ nợ trên thu nhập", "en": "Debt-to-income ratio" },
      "forms": ["DTI", "debt-to-income", "debt-to-income ratio", "tỷ lệ nợ trên thu nhập", "nợ trên thu nhập"],
      "meaning": {
        "vi": "Tổng nợ của bạn chia cho tổng thu nhập trước thuế. APRA xếp khoản vay có tổng nợ từ 6 lần thu nhập trở lên vào nhóm nợ cao, và ngân hàng giới hạn tỷ trọng các khoản vay này.",
        "en": "Your total debt divided by your gross income. APRA treats lending at 6 times income or more as high-DTI, and lenders limit how many such loans they write."
      },
      "why": {
        "vi": "Dù đã qua phép thử khả năng trả nợ, hồ sơ gần mức 6 lần thu nhập vẫn có thể bị chính sách DTI của ngân hàng giới hạn.",
        "en": "A borrower near 6 times income can pass the serviceability test and still be held back by the lender's DTI policy."
      },
      "kb": "kb.lender.serviceability-basics"
    },
    {
      "id": "hem",
      "abbr": "HEM",
      "name": { "vi": "Chuẩn chi tiêu hộ gia đình", "en": "Household Expenditure Measure" },
      "forms": ["HEM", "Household Expenditure Measure"],
      "meaning": {
        "vi": "Mức chi phí sinh hoạt chuẩn do Melbourne Institute công bố, thay đổi theo thu nhập, nơi ở và số người trong nhà. Ngân hàng lấy số lớn hơn giữa chi phí bạn khai và mức chuẩn này.",
        "en": "A living-costs benchmark published by the Melbourne Institute that varies with income, location and household size. Lenders use the higher of your declared expenses and this benchmark."
      },
      "why": {
        "vi": "Khai chi tiêu thấp không giúp bạn vay nhiều hơn, vì ngân hàng không tính dưới mức chuẩn này.",
        "en": "Declaring very low spending does not raise how much you can borrow, because the lender will not go below this benchmark."
      },
      "kb": "kb.lender.hem-living-expenses"
    },
    {
      "id": "offset_account",
      "abbr": null,
      "name": { "vi": "Tài khoản offset", "en": "Offset account" },
      "forms": ["offset account", "offset accounts", "offset strategy", "tài khoản offset", "chiến lược offset", "offset toàn phần"],
      "meaning": {
        "vi": "Tài khoản giao dịch gắn với khoản vay; số dư trong đó được trừ vào dư nợ trước khi tính lãi. Ví dụ 30.000 đô trong offset với khoản vay 500.000 đô thì chỉ tính lãi trên 470.000 đô, và tiền vẫn rút ra được bất cứ lúc nào.",
        "en": "An everyday account linked to the loan whose balance is subtracted from the loan before interest is charged — $30,000 in offset against a $500,000 loan means interest on $470,000 — and the money stays yours to use."
      },
      "why": {
        "vi": "Tiền dự phòng để trong offset vừa sẵn sàng dùng vừa giảm tiền lãi, nhưng gói vay có offset thường kèm phí hằng năm, nên chỉ có lợi khi số dư đủ lớn.",
        "en": "A cash reserve held there stays at hand and cuts interest, though offset loans often carry an annual package fee that only a large enough balance outweighs."
      },
      "kb": "kb.offset-account.basics"
    },
    {
      "id": "interest_only",
      "abbr": null,
      "name": { "vi": "Chỉ trả lãi", "en": "Interest-only" },
      "forms": ["interest-only", "interest only", "chỉ trả lãi"],
      "meaning": {
        "vi": "Trong một giai đoạn (thường tới 5 năm) bạn chỉ trả tiền lãi, nên khoản trả hằng tháng thấp hơn nhưng dư nợ không giảm. Hết giai đoạn đó, khoản vay chuyển sang trả cả gốc và lãi trong thời hạn còn lại.",
        "en": "For a set period (commonly up to 5 years) repayments cover interest only, so they are lower but the loan does not shrink. When the period ends the loan switches to principal and interest over the remaining term."
      },
      "why": {
        "vi": "Khi giai đoạn chỉ trả lãi kết thúc, khoản trả hằng tháng tăng mạnh; và hình thức này không giúp bạn vay được nhiều hơn.",
        "en": "Repayments step up sharply when the interest-only period ends, and it does not raise how much you can borrow."
      },
      "kb": "kb.loan.interest-only-vs-pi-investor"
    },
    {
      "id": "principal_and_interest",
      "abbr": null,
      "name": { "vi": "Trả cả gốc và lãi", "en": "Principal and interest" },
      "forms": ["principal and interest", "principal-and-interest", "gốc và lãi"],
      "meaning": {
        "vi": "Mỗi kỳ bạn trả cả tiền lãi và một phần tiền gốc, nên dư nợ giảm dần ngay từ đầu.",
        "en": "Each repayment covers the interest and part of the loan itself, so the balance falls from the start."
      },
      "why": {
        "vi": "Khoản trả hằng tháng cao hơn chỉ trả lãi, nhưng bạn tích lũy được phần sở hữu nhà và tổng tiền lãi cả đời khoản vay thấp hơn.",
        "en": "Repayments are higher than interest-only, but you build equity and pay less interest over the life of the loan."
      },
      "kb": "kb.loan.interest-only-vs-pi-investor"
    },
    {
      "id": "pre_approval",
      "abbr": null,
      "name": { "vi": "Duyệt vay sơ bộ", "en": "Pre-approval" },
      "forms": ["pre-approval", "pre-approvals", "pre-approved", "duyệt vay sơ bộ", "duyệt vay đầu tư sơ bộ"],
      "meaning": {
        "vi": "Ngân hàng xem qua tài chính của bạn và cho biết họ có khả năng cho vay, kèm điều kiện — thường là định giá căn nhà đạt yêu cầu và xác minh thu nhập, chi tiêu.",
        "en": "The lender reviews your finances and indicates it is likely to lend, subject to conditions — typically a satisfactory valuation of the property and verified income and expenses."
      },
      "why": {
        "vi": "Duyệt sơ bộ giúp bạn biết ngân sách khi đi xem nhà, nhưng chưa phải đã có vốn vay: chỉ khi ngân hàng duyệt chính thức (vô điều kiện) thì điều kiện vay trong hợp đồng mới được đáp ứng.",
        "en": "It tells you your budget before you search, but it is not secured finance: only unconditional approval satisfies the contract's finance condition."
      },
      "kb": "kb.lender-docs.standard-timeline"
    },
    {
      "id": "bnpl",
      "abbr": "BNPL",
      "name": { "vi": "Mua trước trả sau", "en": "Buy now, pay later" },
      "forms": ["BNPL", "buy now, pay later", "buy now pay later", "buy-now-pay-later", "mua trước trả sau", "mua-trả-sau"],
      "meaning": {
        "vi": "Các dịch vụ trả góp như Afterpay, Zip. Từ ngày 10/6/2025, BNPL là tín dụng được quản lý và hiện lên trong hồ sơ tín dụng của bạn.",
        "en": "Instalment services such as Afterpay and Zip. Since 10 June 2025 BNPL is regulated credit and shows on your credit report."
      },
      "why": {
        "vi": "Ngân hàng giờ tính BNPL vào khả năng trả nợ, nên dù chỉ vài trăm đô mỗi tháng cũng có thể làm giảm số tiền bạn vay được hàng chục nghìn đô.",
        "en": "Lenders now count it, so even a couple of hundred dollars a month can cut what you can borrow by tens of thousands."
      },
      "kb": "kb.lender.bnpl-treatment-2026"
    },
    {
      "id": "hecs_help",
      "abbr": "HECS-HELP",
      "name": { "vi": "Nợ vay học phí HECS-HELP", "en": "HECS-HELP study loan" },
      "forms": ["HECS", "HECS/HELP", "HECS-HELP"],
      "meaning": {
        "vi": "Khoản vay học đại học của chính phủ Úc, được trả dần qua hệ thống thuế khi thu nhập vượt một ngưỡng nhất định.",
        "en": "A government university loan, repaid through the tax system once your income passes a threshold."
      },
      "why": {
        "vi": "Ngân hàng coi khoản trả HECS bắt buộc là một khoản chi cố định, nên nó làm giảm số tiền bạn vay được — mức giảm tùy theo thu nhập, không theo số dư nợ.",
        "en": "Lenders treat the compulsory repayment as a fixed commitment, so it reduces what you can borrow — by an amount that follows your income, not your balance."
      },
      "kb": "kb.hecs.thresholds"
    },
    {
      "id": "mortgage_broker",
      "abbr": null,
      "name": { "vi": "Chuyên viên môi giới vay", "en": "Mortgage broker" },
      "forms": ["mortgage broker", "mortgage brokers", "môi giới vay", "chuyên viên môi giới vay"],
      "meaning": {
        "vi": "Người so sánh các ngân hàng và lo hồ sơ vay giúp bạn. Từ 1/1/2021, môi giới vay phải hành động vì lợi ích tốt nhất của khách hàng.",
        "en": "A professional who compares lenders and arranges the loan for you. Since 1 January 2021 brokers must act in the customer's best interests."
      },
      "why": {
        "vi": "Môi giới vay thường được ngân hàng trả hoa hồng nên bạn thường không mất phí; nếu họ thu phí trực tiếp, bạn phải ký báo giá trước.",
        "en": "Lenders usually pay the broker a commission, so you typically pay nothing; any direct fee needs a quote you sign first."
      },
      "kb": "kb.buyer-costs.broker-and-buyers-agent"
    },
    {
      "id": "mortgage_discharge",
      "abbr": null,
      "name": { "vi": "Giải chấp (tất toán khoản vay)", "en": "Mortgage discharge" },
      "forms": ["mortgage discharge", "discharge of mortgage", "release of mortgage", "discharge fee", "giải chấp", "tất toán khoản vay"],
      "meaning": {
        "vi": "Trả hết và đóng khoản vay thế chấp bằng căn nhà, thường làm khi bán nhà. Ngân hàng cần được báo trước để xử lý.",
        "en": "Paying out and closing the mortgage secured on a property, usually when you sell it. The lender needs notice to process it."
      },
      "why": {
        "vi": "Khi bán nhà, khoản nợ còn lại và phí giải chấp được trừ thẳng vào tiền bán; khoản vay lãi suất cố định tất toán sớm còn có thể bị phí phá vỡ hợp đồng.",
        "en": "When you sell, the remaining loan and the discharge fee come out of the sale money, and a fixed-rate loan ended early can add a break cost."
      },
      "kb": "kb.existing-home-sale.net-proceeds"
    }
  ]
}
```
