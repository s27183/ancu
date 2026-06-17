<script lang="ts">
    // The `calculator` renderer — cash_position (budget_envelope). Opens with the CASH
    // WATERFALL hero (plan-card-visual-spec §3.4): the NEED bar (deposit + duty + other
    // costs → total cash to get in). The HAVE side is PENDING by design at base — no
    // savings are captured at onboarding (Decision 9), so it ghosts with a CTA; the
    // verdict computes on a refine turn. The detailed breakdown follows the hero.
    //
    // R1 the bar is a pure outcome→geometry function (shared StackedBar; nothing agent-
    // drawn). R2 honest-partial — a null line is omitted/ghosted, never a zero or fake
    // point. R4 bilingual — labels enum→$t, notes LocalizedText, figures via money()/
    // moneyRange(). All money is resolver-computed + single-valued/ranged (§98).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import type { BudgetEnvelopeOutcome, MoneyRange } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import StackedBar from './StackedBar.svelte';

    let { outcome, density = 'compact', interactive = false }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
        // The cash_calculator tab declares `interactive: true` (the blueprint's ui_tabs,
        // plan-card-lifecycle-restoration §6). The shell renders that declaration: only
        // then does the HAVE side become a client-side what-if (below). The same
        // Calculator is non-interactive under the Before-you-buy tab.
        interactive?: boolean;
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

    // NEED-bar segments (Decision 9): deposit (range), duty (scalar, exact), other costs
    // (range, convention estimate → ~ marker). Each present only when its figure is known.
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
    const needTotal = $derived(hasRange(o.total_cash_required) ? rangeLabel(o.total_cash_required) : null);
    const haveKnown = $derived(typeof o.cash_available === 'number');

    const VERDICTS: Record<string, 'good' | 'warn'> = {
        surplus: 'good',
        tight: 'warn',
        short: 'warn'
    };
    const GSV: Record<string, 'good' | 'warn' | 'neutral'> = {
        meets: 'good',
        fails_recent_gift: 'warn',
        insufficient_track_record: 'warn',
        unknown: 'neutral'
    };
    function verdictLabel(v: string): string {
        return v in VERDICTS ? $t(`plan.verdict.${v}` as 'plan.verdict.short') : v;
    }
    function gsvLabel(v: string): string {
        return v in GSV ? $t(`plan.gsv.${v}` as 'plan.gsv.unknown') : v;
    }

    // ── Interactive cash what-if (B2, plan-card-lifecycle-restoration §6) ──────
    // CASH-ONLY by design. The engine already computed total_cash_required as a
    // money_range (single-sourced, regulated duty verified to the dollar). The client
    // does SUBTRACTION ONLY — cash on hand vs that range — and NEVER recomputes duty
    // (that would be a second, unverified computer). It is EPHEMERAL decision-support:
    // the engine keeps verdict=null; persisting one is the refine turn. Varying PRICE is
    // out of scope (it changes target_price_range → re-run the engine), so there is no
    // price slider — only a cash-on-hand input.
    let cashInput = $state('');
    const cashOnHand = $derived.by((): number | null => {
        const n = Number(cashInput.replace(/[^0-9.]/g, ''));
        return cashInput.trim() !== '' && Number.isFinite(n) && n >= 0 ? n : null;
    });
    const need = $derived(hasRange(o.total_cash_required) ? o.total_cash_required : null);
    type WhatIf = { verdict: 'surplus' | 'tight' | 'short'; label: string; amount: string };
    const whatif = $derived.by((): WhatIf | null => {
        if (cashOnHand === null || !need) return null;
        const [lo, hi] = need;
        // Range-aware: above the band → spare ∈ [cash−hi, cash−lo]; within the band →
        // covers the low end, up to (hi−cash) short of the top; below → shortfall ∈
        // [lo−cash, hi−cash]. All honest about the band, never a single false point.
        if (cashOnHand >= hi) {
            return { verdict: 'surplus', label: $t('plan.cash.whatif.spare'),
                amount: rangeLabel([cashOnHand - hi, cashOnHand - lo]) };
        }
        if (cashOnHand >= lo) {
            return { verdict: 'tight', label: $t('plan.cash.whatif.toptier'),
                amount: money(hi - cashOnHand, $lang) ?? '—' };
        }
        return { verdict: 'short', label: $t('plan.cash.whatif.shortfall'),
            amount: rangeLabel([lo - cashOnHand, hi - cashOnHand]) };
    });
