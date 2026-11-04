// Regulated figures are grounded -> the RBA's AUD rate -> the web frontend -> the AUD line
// before the listing-site links (behavior 153 Expect 9): over random /api/fx answers through
// getFx, a rate is drawn only from a VND rate > 0 with a real date, never NaN, 0 or undefined.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { getFx } from '../src/lib/fx.ts';
import { audRate } from '../src/lib/fxLine.ts';

const SEED = 153;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const GOOD = { date: '2026-10-16', rates: { VND: 17970, USD: 0.6947 }, source: 'https://www.rba.gov.au/statistics/frequency/exchange-rates.html', bank: null };

test('the dev stack\'s rate reads as behavior 153 states it', () => {
    assert.equal(audRate(GOOD, 'vi'), '1 AUD = 17.970 VND · RBA, 16 thg 10, 2026');
    assert.equal(audRate(GOOD, 'en'), '1 AUD = 17,970 VND · RBA, 16 Oct 2026');
    assert.equal(audRate(null, 'en'), null);
});

test('300 random /api/fx answers, seed 153: a rate only from a VND > 0 with a real date', async () => {
    const rand = mulberry32(SEED);
    const pick = <T,>(xs: T[]) => xs[Math.floor(rand() * xs.length)];
    const rates = [17970, 17970, 17970, 16234.5, 0, -17970, NaN, Infinity, '17970', null, undefined, 0.2, 1e9, 16234.5];
    const dates = ['2026-10-16', '2026-10-16', '2024-02-29', '2026-01-02', '', '2026-13-01', '2026-02-30', '16/10/2026', null, 20261016, '2026-10-16T00:00:00Z', '<b>x</b>', undefined];
    const bad: string[] = [];
    let drawn = 0;
    for (let i = 0; i < 300; i++) {
        const kind = pick(['ok', 'ok', 'ok', '500', 'nonjson', 'array']);
        const vnd = pick(rates);
        const date = pick(dates);
        const body: Record<string, unknown> = { rates: rand() < 0.1 ? undefined : { VND: vnd, USD: rand() < 0.75 ? 0.69 : pick([0, NaN, '0.69']) }, date, source: 'x' };
        if (rand() < 0.3) body.extra = { evil: '<script>' };
        if (rand() < 0.2) body.bank = { name: 'b', time: 'nope', buy_cash: -1 };
        const fetchFn = (async () =>
            kind === '500'
                ? new Response('err', { status: 500 })
                : new Response(kind === 'nonjson' ? '<html>' : JSON.stringify(kind === 'array' ? [body] : body), { status: 200 })) as unknown as typeof fetch;
        const fx = await getFx(fetchFn);
        const realDay = typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date) && !['2026-13-01', '2026-02-30'].includes(date);
        const ok = fx !== null && typeof fx.rates.VND === 'number' && Number.isFinite(fx.rates.VND) && fx.rates.VND >= 0.5 && realDay;
        for (const lang of ['vi', 'en'] as const) {
            const line = audRate(fx, lang);
            if (line !== null) drawn++;
            if (ok !== (line !== null)) bad.push(`${i} ${lang}: ${JSON.stringify(body)} → ${line}`);
            if (line !== null && (/NaN|undefined|Infinity|null/.test(line) || / 0 VND/.test(line) || !line.startsWith('1 AUD = ')))
                bad.push(`${i} ${lang}: drew ${line}`);
        }
    }
    assert.deepEqual(bad, []);
    assert.ok(drawn >= 20, `only ${drawn} answers drew a rate`);
});
