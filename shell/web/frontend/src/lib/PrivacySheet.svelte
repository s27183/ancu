<script lang="ts">
    // The privacy policy sheet (behavior 62), opened from the menu. The text lives in
    // privacyPolicy.ts, one record per language; this only lays it out. Closes on ✕,
    // the backdrop and Esc; the body scrolls inside the sheet.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { PRIVACY } from '$lib/privacyPolicy';

    let { onclose }: { onclose: () => void } = $props();

    const policy = $derived(PRIVACY[$lang === 'en' ? 'en' : 'vi']);
    let closeBtn: HTMLButtonElement | undefined = $state();
    $effect(() => closeBtn?.focus());
</script>

<svelte:window onkeydown={(e) => e.key === 'Escape' && onclose()} />

<!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
<div class="privacy-backdrop" onclick={(e) => e.target === e.currentTarget && onclose()}>
    <div class="privacy-sheet" role="dialog" aria-modal="true" aria-labelledby="privacy-title">
        <header class="privacy-head">
            <h2 id="privacy-title">{policy.title}</h2>
            <button
                bind:this={closeBtn}
                type="button"
                class="close"
                onclick={onclose}
                aria-label={$t('sheet.close')}>✕</button
            >
        </header>
        <div class="privacy-body">
            <p class="privacy-effective">{policy.effective}</p>
            <p>{policy.intro}</p>
            {#each policy.sections as s (s.h)}
                <section>
                    <h3>{s.h}</h3>
                    {#if s.items}
                        <ul>
                            {#each s.items as item (item)}<li>{item}</li>{/each}
                        </ul>
                    {/if}
                    {#each s.p ?? [] as para (para)}<p>{para}</p>{/each}
                </section>
            {/each}
        </div>
    </div>
</div>
