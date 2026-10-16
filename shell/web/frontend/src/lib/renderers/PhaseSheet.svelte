<script lang="ts">
    // One Flow phase, drilled in (task 10). The Flow view shows the whole journey
    // (SwimlaneDiagram, all phases) as the overview; tapping a phase opens THIS sheet for
    // that one phase, in order: a phase-FOCUSED visualization → the temporally-ordered
    // action checklist → the KB-grounded risks. Nothing here is recomputed — it PLACES:
    //   - the focused viz is a pure FILTER of the same purchase_journey outcome to this
    //     phase (place-don't-recompute: a subset, fed back to the existing renderer);
    //   - each action LINKS to a figure by id (budget_ref → a cash_event.id, the amount
    //     joined here at render — never a stored amount) and to a backing component by id
    //     (component_ref → the only path to the components dropped from the top level);
    //   - status is the resolver's seed overlaid by the user-set `done` (checklistStatus).
    // The toggle is owned by the parent (it holds card state + the SOT reconcile); this
    // emits intent via onToggle. honest-partial throughout: a null budget_ref → no chip,
    // an absent component → a calm "attach property", an empty phase → no checklist tab.
    // Behavior 95 (the checklist links both ways): a step's amount is a button that opens
    // the line it links (LineDetail, the same body the statement's phase sheet opens in
    // place) in a modal over this one — closing it returns to the checklist; a ref naming a
    // figure split into lines (its group) lists those lines, each opening its detail. Opened
    // from a line's detail (`focusAction`), the sheet starts on the checklist at that step.
    import { tick } from 'svelte';
    import LineDetail from '$lib/LineDetail.svelte';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type JourneySwimlaneOutcome,
        type PhasePlaybookPhase,
        type PhaseAction,
        type CashEvent,
        type ComponentEntry,
        type ChecklistStatusMap,
        type MoneyRange
    } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import Modal from '$lib/Modal.svelte';
    import Tabs from '$lib/Tabs.svelte';
    import SwimlaneDiagram from './SwimlaneDiagram.svelte';
    import ComponentCard from './ComponentCard.svelte';
    import RiskFlagList from './RiskFlagList.svelte';

    // Content-only: the parent renders this INSIDE a Modal that owns the card chrome, the
    // phase title and the close control. This emits just the three stacked sections.
    let {
        phaseId,
        journey,
        playbookPhase,
        cashEvents,
        components,
        checklistStatus,
        onToggle,
        focusAction = null
    }: {
        phaseId: string;
        journey: JourneySwimlaneOutcome;
        playbookPhase: PhasePlaybookPhase | undefined;
        cashEvents: CashEvent[];
        components: Record<string, ComponentEntry>;
        checklistStatus: ChecklistStatusMap;
        onToggle: (phase: string, actionId: string, next: 'done' | 'not_started') => void;
        /** Open on the checklist at this step (a line's detail chose it). */
        focusAction?: string | null;
    } = $props();

    // The focused viz: the same journey outcome FILTERED to this phase (pure subset —
    // no recompute). Actors narrow to those acting in this phase so the grid has no
    // empty rows; key_assumptions are plan-level → dropped from the focused view.
    const focusedJourney = $derived.by((): JourneySwimlaneOutcome => {
        const cells = (journey.cells ?? []).filter((c) => c.phase === phaseId);
        const actorIds = new Set(cells.map((c) => c.actor));
        return {
            phases: (journey.phases ?? []).filter((p) => p.id === phaseId),
            actors: (journey.actors ?? []).filter((a) => actorIds.has(a.id)),
            cells,
            interactions: (journey.interactions ?? []).filter((it) => it.phase === phaseId)
        };
    });

    // Actions for this phase, ordered. The resolver already seeds `order`; sort defensively.
    const actions = $derived(
        [...(playbookPhase?.actions ?? [])].sort((a, b) => a.order - b.order)
    );
    const risks = $derived(playbookPhase?.risks ?? []);

    // Effective status = the user-set `done` overlaid on the resolver seed. The user-set
    // map only ever stores `done`; absent reads as the seeded `not_started`.
    const isDone = (a: PhaseAction): boolean =>
        checklistStatus[phaseId]?.[a.id] === 'done' || a.status === 'done';

    // budget_ref → the cash_event's amount (joined here; the action stores no amount).
    // honest-partial: a null/dangling ref → null → no chip.
    function amountFor(ref: string | null | undefined): MoneyRange | null {
        if (!ref) return null;
        const own = cashEvents.find((e) => e.id === ref);
        if (own) return own.amount ?? null;
        // behavior 83: the ref names a figure split into fee lines (its `group`) → the sum of
        // the lines paid for sure, as the engine's total (fh_engine_fees:committed/1).
        const lines = cashEvents.filter(
            (e) => e.group === ref && hasRange(e.amount ?? null) && !e.detail?.optional && !e.detail?.condition
        );
        if (lines.length === 0) return null;
        return [
            lines.reduce((t, e) => t + (e.amount as [number, number])[0], 0),
            lines.reduce((t, e) => t + (e.amount as [number, number])[1], 0)
        ];
    }
    const hasRange = (v: MoneyRange | null): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    function amountLabel(v: MoneyRange | null): string | null {
        if (!hasRange(v)) return null;
        return v[0] === v[1] ? money(v[0], $lang) : moneyRange(v, $lang);
    }

    // component_ref drill-down: "Xem chi tiết" opens the backing component's renderer in a
    // SECOND modal layered over this phase modal (layered representation — not inline). One
    // open at a time; a per-property component absent at base shows the attach affordance.
    let selectedActionId = $state<string | null>(null);
    const selectedAction = $derived(actions.find((a) => a.id === selectedActionId) ?? null);

    // The sheet's three tabs (§7.2): the focused viz incl. who-deals-with-whom → the action
    // checklist → the KB risks. The checklist and risks tabs are present only when the phase
    // has actions / risks (no empty tab); 'overview' is the #if fallback so a vanished tab can
    // never blank the sheet (e.g. risks removed by a preview while that tab was open).
    // svelte-ignore state_referenced_locally
    let psTab = $state<string>(focusAction ? 'checklist' : 'overview');
    let listEl: HTMLElement | undefined = $state();
    $effect(() => {
        const id = focusAction;
        if (!id) return;
        psTab = 'checklist';
        void tick().then(() => {
            const el = listEl?.querySelector<HTMLElement>(`[data-action="${CSS.escape(id)}"]`);
            el?.scrollIntoView({ block: 'center' });
            el?.querySelector<HTMLElement>('input')?.focus({ preventScroll: true });
        });
    });

    // The line a step links, opened over the checklist: its own event, or the lines of the
    // figure it names (group) — the same events amountFor sums.
    let lineRef = $state<string | null>(null);
    let lineTitle = $state('');
    const lineEvents = $derived.by((): CashEvent[] => {
        if (!lineRef) return [];
        const own = cashEvents.filter((e) => e.id === lineRef);
        return own.length ? own : cashEvents.filter((e) => e.group === lineRef);
    });
    function openLine(a: PhaseAction) {
        lineRef = a.budget_ref ?? null;
        lineTitle = pick(a.label, $lang);
    }
    const psTabs = $derived([
        { id: 'overview', label: $t('plan.journey.interactions') },
        ...(actions.length ? [{ id: 'checklist', label: $t('plan.flow.actions') }] : []),
        ...(risks.length ? [{ id: 'risks', label: $t('plan.flow.risks') }] : [])
    ]);
