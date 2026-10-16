<script lang="ts">
    // Whole lifecycle -> honest-partial; one computer per figure -> the web frontend -> the lifecycle sheet
    // Purpose:   the plan's bird's-eye layer (behavior 82): every money line from buying to
    //            owning to selling on one page, grouped Buy / Own / Sell, with three totals.
    // Holds:     it computes no figure. Lines are the engine's cash events (harvested like
    //            the calculator's spine, plus disposition's dispose events); the totals and
    //            the waiting lines are purchase_journey.lifecycle_budget. A line whose input
    //            is missing says which input, never a figure. Tapping a line opens its
    //            source component (the zoom-in layer) through `onopen`.
    // Rests on:  fh_engine_journey's lifecycle_budget block (what each total sums).
    // Known gaps: the hold-years choice is a what-if preview (the cockpit's horizon), not
    //            saved until the plan is saved from the budget tab.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        harvestCashEvents,
        type CashEvent,
        type ComponentEntry,
        type DispositionOutcome,
        type JourneySwimlaneOutcome,
        type MoneyRange,
        type PendingLine
    } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';

    let {
        components,
        filling,
        horizon,
        busy = false,
        onhorizon,
        onopen
    }: {
        components: Record<string, ComponentEntry>;
        filling: boolean;
        /** The hold years currently shown (0 = none chosen). */
        horizon: number;
        busy?: boolean;
        onhorizon: (years: number) => void;
        onopen: (componentId: string) => void;
    } = $props();

    const BUY_PHASES = ['prepare', 'pre_approve', 'contract', 'settle'];
    const HOLD_CHOICES = [5, 10, 15, 20, 30];

    const disposeEvents = $derived(
        ((components.disposition?.outcome as DispositionOutcome | undefined)?.dispose_cash_events ??
            []) as CashEvent[]
    );
    const events = $derived(harvestCashEvents(components));
    const budget = $derived(
        (components.purchase_journey?.outcome as JourneySwimlaneOutcome | undefined)?.lifecycle_budget ??
            null
    );
    const pending = $derived((budget?.pending ?? []) as PendingLine[]);

    const groups = $derived([
        {
            key: 'buy',
            title: $t('plan.sheet.buy'),
            sub: $t('plan.sheet.buy_sub'),
            lines: events.filter((e) => BUY_PHASES.includes(e.phase)),
            total: budget?.buy ?? null,
            totalLabel: $t('plan.sheet.total_buy'),
            perYear: false
        },
        {
            key: 'own',
            title: $t('plan.sheet.own'),
            sub: $t('plan.sheet.own_sub'),
            lines: events.filter((e) => e.phase === 'own'),
            total: budget?.own_per_year ?? null,
            totalLabel: $t('plan.sheet.total_own'),
            perYear: true
        },
        {
            key: 'sell',
            title: $t('plan.sheet.sell'),
            sub: $t('plan.sheet.sell_sub'),
            lines: disposeEvents,
            total: budget?.sell ?? null,
            totalLabel: $t('plan.sheet.total_sell'),
            perYear: false
        }
    ]);
    const hasGrant = $derived(events.some((e) => e.direction === 'in' && BUY_PHASES.includes(e.phase)));
    const holdPending = $derived(pending.some((p) => p.needs === 'hold_years'));

    function range(r: MoneyRange | null | undefined): string {
        if (!r) return '—';
        return (r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang)) ?? '—';
    }
    // The dispose events' owner is disposition; every other event names its own.
    function owner(e: CashEvent): string | null {
        const id = e.phase === 'dispose' ? 'disposition' : (e.source_component ?? null);
        return id && components[id] ? id : null;
    }
    function needsLabel(p: PendingLine): string {
        return $t(`plan.sheet.needs.${p.needs}` as 'plan.sheet.needs.income');
    }
</script>

