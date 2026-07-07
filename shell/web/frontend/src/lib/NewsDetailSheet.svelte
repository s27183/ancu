<script lang="ts">
    // News detail sheet (kb-news-feature.md, task 28): opened by tapping a NewsTicker
    // headline. Built on Modal.svelte (the existing drill-down surface — attach-property,
    // settlement dates, lease upload all open into it), not SuburbSheet's bespoke
    // tab-bearing panel, since this is the "small popup with a few facts" idiom, not an
    // outer container. Bilingual summary + a generic diff dump + the primary source link —
    // no dismiss action here (task 31, separate slice); the ticker keeps cycling until
    // that's wired.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import type { NewsNote } from '$lib/api';

    let { note, onClose }: { note: NewsNote; onClose: () => void } = $props();

    // Same inline bilingual-pick idiom as NewsTicker.svelte/Onboarding.svelte/
    // SuburbSheet.svelte — task 30 stays open until a second real consumer reuses it;
    // this sheet is that consumer.
    const summary = $derived(
        ($lang === 'vi' ? note.summary_vi : note.summary_en) ?? note.summary_en ?? note.summary_vi ?? ''
    );

    // `diff` has no fixed schema (kb_compiler.py parse_news_doc just parses whatever
    // JSON follows "## Diff") — a generic dump is the honest rendering; a bespoke
    // old/new-value UI would assume a shape no gate actually enforces.
    const diffText = $derived(note.diff ? JSON.stringify(note.diff, null, 2) : '');
    const sourceUrl = $derived(note.sources?.[0]?.url ?? '');
</script>

<Modal title={$t('plan.news.detail_title')} {onClose}>
    <p class="pp-news-summary">{summary}</p>
    {#if diffText}
        <h4 class="pp-news-subhead">{$t('plan.news.diff_heading')}</h4>
        <pre class="pp-news-diff">{diffText}</pre>
    {/if}
    {#if sourceUrl}
        <a class="pp-news-source" href={sourceUrl} target="_blank" rel="noopener noreferrer"
            >{$t('plan.news.source')}</a
        >
    {/if}
</Modal>
