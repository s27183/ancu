// UI-chrome i18n — vi/en, zero-dependency, reactive to the lang store: `$t(key)`
// re-evaluates when the language flips. Keys are a typed union derived from the
// dictionary, so a typo or missing key is a compile error (svelte-check).
//
// SCOPE: product chrome only — nav, labels, status copy. Plan/eligibility CONTENT
// is bilingual {vi, en} authored engine-side and is NEVER routed through here
// (bilingual-content.md). vi is primary, en secondary. (Mirrors aleap's i18n.)
import { derived } from 'svelte/store';
import { lang } from '$lib/stores/lang';

const messages = {
    'brand.name': { vi: 'FirstHomey', en: 'FirstHomey' },
    'brand.tagline': {
        vi: 'Kế hoạch mua nhà đầu tiên tại Úc',
        en: 'Your first-home plan in Australia'
    },
    'lang.label': { vi: 'Ngôn ngữ', en: 'Language' },

    'map.state.label': { vi: 'Bang', en: 'State' },
    'map.state.all': { vi: 'Tất cả', en: 'All' },
    // Size filter — the criterion driving each suburb dot's colour + size. The chosen
    // criterion's label doubles as the legend title.
    'map.size.label': { vi: 'Hiển thị theo', en: 'Show by' },
    'map.size.seifa': { vi: 'Chỉ số kinh tế', en: 'Economic index' },
    'map.size.vietnamese': { vi: 'Cộng đồng gốc Việt', en: 'Vietnamese community' },
    'map.size.population': { vi: 'Dân số', en: 'Population' },
    'map.size.crime': { vi: 'Chỉ số tội phạm', en: 'Recorded criminal incidents' },
    'map.legend.nodata': { vi: 'Chưa có dữ liệu', en: 'No data' },
    'map.sources': { vi: 'Nguồn dữ liệu', en: 'Data sources' },
    'map.zoomhint': {
        vi: 'Phóng to vào một thành phố để so sánh từng khu vực',
        en: 'Zoom into a city to compare suburbs'
    },
    'map.loading': { vi: 'Đang tải bản đồ…', en: 'Loading the map…' },
    'map.error': {
        vi: 'Không tải được dữ liệu khu vực. Vui lòng thử lại.',
        en: 'Couldn’t load suburb data. Please try again.'
    },
    'map.retry': { vi: 'Thử lại', en: 'Retry' },

    'sheet.tab.zone': { vi: 'Dữ liệu khu vực', en: 'Zone data' },
    'sheet.tab.plan': { vi: 'Kế hoạch', en: 'Plan' },
    'sheet.close': { vi: 'Đóng', en: 'Close' },
    'sheet.viet': { vi: 'Cộng đồng gốc Việt', en: 'Vietnamese community' },
    'sheet.seifa': { vi: 'Chỉ số kinh tế – xã hội (SEIFA)', en: 'Socio-economic (SEIFA)' },
    'sheet.seifa.note': {
        vi: 'Thập phân vị 1 = khó khăn nhất, 10 = thuận lợi nhất.',
        en: 'Decile 1 = most disadvantaged, 10 = most advantaged.'
    },
    'sheet.population': { vi: 'Dân số', en: 'Population' },
    'sheet.crime': { vi: 'Số vụ được ghi nhận', en: 'Recorded incidents' },
    'sheet.crime.unit': { vi: 'trên 1.000 dân', en: 'per 1,000 people' },
    'sheet.crime.note': {
        vi: 'Số liệu tham khảo, không phải đánh giá khu vực.',
        en: 'A reference figure — not a rating of the area.'
    },
    'sheet.nodata': { vi: 'Chưa có dữ liệu', en: 'No data yet' },
    'sheet.plan.placeholder': {
        vi: 'Kế hoạch mua nhà cho khu vực này sẽ xuất hiện ở đây.',
        en: 'Your home-buying plan for this suburb will appear here.'
    },

    'onboarding.cta': { vi: 'Lập kế hoạch tại đây', en: 'Make a plan here' },
    'onboarding.title': { vi: 'Lập kế hoạch tại', en: 'Plan for' },
    'onboarding.gate.citizen': {
        vi: 'Bạn là công dân hoặc thường trú nhân Úc?',
        en: 'Are you an Australian citizen or permanent resident?'
    },
    'onboarding.gate.firsthome': {
        vi: 'Đây có phải ngôi nhà đầu tiên của bạn?',
        en: 'Is this your first home?'
    },
    'onboarding.yes': { vi: 'Có', en: 'Yes' },
    'onboarding.no': { vi: 'Không', en: 'No' },
    'onboarding.outofscope': {
        vi: 'Hiện FirstHomey hỗ trợ người mua nhà lần đầu là công dân hoặc thường trú nhân Úc. Các trường hợp khác sẽ sớm có.',
        en: 'Right now FirstHomey supports first-home buyers who are Australian citizens or permanent residents. Other paths are coming soon.'
    },
    'onboarding.budget.label': { vi: 'Ngân sách mục tiêu (AUD)', en: 'Target budget (AUD)' },
    'onboarding.budget.note': {
        vi: 'Quy đổi sang VND sẽ có khi tỉ giá được kết nối.',
        en: 'VND conversion arrives once the FX feed is connected.'
    },
    'onboarding.budget.under': { vi: 'Dưới', en: 'Under' },
    'onboarding.submit': { vi: 'Tạo kế hoạch', en: 'Create my plan' },
    'onboarding.submitting': { vi: 'Đang tạo…', en: 'Creating…' },
    'onboarding.created.title': {
        vi: 'Đang chuẩn bị kế hoạch của bạn',
        en: 'Preparing your plan'
    },
    'onboarding.created.body': {
        vi: 'Kế hoạch cơ bản đang được tính toán và sẽ xuất hiện trong mục Kế hoạch.',
        en: 'Your base plan is being computed and will appear in the Plan tab.'
    },
    'onboarding.auth.title': { vi: 'Đăng nhập để lưu kế hoạch', en: 'Sign in to save your plan' },
    'onboarding.auth.body': {
        vi: 'Bạn cần đăng nhập để lưu và xem kế hoạch của mình.',
        en: 'You’ll need to sign in to save and view your plan.'
    },
    'onboarding.auth.cta': { vi: 'Đăng nhập', en: 'Sign in' },
    'onboarding.error': {
        vi: 'Có lỗi xảy ra. Vui lòng thử lại.',
        en: 'Something went wrong. Please try again.'
    },
    'onboarding.retry': { vi: 'Thử lại', en: 'Try again' },

    // --- Plan projection (8-S4c) ---------------------------------------------
    // Field LABELS and enum-DISPLAY labels are chrome (UI furniture) → $t. The engine
    // owns CONTENT: prose arrives as {vi,en} and figures/enums are single-valued, so
    // an enum's value (e.g. "surplus") is mapped to its display label here, never
    // translated at the engine (bilingual-content.md).
    'plan.loading': { vi: 'Đang tải kế hoạch…', en: 'Loading your plan…' },
    'plan.error': { vi: 'Không tải được kế hoạch.', en: 'Couldn’t load your plan.' },
    'plan.retry': { vi: 'Thử lại', en: 'Try again' },
    'plan.failed': {
        vi: 'Kế hoạch chưa tính xong. Vui lòng thử lại.',
        en: 'Your plan didn’t finish computing. Please try again.'
    },
    'plan.running': {
        vi: 'Đang lập kế hoạch cơ bản cho bạn…',
        en: 'Preparing your base plan…'
    },
    'plan.computing': { vi: 'Đang tính…', en: 'Computing…' },
    'plan.pending': { vi: 'Chưa có', en: 'Not yet' },

    'plan.c.buyer_profile': { vi: 'Hồ sơ của bạn', en: 'Your profile' },
    'plan.c.eligibility': { vi: 'Chương trình hỗ trợ', en: 'Schemes & eligibility' },
    'plan.c.mortgage_finance': { vi: 'Vay & tài chính', en: 'Mortgage & finance' },
    'plan.c.cash_position': { vi: 'Dòng tiền', en: 'Cash position' },
    'plan.c.ownership_planning': { vi: 'Chi phí sở hữu', en: 'Owning the home' },

    'plan.f.applicants': { vi: 'Số người mua', en: 'Applicants' },
    'plan.f.firb': { vi: 'Cần FIRB?', en: 'FIRB required?' },
    'plan.f.income': { vi: 'Thu nhập xét duyệt', en: 'Assessable income' },
    'plan.f.capacity': { vi: 'Khả năng vay ước tính', en: 'Est. borrowing capacity' },
    'plan.f.deposit': { vi: 'Tiền cọc sẵn có', en: 'Deposit ready' },
    'plan.f.target_price': { vi: 'Khoảng giá mục tiêu', en: 'Target price range' },
    'plan.f.strengths': { vi: 'Điểm mạnh', en: 'Strengths' },
    'plan.f.constraints': { vi: 'Điểm cần lưu ý', en: 'Things to watch' },

    'plan.f.basis': { vi: 'Tình trạng đủ điều kiện', en: 'Eligibility' },
    'plan.f.applicable_schemes': { vi: 'Chương trình áp dụng được', en: 'Schemes you can use' },
    'plan.f.rejected_schemes': { vi: 'Không áp dụng', en: 'Not applicable' },
    'plan.f.total_benefit': { vi: 'Tổng lợi ích ước tính', en: 'Est. total benefit' },
    'plan.f.stacking': { vi: 'Lưu ý khi kết hợp', en: 'Stacking notes' },
    'plan.f.order': { vi: 'Thứ tự nộp hồ sơ', en: 'Application order' },
    'plan.basis.all_applicants_eligible': {
        vi: 'Tất cả người mua đủ điều kiện',
        en: 'All applicants eligible'
    },
    'plan.basis.eligible_only_if_restructured': {
        vi: 'Đủ điều kiện nếu điều chỉnh cơ cấu',
        en: 'Eligible if restructured'
    },
    'plan.basis.ineligible': { vi: 'Chưa đủ điều kiện', en: 'Not yet eligible' },

    'plan.f.path': { vi: 'Hướng vay đề xuất', en: 'Recommended path' },
    'plan.f.lenders': { vi: 'Ngân hàng phù hợp', en: 'Lender shortlist' },
    'plan.f.preapproval': { vi: 'Chuẩn bị duyệt sơ bộ', en: 'Pre-approval steps' },
    'plan.f.assumptions': { vi: 'Giả định', en: 'Assumptions' },
    'plan.path.fhg_backed': { vi: 'Bảo lãnh FHG', en: 'FHG-backed' },
    'plan.path.lmi_5_to_20': { vi: 'Vay kèm bảo hiểm LMI (cọc 5–20%)', en: 'LMI (5–20% deposit)' },
    'plan.path.twenty_plus': { vi: 'Cọc từ 20% trở lên', en: '20%+ deposit' },
    'plan.path.user_specific_alternative': { vi: 'Phương án riêng', en: 'Tailored option' },

    'plan.f.stamp_duty': { vi: 'Thuế trước bạ', en: 'Stamp duty' },
    'plan.f.duty_before': { vi: 'Trước ưu đãi', en: 'Before concession' },
    'plan.f.duty_after': { vi: 'Sau ưu đãi', en: 'After concession' },
    'plan.f.max_price': { vi: 'Giá nhà tối đa hỗ trợ', en: 'Max price supported' },
    'plan.f.cash_required': { vi: 'Tổng tiền mặt cần', en: 'Total cash needed' },
    'plan.f.cash_available': { vi: 'Tiền mặt hiện có', en: 'Cash available' },
    'plan.f.gap': { vi: 'Chênh lệch', en: 'Gap / surplus' },
    'plan.f.verdict': { vi: 'Đánh giá dòng tiền', en: 'Cash verdict' },
    'plan.f.genuine_savings': { vi: 'Tiết kiệm thực', en: 'Genuine savings' },
    'plan.f.mitigation': { vi: 'Gợi ý nếu còn thiếu', en: 'If you’re short' },
    'plan.verdict.surplus': { vi: 'Dư', en: 'Surplus' },
    'plan.verdict.tight': { vi: 'Vừa đủ', en: 'Tight' },
    'plan.verdict.short': { vi: 'Còn thiếu', en: 'Short' },
    'plan.gsv.meets': { vi: 'Đạt', en: 'Meets' },
    'plan.gsv.fails_recent_gift': { vi: 'Vướng tiền tặng gần đây', en: 'Recent gift' },
    'plan.gsv.insufficient_track_record': { vi: 'Chưa đủ lịch sử tiết kiệm', en: 'Insufficient history' },
    'plan.gsv.unknown': { vi: 'Cần xác minh', en: 'To verify' },

    'plan.f.recurring': { vi: 'Chi phí định kỳ (ước tính)', en: 'Recurring costs (est.)' },
    'plan.f.statutory': { vi: 'Phí pháp định (rates + nước)', en: 'Council + water' },
    'plan.f.land_tax': { vi: 'Thuế đất', en: 'Land tax' },
    'plan.f.maintenance': { vi: 'Quỹ bảo trì mỗi năm', en: 'Maintenance reserve / yr' },
    'plan.f.monthly': { vi: 'Chi phí hàng tháng', en: 'Monthly outgoings' },
    'plan.f.annual': { vi: 'Chi phí hàng năm', en: 'Annual outgoings' },
    'plan.f.alerts': { vi: 'Nhắc nhở đã bật', en: 'Alerts armed' },
    'plan.landtax.exempt_ppor': { vi: 'Miễn (nhà ở chính)', en: 'Exempt (your home)' },
    'plan.landtax.applicable': { vi: 'Có áp dụng', en: 'Applicable' },
    'plan.landtax.to_verify': { vi: 'Cần xác minh', en: 'To verify' },

    // --- Chat / Q&A (8-S4d) --------------------------------------------------
    // Chrome only. The answer prose is engine-authored {vi,en} (pick()), never $t.
    'chat.title': { vi: 'Hỏi về kế hoạch của bạn', en: 'Ask about your plan' },
    'chat.placeholder': {
        vi: 'Đặt câu hỏi về kế hoạch của bạn…',
        en: 'Ask a question about your plan…'
    },
    'chat.send': { vi: 'Gửi', en: 'Send' },
    'chat.thinking': { vi: 'Đang suy nghĩ…', en: 'Thinking…' },
    'chat.looking': { vi: 'Đang tra cứu thông tin…', en: 'Looking things up…' },
    'chat.busy': {
        vi: 'Kế hoạch đang được cập nhật. Vui lòng đợi một chút rồi hỏi lại.',
        en: 'Your plan is updating. Please wait a moment, then ask again.'
    },
    'chat.error': {
        vi: 'Chưa trả lời được câu hỏi này. Vui lòng thử lại.',
        en: 'Couldn’t answer that just now. Please try again.'
    },
    'chat.disclaimer': {
        vi: 'Thông tin hỗ trợ quyết định — không phải tư vấn tài chính hay pháp lý.',
        en: 'Decision-support information — not financial or legal advice.'
    },

    'auth.signin': { vi: 'Đăng nhập', en: 'Sign in' },
    'auth.signout': { vi: 'Đăng xuất', en: 'Sign out' },
    'auth.title': { vi: 'Đăng nhập vào FirstHomey', en: 'Sign in to FirstHomey' },
    'auth.email.label': { vi: 'Email', en: 'Email' },
    'auth.email.placeholder': { vi: 'ban@example.com', en: 'you@example.com' },
    'auth.email.invalid': {
        vi: 'Vui lòng nhập một email hợp lệ.',
        en: 'Please enter a valid email.'
    },
    'auth.send': { vi: 'Gửi liên kết đăng nhập', en: 'Send sign-in link' },
    'auth.sending': { vi: 'Đang gửi…', en: 'Sending…' },
    'auth.sent.title': { vi: 'Kiểm tra email của bạn', en: 'Check your email' },
    'auth.sent.body': {
        vi: 'Chúng tôi đã gửi cho bạn một liên kết đăng nhập. Liên kết hết hạn sau 15 phút.',
        en: 'We’ve emailed you a sign-in link. It expires in 15 minutes.'
    },
    'auth.or': { vi: 'hoặc', en: 'or' },
    'auth.google': { vi: 'Tiếp tục với Google', en: 'Continue with Google' },
    'auth.devlink': {
        vi: 'Liên kết dev (chỉ môi trường phát triển):',
        en: 'Dev link (development only):'
    },
    'auth.flag.ok': { vi: 'Bạn đã đăng nhập.', en: 'You’re signed in.' },
    'auth.flag.expired': {
        vi: 'Liên kết đã hết hạn hoặc đã được sử dụng. Vui lòng yêu cầu liên kết mới.',
        en: 'That link has expired or was already used. Please request a new one.'
    },
    'auth.flag.invalid': {
        vi: 'Liên kết đăng nhập không hợp lệ. Vui lòng yêu cầu liên kết mới.',
        en: 'That sign-in link wasn’t valid. Please request a new one.'
    },
    'auth.flag.error': {
        vi: 'Đăng nhập chưa hoàn tất. Vui lòng thử lại.',
        en: 'Sign-in didn’t complete. Please try again.'
    },
    'auth.flag.google_unavailable': {
        vi: 'Đăng nhập bằng Google hiện chưa khả dụng.',
        en: 'Google sign-in isn’t available right now.'
    },

    'status.title': { vi: 'Trạng thái hệ thống', en: 'System status' },
    'status.checking': { vi: 'Đang kiểm tra…', en: 'Checking…' },
    'status.ok': { vi: 'Backend đang hoạt động', en: 'Backend is up' },
    'status.fail': { vi: 'Không kết nối được backend', en: 'Backend unreachable' }
} as const;

export type MessageKey = keyof typeof messages;

export const t = derived(lang, ($lang) => (key: MessageKey) => messages[key][$lang]);
