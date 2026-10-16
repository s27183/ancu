<script lang="ts">
    // Bilingual -> The web frontend -> the news band on every page
    // Behavior 81 (Son 2026-10-16): the home, the planner and the map each carry the same
    // news strip under the header, and its sheets work from all three as they did on the
    // map-first home. This is that strip, lifted out of the old single page: every compiled
    // news note, unfiltered (kb-news-feature.md "Homepage ticker"). Tapping the ticker opens
    // that note; closing a note lands on the categorized list (Son 2026-08-06); the list's
    // active tab is held here so a reopened list keeps it. `height` is the band's measured
    // height, which a page feeds into --home-news-h (never a guessed offset).
    import { onMount } from 'svelte';
    import { afterNavigate } from '$app/navigation';
    import { page } from '$app/state';
    import { getAllNews, type NewsNote } from '$lib/api';
    import NewsTicker from '$lib/NewsTicker.svelte';
    import NewsListSheet from '$lib/NewsListSheet.svelte';
    import NewsDetailSheet from '$lib/NewsDetailSheet.svelte';
    import { t } from '$lib/i18n';

    let { height = $bindable(0) }: { height?: number } = $props();

    let news = $state<NewsNote[]>([]);
    let listOpen = $state(false);
    let selected = $state<NewsNote | null>(null);
    let activeCategory = $state('all');

    onMount(() => {
        getAllNews().then((n) => (news = n));
    });
    // The band outlives a page change (it is the layout's); its sheets do not.
    afterNavigate(() => {
        listOpen = false;
        selected = null;
    });
</script>

{#if news.length > 0}
    <div class="home-news-band" bind:clientHeight={height}>
        <NewsTicker
            {news}
            onSelect={(note) => (selected = note)}
            variant="marquee"
            ariaLabel={$t('home.news.aria')}
        />
    </div>
{/if}

{#if listOpen}
    <NewsListSheet
        {news}
        active={activeCategory}
        onSelectCategory={(id) => (activeCategory = id)}
        onSelectNote={(note) => {
            listOpen = false;
            selected = note;
        }}
        onClose={() => (listOpen = false)}
    />
{/if}

{#if selected}
    <NewsDetailSheet
        note={selected}
        onClose={() => {
            selected = null;
            // On the News page the list is the page itself (behavior 88).
            listOpen = page.url.pathname !== '/news';
        }}
    />
{/if}
