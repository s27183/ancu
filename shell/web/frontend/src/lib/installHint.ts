// Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend -> the
// iPhone's add-to-home-screen hint
// Goal:      behavior 152 — iPhone Safari has no install prompt of its own, so the home page
//            says how: "Chạm Chia sẻ, rồi Thêm vào MH chính" / "Tap Share, then Add to Home
//            Screen" (InstallHint.svelte).
// Invariant: shown only in iOS Safari, never inside the installed app (navigator.standalone or
//            display-mode: standalone) nor in another iOS browser (CriOS, FxiOS, EdgiOS, …,
//            whose Share sheet has no Add to Home Screen of ours to point at); once closed with
//            ✕ it does not come back (HINT_KEY). Storage that throws never throws here: a
//            blocked read shows the hint, a blocked write hides it for the page view only.
// Capability: a pure rule over what the page can read — the user agent, touch points (iPadOS
//            reports a Mac user agent), the two standalone signals and a storage — so
//            unit/installHint.test.ts runs it over every case; Android Chrome offers its own
//            install prompt from the manifest (measured 2026-11-04: Chrome 156 fires
//            beforeinstallprompt with no service worker).

export const HINT_KEY = 'ancu-install-hint-closed';

/** The part of Storage the rule uses; a real localStorage or a test double. */
export interface HintStorage {
    getItem(key: string): string | null;
    setItem(key: string, value: string): void;
}

export interface HintEnv {
    ua: string;
    maxTouchPoints: number;
    /** Safari's navigator.standalone: true inside a home-screen app. */
    navigatorStandalone: boolean;
    /** matchMedia('(display-mode: standalone)').matches */
    displayStandalone: boolean;
    storage: HintStorage | null;
}

// Other browsers on iOS wrap WebKit and keep "Safari/" in their user agent; each adds its mark.
const OTHER_IOS_BROWSER = /CriOS|FxiOS|EdgiOS|OPiOS|OPT\/|GSA\/|YaBrowser|DuckDuckGo|Brave|FBAN|FBAV|Instagram|Line\/|Zalo|MicroMessenger|Snapchat|Twitter|LinkedInApp|Pinterest/i;

export function isIosSafari(ua: string, maxTouchPoints: number): boolean {
    if (typeof ua !== 'string') return false;
    const iosDevice = /\b(iPhone|iPad|iPod)\b/.test(ua) || (/\bMacintosh\b/.test(ua) && maxTouchPoints > 1);
    if (!iosDevice) return false;
    if (!/\bVersion\/\d/.test(ua) || !/\bSafari\//.test(ua) || !/AppleWebKit\//.test(ua)) return false;
    return !OTHER_IOS_BROWSER.test(ua);
}

function closed(storage: HintStorage | null): boolean {
    try {
        return storage?.getItem(HINT_KEY) === '1';
    } catch {
        return false;
    }
}

export function shouldShowInstallHint(env: HintEnv): boolean {
    if (env.navigatorStandalone || env.displayStandalone) return false;
    if (!isIosSafari(env.ua, env.maxTouchPoints)) return false;
    return !closed(env.storage);
}

/** ✕: remember it in this browser; a storage that refuses only loses the memory. */
export function closeInstallHint(storage: HintStorage | null): void {
    try {
        storage?.setItem(HINT_KEY, '1');
    } catch {
        /* storage blocked: hidden for this page view, shown again next visit */
    }
}

/** The page's own environment; null storage where reading localStorage itself throws. */
export function browserHintEnv(): HintEnv {
    let storage: HintStorage | null = null;
    try {
        storage = window.localStorage;
    } catch {
        storage = null;
    }
    let displayStandalone = false;
    try {
        displayStandalone = window.matchMedia('(display-mode: standalone)').matches;
    } catch {
        displayStandalone = false;
    }
    return {
        ua: navigator.userAgent,
        maxTouchPoints: navigator.maxTouchPoints ?? 0,
        navigatorStandalone: (navigator as Navigator & { standalone?: boolean }).standalone === true,
        displayStandalone,
        storage
    };
}
