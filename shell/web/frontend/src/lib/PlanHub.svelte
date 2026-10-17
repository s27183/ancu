<script lang="ts">
    // Whole lifecycle -> bilingual; information as is -> the web frontend -> the plan hub
    // Purpose:   the plan's first level (behavior 106): two cards, each the way into one
    //            sheet and each carrying the one fact that says why to open it — Ngân sách
    //            with the statement's bottom line ("Tổng tiền bạn bỏ ra trong N năm", behavior 110), Hành trình with
    //            the checklist steps done of all and the next step. The plan's levels and
    //            the back button are PlanProjection's "the plan's levels" block.
    // Holds:     it computes no figure: the total is lifecycle_budget.out_total for the
    //            hold it was made for (hold_years), as the statement shows it; the count
    //            is the playbook's actions with the card's checklist_status over them (the
    //            same overlay PhaseSheet's isDone reads), the next step the first not done
    //            in phase and action order.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { money, moneyRange } from '$lib/format';
    import {
        pick,
        type ChecklistStatusMap,
        type ComponentEntry,
        type JourneySwimlaneOutcome,
        type MoneyRange,
        type PhaseAction,
        type PhasePlaybookOutcome
    } from '$lib/planCard';

    let {
        components,
        checklistStatus,
        filling,
        hasBudget,
        hasFlow,
        onbudget,
        onflow
    }: {
        components: Record<string, ComponentEntry>;
        checklistStatus: ChecklistStatusMap;
        filling: boolean;
        hasBudget: boolean;
        hasFlow: boolean;
        onbudget: () => void;
        onflow: () => void;
    } = $props();

    const budget = $derived(
        (components.purchase_journey?.outcome as JourneySwimlaneOutcome | undefined)?.lifecycle_budget ??
            null
    );
    const total = $derived((budget?.out_total ?? null) as MoneyRange | null);
    const holdYears = $derived(budget?.hold_years ?? 0);

    const playbook = $derived(components.phase_playbook?.outcome as PhasePlaybookOutcome | undefined);
    const steps = $derived(
        (playbook?.phases ?? []).flatMap((p) =>
            [...(p.actions ?? [])]
                .sort((a, b) => a.order - b.order)
                .map((a) => ({ phase: p.phase, a }))
        )
    );
    const isDone = (phase: string, a: PhaseAction) =>
        checklistStatus[phase]?.[a.id] === 'done' || a.status === 'done';
    const done = $derived(steps.filter((s) => isDone(s.phase, s.a)).length);
    const next = $derived(steps.find((s) => !isDone(s.phase, s.a)) ?? null);

    function fig(r: MoneyRange): string {
        return (r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang)) ?? '—';
    }
</script>

<nav class="hub" aria-label={$t('sheet.tab.plan')}>
    {#if hasBudget}
        <button type="button" class="hub-card" data-hub="budget" onclick={onbudget}>
            <span class="hub-name">{$t('plan.ltab.budget')}</span>
            <span class="hub-label"
                >{holdYears
                    ? $t('plan.sheet.total_hold').replace('{n}', String(holdYears))
                    : $t('plan.sheet.total_hold_none')}</span
            >
            <span class="hub-fig"
                >{#if total}{fig(total)}{:else if filling}<span class="hub-skel" aria-hidden="true"></span>{:else}—{/if}</span
            >
            <span class="hub-caret" aria-hidden="true">›</span>
        </button>
    {/if}
    {#if hasFlow}
        <button type="button" class="hub-card" data-hub="flow" onclick={onflow}>
            <span class="hub-name">{$t('plan.ltab.flow')}</span>
            {#if steps.length > 0}
                <span class="hub-label">{$t('plan.hub.steps')}</span>
                <span class="hub-fig" data-hub-count
                    >{done}<span class="hub-of">/{steps.length}</span></span
                >
                <span class="hub-next"
                    >{#if next}{$t('plan.hub.next')} {pick(next.a.label, $lang)}{:else}{$t(
                            'plan.hub.all_done'
                        )}{/if}</span
                >
            {:else if filling}
                <span class="hub-fig"><span class="hub-skel" aria-hidden="true"></span></span>
            {:else}
                <span class="hub-label">{$t('plan.hub.flow_what')}</span>
            {/if}
            <span class="hub-caret" aria-hidden="true">›</span>
        </button>
    {/if}
</nav>

<style>
    .hub {
        display: grid;
        gap: 0.75rem;
    }
    .hub-card {
        position: relative;
        display: grid;
        gap: 0.2rem;
        width: 100%;
        padding: 1rem 2.5rem 1rem 1rem;
        text-align: left;
        font: inherit;
        color: inherit;
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 0.75rem;
        cursor: pointer;
    }
    .hub-card:hover {
        border-color: var(--accent-line);
    }
    .hub-card:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }
    .hub-name {
        font-size: var(--fs-lg, 1.125rem);
        font-weight: 700;
    }
    .hub-label {
        font-size: var(--fs-sm, 0.875rem);
        color: var(--muted);
    }
    .hub-fig {
        font-size: var(--fs-xl, 1.375rem);
        font-weight: 700;
        font-variant-numeric: tabular-nums;
        letter-spacing: -0.01em;
    }
    .hub-of {
        font-weight: 500;
        color: var(--muted);
    }
    .hub-next {
        font-size: var(--fs-sm, 0.875rem);
        color: var(--ink-2, var(--muted));
    }
    .hub-caret {
        position: absolute;
        right: 1rem;
        top: 50%;
        transform: translateY(-50%);
        color: var(--muted);
        font-size: 1.25rem;
    }
    .hub-skel {
        display: inline-block;
        width: 8rem;
        height: 1.1em;
        border-radius: 0.35rem;
        background: var(--border);
        vertical-align: middle;
    }
</style>
