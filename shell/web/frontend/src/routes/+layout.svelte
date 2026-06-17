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

    // The account side-sheet (slides in from the right).
    let accountOpen = $state(false);
</script>

<header class="app-header">
    <a class="brand" href="/">{$t('brand.name')}</a>

    <!-- Segmented language toggle — centred in the header. -->
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

    <!-- Far-right: signed-in → an account-menu trigger (opens the right sheet);
         signed-out → a sign-in button. Held back until /api/me resolves. -->
    <div class="header-right">
        {#if $session}
            <button
                type="button"
                class="account-trigger"
                aria-label={$t('account.menu')}
                onclick={() => (accountOpen = true)}
            >
                <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                >
                    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
                    <circle cx="12" cy="7" r="4" />
                </svg>
            </button>
        {:else if $sessionLoaded}
            <button type="button" class="account-btn" onclick={() => loginOpen.set(true)}
                >{$t('auth.signin')}</button
            >
        {/if}
    </div>
</header>

<main>
    {@render children()}
</main>

<!-- Account side-sheet — slides in from the right (CSS transform on a solid panel).
     Always in the DOM for the slide; `inert` + off-screen when closed. -->
<button
    type="button"
    class="account-backdrop"
    class:open={accountOpen}
    aria-label={$t('sheet.close')}
    onclick={() => (accountOpen = false)}
></button>
<aside
    class="account-sheet"
    class:open={accountOpen}
    inert={!accountOpen}
    aria-label={$t('account.title')}
>
    <header class="account-sheet-head">
        <span>{$t('account.title')}</span>
        <button
            type="button"
            class="close"
            aria-label={$t('sheet.close')}
            onclick={() => (accountOpen = false)}>✕</button
        >
    </header>
    <div class="account-sheet-body">
        {#if $session}
            <div class="account-user">
                <svg
                    class="account-avatar"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                >
                    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
                    <circle cx="12" cy="7" r="4" />
                </svg>
                <span class="account-user-email">{$session.email}</span>
            </div>
            <button
                type="button"
                class="account-action"
                onclick={() => {
                    signOut();
                    accountOpen = false;
                }}
            >
                <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                >
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                </svg>
                {$t('auth.signout')}
            </button>
        {/if}
    </div>
</aside>
