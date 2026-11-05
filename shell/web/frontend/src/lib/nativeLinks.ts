// Honest-partial -> the suburb data the goal names -> the web frontend -> outside links in the phone app
// Goal:      behavior 161 — in the Mai An Cư phone app (shell/mobile/, Capacitor), every outside
//            link (the listing sites, a fact's, term's or news note's source, the FX bank) opens
//            in the phone's own in-app browser over the app — Chrome Custom Tabs on Android,
//            SFSafariViewController on iPhone — and closing it lands back where the reader was.
// Invariant: only an absolute https URL to a host other than the page's own is handed to the
//            in-app browser, and only inside the app; anything else (relative, our own host or maiancu.com,
//            http, javascript:, intent:, data:, mailto:, malformed) is left to the web view's
//            own handling. On the website nothing changes: there is no bridge, so this is inert
//            and behavior 150's tab / popup stays. The listing page runs in Chrome's or
//            Safari's process, never in our web view: we link out, never frame
//            («No property scraping»).
// Capability: the Capacitor bridge is injected into the page the app loads (server.url) as
//            window.Capacitor, with isNativePlatform() and nativePromise(plugin, method, opts)
//            (@capacitor/android 8.5.3 native-bridge.js; iOS JSExport.swift's WKUserScript at
//            document start), so the website bundle carries no Capacitor package: it calls
//            the Browser plugin (@capacitor/browser 8.0.5: open({ url })) by name.

interface CapacitorBridge {
    isNativePlatform?: () => boolean;
    nativePromise?: (plugin: string, method: string, options: Record<string, unknown>) => Promise<unknown>;
}

function bridge(): CapacitorBridge | null {
    const cap = (globalThis as { Capacitor?: CapacitorBridge }).Capacitor;
    return cap && typeof cap.nativePromise === 'function' ? cap : null;
}

/** True inside the phone app (the Capacitor bridge is present and says so). */
export function isNativeApp(): boolean {
    const cap = bridge();
    try {
        return !!cap?.isNativePlatform?.();
    } catch {
        return false;
    }
}

/** Mai An Cư's own site: a link to it stays in the app even when the app loads the dev stack. */
const OWN_HOSTS = new Set(['maiancu.com', 'www.maiancu.com']);

/** The URL to hand to the in-app browser for this href, or null to leave it to the web view. */
export function externalTarget(href: string | null | undefined, ownHost: string, native: boolean): string | null {
    if (!native || typeof href !== 'string' || !href) return null;
    let u: URL;
    try {
        u = new URL(href); // no base: a relative href throws
    } catch {
        return null;
    }
    if (u.protocol !== 'https:' || !u.hostname) return null;
    if (u.username || u.password) return null;
    if (u.host.toLowerCase() === ownHost.toLowerCase() || OWN_HOSTS.has(u.hostname)) return null;
    return u.href;
}

/** Open url in the phone's in-app browser. Resolves false if the bridge refused. */
export async function openInApp(url: string): Promise<boolean> {
    const cap = bridge();
    if (!cap?.nativePromise) return false;
    try {
        await cap.nativePromise('Browser', 'open', { url });
        return true;
    } catch {
        return false;
    }
}

/** In the app, catch every click on an outside link before the page's own handlers
 *  (capture on document) and open it in the in-app browser. Returns the remover. */
export function installNativeLinks(doc: Document = document): () => void {
    if (!isNativeApp()) return () => {};
    const onClick = (e: MouseEvent) => {
        if (e.defaultPrevented || e.button !== 0) return;
        const a = (e.target as Element | null)?.closest?.('a[href]') as HTMLAnchorElement | null;
        if (!a) return;
        const url = externalTarget(a.getAttribute('href'), location.host, true);
        if (!url) return;
        e.preventDefault();
        e.stopPropagation();
        void openInApp(url);
    };
    doc.addEventListener('click', onClick, true);
    return () => doc.removeEventListener('click', onClick, true);
}
