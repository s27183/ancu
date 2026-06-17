<script lang="ts">
    // The sign-in sheet (login slice): a passwordless magic link + Google OAuth, the
    // two backends fh_shell_h_auth exposes. Mobile-native (§7.1): one decision (your
    // email), a big thumb-zone action, calm terminal ("check your email") — never a
    // blank wait or a raw error. Reuses the .ob-backdrop / dialog chrome the
    // onboarding sheet uses. The session itself is an httpOnly cookie the backend
    // sets on redemption; this sheet never touches a token.
    import { requestMagicLink, GOOGLE_SIGNIN_HREF } from '$lib/auth';
    import { t } from '$lib/i18n';
    import { fade } from 'svelte/transition';
    import { modalCard } from '$lib/transitions';

    let { onclose }: { onclose: () => void } = $props();

    let email = $state('');
    let phase = $state<'form' | 'sending' | 'sent'>('form');
    let devLink = $state<string | null>(null);
    let showInvalid = $state(false);

    const emailValid = $derived(email.trim().length >= 3 && email.includes('@'));

    async function send() {
        if (!emailValid) {
            showInvalid = true;
            return;
        }
        phase = 'sending';
        const res = await requestMagicLink(email.trim());
        devLink = res.dev_link ?? null;
        phase = 'sent';
    }
</script>

<div class="ob-backdrop" transition:fade={{ duration: 200 }}>
    <div class="onboarding" role="dialog" aria-modal="true" aria-label={$t('auth.title')} transition:modalCard>
        <header class="ob-head">
            <h2>{$t('auth.title')}</h2>
            <button type="button" class="close" onclick={onclose} aria-label={$t('sheet.close')}
                >✕</button
            >
        </header>

        {#if phase === 'sent'}
            <div class="ob-terminal">
                <h3>{$t('auth.sent.title')}</h3>
                <p>{$t('auth.sent.body')}</p>
                {#if devLink}
                    <!-- dev only: the backend echoes the link when AUTH_DEV_EXPOSE_LINK
                         is set, so the loop works with no inbox. -->
                    <p class="ob-hint">{$t('auth.devlink')}</p>
                    <a class="dev-link" href={devLink}>{devLink}</a>
                {/if}
                <button type="button" class="primary" onclick={onclose}>{$t('sheet.close')}</button>
            </div>
        {:else}
            <div class="ob-body">
                <label class="auth-field">
                    <span>{$t('auth.email.label')}</span>
                    <input
                        type="email"
                        inputmode="email"
                        autocomplete="email"
                        placeholder={$t('auth.email.placeholder')}
                        bind:value={email}
                        oninput={() => (showInvalid = false)}
                    />
                </label>
                {#if showInvalid}
                    <p class="ob-error">{$t('auth.email.invalid')}</p>
                {/if}

                <div class="auth-divider"><span>{$t('auth.or')}</span></div>

                <a class="google-btn" href={GOOGLE_SIGNIN_HREF}>{$t('auth.google')}</a>
            </div>

            <footer class="ob-foot">
                <button
                    type="button"
                    class="primary"
                    disabled={!emailValid || phase === 'sending'}
                    onclick={send}
                >
                    {phase === 'sending' ? $t('auth.sending') : $t('auth.send')}
                </button>
            </footer>
        {/if}
    </div>
</div>
