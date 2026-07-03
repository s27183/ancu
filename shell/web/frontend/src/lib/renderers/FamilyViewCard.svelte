<script lang="ts">
    // The `family-view-card` renderer (constraint #7 vocabulary, Mode B) — family_context's
    // cross-border funding plan (outcome `family_funding_plan`): who contributes how much
    // from where, and who holds decision authority. Enables the Family view tab.
    //
    // Producer closed (mode-b-wedge.md P2 slice 6, fh_engine_family.erl): every leaf is
    // genuinely user-input, so the base-turn job is aggregate-and-score-what's-captured,
    // not compute — at base (no funder captured) everything is honestly empty/null.
    // No live turn reaches this yet (P5, base_components/1 has no Mode-B clause). None of
    // the array fields carry engine bilingual {vi,en} prose (grounded against the .erl
    // source directly) — they're snake_case codes; the shell owns the code→label lookup
    // (closed-set $t + raw-fallback humanize, mirroring BuyingStrategyCard's thesisLabel).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { type FamilyFundingPlanOutcome, type ContributionLine } from '$lib/planCard';
    import { money } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import Pending from './Pending.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as FamilyFundingPlanOutcome);
    const breakdown = $derived(o.contribution_breakdown ?? []);

    const RELATIONSHIP = new Set([
        'spouse', 'de_facto', 'parent', 'sibling', 'other_family', 'self_funding', 'none'
    ]);
    function humanize(v: string): string {
        return v.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
    }
    function partyLabel(v: string | null | undefined): string {
        if (!v) return '';
        return RELATIONSHIP.has(v) ? $t(`plan.family.relationship.${v}` as 'plan.family.relationship.parent') : humanize(v);
    }

    const AUTHORITY = new Set(['au_member', 'vn_parent', 'joint', 'family_council']);
    const authorityLabel = $derived.by(() => {
        const a = o.decision_authority;
        if (!a) return null;
        return AUTHORITY.has(a) ? $t(`plan.family.authority.${a}` as 'plan.family.authority.joint') : humanize(a);
    });

    const GAP = new Set(['funding_source_and_documentation_pending']);
    function gapLabel(v: string): string {
        return GAP.has(v) ? $t(`plan.family.gap.${v}` as 'plan.family.gap.funding_source_and_documentation_pending') : humanize(v);
    }

    const gaps = $derived(o.documentation_gaps ?? []);
</script>

<!-- ── Family capacity hero ───────────────────────────────────────────── -->
<div class="pp-field">
    <span class="pp-label">{$t('plan.f.family_capacity')}</span>
    {#if typeof o.total_capacity_aud === 'number'}
        <span class="fv-capacity">{money(o.total_capacity_aud, $lang)}</span>
    {:else}
        <Pending />
    {/if}
</div>

<!-- contributions -->
{#if breakdown.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.contributions')}</span>
        {#each breakdown as c, i (i)}
            <div class="fv-contrib">
                <div class="fv-contrib-head">
                    {#if c.party}<Chip label={partyLabel(c.party)} tone="info" />{/if}
                    {#if typeof c.amount_aud === 'number'}
                        <span class="fv-contrib-amt">{money(c.amount_aud, $lang)}</span>
                    {/if}
                    {#if c.currency_origin}<span class="fv-contrib-ccy">{c.currency_origin}</span>{/if}
                </div>
            </div>
        {/each}
    </div>
{:else}
    <p class="fv-none">{$t('plan.family.none')}</p>
{/if}

<Field label={$t('plan.f.decision_authority')} value={authorityLabel} />

<div class="pp-field">
    <span class="pp-label">{$t('plan.f.bilingual_coordination')}</span>
    <Chip
        label={o.bilingual_coordination_required ? $t('plan.family.bilingual_yes') : $t('plan.family.bilingual_no')}
        tone={o.bilingual_coordination_required ? 'info' : 'neutral'}
    />
</div>

<Field
    label={$t('plan.f.complexity')}
    value={typeof o.funding_complexity_score === 'number' ? `${o.funding_complexity_score}/10` : null}
/>

{#if gaps.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.doc_gaps')}</span>
        {#each gaps as g, i (i)}
            <p class="fv-gap">{gapLabel(g)}</p>
        {/each}
    </div>
{/if}

<style>
    .fv-capacity {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    .fv-contrib {
        padding: 0.35rem 0;
        border-top: 1px solid var(--border);
    }
    .fv-contrib-head {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        flex-wrap: wrap;
    }
    .fv-contrib-amt {
        font-size: 0.85rem;
        font-weight: 600;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    .fv-contrib-ccy {
        font-size: 0.7rem;
        color: var(--muted);
    }
    .fv-none {
        font-size: 0.82rem;
        font-style: italic;
        color: var(--muted);
        margin: 0;
    }
    .fv-gap {
        margin: 0.2rem 0 0;
        font-size: 0.8rem;
        color: var(--muted);
        line-height: 1.4;
    }
</style>
