<script lang="ts">
    // The `data-table` renderer — ownership_planning (ongoing_obligations): the cost
    // of holding the home. At base scope this is honest-partial — the statutory band
    // (council + water) and land-tax status are knowable; mortgage-dominated monthly /
    // annual outgoings need a firm loan, so they show Pending until a property is
    // attached.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type OngoingObligationsOutcome,
        type TaxOptimisedStructureOutcome,
        type TaxOptimisedStructureForeignOutcome,
        type PortfolioPositionOutcome,
        type PortfolioPositionForeignOutcome,
        type MortgagePlanOutcome
    } from '$lib/planCard';
    import { money, moneyRange, num } from '$lib/format';
    import Field from './Field.svelte';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import StackedBar from './StackedBar.svelte';

    let { outcome, density = 'compact' }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
    } = $props();
    const o = $derived(outcome as OngoingObligationsOutcome);

    // `data-table` is named by SEVEN unrelated outcome shapes (2026-07-11 audit added three
    // — mortgage_plan/portfolio_position_foreign/preparation_plan — then a fourth on a second
    // pass the same day, below). Shape-discriminate so each rich producer isn't dropped (the
    // Slice-4 Checklist lesson): tax_structure → tax_optimised_structure (the investor tax
    // cluster + the NG reform note); ownership_planning_investor → portfolio_position (below);
    // else the FHB ownership ongoing_obligations view.
    const isTax = $derived('cgt_discount_eligible' in outcome && 'recommended_entity' in outcome);
    const tx = $derived(outcome as TaxOptimisedStructureOutcome);
    // The reform note (the headline of this view) is the engine's bilingual {vi,en}; never recomputed.
    const reformNote = $derived(pick(tx.negative_gearing_reform_note, $lang));
    // The recommended ownership entity is a closed enum; guard the $t lookup (a producer-renamed id
    // degrades to the raw value, not a crash) and surface the "confirm with a tax agent" copy at base.
    const ENTITY = new Set([
        'personal_sole', 'personal_joint', 'discretionary_trust', 'unit_trust',
        'company', 'smsf', 'smsf_with_lrba'
    ]);
    const entityLabel = $derived.by(() => {
        const e = tx.recommended_entity;
        if (!e) return $t('plan.tx.entity_pending');
        return ENTITY.has(e) ? $t(`plan.entity.${e}` as 'plan.entity.personal_sole') : e;
    });
    const marginalRate = $derived(tx.cgt_marginal_rate != null ? `${num(tx.cgt_marginal_rate, $lang)}%` : null);
    const afterTaxCf = $derived(moneyRange(tx.after_tax_cash_flow_year_1, $lang));
    // Entity setup is an INDICATIVE band the engine places from the KB (never the agent's):
    // [0, 0] → "$0", [lo, hi] → "lo – hi", [lo, null] → "from lo" (an open-ended floor), each
    // labelled indicative; null (no entity yet) → Pending. Not part of the cash total.
    const setupCosts = $derived.by(() => {
        const r = tx.setup_costs;
        if (!Array.isArray(r) || typeof r[0] !== 'number') return null;
        const [lo, hi] = r;
        const lo$ = money(lo, $lang) ?? '';
        const band = hi === null ? $t('plan.tx.setup_from').replace('{amount}', lo$)
            : hi === lo ? lo$
            : moneyRange([lo, hi], $lang);
        return `${band} ${$t('plan.tx.indicative')}`;
    });

    // tax_structure_non_resident (Mode D) — the SEVENTH shape, found 2026-07-11 auditing a
    // live investor-foreign-au card: it shares tax_optimised_structure's type name AND both
    // of isTax's discriminator fields (cgt_discount_eligible, recommended_entity), so isTax
    // fires true for this shape too — but the rest of Mode C's field names don't exist here
    // (negative_gearing_active → negative_gearing_available_against_au_income; no
    // after_tax_cash_flow_year_1 at all, per the blueprint's own outcome schema). Without
    // this, the branch above silently rendered Pending for gearing/cash-flow instead of this
    // shape's real fields. Checked BEFORE isTax in the template (more specific first);
    // rental_withholding_rate is unique to Mode D (absent from Mode C's schema).
    const isTaxForeign = $derived('rental_withholding_rate' in outcome);
    const txf = $derived(outcome as TaxOptimisedStructureForeignOutcome);
    const txfEntityLabel = $derived.by(() => {
        const e = txf.recommended_entity;
        if (!e) return $t('plan.tx.entity_pending');
        return ENTITY.has(e) ? $t(`plan.entity.${e}` as 'plan.entity.personal_sole') : e;
    });
    const txfMarginalRate = $derived(txf.cgt_marginal_rate != null ? `${num(txf.cgt_marginal_rate, $lang)}%` : null);
    const txfWithholdingRate = $derived(
        txf.rental_withholding_rate != null ? `${num(txf.rental_withholding_rate, $lang)}%` : null
    );

    // The third shape on `data-table`: ownership_planning_investor → portfolio_position (the
    // hold/operate view). Discriminate on annual_tax_obligations (unique to this shape) so the
    // engine-authored bilingual content isn't dropped — without this, portfolio_position falls
    // through to the FHB branch below, which renders alert_triggers_armed only by a shared-name
    // coincidence and silently drops everything else.
    const isPortfolio = $derived('annual_tax_obligations' in outcome);
    const pp = $derived(outcome as PortfolioPositionOutcome);
    // The headline: the annual tax obligations the investor carries — engine-authored {vi,en}.
    const ppObligations = $derived(pp.annual_tax_obligations ?? []);
    // The six post-acquisition figures — honest-partial, null until post-settlement actuals.
    const ppLvr = $derived(pp.current_lvr != null ? `${num(pp.current_lvr, $lang)}%` : null);
    const ppEquity = $derived(money(pp.equity_built, $lang));
    const ppCashFlow = $derived(money(pp.monthly_net_cash_flow_actual, $lang));
    const ppDiversification = $derived(pp.portfolio_diversification_score != null ? `${pp.portfolio_diversification_score}/10` : null);

    // mortgage_finance (mortgage_plan, ALL modes) — data-table is this component's SECOND
    // renderer (after summary-card, constraint #7: one renderer name, composed >1). Four
    // real shapes (fh_engine_mortgage.erl fill_fhb/fill_fhb_foreign/fill_investor/
    // fill_investor_foreign) share this one outcome_type; none of the OTHER five shapes on
    // this renderer carry expected_borrowing_capacity / recommended_lender_shortlist / either
    // loan-structure scaffold key, so any one of those is a safe discriminator. Found
    // 2026-07-11: without this the whole mortgage_plan detail silently rendered the FHB
    // ownership-cost placeholders below instead — this branch shows what summary-card's
    // hero (recommended_path / expected_borrowing_capacity / lender shortlist / pre_approval_
    // action_plan / key_assumptions) does NOT already cover.
    const isMortgage = $derived(
        'expected_borrowing_capacity' in outcome || 'recommended_lender_shortlist' in outcome
        || 'loan_structure_recommendation' in outcome || 'recommended_loan_structure' in outcome
    );
    const mp = $derived(outcome as MortgagePlanOutcome);
    // Mode A/B's loan_structure_recommendation vs Mode C's recommended_loan_structure are
    // genuinely DIFFERENT key names for the same concept (fh_engine_mortgage.erl, not a
    // drift bug) — normalize into one display.
    const loanStructure = $derived(
        (mp.loan_structure_recommendation ?? mp.recommended_loan_structure ?? null) as {
            type?: string | null;
            repayment_type?: string | null;
            rate?: string | null;
            offset?: string | null;
            currency?: string | null;
            uses_existing_ppor_equity?: boolean | null;
            interest_only_period_years?: number | null;
        } | null
    );
    const structureType = $derived(loanStructure?.type ?? loanStructure?.repayment_type ?? null);
    const IOVSPI = new Set(['interest_only', 'principal_and_interest']);
    function iovspiLabel(v: string | null | undefined): string | null {
        if (!v) return null;
        return IOVSPI.has(v) ? $t(`plan.iovspi.${v}` as 'plan.iovspi.interest_only') : v;
    }
    const RATE = new Set(['variable', 'fixed_1yr', 'fixed_2yr', 'fixed_3yr', 'split_fixed_variable']);
    function rateLabel(v: string | null | undefined): string | null {
        if (!v) return null;
        return RATE.has(v) ? $t(`plan.rate.${v}` as 'plan.rate.variable') : v;
    }
    const OFFSET = new Set([
        'full_offset_on_this_property', 'offset_pointed_at_ppor_for_tax_efficiency',
        'redraw_only', 'no_offset'
    ]);
    function offsetLabel(v: string | null | undefined): string | null {
        if (!v) return null;
        return OFFSET.has(v) ? $t(`plan.offset.${v}` as 'plan.offset.full_offset_on_this_property') : v;
    }
    const depositAmount = $derived(mp.deposit_required ?? mp.deposit_required_amount ?? null);
    const rateEstimateLabel = $derived.by(() => {
        const r = mp.rate_estimate;
        if (!Array.isArray(r) || r.length !== 2) return null;
        return r[0] === r[1] ? `${num(r[0], $lang)}%` : `${num(r[0], $lang)}–${num(r[1], $lang)}%`;
    });
    const refi = $derived(mp.refinance_plan_for_portfolio_growth ?? null);

    // ownership_planning_foreign_investor (portfolio_position_foreign, Mode D) — the FOURTH
    // shape on this renderer, found in the same 2026-07-11 audit: fh_engine_ownership.erl's
    // fill_foreign_investor/2 is its own 8-field shape, distinct from Mode C's
    // portfolio_position (annual_au_tax_obligations, not annual_tax_obligations — a renamed
    // field, not a typo: Mode D splits AU/VN obligations where Mode C has only one country).
    // Without this it fell through to isPortfolio's FALSE (annual_tax_obligations absent) and
    // then to the FHB branch, dropping real vacancy/FRCGW/mode-switch content.
    const isPortfolioForeign = $derived('annual_au_tax_obligations' in outcome);
    const ppf = $derived(outcome as PortfolioPositionForeignOutcome);
    const ppfAuObligations = $derived(ppf.annual_au_tax_obligations ?? []);
    const ppfVnObligations = $derived(ppf.annual_vn_tax_obligations ?? []);
    const ppfCashFlow = $derived(money(ppf.monthly_net_cash_flow_after_withholding, $lang));
    const ppfFrcgw = $derived(money(ppf.frcgw_reserve_at_exit, $lang));

    // preparation (preparation_plan, Mode A/E) — the FIFTH shape, also found 2026-07-11.
    // data-table is its SECOND renderer (after checklist); every one of its real fields
    // (document_checklist / people_to_engage / scheme_applications_to_prepare / money_buffer
    // / key_assumptions) is already rendered by the sibling Checklist.svelte preparation
    // branch, so this half intentionally renders NOTHING — the fix here is recognizing the
    // shape at all, not duplicating content, so it stops falling through to the FHB branch.
    const isPreparation = $derived('scheme_applications_to_prepare' in outcome);

    // ownership_planning (Mode B, fhb-foreign-au component 11) shares ongoing_obligations
    // with Mode A but adds the foreign-person rows; vacancy_fee_at_risk_amount is unique to
    // it. Each row shows Pending while null (occupancy intent not captured yet) — never
    // dropped (behavior 30).
    const isOwnershipForeign = $derived('vacancy_fee_at_risk_amount' in outcome);
    const OCCUPANCY: Record<string, 'good' | 'warn' | 'neutral'> = {
        compliant_owner_occupier: 'good',
        compliant_genuinely_rented: 'good',
        at_risk: 'warn',
        non_compliant: 'warn'
    };
    function occupancyLabel(v: string): string {
        return v in OCCUPANCY ? $t(`plan.f.occupancy.${v}` as 'plan.f.occupancy.at_risk') : v;
    }

    const LAND_TAX: Record<string, 'good' | 'info' | 'neutral'> = {
        exempt_ppor: 'good',
        applicable: 'info',
        to_verify: 'neutral'
    };
    function landTaxLabel(v: string): string {
        return v in LAND_TAX ? $t(`plan.landtax.${v}` as 'plan.landtax.to_verify') : v;
    }

    const band = $derived(o.recurring_costs_estimate?.statutory_band ?? null);
    const statutory = $derived.by(() => {
        if (!band) return null;
        const lo = money(band.low, $lang);
        const hi = money(band.high, $lang);
        if (lo === null && hi === null) return null;
        if (lo === null) return hi;
        if (hi === null) return lo;
        return `${lo} – ${hi}`;
    });

    // Outgoings hero (plan-card-visual-spec §3.5): a segmented bar of the recurring cost
    // lines. At base only the statutory band (council + water) is knowable; strata /
    // utilities / building insurance need a property → hatched (counted, not sized). The
    // monthly total is mortgage-dominated → Pending until a loan. Reuses StackedBar (R1/R2).
    const num2 = (v: number | null | undefined): v is number => typeof v === 'number';
    const bandMid = $derived(num2(band?.low) && num2(band?.high) ? (band!.low! + band!.high!) / 2 : null);
    const rc = $derived(o.recurring_costs_estimate ?? null);
    const outSegments = $derived([
        { value: bandMid, label: $t('plan.f.statutory'), amount: statutory ?? '—', estimate: true },
        { value: rc?.strata_levies ?? null, label: $t('plan.f.strata'),
          amount: money(rc?.strata_levies, $lang) ?? '—', estimate: false },
        { value: rc?.utilities ?? null, label: $t('plan.f.utilities'),
          amount: money(rc?.utilities, $lang) ?? '—', estimate: false },
        { value: rc?.building_insurance ?? null, label: $t('plan.f.insurance'),
          amount: money(rc?.building_insurance, $lang) ?? '—', estimate: false }
    ]);
    const monthly = $derived(money(o.total_monthly_outgoings_estimate, $lang));

    // The "graduation" event (point 6) — when LVR crosses the target, the FHG falls away
    // and a no-LMI refinance window opens. Year is PENDING until a loan/savings fact.
    const grad = $derived(o.graduation_milestone ?? null);
    const gradBody = $derived(
        grad ? $t('plan.grad.body').replace('{lvr}', String(grad.target_lvr ?? 80)) : ''
    );
