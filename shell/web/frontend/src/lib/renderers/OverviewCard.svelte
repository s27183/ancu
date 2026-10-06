<script lang="ts">
    // The Overview tab's SYNTHESIS — "the plan in 90 seconds" (plan-card-lifecycle-
    // restoration §5.4). NOT a constraint-#7 vocabulary entry and NOT dispatched by
    // ComponentCard: it is a shell-composed summary that READS the already-filled base
    // outcomes (profile, scheme_stack, mortgage_plan, budget_envelope) and distils the
    // headline numbers a buyer wants first — target, recommended path, scheme benefit,
    // cash to get in — instead of re-stacking every component card.
    //
    // R1 deterministic outcome→display. R2 honest-partial: a figure the base turn can't
    // yet know (reach/capacity — no income at onboarding) ghosts with a calm hint, never
    // a zero. R4 bilingual: connective copy is product chrome ($t); the figures come from
    // engine outcomes via money()/moneyRange(); engine CONTENT prose is never routed here.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        type ComponentEntry,
        type ProfileOutcome,
        type SchemeStackOutcome,
        type MortgagePlanOutcome,
        type BudgetEnvelopeOutcome,
        type ExistingHomeDisposalOutcome,
        type StrategyThesisOutcome,
        type FirbStatusOutcome,
        type MoneyRange,
        firstComponentEntry,
        PROFILE_COMPONENT_IDS
    } from '$lib/planCard';
    import { moneyRange, asRange } from '$lib/format';
    import Pending from './Pending.svelte';

    let { components, filling }: {
        components: Record<string, ComponentEntry>;
        filling: boolean;
    } = $props();

    // Mode A/B share `buyer_profile`; Mode C is `investor_profile`; Mode D is
    // `investor_profile_foreign` — all three emit the same `profile` outcome shape.
    const profile = $derived(
        firstComponentEntry(components, PROFILE_COMPONENT_IDS)?.outcome as ProfileOutcome | undefined
    );
    // `eligibility` doesn't exist for Modes C/D (no FHB scheme stack for investors) — `scheme`
    // is honestly undefined there, not "not yet computed"; the `benefit` tile below is
    // presence-gated on it rather than reading a permanent null forever.
    const scheme = $derived(components.eligibility?.outcome as SchemeStackOutcome | undefined);
    const mortgage = $derived(components.mortgage_finance?.outcome as MortgagePlanOutcome | undefined);
    const budget = $derived(components.cash_position?.outcome as BudgetEnvelopeOutcome | undefined);
    // Mode C/D only — investment_strategy replaces eligibility as the "what's the plan" component.
    const strategy = $derived(
        components.investment_strategy?.outcome as StrategyThesisOutcome | undefined
    );
    // Modes B/D only — firb_workflow doesn't exist for A/C/E. FIRB status is a first-class
    // headline (CLAUDE.md #10 — "build the gate into the architecture, not as a disclaimer"),
    // so it's presence-gated onto the Overview grid the same way `scheme`/`existingHome` are,
    // not left for the Flow tab alone to surface (task 9, plan-card-lifecycle-restoration §11.3
    // "overview" now lists firb_workflow for Mode D, mirroring how Mode A's overview lists
    // `eligibility` for the same reason — a gate the buyer needs to see in the 90-second read).
    const firbStatus = $derived(components.firb_workflow?.outcome as FirbStatusOutcome | undefined);
    const firbStageLabel = $derived(
        firbStatus?.current_stage
            ? $t(`plan.firb.stage.${firbStatus.current_stage}` as 'plan.firb.stage.not_started')
            : null
    );
    // Mode-E ONLY: no other mode has this component, so the tile below is present/absent by
    // component presence (not honest-partial-null) — Modes A/B/C/D never grow a dead
    // "Pending" tile for a figure that doesn't apply to them.
    const existingHome = $derived(
        components.existing_home_disposal?.outcome as ExistingHomeDisposalOutcome | undefined
    );

    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const range = (v: MoneyRange | null | undefined): string | null =>
        hasRange(v) ? moneyRange(v, $lang) : null;

    // recommended_path is a known enum → a label; an unknown value shows verbatim so
    // nothing is silently dropped (mirrors SummaryCard). mortgage.recommended_path is an
    // FHB-only concept — `fill_investor_domestic`/`fill_investor_foreign` never set it, so
    // it's permanently undefined for Modes C/D (not "not yet"). Fall back to the investor
    // archetype (investment_strategy's agent-filled headline, real at base for C/D — an
    // interim substitute for the same tile slot until the Mode C/D Overview restructure
    // gives investors their own copy, plan-card-lifecycle-restoration.md §11).
    const PATHS = new Set(['fhg_backed', 'lmi_5_to_20', 'twenty_plus', 'user_specific_alternative']);
    const path = $derived(mortgage?.recommended_path ?? strategy?.archetype ?? null);
    const pathLabel = $derived(
        path ? (PATHS.has(path) ? $t(`plan.path.${path}` as 'plan.path.fhg_backed') : path) : null
    );

    const target = $derived(range(profile?.target_price_range));
    // eligibility (and its total_benefit_value) doesn't exist for Modes C/D — see `stats`
    // below, where this tile is presence-gated on `scheme` rather than shown as a
    // perpetual "Not yet" for a figure that structurally can't apply.
    const benefit = $derived(range(scheme?.total_benefit_value));
    // total_cash_required is a range for Modes A/B/E, a scalar point for Modes C/D
    // (fh_engine_cash.erl SEAMS note) — asRange() upgrades a scalar to [v,v] instead of the
    // bare hasRange() check treating it as absent.
    const cashNeed = $derived.by(() => {
        const r = asRange(budget?.total_cash_required);
        return r ? moneyRange(r, $lang) : null;
    });
    const capacity = $derived(range(profile?.approx_borrowing_capacity));
    const existingHomeNet = $derived(existingHome ? range(existingHome.net_sale_proceeds) : null);

    // Headline tiles. Cash-to-get-in leads (2026-08, Son's call): it's the number a buyer
    // asks first ("can I actually afford this?"), ahead of the journey-order framing
    // (where you're aiming → how you finance → what help stacks) the rest of the grid
    // still follows. Each ghosts honest-partial when null (its component ran but hasn't
    // filled the figure yet). `benefit` is different: it's presence-gated on `scheme`
    // (component-presence, not honest-partial) since Modes C/D have no eligibility
    // component at all — same treatment the existing-home tile already gets for Mode E, so
    // C/D never carry a tile for a figure that can't structurally exist for them.
    const stats = $derived([
        { key: 'cash', label: $t('plan.cash.need'), value: cashNeed },
        { key: 'target', label: $t('plan.f.target_price'), value: target },
        ...(firbStatus
            ? [{ key: 'firb', label: $t('plan.f.stage'), value: firbStageLabel }]
            : []),
        { key: 'path', label: $t('plan.f.path'), value: pathLabel },
        ...(scheme
            ? [{ key: 'benefit', label: $t('plan.f.total_benefit'), value: benefit }]
            : []),
        ...(existingHome
            ? [{ key: 'existing_home_net', label: $t('plan.xhd.net_proceeds'), value: existingHomeNet }]
            : [])
    ]);
