<script lang="ts">
    // The privacy policy popup (behaviors 62, 64), opened from the menu. The text lives in
    // privacyPolicy.ts, one record per language; the frame is InfoSheet's.
    import { lang } from '$lib/stores/lang';
    import { PRIVACY } from '$lib/privacyPolicy';
    import InfoSheet from '$lib/InfoSheet.svelte';

    let { onclose }: { onclose: () => void } = $props();

    const policy = $derived(PRIVACY[$lang === 'en' ? 'en' : 'vi']);
</script>

<InfoSheet title={policy.title} {onclose}>
    <p class="privacy-effective">{policy.effective}</p>
    <p>{policy.intro}</p>
    {#each policy.sections as s (s.h)}
        <section>
            <h3>{s.h}</h3>
            {#if s.items}
                <ul>
                    {#each s.items as item (item)}<li>{item}</li>{/each}
                </ul>
            {/if}
            {#each s.p ?? [] as para (para)}<p>{para}</p>{/each}
        </section>
    {/each}
</InfoSheet>
