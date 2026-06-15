<script lang="ts">
    // The `calculator` renderer — cash_position (budget_envelope). The cash-to-close
    // math: stamp duty (before/after concession), what's required vs available, the
    // gap, and the two distinct verdicts (cash sufficiency vs the lender's genuine-
    // savings test — F5, deliberately separate). All figures are resolver-computed and
    // single-valued (§98: no LLM-authored money); we only format them.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import type { BudgetEnvelopeOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as BudgetEnvelopeOutcome);

    const VERDICTS: Record<string, 'good' | 'warn'> = {
        surplus: 'good',
        tight: 'warn',
        short: 'warn'
    };
    const GSV: Record<string, 'good' | 'warn' | 'neutral'> = {
        meets: 'good',
        fails_recent_gift: 'warn',
        insufficient_track_record: 'warn',
        unknown: 'neutral'
    };
    function verdictLabel(v: string): string {
        return v in VERDICTS ? $t(`plan.verdict.${v}` as 'plan.verdict.short') : v;
    }
    function gsvLabel(v: string): string {
        return v in GSV ? $t(`plan.gsv.${v}` as 'plan.gsv.unknown') : v;
    }
</script>

{#if o.stamp_duty}
    <Field label={$t('plan.f.duty_before')} value={money(o.stamp_duty.before_concession, $lang)} />
    <Field label={$t('plan.f.duty_after')} value={money(o.stamp_duty.after_concession, $lang)} />
    <NoteList notes={o.stamp_duty.notes} />
{:else}
    <Field label={$t('plan.f.stamp_duty')} value={null} />
{/if}

<Field label={$t('plan.f.max_price')} value={money(o.max_property_price_supported, $lang)} />
<Field label={$t('plan.f.cash_required')} value={money(o.total_cash_required, $lang)} />
<Field label={$t('plan.f.cash_available')} value={money(o.cash_available, $lang)} />

{#if typeof o.gap_or_surplus === 'number'}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.gap')}</span>
        <span class="pp-value" class:pp-neg={o.gap_or_surplus < 0}>{money(o.gap_or_surplus, $lang)}</span>
    </div>
{:else}
    <Field label={$t('plan.f.gap')} value={null} />
{/if}

{#if o.verdict}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.verdict')}</span>
        <Chip label={verdictLabel(o.verdict)} tone={VERDICTS[o.verdict] ?? 'neutral'} />
    </div>
{/if}
{#if o.genuine_savings_verdict}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.genuine_savings')}</span>
        <Chip label={gsvLabel(o.genuine_savings_verdict)} tone={GSV[o.genuine_savings_verdict] ?? 'neutral'} />
    </div>
{/if}

{#if o.mitigation_options_if_short?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.mitigation')}</span>
        <ul>
            {#each o.mitigation_options_if_short as m, i (i)}
                <li>{m}</li>
            {/each}
        </ul>
    </div>
{/if}

<NoteList heading={$t('plan.f.assumptions')} notes={o.key_assumptions} />
