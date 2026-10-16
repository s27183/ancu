<script lang="ts">
    // News overview sheet (kb-news-feature.md "News overview sheet") — layer 1 of the
    // two-layer news flow: closing a note opened from the ticker lands here, over the page
    // the visitor is on. The list itself is NewsList.svelte, which the News page (/news,
    // behavior 88) draws too; the active tab is the caller's, so a reopened list keeps it.
    import { t } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import NewsList from '$lib/NewsList.svelte';
    import type { NewsNote } from '$lib/api';

    let { news, active, onSelectCategory, onSelectNote, onClose }: {
        news: NewsNote[];
        active: string;
        onSelectCategory: (id: string) => void;
        onSelectNote: (note: NewsNote) => void;
        onClose: () => void;
    } = $props();
</script>

<Modal title={$t('home.news.sheet_title')} {onClose}>
    <NewsList {news} {active} {onSelectCategory} {onSelectNote} />
</Modal>
