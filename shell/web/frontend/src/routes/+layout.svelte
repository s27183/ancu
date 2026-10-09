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
    import { getUsage, type UsageSummary } from '$lib/api';
    import { num, date } from '$lib/format';

    let { children }: { children: import('svelte').Snippet } = $props();

    // The account chip lives in the global header now, so learn the session here.
    onMount(refreshSession);

    // The account side-sheet (slides in from the right).
    let accountOpen = $state(false);

    // Usage summary (8-S5g, billing.md §6/§7) — fetched fresh each time the sheet
    // opens (a low-frequency, cheap read; no point caching a per-visit glance).
    type UsagePhase = 'idle' | 'loading' | 'ok' | 'error';
    let usagePhase: UsagePhase = $state('idle');
    let usage: UsageSummary | null = $state(null);

    const costFormat = $derived(
        new Intl.NumberFormat($lang === 'vi' ? 'vi-VN' : 'en-AU', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 2
        })
    );

    async function openAccount() {
        accountOpen = true;
        usagePhase = 'loading';
        const out = await getUsage();
        if (out.kind === 'ok') {
            usage = out.usage;
            usagePhase = 'ok';
        } else {
            usagePhase = 'error';
        }
    }

    function tierKey(
        tier: UsageSummary['tier']
    ): 'account.usage.tier.free' | 'account.usage.tier.plus' | 'account.usage.tier.pro' {
        return tier === 'plus'
            ? 'account.usage.tier.plus'
            : tier === 'pro'
              ? 'account.usage.tier.pro'
              : 'account.usage.tier.free';
    }
</script>

<!-- The tab title is the product name from i18n's one BRAND constant (behavior 17). -->
<svelte:head>
    <title>{$t('brand.name')}</title>
</svelte:head>

<header class="app-header">
    <a class="brand" href="/">
        <!-- The brand mark: a roof over a settled line ("an cư" — settling into a home). -->
        <span class="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 11.5 12 5l8 6.5" />
                <path d="M7 10v8.5h10V10" />
                <path d="M10.5 18.5v-4h3v4" />
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

    <!-- Far-right: signed-in → an account-menu trigger (opens the right sheet);
         signed-out → a sign-in button. Held back until /api/me resolves. -->
    <div class="header-right">
        {#if $session}
            <button
                type="button"
                class="account-trigger"
                aria-label={$t('account.menu')}
                onclick={openAccount}
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

            <div class="account-usage">
                {#if usagePhase === 'loading'}
                    <p class="placeholder">{$t('account.usage.loading')}</p>
                {:else if usagePhase === 'error'}
                    <p class="placeholder">{$t('account.usage.error')}</p>
                {:else if usagePhase === 'ok' && usage}
                    <div class="account-usage-tier">{$t(tierKey(usage.tier))}</div>
                    <div class="account-usage-row">
                        <span class="account-usage-label">{$t('account.usage.tokens_used')}</span>
                        <span class="account-usage-value">
                            {#if usage.limitTokens === 'unlimited'}
                                {num(usage.usedTokens, $lang)} · {$t('account.usage.tokens_unlimited')}
                            {:else}
                                {num(usage.usedTokens, $lang)} / {num(usage.limitTokens, $lang)}
                            {/if}
                        </span>
                    </div>
                    <div class="account-usage-row">
                        <span class="account-usage-label">{$t('account.usage.period')}</span>
                        <span class="account-usage-value">
                            {date(usage.periodStart, $lang)} – {date(usage.periodEnd, $lang)}
                        </span>
                    </div>
                    <div class="account-usage-row">
                        <span class="account-usage-label">{$t('account.usage.cost')}</span>
                        <span class="account-usage-value">{costFormat.format(usage.shadowCost)}</span>
                    </div>
                {/if}
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
