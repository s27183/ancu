<script lang="ts">
    // Whole lifecycle -> The web frontend -> the planner page (/plan)
    // Behavior 81: the plan has its own page, reached from the home, not from a suburb on
    // the map. It shows the visitor's newest plan (listPlanCards is newest first), opened
    // by id — its state the one the engine resolved for it (GET card `state`). With no plan
    // yet: pick a state, answer the onboarding, and the plan is for that state alone (no
    // suburb). Until behavior 84 lists every plan, an older suburb-titled plan is still
    // shown here when it is the newest. A sign-in from the onboarding (the guest's daily
    // cap) or from a guest's plan comes back here (pendingOnboarding.ts, page 'plan').
    // The plan is drawn in the same frame as the map's sheet (.sheet) so its sticky rails,
    // section menu and popups behave as they did there; .page-sheet makes it a page.
    import { listPlanCards } from '$lib/api';
    import type { PlanCardSummary } from '$lib/planCard';
    import { AU_STATES, STATE_NAMES, type AuState } from '$lib/map';
    import { session, guest, refreshSession } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import { savePending, takePending, type OnboardingAnswers } from '$lib/pendingOnboarding';
    import PlanProjection from '$lib/PlanProjection.svelte';
    import Onboarding from '$lib/Onboarding.svelte';
    import SectionMenu from '$lib/SectionMenu.svelte';
    import Sparkle from '$lib/Sparkle.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import { provideSections } from '$lib/sections.svelte';
    import { t } from '$lib/i18n';

    const isState = (s: string): s is AuState => (AU_STATES as readonly string[]).includes(s);

    let cards = $state<PlanCardSummary[] | null>(null);
    let reload = $state(0);
    $effect(() => {
        void $session; // a sign-in (or a guest made by a create) can bring a plan
        void reload;
        listPlanCards().then((c) => (cards = c));
    });
    const newest = $derived(cards?.[0] ?? null);
    // The card's title is a suburb (made from the map) or a state code (made here).
    const place = $derived(
        newest ? (isState(newest.title) ? STATE_NAMES[newest.title] : newest.title) : ''
    );

    let pick = $state<AuState>('NSW');
    let planning = $state(false);
    let restoreAnswers = $state<OnboardingAnswers | undefined>(undefined);

    // Back from a sign-in begun here: reopen the onboarding with its answers, or (a guest
    // who signed in from their plan) show the plan they now own.
    let taken = false;
    $effect(() => {
        if (!$session || taken) return;
        taken = true;
        const p = takePending('plan');
        if (!p) return;
        if (isState(p.scope)) pick = p.scope;
        if (p.answers) {
            restoreAnswers = p.answers;
            planning = true;
        } else reload++;
    });
    // A guest opening sign-in from their plan (its 7-day notice, or the menu) comes back here.
    $effect(() => {
        if ($loginOpen && $guest && !planning && newest)
            savePending({ page: 'plan', scope: pick, ts: Date.now() });
    });

    const sections = provideSections();
    let bodyEl: HTMLDivElement | undefined = $state();
    const toTop = () => bodyEl?.scrollTo({ top: 0 });
    const menuCurrent = $derived(sections.current || $t('sheet.tab.plan'));

    function startPlan() {
        restoreAnswers = undefined;
        planning = true;
    }
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('planpage.title')}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title">
                <h2>{$t('planpage.title')}</h2>
                {#if place}<p class="sub">{place}</p>{/if}
            </div>
            {#if sections.ask}
                <button
                    type="button"
                    class="head-link accent"
                    onclick={() => {
                        sections.ask?.();
                        toTop();
                    }}><Sparkle /><span class="head-link-text">{$t('plan.tab.qa_short')}</span></button
                >
            {/if}
        </header>

        <div class="body" data-tour="plan" bind:this={bodyEl}>
            {#if cards === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if newest}
                {#key `${newest.plan_card_id}:${reload}`}
                    <PlanProjection
                        cardId={newest.plan_card_id}
                        suburbName={isState(newest.title) ? '' : newest.title}
                        suburbState={isState(newest.title) ? newest.title : ''}
                        onplan={startPlan}
                    />
                {/key}
            {:else}
                <div class="plan-start">
                    <p>{$t('planpage.intro')}</p>
                    <div class="control">
                        <label for="plan-state">{$t('planpage.state')}</label>
                        <div class="select-wrap">
                            <select id="plan-state" bind:value={pick}>
                                {#each AU_STATES as s (s)}
                                    <option value={s}>{STATE_NAMES[s]} ({s})</option>
                                {/each}
                            </select>
                        </div>
                    </div>
                    <button type="button" class="primary" data-tour="plan-cta" onclick={startPlan}
                        >{$t('planpage.cta')}</button
                    >
                </div>
            {/if}
        </div>
        {#if newest}
            <SectionMenu groups={sections.plan} current={menuCurrent} onpick={toTop} inPlan={sections.plan.length > 0} />
        {/if}
    </div>

    {#if planning}
        <Onboarding
            stateCode={pick}
            initial={restoreAnswers}
            oncreated={() => {
                planning = false;
                reload++;
                // A signed-out create made this browser a guest (behavior 45): re-read
                // /api/me so the plan shows the 7-day notice.
                void refreshSession();
            }}
            onclose={() => (planning = false)}
            onsignin={(answers) => {
                savePending({ page: 'plan', scope: pick, answers, ts: Date.now() });
                planning = false;
                loginOpen.set(true);
            }}
        />
    {/if}
</div>
