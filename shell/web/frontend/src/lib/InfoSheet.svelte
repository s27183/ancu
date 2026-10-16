<script lang="ts">
    // Bilingual -> P-7 · One declaration per outcome shape -> The web frontend -> the menu's popup frame
    // The one popup frame the menu's items open (behavior 64): the free allowance and
    // the privacy policy look and close alike — ✕, Esc, a tap outside — and closing one
    // leaves the menu as it was. Above the menu; centred on wide screens, a bottom sheet
    // on phones; the body scrolls inside the frame. The contents are the caller's.
    // On phones the frame is the one sheet height and motion of the planning sheets
    // (behavior 73 → behavior 66's --sheet-h and lib/sheetMotion.ts): the scrim is its own
    // layer so it fades while the card slides, neither fading the other. A `fit` frame
    // (the term card, behavior 102) is the exception: on phones it hugs its content up to
    // that height, so the line the reader tapped stays in view above it.
    import type { Snippet } from 'svelte';
    import { t } from '$lib/i18n';
    import { sheetMotion, scrimMotion } from '$lib/sheetMotion';

    let {
        title,
        onclose,
        narrow = false,
        fit = false,
        children
    }: {
        title: string;
        onclose: () => void;
        narrow?: boolean;
        /** on phones, as tall as its content (up to the sheet height) — the term card */
        fit?: boolean;
        children: Snippet;
    } = $props();

    const titleId = `info-title-${Math.random().toString(36).slice(2, 8)}`;
    let closeBtn: HTMLButtonElement | undefined = $state();
    $effect(() => closeBtn?.focus());
</script>

<!-- Esc closes this frame only: taken at the window's capture phase and stopped there, so a
     popup under it (the news detail Modal under a term card, behavior 102; the menu,
     behavior 64) does not close with it. Measured 2026-10-17: with a bubble listener, one
     Esc on a term card over a news item closed both. -->
<svelte:window
    onkeydowncapture={(e) => {
        if (e.key !== 'Escape') return;
        e.stopPropagation();
        onclose();
    }}
/>

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
        class:info-sheet-fit={fit}
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