</script>

<!-- "What this is" — the prototype's lead card: orient the buyer before the numbers. -->
<section class="pp-card ov-what">
    <h3 class="ov-what-title">{$t('plan.ov.what.title')}</h3>
    <p class="ov-what-body">{$t('plan.ov.what.body')}</p>
</section>

<section class="pp-card ov-card">
    <p class="ov-lead">{$t('plan.ov.lead')}</p>

    <div class="ov-grid">
        {#each stats as s (s.key)}
            <div class="ov-stat">
                <span class="ov-stat-label">{s.label}</span>
                {#if s.value}
                    <span class="ov-stat-value">{s.value}</span>
                {:else if filling}
                    <span class="ov-stat-value ov-muted">…</span>
                {:else}
                    <Pending />
                {/if}
            </div>
        {/each}
    </div>

    <!-- Reach: target vs borrowing capacity. Capacity is pending-by-design at base (no
         income captured at onboarding) — surface the hint, never a fabricated reach. -->
    <div class="ov-reach">
        <span class="ov-stat-label">{$t('plan.reach.label')}</span>
        {#if capacity}
            <span class="ov-stat-value">{capacity}</span>
        {:else}
            <p class="ov-hint">{$t('plan.reach.capacity_pending')}</p>
        {/if}
    </div>

    <p class="ov-partial">{$t('plan.ov.partial')}</p>
</section>

<style>
    .ov-what {
        margin-bottom: 0.6rem;
    }
    .ov-what-title {
        margin: 0 0 0.35rem;
        font-size: 0.95rem;
        font-weight: 700;
        color: var(--ink);
    }
    .ov-what-body {
        margin: 0;
        font-size: 0.85rem;
        color: var(--muted);
        line-height: 1.5;
    }
    .ov-lead {
        margin: 0 0 0.75rem;
        font-size: 0.95rem;
        font-weight: 600;
        color: var(--ink);
    }
    .ov-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.5rem;
    }
    .ov-stat {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        padding: 0.6rem 0.7rem;
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        background: var(--bg);
    }
    .ov-stat-label {
        font-size: 0.72rem;
        color: var(--muted);
    }
    .ov-stat-value {
        font-size: 1rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    .ov-muted {
        color: var(--muted);
        font-weight: 400;
    }
    .ov-reach {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        margin-top: 0.75rem;
        padding-top: 0.6rem;
        border-top: 1px solid var(--border);
    }
    .ov-hint {
        margin: 0.1rem 0 0;
        font-size: 0.8rem;
        font-style: italic;
        color: var(--muted);
    }
    .ov-partial {
        margin: 0.75rem 0 0;
        font-size: 0.78rem;
        font-style: italic;
        color: var(--muted);
    }
</style>
