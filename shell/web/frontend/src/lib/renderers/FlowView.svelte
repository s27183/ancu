<script lang="ts">
    // The Flow view (task 10) — the legal/temporal spine as a top-level view. The swimlane
    // (SwimlaneDiagram, all phases) IS the navigation (§7.1): every phase header and every
    // item cell is a click target that opens that phase's drill-down PhaseSheet (focused viz
    // → action checklist with the done-toggle + budget/component links → KB-grounded risks).
    // One lifecycle projected two ways over one shared cash_events primitive (the swimlane
    // PLACES the flows on the timeline; the sheet's checklist LINKS to the same cash_events
    // by id). honest-partial: no journey yet → a calm computing/pending line; no playbook →
    // the swimlane alone, no drill (settlement_prep is Phase-B and simply absent at base).
    // The toggle is owned by the parent (card state + SOT reconcile); this passes intent
    // straight through.
    // Behavior 95: a statement line's detail opens Hành trình at a step that links it —
    // the step opens its phase sheet on its checklist, at the step (flowAction).
    // Behavior 106: a phase's sheet is a level of its own, not a popup — a history entry
    // (page.state.flowPhase, its step flowAction) drawn in place of the swimlane, so the
    // plan head's one back button ("‹ Hành trình") closes it, as the browser's back does.
    import { pushState } from '$app/navigation';
    import { page } from '$app/state';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type JourneySwimlaneOutcome,
        type PhasePlaybookOutcome,
        type CashEvent,
        type ComponentEntry,
        type ChecklistStatusMap
    } from '$lib/planCard';
    import SwimlaneDiagram from './SwimlaneDiagram.svelte';
    import PhaseSheet from './PhaseSheet.svelte';
    import NoteList from './NoteList.svelte';

    let {
        journey,
        playbook,
        cashEvents,
        components,
        checklistStatus,
        onToggle,
        filling
    }: {
        journey: JourneySwimlaneOutcome | undefined;
        playbook: PhasePlaybookOutcome | undefined;
        cashEvents: CashEvent[];
        components: Record<string, ComponentEntry>;
        checklistStatus: ChecklistStatusMap;
        onToggle: (phase: string, actionId: string, next: 'done' | 'not_started') => void;
        filling: boolean;
    } = $props();

    const phases = $derived(journey?.phases ?? []);
    // phase id → its playbook entry (actions + risks). The drill-down reads from here;
    // a phase with no playbook entry just opens an empty sheet (honest-partial).
    const playbookByPhase = $derived(
        new Map((playbook?.phases ?? []).map((p) => [p.phase, p]))
    );
    const drillable = $derived(playbookByPhase.size > 0);

    // The open phase (and the step it was opened at): the history entry's.
    const selected = $derived(page.state.flowPhase ?? null);
    const focusAction = $derived(page.state.flowAction ?? null);
    const selectedPhase = $derived(phases.find((p) => p.id === selected) ?? null);
    // The swimlane IS the navigation (§7.1): a phase header or any item cell opens that
    // phase's sheet, one level down.
    const selectPhase = (id: string) => {
        pushState('', { ...page.state, flowPhase: id, flowAction: undefined });
    };
</script>

<section class="pp-card pp-flat">
    {#if phases.length && drillable && selectedPhase}
        <h3 class="fv-title">{pick(selectedPhase.label, $lang)}</h3>
        <PhaseSheet
            phaseId={selectedPhase.id}
            journey={journey as JourneySwimlaneOutcome}
            playbookPhase={playbookByPhase.get(selectedPhase.id)}
            {cashEvents}
            {components}
            {checklistStatus}
            {onToggle}
            {focusAction}
        />
    {:else if phases.length}
        {#if drillable}
            <p class="fv-hint">{$t('plan.flow.open')}</p>
        {/if}
        <SwimlaneDiagram
            outcome={journey as unknown as Record<string, unknown>}
            onSelectPhase={drillable ? selectPhase : undefined}
            selectedPhase={selected}
            showInteractions={false}
        />

        <NoteList heading={$t('plan.f.assumptions')} notes={playbook?.key_assumptions} />
    {:else if filling}
        <p class="pp-computing"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.computing')}</p>
    {:else}
        <p class="pp-pending">{$t('plan.computing')}</p>
    {/if}
</section>

<style>
    .fv-title {
        margin: 0 0 0.75rem;
        font-size: var(--fs-lg, 1.125rem);
        font-weight: 700;
    }
    .fv-hint {
        margin: 0 0 0.5rem;
        font-size: var(--fs-xs);
        color: var(--muted);
    }
</style>
