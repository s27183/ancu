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

import { escapeHtml, renderMarkdown } from '../src/lib/markdown.ts';
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
                const src = ([] as number[]).concat(f.source).map((i) => d.sources[i]?.url).filter((u): u is string => !!u && /^https?:\/\//.test(u));
                const cite = src.length ? ` <a href="${escapeHtml(src[0])}">Nguồn · Source</a>` : '';
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
