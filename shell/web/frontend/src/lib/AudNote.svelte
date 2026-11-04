<script lang="ts">
    // Regulated figures are grounded -> the RBA's AUD rate -> the web frontend -> the AUD line
    // before the listing-site links (behavior 153; the rule and its block: fxLine.ts). Drawn
    // in the listing sheet (ListingSheet.svelte) and above /market's listing sites: the AUD
    // sentence always, the RBA's rate with its date only when getFx has one.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { getFx, type FxRate } from '$lib/fx';
    import { audRate } from '$lib/fxLine';

    let fx = $state<FxRate | null>(null);
    onMount(() => {
        getFx().then((r) => (fx = r));
    });
    const rate = $derived(audRate(fx, $lang === 'vi' ? 'vi' : 'en'));
</script>

<p class="aud-note">
    <span>{$t('listing.aud')}</span>
    {#if rate}<span class="aud-rate">{rate}</span>{/if}
</p>

<style>
    .aud-note {
        display: flex;
        flex-direction: column;
        gap: 2px;
        margin: 0;
        padding: var(--sp-2) var(--sp-3);
        border-radius: var(--radius);
        background: var(--accent-soft);
        color: var(--ink);
        font-size: var(--fs-sm);
        font-weight: 600;
    }
    .aud-rate {
        font-weight: 500;
        color: var(--ink-2);
        font-variant-numeric: tabular-nums;
    }
</style>
