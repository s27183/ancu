<script lang="ts">
    // A reusable popup modal/sheet — the drill-down surface for the plan card (the Flow
    // phase sheet and the Budget cash-event detail both open INTO this, rather than rendering
    // inline). Mirrors the app's onboarding modal design language (app.css .ob-backdrop /
    // .onboarding): a scrim backdrop + a SOLID card, a bottom-sheet on phone and a centred
    // card on desktop (mobile-native §7.1). Close via the ✕, the scrim, or Escape.
    //
    // The backdrop is a real <button> (an accessible close control — no role/keyboard hacks
    // on a non-interactive div). The card is role=dialog/aria-modal. It is position:fixed; a
    // transformed ancestor (the desktop .sheet) becomes its containing block, so the modal
    // overlays the plan card — the intended "popup over the plan" surface.
    import type { Snippet } from 'svelte';
    import { t } from '$lib/i18n';

    let { title = '', onClose, children }: {
        title?: string;
        onClose: () => void;
        children: Snippet;
    } = $props();

    function onKey(e: KeyboardEvent) {
        if (e.key === 'Escape') onClose();
    }
</script>

<svelte:window onkeydown={onKey} />

<div class="mo-root">
    <button type="button" class="mo-backdrop" aria-label={$t('sheet.close')} onclick={onClose}></button>
    <div class="mo-card" role="dialog" aria-modal="true" aria-label={title}>
        <header class="mo-head">
            <h3 class="mo-title">{title}</h3>
            <button type="button" class="mo-close" aria-label={$t('sheet.close')} onclick={onClose}>✕</button>
        </header>
        <div class="mo-body">
            {@render children()}
        </div>
    </div>
</div>

<style>
    .mo-root {
        position: fixed;
        inset: 0;
        z-index: 70;
        display: flex;
        align-items: flex-end;
        justify-content: center;
    }
    .mo-backdrop {
        position: absolute;
        inset: 0;
        border: none;
        padding: 0;
        margin: 0;
        background: var(--scrim);
        backdrop-filter: blur(2px);
        -webkit-backdrop-filter: blur(2px);
        cursor: default;
    }
    .mo-card {
        /* SOLID, not glass — the backdrop-filter + transform compositing trap noted in
           app.css; and content reads better on a solid surface. */
        position: relative;
        background: var(--surface);
        width: 100%;
        max-height: 88%;
        display: flex;
        flex-direction: column;
        border-radius: var(--radius-lg) var(--radius-lg) 0 0;
        box-shadow: var(--shadow-2);
        animation: mo-rise var(--t-med, 0.22s) var(--ease, ease);
    }
    @keyframes mo-rise {
        from {
            opacity: 0;
            transform: translateY(1rem);
        }
    }
    .mo-head {
        display: flex;
        align-items: flex-start;
        gap: 0.5rem;
        padding: 0.9rem 1rem 0.5rem;
        border-bottom: 1px solid var(--border);
    }
    .mo-title {
        margin: 0;
        font-size: 1.05rem;
        font-weight: 700;
        color: var(--ink);
    }
    .mo-close {
        margin-left: auto;
        border: none;
        background: transparent;
        font-size: 1.1rem;
        color: var(--muted);
        cursor: pointer;
        padding: 0.2rem 0.4rem;
        line-height: 1;
    }
    .mo-body {
        padding: 0.75rem 1rem 1rem;
        overflow-y: auto;
    }

    /* Desktop: a centred card (not a bottom sheet), matching .sheet's modal form. */
    @media (min-width: 48rem) {
        .mo-root {
            align-items: center;
        }
        .mo-card {
            width: min(92%, 34rem);
            max-height: 85%;
            border-radius: var(--radius-lg);
            border: 1px solid var(--glass-border);
            animation: mo-fade var(--t-med, 0.22s) var(--ease, ease);
        }
    }
    @keyframes mo-fade {
        from {
            opacity: 0;
            transform: translateY(0.5rem);
        }
    }
</style>