</script>

{#if isTaxForeign}
<!-- ── tax_structure_non_resident (tax_optimised_structure, Mode D) ─────── -->
<Field label={$t('plan.tx.entity')} value={txfEntityLabel} />
<div class="pp-field">
    <span class="pp-label">{$t('plan.tx.gearing')}</span>
    {#if txf.negative_gearing_available_against_au_income === true}
        <Chip label={$t('plan.tx.geared_negative')} tone="info" />
    {:else if txf.negative_gearing_available_against_au_income === false}
        <Chip label={$t('plan.tx.geared_not_available')} tone="neutral" />
    {:else}
        <Pending />
    {/if}
</div>
<Field label={$t('plan.tx.marginal_rate')} value={txfMarginalRate} />
<Field label={$t('plan.tx.withholding_rate')} value={txfWithholdingRate} />
<Field label={$t('plan.tx.annual_tax_payable')} value={money(txf.annual_au_tax_payable_on_rental, $lang)} />
<Field label={$t('plan.tx.annual_depreciation')} value={money(txf.annual_depreciation_year_1, $lang)} />
<Field label={$t('plan.tx.annual_compliance_cost')} value={money(txf.annual_compliance_cost_au, $lang)} />
<div class="pp-chips-row">
    {#if typeof txf.ppor_exemption_eligible === 'boolean'}
        <Chip
            label={`${$t('plan.tx.ppor_exemption')} ${txf.ppor_exemption_eligible ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={txf.ppor_exemption_eligible ? 'good' : 'neutral'}
        />
    {/if}
    {#if typeof txf.frcgw_applicable === 'boolean'}
        <Chip
            label={`${$t('plan.tx.frcgw_applicable')} ${txf.frcgw_applicable ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={txf.frcgw_applicable ? 'warn' : 'neutral'}
        />
    {/if}
    {#if typeof txf.vn_tax_treaty_relief_applicable === 'boolean'}
        <Chip
            label={`${$t('plan.tx.vn_treaty_relief')} ${txf.vn_tax_treaty_relief_applicable ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={txf.vn_tax_treaty_relief_applicable ? 'good' : 'neutral'}
        />
    {/if}
</div>

{:else if isTax}
<!-- ── tax_structure (tax_optimised_structure) ────────────────────────── -->
{#if reformNote}
    <div class="tx-reform">
        <span class="tx-reform-title">{$t('plan.tx.reform_title')}</span>
        <p class="tx-reform-body">{reformNote}</p>
    </div>
{/if}
<Field label={$t('plan.tx.entity')} value={entityLabel} />
<div class="pp-field">
    <span class="pp-label">{$t('plan.tx.gearing')}</span>
    {#if tx.negative_gearing_active === true}
        <Chip label={$t('plan.tx.geared_negative')} tone="info" />
    {:else}
        <Pending />
    {/if}
</div>
<Field label={$t('plan.tx.marginal_rate')} value={marginalRate} />
<Field label={$t('plan.tx.after_tax_cf')} value={afterTaxCf} />
<Field label={$t('plan.tx.setup_costs')} value={setupCosts} />

{:else if isPortfolio}
<!-- ── ownership_planning_investor (portfolio_position) ────────────────── -->
{#if ppObligations.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.pp.obligations')}</span>
        {#each ppObligations as ob, i (i)}
            {#if pick(ob, $lang)}<p class="pp-obligation">{pick(ob, $lang)}</p>{/if}
        {/each}
    </div>
{/if}
<Field label={$t('plan.pp.lvr')} value={ppLvr} />
<Field label={$t('plan.pp.equity')} value={ppEquity} />
<Field label={$t('plan.pp.cash_flow')} value={ppCashFlow} />
<div class="pp-field">
    <span class="pp-label">{$t('plan.pp.ready')}</span>
    {#if pp.ready_for_next_property === true}
        <Chip label={$t('plan.pp.ready_yes')} tone="good" />
    {:else}
        <Pending />
    {/if}
</div>
<Field label={$t('plan.pp.diversification')} value={ppDiversification} />
{#if pp.alert_triggers_armed?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.alerts')}</span>
        {#each pp.alert_triggers_armed as a, i (i)}
            {#if pick(a.trigger, $lang) || pick(a.action, $lang)}
                <div class="pp-alert">
                    {#if pick(a.trigger, $lang)}<span class="pp-alert-trigger">{pick(a.trigger, $lang)}</span>{/if}
                    {#if pick(a.action, $lang)}<span class="pp-alert-action">{pick(a.action, $lang)}</span>{/if}
                </div>
            {/if}
        {/each}
    </div>
{/if}

{:else if isMortgage}
<!-- ── mortgage_finance (mortgage_plan) — the detail summary-card's hero doesn't cover ── -->
{#if structureType || loanStructure?.rate || loanStructure?.offset}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.loan_type')}</span>
        {#if structureType}<Chip label={iovspiLabel(structureType) ?? structureType} tone="info" />{/if}
    </div>
{/if}
{#if loanStructure}
<!-- loan_structure_recommendation/recommended_loan_structure (Mode A/B/C only) — Mode D
     (investor-foreign-au) has NO loan-structure-scaffold or offset concept at all (its
     blueprint: "no offset-strategy or PPOR-equity leaves... Mode D has no AU PPOR to point
     an offset at"), so loanStructure is null there. Found 2026-07-11: these two Fields
     rendered unconditionally, showing "Chưa có" for a mode where the field will NEVER
     exist — honest-partial (Pending) is for a value not yet known, not for a concept that
     doesn't apply; the fix is to not render the row at all, gated on the scaffold's presence. -->
<Field label={$t('plan.f.loan_rate_type')} value={rateLabel(loanStructure.rate)} />
<Field label={$t('plan.f.loan_offset')} value={offsetLabel(loanStructure.offset)} />
{/if}
{#if loanStructure && 'currency' in loanStructure}
    <Field label={$t('plan.f.loan_currency')} value={loanStructure.currency ?? null} />
{/if}
{#if loanStructure && 'uses_existing_ppor_equity' in loanStructure}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.ppor_equity')}</span>
        {#if loanStructure.uses_existing_ppor_equity === true}
            <Chip label={$t('onboarding.yes')} tone="info" />
        {:else if loanStructure.uses_existing_ppor_equity === false}
            <Chip label={$t('onboarding.no')} tone="neutral" />
        {:else}
            <Pending />
        {/if}
    </div>
{/if}
{#if loanStructure && 'interest_only_period_years' in loanStructure}
    <Field
        label={$t('plan.f.io_period')}
        value={loanStructure.interest_only_period_years != null
            ? `${loanStructure.interest_only_period_years} ${$t('plan.whatif.years_unit')}`
            : null}
    />
{/if}

{#if depositAmount != null}
    <Field label={$t('plan.f.deposit_required')} value={money(depositAmount, $lang)} />
{/if}
{#if mp.deposit_required_percentage != null}
    <Field label={$t('plan.f.deposit_pct')} value={`${num(mp.deposit_required_percentage, $lang)}%`} />
{/if}
{#if rateEstimateLabel}
    <Field label={$t('plan.f.rate_estimate')} value={rateEstimateLabel} />
{/if}
<Field label={$t('plan.f.io_vs_pi')} value={iovspiLabel(mp.io_vs_pi_recommendation)} />
{#if 'offset_strategy_recommendation' in outcome}
<!-- Mode C only (offset_strategy_recommendation) — same "doesn't apply, don't render"
     call as loanStructure above; Mode D has no offset concept at all. -->
<Field label={$t('plan.f.offset_strategy')} value={offsetLabel(mp.offset_strategy_recommendation)} />
{/if}
{#if 'fixed_vs_variable' in outcome}
    <Field label={$t('plan.f.fixed_vs_variable')} value={rateLabel(mp.fixed_vs_variable)} />
{/if}

<div class="pp-chips-row">
    {#if typeof mp.firb_dependency_acknowledged === 'boolean'}
        <Chip
            label={`${$t('plan.f.firb_dependency')} ${mp.firb_dependency_acknowledged ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={mp.firb_dependency_acknowledged ? 'warn' : 'neutral'}
        />
    {/if}
    {#if typeof mp.vn_income_acceptance_confirmed === 'boolean'}
        <Chip
            label={`${$t('plan.f.vn_income_confirmed')} ${mp.vn_income_acceptance_confirmed ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={mp.vn_income_acceptance_confirmed ? 'good' : 'neutral'}
        />
    {/if}
    {#if typeof mp.fx_risk_acknowledged === 'boolean'}
        <Chip
            label={`${$t('plan.f.fx_risk_ack')} ${mp.fx_risk_acknowledged ? $t('onboarding.yes') : $t('onboarding.no')}`}
            tone={mp.fx_risk_acknowledged ? 'good' : 'neutral'}
        />
    {/if}
</div>

{#if 'loan_cost_estimate_year_1' in outcome}
    <Field label={$t('plan.f.loan_cost_y1')} value={money(mp.loan_cost_estimate_year_1, $lang)} />
{/if}
{#if 'pre_approval_expiry' in outcome}
    <Field label={$t('plan.f.preapproval_expiry')} value={mp.pre_approval_expiry ?? null} />
{/if}
{#if 'reapplication_required' in outcome}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.reapplication')}</span>
        {#if mp.reapplication_required === true}
            <Chip label={$t('onboarding.yes')} tone="warn" />
        {:else if mp.reapplication_required === false}
            <Chip label={$t('onboarding.no')} tone="good" />
        {:else}
            <Pending />
        {/if}
    </div>
{/if}

<NoteList heading={$t('plan.f.debt_optimisations')} notes={mp.debt_optimisations_to_action} />

{#if refi}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.refinance')}</span>
        <Field label={$t('plan.f.usable_equity')} value={money(refi.usable_equity_estimate, $lang)} />
        <Field
            label={$t('plan.f.usable_equity_lvr')}
            value={refi.usable_equity_target_lvr_pct != null ? `${num(refi.usable_equity_target_lvr_pct, $lang)}%` : null}
        />
    </div>
{/if}

{:else if isPortfolioForeign}
<!-- ── ownership_planning_foreign_investor (portfolio_position_foreign, Mode D) ────── -->
{#if ppfAuObligations.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.pp.obligations')} (AU)</span>
        {#each ppfAuObligations as ob, i (i)}
            {#if pick(ob, $lang)}<p class="pp-obligation">{pick(ob, $lang)}</p>{/if}
        {/each}
    </div>
{/if}
{#if ppfVnObligations.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.pp.obligations')} (VN)</span>
        {#each ppfVnObligations as ob, i (i)}
            {#if pick(ob, $lang)}<p class="pp-obligation">{pick(ob, $lang)}</p>{/if}
        {/each}
    </div>
{/if}
<Field label={$t('plan.pp.cash_flow')} value={ppfCashFlow} />
<Field label={$t('plan.f.frcgw_reserve')} value={ppfFrcgw} />
<div class="pp-field">
    <span class="pp-label">{$t('plan.pp.ready')}</span>
    {#if ppf.ready_for_next_property === true}
        <Chip label={$t('plan.pp.ready_yes')} tone="good" />
    {:else}
        <Pending />
    {/if}
</div>
<div class="pp-field">
    <span class="pp-label">{$t('plan.mode_switch.title')}</span>
    {#if ppf.mode_switch_eligible_on_pr === true}
        <Chip label={$t('onboarding.yes')} tone="good" />
    {:else}
        <Chip label={$t('onboarding.no')} tone="neutral" />
    {/if}
</div>
{#if ppf.alert_triggers_armed?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.alerts')}</span>
        {#each ppf.alert_triggers_armed as a, i (i)}
            {#if pick(a.trigger, $lang) || pick(a.action, $lang)}
                <div class="pp-alert">
                    {#if pick(a.trigger, $lang)}<span class="pp-alert-trigger">{pick(a.trigger, $lang)}</span>{/if}
                    {#if pick(a.action, $lang)}<span class="pp-alert-action">{pick(a.action, $lang)}</span>{/if}
                </div>
            {/if}
        {/each}
    </div>
{/if}

{:else if isPreparation}
<!-- preparation_plan: every real field is already rendered by the sibling `checklist`
     renderer (Checklist.svelte) — intentionally empty rather than duplicating content or
     falling through to the FHB ownership-cost shape below. -->

{:else}
<!-- ── Outgoings hero ─────────────────────────────────────────────────── -->
<div class="og-hero">
    <div class="og-head">
        <span class="og-label">{$t('plan.f.monthly')}</span>
        {#if monthly}<span class="og-total">{monthly}</span>{:else}<Pending />{/if}
    </div>
    <StackedBar segments={outSegments} {density} />
</div>

<Field label={$t('plan.f.statutory')} value={statutory} />

{#if o.land_tax_check}
    <div class="pp-field">
        <span class="pp-label">{$t('plan.f.land_tax')}</span>
        <Chip label={landTaxLabel(o.land_tax_check)} tone={LAND_TAX[o.land_tax_check] ?? 'neutral'} />
    </div>
{:else}
    <Field label={$t('plan.f.land_tax')} value={null} />
{/if}

<Field label={$t('plan.f.maintenance')} value={money(o.maintenance_reserve_target, $lang)} />
<Field label={$t('plan.f.monthly')} value={money(o.total_monthly_outgoings_estimate, $lang)} />
<Field label={$t('plan.f.annual')} value={money(o.total_annual_outgoings_estimate, $lang)} />

{#if isOwnershipForeign}
    <Field label={$t('plan.f.vacancy_fee_at_risk')} value={money(o.vacancy_fee_at_risk_amount, $lang)} />
    {#if o.current_year_occupancy_status}
        <div class="pp-field">
            <span class="pp-label">{$t('plan.f.occupancy_status')}</span>
            <Chip label={occupancyLabel(o.current_year_occupancy_status)}
                tone={OCCUPANCY[o.current_year_occupancy_status] ?? 'neutral'} />
        </div>
    {:else}
        <Field label={$t('plan.f.occupancy_status')} value={null} />
    {/if}
    <Field label={$t('plan.f.nr_filing')}
        value={typeof o.non_resident_tax_filing_required === 'boolean'
            ? (o.non_resident_tax_filing_required ? $t('plan.f.yes') : $t('plan.f.no'))
            : null} />
{/if}

<NoteList notes={o.recurring_costs_estimate?.notes} />

{#if grad}
    <div class="og-grad">
        <span class="og-grad-title">{$t('plan.grad.title')}</span>
        <p class="og-grad-body">{gradBody}</p>
        {#if typeof grad.estimated_year === 'number'}
            <p class="og-grad-year">{$t('plan.grad.year')} {grad.estimated_year}</p>
        {:else}
            <p class="og-grad-year og-grad-pending">{$t('plan.grad.year_pending')}</p>
        {/if}
    </div>
{/if}

{#if o.alert_triggers_armed?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.alerts')}</span>
        {#each o.alert_triggers_armed as a, i (i)}
            {#if pick(a.trigger, $lang) || pick(a.action, $lang)}
                <div class="pp-alert">
                    {#if pick(a.trigger, $lang)}<span class="pp-alert-trigger">{pick(a.trigger, $lang)}</span>{/if}
                    {#if pick(a.action, $lang)}<span class="pp-alert-action">{pick(a.action, $lang)}</span>{/if}
                </div>
            {/if}
        {/each}
    </div>
{/if}
{/if}

<style>
    /* The negative-gearing reform note — a calm caveat highlight (proposed, not law). */
    .tx-reform {
        margin: 0 0 0.6rem;
        padding: 0.6rem 0.75rem;
        border-left: 3px solid var(--accent);
        background: var(--accent-soft);
        border-radius: 0 0.4rem 0.4rem 0;
    }
    .tx-reform-title {
        font-size: var(--fs-xs);
        font-weight: 700;
        color: var(--accent);
    }
    .tx-reform-body {
        margin: 0.25rem 0 0;
        font-size: var(--fs-sm);
        color: var(--ink);
        line-height: 1.45;
    }
    /* One annual-tax-obligation line (portfolio_position headline) — calm prose. */
    .pp-obligation {
        margin: 0.2rem 0 0;
        font-size: var(--fs-sm);
        color: var(--ink);
        line-height: 1.45;
    }
    .og-hero {
        margin-bottom: 0.6rem;
    }
    .og-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .og-label {
        font-size: var(--fs-sm);
        color: var(--muted);
    }
    .og-total {
        font-size: var(--fs-lg);
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    /* The graduation milestone — a calm highlight (the prototype's callout). */
    .og-grad {
        margin: 0.7rem 0 0.4rem;
        padding: 0.6rem 0.75rem;
        border-left: 3px solid var(--accent);
        background: var(--accent-soft);
        border-radius: 0 0.4rem 0.4rem 0;
    }
    .og-grad-title {
        font-size: var(--fs-xs);
        font-weight: 700;
        color: var(--accent);
    }
    .og-grad-body {
        margin: 0.25rem 0 0;
        font-size: var(--fs-sm);
        color: var(--ink);
        line-height: 1.45;
    }
    .og-grad-year {
        margin: 0.3rem 0 0;
        font-size: var(--fs-xs);
        font-weight: 600;
        color: var(--ink);
    }
    .og-grad-pending {
        font-weight: 400;
        font-style: italic;
        color: var(--muted);
    }
</style>
