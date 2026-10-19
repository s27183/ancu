import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

// Frontend deploys as a static SPA (shell-architecture.md §1/§8). The shell
// backend (Erlang/Cowboy, :8081) serves the built bundle from `/` and the JSON
// API from `/api/*`; Cloudflare Pages can host the same static bundle. Client-side
// routing handles deep links via `fallback`. (Mirrors aleap's adapter-static SPA;
// §8's "Cloudflare Pages adapter" wording = adapter-static's bundle hosted on Pages.)
/** @type {import('@sveltejs/kit').Config} */
const config = {
    preprocess: vitePreprocess(),
    kit: {
        adapter: adapter({
            pages: 'build',
            assets: 'build',
            fallback: 'index.html',
            precompress: false,
            strict: true
        }),
        // Behavior 135: every merge rebuilds the bundle (Cloudflare Pages, measured
        // 2026-10-19: version.json 4 min after the merge); the page asks for
        // _app/version.json once a minute, and +layout.svelte loads a new bundle at the
        // next move between pages or return to the tab (`updated` from $app/state).
        version: { pollInterval: 60_000 }
    }
};

export default config;