<section class="ls" aria-labelledby="ls-title">
    <header class="ls-head">
        <h3 id="ls-title" class="ls-title">{$t('plan.sheet.title')}</h3>
        <p class="ls-sub">{$t('plan.sheet.sub')}</p>
    </header>

    <!-- Summary before detail: the three totals, readable without opening anything. -->
    <dl class="ls-totals">
        {#each groups as g (g.key)}
            <div class="ls-total" data-group={g.key}>
                <dt>{g.totalLabel}</dt>
                <dd>
                    {#if g.total}
                        <span class="ls-total-fig">{range(g.total)}</span>{#if g.perYear}<span class="ls-unit">{$t('plan.sheet.per_year')}</span>{/if}
                    {:else if g.key === 'sell' && holdPending}
                        <span class="ls-needs">{$t('plan.sheet.needs.hold_years')}</span>
                    {:else}
                        <span class="ls-needs">{filling ? $t('plan.sheet.filling') : '—'}</span>
                    {/if}
                </dd>
            </div>
        {/each}
    </dl>

    {#each groups as g (g.key)}
        <div class="ls-group" data-group={g.key}>
            <h4 class="ls-group-title">{g.title} <span class="ls-group-sub">{g.sub}</span></h4>

            {#if g.key === 'sell'}
                <div class="ls-hold" role="group" aria-label={$t('plan.sheet.hold_q')}>
                    <span class="ls-hold-q">{$t('plan.sheet.hold_q')}</span>
                    <div class="ls-hold-chips">
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
                </div>
            {/if}

            <ul class="ls-lines">
                {#each g.lines as e (e.id)}
                    {@const own = owner(e)}
                    <li class="ls-line" class:ls-in={e.direction === 'in'}>
                        {#if own}
                            <button type="button" class="ls-line-btn" onclick={() => onopen(own)}>
                                {@render body(e)}
                                <span class="ls-caret" aria-hidden="true">›</span>
                            </button>
                        {:else}
                            <div class="ls-line-btn ls-static">{@render body(e)}</div>
                        {/if}
                    </li>
                {/each}
                {#if g.key === 'sell'}
                    {#each pending as p (p.id)}
                        <li class="ls-line ls-pending">
                            <div class="ls-line-btn ls-static">
                                <span class="ls-label">
                                    {$t(`plan.sheet.line.${p.id}` as 'plan.sheet.line.loan_payout')}
                                    <span class="ls-needs">{needsLabel(p)}</span>
                                </span>
                                <span class="ls-amt">—</span>
                            </div>
                        </li>
                    {/each}
                {/if}
                {#if g.lines.length === 0 && !(g.key === 'sell' && pending.length)}
                    <li class="ls-empty">{filling ? $t('plan.sheet.filling') : $t('plan.sheet.none')}</li>
                {/if}
            </ul>
            {#if g.key === 'buy' && hasGrant}
                <p class="ls-note">{$t('plan.sheet.grant_note')}</p>
            {/if}
        </div>
    {/each}
</section>

{#snippet body(e: CashEvent)}
    <span class="ls-label">
        {pick(e.label, $lang)}
        <span class="ls-tier" class:ls-exact={!e.is_estimate}
            >{e.is_estimate ? $t('plan.sheet.estimate') : $t('plan.sheet.exact')}</span
        >
    </span>
    <span class="ls-amt"
        >{e.direction === 'in' ? '+' : ''}{range(e.amount)}{#if e.timing === 'recurring'}<span class="ls-unit"
                >{$t('plan.sheet.per_year')}</span
            >{/if}</span
    >
{/snippet}

<style>
    .ls { display: grid; gap: 1rem; }
    .ls-head { display: grid; gap: 0.25rem; }
    .ls-title { margin: 0; font-size: var(--fs-lg, 1.125rem); color: var(--ink); text-wrap: balance; }
    .ls-sub { margin: 0; font-size: var(--fs-sm, 0.875rem); color: var(--muted); }

    .ls-totals {
        margin: 0; display: grid; gap: 0.5rem;
        grid-template-columns: repeat(auto-fit, minmax(9.5rem, 1fr));
    }
    .ls-total {
        background: var(--surface); border: 1px solid var(--border); border-radius: 0.75rem;
        padding: 0.65rem 0.75rem; display: grid; gap: 0.2rem; align-content: start;
    }
    .ls-total[data-group='buy'] { border-color: var(--accent-line); background: var(--accent-soft); }
    .ls-total dt {
        font-size: var(--fs-2xs, 0.6875rem); font-weight: 700; color: var(--muted);
        text-transform: uppercase; letter-spacing: 0.04em;
    }
    .ls-total dd { margin: 0; color: var(--ink); }
    .ls-total-fig { font-weight: 700; font-variant-numeric: tabular-nums; }

    .ls-group { display: grid; gap: 0.4rem; }
    .ls-group-title {
        margin: 0; font-size: var(--fs-sm, 0.875rem); font-weight: 700; color: var(--accent);
        text-transform: uppercase; letter-spacing: 0.04em;
    }
    .ls-group-sub { font-weight: 500; color: var(--muted); text-transform: none; letter-spacing: 0; }

    .ls-lines {
        list-style: none; margin: 0; padding: 0; background: var(--surface);
        border: 1px solid var(--border); border-radius: 0.75rem; overflow: hidden;
    }
    .ls-line + .ls-line, .ls-line + .ls-empty { border-top: 1px solid var(--border); }
    .ls-line-btn {
        width: 100%; display: flex; align-items: baseline; gap: 0.75rem;
        padding: 0.6rem 0.75rem; background: none; border: 0; text-align: left;
        font: inherit; color: var(--ink);
    }
    button.ls-line-btn { cursor: pointer; }
    button.ls-line-btn:hover { background: var(--accent-soft); }
    button.ls-line-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    .ls-label { flex: 1 1 auto; min-width: 0; display: flex; flex-wrap: wrap; gap: 0.25rem 0.5rem; align-items: baseline; }
    .ls-amt { flex: 0 0 auto; font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 600; }
    .ls-in .ls-amt { color: var(--success); }
    .ls-unit { font-weight: 400; color: var(--muted); font-size: 0.85em; }
    .ls-caret { color: var(--muted); }
    .ls-tier {
        font-size: var(--fs-2xs, 0.6875rem); color: var(--warning); background: var(--warning-soft);
        border-radius: 999px; padding: 0 0.45rem; line-height: 1.5;
    }
    .ls-tier.ls-exact { color: var(--info); background: var(--info-soft); }
    .ls-needs { font-size: var(--fs-xs, 0.75rem); color: var(--muted); font-style: italic; }
    .ls-pending .ls-amt { color: var(--muted); }
    .ls-empty { padding: 0.6rem 0.75rem; font-size: var(--fs-xs, 0.75rem); color: var(--muted); font-style: italic; }
    .ls-note { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); }

    .ls-hold { display: flex; flex-wrap: wrap; align-items: center; gap: 0.4rem 0.75rem; }
    .ls-hold-q { font-size: var(--fs-sm, 0.875rem); color: var(--ink); }
    .ls-hold-chips { display: flex; flex-wrap: wrap; gap: 0.35rem; }
    .ls-chip {
        font: inherit; font-size: var(--fs-xs, 0.75rem); padding: 0.25rem 0.65rem;
        border: 1px solid var(--border-strong); border-radius: 999px;
        background: var(--surface); color: var(--ink); cursor: pointer;
    }
    .ls-chip[aria-pressed='true'] { background: var(--accent); border-color: var(--accent); color: var(--accent-ink); }
    .ls-chip:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .ls-chip:disabled { opacity: 0.6; cursor: progress; }
</style>
