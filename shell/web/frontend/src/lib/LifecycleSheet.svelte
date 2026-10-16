<script lang="ts">
    // Whole lifecycle -> honest-partial; one computer per figure -> the web frontend -> the lifecycle statement
    // Purpose:   the plan's first sheet (behavior 93, over behavior 82's lines): the whole
    //            lifecycle budget read top to bottom like a P&L — one row per phase (Buy,
    //            Own per year, Sell), its figure right-aligned, and a bottom line: the total
    //            paid over the hold chosen on the statement (buy + own × years + sell).
    //            Tapping a phase opens its sheet (that phase's lines); tapping a line opens
    //            its detail — a fee line in place (behavior 83), any other its source
    //            component through `onopen`. Each layer is a history entry (shallow
    //            routing, page.state.lifecycle), so back returns one layer at a time.
    // Holds:     it computes no figure but the bottom line, and that only as a sum of the
    //            engine's own totals (purchase_journey.lifecycle_budget) with the hold the
    //            sell figures were computed for (disposition.horizon_years) — never a
    //            forecast. Lines are the engine's cash events. A line the engine's totals do
    //            not sum (a grant or sale price coming in, an optional or still-conditional
    //            fee, the loan payout, a line waiting on an input) sits after one quiet
    //            divider, never tagged one by one; a line waiting on an input says which.
    //            Every sheet here follows the clean-sheet rule (architecture.md, Design
    //            rules): one job, its figure first, the rest one tap down — no subtitles,
    //            an estimate is one small mark keyed once at the foot.
    // Rests on:  fh_engine_journey's lifecycle_budget block (what each total sums: the
    //            `counted` test below mirrors its out/1, own's recurring and payout/1).
    //            Behavior 96: the plan's state is text in the statement's head, never a
    //            choice — a plan is for one state (81); another state is another plan,
    //            made from the planner's list.
    // Known gaps: the hold-years choice is a what-if preview (the cockpit's horizon), not
    //            saved until the plan is saved from the budget tab.
    import { tick } from 'svelte';
    import { pushState } from '$app/navigation';
    import { page } from '$app/state';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        harvestCashEvents,
        type CashEvent,
        type ComponentEntry,
        type DispositionOutcome,
        type JourneySwimlaneOutcome,
        type FeeDetail,
        type MoneyRange,
        type PendingLine
    } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';

    let {
        components,
        filling,
        horizon,
        planState,
        busy = false,
        onhorizon,
        onopen
    }: {
        components: Record<string, ComponentEntry>;
        filling: boolean;
        /** The hold years currently chosen (0 = none chosen). */
        horizon: number;
        /** The state the figures are planned for. */
        planState: string;
        busy?: boolean;
        onhorizon: (years: number) => void;
        onopen: (componentId: string) => void;
    } = $props();

    type PhaseKey = 'buy' | 'own' | 'sell';
    const BUY_PHASES = ['prepare', 'pre_approve', 'contract', 'settle'];
    const HOLD_CHOICES = [5, 10, 15, 20, 30];

    const disposition = $derived(components.disposition?.outcome as DispositionOutcome | undefined);
    const disposeEvents = $derived((disposition?.dispose_cash_events ?? []) as CashEvent[]);
    const events = $derived(harvestCashEvents(components));
    const budget = $derived(
        (components.purchase_journey?.outcome as JourneySwimlaneOutcome | undefined)?.lifecycle_budget ??
            null
    );
    const pending = $derived((budget?.pending ?? []) as PendingLine[]);
    const holdPending = $derived(pending.some((p) => p.needs === 'hold_years'));

    const groups = $derived([
        {
            key: 'buy' as PhaseKey,
            title: $t('plan.sheet.buy'),
            lines: events.filter((e) => BUY_PHASES.includes(e.phase)),
            total: budget?.buy ?? null,
            perYear: false
        },
        {
            key: 'own' as PhaseKey,
            title: $t('plan.sheet.own'),
            lines: events.filter((e) => e.phase === 'own'),
            total: budget?.own_per_year ?? null,
            perYear: true
        },
        {
            key: 'sell' as PhaseKey,
            title: $t('plan.sheet.sell'),
            lines: disposeEvents,
            total: budget?.sell ?? null,
            perYear: false
        }
    ]);

    // The bottom line: the total paid over the hold, low and high ends — the engine's three
    // totals summed, own taken once per year of the hold the sell figures were made for.
    const holdYears = $derived(disposition?.horizon_years ?? 0);
    const bottom = $derived.by((): MoneyRange | null => {
        const b = budget;
        if (!b?.buy || !b.own_per_year || !b.sell || !holdYears) return null;
        return [
            b.buy[0] + b.own_per_year[0] * holdYears + b.sell[0],
            b.buy[1] + b.own_per_year[1] * holdYears + b.sell[1]
        ];
    });

    // The open layer: the statement (null) or one phase's sheet, kept in the history entry.
    const openKey = $derived(page.state.lifecycle ?? null);
    const openGroup = $derived(groups.find((g) => g.key === openKey) ?? null);
    let rootEl: HTMLElement | undefined = $state();
    async function toTop() {
        await tick();
        rootEl?.closest('.body')?.scrollTo({ top: 0 });
    }
    function openPhase(key: PhaseKey) {
        // over whatever layer the page is on (the planner's list, behavior 96)
        pushState('', { ...page.state, lifecycle: key });
        void toTop();
    }
    function back() {
        history.back();
        void toTop();
    }

    function range(r: MoneyRange | null | undefined): string {
        if (!r) return '—';
        return (r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang)) ?? '—';
    }
    // A statement figure breaks only after its dash: each end of the range stays whole.
    function rangeEnds(r: MoneyRange): string[] {
        if (r[0] === r[1]) return [money(r[0], $lang) ?? '—'];
        return [`${money(r[0], $lang) ?? '—'} –`, money(r[1], $lang) ?? '—'];
    }
    // The dispose events' owner is disposition; every other event names its own.
    function owner(e: CashEvent): string | null {
        const id = e.phase === 'dispose' ? 'disposition' : (e.source_component ?? null);
        return id && components[id] ? id : null;
    }
    // Whether the engine's total for this phase sums the line (fh_engine_journey:
    // out/1 — an out-event, not optional, no open condition; own: recurring; sell: not the
    // loan payout, which the sale proceeds repay).
    function counted(e: CashEvent, key: PhaseKey): boolean {
        if (e.direction !== 'out') return false;
        if (e.detail && (e.detail.optional || e.detail.condition)) return false;
        if (key === 'own') return e.timing === 'recurring';
        if (key === 'sell') return e.id !== 'dispose_loan_payout';
        return true;
    }
    // a pending line sits in its own phase's sheet: buy, own or sell.
    function groupOf(phase: string): PhaseKey {
        return phase === 'own' ? 'own' : phase === 'dispose' ? 'sell' : 'buy';
    }
    function pendingFor(key: PhaseKey): PendingLine[] {
        return pending.filter((p) => groupOf(p.phase) === key);
    }
    function pendingLabel(p: PendingLine): string {
        return p.label
            ? pick(p.label, $lang)
            : $t(`plan.sheet.line.${p.id}` as 'plan.sheet.line.loan_payout');
    }
    function needsLabel(p: PendingLine): string {
        return $t(`plan.sheet.needs.${p.needs}` as 'plan.sheet.needs.income');
    }
    // why a shown line is left out of the total (opened with its detail), or null.
    function notCounted(d: FeeDetail): string | null {
        if (d.optional) return $t('plan.sheet.fee.optional');
        if (d.condition === 'strata') return $t('plan.sheet.fee.if_strata');
        if (d.condition === 'house') return $t('plan.sheet.fee.if_house');
        return null;
    }
    // a percentage line states its rate and base; a fixed line's range is its amount.
    function basisText(d: FeeDetail): string | null {
        const [lo, hi] = d.band;
        if (d.basis === 'fixed' || lo == null || hi == null) return null;
        const fmt = (n: number) => n.toLocaleString($lang === 'vi' ? 'vi-VN' : 'en-AU');
        return $t(`plan.sheet.basis.${d.basis}` as 'plan.sheet.basis.pct_of_sale')
            .replace('{lo}', fmt(lo))
            .replace('{hi}', fmt(hi));
    }
    function sourceHost(url: string): string {
        try {
            return new URL(url).hostname.replace(/^www\./, '');
        } catch {
            return url;
        }
    }
