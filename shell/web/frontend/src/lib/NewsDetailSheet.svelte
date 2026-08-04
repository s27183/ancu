<script lang="ts">
    // News detail sheet (kb-news-feature.md, task 28): opened by tapping a NewsTicker
    // headline. Built on Modal.svelte (the existing drill-down surface — attach-property,
    // settlement dates, lease upload all open into it), not SuburbSheet's bespoke
    // tab-bearing panel, since this is the "small popup with a few facts" idiom, not an
    // outer container. Bilingual summary + a generic diff dump + the primary source link +
    // an explicit dismiss action (task 31) — distinct from onClose: closing (✕/backdrop/
    // Escape) just puts the sheet away and still scrolls/highlights the affected tile;
    // dismiss additionally retires the note from this card's rotation for good.
    //
    // `onDismiss` is OPTIONAL (kb-news-feature.md "Homepage ticker", 2026-07-08): the
    // homepage's unfiltered ticker has no card to retire a note FROM, so it opens this
    // same sheet with no onDismiss — the Dismiss button just doesn't render. Dismiss
    // was always a per-card action surfaced here, never a property of the sheet itself.
    import { lang } from '$lib/stores/lang';
    import { t, type MessageKey } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import type { NewsNote, NewsCategory } from '$lib/api';
    import { renderInlineMarkdown } from '$lib/markdown';
    import { date as formatDate } from '$lib/format';

    let { note, onClose, onDismiss }: { note: NewsNote; onClose: () => void; onDismiss?: () => void } =
        $props();

    // Same inline bilingual-pick idiom as NewsTicker.svelte/NewsListSheet.svelte — kept
    // duplicated (task 30 note) rather than newly extracted here. Was previously read only
    // for the ticker strip; the sheet title used a generic "Plan update" chrome string
    // instead, so opening any note showed the same title regardless of which one — this
    // sheet now titles itself with the note's own headline, the thing the buyer actually
    // tapped.
    function headlineFor(n: NewsNote): string {
        const primary = $lang === 'vi' ? n.headline_vi : n.headline_en;
        const fallback = $lang === 'vi' ? n.headline_en : n.headline_vi;
        return primary ?? fallback ?? n.summary_en ?? n.summary_vi ?? '';
    }
    const headline = $derived(headlineFor(note) || $t('plan.news.detail_title'));

    const CATEGORY_LABEL_KEY: Record<NewsCategory, MessageKey> = {
        visa: 'home.news.category.visa',
        finance: 'home.news.category.finance',
        scheme: 'home.news.category.scheme',
        tax: 'home.news.category.tax',
        property: 'home.news.category.property',
        market: 'home.news.category.market'
    };
    const categoryLabel = $derived(note.category ? $t(CATEGORY_LABEL_KEY[note.category]) : null);
    // authored_date (when the KB note was written) is the more meaningful "how fresh is
    // this" figure for a buyer; effective_from (when the change takes legal/policy effect)
    // is the fallback for a note authored without it.
    const dateLabel = $derived(formatDate(note.authored_date ?? note.effective_from, $lang));

    // Same inline bilingual-pick idiom as NewsTicker.svelte/Onboarding.svelte/
    // SuburbSheet.svelte — task 30 stays open until a second real consumer reuses it;
    // this sheet is that consumer.
    const summary = $derived(
        ($lang === 'vi' ? note.summary_vi : note.summary_en) ?? note.summary_en ?? note.summary_vi ?? ''
    );
    // KB authors write summaries with **bold**/*italic* (docs/kb convention) — render it,
    // don't show the buyer literal asterisks.
    const summaryHtml = $derived(renderInlineMarkdown(summary));

    // `note.diff` is a generic, schema-less JSON blob (kb_compiler.py's build-time audit
    // trail for what a news note changed) — authored for the KB-authoring/QA workflow, not
    // for a buyer to read. Rendering it as a raw JSON dump here was audit content leaking
    // into the end-user surface; the human-readable version is already the summary above.
    const sourceUrl = $derived(note.sources?.[0]?.url ?? '');
</script>

<Modal title={headline} {onClose}>
    {#if categoryLabel || dateLabel}
        <p class="pp-news-meta">
            {#if categoryLabel}<span class="pp-news-meta-cat">{categoryLabel}</span>{/if}
            {#if categoryLabel && dateLabel}<span aria-hidden="true"> · </span>{/if}
            {#if dateLabel}<span class="pp-news-meta-date">{dateLabel}</span>{/if}
        </p>
    {/if}
    <p class="pp-news-summary">{@html summaryHtml}</p>
    {#if sourceUrl}
        <a class="pp-news-source" href={sourceUrl} target="_blank" rel="noopener noreferrer"
            >{$t('plan.news.source')}</a
        >
    {/if}
    {#if onDismiss}
        <button type="button" class="primary pp-news-dismiss" onclick={onDismiss}>
            {$t('plan.news.dismiss')}
        </button>
    {/if}
</Modal>
