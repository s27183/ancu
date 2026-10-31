// Regulated figures are grounded -> P-7 -> The web frontend -> the built public pages match the KB (behavior 137, Expect 7)
// A done check, run after `npm run build`: the build holds one page per news note in the
// compiled artifact, each with its title, canonical link and one NewsArticle JSON-LD that
// parses; the sitemap lists /, /news, /facts and each note once; robots.txt names the
// sitemap; llms.txt links each note. Behavior 146: one static guide page per published KB
// doc (title, canonical, one Article JSON-LD, an h1, its sources), /guide, llms.txt's Guides
// section, llms-full.txt naming every page, the guides in the sitemap and one Dataset per
// facts section on /facts. Exits 1 naming what is missing.
//   node scripts/seo_check.ts [artifact.json] [build dir]
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { allNews, allFacts, allGuides, guideSlug, noteSlug, ORIGIN, type Artifact } from './seo.ts';

const artifactPath = process.argv[2] ?? '../../../engine/erlang/priv/kb/artifact.json';
const build = process.argv[3] ?? 'build';
const artifact = JSON.parse(readFileSync(artifactPath, 'utf8')) as Artifact;
const news = allNews(artifact);
const facts = allFacts(artifact);
const guides = allGuides(artifact);
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
const ldTypes = (html: string): string[] => [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)].map((m) => {
    try { return (JSON.parse(m[1]) as { '@type'?: string })['@type'] ?? '?'; } catch { return 'unparsed'; }
});
const gpages = existsSync(join(build, 'guide')) ? readdirSync(join(build, 'guide')).filter((f) => f.endsWith('.html')) : [];
if (gpages.length !== guides.length) bad.push(`build/guide holds ${gpages.length} pages, the artifact ${guides.length} published docs`);
for (const [k, d] of guides) {
    const slug = guideSlug(k);
    const f = join(build, 'guide', `${slug}.html`);
    if (!existsSync(f)) { bad.push(`no guide for ${k}`); continue; }
    const html = readFileSync(f, 'utf8');
    if (!html.includes(`<link rel="canonical" href="${ORIGIN}/guide/${slug}" />`)) bad.push(`guide ${slug}: no canonical`);
    if (!/<title>[^<]+<\/title>/.test(html) || !/<h1>[^<]+<\/h1>/.test(html)) bad.push(`guide ${slug}: no title or h1`);
    if (ldTypes(html).join() !== 'Article') bad.push(`guide ${slug}: not one Article (${ldTypes(html).join()})`);
    if (/<script(?! type="application\/ld\+json")/.test(html)) bad.push(`guide ${slug}: runs script`);
    for (const s of d.sources ?? []) if (s.url?.startsWith('https://') && !html.includes(`<a href="${s.url.replace(/&/g, '&amp;').replace(/"/g, '&quot;')}">`)) bad.push(`guide ${slug}: source ${s.url} not linked`);
}
if (existsSync(join(build, 'facts.html'))) {
    const n = ldTypes(readFileSync(join(build, 'facts.html'), 'utf8')).filter((t) => t === 'Dataset').length;
    if (n !== facts.length) bad.push(`facts.html holds ${n} Dataset, the artifact ${facts.length} fact docs`);
}
for (const p of ['index.html', 'news.html', 'facts.html', 'guide.html', 'robots.txt', 'sitemap.xml', 'llms.txt', 'llms-full.txt']) if (!existsSync(join(build, p))) bad.push(`no ${p}`);
if (!bad.length) {
    const sm = readFileSync(join(build, 'sitemap.xml'), 'utf8');
    const locs = [...sm.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
    const want = [`${ORIGIN}/`, `${ORIGIN}/news`, `${ORIGIN}/facts`, ...news.map((n) => `${ORIGIN}/news/${noteSlug(n.news_slug)}`), `${ORIGIN}/guide`, ...guides.map(([k]) => `${ORIGIN}/guide/${guideSlug(k)}`)];
    if (locs.length !== want.length || want.some((u) => !locs.includes(u))) bad.push(`sitemap lists ${locs.length} URLs, want ${want.length}`);
    if (!readFileSync(join(build, 'robots.txt'), 'utf8').includes(`Sitemap: ${ORIGIN}/sitemap.xml`)) bad.push('robots.txt names no sitemap');
    const l = readFileSync(join(build, 'llms.txt'), 'utf8');
    for (const n of news) if (!l.includes(`${ORIGIN}/news/${noteSlug(n.news_slug)})`)) bad.push(`llms.txt misses ${n.news_slug}`);
    const gsec = l.split('\n## Guides\n')[1]?.split('\n## ')[0] ?? '';
    if (!gsec) bad.push('llms.txt has no Guides section');
    for (const [k] of guides) if (!gsec.includes(`${ORIGIN}/guide/${guideSlug(k)})`)) bad.push(`llms.txt Guides misses ${k}`);
    const full = readFileSync(join(build, 'llms-full.txt'), 'utf8');
    for (const [k] of guides) if (!full.includes(`Page: ${ORIGIN}/guide/${guideSlug(k)}`)) bad.push(`llms-full.txt misses ${k}`);
    for (const n of news) if (!full.includes(`Page: ${ORIGIN}/news/${noteSlug(n.news_slug)}`)) bad.push(`llms-full.txt misses ${n.news_slug}`);
    if (!full.includes(`Page: ${ORIGIN}/facts`)) bad.push('llms-full.txt misses /facts');
}
if (bad.length) {
    console.error(bad.join('\n'));
    process.exit(1);
}
console.log(`seo_check: ${news.length} note pages, ${guides.length} guide pages (/guide), sitemap ${news.length + guides.length + 4} URLs, ${facts.length} facts Datasets, robots.txt, llms.txt (Guides), llms-full.txt — ok`);
