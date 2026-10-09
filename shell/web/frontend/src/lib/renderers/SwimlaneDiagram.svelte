<script lang="ts">
    // The `swimlane-diagram` renderer — purchase_journey (journey_swimlane). The base
    // LIFECYCLE SPINE the prototype led with (plan-card-lifecycle-restoration §7): the
    // phases of a first-home purchase (columns, Prepare → Own) against the actors who act
    // in each (rows, You / Government / Lender / Services), with the buyer's money flows
    // placed on the timeline.
    //
    // TWO LAYOUTS, one data model (container-query, not a viewport media query — the
    // projection lives in a sheet/side-panel, so it reacts to ITS OWN width). At width:
    // the grid swimlane. Below ~600px (the phone surface, mobile-native §7.1): a VERTICAL
    // phase-stack so the lifecycle reads top-to-bottom instead of one column at a time
    // behind a horizontal scroll. Both render the SAME cell body via the {cellBody}
    // snippet — geometry differs, content can't drift.
    //
    // R1 deterministic outcome→geometry: both layouts are pure functions of phases ×
    // actors × cells; nothing agent-drawn. R2 honest-partial: a (phase, actor) with no
    // cell is blank (grid) / omitted (stack); a money cell whose figure is absent shows
    // the prose alone (the engine sets flow_marker=none then); a ZERO figure shows a calm
    // "$0" with no sign/colour (a fully-concessioned duty is not an outflow). R4 bilingual:
    // cell prose + labels are engine {vi,en} picked by pick()/$lang — never $t; only the
    // marker chrome labels are $t. Figures are single-valued, formatted by locale
    // (money/moneyRange) — placed, never recomputed.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type JourneySwimlaneOutcome,
        type JourneyCell,
        type MoneyRange
    } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import NoteList from './NoteList.svelte';

    let {
        outcome,
        density = 'compact',
        onSelectPhase = undefined,
        selectedPhase = null,
        showInteractions = true
    }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
        // When provided, the swimlane IS the navigation (lifecycle-simulation-model §7.1):
        // every phase header AND every item cell becomes a click target that opens that
        // phase's drill-down sheet. Absent → a pure read-only diagram (the dossier, and the
        // phase sheet's own focused slice, which must not be re-clickable).
        onSelectPhase?: ((phaseId: string) => void) | undefined;
        selectedPhase?: string | null;
        // The "ai làm việc với ai" (who-deals-with-whom) flows list below the grid. Shown by
        // default (the focused phase sheet's overview tab + the export dossier). The top-level
        // Flow swimlane passes false (§7.1): each phase sheet now owns its FOCUSED flows, so
        // the all-phases list there is redundant — the top-level swimlane is pure navigation.
        showInteractions?: boolean;
    } = $props();
    const o = $derived(outcome as JourneySwimlaneOutcome);
    const interactive = $derived(typeof onSelectPhase === 'function');
    // Item cells / phase headers stay plain <div>s (they hold block content like <p>, which
    // is invalid inside a <button>); when interactive they get role=button + keyboard so the
    // whole cell is an accessible click target.
    function onPhaseKey(e: KeyboardEvent, phaseId: string) {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onSelectPhase?.(phaseId);
        }
    }

    const phases = $derived(o.phases ?? []);
    const actors = $derived(o.actors ?? []);
    const cells = $derived(o.cells ?? []);
    // Who-talks-to-whom: the money flows between actors, grouped by phase below the grid.
    // Same shared flows as cash_events (the two spines' common primitive); actor ids resolve
    // to the swimlane's own actor labels.
    const interactions = $derived(o.interactions ?? []);
    function actorLabel(id: string): string {
        const a = actors.find((x) => x.id === id);
        return a ? pick(a.label, $lang) : id;
    }

    // (phase, actor) → ALL cells at that coordinate. The engine emits TWO kinds of cell
    // (legal prose + one money cell per placed flow, fh_engine_journey "two kinds of cell"),
    // so a coordinate can hold several — e.g. Dispose/other = the agent prose + sale_proceeds
    // (in) + selling_costs (out); Settle/government = duty + the FHOG grant. We render them
    // ALL, stacked — keying a Map by (phase, actor) would keep only the last and silently
    // drop the rest. cells is tiny (≤ phases × actors), so a plain filter is fine.
    const cellsAt = (phaseId: string, actorId: string): JourneyCell[] =>
        cells.filter((c) => c.phase === phaseId && c.actor === actorId);

    // grid: a sticky actor-label column + one column per phase.
    const cols = $derived(`minmax(4.5rem, auto) repeat(${phases.length}, minmax(8.5rem, 1fr))`);

    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    // a placed figure: "$x" when collapsed ([v,v]), "$lo – $hi" as a band.
    function amountLabel(v: MoneyRange | null | undefined): string | null {
        if (!hasRange(v)) return null;
        return v[0] === v[1] ? money(v[0], $lang) : moneyRange(v, $lang);
    }
    // a placed figure that is exactly zero ([0,0]) — shown neutrally, no +/− sign and no
    // out/in colour (e.g. stamp duty fully removed by the FHB concession is $0, not a
    // red outflow).
    const isZero = (v: MoneyRange | null | undefined): boolean =>
        hasRange(v) && v[0] === 0 && v[1] === 0;

    // money markers carry a sign; document/milestone are non-money tags.
    function markerTag(c: JourneyCell): string | null {
        if (c.flow_marker === 'document') return $t('plan.journey.flow.document');
        if (c.flow_marker === 'milestone') return $t('plan.journey.flow.milestone');
        return null;
    }
