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
    // Filters — the collapsible controls cluster + the saved-plans / name filter.
    'map.filters': { vi: 'Bộ lọc', en: 'Filters' },
    'filter.saved': { vi: 'Kế hoạch đã lưu', en: 'Saved plans' },
    'filter.name.placeholder': { vi: 'Tìm khu vực…', en: 'Search suburbs…' },
    'filter.nomatch': { vi: 'Không tìm thấy khu vực phù hợp.', en: 'No matching suburbs.' },
    'filter.saved.empty': {
        vi: 'Bạn chưa lưu kế hoạch nào. Hãy tạo một kế hoạch để ghim khu vực tại đây.',
        en: 'No saved plans yet. Create a plan to pin a suburb here.'
    },
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
    'onboarding.intent.label': {
        vi: 'Bạn mua để ở hay để đầu tư?',
        en: 'Are you buying to live in or to invest?'
    },
    'onboarding.intent.live': { vi: 'Để ở', en: 'To live in' },
    'onboarding.intent.invest': { vi: 'Để đầu tư', en: 'As an investment' },
    'onboarding.gate.citizen': {
        vi: 'Bạn là công dân hoặc thường trú nhân Úc?',
        en: 'Are you an Australian citizen or permanent resident?'
    },
    'onboarding.gate.firsthome': {
        vi: 'Đây có phải ngôi nhà đầu tiên của bạn?',
        en: 'Is this your first home?'
    },
    'onboarding.outofscope.foreign': {
        vi: 'Hiện FirstHomey hỗ trợ công dân và thường trú nhân Úc. Trường hợp người mua ở nước ngoài sẽ sớm có.',
        en: 'Right now FirstHomey supports Australian citizens and permanent residents. Foreign-buyer paths are coming soon.'
    },
    'onboarding.yes': { vi: 'Có', en: 'Yes' },
    'onboarding.no': { vi: 'Không', en: 'No' },
    'onboarding.outofscope': {
        vi: 'Để mua nhà để ở, hiện FirstHomey hỗ trợ người mua nhà lần đầu. Kế hoạch cho người đã từng sở hữu nhà sẽ sớm có.',
        en: 'For buying a home to live in, FirstHomey currently supports first-home buyers. Plans for next-home buyers are coming soon.'
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
    'onboarding.created.cta': { vi: 'Xem kế hoạch', en: 'View your plan' },
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
    'plan.c.preparation': { vi: 'Chuẩn bị', en: 'Getting ready' },
    'plan.c.eligibility': { vi: 'Chương trình hỗ trợ', en: 'Schemes & eligibility' },
    'plan.c.mortgage_finance': { vi: 'Vay & tài chính', en: 'Mortgage & finance' },
    'plan.c.cash_position': { vi: 'Dòng tiền', en: 'Cash position' },
    'plan.c.ownership_planning': { vi: 'Chi phí sở hữu', en: 'Owning the home' },
    'plan.c.ownership_planning_investor': { vi: 'Danh mục & cơ hội', en: 'Portfolio & opportunities' },

    // Plan sub-tab labels (short) — the plan sections + Q&A as tabs inside the Plan view.
    'plan.tab.buyer_profile': { vi: 'Hồ sơ', en: 'Profile' },
    'plan.tab.eligibility': { vi: 'Chương trình', en: 'Schemes' },
    'plan.tab.mortgage_finance': { vi: 'Vay', en: 'Finance' },
    'plan.tab.cash_position': { vi: 'Dòng tiền', en: 'Cash' },
    'plan.tab.ownership_planning': { vi: 'Sở hữu', en: 'Owning' },
    'plan.tab.qa': { vi: 'Hỏi đáp', en: 'Q&A' },
    // Lifecycle tab labels — the blueprint-declared spine (plan-card-lifecycle-restoration.md
    // §3.2). The full mode-general vocabulary (Mode A renders a 6-tab subset; B/C/D tabs are
    // present for when those blueprints come in scope).
    'plan.ltab.overview': { vi: 'Tổng quan', en: 'Overview' },
    // Mode-A three-view spine: Flow (legal/temporal journey) + Budget (financial spine).
    'plan.ltab.flow': { vi: 'Hành trình', en: 'Flow' },
    'plan.ltab.budget': { vi: 'Ngân sách', en: 'Budget' },
    'plan.ltab.family_view': { vi: 'Gia đình', en: 'Family view' },
    'plan.ltab.investment_strategy': { vi: 'Chiến lược đầu tư', en: 'Investment strategy' },
    'plan.ltab.firb_funding': { vi: 'FIRB & Chuyển tiền', en: 'FIRB & Funding' },
    'plan.ltab.before_you_buy': { vi: 'Trước khi mua', en: 'Before you buy' },
    'plan.ltab.yield_tax': { vi: 'Lợi suất & Thuế', en: 'Yield & Tax' },
    'plan.ltab.cash_calculator': { vi: 'Tính tiền mặt', en: 'Cash calculator' },
    'plan.ltab.journey': { vi: 'Hành trình', en: 'Journey' },
    'plan.ltab.property': { vi: 'Bất động sản', en: 'Property' },
    'plan.ltab.buying': { vi: 'Ra giá & Mua', en: 'Buying' },
    'plan.ltab.after_you_buy': { vi: 'Sau khi mua', en: 'After you buy' },
    'plan.ltab.portfolio': { vi: 'Danh mục', en: 'Portfolio' },
    // Per-property component titles — shown as affordance cards at base (the full
    // component appears once a property is attached). Base components already have plan.c.*.
    'plan.c.purchase_journey': { vi: 'Hành trình mua nhà', en: 'Your buying journey' },
    'plan.c.disposition': { vi: 'Khi bán nhà', en: 'When you sell' },
    'plan.c.due_diligence': { vi: 'Thẩm định', en: 'Due diligence' },
    'plan.c.settlement_prep': { vi: 'Chuẩn bị bàn giao', en: 'Settlement prep' },
    'plan.c.buying_strategy': { vi: 'Chiến lược ra giá', en: 'Buying strategy' },
    'plan.attach_property': {
        vi: 'Phần này mở ra khi bạn gắn một bất động sản cụ thể vào kế hoạch.',
        en: 'This unlocks once you attach a specific property to your plan.'
    },
    // The property selector (Mode-C Phase-B shell): switch the whole projection between
    // the base plan and each attached property (its addendum overlays the per-property
    // components). Shown only when at least one property is attached.
    'plan.prop.base': { vi: 'Kế hoạch cơ sở', en: 'Base plan' },
    'plan.prop.untitled': { vi: 'Bất động sản', en: 'Property' },
    'plan.prop.viewing': {
        vi: 'Đang xem số liệu của bất động sản này. Chuyển về “Kế hoạch cơ sở” để thử các kịch bản.',
        en: "Showing this property's figures. Switch to “Base plan” to explore what-ifs."
    },
    // Attach a property (Mode-C Phase-B): the manual entry form — the first producer of a
    // normalized property_card (engine §12). Required: price/suburb/state/property_type;
    // optional: year/land/strata. Surfaces the meter 402 (over_limit) + 409 (busy) calmly.
    'plan.attach.cta': { vi: 'Gắn bất động sản', en: 'Attach property' },
    'plan.attach.title': { vi: 'Gắn một bất động sản', en: 'Attach a property' },
    'plan.attach.intro': {
        vi: 'Nhập thông tin bất động sản bạn đang cân nhắc. Chúng tôi sẽ tính lợi suất, dòng tiền và phân tích riêng cho bất động sản này.',
        en: "Enter the property you're considering. We'll compute its yield, cash flow and a per-property analysis."
    },
    'plan.attach.price': { vi: 'Giá (AUD)', en: 'Price (AUD)' },
    'plan.attach.price_ph': { vi: 'ví dụ 850000', en: 'e.g. 850000' },
    'plan.attach.suburb': { vi: 'Khu vực (suburb)', en: 'Suburb' },
    'plan.attach.state': { vi: 'Bang', en: 'State' },
    'plan.attach.ptype': { vi: 'Loại bất động sản', en: 'Property type' },
    'plan.attach.ptype_ph': { vi: 'Chọn loại…', en: 'Choose a type…' },
    // These values ARE the engine `property_fit_investor` enum (closed; validated at the
    // commit seam). The established-vs-new split drives depreciation eligibility — an
    // investor-meaningful label, not a generic dwelling type.
    'plan.attach.ptype.established_house': { vi: 'Nhà có sẵn (đã qua sử dụng)', en: 'Established house' },
    'plan.attach.ptype.established_apartment': { vi: 'Căn hộ có sẵn (đã qua sử dụng)', en: 'Established apartment' },
    'plan.attach.ptype.new_house': { vi: 'Nhà mới', en: 'New house' },
    'plan.attach.ptype.new_apartment': { vi: 'Căn hộ mới', en: 'New apartment' },
    'plan.attach.ptype.off_the_plan': { vi: 'Mua theo bản vẽ (off-the-plan)', en: 'Off-the-plan' },
    'plan.attach.ptype.house_and_land': { vi: 'Gói nhà và đất', en: 'House & land package' },
    'plan.attach.optional': { vi: 'Tùy chọn', en: 'Optional' },
    'plan.attach.year': { vi: 'Năm xây dựng', en: 'Year built' },
    'plan.attach.land': { vi: 'Diện tích đất (m²)', en: 'Land size (m²)' },
    'plan.attach.strata': {
        vi: 'Có phí strata (chung cư / nhà phố có ban quản lý)',
        en: 'Has strata fees (managed unit / townhouse)'
    },
    'plan.attach.cancel': { vi: 'Hủy', en: 'Cancel' },
    'plan.attach.submit': { vi: 'Gắn & phân tích', en: 'Attach & analyse' },
    'plan.attach.submitting': { vi: 'Đang phân tích…', en: 'Analysing…' },
    'plan.attach.err.over_limit': {
        vi: 'Bạn đã dùng hết hạn mức của gói hiện tại. Nâng cấp để gắn bất động sản.',
        en: "You've reached your plan's limit. Upgrade to attach a property."
    },
    'plan.attach.err.busy': {
        vi: 'Kế hoạch đang được tính. Vui lòng thử lại sau giây lát.',
        en: 'The plan is busy computing. Please try again shortly.'
    },
    'plan.attach.err.invalid': {
        vi: 'Thông tin bất động sản chưa hợp lệ. Kiểm tra lại các trường.',
        en: 'The property details are invalid. Please check the fields.'
    },
    'plan.attach.err.generic': {
        vi: 'Không gắn được bất động sản. Vui lòng thử lại.',
        en: "Couldn't attach the property. Please try again."
    },
    // settlement_prep B — contract-date form + the dated critical-path render (§11).
    'plan.settle.cta_enter': { vi: 'Nhập ngày hợp đồng', en: 'Enter contract dates' },
    'plan.settle.cta_update': { vi: 'Cập nhật ngày', en: 'Update dates' },
    'plan.settle.title': { vi: 'Ngày giao dịch', en: 'Transaction dates' },
    'plan.settle.intro': {
        vi: 'Khi hợp đồng đã ký, nhập hai ngày để kích hoạt lộ trình bàn giao theo ngày.',
        en: 'Once your contract is signed, enter the two dates to activate the dated settlement path.'
    },
    'plan.settle.contract_date': { vi: 'Ngày ký hợp đồng', en: 'Contract signed date' },
    'plan.settle.settlement_date': { vi: 'Ngày bàn giao', en: 'Settlement date' },
    'plan.settle.cancel': { vi: 'Hủy', en: 'Cancel' },
    'plan.settle.submit': { vi: 'Lưu ngày', en: 'Save dates' },
    'plan.settle.submitting': { vi: 'Đang lưu…', en: 'Saving…' },
    'plan.settle.err.not_attached': {
        vi: 'Hãy gắn bất động sản trước khi nhập ngày giao dịch.',
        en: 'Attach the property before submitting its transaction dates.'
    },
    'plan.settle.err.busy': {
        vi: 'Kế hoạch đang được tính. Vui lòng thử lại sau giây lát.',
        en: 'The plan is busy computing. Please try again shortly.'
    },
    'plan.settle.err.order': {
        vi: 'Ngày bàn giao phải sau ngày ký hợp đồng.',
        en: 'The settlement date must be after the contract signed date.'
    },
    'plan.settle.err.invalid': {
        vi: 'Ngày chưa hợp lệ. Kiểm tra lại định dạng.',
        en: 'Those dates are invalid. Please check them.'
    },
    'plan.settle.err.generic': {
        vi: 'Không lưu được ngày giao dịch. Vui lòng thử lại.',
        en: "Couldn't save the dates. Please try again."
    },
    // The dated-path render headings + status chrome.
    'plan.settle.awaiting': {
        vi: 'Đang chờ ngày hợp đồng',
        en: 'Awaiting contract dates'
    },
    'plan.settle.critical_path': { vi: 'Lộ trình bàn giao', en: 'Settlement critical path' },
    'plan.settle.investor': { vi: 'Mốc dành cho nhà đầu tư', en: 'Investor milestones' },
    'plan.settle.at_risk': { vi: 'Mốc cần xác nhận (đã qua hạn)', en: 'Milestones to confirm (date passed)' },
    'plan.settle.insurance': { vi: 'Thời điểm bảo hiểm', en: 'Insurance timing' },
    'plan.settle.due': { vi: 'Hạn', en: 'Due' },
    'plan.settle.status.pending': { vi: 'Chờ ngày', en: 'Pending dates' },
    'plan.settle.status.done': { vi: 'Hoàn tất', en: 'Done' },
    'plan.settle.status.scheduled': { vi: 'Đã lên lịch', en: 'Scheduled' },
    'plan.settle.status.at_risk': { vi: 'Quá hạn', en: 'Date passed' },
    'plan.qa.pending': {
        vi: 'Phần hỏi đáp sẽ sẵn sàng khi kế hoạch tính xong.',
        en: 'Q&A opens once your plan finishes computing.'
    },
    // Overview tab — shell-composed synthesis (OverviewCard).
    'plan.ov.lead': {
        vi: 'Kế hoạch của bạn trong 90 giây',
        en: 'Your plan in 90 seconds'
    },
    'plan.ov.partial': {
        vi: 'Một số con số sẽ hiện ra khi bạn bổ sung thu nhập và tiền tiết kiệm.',
        en: 'Some figures unlock once you add your income and savings.'
    },
    // Journey swimlane (purchase_journey) — non-money cell marker tags.
    'plan.journey.flow.document': { vi: 'Hồ sơ', en: 'Doc' },
    'plan.journey.flow.milestone': { vi: 'Mốc', en: 'Step' },

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
    'plan.path.recommended': { vi: 'đề xuất', en: 'recommended' },
    'plan.reach.label': { vi: 'Khả năng với tới', en: 'Your reach' },
    'plan.reach.capacity_pending': {
        vi: 'Khả năng vay sẽ tính khi bạn thêm thu nhập và tiền tiết kiệm.',
        en: 'Borrowing capacity computes once you add income and savings.'
    },

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
    'plan.cash.need': { vi: 'Tiền mặt cần để bắt đầu', en: 'Cash to get in' },
    'plan.cash.deposit': { vi: 'Tiền cọc tối thiểu', en: 'Min. deposit' },
    'plan.cash.other': { vi: 'Chi phí giao dịch khác', en: 'Other costs' },
    'plan.cash.reserve': { vi: 'Quỹ dự phòng sau giao dịch', en: 'Post-settlement buffer' },
    'plan.cash.add_savings': {
        vi: 'Nhập thu nhập và tiền tiết kiệm để biết bạn có đủ hay chưa.',
        en: 'Add your income and savings to see if you’re covered.'
    },
    // Interactive cash what-if (B2) — client-side subtraction vs the engine's need range.
    'plan.cash.whatif.label': { vi: 'Thử số tiền mặt bạn có', en: 'Test your cash on hand' },
    'plan.cash.whatif.placeholder': { vi: 'ví dụ 150.000', en: 'e.g. 150,000' },
    'plan.cash.whatif.spare': { vi: 'Ước tính dư', en: 'Estimated spare' },
    'plan.cash.whatif.shortfall': { vi: 'Ước tính còn thiếu', en: 'Estimated shortfall' },
    'plan.cash.whatif.toptier': {
        vi: 'Đủ mức thấp; còn thiếu so với mức cao',
        en: 'Covers the low end; short of the top by'
    },
    'plan.cash.whatif.disclaimer': {
        vi: 'Đây là ước tính tham khảo so với nhu cầu tiền mặt của bạn — không phải tư vấn tài chính. Muốn thử mức giá khác, hãy cập nhật lại kế hoạch.',
        en: 'An informational estimate against your cash need — not financial advice. To test a different price, refine your plan.'
    },
    // Financial spine — cash_events grouped by lifecycle phase (the calculator's
    // projection, phase-aligned with the swimlane). Phase labels match the swimlane.
    'plan.cash.spine': { vi: 'Dòng tiền theo giai đoạn', en: 'When the money moves' },
    'plan.cash.spine.empty': { vi: 'Chưa có dòng tiền ở giai đoạn này.', en: 'No cash flow at this stage yet.' },
    'plan.cash.col_item': { vi: 'Khoản mục', en: 'Item' },
    'plan.cash.col_amount': { vi: 'Số tiền', en: 'Amount' },
    'plan.cash.breakdown': { vi: 'Chi tiết ngân sách', en: 'Budget breakdown' },
    'plan.cash.recurring': { vi: 'định kỳ', en: 'recurring' },
    'plan.cash.in': { vi: 'nhận về', en: 'in' },
    'plan.cash.out': { vi: 'chi ra', en: 'out' },
    'plan.cash.ready': { vi: 'Bạn đã đủ chưa?', en: 'Am I ready?' },
    'plan.cash.horizon': { vi: 'Cả hành trình', en: 'Full horizon' },
    // Disposition (the dispose-phase figure-owner, lifecycle-simulation-model §8): the
    // sell-side projection + the full-horizon net position. Honest-partial throughout.
    'plan.disp.full_horizon': { vi: 'Vị thế ròng cả hành trình', en: 'Full-horizon net position' },
    'plan.disp.full_horizon_sub': {
        vi: 'Mua → giữ → bán: sau tiền mặt ban đầu và chi phí sở hữu.',
        en: 'Buy → hold → sell: after acquisition cash and holding costs.'
    },
    'plan.disp.sale': { vi: 'Tiền bán (dự phóng)', en: 'Sale proceeds (projected)' },
    'plan.disp.selling': { vi: 'Chi phí bán', en: 'Selling costs' },
    'plan.disp.loan': { vi: 'Tất toán khoản vay', en: 'Loan payout' },
    'plan.disp.net': { vi: 'Tiền ròng nhận về', en: 'Net proceeds' },
    'plan.disp.cgt': { vi: 'Thuế lãi vốn (CGT)', en: 'Capital gains tax (CGT)' },
    'plan.disp.cgt.exempt': { vi: 'Được miễn', en: 'Exempt' },
    'plan.disp.cgt.to_verify': { vi: 'Cần kiểm tra', en: 'To verify' },
    'plan.disp.set_horizon': { vi: 'Chưa có dự phóng khi bán', en: 'No sell-side projection yet' },
    'plan.disp.loan_pending': {
        vi: 'Khoản tất toán vay và tiền ròng sẽ được tính khi biết số tiền vay — bổ sung thu nhập của bạn trong phần trò chuyện.',
        en: 'Loan payout and net proceeds compute once your loan amount is known — add your income in chat.'
    },
    'plan.phase.prepare': { vi: 'Chuẩn bị', en: 'Prepare' },
    'plan.phase.pre_approve': { vi: 'Phê duyệt sơ bộ', en: 'Pre-approval' },
    'plan.phase.contract': { vi: 'Hợp đồng', en: 'Contract' },
    'plan.phase.settle': { vi: 'Bàn giao', en: 'Settle' },
    'plan.phase.own': { vi: 'Sở hữu', en: 'Own' },
    'plan.phase.dispose': { vi: 'Bán nhà', en: 'Sell' },
    // Budget cockpit (the prototype's input form, engine-driven).
    'plan.cockpit.title': { vi: 'Ngân sách — bạn đã sẵn sàng?', en: 'Budget — am I ready?' },
    'plan.cockpit.intro': {
        vi: 'Đổi giá hoặc tiểu bang để tính lại toàn bộ kế hoạch; nhập tiền mặt bạn có để xem còn thiếu bao nhiêu. Phí trước bạ do hệ thống tính chính xác, không phải ước lượng.',
        en: 'Change the price or state to recompute the whole plan; enter your cash on hand to see the gap. Stamp duty is computed exactly, not estimated.'
    },
    'plan.cockpit.ptype': { vi: 'Loại bất động sản', en: 'Property type' },
    'plan.cockpit.ptype.locked': {
        vi: 'Gắn một bất động sản để so sánh nhà mới vs nhà cũ.',
        en: 'Attach a property to compare new vs established.'
    },
    // Preparation → checklist renderer (the prototype's "Before you buy").
    'plan.prep.docs': { vi: 'Giấy tờ cần chuẩn bị', en: 'Documents to gather' },
    'plan.prep.people': { vi: 'Những người cần liên hệ', en: 'People to engage' },
    'plan.prep.schemes': { vi: 'Chương trình cần nộp đơn', en: 'Scheme applications to start' },
    'plan.prep.buffer': { vi: 'Khoản dự phòng tiền mặt', en: 'Money buffer' },
    'plan.prep.when': { vi: 'Khi nào', en: 'When' },
    'plan.prep.why': { vi: 'Vì sao', en: 'Why' },
    'plan.prep.status.not_started': { vi: 'Chưa bắt đầu', en: 'Not started' },
    'plan.prep.status.in_progress': { vi: 'Đang làm', en: 'In progress' },
    'plan.prep.status.done': { vi: 'Xong', en: 'Done' },
    // Flow view → per-phase drill-down sheet (the legal/temporal spine's actionable layer).
    'plan.flow.open': { vi: 'Mở từng giai đoạn', en: 'Open a stage' },
    'plan.flow.close': { vi: 'Đóng', en: 'Close' },
    'plan.flow.actions': { vi: 'Việc cần làm', en: 'What to do' },
    'plan.flow.risks': { vi: 'Rủi ro & cách xử lý', en: 'Risks & what to do' },
    'plan.flow.detail': { vi: 'Xem chi tiết', en: 'See detail' },
    'plan.flow.detail_hide': { vi: 'Ẩn chi tiết', en: 'Hide detail' },
    'plan.flow.done': { vi: 'Đã xong', en: 'Done' },
    'plan.flow.empty': {
        vi: 'Chưa có việc nào ở giai đoạn này.',
        en: 'No actions at this stage yet.'
    },
    // Risk-flag-list → severity chrome + mitigation label.
    'plan.risk.sev.low': { vi: 'Thấp', en: 'Low' },
    'plan.risk.sev.medium': { vi: 'Trung bình', en: 'Medium' },
    'plan.risk.sev.high': { vi: 'Cao', en: 'High' },
    'plan.risk.mitigation': { vi: 'Cách xử lý', en: 'What to do' },
    // Swimlane → who-talks-to-whom (interactions).
    'plan.journey.interactions': { vi: 'Ai làm việc với ai', en: 'Who deals with whom' },
    'plan.journey.to': { vi: '→', en: '→' },
    // Ownership → the graduation milestone (the prototype's "graduation event").
    'plan.grad.title': { vi: 'Cột mốc “tốt nghiệp”', en: 'The “graduation” event' },
    'plan.grad.body': {
        vi: 'Khi tỷ lệ vay (LVR) giảm xuống {lvr}%, chương trình First Home Guarantee hết vai trò: bạn có thể tái cấp vốn tự do, không cần bảo hiểm LMI. Bạn trở thành người vay thông thường.',
        en: 'When your LVR drops below {lvr}%, the First Home Guarantee stops doing work for you — you can refinance freely with no LMI either way. You become a regular mortgage holder.'
    },
    'plan.grad.year': { vi: 'Ước tính vào khoảng năm', en: 'Estimated around year' },
    'plan.grad.year_pending': {
        vi: 'Thời điểm sẽ rõ hơn khi bạn bổ sung khoản vay và tiền tiết kiệm.',
        en: 'The timing becomes clearer once you add your loan and savings.'
    },
    // Overview → "What this is" intro (the prototype's lead card).
    'plan.ov.what.title': { vi: 'Đây là gì', en: 'What this is' },
    'plan.ov.what.body': {
        vi: 'Đây là kế hoạch mua căn nhà đầu tiên được cá nhân hoá cho bạn. Hãy đi qua các thẻ: Tổng quan để xem bức tranh lớn, Tính tiền mặt để nhập số liệu của bạn, Hành trình để xem ai làm gì khi nào, Trước/Sau khi mua cho các bước cụ thể, và Hỏi đáp để hỏi thêm.',
        en: 'This is your personalised plan for buying your first home. Walk the tabs: Overview for the big picture, Cash calculator to plug in your own numbers, Journey for who does what when, Before/After you buy for the concrete steps, and Q&A to ask anything.'
    },
    // Structural what-if (W9) — vary target price / state → engine preview, no save.
    'plan.whatif.title': { vi: 'Thử kịch bản khác', en: 'Try a different scenario' },
    'plan.whatif.price': { vi: 'Giá mục tiêu', en: 'Target price' },
    'plan.whatif.state': { vi: 'Tiểu bang', en: 'State' },
    // The horizon slider (TW6): the dispose-phase hold years H — a structural what-if at
    // plan scope (drives the free simulate, re-renders the Full-horizon tab + Flow dispose
    // column). 0 = no sale projection (the Mode-A long/indefinite default).
    'plan.whatif.horizon': { vi: 'Số năm nắm giữ', en: 'Hold horizon' },
    'plan.whatif.years_unit': { vi: 'năm', en: 'yrs' },
    'plan.whatif.horizon_off': { vi: 'Giữ lâu dài', en: 'Hold indefinitely' },
    'plan.whatif.current': { vi: 'Hiện tại:', en: 'Now:' },
    'plan.whatif.run': { vi: 'Xem thử', en: 'Preview' },
    'plan.whatif.reset': { vi: 'Đặt lại', en: 'Reset' },
    'plan.whatif.running': { vi: 'Đang tính lại…', en: 'Recomputing…' },
    'plan.whatif.banner': {
        vi: 'Bản xem thử — chưa lưu. Đặt lại để xem kế hoạch hiện tại.',
        en: 'Preview — not saved. Reset to see your current plan.'
    },
    'plan.whatif.error': {
        vi: 'Không xem thử được kịch bản này. Vui lòng thử lại.',
        en: 'Couldn’t preview that scenario. Please try again.'
    },
    'plan.whatif.save': { vi: 'Lưu kịch bản này', en: 'Save this scenario' },
    'plan.whatif.saving': { vi: 'Đang lưu…', en: 'Saving…' },
    'plan.whatif.saveerror': {
        vi: 'Không lưu được kịch bản. Vui lòng thử lại.',
        en: 'Couldn’t save the scenario. Please try again.'
    },
    // Budget cockpit — household financials (IC5). A persisted FACT (income + debts) that
    // unblocks borrowing capacity → the full-horizon net position; distinct from the
    // ephemeral price/state what-if and the client-side cash-on-hand figure.
    'plan.fin.title': { vi: 'Tài chính của bạn', en: 'Your finances' },
    'plan.fin.intro': {
        vi: 'Nhập thu nhập và các khoản nợ để hệ thống ước tính khả năng vay và vị thế ròng cả hành trình. Thông tin này được lưu vào kế hoạch của bạn.',
        en: 'Enter your income and debts so we can estimate your borrowing capacity and full-horizon net position. This is saved to your plan.'
    },
    'plan.fin.income': { vi: 'Thu nhập hộ gia đình (trước thuế)', en: 'Household income (before tax)' },
    'plan.fin.income_hint': {
        vi: 'Tổng thu nhập chịu thuế của cả hộ, mỗi năm.',
        en: 'Combined household assessable income, per year.'
    },
    'plan.fin.foreign': { vi: 'Trong đó, thu nhập từ nước ngoài', en: 'of which, foreign-sourced' },
    'plan.fin.debts_label': { vi: 'Các khoản nợ', en: 'Debts' },
    'plan.fin.hecs': { vi: 'Dư nợ HECS/HELP', en: 'HECS/HELP balance' },
    'plan.fin.cards': { vi: 'Tổng hạn mức thẻ tín dụng', en: 'Total credit-card limits' },
    'plan.fin.personal': { vi: 'Vay tiêu dùng', en: 'Personal loans' },
    'plan.fin.car': { vi: 'Vay mua xe', en: 'Car loan' },
    'plan.fin.bnpl': { vi: 'Mua trước trả sau (BNPL)', en: 'Buy now, pay later (BNPL)' },
    'plan.fin.placeholder': { vi: 'ví dụ 95.000', en: 'e.g. 95,000' },
    'plan.fin.placeholder0': { vi: 'ví dụ 0', en: 'e.g. 0' },
    'plan.fin.save': { vi: 'Cập nhật tài chính', en: 'Update my finances' },
    'plan.fin.saving': { vi: 'Đang lưu…', en: 'Saving…' },
    'plan.fin.recomputing': {
        vi: 'Đang tính lại kế hoạch với số liệu mới…',
        en: 'Recomputing your plan with the new figures…'
    },
    'plan.fin.busy': {
        vi: 'Một bản cập nhật đang chạy. Vui lòng thử lại sau giây lát.',
        en: 'An update is already running. Please try again shortly.'
    },
    'plan.fin.error': { vi: 'Không lưu được. Vui lòng thử lại.', en: 'Couldn’t save. Please try again.' },
    'plan.fin.disclaimer': {
        vi: 'Khả năng vay là ước tính theo dải, dựa trên quy ước của người cho vay — không phải lời khuyên tài chính hay cam kết cho vay.',
        en: 'Borrowing capacity is a banded estimate based on lender conventions — not financial advice or a loan commitment.'
    },
    'plan.verdict.surplus': { vi: 'Dư', en: 'Surplus' },
    'plan.verdict.tight': { vi: 'Vừa đủ', en: 'Tight' },
    'plan.verdict.short': { vi: 'Còn thiếu', en: 'Short' },
    'plan.gsv.meets': { vi: 'Đạt', en: 'Meets' },
    'plan.gsv.fails_recent_gift': { vi: 'Vướng tiền tặng gần đây', en: 'Recent gift' },
    'plan.gsv.insufficient_track_record': { vi: 'Chưa đủ lịch sử tiết kiệm', en: 'Insufficient history' },
    'plan.gsv.unknown': { vi: 'Cần xác minh', en: 'To verify' },

    'plan.f.recurring': { vi: 'Chi phí định kỳ (ước tính)', en: 'Recurring costs (est.)' },
    'plan.f.statutory': { vi: 'Phí pháp định (rates + nước)', en: 'Council + water' },
    'plan.f.strata': { vi: 'Phí chung cư', en: 'Strata levies' },
    'plan.f.utilities': { vi: 'Điện nước', en: 'Utilities' },
    'plan.f.insurance': { vi: 'Bảo hiểm công trình', en: 'Building insurance' },
    'plan.f.land_tax': { vi: 'Thuế đất', en: 'Land tax' },
    'plan.f.maintenance': { vi: 'Quỹ bảo trì mỗi năm', en: 'Maintenance reserve / yr' },
    'plan.f.monthly': { vi: 'Chi phí hàng tháng', en: 'Monthly outgoings' },
    'plan.f.annual': { vi: 'Chi phí hàng năm', en: 'Annual outgoings' },
    'plan.f.alerts': { vi: 'Nhắc nhở đã bật', en: 'Alerts armed' },
    'plan.landtax.exempt_ppor': { vi: 'Miễn (nhà ở chính)', en: 'Exempt (your home)' },
    'plan.landtax.applicable': { vi: 'Có áp dụng', en: 'Applicable' },
    'plan.landtax.to_verify': { vi: 'Cần xác minh', en: 'To verify' },

    // --- Investor (Mode C) renderers ----------------------------------------
    // buying-strategy-card (buying_strategy → bid_plan_investor): the bid-discipline
    // price ladder + the closed thesis/style enums (mapped to display labels here).
    'plan.f.max_bid': { vi: 'Giá đặt tối đa', en: 'Max bid' },
    'plan.f.walk_away': { vi: 'Giá rút lui', en: 'Walk-away price' },
    'plan.f.yield_ceiling': { vi: 'Trần giá theo lợi suất', en: 'Yield-anchored ceiling' },
    'plan.f.thesis': { vi: 'Mức phù hợp chiến lược', en: 'Thesis alignment' },
    'plan.f.nego_style': { vi: 'Phong cách thương lượng', en: 'Negotiation style' },
    'plan.f.comparables': { vi: 'Giao dịch so sánh', en: 'Comparable sales' },
    'plan.f.conditions': { vi: 'Điều kiện trong đề nghị', en: 'Offer conditions' },
    'plan.thesis.aligned': { vi: 'Phù hợp', en: 'Aligned' },
    'plan.thesis.stretched': { vi: 'Hơi quá tầm', en: 'Stretched' },
    'plan.thesis.misaligned': { vi: 'Lệch chiến lược', en: 'Misaligned' },
    'plan.style.assertive': { vi: 'Quyết đoán', en: 'Assertive' },
    'plan.style.patient': { vi: 'Kiên nhẫn', en: 'Patient' },
    'plan.style.early_offer': { vi: 'Ra giá sớm', en: 'Early offer' },
    'plan.style.low_anchor': { vi: 'Neo giá thấp', en: 'Low anchor' },
    'plan.style.thesis_walk_away': { vi: 'Kỷ luật, sẵn sàng rút', en: 'Disciplined walk-away' },
    // opportunity-card (ownership_planning_investor): modelled opportunities to act on.
    'plan.f.modeled_benefit': { vi: 'Lợi ích ước tính', en: 'Modelled benefit' },
    'plan.opp.none': {
        vi: 'Chưa có cơ hội nào được mô hình hoá.',
        en: 'No opportunities modelled yet.'
    },

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
    'account.title': { vi: 'Tài khoản', en: 'Account' },
    'account.menu': { vi: 'Menu tài khoản', en: 'Account menu' },
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
    'auth.expired.cue': {
        vi: 'Phiên đăng nhập đã hết hạn — đăng nhập lại để xem các kế hoạch đã lưu.',
        en: 'Your session expired — sign in again to see your saved plans.'
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
