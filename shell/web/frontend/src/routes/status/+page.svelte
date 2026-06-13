<script lang="ts">
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import { getHealth } from '$lib/api';

    type Phase = 'checking' | 'ok' | 'fail';
    let phase: Phase = $state('checking');
    let service: string = $state('');

    onMount(async () => {
        try {
            const h = await getHealth();
            service = h.service;
            phase = 'ok';
        } catch {
            phase = 'fail';
        }
    });
</script>

<section class="content">
    <h1>{$t('status.title')}</h1>
    {#if phase === 'checking'}
        <p class="placeholder">{$t('status.checking')}</p>
    {:else if phase === 'ok'}
        <p>{$t('status.ok')} — <code>{service}</code></p>
    {:else}
        <p>{$t('status.fail')}</p>
    {/if}
</section>
