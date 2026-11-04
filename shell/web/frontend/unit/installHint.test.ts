// Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend -> the
// iPhone's add-to-home-screen hint, proven over every case (behavior 152, Expect 7)
// 6 user agents × standalone on/off × closed flag set/unset × storage (works, throws on read,
// throws on write) = 72 cases, seed 152: the hint shows only for iOS Safari, not standalone,
// flag unset; ✕ sets the flag; a throwing storage hides nothing and throws nothing.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { HINT_KEY, closeInstallHint, isIosSafari, shouldShowInstallHint, type HintStorage } from '../src/lib/installHint.ts';

const SEED = 152;
function mulberry32(a: number) {
    return () => {
        a |= 0;
        a = (a + 0x6d2b79f5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}
const rand = mulberry32(SEED);

// A hostile string: control characters, a script tag, an iPhone mark without Safari's, huge length.
function hostile(): string {
    const parts = ['<script>alert(1)</script>', '\u0000‮', 'iPhone', 'CriOS/1', 'Mozilla/5.0', '"\'`', '\n', 'x'.repeat(4096)];
    let s = '';
    const n = 1 + Math.floor(rand() * 5);
    for (let i = 0; i < n; i++) s += parts[Math.floor(rand() * parts.length)];
    return s;
}

const AGENTS: { name: string; ua: string; touch: number; safari: boolean }[] = [
    {
        name: 'iOS Safari',
        ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1',
        touch: 5,
        safari: true
    },
    {
        name: 'iOS Chrome',
        ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/156.0.8078.80 Mobile/15E148 Safari/604.1',
        touch: 5,
        safari: false
    },
    {
        name: 'iOS Firefox',
        ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/146.0 Mobile/15E148 Safari/605.1.15',
        touch: 5,
        safari: false
    },
    {
        name: 'Android Chrome',
        ua: 'Mozilla/5.0 (Linux; Android 16; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.8078.80 Mobile Safari/537.36',
        touch: 5,
        safari: false
    },
    {
        name: 'desktop Chrome',
        ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.8078.80 Safari/537.36',
        touch: 0,
        safari: false
    },
    { name: 'hostile', ua: hostile(), touch: Math.floor(rand() * 6), safari: false }
];

type Mode = 'works' | 'throws-read' | 'throws-write';
function storage(mode: Mode, flagSet: boolean): HintStorage & { map: Map<string, string> } {
    const map = new Map<string, string>(flagSet ? [[HINT_KEY, '1']] : []);
    return {
        map,
        getItem(k) {
            if (mode === 'throws-read') throw new Error('SecurityError');
            return map.get(k) ?? null;
        },
        setItem(k, v) {
            if (mode === 'throws-write') throw new Error('QuotaExceededError');
            map.set(k, v);
        }
    };
}

test('the hint rule over 72 cases, seed 152', () => {
    let cases = 0;
    const counterexamples: string[] = [];
    for (const a of AGENTS) {
        for (const standalone of [false, true]) {
            for (const flagSet of [false, true]) {
                for (const mode of ['works', 'throws-read', 'throws-write'] as Mode[]) {
                    cases++;
                    // standalone "on" picks one of the two signals at random, as either alone must hide it
                    const viaNavigator = standalone && rand() < 0.5;
                    const viaDisplay = standalone && !viaNavigator;
                    const st = storage(mode, flagSet);
                    const env = { ua: a.ua, maxTouchPoints: a.touch, navigatorStandalone: viaNavigator, displayStandalone: viaDisplay, storage: st };
                    // a storage that throws on read cannot tell a closed hint: it shows (hides nothing)
                    const flagSeen = flagSet && mode !== 'throws-read';
                    const want = a.safari && !standalone && !flagSeen;
                    let got: boolean;
                    try {
                        got = shouldShowInstallHint(env);
                    } catch (e) {
                        counterexamples.push(`${a.name}/${standalone}/${flagSet}/${mode}: threw ${e}`);
                        continue;
                    }
                    if (got !== want) counterexamples.push(`${a.name}/${standalone}/${flagSet}/${mode}: got ${got}, want ${want}`);
                    // ✕ never throws; where storage writes, it sets the flag and the hint stays gone
                    try {
                        closeInstallHint(st);
                    } catch (e) {
                        counterexamples.push(`${a.name}/${mode}: close threw ${e}`);
                        continue;
                    }
                    if (mode === 'works') {
                        if (st.map.get(HINT_KEY) !== '1') counterexamples.push(`${a.name}: ✕ did not set the flag`);
                        if (shouldShowInstallHint(env)) counterexamples.push(`${a.name}: shown again after ✕`);
                    }
                }
            }
        }
    }
    assert.equal(cases, 72);
    assert.deepEqual(counterexamples, []);
});

test('iPadOS reports a Mac: Safari there with touch is iOS Safari, without touch is not', () => {
    const mac = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15';
    assert.equal(isIosSafari(mac, 5), true);
    assert.equal(isIosSafari(mac, 0), false);
});

test('a null storage (localStorage itself refused) shows the hint and ✕ does not throw', () => {
    const ua = AGENTS[0].ua;
    assert.equal(shouldShowInstallHint({ ua, maxTouchPoints: 5, navigatorStandalone: false, displayStandalone: false, storage: null }), true);
    assert.doesNotThrow(() => closeInstallHint(null));
});
