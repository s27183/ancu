// Regulated figures are grounded -> P-7 -> The web frontend -> the content watch's rules, proven on fakes
// Behavior 135, step 2: the first answer only records the hash; a moved hash calls
// onChange once; a failed read changes nothing; a hidden tab is not polled; showing the
// tab checks at once; stopping removes the timer and the listener.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { watchContent, fetchKbVersion, POLL_MS } from '../src/lib/contentWatch.ts';

function rig(answers: (string | null)[]) {
    const listeners = new Map<string, () => void>();
    const doc = {
        visibilityState: 'visible' as DocumentVisibilityState,
        addEventListener: (k: string, f: () => void) => listeners.set(k, f),
        removeEventListener: (k: string) => listeners.delete(k)
    };
    let tick: (() => void) | null = null;
    let ms = 0;
    let cleared = false;
    let calls = 0;
    let changes = 0;
    const stop = watchContent({
        fetchVersion: async () => {
            calls++;
            return answers.length ? answers.shift()! : null;
        },
        onChange: () => changes++,
        doc: doc as never,
        setInterval: (f, m) => ((tick = f), (ms = m), 7),
        clearInterval: () => (cleared = true)
    });
    const flush = () => new Promise((r) => setTimeout(r, 0));
    return {
        doc, listeners, stop, flush,
        tick: async () => (tick!(), await flush()),
        get calls() { return calls; },
        get changes() { return changes; },
        get ms() { return ms; },
        get cleared() { return cleared; }
    };
}

test('the first answer records, a moved hash calls onChange once', async () => {
    const r = rig(['a', 'a', 'b', 'b']);
    await r.flush();
    assert.equal(r.changes, 0);
    assert.equal(r.ms, POLL_MS);
    await r.tick();
    assert.equal(r.changes, 0);
    await r.tick();
    assert.equal(r.changes, 1);
    await r.tick();
    assert.equal(r.changes, 1);
});

test('a failed read changes nothing', async () => {
    const r = rig(['a', null, 'a']);
    await r.flush();
    await r.tick();
    await r.tick();
    assert.equal(r.changes, 0);
});

test('a hidden tab is not polled; showing it checks at once', async () => {
    const r = rig(['a', 'b']);
    await r.flush();
    r.doc.visibilityState = 'hidden';
    await r.tick();
    assert.equal(r.calls, 1);
    r.doc.visibilityState = 'visible';
    r.listeners.get('visibilitychange')!();
    await r.flush();
    assert.equal(r.calls, 2);
    assert.equal(r.changes, 1);
});

test('stop removes the timer and the listener', async () => {
    const r = rig(['a']);
    await r.flush();
    r.stop();
    assert.ok(r.cleared);
    assert.equal(r.listeners.size, 0);
});

test('fetchKbVersion reads kb, asks no-store, and yields null on failure', async () => {
    let init: RequestInit | undefined;
    const ok = (async (_u: string, i?: RequestInit) => ((init = i), new Response('{"kb":"abc"}'))) as typeof fetch;
    assert.equal(await fetchKbVersion(ok), 'abc');
    assert.equal(init?.cache, 'no-store');
    const bad = (async () => new Response('x', { status: 503 })) as typeof fetch;
    assert.equal(await fetchKbVersion(bad), null);
    const odd = (async () => new Response('{"kb":5}')) as typeof fetch;
    assert.equal(await fetchKbVersion(odd), null);
    const thrown = (async () => { throw new Error('down'); }) as typeof fetch;
    assert.equal(await fetchKbVersion(thrown), null);
});
