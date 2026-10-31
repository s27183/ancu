// Regulated figures are grounded -> P-7 -> The web frontend -> crawlers read the public pages as served (behavior 137)
//
// Son 2026-10-25: "optimizing the platform for SEO, including AI agent search". The app
// is a static SPA (ssr = false): every address served the same empty shell, so a crawler
// that does not run script (GPTBot, ClaudeBot, PerplexityBot fetch HTML only) read no
// title and no text. Kit 2.65.0 with ssr = false mounts with hydrate: false and appends
// to its target (measured in client.js), so the app does not need server-rendered markup:
// after `vite build`, seo_pages.ts copies build/index.html once per public page and these
// pure helpers put into each copy its own title, description, canonical address, JSON-LD
// and the page's text in a `#seo-static` block beside the app's target. app.html hides
// that block once script runs, so a reader sees only the app; a crawler reads the text.
// The data is the compiled KB artifact (kb_compiler.py), the same news and facts the
// engine serves at /api/news and /api/facts, typed by the same declarations (P-7).
// Safety: every text is escaped (markdown.ts, escape-first) and JSON-LD escapes < > &
// U+2028 U+2029 as \uXXXX, so no KB text can close the script element
// (unit/seo.test.ts, a property over hostile strings).

import { escapeHtml, renderMarkdown, renderInlineMarkdown } from '../src/lib/markdown.ts';
import type { NewsNote } from '../src/lib/api.ts';
import type { FactDoc } from '../src/lib/facts.ts';

export const ORIGIN = 'https://maiancu.com';
export const BRAND = 'Mai An Cư';
const TAGLINE_VI = 'Kế hoạch ngân sách bất động sản tại Úc — mua, giữ, bán';
const TAGLINE_EN = 'Your Australian property budget plan — buy, hold, sell';

/** The artifact as kb_compiler.py writes it (the parts these pages read). */
export interface Artifact {
    news?: Record<string, Omit<NewsNote, 'news_slug'>>;
    facts?: Record<string, Omit<FactDoc, 'slug'>>;
    kb?: Record<string, KbDoc>;
}

/** A KB doc as kb_compiler.py writes it under `kb` (the fields the guide pages read). */
export interface KbDoc {
    content_md: string;
    effective_from?: string;
    last_verified?: string;
    sources?: { url?: string; retrieved?: string }[];
}

/** News as fh_engine_kb:all_news/0 serves it: news_slug = key, newest authored_date first. */
export function allNews(a: Artifact): NewsNote[] {
    return Object.entries(a.news ?? {})
        .map(([news_slug, e]) => ({ ...e, news_slug }) as NewsNote)
        .sort((x, y) => (y.authored_date ?? '').localeCompare(x.authored_date ?? ''));
}

/** Facts as fh_engine_kb:all_facts/0 serves them: slug = key, sorted by slug. */
export function allFacts(a: Artifact): FactDoc[] {
    return Object.keys(a.facts ?? {})
        .sort()
        .map((slug) => ({ ...a.facts![slug], slug }) as FactDoc);
}

/** kb.news.2026-03-temporary-graduate-485-charge -> 2026-03-temporary-graduate-485-charge */
export function noteSlug(newsSlug: string): string {
    return newsSlug.replace(/^kb\.news\./, '');
}

export function notePath(n: NewsNote): string {
    return `/news/${noteSlug(n.news_slug)}`;
}

/** JSON for a <script type="application/ld+json">: nothing in it can end the element. */
export function jsonLd(value: unknown): string {
    return JSON.stringify(value)
        .replace(/</g, '\\u003c')
        .replace(/>/g, '\\u003e')
        .replace(/&/g, '\\u0026')
        .replace(/\u2028/g, '\\u2028')
        .replace(/\u2029/g, '\\u2029');
}

