<script lang="ts">
    // Bilingual -> the way home is the same everywhere -> the web frontend -> one pill back to the home
    // Goal:      behaviors 81/88/115 — a guest always sees how to get back to the home's cards: on
    //            the planner, the News page and the map, first at the top-left (Son 2026-10-18: the
    //            house alone was hard to spot, so the word stays on every width).
    // Invariant: a link, so it is also a real address (the header's brand goes there too, but few
    //            read a logo as "home"); one look on every page — app.css .home-back owns it, no page
    //            restyles it.
    // Capability: house and word, 2.6rem high, bordered and shadowed, on every page and width
    //            (measured 2026-10-18 in Chrome: 111×42 on /explore, /news, /plan at 400 and 1280;
    //            before behavior 115, 32×32 house alone on /news and /plan at 400).
    import { t } from '$lib/i18n';
</script>

<a class="home-back" href="/" aria-label={$t('nav.home')}
    ><svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"
        ><path
            d="M4 11 12 4l8 7M6 9.5V20h12V9.5"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
        /></svg
    ><span class="home-back-text">{$t('nav.home')}</span></a
>
