<script lang="ts">
    // Bilingual -> The web frontend -> the facts page (/facts)
    // Purpose:   behavior 121/122 (Son 2026-10-18): the home's fourth card, "Úc qua số liệu" /
    //            "Australia in figures", opens one page of the facts about Australia a buyer
    //            cares about — the Introduction's three sections first, in its order, then the
    //            KB's other fact docs (the economy, visa charges: PAGE_ORDER, facts.ts).
    //            Behavior 123: the RBA's latest AUD rate (GET /api/fx) leads them, or is absent.
    // Holds:     every figure comes from GET /api/facts and is drawn by FactCards, the same
    //            cards the Introduction sheet draws, so the two show the same figures and
    //            sources; the page frame and the way home are the News page's.
    // Rests on:  facts.ts (getFacts, pageRank), FactCards.svelte, HomeBack.svelte, app.css .page-sheet.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { type FactDoc, getFacts, pageRank, pick } from '$lib/facts';
    import FactCards from '$lib/FactCards.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import NewsDetailSheet from '$lib/NewsDetailSheet.svelte';
    import { getAllNews, type NewsNote } from '$lib/api';
    import FxRate from '$lib/FxRate.svelte';
    import { type FxRate as Fx, getFx } from '$lib/fx';

    let docs = $state<FactDoc[] | null>(null);
    // Behavior 123: the RBA's latest rate leads the page; none stored, no section.
    let fx = $state<Fx | null>(null);
    // Behavior 125: a section's `news` notes, linked under it; a tap opens the note over the
    // page as on /news. A slug the news list lacks draws no link.
    let news = $state<NewsNote[]>([]);
    let selected = $state<NewsNote | null>(null);
    const notesFor = (doc: FactDoc) =>
        (doc.news ?? []).map((s) => news.find((n) => n.news_slug === s)).filter((n): n is NewsNote => !!n);
    const ordered = $derived(docs ? [...docs].sort((a, b) => pageRank(a.slug) - pageRank(b.slug)) : []);

    onMount(async () => {
        getFx().then((r) => (fx = r));
        getAllNews().then((n) => (news = n));
        // As in the sheet: an empty answer (a cold engine) is retried before giving up.
        let got: FactDoc[] = [];
        for (let i = 0; i < 3 && !got.length; i++) {
            if (i) await new Promise((r) => setTimeout(r, 1500 * i));
            got = await getFacts();
        }
        docs = got;
    });
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('home.facts.title')}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title">
                <h2>{$t('home.facts.title')}</h2>
                <p class="sub">{$t('factspage.sub')}</p>
            </div>
        </header>
        <div class="body">
            {#if docs === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if !docs.length}
                <div class="pp-state"><p>{$t('factspage.empty')}</p></div>
            {:else}
                <p class="fp-note">{$t('intro.sources.note')}</p>
                {#if fx}<FxRate rate={fx} />{/if}
                {#each ordered as doc (doc.slug)}
                    <section class="fp-section" id={doc.slug} aria-labelledby="fp-{doc.slug}">
                        <h3 id="fp-{doc.slug}">{pick(doc.title, $lang)}</h3>
                        <FactCards {doc} />
                        {#each notesFor(doc) as note (note.news_slug)}
                            <button type="button" class="fp-news" onclick={() => (selected = note)}>
                                <span class="fp-news-tag">{$t('factspage.news')}</span>
                                <span>{($lang === 'vi' ? note.headline_vi : note.headline_en) ?? note.headline_en}</span>
                            </button>
                        {/each}
                    </section>
                {/each}
            {/if}
        </div>
    </div>
</div>

{#if selected}
    <NewsDetailSheet note={selected} onClose={() => (selected = null)} />
{/if}

<style>
    .fp-note {
        margin: 0 0 var(--sp-3);
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .fp-section {
        padding-bottom: var(--sp-5);
    }
    .fp-section h3 {
        margin: var(--sp-3) 0;
        font-size: var(--fs-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--ink);
        text-wrap: balance;
    }
    .fp-news {
        display: flex;
        align-items: baseline;
        gap: var(--sp-2);
        width: 100%;
        margin-top: var(--sp-3);
        padding: var(--sp-3) var(--sp-4);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        background: var(--surface-2, var(--surface));
        color: var(--ink);
        font: inherit;
        font-size: var(--fs-sm);
        text-align: left;
        cursor: pointer;
    }
    .fp-news:hover {
        border-color: var(--accent);
    }
    .fp-news:focus-visible {
        outline: none;
        box-shadow: var(--ring);
    }
    .fp-news-tag {
        flex: none;
        color: var(--accent);
        font-weight: 700;
        font-size: var(--fs-xs);
        text-transform: uppercase;
        letter-spacing: 0.04em;
    }
</style>
