<script lang="ts">
    // The `checklist` renderer — used by TWO components with different outcome shapes
    // (the engine names "checklist" for both; constraint #7 = no new renderer). We branch
    // on the outcome's discriminator:
    //
    //  • PreparationOutcome (due_diligence) — the prototype's "Before you buy": the
    //    property-agnostic readiness layer (documents · people · schemes · buffer).
    //  • SettlementChecklistOutcome (settlement_prep B, §11) — the DATED critical path:
    //    `pending_contract` (structure, every date null, awaiting the attested contract
    //    dates) or `active` (back-calculated milestones + at-risk detection). The dates
    //    are submitted via the settlement_prep B form (setTransactionDates).
    //
    // The engine PLACES this content; the renderer only lays it out. R2 honest-partial:
    // an absent section is omitted, never an empty heading. R4 bilingual: engine prose via
    // pick()/$lang; headings + status chrome via $t.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        pick,
        type PreparationOutcome,
        type SettlementChecklistOutcome,
        type MilestoneStatus,
        type RiskAssessmentInvestorOutcome,
        type DueDiligenceDoc
    } from '$lib/planCard';
    import { money } from '$lib/format';
    import NoteList from './NoteList.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();

    // The discriminators (constraint #7 — one renderer NAME, three outcome shapes): settlement
    // carries `dates_status`; Mode-C due_diligence (risk_assessment_investor) carries `docs_status`;
    // preparation (FHB readiness) carries neither.
    const isSettlement = $derived('dates_status' in (outcome ?? {}));
    const isDueDiligence = $derived('docs_status' in (outcome ?? {}));

    // --- due_diligence (Mode C, Phase B) — the PROCUREMENT surface ------------
    // The document checklist (what to gather + why; the lease entry flips received/reviewed once
    // interpreted), the actions-before-signing + vendor questions, and the next action. The RISK
    // surface (verdict + concerns + high-severity flags) is the sibling risk-flag-list renderer.
    const dd = $derived(outcome as unknown as RiskAssessmentInvestorOutcome);
    const ddDocs = $derived(dd.document_checklist ?? []);
    const ddActions = $derived(dd.actions_before_signing ?? []);
    const ddQuestions = $derived(dd.questions_for_vendor ?? []);
    function ddDocStatus(d: DueDiligenceDoc): { cls: string; label: string } {
        if (d.reviewed) return { cls: 'done', label: $t('plan.dd.doc.reviewed') };
        if (d.received) return { cls: 'in_progress', label: $t('plan.dd.doc.received') };
        if (d.required) return { cls: 'pending', label: $t('plan.dd.doc.required') };
        return { cls: 'pending', label: $t('plan.dd.doc.optional') };
    }

    // --- preparation (due_diligence) -----------------------------------------
    const prep = $derived(outcome as PreparationOutcome);
    const docs = $derived(prep.document_checklist ?? []);
    const people = $derived(prep.people_to_engage ?? []);
    const schemes = $derived(prep.scheme_applications_to_prepare ?? []);
    const buffer = $derived(prep.money_buffer ?? null);

    const STATUS = new Set(['not_started', 'in_progress', 'done']);
    function statusLabel(s: string | null | undefined): string | null {
        if (!s) return null;
        return STATUS.has(s) ? $t(`plan.prep.status.${s}` as 'plan.prep.status.not_started') : s;
    }

    // --- settlement_prep B (the dated critical path) -------------------------
    const settle = $derived(outcome as unknown as SettlementChecklistOutcome);
    const criticalPath = $derived(settle.critical_path_milestones ?? []);
    // Only applicable investor milestones (e.g. entity setup is dropped when the structure
    // needs none) — honest-partial: never show a milestone that does not apply.
    const investorMilestones = $derived(
        (settle.investor_milestones ?? []).filter((m) => m.applicable)
    );
    const atRisk = $derived(settle.at_risk_milestones ?? []);
    const M_STATUS = new Set(['pending', 'done', 'scheduled', 'at_risk']);
    function milestoneStatus(s: MilestoneStatus | null | undefined): string | null {
        if (!s) return null;
        return M_STATUS.has(s) ? $t(`plan.settle.status.${s}` as 'plan.settle.status.pending') : s;
    }
