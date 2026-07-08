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
    import { t } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import type { NewsNote } from '$lib/api';
    import { renderInlineMarkdown } from '$lib/markdown';

    let { note, onClose, onDismiss }: { note: NewsNote; onClose: () => void; onDismiss?: () => void } =
        $props();

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

<Modal title={$t('plan.news.detail_title')} {onClose}>
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
