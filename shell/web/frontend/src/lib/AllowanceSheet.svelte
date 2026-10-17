<script lang="ts">
    // Honest-partial -> P-5 · Metering, not gating -> The web frontend -> the free allowance popup
    // What the visitor can still use for free (behaviors 62, 64), opened from the menu:
    // (behavior 111: saved plans read "N / 7" signed out, "N / 28" signed in)
    // the same three rows for every visitor — saved plans, kept for, AI questions today —
    // read fresh from GET /api/me/quota (the gates' own counters) each time it opens. The
    // monthly AI allowance is a ceiling on what an account may cost, in a unit visitors
    // do not use; it is named only from 80% used (Son 2026-10-11). Tier, tokens and
    // cost never appear.
    import { onMount } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import { getQuota, type Quota } from '$lib/api';
    import { date } from '$lib/format';
    import InfoSheet from '$lib/InfoSheet.svelte';

    let { onclose }: { onclose: () => void } = $props();

    type Phase = 'loading' | 'ok' | 'error';
    let phase: Phase = $state('loading');
    let quota: Quota | null = $state(null);
    onMount(async () => {
        quota = await getQuota();
        phase = quota ? 'ok' : 'error';
    });

    // The share of the month's AI allowance from which it is named.
    const ALLOWANCE_WARN = 0.8;
    const pct = (f: number) => Math.round(Math.min(1, Math.max(0, f)) * 100);
</script>

<InfoSheet title={$t('quota.title')} {onclose} narrow>
    {#if phase === 'loading'}
        <p class="placeholder">{$t('quota.loading')}</p>
    {:else if phase === 'error' || !quota}
        <p class="placeholder">{$t('quota.error')}</p>
    {:else}
        <div class="menu-quota">
            <div class="menu-row">
                <span class="menu-label">{$t('quota.saved')}</span>
                <!-- behavior 111: the plans held against the cap ("3 / 7"); an older shell
                     without plans_limit reads the count alone -->
                <span class="menu-value" data-plans-held
                    >{quota.plansLimit ? `${quota.plansSaved} / ${quota.plansLimit}` : quota.plansSaved}</span
                >
            </div>
            {#if quota.plansLimit && quota.plansSaved >= quota.plansLimit}
                <p class="menu-note">{$t(quota.kind === 'guest' ? 'quota.full_guest' : 'quota.full_user')}</p>
            {:else if quota.plansToday !== 'unlimited' && quota.plansToday.used >= quota.plansToday.limit}
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
            {#if quota.allowance && quota.allowance !== 'unlimited' && quota.allowance.usedFraction >= ALLOWANCE_WARN}
                <p class="menu-note menu-warn">
                    {$t('quota.allowance_near').replace('{p}', String(pct(quota.allowance.usedFraction)))}{#if quota.allowance.resetsAt}{' · '}{$t('quota.resets').replace('{d}', date(quota.allowance.resetsAt, $lang) ?? '')}{/if}
                </p>
            {/if}
        </div>
        {#if quota.kind === 'guest'}
            <p class="menu-note">{$t('quota.signin_adds')}</p>
        {/if}
    {/if}
</InfoSheet>
