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

    // Behavior 43: the strip moves under the finger. One Web Animations API animation
    // owns the track's translateX (behavior 51), so:
    //   - its free motion is that animation: translateX from 0 to -runWidth over
    //     runWidth / SPEED_PX_S seconds, repeating, wrapping over the two duplicated
    //     runs. The compositor runs it; no script runs per frame. (Before 51 a
    //     requestAnimationFrame loop set the offset every frame: measured 2026-10-10,
    //     120 rAF calls a second on an idle home screen, the phone ran warm);
    //   - a drag pauses it and sets its currentTime from the finger, 1:1 with the
    //     pointer (a CSS animation could not be dragged; a paused WAAPI one can);
    //   - a press that travels < TAP_PX is a tap: it opens the note it started on;
    //   - while a pointer is down, a mouse hovers, or focus is inside, the strip stands
    //     still, and it waits RESUME_MS after the last touch, drag or hover before it
    //     moves again (behavior 48, Son: a reader swiping back and forth to find a
    //     headline must not have it run off; a new touch restarts the wait) — one
    //     timer resumes it, not a per-frame check;
    //   - it moves at a constant SPEED_PX_S, whatever the number of headlines (behavior
    //     48: the old run-duration cap of 60 s made 18 headlines pass at 163 px/s,
    //     ~3 s each — too fast to read);
    //   - a tap opens its note on the CLICK that follows a short press, not on
    //     pointerup: on a phone the detail sheet rises from the bottom and its scrim
    //     covers the strip, so a sheet opened on pointerup would sit under the click the
    //     browser sends next, and that click would land on the scrim and close it.
    // WCAG 2.2.2 (Pause, Stop, Hide) without a visible pause button (Son, behavior 43):
    // press-and-hold stops it, hover/focus stop it, prefers-reduced-motion keeps it
    // still (drag still scrolls it), and the sr-only list below is a non-moving
    // equivalent for keyboard and screen-reader users.
    const TAP_PX = 8;
    // ~5 characters a second at the strip's type size (≈7.6 px a character measured
    // 2026-10-10): an average headline (≈540 px) takes ≈13 s to pass. Son judges it.
    const SPEED_PX_S = 40;
    const RESUME_MS = 3000;

    let runEl: HTMLElement | undefined = $state();
    let trackEl: HTMLElement | undefined = $state();
    let runWidth = $state(0);
    let anim: Animation | undefined;
    let keptFrac = 0;
    let held = false;
    let hovering = false;
    let focused = false;
    let reduced = false;
    let resting = false; // inside RESUME_MS after the last touch, drag or hover
    let restTimer: ReturnType<typeof setTimeout> | undefined;

    const durationMs = () => (runWidth / SPEED_PX_S) * 1000;

    function wrap(x: number): number {
        if (runWidth <= 0) return 0;
        const m = x % runWidth;
        return m > 0 ? m - runWidth : m;
    }

    // The track's offset in px, <= 0, read from and written to the animation's clock.
    function getOffset(): number {
        const d = durationMs();
        if (!anim || d <= 0) return 0;
        const tm = Number(anim.currentTime ?? 0);
        return -((tm % d) / d) * runWidth;
    }
    function setOffset(x: number) {
        if (!anim || runWidth <= 0) return;
        anim.currentTime = (-wrap(x) / runWidth) * durationMs();
    }

    // Play or pause to match the reader's state; called on each change, never per frame.
    function sync() {
        if (!anim) return;
        const still = held || hovering || focused || reduced || resting;
        if (still && anim.playState !== 'paused') anim.pause();
        else if (!still && anim.playState !== 'running') anim.play();
    }

    function rest() {
        resting = true;
        clearTimeout(restTimer);
        restTimer = setTimeout(() => {
            resting = false;
            sync();
        }, RESUME_MS);
        sync();
    }

    $effect(() => {
        if (variant !== 'marquee' || !runEl) return;
        const el = runEl;
        const ro = new ResizeObserver(() => (runWidth = el.offsetWidth));
        ro.observe(el);
        runWidth = el.offsetWidth;
        const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
        reduced = mq.matches;
        const onMq = () => {
            reduced = mq.matches;
            sync();
        };
        mq.addEventListener('change', onMq);
        return () => {
            ro.disconnect();
            mq.removeEventListener('change', onMq);
            clearTimeout(restTimer);
        };
    });

    // (Re)build the animation when the run's width changes (a language switch, a
    // resize, new headlines), keeping the strip where it stood.
    $effect(() => {
        if (variant !== 'marquee' || !trackEl || runWidth <= 0) return;
        anim = trackEl.animate(
            [{ transform: 'translate3d(0, 0, 0)' }, { transform: `translate3d(${-runWidth}px, 0, 0)` }],
            { duration: durationMs(), iterations: Infinity, easing: 'linear' }
        );
        anim.currentTime = keptFrac * durationMs();
        sync();
        return () => {
            // the fraction of a run already travelled, for the next animation to resume at
            const d = Number(anim?.effect?.getTiming().duration ?? 0);
            keptFrac = anim && d > 0 ? (Number(anim.currentTime ?? 0) % d) / d : 0;
            anim?.cancel();
            anim = undefined;
        };
    });

    let downX = 0;
    let downOffset = 0;
    let travel = 0;
    let downNote: NewsNote | undefined;
    let tapNote: NewsNote | undefined; // a short press's note, opened by the click after it

    function onPointerDown(e: PointerEvent) {
        if (e.button !== 0) return;
        held = true;
        sync();
        tapNote = undefined;
        downX = e.clientX;
        downOffset = getOffset();
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
        setOffset(downOffset + dx);
    }
    function onPointerUp() {
        if (!held) return;
        held = false;
        rest();
        tapNote = travel < TAP_PX ? downNote : undefined;
        downNote = undefined;
    }
    function onPointerCancel() {
        held = false;
        rest();
        downNote = undefined;
        tapNote = undefined;
    }
    function onClick() {
        const note = tapNote;
        tapNote = undefined;
        if (note) onSelect?.(note);
    }
</script>

{#if news.length > 0 && variant === 'marquee'}
    <div
        class="pp-ticker pp-ticker-marquee"
        role="region"
        aria-label={regionLabel}
        onfocusin={() => {
            focused = true;
            sync();
        }}
        onfocusout={() => {
            focused = false;
            sync();
        }}
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
            onclick={onClick}
            onpointerenter={(e) => {
                hovering = e.pointerType === 'mouse';
                sync();
            }}
            onpointerleave={() => {
                const was = hovering;
                hovering = false;
                if (was) rest();
            }}
        >
            <div class="pp-ticker-marquee-track" bind:this={trackEl}>
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
