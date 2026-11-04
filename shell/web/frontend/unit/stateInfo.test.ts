// Regulated figures are grounded -> each state's capital-city figures -> the web frontend ->
// the map filter's ranked states (behavior 154; the rule and its block: stateInfo.ts). The
// shipped doc's shape ranks Sydney first; 300 hostile /api/facts answers, seed 154, never
// throw, never show a figure that is not a finite value > 0 under a known capital, and
// always give the 8 states.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stateRows, popShort, popFull, priceK, STATE_CAPITALS, CAPITALS_DOC } from '../src/lib/stateInfo.ts';

const SEED = 154;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

// The shipped doc's facts, read from the KB source itself (its ```jsonc block).
function shippedDoc() {
    const md = readFileSync(new URL('../../../../docs/kb/facts/capital-cities.md', import.meta.url), 'utf8');
    const body = md.split('```jsonc')[1].split('```')[0];
    return { slug: CAPITALS_DOC, ...JSON.parse(body) };
}

test('the shipped doc: Sydney first, every state with its three figures', () => {
    const rows = stateRows([shippedDoc()]);
    assert.deepEqual(rows.map((r) => r.state), ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'ACT', 'TAS', 'NT']);
    assert.deepEqual(rows[0], { state: 'NSW', capital: 'Sydney', population: 5638830, house: 1487.6, attached: 840 });
    assert.deepEqual(rows[6], { state: 'TAS', capital: 'Hobart', population: 255250, house: 750, attached: 600 });
    for (const r of rows) assert.ok(r.population && r.house && r.attached, r.state);
});

test('no facts: the 8 states in the fixed order, no figures', () => {
    for (const answer of [[], null, undefined, 'x', [{ slug: 'other' }]]) {
        const rows = stateRows(answer);
        assert.deepEqual(rows.map((r) => r.state), ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT']);
        assert.ok(rows.every((r) => r.population === null && r.house === null && r.attached === null));
    }
});

test('formats', () => {
    assert.equal(popShort(5638830, 'vi'), '5,6 tr');
    assert.equal(popShort(5638830, 'en'), '5.6m');
    assert.equal(popShort(484630, 'vi'), '484.630');
    assert.equal(popShort(484630, 'en'), '484,630');
    assert.equal(popFull(5638830, 'vi'), '5.638.830');
    assert.equal(popFull(5638830, 'en'), '5,638,830');
    assert.equal(priceK(1487.6, 'vi'), '1,49 tr AUD');
    assert.equal(priceK(1487.6, 'en'), '$1.49m');
    assert.equal(priceK(840, 'vi'), '840 nghìn AUD');
    assert.equal(priceK(840, 'en'), '$840k');
});

test('300 hostile /api/facts answers, seed 154: 8 states, figures only from finite values > 0', () => {
    const rand = mulberry32(SEED);
    const pick = <T,>(xs: T[]) => xs[Math.floor(rand() * xs.length)];
    const labels = [...Object.values(STATE_CAPITALS), 'Gold Coast', '', '<script>', { en: 'Sydney', vi: 'Sydney' }, { vi: 'x' }, null, 42];
    const values = [5638830, 1, 0, -5, NaN, Infinity, -Infinity, '5638830', null, undefined, 1e300, 0.5];
    const ids = ['capital_city_population', 'capital_city_house_median', 'capital_city_attached_median', 'other'];
    const bad: string[] = [];
    let drew = 0;
    for (let i = 0; i < 300; i++) {
        const facts = Array.from({ length: Math.floor(rand() * 5) }, () =>
            rand() < 0.1
                ? pick([null, 'x', { id: 'capital_city_population', items: 'no' }])
                : { id: pick(ids), items: Array.from({ length: Math.floor(rand() * 12) }, () => (rand() < 0.05 ? null : { label: pick(labels), value: pick(values), extra: 1 })) }
        );
        const doc = rand() < 0.1 ? pick([null, { slug: CAPITALS_DOC }, { slug: CAPITALS_DOC, facts: 'x' }]) : { slug: CAPITALS_DOC, facts, extra: true };
        const answer = rand() < 0.1 ? pick([null, {}, 'x', 7]) : [pick([{ slug: 'other' }, null]), doc];
        try {
            const rows = stateRows(answer);
            if (rows.length !== 8 || new Set(rows.map((r) => r.state)).size !== 8) bad.push(`${i}: ${rows.length} rows`);
            let seenNull = false;
            let last = Infinity;
            for (const r of rows) {
                if (r.capital !== STATE_CAPITALS[r.state]) bad.push(`${i}: ${r.state} capital ${r.capital}`);
                for (const v of [r.population, r.house, r.attached]) {
                    if (v !== null && !(typeof v === 'number' && Number.isFinite(v) && v > 0)) bad.push(`${i}: ${r.state} figure ${v}`);
                    if (v !== null) {
                        drew++;
                        for (const lang of ['vi', 'en'] as const)
                            for (const s of [popShort(v, lang), popFull(v, lang), priceK(v, lang)])
                                if (/NaN|undefined|Infinity/.test(s)) bad.push(`${i}: formatted ${s}`);
                    }
                }
                if (r.population === null) seenNull = true;
                else {
                    if (seenNull) bad.push(`${i}: ${r.state} ranked after a state with no population`);
                    if (r.population > last) bad.push(`${i}: ${r.state} out of order`);
                    last = r.population;
                }
            }
        } catch (e) {
            bad.push(`${i}: threw ${e}`);
        }
    }
    assert.deepEqual(bad, []);
    assert.ok(drew >= 50, `only ${drew} figures drawn`);
});
