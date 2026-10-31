// Regulated figures are grounded -> P-7 -> The web frontend -> the public pages written after the build (behavior 137)
// Run by `npm run build` after kb_compiler.py and `vite build`: reads the compiled KB
// artifact (engine/erlang/priv/kb/artifact.json, the one the engine loads at the same
// commit) and build/index.html, and writes build/index.html (the home; it stays the SPA
// fallback for every other address), build/news.html, build/news/<slug>.html,
// build/facts.html, build/guide.html, build/guide/<doc>.html (behavior 146), robots.txt,
// sitemap.xml, llms.txt and llms-full.txt. Cloudflare Pages serves /news/<slug> from
// news/<slug>.html and /guide/<doc> from guide/<doc>.html, before the SPA fallback. The helpers are in seo.ts.
//   node scripts/seo_pages.ts [artifact.json] [build dir]
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { allNews, allFacts, allGuides, guideTitles, guidePage, guideIndexPage, guideSlug, staticPage, llmsFull, render, homePage, newsIndexPage, notePage, factsPage, robots, sitemap, llms, noteSlug, type Artifact } from './seo.ts';

const artifactPath = process.argv[2] ?? '../../../engine/erlang/priv/kb/artifact.json';
const build = process.argv[3] ?? 'build';

const artifact = JSON.parse(readFileSync(artifactPath, 'utf8')) as Artifact;
const news = allNews(artifact);
const facts = allFacts(artifact);
const guides = allGuides(artifact);
if (!news.length || !facts.length || !guides.length) throw new Error(`${artifactPath}: ${news.length} news notes, ${facts.length} fact docs, ${guides.length} guides — refusing to write empty pages`);

const shell = readFileSync(join(build, 'index.html'), 'utf8');
if (shell.includes('id="seo-static"')) throw new Error(`${build}/index.html already holds a page: run vite build first`);

const put = (rel: string, text: string) => writeFileSync(join(build, rel), text);
put('index.html', render(shell, homePage(news)));
put('news.html', render(shell, newsIndexPage(news)));
put('facts.html', render(shell, factsPage(facts)));
mkdirSync(join(build, 'news'), { recursive: true });
for (const n of news) put(`news/${noteSlug(n.news_slug)}.html`, render(shell, notePage(n)));
// Guides (behavior 146): whole static pages, not the SPA shell — the app would hide the
// text and show its not-found at /guide/<doc>.
const titles = guideTitles(guides);
mkdirSync(join(build, 'guide'), { recursive: true });
put('guide.html', staticPage(guideIndexPage(guides)));
for (const [k, d] of guides) put(`guide/${guideSlug(k)}.html`, staticPage(guidePage(k, d, titles)));
put('robots.txt', robots());
put('sitemap.xml', sitemap(news, facts, guides));
put('llms.txt', llms(news, facts, guides));
put('llms-full.txt', llmsFull(news, facts, guides));
console.log(`seo_pages: ${news.length} note pages, ${guides.length} guides, home, /news, /facts, /guide, robots.txt, sitemap.xml (${news.length + guides.length + 4} URLs), llms.txt, llms-full.txt`);
