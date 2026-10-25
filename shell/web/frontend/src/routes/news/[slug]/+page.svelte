<script lang="ts">
    // Bilingual -> The web frontend -> one news note's address (/news/<slug>, behavior 137):
    // the News page with that note open. Crawlers read build/news/<slug>.html (scripts/seo_pages.ts).
    import { page } from '$app/state';
    import NewsPage from '$lib/NewsPage.svelte';
</script>

{#key page.params.slug}
    <NewsPage slug={page.params.slug} />
{/key}
