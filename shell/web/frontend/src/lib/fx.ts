// Bilingual -> Honest-partial -> The web frontend -> the RBA's AUD rate on /facts
// Purpose:   reads GET /api/fx (behavior 123): the Reserve Bank's latest 1 AUD in VND and
//            USD with the RBA's date, kept by the shell (fh_shell_h_fx.erl).
// Holds:     no stored rate, or any failure, is `null` and the page draws no rate section —
//            never a made-up or cached-in-browser figure.
// Rests on:  the shell's /api/fx shape {date, rates: {VND, USD}, source}.

export interface FxRate {
    date: string; // YYYY-MM-DD, the RBA's
    rates: { VND: number; USD: number };
    source: string;
}

export async function getFx(fetchFn: typeof fetch = fetch): Promise<FxRate | null> {
    try {
        const res = await fetchFn('/api/fx');
        if (!res.ok) return null;
        const body = (await res.json()) as Partial<FxRate>;
        const r = body.rates;
        if (!body.date || !r || !(r.VND > 0) || !(r.USD > 0)) return null;
        return body as FxRate;
    } catch {
        return null;
    }
}
