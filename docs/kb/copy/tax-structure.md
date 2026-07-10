---
slug: kb.copy.tax-structure
effective_from: 2026-06-27
last_verified: 2026-07-10
---

# Investor tax-structure component copy (bilingual)

User-facing copy-templates for the `tax_structure` resolver half (`fh_engine_fill:tax_structure/1`):
the **negative-gearing reform note** — the bilingual decision-support caveat surfacing the announced
2026-27 Budget change (negative gearing limited to new builds from 1 July 2027) — and, since
2026-07-10, `event_tax_refund`, the label for the `tax_refund` hold-phase `cash_event`
(`fh_engine_fill:tax_cash_events/1`) purchase_journey's generic multi-source harvest places on
the swimlane's Own/Hold column. Each variant is a single `{vi, en}` prose line, read by the
resolver via `fh_engine_kb:copy/2` (+ `fh_engine_i18n:subst/2` for the reform-note params).

The regulated **fact** lives in `kb.tax.negative-gearing-mechanics` (`announced_reform_not_yet_law`,
verified 2026-07-06): the reform is now **ENACTED** — the *Treasury Laws Amendment (Tax Reform No. 1)
Act 2026* (Act No. 49 of 2026) passed both Houses 25 June 2026 and received Royal Assent 26 June 2026
— but **not yet in effect** (effective 1 July 2027); full negative gearing **remains current law**
through the transition; an **established** property purchased after Budget night loses the offset
against wages from 1 July 2027 (losses only vs rental income / future capital gains, carried forward),
while **new builds remain fully negatively gearable**. This doc holds only the bilingual rendering of
that fact — it asserts no figure and no new fact.

The note is **property-conditional**, resolver-selected from the attached property's
`property_fit_investor.property_type`:

- `reform_established` — an `established_*` property (the wedge's own target case): the concrete
  warning that this purchase would lose the wage offset from 1 July 2027.
- `reform_new_build` — a `new_*` / `off_the_plan` / `house_and_land` property: new builds keep full
  negative gearing under the proposal.
- `reform_base` — **no property attached yet** (the base plan): the general caveat, with the
  applicability flagged as per-property (honest-partial — the established-vs-new pivot needs a property).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse + bilingual-copy gates apply). Vietnamese is authored for register —
not a transliteration of the English (trap #4). Decision-support tone, never advice: the note states
the mechanics and the trade-off and points to a **registered tax agent**; it never tells an investor
to gear negatively, never calls the strategy attractive, and never models the unenacted reform as
settled law (ASIC/TPB line).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — template
ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "reform_base": {
      "vi": "Theo luật hiện hành, bạn được khấu trừ khoản lỗ cho thuê (âm dòng tiền) vào thu nhập khác. Cải cách trong Ngân sách 2026-27 giới hạn negative gearing chỉ cho nhà xây mới, kể từ 1/7/2027, nay đã thành luật (có hiệu lực từ 26/6/2026) nhưng chưa áp dụng cho đến ngày đó — negative gearing đầy đủ vẫn là luật hiện hành trong giai đoạn chuyển tiếp. Việc này có ảnh hưởng đến bạn hay không tùy vào loại bất động sản: mua nhà cũ (established) ở thời điểm này thì sẽ mất phần khấu trừ vào lương kể từ 1/7/2027, còn nhà xây mới thì vẫn giữ được. Hãy xác nhận với chuyên viên thuế có đăng ký.",
      "en": "Under current law you can deduct a rental loss (negative cash flow) against your other income. A 2026-27 Budget reform limiting negative gearing to new builds from 1 July 2027 is now law (enacted 26 June 2026) but does not take effect until then — full negative gearing remains the applicable law through the transition. Whether it affects you depends on the property: an established purchase made now would lose the offset against salary from 1 July 2027, while a new build would keep it. Confirm with a registered tax agent."
    },
    "reform_established": {
      "vi": "Theo luật hiện hành, bạn được khấu trừ khoản lỗ cho thuê vào lương và thu nhập khác. Cải cách trong Ngân sách 2026-27 giới hạn negative gearing chỉ cho nhà xây mới, kể từ 1/7/2027, nay đã thành luật (có hiệu lực từ 26/6/2026) nhưng chưa áp dụng cho đến ngày đó. Với một căn nhà cũ (established) mua ở thời điểm này, từ 1/7/2027 khoản lỗ sẽ không còn được trừ vào lương — chỉ trừ vào thu nhập cho thuê hoặc lãi vốn sau này, và được chuyển sang các năm sau. Hãy xác nhận với chuyên viên thuế có đăng ký.",
      "en": "Under current law you can deduct a rental loss against your salary and other income. A 2026-27 Budget reform limiting negative gearing to new builds from 1 July 2027 is now law (enacted 26 June 2026) but does not take effect until then. For an established property bought now, from 1 July 2027 the loss could no longer be deducted against salary — only against rental income or future capital gains, carried forward to later years. Confirm with a registered tax agent."
    },
    "reform_new_build": {
      "vi": "Theo luật hiện hành, bạn được khấu trừ khoản lỗ cho thuê vào lương và thu nhập khác. Cải cách trong Ngân sách 2026-27 giới hạn negative gearing chỉ cho nhà xây mới, kể từ 1/7/2027, nay đã thành luật (có hiệu lực từ 26/6/2026) nhưng chưa áp dụng cho đến ngày đó. Một căn nhà xây mới như thế này vẫn được negative gearing đầy đủ (khoản lỗ vẫn trừ vào thu nhập khác). Hãy xác nhận với chuyên viên thuế có đăng ký.",
      "en": "Under current law you can deduct a rental loss against your salary and other income. A 2026-27 Budget reform limiting negative gearing to new builds from 1 July 2027 is now law (enacted 26 June 2026) but does not take effect until then. A new build like this would remain fully negatively gearable (the loss still deductible against other income). Confirm with a registered tax agent."
    },
    "event_tax_refund": {
      "vi": "Hoàn thuế nhờ khấu trừ lỗ cho thuê (nếu có)",
      "en": "Tax refund from the negative-gearing offset (when applicable)"
    }
  }
}
```

## Sources

The regulated fact and its provenance live in `kb.tax.negative-gearing-mechanics` (ATO *Tax reform
– Boosting home ownership – Reforming negative gearing and capital gains tax*; Treasury *Budget
2026-27*; *Treasury Laws Amendment (Tax Reform No. 1) Act 2026*, Act No. 49 of 2026 — passed both
Houses 25 June 2026, Royal Assent 26 June 2026, effective 1 July 2027; verified 2026-07-06). This
copy doc adds no fact; it renders that one bilingually.
