<script lang="ts">
    // Draws the first-visit tour's current step (behavior 52; the flow lives in tour.ts):
    // a spotlight ring around the control to tap next, the rest of the screen dimmed, and
    // one bubble beside it with the step count, "Skip", and on step 1 a "Try Cabramatta"
    // chip, on step 4 "Done". The layer takes no pointer events — only the bubble does —
    // so the visitor taps the real control under the ring (or anything else) as normal.
    // The target is found by its data-tour attribute and re-measured every 150 ms while a
    // step shows, because the controls move with the app (the map flies, the sheet slides
    // in); nothing runs while the tour is off or between bubbles. Placement tries below,
    // above, right, left of the target (right, left first for a target taller than half
    // the screen) and keeps the first that fits in the viewport with a
    // 12 px margin; if none does, the side with more room, clamped inside.
    import { onDestroy } from 'svelte';
    import { t, type MessageKey } from '$lib/i18n';
    import { tourStep, endTour, TOUR_STEPS, type TourStep } from '$lib/tour';

    let { ontry }: { ontry: () => void } = $props();

    // Each step's target, first one present wins (step 1 falls back to the filters button
    // when the search panel has been closed).
    const TARGETS: Record<1 | 2 | 3 | 4, string[]> = {
        1: ['search', 'controls'],
        2: ['plan-tab'],
        3: ['plan-cta'],
        4: ['plan']
    };
    const TEXT: Record<1 | 2 | 3 | 4, MessageKey> = {
        1: 'tour.step1',
        2: 'tour.step2',
        3: 'tour.step3',
        4: 'tour.step4'
    };
    const MARGIN = 12;
    const GAP = 10;
    const PAD = 6;

    const shown = (s: TourStep): s is 1 | 2 | 3 | 4 => typeof s === 'number' && s > 0;

    let rect = $state<DOMRect | null>(null);
    let bubbleEl = $state<HTMLElement | null>(null);
    let pos = $state({ top: 0, left: 0 });

    function find(s: 1 | 2 | 3 | 4): DOMRect | null {
        for (const name of TARGETS[s]) {
            const el = document.querySelector<HTMLElement>(`[data-tour="${name}"]`);
            if (!el) continue;
            let r = el.getBoundingClientRect();
            if (!(r.width > 0 && r.height > 0)) continue;
            // A part that pops out of the target (the search's suggestion list) counts as
            // the target, so the bubble never sits over it.
            for (const part of el.querySelectorAll<HTMLElement>('[data-tour-part]')) {
                const q = part.getBoundingClientRect();
                const l = Math.min(r.left, q.left);
                const tp = Math.min(r.top, q.top);
                r = new DOMRect(l, tp, Math.max(r.right, q.right) - l, Math.max(r.bottom, q.bottom) - tp);
            }
            return r;
        }
        return null;
    }

    function place(r: DOMRect) {
        if (!bubbleEl) return;
        const vw = window.innerWidth;
        const vh = window.innerHeight;
        const bw = bubbleEl.offsetWidth;
        const bh = bubbleEl.offsetHeight;
        const clampX = (x: number) => Math.min(Math.max(x, MARGIN), vw - MARGIN - bw);
        const clampY = (y: number) => Math.min(Math.max(y, MARGIN), vh - MARGIN - bh);
        const cx = clampX(r.left + r.width / 2 - bw / 2);
        const cy = clampY(r.top + r.height / 2 - bh / 2);
        const below = r.bottom + PAD + GAP;
        const above = r.top - PAD - GAP - bh;
        const right = r.right + PAD + GAP;
        const left = r.left - PAD - GAP - bw;
        const fits = {
            below: below + bh <= vh - MARGIN,
            above: above >= MARGIN,
            right: right + bw <= vw - MARGIN,
            left: left >= MARGIN
        };
        const at = {
            below: { top: below, left: cx },
            above: { top: above, left: cx },
            right: { top: cy, left: right },
            left: { top: cy, left }
        };
        // A tall target (the plan on desktop) is better read with the bubble beside it.
        const order = (
            r.height > vh / 2 ? ['right', 'left', 'above', 'below'] : ['below', 'above', 'right', 'left']
        ) as (keyof typeof fits)[];
        const side = order.find((k) => fits[k]);
        if (side) pos = at[side];
        else if (vh - r.bottom > r.top) pos = { top: clampY(below), left: cx };
        else pos = { top: clampY(above), left: cx };
    }

    function measure() {
        const s = $tourStep;
        if (!shown(s)) {
            rect = null;
            return;
        }
        const r = find(s);
        // Only re-render when the target actually moved (no churn while it sits still).
        if (
            !r !== !rect ||
            (r &&
                rect &&
                (r.top !== rect.top ||
                    r.left !== rect.left ||
                    r.width !== rect.width ||
                    r.height !== rect.height))
        )
            rect = r;
        if (r) place(r);
    }

    let timer: ReturnType<typeof setInterval> | undefined;
    $effect(() => {
        const s = $tourStep;
        clearInterval(timer);
        timer = undefined;
        if (!shown(s)) {
            rect = null;
            return;
        }
        measure();
        timer = setInterval(measure, 150);
        return () => clearInterval(timer);
    });
    // Place again once the bubble has rendered (its size is known only then).
    $effect(() => {
        if (bubbleEl && rect) place(rect);
    });
    onDestroy(() => clearInterval(timer));
