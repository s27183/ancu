<script lang="ts">
    // The KB-news ticker (kb-news-feature.md, task 29; extended 2026-07-09 with a
    // `variant` prop). Two distinct interaction models sharing one component because
    // they share the same data shape + tap-to-open contract:
    //   - `discrete` (default, per-card — task 29/31, UNCHANGED behavior): one
    //     headline visible at a time in a narrow sidebar strip, swaps every 6s,
    //     swipe/arrow nav. Built for the plan-projection sticky rail.
    //   - `marquee` (homepage — kb-news-feature.md "Homepage ticker" CNBC/Bloomberg
    //     extension): every headline concatenated into one continuously-scrolling
    //     single-line strip, full-width chrome, no per-item nav (there's nothing to
    //     page through — everything is already visible, just moving).
    // Bilingual pick (task 30) + headline/summary text source is shared by both:
    // prefers the short ticker `headline_en/vi` field (GATE 11, <=100 chars) over the
    // full `summary_en/vi` paragraph, which stays reserved for the detail sheet.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import type { NewsNote } from '$lib/api';

    let {
        news,
        onSelect,
        variant = 'discrete',
        ariaLabel
    }: {
        news: NewsNote[];
        onSelect?: (note: NewsNote) => void;
        variant?: 'discrete' | 'marquee';
        ariaLabel?: string;
    } = $props();

    // Falls back to the full summary only for a note authored before the headline
    // field existed (defensive honest-partial — GATE 11 requires headline going
    // forward, so this path is a safety net, not the normal case).
    function headlineFor(note: NewsNote): string {
        const primary = $lang === 'vi' ? note.headline_vi : note.headline_en;
        const fallback = $lang === 'vi' ? note.headline_en : note.headline_vi;
        return primary ?? fallback ?? note.summary_en ?? note.summary_vi ?? '';
    }

    const regionLabel = $derived(ariaLabel ?? $t('plan.news.aria'));

    // ---- discrete mode: per-card sticky strip (task 29/31 — interaction UNTOUCHED) ----

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
        if (variant !== 'discrete' || news.length <= 1) return;
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

    const discreteHeadline = $derived.by((): string => {
        const note = news[safeIdx];
        return note ? headlineFor(note) : '';
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

    // ---- marquee mode: homepage full-width continuous scroll ----

    // Explicit pause/play (WCAG 2.2.2 — motion lasting >5s needs a stop control that
    // isn't hover-only, since hover doesn't help touch/keyboard users). Left unset
    // (not forced to 'running') when not paused so the CSS :hover/:focus-within rule
    // can still pause it for mouse users without fighting an inline style.
    let paused = $state(false);
    function togglePaused() {
        paused = !paused;
    }

    // Reading-speed heuristic, not a measured layout value: ~6 chars/sec, clamped so
    // a one-note list doesn't whip past and a long list doesn't crawl for a minute.
    const marqueeDurationS = $derived(
        Math.min(60, Math.max(15, news.reduce((acc, n) => acc + headlineFor(n).length, 0) / 6))
    );
</script>

{#if news.length > 0 && variant === 'marquee'}
    <div class="pp-ticker pp-ticker-marquee" role="region" aria-label={regionLabel}>
        <button
            type="button"
            class="pp-ticker-pause"
            onclick={togglePaused}
            aria-label={paused ? $t('plan.news.play') : $t('plan.news.pause')}
            >{paused ? '▶' : '❚❚'}</button
        >
        <div class="pp-ticker-marquee-viewport">
            <!-- Decorative: the moving copy is aria-hidden; the sr-only list below is
                 the real, non-moving, keyboard/AT-reachable equivalent. -->
            <div
                class="pp-ticker-marquee-track"
                aria-hidden="true"
                style:animation-duration="{marqueeDurationS}s"
                style:animation-play-state={paused ? 'paused' : undefined}
            >
                {#each [0, 1] as run (run)}
                    <span class="pp-ticker-marquee-run">
                        {#each news as note (note.news_slug + '-' + run)}
                            <button
                                type="button"
                                tabindex="-1"
                                class="pp-ticker-marquee-item"
                                onclick={() => onSelect?.(note)}>{headlineFor(note)}</button
                            >
                            <span class="pp-ticker-sep">•</span>
                        {/each}
                    </span>
                {/each}
            </div>
        </div>
        <ul class="sr-only">
            {#each news as note (note.news_slug)}
                <li><button type="button" onclick={() => onSelect?.(note)}>{headlineFor(note)}</button></li>
            {/each}
        </ul>
    </div>
{:else if news.length > 0}
    <div class="pp-ticker" role="region" aria-label={regionLabel}>
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
            {discreteHeadline}
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
