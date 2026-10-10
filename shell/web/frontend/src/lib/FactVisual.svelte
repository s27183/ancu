<script lang="ts">
    // One fact drawn as a picture (behavior 42): bars, a year series, a big counted-up
    // figure, a 10×10 waffle for shares, a dumbbell of price growth, or a titled parcel
    // for a statement that has no number (behavior 44). Hand-drawn in
    // HTML/CSS on the app's tokens (no chart library, the behavior's Approach), so it
    // follows the theme and the type scale. Each mark is sized from the fact's own
    // numbers; nothing here invents or rounds a figure the reader sees — labels print
    // the compiled values through formatValue.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { type Fact, formatValue, pick, waffleCells } from '$lib/facts';

    let { fact }: { fact: Fact } = $props();

    // Marks grow in once the sheet is on screen. Under prefers-reduced-motion they are
    // drawn at full size at once (CSS below), and the figure shows its final value.
    let shown = $state(false);
    let counted = $state(0);
    onMount(() => {
        const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
        const target = fact.value ?? 0;
        if (reduce) {
            shown = true;
            counted = target;
            return;
        }
        const raf = requestAnimationFrame(() => (shown = true));
        const t0 = performance.now();
        const dur = 1100;
        let frame = 0;
        const tick = (now: number) => {
            const p = Math.min(1, (now - t0) / dur);
            counted = Math.round(target * (1 - Math.pow(1 - p, 3)));
            if (p < 1) frame = requestAnimationFrame(tick);
        };
        frame = requestAnimationFrame(tick);
        return () => {
            cancelAnimationFrame(raf);
            cancelAnimationFrame(frame);
        };
    });

    const items = $derived(fact.items ?? []);
    const max = $derived(Math.max(1, ...items.map((i) => i.value)));
    const fmt = (n: number) => formatValue(n, fact.unit, $lang);

    // Waffle: which segment each of the 100 cells belongs to.
    const cells = $derived.by(() => {
        const counts = waffleCells(items.map((i) => i.value));
        const out: number[] = [];
        counts.forEach((c, seg) => {
            for (let k = 0; k < c; k++) out.push(seg);
        });
        return out;
    });
    // Highlighted segments take the jade ramp, the rest neutral steps, in item order.
    const segTone = $derived.by(() => {
        let h = 0;
        let n = 0;
        return items.map((i) => (i.highlight ? `hl-${h++ % 3}` : `nt-${n++ % 4}`));
    });
</script>

