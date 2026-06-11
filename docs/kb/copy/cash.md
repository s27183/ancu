---
slug: kb.copy.cash
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Cash-position component copy (bilingual)

User-facing copy-templates for the `cash_position` resolver half (`fh_engine_cash`): the
stamp-duty `notes` (concession applied / phased out / full duty / pending), the
`key_assumptions` narration, and the two pending-state notes. Each template is a `{vi, en}`
pair with `{param}` placeholders the resolver fills via `fh_engine_i18n:subst/2`.

Params here are all **scalars** (same in both languages, per the figure/locale boundary,
bilingual-content.md §3b/§4): `{state}` is a state code proper noun (NSW/VIC/QLD), `{ceiling}`
and `{saving}` are money figures the resolver pre-formats with `fh_engine_money:money/1`
(the engine emits the bare composed figure; fine-grained locale formatting is shell-owned, §4).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt;
only slug==path + content_json-parse gates apply). Vietnamese is authored for register —
not a transliteration of the English (trap #4). Decision-support tone, never advice (ASIC).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "note_set_range": {
      "vi": "Hãy chọn khoảng giá mục tiêu để chúng tôi ước tính thuế trước bạ.",
      "en": "Set a target price range to estimate transfer duty."
    },
    "note_state_unmodelled": {
      "vi": "Thuế trước bạ cho tiểu bang {state} chưa được tính ở đây (hiện hỗ trợ NSW, VIC, QLD).",
      "en": "Transfer duty for {state} is not yet modelled (NSW, VIC, QLD supported)."
    },
    "assume_stamp_only": {
      "vi": "Hiện mới ước tính thuế trước bạ trong các chi phí khi hoàn tất giao dịch; bức tranh tiền mặt đầy đủ sẽ hiện ra khi bạn nhập thu nhập, tiền tiết kiệm và một bất động sản cụ thể.",
      "en": "Stamp duty is the only settlement cost estimated so far; the full cash picture fills in as you add income, savings and a property."
    },
    "assume_ceiling": {
      "vi": "Thuế được tính ở mức cao nhất trong khoảng giá mục tiêu của bạn ({ceiling}).",
      "en": "Duty computed at the top of your target range ({ceiling})."
    },
    "duty_concession_applied": {
      "vi": "Đã bao gồm ưu đãi thuế trước bạ cho người mua nhà lần đầu — giảm khoảng {saving} — còn chờ xác nhận thông tin của bạn.",
      "en": "Includes the first-home transfer-duty concession — about {saving} off — pending confirmation of your details."
    },
    "duty_concession_phased_out": {
      "vi": "Ở mức cao nhất trong khoảng giá mục tiêu, ưu đãi thuế trước bạ cho người mua nhà lần đầu không còn áp dụng; một mức giá thấp hơn có thể đủ điều kiện.",
      "en": "At the top of your target range the first-home duty concession no longer applies; a lower target may qualify."
    },
    "duty_full": {
      "vi": "Đang hiển thị mức thuế đầy đủ — chưa áp dụng ưu đãi người mua nhà lần đầu ở mức giá/tiểu bang này.",
      "en": "Shown at full duty — no first-home concession applied at this price/state yet."
    }
  }
}
```
