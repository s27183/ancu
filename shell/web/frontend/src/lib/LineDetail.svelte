<script module lang="ts">
    import type { LocalizedText } from '$lib/planCard';
    export type LineStep = { phase: string; id: string; label: LocalizedText };
</script>

<script lang="ts">
    // Whole lifecycle -> the checklist links both ways -> the web frontend -> one line's detail
    // Goal:      behavior 95 — a statement line's detail reads the same wherever it opens: in
    //            place on its phase sheet (LifecycleSheet) or over the checklist from a step
    //            that links it (PhaseSheet), and from the sheet it names the steps that link
    //            it, each opening Hành trình at that step.
    // Invariant: it shows the engine's `detail` as is (behavior 83/93 words, the KB's) and
    //            the components that detail `explains`, never a figure of its own; the steps
    //            are the playbook actions whose budget_ref is this line's id or its group.
    // Capability: the detail body; `steps` empty or no `onstep` → no steps list.
    import { t } from '$lib/i18n';
    import Termed from '$lib/Termed.svelte';
    import { lang } from '$lib/stores/lang';
    import { pick, type ComponentEntry, type FeeDetail } from '$lib/planCard';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';

    let {
        detail: d,
        components,
        filling = false,
        steps = [],
        onstep
    }: {
        detail: FeeDetail;
        components: Record<string, ComponentEntry>;
        filling?: boolean;
        steps?: LineStep[];
        onstep?: (s: LineStep) => void;
    } = $props();

    // why a shown line is left out of the total, or null.
    const why = $derived.by((): string | null => {
        if (d.optional) return $t('plan.sheet.fee.optional');
        if (d.condition === 'strata') return $t('plan.sheet.fee.if_strata');
        if (d.condition === 'house') return $t('plan.sheet.fee.if_house');
        return null;
    });
    // a percentage line states its rate and base; a fixed line's range is its amount.
    const basis = $derived.by((): string | null => {
        const [lo, hi] = d.band;
        if (d.basis === 'fixed' || lo == null || hi == null) return null;
        const fmt = (n: number) => n.toLocaleString($lang === 'vi' ? 'vi-VN' : 'en-AU');
        return $t(`plan.sheet.basis.${d.basis}` as 'plan.sheet.basis.pct_of_sale')
            .replace('{lo}', fmt(lo))
            .replace('{hi}', fmt(hi));
    });
    function sourceHost(url: string): string {
        try {
            return new URL(url).hostname.replace(/^www\./, '');
        } catch {
            return url;
        }
    }
    const explained = $derived((d.explains ?? []).filter((c) => components[c]));
</script>

<div class="ld">
    {#if why}<p class="ld-why">{why}</p>{/if}
    <dl class="ld-facts">
        {#if d.how}
            <div><dt>{$t('plan.sheet.fee.how')}</dt><dd><Termed text={pick(d.how, $lang)} /></dd></div>
        {:else if basis}
            <div><dt>{$t('plan.sheet.fee.range')}</dt><dd>{basis}</dd></div>
        {/if}
        {#if d.payer}
            <div><dt>{$t('plan.sheet.fee.payer')}</dt><dd><Termed text={pick(d.payer, $lang)} /></dd></div>
        {/if}
        {#if d.drivers}
            <div><dt>{$t('plan.sheet.fee.drivers')}</dt><dd><Termed text={pick(d.drivers, $lang)} /></dd></div>
        {/if}
        {#if d.source}
            <div>
                <dt>{$t('plan.sheet.fee.source')}</dt>
                <dd>
                    <a href={d.source} target="_blank" rel="noopener noreferrer">{sourceHost(d.source)}</a>
                </dd>
            </div>
        {/if}
    </dl>
    <p class="ld-note">
        <Termed
            text={d.note
                ? pick(d.note, $lang)
                : d.tier === 'REGULATED'
                  ? $t('plan.sheet.fee.regulated_note')
                  : $t('plan.sheet.fee.quote_note')}
        />
    </p>
    {#if onstep && steps.length > 0}
        <div class="ld-steps">
            <p class="ld-steps-title">{$t('plan.sheet.steps')}</p>
            <ul>
                {#each steps as s (s.phase + s.id)}
                    <li>
                        <button type="button" class="ld-step" onclick={() => onstep(s)}
                            >{pick(s.label, $lang)} <span aria-hidden="true">›</span></button
                        >
                    </li>
                {/each}
            </ul>
        </div>
    {/if}
    {#each explained as cid (cid)}
        <div class="ld-explains">
            <ComponentCard componentId={cid} entry={components[cid]} {filling} />
        </div>
    {/each}
</div>

<style>
    .ld { display: grid; gap: 0.5rem; font-size: var(--fs-sm, 0.875rem); color: var(--ink); }
    .ld-why { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); font-style: italic; }
    .ld-facts { margin: 0; display: grid; gap: 0.4rem; }
    .ld-facts > div { display: grid; gap: 0.1rem; }
    .ld-facts dt {
        font-size: var(--fs-2xs, 0.6875rem); font-weight: 700; color: var(--muted);
        text-transform: uppercase; letter-spacing: 0.04em;
    }
    .ld-facts dd { margin: 0; max-width: 65ch; }
    .ld-facts a { color: var(--accent); overflow-wrap: anywhere; }
    .ld-note { margin: 0; font-size: var(--fs-xs, 0.75rem); color: var(--muted); }
    .ld-steps { display: grid; gap: 0.25rem; }
    .ld-steps-title {
        margin: 0; font-size: var(--fs-2xs, 0.6875rem); font-weight: 700; color: var(--muted);
        text-transform: uppercase; letter-spacing: 0.04em;
    }
    .ld-steps ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 0.15rem; }
    .ld-step {
        padding: 0.2rem 0; background: none; border: 0; font: inherit; text-align: left;
        color: var(--accent); cursor: pointer;
    }
    .ld-step:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    /* behavior 95: the component a line explains, drawn inside its detail. */
    .ld-explains { border-top: 1px solid var(--border); padding-top: 0.5rem; }
    .ld-explains :global(.pp-card) { margin: 0; padding: 0; border: 0; box-shadow: none; background: none; }
</style>
