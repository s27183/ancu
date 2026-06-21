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
        type MoneyRange
    } from '$lib/planCard';
    import { moneyRange } from '$lib/format';
    import Pending from './Pending.svelte';

    let { components, filling }: {
        components: Record<string, ComponentEntry>;
        filling: boolean;
    } = $props();

    const profile = $derived(components.buyer_profile?.outcome as ProfileOutcome | undefined);
    const scheme = $derived(components.eligibility?.outcome as SchemeStackOutcome | undefined);
    const mortgage = $derived(components.mortgage_finance?.outcome as MortgagePlanOutcome | undefined);
    const budget = $derived(components.cash_position?.outcome as BudgetEnvelopeOutcome | undefined);

    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const range = (v: MoneyRange | null | undefined): string | null =>
        hasRange(v) ? moneyRange(v, $lang) : null;

    // recommended_path is a known enum → a label; an unknown value shows verbatim so
    // nothing is silently dropped (mirrors SummaryCard).
    const PATHS = new Set(['fhg_backed', 'lmi_5_to_20', 'twenty_plus', 'user_specific_alternative']);
    const path = $derived(mortgage?.recommended_path ?? null);
    const pathLabel = $derived(
        path ? (PATHS.has(path) ? $t(`plan.path.${path}` as 'plan.path.fhg_backed') : path) : null
    );

    const target = $derived(range(profile?.target_price_range));
    const benefit = $derived(range(scheme?.total_benefit_value));
    const cashNeed = $derived(range(budget?.total_cash_required));
    const capacity = $derived(range(profile?.approx_borrowing_capacity));

    // Four headline tiles, in journey order: where you're aiming → how you finance →
    // what help stacks → what cash gets you in. Each ghosts honest-partial when null.
    const stats = $derived([
        { key: 'target', label: $t('plan.f.target_price'), value: target },
        { key: 'path', label: $t('plan.f.path'), value: pathLabel },
        { key: 'benefit', label: $t('plan.f.total_benefit'), value: benefit },
        { key: 'cash', label: $t('plan.cash.need'), value: cashNeed }
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
