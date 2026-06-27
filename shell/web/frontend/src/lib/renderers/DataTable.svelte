<script lang="ts">
    // The `data-table` renderer — ownership_planning (ongoing_obligations): the cost
    // of holding the home. At base scope this is honest-partial — the statutory band
    // (council + water) and land-tax status are knowable; mortgage-dominated monthly /
    // annual outgoings need a firm loan, so they show Pending until a property is
    // attached.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type OngoingObligationsOutcome, type TaxOptimisedStructureOutcome } from '$lib/planCard';
    import { money, moneyRange, num } from '$lib/format';
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

    // `data-table` is named by two unrelated outcome shapes. Shape-discriminate so the rich
    // producer isn't dropped (the Slice-4 Checklist lesson): tax_structure → tax_optimised_structure
    // (the investor tax cluster + the NG reform note); else the ownership ongoing_obligations view.
    const isTax = $derived('cgt_discount_eligible' in outcome && 'recommended_entity' in outcome);
    const tx = $derived(outcome as TaxOptimisedStructureOutcome);
    // The reform note (the headline of this view) is the engine's bilingual {vi,en}; never recomputed.
    const reformNote = $derived(pick(tx.negative_gearing_reform_note, $lang));
    // The recommended ownership entity is a closed enum; guard the $t lookup (a producer-renamed id
    // degrades to the raw value, not a crash) and surface the "confirm with a tax agent" copy at base.
    const ENTITY = new Set([
        'personal_sole', 'personal_joint', 'discretionary_trust', 'unit_trust',
        'company', 'smsf', 'smsf_with_lrba'
    ]);
    const entityLabel = $derived.by(() => {
        const e = tx.recommended_entity;
        if (!e) return $t('plan.tx.entity_pending');
        return ENTITY.has(e) ? $t(`plan.entity.${e}` as 'plan.entity.personal_sole') : e;
    });
    const marginalRate = $derived(tx.cgt_marginal_rate != null ? `${num(tx.cgt_marginal_rate, $lang)}%` : null);
    const afterTaxCf = $derived(moneyRange(tx.after_tax_cash_flow_year_1, $lang));

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

    // The "graduation" event (point 6) — when LVR crosses the target, the FHG falls away
    // and a no-LMI refinance window opens. Year is PENDING until a loan/savings fact.
    const grad = $derived(o.graduation_milestone ?? null);
    const gradBody = $derived(
        grad ? $t('plan.grad.body').replace('{lvr}', String(grad.target_lvr ?? 80)) : ''
    );
</script>

{#if isTax}
<!-- ── tax_structure (tax_optimised_structure) ────────────────────────── -->
{#if reformNote}
    <div class="tx-reform">
        <span class="tx-reform-title">{$t('plan.tx.reform_title')}</span>
        <p class="tx-reform-body">{reformNote}</p>
    </div>
{/if}
<Field label={$t('plan.tx.entity')} value={entityLabel} />
<div class="pp-field">
    <span class="pp-label">{$t('plan.tx.gearing')}</span>
    {#if tx.negative_gearing_active === true}
        <Chip label={$t('plan.tx.geared_negative')} tone="info" />
    {:else}
        <Pending />
    {/if}
</div>
<Field label={$t('plan.tx.marginal_rate')} value={marginalRate} />
<Field label={$t('plan.tx.after_tax_cf')} value={afterTaxCf} />

{:else}
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

{#if grad}
    <div class="og-grad">
        <span class="og-grad-title">{$t('plan.grad.title')}</span>
        <p class="og-grad-body">{gradBody}</p>
        {#if typeof grad.estimated_year === 'number'}
            <p class="og-grad-year">{$t('plan.grad.year')} {grad.estimated_year}</p>
        {:else}
            <p class="og-grad-year og-grad-pending">{$t('plan.grad.year_pending')}</p>
        {/if}
    </div>
{/if}

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
{/if}

<style>
    /* The negative-gearing reform note — a calm caveat highlight (proposed, not law). */
    .tx-reform {
        margin: 0 0 0.6rem;
        padding: 0.6rem 0.75rem;
        border-left: 3px solid var(--accent);
        background: var(--accent-soft, #fff7ed);
        border-radius: 0 0.4rem 0.4rem 0;
    }
    .tx-reform-title {
        font-size: 0.8rem;
        font-weight: 700;
        color: var(--accent);
    }
    .tx-reform-body {
        margin: 0.25rem 0 0;
        font-size: 0.82rem;
        color: var(--ink);
        line-height: 1.45;
    }
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
    /* The graduation milestone — a calm highlight (the prototype's callout). */
    .og-grad {
        margin: 0.7rem 0 0.4rem;
        padding: 0.6rem 0.75rem;
        border-left: 3px solid var(--accent);
        background: var(--accent-soft, #fff7ed);
        border-radius: 0 0.4rem 0.4rem 0;
    }
    .og-grad-title {
        font-size: 0.8rem;
        font-weight: 700;
        color: var(--accent);
    }
    .og-grad-body {
        margin: 0.25rem 0 0;
        font-size: 0.82rem;
        color: var(--ink);
        line-height: 1.45;
    }
    .og-grad-year {
        margin: 0.3rem 0 0;
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--ink);
    }
    .og-grad-pending {
        font-weight: 400;
        font-style: italic;
        color: var(--muted);
    }
</style>
