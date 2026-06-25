<script lang="ts">
    // The `opportunity-card` renderer (constraint #7 vocabulary) — the alerts /
    // recommendations slice of ownership_planning_investor: modelled opportunities to act
    // on (rent review, refinance to release equity, scale-up), each a { kind,
    // modeled_benefit, action }. Decision-support: it surfaces the option + its modelled
    // benefit; the user decides and acts.
    //
    // Producer half closed (mode-c-wedge P5-engine 6): portfolio_position now declares + emits
    // opportunities[] ([] at base — populates per-property in Phase B). Consumer half remains:
    // ComponentCard renders only renderers[0] (data-table), so this card is unreached until
    // dual-renderer support lands (a shell unit). Built against the §11.9 renderer contract;
    // list-tolerant + honest-partial.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type OpportunityCardOutcome, type Opportunity } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import Chip from './Chip.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as OpportunityCardOutcome);

    // list-tolerant: accept opportunities[] or a single { kind, modeled_benefit, action }.
    const items: Opportunity[] = $derived(
        Array.isArray(o.opportunities)
            ? o.opportunities
            : o.kind || o.action || o.modeled_benefit != null
              ? [o]
              : []
    );

    // kind is an open producer enum (no closed blueprint set) → humanize the raw value
    // language-neutrally rather than fabricate a bilingual label (raw-fallback convention).
    function kindLabel(k: string | null | undefined): string {
        if (!k) return '';
        return k.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
    }
    function benefit(v: Opportunity['modeled_benefit']): string | null {
        return Array.isArray(v) ? moneyRange(v, $lang) : money(v ?? null, $lang);
    }
</script>

{#if items.length}
    <ul class="op-list">
        {#each items as op, i (i)}
            <li class="op-item">
                <div class="op-head">
                    {#if op.kind}<Chip label={kindLabel(op.kind)} tone="info" />{/if}
                    {#if benefit(op.modeled_benefit)}
                        <span class="op-benefit">
                            <span class="op-benefit-label">{$t('plan.f.modeled_benefit')}</span>
                            {benefit(op.modeled_benefit)}
                        </span>
                    {/if}
                </div>
                {#if pick(op.action, $lang)}
                    <p class="op-action">{pick(op.action, $lang)}</p>
                {/if}
            </li>
        {/each}
    </ul>
{:else}
    <p class="op-none">{$t('plan.opp.none')}</p>
{/if}

<style>
    .op-list {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .op-item {
        padding: 0.5rem 0.6rem;
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        border-left: 3px solid var(--accent);
    }
    .op-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
        flex-wrap: wrap;
    }
    .op-benefit {
        font-size: 0.8rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .op-benefit-label {
        font-size: 0.7rem;
        font-weight: 400;
        color: var(--muted);
        margin-right: 0.25rem;
    }
    .op-action {
        margin: 0.3rem 0 0;
        font-size: 0.82rem;
        color: var(--ink);
        line-height: 1.45;
    }
    .op-none {
        font-size: 0.82rem;
        font-style: italic;
        color: var(--muted);
        margin: 0;
    }
</style>
