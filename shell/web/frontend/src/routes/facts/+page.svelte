<script lang="ts">
    // Bilingual -> P-6 · Shells reach the engine only through the contract -> The web frontend -> the facts page (/facts)
    // Purpose:   behavior 121/122 (Son 2026-10-18): the home's fourth card, "Úc qua số liệu" /
    //            "Australia in figures", opens one page of the facts about Australia a buyer
    //            cares about — the Introduction's three sections first, in its order, then the
    //            KB's other fact docs (the economy, visa charges: PAGE_ORDER, facts.ts).
    //            Behavior 123: the RBA's latest AUD rate (GET /api/fx) leads them, or is absent.
    //            Behavior 126 (Son 2026-10-18): the sections run in the order a buyer asks
    //            (PAGE_ORDER), and a row of chips between the head and the scrolling body —
    //            so it never scrolls away — names each section, jumps to it and marks the
    //            one being read (the last whose top has passed the body's top). Above the
    //            sections, key figures (KEY_FIGURES, facts.ts: picked by fact id, so each
    //            equals its card) each name their section and jump to it; one whose fact the
    //            KB lacks is not drawn.
    // Holds:     every figure comes from GET /api/facts and is drawn by FactCards, the same
    //            cards the Introduction sheet draws, so the two show the same figures and
    //            sources; the page frame and the way home are the News page's.
    // Rests on:  facts.ts (getFacts, pageRank), FactCards.svelte, HomeBack.svelte, app.css .page-sheet.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t, type MessageKey } from '$lib/i18n';
    import { CHIP_KEY, type FactDoc, getFacts, KEY_FIGURES, keyFigure, pageRank, pick } from '$lib/facts';
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

    // Behavior 126: one chip per drawn section, in page order; ids are the sections' ids.
    const chips = $derived([
        ...(fx ? [{ id: 'fp-fx', label: $t('facts.chip.fx') }] : []),
        ...ordered.map((d) => ({
            id: d.slug,
            label: CHIP_KEY[d.slug] ? $t(`facts.chip.${CHIP_KEY[d.slug]}` as MessageKey) : pick(d.title, $lang)
        }))
    ]);
    const chipName = (id: string) => chips.find((c) => c.id === id)?.label ?? '';
    const loc = $derived($lang === 'vi' ? 'vi-VN' : 'en-AU');
    const keys = $derived([
        ...(fx
            ? [{ key: 'fx', id: 'fp-fx', value: `${new Intl.NumberFormat(loc).format(fx.rates.VND)} VND` }]
            : []),
        ...(docs ?? []).length
            ? KEY_FIGURES.flatMap((k) => {
                  const f = keyFigure(docs ?? [], k, $lang);
                  if (!f) return [];
                  const value = f.rank ? $t('facts.key.rankvalue').replace('{n}', String(f.rank)) : f.value;
                  return [{ key: k.key, id: k.slug, value }];
              })
            : []
    ]);
    let body = $state<HTMLDivElement | null>(null);
    let chipRow = $state<HTMLElement | null>(null);
    let current = $state('');

    function mark() {
        if (!body) return;
        const top = body.getBoundingClientRect().top + 32;
        let at = chips[0]?.id ?? '';
        for (const c of chips) {
            const el = document.getElementById(c.id);
            if (el && el.getBoundingClientRect().top <= top) at = c.id;
        }
        // scrolled to the end: the last section is the one being read
        if (body.scrollTop + body.clientHeight >= body.scrollHeight - 2 && chips.length) at = chips[chips.length - 1].id;
        current = at;
    }
    function go(id: string) {
        document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    $effect(() => {
        chips;
        mark();
    });
    // keep the marked chip in view in the row
    $effect(() => {
        const el = chipRow?.querySelector<HTMLElement>(`[data-id="${current}"]`);
        if (el && chipRow) {
            const r = el.offsetLeft - chipRow.clientWidth / 2 + el.clientWidth / 2;
            chipRow.scrollTo({ left: Math.max(0, r), behavior: 'smooth' });
        }
    });

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
        {#if chips.length > 1}
            <nav class="fp-chips" aria-label={$t('facts.chips')} bind:this={chipRow}>
                {#each chips as c (c.id)}
                    <button
                        type="button"
                        class="fp-chip"
                        class:on={current === c.id}
                        aria-current={current === c.id ? 'true' : undefined}
                        data-id={c.id}
                        onclick={() => go(c.id)}>{c.label}</button
                    >
                {/each}
            </nav>
        {/if}
        <div class="body" bind:this={body} onscroll={mark}>
            {#if docs === null}
                <div class="pp-state"><p>{$t('plan.loading')}</p></div>
            {:else if !docs.length}
                <div class="pp-state"><p>{$t('factspage.empty')}</p></div>
            {:else}
                {#if keys.length}
                    <section class="fp-keys" aria-labelledby="fp-keys-title">
                        <h3 id="fp-keys-title" class="fp-keys-title">{$t('facts.key.title')}</h3>
                        <div class="fp-key-grid">
                            {#each keys as k (k.key)}
                                <button type="button" class="fp-key" onclick={() => go(k.id)}>
                                    <span class="fp-key-sec">{chipName(k.id)}</span>
                                    <strong class="fp-key-val">{k.value}</strong>
                                    <span class="fp-key-lbl">{$t(`facts.key.${k.key}` as MessageKey)}</span>
                                </button>
                            {/each}
                        </div>
                    </section>
                {/if}
                <p class="fp-note">{$t('factspage.note')}</p>
                {#if fx}<div id="fp-fx" class="fp-anchor"><FxRate rate={fx} /></div>{/if}
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
    .fp-section,
    .fp-anchor {
        scroll-margin-top: var(--sp-2);
    }
    .fp-keys {
        padding-bottom: var(--sp-4);
    }
    .fp-keys-title {
        margin: var(--sp-1) 0 var(--sp-3);
        font-size: var(--fs-xs);
        font-weight: 700;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: var(--muted);
    }
    .fp-key-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: var(--sp-2);
    }
    @media (min-width: 48rem) {
        .fp-key-grid {
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }
    }
    .fp-key {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.2rem;
        min-width: 0;
        padding: var(--sp-3);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        background: var(--surface);
        font: inherit;
        text-align: left;
        cursor: pointer;
    }
    .fp-key:hover {
        border-color: var(--accent);
    }
    .fp-key:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }
    .fp-key-sec {
        font-size: var(--fs-2xs);
        font-weight: 700;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        color: var(--accent);
    }
    .fp-key-val {
        font-size: var(--fs-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--ink);
        font-variant-numeric: tabular-nums;
        overflow-wrap: anywhere;
    }
    .fp-key-lbl {
        font-size: var(--fs-xs);
        color: var(--ink-2);
        line-height: 1.3;
    }
    .fp-chips {
        flex: none;
        display: flex;
        gap: var(--sp-2);
        padding: 0 var(--sp-5) var(--sp-3);
        overflow-x: auto;
        scrollbar-width: none;
        border-bottom: 1px solid var(--border);
    }
    .fp-chips::-webkit-scrollbar {
        display: none;
    }
    .fp-chip {
        flex: none;
        padding: 0.35rem 0.8rem;
        border: 1px solid var(--border);
        border-radius: 999px;
        background: var(--surface);
        color: var(--ink-2);
        font: inherit;
        font-size: var(--fs-sm);
        font-weight: 600;
        white-space: nowrap;
        cursor: pointer;
    }
    .fp-chip.on {
        background: var(--accent);
        border-color: var(--accent);
        color: var(--accent-ink);
    }
    .fp-chip:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
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
