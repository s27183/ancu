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

    'home.placeholder': {
        vi: 'Bản đồ khu vực sẽ xuất hiện ở đây (8-S2).',
        en: 'The suburb-intelligence map will land here (8-S2).'
    },

    'status.title': { vi: 'Trạng thái hệ thống', en: 'System status' },
    'status.checking': { vi: 'Đang kiểm tra…', en: 'Checking…' },
    'status.ok': { vi: 'Backend đang hoạt động', en: 'Backend is up' },
    'status.fail': { vi: 'Không kết nối được backend', en: 'Backend unreachable' }
} as const;

export type MessageKey = keyof typeof messages;

export const t = derived(lang, ($lang) => (key: MessageKey) => messages[key][$lang]);
