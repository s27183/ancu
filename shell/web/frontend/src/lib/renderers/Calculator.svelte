<script lang="ts">
    // The `calculator` renderer — cash_position (budget_envelope). The financial spine of
    // the temporal flow (plan-card-lifecycle §7): the calculator visualises the FINANCIAL
    // process the same way the swimlane visualises the LEGAL process — both projections of
    // one lifecycle over shared primitives (cash_events ↔ the swimlane's interactions).
    //
    // Three stacked sections: (1) the "Am I ready?" VERDICT hero — total cash need vs the
    // user's cash-on-hand (a CLIENT-SIDE subtraction against the engine's verified need
    // range — never recomputes a regulated figure, the one thing the prototype did that we
    // must not copy); (2) the cash_events SPINE — every money flow placed on the lifecycle
    // phases, phase-aligned with the swimlane; (3) the breakdown detail.
    //
    // The interactive INPUTS (price / state / cash-on-hand) live in the cockpit the parent
    // (PlanProjection) renders above this — price/state drive the engine `simulate`, so the
    // figures below recompute; cash-on-hand arrives as a prop and drives the verdict only.
    //
    // R1 every bar/figure is a pure outcome→geometry function (nothing agent-drawn). R2
    // honest-partial — a null line is omitted/ghosted, never a zero or fake point; an empty
    // phase says so. R4 bilingual — enum labels via $t, engine prose via pick(), figures via
    // money()/moneyRange(). All money is resolver-computed + single-valued/ranged.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type BudgetEnvelopeOutcome,
        type CashEvent,
        type ComponentEntry,
        type DispositionOutcome,
        type ExistingHomeDisposalOutcome,
        type MoneyRange
    } from '$lib/planCard';
    import { money, moneyRange, asRange } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import StackedBar from './StackedBar.svelte';
    import ComponentCard from './ComponentCard.svelte';
    import Modal from '$lib/Modal.svelte';

    let {
        outcome,
        density = 'compact',
        cashOnHand = null,
        components = {},
        view = 'full',
        onShowDetail = undefined
    }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
        // Cash on hand from the parent's cockpit input (null = not entered). Drives the
        // verdict via a client-side subtraction against total_cash_required only.
        cashOnHand?: number | null;
        // The filled components, so a cash-event row can drill to its owner (§7.3): each
        // event carries source_component; clicking the row opens that component's renderer
        // as its explanation — the budget-side mirror of the phase sheet's component_ref.
        components?: Record<string, ComponentEntry>;
        // Which slice to render (§7.3 budget tabs): 'verdict' (the "Am I ready?" hero),
        // 'table' (the cash-events spine), 'detail' (the breakdown, inline). Default 'full'
        // stacks all three with the breakdown behind a modal — the standalone render used by
        // ComponentCard and the export dossier (untouched by the tabbed budget surface).
        // 'disposition' renders the SEPARATE `disposition` outcome (the dispose-phase
        // figure-owner) — the sell-side projection + full-horizon net position (TW5).
        view?: 'verdict' | 'table' | 'detail' | 'full' | 'disposition';
        // Tabbed mode only: a self-owned row (deposit/duty/other → cash_position itself) has
        // no external explainer, so instead of the breakdown MODAL it asks the parent to
        // switch to the Detail tab. Absent (full mode) → the self-owned row opens the modal.
        onShowDetail?: (() => void) | undefined;
    } = $props();
    const o = $derived(outcome as BudgetEnvelopeOutcome);

    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const mid = (r: MoneyRange) => (r[0] + r[1]) / 2;
    // a money_range reads "$x" collapsed (per-property), "$lo – $hi" as a base band.
    function rangeLabel(v: MoneyRange | null | undefined): string {
        if (!hasRange(v)) return '—';
        if (v[0] === v[1]) return money(v[0], $lang) ?? '—';
        return moneyRange(v, $lang) ?? '—';
    }

    // NEED-bar segments: deposit (range), duty (scalar, exact), other costs (range,
    // convention estimate). Each present only when its figure is known.
    type Seg = { value: number | null; label: string; amount: string; estimate: boolean };
    const dutyAfter = $derived(o.stamp_duty?.after_concession ?? null);
    const needSegments = $derived(
        ([
            hasRange(o.deposit?.minimum_required_amount)
                ? { value: mid(o.deposit!.minimum_required_amount!), label: $t('plan.cash.deposit'),
                    amount: rangeLabel(o.deposit!.minimum_required_amount), estimate: false }
                : null,
            typeof dutyAfter === 'number'
                ? { value: dutyAfter, label: $t('plan.f.stamp_duty'),
                    amount: money(dutyAfter, $lang) ?? '—', estimate: false }
                : null,
            hasRange(o.other_buying_costs?.total)
                ? { value: mid(o.other_buying_costs!.total!), label: $t('plan.cash.other'),
                    amount: rangeLabel(o.other_buying_costs!.total), estimate: true }
                : null
        ] as (Seg | null)[]).filter((s): s is Seg => s !== null)
    );
    // total_cash_required is a range for Modes A/B/E, a scalar point for Modes C/D
    // (fh_engine_cash.erl SEAMS note) — asRange() upgrades a scalar to [v,v] rather than
    // treating it as absent (the bug: hasRange() alone rejects a bare number).
    const needRange = $derived(asRange(o.total_cash_required));
    const needTotal = $derived(needRange ? rangeLabel(needRange) : null);

    const VERDICTS: Record<string, 'good' | 'warn'> = { surplus: 'good', tight: 'warn', short: 'warn' };
    const GSV: Record<string, 'good' | 'warn' | 'neutral'> = {
        meets: 'good', fails_recent_gift: 'warn', insufficient_track_record: 'warn', unknown: 'neutral'
    };
    function verdictLabel(v: string): string {
        return v in VERDICTS ? $t(`plan.verdict.${v}` as 'plan.verdict.short') : v;
    }
    function gsvLabel(v: string): string {
        return v in GSV ? $t(`plan.gsv.${v}` as 'plan.gsv.unknown') : v;
    }

    // ── "Am I ready?" verdict (B2) ────────────────────────────────────────────
    // CASH-ONLY: subtraction of cash-on-hand vs the engine's verified need range. The
    // engine keeps verdict=null until savings persist (a refine fact), so this is the
    // ephemeral what-if; once cash_available is a stored fact, the engine's own verdict
    // shows instead. Never recomputes duty (a second, unverified computer).
    const need = $derived(needRange);
    type Assess = { tone: 'good' | 'warn' | 'bad'; verdict: string; label: string; amount: string };
    const assessment = $derived.by((): Assess | null => {
        if (cashOnHand !== null && need) {
            const [lo, hi] = need;
            // Range-aware: above the band → spare; within → covers low, short of top;
            // below → shortfall. Honest about the band, never a single false point.
            if (cashOnHand >= hi)
                return { tone: 'good', verdict: 'surplus', label: $t('plan.cash.whatif.spare'),
                         amount: rangeLabel([cashOnHand - hi, cashOnHand - lo]) };
            if (cashOnHand >= lo)
                return { tone: 'warn', verdict: 'tight', label: $t('plan.cash.whatif.toptier'),
                         amount: money(hi - cashOnHand, $lang) ?? '—' };
            return { tone: 'bad', verdict: 'short', label: $t('plan.cash.whatif.shortfall'),
                     amount: rangeLabel([lo - cashOnHand, hi - cashOnHand]) };
        }
        // Persisted-fact path: the engine's own verdict once savings are stored.
        if (typeof o.cash_available === 'number' && o.verdict && typeof o.gap_or_surplus === 'number') {
            const tone = o.verdict === 'surplus' ? 'good' : o.verdict === 'short' ? 'bad' : 'warn';
            return { tone, verdict: o.verdict, label: $t('plan.f.gap'),
                     amount: money(Math.abs(o.gap_or_surplus), $lang) ?? '—' };
        }
        return null;
    });

    // ── Financial spine: cash_events placed on the lifecycle phases ───────────
    // Phase-aligned with the swimlane (same ids/order). The spine PLACES the engine's
    // events; it never sums them into a total (the headline total is total_cash_required,
    // engine-computed — one-computer-per-figure). Empty phases say so (honest-partial:
    // recurring Own-phase costs are PENDING until profile facts arrive).
    const PHASE_ORDER = ['prepare', 'pre_approve', 'contract', 'settle', 'own'] as const;
    const events = $derived((o.cash_events ?? []) as CashEvent[]);
    const hasSpine = $derived(events.length > 0);
    const byPhase = $derived.by((): Array<{ phase: string; events: CashEvent[] }> => {
        // Canonical phases first, then any unexpected phase the engine sends (forward-
        // compatible), de-duped — then group. Pure local computation, no mutable state.
        const known: readonly string[] = PHASE_ORDER;
        const extra = events.map((e) => e.phase).filter((p) => !known.includes(p));
        const phases = [...PHASE_ORDER, ...extra.filter((p, i) => extra.indexOf(p) === i)];
        return phases.map((phase) => ({ phase, events: events.filter((e) => e.phase === phase) }));
    });
    function phaseLabel(p: string): string {
        return $t(`plan.phase.${p}` as 'plan.phase.prepare');
    }
    function signed(e: CashEvent): string {
        return (e.direction === 'out' ? '−' : '+') + rangeLabel(e.amount);
    }

    // Row drill (§7.3), layered representation:
    //  - an EXTERNALLY-owned row (e.g. grant → eligibility) opens that component's renderer
    //    in a popup Modal;
    //  - a SELF-owned row (deposit/duty/other → cash_position) has no external explainer —
    //    drilling to cash_position would recurse into this whole calculator — so it opens the
    //    Budget-breakdown modal (where its line detail + notes live) instead;
    //  - a row with no resolvable owner stays static (honest-partial — never a dead link).
    // A dangling selected id (e.g. after a preview swaps the events) resolves to null → closed.
    let selectedEventId = $state<string | null>(null);
    let showBreakdown = $state(false);
    function ownerOf(e: CashEvent): string | null {
        return e.source_component && e.source_component !== 'cash_position' && components[e.source_component]
            ? e.source_component
            : null;
    }
    function rowClickable(e: CashEvent): boolean {
        return !!ownerOf(e) || e.source_component === 'cash_position';
    }
    function openRow(e: CashEvent) {
        if (ownerOf(e)) selectedEventId = e.id; // external owner → its component modal
        else if (onShowDetail) onShowDetail(); // self-owned, tabbed → switch to Detail tab
        else showBreakdown = true; // self-owned, full mode → the breakdown modal
    }
    const selectedEvent = $derived(events.find((e) => e.id === selectedEventId) ?? null);
    const selectedOwner = $derived(selectedEvent ? ownerOf(selectedEvent) : null);
    // The below-table breakdown + summary now live in a modal; show the opener only when
    // there is something to show (honest-partial).
    const hasBreakdown = $derived(
        !!(
            o.stamp_duty ||
            o.deposit ||
            o.other_buying_costs ||
            o.reserve_buffer ||
            o.max_property_price_supported != null ||
            o.genuine_savings_verdict ||
            o.mitigation_options_if_short?.length ||
            o.key_assumptions?.length
        )
    );

    // ── Disposition (view='disposition') — the dispose-phase figure-owner ──────
    // A SEPARATE outcome shape from budget_envelope; both use the `calculator` renderer
    // (the blueprint maps both → calculator). This view reads `disposition`: the sell-side
    // projection (sale − selling − loan − cgt = net) + the full-horizon net position.
    // Honest-partial: H null → invitation; H set + loan unknown (no income captured, the
    // common simulate-only state) → sale/selling banded, loan/net/full PENDING with a CTA.
    const d = $derived(outcome as DispositionOutcome);
    // The `calculator` renderer is mapped to THREE outcome types (cash_position's
    // budget_envelope, disposition, and Mode-E-only existing_home_disposal); a standalone
    // render (ComponentCard / export dossier / the PhaseSheet component_ref drill) hands
    // view='full', so the renderer must discriminate by outcome shape. `cgt_status` alone is
    // NOT a safe disposition discriminator: existing_home_disposal also carries a non-null
    // `cgt_status` string (same enum, same main-residence-exemption concept applied to the
    // CURRENT home) — so existing_home_disposal is checked FIRST, on a field unique to it
    // (`bridging_finance_is_placeholder`, always a bool for that shape, absent from
    // disposition), and disposition's own check excludes it.
    const xhd = $derived(outcome as ExistingHomeDisposalOutcome);
    const isExistingHomeDisposal = $derived(typeof xhd.bridging_finance_is_placeholder === 'boolean');
    const isDisposition = $derived(typeof d.cgt_status === 'string' && !isExistingHomeDisposal);
    const hasHorizon = $derived(typeof d.horizon_years === 'number' && d.horizon_years > 0);
    const loanPending = $derived(hasHorizon && !hasRange(d.loan_payout));
    const fullHorizon = $derived(hasRange(d.full_horizon_net_position) ? d.full_horizon_net_position : null);
    const CGT_TONE: Record<string, 'good' | 'warn' | 'neutral'> = { exempt: 'good', to_verify: 'warn' };
    // Map the closed cgt_status enum to literal i18n keys (no dynamic-key cast that would
    // hide a producer rename — firsthomey-svelte-conventions).
    function cgtLabel(s: string): string {
        if (s === 'exempt') return $t('plan.disp.cgt.exempt');
        if (s === 'to_verify') return $t('plan.disp.cgt.to_verify');
        return s;
    }
    // existing_home_disposal's break_cost_status — same literal-key discipline as cgtLabel.
    function breakCostLabel(s: string): string {
        if (s === 'not_applicable') return $t('plan.xhd.break_cost.not_applicable');
        if (s === 'to_verify') return $t('plan.xhd.break_cost.to_verify');
        return s;
    }
