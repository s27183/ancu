<script lang="ts">
    // Self-hosted faces (behavior 41): Inter for the UI and every headline, Newsreader
    // for a news item's body only. Each ships a Vietnamese subset (unicode-range), so
    // VI text never falls back; served from this origin, no third-party font host.
    import '@fontsource-variable/inter';
    import '@fontsource-variable/newsreader';
    import '../app.css';
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { session, sessionLoaded, refreshSession, signOut } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import PrivacySheet from '$lib/PrivacySheet.svelte';
    import AllowanceSheet from '$lib/AllowanceSheet.svelte';

    let { children }: { children: import('svelte').Snippet } = $props();

    // The account chip lives in the global header now, so learn the session here.
    onMount(refreshSession);

    // Honest-partial -> P-5 · Metering, not gating -> The web frontend -> the visitor's menu
    // The side-sheet (slides in from the right) every visitor opens from the header,
    // signed in or not (behavior 62): three items, each an icon and a name (behavior 64)
    // — the free allowance and the privacy policy open a popup over the menu
    // (AllowanceSheet, PrivacySheet, one InfoSheet frame), contact opens the email
    // program — then sign in / out. Nothing else. The tier, token
    // counts and infrastructure cost stay internal (GET /api/billing/usage).
    let menuOpen = $state(false);
    // Which of the menu's popups is open over it, if any (behavior 64).
    let popup: 'allowance' | 'privacy' | null = $state(null);
</script>

<!-- The tab title is the product name from i18n's one BRAND constant (behavior 17). -->
<svelte:head>
    <title>{$t('brand.name')}</title>
</svelte:head>

<header class="app-header">
    <a class="brand" href="/">
        <!-- The brand mark (Son's pick, 2026-10-09): the four stars of the Southern Cross
             placed to trace a house — roof, walls, floor — with a small gold star inside,
             the household. Australian sky, a home under it. -->
        <span class="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
                <path d="M6.5 16 16 5.5l9.5 9M6.5 16v10.5h19V14.5" stroke-width="2" opacity=".6" />
                <path d="M16 0.5Q16 5.5 21 5.5Q16 5.5 16 10.5Q16 5.5 11 5.5Q16 5.5 16 0.5ZM25.5 10.3Q25.5 14.5 29.7 14.5Q25.5 14.5 25.5 18.7Q25.5 14.5 21.3 14.5Q25.5 14.5 25.5 10.3ZM6.5 11.8Q6.5 16 10.7 16Q6.5 16 6.5 20.2Q6.5 16 2.3 16Q6.5 16 6.5 11.8ZM16 21.5Q16 26.5 21 26.5Q16 26.5 16 31.5Q16 26.5 11 26.5Q16 26.5 16 21.5Z" fill="currentColor" stroke="none" />
                <path class="brand-mark-home" d="M20 17.2Q20 20 22.8 20Q20 20 20 22.8Q20 20 17.2 20Q20 20 20 17.2Z" stroke="none" />
            </svg>
        </span>
        <span class="brand-name">{$t('brand.name')}</span>
    </a>

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

    <!-- Far-right: the menu icon only, for every visitor once /api/me resolves (held back
         until then, so nothing flashes). Signing in lives in the menu, not the header
         (Son 2026-10-11: a button beside the icon crowded the header at 390px). -->
    <div class="header-right">
        {#if $sessionLoaded}
            <button
                type="button"
                class="account-trigger"
                aria-label={$t('menu.open')}
                aria-expanded={menuOpen}
                onclick={() => (menuOpen = true)}
            >
                <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    aria-hidden="true"
                >
                    <line x1="4" y1="7" x2="20" y2="7" />
                    <line x1="4" y1="12" x2="20" y2="12" />
                    <line x1="4" y1="17" x2="20" y2="17" />
                </svg>
            </button>
        {/if}
    </div>
</header>

<main>
    {@render children()}
</main>
<div class="safe-bottom-glass" aria-hidden="true"></div>

<!-- The menu — slides in from the right (CSS transform on a solid panel). -->
<!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
<div
    class="account-backdrop"
    class:open={menuOpen}
    aria-hidden="true"
    onclick={() => (menuOpen = false)}
></div>
<aside
    class="account-sheet"
    class:open={menuOpen}
    inert={!menuOpen}
    aria-label={$t('menu.title')}
>
    <header class="account-sheet-head">
        <span>{$t('menu.title')}</span>
        <button
            type="button"
            class="close"
            aria-label={$t('menu.close')}
            onclick={() => (menuOpen = false)}>✕</button
        >
    </header>
    <div class="account-sheet-body">
        <!-- Three items, each an icon, a name and what it does (behavior 64): two open a
             popup over the menu, the third hands a new message to the email program. -->
        <ul class="menu-list">
            <li>
                <button type="button" class="menu-item" onclick={() => (popup = 'allowance')}>
                    <span class="menu-icon" aria-hidden="true">
                        <!-- a gauge: what is left of the free allowance -->
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 18a9 9 0 1 1 15 0" /><path d="M12 13.5 15.5 9" /><circle cx="12" cy="14" r="1.2" fill="currentColor" stroke="none" /></svg>
                    </span>
                    <span class="menu-item-text">
                        <span class="menu-item-name">{$t('menu.allowance')}</span>
                        <span class="menu-item-hint">{$t('menu.allowance_hint')}</span>
                    </span>
                    <svg class="menu-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="9 6 15 12 9 18" /></svg>
                </button>
            </li>
            <li>
                <button type="button" class="menu-item" onclick={() => (popup = 'privacy')}>
                    <span class="menu-icon" aria-hidden="true">
                        <!-- a shield: how the visitor's data is kept -->
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3 5 6v5.5c0 4.3 3 8 7 9.5 4-1.5 7-5.2 7-9.5V6l-7-3Z" /><polyline points="9 12 11.2 14.2 15 10.2" /></svg>
                    </span>
                    <span class="menu-item-text">
                        <span class="menu-item-name">{$t('menu.privacy')}</span>
                        <span class="menu-item-hint">{$t('menu.privacy_hint')}</span>
                    </span>
                    <svg class="menu-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="9 6 15 12 9 18" /></svg>
                </button>
            </li>
            <li>
                <a class="menu-item" href="mailto:info@maiancu.com">
                    <span class="menu-icon" aria-hidden="true">
                        <!-- an envelope: write to us -->
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2" /><polyline points="3.5 6.5 12 13 20.5 6.5" /></svg>
                    </span>
                    <span class="menu-item-text">
                        <span class="menu-item-name">{$t('menu.contact')}</span>
                        <span class="menu-item-hint menu-item-email">info@maiancu.com</span>
                    </span>
                </a>
            </li>
        </ul>

        {#if $session}
            <button
                type="button"
                class="account-action"
                onclick={() => {
                    signOut();
                    menuOpen = false;
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
        {:else}
            <div class="menu-signin">
                <button
                    type="button"
                    class="account-action"
                    onclick={() => {
                        menuOpen = false;
                        loginOpen.set(true);
                    }}>{$t('auth.signin')}</button
                >
                <p class="menu-note">{$t('quota.signin_adds')}</p>
            </div>
        {/if}
    </div>
</aside>

{#if popup === 'allowance'}
    <AllowanceSheet onclose={() => (popup = null)} />
{:else if popup === 'privacy'}
    <PrivacySheet onclose={() => (popup = null)} />
{/if}
