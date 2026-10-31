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
            sources: [{ url: 'https://www.abs.gov.au/x' }, { url: 'https://www.abs.gov.au/rule' }, { url: 'https://www.abs.gov.au/exception' }, { url: 'https://www.abs.gov.au/note' }],
            facts: [
                { id: 'x', visual: 'figure', unit: 'pct', value: 4.2, headline: { vi: 'Thất nghiệp 4,2%', en: 'Unemployment 4.2%' }, caption: { vi: 'c', en: 'c' }, as_of: '2025-12', source: 0 },
                { id: 'y', visual: 'figure', unit: 'aud', value: 5, headline: { vi: 'Phí Y', en: 'Fee Y' }, caption: { vi: 'c', en: 'c' }, source: [1, 2], note_sources: [3, 1] }
            ]
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
    const fp = render(SHELL, factsPage(facts));
    assert.match(fp, /Thất nghiệp 4,2%[\s\S]*4\.2 pct[\s\S]*https:\/\/www.abs.gov.au\/x/);
    for (const u of ['rule', 'exception', 'note']) assert.equal(fp.split(`href="https://www.abs.gov.au/${u}"`).length, 2, `every cited source linked once: ${u}`);
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

// ---- Guides (behavior 146) ----------------------------------------------------------------
// Expect 2: for all KB docs in the compiled artifact plus 200 planted hostile docs (seed 146):
// a page exists iff the doc passes the publish rule; it keeps its H1, every other heading as an
// h2/h3 and at least nine tenths of the doc's reader text; it holds no PLACEHOLDER, "Mode-",
// tag outside the allowlist or raw `](../`; its JSON-LD parses. Expect 3: every href in a
// guide's article is https, and one on maiancu.com names a guide that is built.
import { readFileSync, existsSync } from 'node:fs';
import { allGuides, guidePage, guideTitles, guidePath, guideIndexPage, isPublished, llmsFull, staticPage, type KbDoc } from '../scripts/seo.ts';

const ARTIFACT_JSON = new URL('../../../../engine/erlang/priv/kb/artifact.json', import.meta.url);

// The publish rule, written again from the behavior's words as the oracle.
function shouldPublish(slug: string, d: KbDoc): boolean {
    const cat = slug.split('.')[1];
    if (cat === 'copy' || cat === 'journey' || cat === 'bilingual') return false;
    if (d.content_md.includes('PLACEHOLDER') || d.content_md.includes('NOT SOURCE-GROUNDED')) return false;
    return (d.sources ?? []).some((s) => (s.url ?? '').startsWith('https://'));
}

const ALLOWED = new Set(['html', 'head', 'meta', 'title', 'link', 'script', 'style', 'body', 'header', 'nav', 'a', 'main', 'article', 'footer', 'h1', 'h2', 'h3', 'p', 'time', 'ul', 'ol', 'li', 'strong', 'em', 'code', 'pre', 'br', 'hr', 'blockquote', 'div', 'table', 'thead', 'tbody', 'tr', 'th', 'td']);

const decode = (s: string) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&amp;/g, '&');
const squash = (s: string) => s.replace(/\s+/g, '');

