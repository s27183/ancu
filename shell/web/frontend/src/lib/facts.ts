// The first-visit sheet's data (behavior 42): the KB fact docs compiled from
// docs/kb/facts/*.md (kb_compiler.py GATE 12 — every figure quotes an archived
// government primary), served at GET /api/facts. This module only types, fetches and
// formats them; the figures are never authored here.
import type { Lang } from '$lib/stores/lang';

export type Localized = { en: string; vi: string };
/** A proper name reads the same in every locale, so the KB may give a plain string. */
export type Label = Localized | string;

export interface FactItem {
    label: Label;
    value: number;
    /** `growth` only: the starting value the item grew from. */
    from?: number;
    highlight?: boolean;
    /** A period not yet complete (a year-to-date bar). */
    partial?: boolean;
    /** How a computed item was derived from quoted numbers. */
    derived?: string;
}

export interface Fact {
    id: string;
    visual: 'bars' | 'series' | 'figure' | 'split' | 'growth';
    unit: 'count' | 'people' | 'pct' | 'aud_k';
    headline: Localized;
    caption: Localized;
    /** YYYY-MM */
    as_of: string;
    /** Index into the doc's `sources`. */
    source: number;
    value?: number;
    compare?: { label: Label; value: number };
    items?: FactItem[];
}

export interface FactSource {
    url?: string;
    retrieved?: string;
    path?: string;
    note?: string;
}

export interface FactDoc {
    slug: string;
    title: Localized;
    last_verified: string;
    sources: FactSource[];
    facts: Fact[];
}

/** GET /api/facts — PUBLIC like /api/news. A failure yields no facts (the sheet still
 *  opens with its introduction), never an error screen. */
export async function getFacts(fetchFn: typeof fetch = fetch): Promise<FactDoc[]> {
    try {
        const res = await fetchFn('/api/facts');
        if (!res.ok) return [];
        const body = (await res.json()) as { facts?: FactDoc[] };
        return body.facts ?? [];
    } catch {
        return [];
    }
}

// The display order of the sheet's two fact sections: where Vietnamese buyers stand,
// then why Australian property (Son's brief, behavior 42).
export const SECTION_ORDER = ['kb.facts.vietnamese-in-australia', 'kb.facts.australian-property'];

export function pick(l: Label | undefined, lang: Lang): string {
    if (!l) return '';
    return typeof l === 'string' ? l : (l[lang] ?? l.en);
}

const LOCALE: Record<Lang, string> = { vi: 'vi-VN', en: 'en-AU' };

/** A figure as a reader says it: grouped digits, a % for shares, $…k / $…m for prices
 *  given in $'000. */
export function formatValue(n: number, unit: Fact['unit'], lang: Lang): string {
    const nf = (v: number, digits = 0) =>
        new Intl.NumberFormat(LOCALE[lang], {
            maximumFractionDigits: digits,
            minimumFractionDigits: 0
        }).format(v);
    if (unit === 'pct') return `${nf(n, 1)}%`;
    if (unit === 'aud_k') return n >= 1000 ? `$${nf(n / 1000, 2)}m` : `$${nf(n)}k`;
    return nf(n);
}

/** "Mar 2026" / "tháng 3/2026" from YYYY-MM. */
export function formatAsOf(asOf: string, lang: Lang): string {
    const [y, m] = asOf.split('-').map(Number);
    if (!y || !m) return asOf;
    if (lang === 'vi') return `tháng ${m}/${y}`;
    return new Intl.DateTimeFormat('en-AU', { month: 'short', year: 'numeric', timeZone: 'UTC' }).format(
        new Date(Date.UTC(y, m - 1, 1))
    );
}

// Who publishes each source host, as the sheet names it under a figure. Hosts are the
// government primaries GATE 12 admits; an unknown one shows its host name.
const PUBLISHERS: Record<string, Localized> = {
    'foreigninvestment.gov.au': {
        en: 'Foreign Investment Review Board',
        vi: 'Hội đồng Thẩm định Đầu tư Nước ngoài (FIRB)'
    },
    'www.homeaffairs.gov.au': { en: 'Department of Home Affairs', vi: 'Bộ Nội vụ Úc' },
    'www.abs.gov.au': { en: 'Australian Bureau of Statistics', vi: 'Cục Thống kê Úc (ABS)' }
};

export function publisher(src: FactSource | undefined, lang: Lang): string {
    if (!src?.url) return '';
    let host = '';
    try {
        host = new URL(src.url).hostname;
    } catch {
        return '';
    }
    return PUBLISHERS[host]?.[lang] ?? host;
}

/** Shares rounded to whole cells of a 10×10 grid that sum to exactly 100 (largest
 *  remainder), so a split whose published shares add to 101 still fills the grid once. */
export function waffleCells(values: number[]): number[] {
    const total = values.reduce((a, b) => a + b, 0) || 1;
    const raw = values.map((v) => (v / total) * 100);
    const cells = raw.map(Math.floor);
    let left = 100 - cells.reduce((a, b) => a + b, 0);
    const order = raw.map((r, i) => [r - Math.floor(r), i] as const).sort((a, b) => b[0] - a[0]);
    for (const [, i] of order) {
        if (left <= 0) break;
        cells[i] += 1;
        left -= 1;
    }
    return cells;
}

// The first-visit flag (behavior 42, its Approach): "first time" means this browser
// has never closed the sheet. Kept in localStorage beside ancu-lang; no login needed,
// so a signed-in user on a new browser sees the sheet once there. Storage that throws
// (private mode) reads as not seen — the sheet opens, it just cannot be remembered.
const SEEN_KEY = 'ancu-intro-seen';

export function introSeen(): boolean {
    try {
        return localStorage.getItem(SEEN_KEY) === '1';
    } catch {
        return false;
    }
}

export function markIntroSeen(): void {
    try {
        localStorage.setItem(SEEN_KEY, '1');
    } catch {
        // storage disabled — the sheet will open again next visit
    }
}
