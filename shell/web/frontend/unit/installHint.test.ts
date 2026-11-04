// Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend -> the
// «Use as an app» pill's rule (behavior 153, was 152): every browser gets the pill except
// the installed app; each device its own steps; an in-app browser is told to open the page
// in a browser first. Run over every agent × standalone signal, and seeded hostile agents.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ANDROID_VIDEO, INSTALL_VIDEOS, IOS_VIDEO, installClip, installSteps, installVideo, showInstallButton, type InstallPlatform, type OfferState } from '../src/lib/installHint.ts';

const SEED = 153;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const IOS = 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)';
const AGENTS: { name: string; ua: string; touch: number; platform: InstallPlatform; inApp: boolean }[] = [
    { name: 'iOS Safari', ua: `${IOS} Version/26.2 Mobile/15E148 Safari/604.1`, touch: 5, platform: 'ios', inApp: false },
    { name: 'iOS Chrome', ua: `${IOS} CriOS/156.0.8078.80 Mobile/15E148 Safari/604.1`, touch: 5, platform: 'ios', inApp: false },
    { name: 'iOS Zalo', ua: `${IOS} Mobile/15E148 Zalo iOS/583 ZaloTheme/light ZaloLanguage/vn`, touch: 5, platform: 'ios', inApp: true },
    { name: 'iOS Facebook', ua: `${IOS} Mobile/15E148 [FBAN/FBIOS;FBAV/530.0.0.40.98;FBBV/1]`, touch: 5, platform: 'ios', inApp: true },
    { name: 'iPadOS Safari (Mac UA, touch)', ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15', touch: 5, platform: 'ios', inApp: false },
    { name: 'macOS Safari (no touch)', ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15', touch: 0, platform: 'desktop', inApp: false },
    { name: 'Android Chrome', ua: 'Mozilla/5.0 (Linux; Android 16; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.8078.80 Mobile Safari/537.36', touch: 5, platform: 'android', inApp: false },
    { name: 'Android Zalo', ua: 'Mozilla/5.0 (Linux; Android 16; SM-S931B) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/156.0 Mobile Safari/537.36 Zalo android/12345', touch: 5, platform: 'android', inApp: true },
    { name: 'desktop Chrome', ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.8078.80 Safari/537.36', touch: 0, platform: 'desktop', inApp: false }
];

test('every agent × standalone signal: the pill hides only in the installed app, with its own steps', () => {
    for (const a of AGENTS)
        for (const ns of [false, true])
            for (const ds of [false, true]) {
                const got = installSteps({ ua: a.ua, maxTouchPoints: a.touch, navigatorStandalone: ns, displayStandalone: ds });
                if (ns || ds) assert.equal(got, null, `${a.name} standalone`);
                else assert.deepEqual(got, { platform: a.platform, inApp: a.inApp }, a.name);
            }
});

test('300 hostile agents, seed 153: never throws, always a known platform, null only when standalone', () => {
    const rand = mulberry32(SEED);
    const parts = ['<script>alert(1)</script>', '\u0000‮', 'iPhone', 'Android', 'Zalo', 'FBAN', 'Macintosh', 'CriOS/1', '"\'`', '\n', 'x'.repeat(4096)];
    const bad: string[] = [];
    for (let i = 0; i < 300; i++) {
        let ua = '';
        for (let k = 0, n = Math.floor(rand() * 5); k <= n; k++) ua += parts[Math.floor(rand() * parts.length)];
        const odd = [ua, undefined, null, 42][Math.floor(rand() * 4)] as unknown as string;
        const touch = [0, 5, NaN, -1, Infinity][Math.floor(rand() * 5)];
        const standalone = rand() < 0.2;
        try {
            const got = installSteps({ ua: odd, maxTouchPoints: touch, navigatorStandalone: standalone, displayStandalone: false });
            if (standalone ? got !== null : !got || !['ios', 'android', 'desktop'].includes(got.platform)) bad.push(`${i}: ${JSON.stringify(got)}`);
            if (got?.inApp && got.platform === 'desktop') bad.push(`${i}: in-app on desktop`);
        } catch (e) {
            bad.push(`${i}: threw ${e}`);
        }
    }
    assert.deepEqual(bad, []);
});

// Behavior 157: the one-tap Install button shows exactly when the browser's offer is held,
// the page is not the installed app and not an in-app browser; every other case keeps the
// steps as they were.
const OFFERS: OfferState[] = ['held', 'used', 'none'];

test('every agent × standalone signal × offer state: the button only with a held offer, outside the app and in-app browsers', () => {
    for (const a of AGENTS)
        for (const ns of [false, true])
            for (const ds of [false, true])
                for (const o of OFFERS) {
                    const steps = installSteps({ ua: a.ua, maxTouchPoints: a.touch, navigatorStandalone: ns, displayStandalone: ds });
                    const want = o === 'held' && !ns && !ds && !a.inApp;
                    assert.equal(showInstallButton(steps, o), want, `${a.name} ns=${ns} ds=${ds} ${o}`);
                    if (!ns && !ds) assert.deepEqual(steps, { platform: a.platform, inApp: a.inApp }, `${a.name} steps unchanged`);
                }
});

test('2,000 hostile cases, seed 157: the button exactly when held, not standalone, not in-app; never throws', () => {
    const rand = mulberry32(157);
    const parts = ['<script>alert(1)</script>', '\u0000‮', 'iPhone', 'Android', 'Zalo', 'FBAN', 'Instagram', 'Macintosh', 'CriOS/1', 'Chrome/156', '"\'`', '\n', 'x'.repeat(4096)];
    const bad: string[] = [];
    for (let i = 0; i < 2000; i++) {
        let ua = '';
        for (let k = 0, n = Math.floor(rand() * 5); k <= n; k++) ua += parts[Math.floor(rand() * parts.length)];
        const odd = [ua, ua, undefined, null, 42][Math.floor(rand() * 5)] as unknown as string;
        const touch = [0, 5, NaN, -1, Infinity][Math.floor(rand() * 5)];
        const ns = rand() < 0.2;
        const ds = rand() < 0.2;
        const o = [...OFFERS, 'bogus' as OfferState][Math.floor(rand() * 4)];
        try {
            const steps = installSteps({ ua: odd, maxTouchPoints: touch, navigatorStandalone: ns, displayStandalone: ds });
            const want = o === 'held' && !ns && !ds && steps !== null && !steps.inApp;
            if (showInstallButton(steps, o) !== want) bad.push(`${i}: ${o} ns=${ns} ds=${ds} ${JSON.stringify(steps)}`);
            if ((ns || ds) && showInstallButton(steps, o)) bad.push(`${i}: button in the installed app`);
            if (steps?.inApp && showInstallButton(steps, o)) bad.push(`${i}: button in an in-app browser`);
        } catch (e) {
            bad.push(`${i}: threw ${e}`);
        }
    }
    assert.deepEqual(bad, []);
});

// Behavior 158: the sheet opens on the visitor's own phone's clip: Android on android, the
// iPhone clip on an iPhone, an iPad or a computer; none in the installed app.
const WANT_VIDEO = { ios: IOS_VIDEO, android: ANDROID_VIDEO, desktop: IOS_VIDEO };

test('every agent × standalone signal: the Android clip on android, the iPhone clip otherwise, none in the app', () => {
    for (const a of AGENTS)
        for (const ns of [false, true])
            for (const ds of [false, true]) {
                const got = installVideo(installSteps({ ua: a.ua, maxTouchPoints: a.touch, navigatorStandalone: ns, displayStandalone: ds }));
                assert.equal(got, ns || ds ? null : WANT_VIDEO[a.platform], `${a.name} ns=${ns} ds=${ds}`);
            }
    assert.equal(installVideo(null), null);
    assert.deepEqual(INSTALL_VIDEOS, { ios: IOS_VIDEO, android: ANDROID_VIDEO });
});

test('2,000 hostile cases, seed 158: the clip follows the platform exactly; never throws', () => {
    const rand = mulberry32(158);
    const parts = ['<script>alert(1)</script>', '\u0000\u202e', 'iPhone', 'iPad', 'Android', 'Zalo', 'FBAN', 'Instagram', 'Macintosh', 'Windows', 'CriOS/1', 'Chrome/156', '"\'`', '\n', 'x'.repeat(4096)];
    const bad: string[] = [];
    for (let i = 0; i < 2000; i++) {
        let ua = '';
        for (let k = 0, n = Math.floor(rand() * 5); k <= n; k++) ua += parts[Math.floor(rand() * parts.length)];
        const odd = [ua, ua, undefined, null, 42][Math.floor(rand() * 5)] as unknown as string;
        const touch = [0, 5, NaN, -1, Infinity][Math.floor(rand() * 5)];
        const ns = rand() < 0.2;
        const ds = rand() < 0.2;
        try {
            const steps = installSteps({ ua: odd, maxTouchPoints: touch, navigatorStandalone: ns, displayStandalone: ds });
            const got = installVideo(steps);
            const want = steps === null ? null : WANT_VIDEO[steps.platform];
            if (got !== want) bad.push(`${i}: ${JSON.stringify(steps)} -> ${got?.src}`);
            if ((ns || ds) && got) bad.push(`${i}: clip in the installed app`);
            if (steps && (got === ANDROID_VIDEO) !== (steps.platform === 'android')) bad.push(`${i}: Android clip off android`);
            if (installClip(steps) !== (steps ? (steps.platform === 'android' ? 'android' : 'ios') : null)) bad.push(`${i}: clip key`);
        } catch (e) {
            bad.push(`${i}: threw ${e}`);
        }
    }
    assert.deepEqual(bad, []);
});
