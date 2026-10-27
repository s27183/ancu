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
    /** `statement` (behavior 44): no number — headline and caption carry the fact. */
    visual: 'bars' | 'series' | 'figure' | 'split' | 'growth' | 'statement';
    /** A statement's picture (behavior 49): the land parcel by default, or a health cross. */
    glyph?: 'health';
    /** Absent on a statement. */
    unit?: 'count' | 'people' | 'pct' | 'aud_k' | 'aud' | 'years' | 'usd_bn' | 'aud_bn' | 'aud_m' | 'million' | 'km';
    /** Digits after the point, fixed (behavior 124: DFAT's "2.0%" stays 2.0%). */
    decimals?: number;
    headline: Localized;
    caption: Localized;
    /** YYYY-MM */
    as_of: string;
    /** Index into the doc's `sources`, or several (a rule and its exception). */
    source: number | number[];
    value?: number;
    /** `now_label` names the current row ("2025"); absent, it reads "now". */
    compare?: { label: Label; value: number; now_label?: Label };
    items?: FactItem[];
    /** What the figure covers and leaves out (behavior 46), shown under the caption. */
    note?: Localized;
    /** Indices into the doc's `sources` the note quotes; the first is linked. */
    note_sources?: number[];
}

export interface FactSource {
    url?: string;
    retrieved?: string;
    path?: string;
    note?: string;
    /** Behavior 49: a named non-government ranking (EIU), labelled as such in the sheet. */
    kind?: 'ranking' | 'reference';
    /** Behavior 133: a named reference work, where no government publishes the answer (none is named since behavior 138 removed Highway 1). */
}