</script>

{#if isSettlement}
    {#if settle.dates_status === 'pending_contract'}
        <p class="ck-awaiting">{$t('plan.settle.awaiting')}</p>
    {/if}
    {#if settle.next_action_for_user}
        <p class="ck-why ck-next">{pick(settle.next_action_for_user, $lang)}</p>
    {/if}

    {#if atRisk.length}
        <h4 class="ck-heading">{$t('plan.settle.at_risk')}</h4>
        <ul class="ck-list">
            {#each atRisk as m, i (i)}
                <li class="ck-item ck-item-risk">
                    <span class="ck-item-name">{pick(m.name, $lang)}</span>
                    <p class="ck-why">{pick(m.reason, $lang)}</p>
                </li>
            {/each}
        </ul>
    {/if}

    {#if criticalPath.length}
        <h4 class="ck-heading">{$t('plan.settle.critical_path')}</h4>
        <ul class="ck-list">
            {#each criticalPath as m (m.id)}
                <li class="ck-item">
                    <div class="ck-item-head">
                        <span class="ck-item-name">{pick(m.name, $lang)}</span>
                        {#if milestoneStatus(m.status)}
                            <span class="ck-status ck-status-{m.status}">{milestoneStatus(m.status)}</span>
                        {/if}
                    </div>
                    {#if m.due_date}
                        <p class="ck-meta"><span class="ck-meta-k">{$t('plan.settle.due')}:</span> {m.due_date}</p>
                    {/if}
                </li>
            {/each}
        </ul>
    {/if}

    {#if investorMilestones.length}
        <h4 class="ck-heading">{$t('plan.settle.investor')}</h4>
        <ul class="ck-list">
            {#each investorMilestones as m (m.id)}
                <li class="ck-item">
                    <div class="ck-item-head">
                        <span class="ck-item-name">{pick(m.name, $lang)}</span>
                        {#if milestoneStatus(m.status)}
                            <span class="ck-status ck-status-{m.status}">{milestoneStatus(m.status)}</span>
                        {/if}
                    </div>
                    {#if m.why}<p class="ck-why">{pick(m.why, $lang)}</p>{/if}
                    {#if m.due_date}
                        <p class="ck-meta"><span class="ck-meta-k">{$t('plan.settle.due')}:</span> {m.due_date}</p>
                    {/if}
                </li>
            {/each}
        </ul>
    {/if}

    {#if settle.insurance_timing_rule}
        <h4 class="ck-heading">{$t('plan.settle.insurance')}</h4>
        <p class="ck-why">{pick(settle.insurance_timing_rule, $lang)}</p>
    {/if}
{:else if isDueDiligence}
    {#if dd.next_action_for_user}
        <p class="ck-why ck-next">{pick(dd.next_action_for_user, $lang)}</p>
    {/if}

    {#if ddDocs.length}
        <h4 class="ck-heading">{$t('plan.dd.docs')}</h4>
        <ul class="ck-list">
            {#each ddDocs as d (d.id)}
                <li class="ck-item">
                    <div class="ck-item-head">
                        <span class="ck-item-name">{pick(d.name, $lang)}</span>
                        <span class="ck-status ck-status-{ddDocStatus(d).cls}">{ddDocStatus(d).label}</span>
                    </div>
                    {#if d.why}<p class="ck-why">{pick(d.why, $lang)}</p>{/if}
                </li>
            {/each}
        </ul>
    {/if}

    <NoteList heading={$t('plan.dd.actions')} notes={ddActions} />
    <NoteList heading={$t('plan.dd.questions')} notes={ddQuestions} />
{:else}
    {#if docs.length}
        <h4 class="ck-heading">{$t('plan.prep.docs')}</h4>
        <ul class="ck-list">
            {#each docs as d (d.id)}
                <li class="ck-item">
                    <div class="ck-item-head">
                        <span class="ck-item-name">{pick(d.item, $lang)}</span>
                        {#if statusLabel(d.status)}
                            <span class="ck-status ck-status-{d.status}">{statusLabel(d.status)}</span>
                        {/if}
                    </div>
                    {#if d.why}<p class="ck-why">{pick(d.why, $lang)}</p>{/if}
                </li>
            {/each}
        </ul>
    {/if}

    {#if people.length}
        <h4 class="ck-heading">{$t('plan.prep.people')}</h4>
        <ul class="ck-list">
            {#each people as p, i (i)}
                <li class="ck-item">
                    <span class="ck-item-name">{pick(p.role, $lang)}</span>
                    {#if p.when}<p class="ck-meta"><span class="ck-meta-k">{$t('plan.prep.when')}:</span> {pick(p.when, $lang)}</p>{/if}
                    {#if p.why}<p class="ck-why">{pick(p.why, $lang)}</p>{/if}
                </li>
            {/each}
        </ul>
    {/if}

    {#if schemes.length}
        <h4 class="ck-heading">{$t('plan.prep.schemes')}</h4>
        <ul class="ck-list">
            {#each schemes as s (s.scheme)}
                <li class="ck-item"><span class="ck-item-name">{pick(s.action, $lang)}</span></li>
            {/each}
        </ul>
    {/if}

    {#if buffer}
        <h4 class="ck-heading">{$t('plan.prep.buffer')}</h4>
        {#if typeof buffer.reserve_buffer === 'number'}
            <p class="ck-buffer-amt">{money(buffer.reserve_buffer, $lang)}</p>
        {/if}
        <NoteList notes={buffer.notes} />
    {/if}

    <NoteList heading={$t('plan.f.assumptions')} notes={prep.key_assumptions} />
{/if}

<style>
    .ck-heading {
        margin: 0.8rem 0 0.4rem;
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--ink);
    }
    .ck-heading:first-child { margin-top: 0; }
    .ck-list {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .ck-item {
        border-bottom: 1px dashed var(--border);
        padding-bottom: 0.5rem;
    }
    .ck-item:last-child { border-bottom: none; padding-bottom: 0; }
    .ck-item-head {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
    }
    .ck-item-name {
        font-size: 0.88rem;
        font-weight: 600;
        color: var(--ink);
    }
    .ck-item-risk {
        border-left: 3px solid #f59e0b;
        padding-left: 0.5rem;
    }
    .ck-why {
        margin: 0.15rem 0 0;
        font-size: 0.8rem;
        color: var(--muted);
        line-height: 1.4;
    }
    .ck-next {
        margin: 0 0 0.4rem;
        color: var(--ink);
    }
    .ck-awaiting {
        margin: 0 0 0.4rem;
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--accent);
    }
    .ck-meta {
        margin: 0.15rem 0 0;
        font-size: 0.8rem;
        color: var(--ink);
    }
    .ck-meta-k { color: var(--muted); }
    .ck-status {
        flex: none;
        font-size: 0.66rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        padding: 0.05rem 0.4rem;
        border-radius: 0.3rem;
        border: 1px solid var(--border);
        color: var(--muted);
        white-space: nowrap;
    }
    .ck-status-done { color: #15803d; border-color: #a7f3d0; background: #ecfdf5; }
    .ck-status-in_progress { color: #92400e; border-color: #fde68a; background: #fffbeb; }
    .ck-status-scheduled { color: #1d4ed8; border-color: #bfdbfe; background: #eff6ff; }
    .ck-status-at_risk { color: #b91c1c; border-color: #fecaca; background: #fef2f2; }
    .ck-status-pending { color: var(--muted); }
    .ck-buffer-amt {
        margin: 0 0 0.3rem;
        font-size: 1rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
</style>