</script>

{#if openGroup}
    {@const g = openGroup}
    {@const inTotal = g.lines.filter((e) => counted(e, g.key))}
    {@const rest = g.lines.filter((e) => !counted(e, g.key))}
    {@const waiting = pendingFor(g.key)}
    <section class="ls" data-group={g.key} bind:this={rootEl} aria-labelledby="ls-phase-title">
        <button type="button" class="ls-back" onclick={back}
            ><span aria-hidden="true">‹</span> {$t('plan.sheet.back')}</button
        >
        <h3 id="ls-phase-title" class="ls-row ls-phase-head">
            <span class="ls-row-label">{g.title}</span>
            <span class="ls-row-fig">{@render total(g.key, g.total, g.perYear)}</span>
        </h3>

        {#if inTotal.length > 0}
            <ul class="ls-lines">
                {#each inTotal as e (e.id)}{@render line(e)}{/each}
            </ul>
        {:else if rest.length === 0 && waiting.length === 0}
            <p class="ls-empty">{filling ? $t('plan.sheet.filling') : $t('plan.sheet.none')}</p>
        {/if}

        {#if rest.length > 0 || waiting.length > 0}
            <p class="ls-divider">{$t('plan.sheet.not_in_total')}</p>
            <ul class="ls-lines ls-rest">
                {#each rest as e (e.id)}{@render line(e)}{/each}
                {#each waiting as p (p.id)}
                    <li class="ls-line">
                        <div class="ls-line-btn ls-static">
                            <span class="ls-label">{pendingLabel(p)}</span>
                            <span class="ls-needs">{needsLabel(p)}</span>
                        </div>
                    </li>
                {/each}
            </ul>
        {/if}

        {#if g.lines.some((e) => e.is_estimate)}
            <p class="ls-key">{$t('plan.sheet.key')}</p>
        {/if}
    </section>
{:else}
    <section class="ls" bind:this={rootEl} aria-labelledby="ls-title">
        <div class="ls-head">
            <h3 id="ls-title" class="ls-title">{$t('plan.sheet.title')}</h3>
            {#if planState}<span class="ls-state" aria-label={$t('plan.sheet.state_q')}>{planState}</span>{/if}
        </div>

        <ul class="ls-statement">
            {#each groups as g (g.key)}
                <li>
                    <button type="button" class="ls-row" data-group={g.key} onclick={() => openPhase(g.key)}>
                        <span class="ls-row-label">{g.title}</span>
                        <span class="ls-row-fig">{@render total(g.key, g.total, g.perYear)}</span>
                        <span class="ls-caret" aria-hidden="true">›</span>
                    </button>
                </li>
            {/each}
        </ul>

        <div class="ls-row ls-bottom">
            <span class="ls-row-label"
                >{holdYears
                    ? $t('plan.sheet.total_hold').replace('{n}', String(holdYears))
                    : $t('plan.sheet.total_hold_none')}</span
            >
            <span class="ls-row-fig"
                >{#if bottom}{@render ends(bottom)}{:else if busy || filling}{@render skel()}{:else}—{/if}</span
            >
        </div>

        <div class="ls-hold" role="group" aria-label={$t('plan.sheet.hold_q')}>
            {#each HOLD_CHOICES as y (y)}
                <button
                    type="button"
                    class="ls-chip"
                    aria-pressed={horizon === y}
                    disabled={busy}
                    onclick={() => onhorizon(y)}>{y} {$t('plan.sheet.years')}</button
                >
            {/each}
        </div>
    </section>
{/if}

{#snippet total(key: PhaseKey, r: MoneyRange | null, perYear: boolean)}
    {#if r}
        {@render ends(r)}{#if perYear}<span class="ls-unit">{$t('plan.sheet.per_year')}</span>{/if}
    {:else if busy || filling}
        {@render skel()}
    {:else if key === 'sell' && holdPending}
        <span class="ls-needs">{$t('plan.sheet.needs.hold_years')}</span>
    {:else}
        —
    {/if}
{/snippet}

<!-- Behavior 92: the moment a figure is still on its way (the hold preview, well under a
     second) holds a still bar, never words — the plan never says it is still working. -->
{#snippet skel()}
    <span class="ls-skel" role="img" aria-label={$t('plan.sheet.filling')}></span>
{/snippet}

{#snippet ends(r: MoneyRange)}
    {#each rangeEnds(r) as end, i (i)}{#if i > 0}{' '}{/if}<span class="ls-end">{end}</span>{/each}
{/snippet}

{#snippet line(e: CashEvent)}
    {@const own = owner(e)}
    <li class="ls-line" class:ls-in={e.direction === 'in'}>
        {#if e.detail}
            {@render fee(e, e.detail)}
        {:else if own}
            <button type="button" class="ls-line-btn" onclick={() => onopen(own)}>
                {@render body(e)}
                <span class="ls-caret" aria-hidden="true">›</span>
            </button>
        {:else}
            <div class="ls-line-btn ls-static">{@render body(e)}</div>
        {/if}
    </li>
{/snippet}

{#snippet fee(e: CashEvent, d: FeeDetail)}
    {@const why = notCounted(d)}
    {@const basis = basisText(d)}
    <details class="ls-fee">
        <summary class="ls-line-btn">
            {@render body(e)}
            <span class="ls-caret ls-fee-caret" aria-hidden="true">›</span>
        </summary>
        <div class="ls-fee-detail">
            {#if why}<p class="ls-fee-why">{why}</p>{/if}
            <dl class="ls-fee-facts">
                {#if basis}
                    <div><dt>{$t('plan.sheet.fee.range')}</dt><dd>{basis}</dd></div>
                {/if}
                {#if d.payer}
                    <div><dt>{$t('plan.sheet.fee.payer')}</dt><dd>{pick(d.payer, $lang)}</dd></div>
                {/if}
                {#if d.drivers}
                    <div><dt>{$t('plan.sheet.fee.drivers')}</dt><dd>{pick(d.drivers, $lang)}</dd></div>
                {/if}
                {#if d.source}
                    <div>
                        <dt>{$t('plan.sheet.fee.source')}</dt>
                        <dd>
                            <a href={d.source} target="_blank" rel="noopener noreferrer"
                                >{sourceHost(d.source)}</a
                            >
                        </dd>
                    </div>
                {/if}
            </dl>
            <p class="ls-fee-note">
                {d.tier === 'REGULATED' ? $t('plan.sheet.fee.regulated_note') : $t('plan.sheet.fee.quote_note')}
            </p>
        </div>
    </details>
{/snippet}

{#snippet body(e: CashEvent)}
    <span class="ls-label">{pick(e.label, $lang)}</span>
    <span class="ls-amt"
        >{#if e.is_estimate}<span class="ls-mark" title={$t('plan.sheet.estimate')}>≈</span>{/if}{e.direction ===
        'in'
            ? '+'
            : ''}{range(e.amount)}{#if e.timing === 'recurring'}<span class="ls-unit"
                >{$t('plan.sheet.per_year')}</span
            >{/if}</span
    >
{/snippet}

<style>
    .ls { display: grid; gap: 0.75rem; }
    .ls-head { display: flex; align-items: center; justify-content: space-between; gap: 0.75rem; }
    .ls-title { margin: 0; font-size: var(--fs-lg, 1.125rem); color: var(--ink); }
    .ls-state { font-size: var(--fs-sm, 0.875rem); font-weight: 700; letter-spacing: 0.04em; color: var(--muted); }

    /* The statement: one row per phase, its figure right-aligned, then the bottom line. */
    .ls-statement {
        list-style: none; margin: 0; padding: 0; background: var(--surface);
        border: 1px solid var(--border); border-radius: 0.75rem; overflow: hidden;
    }
    .ls-statement li + li { border-top: 1px solid var(--border); }
    .ls-row {
        width: 100%; display: flex; align-items: baseline; gap: 0.75rem;
        padding: 0.85rem 0.9rem; margin: 0; background: none; border: 0; text-align: left;
        font: inherit; font-size: var(--fs-md, 1rem); color: var(--ink);
    }
    button.ls-row { cursor: pointer; }
    button.ls-row:hover { background: var(--accent-soft); }
    button.ls-row:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    /* The label keeps its line; on a phone a long range wraps inside the figure's column. */
    .ls-row-label { flex: 0 0 auto; white-space: nowrap; font-weight: 600; }
    .ls-row-fig {
        flex: 1 1 auto; min-width: 0; text-align: right; font-weight: 700;
        font-variant-numeric: tabular-nums; text-wrap: balance;
    }
    .ls-end { white-space: nowrap; }
    .ls-bottom { border-top: 2px solid var(--ink); border-radius: 0; padding-top: 0.75rem; }
    .ls-bottom .ls-row-fig { font-size: var(--fs-lg, 1.125rem); }
    .ls-bottom .ls-row-label { font-weight: 700; }

    .ls-hold { display: flex; flex-wrap: wrap; gap: 0.35rem; }
    .ls-chip {
        font: inherit; font-size: var(--fs-xs, 0.75rem); padding: 0.3rem 0.7rem;
        border: 1px solid var(--border-strong); border-radius: 999px;
        background: var(--surface); color: var(--ink); cursor: pointer;
    }
    .ls-chip[aria-pressed='true'] { background: var(--accent); border-color: var(--accent); color: var(--accent-ink); }
    .ls-chip:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .ls-chip:disabled { opacity: 0.6; cursor: progress; }

    /* A phase's sheet: back, its title and figure first, its lines, the rest. */
    .ls-back {
        justify-self: start; display: inline-flex; align-items: center; gap: 0.3rem;
        padding: 0.25rem 0; background: none; border: 0; font: inherit;
        font-size: var(--fs-sm, 0.875rem); color: var(--accent); cursor: pointer;
    }
    .ls-back:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .ls-phase-head { padding: 0 0 0.25rem; font-size: var(--fs-lg, 1.125rem); }

    .ls-lines {
        list-style: none; margin: 0; padding: 0; background: var(--surface);
        border: 1px solid var(--border); border-radius: 0.75rem; overflow: hidden;
    }
    .ls-line + .ls-line { border-top: 1px solid var(--border); }
    .ls-rest { background: none; }
    .ls-rest .ls-amt { font-weight: 500; color: var(--ink-2, var(--muted)); }
    .ls-divider {
        margin: 0.25rem 0 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted);
        display: flex; align-items: center; gap: 0.5rem;
    }
    .ls-divider::after { content: ''; flex: 1; border-top: 1px dashed var(--border-strong); }
    .ls-line-btn {
        /* Wraps: on a phone a band amount drops under its label rather than squeezing it. */
        width: 100%; display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.25rem 0.75rem;
        padding: 0.6rem 0.75rem; background: none; border: 0; text-align: left;
        font: inherit; color: var(--ink);
    }
    button.ls-line-btn { cursor: pointer; }
    button.ls-line-btn:hover { background: var(--accent-soft); }
    button.ls-line-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    .ls-label { flex: 1 1 10rem; min-width: 0; }
    .ls-amt { flex: 0 0 auto; margin-left: auto; font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 600; }
    .ls-in .ls-amt { color: var(--success); }
    .ls-mark { margin-right: 0.2rem; color: var(--warning); font-weight: 700; }
    .ls-unit { font-weight: 400; color: var(--muted); font-size: 0.85em; }
    .ls-caret { color: var(--muted); }
    .ls-skel { display: inline-block; margin-left: auto; width: 7.5rem; height: 0.9em; vertical-align: middle; border-radius: var(--radius-pill); background: var(--bg-2); }
    .ls-needs { margin-left: auto; font-size: var(--fs-xs, 0.75rem); font-weight: 400; color: var(--muted); font-style: italic; }
    .ls-empty, .ls-key { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); }
    .ls-empty { font-style: italic; }

    /* A fee line opens in place: its summary is the line, its body the facts behind it. */
    .ls-fee > summary { list-style: none; cursor: pointer; }
    .ls-fee > summary::-webkit-details-marker { display: none; }
    .ls-fee > summary:hover { background: var(--accent-soft); }
    .ls-fee > summary:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    .ls-fee-caret { transition: transform 0.15s ease; }
    .ls-fee[open] .ls-fee-caret { transform: rotate(90deg); }
    @media (prefers-reduced-motion: reduce) { .ls-fee-caret { transition: none; } }
    .ls-fee-detail {
        display: grid; gap: 0.5rem; padding: 0 0.75rem 0.75rem;
        font-size: var(--fs-sm, 0.875rem); color: var(--ink);
    }
    .ls-fee-why { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); font-style: italic; }
    .ls-fee-facts { margin: 0; display: grid; gap: 0.4rem; }
    .ls-fee-facts > div { display: grid; gap: 0.1rem; }
    .ls-fee-facts dt {
        font-size: var(--fs-2xs, 0.6875rem); font-weight: 700; color: var(--muted);
        text-transform: uppercase; letter-spacing: 0.04em;
    }
    .ls-fee-facts dd { margin: 0; max-width: 65ch; }
    .ls-fee-facts a { color: var(--accent); overflow-wrap: anywhere; }
    .ls-fee-note { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); }
</style>
