<script lang="ts">
    // Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend ->
    // the iPhone's add-to-home-screen hint (behavior 152; the rule and its block:
    // installHint.ts). Drawn after the home's cards, in the page's own scroll, so it covers
    // no card and no control; the Share glyph is iOS's own square-and-arrow.
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import { browserHintEnv, closeInstallHint, shouldShowInstallHint } from '$lib/installHint';

    let show = $state(false);

    onMount(() => {
        show = shouldShowInstallHint(browserHintEnv());
    });

    function close() {
        closeInstallHint(browserHintEnv().storage);
        show = false;
    }
</script>

{#if show}
    <aside class="install-hint" aria-label={$t('installhint.label')}>
        <span class="install-hint-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                ><path d="M8 9H6a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V10a1 1 0 0 0-1-1h-2" /><line x1="12" y1="3" x2="12" y2="15" /><polyline points="8.5 6.5 12 3 15.5 6.5" /></svg
            >
        </span>
        <span class="install-hint-text">{$t('installhint.text')}</span>
        <button type="button" class="install-hint-close" aria-label={$t('installhint.close')} onclick={close}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"
                ><line x1="6" y1="6" x2="18" y2="18" /><line x1="18" y1="6" x2="6" y2="18" /></svg
            >
        </button>
    </aside>
{/if}
