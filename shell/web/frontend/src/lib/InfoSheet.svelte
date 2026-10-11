<script lang="ts">
    // Bilingual -> P-7 · One declaration per outcome shape -> The web frontend -> the menu's popup frame
    // The one popup frame the menu's items open (behavior 64): the free allowance and
    // the privacy policy look and close alike — ✕, Esc, a tap outside — and closing one
    // leaves the menu as it was. Above the menu; centred on wide screens, a bottom sheet
    // on phones; the body scrolls inside the frame. The contents are the caller's.
    // On phones the frame is the one sheet height and motion of the planning sheets
    // (behavior 73 → behavior 66's --sheet-h and lib/sheetMotion.ts): the scrim is its own
    // layer so it fades while the card slides, neither fading the other.
    import type { Snippet } from 'svelte';
    import { t } from '$lib/i18n';
    import { sheetMotion, scrimMotion } from '$lib/sheetMotion';

    let {
        title,
        onclose,
        narrow = false,
        children
    }: { title: string; onclose: () => void; narrow?: boolean; children: Snippet } = $props();

    const titleId = `info-title-${Math.random().toString(36).slice(2, 8)}`;
    let closeBtn: HTMLButtonElement | undefined = $state();
    $effect(() => closeBtn?.focus());
</script>

<svelte:window onkeydown={(e) => e.key === 'Escape' && onclose()} />

<div class="info-backdrop">
    <button
        type="button"
        class="info-scrim"
        tabindex="-1"
        aria-label={$t('sheet.close')}
        onclick={onclose}
        transition:scrimMotion|global
    ></button>
    <div
        transition:sheetMotion|global
        class="info-sheet"
        class:info-sheet-narrow={narrow}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
    >
        <header class="info-head">
            <h2 id={titleId}>{title}</h2>
            <button
                bind:this={closeBtn}
                type="button"
                class="close"
                onclick={onclose}
                aria-label={$t('sheet.close')}>✕</button
            >
        </header>
        <div class="info-body">
            {@render children()}
        </div>
    </div>
</div>
