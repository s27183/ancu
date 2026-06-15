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

/** A plain grouped integer (no currency), e.g. a count. */
export function num(n: number | null | undefined, lang: Lang): string | null {
    if (typeof n !== 'number' || !Number.isFinite(n)) return null;
    return new Intl.NumberFormat(locale(lang)).format(n);
}
