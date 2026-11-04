<script lang="ts">
    // Regulated figures are grounded -> P-6 · Shells reach the engine only through the contract -> The web frontend -> the property market page (/market)
    // Purpose:   behavior 151 (Son 2026-11-04): the home's fifth card, "Thị trường nhà ở Úc" /
    //            "Australia's property market", opens one page of why the market can be
    //            trusted — the property facts (kb.facts.australian-property, until now on
    //            /facts), the safeguards when you buy (kb.facts.property-safeguards, each a
    //            sentence its linked government page states), then the main listing sites.
    // Holds:     the fact docs drawn are MARKET_DOCS (facts.ts) and /facts draws every other,
    //            so a property fact shows on exactly one page; each figure and safeguard comes
    //            from GET /api/facts, drawn by FactCards with its source. The listing sites are
    //            constants here, not KB facts (they state no figure), each a plain https link to
    //            the site's home with rel="noopener noreferrer", labelled as a private company
    //            Mai An Cư has no tie to. A failed /api/facts (getFacts → []) leaves the
    //            listing sites and the page frame, never an error screen.
    // Rests on:  facts.ts (getFacts, MARKET_DOCS), FactCards.svelte, HomeBack.svelte, app.css .page-sheet.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { type FactDoc, getFacts, MARKET_DOCS, pick } from '$lib/facts';
    import FactCards from '$lib/FactCards.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import { onContentChange } from '$lib/stores/content';

    // Name and address only: no ranking or description, which no government source states.
    const LISTINGS: { name: string; href: string }[] = [
        { name: 'realestate.com.au', href: 'https://www.realestate.com.au/' },
        { name: 'Domain', href: 'https://www.domain.com.au/' },
        { name: 'Allhomes', href: 'https://www.allhomes.com.au/' }
    ];

    let docs = $state<FactDoc[] | null>(null);
    const shown = $derived(
        (docs ?? [])
            .filter((d) => MARKET_DOCS.includes(d.slug))
            .sort((a, b) => MARKET_DOCS.indexOf(a.slug) - MARKET_DOCS.indexOf(b.slug))
    );

    onMount(() => onContentChange(() => getFacts().then((d) => d.length && (docs = d))));
    onMount(async () => {
        // As on /facts: an empty answer (a cold engine) is retried before giving up.
        let got: FactDoc[] = [];
        for (let i = 0; i < 3 && !got.length; i++) {
            if (i) await new Promise((r) => setTimeout(r, 1500 * i));
            got = await getFacts();
        }
        docs = got;
    });
</script>

<div class="page-shell">
    <div class="sheet page-sheet" role="region" aria-label={$t('home.market.title')}>
        <header class="sheet-head">
            <HomeBack />
            <div class="title">
                <h2>{$t('home.market.title')}</h2>
                <p class="sub">{$t('marketpage.sub')}</p>
            </div>
        </header>
        <div class="body">
            {#if docs === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if !shown.length}
                <div class="pp-state"><p>{$t('factspage.empty')}</p></div>
            {:else}
                <p class="mk-note">{$t('marketpage.note')}</p>
                {#each shown as doc (doc.slug)}
                    <section class="mk-section" id={doc.slug} aria-labelledby="mk-{doc.slug}">
                        <h3 id="mk-{doc.slug}">{pick(doc.title, $lang)}</h3>
                        <FactCards {doc} />
                    </section>
                {/each}
            {/if}
            <section class="mk-section" id="mk-listings" aria-labelledby="mk-listings-title">
                <h3 id="mk-listings-title">{$t('marketpage.listings.title')}</h3>
                <ul class="mk-sites">
                    {#each LISTINGS as s (s.href)}
                        <li>
                            <a class="mk-site" href={s.href} target="_blank" rel="noopener noreferrer">
                                <strong>{s.name}</strong>
                                <span>{new URL(s.href).host}</span>
                            </a>
                        </li>
                    {/each}
                </ul>
                <p class="mk-notie">{$t('marketpage.listings.notie')}</p>
            </section>
        </div>
    </div>
</div>

<style>
    .mk-note,
    .mk-notie {
        margin: 0 0 var(--sp-3);
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .mk-notie {
        margin-top: var(--sp-3);
    }
    .mk-section {
        padding-bottom: var(--sp-5);
    }
    .mk-section h3 {
        margin: var(--sp-3) 0;
        font-size: var(--fs-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--ink);
        text-wrap: balance;
    }
    .mk-sites {
        display: grid;
        gap: var(--sp-2);
        margin: 0;
        padding: 0;
        list-style: none;
    }
    .mk-site {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        padding: var(--sp-3) var(--sp-4);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        background: var(--surface);
        color: var(--ink);
        text-decoration: none;
    }
    .mk-site span {
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    .mk-site:hover {
        border-color: var(--accent);
    }
    .mk-site:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }
</style>
