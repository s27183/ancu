<script lang="ts">
    // The onboarding sheet (8-S3b): entered from a map suburb's planning tab, so the
    // state + zone arrive pre-filled (plan cards pin to a zone, §7). It captures the
    // domestic set — the intent choice (owner_occupier → Mode A / investment → Mode C),
    // a mode-qualifying gate (citizen/PR, plus first-home for owner-occupiers only,
    // constraint #10), then a target budget band — and POSTs the plan-first payload
    // (constraint #1). Mobile-native: one decision per step, big tap targets, the
    // primary action in the thumb zone, calm terminal states (§7.1). The base plan
    // itself renders later, in the Plan tab (8-S4).
    import { createPlanCard } from '$lib/api';
    import { BUDGET_BANDS, buildOnboardingInput, type BudgetBand, type Intent } from '$lib/onboarding';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';

    let { stateCode, suburbName, suburbSal, onclose, onsignin, oncreated }: {
        stateCode: string;
        suburbName: string;
        suburbSal: string;
        onclose: () => void;
        onsignin: () => void;
        /** The plan card was created — close the modal and reveal it in the Plan tab. */
        oncreated: () => void;
    } = $props();

    let intent = $state<Intent | null>(null);
    let citizenPr = $state<boolean | null>(null);
    let firstHome = $state<boolean | null>(null);
    let band = $state<BudgetBand | null>(null);
    let phase = $state<'form' | 'submitting' | 'created' | 'auth' | 'error'>('form');

    // The gate branches on intent (mode-c-wedge.md P5-activate): owner_occupier still
    // requires a first-home answer (Mode A); investment needs only citizen/PR (Mode C —
    // first-home is meaningless for an investor). The "citizen/PR yes · not first home ·
    // live-in" cell is the Mode-E next-home gap, out of scope (calm note, not an error).
    const ooNeedsFirstHome = $derived(intent === 'owner_occupier');
    const gateAnswered = $derived(
        intent !== null && citizenPr !== null && (!ooNeedsFirstHome || firstHome !== null)
    );
    const eligible = $derived(
        intent !== null &&
            citizenPr === true &&
            (intent === 'investment' || firstHome === true)
    );
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
        if (band === null || intent === null) return;
        phase = 'submitting';
        const outcome = await createPlanCard(
            buildOnboardingInput(stateCode, suburbName, suburbSal, band, intent)
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
            <button type="button" class="primary" onclick={oncreated}>{$t('onboarding.created.cta')}</button>
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
            <!-- Intent first — it decides which gate questions apply (P5-activate). -->
            <fieldset class="gate">
                <legend>{$t('onboarding.intent.label')}</legend>
                <div class="choice">
                    <button
                        type="button"
                        class:active={intent === 'owner_occupier'}
                        aria-pressed={intent === 'owner_occupier'}
                        onclick={() => (intent = 'owner_occupier')}>{$t('onboarding.intent.live')}</button
                    >
                    <button
                        type="button"
                        class:active={intent === 'investment'}
                        aria-pressed={intent === 'investment'}
                        onclick={() => (intent = 'investment')}>{$t('onboarding.intent.invest')}</button
                    >
                </div>
            </fieldset>

            <!-- Domestic gate (constraint #10) — citizen/PR applies to both modes. -->
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

            {#if ooNeedsFirstHome}
                <!-- First-home gate is Mode-A only — meaningless for an investor (Mode C). -->
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
            {/if}

            {#if gateAnswered && !eligible}
                <!-- Out of scope — calm, not an error (§7.1). Two distinct reasons:
                     foreign (Mode B/D) vs domestic next-home owner-occupier (Mode-E gap). -->
                <p class="ob-note">
                    {citizenPr === false
                        ? $t('onboarding.outofscope.foreign')
                        : $t('onboarding.outofscope')}
                </p>
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