<div class="fv fv--{fact.visual}" class:shown>
    {#if fact.visual === 'figure'}
        <div class="fv-big">{fmt(counted)}</div>
        {#if fact.compare}
            {@const from = fact.compare.value}
            {@const to = fact.value ?? 0}
            <div class="fv-compare">
                <div class="fv-cmp-row">
                    <span class="fv-cmp-label">{pick(fact.compare.label, $lang)}</span>
                    <span class="fv-cmp-track"
                        ><span class="fv-cmp-bar muted" style="--w:{(from / to) * 100}%"></span></span
                    >
                    <span class="fv-cmp-val">{fmt(from)}</span>
                </div>
                <div class="fv-cmp-row">
                    <span class="fv-cmp-label">{$t('intro.now')}</span>
                    <span class="fv-cmp-track"><span class="fv-cmp-bar" style="--w:100%"></span></span>
                    <span class="fv-cmp-val strong">{fmt(to)}</span>
                </div>
            </div>
        {/if}
    {:else if fact.visual === 'bars'}
        <ol class="fv-bars">
            {#each items as it, i (i)}
                <li class:hl={it.highlight} style="--i:{i}">
                    <span class="fv-rank">{i + 1}</span>
                    <span class="fv-label">{pick(it.label, $lang)}</span>
                    <span class="fv-track"><span class="fv-bar" style="--w:{(it.value / max) * 100}%"></span></span>
                    <span class="fv-val">{fmt(it.value)}</span>
                </li>
            {/each}
        </ol>
    {:else if fact.visual === 'series'}
        <div class="fv-cols" role="list">
            {#each items as it, i (i)}
                <div class="fv-col" class:partial={it.partial} role="listitem" style="--i:{i}">
                    <span class="fv-col-val">{fmt(it.value)}</span>
                    <span class="fv-col-track"><span class="fv-col-bar" style="--h:{(it.value / max) * 100}%"></span></span>
                    <span class="fv-col-label">{pick(it.label, $lang)}</span>
                </div>
            {/each}
        </div>
    {:else if fact.visual === 'split'}
        <div class="fv-split">
            <div class="fv-waffle" aria-hidden="true">
                {#each cells as seg, k (k)}
                    <span class="cell {segTone[seg]}" style="--k:{k}"></span>
                {/each}
            </div>
            <ul class="fv-key">
                {#each items as it, i (i)}
                    <li class:hl={it.highlight}>
                        <span class="sw {segTone[i]}"></span>
                        <span class="fv-key-val">{fmt(it.value)}</span>
                        <span class="fv-key-label">{pick(it.label, $lang)}</span>
                    </li>
                {/each}
            </ul>
        </div>
    {:else if fact.visual === 'growth'}
        <ul class="fv-growth">
            {#each items as it, i (i)}
                {@const from = it.from ?? 0}
                <li class:hl={it.highlight} style="--i:{i}">
                    <span class="fv-label">{pick(it.label, $lang)}</span>
                    <span class="fv-db">
                        <span class="fv-db-line" style="--a:{(from / max) * 100}%; --b:{(it.value / max) * 100}%"></span>
                        <span class="fv-db-dot from" style="--x:{(from / max) * 100}%"></span>
                        <span class="fv-db-dot to" style="--x:{(it.value / max) * 100}%"></span>
                    </span>
                    <span class="fv-db-vals"
                        ><span class="muted">{fmt(from)}</span> → <strong>{fmt(it.value)}</strong></span
                    >
                    <span class="fv-mult">×{(it.value / (from || 1)).toLocaleString($lang === 'vi' ? 'vi-VN' : 'en-AU', { maximumFractionDigits: 1 })}</span>
                </li>
            {/each}
        </ul>
    {:else if fact.visual === 'statement'}
        <!-- A titled parcel: the house and the ground under it inside one boundary. -->
        <svg class="fv-parcel" viewBox="0 0 120 64" aria-hidden="true">
            <path class="ground" d="M6 50 L60 36 L114 50 L60 62 Z" />
            <path class="line" d="M6 50 L60 36 L114 50 L60 62 Z" />
            <path class="house" d="M44 48 V34 L60 24 L76 34 V48 L60 52 Z" />
            <path class="roof" d="M40 35 L60 22 L80 35" />
            <circle class="pin" cx="96" cy="47" r="3.2" />
        </svg>
    {/if}
</div>

<style>
    .fv {
        --grow: cubic-bezier(0.2, 0.8, 0.2, 1);
        font-variant-numeric: tabular-nums;
    }

    /* --- statement --------------------------------------------------------- */
    .fv-parcel {
        width: 7.5rem;
        height: 4rem;
    }
    .fv-parcel .ground {
        fill: var(--accent-soft);
    }
    .fv-parcel .line {
        fill: none;
        stroke: var(--accent);
        stroke-width: 1.6;
        stroke-dasharray: 4 3;
    }
    .fv-parcel .house {
        fill: var(--surface);
        stroke: var(--ink-2);
        stroke-width: 1.6;
        stroke-linejoin: round;
    }
    .fv-parcel .roof {
        fill: none;
        stroke: var(--accent);
        stroke-width: 2.4;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
    .fv-parcel .pin {
        fill: var(--gold-mark);
    }

    /* --- figure ------------------------------------------------------------ */
    .fv-big {
        font-size: clamp(2.4rem, 7vw, 3.4rem);
        font-weight: 800;
        letter-spacing: -0.035em;
        line-height: 1;
        color: var(--accent);
    }
    .fv-compare {
        margin-top: var(--sp-3);
        display: grid;
        gap: var(--sp-1);
    }
    .fv-cmp-row {
        display: grid;
        grid-template-columns: 4.5rem 1fr auto;
        align-items: center;
        gap: var(--sp-2);
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .fv-cmp-track {
        height: 0.5rem;
        border-radius: var(--radius-pill);
        background: var(--bg-2);
        overflow: hidden;
    }
    .fv-cmp-bar {
        display: block;
        height: 100%;
        width: 0;
        border-radius: inherit;
        background: var(--accent);
        transition: width 0.9s var(--grow);
    }
    .fv-cmp-bar.muted {
        background: var(--border-strong);
    }
    .shown .fv-cmp-bar {
        width: var(--w);
    }
    .fv-cmp-val.strong {
        color: var(--ink);
        font-weight: 700;
    }

    /* --- ranked bars --------------------------------------------------------- */
    .fv-bars {
        list-style: none;
        margin: 0;
        padding: 0;
        display: grid;
        gap: var(--sp-2);
    }
    .fv-bars li,
    .fv-growth li {
        display: grid;
        grid-template-columns: 1.25rem minmax(4.5rem, 6.5rem) 1fr 3rem;
        align-items: center;
        gap: var(--sp-2);
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    .fv-rank {
        font-size: var(--fs-2xs);
        font-weight: 700;
        color: var(--muted);
        text-align: center;
    }
    .fv-track {
        height: 0.85rem;
        border-radius: var(--radius-pill);
        background: var(--bg-2);
        overflow: hidden;
    }
    .fv-bar {
        display: block;
        height: 100%;
        width: 0;
        border-radius: inherit;
        background: var(--border-strong);
        transition: width 0.9s var(--grow) calc(var(--i) * 90ms);
    }
    .shown .fv-bar {
        width: var(--w);
    }
    .fv-val {
        text-align: right;
        font-weight: 600;
    }
    .fv-bars li.hl {
        color: var(--ink);
        font-weight: 700;
    }
    .fv-bars li.hl .fv-bar {
        background: var(--brand-gradient);
    }
    .fv-bars li.hl .fv-rank {
        color: var(--ink-inverse);
        background: var(--accent);
        border-radius: var(--radius-pill);
        line-height: 1.25rem;
    }

    /* --- year columns ------------------------------------------------------- */
    .fv-cols {
        display: grid;
        grid-auto-flow: column;
        grid-auto-columns: 1fr;
        gap: var(--sp-3);
        align-items: end;
        height: 9.5rem;
    }
    .fv-col {
        display: grid;
        grid-template-rows: auto 1fr auto;
        height: 100%;
        gap: var(--sp-1);
        text-align: center;
    }
    .fv-col-val {
        font-weight: 700;
        font-size: var(--fs-md);
        color: var(--ink);
    }
    .fv-col-track {
        position: relative;
        display: flex;
        align-items: flex-end;
    }
    .fv-col-bar {
        width: 100%;
        height: 0;
        border-radius: var(--radius-sm) var(--radius-sm) 0.2rem 0.2rem;
        background: var(--brand-gradient);
        transition: height 0.9s var(--grow) calc(var(--i) * 120ms);
    }
    .shown .fv-col-bar {
        height: var(--h);
    }
    .fv-col.partial .fv-col-bar {
        background: repeating-linear-gradient(
            135deg,
            var(--accent-soft-2) 0 0.35rem,
            var(--accent-soft) 0.35rem 0.7rem
        );
        outline: 1.5px dashed var(--accent);
        outline-offset: -1.5px;
    }
    .fv-col-label {
        font-size: var(--fs-2xs);
        color: var(--muted);
    }

    /* --- waffle ------------------------------------------------------------- */
    .fv-split {
        display: grid;
        grid-template-columns: minmax(7rem, 9.5rem) 1fr;
        gap: var(--sp-4);
        align-items: center;
    }
    .fv-waffle {
        display: grid;
        grid-template-columns: repeat(10, 1fr);
        gap: 2px;
        aspect-ratio: 1;
        max-width: 100%;
    }
    .cell {
        border-radius: var(--radius-xs);
        transform: scale(0);
        transition: transform 0.35s var(--grow) calc(var(--k) * 7ms);
    }
    .shown .cell {
        transform: scale(1);
    }
    .hl-0 {
        background: var(--accent);
    }
    .hl-1 {
        background: var(--chart-2);
    }
    .hl-2 {
        background: var(--accent-hover);
    }
    .nt-0 {
        background: var(--border-strong);
    }
    .nt-1 {
        background: var(--border);
    }
    .nt-2 {
        background: var(--bg-2);
        box-shadow: inset 0 0 0 1px var(--border);
    }
    .nt-3 {
        background: var(--surface-2);
        box-shadow: inset 0 0 0 1px var(--border);
    }
    .fv-key {
        list-style: none;
        margin: 0;
        padding: 0;
        display: grid;
        gap: 0.3rem;
        font-size: var(--fs-xs);
        color: var(--ink-2);
    }
    .fv-key li {
        display: grid;
        grid-template-columns: 0.75rem 3rem 1fr;
        align-items: center;
        gap: var(--sp-2);
    }
    .fv-key li.hl {
        color: var(--ink);
        font-weight: 600;
    }
    .sw {
        width: 0.75rem;
        height: 0.75rem;
        border-radius: var(--radius-xs);
    }
    .fv-key-val {
        font-weight: 700;
        text-align: right;
    }

    /* --- growth dumbbells ---------------------------------------------------- */
    .fv-growth {
        list-style: none;
        margin: 0;
        padding: 0;
        display: grid;
        gap: var(--sp-3);
    }
    .fv-growth li {
        grid-template-columns: 5.25rem 1fr auto auto;
        row-gap: 0.1rem;
    }
    .fv-growth li.hl .fv-label {
        color: var(--ink);
        font-weight: 700;
    }
    .fv-db {
        position: relative;
        height: 0.9rem;
    }
    .fv-db::before {
        content: '';
        position: absolute;
        left: 0;
        right: 0;
        top: 50%;
        border-top: 1px dashed var(--border);
    }
    .fv-db-line {
        position: absolute;
        top: calc(50% - 0.15rem);
        height: 0.3rem;
        left: var(--a);
        width: 0;
        border-radius: var(--radius-pill);
        background: var(--brand-gradient);
        transition: width 1s var(--grow) calc(var(--i) * 110ms);
    }
    .shown .fv-db-line {
        width: calc(var(--b) - var(--a));
    }
    .fv-db-dot {
        position: absolute;
        top: 50%;
        width: 0.7rem;
        height: 0.7rem;
        margin: -0.35rem 0 0 -0.35rem;
        border-radius: 50%;
        left: var(--x);
    }
    .fv-db-dot.from {
        background: var(--surface);
        box-shadow: inset 0 0 0 2px var(--border-strong);
    }
    .fv-db-dot.to {
        background: var(--accent);
        box-shadow: 0 0 0 3px var(--accent-soft);
        opacity: 0;
        transition: opacity 0.3s ease calc(0.8s + var(--i) * 110ms);
    }
    .shown .fv-db-dot.to {
        opacity: 1;
    }
    .fv-db-vals {
        font-size: var(--fs-xs);
        white-space: nowrap;
    }
    .fv-db-vals .muted {
        color: var(--muted);
    }
    .fv-mult {
        font-size: var(--fs-xs);
        font-weight: 800;
        color: var(--accent);
        background: var(--accent-soft);
        border-radius: var(--radius-pill);
        padding: 0.1rem 0.45rem;
    }

    @media (max-width: 30rem) {
        .fv-growth li {
            grid-template-columns: 4.75rem 1fr auto;
        }
        .fv-growth .fv-db {
            grid-column: 1 / -1;
            grid-row: 2;
        }
        .fv-split {
            grid-template-columns: 7rem 1fr;
        }
    }

    @media (prefers-reduced-motion: reduce) {
        .fv * {
            transition: none !important;
        }
    }
</style>
