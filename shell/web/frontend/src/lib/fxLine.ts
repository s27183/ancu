// Regulated figures are grounded -> the RBA's AUD rate (behavior 123) -> the web frontend ->
// the AUD line before the listing-site links
// Goal:      behavior 153 (Son 2026-11-04: «state explicitly that the price is in Australian
//            Dollar … adding FX rate»): the listing sheet and /market's listing sites say the
//            prices there are in AUD, with the RBA's rate and its date.
// Invariant: a rate is drawn only from getFx's answer with a VND rate > 0 and a YYYY-MM-DD
//            date that is a real day; anything else gives null and the AUD sentence stands
//            alone — never "NaN", "0" or "undefined". It is the RBA's rate (rates.VND), never
//            the bank's quote. Run by unit/fxLine.test.ts over 300 random /api/fx answers.
// Capability: Intl in the page's language — "1 AUD = 17.970 VND · RBA, 16 thg 10, 2026" in
//            Vietnamese, "1 AUD = 17,970 VND · RBA, 16 Oct 2026" in English (node 26 and
//            Chrome share ICU's formats, measured 2026-11-04).
import type { FxRate } from './fx';

const DAY = /^(\d{4})-(\d{2})-(\d{2})$/;

export function audRate(fx: FxRate | null, lang: 'vi' | 'en'): string | null {
    const vnd = fx?.rates?.VND;
    if (typeof vnd !== 'number' || !Number.isFinite(vnd) || !(vnd > 0)) return null;
    const m = typeof fx?.date === 'string' ? DAY.exec(fx.date) : null;
    if (!m) return null;
    const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
    const at = new Date(Date.UTC(y, mo - 1, d));
    if (at.getUTCFullYear() !== y || at.getUTCMonth() !== mo - 1 || at.getUTCDate() !== d) return null;
    const loc = lang === 'vi' ? 'vi-VN' : 'en-AU';
    const num = new Intl.NumberFormat(loc, { maximumFractionDigits: 0 }).format(vnd);
    if (num === '0') return null;
    const day = new Intl.DateTimeFormat(loc, { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' }).format(at);
    return `1 AUD = ${num} VND · RBA, ${day}`;
}
