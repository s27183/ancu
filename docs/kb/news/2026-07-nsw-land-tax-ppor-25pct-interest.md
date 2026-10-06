---
slug: kb.news.2026-07-nsw-land-tax-ppor-25pct-interest
kb_slug: kb.land-tax.ppor-exemption
category: tax
affected_kb_slugs:
  - kb.land-tax.ppor-exemption
effective_from: 2025-01-01
authored_date: 2026-07-09
sources:
  - url: https://www.revenue.nsw.gov.au/taxes-duties-levies-royalties/land-tax/exemptions-and-concessions/principal-place-of-residence
    retrieved: 2026-07-06
---

## Headline (EN)

NSW land-tax PPOR exemption now requires a ≥25% ownership interest

## Headline (VI)

Miễn thuế đất PPOR tại NSW nay yêu cầu sở hữu tối thiểu 25%

## Summary (EN)

NSW's principal-place-of-residence (PPOR) land-tax exemption gained a **new eligibility condition** from the **2025 land tax year**: the owner claiming the exemption must hold **at least a 25% interest** in the land, in addition to the existing conditions (natural person, continuous occupation since 1 July before the 31 December taxing date, only one PPR worldwide). Previously there was no explicit minimum-interest threshold. This matters most for co-ownership structures — a buyer with a small minority stake (for example, a family member added to title for lending or estate reasons) could now fall short of the exemption on that basis alone, even while genuinely living in the home. If your plan assumed automatic `exempt_ppor` status for a NSW co-ownership arrangement, the ownership split should now be checked against this 25% floor.

## Summary (VI)

Diện miễn thuế đất nơi ở chính (PPOR) tại NSW đã có thêm **một điều kiện đủ điều kiện mới** kể từ **năm thuế đất 2025**: chủ sở hữu yêu cầu miễn thuế phải nắm giữ **tối thiểu 25% quyền lợi** trong thửa đất, bên cạnh các điều kiện hiện có (là cá nhân, cư trú liên tục từ ngày 1/7 trước ngày tính thuế 31/12, chỉ có một nơi ở chính trên toàn thế giới). Trước đây không có ngưỡng tỷ lệ sở hữu tối thiểu rõ ràng. Điều này ảnh hưởng nhiều nhất đến các cấu trúc đồng sở hữu — một người mua chỉ nắm giữ tỷ lệ nhỏ (ví dụ, một thành viên gia đình được thêm vào giấy tờ sở hữu vì lý do vay vốn hoặc thừa kế) nay có thể không đủ điều kiện miễn thuế chỉ vì lý do này, dù thực sự đang sinh sống tại nhà đó. Nếu kế hoạch của bạn từng mặc định trạng thái `exempt_ppor` cho một cấu trúc đồng sở hữu tại NSW, tỷ lệ sở hữu nay cần được kiểm tra lại theo ngưỡng 25% này.

## Diff

```jsonc
{
  "old_value": { "nsw_ppor_min_interest_pct": null, "note": "no explicit minimum-interest condition" },
  "new_value": { "nsw_ppor_min_interest_pct": 25, "effective": "2025 land tax year (from 2025-01-01)", "note": "layered onto existing conditions: natural person, continuous occupation since 1 Jul before 31 Dec taxing date, one PPR worldwide" }
}
```

Notes:

- **`sources:` reuses `kb.land-tax.ppor-exemption`'s own citation (Revenue NSW), unchanged from its last verify (2026-07-06).**
- **Mode A relevant now** — this is a live domestic-buyer fact, not a foreign-buyer or investor item.
- **Immutable once authored.**