</script>

<!-- The breakdown detail — the line breakdown + summary. Rendered INLINE in the Detail tab
     (view='detail') and inside the modal in full mode. One snippet, two mounts. -->
{#snippet breakdownBody()}
    {#if o.stamp_duty}
        <Field label={$t('plan.f.duty_before')} value={money(o.stamp_duty.before_concession, $lang)} />
        <Field label={$t('plan.f.duty_after')} value={money(o.stamp_duty.after_concession, $lang)} />
        <NoteList notes={o.stamp_duty.notes} />
    {/if}

    {#if o.deposit}
        <Field label={$t('plan.cash.deposit')} value={rangeLabel(o.deposit.minimum_required_amount)} />
        <NoteList notes={o.deposit.notes} />
    {/if}
    {#if o.other_buying_costs}
        <Field label={$t('plan.cash.other')} value={rangeLabel(o.other_buying_costs.total)} />
        <NoteList notes={o.other_buying_costs.notes} />
    {/if}
    {#if o.reserve_buffer}
        <Field label={$t('plan.cash.reserve')} value={money(o.reserve_buffer.amount, $lang)} />
        <NoteList notes={o.reserve_buffer.notes} />
    {/if}

    <Field label={$t('plan.f.max_price')} value={money(o.max_property_price_supported, $lang)} />

    {#if o.genuine_savings_verdict}
        <div class="pp-field">
            <span class="pp-label">{$t('plan.f.genuine_savings')}</span>
            <Chip label={gsvLabel(o.genuine_savings_verdict)} tone={GSV[o.genuine_savings_verdict] ?? 'neutral'} />
        </div>
    {/if}

    {#if o.mitigation_options_if_short?.length}
        <div class="pp-sublist">
            <span class="pp-label">{$t('plan.f.mitigation')}</span>
            <ul>
                {#each o.mitigation_options_if_short as m, i (i)}
                    <li>{m}</li>
                {/each}
            </ul>
        </div>
    {/if}

    <NoteList heading={$t('plan.f.assumptions')} notes={o.key_assumptions} />
{/snippet}

<!-- ── (1) "Am I ready?" verdict hero ───────────────────────────────────── -->
{#if view === 'verdict' || (view === 'full' && !isDisposition && !isExistingHomeDisposal)}
<div class="cw-hero" class:cw-full={density === 'full'}>
    <div class="cw-head">
        <span class="cw-need-label">{$t('plan.cash.need')}</span>
        {#if needTotal}
            <span class="cw-need-total">{needTotal}</span>
        {:else}
            <Pending />
        {/if}
    </div>

    {#if needSegments.length}
        <StackedBar segments={needSegments} {density} />
    {/if}

    <div class="cw-verdict">
        {#if assessment}
            <div class="cw-vbox cw-{assessment.tone}">
                <span class="cw-vlabel">{$t('plan.cash.ready')}</span>
                <span class="cw-vbody">
                    <Chip label={verdictLabel(assessment.verdict)} tone={VERDICTS[assessment.verdict] ?? 'neutral'} />
                    <span class="cw-vamount">{assessment.label} {assessment.amount}</span>
                </span>
            </div>
        {:else}
            <p class="cw-cta">{$t('plan.cash.add_savings')}</p>
        {/if}
    </div>
</div>
{/if}

<!-- ── (2) The financial spine — cash_events across the lifecycle phases ──── -->
<!-- A clean Item/Amount table (the prototype's design language). Each phase is a sub-header
     band; each event row drills to its source_component (§7.3) when that owner is filled. -->
{#if (view === 'table' || (view === 'full' && !isDisposition && !isExistingHomeDisposal)) && hasSpine}
    <div class="cw-spine">
        <h4 class="cw-spine-title">{$t('plan.cash.spine')}</h4>
        <table class="cw-table">
            <thead>
                <tr>
                    <th>{$t('plan.cash.col_item')}</th>
                    <th class="num">{$t('plan.cash.col_amount')}</th>
                </tr>
            </thead>
            <tbody>
                {#each byPhase as { phase, events: evs } (phase)}
                    <tr class="cw-trphase"><td colspan="2">{phaseLabel(phase)}</td></tr>
                    {#if evs.length}
                        {#each evs as e (e.id)}
                            {@const clickable = rowClickable(e)}
                            <tr class="cw-trevent">
                                <td class="cw-td-item">
                                    {#if clickable}
                                        <button
                                            type="button"
                                            class="cw-ev-btn"
                                            onclick={() => openRow(e)}
                                        >
                                            <span class="cw-caret" aria-hidden="true">▸</span>
                                            <span class="cw-ev-label">{pick(e.label, $lang)}</span>
                                        </button>
                                    {:else}
                                        <span class="cw-ev-label">{pick(e.label, $lang)}</span>
                                    {/if}
                                    {#if e.timing === 'recurring'}
                                        <span class="cw-ev-rec">⟳ {$t('plan.cash.recurring')}</span>
                                    {/if}
                                </td>
                                <td
                                    class="num cw-ev-amt"
                                    class:cw-out={e.direction === 'out'}
                                    class:cw-in={e.direction === 'in'}>{signed(e)}</td
                                >
                            </tr>
                        {/each}
                    {:else}
                        <tr class="cw-trempty"><td colspan="2">{$t('plan.cash.spine.empty')}</td></tr>
                    {/if}
                {/each}
            </tbody>
        </table>
    </div>
{/if}

<!-- full mode: the breakdown sits behind a modal opener under the table. -->
{#if view === 'full' && !isDisposition && !isExistingHomeDisposal && hasBreakdown}
    <button type="button" class="cw-breakdown-btn" onclick={() => (showBreakdown = true)}>
        {$t('plan.cash.breakdown')}
    </button>
{/if}

<!-- ── (3) The breakdown — inline in the Detail tab (tabbed budget, §7.3). ── -->
{#if view === 'detail'}
    {#if hasBreakdown}
        {@render breakdownBody()}
    {:else}
        <Pending />
    {/if}
{/if}

<!-- ── (4) Disposition — the sell-side projection + full-horizon net position. ── -->
<!-- A separate outcome (the dispose-phase figure-owner); the calculator's culminating
     projection of the financial process (buy → hold → sell). Honest-partial throughout.
     Triggered by view='disposition' (the Budget tab) OR a 'full' render of a disposition
     outcome (ComponentCard / dossier / PhaseSheet drill — the renderer self-discriminates). -->
{#if view === 'disposition' || (view === 'full' && isDisposition)}
    {#if hasHorizon}
        <!-- The full-horizon net position hero (the headline). -->
        <div class="cw-hero cw-full">
            <div class="cw-head">
                <span class="cw-need-label">{$t('plan.disp.full_horizon')}</span>
                {#if fullHorizon}
                    <span class="cw-need-total">{rangeLabel(fullHorizon)}</span>
                {:else}
                    <Pending />
                {/if}
            </div>
            <p class="cw-disp-sub">{$t('plan.disp.full_horizon_sub')}</p>
        </div>

        <!-- The sell-side breakdown: sale − selling − loan − cgt = net. Every figure is
             resolver-computed + banded; a pending figure shows "—", never a fake zero. -->
        <div class="cw-spine">
            <h4 class="cw-spine-title">{phaseLabel('dispose')}</h4>
            <table class="cw-table">
                <tbody>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.sale')}</span></td>
                        <td class="num cw-ev-amt cw-in">+{rangeLabel(d.sale_proceeds)}</td>
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.selling')}</span></td>
                        <td class="num cw-ev-amt cw-out">−{rangeLabel(d.selling_costs)}</td>
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.loan')}</span></td>
                        <td class="num cw-ev-amt" class:cw-out={hasRange(d.loan_payout)}
                            >{hasRange(d.loan_payout) ? '−' + rangeLabel(d.loan_payout) : '—'}</td
                        >
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.cgt')}</span></td>
                        <td class="num">
                            {#if d.cgt_status}
                                <Chip label={cgtLabel(d.cgt_status)} tone={CGT_TONE[d.cgt_status] ?? 'neutral'} />
                            {:else}
                                —
                            {/if}
                        </td>
                    </tr>
                    <tr class="cw-trevent cw-trnet">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.net')}</span></td>
                        <td class="num cw-ev-amt">{rangeLabel(d.net_proceeds)}</td>
                    </tr>
                </tbody>
            </table>
        </div>

        {#if loanPending}
            <p class="cw-cta">{$t('plan.disp.loan_pending')}</p>
        {/if}

        <NoteList heading={$t('plan.f.assumptions')} notes={d.key_assumptions} />
    {:else}
        <!-- H null → no projection (Mode-A long/indefinite default); the engine emits the
             single invitation line in key_assumptions. TW6 wires the horizon control. -->
        <div class="cw-hero">
            <span class="cw-need-label">{$t('plan.disp.set_horizon')}</span>
        </div>
        <NoteList notes={d.key_assumptions} />
    {/if}
{/if}

<!-- ── (5) existing_home_disposal (Mode E ONLY) — net proceeds of selling the buyer's
     CURRENT home to fund THIS purchase. A separate outcome from disposition (which projects
     the FUTURE exit of the new property); both use the calculator renderer, self-discriminated
     above. Honest-partial: no onboarding capture of the sale price / loan balance (plan-first),
     so the breakdown only shows once a refine turn supplies at least the sale price. -->
{#if view === 'full' && isExistingHomeDisposal}
    {#if typeof xhd.estimated_sale_price === 'number'}
        <div class="cw-hero cw-full">
            <div class="cw-head">
                <span class="cw-need-label">{$t('plan.xhd.net_proceeds')}</span>
                {#if hasRange(xhd.net_sale_proceeds)}
                    <span class="cw-need-total">{rangeLabel(xhd.net_sale_proceeds)}</span>
                {:else}
                    <Pending />
                {/if}
            </div>
            <p class="cw-disp-sub">{$t('plan.xhd.net_proceeds_sub')}</p>
        </div>

        <div class="cw-spine">
            <h4 class="cw-spine-title">{$t('plan.c.existing_home_disposal')}</h4>
            <table class="cw-table">
                <tbody>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.xhd.sale_price')}</span></td>
                        <td class="num cw-ev-amt cw-in">+{money(xhd.estimated_sale_price, $lang) ?? '—'}</td>
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item">
                            <span class="cw-ev-label">{$t('plan.xhd.loan_payout')}</span>
                            {#if xhd.loan_payout?.break_cost_status}
                                <Chip label={breakCostLabel(xhd.loan_payout.break_cost_status)} tone="neutral" />
                            {/if}
                        </td>
                        <td class="num cw-ev-amt" class:cw-out={hasRange(xhd.loan_payout?.total_payout)}
                            >{hasRange(xhd.loan_payout?.total_payout)
                                ? '−' + rangeLabel(xhd.loan_payout?.total_payout)
                                : '—'}</td
                        >
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.selling')}</span></td>
                        <td class="num cw-ev-amt" class:cw-out={hasRange(xhd.selling_costs)}
                            >{hasRange(xhd.selling_costs) ? '−' + rangeLabel(xhd.selling_costs) : '—'}</td
                        >
                    </tr>
                    <tr class="cw-trevent">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.cgt')}</span></td>
                        <td class="num">
                            {#if xhd.cgt_status}
                                <Chip label={cgtLabel(xhd.cgt_status)} tone={CGT_TONE[xhd.cgt_status] ?? 'neutral'} />
                            {:else}
                                —
                            {/if}
                        </td>
                    </tr>
                    <tr class="cw-trevent cw-trnet">
                        <td class="cw-td-item"><span class="cw-ev-label">{$t('plan.disp.net')}</span></td>
                        <td class="num cw-ev-amt">{rangeLabel(xhd.net_sale_proceeds)}</td>
                    </tr>
                </tbody>
            </table>
        </div>

        {#if xhd.settlement_timing_mismatch}
            <p class="cw-cta">{$t('plan.xhd.settlement_mismatch')}</p>
            {#if xhd.bridging_finance_is_placeholder}
                <p class="cw-cta">{$t('plan.xhd.bridging_placeholder')}</p>
            {/if}
        {/if}

        <NoteList heading={$t('plan.f.assumptions')} notes={xhd.key_assumptions} />
    {:else}
        <!-- No sale-price fact yet (base turn, plan-first — honest-partial, mirrors
             disposition's own set_horizon invitation). -->
        <div class="cw-hero">
            <span class="cw-need-label">{$t('plan.xhd.add_facts')}</span>
        </div>
        <NoteList notes={xhd.key_assumptions} />
    {/if}
{/if}

<!-- The cash-event drill-down (§7.3): an EXTERNAL owner's renderer in a popup Modal. -->
{#if selectedEvent && selectedOwner}
    <Modal title={pick(selectedEvent.label, $lang)} onClose={() => (selectedEventId = null)}>
        <ComponentCard componentId={selectedOwner} entry={components[selectedOwner]} filling={false} />
    </Modal>
{/if}

<!-- full mode: the breakdown modal (a self-owned row opens it; tabbed mode uses the tab). -->
{#if showBreakdown}
    <Modal title={$t('plan.cash.breakdown')} onClose={() => (showBreakdown = false)}>
        {@render breakdownBody()}
    </Modal>
{/if}

<style>
    .cw-hero { margin-bottom: 0.6rem; }
    .cw-head {
        display: flex; align-items: baseline; justify-content: space-between;
        gap: 0.5rem; margin-bottom: 0.5rem;
    }
    .cw-need-label { font-size: 0.85rem; color: var(--muted); }
    .cw-need-total {
        font-size: 1.15rem; font-weight: 700; color: var(--accent);
        font-variant-numeric: tabular-nums;
    }

    /* Verdict box — prototype's ok/warn/bad hero. */
    .cw-verdict { margin-top: 0.6rem; }
    .cw-vbox {
        border: 1px solid var(--border); border-radius: 0.5rem;
        padding: 0.6rem 0.75rem; display: flex; flex-direction: column; gap: 0.35rem;
    }
    .cw-good { background: #ecfdf5; border-color: #a7f3d0; }
    .cw-warn { background: #fffbeb; border-color: #fde68a; }
    .cw-bad  { background: #fef2f2; border-color: #fecaca; }
    .cw-vlabel { font-size: 0.8rem; font-weight: 600; color: var(--muted); }
    .cw-vbody { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
    .cw-vamount { font-weight: 700; font-variant-numeric: tabular-nums; color: var(--ink); }
    .cw-cta { margin: 0; font-size: 0.85rem; color: var(--muted); font-style: italic; }

    /* Disposition: the sub-label under the full-horizon hero + the net subtotal row. */
    .cw-disp-sub { margin: 0.25rem 0 0; font-size: 0.78rem; color: var(--muted); }
    .cw-trnet td {
        border-top: 2px solid var(--border); font-weight: 700;
        padding-top: 0.55rem; background: var(--surface-2, #fafaf9);
    }

    /* Financial spine — cash_events as a clean Item/Amount table (prototype design
       language: uppercase head, hairline row borders, right-aligned tabular amounts). */
    .cw-spine {
        margin: 0.9rem 0; border: 1px solid var(--border);
        border-radius: 0.5rem; overflow: hidden;
    }
    .cw-spine-title {
        margin: 0; padding: 0.5rem 0.75rem; font-size: 0.85rem; font-weight: 700;
        background: var(--surface-2, #f5f5f4); color: var(--ink);
        border-bottom: 1px solid var(--border);
    }
    .cw-table {
        width: 100%; border-collapse: collapse; font-size: 0.82rem;
    }
    .cw-table th {
        text-align: left; padding: 0.5rem 0.75rem;
        background: var(--surface-2, #fafaf9); color: var(--muted);
        font-size: 0.68rem; font-weight: 700; text-transform: uppercase;
        letter-spacing: 0.04em; border-bottom: 1px solid var(--border);
    }
    .cw-table th.num { text-align: right; }
    .cw-table td {
        padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--border);
        color: var(--ink); vertical-align: top;
    }
    .cw-table td.num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
    .cw-trphase td {
        font-size: 0.68rem; font-weight: 700; color: var(--accent);
        text-transform: uppercase; letter-spacing: 0.03em;
        background: var(--surface); padding-top: 0.55rem; padding-bottom: 0.3rem;
    }
    .cw-ev-btn {
        display: inline-flex; align-items: baseline; gap: 0.35rem;
        font: inherit; color: var(--ink); background: none; border: none;
        padding: 0; margin: 0; cursor: pointer; text-align: left;
    }
    .cw-ev-btn:hover .cw-ev-label { color: var(--accent); text-decoration: underline; }
    .cw-caret { font-size: 0.7rem; color: var(--accent); flex: none; }
    .cw-ev-label { font-size: 0.82rem; color: inherit; }
    .cw-ev-rec { font-size: 0.7rem; color: var(--muted); white-space: nowrap; margin-left: 0.3rem; }
    .cw-ev-amt { font-weight: 700; }
    .cw-out { color: #b91c1c; }
    .cw-in { color: #15803d; }
    .cw-trempty td { font-size: 0.78rem; color: var(--muted); font-style: italic; }

    /* The Budget-breakdown opener — a calm full-width affordance under the table. */
    .cw-breakdown-btn {
        display: block;
        width: 100%;
        margin: 0.6rem 0 0;
        padding: 0.55rem 0.75rem;
        font-size: 0.82rem;
        font-weight: 600;
        color: var(--accent);
        background: none;
        border: 1px solid var(--border);
        border-radius: 0.5rem;
        cursor: pointer;
        text-align: left;
    }
    .cw-breakdown-btn:hover {
        background: color-mix(in srgb, var(--accent) 6%, var(--surface));
    }
</style>
