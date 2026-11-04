// Regulated figures are grounded -> each state's capital-city figures -> the web frontend ->
// the map filter's ranked states
// Goal:      behavior 154 (Son 2026-11-04: «some info about each state, ranked by their
//            city's population (Sydney first?)»): the filter's state list runs by its
//            capital city's population, and a chosen state shows that city's population
//            and its median house and attached-dwelling prices.
// Invariant: every figure comes from kb.facts.capital-cities as /api/facts serves it (each
//            quoted from the ABS, GATE 12); none is authored here. A figure shows only from
//            a finite value > 0 under a known capital's label; anything else leaves that
//            figure out. The list is always the 8 states: those with a population first,
//            largest first, then the rest in the shipped ranking (STATE_ORDER). AU_STATES itself keeps its
//            order (the plan pages iterate it). Nothing here throws.
// Capability: pure over getFacts' answer, so unit/stateInfo.test.ts runs it over hostile ones.
import type { AuState } from './map';

/** The fixed order for a state with no population: the capitals' order by population as
 *  of kb.facts.capital-cities (ACT before TAS), so the list reads the same when /api/facts
 *  fails. Kept here, typed against map.ts's AuState, because map.ts loads MapLibre and so
 *  cannot run under node --test; the type keeps it to the same 8 states. */
const STATE_ORDER: readonly AuState[] = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'ACT', 'TAS', 'NT'];

/** Each state's capital city, as the ABS names its Greater Capital City Statistical Area
 *  (kb.facts.capital-cities' item labels). Proper names, never translated. */
export const STATE_CAPITALS: Record<AuState, string> = {
    NSW: 'Sydney',
    VIC: 'Melbourne',
    QLD: 'Brisbane',
    WA: 'Perth',
    SA: 'Adelaide',
    TAS: 'Hobart',
    ACT: 'Canberra',
    NT: 'Darwin'
};

export const CAPITALS_DOC = 'kb.facts.capital-cities';

export interface StateRow {
    state: AuState;
    capital: string;
    /** People at 30 June 2025, or null. */
    population: number | null;
    /** Median prices, $'000, June quarter 2026, or null. */
    house: number | null;
    attached: number | null;
}

function figures(doc: unknown, id: string): Map<string, number> {
    const out = new Map<string, number>();
    const facts = (doc as { facts?: unknown })?.facts;
    if (!Array.isArray(facts)) return out;
    const fact = facts.find((f) => (f as { id?: unknown })?.id === id) as { items?: unknown } | undefined;
    if (!fact || !Array.isArray(fact.items)) return out;
    for (const it of fact.items as unknown[]) {
        const label = (it as { label?: unknown })?.label;
        const value = (it as { value?: unknown })?.value;
        const name = typeof label === 'string' ? label : typeof (label as { en?: unknown })?.en === 'string' ? (label as { en: string }).en : null;
        if (name === null || out.has(name)) continue; // the first under a label counts
        if (typeof value === 'number' && Number.isFinite(value) && value > 0) out.set(name, value);
    }
    return out;
}

/** The 8 states, ranked by capital-city population where /api/facts gives one. */
export function stateRows(docs: unknown): StateRow[] {
    const doc = Array.isArray(docs) ? docs.find((d) => (d as { slug?: unknown })?.slug === CAPITALS_DOC) : undefined;
    const pop = figures(doc, 'capital_city_population');
    const house = figures(doc, 'capital_city_house_median');
    const attached = figures(doc, 'capital_city_attached_median');
    const rows = STATE_ORDER.map((state, i) => {
        const capital = STATE_CAPITALS[state];
        return { i, row: { state, capital, population: pop.get(capital) ?? null, house: house.get(capital) ?? null, attached: attached.get(capital) ?? null } };
    });
    rows.sort((a, b) => {
        const pa = a.row.population, pb = b.row.population;
        if (pa !== null && pb !== null) return pb - pa || a.i - b.i;
        if (pa !== null) return -1;
        if (pb !== null) return 1;
        return a.i - b.i;
    });
    return rows.map((r) => r.row);
}

/** 5638830 → "5,6 tr" (vi) / "5.6m" (en); under a million → "484.630" / "484,630". */
export function popShort(n: number, lang: 'vi' | 'en'): string {
    const loc = lang === 'vi' ? 'vi-VN' : 'en-AU';
    if (n >= 1e6) {
        const m = new Intl.NumberFormat(loc, { maximumFractionDigits: 1 }).format(Math.round(n / 1e5) / 10);
        return lang === 'vi' ? `${m} tr` : `${m}m`;
    }
    return new Intl.NumberFormat(loc).format(Math.round(n));
}

export function popFull(n: number, lang: 'vi' | 'en'): string {
    return new Intl.NumberFormat(lang === 'vi' ? 'vi-VN' : 'en-AU').format(Math.round(n));
}

/** $'000 → "1,49 tr AUD" / "$1.49m"; under a million → "840 nghìn AUD" / "$840k". */
export function priceK(k: number, lang: 'vi' | 'en'): string {
    const loc = lang === 'vi' ? 'vi-VN' : 'en-AU';
    if (k >= 1000) {
        const m = new Intl.NumberFormat(loc, { maximumFractionDigits: 2 }).format(Math.round(k / 10) / 100);
        return lang === 'vi' ? `${m} tr AUD` : `$${m}m`;
    }
    const v = new Intl.NumberFormat(loc, { maximumFractionDigits: 0 }).format(Math.round(k));
    return lang === 'vi' ? `${v} nghìn AUD` : `$${v}k`;
}
