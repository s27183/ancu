<script lang="ts">
    // The `summary-card` renderer (constraint #7 vocabulary). It serves the two base
    // components whose blueprint lists summary-card first — buyer_profile (profile) and
    // mortgage_finance (mortgage_plan) — so it hosts TWO heroes, branched on componentId
    // (plan-card-visual-spec §2/§3.1/§3.3): a REACH BAR (target vs borrowing reach) and a
    // PATH PICKER (the recommended financing lane). Both are deterministic outcome→geometry
    // (R1), honest-partial (R2: the reach/capacity ghosts until income arrives on a refine
    // turn — financials aren't captured at onboarding), bilingual at the source (R4).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type ProfileOutcome, type MortgagePlanOutcome, type MoneyRange } from '$lib/planCard';
    import { money, moneyRange, num } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';

    let { componentId, outcome }: {
        componentId: string;
        outcome: Record<string, unknown>;
    } = $props();

    const profile = $derived(outcome as ProfileOutcome);
    const mortgage = $derived(outcome as MortgagePlanOutcome);

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
</script>

{#if componentId === 'buyer_profile'}
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
{:else}
    <!-- ── Path picker hero ───────────────────────────────────────────── -->
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
{/if}

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
</style>
