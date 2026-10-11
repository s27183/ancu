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
    import { getQuota, type Quota } from '$lib/api';
    import PrivacySheet from '$lib/PrivacySheet.svelte';
    import { date } from '$lib/format';

    let { children }: { children: import('svelte').Snippet } = $props();

    // The account chip lives in the global header now, so learn the session here.
    onMount(refreshSession);

    // Honest-partial -> P-5 · Metering, not gating -> The web frontend -> the visitor's menu
    // The side-sheet (slides in from the right) every visitor opens from the header,
    // signed in or not (behavior 62): the same three allowance rows for everyone, the
    // privacy policy, the contact address, and sign in / out — nothing else. The tier, token
    // counts and infrastructure cost stay internal (GET /api/billing/usage).
    let menuOpen = $state(false);
    let privacyOpen = $state(false);

    // Fetched fresh each time the menu opens, from the gates' own counters.
    type QuotaPhase = 'idle' | 'loading' | 'ok' | 'error';
    let quotaPhase: QuotaPhase = $state('idle');
    let quota: Quota | null = $state(null);

    async function openMenu() {
        menuOpen = true;
        quotaPhase = 'loading';
        quota = await getQuota();
        quotaPhase = quota ? 'ok' : 'error';
    }

    const pct = (f: number) => Math.round(Math.min(1, Math.max(0, f)) * 100);
    // The share of the month's AI allowance from which the menu names it.
    const ALLOWANCE_WARN = 0.8;
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
                onclick={openMenu}
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
        <section class="menu-quota" aria-labelledby="menu-quota-h">
            <h2 id="menu-quota-h" class="menu-h">{$t('quota.title')}</h2>
            {#if quotaPhase === 'loading'}
                <p class="placeholder">{$t('quota.loading')}</p>
            {:else if quotaPhase === 'error' || !quota}
                <p class="placeholder">{$t('quota.error')}</p>
            {:else}
                <!-- The same three rows for every visitor (Son 2026-10-11); only the values
                     differ between signed out and signed in. -->
                <div class="menu-row">
                    <span class="menu-label">{$t('quota.saved')}</span>
                    <span class="menu-value"
                        >{quota.plansSaved} · {quota.plansToday === 'unlimited'
                            ? $t('quota.saved_nocap')
                            : $t('quota.saved_cap').replace('{n}', String(quota.plansToday.limit))}</span
                    >
                </div>
                {#if quota.plansToday !== 'unlimited' && quota.plansToday.used >= quota.plansToday.limit}
                    <p class="menu-note">{$t('quota.saved_none_left')}</p>
                {/if}
                <div class="menu-row">
                    <span class="menu-label">{$t('quota.kept')}</span>
                    <span class="menu-value"
                        >{quota.keepDays === 'until_deleted'
                            ? $t('quota.kept_until_deleted')
                            : $t('quota.kept_days').replace('{n}', String(quota.keepDays))}</span
                    >
                </div>
                <div class="menu-row">
                    <span class="menu-label">{$t('quota.questions_today')}</span>
                    <span class="menu-value">
                        {#if quota.questionsToday === 'sign_in'}
                            {$t('quota.questions_signin')}
                        {:else if quota.questionsToday === 'unlimited'}
                            {$t('quota.unlimited')}
                        {:else}
                            {$t('quota.left')
                                .replace('{n}', String(Math.max(0, quota.questionsToday.limit - quota.questionsToday.used)))
                                .replace('{of}', String(quota.questionsToday.limit))}
                        {/if}
                    </span>
                </div>
                <!-- The monthly AI allowance is a ceiling on what an account may cost, in a
                     unit visitors do not use; named only once it is near (Son 2026-10-11). -->
                {#if quota.allowance && quota.allowance !== 'unlimited' && quota.allowance.usedFraction >= ALLOWANCE_WARN}
                    <p class="menu-note menu-warn">
                        {$t('quota.allowance_near').replace('{p}', String(pct(quota.allowance.usedFraction)))}{#if quota.allowance.resetsAt}{' · '}{$t('quota.resets').replace('{d}', date(quota.allowance.resetsAt, $lang) ?? '')}{/if}
                    </p>
                {/if}
            {/if}
        </section>

        <button type="button" class="menu-link" onclick={() => (privacyOpen = true)}
            >{$t('menu.privacy')}</button
        >

        <section class="menu-contact" aria-labelledby="menu-contact-h">
            <h2 id="menu-contact-h" class="menu-h">{$t('menu.contact')}</h2>
            <a class="menu-email" href="mailto:info@maiancu.com">info@maiancu.com</a>
        </section>

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

{#if privacyOpen}
    <PrivacySheet onclose={() => (privacyOpen = false)} />
{/if}
