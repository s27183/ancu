// Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend -> the
// Add to Home Screen pill and its sheet
// Goal:      behavior 153 (was 152's strip under the cards): a pill at the top-right of the
//            home opens a sheet with the steps for this device, and Son's video once one is
//            published (InstallSheet.svelte). iOS 26.2 Safari keeps Share under its ⋯ menu
//            (measured 2026-11-04: its own first-run tip says so).
// Invariant: the pill shows in every browser except the installed app (navigator.standalone
//            or display-mode: standalone). The steps are those of the device the page reads:
//            an in-app browser (Zalo, Facebook, Instagram, …, which has no Add to Home
//            Screen of its own) is told to open the page in Safari or Chrome first, then the
//            phone's own steps. Nothing read here can throw.
// Capability: a pure rule over what the page can read — the user agent, touch points
//            (iPadOS reports a Mac user agent) and the two standalone signals — so
//            unit/installHint.test.ts runs it over every case.

export interface HintEnv {
    ua: string;
    maxTouchPoints: number;
    /** Safari's navigator.standalone: true inside a home-screen app. */
    navigatorStandalone: boolean;
    /** matchMedia('(display-mode: standalone)').matches */
    displayStandalone: boolean;
}

export type InstallPlatform = 'ios' | 'android' | 'desktop';

export interface InstallSteps {
    platform: InstallPlatform;
    /** An in-app browser: open the page in Safari or Chrome first. */
    inApp: boolean;
}

// In-app browsers of the apps Vietnamese visitors arrive from; each adds its mark.
const IN_APP = /FBAN|FBAV|FB_IAB|Instagram|Zalo|Line\/|MicroMessenger|Messenger|Snapchat|Twitter|LinkedInApp|Pinterest|TikTok|musical_ly|BytedanceWebview/i;

function isIosDevice(ua: string, maxTouchPoints: number): boolean {
    return /\b(iPhone|iPad|iPod)\b/.test(ua) || (/\bMacintosh\b/.test(ua) && maxTouchPoints > 1);
}

/** null inside the installed app: no pill. */
export function installSteps(env: HintEnv): InstallSteps | null {
    if (env.navigatorStandalone || env.displayStandalone) return null;
    const ua = typeof env.ua === 'string' ? env.ua : '';
    const touch = Number.isFinite(env.maxTouchPoints) ? env.maxTouchPoints : 0;
    const platform: InstallPlatform = isIosDevice(ua, touch) ? 'ios' : /\bAndroid\b/.test(ua) ? 'android' : 'desktop';
    return { platform, inApp: platform !== 'desktop' && IN_APP.test(ua) };
}

// Behavior 157: the one-tap Install button.
// Invariant: the button shows exactly when the browser's install offer is held (caught in
//            app.html), the page is not the installed app and not an in-app browser; each
//            offer opens one dialog, so once used (Install or Cancel) the button goes until
//            the browser makes a new offer. Every other case keeps the steps as behavior 153
//            set them.
export type OfferState = 'held' | 'used' | 'none';

export function showInstallButton(steps: InstallSteps | null, offer: OfferState): boolean {
    return offer === 'held' && steps !== null && !steps.inApp;
}

/** The page's own environment; any signal that throws reads as false. */
export function browserHintEnv(): HintEnv {
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
        displayStandalone
    };
}