</script>

<div class="ps-sheet">
    <Tabs tabs={psTabs} active={psTab} onSelect={(id) => (psTab = id)} />

    {#if psTab === 'checklist' && actions.length}
        <!-- the temporally-ordered action checklist -->
        <ul class="ps-actions" bind:this={listEl}>
            {#each actions as a (a.id)}
                {@const amt = amountLabel(amountFor(a.budget_ref))}
                <li class="ps-action" class:ps-done={isDone(a)} class:ps-focus={a.id === focusAction} data-action={a.id}>
                    <label class="ps-act-row">
                        <input
                            type="checkbox"
                            checked={isDone(a)}
                            onchange={() =>
                                onToggle(phaseId, a.id, isDone(a) ? 'not_started' : 'done')}
                        />
                        <span class="ps-act-text">
                            <span class="ps-act-label">{pick(a.label, $lang)}</span>
                        </span>
                    </label>
                    {#if amt}
                        <button type="button" class="ps-act-amt" onclick={() => openLine(a)}
                            >{amt} <span aria-hidden="true">›</span></button
                        >
                    {/if}
                    {#if a.detail}<p class="ps-act-detail">{pick(a.detail, $lang)}</p>{/if}
                    {#if a.component_ref}
                        <button type="button" class="ps-detail-btn" onclick={() => (selectedActionId = a.id)}>
                            {$t('plan.flow.detail')}
                        </button>
                    {/if}
                </li>
            {/each}
        </ul>
    {:else if psTab === 'risks' && risks.length}
        <!-- the KB-grounded risks + mitigations (layered: row → mitigation modal) -->
        <RiskFlagList {risks} />
    {:else}
        <!-- overview (the #if fallback): the phase-focused viz incl. who-deals-with-whom -->
        <SwimlaneDiagram outcome={focusedJourney as unknown as Record<string, unknown>} />
    {/if}
</div>

<!-- Layered drill: an action's backing component renderer, in a second modal over this one. -->
{#if selectedAction?.component_ref}
    <Modal title={pick(selectedAction.label, $lang)} onClose={() => (selectedActionId = null)}>
        {#if components[selectedAction.component_ref]}
            <ComponentCard
                componentId={selectedAction.component_ref}
                entry={components[selectedAction.component_ref]}
                filling={false}
            />
        {:else}
            <p class="ps-pending">{$t('plan.attach_property')}</p>
        {/if}
    </Modal>
{/if}

<!-- Behavior 95: the line a step links, over the checklist; closing returns to it. -->
{#if lineRef && lineEvents.length}
    <Modal title={lineTitle} onClose={() => (lineRef = null)}>
        <ul class="ps-lines">
            {#each lineEvents as e (e.id)}
                {@const amt = amountLabel(e.amount ?? null)}
                <li class="ps-line">
                    {#if lineEvents.length > 1 && e.detail}
                        <details>
                            <summary class="ps-line-head">
                                <span>{pick(e.label, $lang)}</span>{#if amt}<span class="ps-line-amt">{amt}</span>{/if}
                            </summary>
                            <LineDetail detail={e.detail} {components} />
                        </details>
                    {:else}
                        <p class="ps-line-head">
                            <span>{pick(e.label, $lang)}</span>{#if amt}<span class="ps-line-amt">{amt}</span>{/if}
                        </p>
                        {#if e.detail}<LineDetail detail={e.detail} {components} />{/if}
                    {/if}
                </li>
            {/each}
        </ul>
    </Modal>
{/if}

<style>
    .ps-sheet {
        display: flex;
        flex-direction: column;
    }
    .ps-actions {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
    }
    .ps-action {
        border-bottom: 1px dashed var(--border);
        padding-bottom: 0.6rem;
    }
    .ps-action:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }
    .ps-act-row {
        display: flex;
        align-items: flex-start;
        gap: 0.5rem;
        cursor: pointer;
    }
    .ps-act-row input {
        margin-top: 0.15rem;
        flex: none;
        width: 1rem;
        height: 1rem;
        accent-color: var(--accent);
    }
    .ps-act-text {
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
        gap: 0.4rem;
    }
    .ps-act-label {
        font-size: var(--fs-sm);
        font-weight: 600;
        color: var(--ink);
        line-height: 1.35;
    }
    .ps-done .ps-act-label {
        text-decoration: line-through;
        color: var(--muted);
    }
    .ps-act-amt {
        margin: 0.3rem 0 0 1.5rem;
        border: 0;
        font-family: inherit;
        cursor: pointer;
        font-size: var(--fs-xs);
        font-weight: 700;
        font-variant-numeric: tabular-nums;
        color: var(--accent);
        padding: 0.02rem 0.35rem;
        border-radius: var(--radius-xs);
        background: color-mix(in srgb, var(--accent) 12%, transparent);
        white-space: nowrap;
    }
    .ps-act-detail {
        margin: 0.25rem 0 0 1.5rem;
        font-size: var(--fs-xs);
        color: var(--muted);
        line-height: 1.4;
    }
    .ps-detail-btn {
        margin: 0.3rem 0 0 1.5rem;
        font-size: var(--fs-xs);
        font-weight: 600;
        color: var(--accent);
        background: none;
        border: none;
        padding: 0;
        cursor: pointer;
    }
    .ps-act-amt:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .ps-focus { background: var(--accent-soft); border-radius: var(--radius-xs); }
    .ps-lines { list-style: none; margin: 0; padding: 0; display: grid; gap: 0.75rem; }
    .ps-line + .ps-line { border-top: 1px solid var(--border); padding-top: 0.75rem; }
    .ps-line details > summary { cursor: pointer; list-style: none; }
    .ps-line details > summary::-webkit-details-marker { display: none; }
    .ps-line details[open] > summary { margin-bottom: 0.5rem; }
    .ps-line-head {
        margin: 0; display: flex; flex-wrap: wrap; justify-content: space-between; gap: 0.25rem 0.75rem;
        font-weight: 600; color: var(--ink);
    }
    .ps-line-amt { font-variant-numeric: tabular-nums; white-space: nowrap; }
    .ps-pending {
        margin: 0;
        font-size: var(--fs-sm);
        color: var(--muted);
    }
</style>
