<script lang="ts">
    // The `summary-card` renderer (constraint #7 vocabulary). Every blueprint's profile
    // component lists summary-card first, but the componentId is NOT a single literal —
    // Mode A/B share `buyer_profile`, Mode C is `investor_profile`, Mode D is
    // `investor_profile_foreign`, all three emitting the canonical `profile` outcome. It
    // hosts THREE heroes, branched on componentId (plan-card-visual-spec §2/§3.1/§3.3): a
    // REACH BAR (profile: target vs borrowing reach), a PATH PICKER (mortgage_finance: the
    // recommended financing lane, one stable id across all four blueprints), and a STRATEGY
    // hero (investment_strategy, Mode C/D only — outcome `strategy_thesis`). Anything else
    // reaching this renderer (e.g. `property_assessment`'s `property_fit`, per-property scope,
    // no dedicated hero yet) renders NOTHING rather than guessing a hero for a shape it
    // wasn't built for — an unmapped componentId used to silently fall into the path-picker
    // branch and read undefined mortgage fields (Mode-D P4 finding, 2026-07-04).
    // All heroes are deterministic outcome→geometry (R1), honest-partial (R2: fields the
    // base turn can't yet know ghost via `Field`'s Pending, or the reach bar's own hint —
    // financials/thesis reasoning arrive on a refine turn), bilingual at the source (R4).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        PROFILE_COMPONENT_IDS,
        type ProfileOutcome,
        type MortgagePlanOutcome,
        type StrategyThesisOutcome,
        type MoneyRange
    } from '$lib/planCard';
    import { money, moneyRange, num } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import { archetypeLabel } from './archetype';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';

    let { componentId, outcome }: {
        componentId: string;
        outcome: Record<string, unknown>;
    } = $props();

    const profile = $derived(outcome as ProfileOutcome);
    const mortgage = $derived(outcome as MortgagePlanOutcome);
    const strategy = $derived(outcome as StrategyThesisOutcome);
    const isProfile = $derived((PROFILE_COMPONENT_IDS as readonly string[]).includes(componentId));

    // recommended_path is a known enum → a display label via $t; unknown values fall
    // back to the raw value so nothing is silently dropped.
    const PATHS = new Set([
        'fhg_backed',
        'lmi_5_to_20',
        'twenty_plus',
        'user_specific_alternative'
    ]);
    function pathLabel(p: string | null | undefined): string | null {
        if (!p) return null;
        return PATHS.has(p) ? $t(`plan.path.${p}` as 'plan.path.fhg_backed') : p;
    }

    // --- reach bar (profile, §3.1) ------------------------------------------
    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const target = $derived(profile.target_price_range);
    const capacity = $derived(profile.approx_borrowing_capacity);
    // a shared price axis 0..scale; the target band + the reach band plot against it. At
    // base capacity is null (no income at onboarding) → scale is the target ceiling and
    // the reach band ghosts.
    const scale = $derived(
        Math.max(hasRange(capacity) ? capacity[1] : 0, hasRange(target) ? target[1] : 0)
    );
    const pctOf = (v: number) => (scale > 0 ? Math.max(0, Math.min(100, (v / scale) * 100)) : 0);

    // --- path picker (mortgage, §3.3) ---------------------------------------
    // the three standard lanes, recommended one highlighted. A non-standard recommended
    // path (e.g. a tailored option) shows as a chip below rather than a phantom lane.
    const LANES: string[] = ['twenty_plus', 'fhg_backed', 'lmi_5_to_20'];
    const recPath = $derived(mortgage.recommended_path ?? null);
    const recIsCustom = $derived(!!recPath && !LANES.includes(recPath));
    // Mode C/D's mortgage_plan has NO recommended_path at all (fh_engine_mortgage.erl's
    // fill_investor/fill_investor_foreign never emit it — not merely null) — the FHB path
    // picker has no lanes to highlight there. isInvestorMortgage discriminates on
    // io_vs_pi_recommendation (present as a key, even when its value is still null pre-
    // agent-fill, on both investor shapes; absent from Mode A/B's). Found 2026-07-11: the
    // lane list rendered with nothing ever lit up for every Mode C/D card — silently
    // uninformative, not a crash. DataTable's mortgage_plan branch already shows the full
    // figures (deposit %, rate, io/pi, offset) — this hero stays a HERO: just the headline
    // financing snapshot, not a duplicate of that detail.
    const isInvestorMortgage = $derived('io_vs_pi_recommendation' in outcome);
    const IOVSPI = new Set(['interest_only', 'principal_and_interest']);
    function iovspiLabel(v: string | null | undefined): string | null {
        if (!v) return null;
        return IOVSPI.has(v) ? $t(`plan.iovspi.${v}` as 'plan.iovspi.interest_only') : v;
    }

    // --- strategy hero (investment_strategy, Mode C/D, strategy_thesis) -----
    // Mostly agent-filled — null at base except hold_period_years (resolver-carried off
    // profile.hold_horizon_years); every field ghosts via Field's own Pending until a
    // refine turn. No bilingual label table for these enums (would be ~30 option pairs
    // for a mostly-null base card) — same raw-value fallback as pathLabel above.
    const pct = (v: number | null | undefined) => (v != null ? `${num(v, $lang)}%` : null);
    const years = (v: number | null | undefined) =>
        v != null ? `${num(v, $lang)} ${$t('plan.whatif.years_unit')}` : null;
