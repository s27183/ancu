// The display-language store. The engine emits bilingual {vi, en} content; the
// SHELL picks which to show (bilingual-content.md, the 2c residual). vi is the
// default (VI-first product). Persisted to localStorage and reflected on <html lang>
// so it survives reloads and the FOUC guard in app.html can pre-apply it.
import { writable } from 'svelte/store';
import { browser } from '$app/environment';

export type Lang = 'vi' | 'en';

const KEY = 'ancu-lang';

function initial(): Lang {
    if (!browser) return 'vi';
    const stored = localStorage.getItem(KEY);
    return stored === 'en' ? 'en' : 'vi';
}

export const lang = writable<Lang>(initial());

if (browser) {
    lang.subscribe((value) => {
        try {
            localStorage.setItem(KEY, value);
            document.documentElement.setAttribute('lang', value);
        } catch (e) {
            // private mode / storage disabled — display still works, just not persisted
        }
    });
}
