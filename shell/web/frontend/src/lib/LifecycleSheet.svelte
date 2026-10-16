<script lang="ts">
    // Whole lifecycle -> honest-partial; one computer per figure -> the web frontend -> the lifecycle statement
    // Purpose:   the plan's first sheet (behavior 93, over behavior 82's lines): the whole
    //            lifecycle budget read top to bottom like a P&L of costs over the hold
    //            chosen on the statement (behavior 98) — Phí mua, Phí giữ nhà trong N năm
    //            (≈ X/năm beside it), Phí bán, each right-aligned, and the bottom line
    //            "Tổng phí trong N năm", exactly their sum. Money into the home (the deposit,
    //            the loan principal repaid by N) is not a cost: it sits after a divider, with
    //            the cash needed to buy (deposit + Phí mua), on the statement and the Mua sheet.
    //            Tapping a phase opens its sheet (that phase's lines); tapping a line opens
    //            its detail in place — what it is, how its figure is set, who pays, what
    //            moves it, its source (the engine's `detail`: a fee line's, behavior 83, or
    //            any other line's, fh_engine_line_detail, behavior 93); a line never leaves
    //            the sheet for a component card, but a detail whose KB entry `explains`
    //            components draws them under its facts (behavior 95: the FIRB fee → FIRB,
    //            an FX line → money from overseas, "Nguồn tiền" → family funding,
    //            "Tiền thuê thu về" → yield and tax — those two from lifecycle_budget.beside,
    //            after the divider, in no total). A phase sheet is a history entry (shallow routing,
    //            page.state.lifecycle), so back returns to the statement.
    // Holds:     it computes no figure: every row, the bottom line and the money into the
    //            home are the engine's (purchase_journey.lifecycle_budget costs_*, into_home,
    //            buy; fh_engine_journey costs/4), for the hold they were made for
    //            (hold_years). Phí giữ nhà's sheet lists the yearly lines and the loan's
    //            interest over the hold (disposition.loan_over_hold) — the repayments line
    //            itself, principal and interest together, after the divider — and says
    //            "X/năm × N năm"; Phí bán's names the projected sale price and its growth
    //            band (disposition.growth_pct_pa). Lines are the engine's cash events. A line the engine's totals do
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
    //            Behavior 101 (over 95): every number the statement rests on has one home,
    //            "Tài chính của bạn" — a button under the statement opens it as a layer
    //            (page.state.lifecycle 'finances'): the price and the deposit (the
    //            planner's `scenario`: "Xem thử" previews, "Lưu" saves to the plan), "Tiền
    //            bạn có" (a sum the visitor types, set against the cash needed to buy,
    //            lifecycle_budget.buy, at its low and high ends — "Đủ" or "Còn thiếu
    //            <total − sum>" — a subtraction, never a figure of its own; kept in this
    //            browser per plan, localStorage, never sent), then income and debts (the
    //            planner's `household`). Each field says in one line what it moves. The
    //            Mua sheet shows the cash verdict, never an input.
    //            A line's detail (LineDetail, the same body PhaseSheet opens over the
    //            checklist) names the checklist steps that link it; choosing one is
    //            `onstep` — the planner opens Hành trình at that step.
    // Known gaps: the hold-years choice is a what-if preview, not saved with the plan.
    import { tick, type Snippet } from 'svelte';
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
        type PendingLine,
        type BesideLine,
        type PhasePlaybookOutcome
    } from '$lib/planCard';
    import LineDetail, { type LineStep } from '$lib/LineDetail.svelte';
    import { money, moneyRange, num } from '$lib/format';

    let {
        components,
        filling,
        horizon,
        planState,
        busy = false,
        onhorizon,
        planId = null,
        scenario,
        household,
        onstep
    }: {
        components: Record<string, ComponentEntry>;
        filling: boolean;
        /** The hold years currently chosen (0 = none chosen). */
        horizon: number;
        /** The state the figures are planned for. */
        planState: string;
        busy?: boolean;
        onhorizon: (years: number) => void;
        /** The plan whose "Tiền bạn có" this browser keeps. */
        planId?: string | null;
        /** The price and deposit fields with "Xem thử" / "Lưu", drawn first on the finances sheet. */
        scenario?: Snippet;
        /** Income and debts, drawn last on the finances sheet. */
        household?: Snippet;
        /** A step that links a line, chosen from the line's detail: open Hành trình there. */
        onstep?: (s: LineStep) => void;
    } = $props();

    // behavior 95: the checklist steps that link a line — the playbook actions whose
    // budget_ref is the line's id or the figure it belongs to (its group).
    const playbook = $derived(components.phase_playbook?.outcome as PhasePlaybookOutcome | undefined);
    function stepsFor(e: CashEvent): LineStep[] {
        const refs = [e.id, e.group].filter((r): r is string => !!r);
        return (playbook?.phases ?? []).flatMap((p) =>
            (p.actions ?? [])
                .filter((a) => a.budget_ref && refs.includes(a.budget_ref))
                .map((a) => ({ phase: p.phase, id: a.id, label: a.label }))
        );
    }

    // "Tiền bạn có": the visitor's own sum, kept in this browser for this plan only.
    const CASH_KEY = 'fh.cash_on_hand.';
    let cashInput = $state('');
    $effect(() => {
        const id = planId;
        let v = '';
        try {
            if (id) v = localStorage.getItem(CASH_KEY + id) ?? '';
        } catch {
            v = '';
        }
        cashInput = v;
    });
    function keepCash() {
        try {
            if (!planId) return;
            if (cashInput.trim() === '') localStorage.removeItem(CASH_KEY + planId);
            else localStorage.setItem(CASH_KEY + planId, cashInput);
        } catch {
            /* a private window keeps it for this page only */
        }
    }
    const cash = $derived.by((): number | null => {
        const n = Number(cashInput.replace(/[^0-9]/g, ''));
        return cashInput.trim() !== '' && Number.isFinite(n) ? n : null;
    });
    function cashVerdict(need: number, have: number): string {
        return have >= need
            ? $t('plan.sheet.cash_ok')
            : $t('plan.sheet.cash_short').replace('{x}', money(need - have, $lang) ?? '—');
    }

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
    // behavior 95: where the money comes from and the rent coming in — after the divider,
    // in no total (fh_engine_journey beside/1).
    const beside = $derived((budget?.beside ?? []) as BesideLine[]);
    type SheetLine = CashEvent & { needs?: string | null };
    function lineNeeds(e: SheetLine): string | null {
        return e.needs ?? null;
    }
    function besideFor(key: PhaseKey): SheetLine[] {
        return beside
            .filter((b) => groupOf(b.phase) === key)
            .map((b) => ({
                id: b.id,
                label: b.label,
                amount: b.amount as MoneyRange,
                direction: 'in' as const,
                timing: b.timing === 'recurring' ? ('recurring' as const) : ('one_off' as const),
                phase: b.phase,
                is_estimate: b.amount !== null,
                detail: b.detail,
                needs: b.needs
            }));
    }

    // behavior 98: every figure on the statement is the engine's (lifecycle_budget costs/4) —
    // the hold they were made for, the costs and their total, the money into the home.
    const holdYears = $derived(budget?.hold_years ?? disposition?.horizon_years ?? 0);
    const loan = $derived(disposition?.loan_over_hold ?? null);
    const intoHome = $derived(budget?.into_home ?? null);
    const deposits = $derived(events.filter((e) => BUY_PHASES.includes(e.phase) && e.id === 'deposit'));
    const groups = $derived([
        {
            key: 'buy' as PhaseKey,
            title: $t('plan.sheet.costs_buy'),
            lines: events.filter((e) => BUY_PHASES.includes(e.phase) && e.id !== 'deposit'),
            total: budget?.costs_buy ?? null,
            perYear: null as MoneyRange | null
        },
        {
            key: 'own' as PhaseKey,
            title: holdYears
                ? $t('plan.sheet.costs_own').replace('{n}', String(holdYears))
                : $t('plan.sheet.costs_own_none'),
            lines: events.filter((e) => e.phase === 'own'),
            total: budget?.costs_own ?? null,
            perYear: budget?.costs_own_per_year ?? null
        },
        {
            key: 'sell' as PhaseKey,
            title: $t('plan.sheet.costs_sell'),
            lines: disposeEvents,
            total: budget?.costs_sell ?? null,
            perYear: null as MoneyRange | null
        }
    ]);
    // The bottom line: the engine's costs_total, exactly the three rows' sum at each end.
    const bottom = $derived(budget?.costs_total ?? null);

    // The loan's interest over the hold, a line of Phí giữ nhà: the engine's split of the
    // repayments line (disposition.loan_over_hold), with that line's detail — only where the
    // plan has a repayments line, as costs/4 sums it.
    const interestLine = $derived.by((): CashEvent | null => {
        const rep = events.find((e) => e.phase === 'own' && e.id === 'loan_repayments');
        if (!rep || !loan?.interest || !holdYears) return null;
        const label = $t('plan.sheet.interest_hold').replace('{n}', String(holdYears));
        return {
            ...rep,
            id: 'loan_interest_over_hold',
            label: { vi: label, en: label },
            amount: loan.interest,
            timing: 'one_off',
            is_estimate: true
        };
    });

    // One line each on why Phí giữ nhà and Phí bán move with the hold.
    const ownWhy = $derived.by((): string | null => {
        const p = budget?.costs_own_per_year;
        if (!p || !holdYears) return null;
        return $t('plan.sheet.own_why').replace('{x}', range(p)).replace('{n}', String(holdYears));
    });
    const sellWhy = $derived.by((): string | null => {
        const sale = disposition?.sale_proceeds;
        const g = disposition?.growth_pct_pa;
        if (!sale || !g || !holdYears) return null;
        const pct = (x: number) => num(x, $lang) ?? String(x);
        return $t('plan.sheet.sell_why')
            .replace('{n}', String(holdYears))
            .replace('{p}', range(sale))
            .replace('{g}', g[0] === g[1] ? pct(g[0]) : `${pct(g[0])}–${pct(g[1])}`);
    });

    // The open layer: the statement (null) or one phase's sheet, kept in the history entry.
    const openKey = $derived(page.state.lifecycle ?? null);
    const openGroup = $derived(groups.find((g) => g.key === openKey) ?? null);
    let rootEl: HTMLElement | undefined = $state();
    async function toTop() {
        await tick();
        rootEl?.closest('.body')?.scrollTo({ top: 0 });
    }
    function openPhase(key: PhaseKey | 'finances') {
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
    // Whether the engine's total for this phase sums the line (fh_engine_journey:
    // out/1 — an out-event, not optional, no open condition; own: recurring; sell: not the
    // loan payout, which the sale proceeds repay).
    // behavior 98 (costs/4): the deposit is money into the home, never a cost; the loan
    // repayments are not summed as they are — their interest over the hold is (a line of
    // its own), their principal goes into the home.
    function counted(e: CashEvent, key: PhaseKey): boolean {
        if (e.direction !== 'out') return false;
        if (e.detail && (e.detail.optional || e.detail.condition)) return false;
        if (key === 'buy') return e.id !== 'deposit';
        if (key === 'own') return e.timing === 'recurring' && e.id !== 'loan_repayments';
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
</script>

{#if openKey === 'finances' && scenario}
    <!-- behavior 101: "Tài chính của bạn" — price, deposit, cash, income and debts -->
    <section class="ls ls-fin" data-finances bind:this={rootEl} aria-labelledby="ls-fin-title">
        <button type="button" class="ls-back" onclick={back}
            ><span aria-hidden="true">‹</span> {$t('plan.sheet.back')}</button
        >
        <h3 id="ls-fin-title" class="ls-title">{$t('plan.fin.title')}</h3>
        {@render scenario()}
        <div class="ls-cash ls-fin-field">
            <label class="ls-cash-row">
                <span class="ls-label">{$t('plan.sheet.cash')}</span>
                <input
                    class="ls-cash-in"
                    type="text"
                    inputmode="numeric"
                    bind:value={cashInput}
                    oninput={keepCash}
                    placeholder={$t('plan.cash.whatif.placeholder')}
                />
            </label>
            <p class="ls-fin-effect">{$t('plan.fin.cash_effect')}</p>
            {#if cash !== null && budget?.buy}{@render verdict(budget.buy, cash)}{/if}
        </div>
        {#if household}{@render household()}{/if}
    </section>
{:else if openGroup}
    {@const g = openGroup}
    {@const inTotal = g.lines.filter((e) => counted(e, g.key))}
    {@const rest = g.lines.filter((e) => !counted(e, g.key))}
    {@const waiting = pendingFor(g.key)}
    {@const extra = besideFor(g.key)}
    {@const interest = g.key === 'own' ? interestLine : null}
    <section class="ls" data-group={g.key} bind:this={rootEl} aria-labelledby="ls-phase-title">
        <button type="button" class="ls-back" onclick={back}
            ><span aria-hidden="true">‹</span> {$t('plan.sheet.back')}</button
        >
        <h3 id="ls-phase-title" class="ls-row ls-phase-head">
            <span class="ls-row-label">{g.title}</span>
            <span class="ls-row-fig">{@render total(g.key, g.total, null)}</span>
        </h3>
        {#if g.key === 'own' && ownWhy}<p class="ls-why">≈ {ownWhy}</p>{/if}
        {#if g.key === 'sell' && sellWhy}<p class="ls-why">{sellWhy}</p>{/if}

        {#if inTotal.length > 0 || interest}
            <ul class="ls-lines">
                {#each inTotal as e (e.id)}{@render line(e)}{/each}
                {#if interest}{@render line(interest)}{/if}
            </ul>
        {:else if filling && rest.length === 0 && waiting.length === 0}
            <p class="ls-empty">{$t('plan.sheet.filling')}</p>
        {/if}

        {#if g.key === 'buy' && (deposits.length > 0 || intoHome?.deposit)}
            <!-- behavior 98: money that goes into the home, not a cost — apart, in no total -->
            <p class="ls-divider">{$t('plan.sheet.not_a_cost')}</p>
            <div class="ls-into" data-into-home>
                <div class="ls-row ls-into-head">
                    <span class="ls-row-label"
                        >{holdYears
                            ? $t('plan.sheet.into_home_hold').replace('{n}', String(holdYears))
                            : $t('plan.sheet.into_home')}</span
                    >
                    <span class="ls-row-fig"
                        >{#if intoHome?.total}{@render ends(intoHome.total)}{:else if intoHome?.deposit}{@render ends(intoHome.deposit)}{:else}—{/if}</span
                    >
                </div>
                <ul class="ls-lines ls-rest">
                    {#each deposits as e (e.id)}{@render line(e)}{/each}
                    <li class="ls-line">
                        <div class="ls-line-btn ls-static">
                            <span class="ls-label"
                                >{holdYears
                                    ? $t('plan.sheet.into_principal').replace('{n}', String(holdYears))
                                    : $t('plan.sheet.into_principal_none')}</span
                            >
                            {#if intoHome?.principal_repaid}
                                <span class="ls-amt"
                                    ><span class="ls-mark" title={$t('plan.sheet.estimate')}>≈</span>{range(
                                        intoHome.principal_repaid
                                    )}</span
                                >
                            {:else if !holdYears}
                                <span class="ls-needs">{$t('plan.sheet.needs.hold_years')}</span>
                            {:else}
                                <span class="ls-amt">—</span>
                            {/if}
                        </div>
                    </li>
                </ul>
            </div>
        {/if}

        {#if g.key === 'buy' && budget?.buy}
            {@const need = budget.buy}
            <div class="ls-row ls-need" data-cash-to-buy>
                <span class="ls-row-label">{$t('plan.sheet.cash_to_buy')}</span>
                <span class="ls-row-fig">{@render ends(need)}</span>
            </div>
            {#if cash !== null}
                <div class="ls-cash">
                    <span class="ls-label">{$t('plan.sheet.cash')} · {money(cash, $lang)}</span>
                    {@render verdict(need, cash)}
                </div>
            {/if}
        {/if}

        {#if rest.length > 0 || waiting.length > 0 || extra.length > 0}
            <p class="ls-divider">{$t('plan.sheet.not_in_total')}</p>
            <ul class="ls-lines ls-rest">
                {#each rest as e (e.id)}{@render line(e)}{/each}
                {#each extra as e (e.id)}{@render line(e)}{/each}
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
        {#if scenario}
            <button type="button" class="ls-fin-open" data-finances-open onclick={() => openPhase('finances')}
                >{$t('plan.fin.title')} <span class="ls-caret" aria-hidden="true">›</span></button
            >
        {/if}

        {#if intoHome?.deposit || budget?.buy}
            <!-- behavior 98: not costs — what goes into the home, and the cash to buy -->
            <p class="ls-divider">{$t('plan.sheet.not_a_cost')}</p>
            <div class="ls-aside">
                {#if intoHome?.deposit}
                    <button type="button" class="ls-row" data-into-home onclick={() => openPhase('buy')}>
                        <span class="ls-row-label"
                            >{holdYears
                                ? $t('plan.sheet.into_home_hold').replace('{n}', String(holdYears))
                                : $t('plan.sheet.into_home')}</span
                        >
                        <span class="ls-row-fig">{@render ends(intoHome.total ?? intoHome.deposit)}</span>
                        <span class="ls-caret" aria-hidden="true">›</span>
                    </button>
                {/if}
                {#if budget?.buy}
                    <div class="ls-row ls-need" data-cash-to-buy>
                        <span class="ls-row-label">{$t('plan.sheet.cash_to_buy')}</span>
                        <span class="ls-row-fig">{@render ends(budget.buy)}</span>
                    </div>
                {/if}
            </div>
        {/if}
    </section>
{/if}

{#snippet verdict(need: MoneyRange, have: number)}
    <dl class="ls-cash-verdict" aria-live="polite">
        {#each [[$t('plan.sheet.cash_low'), need[0]], [$t('plan.sheet.cash_high'), need[1]]] as [lbl, n] (lbl)}
            <div class:ls-short={have < Number(n)}>
                <dt>{lbl}</dt>
                <dd>{cashVerdict(Number(n), have)}</dd>
            </div>
        {/each}
    </dl>
{/snippet}

{#snippet total(key: PhaseKey, r: MoneyRange | null, perYear: MoneyRange | null)}
    {#if r}
        {@render ends(r)}{#if perYear}<span class="ls-per"
                >≈ {range(perYear)}<span class="ls-unit">{$t('plan.sheet.per_year')}</span></span
            >{/if}
    {:else if busy || filling}
        {@render skel()}
    {:else if (key === 'sell' && holdPending) || (key === 'own' && !holdYears)}
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
    <li class="ls-line" class:ls-in={e.direction === 'in'}>
        {#if e.detail}
            {@render fee(e, e.detail)}
        {:else}
            <div class="ls-line-btn ls-static">{@render body(e)}</div>
        {/if}
    </li>
{/snippet}

{#snippet fee(e: CashEvent, d: FeeDetail)}
    <details class="ls-fee">
        <summary class="ls-line-btn">
            {@render body(e)}
            <span class="ls-caret ls-fee-caret" aria-hidden="true">›</span>
        </summary>
        <div class="ls-fee-detail">
            <LineDetail detail={d} {components} {filling} steps={stepsFor(e)} {onstep} />
        </div>
    </details>
{/snippet}

{#snippet body(e: CashEvent)}
    <span class="ls-label">{pick(e.label, $lang)}</span>
    {#if !e.amount}
        <!-- a line beside the totals with no figure yet (behavior 95) names its input, if any -->
        {#if lineNeeds(e)}<span class="ls-needs"
                >{$t(`plan.sheet.needs.${lineNeeds(e)}` as 'plan.sheet.needs.rent')}</span
            >{/if}
    {:else}
        <span class="ls-amt"
            >{#if e.is_estimate}<span class="ls-mark" title={$t('plan.sheet.estimate')}>≈</span>{/if}{e.direction ===
            'in'
                ? '+'
                : ''}{range(e.amount)}{#if e.timing === 'recurring'}<span class="ls-unit"
                    >{$t('plan.sheet.per_year')}</span
                >{/if}</span
        >
    {/if}
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
    /* On a phone a long range wraps inside the figure's column, after its dash. */
    /* behavior 98: "Phí giữ nhà trong N năm" is long, so on a phone the label wraps rather
       than squeeze the figure under one whole end of its range. */
    .ls-row-label { flex: 0 1 auto; min-width: 0; font-weight: 600; }
    .ls-row-fig {
        flex: 1 0 9rem; min-width: 9rem; text-align: right; font-weight: 700;
        font-variant-numeric: tabular-nums; text-wrap: balance;
    }
    .ls-end { white-space: nowrap; }
    .ls-bottom { border-top: 2px solid var(--ink); border-radius: 0; padding-top: 0.75rem; }
    .ls-bottom .ls-row-fig { font-size: var(--fs-lg, 1.125rem); }
    .ls-bottom .ls-row-label { font-weight: 700; }

    /* Phí giữ nhà's per-year figure, quiet beside its total. */
    .ls-per { display: block; font-size: var(--fs-xs, 0.75rem); font-weight: 500; color: var(--muted); }
    .ls-why { margin: -0.4rem 0 0; font-size: var(--fs-sm, 0.875rem); color: var(--muted); }
    /* Not costs (behavior 98): the money into the home and the cash to buy, quieter than
       the statement, their labels free to wrap on a phone. */
    .ls-aside, .ls-into {
        display: grid; background: var(--surface); border: 1px solid var(--border); border-radius: 0.75rem; overflow: hidden;
    }
    .ls-aside > * + * { border-top: 1px solid var(--border); }
    .ls-aside .ls-row-fig, .ls-into-head .ls-row-fig, .ls-need .ls-row-fig { font-weight: 600; }
    .ls-need .ls-row-label, .ls-into-head .ls-row-label, .ls-aside .ls-row-label { white-space: normal; flex: 1 1 9rem; font-weight: 500; }
    .ls-into .ls-rest { border: 0; border-top: 1px solid var(--border); border-radius: 0; }
    .ls-need { background: var(--surface); border: 1px solid var(--border); border-radius: 0.75rem; }
    .ls-aside .ls-need { border: 0; border-radius: 0; }
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

    /* A line opens in place: its summary is the line, its body the facts behind it. */
    .ls-fee > summary { list-style: none; cursor: pointer; }
    .ls-fee > summary::-webkit-details-marker { display: none; }
    .ls-fee > summary:hover { background: var(--accent-soft); }
    .ls-fee > summary:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    .ls-fee-caret { transition: transform 0.15s ease; }
    .ls-fee[open] .ls-fee-caret { transform: rotate(90deg); }
    @media (prefers-reduced-motion: reduce) { .ls-fee-caret { transition: none; } }
    .ls-fee-detail { padding: 0 0.75rem 0.75rem; }
    /* "Tiền bạn có": the visitor's sum, then each end of the Mua total enough or short. */
    .ls-cash {
        display: grid; gap: 0.5rem; padding: 0.6rem 0.75rem; background: var(--surface);
        border: 1px solid var(--border); border-radius: 0.75rem;
    }
    .ls-cash-row { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem 0.75rem; }
    .ls-cash-in {
        flex: 1 1 8rem; min-width: 0; font: inherit; text-align: right; font-variant-numeric: tabular-nums;
        padding: 0.4rem 0.6rem; border: 1px solid var(--border-strong); border-radius: 0.5rem;
        background: var(--surface); color: var(--ink);
    }
    .ls-cash-verdict { margin: 0; display: grid; gap: 0.25rem; }
    /* behavior 101: the finances sheet's opener under the statement, and its fields */
    .ls-fin-open {
        display: flex; justify-content: space-between; align-items: center; width: 100%;
        margin-top: 0.75rem; padding: 0.7rem 0.9rem; font: inherit; font-weight: 600;
        color: var(--ink); background: var(--surface);
        border: 1px solid var(--border); border-radius: 0.75rem; cursor: pointer; text-align: left;
    }
    .ls-fin-open:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .ls-fin { display: grid; gap: 1rem; }
    .ls-fin-effect { margin: 0.25rem 0 0; font-size: 0.85rem; color: var(--muted); }
    .ls-cash-verdict > div { display: flex; justify-content: space-between; gap: 0.75rem; }
    .ls-cash-verdict dt { color: var(--muted); font-size: var(--fs-sm, 0.875rem); }
    .ls-cash-verdict dd { margin: 0; font-weight: 700; color: var(--success); font-variant-numeric: tabular-nums; }
    .ls-cash-verdict .ls-short dd { color: var(--danger, var(--warning)); }
</style>
