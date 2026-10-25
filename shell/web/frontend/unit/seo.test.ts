// Regulated figures are grounded -> P-7 -> The web frontend -> crawlers read the public pages as served (behavior 137)
// Expect 6: for all headline and summary strings drawn with `</script>`, `<!--`, quotes,
// `&`, `<` and Vietnamese diacritics, the built note page's JSON-LD parses back to the
// same strings and holds no `</script` or `<!--`; its <title> and description hold
// no raw `<`. 200 cases, seed 137. Plus the page set's shapes (Expect 1–4 in small).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render, notePage, allNews, allFacts, robots, sitemap, llms, newsIndexPage, factsPage, homePage, noteSlug, jsonLd } from '../scripts/seo.ts';

const SHELL = '<!doctype html>\n<html lang="vi">\n<head>\n<meta charset="utf-8" />\n</head>\n<body data-sveltekit-preload-data="hover">\n<div style="display: contents"><script>start()</script></div>\n</body>\n</html>\n';

// mulberry32: a seeded generator, so a failing case reruns.
function rng(seed: number) {
    let a = seed >>> 0;
    return () => {
        a = (a + 0x6d2b79f5) >>> 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const PIECES = ['</script>', '</SCRIPT >', '<!--', '-->', '<script>alert(1)</script>', '"', "'", '&', '&amp;', '<', '>', '\\', '\u2028', '\u2029', 'Phí visa ', 'tăng gấp đôi ', 'Người Việt ', 'đ', 'ữ', '$4.600 ', '**bold** ', '[x](javascript:alert(1)) ', '| a | b |\n', '\n\n', ' ', 'x'];

function draw(r: () => number): string {
    let s = '';
    const n = 1 + Math.floor(r() * 12);
    for (let i = 0; i < n; i++) s += PIECES[Math.floor(r() * PIECES.length)];
    return s;
}

function ldOf(html: string): unknown[] {
    return [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)].map((m) => JSON.parse(m[1]));
}

test('property: hostile note text stays inside its JSON-LD and parses back (200 cases, seed 137)', () => {
    const r = rng(137);
    for (let i = 0; i < 200; i++) {
        const note = {
            news_slug: 'kb.news.case-' + i,
            headline_vi: draw(r),
            headline_en: draw(r),
            summary_vi: draw(r),
            summary_en: draw(r),
            authored_date: '2026-10-25',
            sources: [{ url: 'https://www.legislation.gov.au/x' }]
        };
        const html = render(SHELL, notePage(note));
        const scripts = [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
        assert.equal(scripts.length, 1, `case ${i}: one JSON-LD element`);
        const body = scripts[0][1];
        assert.ok(!/<\/script/i.test(body) && !body.includes('<!--'), `case ${i}: JSON-LD holds no </script or <!--`);
        const ld = JSON.parse(body) as { headline: string; alternativeHeadline?: string };
        assert.equal(ld.headline, note.headline_vi, `case ${i}: headline parses back`);
        assert.equal(ld.alternativeHeadline, note.headline_en, `case ${i}: EN headline parses back`);
        const title = html.match(/<title>([\s\S]*?)<\/title>/)![1];
        assert.ok(!title.includes('<'), `case ${i}: title holds no raw <`);
        const desc = html.match(/<meta name="description" content="([^"]*)" \/>/);
        assert.ok(desc, `case ${i}: description attribute stays closed`);
        // The page's only script elements are the shell's own and the JSON-LD.
        assert.equal([...html.matchAll(/<script\b/gi)].length, 2, `case ${i}: no injected script element`);
    }
});

test('jsonLd escapes every character that could end the element', () => {
    const s = jsonLd({ a: '</script><!--&\u2028\u2029' });
    assert.ok(!/[<>&\u2028\u2029]/.test(s));
    assert.deepEqual(JSON.parse(s), { a: '</script><!--&\u2028\u2029' });
});

const ARTIFACT = {
    news: {
        'kb.news.b': { headline_vi: 'Tin B', headline_en: 'News B', summary_vi: 'Tóm tắt B', authored_date: '2026-10-18', sources: [{ url: 'https://www.ato.gov.au/b' }] },
        'kb.news.a': { headline_vi: 'Tin A', headline_en: 'News A', summary_vi: 'Tóm tắt A', authored_date: '2026-10-20', sources: [{ url: 'https://www.rba.gov.au/a' }] }
    },
    facts: {
        'kb.facts.x': {
            title: { vi: 'Số X', en: 'Figure X' },
            last_verified: '2026-10-18',
            sources: [{ url: 'https://www.abs.gov.au/x' }],
            facts: [{ id: 'x', visual: 'figure', unit: 'pct', value: 4.2, headline: { vi: 'Thất nghiệp 4,2%', en: 'Unemployment 4.2%' }, caption: { vi: 'c', en: 'c' }, as_of: '2025-12', source: 0 }]
        }
    }
} as never;

test('news and facts read as the engine serves them', () => {
    const news = allNews(ARTIFACT);
    assert.deepEqual(news.map((n) => n.news_slug), ['kb.news.a', 'kb.news.b']);
    assert.equal(noteSlug('kb.news.2026-03-temporary-graduate-485-charge'), '2026-03-temporary-graduate-485-charge');
    assert.equal(allFacts(ARTIFACT)[0].slug, 'kb.facts.x');
});

test('a note page carries its title, canonical, NewsArticle and sources', () => {
    const [a] = allNews(ARTIFACT);
    const html = render(SHELL, notePage(a));
    assert.match(html, /<title>Tin A \| Mai An Cư<\/title>/);
    assert.match(html, /<link rel="canonical" href="https:\/\/maiancu.com\/news\/a" \/>/);
    const [ld] = ldOf(html) as { '@type': string; datePublished: string; inLanguage: string; citation: string[] }[];
    assert.equal(ld['@type'], 'NewsArticle');
    assert.equal(ld.datePublished, '2026-10-20');
    assert.equal(ld.inLanguage, 'vi');
    assert.deepEqual(ld.citation, ['https://www.rba.gov.au/a']);
    assert.match(html, /<div id="seo-static">[\s\S]*Tin A[\s\S]*News A[\s\S]*https:\/\/www.rba.gov.au\/a/);
    assert.ok(html.indexOf('id="seo-static"') < html.indexOf('display: contents'), 'the block sits beside the app target, not in it');
});

test('index pages, robots, sitemap and llms.txt', () => {
    const news = allNews(ARTIFACT);
    const facts = allFacts(ARTIFACT);
    assert.match(render(SHELL, newsIndexPage(news)).match(/<div id="seo-static">[\s\S]*<\/div>/)![0], /href="\/news\/a"[\s\S]*href="\/news\/b"/);
    assert.match(render(SHELL, factsPage(facts)), /Thất nghiệp 4,2%[\s\S]*4\.2 pct[\s\S]*https:\/\/www.abs.gov.au\/x/);
    assert.match(render(SHELL, homePage(news)), /<title>Mai An Cư — /);
    const r = robots();
    for (const ua of ['*', 'GPTBot', 'OAI-SearchBot', 'ChatGPT-User', 'ClaudeBot', 'Claude-SearchBot', 'PerplexityBot', 'Google-Extended', 'Googlebot', 'Bingbot']) assert.ok(r.includes(`User-agent: ${ua}\n`), ua);
    assert.match(r, /Allow: \/\nDisallow: \/plan\nDisallow: \/status\nDisallow: \/api\/\n/);
    assert.match(r, /Sitemap: https:\/\/maiancu.com\/sitemap.xml/);
    const sm = sitemap(news, facts);
    assert.equal([...sm.matchAll(/<loc>/g)].length, 3 + news.length);
    assert.match(sm, /<loc>https:\/\/maiancu.com\/news\/a<\/loc><lastmod>2026-10-20<\/lastmod>/);
    const l = llms(news, facts);
    assert.match(l, /^# Mai An Cư\n\n> /);
    assert.match(l, /- \[News A\]\(https:\/\/maiancu.com\/news\/a\): Tin A \(2026-10-20\)/);
});
