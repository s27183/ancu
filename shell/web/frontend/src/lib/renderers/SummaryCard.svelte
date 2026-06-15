<script lang="ts">
    // The `summary-card` renderer (constraint #7 vocabulary). It serves the two base
    // components whose blueprint lists summary-card first: buyer_profile (profile) and
    // mortgage_finance (mortgage_plan). The visual shape (label/value rows + note
    // sections) is the renderer; the field SELECTION per component is the Wedge-1a
    // pragmatic projection (deferred generalization: a blueprint-declared presentation
    // spec — see grounding-checklist 8-S4c).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type ProfileOutcome, type MortgagePlanOutcome } from '$lib/planCard';
    import { money, moneyRange, num } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';

    let { componentId, outcome }: {
        componentId: string;
        outcome: Record<string, unknown>;
    } = $props();

    const profile = $derived(outcome as ProfileOutcome);
    const mortgage = $derived(outcome as MortgagePlanOutcome);

    // recommended_path is a known enum → a display label via $t; unknown values fall
    // back to the raw value so nothing is silently dropped.
    const PATHS = new Set([
        'fhg_backed',
        'lmi_5_to_20',
        'twenty_plus',
        'user_specific_alternative'
    ]);
    function pathLabel(p: string | null | undefined): string | null {
        if (!p) return null;
        return PATHS.has(p) ? $t(`plan.path.${p}` as 'plan.path.fhg_backed') : p;
    }
</script>

{#if componentId === 'buyer_profile'}
    <Field label={$t('plan.f.applicants')} value={num(profile.applicant_count, $lang)} />
    {#if typeof profile.firb_required_any === 'boolean'}
        <div class="pp-field">
            <span class="pp-label">{$t('plan.f.firb')}</span>
            <Chip
                label={profile.firb_required_any ? $t('onboarding.yes') : $t('onboarding.no')}
                tone={profile.firb_required_any ? 'warn' : 'good'}
            />
        </div>
    {:else}
        <Field label={$t('plan.f.firb')} value={null} />
    {/if}
    <Field label={$t('plan.f.income')} value={money(profile.assessable_income, $lang)} />
    <Field
        label={$t('plan.f.capacity')}
        value={moneyRange(profile.approx_borrowing_capacity, $lang)}
    />
    <Field
        label={$t('plan.f.deposit')}
        value={money(profile.deposit_ready_for_purchase_amount, $lang)}
    />
    <Field
        label={$t('plan.f.target_price')}
        value={moneyRange(profile.target_price_range, $lang)}
    />
    <NoteList heading={$t('plan.f.strengths')} notes={profile.key_strengths} />
    <NoteList heading={$t('plan.f.constraints')} notes={profile.key_constraints} />
{:else}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.path')}</span>
        {#if mortgage.recommended_path}
            <Chip label={pathLabel(mortgage.recommended_path) ?? ''} tone="info" />
        {:else}
            <Field label="" value={null} />
        {/if}
    </div>
    <Field
        label={$t('plan.f.capacity')}
        value={moneyRange(mortgage.expected_borrowing_capacity, $lang)}
    />
    {#if mortgage.recommended_lender_shortlist?.length}
        <div class="pp-sublist">
            <span class="pp-label">{$t('plan.f.lenders')}</span>
            {#each mortgage.recommended_lender_shortlist as l, i (i)}
                <div class="pp-lender">
                    {#if l.lender}<span class="pp-lender-name">{l.lender}</span>{/if}
                    {#if pick(l.reasoning, $lang)}
                        <p class="pp-lender-why">{pick(l.reasoning, $lang)}</p>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}
    <NoteList heading={$t('plan.f.preapproval')} notes={mortgage.pre_approval_action_plan} />
    <NoteList heading={$t('plan.f.assumptions')} notes={mortgage.key_assumptions} />
{/if}
