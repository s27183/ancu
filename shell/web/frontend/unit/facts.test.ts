// Regulated figures are grounded -> P-6 -> The web frontend -> the facts fetch and the /facts–/market split, proven on fakes
// Behavior 151, Expect 7: every way GET /api/facts can fail yields [] and never throws,
// so /market keeps its listing sites and frame. MARKET_DOCS names the two property docs,
// and each fact doc belongs to exactly one page.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { getFacts, isMarketDoc, MARKET_DOCS, PAGE_ORDER, KEY_FIGURES } from '../src/lib/facts.ts';

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
    assert.deepEqual(MARKET_DOCS, ['kb.facts.australian-property', 'kb.facts.property-safeguards']);
    for (const s of PAGE_ORDER) assert.equal(isMarketDoc(s), false, s);
    for (const k of KEY_FIGURES) assert.equal(isMarketDoc(k.slug), false, k.key);
});
