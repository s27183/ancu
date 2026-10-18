<script lang="ts">
    // Bilingual -> Honest-partial -> The web frontend -> the RBA's AUD rate on /facts
    // Purpose:   behavior 123: "1 AUD = 17.970 VND" and "1 AUD = 0,6947 USD" with the RBA's
    //            date and 4pm, linked to the RBA's exchange-rates page; drawn only when the
    //            shell holds a rate (fx.ts returns null otherwise).
    // Rests on:  fx.ts (FxRate), i18n fx.* keys.
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
    </div>
</section>

<style>
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
