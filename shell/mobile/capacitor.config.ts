// Honest-partial -> the suburb data the goal names -> the phone app -> what the app loads
// Goal:      behavior 161 — the Mai An Cư phone app is the website itself in a web view, so
//            every deploy reaches it with no store update, and /api stays same-origin with its
//            cookies (the guest session, the chat stream).
// Invariant: server.url is https://maiancu.com unless CAP_SERVER_URL names another origin at
//            `cap sync` time (the dev stack: http://10.0.2.2:5173 on the Android emulator,
//            http://127.0.0.1:5173 on the iPhone simulator). Cleartext is allowed only when that
//            URL is http, so a build on the default never allows it.
// Capability: Capacitor 8.5.3 — server.url «Load an external URL in the Web View … not intended
//            for production» (cli declarations.d.ts); a later behavior decides between it and
//            bundling the pages before any store submission. webDir (www/) is a placeholder
//            the CLI requires; nothing in it is served while server.url is set.
import type { CapacitorConfig } from '@capacitor/cli';

const url = process.env.CAP_SERVER_URL || 'https://maiancu.com';
if (!/^https?:\/\/[^/]+$/.test(url)) throw new Error(`CAP_SERVER_URL must be an origin, got ${url}`);
const cleartext = url.startsWith('http://');

const config: CapacitorConfig = {
    appId: 'com.maiancu.app',
    appName: 'Mai An Cư',
    webDir: 'www',
    server: { url, cleartext },
    android: { allowMixedContent: false },
};

export default config;
