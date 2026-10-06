<script lang="ts">
    // News overview sheet (kb-news-feature.md "News overview sheet") — layer 1 of the
    // homepage's two-layer news flow (a friend's suggestion, relayed 2026-07-09): tapping
    // ANY headline on the homepage ticker opens this instead of jumping straight to a
    // detail sheet. Every current note (already fetched as `homeNews` in +page.svelte, no
    // new API call), grouped into category sections, scrollable (Modal's .mo-body already
    // is). Tapping a headline here opens NewsDetailSheet (layer 2, unchanged) via onSelectNote.
    //
    // Scope: homepage only. The per-card ticker in PlanProjection (discrete variant) keeps
    // its existing direct-tap-to-detail + dismiss behavior — a small, already-filtered list
    // where "browse everything by category" doesn't add value and dismiss doesn't belong in
    // a general overview.
    import { lang } from '$lib/stores/lang';
    import { t, type MessageKey } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import Tabs from '$lib/Tabs.svelte';
    import type { NewsNote, NewsCategory } from '$lib/api';
    import { date as formatDate } from '$lib/format';

    let { news, active, onSelectCategory, onSelectNote, onClose }: {
        news: NewsNote[];
        /** Controlled, like Tabs.svelte itself — owned by the caller (+page.svelte), not
         *  local state here, because this sheet is conditionally mounted and a local
         *  $state would reset to 'all' every time it remounts (e.g. closing a note's
         *  detail sheet reopens this fresh). */
        active: string;
        onSelectCategory: (id: string) => void;
        onSelectNote: (note: NewsNote) => void;
        onClose: () => void;
    } = $props();

    // Same bilingual-pick idiom as NewsTicker.svelte/NewsDetailSheet.svelte.
    function headlineFor(note: NewsNote): string {
        const primary = $lang === 'vi' ? note.headline_vi : note.headline_en;
        const fallback = $lang === 'vi' ? note.headline_en : note.headline_vi;
        return primary ?? fallback ?? note.summary_en ?? note.summary_vi ?? '';
    }
    // A row was a bare headline with no sense of recency — every item in a category read
    // as equally new. authored_date is the "how fresh" figure (mirrors NewsDetailSheet.svelte).
    function dateFor(note: NewsNote): string | null {
        return formatDate(note.authored_date ?? note.effective_from, $lang);
    }

    // Fixed display order (not alphabetical/insertion) — visa/finance first since FIRB +
    // borrowing capacity are the highest-stakes categories for this audience.
    const CATEGORY_ORDER: NewsCategory[] = ['visa', 'finance', 'scheme', 'tax', 'property', 'market'];
    const CATEGORY_LABEL_KEY: Record<NewsCategory, MessageKey> = {
        visa: 'home.news.category.visa',
        finance: 'home.news.category.finance',
        scheme: 'home.news.category.scheme',
        tax: 'home.news.category.tax',
        property: 'home.news.category.property',
        market: 'home.news.category.market'
    };

    // Newest first within a category — the API gives no ordering guarantee, and now that
    // each row shows its own date (below), an unordered list would read as internally
    // inconsistent (a "3 days ago" row above a "today" row in the same section).
    function sortKey(note: NewsNote): string {
        return note.authored_date ?? note.effective_from ?? '';
    }

    const sections = $derived.by((): { category: NewsCategory; notes: NewsNote[] }[] => {
        const byCategory = new Map<NewsCategory, NewsNote[]>();
        for (const note of news) {
            // Defensive fallback for a note authored before `category` existed (GATE 11
            // requires it going forward — see kb_compiler.py NEWS_CATEGORIES).
            const cat = note.category ?? 'market';
            const list = byCategory.get(cat) ?? [];
            list.push(note);
            byCategory.set(cat, list);
        }
        return CATEGORY_ORDER.filter((cat) => byCategory.has(cat)).map((cat) => ({
            category: cat,
            notes: (byCategory.get(cat) ?? []).slice().sort((a, b) => sortKey(b).localeCompare(sortKey(a)))
        }));
    });

    // 'all' is the default landing tab, not the first category — with content hidden
    // behind whichever category tab is active, a category-first default risks a
    // buyer never noticing a note in a category they didn't tap (2026-08 tabs redesign,
    // replacing the always-visible stacked-sections layout). 'all' keeps the same
    // "everything visible on open" property that layout had; per-category tabs are an
    // opt-in narrowing, same role chips would have played, on the affordance actually
    // chosen. (The default itself lives in +page.svelte's `homeNewsActiveCategory`
    // — this component just renders whatever `active` it's given.)
    const allSorted = $derived(news.slice().sort((a, b) => sortKey(b).localeCompare(sortKey(a))));

    // Counts ride in the label itself (`Category · N`) rather than a separate badge —
    // Tabs.svelte's label is a plain string, and the count is exactly what helped a
    // buyer choose a tab in the old section-heading layout (kb-news-feature.md
    // "News overview sheet"); worth keeping visible at the point of choice.
    const tabs = $derived([
        { id: 'all', label: `${$t('home.news.category.all')} · ${news.length}` },
        ...sections.map((s) => ({
            id: s.category,
            label: `${$t(CATEGORY_LABEL_KEY[s.category])} · ${s.notes.length}`
        }))
    ]);

    const visibleNotes = $derived(
        active === 'all' ? allSorted : (sections.find((s) => s.category === active)?.notes ?? [])
    );
</script>

<Modal title={$t('home.news.sheet_title')} {onClose}>
    <div class="pp-news-list">
        <Tabs {tabs} {active} onSelect={onSelectCategory} />
        <ul class="pp-news-list-items">
            {#each visibleNotes as note (note.news_slug)}
                <li>
                    <button type="button" class="pp-news-list-item" onclick={() => onSelectNote(note)}>
                        <span class="pp-news-list-item-headline">{headlineFor(note)}</span>
                        {#if dateFor(note)}
                            <span class="pp-news-list-item-date">{dateFor(note)}</span>
                        {/if}
                    </button>
                </li>
            {/each}
        </ul>
    </div>
</Modal>
