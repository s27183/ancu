// Bilingual -> Honest-partial -> The web frontend -> the RBA's AUD rate on /facts
// Purpose:   reads GET /api/fx (behavior 123): the Reserve Bank's latest 1 AUD in VND and
//            USD with the RBA's date, kept by the shell (fh_shell_h_fx.erl).
// Holds:     no stored rate, or any failure, is `null` and the page draws no rate section —
//            never a made-up or cached-in-browser figure.
//            Behavior 130: `bank` is Vietcombank's AUD quote (buys cash, buys by transfer,
//            sells, in VND) with the board's time — a bank's reference price, kept by the
//            shell (fh_shell_vcb.erl); a missing or malformed one is `null`, and the RBA
//            rate is shown alone.
// Rests on:  the shell's /api/fx shape {date, rates: {VND, USD}, source, bank}.

export interface BankQuote {
    name: string;
    time: string; // ISO with +07:00, the board's
    buy_cash: number;
    buy_transfer: number;
    sell: number;
    source: string;
}

export interface FxRate {
    date: string; // YYYY-MM-DD, the RBA's
    rates: { VND: number; USD: number };
    source: string;
    bank: BankQuote | null;
}

function bankQuote(b: Partial<BankQuote> | null | undefined): BankQuote | null {
    if (!b || !b.name || !b.time || !b.source || Number.isNaN(Date.parse(b.time))) return null;
    if (!((b.buy_cash ?? 0) > 0 && (b.buy_transfer ?? 0) > 0 && (b.sell ?? 0) > 0)) return null;
    return b as BankQuote;
}

export async function getFx(fetchFn: typeof fetch = fetch): Promise<FxRate | null> {
    try {
        const res = await fetchFn('/api/fx');
        if (!res.ok) return null;
        const body = (await res.json()) as Partial<FxRate>;
        const r = body.rates;
        if (!body.date || !r || !(r.VND > 0) || !(r.USD > 0)) return null;
        return { ...(body as FxRate), bank: bankQuote(body.bank) };
    } catch {
        return null;
    }
}
