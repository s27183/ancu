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
    'nav.home': { vi: 'Trang chính', en: 'Home' },
    'nav.status': { vi: 'Trạng thái', en: 'Status' },
    'lang.label': { vi: 'Ngôn ngữ', en: 'Language' },

    'map.state.label': { vi: 'Bang', en: 'State' },
    'map.legend.title': { vi: 'Tỉ lệ cộng đồng gốc Việt', en: 'Vietnamese ancestry' },
    'map.legend.nodata': { vi: 'Chưa có dữ liệu', en: 'No data' },
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

    'status.title': { vi: 'Trạng thái hệ thống', en: 'System status' },
    'status.checking': { vi: 'Đang kiểm tra…', en: 'Checking…' },
    'status.ok': { vi: 'Backend đang hoạt động', en: 'Backend is up' },
    'status.fail': { vi: 'Không kết nối được backend', en: 'Backend unreachable' }
} as const;

export type MessageKey = keyof typeof messages;

export const t = derived(lang, ($lang) => (key: MessageKey) => messages[key][$lang]);
