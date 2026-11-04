// Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend -> the
// «Use as an app» pill and its sheet
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

// Behavior 158: two clips, iPhone and Android, behind two pills in the sheet.
// Invariant: the sheet opens on the visitor's own phone's clip: an Android phone (Chrome or
//            an in-app browser) gets the Android clip; an iPhone, an iPad or a computer the
//            iPhone clip (Son, 2026-11-04: both videos in the guide, the pills to switch);
//            the installed app has no sheet. The iPhone clip was recorded on Son's iPhone and
//            cropped above its dock (behavior 156); the Android clip on the Pixel 9 Pro
//            emulator set to Vietnamese, uncropped (Son: «it's just a simulator»).
//            width × height are each file's own, so the player is sized to the clip with no
//            bars beside it.
export interface InstallVideo {
    src: string;
    width: number;
    height: number;
}

export const IOS_VIDEO: InstallVideo = { src: '/install/add-to-home.mp4', width: 540, height: 1000 };
export const ANDROID_VIDEO: InstallVideo = { src: '/install/add-to-home-android.mp4', width: 720, height: 1606 };

export type InstallClip = 'ios' | 'android';
export const INSTALL_VIDEOS: Record<InstallClip, InstallVideo> = { ios: IOS_VIDEO, android: ANDROID_VIDEO };

/** The clip the sheet opens on; null inside the installed app. */
export function installClip(steps: InstallSteps | null): InstallClip | null {
    if (!steps) return null;
    return steps.platform === 'android' ? 'android' : 'ios';
}

export function installVideo(steps: InstallSteps | null): InstallVideo | null {
    const clip = installClip(steps);
    return clip ? INSTALL_VIDEOS[clip] : null;
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

// Behavior 159: the iPhone and Android pills pick the steps as well as the clip.
// Invariant: the phone steps under the pills are always the picked pill's phone. The
//            one-tap button (157's rule) and the in-app line show only while the pill is the
//            visitor's own phone (an iPhone never gets the button: Safari has no offer); on a
//            computer the computer's button and steps stay at the top, for this computer,
//            and the pills below are for a phone (Son, 2026-11-04: «why do we still have ios
//            guide text for android? where is the "Cài đặt ứng dụng" button?»).
export interface SheetView {
    /** A computer: its own steps (and button) at the top, the phone steps under a heading. */
    desktop: boolean;
    /** The phone whose steps show under the pills. */
    phone: InstallClip;
    /** The in-app line above the phone steps. */
    inApp: boolean;
    /** The one-tap Install button. */
    button: boolean;
}

export function sheetView(steps: InstallSteps, clip: InstallClip, offer: OfferState): SheetView {
    const desktop = steps.platform === 'desktop';
    const own = steps.platform === clip;
    return {
        desktop,
        phone: clip,
        inApp: own && steps.inApp,
        button: showInstallButton(steps, offer) && steps.platform !== 'ios' && (desktop || own)
    };
}
