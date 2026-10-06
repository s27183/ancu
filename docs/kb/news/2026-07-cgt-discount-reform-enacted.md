---
slug: kb.news.2026-07-cgt-discount-reform-enacted
kb_slug: kb.tax.cgt-50-percent-discount
category: tax
affected_kb_slugs:
  - kb.tax.cgt-50-percent-discount
  - kb.tax.negative-gearing-mechanics
  - kb.tax.entity-comparison-personal-trust-company-smsf
effective_from: 2026-06-26
authored_date: 2026-07-09
sources:
  - url: https://www.legislation.gov.au/C2026A00049/latest/text
    retrieved: 2026-07-06
    path: docs/sources/legislation/treasury-laws-amendment-tax-reform-no-1-act-2026-no49.pdf
  - url: https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=r7493
    retrieved: 2026-07-06
---

## Headline (EN)

CGT reform now law: 50% discount replaced by indexation from 1 Jul 2027

## Headline (VI)

Cải cách CGT đã thành luật: khấu trừ 50% bị thay bằng lập chỉ số từ 1/7/2027

## Summary (EN)

The *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (Act No. 49 of 2026) received **Royal Assent on 26 June 2026**, after passing both Houses on 25 June 2026. It **replaces the 50% CGT discount** for individuals, trusts and partnerships with **cost-base indexation** (tax on the real, inflation-adjusted gain) plus a **30% minimum tax rate** on real capital gains (pensioners exempt) — but it doesn't take effect until **1 July 2027**. The 50% discount remains the applicable law for every disposal up to that date. For an existing holding, the gain accrued up to 1 July 2027 stays taxed under the old 50% rule; the gain accruing after is taxed under the new regime. New-build investors get a choice between the two regimes. This also changes negative-gearing settings (limited to new builds from 1 Jul 2027) and the CGT trade-off between entity types (company/trust/SMSF/individual). If your plan modelled a disposal or entity comparison before 26 June 2026, it was working from a *proposed* reform — it's now enacted law, still with the same 1 July 2027 start date.

## Summary (VI)

*Luật sửa đổi thuế (Cải cách thuế số 1) 2026* (Đạo luật số 49/2026) đã được **Toàn quyền phê chuẩn ngày 26/6/2026**, sau khi được cả hai viện Quốc hội thông qua ngày 25/6/2026. Luật này **thay thế mức khấu trừ 50% thuế lãi vốn (CGT)** đối với cá nhân, quỹ tín thác và hợp danh bằng **lập chỉ số theo giá vốn** (đánh thuế trên phần lãi thực, đã điều chỉnh lạm phát) cùng **mức thuế tối thiểu 30%** trên lãi vốn thực (người hưởng lương hưu được miễn) — nhưng luật này **chưa có hiệu lực cho đến ngày 1/7/2027**. Mức khấu trừ 50% vẫn được áp dụng cho mọi giao dịch bán trước ngày đó. Với tài sản đang nắm giữ, phần lãi phát sinh đến 1/7/2027 vẫn tính theo quy tắc khấu trừ 50% cũ; phần lãi phát sinh sau đó tính theo chế độ mới. Nhà đầu tư mua nhà mới xây được chọn giữa hai chế độ. Thay đổi này cũng ảnh hưởng đến quy định negative gearing (chỉ áp dụng cho nhà mới xây từ 1/7/2027) và bài toán so sánh giữa các loại hình sở hữu (công ty/quỹ tín thác/SMSF/cá nhân). Nếu kế hoạch của bạn từng mô phỏng việc bán tài sản hoặc so sánh loại hình sở hữu trước ngày 26/6/2026, khi đó luật này còn là *đề xuất* — nay đã chính thức thành luật, vẫn giữ nguyên ngày bắt đầu hiệu lực 1/7/2027.

## Diff

```jsonc
{
  "old_value": { "status": "proposed (2026-27 Budget announcement, 12 May 2026)", "regime": "50% CGT discount (individuals/trusts), 33⅓% (SMSF), none (company)" },
  "new_value": { "status": "enacted law (Act No. 49 of 2026, Royal Assent 26 Jun 2026)", "takes_effect": "2027-07-01", "regime_from_effective_date": "cost-base indexation + 30% minimum tax rate on real gains (pensioners exempt); pre-1-Jul-2027 accrued gain still taxed under the old 50% discount; new-build investors may choose either regime", "also_affects": "negative gearing limited to new builds from 1 Jul 2027" }
}
```

Notes:

- **`sources:` reuses the citations already in `kb.tax.cgt-50-percent-discount`'s own frontmatter** (Federal Register of Legislation + APH bill page), unchanged from its 2026-07-06 verify.
- **`affected_kb_slugs` spans three docs** because the same enacted Act touches three distinct KB facts — the CGT discount itself, negative-gearing mechanics, and the entity-comparison CGT row — each of which already carries its own "Enacted reform" section with matching detail.
- **The transition being reported is the enactment event (bill → law), not the 1 Jul 2027 mechanics** — that's still a future date and remains `to_verify` at the resolver. `effective_from` is set to the Royal Assent date (2026-06-26), the date this KB fact actually changed.
- **Immutable once authored.**
