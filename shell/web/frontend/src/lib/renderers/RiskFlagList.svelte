<script lang="ts">
    // The `risk-flag-list` renderer. TWO callers, two shapes (constraint #7 — one renderer
    // NAME, shape-discriminated INSIDE; no new renderer):
    //  • PhaseSheet passes `risks` (PhaseRisk[]) — the phase_playbook per-phase KB risks. A row
    //    SUMMARISES the risk (severity badge + the risk) and is clickable; the mitigation opens
    //    in a popup Modal (layered over the phase modal).
    //  • ComponentCard passes `outcome` — due_diligence's risk_assessment_investor (Mode C, Phase
    //    B): the RISK surface = overall_verdict + investor_specific_concerns + high_severity_flags.
    //    The PROCUREMENT surface (checklist · actions · questions) is the sibling `checklist`
    //    renderer ([[unify-views-as-projections-of-one-primitive]] — two renderers, one outcome).
    // Discriminate on WHICH prop is defined; the dd shape is recognised by docs_status/
    // overall_verdict, so any other outcome flowing through ComponentCard renders nothing (never
    // garbage). R2 honest-partial: an empty list / absent section renders nothing. R4 bilingual:
    // item/action/detail via pick()/$lang; severity + verdict labels are closed-enum chrome via $t.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type PhaseRisk, type RiskAssessmentInvestorOutcome } from '$lib/planCard';
    import Modal from '$lib/Modal.svelte';

    let { risks, outcome }: { risks?: PhaseRisk[]; outcome?: Record<string, unknown> } = $props();

    const SEV = new Set(['low', 'medium', 'high']);
    const sevLabel = (s: string): string =>
        SEV.has(s) ? $t(`plan.risk.sev.${s}` as 'plan.risk.sev.low') : s;

    // --- phase_playbook path (PhaseSheet, `risks`) ---------------------------
    // Risks carry no stable id → track the open one by index (stable within a render).
    let selectedIndex = $state<number | null>(null);
    const selected = $derived(
        risks && selectedIndex !== null ? (risks[selectedIndex] ?? null) : null
    );

    // --- due_diligence path (ComponentCard, `outcome`) -----------------------
    const dd = $derived(
        outcome && ('docs_status' in outcome || 'overall_verdict' in outcome)
            ? (outcome as unknown as RiskAssessmentInvestorOutcome)
            : null
    );
    const ddConcerns = $derived(dd?.investor_specific_concerns ?? []);
    const ddFlags = $derived(dd?.high_severity_flags ?? []);
    const VERDICT = new Set(['pending_documents', 'low_risk', 'proceed_with_actions', 'high_risk']);
    const verdictLabel = (v: string): string =>
        VERDICT.has(v) ? $t(`plan.dd.verdict.${v}` as 'plan.dd.verdict.low_risk') : v;
    const verdictClass = (v: string): string =>
        v === 'high_risk' ? 'high'
        : v === 'proceed_with_actions' ? 'medium'
        : v === 'low_risk' ? 'low'
        : 'pending';
    // The high-severity flags carry no stable id → track the open one by index.
    let selectedFlag = $state<number | null>(null);
    const flag = $derived(selectedFlag !== null ? (ddFlags[selectedFlag] ?? null) : null);
</script>

