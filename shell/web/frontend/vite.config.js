import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

// Dev: the frontend never talks to the engine directly (shell-architecture.md §1)
// — it proxies /api/* and /health to the shell BACKEND (Erlang, :8081), which holds
// the engine signing key and mints the tenant JWT. In prod the static bundle is
// served by that same backend (or Cloudflare Pages with the backend at /api).
export default defineConfig({
    plugins: [sveltekit()],
    server: {
        port: 5173,
        // A sandboxed seat gets no file-system events, so its edits never reach the dev
        // server; FH_VITE_POLL=1 (scripts/dev_stack.sh sets it) polls instead.
        watch: process.env.FH_VITE_POLL ? { usePolling: true, interval: 300 } : undefined,
        proxy: {
            '/api': { target: 'http://127.0.0.1:8081', changeOrigin: false },
            '/health': { target: 'http://127.0.0.1:8081', changeOrigin: false }
        }
    }
});
