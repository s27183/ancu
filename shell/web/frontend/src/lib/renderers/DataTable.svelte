<script lang="ts">
    // The `data-table` renderer — ownership_planning (ongoing_obligations): the cost
    // of holding the home. At base scope this is honest-partial — the statutory band
    // (council + water) and land-tax status are knowable; mortgage-dominated monthly /
    // annual outgoings need a firm loan, so they show Pending until a property is
    // attached.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type OngoingObligationsOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import StackedBar from './StackedBar.svelte';

    let { outcome, density = 'compact' }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
    } = $props();
    const o = $derived(outcome as OngoingObligationsOutcome);

    const LAND_TAX: Record<string, 'good' | 'info' | 'neutral'> = {
        exempt_ppor: 'good',
        applicable: 'info',
        to_verify: 'neutral'
    };
    function landTaxLabel(v: string): string {
        return v in LAND_TAX ? $t(`plan.landtax.${v}` as 'plan.landtax.to_verify') : v;
    }

    const band = $derived(o.recurring_costs_estimate?.statutory_band ?? null);
    const statutory = $derived.by(() => {
        if (!band) return null;
        const lo = money(band.low, $lang);
        const hi = money(band.high, $lang);
        if (lo === null && hi === null) return null;
        if (lo === null) return hi;
        if (hi === null) return lo;
        return `${lo} – ${hi}`;
    });

    // Outgoings hero (plan-card-visual-spec §3.5): a segmented bar of the recurring cost
    // lines. At base only the statutory band (council + water) is knowable; strata /
    // utilities / building insurance need a property → hatched (counted, not sized). The
    // monthly total is mortgage-dominated → Pending until a loan. Reuses StackedBar (R1/R2).
    const num2 = (v: number | null | undefined): v is number => typeof v === 'number';
    const bandMid = $derived(num2(band?.low) && num2(band?.high) ? (band!.low! + band!.high!) / 2 : null);
    const rc = $derived(o.recurring_costs_estimate ?? null);
    const outSegments = $derived([
        { value: bandMid, label: $t('plan.f.statutory'), amount: statutory ?? '—', estimate: true },
        { value: rc?.strata_levies ?? null, label: $t('plan.f.strata'),
          amount: money(rc?.strata_levies, $lang) ?? '—', estimate: false },
        { value: rc?.utilities ?? null, label: $t('plan.f.utilities'),
          amount: money(rc?.utilities, $lang) ?? '—', estimate: false },
        { value: rc?.building_insurance ?? null, label: $t('plan.f.insurance'),
          amount: money(rc?.building_insurance, $lang) ?? '—', estimate: false }
    ]);
    const monthly = $derived(money(o.total_monthly_outgoings_estimate, $lang));
</script>

<!-- ── Outgoings hero ─────────────────────────────────────────────────── -->
<div class="og-hero">
    <div class="og-head">
        <span class="og-label">{$t('plan.f.monthly')}</span>
        {#if monthly}<span class="og-total">{monthly}</span>{:else}<Pending />{/if}
    </div>
    <StackedBar segments={outSegments} {density} />
</div>

<Field label={$t('plan.f.statutory')} value={statutory} />

{#if o.land_tax_check}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.land_tax')}</span>
        <Chip label={landTaxLabel(o.land_tax_check)} tone={LAND_TAX[o.land_tax_check] ?? 'neutral'} />
    </div>
{:else}
    <Field label={$t('plan.f.land_tax')} value={null} />
{/if}

<Field label={$t('plan.f.maintenance')} value={money(o.maintenance_reserve_target, $lang)} />
<Field label={$t('plan.f.monthly')} value={money(o.total_monthly_outgoings_estimate, $lang)} />
<Field label={$t('plan.f.annual')} value={money(o.total_annual_outgoings_estimate, $lang)} />

<NoteList notes={o.recurring_costs_estimate?.notes} />

{#if o.alert_triggers_armed?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.alerts')}</span>
        {#each o.alert_triggers_armed as a, i (i)}
            {#if pick(a.trigger, $lang) || pick(a.action, $lang)}
                <div class="pp-alert">
                    {#if pick(a.trigger, $lang)}<span class="pp-alert-trigger">{pick(a.trigger, $lang)}</span>{/if}
                    {#if pick(a.action, $lang)}<span class="pp-alert-action">{pick(a.action, $lang)}</span>{/if}
                </div>
            {/if}
        {/each}
    </div>
{/if}

<style>
    .og-hero {
        margin-bottom: 0.6rem;
    }
    .og-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .og-label {
        font-size: 0.85rem;
        color: var(--muted);
    }
    .og-total {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
</style>
