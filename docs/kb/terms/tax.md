---
slug: kb.terms.tax
effective_from: 2026-10-17
last_verified: 2026-10-17
---

# Tax terms — Thuật ngữ về thuế

The Australian taxes and tax rules that touch a home or an investment property over its life: on the gain at sale, on the land each year, on rental losses and building wear, and the structures and office behind them. Each explanation rests on the KB doc its `kb` names, whose sources are the record.

## Terms

```jsonc
{
  "terms": [
    {
      "id": "cgt",
      "abbr": "CGT",
      "name": { "vi": "Thuế lãi vốn", "en": "Capital gains tax" },
      "forms": ["CGT", "capital gains tax", "thuế lãi vốn"],
      "meaning": {
        "vi": "Thuế đánh trên phần lời khi bạn bán một tài sản, kể cả bất động sản.",
        "en": "The tax on the gain when you sell an asset, including property."
      },
      "why": {
        "vi": "Căn nhà bạn ở thường được miễn; nhưng nhà cho thuê, hoặc nhà bán khi bạn là người không cư trú về thuế, thì thường phải chịu.",
        "en": "The home you live in is generally exempt, but a rented property, or a home sold while you are a foreign resident for tax, generally is not."
      },
      "kb": "kb.tax.cgt-main-residence-exemption"
    },
    {
      "id": "main_residence_exemption",
      "abbr": "PPOR",
      "name": { "vi": "Miễn thuế lãi vốn cho nhà ở chính", "en": "Main residence exemption" },
      "forms": ["PPOR", "main residence exemption", "main-residence exemption", "main residence", "main-residence", "miễn thuế nhà ở chính", "miễn thuế lãi vốn cho nhà ở chính", "miễn trừ nhà ở chính"],
      "meaning": {
        "vi": "Khi bán căn nhà là nơi bạn ở trong suốt thời gian sở hữu, không cho thuê và trên đất không quá 2 hecta, bạn thường không phải đóng thuế lãi vốn (CGT).",
        "en": "When you sell a home that was your home for the whole time you owned it, was not rented out and sits on 2 hectares or less, there is generally no capital gains tax (CGT)."
      },
      "why": {
        "vi": "Cho thuê nhà, hoặc chuyển ra nước ngoài và trở thành người không cư trú về thuế khi bán, có thể làm mất một phần hoặc toàn bộ quyền miễn này.",
        "en": "Renting the home out, or moving overseas and being a foreign resident for tax when you sell, can reduce or remove the exemption."
      },
      "kb": "kb.tax.cgt-main-residence-exemption"
    },
    {
      "id": "land_tax",
      "abbr": null,
      "name": { "vi": "Thuế đất", "en": "Land tax" },
      "forms": ["land tax", "land-tax", "thuế đất"],
      "meaning": {
        "vi": "Thuế hằng năm của tiểu bang, tính trên tổng giá trị đất (không tính căn nhà) bạn sở hữu trong tiểu bang đó. Nhà bạn đang ở thường được miễn; đất đầu tư thì phải đóng khi vượt ngưỡng.",
        "en": "An annual state tax on the total value of the land (not the house) you own in that state. Your own home is generally exempt; investment land is taxed above the state's threshold."
      },
      "why": {
        "vi": "Ngưỡng tính trên tổng đất bạn có trong tiểu bang, nên mỗi căn đầu tư thêm có thể đẩy bạn vào diện đóng thuế; chủ sở hữu nước ngoài còn chịu thêm phụ phí ở nhiều tiểu bang.",
        "en": "The threshold applies to all your land in the state combined, so each extra investment property can push you over it, and foreign or absentee owners pay a surcharge in several states."
      },
      "kb": "kb.tax.land-tax-by-state"
    },
    {
      "id": "negative_gearing",
      "abbr": null,
      "name": { "vi": "Khấu trừ lỗ cho thuê (negative gearing)", "en": "Negative gearing" },
      "forms": ["negative gearing", "negative-gearing", "negatively geared"],
      "meaning": {
        "vi": "Khi chi phí của căn nhà cho thuê (kể cả tiền lãi vay) lớn hơn tiền thuê, khoản lỗ đó được trừ vào thu nhập khác như tiền lương, làm giảm thuế bạn phải đóng.",
        "en": "When a rental property's costs, including loan interest, exceed its rent, the loss can be deducted from your other income, such as salary, lowering your tax."
      },
      "why": {
        "vi": "Khoản thuế được giảm là nhờ một khoản lỗ tiền mặt có thật; và theo luật đã ban hành, từ 1/7/2027 nhà đã xây sẵn mua sau đêm công bố Ngân sách (12/5/2026) sẽ không được trừ lỗ vào tiền lương nữa.",
        "en": "The tax saving comes from a real cash loss, and under enacted law, from 1 July 2027 an established property bought after Budget night (12 May 2026) can no longer offset the loss against salary."
      },
      "kb": "kb.tax.negative-gearing-mechanics"
    },
    {
      "id": "depreciation",
      "abbr": null,
      "name": { "vi": "Khấu hao", "en": "Depreciation" },
      "forms": ["depreciation", "depreciation schedule", "khấu hao", "lịch khấu hao", "báo cáo khấu hao"],
      "meaning": {
        "vi": "Khoản khấu trừ thuế không tốn tiền mặt cho căn nhà cho thuê: một phần chi phí xây dựng mỗi năm (Division 43) và sự hao mòn của đồ đạc, thiết bị (Division 40). Thường cần báo cáo của chuyên viên khảo sát khối lượng (quantity surveyor).",
        "en": "Non-cash tax deductions on a rental property: a share of the building's construction cost each year (Division 43) and the wear of fittings and equipment (Division 40). A quantity surveyor's schedule usually backs the claim."
      },
      "why": {
        "vi": "Nhà đã qua sử dụng mua từ 9/5/2017 không được khấu hao đồ đạc cũ đi kèm, và phần khấu hao xây dựng đã trừ sẽ làm tăng phần lời chịu thuế khi bán.",
        "en": "An established home bought from 9 May 2017 cannot claim the second-hand fittings that came with it, and building deductions claimed increase the taxable gain when you sell."
      },
      "kb": "kb.tax.depreciation-division-43-and-40"
    },
    {
      "id": "smsf",
      "abbr": "SMSF",
      "name": { "vi": "Quỹ hưu tự quản", "en": "Self-managed super fund" },
      "forms": ["SMSF", "self-managed super fund", "quỹ hưu tự quản"],
      "meaning": {
        "vi": "Quỹ hưu trí (super) do chính các thành viên tự quản lý, có thể sở hữu bất động sản đầu tư theo luật hưu trí rất chặt chẽ.",
        "en": "A super fund run by its own members, which can hold investment property under strict superannuation law."
      },
      "why": {
        "vi": "Bạn và người thân không được ở hay dùng căn nhà, không được mua nhà từ người có liên quan, và chi phí, thủ tục tuân thủ là cao nhất trong các hình thức sở hữu.",
        "en": "Neither you nor your relatives may live in or use the property, it cannot be bought from a related party, and its cost and compliance are the highest of the ownership options."
      },
      "kb": "kb.tax.entity-comparison-personal-trust-company-smsf"
    },
    {
      "id": "lrba",
      "abbr": "LRBA",
      "name": { "vi": "Khoản vay truy đòi giới hạn của quỹ hưu", "en": "Limited recourse borrowing arrangement" },
      "forms": ["LRBA", "limited recourse borrowing arrangement"],
      "meaning": {
        "vi": "Cách duy nhất để quỹ hưu tự quản (SMSF) vay tiền: tiền vay mua một tài sản duy nhất, đứng tên một quỹ tín thác giữ hộ riêng.",
        "en": "The only way a self-managed super fund may borrow: the loan buys a single asset, held in a separate holding trust."
      },
      "why": {
        "vi": "Nếu không trả được nợ, ngân hàng chỉ được lấy tài sản đó, các tài sản khác của quỹ được bảo vệ — đổi lại, đây là cấu trúc phức tạp và tốn kém nhất.",
        "en": "The lender can claim only that asset, protecting the fund's other assets — at the price of the most complex and costly structure."
      },
      "kb": "kb.tax.entity-comparison-personal-trust-company-smsf"
    },
    {
      "id": "ato",
      "abbr": "ATO",
      "name": { "vi": "Sở Thuế Úc", "en": "Australian Taxation Office" },
      "forms": ["ATO", "Australian Taxation Office", "Sở Thuế Úc"],
      "meaning": {
        "vi": "Cơ quan thuế liên bang của Úc. Ngoài thuế thu nhập, ATO quản lý chương trình First Home Super Saver: xét số tiền được rút và cho phép quỹ hưu trả tiền ra.",
        "en": "Australia's federal tax office. Besides income tax, it runs the First Home Super Saver scheme: it determines how much you can release and authorises your fund to pay it out."
      },
      "why": {
        "vi": "Nhiều bước của bạn đi qua ATO, nên thời gian xử lý của họ cần được tính vào kế hoạch — ví dụ rút tiền FHSS thường mất vài tuần.",
        "en": "Several of your steps go through the ATO, so its processing time belongs in the plan — an FHSS release, for one, typically takes weeks."
      },
      "kb": "kb.scheme.fhss"
    },
    {
      "id": "ppr",
      "abbr": "PPR",
      "name": {
        "vi": "Nơi ở chính (PPR)",
        "en": "Principal place of residence"
      },
      "forms": [
        "PPR",
        "principal place of residence",
        "nơi ở chính"
      ],
      "meaning": {
        "vi": "Căn nhà bạn thực sự sống làm nhà chính. Với thuế đất (land tax), tiểu bang miễn thuế cho đất có nơi ở chính của bạn nếu đáp ứng điều kiện về thời gian ở và quyền sở hữu.",
        "en": "The home you actually live in as your main home. For land tax, the state exempts the land your principal place of residence stands on, if you meet its conditions on occupation and ownership."
      },
      "why": {
        "vi": "Nhà đầu tư chịu thuế đất hằng năm, còn nhà bạn ở thì thường được miễn — nhưng điều kiện (như chỉ được một nơi ở chính) khác nhau giữa các tiểu bang.",
        "en": "An investment property pays land tax every year while the home you live in is usually exempt — but the conditions (such as having only one principal place of residence) differ between states."
      },
      "url": "https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/exemptions-and-concessions/principal-place-of-residence"
    }
  ]
}
```