/** Plain text of a markdown summary, cut at a word near `max` characters. */
export function plain(md: string, max = 160): string {
    const t = md
        .replace(/\|[^\n]*\|/g, ' ')
        .replace(/[*_`#>]/g, '')
        .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
        .replace(/\s+/g, ' ')
        .trim();
    if (t.length <= max) return t;
    const cut = t.slice(0, max);
    return cut.slice(0, cut.lastIndexOf(' ') > 0 ? cut.lastIndexOf(' ') : max).replace(/[,.;:—-]+$/, '') + '…';
}

export interface Page {
    /** Site path, '/' or '/news/x'. */
    path: string;
    title: string;
    description: string;
    /** Structured data, one or more JSON-LD objects. */
    ld?: unknown[];
    /** The page's text as HTML, already escaped. */
    body: string;
}

/** The shell (build/index.html) with one page's head and text put in. */
export function render(shell: string, p: Page): string {
    const url = ORIGIN + p.path;
    const head = [
        `<title>${escapeHtml(p.title)}</title>`,
        `<meta name="description" content="${escapeHtml(p.description)}" />`,
        `<link rel="canonical" href="${escapeHtml(url)}" />`,
        `<meta property="og:type" content="website" />`,
        `<meta property="og:site_name" content="${BRAND}" />`,
        `<meta property="og:title" content="${escapeHtml(p.title)}" />`,
        `<meta property="og:description" content="${escapeHtml(p.description)}" />`,
        `<meta property="og:url" content="${escapeHtml(url)}" />`,
        `<meta property="og:locale" content="vi_VN" />`,
        `<meta property="og:locale:alternate" content="en_AU" />`,
        ...(p.ld ?? []).map((o) => `<script type="application/ld+json">${jsonLd(o)}</script>`)
    ].join('\n        ');
    if (!shell.includes('</head>') || !/<body[^>]*>/.test(shell)) throw new Error('shell has no </head> or <body>');
    return shell
        .replace('</head>', `        ${head}\n    </head>`)
        .replace(/<body[^>]*>/, (b) => `${b}\n        <div id="seo-static">${p.body}</div>`);
}

const nav = `<nav><a href="/">${BRAND}</a> · <a href="/news">Tin tức · News</a> · <a href="/facts">Số liệu · Facts</a> · <a href="/plan">Lập kế hoạch · Plan</a></nav>`;

function sourcesList(urls: string[]): string {
    const u = [...new Set(urls.filter((x) => /^https?:\/\//.test(x)))];
    if (!u.length) return '';
    return `<h2>Nguồn · Sources</h2><ul>${u.map((x) => `<li><a href="${escapeHtml(x)}">${escapeHtml(x)}</a></li>`).join('')}</ul>`;
}

const publisher = { '@type': 'Organization', name: BRAND, url: ORIGIN };

export function notePage(n: NewsNote): Page {
    const vi = n.headline_vi || n.headline_en || noteSlug(n.news_slug);
    const en = n.headline_en || '';
    const urls = (n.sources ?? []).map((s) => s.url ?? '');
    const date = n.authored_date ?? n.effective_from ?? '';
    const body = [
        nav,
        `<article>`,
        `<h1>${escapeHtml(vi)}</h1>`,
        en ? `<p lang="en"><strong>${escapeHtml(en)}</strong></p>` : '',
        date ? `<p><time datetime="${escapeHtml(date)}">${escapeHtml(date)}</time></p>` : '',
        n.summary_vi ? `<section lang="vi">${renderMarkdown(n.summary_vi)}</section>` : '',
        n.summary_en ? `<section lang="en">${renderMarkdown(n.summary_en)}</section>` : '',
        sourcesList(urls),
        `</article>`
    ].join('');
    return {
        path: notePath(n),
        title: `${vi} | ${BRAND}`,
        description: plain(n.summary_vi || n.summary_en || vi),
        ld: [
            {
                '@context': 'https://schema.org',
                '@type': 'NewsArticle',
                headline: vi,
                ...(en ? { alternativeHeadline: en } : {}),
                description: plain(n.summary_vi || vi, 300),
                ...(date ? { datePublished: date, dateModified: date } : {}),
                inLanguage: 'vi',
                url: ORIGIN + notePath(n),
                mainEntityOfPage: ORIGIN + notePath(n),
                citation: [...new Set(urls.filter(Boolean))],
                author: publisher,
                publisher
            }
        ],
        body
    };
}

function noteItem(n: NewsNote): string {
    const d = n.authored_date ? `<time datetime="${escapeHtml(n.authored_date)}">${escapeHtml(n.authored_date)}</time> — ` : '';
    const en = n.headline_en ? ` <span lang="en">(${escapeHtml(n.headline_en)})</span>` : '';
    return `<li>${d}<a href="${notePath(n)}">${escapeHtml(n.headline_vi || n.headline_en || '')}</a>${en}</li>`;
}

export function newsIndexPage(news: NewsNote[]): Page {
    return {
        path: '/news',
        title: `Tin tức visa, thuế, tài chính và nhà đất Úc · News | ${BRAND}`,
        description:
            'Thay đổi về visa, tài chính, thuế và thị trường nhà đất Úc, từ nguồn chính phủ. Changes in Australian visas, finance, tax and property, from government sources.',
        ld: [{ '@context': 'https://schema.org', '@type': 'CollectionPage', name: 'Tin tức · News', url: ORIGIN + '/news', inLanguage: 'vi' }],
        body: `${nav}<h1>Tin tức · News</h1><p>Thay đổi về visa, tài chính, thuế và thị trường, theo từng chủ đề. <span lang="en">Changes in visas, finance, tax and the market, by topic.</span></p><ul>${news.map(noteItem).join('')}</ul>`
    };
}

function factValue(f: FactDoc['facts'][number]): string {
    return f.value === undefined ? '' : ` — ${escapeHtml(String(f.value))}${f.unit ? ' ' + escapeHtml(f.unit) : ''}`;
}

export function factsPage(docs: FactDoc[]): Page {
    const sections = docs.map((d) => {
        const items = d.facts
            .map((f) => {
                // Every source the fact cites — a rule and its exception, or a figure and
                // the note under it — so a crawler reads each citation (behavior 137 Expect 2).
                const idx = [...new Set(([] as number[]).concat(f.source, f.note_sources ?? []))];
                const src = [...new Set(idx.map((i) => d.sources[i]?.url).filter((u): u is string => !!u && /^https?:\/\//.test(u)))];
                const cite = src.map((u, k) => ` <a href="${escapeHtml(u)}">${k ? `Nguồn ${k + 1}` : 'Nguồn · Source'}</a>`).join('');
                return `<li><strong>${escapeHtml(f.headline.vi)}</strong> <span lang="en">(${escapeHtml(f.headline.en)})</span>${factValue(f)}. ${escapeHtml(f.caption.vi)} <span lang="en">${escapeHtml(f.caption.en)}</span>${f.as_of ? ` (${escapeHtml(f.as_of)})` : ''}.${cite}</li>`;
            })
            .join('');
        return `<section><h2>${escapeHtml(d.title.vi)} · <span lang="en">${escapeHtml(d.title.en)}</span></h2><ul>${items}</ul></section>`;
    });
    return {
        path: '/facts',
        title: `Nước Úc qua số liệu · Australia in figures | ${BRAND}`,
        description:
            'Người Việt ở Úc, nhà đất, cuộc sống, kinh tế và phí visa, từ nguồn chính phủ. Vietnamese in Australia, property, living, the economy and visa fees, from government sources.',
        ld: [{ '@context': 'https://schema.org', '@type': 'CollectionPage', name: 'Nước Úc qua số liệu · Australia in figures', url: ORIGIN + '/facts', inLanguage: 'vi' }],
        body: `${nav}<h1>Nước Úc qua số liệu · <span lang="en">Australia in figures</span></h1>${sections.join('')}`
    };
}

export function homePage(news: NewsNote[]): Page {
    return {
        path: '/',
        title: `${BRAND} — ${TAGLINE_VI}`,
        description: `${TAGLINE_VI}: chi phí khi mua, khi sở hữu và khi bán nhà theo từng bang, tin tức visa, thuế và tài chính từ nguồn chính phủ. ${TAGLINE_EN}.`,
        ld: [
            { '@context': 'https://schema.org', '@type': 'WebSite', name: BRAND, url: ORIGIN + '/', inLanguage: ['vi', 'en'], description: `${TAGLINE_VI}. ${TAGLINE_EN}.` },
            { '@context': 'https://schema.org', ...publisher }
        ],
        body: `${nav}<h1>${BRAND}</h1><p>${escapeHtml(TAGLINE_VI)}. <span lang="en">${escapeHtml(TAGLINE_EN)}.</span></p><ul><li><a href="/plan">Lập kế hoạch ngân sách · Plan your budget</a>: chi phí khi mua, khi sở hữu và khi bán nhà, theo bang.</li><li><a href="/news">Tin tức · News</a></li><li><a href="/facts">Nước Úc qua số liệu · Australia in figures</a></li></ul><h2>Tin mới · Latest</h2><ul>${news.slice(0, 10).map(noteItem).join('')}</ul>`
    };
}

/** robots.txt: every crawler, search and AI, reads the public pages; app pages and the API stay out. */
export function robots(): string {
    const agents = ['*', 'Googlebot', 'Bingbot', 'GPTBot', 'OAI-SearchBot', 'ChatGPT-User', 'ClaudeBot', 'Claude-SearchBot', 'Claude-User', 'PerplexityBot', 'Perplexity-User', 'Google-Extended', 'Applebot', 'Applebot-Extended'];
    return [
        '# Mai An Cư — public pages for search engines and AI assistants (behavior 137).',
        ...agents.map((a) => `User-agent: ${a}`),
        'Allow: /',
        'Disallow: /plan',
        'Disallow: /status',
        'Disallow: /api/',
        '',
        `Sitemap: ${ORIGIN}/sitemap.xml`,
        ''
    ].join('\n');
}

export function sitemap(news: NewsNote[], facts: FactDoc[]): string {
    const newest = news[0]?.authored_date;
    const factsDate = facts.map((d) => d.last_verified).filter(Boolean).sort().at(-1);
    const urls: [string, string | undefined][] = [
        ['/', newest],
        ['/news', newest],
        ['/facts', factsDate],
        ...news.map((n): [string, string | undefined] => [notePath(n), n.authored_date])
    ];
    const rows = urls.map(([p, d]) => `  <url><loc>${escapeHtml(ORIGIN + p)}</loc>${d ? `<lastmod>${escapeHtml(d)}</lastmod>` : ''}</url>`);
    return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${rows.join('\n')}\n</urlset>\n`;
}

/** llms.txt (llmstxt.org): a plain index an AI assistant reads to find the right page. */
export function llms(news: NewsNote[], facts: FactDoc[]): string {
    const oneLine = (s: string) => s.replace(/\s+/g, ' ').trim();
    return [
        `# ${BRAND}`,
        '',
        `> ${TAGLINE_EN}. A bilingual (Vietnamese and English) guide for Vietnamese buyers of Australian property: what buying, owning and selling a home cost by state, and the visa, tax, finance and scheme rules behind those costs. Every figure and news note cites a government source.`,
        '',
        'Pages are in Vietnamese with English alongside. The budget planner (/plan) is an interactive app and is not indexed.',
        '',
        '## News',
        '',
        ...news.map((n) => `- [${oneLine(n.headline_en || n.headline_vi || '')}](${ORIGIN}${notePath(n)}): ${oneLine(n.headline_vi || '')}${n.authored_date ? ` (${n.authored_date})` : ''}`),
        '',
        '## Facts',
        '',
        `- [Australia in figures](${ORIGIN}/facts): ${facts.map((d) => d.title.en).join('; ')}`,
        '',
        '## Optional',
        '',
        `- [Home](${ORIGIN}/): ${TAGLINE_EN}`,
        ''
    ].join('\n');
}

// ---- Guides (behavior 146) -------------------------------------------------------------
// Regulated figures are grounded -> P-7 -> The web frontend -> one static page per published KB doc
// Son 2026-11-01: "make sure our platform is optimal for ai agent search (perplexity,
// chatgpt, ...)". An assistant cites a page that states the rule; the news pages only say
// what changed. So each KB doc a reader may see becomes /guide/<slug, dots as dashes>: a
// plain static HTML page (no app script — a person sees the same page, since the SPA
// shell would hide it and show its not-found), in English (Son allowed English-only).
// Invariant: a guide exists only for a published doc — not UI copy, a journey or a
//   bilingual-term doc, not carrying PLACEHOLDER or NOT SOURCE-GROUNDED, and with at least
//   one source — and keeps the doc's whole text (the checker found a section filter cut the
//   FIRB fee path, the non-resident CGT default and agent commission). Every href on it is
//   https, a built /guide or /news page, or nothing: a KB link (../x.md) to a published doc
//   becomes its guide, any other non-https link becomes its text.
// Mechanism: readerMarkdown rewrites the markdown (mode labels in reader words, the one
//   planner aside removed, links), then guideHtml splits it at heading lines outside code
//   fences — the heading escaped into h1/h2/h3, each chunk between through renderMarkdown
//   (escape-first; it keeps only http(s) links, which the rewrite has already limited to
//   https). Hosts are not checked here: kb_compiler's GATE 17 passed every URL a doc carries
//   before `npm run build` reaches this (kb_compiler.py), so no copy of its host map is kept.
// Capability: isPublished, guidePath, readerMarkdown, guidePage, staticPage.

const UNPUBLISHED = new Set(['copy', 'journey', 'bilingual']);

export function isPublished(slug: string, d: KbDoc): boolean {
    return (
        !UNPUBLISHED.has(slug.split('.')[1] ?? '') &&
        !d.content_md.includes('PLACEHOLDER') &&
        !d.content_md.includes('NOT SOURCE-GROUNDED') &&
        (d.sources ?? []).some((s) => /^https:\/\//.test(s.url ?? ''))
    );
}

/** kb.scheme.nsw.fhbas -> scheme-nsw-fhbas */
export function guideSlug(slug: string): string {
    return slug.replace(/^kb\./, '').replace(/\./g, '-');
}

export function guidePath(slug: string): string {
    return `/guide/${guideSlug(slug)}`;
}

/** kb.scheme.nsw.fhbas -> scheme/nsw/fhbas.md, its file under docs/kb (kb_compiler's naming). */
function kbFile(slug: string): string {
    return slug.replace(/^kb\./, '').replace(/\./g, '/') + '.md';
}

/** The published docs, sorted by slug. */
export function allGuides(a: Artifact): [string, KbDoc][] {
    return Object.entries(a.kb ?? {})
        .filter(([k, d]) => isPublished(k, d))
        .sort(([x], [y]) => x.localeCompare(y));
}

// The planner's buyer modes (docs/blueprints), in the words a reader uses.
const MODE: Record<string, [string, string]> = {
    A: ['first-home buyer who is an Australian citizen or PR', 'first-home buyers who are Australian citizens or PRs'],
    B: ['first-home buyer who is a foreign person', 'first-home buyers who are foreign persons'],
    C: ['investor who is an Australian citizen or PR', 'investors who are Australian citizens or PRs'],
    D: ['foreign investor living in Vietnam', 'foreign investors living in Vietnam'],
    E: ['repeat owner-occupier', 'repeat owner-occupiers']
};
const MODE_RE = /Modes?[- ]([A-E])\b((?:\s*(?:\/|\+|,|&|\band\b|\bor\b)\s*(?:Modes?[- ])?[A-E]\b)*)(?:\s+(buyers|investors|buyer|investor)\b)?/g;

function modeWords(md: string): string {
    return md.replace(MODE_RE, (_m, first: string, rest: string, noun?: string) => {
        const letters = [...new Set([first, ...(rest.match(/\b[A-E]\b/g) ?? [])])];
        const plural = letters.length > 1 || noun === 'buyers' || noun === 'investors';
        return letters.map((l) => MODE[l][plural ? 1 : 0]).join(' or ');
    }).replace(/Modes?-(?=[a-z])/g, 'buyer-type ');
}

/** Resolve a link target written in docs/kb/<from> to a KB slug, or null. */
function kbTarget(fromSlug: string, target: string): string | null {
    const dir = kbFile(fromSlug).split('/').slice(0, -1);
    for (const part of target.split('/')) {
        if (part === '..') { if (!dir.length) return null; dir.pop(); }
        else if (part !== '.' && part !== '') dir.push(part);
    }
    const file = dir.join('/');
    if (!file.endsWith('.md')) return null;
    return 'kb.' + file.slice(0, -3).replace(/\//g, '.');
}

/**
 * The doc's markdown as a reader gets it: mode labels in reader words, the planner aside
 * gone, and every [text](target) either an https link (a source, or a published doc's
 * guide) or its text alone; a published doc named by its key links to its guide.
 */
export function readerMarkdown(slug: string, md: string, published: Map<string, string>): string {
    const keyTitle = (t: string) => t.replace(/`(kb\.[a-z0-9.-]+)`/g, (m, k: string) => published.get(k) ?? m);
    const linked = md.replace(/(!?)\[([^\]\n]*)\]\(([^)\n]*)\)/g, (_m, bang: string, rawText: string, raw: string) => {
        const text = keyTitle(rawText);
        const target = raw.trim().split(/\s+/)[0] ?? '';
        if (/^https:\/\/[^\s"'<>]+$/.test(target)) return `${bang}[${text}](${target})`;
        if (/^[a-z][a-z0-9+.-]*:/i.test(target) || target.startsWith('#') || target.startsWith('/')) return text;
        const to = kbTarget(slug, target.split('#')[0]);
        return to && published.has(to) ? `[${text}](${ORIGIN}${guidePath(to)})` : text;
    });
    // A doc named by its key in a code span (`kb.scheme.qld.fhc`) reads as its guide's title.
    const named = linked.replace(/`(kb\.[a-z0-9.-]+)`/g, (m, k: string) => (published.has(k) ? `[${published.get(k)}](${ORIGIN}${guidePath(k)})` : m));
    return modeWords(named.replace(/\s*\(agent reasons over these\)/g, ''));
}

// [^\n], not '.': '.' stops at U+2028/U+2029, which a KB text may carry.
const GHEAD = /^\s{0,3}(#{1,6})\s+([^\n]*?)\s*#*\s*$/;
const GFENCE = /^\s*```/;

/** The markdown as HTML: real h1/h2/h3 headings, each body chunk through renderMarkdown. */
export function guideHtml(md: string): string {
    const out: string[] = [];
    let chunk: string[] = [];
    let fenced = false;
    const flush = () => {
        if (chunk.join('').trim()) out.push(renderMarkdown(chunk.join('\n')));
        chunk = [];
    };
    for (const line of md.replace(/\r\n?/g, '\n').split('\n')) {
        if (GFENCE.test(line)) fenced = !fenced;
        const h = fenced ? null : GHEAD.exec(line);
        if (h) {
            flush();
            const n = Math.min(h[1].length, 3);
            out.push(`<h${n}>${renderInlineMarkdown(h[2])}</h${n}>`);
        } else chunk.push(line);
    }
    flush();
    return out.join('\n');
}

/** The doc's title: its first `# ` heading, as plain text. */
export function guideTitle(slug: string, md: string): string {
    const h1 = splitH1(md)[0];
    return plain(h1 || guideSlug(slug), 200) || guideSlug(slug);
}

/** [the first `# ` heading's text, the markdown without that line] — split on \n only. */
function splitH1(md: string): [string, string] {
    const lines = md.replace(/\r\n?/g, '\n').split('\n');
    const i = lines.findIndex((l) => /^\s{0,3}#\s/.test(l));
    if (i < 0) return ['', md];
    const t = lines[i].replace(/^\s{0,3}#\s+/, '').replace(/\s*#*\s*$/, '');
    return [t, [...lines.slice(0, i), ...lines.slice(i + 1)].join('\n')];
}

/** Each published doc's slug and title, the map readerMarkdown links by. */
export function guideTitles(guides: [string, KbDoc][]): Map<string, string> {
    return new Map(guides.map(([k, d]) => [k, guideTitle(k, d.content_md).replace(/[[\]\n]/g, '')]));
}

export function guidePage(slug: string, d: KbDoc, published: Map<string, string>): Page {
    const md = readerMarkdown(slug, d.content_md, published);
    const title = guideTitle(slug, md);
    const body = splitH1(md)[1];
    const urls = [...new Set((d.sources ?? []).map((s) => s.url ?? '').filter((u) => /^https:\/\/[^\s"'<>]+$/.test(u)))];
    const retrieved = new Map((d.sources ?? []).map((s) => [s.url ?? '', s.retrieved ?? '']));
    const path = guidePath(slug);
    const html = [
        `<article>`,
        `<h1>${escapeHtml(title)}</h1>`,
        d.last_verified ? `<p class="meta">Last verified <time datetime="${escapeHtml(d.last_verified)}">${escapeHtml(d.last_verified)}</time>${d.effective_from ? ` · in effect from <time datetime="${escapeHtml(d.effective_from)}">${escapeHtml(d.effective_from)}</time>` : ''}</p>` : '',
        guideHtml(body),
        urls.length
            ? `<h2>Sources</h2><ul class="sources">${urls.map((u) => `<li><a href="${escapeHtml(u)}">${escapeHtml(u)}</a>${retrieved.get(u) ? ` (retrieved ${escapeHtml(retrieved.get(u)!)})` : ''}</li>`).join('')}</ul>`
            : '',
        `</article>`
    ].join('\n');
    const description = plain(body.split('\n').filter((l) => !GHEAD.test(l)).join('\n')) || title;
    return {
        path,
        title: `${title} | ${BRAND}`,
        description,
        ld: [
            {
                '@context': 'https://schema.org',
                '@type': 'Article',
                headline: title,
                description,
                inLanguage: 'en',
                ...(d.effective_from ? { datePublished: d.effective_from } : {}),
                ...(d.last_verified ? { dateModified: d.last_verified } : {}),
                url: ORIGIN + path,
                mainEntityOfPage: ORIGIN + path,
                citation: urls,
                author: publisher,
                publisher
            }
        ],
        body: html
    };
}

const STATIC_CSS = `body{margin:0;background:#f6f4ef;color:#1f2328;font:16px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}header,main,footer{max-width:46rem;margin:0 auto;padding:0 16px}header{padding-block:14px;border-bottom:1px solid #ddd8cc}header nav a{margin-right:14px}header nav a:first-child{font-weight:700}a{color:#0b5a7a}h1{font-size:1.7rem;line-height:1.25;text-wrap:balance}h2{font-size:1.25rem;margin-top:2rem}h3{font-size:1.05rem}.meta{color:#5b5f66;font-size:.9rem}.md-table{overflow-x:auto}table{border-collapse:collapse;font-size:.92rem}th,td{border:1px solid #ddd8cc;padding:4px 8px;text-align:left;vertical-align:top}.sources{word-break:break-all;font-size:.9rem}footer{padding-block:24px;color:#5b5f66;font-size:.85rem}@media (prefers-color-scheme:dark){body{background:#1b1d20;color:#e6e3dc}header{border-color:#3a3d42}a{color:#7cc4e4}.meta,footer{color:#a5a29b}th,td{border-color:#3a3d42}}`;

/** A whole static page (no app): the site header, the page's text and its head. */
export function staticPage(p: Page, lang = 'en'): string {
    const url = ORIGIN + p.path;
    return `<!doctype html>
<html lang="${lang}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${escapeHtml(p.title)}</title>
<meta name="description" content="${escapeHtml(p.description)}" />
<link rel="canonical" href="${escapeHtml(url)}" />
<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
<meta property="og:type" content="article" />
<meta property="og:site_name" content="${BRAND}" />
<meta property="og:title" content="${escapeHtml(p.title)}" />
<meta property="og:description" content="${escapeHtml(p.description)}" />
<meta property="og:url" content="${escapeHtml(url)}" />
${(p.ld ?? []).map((o) => `<script type="application/ld+json">${jsonLd(o)}</script>`).join('\n')}
<style>${STATIC_CSS}</style>
</head>
<body>
<header><nav><a href="/">${BRAND}</a><a href="/guide">Guides</a><a href="/news">News</a><a href="/facts">Facts</a><a href="/plan">Plan your budget</a></nav></header>
<main>
${p.body}
</main>
<footer>General information from government sources, not financial, legal or tax advice. ${BRAND} · <a href="${ORIGIN}/">maiancu.com</a></footer>
</body>
</html>
`;
}
