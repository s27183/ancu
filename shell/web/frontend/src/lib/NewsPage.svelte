<script lang="ts">
    // Bilingual -> The web frontend -> the News page (/news and /news/<slug>)
    // Behavior 88 (Son 2026-10-16): the home's third card. Every current news note under
    // the list's category tabs (NewsList.svelte, the same list the list sheet draws), in
    // the planner's page frame (.page-sheet) with the same home button. A headline opens
    // its note over the page; closing it shows the list again, on the tab that was open.
    // Behavior 137: each note has its own address, /news/<slug> (slug = news_slug without
    // `kb.news.`, scripts/seo.ts noteSlug), which crawlers read as a page of its own; here
    // `slug` opens that note over the list once the news loads, and closing it goes to
    // /news. An unknown slug shows the list.
    import { onMount } from 'svelte';
    import { getAllNews, type NewsNote } from '$lib/api';
    import { onContentChange } from '$lib/stores/content';
    import NewsList from '$lib/NewsList.svelte';
    import NewsDetailSheet from '$lib/NewsDetailSheet.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import { t } from '$lib/i18n';
    import { goto } from '$app/navigation';

    let { slug }: { slug?: string } = $props();

    let news = $state<NewsNote[] | null>(null);
    let active = $state('all');
    let selected = $state<NewsNote | null>(null);

    onMount(() => {
        getAllNews().then((n) => {
            news = n;
            if (slug) selected = n.find((x) => x.news_slug === `kb.news.${slug}`) ?? null;
        });
        // Behavior 135: a replaced KB re-reads in place; an empty answer keeps the list.
        return onContentChange(() => getAllNews().then((n) => n.length && (news = n)));
    });
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('home.news.sheet_title')}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title">
                <h2>{$t('home.news.sheet_title')}</h2>
                <p class="sub">{$t('newspage.sub')}</p>
            </div>
        </header>
        <div class="body">
            {#if news === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if news.length === 0}
                <div class="pp-state"><p>{$t('newspage.empty')}</p></div>
            {:else}
                <NewsList {news} {active} onSelectCategory={(id) => (active = id)} onSelectNote={(n) => (selected = n)} />
            {/if}
        </div>
    </div>
</div>

{#if selected}
    <NewsDetailSheet note={selected} onClose={() => (slug ? goto('/news') : (selected = null))} />
{/if}
