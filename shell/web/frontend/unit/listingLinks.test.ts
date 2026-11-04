// Honest-partial -> the suburb data the goal names -> the web frontend -> the listing sites'
// links, proven over every suburb the snapshot ships and 200 seeded hostile names
// (behavior 150, Expect 1): each link's host is one of the three, its path the site's
// suburb pattern, no "(Vic.)" qualifier left, and Domain/Allhomes only with a postcode.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { LISTING_HOSTS, listingLinks } from '../src/lib/listingLinks.ts';

const SEED = 150;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

type Row = { name: string; state: string; facts_jsonb: { postcode?: string } };
const snapshot: Row[] = JSON.parse(gunzipSync(readFileSync(new URL('../../../../engine/erlang/priv/suburbs/suburbs.json.gz', import.meta.url))).toString());

const HOSTS = new Set(Object.values(LISTING_HOSTS));
const REA_PATH = /^\/buy\/in-[^/?#\s]+,\+(nsw|vic|qld|sa|wa|tas|nt|act)\/list-1$/;
const SALE_PATH = /^\/sale\/[a-z0-9]+(-[a-z0-9]+)*-(nsw|vic|qld|sa|wa|tas|nt|act)-[0-9]{4}\/$/;

function problems(name: string, state: string, postcode: unknown): string[] {
    const out: string[] = [];
    let links;
    try {
        links = listingLinks(name, state, postcode as string);
    } catch (e) {
        return [`threw ${e}`];
    }
    const hasPc = typeof postcode === 'string' && /^[0-9]{4}$/.test(postcode);
    for (const l of links) {
        let u: URL;
        try {
            u = new URL(l.url);
        } catch {
            out.push(`unparseable ${l.url}`);
            continue;
        }
        if (u.protocol !== 'https:' || !HOSTS.has(u.host) || u.host !== LISTING_HOSTS[l.site]) out.push(`host ${u.host}`);
        if (u.search || u.hash || u.username || u.port) out.push(`extra url parts ${l.url}`);
        const pattern = l.site === 'rea' ? REA_PATH : SALE_PATH;
        if (!pattern.test(u.pathname)) out.push(`path ${u.pathname}`);
        if (/\((vic|nsw|qld|sa|wa|tas|nt|act)\.?\)/i.test(decodeURIComponent(u.pathname))) out.push(`qualifier left ${u.pathname}`);
    }
    const sites = links.map((l) => l.site);
    if (!hasPc && (sites.includes('domain') || sites.includes('allhomes'))) out.push('domain/allhomes without a postcode');
    return out;
}

test('every suburb in the snapshot builds only safe, well-formed links', () => {
    assert.ok(snapshot.length >= 15_000, `snapshot rows ${snapshot.length}`);
    const bad: string[] = [];
    let withPc = 0;
    let three = 0;
    for (const s of snapshot) {
        const pc = s.facts_jsonb?.postcode;
        if (pc) withPc++;
        const p = problems(s.name, s.state, pc);
        if (p.length) bad.push(`${s.name} ${s.state}: ${p.join('; ')}`);
        const n = listingLinks(s.name, s.state, pc).length;
        if (pc && n === 3) three++;
        const placeholder = /^(No usual address|Migratory - Offshore - Shipping) \(/.test(s.name);
        if (placeholder ? n !== 0 : n === 0) bad.push(`${s.name} ${s.state}: ${n} links`);
    }
    assert.deepEqual(bad.slice(0, 20), []);
    assert.equal(three, withPc, 'every suburb with a postcode gets all three links');
    assert.equal(snapshot.filter((s) => /^(No usual address|Migratory - Offshore - Shipping) \(/.test(s.name)).length, 16);
});

test('200 hostile names, seed 150: no link leaves the three hosts or their patterns', () => {
    const rand = mulberry32(SEED);
    const parts = ['', ' ', '/', '//evil.example', '@evil.example', '#frag', '?q=1', '%2f', '%2F..%2F', '..', '<script>alert(1)</script>', 'Ñandú', '東京', '‮', '\u0000', '\n', "O'Connor", '(Vic.)', 'x'.repeat(10_000), 'https://evil.example/', '\\', '%', '+', ','];
    const states = ['VIC', 'NSW', 'ACT', 'NT', 'vic', 'XX', '', '../'];
    const pcs: unknown[] = ['3128', '', '31280', 'abcd', '3128/../', undefined, null, 3128];
    const bad: string[] = [];
    for (let i = 0; i < 200; i++) {
        let name = '';
        for (let k = 0, n = Math.floor(rand() * 4); k <= n; k++) name += parts[Math.floor(rand() * parts.length)];
        const st = states[Math.floor(rand() * states.length)];
        const pc = pcs[Math.floor(rand() * pcs.length)];
        const p = problems(name, st, pc);
        if (p.length) bad.push(`${JSON.stringify(name.slice(0, 40))} ${st} ${String(pc)}: ${p.join('; ')}`);
    }
    assert.deepEqual(bad, []);
});

test('the measured forms (probe 2/9)', () => {
    const urls = (n: string, s: string, p?: string) => listingLinks(n, s, p).map((l) => l.url);
    assert.deepEqual(urls('Box Hill (Vic.)', 'VIC', '3128'), [
        'https://www.realestate.com.au/buy/in-box+hill,+vic/list-1',
        'https://www.domain.com.au/sale/box-hill-vic-3128/',
        'https://www.allhomes.com.au/sale/box-hill-vic-3128/'
    ]);
    assert.deepEqual(urls("O'Connor (ACT)", 'ACT', '2602'), [
        "https://www.realestate.com.au/buy/in-o'connor,+act/list-1",
        'https://www.domain.com.au/sale/o-connor-act-2602/',
        'https://www.allhomes.com.au/sale/o-connor-act-2602/'
    ]);
    assert.deepEqual(urls('Richmond (Vic.)', 'VIC'), ['https://www.realestate.com.au/buy/in-richmond,+vic/list-1']);
});
