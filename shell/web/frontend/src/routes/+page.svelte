<script lang="ts">
    // Bilingual -> the first-screen sentence -> The web frontend -> the home (/)
    // Behavior 81 (Son 2026-10-16): the home leads to two pages — plan a budget by state
    // (/plan) or explore suburbs on the map (/explore) — under the news band (the
    // layout's). Behavior 88: and a third, the News page (/news). Behavior 122: and a
    // fourth, "Nước Úc qua số liệu" (/facts; so titled by behavior 128), the cited facts about Australia on one page. Behavior 151: and a fifth, "Thị trường nhà ở Úc" (/market), the property market and its safeguards. The map no longer opens first. A first visit still opens "Giới thiệu"
    // (Welcome) over the cards, whose first screen leads to the independent /
    // information-not-advice position in one tap; minimised, it leaves the cards in view.
    // Behavior 89: a dotted map of Australia lights up behind the cards (HomeBackdrop).
    // Behavior 153: the cards run market, explore, plan, facts, news (Son 2026-11-04:
    // how prices are disclosed is what Vietnamese buyers ask first).
    // Behavior 153: one row heads the home, above every card (.home-pills): Welcome's
    // "Giới thiệu" launcher on the left, the Add to Home Screen pill (InstallHint) on the
    // right. In the flow, neither can cover a card (behavior 128's placement retired), and
    // the install pill replaces behavior 152's strip under the cards.
    import Welcome from '$lib/Welcome.svelte';
    import HomeBackdrop from '$lib/HomeBackdrop.svelte';
    import InstallHint from '$lib/InstallHint.svelte';
    import { t } from '$lib/i18n';
</script>

<HomeBackdrop />
<div class="home">
    <div class="home-pills">
        <!-- First visit: the case for Australian property, then the launcher that reopens it (behavior 42). -->
        <Welcome />
        <InstallHint />
    </div>
    <nav class="home-ways" aria-label={$t('brand.name')}>
        <a class="home-way" href="/market">
            <span class="home-way-icon" aria-hidden="true">
                <!-- a house under a check: the market's safeguards -->
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                    ><path d="M3 11 12 4l9 7" /><path d="M5 10v10h14V10" /><polyline points="9 14.5 11.2 16.7 15.5 12.4" /></svg
                >
            </span>
            <span class="home-way-text">
                <span class="home-way-title">{$t('home.market.title')}</span>
                <span class="home-way-body">{$t('home.market.body')}</span>
            </span>
            <svg class="home-way-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                ><polyline points="9 6 15 12 9 18" /></svg
            >
        </a>
        <a class="home-way" href="/explore">
            <span class="home-way-icon" aria-hidden="true">
                <!-- a pin on a folded map -->
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                    ><path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Z" /><line x1="9" y1="4" x2="9" y2="18" /><line x1="15" y1="6" x2="15" y2="20" /></svg
                >
            </span>
            <span class="home-way-text">
                <span class="home-way-title">{$t('home.explore.title')}</span>
                <span class="home-way-body">{$t('home.explore.body')}</span>
            </span>
            <svg class="home-way-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                ><polyline points="9 6 15 12 9 18" /></svg
            >
        </a>
        <a class="home-way" href="/plan">
            <span class="home-way-icon" aria-hidden="true">
                <!-- a ledger: the budget, line by line -->
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                    ><rect x="4" y="3" width="16" height="18" rx="2" /><line x1="8" y1="8" x2="16" y2="8" /><line x1="8" y1="12" x2="16" y2="12" /><line x1="8" y1="16" x2="12" y2="16" /></svg
                >
            </span>
            <span class="home-way-text">
                <span class="home-way-title">{$t('home.plan.title')}</span>
                <span class="home-way-body">{$t('home.plan.body')}</span>
            </span>
            <svg class="home-way-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                ><polyline points="9 6 15 12 9 18" /></svg
            >
        </a>
        <a class="home-way" href="/facts">
            <span class="home-way-icon" aria-hidden="true">
                <!-- a bar chart: the figures -->
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                    ><line x1="4" y1="20" x2="20" y2="20" /><rect x="5.5" y="12" width="3" height="8" /><rect x="10.5" y="7" width="3" height="13" /><rect x="15.5" y="4" width="3" height="16" /></svg
                >
            </span>
            <span class="home-way-text">
                <span class="home-way-title">{$t('home.facts.title')}</span>
                <span class="home-way-body">{$t('home.facts.body')}</span>
            </span>
            <svg class="home-way-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                ><polyline points="9 6 15 12 9 18" /></svg
            >
        </a>
        <a class="home-way" href="/news">
            <span class="home-way-icon" aria-hidden="true">
                <!-- a folded newspaper -->
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                    ><path d="M4 5h13v14H6a2 2 0 0 1-2-2V5Z" /><path d="M17 9h3v8a2 2 0 0 1-2 2h-1" /><line x1="7.5" y1="9" x2="13.5" y2="9" /><line x1="7.5" y1="12.5" x2="13.5" y2="12.5" /><line x1="7.5" y1="16" x2="11" y2="16" /></svg
                >
            </span>
            <span class="home-way-text">
                <span class="home-way-title">{$t('home.news.title')}</span>
                <span class="home-way-body">{$t('home.news.body')}</span>
            </span>
            <svg class="home-way-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                ><polyline points="9 6 15 12 9 18" /></svg
            >
        </a>
    </nav>
</div>
