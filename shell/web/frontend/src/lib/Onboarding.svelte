<script lang="ts">
    // The onboarding sheet (8-S3b): entered from a map suburb's planning tab, so the
    // state + zone arrive pre-filled (plan cards pin to a zone, §7). It captures the
    // three mode-derivation axes (engine-contract §9.1) as a mode-qualifying gate: intent
    // (owner_occupier / investment), citizen-PR (domestic / foreign, constraint #10), and
    // — for owner_occupier only — first-home (first_home / next_home, mode-e-wedge.md P5).
    // Together these select one of Mode A/B/C/D/E's blueprints (or fail the gate calmly
    // for the one still-out-of-scope cell), then a target budget band — and POSTs the
    // plan-first payload (constraint #1). Mobile-native: one decision per step, big tap
    // targets, the primary action in the thumb zone, calm terminal states (§7.1). The
    // base plan itself renders later, in the Plan tab (8-S4).
    import { createPlanCard } from '$lib/api';
    import {
        BUDGET_BANDS,
        buildOnboardingInput,
        type BudgetBand,
        type BuyerStage,
        type Intent
    } from '$lib/onboarding';
    import { t } from '$lib/i18n';
    import { STATE_NAMES, type AuState } from '$lib/map';
    import { lang } from '$lib/stores/lang';
    import { sheetMotion, scrimMotion } from '$lib/sheetMotion';
    import type { OnboardingAnswers } from '$lib/pendingOnboarding';
    import { subscribePlanCard, type PlanCardStream } from '$lib/planCardStream';
    import { describeFailure, type FailureView } from '$lib/turnFailure';
    import { onDestroy } from 'svelte';

    let { stateCode, suburbName, suburbSal, initial, onclose, onsignin, oncreated }: {
        stateCode: string;
        /** Absent on the planner page (behavior 81): a plan for the state alone. */
        suburbName?: string;
        suburbSal?: string;
        /** Answers restored after the sign-in round-trip (pendingOnboarding.ts). */
        initial?: OnboardingAnswers;
        onclose: () => void;
        /** Sign-in is needed; the answers so far ride along so they survive the redirect. */
        onsignin: (answers: OnboardingAnswers) => void;
        /** The plan card was created — close the modal and reveal it; `id` is the new
         *  card's, so the planner opens that plan (behavior 86). */
        oncreated: (id: string) => void;
    } = $props();

    // Seeded once from `initial` (a restore), never re-synced — the user's taps own them after.
    // svelte-ignore state_referenced_locally
    let intent = $state<Intent | null>(initial?.intent ?? null);
    // svelte-ignore state_referenced_locally
    let citizenPr = $state<boolean | null>(initial?.citizenPr ?? null);
    // svelte-ignore state_referenced_locally
    let firstHome = $state<boolean | null>(initial?.firstHome ?? null);
    // svelte-ignore state_referenced_locally
    let band = $state.raw<BudgetBand | null>(
        initial?.band != null ? (BUDGET_BANDS[initial.band] ?? null) : null
    );
    function answers(): OnboardingAnswers {
        return {
            intent,
            citizenPr,
            firstHome,
            band: band === null ? null : BUDGET_BANDS.indexOf(band)
        };
    }
    let createdId = '';
    let phase = $state<'form' | 'submitting' | 'waiting' | 'failed' | 'auth' | 'limit' | 'error'>('form');
    let guestLimit = $state(3);

    // The gate branches on intent (mode-c-wedge.md P5-activate) AND, orthogonally, on
    // citizen/PR (mode-b-wedge.md P5 / mode-d-wedge.md P5): owner_occupier still requires
    // a first-home answer; investment needs only citizen/PR (Mode C domestic / Mode D
    // foreign — first-home is meaningless for an investor either way). A THIRD axis now
    // bites here too (mode-e-wedge.md P5): for owner_occupier + domestic, first-home →
    // Mode A, next-home → Mode E (nexthome-domestic-au) — both now eligible, no longer an
    // out-of-scope cell. Only ONE cell remains out of scope (calm note, not an error):
    // owner_occupier + foreign + next-home (the Mode-E gap's foreign twin) — fails closed
    // at the engine too now (fh_engine_h_plan_cards:blueprint_for/3), not just shell-gated.
    const ooNeedsFirstHome = $derived(intent === 'owner_occupier');
    const gateAnswered = $derived(
        intent !== null && citizenPr !== null && (!ooNeedsFirstHome || firstHome !== null)
    );
    const eligibleDomestic = $derived(
        intent !== null &&
            citizenPr === true &&
            (intent === 'investment' || firstHome !== null)
    );
    // Mode B: foreign person, buying to live in, first home — the blueprint's own scope
    // (fhb-foreign-au.md — a Vietnam-parent-funded / temp-resident FHB, not an investor
    // or next-home purchase; those combinations are Mode D / the Mode-E gap's foreign twin).
    const eligibleForeign = $derived(
        intent === 'owner_occupier' && citizenPr === false && firstHome === true
    );
    // Mode D (mode-d-wedge.md P5): foreign person, investing — no first-home question,
    // same as Mode C. Newly in scope; previously fell into the "out of scope" note above.
    const eligibleForeignInvestor = $derived(
        intent === 'investment' && citizenPr === false
    );
    // Domestic + owner_occupier + next-home — Mode E (mode-e-wedge.md P5). Drives both the
    // informational note below and the buyer_stage payload; never inferred, always a tap.
    const eligibleNextHome = $derived(
        intent === 'owner_occupier' && citizenPr === true && firstHome === false
    );
    const isForeign = $derived(eligibleForeign || eligibleForeignInvestor);
    const eligible = $derived(eligibleDomestic || eligibleForeign || eligibleForeignInvestor);
    const canSubmit = $derived(eligible && band !== null && phase === 'form');

    // buyer_stage (mode-e-wedge.md P0/P5): only meaningful for owner_occupier, and always
    // sent explicitly for that intent — never left for the engine's next_home default to
    // resolve (fh_engine_h_plan_cards:stage_of/1's own comment on why first_home is never
    // a safe silent default).
    const buyerStage = $derived<BuyerStage | undefined>(
        intent === 'owner_occupier'
            ? firstHome === true
                ? 'first_home'
                : firstHome === false
                  ? 'next_home'
                  : undefined
            : undefined
    );

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
            buildOnboardingInput(stateCode, suburbName, suburbSal, band, intent, isForeign, buyerStage)
        );
        if (outcome.kind === 'guest_limit') guestLimit = outcome.limit;
        if (outcome.kind === 'created') {
            createdId = outcome.result.plan_card_id;
            phase = 'waiting';
            wait(createdId);
            return;
        }
        phase =
            outcome.kind === 'guest_limit' ? 'limit'
            : outcome.kind === 'auth_required' ? 'auth'
            : 'error';
    }

    // The wait after a create (behavior 92).
    // Goal property: a visitor sees the plan being made, then lands on it with no tap.
    // Invariant: the dialog lands on the plan once its budget (cash_position) has
    //   arrived, or the turn completed; never earlier, and never stuck: a failed turn
    //   says so with "Thử lại" (when describeFailure allows one), and past 20 s it says
    //   it is taking longer and offers to open the plan anyway.
    // Component: this dialog, on the new card's own stream (planCardStream), apart from
    //   the projection's — it only counts arrivals, it renders nothing of them.
    // Capability: the engine's quick pass (behavior 94) fills every base component,
    //   cash_position included, within ~1 s, then the full pass refills them and
    //   turn_completed follows 13-30 s later; component_filled may come twice per id.
    //   The three progress lines step at most one per STEP_MS, so a 1 s plan still shows
    //   each line rather than a flash; without arrivals they step on time alone up to the
    //   last, which only the budget's arrival passes.
    const STEP_MS = 700;
    const TIME_STEP_MS = 4000;
    const SLOW_MS = 20_000;
    const WAIT_LINES = ['onboarding.wait.buy', 'onboarding.wait.hold', 'onboarding.wait.sell'] as const;
    let shown = $state(0);
    let slow = $state(false);
    let failure = $state.raw<FailureView | null>(null);
    let stream: PlanCardStream | null = null;
    let ticker: ReturnType<typeof setInterval> | undefined;
    let slowTimer: ReturnType<typeof setTimeout> | undefined;

    function stopWait() {
        stream?.close();
        stream = null;
        clearInterval(ticker);
        clearTimeout(slowTimer);
    }
    onDestroy(stopWait);

    function wait(id: string) {
        stopWait();
        shown = 0;
        slow = false;
        failure = null;
        const filled = new Set<string>();
        let ready = false;
        const started = Date.now();
        stream = subscribePlanCard(id, {
            onComponentFilled: (e) => {
                if (e.property_id) return;
                filled.add(e.component_id);
                if (e.component_id === 'cash_position') ready = true;
            },
            onDone: (failed) => {
                if (failed === null || ready) {
                    ready = true;
                    return;
                }
                stopWait();
                failure = describeFailure(failed);
                phase = 'failed';
            }
        });
        ticker = setInterval(() => {
            const byEvents = filled.has('mortgage_finance') ? 2 : filled.size > 0 ? 1 : 0;
            const byTime = Math.min(WAIT_LINES.length - 1, Math.floor((Date.now() - started) / TIME_STEP_MS));
            const target = ready ? WAIT_LINES.length : Math.max(byEvents, byTime);
            if (shown < target) shown += 1;
            if (shown >= WAIT_LINES.length) land();
        }, STEP_MS);
        slowTimer = setTimeout(() => (slow = true), SLOW_MS);
    }

    function land() {
        stopWait();
        oncreated(createdId);
    }

    // ✕ once the plan exists lands on it, as the wait would (behavior 28): the parent
    // reloads the sheet's plan on oncreated only, so closing with ✕ after a create left
    // the new plan missing until a page refresh (read 2026-10-08, +page.svelte).
    // What the plan is for: the suburb on the map, the state on the planner page.
    const place = $derived(suburbName || STATE_NAMES[stateCode as AuState] || stateCode);

    function close() {
        if (phase === 'waiting' || phase === 'failed') land();
        else onclose();
    }
