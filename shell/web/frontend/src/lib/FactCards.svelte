<script lang="ts">
    // Bilingual -> The web frontend -> the facts, drawn the same wherever they appear
    // Purpose:   draws one KB fact doc's facts as cards — headline, picture, caption, note,
    //            sources and date — for the Introduction sheet (Welcome) and the
    //            "Úc qua số liệu" page (/facts, behavior 122), so the two cannot disagree.
    // Holds:     every figure and source comes from the doc (GET /api/facts); nothing here
    //            authors a fact.
    // Rests on:  facts.ts (pick, factSources, publisher, formatAsOf), FactVisual.svelte.
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import FactVisual from '$lib/FactVisual.svelte';
    import { type FactDoc, factSources, formatAsOf, pick, publisher } from '$lib/facts';

    let { doc }: { doc: FactDoc } = $props();
</script>

<div class="wl-grid">
    {#each doc.facts as fact (fact.id)}
        {@const srcs = factSources(doc, fact)}
        <article
            class="wl-fact"
            class:wide={fact.visual === 'bars' || fact.visual === 'growth'}
            class:statement={fact.visual === 'statement'}
            data-fact={fact.id}
        >
            <h4>{pick(fact.headline, $lang)}</h4>
            <FactVisual {fact} />
            <p class="wl-caption">{pick(fact.caption, $lang)}</p>
            {#if fact.note}
                {@const nsrc = doc.sources[fact.note_sources?.[0] ?? -1]}
                <p class="wl-fact-note">
                    {pick(fact.note, $lang)}
                    {#if nsrc?.url}<a href={nsrc.url} target="_blank" rel="noopener noreferrer">{publisher(nsrc, $lang)}</a>{/if}
                </p>
            {/if}
            <p class="wl-src">
                {$t('intro.source')}:
                {#each srcs as src, k (k)}{#if k}{', '}{/if}{#if src.url}<a href={src.url} target="_blank" rel="noopener noreferrer"
                            >{publisher(src, $lang)}</a
                        >{/if}{#if src.kind === 'ranking'}{' '}<span class="wl-src-kind">({$t('intro.source.ranking')})</span>{/if}{/each}
                · {formatAsOf(fact.as_of, $lang)}
            </p>
        </article>
    {/each}
</div>

<style>
    .wl-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: var(--sp-3);
    }
    .wl-fact {
        display: flex;
        flex-direction: column;
        gap: var(--sp-3);
        min-width: 0;
        padding: var(--sp-4);
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        box-shadow: var(--shadow-1);
    }
    .wl-fact h4 {
        margin: 0;
        font-size: var(--fs-md);
        font-weight: 700;
        line-height: 1.35;
        letter-spacing: -0.01em;
        color: var(--ink);
        text-wrap: balance;
    }
    .wl-caption {
        margin: 0;
        font-size: var(--fs-xs);
        color: var(--ink-2);
    }
    .wl-fact-note {
        margin: 0;
        padding: var(--sp-2) var(--sp-3);
        background: var(--info-soft, var(--surface-2));
        border-radius: var(--radius-xs);
        font-size: var(--fs-2xs);
        line-height: 1.5;
        color: var(--ink-2);
    }
    .wl-fact-note a {
        color: var(--accent);
        font-weight: 600;
        text-decoration: none;
        white-space: nowrap;
    }
    /* A statement has no chart: its caption is the fact, so it reads at body size. */
    .wl-fact.statement .wl-caption {
        font-size: var(--fs-sm);
        line-height: 1.55;
    }
    .wl-src-kind {
        font-style: italic;
    }
    .wl-src {
        margin: auto 0 0;
        padding-top: var(--sp-2);
        border-top: 1px solid var(--border);
        font-size: var(--fs-2xs);
        color: var(--muted);
    }
    .wl-src a {
        color: var(--accent);
        font-weight: 600;
        text-decoration: none;
        border-radius: var(--radius-xs);
    }
    .wl-src a:hover {
        text-decoration: underline;
        text-underline-offset: 2px;
    }
    .wl-src a:focus-visible {
        outline: none;
        box-shadow: var(--ring);
    }
    @media (min-width: 48rem) {
        .wl-grid {
            grid-template-columns: repeat(2, 1fr);
        }
        .wl-fact.wide {
            grid-column: 1 / -1;
        }
    }
</style>
