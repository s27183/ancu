---
slug: kb.copy.cash
effective_from: 2026-06-01
last_verified: 2026-07-10
---

# Cash-position component copy (bilingual)

User-facing copy-templates for the `cash_position` resolver half (`fh_engine_cash`): the
Mode-A FHB stamp-duty `notes` (concession applied / phased out / full duty / pending), the
`key_assumptions` narration (shared across Mode A + Mode B — `assume_ceiling` /
`assume_need_side` carry no mode-specific claim), the pending-state notes, the NEED-side
notes (Decision 9 — deposit assumption, banded other-costs, the pending reserve buffer),
the Mode-B foreign-person `key_assumptions` (`assume_*_foreign` — no first-home
concession, FX not yet included, the no-LMI base convention), and the `cash_events`
spine labels (`event_*` — two-spines §2; param-free, since the figure rides in the
event's `amount`, not interpolated into prose — `event_lmi` added 2026-07-10 for Mode
C's investor acquire-phase spine, `cash_events_investor/4`). Each template is a `{vi, en}` pair with
`{param}` placeholders the resolver fills via `fh_engine_i18n:subst/2`.

Params here are all **scalars** (same in both languages, per the figure/locale boundary,
bilingual-content.md §3b/§4): `{state}` is a state code proper noun (NSW/VIC/QLD), `{ceiling}`
and `{saving}` are money figures the resolver pre-formats with `fh_engine_money:money/1`,
and `{pct}` / `{months}` are integers (deposit percentage, reserve months) the resolver
passes raw (`fh_engine_i18n:subst/2` stringifies them; the engine emits the bare composed
figure, fine-grained locale formatting is shell-owned, §4).

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
    "note_state_unknown": {
      "vi": "Chưa xác định được tiểu bang cho khu vực của bạn, nên chưa ước tính thuế trước bạ.",
      "en": "We couldn't determine the state for your area yet, so transfer duty isn't estimated."
    },
    "assume_stamp_only": {
      "vi": "Hiện mới ước tính thuế trước bạ trong các chi phí khi hoàn tất giao dịch; bức tranh tiền mặt đầy đủ sẽ hiện ra khi bạn nhập thu nhập, tiền tiết kiệm và một bất động sản cụ thể.",
      "en": "Stamp duty is the only settlement cost estimated so far; the full cash picture fills in as you add income, savings and a property."
    },
    "assume_ceiling": {
      "vi": "Thuế được tính ở mức cao nhất trong khoảng giá mục tiêu của bạn ({ceiling}).",
      "en": "Duty computed at the top of your target range ({ceiling})."
    },
    "assume_need_side": {
      "vi": "Đây là số tiền cần để bắt đầu mua — tiền đặt cọc, thuế trước bạ và chi phí giao dịch, ước tính ở mức cao nhất trong khoảng giá mục tiêu. Việc bạn có đủ hay không sẽ rõ khi bạn nhập thu nhập và tiền tiết kiệm.",
      "en": "This is what it costs to get in — deposit, transfer duty and transaction costs, estimated at the top of your target range. Whether your savings cover it fills in once you add your income and savings."
    },
    "deposit_min_fhg": {
      "vi": "Giả định mức đặt cọc tối thiểu {pct}% theo phương án Bảo lãnh Nhà đầu tiên (không cần bảo hiểm khoản vay LMI).",
      "en": "Assumes the minimum {pct}% deposit on the First Home Guarantee path (no LMI)."
    },
    "deposit_min_floor": {
      "vi": "Giả định mức đặt cọc tối thiểu {pct}%; phương án vay của bạn sẽ xác nhận con số này.",
      "en": "Assumes the minimum {pct}% deposit; your loan path will confirm the figure."
    },
    "costs_banded": {
      "vi": "Phí đăng bộ của nhà nước là con số chính xác; chi phí kiểm định, sang tên, bảo hiểm, điện nước và chuyển nhà là khoảng ước tính thông thường — báo giá thực tế của bạn mới là con số ràng buộc. Bảo hiểm công trình áp dụng cho nhà riêng; với căn hộ chung cư, khoản này nằm trong phí quản lý chung cư.",
      "en": "Government registration fees are exact; inspection, conveyancing, insurance, utilities and moving are typical ranges — your own quotes are the binding figures. Building insurance applies to houses; for a strata apartment it sits in the body-corporate levies instead."
    },
    "reserve_pending": {
      "vi": "Nên giữ một khoản dự phòng sau khi hoàn tất giao dịch, khoảng {months} tháng tiền trả góp — chúng tôi sẽ tính cụ thể khi biết mức trả góp khoản vay của bạn.",
      "en": "A post-settlement cash buffer of about {months} months of repayments is recommended — we'll size it once your loan repayment is known."
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
    },
    "event_deposit": {
      "vi": "Tiền đặt cọc khi ký hợp đồng",
      "en": "Deposit at contract"
    },
    "event_stamp_duty": {
      "vi": "Thuế trước bạ khi hoàn tất giao dịch",
      "en": "Transfer duty at settlement"
    },
    "event_other_costs": {
      "vi": "Chi phí giao dịch (đăng bộ, kiểm định, sang tên)",
      "en": "Transaction costs (registration, inspection, conveyancing)"
    },
    "event_grant": {
      "vi": "Trợ cấp người mua nhà lần đầu (nhận khi hoàn tất giao dịch)",
      "en": "First-home owner grant (received at settlement)"
    },
    "event_lmi": {
      "vi": "Bảo hiểm khoản vay (LMI) khi hoàn tất giao dịch",
      "en": "Lenders mortgage insurance (LMI) at settlement"
    },
    "assume_no_concession_foreign_person": {
      "vi": "Ưu đãi thuế trước bạ cho người mua nhà lần đầu không áp dụng cho người nước ngoài — số liệu ở đây là mức thuế đầy đủ, cộng thêm phụ phí dành cho người mua nước ngoài.",
      "en": "The first-home duty concession does not apply to a foreign person — the figures here are full duty, plus the foreign-buyer surcharge."
    },
    "assume_fx_not_included": {
      "vi": "Chi phí chuyển đổi ngoại tệ (VND sang AUD) chưa được tính vào tổng số tiền cần — khoản này sẽ được thêm vào khi biết số tiền chuyển từ Việt Nam.",
      "en": "The VND-to-AUD currency-transfer cost is not yet included in the total — it's added once the transfer amount from Vietnam is known."
    },
    "assume_no_lmi_at_conservative_deposit": {
      "vi": "Giả định không cần bảo hiểm khoản vay (LMI) vì mức đặt cọc ước tính ({pct}%) cao hơn ngưỡng 20%; đây là giả định ban đầu, không phải chính sách của một ngân hàng cụ thể.",
      "en": "Assumes no lender's mortgage insurance (LMI) is needed, since the estimated deposit ({pct}%) is above the 20% threshold — a base assumption, not a specific lender's policy."
    }
  }
}
```