</script>

<div class="ob-backdrop" transition:scrimMotion|global>
<div class="onboarding" role="dialog" aria-modal="true" aria-label={place} transition:sheetMotion|global>
    <header class="ob-head">
        <h2>{$t('onboarding.title')} {place}</h2>
        <button type="button" class="close" onclick={close} aria-label={$t('sheet.close')}
            >✕</button
        >
    </header>

    {#if phase === 'waiting'}
        <div class="ob-terminal ob-wait" role="status" aria-live="polite">
            <svg class="ob-house" viewBox="0 0 120 104" aria-hidden="true">
                <path class="roof" d="M10 50 60 10l50 40" />
                <rect class="wall" x="22" y="44" width="76" height="54" rx="4" />
                {#each WAIT_LINES as key, i (key)}
                    <rect class="line-track" x="34" y={56 + i * 13} width="52" height="6" rx="3" />
                    <rect
                        class="line-fill"
                        class:done={shown > i}
                        class:now={shown === i}
                        x="34"
                        y={56 + i * 13}
                        width="52"
                        height="6"
                        rx="3"
                    />
                {/each}
            </svg>
            <h3>{$t('onboarding.wait.title')}</h3>
            <p class="ob-wait-line">{$t(WAIT_LINES[Math.min(shown, WAIT_LINES.length - 1)])}</p>
            {#if slow}
                <p>{$t('onboarding.wait.slow')}</p>
                <button type="button" class="primary" onclick={land}>{$t('onboarding.wait.open')}</button>
            {/if}
        </div>
    {:else if phase === 'failed' && failure}
        <div class="ob-terminal">
            <p class="ob-error">{$t(failure.key)}</p>
            {#if failure.retry}
                <button type="button" class="primary" onclick={submit}>{$t('onboarding.retry')}</button>
            {:else}
                <button type="button" class="primary" onclick={land}>{$t('onboarding.wait.open')}</button>
            {/if}
        </div>
    {:else if phase === 'limit'}
        <div class="ob-terminal">
            <p>{$t('guest.limit').replace('{n}', String(guestLimit))}</p>
            <button type="button" class="primary" onclick={() => onsignin(answers())}
                >{$t('auth.signin')}</button
            >
        </div>
    {:else if phase === 'auth'}
        <div class="ob-terminal">
            <h3>{$t('onboarding.auth.title')}</h3>
            <p>{$t('onboarding.auth.body')}</p>
            <button type="button" class="primary" onclick={() => onsignin(answers())}
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
                <!-- First-home gate applies to BOTH owner-occupier blueprints — Mode A
                     (domestic) and Mode B (foreign, mode-b-wedge.md P5); meaningless for an
                     investor (Mode C). -->
                <fieldset class="gate">
                    <legend>{$t('onboarding.gate.firsthome')}</legend>
                    {#if citizenPr === false}
                        <p class="ob-hint">{$t('onboarding.gate.firsthome.foreign')}</p>
                    {/if}
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
                <!-- Out of scope — calm, not an error (§7.1). Domestic next-home is now
                     in scope (Mode E, mode-e-wedge.md P5), so the only remaining cell
                     reaching here is owner_occupier + foreign + next-home (the Mode-E
                     gap's foreign twin — investor combinations are both in scope, C/D). -->
                <p class="ob-note">{$t('onboarding.outofscope.foreign')}</p>
            {:else if eligible}
                {#if eligibleForeign}
                    <p class="ob-note ob-note-info">{$t('onboarding.foreign.note')}</p>
                {:else if eligibleForeignInvestor}
                    <p class="ob-note ob-note-info">{$t('onboarding.foreign.investor.note')}</p>
                {:else if eligibleNextHome}
                    <p class="ob-note ob-note-info">{$t('onboarding.nexthome.note')}</p>
                {/if}
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
            <p class="ob-disclaimer">{$t('disclaimer.asic')}</p>
        </div>

        <footer class="ob-foot">
            <button type="button" class="primary" disabled={!canSubmit} onclick={submit}>
                {phase === 'submitting' ? $t('onboarding.submitting') : $t('onboarding.submit')}
            </button>
        </footer>
    {/if}
</div>
</div>