export interface FactDoc {
    slug: string;
    title: Localized;
    /** News notes that explain the section (behavior 125), linked under it on /facts. */
    news?: string[];
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

// The display order of the sheet's fact sections: where Vietnamese buyers stand, then
// why Australian property (Son's brief, behavior 42), then what settling there gives a
// family (behavior 47: people buy because they mean to settle).
export const SECTION_ORDER = [
    'kb.facts.vietnamese-in-australia',
    'kb.facts.australian-property',
    'kb.facts.living-in-australia'
];

// The facts page's order (/facts, behavior 126, Son 2026-10-18): by what a buyer asks, in
// the order they ask it — what the money is worth (the RBA rate, drawn before these), what
// the visa costs, how the economy stands, the property itself, settling in, then where
// Vietnamese buyers stand. A fact doc the KB adds later and this list does not name
// follows them, never ahead. The Introduction sheet keeps SECTION_ORDER.
export const PAGE_ORDER = [
    'kb.facts.visa-charges',
    'kb.facts.australian-economy',
    'kb.facts.australian-property',
    'kb.facts.living-in-australia',
    'kb.facts.vietnamese-in-australia'
];

/** Behavior 126: each section's short name for the chips on /facts (i18n `facts.chip.<key>`);
 *  a doc not named here is chipped by its title. */
export const CHIP_KEY: Record<string, string> = {
    'kb.facts.visa-charges': 'visa',
    'kb.facts.australian-economy': 'economy',
    'kb.facts.australian-property': 'property',
    'kb.facts.living-in-australia': 'living',
    'kb.facts.vietnamese-in-australia': 'vietnamese'
};

export function pageRank(slug: string): number {
    const i = PAGE_ORDER.indexOf(slug);
    return i < 0 ? PAGE_ORDER.length : i;
}

/** Behavior 126: the key figures that open /facts — each names a KB fact by doc and id
 *  (and, for a list, its highlighted item), so its value is the card's own, never typed
 *  here. `rank`: the highlighted item's place by value ("Vietnam is 3rd"). The rate (fx)
 *  comes from GET /api/fx, drawn by the page. */
export interface KeyFigureSpec {
    key: string;
    slug: string;
    fact: string;
    pick?: 'highlight';
    rank?: boolean;
}
export const KEY_FIGURES: KeyFigureSpec[] = [
    { key: 'visa189', slug: 'kb.facts.visa-charges', fact: 'skilled_employer', pick: 'highlight' },
    { key: 'gdp', slug: 'kb.facts.australian-economy', fact: 'real_gdp_growth' },
    { key: 'population', slug: 'kb.facts.australian-property', fact: 'population_growth' },
    { key: 'wage', slug: 'kb.facts.living-in-australia', fact: 'minimum_wage' },
    { key: 'vnrank', slug: 'kb.facts.vietnamese-in-australia', fact: 'firb_top_sources_quarter', rank: true }
];

/** The figure a spec names, formatted as its card formats it; null when the KB lacks it. */
export function keyFigure(docs: FactDoc[], spec: KeyFigureSpec, lang: Lang): { value: string; rank?: number } | null {
    const f = docs.find((d) => d.slug === spec.slug)?.facts.find((x) => x.id === spec.fact);
    if (!f) return null;
    if (spec.rank) {
        const items = [...(f.items ?? [])].sort((a, b) => b.value - a.value);
        const i = items.findIndex((x) => x.highlight);
        return i < 0 ? null : { value: String(i + 1), rank: i + 1 };
    }
    const v = spec.pick ? f.items?.find((x) => x.highlight)?.value : f.value;
    return v === undefined ? null : { value: formatValue(v, f.unit, lang, f.decimals) };
}

export function pick(l: Label | undefined, lang: Lang): string {
    if (!l) return '';
    return typeof l === 'string' ? l : (l[lang] ?? l.en);
}

const LOCALE: Record<Lang, string> = { vi: 'vi-VN', en: 'en-AU' };

/** A figure as a reader says it: grouped digits, a % for shares, $…k / $…m for prices
 *  given in $'000, dollars and cents for a wage or a fee. A figure keeps the decimals
 *  its source gives (24.92%, 12.8, 81.1 years — behavior 47), up to two. */
export function formatValue(n: number, unit: Fact['unit'], lang: Lang, decimals?: number): string {
    const nf = (v: number, digits = 0) =>
        new Intl.NumberFormat(LOCALE[lang], {
            maximumFractionDigits: decimals ?? digits,
            minimumFractionDigits: decimals ?? 0
        }).format(v);
    if (unit === 'pct') return `${nf(n, 2)}%`;
    if (unit === 'aud_k') return n >= 1000 ? `$${nf(n / 1000, 2)}m` : `$${nf(n)}k`;
    if (unit === 'aud')
        return `$${new Intl.NumberFormat(LOCALE[lang], {
            minimumFractionDigits: Number.isInteger(n) ? 0 : 2,
            maximumFractionDigits: 2
        }).format(n)}`;
    if (unit === 'years') return lang === 'vi' ? `${nf(n, 2)} tuổi` : `${nf(n, 2)} yrs`;
    // Behavior 124: DFAT's figures in their own scale; Vietnamese names the scale in words.
    if (unit === 'usd_bn') return lang === 'vi' ? `${nf(n, 1)} tỷ USD` : `US$${nf(n, 1)}b`;
    if (unit === 'aud_bn') return lang === 'vi' ? `${nf(n, 1)} tỷ AUD` : `A$${nf(n, 1)}b`;
    if (unit === 'aud_m') return lang === 'vi' ? `${nf(n, 1)} triệu AUD` : `A$${nf(n, 1)}m`;
    if (unit === 'million') return lang === 'vi' ? `${nf(n, 1)} triệu` : `${nf(n, 1)}m`;
    // Behavior 133: BITRE's road lengths and intercapital distances.
    if (unit === 'km') return `${nf(n)} km`;
    return nf(n, 2);
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
    'immi.homeaffairs.gov.au': { en: 'Department of Home Affairs', vi: 'Bộ Nội vụ Úc' },
    'www.homeaffairs.gov.au': { en: 'Department of Home Affairs', vi: 'Bộ Nội vụ Úc' },
    'www.dfat.gov.au': { en: 'Department of Foreign Affairs and Trade (DFAT)', vi: 'Bộ Ngoại giao và Thương mại Úc (DFAT)' },
    'www.abs.gov.au': { en: 'Australian Bureau of Statistics', vi: 'Cục Thống kê Úc (ABS)' },
    'www.dcceew.gov.au': {
        en: 'Department of Climate Change, Energy, the Environment and Water',
        vi: 'Bộ Biến đổi Khí hậu, Năng lượng, Môi trường và Nước Úc'
    },
    'www.health.gov.au': { en: 'Department of Health', vi: 'Bộ Y tế Úc' },
    // Behavior 132: the Commonwealth's land transport program, named as its site names itself.
    'investment.infrastructure.gov.au': {
        en: 'Infrastructure Investment Program, Australian Government',
        vi: 'Chương trình Đầu tư Hạ tầng của Chính phủ Úc'
    },
    'www.pbs.gov.au': {
        en: 'Pharmaceutical Benefits Scheme',
        vi: 'Chương trình Trợ giá Thuốc (PBS)'
    },
    'www.fairwork.gov.au': { en: 'Fair Work Ombudsman', vi: 'Thanh tra Lao động Công bằng (Fair Work)' },
    'www.qld.gov.au': { en: 'Queensland Government', vi: 'Chính quyền bang Queensland' },
    'www.planning.act.gov.au': { en: 'ACT Planning', vi: 'Cơ quan Quy hoạch ACT' },
    // Behavior 114: the government bodies a Hành trình step's rule cites (GATE 16 admits
    // only *.gov.au), named as a reader knows them.
    'www.ato.gov.au': { en: 'Australian Taxation Office (ATO)', vi: 'Sở Thuế Úc (ATO)' },
    'asic.gov.au': { en: 'ASIC', vi: 'Ủy ban Chứng khoán và Đầu tư Úc (ASIC)' },
    'download.asic.gov.au': { en: 'ASIC', vi: 'Ủy ban Chứng khoán và Đầu tư Úc (ASIC)' },
    'moneysmart.gov.au': { en: 'ASIC Moneysmart', vi: 'Moneysmart của ASIC' },
    'www.apra.gov.au': { en: 'APRA', vi: 'Cơ quan Quản lý Thận trọng Úc (APRA)' },
    'handbook.apra.gov.au': { en: 'APRA', vi: 'Cơ quan Quản lý Thận trọng Úc (APRA)' },
    'www.austrac.gov.au': { en: 'AUSTRAC', vi: 'Cơ quan Phòng chống Rửa tiền Úc (AUSTRAC)' },
    'firsthomebuyers.gov.au': { en: 'Housing Australia', vi: 'Housing Australia (cơ quan nhà ở liên bang)' },
    'www.arnecc.gov.au': { en: 'ARNECC', vi: 'Hội đồng Chuyển nhượng Điện tử Quốc gia (ARNECC)' },
    'www.legislation.gov.au': { en: 'Federal Register of Legislation', vi: 'Công báo Luật liên bang Úc' },
    'www.revenue.nsw.gov.au': { en: 'Revenue NSW', vi: 'Sở Thuế bang NSW (Revenue NSW)' },
    'www.nsw.gov.au': { en: 'NSW Government', vi: 'Chính quyền bang NSW' },
    'www.fairtrading.nsw.gov.au': { en: 'NSW Fair Trading', vi: 'Cơ quan Thương mại Công bằng NSW' },
    'legislation.nsw.gov.au': { en: 'NSW Legislation', vi: 'Luật bang NSW' },
    'www.sro.vic.gov.au': { en: 'State Revenue Office Victoria', vi: 'Sở Thuế bang Victoria (SRO)' },
    'www.legislation.vic.gov.au': { en: 'Victorian Legislation', vi: 'Luật bang Victoria' },
    'qro.qld.gov.au': { en: 'Queensland Revenue Office', vi: 'Sở Thuế bang Queensland (QRO)' },
    'www.legislation.qld.gov.au': { en: 'Queensland Legislation', vi: 'Luật bang Queensland' },
    'www.wa.gov.au': { en: 'WA Government', vi: 'Chính quyền bang WA' },
    'www.revenuesa.sa.gov.au': { en: 'RevenueSA', vi: 'Sở Thuế bang SA (RevenueSA)' },
    'www.sro.tas.gov.au': { en: 'State Revenue Office Tasmania', vi: 'Sở Thuế bang Tasmania (SRO)' },
    'sro.tas.gov.au': { en: 'State Revenue Office Tasmania', vi: 'Sở Thuế bang Tasmania (SRO)' },
    'www.revenue.act.gov.au': { en: 'ACT Revenue Office', vi: 'Sở Thuế ACT' },
    // Behavior 49: the one non-government source GATE 12 admits (FACT_RANKING_SOURCES),
    // EIU's own release and its table, distributed through PR Newswire.
    'www.prnewswire.com': { en: 'EIU', vi: 'EIU' },
    'mmx.prnewswire.com': { en: 'EIU', vi: 'EIU' },
    'www.bitre.gov.au': {
        en: 'Bureau of Infrastructure and Transport Research Economics (BITRE)',
        vi: 'Cục Nghiên cứu Kinh tế Hạ tầng và Giao thông Úc (BITRE)'
    }
};

/** The sources a fact cites, in its own order, one per publisher (EIU's release and its
 *  table both read "EIU"; the first is linked). */
export function factSources(doc: FactDoc, fact: Fact): FactSource[] {
    const idx = Array.isArray(fact.source) ? fact.source : [fact.source];
    const seen = new Set<string>();
    return idx
        .map((i) => doc.sources[i])
        .filter((s): s is FactSource => !!s)
        .filter((s) => {
            const who = publisher(s, 'en') || String(s.url);
            if (seen.has(who)) return false;
            seen.add(who);
            return true;
        });
}

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
