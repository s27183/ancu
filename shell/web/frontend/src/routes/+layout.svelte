<script lang="ts">
    import '../app.css';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';

    let { children }: { children: import('svelte').Snippet } = $props();
</script>

<header>
    <a class="brand" href="/">{$t('brand.name')}</a>
    <nav>
        <a href="/">{$t('nav.home')}</a>
        <a href="/status">{$t('nav.status')}</a>
        <div class="lang" role="group" aria-label={$t('lang.label')}>
            <button
                type="button"
                class:active={$lang === 'vi'}
                aria-pressed={$lang === 'vi'}
                onclick={() => lang.set('vi')}>VI</button
            >
            <button
                type="button"
                class:active={$lang === 'en'}
                aria-pressed={$lang === 'en'}
                onclick={() => lang.set('en')}>EN</button
            >
        </div>
    </nav>
</header>

<main>
    {@render children()}
</main>
