<script lang="ts">
    // The `firb-workflow-card` renderer (constraint #7 vocabulary, Mode B) — named by TWO
    // outcome shapes (the engine reuses "firb-workflow-card" for both — no new renderer):
    //
    //  • firb_status (firb_workflow, blueprint §4) — the FIRB approval state machine, the
    //    mandatory gate before contract signing. `blocking_for_contract` is the critical
    //    downstream gate (buying_strategy/settlement_prep read it, not this card).
    //  • transfer_plan (cross_border_funding, blueprint §7) — used here "as a state-machine
    //    renderer for the transfer workflow" (the blueprint's own words): provider + amounts
    //    + dates. The step/compliance/critical-path sub-lists ride the SIBLING `checklist`
    //    renderer this component also composes (Checklist.svelte's third shape), matching
    //    the blueprint's explicit dual-renderer line.
    //
    // Shape-discriminate on a unique field (the DataTable isTax/isPortfolio precedent):
    // transfer_plan is the only shape carrying `total_transfer_amount_aud`.
    //
    // Producers closed (mode-b-wedge.md P2 slices 2+6); no live turn reaches this yet (P5).
    // No engine bilingual {vi,en} prose in either shape (grounded against fh_engine_firb.erl
    // / fh_engine_cross_border.erl directly) — every array is a snake_case CODE; closed-set
    // $t + raw-fallback humanize.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { type FirbStatusOutcome, type TransferPlanOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import Pending from './Pending.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const isTransfer = $derived('total_transfer_amount_aud' in (outcome ?? {}));

    function humanize(v: string): string {
        return v.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
    }

    // --- firb_status ------------------------------------------------------------
    const f = $derived(outcome as FirbStatusOutcome);

    const STAGE = new Set([
        'not_started', 'in_preparation', 'submitted', 'under_review',
        'approved', 'approved_with_conditions', 'rejected', 'withdrawn'
    ]);
    const STAGE_TONE: Record<string, 'good' | 'warn' | 'info' | 'neutral'> = {
        not_started: 'neutral',
        in_preparation: 'info',
        submitted: 'info',
        under_review: 'info',
        approved: 'good',
        approved_with_conditions: 'good',
        rejected: 'warn',
        withdrawn: 'warn'
    };
    function stageLabel(v: string | null | undefined): string {
        if (!v) return '';
        return STAGE.has(v) ? $t(`plan.firb.stage.${v}` as 'plan.firb.stage.not_started') : humanize(v);
    }

    const TIER = new Set(['under_1m', '1m_to_2m', '2m_to_3m', '3m_to_5m', 'over_5m']);
    function tierLabel(v: string | null | undefined): string {
        if (!v) return '';
        return TIER.has(v) ? $t(`plan.firb.tier.${v}` as 'plan.firb.tier.under_1m') : humanize(v);
    }

    const DOC = new Set([
        'passport_au_member', 'passport_vn_funder_if_applicable', 'visa_grant_evidence',
        'property_details_contract_or_listing', 'source_of_funds_evidence', 'vendor_or_developer_details'
    ]);
    function docLabel(v: string): string {
        return DOC.has(v) ? $t(`plan.firb.doc.${v}` as 'plan.firb.doc.passport_au_member') : humanize(v);
    }

    const conditions = $derived(f.approval_conditions ?? []);
    const outstanding = $derived(f.documents_outstanding ?? []);

    // --- transfer_plan ------------------------------------------------------------
    const tp = $derived(outcome as TransferPlanOutcome);

    const PROVIDER = new Set([
        'wise', 'ofx', 'bank_wire_anz', 'bank_wire_cba', 'bank_wire_nab', 'bank_wire_westpac', 'other'
    ]);
    function providerLabel(v: string | null | undefined): string | null {
        if (!v) return null;
        return PROVIDER.has(v) ? $t(`plan.transfer.provider.${v}` as 'plan.transfer.provider.wise') : humanize(v);
    }
</script>

{#if isTransfer}
    <!-- ── transfer_plan (cross_border_funding) ─────────────────────────── -->
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.provider')}</span>
        {#if providerLabel(tp.provider)}
            <Chip label={providerLabel(tp.provider) ?? ''} tone="info" />
        {:else}
            <Pending />
        {/if}
    </div>
    <Field label={$t('plan.f.transfer_amount')} value={money(tp.total_transfer_amount_aud, $lang)} />
    <Field label={$t('plan.f.fx_cost')} value={money(tp.estimated_fx_cost, $lang)} />
    <Field label={$t('plan.f.transfer_initiated')} value={tp.transfer_initiated_by_date ?? null} />
    <Field label={$t('plan.f.transfer_received')} value={tp.transfer_received_by_date ?? null} />
{:else}
    <!-- ── firb_status (firb_workflow) ──────────────────────────────────── -->
    {#if f.blocking_for_contract}
        <div class="fw-blocking">
            <p class="fw-blocking-body">{$t('plan.firb.blocking')}</p>
        </div>
    {/if}

    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.stage')}</span>
        {#if f.current_stage}
            <Chip label={stageLabel(f.current_stage)} tone={STAGE_TONE[f.current_stage] ?? 'neutral'} />
        {:else}
            <Pending />
        {/if}
    </div>

    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.eligible')}</span>
        {#if typeof f.foreign_person_eligible === 'boolean'}
            <Chip
                label={f.foreign_person_eligible ? $t('plan.firb.yes') : $t('plan.firb.no')}
                tone={f.foreign_person_eligible ? 'good' : 'warn'}
            />
        {:else}
            <Pending />
        {/if}
    </div>

    <Field label={$t('plan.f.firb_fee')} value={money(f.total_firb_fee_payable, $lang)} />
    <Field label={$t('plan.f.fee_tier')} value={f.firb_fee_tier ? tierLabel(f.firb_fee_tier) : null} />

    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.approval_received')}</span>
        {#if typeof f.approval_received === 'boolean' && f.approval_received}
            <Chip label={$t('plan.firb.yes')} tone="good" />
        {:else}
            <Pending />
        {/if}
    </div>

    <Field
        label={$t('plan.f.days_to_decision')}
        value={typeof f.days_to_expected_decision === 'number' ? String(f.days_to_expected_decision) : null}
    />

    {#if conditions.length}
        <div class="pp-sublist">
            <span class="pp-label">{$t('plan.f.approval_conditions')}</span>
            {#each conditions as c, i (i)}
                <p class="fw-item">{humanize(c)}</p>
            {/each}
        </div>
    {/if}

    {#if outstanding.length}
        <div class="pp-sublist">
            <span class="pp-label">{$t('plan.f.documents_outstanding')}</span>
            {#each outstanding as d, i (i)}
                <p class="fw-item">{docLabel(d)}</p>
            {/each}
        </div>
    {/if}
{/if}

<style>
    .fw-blocking {
        margin: 0 0 0.6rem;
        padding: 0.6rem 0.75rem;
        border-left: 3px solid #b91c1c;
        background: #fef2f2;
        border-radius: 0 0.4rem 0.4rem 0;
    }
    .fw-blocking-body {
        margin: 0;
        font-size: 0.82rem;
        font-weight: 600;
        color: #b91c1c;
        line-height: 1.45;
    }
    .fw-item {
        margin: 0.2rem 0 0;
        font-size: 0.8rem;
        color: var(--ink);
        line-height: 1.4;
    }
</style>
