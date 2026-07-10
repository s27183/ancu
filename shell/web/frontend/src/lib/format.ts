// Locale-aware figure formatting for the plan projection. Figures are single-valued
// engine outputs (not LocalizedText) — only the *formatting* (grouping, currency
// placement) follows the display language. AUD is the buyer's purchase currency in
// Wedge 1a; VND framing arrives with the RBA FX feed (onboarding.ts note), so we do
// not invent a rate here.
import type { Lang, MoneyRange } from '$lib/planCard';

function locale(lang: Lang): string {
    return lang === 'vi' ? 'vi-VN' : 'en-AU';
}

/** Whole-dollar AUD, e.g. "$650,000" / "650.000 AUD" depending on locale. */
export function money(n: number | null | undefined, lang: Lang): string | null {
    if (typeof n !== 'number' || !Number.isFinite(n)) return null;
    return new Intl.NumberFormat(locale(lang), {
        style: 'currency',
        currency: 'AUD',
        maximumFractionDigits: 0
    }).format(n);
}

/** A money range "[$500,000 – $650,000]"; null if neither bound is a number. */
export function moneyRange(r: MoneyRange | null | undefined, lang: Lang): string | null {
    if (!Array.isArray(r)) return null;
    const lo = money(r[0], lang);
    const hi = money(r[1], lang);
    if (lo === null && hi === null) return null;
    if (lo === null) return hi;
    if (hi === null) return lo;
    return `${lo} – ${hi}`;
}

/** Upgrades a scalar `money` point to a degenerate `[v, v]` range; passes a real range
 *  through unchanged; null/undefined/malformed → null. Mirrors the Erlang-side
 *  `money_range/1` helper `fh_engine_disposition` already uses to read Mode C/D's
 *  `total_cash_required` (typed scalar for those modes — fh_engine_cash.erl SEAMS note) —
 *  use this instead of a bare `Array.isArray` check for any field typed `MoneyRange | number | null`. */
export function asRange(v: MoneyRange | number | null | undefined): MoneyRange | null {
    if (Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number') {
        return v;
    }
    if (typeof v === 'number' && Number.isFinite(v)) return [v, v];
    return null;
}

/** A plain grouped integer (no currency), e.g. a count. */
export function num(n: number | null | undefined, lang: Lang): string | null {
    if (typeof n !== 'number' || !Number.isFinite(n)) return null;
    return new Intl.NumberFormat(locale(lang)).format(n);
}
