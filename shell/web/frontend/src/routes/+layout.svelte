<script lang="ts">
    import '../app.css';
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { session, sessionLoaded, refreshSession, signOut } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';

    let { children }: { children: import('svelte').Snippet } = $props();

    // The account chip lives in the global header now, so learn the session here.
    onMount(refreshSession);
</script>

<header>
    <a class="brand" href="/">{$t('brand.name')}</a>
    <nav>
        <!-- Account / sign-in: held back until /api/me resolves so it never flashes
             "Sign in" for an authed user. -->
        {#if $session}
            <span class="account-email">{$session.email}</span>
            <button type="button" class="account-btn" onclick={() => signOut()}
                >{$t('auth.signout')}</button
            >
        {:else if $sessionLoaded}
            <button type="button" class="account-btn" onclick={() => loginOpen.set(true)}
                >{$t('auth.signin')}</button
            >
        {/if}

        <!-- Segmented language toggle: a single pill with a sliding active segment. -->
        <div class="lang" role="group" aria-label={$t('lang.label')} data-active={$lang}>
            <span class="lang-thumb" aria-hidden="true"></span>
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
