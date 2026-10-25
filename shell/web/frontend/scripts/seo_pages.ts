// Regulated figures are grounded -> P-7 -> The web frontend -> the public pages written after the build (behavior 137)
// Run by `npm run build` after kb_compiler.py and `vite build`: reads the compiled KB
// artifact (engine/erlang/priv/kb/artifact.json, the one the engine loads at the same
// commit) and build/index.html, and writes build/index.html (the home; it stays the SPA
// fallback for every other address), build/news.html, build/news/<slug>.html,
// build/facts.html, robots.txt, sitemap.xml and llms.txt. Cloudflare Pages serves
// /news/<slug> from news/<slug>.html. The helpers are in seo.ts.
//   node scripts/seo_pages.ts [artifact.json] [build dir]
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { allNews, allFacts, render, homePage, newsIndexPage, notePage, factsPage, robots, sitemap, llms, noteSlug, type Artifact } from './seo.ts';

const artifactPath = process.argv[2] ?? '../../../engine/erlang/priv/kb/artifact.json';
const build = process.argv[3] ?? 'build';

const artifact = JSON.parse(readFileSync(artifactPath, 'utf8')) as Artifact;
const news = allNews(artifact);
const facts = allFacts(artifact);
if (!news.length || !facts.length) throw new Error(`${artifactPath}: ${news.length} news notes, ${facts.length} fact docs — refusing to write empty pages`);

const shell = readFileSync(join(build, 'index.html'), 'utf8');
if (shell.includes('id="seo-static"')) throw new Error(`${build}/index.html already holds a page: run vite build first`);

const put = (rel: string, text: string) => writeFileSync(join(build, rel), text);
put('index.html', render(shell, homePage(news)));
put('news.html', render(shell, newsIndexPage(news)));
put('facts.html', render(shell, factsPage(facts)));
mkdirSync(join(build, 'news'), { recursive: true });
for (const n of news) put(`news/${noteSlug(n.news_slug)}.html`, render(shell, notePage(n)));
put('robots.txt', robots());
put('sitemap.xml', sitemap(news, facts));
put('llms.txt', llms(news, facts));
console.log(`seo_pages: ${news.length} note pages, home, /news, /facts, robots.txt, sitemap.xml (${news.length + 3} URLs), llms.txt`);
