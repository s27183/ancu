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

    // Behavior 43: the strip moves under the finger. A requestAnimationFrame loop owns
    // the track's translateX (a CSS animation cannot be dragged), so:
    //   - a drag moves it 1:1 with the pointer, wrapping over the two duplicated runs;
    //   - a press that travels < TAP_PX is a tap: it opens the note it started on;
    //   - while a pointer is down, a mouse hovers, or focus is inside, the strip stands
    //     still; on release it carries on.
    // WCAG 2.2.2 (Pause, Stop, Hide) without a visible pause button (Son, behavior 43):
    // press-and-hold stops it, hover/focus stop it, prefers-reduced-motion keeps it
    // still (drag still scrolls it), and the sr-only list below is a non-moving
    // equivalent for keyboard and screen-reader users.
    const TAP_PX = 8;

    // Reading-speed heuristic, not a measured layout value: ~6 chars/sec over one run,
    // clamped so a one-note list doesn't whip past and a long list doesn't crawl.
    const marqueeDurationS = $derived(
        Math.min(60, Math.max(15, news.reduce((acc, n) => acc + headlineFor(n).length, 0) / 6))
    );

    let runEl: HTMLElement | undefined = $state();
    let runWidth = $state(0);
    let offset = $state(0); // px, <= 0; wrapped into (-runWidth, 0]
    let held = false;
    let hovering = false;
    let focused = false;
    let reduced = false;

    function wrap(x: number): number {
        if (runWidth <= 0) return 0;
        const m = x % runWidth;
        return m > 0 ? m - runWidth : m;
    }

    $effect(() => {
        if (variant !== 'marquee' || !runEl) return;
        const el = runEl;
        const ro = new ResizeObserver(() => (runWidth = el.offsetWidth));
        ro.observe(el);
        runWidth = el.offsetWidth;
        const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
        reduced = mq.matches;
        const onMq = () => (reduced = mq.matches);
        mq.addEventListener('change', onMq);
        let last = performance.now();
        let raf = requestAnimationFrame(function tick(now) {
            const dt = Math.min(0.1, (now - last) / 1000);
            last = now;
            if (!held && !hovering && !focused && !reduced && runWidth > 0) {
                offset = wrap(offset - (runWidth / marqueeDurationS) * dt);
            }
            raf = requestAnimationFrame(tick);
        });
        return () => {
            cancelAnimationFrame(raf);
            ro.disconnect();
            mq.removeEventListener('change', onMq);
        };
    });

    let downX = 0;
    let downOffset = 0;
    let travel = 0;
    let downNote: NewsNote | undefined;

    function onPointerDown(e: PointerEvent) {
        if (e.button !== 0) return;
        held = true;
        downX = e.clientX;
        downOffset = offset;
        travel = 0;
        const i = (e.target as HTMLElement | null)?.closest<HTMLElement>('[data-i]')?.dataset.i;
        downNote = i !== undefined ? news[Number(i)] : undefined;
        try {
            (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
        } catch {
            // a pointer the browser no longer tracks — drag still works inside the strip
        }
    }
    function onPointerMove(e: PointerEvent) {
        if (!held) return;
        const dx = e.clientX - downX;
        travel = Math.max(travel, Math.abs(dx));
        offset = wrap(downOffset + dx);
    }
    function onPointerUp() {
        if (!held) return;
        held = false;
        if (travel < TAP_PX && downNote) onSelect?.(downNote);
        downNote = undefined;
    }
    function onPointerCancel() {
        held = false;
        downNote = undefined;
    }
</script>

{#if news.length > 0 && variant === 'marquee'}
    <div
        class="pp-ticker pp-ticker-marquee"
        role="region"
        aria-label={regionLabel}
        onfocusin={() => (focused = true)}
        onfocusout={() => (focused = false)}
    >
        <!-- Decorative: the moving copy is aria-hidden; the sr-only list below is the
             real, non-moving, keyboard/AT-reachable equivalent. Pointer handling (drag,
             tap, hold) lives on the viewport — see the script's marquee block. -->
        <div
            class="pp-ticker-marquee-viewport"
            aria-hidden="true"
            onpointerdown={onPointerDown}
            onpointermove={onPointerMove}
            onpointerup={onPointerUp}
            onpointercancel={onPointerCancel}
            onpointerenter={(e) => (hovering = e.pointerType === 'mouse')}
            onpointerleave={() => (hovering = false)}
        >
            <div class="pp-ticker-marquee-track" style:transform="translate3d({offset}px, 0, 0)">
                {#each [0, 1] as run (run)}
                    {#if run === 0}
                        <span class="pp-ticker-marquee-run" bind:this={runEl}>
                            {#each news as note, i (note.news_slug + '-0')}
                                <span class="pp-ticker-marquee-item" data-i={i}>{headlineFor(note)}</span>
                                <span class="pp-ticker-sep">•</span>
                            {/each}
                        </span>
                    {:else}
                        <span class="pp-ticker-marquee-run">
                            {#each news as note, i (note.news_slug + '-1')}
                                <span class="pp-ticker-marquee-item" data-i={i}>{headlineFor(note)}</span>
                                <span class="pp-ticker-sep">•</span>
                            {/each}
                        </span>
                    {/if}
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
