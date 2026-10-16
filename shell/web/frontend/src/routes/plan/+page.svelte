<script lang="ts">
    // Whole lifecycle -> The web frontend -> the planner page (/plan)
    // Behavior 81: the plan has its own page, reached from the home, not from a suburb on
    // the map. It shows one of the visitor's plans, opened by id — its state the one the
    // engine resolved for it (GET card `state`). With no plan yet: pick a state, answer the
    // onboarding, and the plan is for that state alone (no suburb). Behavior 84: the head
    // lists every saved plan (title, state, last update — older plans titled by a suburb
    // among them); the one opened is in the address (?plan=<id>), else the newest.
    // Behavior 86: with a plan open, "Kế hoạch mới" in the head brings back the empty
    // page's state picker (`choosing`); cancelling it, or the questions, returns to the
    // plan, and a create opens the new plan by its id. A sign-in from the onboarding (the guest's daily
    // cap) or from a guest's plan comes back here (pendingOnboarding.ts, page 'plan').
    // The plan is drawn in the same frame as the map's sheet (.sheet) so its sticky rails,
    // section menu and popups behave as they did there; .page-sheet makes it a page.
    import { goto } from '$app/navigation';
    import { page } from '$app/state';
    import { listPlanCards } from '$lib/api';
    import { clickOutside } from '$lib/actions/clickOutside';
    import { lang } from '$lib/stores/lang';
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
    // The plan shown: the one the address names, if it is theirs, else the newest.
    const wanted = $derived(page.url.searchParams.get('plan'));
    const newest = $derived(
        cards?.find((c) => c.plan_card_id === wanted) ?? cards?.[0] ?? null
    );
    // The card's title is a suburb (made from the map) or a state code (made here).
    const placeOf = (c: PlanCardSummary) => (isState(c.title) ? STATE_NAMES[c.title] : c.title);
    const place = $derived(newest ? placeOf(newest) : '');
    // The saved plans list (behavior 84): open in the head, one row per plan.
    let listOpen = $state(false);
    const df = $derived(
        new Intl.DateTimeFormat($lang === 'vi' ? 'vi-VN' : 'en-AU', { dateStyle: 'medium' })
    );
    const updatedOn = (c: PlanCardSummary) => df.format(new Date(c.updated_at ?? c.created_at));
    function openPlan(c: PlanCardSummary) {
        listOpen = false;
        if (c.plan_card_id !== newest?.plan_card_id)
            goto(`/plan?plan=${encodeURIComponent(c.plan_card_id)}`, { noScroll: true, keepFocus: true });
    }

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
    // The state picker over an open plan (behavior 86).
    let choosing = $state(false);
    function newPlan() {
        listOpen = false;
        choosing = true;
        toTop();
    }
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('planpage.title')}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title" use:clickOutside={() => (listOpen = false)}>
                <h2>{$t('planpage.title')}</h2>
                <div class="plan-line">
                {#if cards && cards.length > 1 && newest && !choosing}
                    <button
                        type="button"
                        class="plan-switch"
                        aria-expanded={listOpen}
                        aria-controls="plan-list"
                        onclick={() => (listOpen = !listOpen)}
                        >{place}{#if newest.state && newest.state !== newest.title}<span class="state-chip"
                                >{newest.state}</span
                            >{/if}<span class="plan-switch-count">{$t('planpage.plans').replace('{n}', String(cards.length))}</span
                        ><svg viewBox="0 0 12 12" width="10" height="10" aria-hidden="true"
                            ><path d="M2 4.5 6 8l4-3.5" fill="none" stroke="currentColor" stroke-width="1.6" /></svg
                        ></button
                    >
                    {#if listOpen}
                        <ul class="plan-list" id="plan-list" aria-label={$t('planpage.saved')}>
                            {#each cards as c (c.plan_card_id)}
                                <li>
                                    <button
                                        type="button"
                                        aria-current={c.plan_card_id === newest.plan_card_id}
                                        onclick={() => openPlan(c)}
                                    >
                                        <span class="plan-list-name">{placeOf(c)}</span>
                                        {#if c.state}<span class="state-chip">{c.state}</span>{/if}
                                        <span class="plan-list-date"
                                            >{$t('planpage.updated').replace('{d}', updatedOn(c))}</span
                                        >
                                    </button>
                                </li>
                            {/each}
                        </ul>
                    {/if}
                {:else if place && !choosing}<p class="sub">{place}</p>{/if}
                {#if newest && !choosing}
                    <button type="button" class="plan-new" onclick={newPlan}
                        ><span aria-hidden="true">+</span> {$t('planpage.new')}</button
                    >
                {/if}
                </div>
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
            {:else if newest && !choosing}
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
                    {#if newest}
                        <button type="button" class="plan-cancel" onclick={() => (choosing = false)}
                            >{$t('planpage.back')}</button
                        >
                    {/if}
                </div>
            {/if}
        </div>
        {#if newest && !choosing}
            <SectionMenu groups={sections.plan} current={menuCurrent} onpick={toTop} inPlan={sections.plan.length > 0} />
        {/if}
    </div>

    {#if planning}
        <Onboarding
            stateCode={pick}
            initial={restoreAnswers}
            oncreated={(id) => {
                planning = false;
                choosing = false;
                reload++;
                if (id) goto(`/plan?plan=${encodeURIComponent(id)}`, { noScroll: true });
                // A signed-out create made this browser a guest (behavior 45): re-read
                // /api/me so the plan shows the 7-day notice.
                void refreshSession();
            }}
            onclose={() => {
                planning = false;
                choosing = false;
            }}
            onsignin={(answers) => {
                savePending({ page: 'plan', scope: pick, answers, ts: Date.now() });
                planning = false;
                loginOpen.set(true);
            }}
        />
    {/if}
</div>