</script>

<!-- ── Cash waterfall hero ─────────────────────────────────────────────── -->
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

    <!-- HAVE side: real once savings arrive (refine), otherwise pending-by-design. -->
    <div class="cw-have">
        {#if haveKnown}
            <Field label={$t('plan.f.cash_available')} value={money(o.cash_available, $lang)} />
            {#if typeof o.gap_or_surplus === 'number'}
                <div class="pp-field">
                    <span class="pp-label">{$t('plan.f.gap')}</span>
                    <span class="pp-value" class:pp-neg={o.gap_or_surplus < 0}
                        >{money(o.gap_or_surplus, $lang)}</span
                    >
                </div>
            {/if}
        {:else if interactive}
            <!-- Client-side what-if: subtraction against the engine's need range only. -->
            <div class="cw-whatif">
                <label class="cw-wi-field">
                    <span class="pp-label">{$t('plan.cash.whatif.label')}</span>
                    <input
                        type="text"
                        inputmode="numeric"
                        bind:value={cashInput}
                        placeholder={$t('plan.cash.whatif.placeholder')}
                    />
                </label>
                {#if whatif}
                    <div class="pp-field">
                        <span class="pp-label">{whatif.label}</span>
                        <span class="cw-wi-result">
                            <Chip label={verdictLabel(whatif.verdict)} tone={VERDICTS[whatif.verdict]} />
                            <span class="cw-wi-amount" class:pp-neg={whatif.verdict === 'short'}
                                >{whatif.amount}</span
                            >
                        </span>
                    </div>
                {/if}
                <p class="cw-wi-note">{$t('plan.cash.whatif.disclaimer')}</p>
            </div>
        {:else}
            <p class="cw-cta">{$t('plan.cash.add_savings')}</p>
        {/if}
    </div>
</div>

<!-- ── Breakdown detail ───────────────────────────────────────────────── -->
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

{#if o.verdict}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.verdict')}</span>
        <Chip label={verdictLabel(o.verdict)} tone={VERDICTS[o.verdict] ?? 'neutral'} />
    </div>
{/if}
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

<style>
    .cw-hero {
        margin-bottom: 0.6rem;
    }
    .cw-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .cw-need-label {
        font-size: 0.85rem;
        color: var(--muted);
    }
    .cw-need-total {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    .cw-have {
        margin-top: 0.6rem;
    }
    .cw-cta {
        margin: 0;
        font-size: 0.85rem;
        color: var(--muted);
        font-style: italic;
    }
    .cw-whatif {
        margin-top: 0.3rem;
    }
    .cw-wi-field {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        margin-bottom: 0.4rem;
    }
    .cw-wi-field input {
        padding: 0.45rem 0.6rem;
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        background: var(--surface);
        color: var(--ink);
        font-size: 1rem;
        font-variant-numeric: tabular-nums;
    }
    .cw-wi-field input:focus {
        outline: none;
        border-color: var(--accent);
    }
    .cw-wi-result {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }
    .cw-wi-amount {
        font-size: 1.05rem;
        font-weight: 700;
        color: var(--ink);
        font-variant-numeric: tabular-nums;
    }
    .cw-wi-amount.pp-neg {
        color: #b91c1c;
    }
    .cw-wi-note {
        margin: 0.5rem 0 0;
        font-size: 0.75rem;
        font-style: italic;
        color: var(--muted);
    }
</style>