</script>

{#if isProfile}
    <!-- ── Reach bar hero ─────────────────────────────────────────────── -->
    <div class="rb-hero">
        <div class="rb-chips">
            {#if typeof profile.firb_required_any === 'boolean'}
                <Chip
                    label={`${$t('plan.f.firb')} ${profile.firb_required_any ? $t('onboarding.yes') : $t('onboarding.no')}`}
                    tone={profile.firb_required_any ? 'warn' : 'good'}
                />
            {/if}
            {#if num(profile.applicant_count, $lang)}
                <Chip
                    label={`${num(profile.applicant_count, $lang)} · ${$t('plan.f.applicants')}`}
                    tone="neutral"
                />
            {/if}
        </div>

        {#if hasRange(target)}
            <div class="rb-row">
                <span class="rb-rowlabel">{$t('plan.f.target_price')}</span>
                <div class="rb-track" aria-hidden="true">
                    <span
                        class="rb-target"
                        style="left:{pctOf(target[0])}%;width:{pctOf(target[1]) - pctOf(target[0])}%"
                    ></span>
                </div>
                <span class="rb-val">{moneyRange(target, $lang)}</span>
            </div>
        {/if}

        <div class="rb-row">
            <span class="rb-rowlabel">{$t('plan.reach.label')}</span>
            {#if hasRange(capacity)}
                <div class="rb-track" aria-hidden="true">
                    <span class="rb-reach" style="width:{pctOf(capacity[1])}%"></span>
                </div>
                <span class="rb-val">{moneyRange(capacity, $lang)}</span>
            {:else}
                <div class="rb-track rb-pending" aria-hidden="true"></div>
                <span class="rb-val rb-muted">—</span>
            {/if}
        </div>
        {#if !hasRange(capacity)}
            <p class="rb-hint">{$t('plan.reach.capacity_pending')}</p>
        {/if}
    </div>

    <!-- detail (the figures the hero summarizes are not repeated) -->
    <Field label={$t('plan.f.income')} value={money(profile.assessable_income, $lang)} />
    <Field
        label={$t('plan.f.deposit')}
        value={money(profile.deposit_ready_for_purchase_amount, $lang)}
    />
    <NoteList heading={$t('plan.f.strengths')} notes={profile.key_strengths} />
    <NoteList heading={$t('plan.f.constraints')} notes={profile.key_constraints} />
{:else if componentId === 'mortgage_finance'}
    {#if isInvestorMortgage}
        <!-- ── Financing snapshot hero (Mode C/D — no FHB path lanes to light up) ──── -->
        <div class="pk-hero">
            <div class="pp-chips-row">
                {#if mortgage.io_vs_pi_recommendation}
                    <Chip label={iovspiLabel(mortgage.io_vs_pi_recommendation) ?? mortgage.io_vs_pi_recommendation} tone="info" />
                {/if}
                {#if mortgage.deposit_required_percentage != null}
                    <Chip label={`${$t('plan.f.deposit_pct')}: ${num(mortgage.deposit_required_percentage, $lang)}%`} tone="neutral" />
                {/if}
            </div>
            {#if !mortgage.io_vs_pi_recommendation && mortgage.deposit_required_percentage == null}
                <Pending />
            {/if}
        </div>
    {:else}
        <!-- ── Path picker hero (Mode A/B) ─────────────────────────────────── -->
        <div class="pk-hero">
            <ul class="pk-lanes">
                {#each LANES as lane (lane)}
                    <li class="pk-lane" class:pk-on={lane === recPath}>
                        <span class="pk-marker" aria-hidden="true">{lane === recPath ? '●' : '○'}</span>
                        <span class="pk-name">{pathLabel(lane)}</span>
                        {#if lane === recPath}
                            <span class="pk-rec">{$t('plan.path.recommended')}</span>
                        {/if}
                    </li>
                {/each}
            </ul>
            {#if recIsCustom}
                <div class="pp-field">
                    <span class="pp-label">{$t('plan.f.path')}</span>
                    <Chip label={pathLabel(recPath) ?? ''} tone="info" />
                </div>
            {/if}
        </div>
    {/if}

    <!-- detail -->
    <Field
        label={$t('plan.f.capacity')}
        value={moneyRange(mortgage.expected_borrowing_capacity, $lang)}
    />
    {#if mortgage.recommended_lender_shortlist?.length}
        <div class="pp-sublist">
            <span class="pp-label">{$t('plan.f.lenders')}</span>
            {#each mortgage.recommended_lender_shortlist as l, i (i)}
                <div class="pp-lender">
                    {#if l.lender}<span class="pp-lender-name">{l.lender}</span>{/if}
                    {#if pick(l.reasoning, $lang)}
                        <p class="pp-lender-why">{pick(l.reasoning, $lang)}</p>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}
    <NoteList heading={$t('plan.f.preapproval')} notes={mortgage.pre_approval_action_plan} />
    <NoteList heading={$t('plan.f.assumptions')} notes={mortgage.key_assumptions} />
{:else if componentId === 'investment_strategy'}
    <!-- ── Strategy hero ───────────────────────────────────────────────── -->
    <div class="st-hero">
        {#if strategy.archetype}
            <Chip label={archetypeLabel(strategy.archetype, $t)} tone="info" />
        {/if}
        {#if strategy.one_liner}
            <p class="st-oneliner">{strategy.one_liner}</p>
        {/if}
    </div>

    <Field label={$t('plan.f.yield_target')} value={pct(strategy.target_gross_yield)} />
    <Field label={$t('plan.f.growth_target')} value={pct(strategy.target_capital_growth)} />
    <Field label={$t('plan.f.gearing_type')} value={strategy.gearing_type} />
    <Field label={$t('plan.f.target_lvr')} value={pct(strategy.target_lvr)} />
    <Field label={$t('plan.f.hold_period')} value={years(strategy.hold_period_years)} />
    <Field label={$t('plan.f.exit_strategy')} value={strategy.exit_strategy} />
    {#if strategy.migration_pathway_alignment}
        <Field label={$t('plan.f.migration_alignment')} value={strategy.migration_pathway_alignment} />
    {/if}
    {#if strategy.currency_hedging_strategy}
        <Field label={$t('plan.f.currency_hedging')} value={strategy.currency_hedging_strategy} />
    {/if}
{/if}
<!-- else: an unmapped componentId (e.g. property_assessment's property_fit) reaches
     summary-card with no dedicated hero — render nothing rather than guess one. -->

<style>
    /* reach bar */
    .rb-hero {
        margin-bottom: 0.6rem;
    }
    .rb-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
        margin-bottom: 0.6rem;
    }
    .rb-row {
        display: grid;
        grid-template-columns: 5.5rem 1fr auto;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.35rem;
    }
    .rb-rowlabel {
        font-size: 0.75rem;
        color: var(--muted);
    }
    .rb-track {
        position: relative;
        height: 0.9rem;
        border-radius: 0.3rem;
        background: var(--bg);
        border: 1px solid var(--border);
        overflow: hidden;
    }
    .rb-target {
        position: absolute;
        top: 0;
        bottom: 0;
        background: var(--accent);
        border-radius: 0.2rem;
    }
    .rb-reach {
        position: absolute;
        top: 0;
        bottom: 0;
        left: 0;
        background: color-mix(in srgb, var(--accent) 35%, transparent);
    }
    .rb-pending {
        background-image: repeating-linear-gradient(
            45deg,
            var(--border) 0 6px,
            transparent 6px 12px
        );
    }
    .rb-val {
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .rb-muted {
        color: var(--muted);
        font-weight: 400;
    }
    .rb-hint {
        margin: 0.2rem 0 0;
        font-size: 0.8rem;
        font-style: italic;
        color: var(--muted);
    }

    /* path picker */
    .pk-hero {
        margin-bottom: 0.6rem;
    }
    .pk-lanes {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.3rem;
    }
    .pk-lane {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.4rem 0.6rem;
        border-radius: 0.4rem;
        border: 1px solid var(--border);
        font-size: 0.9rem;
        color: var(--muted);
    }
    .pk-on {
        border-color: var(--accent);
        background: color-mix(in srgb, var(--accent) 10%, transparent);
        color: var(--ink);
        font-weight: 600;
    }
    .pk-marker {
        color: var(--accent);
    }
    .pk-name {
        flex: 1;
    }
    .pk-rec {
        font-size: 0.7rem;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        color: var(--accent);
    }

    /* strategy hero */
    .st-hero {
        margin-bottom: 0.6rem;
        display: flex;
        flex-direction: column;
        gap: 0.4rem;
    }
    .st-oneliner {
        margin: 0;
        font-size: 0.95rem;
        font-weight: 600;
        color: var(--ink);
    }
</style>
