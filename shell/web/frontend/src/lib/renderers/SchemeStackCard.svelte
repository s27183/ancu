<script lang="ts">
    // The `scheme-stack-card` renderer — eligibility (scheme_stack). Stacks the
    // schemes the buyer can use (name + benefit + engine notes), what's rejected and
    // why, and the combined-benefit + stacking constraints. Honest-partial: empty
    // lists render nothing; a null basis shows Pending.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type SchemeStackOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as SchemeStackOutcome);

    const BASES: Record<string, 'good' | 'warn' | 'neutral'> = {
        all_applicants_eligible: 'good',
        eligible_only_if_restructured: 'warn',
        ineligible: 'warn'
    };
    function basisLabel(b: string): string {
        return b in BASES ? $t(`plan.basis.${b}` as 'plan.basis.ineligible') : b;
    }
</script>

{#if o.eligibility_basis}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.basis')}</span>
        <Chip label={basisLabel(o.eligibility_basis)} tone={BASES[o.eligibility_basis] ?? 'neutral'} />
    </div>
{:else}
    <Field label={$t('plan.f.basis')} value={null} />
{/if}

{#if o.applicable_schemes?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.applicable_schemes')}</span>
        {#each o.applicable_schemes as s, i (i)}
            <div class="pp-scheme">
                <div class="pp-scheme-head">
                    {#if s.name}<span class="pp-scheme-name">{s.name}</span>{/if}
                    {#if money(s.benefit_value, $lang)}
                        <span class="pp-scheme-benefit">{money(s.benefit_value, $lang)}</span>
                    {/if}
                </div>
                <NoteList notes={s.notes} />
            </div>
        {/each}
    </div>
{/if}

<Field label={$t('plan.f.total_benefit')} value={money(o.total_benefit_value, $lang)} />

{#if o.rejected_schemes?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.rejected_schemes')}</span>
        {#each o.rejected_schemes as r, i (i)}
            <div class="pp-scheme muted">
                {#if r.name}<span class="pp-scheme-name">{r.name}</span>{/if}
                {#if pick(r.reason, $lang)}<p class="pp-scheme-why">{pick(r.reason, $lang)}</p>{/if}
            </div>
        {/each}
    </div>
{/if}

<NoteList heading={$t('plan.f.stacking')} notes={o.stacking_constraints} />

{#if o.recommended_application_order?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.order')}</span>
        <ol class="pp-order">
            {#each o.recommended_application_order as step, i (i)}
                <li>{step}</li>
            {/each}
        </ol>
    </div>
{/if}
