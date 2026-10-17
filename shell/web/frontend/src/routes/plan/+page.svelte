<script lang="ts">
    // Whole lifecycle -> The web frontend -> the planner page (/plan)
    // Behavior 81: the plan has its own page, reached from the home, not from a suburb on
    // the map — its state the one the engine resolved for it (GET card `state`). With no
    // plan yet: pick a state, answer the onboarding, and the plan is for that state alone.
    // Behavior 96 (over 84 and 86): /plan is the visitor's plans list — one card per plan,
    // newest first (place, state, what it is for, the statement's Buy and Own-per-year
    // figures as the engine's summaries carry them, last update), "+ Kế hoạch mới" above
    // them, which brings the state picker (`choosing`); cancelling it returns to the list.
    // With no plans the list is the state picker itself. A plan opens at /plan?plan=<id>
    // as a history entry over the list (page.state.overList), so ‹ and the browser's back
    // return to it; an old link straight to a plan is given the list underneath once, on
    // arrival. A plan's head is its back button (naming the level above, behavior 106),
    // its place and "Hỏi AI" — nothing else. A create opens the new plan the same way, on
    // its hub (behavior 106, over 92's statement), so back shows the list
    // with it first. A sign-in from the onboarding (the guest's daily cap) or from a
    // guest's plan comes back here (pendingOnboarding.ts, page 'plan').
    // The plan is drawn in the same frame as the map's sheet (.sheet) so its sticky rails,
    // section menu and popups behave as they did there; .page-sheet makes it a page.
    import { goto } from '$app/navigation';
    import { page } from '$app/state';
    import { deletePlanCard, listPlanCards } from '$lib/api';
    import { lang } from '$lib/stores/lang';
    import type { MoneyRange, PlanCardSummary } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import { AU_STATES, STATE_NAMES, type AuState } from '$lib/map';
    import { session, guest, refreshSession } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import { savePending, takePending, type OnboardingAnswers } from '$lib/pendingOnboarding';
    import { readDraft, type OnboardingDraft } from '$lib/onboardingDraft';
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
    // Behavior 111: a plan leaves the list by its own delete, after a confirm in the page
    // (the viewer may refuse browser dialogs): the card asks once, "Xoá" removes it
    // (DELETE /api/plan-cards/:id, the slot frees at once) and the list reloads.
    let confirming = $state<string | null>(null);
    let deleting = $state(false);
    let deleteFailed = $state(false);
    async function removePlan(id: string) {
        deleting = true;
        deleteFailed = false;
        const ok = await deletePlanCard(id);
        deleting = false;
        if (!ok) {
            deleteFailed = true;
            return;
        }
        confirming = null;
        cards = cards?.filter((c) => c.plan_card_id !== id) ?? null;
        reload++;
    }
    // Newest first: the last update, else when it was made.
    const stamp = (c: PlanCardSummary) => Date.parse(c.updated_at ?? c.created_at) || 0;
    const sorted = $derived(cards ? [...cards].sort((a, b) => stamp(b) - stamp(a)) : null);
    // The plan open over the list: the one the address names, if it is theirs.
    const wanted = $derived(page.url.searchParams.get('plan'));
    const open = $derived(cards?.find((c) => c.plan_card_id === wanted) ?? null);
    // The card's title is a suburb (made from the map) or a state code (made here).
    const placeOf = (c: PlanCardSummary) => (isState(c.title) ? STATE_NAMES[c.title] : c.title);

    const df = $derived(
        new Intl.DateTimeFormat($lang === 'vi' ? 'vi-VN' : 'en-AU', { dateStyle: 'medium' })
    );
    const updatedOn = (c: PlanCardSummary) => df.format(new Date(c.updated_at ?? c.created_at));
    // What the plan is for: the intent, then the buyer (mode: A first home, B foreign first
    // home, C investor, D foreign investor, E next home).
    function purposeOf(c: PlanCardSummary): string {
        const why = c.intent === 'investment' || c.mode === 'C' || c.mode === 'D'
            ? $t('planpage.for.invest')
            : c.intent || c.mode ? $t('planpage.for.live') : '';
        const who =
            c.mode === 'A' ? $t('planpage.buyer.first')
            : c.mode === 'E' ? $t('planpage.buyer.next')
            : c.mode === 'B' || c.mode === 'D' ? $t('planpage.buyer.foreign')
            : '';
        return [why, who].filter(Boolean).join(' · ');
    }
    function fig(r: MoneyRange | null | undefined): string | null {
        if (!r) return null;
        return r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang);
    }

    function openPlan(c: PlanCardSummary) {
        goto(`/plan?plan=${encodeURIComponent(c.plan_card_id)}`, { state: { overList: true } });
    }
    // Behavior 106: the plan head's one back button goes up one level and names it — a
    // step → Hành trình, a phase sheet or "Tài chính của bạn" → Ngân sách, a sheet → the
    // plan's hub, the hub → the list. Every level is a history entry (PlanProjection's
    // "the plan's levels" block), so it is history.back(), as the browser's back is; the
    // hub opened with no list underneath (no overList) goes to the list's address.
    const backTo = $derived(
        page.state.flowPhase
            ? $t('plan.ltab.flow')
            : page.state.lifecycle
              ? $t('plan.ltab.budget')
              : page.state.planView
                ? $t('sheet.tab.plan')
                : $t('planpage.list')
    );
    function up() {
        const s = page.state;
        if (s.flowPhase || s.lifecycle || s.planView || s.overList) history.back();
        else goto('/plan');
        toTop();
    }
    // An old link straight to a plan: the list goes underneath it, once, on arrival.
    let seeded = false;
    $effect(() => {
        if (seeded) return;
        seeded = true;
        const id = wanted;
        if (!id || page.state.overList) return;
        void goto('/plan', { replaceState: true }).then(() =>
            goto(`/plan?plan=${encodeURIComponent(id)}`, { state: { overList: true } })
        );
    });

    let pick = $state<AuState>('NSW');
    let planning = $state(false);
    let restoreAnswers = $state<OnboardingAnswers | undefined>(undefined);
    let resumeTap = $state<Pick<OnboardingDraft, 'createKey' | 'planId'> | undefined>(undefined);

    // Behavior 97: this tab was reloaded (Safari, after a lock) while the questions were
    // open — reopen them with their answers, or pick the tap up where it was (send its
    // create again, or go back to its wait). onboardingDraft.ts keeps them.
    {
        const d = readDraft();
        if (d) {
            if (isState(d.scope)) pick = d.scope;
            restoreAnswers = d.answers;
            resumeTap = { createKey: d.createKey, planId: d.planId };
            planning = true;
        }
    }

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
            resumeTap = undefined;
            planning = true;
        } else reload++;
    });
    // A guest opening sign-in from their plan (its 7-day notice, or the menu) comes back here.
    $effect(() => {
        if ($loginOpen && $guest && !planning && open)
            savePending({ page: 'plan', scope: pick, ts: Date.now() });
    });

    const sections = provideSections();
    let bodyEl: HTMLDivElement | undefined = $state();
    const toTop = () => bodyEl?.scrollTo({ top: 0 });
    const menuCurrent = $derived(sections.current || $t('sheet.tab.plan'));

    function startPlan() {
        // From an open plan ("Thử lại" on one that did not finish, behavior 94): its state.
        if (open && open.state && isState(open.state)) pick = open.state;
        restoreAnswers = undefined;
        resumeTap = undefined;
        planning = true;
    }
    // The state picker over the list (behavior 86, moved to the list by 96).
    let choosing = $state(false);
    function newPlan() {
        choosing = true;
        toTop();
    }
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('planpage.title')}>
        {#if open}
            <header class="sheet-head">
                <div class="plan-back-row">
                    <button type="button" class="plan-back" data-back onclick={up}
                        ><span class="plan-back-mark" aria-hidden="true">‹</span> {backTo}</button
                    >
                </div>
                <div class="title">
                    <h2>
                        {placeOf(open)}{#if open.state && open.state !== open.title}<span class="state-chip"
                                >{open.state}</span
                            >{/if}
                    </h2>
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
        {:else}
            <header class="sheet-head">
                <HomeBack />
                <div class="title"><h2>{$t('planpage.title')}</h2></div>
            </header>
        {/if}

        <div class="body" data-tour="plan" bind:this={bodyEl}>
            {#if sorted === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if open}
                {#key `${open.plan_card_id}:${reload}`}
                    <PlanProjection
                        cardId={open.plan_card_id}
                        suburbName={isState(open.title) ? '' : open.title}
                        suburbState={isState(open.title) ? open.title : ''}
                        onplan={startPlan}
                    />
                {/key}
            {:else if sorted.length > 0 && !choosing}
                <div class="plans">
                    <button type="button" class="plan-new" onclick={newPlan}
                        ><span aria-hidden="true">+</span> {$t('planpage.new')}</button
                    >
                    <ul class="plan-cards" aria-label={$t('planpage.saved')}>
                        {#each sorted as c (c.plan_card_id)}
                            {@const purpose = purposeOf(c)}
                            {@const buy = fig(c.costs_buy)}
                            {@const own = fig(c.costs_own_per_year)}
                            <li>
                                <button type="button" class="plan-card" onclick={() => openPlan(c)}>
                                    <span class="plan-card-place"
                                        >{placeOf(c)}{#if c.state}<span class="state-chip">{c.state}</span>{/if}</span
                                    >
                                    {#if purpose}<span class="plan-card-for">{purpose}</span>{/if}
                                    {#if buy || own}
                                        <span class="plan-card-figs">
                                            {#if buy}<span class="plan-card-fig"
                                                    ><span class="plan-card-k">{$t('plan.sheet.costs_buy')}</span>
                                                    <span class="plan-card-v">{buy}</span></span
                                                >{/if}
                                            {#if own}<span class="plan-card-fig"
                                                    ><span class="plan-card-k">{$t('plan.sheet.costs_own_none')}</span>
                                                    <span class="plan-card-v"
                                                        >≈ {own}<span class="plan-card-unit">{$t('plan.sheet.per_year')}</span></span
                                                    ></span
                                                >{/if}
                                        </span>
                                    {/if}
                                    <span class="plan-card-date"
                                        >{$t('planpage.updated').replace('{d}', updatedOn(c))}</span
                                    >
                                    <span class="plan-card-caret" aria-hidden="true">›</span>
                                </button>
                                {#if confirming === c.plan_card_id}
                                    <div class="plan-del-ask" role="group" aria-label={$t('plans.delete_q')}>
                                        <span class="plan-del-q"
                                            >{deleteFailed ? $t('plans.delete_failed') : $t('plans.delete_q')}</span
                                        >
                                        <button
                                            type="button"
                                            class="btn btn-secondary"
                                            data-plan-delete-no
                                            onclick={() => ((confirming = null), (deleteFailed = false))}
                                            >{$t('plans.delete_no')}</button
                                        >
                                        <button
                                            type="button"
                                            class="btn plan-del-yes"
                                            data-plan-delete-yes
                                            disabled={deleting}
                                            onclick={() => removePlan(c.plan_card_id)}>{$t('plans.delete_yes')}</button
                                        >
                                    </div>
                                {:else}
                                    <button
                                        type="button"
                                        class="plan-del"
                                        data-plan-delete
                                        aria-label={$t('plans.delete_label').replace('{p}', placeOf(c))}
                                        onclick={() => ((confirming = c.plan_card_id), (deleteFailed = false))}
                                        >{$t('plans.delete')}</button
                                    >
                                {/if}
                            </li>
                        {/each}
                    </ul>
                </div>
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
                    {#if sorted.length > 0}
                        <button type="button" class="plan-cancel" onclick={() => (choosing = false)}
                            >{$t('planpage.back')}</button
                        >
                    {/if}
                </div>
            {/if}
        </div>
        {#if open && sections.plan.length > 0}
            <!-- behavior 106: not on the plan's hub, whose cards are the way in -->
            <SectionMenu groups={sections.plan} current={menuCurrent} onpick={toTop} inPlan={sections.plan.length > 0} />
        {/if}
    </div>

    {#if planning}
        <Onboarding
            stateCode={pick}
            initial={restoreAnswers}
            resume={resumeTap}
            oncreated={(id) => {
                planning = false;
                choosing = false;
                reload++;
                // The new plan opens over the list (back shows it first), at its top
                // (behavior 92), not where the last one was read.
                if (id)
                    goto(`/plan?plan=${encodeURIComponent(id)}`, {
                        noScroll: true,
                        state: { overList: true }
                    });
                toTop();
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
