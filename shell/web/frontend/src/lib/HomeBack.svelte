<script lang="ts">
    // Bilingual -> The web frontend -> the way back home
    // Behavior 81: the planner and the map page each carry one plain control back to the
    // home's two cards — a link, so it is also a real address (the header's brand goes
    // there too, but few read a logo as "home"). A house and the word; on the planner's
    // head on a phone the house alone (app.css).
    import { t } from '$lib/i18n';

    let { floating = false }: { floating?: boolean } = $props();
</script>

<a class="home-back" class:floating href="/" aria-label={$t('nav.home')}
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
