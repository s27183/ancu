// Regulated figures are grounded -> P-7 -> The web frontend -> the built public pages match the KB (behavior 137, Expect 7)
// A done check, run after `npm run build`: the build holds one page per news note in the
// compiled artifact, each with its title, canonical link and one NewsArticle JSON-LD that
// parses; the sitemap lists /, /news, /facts and each note once; robots.txt names the
// sitemap; llms.txt links each note. Exits 1 naming what is missing.
//   node scripts/seo_check.ts [artifact.json] [build dir]
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { allNews, noteSlug, ORIGIN, type Artifact } from './seo.ts';

const artifactPath = process.argv[2] ?? '../../../engine/erlang/priv/kb/artifact.json';
const build = process.argv[3] ?? 'build';
const news = allNews(JSON.parse(readFileSync(artifactPath, 'utf8')) as Artifact);
const bad: string[] = [];

const pages = existsSync(join(build, 'news')) ? readdirSync(join(build, 'news')).filter((f) => f.endsWith('.html')) : [];
if (pages.length !== news.length) bad.push(`build/news holds ${pages.length} pages, the artifact ${news.length} notes`);
for (const n of news) {
    const slug = noteSlug(n.news_slug);
    const f = join(build, 'news', `${slug}.html`);
    if (!existsSync(f)) { bad.push(`no page for ${n.news_slug}`); continue; }
    const html = readFileSync(f, 'utf8');
    if (!html.includes(`<link rel="canonical" href="${ORIGIN}/news/${slug}" />`)) bad.push(`${slug}: no canonical`);
    if (!/<title>[^<]+<\/title>/.test(html)) bad.push(`${slug}: no title`);
    const ld = [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
    try {
        if (ld.length !== 1 || (JSON.parse(ld[0][1]) as { '@type'?: string })['@type'] !== 'NewsArticle') bad.push(`${slug}: not one NewsArticle`);
    } catch { bad.push(`${slug}: JSON-LD does not parse`); }
    if (!html.includes('<div id="seo-static">')) bad.push(`${slug}: no text block`);
}
for (const p of ['index.html', 'news.html', 'facts.html', 'robots.txt', 'sitemap.xml', 'llms.txt']) if (!existsSync(join(build, p))) bad.push(`no ${p}`);
if (!bad.length) {
    const sm = readFileSync(join(build, 'sitemap.xml'), 'utf8');
    const locs = [...sm.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
    const want = [`${ORIGIN}/`, `${ORIGIN}/news`, `${ORIGIN}/facts`, ...news.map((n) => `${ORIGIN}/news/${noteSlug(n.news_slug)}`)];
    if (locs.length !== want.length || want.some((u) => !locs.includes(u))) bad.push(`sitemap lists ${locs.length} URLs, want ${want.length}`);
    if (!readFileSync(join(build, 'robots.txt'), 'utf8').includes(`Sitemap: ${ORIGIN}/sitemap.xml`)) bad.push('robots.txt names no sitemap');
    const l = readFileSync(join(build, 'llms.txt'), 'utf8');
    for (const n of news) if (!l.includes(`${ORIGIN}/news/${noteSlug(n.news_slug)})`)) bad.push(`llms.txt misses ${n.news_slug}`);
}
if (bad.length) {
    console.error(bad.join('\n'));
    process.exit(1);
}
console.log(`seo_check: ${news.length} note pages, sitemap ${news.length + 3} URLs, robots.txt, llms.txt — ok`);
