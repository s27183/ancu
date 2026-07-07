<script lang="ts">
    // The KB-news ticker strip (kb-news-feature.md, task 29): a sticky, auto-sliding
    // headline strip cycling through the card's relevant, non-dismissed news notes —
    // chrome, not a competing primary surface (map-first-home / plan-card-as-central-
    // artifact constraints). One headline visible at a time; swipe or the arrow
    // buttons advance/reverse; tapping a headline hands the note to the caller (task
    // 28: detail sheet + tile highlight — not built here). Bilingual pick (task 30)
    // folds in here since a ticker with no text isn't a testable component — reuses
    // the SAME $lang === 'vi' inline pattern already used elsewhere (Onboarding.svelte,
    // SuburbSheet.svelte), not a new mechanism.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import type { NewsNote } from '$lib/api';

    let { news, onSelect }: { news: NewsNote[]; onSelect?: (note: NewsNote) => void } = $props();

    // idx is an unbounded advance counter (prev/next/timer just increment/decrement
    // it); safeIdx wraps it into range at READ time, so a shrinking list (a dismiss —
    // task 31 — removing the current headline) never needs a corrective effect of its
    // own — it's a pure derivation, not a clamp mutating state as a side effect.
    let idx = $state(0);
    const safeIdx = $derived(
        news.length > 0 ? ((idx % news.length) + news.length) % news.length : 0
    );

    // Auto-advance while there's more than one note to cycle through; any manual nav
    // (arrow or swipe) resets the timer via this same effect re-running on idx change.
    $effect(() => {
        idx; // re-arm the timer on every manual/auto advance
        if (news.length <= 1) return;
        const id = setInterval(() => {
            idx += 1;
        }, 6000);
        return () => clearInterval(id);
    });

    function prev() {
        idx -= 1;
    }
    function next() {
        idx += 1;
    }

    // Bilingual pick (task 30): active locale first, the other summary as an
    // honest-partial fallback rather than a blank headline if only one was authored.
    const headline = $derived.by((): string => {
        const note = news[safeIdx];
        if (!note) return '';
        return ($lang === 'vi' ? note.summary_vi : note.summary_en)
            ?? note.summary_en ?? note.summary_vi ?? '';
    });

    // Swipe nav: a real swipe (>=40px) advances/reverses and suppresses the browser's
    // synthetic click that would otherwise follow touchend; a short touch (a tap) is
    // left alone so the click fires onSelect normally.
    let touchStartX = 0;
    function onTouchStart(e: TouchEvent) {
        touchStartX = e.touches[0]?.clientX ?? 0;
    }
    function onTouchEnd(e: TouchEvent) {
        const dx = (e.changedTouches[0]?.clientX ?? touchStartX) - touchStartX;
        if (Math.abs(dx) < 40) return;
        e.preventDefault();
        if (dx < 0) next();
        else prev();
    }
</script>

{#if news.length > 0}
    <div class="pp-ticker" role="region" aria-label={$t('plan.news.aria')}>
        {#if news.length > 1}
            <button
                type="button"
                class="pp-ticker-nav"
                onclick={prev}
                aria-label={$t('plan.news.prev')}>‹</button
            >
        {/if}
        <button
            type="button"
            class="pp-ticker-headline"
            ontouchstart={onTouchStart}
            ontouchend={onTouchEnd}
            onclick={() => news[safeIdx] && onSelect?.(news[safeIdx])}
        >
            {headline}
        </button>
        {#if news.length > 1}
            <button
                type="button"
                class="pp-ticker-nav"
                onclick={next}
                aria-label={$t('plan.news.next')}>›</button
            >
        {/if}
    </div>
{/if}
