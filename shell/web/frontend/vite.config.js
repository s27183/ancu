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
        proxy: {
            '/api': { target: 'http://127.0.0.1:8081', changeOrigin: false },
            '/health': { target: 'http://127.0.0.1:8081', changeOrigin: false }
        }
    }
});
