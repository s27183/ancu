<script lang="ts">
    // The `buying-strategy-card` renderer (constraint #7 vocabulary) — the investor
    // bid-discipline plan from buying_strategy (outcome `bid_plan_investor`). The hero is
    // a price ladder: the yield-anchored ceiling and walk-away frame the max bid — the
    // investor-discipline idea that the thesis price, not emotion, sets the cap
    // (kb.investor.bid-discipline / yield-anchored-pricing). Decision-support only: it
    // surfaces the engine's figures honest-partial, never a "you should pay X".
    //
    // No live producer yet (buying_strategy is a Phase-B agent component, unwired in both
    // modes); built against the §11.9 renderer contract { max_bid, walk_away,
    // comparables[], style } + the blueprint's yield_anchored_max_price / thesis_alignment.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type BidPlanInvestorOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as BidPlanInvestorOutcome);

    // thesis alignment + negotiation style are closed blueprint enums → $t with a calm
    // tone; an unknown value falls back to the raw string (SummaryCard pattern), never dropped.
    const THESIS = new Set(['aligned', 'stretched', 'misaligned']);
    const THESIS_TONE: Record<string, 'good' | 'warn' | 'info'> = {
        aligned: 'good',
        stretched: 'warn',
        misaligned: 'warn'
    };
    const STYLES = new Set(['assertive', 'patient', 'early_offer', 'low_anchor', 'thesis_walk_away']);
    function thesisLabel(v: string): string {
        return THESIS.has(v) ? $t(`plan.thesis.${v}` as 'plan.thesis.aligned') : v;
    }
    function styleLabel(v: string): string {
        return STYLES.has(v) ? $t(`plan.style.${v}` as 'plan.style.assertive') : v;
    }

    const isNum = (v: number | null | undefined): v is number => typeof v === 'number';
    // The price ladder: walk-away ≤ yield ceiling ≤ max bid, plotted on a shared axis so
    // the discipline gap reads at a glance. Render only when at least one is a real figure.
    const prices = $derived([
        { key: 'walk_away', label: $t('plan.f.walk_away'), v: o.walk_away ?? null, tone: 'floor' },
        { key: 'yield', label: $t('plan.f.yield_ceiling'), v: o.yield_anchored_max_price ?? null, tone: 'anchor' },
        { key: 'max', label: $t('plan.f.max_bid'), v: o.max_bid ?? null, tone: 'cap' }
    ]);
    const scale = $derived(Math.max(0, ...prices.map((p) => (isNum(p.v) ? p.v : 0))));
    const anyPrice = $derived(prices.some((p) => isNum(p.v)));
    const pctOf = (v: number) => (scale > 0 ? Math.max(0, Math.min(100, (v / scale) * 100)) : 0);
</script>

<!-- ── Price-ladder hero ──────────────────────────────────────────────── -->
{#if anyPrice}
    <div class="bs-hero">
        {#each prices as p (p.key)}
            <div class="bs-row">
                <span class="bs-rowlabel">{p.label}</span>
                <div class="bs-track" aria-hidden="true">
                    {#if isNum(p.v)}
                        <span class="bs-fill bs-{p.tone}" style="width:{pctOf(p.v)}%"></span>
                    {/if}
                </div>
                <span class="bs-val" class:bs-muted={!isNum(p.v)}>
                    {isNum(p.v) ? money(p.v, $lang) : '—'}
                </span>
            </div>
        {/each}
    </div>
{:else}
    <Pending />
{/if}

<!-- discipline chips -->
{#if o.thesis_alignment}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.thesis')}</span>
        <Chip label={thesisLabel(o.thesis_alignment)} tone={THESIS_TONE[o.thesis_alignment] ?? 'neutral'} />
    </div>
{/if}
{#if o.style}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.nego_style')}</span>
        <Chip label={styleLabel(o.style)} tone="info" />
    </div>
{/if}

<!-- comparables -->
{#if o.comparables?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.comparables')}</span>
        {#each o.comparables as c, i (i)}
            <div class="bs-comp">
                <div class="bs-comp-head">
                    {#if c.address}<span class="bs-comp-addr">{c.address}</span>{/if}
                    {#if isNum(c.price)}<span class="bs-comp-price">{money(c.price, $lang)}</span>{/if}
                </div>
                {#if pick(c.note, $lang)}<p class="bs-comp-note">{pick(c.note, $lang)}</p>{/if}
            </div>
        {/each}
    </div>
{/if}

<NoteList heading={$t('plan.f.conditions')} notes={o.conditions} />
<NoteList heading={$t('plan.f.assumptions')} notes={o.key_assumptions} />

<style>
    .bs-hero {
        margin-bottom: 0.6rem;
    }
    .bs-row {
        display: grid;
        grid-template-columns: 6.5rem 1fr auto;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.35rem;
    }
    .bs-rowlabel {
        font-size: 0.75rem;
        color: var(--muted);
    }
    .bs-track {
        position: relative;
        height: 0.9rem;
        border-radius: 0.3rem;
        background: var(--bg);
        border: 1px solid var(--border);
        overflow: hidden;
    }
    .bs-fill {
        position: absolute;
        top: 0;
        bottom: 0;
        left: 0;
        border-radius: 0.2rem;
    }
    /* walk-away = the floor of discipline (muted); yield anchor = the thesis cap; max bid
       = the willing ceiling (accent). One axis, three calm weights. */
    .bs-floor {
        background: color-mix(in srgb, var(--accent) 25%, transparent);
    }
    .bs-anchor {
        background: color-mix(in srgb, var(--accent) 55%, transparent);
    }
    .bs-cap {
        background: var(--accent);
    }
    .bs-val {
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .bs-muted {
        color: var(--muted);
        font-weight: 400;
    }
    .bs-comp {
        padding: 0.35rem 0;
        border-top: 1px solid var(--border);
    }
    .bs-comp-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
    }
    .bs-comp-addr {
        font-size: 0.85rem;
        color: var(--ink);
    }
    .bs-comp-price {
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    .bs-comp-note {
        margin: 0.15rem 0 0;
        font-size: 0.78rem;
        color: var(--muted);
        line-height: 1.4;
    }
</style>
