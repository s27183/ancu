<script lang="ts">
    // Regulated figures are grounded -> P-6 · Shells reach the engine only through the contract -> The web frontend -> the buying demand page (/demand)
    // Purpose:   behavior 164 (Son 2026-11-06: «a separate card in the main page, on top of
    //            other page. we move those facts out of the "Australia in figures" card»): the
    //            home's first card, "Nhu cầu mua nhà ở Úc của người Việt", opens this page of
    //            the Vietnamese home-buying figures — Vietnam's place among approved foreign
    //            purchases (FIRB), approved Vietnamese purchases by year, and its place among
    //            foreign owners on the ATO register.
    // Holds:     the fact docs drawn are DEMAND_DOCS (facts.ts) and /facts draws none of them,
    //            so a buying fact shows on exactly one page; each figure comes from GET
    //            /api/facts, drawn by FactCards with its source and note. The title is the
    //            doc's own, its i18n twin while the facts load or if they fail (getFacts → []),
    //            which leaves the page frame, never an error screen.
    // Rests on:  facts.ts (getFacts, DEMAND_DOCS), FactCards.svelte, HomeBack.svelte, app.css .page-sheet.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { DEMAND_DOCS, type FactDoc, getFacts, pick } from '$lib/facts';
    import FactCards from '$lib/FactCards.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import { onContentChange } from '$lib/stores/content';

    let docs = $state<FactDoc[] | null>(null);
    const shown = $derived(
        (docs ?? [])
            .filter((d) => DEMAND_DOCS.includes(d.slug))
            .sort((a, b) => DEMAND_DOCS.indexOf(a.slug) - DEMAND_DOCS.indexOf(b.slug))
    );
    const title = $derived(shown[0] ? pick(shown[0].title, $lang) : $t('home.demand.title'));

    onMount(() => onContentChange(() => getFacts().then((d) => d.length && (docs = d))));
    onMount(async () => {
        // As on /facts and /market: an empty answer (a cold engine) is retried before giving up.
        let got: FactDoc[] = [];
        for (let i = 0; i < 3 && !got.length; i++) {
            if (i) await new Promise((r) => setTimeout(r, 1500 * i));
            got = await getFacts();
        }
        docs = got;
    });
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={title}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title">
                <h2>{title}</h2>
                <p class="sub">{$t('marketpage.sub')}</p>
            </div>
        </header>
        <div class="body">
            {#if docs === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if !shown.length}
                <div class="pp-state"><p>{$t('factspage.empty')}</p></div>
            {:else}
                {#each shown as doc (doc.slug)}
                    <section class="dm-section" id={doc.slug} aria-label={pick(doc.title, $lang)}>
                        <FactCards {doc} />
                    </section>
                {/each}
            {/if}
        </div>
    </div>
</div>

<style>
    .dm-section {
        padding: var(--sp-3) 0 var(--sp-5);
    }
</style>