</script>

<!-- The cell body, shared by both layouts: prose + a money chip / a doc·step tag. -->
{#snippet cellBody(c: JourneyCell)}
    <p class="sw-item">{pick(c.item, $lang)}</p>
    {#if amountLabel(c.amount)}
        {@const zero = isZero(c.amount)}
        <span
            class="sw-amount"
            class:sw-out={!zero && c.flow_marker === 'money_out'}
            class:sw-in={!zero && c.flow_marker === 'money_in'}
            class:sw-nil={zero}
        >
            {#if !zero && c.flow_marker === 'money_out'}−{:else if !zero && c.flow_marker === 'money_in'}+{/if}{amountLabel(
                c.amount
            )}
        </span>
    {:else if markerTag(c)}
        <span class="sw-tag sw-tag-{c.flow_marker}">{markerTag(c)}</span>
    {/if}
{/snippet}

<div class="sw-root" class:sw-full={density === 'full'}>
    <!-- WIDE: the grid swimlane (phases as columns). -->
    <div class="sw-wrap sw-asgrid">
        <div class="sw-grid" style="grid-template-columns:{cols}">
            <!-- header: empty corner + phase labels (clickable when interactive) -->
            <div class="sw-corner"></div>
            {#each phases as p (p.id)}
                <!-- svelte-ignore a11y_no_noninteractive_tabindex (role=button + tabindex are set together under `interactive`; the checker can't correlate the two ternaries) -->
                <div
                    class="sw-phase"
                    class:sw-clickable={interactive}
                    class:sw-selected={selectedPhase === p.id}
                    role={interactive ? 'button' : undefined}
                    tabindex={interactive ? 0 : undefined}
                    onclick={interactive ? () => onSelectPhase?.(p.id) : undefined}
                    onkeydown={interactive ? (e) => onPhaseKey(e, p.id) : undefined}
                >{pick(p.label, $lang)}</div>
            {/each}

            <!-- one row per actor; each item cell is a click target when interactive -->
            {#each actors as a (a.id)}
                <div class="sw-actor">{pick(a.label, $lang)}</div>
                {#each phases as p (p.id)}
                    {@const cs = cellsAt(p.id, a.id)}
                    <!-- svelte-ignore a11y_no_noninteractive_tabindex (role=button + tabindex set together under `interactive && cs.length`) -->
                    <div
                        class="sw-cell"
                        class:sw-clickable={interactive && cs.length}
                        class:sw-selected={selectedPhase === p.id}
                        role={interactive && cs.length ? 'button' : undefined}
                        tabindex={interactive && cs.length ? 0 : undefined}
                        onclick={interactive && cs.length ? () => onSelectPhase?.(p.id) : undefined}
                        onkeydown={interactive && cs.length ? (e) => onPhaseKey(e, p.id) : undefined}
                    >
                        {#each cs as c, i (i)}{@render cellBody(c)}{/each}
                    </div>
                {/each}
            {/each}
        </div>
    </div>

    <!-- NARROW (mobile): a vertical phase-stack — read the lifecycle top to bottom. -->
    <div class="sw-stack">
        {#each phases as p, pi (p.id)}
            <section class="sw-ph">
                <!-- svelte-ignore a11y_no_noninteractive_tabindex (role=button + tabindex set together under `interactive`) -->
                <div
                    class="sw-ph-head"
                    class:sw-clickable={interactive}
                    class:sw-selected={selectedPhase === p.id}
                    role={interactive ? 'button' : undefined}
                    tabindex={interactive ? 0 : undefined}
                    onclick={interactive ? () => onSelectPhase?.(p.id) : undefined}
                    onkeydown={interactive ? (e) => onPhaseKey(e, p.id) : undefined}
                >
                    <span class="sw-ph-dot" aria-hidden="true"></span>
                    <span class="sw-ph-name">{pick(p.label, $lang)}</span>
                    <span class="sw-ph-step" aria-hidden="true">{pi + 1}/{phases.length}</span>
                </div>
                <div class="sw-ph-rows">
                    {#each actors as a (a.id)}
                        {@const cs = cellsAt(p.id, a.id)}
                        {#if cs.length}
                            <!-- svelte-ignore a11y_no_noninteractive_tabindex (role=button + tabindex set together under `interactive`) -->
                            <div
                                class="sw-srow"
                                class:sw-clickable={interactive}
                                role={interactive ? 'button' : undefined}
                                tabindex={interactive ? 0 : undefined}
                                onclick={interactive ? () => onSelectPhase?.(p.id) : undefined}
                                onkeydown={interactive ? (e) => onPhaseKey(e, p.id) : undefined}
                            >
                                <span class="sw-srow-actor">{pick(a.label, $lang)}</span>
                                <div class="sw-srow-body">
                                    {#each cs as c, i (i)}{@render cellBody(c)}{/each}
                                </div>
                            </div>
                        {/if}
                    {/each}
                </div>
            </section>
        {/each}
    </div>
</div>

<!-- Who deals with whom — the money flows between actors, by phase (point 3). -->
{#if showInteractions && interactions.length}
    <div class="sw-flows">
        <h4 class="sw-flows-title">{$t('plan.journey.interactions')}</h4>
        {#each phases as p (p.id)}
            {@const fl = interactions.filter((it) => it.phase === p.id)}
            {#if fl.length}
                <div class="sw-flow-phase">
                    <span class="sw-flow-phase-name">{pick(p.label, $lang)}</span>
                    <ul class="sw-flow-list">
                        {#each fl as it, i (i)}
                            <li class="sw-flow">
                                <span class="sw-flow-parties"
                                    >{actorLabel(it.from_actor)} → {actorLabel(it.to_actor)}</span
                                >
                                {#if it.flows?.length}
                                    <span class="sw-flow-items">
                                        {#each it.flows as f, fi (fi)}
                                            <span class="sw-flow-item">
                                                {pick(f.label, $lang)}{#if amountLabel(f.amount)}{@const z =
                                                        isZero(f.amount)}
                                                    <span
                                                        class="sw-flow-amt"
                                                        class:sw-out={!z && f.direction === 'out'}
                                                        class:sw-in={!z && f.direction === 'in'}
                                                        >{#if !z}{f.direction === 'out' ? '−' : '+'}{/if}{amountLabel(
                                                            f.amount
                                                        )}</span
                                                    >{/if}
                                            </span>
                                        {/each}
                                    </span>
                                {/if}
                            </li>
                        {/each}
                    </ul>
                </div>
            {/if}
        {/each}
    </div>
{/if}

<NoteList notes={o.key_assumptions} />

<style>
    /* The projection reacts to its OWN width (sheet / side-panel), not the viewport. */
    .sw-root {
        container-type: inline-size;
        margin-bottom: 0.5rem;
    }

    /* ── shared cell body ─────────────────────────────────────────────── */
    .sw-item {
        margin: 0;
        font-size: 0.72rem;
        line-height: 1.3;
        color: var(--ink);
    }
    .sw-amount {
        align-self: flex-start;
        font-size: 0.72rem;
        font-weight: 700;
        font-variant-numeric: tabular-nums;
        padding: 0.05rem 0.35rem;
        border-radius: 0.3rem;
        background: color-mix(in srgb, var(--accent) 12%, transparent);
        color: var(--accent);
        white-space: nowrap;
    }
    .sw-out {
        background: var(--danger-soft);
        color: var(--danger);
    }
    .sw-in {
        background: color-mix(in srgb, var(--accent) 14%, transparent);
        color: var(--accent);
    }
    /* a $0 flow: calm and neutral, no outflow red, no sign. */
    .sw-nil {
        background: var(--bg);
        color: var(--muted);
    }
    .sw-tag {
        align-self: flex-start;
        font-size: 0.62rem;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        color: var(--muted);
        border: 1px solid var(--border);
        border-radius: 0.3rem;
        padding: 0.02rem 0.3rem;
    }

    /* ── WIDE: grid swimlane ──────────────────────────────────────────── */
    .sw-wrap {
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
    }
    .sw-grid {
        display: grid;
        gap: 1px;
        background: var(--border);
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        overflow: hidden;
        min-width: max-content;
    }
    .sw-corner {
        background: var(--surface);
    }
    .sw-phase {
        background: var(--bg);
        padding: 0.35rem 0.5rem;
        font-size: 0.72rem;
        font-weight: 700;
        color: var(--ink);
        text-align: center;
        white-space: nowrap;
    }
    .sw-actor {
        background: var(--bg);
        padding: 0.4rem 0.5rem;
        font-size: 0.7rem;
        font-weight: 600;
        color: var(--muted);
        position: sticky;
        left: 0;
        z-index: 1;
        display: flex;
        align-items: center;
    }
    .sw-cell {
        background: var(--surface);
        padding: 0.4rem 0.5rem;
        display: flex;
        flex-direction: column;
        gap: 0.3rem;
        min-height: 2.2rem;
    }

    /* When the swimlane is the navigation (onSelectPhase), phase headers and item cells
       become role=button click targets — add the affordance + selected state. */
    .sw-clickable {
        cursor: pointer;
        transition: background 0.12s ease;
    }
    .sw-clickable:hover {
        background: color-mix(in srgb, var(--accent) 8%, var(--surface));
    }
    .sw-cell.sw-selected,
    .sw-phase.sw-selected {
        box-shadow: inset 0 0 0 2px var(--accent);
        background: color-mix(in srgb, var(--accent) 6%, var(--surface));
    }
    .sw-ph-head.sw-selected {
        color: var(--accent);
    }

    /* ── NARROW: vertical phase-stack (hidden until the container is small) ── */
    .sw-stack {
        display: none;
    }
    .sw-ph {
        position: relative;
        padding: 0 0 0.5rem 0.9rem;
        /* the timeline spine connecting the phases */
        border-left: 2px solid var(--border);
        margin-left: 0.25rem;
    }
    .sw-ph:last-of-type {
        border-left-color: transparent;
    }
    .sw-ph-head {
        display: flex;
        align-items: center;
        gap: 0.4rem;
        margin: 0 0 0.35rem;
    }
    .sw-ph-dot {
        position: absolute;
        left: -0.43rem;
        width: 0.7rem;
        height: 0.7rem;
        border-radius: 50%;
        background: var(--accent);
        border: 2px solid var(--surface);
    }
    .sw-ph-name {
        font-size: 0.8rem;
        font-weight: 700;
        color: var(--ink);
    }
    .sw-ph-step {
        margin-left: auto;
        font-size: 0.66rem;
        color: var(--muted);
        font-variant-numeric: tabular-nums;
    }
    .sw-ph-rows {
        display: flex;
        flex-direction: column;
        gap: 0.4rem;
    }
    .sw-srow {
        display: grid;
        grid-template-columns: 4.5rem 1fr;
        gap: 0.5rem;
        align-items: start;
        padding: 0.35rem 0.5rem;
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 0.4rem;
    }
    .sw-srow-actor {
        font-size: 0.66rem;
        font-weight: 600;
        color: var(--muted);
        padding-top: 0.1rem;
    }
    .sw-srow-body {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        min-width: 0;
    }
    .sw-srow-body .sw-item {
        font-size: 0.78rem;
    }
    .sw-srow-body .sw-amount {
        font-size: 0.78rem;
    }

    @container (max-width: 600px) {
        .sw-asgrid {
            display: none;
        }
        .sw-stack {
            display: block;
        }
    }

    /* ── Who deals with whom — interactions by phase ──────────────────────── */
    .sw-flows {
        margin-top: 0.8rem;
        border-top: 1px solid var(--border);
        padding-top: 0.6rem;
    }
    .sw-flows-title {
        margin: 0 0 0.5rem;
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--ink);
    }
    .sw-flow-phase {
        display: grid;
        grid-template-columns: minmax(5rem, 0.4fr) 1fr;
        gap: 0.5rem;
        padding: 0.3rem 0;
        border-bottom: 1px dashed var(--border);
    }
    .sw-flow-phase:last-child {
        border-bottom: none;
    }
    .sw-flow-phase-name {
        font-size: 0.72rem;
        font-weight: 600;
        color: var(--accent);
        text-transform: uppercase;
        letter-spacing: 0.03em;
        padding-top: 0.15rem;
    }
    .sw-flow-list {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.35rem;
    }
    .sw-flow-parties {
        display: block;
        font-size: 0.78rem;
        font-weight: 600;
        color: var(--ink);
    }
    .sw-flow-items {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem 0.6rem;
        margin-top: 0.1rem;
    }
    .sw-flow-item {
        font-size: 0.76rem;
        color: var(--muted);
    }
    .sw-flow-amt {
        font-weight: 700;
        font-variant-numeric: tabular-nums;
        color: var(--accent);
    }
    .sw-flow-amt.sw-out {
        color: var(--danger);
    }
    .sw-flow-amt.sw-in {
        color: var(--success);
    }
</style>
