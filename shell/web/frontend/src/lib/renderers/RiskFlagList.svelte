<script lang="ts">
    // The `risk-flag-list` renderer — phase_playbook risks (and later due_diligence /
    // settlement_prep). Each risk is a KB-grounded {severity, item, action(mitigation)}:
    // the engine PLACES it from the KB (resolver, never LLM-generated — risks must be
    // grounded, not invented). LAYERED representation: a row SUMMARISES the risk (severity
    // badge + the risk itself) and is clickable; the mitigation/solution opens in a popup
    // Modal (layered over the phase modal, like the action and budget drill-downs). R2
    // honest-partial: an empty list renders nothing (the caller decides the heading). R4
    // bilingual: item/action via pick()/$lang; the severity label is closed-enum chrome via $t.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type PhaseRisk } from '$lib/planCard';
    import Modal from '$lib/Modal.svelte';

    let { risks }: { risks: PhaseRisk[] } = $props();

    const SEV = new Set(['low', 'medium', 'high']);
    const sevLabel = (s: string): string =>
        SEV.has(s) ? $t(`plan.risk.sev.${s}` as 'plan.risk.sev.low') : s;

    // Risks carry no stable id → track the open one by index (stable within a render).
    let selectedIndex = $state<number | null>(null);
    const selected = $derived(selectedIndex !== null ? (risks[selectedIndex] ?? null) : null);
</script>

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
        color: #b91c1c;
        border-color: #fecaca;
        background: #fef2f2;
    }
    .rf-sev-medium {
        color: #92400e;
        border-color: #fde68a;
        background: #fffbeb;
    }
    .rf-sev-low {
        color: #15803d;
        border-color: #a7f3d0;
        background: #ecfdf5;
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