{#if risks !== undefined}
    {#if risks.length}
        <ul class="rf-list">
            {#each risks as r, i (i)}
                <li class="rf-item">
                    <button type="button" class="rf-row" onclick={() => (selectedIndex = i)}>
                        <span class="rf-sev rf-sev-{r.severity}">{sevLabel(r.severity)}</span>
                        <span class="rf-what">{pick(r.item, $lang)}</span>
                        <span class="rf-caret" aria-hidden="true">▸</span>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}

    <!-- Layered drill: the mitigation/solution for the tapped risk, in a popup modal. -->
    {#if selected}
        <Modal title={pick(selected.item, $lang)} onClose={() => (selectedIndex = null)}>
            <div class="rf-detail">
                <span class="rf-sev rf-sev-{selected.severity}">{sevLabel(selected.severity)}</span>
                <p class="rf-detail-mit">
                    <span class="rf-mit-k">{$t('plan.risk.mitigation')}</span>
                    <span>{pick(selected.action, $lang)}</span>
                </p>
            </div>
        </Modal>
    {/if}
{:else if dd}
    {#if dd.overall_verdict}
        <p class="rf-verdict rf-verdict-{verdictClass(dd.overall_verdict)}">
            {verdictLabel(dd.overall_verdict)}
        </p>
    {/if}

    {#if ddConcerns.length}
        <ul class="rf-list">
            {#each ddConcerns as c (c.id)}
                <li class="rf-item">
                    <div class="rf-row rf-static">
                        <span class="rf-sev rf-sev-{c.severity}">{sevLabel(c.severity)}</span>
                        <span class="rf-what">{pick(c.detail, $lang)}</span>
                    </div>
                </li>
            {/each}
        </ul>
    {/if}

    {#if ddFlags.length}
        <h4 class="rf-flags-h">{$t('plan.dd.high_severity')}</h4>
        <ul class="rf-list">
            {#each ddFlags as f, i (i)}
                <li class="rf-item">
                    <button type="button" class="rf-row" onclick={() => (selectedFlag = i)}>
                        <span class="rf-sev rf-sev-high">{sevLabel('high')}</span>
                        <span class="rf-what">{pick(f.item, $lang)}</span>
                        <span class="rf-caret" aria-hidden="true">▸</span>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}

    <!-- Layered drill: the action for the tapped high-severity flag, in a popup modal. -->
    {#if flag}
        <Modal title={pick(flag.item, $lang)} onClose={() => (selectedFlag = null)}>
            <div class="rf-detail">
                <span class="rf-sev rf-sev-high">{sevLabel('high')}</span>
                <p class="rf-detail-mit">
                    <span class="rf-mit-k">{$t('plan.risk.mitigation')}</span>
                    <span>{pick(flag.action, $lang)}</span>
                </p>
            </div>
        </Modal>
    {/if}
{/if}

<style>
    .rf-list {
        list-style: none;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        gap: 0.4rem;
    }
    .rf-item {
        border-bottom: 1px dashed var(--border);
    }
    .rf-item:last-child {
        border-bottom: none;
    }
    .rf-row {
        display: flex;
        align-items: baseline;
        gap: 0.45rem;
        width: 100%;
        font: inherit;
        text-align: left;
        background: none;
        border: none;
        padding: 0.4rem 0;
        cursor: pointer;
    }
    .rf-row:hover .rf-what {
        color: var(--accent);
    }
    /* a non-clickable concern row (no mitigation drill) — no pointer, no hover-accent. */
    .rf-static {
        cursor: default;
    }
    .rf-static:hover .rf-what {
        color: var(--ink);
    }
    .rf-sev {
        flex: none;
        font-size: 0.62rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        padding: 0.05rem 0.4rem;
        border-radius: 0.3rem;
        border: 1px solid var(--border);
        color: var(--muted);
        white-space: nowrap;
    }
    .rf-sev-high {
        color: var(--danger);
        border-color: var(--danger-line);
        background: var(--danger-soft);
    }
    .rf-sev-medium {
        color: var(--warning);
        border-color: var(--warning-line);
        background: var(--warning-soft);
    }
    .rf-sev-low {
        color: var(--success);
        border-color: var(--success-line);
        background: var(--success-soft);
    }
    .rf-what {
        flex: 1;
        font-size: 0.88rem;
        font-weight: 600;
        color: var(--ink);
        line-height: 1.35;
    }
    .rf-caret {
        flex: none;
        font-size: 0.75rem;
        color: var(--accent);
        align-self: center;
    }
    /* due_diligence overall verdict — a headline pill above the concerns. */
    .rf-verdict {
        margin: 0 0 0.5rem;
        display: inline-block;
        font-size: 0.72rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        padding: 0.15rem 0.5rem;
        border-radius: 0.3rem;
        border: 1px solid var(--border);
        color: var(--muted);
    }
    .rf-verdict-high {
        color: var(--danger);
        border-color: var(--danger-line);
        background: var(--danger-soft);
    }
    .rf-verdict-medium {
        color: var(--warning);
        border-color: var(--warning-line);
        background: var(--warning-soft);
    }
    .rf-verdict-low {
        color: var(--success);
        border-color: var(--success-line);
        background: var(--success-soft);
    }
    .rf-verdict-pending {
        color: var(--muted);
    }
    .rf-flags-h {
        margin: 0.7rem 0 0.4rem;
        font-size: 0.78rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        color: var(--danger);
    }
    .rf-detail {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        align-items: flex-start;
    }
    .rf-detail-mit {
        margin: 0;
        font-size: 0.9rem;
        color: var(--ink);
        line-height: 1.45;
    }
    .rf-mit-k {
        display: block;
        font-size: 0.72rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        color: var(--muted);
        margin-bottom: 0.2rem;
    }
</style>
