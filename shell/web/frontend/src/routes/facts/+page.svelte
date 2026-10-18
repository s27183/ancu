<script lang="ts">
    // Bilingual -> The web frontend -> the facts page (/facts)
    // Purpose:   behavior 121/122 (Son 2026-10-18): the home's fourth card, "Úc qua số liệu" /
    //            "Australia in figures", opens one page of the facts about Australia a buyer
    //            cares about — the Introduction's three sections first, in its order, then the
    //            KB's other fact docs (the economy, visa charges: PAGE_ORDER, facts.ts).
    //            Behavior 123: the RBA's latest AUD rate (GET /api/fx) leads them, or is absent.
    //            Behavior 126 (Son 2026-10-18): the sections run in the order a buyer asks
    //            (PAGE_ORDER), and a row of chips between the head and the scrolling body —
    //            so it never scrolls away — names each section, jumps to it and marks the
    //            one being read (the last whose top has passed the body's top).
    // Holds:     every figure comes from GET /api/facts and is drawn by FactCards, the same
    //            cards the Introduction sheet draws, so the two show the same figures and
    //            sources; the page frame and the way home are the News page's.
    // Rests on:  facts.ts (getFacts, pageRank), FactCards.svelte, HomeBack.svelte, app.css .page-sheet.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t, type MessageKey } from '$lib/i18n';
    import { CHIP_KEY, type FactDoc, getFacts, pageRank, pick } from '$lib/facts';
    import FactCards from '$lib/FactCards.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import FxRate from '$lib/FxRate.svelte';
    import { type FxRate as Fx, getFx } from '$lib/fx';

    let docs = $state<FactDoc[] | null>(null);
    // Behavior 123: the RBA's latest rate leads the page; none stored, no section.
    let fx = $state<Fx | null>(null);
    const ordered = $derived(docs ? [...docs].sort((a, b) => pageRank(a.slug) - pageRank(b.slug)) : []);

    // Behavior 126: one chip per drawn section, in page order; ids are the sections' ids.
    const chips = $derived([
        ...(fx ? [{ id: 'fp-fx', label: $t('facts.chip.fx') }] : []),
        ...ordered.map((d) => ({
            id: d.slug,
            label: CHIP_KEY[d.slug] ? $t(`facts.chip.${CHIP_KEY[d.slug]}` as MessageKey) : pick(d.title, $lang)
        }))
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
                <p class="fp-note">{$t('intro.sources.note')}</p>
                {#if fx}<div id="fp-fx" class="fp-anchor"><FxRate rate={fx} /></div>{/if}
                {#each ordered as doc (doc.slug)}
                    <section class="fp-section" id={doc.slug} aria-labelledby="fp-{doc.slug}">
                        <h3 id="fp-{doc.slug}">{pick(doc.title, $lang)}</h3>
                        <FactCards {doc} />
                    </section>
                {/each}
            {/if}
        </div>
    </div>
</div>

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
</style>
