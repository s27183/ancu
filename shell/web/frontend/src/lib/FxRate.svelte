<script lang="ts">
    // Bilingual -> Honest-partial -> The web frontend -> the RBA's AUD rate on /facts
    // Purpose:   behavior 123: "1 AUD = 17.970 VND" and "1 AUD = 0,6947 USD" with the RBA's
    //            date and 4pm, linked to the RBA's exchange-rates page; drawn only when the
    //            shell holds a rate (fx.ts returns null otherwise).
    //            Behavior 130: under them, Vietcombank's quote — buys cash, buys by transfer,
    //            sells — with the board's time in Vietnam time and a link to its rate page,
    //            marked as a bank's reference price, not a government figure; no quote, no
    //            bank rows.
    // Rests on:  fx.ts (FxRate, BankQuote), i18n fx.* keys.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import type { FxRate } from '$lib/fx';

    let { rate }: { rate: FxRate } = $props();

    const loc = $derived($lang === 'vi' ? 'vi-VN' : 'en-AU');
    const num = (n: number, d: number) =>
        new Intl.NumberFormat(loc, { minimumFractionDigits: d, maximumFractionDigits: d }).format(n);
    const day = $derived.by(() => {
        const [y, m, d] = rate.date.split('-').map(Number);
        return new Intl.DateTimeFormat(loc, { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' }).format(
            new Date(Date.UTC(y, m - 1, d))
        );
    });
    const bankTime = $derived.by(() => {
        if (!rate.bank) return '';
        return new Intl.DateTimeFormat(loc, {
            hour: '2-digit',
            minute: '2-digit',
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour12: false,
            timeZone: 'Asia/Ho_Chi_Minh'
        }).format(new Date(rate.bank.time));
    });
</script>

<section class="fx" aria-labelledby="fx-title">
    <h3 id="fx-title">{$t('fx.title')}</h3>
    <div class="fx-card">
        <p class="fx-row"><span class="fx-one">1 AUD =</span> <strong>{num(rate.rates.VND, 0)} VND</strong></p>
        <p class="fx-row"><span class="fx-one">1 AUD =</span> <strong>{num(rate.rates.USD, 4)} USD</strong></p>
        <p class="fx-src">
            {$t('fx.asof')} {day}, {$t('fx.time')} ·
            <a href={rate.source} target="_blank" rel="noopener noreferrer">{$t('fx.source')}</a>
        </p>
        {#if rate.bank}
            <div class="fx-bank">
                <p class="fx-bank-head">{$t('fx.bank.title')}</p>
                <dl class="fx-bank-rows">
                    <div><dt>{$t('fx.bank.buycash')}</dt><dd>{num(rate.bank.buy_cash, 0)}</dd></div>
                    <div><dt>{$t('fx.bank.buytransfer')}</dt><dd>{num(rate.bank.buy_transfer, 0)}</dd></div>
                    <div><dt>{$t('fx.bank.sell')}</dt><dd>{num(rate.bank.sell, 0)}</dd></div>
                </dl>
                <p class="fx-src">
                    {$t('fx.bank.note')} {$t('fx.bank.at')} {bankTime} ({$t('fx.bank.tz')}) ·
                    <a href={rate.bank.source} target="_blank" rel="noopener noreferrer">{rate.bank.name}</a>
                </p>
            </div>
        {/if}
    </div>
</section>

<style>
    .fx-bank {
        display: flex;
        flex-direction: column;
        gap: var(--sp-2);
        margin-top: var(--sp-2);
        padding-top: var(--sp-3);
        border-top: 1px solid var(--border);
    }
    .fx-bank-head {
        margin: 0;
        font-size: var(--fs-sm);
        font-weight: 700;
        color: var(--ink);
    }
    .fx-bank-rows {
        margin: 0;
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: var(--sp-2);
    }
    .fx-bank-rows div {
        display: flex;
        flex-direction: column;
        gap: 0.1rem;
        min-width: 0;
    }
    .fx-bank-rows dt {
        font-size: var(--fs-2xs);
        color: var(--muted);
    }
    .fx-bank-rows dd {
        margin: 0;
        font-size: var(--fs-md);
        font-weight: 700;
        color: var(--ink);
        font-variant-numeric: tabular-nums;
    }
    .fx {
        padding-bottom: var(--sp-5);
    }
    .fx h3 {
        margin: var(--sp-3) 0;
        font-size: var(--fs-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--ink);
    }
    .fx-card {
        display: flex;
        flex-direction: column;
        gap: var(--sp-2);
        padding: var(--sp-4);
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        box-shadow: var(--shadow-1);
    }
    .fx-row {
        margin: 0;
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
        gap: var(--sp-2);
        font-variant-numeric: tabular-nums;
    }
    .fx-one {
        font-size: var(--fs-md);
        color: var(--ink-2);
    }
    .fx-row strong {
        font-size: var(--fs-xl, 1.6rem);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--accent);
    }
    .fx-src {
        margin: var(--sp-2) 0 0;
        padding-top: var(--sp-2);
        border-top: 1px solid var(--border);
        font-size: var(--fs-2xs);
        color: var(--muted);
    }
    .fx-src a {
        color: var(--accent);
        font-weight: 600;
        text-decoration: none;
    }
    .fx-src a:hover {
        text-decoration: underline;
    }
    .fx-src a:focus-visible {
        outline: none;
        box-shadow: var(--ring);
    }
</style>
