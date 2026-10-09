<script lang="ts">
    // Shared hero primitive (plan-card-visual-spec §4 — extracted at the SECOND renderer
    // that needs a stacked bar: the scheme_stack hero built it inline, the cash waterfall
    // reuses it). A pure `segments → geometry` function: a horizontal flex bar (each
    // segment sized by its `value`) + a swatch legend carrying the text. Deterministic,
    // never agent-drawn (R1); honest-partial (R2) — a null `value` renders as a fixed
    // HATCHED slice (counted, not sized), never a zero or a faked width.
    //
    // The caller pre-computes each segment's sizing `value` (a money midpoint, a scalar
    // figure) + its display `amount` (already locale-formatted) + `label` (enum→$t or
    // LocalizedText→pick). No figure or prose is minted here (R4).

    interface BarSegment {
        /** sizing weight (flex-grow); null → a fixed hatched "unknown" slice. */
        value: number | null;
        /** legend name (already localized by the caller). */
        label: string;
        /** legend figure (already locale-formatted), or '—' when unknown. */
        amount: string;
        /** prefix the amount with ~ (a banded estimate, not an exact figure). */
        estimate?: boolean;
    }

    let { segments, density = 'compact', ariaLabel }: {
        segments: BarSegment[];
        density?: 'compact' | 'full';
        ariaLabel?: string;
    } = $props();

    // A small, fixed categorical palette — segment colour is deterministic by index
    // (cycles if >5 segments). The colours are app.css's --chart-1..5 tokens (behavior 41).
    const PALETTE = ['var(--chart-1)', 'var(--chart-2)', 'var(--chart-3)', 'var(--chart-4)', 'var(--chart-5)'];
    const color = (i: number) => PALETTE[i % PALETTE.length];
    const known = (v: number | null): v is number => typeof v === 'number';

    // Sized by the segment value. A zero/negative known value → a thin slice (still
    // visible). Unknown (null) → a fixed hatched slice.
    function segStyle(value: number | null, i: number): string {
        if (known(value) && value > 0) return `flex:${value} 1 0;background-color:${color(i)};`;
        if (known(value)) return `flex:0 0 0.5rem;background-color:${color(i)};`;
        return 'flex:0 0 2.2rem;';
    }
</script>

<div class="sb" class:sb-full={density === 'full'}>
    {#if segments.length}
        <!-- Decorative reinforcement of the legend below; the legend carries the text
             for screen readers, so the bar itself is aria-hidden. -->
        <div class="sb-bar" aria-hidden="true" aria-label={ariaLabel}>
            {#each segments as s, i (i)}
                <span
                    class="sb-seg"
                    class:sb-seg-unknown={!known(s.value)}
                    style={segStyle(s.value, i)}
                ></span>
            {/each}
        </div>
        <ul class="sb-legend">
            {#each segments as s, i (i)}
                <li>
                    <span
                        class="sb-swatch"
                        class:sb-swatch-unknown={!known(s.value)}
                        style={known(s.value) ? `background-color:${color(i)};` : ''}
                    ></span>
                    <span class="sb-name">{s.label}</span>
                    <span class="sb-amount">{#if s.estimate && known(s.value)}~{/if}{s.amount}</span>
                </li>
            {/each}
        </ul>
    {/if}
</div>

<style>
    .sb-bar {
        display: flex;
        width: 100%;
        height: 1.6rem;
        border-radius: var(--radius-sm);
        overflow: hidden;
        border: 1px solid var(--border);
        background: var(--bg);
    }
    .sb-full .sb-bar {
        height: 2.2rem;
    }
    .sb-seg {
        display: block;
        min-width: 6px;
    }
    .sb-seg-unknown {
        background-color: var(--bg);
        background-image: repeating-linear-gradient(
            45deg,
            var(--border) 0 6px,
            transparent 6px 12px
        );
    }
    .sb-legend {
        list-style: none;
        margin: 0.5rem 0 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }
    .sb-legend li {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: var(--fs-sm);
    }
    .sb-swatch {
        width: 0.7rem;
        height: 0.7rem;
        border-radius: var(--radius-xs);
        flex: none;
    }
    .sb-swatch-unknown {
        background-color: var(--bg);
        background-image: repeating-linear-gradient(
            45deg,
            var(--border) 0 3px,
            transparent 3px 6px
        );
    }
    .sb-name {
        color: var(--ink);
        flex: 1;
    }
    .sb-amount {
        color: var(--accent);
        font-weight: 600;
        font-variant-numeric: tabular-nums;
    }
</style>