/** The doc's text as a reader sees it, from the markdown: link targets, marks and the H1 gone. */
function readerText(md: string): string {
    const lines = md.split('\n');
    lines.splice(lines.findIndex((l) => /^\s{0,3}#\s/.test(l)), 1);
    return squash(
        lines
            .join('\n')
            .replace(/\[([^\]\n]*)\]\([^)\n]*\)/g, '$1')
            .replace(/`kb\.[a-z0-9.-]+`/g, '')
            .replace(/\(agent reasons over these\)/g, '')
            .replace(/^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$/gm, '')
            .replace(/^\s*([-*+]|\d{1,9}[.)])\s+/gm, '')
            .replace(/^\s{0,3}([-*_])(\s*\1){2,}\s*$/gm, '')
            .replace(/^\s{0,3}(#{1,6}|>)\s?/gm, '')
            .replace(/[*_`|\\]/g, '')
    );
}

function headings(md: string): number {
    let fenced = false;
    let n = 0;
    for (const line of md.split('\n')) {
        if (/^\s*```/.test(line)) fenced = !fenced;
        else if (!fenced && /^\s{0,3}#{2,6}\s+\S/.test(line)) n++;
    }
    return n;
}

function checkGuide(slug: string, d: KbDoc, titles: Map<string, string>, why: string): string {
    const html = staticPage(guidePage(slug, d, titles));
    const article = html.slice(html.indexOf('<article>'), html.indexOf('</article>'));
    assert.match(article, /<h1>[^<]+<\/h1>/, `${why}: H1`);
    const hs = [...article.matchAll(/<h([23])>/g)].length - 1; // less the Sources heading
    assert.equal(hs, headings(d.content_md), `${why}: every heading is an h2/h3`);
    const text = squash(decode(article.replace(/<p class="meta">[\s\S]*?<\/p>/, '').replace(/<h2>Sources<\/h2>[\s\S]*$/, '').replace(/<h1>[\s\S]*?<\/h1>/, '').replace(/<[^>]+>/g, '')));
    const want = readerText(d.content_md);
    assert.ok(text.length >= want.length * 0.9, `${why}: body ${text.length} of ${want.length}`);
    for (const bad of ['PLACEHOLDER', 'Mode-', '](../']) assert.ok(!html.includes(bad), `${why}: holds ${bad}`);
    for (const m of html.matchAll(/<\/?([a-zA-Z][a-zA-Z0-9-]*)/g)) assert.ok(ALLOWED.has(m[1].toLowerCase()), `${why}: tag <${m[1]}>`);
    assert.equal([...html.matchAll(/<script\b/gi)].length, 1, `${why}: one script element, the JSON-LD`);
    const [ld] = ldOf(html) as { '@type': string; headline: string }[];
    assert.equal(ld['@type'], 'Article', `${why}: Article JSON-LD`);
    for (const m of article.matchAll(/<a\b([^>]*)>/g)) {
        const href = /^ href="([^"]*)"/.exec(m[1]);
        assert.ok(href, `${why}: <a> without a leading href: ${m[1]}`);
        const u = decode(href[1]);
        assert.ok(u.startsWith('https://'), `${why}: href ${u}`);
        if (u.startsWith('https://maiancu.com/')) {
            const p = u.slice('https://maiancu.com'.length);
            assert.ok([...titles.keys()].some((k) => guidePath(k) === p), `${why}: ${p} is a built guide`);
        }
    }
    return html;
}

test('property: every real KB doc gets a guide iff published, and each guide keeps its text and only safe links', { skip: !existsSync(ARTIFACT_JSON) && 'no compiled artifact' }, () => {
    const kb = (JSON.parse(readFileSync(ARTIFACT_JSON, 'utf8')) as { kb: Record<string, KbDoc> }).kb;
    const guides = allGuides({ kb });
    const titles = guideTitles(guides);
    for (const [slug, d] of Object.entries(kb)) {
        assert.equal(isPublished(slug, d), shouldPublish(slug, d), slug);
        assert.equal(titles.has(slug), shouldPublish(slug, d), slug);
        if (titles.has(slug)) checkGuide(slug, d, titles, slug);
    }
    assert.ok(guides.length > 100, `${guides.length} guides`);
    const index = llms([], [], guides) + llmsFull([], [], guides) + staticPage(guideIndexPage(guides));
    for (const bad of ['PLACEHOLDER', 'NOT SOURCE-GROUNDED', 'Mode-', '](../']) assert.ok(!index.includes(bad), `llms.txt, llms-full.txt and /guide hold no ${bad}`);
});

const HOSTILE = ['</script>', '<img src=x onerror=alert(1)>', '<!--', '"', '&', ' ', '[run](javascript:alert(1))', '[d](data:text/html,x)', '[h](http://example.com/x)', '[ok](https://www.ato.gov.au/x)', '[far](https://evil.example/x)', '[peer](../scheme/fhg.md)', '[hidden](../copy/x.md)', '[frag](#anchor)', '[abs](/plan)', 'a Mode-B buyer', 'Modes B and D', 'Mode A/C', '(agent reasons over these)', '`kb.scheme.fhg`', '| a | b |\n|---|---|\n| 1 | 2 |\n', '- item\n', '**bold** ', 'Phí ', '$46,800 ', '\n\n', ' ', 'x'];

function plantedBody(r: () => number): string {
    let s = '';
    const n = 3 + Math.floor(r() * 14);
    for (let i = 0; i < n; i++) {
        if (r() < 0.15) s += `\n## ${draw(r).replace(/\n/g, ' ')} ${HOSTILE[Math.floor(r() * HOSTILE.length)].replace(/\n/g, ' ')}\n`;
        s += HOSTILE[Math.floor(r() * HOSTILE.length)];
    }
    return s;
}

test('property: planted hostile docs (200 cases, seed 146)', () => {
    const r = rng(146);
    const cats = ['scheme', 'firb', 'copy', 'journey', 'bilingual', 'tax'];
    const peer: KbDoc = { content_md: '# First Home Guarantee\n\nThe guarantee.', sources: [{ url: 'https://www.housingaustralia.gov.au/x' }] };
    let built = 0;
    for (let i = 0; i < 200; i++) {
        const slug = `kb.${cats[Math.floor(r() * cats.length)]}.case-${i}`;
        const mark = r() < 0.1 ? 'PLACEHOLDER ' : r() < 0.05 ? 'NOT SOURCE-GROUNDED ' : '';
        const srcs = r() < 0.1 ? [] : r() < 0.1 ? [{ note: 'NOT VERIFIED' } as never] : [{ url: r() < 0.1 ? 'javascript:alert(1)' : 'https://www.ato.gov.au/case', retrieved: '2026-10-01' }];
        const d: KbDoc = { content_md: `# ${draw(r).replace(/\n/g, ' ') || 'T'}x\n\n${mark}${plantedBody(r)}`, last_verified: '2026-10-01', sources: srcs };
        const kb = { [slug]: d, 'kb.scheme.fhg': peer, 'kb.copy.x': { content_md: '# Copy\n\nx', sources: [{ url: 'https://a.gov.au/' }] } };
        const titles = guideTitles(allGuides({ kb }));
        assert.equal(titles.has(slug), shouldPublish(slug, d), `case ${i}: published iff the rule passes`);
        assert.ok(!titles.has('kb.copy.x'), 'copy never published');
        if (!titles.has(slug)) continue;
        built++;
        const html = checkGuide(slug, d, titles, `case ${i}`);
        for (const bad of ['javascript:', 'data:text', 'http://example.com', '/copy/', '#anchor"', 'href="/plan"></a']) assert.ok(!html.includes(`href="${bad}`) && !html.includes(bad + '"'), `case ${i}: no ${bad} href`);
        if (d.content_md.includes('[peer](../scheme/fhg.md)')) assert.ok(html.includes('href="https://maiancu.com/guide/scheme-fhg"'), `case ${i}: a published peer links to its guide`);
        if (d.content_md.includes('[hidden](../copy/x.md)')) assert.ok(html.includes('hidden'), `case ${i}: an unpublished peer stays as text`);
    }
    assert.ok(built >= 40, `${built} planted guides built`);
});
