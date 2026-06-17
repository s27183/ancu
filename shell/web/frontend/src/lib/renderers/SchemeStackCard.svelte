<script lang="ts">
    // The `scheme-stack-card` renderer — eligibility (scheme_stack). Slice 1 of the
    // plan-card visual layer (plan-card-visual-spec §3.2): the section now OPENS with a
    // hero **scheme stack bar** — one segment per applicable scheme, sized by its
    // benefit_value, summing visually to total_benefit_value — then the textual detail.
    //
    // Stakes held (the spec's cross-cutting rules):
    //   R1 deterministic — the bar is a pure function outcome→geometry, drawn here in
    //      CSS flex. Nothing is agent-drawn.
    //   R2 honest-partial — a scheme whose benefit_value the base turn can't yet know
    //      renders as a fixed-width HATCHED slice (counted, not sized); a null total
    //      shows Pending. Never a zero, never a faked width.
    //   R4 bilingual-at-source — labels are enum→$t or LocalizedText→pick($lang);
    //      figures via the shared money() formatter. No prose minted here.
    //
    // `density` ('compact' for the in-map projection, 'full' for the export dossier)
    // sizes the bar; the same hero drives both surfaces (one outcome model).
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { pick, type SchemeStackOutcome, type MoneyRange } from '$lib/planCard';
    import { money, moneyRange } from '$lib/format';
    import Chip from './Chip.svelte';
    import NoteList from './NoteList.svelte';
    import Pending from './Pending.svelte';
    import StackedBar from './StackedBar.svelte';

    let { outcome, density = 'compact' }: {
        outcome: Record<string, unknown>;
        density?: 'compact' | 'full';
    } = $props();
    const o = $derived(outcome as SchemeStackOutcome);
    const schemes = $derived(o.applicable_schemes ?? []);

    const BASES: Record<string, 'good' | 'warn' | 'neutral'> = {
        all_applicants_eligible: 'good',
        eligible_only_if_restructured: 'warn',
        ineligible: 'warn'
    };
    function basisLabel(b: string): string {
        return b in BASES ? $t(`plan.basis.${b}` as 'plan.basis.ineligible') : b;
    }

    // Decision 8: benefit_value is a money_range [lo, hi] (or null when unknown).
    const hasRange = (v: MoneyRange | null | undefined): v is MoneyRange =>
        Array.isArray(v) && v.length === 2 && typeof v[0] === 'number' && typeof v[1] === 'number';
    const mid = (r: MoneyRange) => (r[0] + r[1]) / 2;

    // A benefit reads as "$x" when the range has collapsed to a point, "$lo – $hi"
    // otherwise, and "—" when unknown. ~ prefixes a banded estimate (e.g. FHG LMI).
    function benefitLabel(v: MoneyRange | null | undefined): string {
        if (!hasRange(v)) return '—';
        if (v[0] === v[1]) return money(v[0], $lang) ?? '—';
        return moneyRange(v, $lang) ?? '—';
    }

    // The hero bar segments (one per scheme), handed to the shared StackedBar primitive:
    // sized by the benefit range MIDPOINT, null when honestly unknown (→ hatched slice).
    const segments = $derived(
        schemes.map((s) => ({
            value: hasRange(s.benefit_value) ? mid(s.benefit_value) : null,
            label: s.name ?? '—',
            amount: benefitLabel(s.benefit_value),
            estimate: s.benefit_is_estimate ?? false
        }))
    );
</script>

<div class="ss-hero">
    <div class="ss-head">
        {#if o.eligibility_basis}
            <Chip label={basisLabel(o.eligibility_basis)} tone={BASES[o.eligibility_basis] ?? 'neutral'} />
        {:else}
            <Pending />
        {/if}
        <div class="ss-total">
            <span class="ss-total-label">{$t('plan.f.total_benefit')}</span>
            {#if hasRange(o.total_benefit_value)}
                <span class="ss-total-value">{benefitLabel(o.total_benefit_value)}</span>
            {:else}
                <Pending />
            {/if}
        </div>
    </div>

    {#if segments.length}
        <StackedBar {segments} {density} />
    {/if}
</div>

<!-- Detail below the hero: per-scheme notes (only where present — the hero already
     carries name+benefit), then rejected schemes, stacking notes, application order. -->
{#each schemes as s, i (i)}
    {#if s.notes?.length}
        <div class="pp-scheme">
            {#if s.name}<span class="pp-scheme-name">{s.name}</span>{/if}
            <NoteList notes={s.notes} />
        </div>
    {/if}
{/each}

{#if o.rejected_schemes?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.rejected_schemes')}</span>
        {#each o.rejected_schemes as r, i (i)}
            <div class="pp-scheme muted">
                {#if r.name}<span class="pp-scheme-name">{r.name}</span>{/if}
                {#if pick(r.reason, $lang)}<p class="pp-scheme-why">{pick(r.reason, $lang)}</p>{/if}
            </div>
        {/each}
    </div>
{/if}

<NoteList heading={$t('plan.f.stacking')} notes={o.stacking_constraints} />

{#if o.recommended_application_order?.length}
    <div class="pp-sublist">
        <span class="pp-label">{$t('plan.f.order')}</span>
        <ol class="pp-order">
            {#each o.recommended_application_order as step, i (i)}
                <li>{step}</li>
            {/each}
        </ol>
    </div>
{/if}

<style>
    .ss-hero {
        margin-bottom: 0.6rem;
    }
    .ss-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .ss-total {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        line-height: 1.1;
    }
    .ss-total-label {
        font-size: 0.7rem;
        color: var(--muted);
    }
    .ss-total-value {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--accent);
        font-variant-numeric: tabular-nums;
    }
    /* the bar + legend now live in the shared StackedBar primitive (visual-spec §4). */
</style>
