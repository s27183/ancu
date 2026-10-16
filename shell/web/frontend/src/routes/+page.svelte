<script lang="ts">
    // Bilingual -> the first-screen sentence -> The web frontend -> the home (/)
    // Behavior 81 (Son 2026-10-16): the home leads to two pages — plan a budget by state
    // (/plan) or explore suburbs on the map (/explore) — under the news band (the
    // layout's). The map no longer opens first. A first visit still opens "Vì sao Úc?"
    // (Welcome) over the cards, whose first screen leads to the independent /
    // information-not-advice position in one tap; minimised, it leaves the cards in view.
    import Welcome from '$lib/Welcome.svelte';
    import { t } from '$lib/i18n';
</script>

<div class="home">
    <nav class="home-ways" aria-label={$t('brand.name')}>
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
    </nav>
</div>

<!-- First visit: the case for Australian property, then a launcher to reopen it (behavior 42). -->
<Welcome />
