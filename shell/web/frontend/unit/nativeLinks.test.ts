// Honest-partial -> the web frontend -> outside links in the phone app (behavior 161, Expect 5):
// property — for all hrefs drawn from https / http / javascript: / intent: / data: / mailto: /
// relative / our own host / maiancu.com / the listing hosts / malformed strings, with and
// without the native flag: only an absolute https URL to a host other than ours reaches the
// in-app browser, and only when native. 2000 seeded cases, plus the named ones.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { externalTarget } from '../src/lib/nativeLinks.ts';

const SEED = 161;
const CASES = 2000;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const OWN = ['10.0.2.2:5173', '127.0.0.1:5173', 'localhost', 'maiancu.com'];
const OTHER = ['www.realestate.com.au', 'www.domain.com.au', 'www.allhomes.com.au', 'www.ato.gov.au', 'evil.example', 'maiancu.com.evil.example', 'xn--mi-ncu-9ta.com'];
const PATHS = ['', '/', '/buy/in-box+hill,+vic/list-1', '/sale/box-hill-vic-3128/', '/a?b=c#d', "/in-o'connor,+act", '/%2e%2e/x', '/<script>'];
const HOSTILE = ['javascript:alert(1)', 'JaVaScRiPt:alert(1)', ' javascript:alert(1)', 'intent://scan/#Intent;scheme=zxing;end', 'data:text/html,<script>alert(1)</script>', 'mailto:a@b.c', 'tel:123', 'file:///etc/passwd', 'blob:https://x/1', 'vbscript:x', 'about:blank', 'chrome://settings', 'capacitor://localhost/x', 'https:', 'https://', 'https:///x', '//www.domain.com.au/x', '/news/x', 'news/x', '#top', '?q=1', '', '   ', 'http//x', 'https://user:pw@www.domain.com.au/', 'https://@evil.example/'];

const pick = <T,>(r: () => number, xs: T[]): T => xs[Math.floor(r() * xs.length)];

type Gen = { href: string; https: boolean; host: string | null };
function gen(r: () => number, own: string): Gen {
    const k = r();
    if (k < 0.3) {
        const host = pick(r, OTHER);
        const scheme = pick(r, ['https', 'https', 'HTTPS', 'http']);
        return { href: `${scheme}://${host}${pick(r, PATHS)}`, https: scheme.toLowerCase() === 'https', host };
    }
    if (k < 0.45) return { href: `https://${own}${pick(r, PATHS)}`, https: true, host: own };
    if (k < 0.55) return { href: `https://${pick(r, ['maiancu.com', 'www.maiancu.com'])}${pick(r, PATHS)}`, https: true, host: 'maiancu.com' };
    if (k < 0.85) return { href: pick(r, HOSTILE), https: false, host: null };
    // random junk
    const chars = 'abc:/?#@%.-_ hjstpx0123456789<>"\'\\\n\t';
    let s = '';
    for (let i = 0, n = Math.floor(r() * 30); i < n; i++) s += chars[Math.floor(r() * chars.length)];
    return { href: s, https: false, host: null };
}

/** The oracle, written apart from the code: what may reach the in-app browser. */
function allowed(href: string, own: string): boolean {
    let u: URL;
    try {
        u = new URL(href);
    } catch {
        return false;
    }
    if (u.protocol !== 'https:' || !u.hostname || u.username || u.password) return false;
    if (u.host === own.toLowerCase()) return false;
    if (u.hostname === 'maiancu.com' || u.hostname === 'www.maiancu.com') return false;
    return true;
}

test(`property: only https to another host reaches the in-app browser, only when native — ${CASES} cases, seed ${SEED}`, () => {
    const r = mulberry32(SEED);
    let handed = 0;
    for (let i = 0; i < CASES; i++) {
        const own = pick(r, OWN);
        const native = r() < 0.7;
        const g = gen(r, own);
        const got = externalTarget(g.href, own, native);
        if (!native) {
            assert.equal(got, null, `not native, yet handed over: ${JSON.stringify(g.href)}`);
            continue;
        }
        if (allowed(g.href, own)) {
            assert.ok(got, `refused a valid outside link: ${JSON.stringify(g.href)}`);
            const u = new URL(got!);
            assert.equal(u.protocol, 'https:');
            assert.notEqual(u.host, own);
            handed++;
        } else {
            assert.equal(got, null, `handed over ${JSON.stringify(g.href)} (own ${own})`);
        }
    }
    assert.ok(handed > 200, `the generator reached too few valid links (${handed})`);
});

test('named cases', () => {
    const own = '10.0.2.2:5173';
    assert.equal(externalTarget('https://www.realestate.com.au/buy/in-box+hill,+vic/list-1', own, true), 'https://www.realestate.com.au/buy/in-box+hill,+vic/list-1');
    assert.equal(externalTarget('https://www.domain.com.au/sale/box-hill-vic-3128/', own, false), null);
    assert.equal(externalTarget('javascript:alert(1)', own, true), null);
    assert.equal(externalTarget('intent://x#Intent;end', own, true), null);
    assert.equal(externalTarget('http://www.domain.com.au/', own, true), null);
    assert.equal(externalTarget('/news/2026-11-rba', own, true), null);
    assert.equal(externalTarget('https://maiancu.com/news/x', own, true), null);
    assert.equal(externalTarget(`https://${own}/explore`, own, true), null);
    assert.equal(externalTarget('https://user:pw@www.domain.com.au/', own, true), null);
    assert.equal(externalTarget(null, own, true), null);
});
