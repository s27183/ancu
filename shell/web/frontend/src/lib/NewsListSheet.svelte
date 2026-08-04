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
    import type { NewsNote, NewsCategory } from '$lib/api';
    import { date as formatDate } from '$lib/format';

    let { news, onSelectNote, onClose }: {
        news: NewsNote[];
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
</script>

<Modal title={$t('home.news.sheet_title')} {onClose}>
    <div class="pp-news-list">
        {#each sections as section (section.category)}
            <section class="pp-news-list-section">
                <h4 class="pp-news-list-heading">
                    {$t(CATEGORY_LABEL_KEY[section.category])}
                    <span class="pp-news-list-count">{section.notes.length}</span>
                </h4>
                <ul class="pp-news-list-items">
                    {#each section.notes as note (note.news_slug)}
                        <li>
                            <button
                                type="button"
                                class="pp-news-list-item"
                                onclick={() => onSelectNote(note)}
                            >
                                <span class="pp-news-list-item-headline">{headlineFor(note)}</span>
                                {#if dateFor(note)}
                                    <span class="pp-news-list-item-date">{dateFor(note)}</span>
                                {/if}
                            </button>
                        </li>
                    {/each}
                </ul>
            </section>
        {/each}
    </div>
</Modal>
