// Regulated figures are grounded -> P-7 -> The web frontend -> an open page shows the KB the engine now serves (behavior 135)
//
// Son 2026-10-19: "currently, users have to refresh the page manually to see updates".
// A merged KB change reaches readers when the engine redeploys and loads the new
// artifact; the page fetched news, facts and terms once, at load. This watch asks the
// shell's GET /api/version ({"kb": <the loaded artifact's hash>}, fh_engine_kb) once a
// minute while the tab is visible, and at once when a hidden tab is shown again; when
// the hash moves it calls `onChange`, which re-fetches the content in place. A few bytes
// a poll, where re-fetching the content itself is ~190 KB (measured 2026-10-19 on
// maiancu.com). A hidden tab is not polled. The first answer only records the hash: the
// page has just fetched its content. A failed or odd answer changes nothing — the next
// poll tries again (the engine may be mid-deploy).
// No imports, so Node's test runner takes it as is (unit/contentWatch.test.ts).

export const POLL_MS = 60_000;

export interface WatchDeps {
    /** The current hash, or null when it could not be read. */
    fetchVersion: () => Promise<string | null>;
    onChange: () => void;
    doc: Pick<Document, 'visibilityState' | 'addEventListener' | 'removeEventListener'>;
    setInterval: (fn: () => void, ms: number) => unknown;
    clearInterval: (id: unknown) => void;
}

/** Start watching; returns the function that stops it. */
export function watchContent(deps: WatchDeps): () => void {
    let known: string | null = null;
    let busy = false;
    const check = async () => {
        if (busy || deps.doc.visibilityState !== 'visible') return;
        busy = true;
        try {
            const v = await deps.fetchVersion();
            if (v === null) return;
            if (known !== null && v !== known) {
                known = v;
                deps.onChange();
            } else {
                known = v;
            }
        } finally {
            busy = false;
        }
    };
    const onVisibility = () => {
        if (deps.doc.visibilityState === 'visible') void check();
    };
    void check();
    const id = deps.setInterval(() => void check(), POLL_MS);
    deps.doc.addEventListener('visibilitychange', onVisibility);
    return () => {
        deps.clearInterval(id);
        deps.doc.removeEventListener('visibilitychange', onVisibility);
    };
}

/** GET /api/version's `kb`, or null. `no-store`: a cached answer would hide a new KB. */
export async function fetchKbVersion(fetchFn: typeof fetch = fetch): Promise<string | null> {
    try {
        const res = await fetchFn('/api/version', { cache: 'no-store' });
        if (!res.ok) return null;
        const body = (await res.json()) as { kb?: unknown };
        return typeof body.kb === 'string' && body.kb ? body.kb : null;
    } catch {
        return null;
    }
}