</script>

{#if shown($tourStep) && rect}
    {@const s = $tourStep as 1 | 2 | 3 | 4}
    <div class="tour-layer" data-tour-layer>
        <div
            class="tour-ring"
            style:top="{rect.top - PAD}px"
            style:left="{rect.left - PAD}px"
            style:width="{rect.width + PAD * 2}px"
            style:height="{rect.height + PAD * 2}px"
        ></div>
        <div
            class="tour-bubble"
            bind:this={bubbleEl}
            role="dialog"
            aria-modal="false"
            aria-label={$t('tour.aria')}
            style:top="{pos.top}px"
            style:left="{pos.left}px"
        >
            <p class="tour-text" aria-live="polite">{$t(TEXT[s])}</p>
            {#if s === 1}
                <button type="button" class="tour-chip" onclick={ontry}>{$t('tour.try')}</button>
            {/if}
            <div class="tour-foot">
                <span class="tour-count">{s}/{TOUR_STEPS}</span>
                {#if s === 4}
                    <button type="button" class="tour-done" onclick={endTour}>{$t('tour.done')}</button>
                {:else}
                    <button type="button" class="tour-skip" onclick={endTour}>{$t('tour.skip')}</button>
                {/if}
            </div>
        </div>
    </div>
{/if}

<style>
    .tour-layer {
        position: fixed;
        inset: 0;
        z-index: 50; /* over the suburb sheet (30) and controls; under Login (70) */
        pointer-events: none;
    }
    /* The dim is the ring's own shadow, so the target stays bright and tappable. */
    .tour-ring {
        position: fixed;
        border-radius: 0.75rem;
        box-shadow:
            0 0 0 2px var(--accent),
            0 0 0 200vmax rgb(15 22 36 / 0.42);
        transition:
            top var(--t-med) var(--ease),
            left var(--t-med) var(--ease),
            width var(--t-med) var(--ease),
            height var(--t-med) var(--ease);
        animation: tour-in var(--t-med) var(--ease);
    }
    .tour-bubble {
        position: fixed;
        width: min(20rem, calc(100vw - 24px));
        box-sizing: border-box;
        padding: 0.85rem 0.95rem 0.7rem;
        border-radius: var(--radius);
        background: var(--surface);
        color: var(--ink);
        box-shadow: var(--shadow-2);
        pointer-events: auto;
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
        transition:
            top var(--t-med) var(--ease),
            left var(--t-med) var(--ease);
        animation: tour-in var(--t-med) var(--ease);
    }
    .tour-text {
        margin: 0;
        font-size: 0.95rem;
        line-height: 1.45;
    }
    .tour-chip {
        align-self: flex-start;
        border: 1px solid var(--accent-line);
        background: var(--accent-soft);
        color: var(--accent);
        border-radius: 999px;
        padding: 0.35rem 0.8rem;
        font: inherit;
        font-size: 0.9rem;
        font-weight: 600;
        cursor: pointer;
    }
    .tour-chip:hover {
        background: var(--accent-soft-2);
    }
    .tour-foot {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.75rem;
    }
    .tour-count {
        font-size: 0.8rem;
        color: var(--muted);
        font-variant-numeric: tabular-nums;
    }
    .tour-skip,
    .tour-done {
        font: inherit;
        font-size: 0.9rem;
        border-radius: 0.5rem;
        padding: 0.3rem 0.75rem;
        cursor: pointer;
    }
    .tour-skip {
        border: none;
        background: none;
        color: var(--muted);
    }
    .tour-skip:hover {
        color: var(--ink);
    }
    .tour-done {
        border: none;
        background: var(--accent);
        color: var(--accent-ink);
        font-weight: 600;
    }
    .tour-done:hover {
        background: var(--accent-hover);
    }
    .tour-chip:focus-visible,
    .tour-skip:focus-visible,
    .tour-done:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }
    @keyframes tour-in {
        from {
            opacity: 0;
        }
    }
    @media (prefers-reduced-motion: reduce) {
        .tour-ring,
        .tour-bubble {
            transition: none;
            animation: none;
        }
    }
</style>
