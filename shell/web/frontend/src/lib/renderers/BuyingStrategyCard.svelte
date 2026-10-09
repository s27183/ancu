<script lang="ts">
    // The `buying-strategy-card` renderer (constraint #7 vocabulary) — the investor
    // bid-discipline plan from buying_strategy (outcome `bid_plan_investor`). The hero is
    // a price ladder: the yield-anchored ceiling and walk-away frame the max bid — the
    // investor-discipline idea that the thesis price, not emotion, sets the cap
    // (kb.investor.bid-discipline / yield-anchored-pricing). Decision-support only: it
    // surfaces the engine's figures honest-partial, never a "you should pay X".
    //
    // Corrected 2026-07-11: this renderer had drifted onto a never-real §11.9 draft shape
    // (max_bid/walk_away/comparables[]/style/conditions/key_assumptions) — buying_strategy
    // IS live today (Mode C, reachable via property-attach; fh_engine_buying.erl), and
    // NONE of those keys exist on its real bid_plan_investor outcome. Every price is a
    // BAND (yield_anchored_max_price/max_bid_value/walk_away_price — the rent input is a
    // band); red_flags_to_monitor (PLACED from property_fit_investor.key_concerns) was
    // real, populated content this renderer never read at all before this fix.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type BidPlanInvestorOutcome, type MoneyRange } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import Field from './Field.svelte';

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

    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const mid = (r: MoneyRange) => (r[0] + r[1]) / 2;
    function rangeLabel(v: MoneyRange | null | undefined): string {
        if (!hasRange(v)) return '—';
        return v[0] === v[1] ? (money(v[0], $lang) ?? '—') : (moneyRange(v, $lang) ?? '—');
    }
    // The price ladder: walk-away ≤ yield ceiling ≤ max bid, plotted on a shared axis so
    // the discipline gap reads at a glance. Render only when at least one is a real figure.
    // Each is a BAND — the ladder plots the band's midpoint (matches SummaryCard's own
    // range-to-scale convention elsewhere).
    const prices = $derived([
        { key: 'walk_away', label: $t('plan.f.walk_away'), v: o.walk_away_price ?? null, tone: 'floor' },
        { key: 'yield', label: $t('plan.f.yield_ceiling'), v: o.yield_anchored_max_price ?? null, tone: 'anchor' },
        { key: 'max', label: $t('plan.f.max_bid'), v: o.max_bid_value ?? null, tone: 'cap' }
    ]);
    const scale = $derived(Math.max(0, ...prices.map((p) => (hasRange(p.v) ? mid(p.v) : 0))));
    const anyPrice = $derived(prices.some((p) => hasRange(p.v)));
    const pctOf = (v: number) => (scale > 0 ? Math.max(0, Math.min(100, (v / scale) * 100)) : 0);
</script>

<!-- ── Price-ladder hero ──────────────────────────────────────────────── -->
{#if anyPrice}
    <div class="bs-hero">
        {#each prices as p (p.key)}
            <div class="bs-row">
                <span class="bs-rowlabel">{p.label}</span>
                <div class="bs-track" aria-hidden="true">
                    {#if hasRange(p.v)}
                        <span class="bs-fill bs-{p.tone}" style="width:{pctOf(mid(p.v))}%"></span>
                    {/if}
                </div>
                <span class="bs-val" class:bs-muted={!hasRange(p.v)}>
                    {rangeLabel(p.v)}
                </span>
            </div>
        {/each}
    </div>
{:else}
    <Pending />
{/if}

{#if pick(o.max_bid_reasoning, $lang)}
    <p class="bs-reasoning">{pick(o.max_bid_reasoning, $lang)}</p>
{/if}

<!-- discipline chips -->
{#if o.thesis_alignment}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.thesis')}</span>
        <Chip label={thesisLabel(o.thesis_alignment)} tone={THESIS_TONE[o.thesis_alignment] ?? 'neutral'} />
    </div>
{/if}
{#if o.negotiation_style}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.nego_style')}</span>
        <Chip label={styleLabel(o.negotiation_style)} tone="info" />
    </div>
{/if}
<Field label={$t('plan.f.max_bid_confidence')} value={o.max_bid_confidence != null ? String(o.max_bid_confidence) : null} />

<!-- red flags — PLACED from property_fit_investor.key_concerns (real content this
     renderer dropped entirely before the 2026-07-11 fix). -->
{#if o.red_flags_to_monitor?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.red_flags')}</span>
        {#each o.red_flags_to_monitor as flag, i (i)}
            {#if pick(flag, $lang)}<p class="bs-comp-note">{pick(flag, $lang)}</p>{/if}
        {/each}
    </div>
{/if}

<NoteList heading={$t('plan.f.conditions')} notes={o.conditions_to_request} />

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
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .bs-track {
        position: relative;
        height: 0.9rem;
        border-radius: var(--radius-xs);
        background: var(--bg);
        border: 1px solid var(--border);
        overflow: hidden;
    }
    .bs-fill {
        position: absolute;
        top: 0;
        bottom: 0;
        left: 0;
        border-radius: var(--radius-xs);
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
        font-size: var(--fs-xs);
        font-weight: 600;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .bs-muted {
        color: var(--muted);
        font-weight: 400;
    }
    .bs-reasoning {
        margin: 0 0 0.6rem;
        font-size: var(--fs-sm);
        color: var(--ink);
        line-height: 1.45;
        font-style: italic;
    }
    .bs-comp-note {
        margin: 0.2rem 0 0;
        font-size: var(--fs-sm);
        color: var(--ink);
        line-height: 1.45;
    }
</style>
