<script lang="ts">
    // The onboarding sheet (8-S3b): entered from a map suburb's planning tab, so the
    // state + zone arrive pre-filled (plan cards pin to a zone, §7). It captures the
    // Wedge-1a Mode-A set — a mode-qualifying gate (citizen/PR + first home,
    // constraint #10) then a target budget band — and POSTs the plan-first payload
    // (constraint #1). Mobile-native: one decision per step, big tap targets, the
    // primary action in the thumb zone, calm terminal states (§7.1). The base plan
    // itself renders later, in the Plan tab (8-S4).
    import { createPlanCard } from '$lib/api';
    import { BUDGET_BANDS, buildOnboardingInput, type BudgetBand } from '$lib/onboarding';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';

    let { stateCode, suburbName, onclose, onsignin }: {
        stateCode: string;
        suburbName: string;
        onclose: () => void;
        onsignin: () => void;
    } = $props();

    let citizenPr = $state<boolean | null>(null);
    let firstHome = $state<boolean | null>(null);
    let band = $state<BudgetBand | null>(null);
    let phase = $state<'form' | 'submitting' | 'created' | 'auth' | 'error'>('form');

    const gateAnswered = $derived(citizenPr !== null && firstHome !== null);
    const eligible = $derived(citizenPr === true && firstHome === true);
    const canSubmit = $derived(eligible && band !== null && phase === 'form');

    const nf = $derived(
        new Intl.NumberFormat($lang === 'vi' ? 'vi-VN' : 'en-AU', {
            style: 'currency',
            currency: 'AUD',
            maximumFractionDigits: 0
        })
    );
    function bandLabel(b: BudgetBand): string {
        return b.lo === 0
            ? `${$t('onboarding.budget.under')} ${nf.format(b.hi)}`
            : `${nf.format(b.lo)} – ${nf.format(b.hi)}`;
    }

    async function submit() {
        if (band === null) return;
        phase = 'submitting';
        const outcome = await createPlanCard(
            buildOnboardingInput(stateCode, suburbName, band)
        );
        phase =
            outcome.kind === 'created' ? 'created'
            : outcome.kind === 'auth_required' ? 'auth'
            : 'error';
    }
</script>

<div class="ob-backdrop">
<div class="onboarding" role="dialog" aria-modal="true" aria-label={suburbName}>
    <header class="ob-head">
        <h2>{$t('onboarding.title')} {suburbName}</h2>
        <button type="button" class="close" onclick={onclose} aria-label={$t('sheet.close')}
            >✕</button
        >
    </header>

    {#if phase === 'created'}
        <div class="ob-terminal">
            <h3>{$t('onboarding.created.title')}</h3>
            <p>{$t('onboarding.created.body')}</p>
            <button type="button" class="primary" onclick={onclose}>{$t('sheet.close')}</button>
        </div>
    {:else if phase === 'auth'}
        <div class="ob-terminal">
            <h3>{$t('onboarding.auth.title')}</h3>
            <p>{$t('onboarding.auth.body')}</p>
            <button type="button" class="primary" onclick={onsignin}
                >{$t('onboarding.auth.cta')}</button
            >
        </div>
    {:else}
        <div class="ob-body">
            <!-- Mode-A gate (constraint #10) — two taps. -->
            <fieldset class="gate">
                <legend>{$t('onboarding.gate.citizen')}</legend>
                <div class="choice">
                    <button
                        type="button"
                        class:active={citizenPr === true}
                        aria-pressed={citizenPr === true}
                        onclick={() => (citizenPr = true)}>{$t('onboarding.yes')}</button
                    >
                    <button
                        type="button"
                        class:active={citizenPr === false}
                        aria-pressed={citizenPr === false}
                        onclick={() => (citizenPr = false)}>{$t('onboarding.no')}</button
                    >
                </div>
            </fieldset>

            <fieldset class="gate">
                <legend>{$t('onboarding.gate.firsthome')}</legend>
                <div class="choice">
                    <button
                        type="button"
                        class:active={firstHome === true}
                        aria-pressed={firstHome === true}
                        onclick={() => (firstHome = true)}>{$t('onboarding.yes')}</button
                    >
                    <button
                        type="button"
                        class:active={firstHome === false}
                        aria-pressed={firstHome === false}
                        onclick={() => (firstHome = false)}>{$t('onboarding.no')}</button
                    >
                </div>
            </fieldset>

            {#if gateAnswered && !eligible}
                <!-- Out of Wedge-1a scope — calm, not an error (§7.1). -->
                <p class="ob-note">{$t('onboarding.outofscope')}</p>
            {:else if eligible}
                <fieldset class="budget">
                    <legend>{$t('onboarding.budget.label')}</legend>
                    <div class="bands">
                        {#each BUDGET_BANDS as b (b.hi)}
                            <button
                                type="button"
                                class:active={band === b}
                                aria-pressed={band === b}
                                onclick={() => (band = b)}>{bandLabel(b)}</button
                            >
                        {/each}
                    </div>
                    <p class="ob-hint">{$t('onboarding.budget.note')}</p>
                </fieldset>
            {/if}

            {#if phase === 'error'}
                <p class="ob-error">{$t('onboarding.error')}</p>
            {/if}
        </div>

        <footer class="ob-foot">
            <button type="button" class="primary" disabled={!canSubmit} onclick={submit}>
                {phase === 'submitting' ? $t('onboarding.submitting') : $t('onboarding.submit')}
            </button>
        </footer>
    {/if}
</div>
</div>
