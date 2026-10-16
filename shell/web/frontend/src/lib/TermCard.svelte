<script lang="ts">
    // Bilingual -> P-7 · The KB -> The web frontend -> the one card a tapped term opens
    // Behavior 102: the term in Vietnamese and English with its abbreviation, what it is,
    // why it matters to this buyer, and the KB source it rests on. The app's popup frame
    // (InfoSheet: ✕, Esc, a tap outside); on close focus goes back to the tapped term.
    import { tick } from 'svelte';
    import InfoSheet from '$lib/InfoSheet.svelte';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { openTerm, pickL } from '$lib/terms';

    const other = $derived($lang === 'vi' ? 'en' : 'vi');

    async function close() {
        const from = $openTerm?.from ?? null;
        openTerm.set(null);
        await tick();
        from?.focus();
    }
    function host(url: string): string {
        try {
            return new URL(url).hostname.replace(/^www\./, '');
        } catch {
            return url;
        }
    }
</script>

{#if $openTerm}
    {@const term = $openTerm.term}
    <InfoSheet title={pickL(term.name, $lang)} onclose={close} narrow>
        <div class="tc" data-term-card={term.id}>
            <p class="tc-names">
                {#if term.abbr}<span class="tc-abbr">{term.abbr}</span> · {/if}<span lang={other}
                    >{pickL(term.name, other)}</span
                >
            </p>
            <p class="tc-meaning">{pickL(term.meaning, $lang)}</p>
            <p class="tc-why"><strong>{$t('term.why')}</strong> {pickL(term.why, $lang)}</p>
            {#if term.source.url}
                <p class="tc-source">
                    {$t('term.source')}
                    <a href={term.source.url} target="_blank" rel="noopener noreferrer">{host(term.source.url)}</a>
                </p>
            {/if}
        </div>
    </InfoSheet>
{/if}

<style>
    .tc { display: grid; gap: 0.6rem; }
    .tc p { margin: 0; line-height: 1.5; }
    .tc-names { color: var(--muted); font-size: var(--fs-sm, 0.875rem); }
    .tc-abbr { font-weight: 700; color: var(--ink); letter-spacing: 0.02em; }
    .tc-meaning { color: var(--ink); }
    .tc-why { color: var(--ink); }
    .tc-source { color: var(--muted); font-size: var(--fs-sm, 0.875rem); }
</style>
