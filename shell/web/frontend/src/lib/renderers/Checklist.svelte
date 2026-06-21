<script lang="ts">
    // The `checklist` renderer — preparation (readiness). The prototype's "Before you buy":
    // the property-agnostic readiness layer — documents to gather (with WHY each matters),
    // people to engage (role · when · why), scheme applications to start, and the money
    // buffer. The engine PLACES this content; the renderer only lays it out.
    //
    // R2 honest-partial: an absent section is omitted, never an empty heading. R4 bilingual:
    // engine prose via pick()/$lang; section headings + status chrome via $t.
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type PreparationOutcome } from '$lib/planCard';
    import { money } from '$lib/format';
    import NoteList from './NoteList.svelte';

    let { outcome }: { outcome: Record<string, unknown> } = $props();
    const o = $derived(outcome as PreparationOutcome);

    const docs = $derived(o.document_checklist ?? []);
    const people = $derived(o.people_to_engage ?? []);
    const schemes = $derived(o.scheme_applications_to_prepare ?? []);
    const buffer = $derived(o.money_buffer ?? null);

    const STATUS = new Set(['not_started', 'in_progress', 'done']);
    function statusLabel(s: string | null | undefined): string | null {
        if (!s) return null;
        return STATUS.has(s) ? $t(`plan.prep.status.${s}` as 'plan.prep.status.not_started') : s;
    }
</script>

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

<NoteList heading={$t('plan.f.assumptions')} notes={o.key_assumptions} />

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
    .ck-why {
        margin: 0.15rem 0 0;
        font-size: 0.8rem;
        color: var(--muted);
        line-height: 1.4;
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
    .ck-buffer-amt {
        margin: 0 0 0.3rem;
        font-size: 1rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
</style>
