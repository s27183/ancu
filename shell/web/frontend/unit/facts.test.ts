// Regulated figures are grounded -> P-6 -> The web frontend -> the facts fetch and the /facts–/market–/demand split, proven on fakes
// Behavior 151, Expect 7: every way GET /api/facts can fail yields [] and never throws,
// so /market keeps its listing sites and frame. MARKET_DOCS names the three property docs (listing transparency first, behavior 153),
// and each fact doc belongs to exactly one page.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DEMAND_DOCS, DEMAND_RANK, factPath, type FactDoc, formatQuarter, getFacts, isDemandDoc, isMarketDoc, keyFigure, MARKET_DOCS, PAGE_ORDER, KEY_FIGURES, SECTION_ORDER } from '../src/lib/facts.ts';

const failures: [string, typeof fetch][] = [
    ['network error', (async () => { throw new TypeError('fetch failed'); }) as unknown as typeof fetch],
    ['500', (async () => new Response('oops', { status: 500 })) as typeof fetch],
    ['404', (async () => new Response('', { status: 404 })) as typeof fetch],
    ['not JSON', (async () => new Response('<html>', { status: 200 })) as typeof fetch],
    ['no facts field', (async () => Response.json({})) as typeof fetch]
];
for (const [name, f] of failures) {
    test(`getFacts on ${name} → []`, async () => assert.deepEqual(await getFacts(f), []));
}

test('MARKET_DOCS are the property docs, and /facts orders none of them', () => {
    assert.deepEqual(MARKET_DOCS, ['kb.facts.listing-transparency', 'kb.facts.australian-property', 'kb.facts.property-safeguards']);
    for (const s of PAGE_ORDER) assert.equal(isMarketDoc(s), false, s);
    for (const k of KEY_FIGURES) assert.equal(isMarketDoc(k.slug), false, k.key);
});

test('behavior 164: Vietnamese home-buying demand has its own page, off /facts, still first in the Introduction sheet', () => {
    assert.deepEqual(DEMAND_DOCS, ['kb.facts.vietnamese-buyers']);
    for (const s of DEMAND_DOCS) assert.equal(isMarketDoc(s), false, s);
    for (const s of PAGE_ORDER) assert.equal(isDemandDoc(s), false, s);
    for (const k of KEY_FIGURES) assert.equal(isDemandDoc(k.slug), false, k.key);
    assert.equal(factPath('kb.facts.vietnamese-buyers'), '/demand');
    assert.equal(factPath('kb.facts.australian-property'), '/market');
    assert.equal(factPath('kb.facts.vietnamese-in-australia'), '/facts');
    assert.equal(SECTION_ORDER[0], 'kb.facts.vietnamese-buyers');
    assert.equal(SECTION_ORDER[1], 'kb.facts.vietnamese-in-australia');
    assert.equal(DEMAND_RANK.slug, 'kb.facts.vietnamese-buyers');
});

test('behavior 164: the home line\'s rank and quarter come from the fact', () => {
    const docs = [{ slug: 'kb.facts.vietnamese-buyers', title: { en: '', vi: '' }, last_verified: '', sources: [], facts: [
        { id: 'firb_top_sources_quarter', visual: 'bars', headline: { en: '', vi: '' }, caption: { en: '', vi: '' }, as_of: '2026-03', source: 0,
          items: [{ label: 'China', value: 156 }, { label: 'Vietnam', value: 65, highlight: true }, { label: 'Taiwan', value: 76 }] }
    ] }] as unknown as FactDoc[];
    const f = keyFigure(docs, DEMAND_RANK, 'vi');
    assert.equal(f?.rank, 3);
    assert.equal(formatQuarter(f!.as_of, 'vi'), 'quý 1/2026');
    assert.equal(formatQuarter('2025-06', 'en'), 'Q2 2025');
    assert.equal(keyFigure([], DEMAND_RANK, 'en'), null);
});
