---
slug: kb.property.types
effective_from: 2026-11-04
last_verified: 2026-11-04
sources:
  - url: https://www.abs.gov.au/census/guide-census-data/census-dictionary/2026/variables-topic/housing/dwelling-structure-strd
    retrieved: 2026-11-04
    path: docs/sources/abs/census-2026-dwelling-structure.txt
    quotes:
      - "Is structurally independent from surrounding dwellings."
      - "Semi-detached, row or terrace house, townhouse, etc. with one, two or more storeys"
      - "Have their own private grounds."
      - "No other dwelling above or below them."
      - "They are attached in some structural way to one or more neighbouring dwellings."
      - "Dwellings in blocks of flats or apartments."
      - "Do not have their own private grounds."
      - "Usually share a common entrance foyer or stairwell."
    note: "ABS Census of Population and Housing: Census dictionary, 2026 — Dwelling structure (STRD), category definitions (marked the latest release; the 2021 page says it is not)."
---

# Property types in Australia — what each listing word means

Behavior 154 (Son 2026-11-04: «many vietnamese clients are new to listing sites in Australia … add some basic info about property types in Australia (English -> Vietnamese)»). The listing sheet's "Property types in Australia" (ListingGuide.svelte) draws this copy, word for word (unit/listingGuide.test.ts checks i18n.ts against it). The house, townhouse and apartment lines follow the ABS Census 2026 dwelling-structure categories, quoted above. The ABS defines no "land" or "studio": those lines say what the listing sites call them, labelled so, and are common usage, not a definition (CONVENTION). Whether a home is strata (an owners corporation, a body corporate) is a separate question owned by kb.terms.buying's strata term; this doc only says apartments and townhouses often are. Risk by type is owned by kb.building-types.risk-by-type.

## Rules

```jsonc
{
  "fills": [],
  "copy": {
    "house": {
      "vi": "Nhà riêng (nhà độc lập): đứng riêng, không dính vào nhà nào bên cạnh.",
      "en": "A separate house: it stands on its own, not joined to any neighbouring home."
    },
    "attached": {
      "vi": "Nhà liền kề: có sân hay khoảnh đất riêng, không có nhà nào ở trên hay ở dưới, và dính vào nhà bên cạnh.",
      "en": "An attached home: it has its own grounds, no home above or below it, and is joined to its neighbour."
    },
    "apartment": {
      "vi": "Căn hộ: nằm trong một khối nhà, không có sân riêng, thường dùng chung lối vào hay cầu thang. Studio là căn hộ một phòng, ngủ và sinh hoạt chung.",
      "en": "An apartment: in a block, with no grounds of its own, usually sharing an entrance or stairs. A studio is a one-room apartment, living and sleeping in one space."
    },
    "land": {
      "vi": "Đất: một lô đất chưa có nhà, để tự xây.",
      "en": "Land: a lot with no home on it, to build on."
    },
    "source": {
      "vi": "Nhà riêng, nhà liền kề và căn hộ theo định nghĩa của Cục Thống kê Úc (ABS, Điều tra dân số 2026). Các tên khác là cách các trang rao bán gọi.",
      "en": "House, attached home and apartment follow the Australian Bureau of Statistics' definitions (ABS, Census 2026). The other names are what the listing sites call them."
    },
    "strata": {
      "vi": "Căn hộ và nhà liền kề thường thuộc một khu strata: bạn sở hữu căn của mình, phần chung do ban quản trị quản lý.",
      "en": "Apartments and townhouses are often strata: you own your lot, and a scheme runs the common property."
    }
  }
}
```
