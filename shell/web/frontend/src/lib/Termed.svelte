<script lang="ts">
    // Bilingual -> P-7 · The KB -> The web frontend -> a run of copy whose Australian terms open their card
    // Behavior 102: draws `text` with the first hit of each term marked (lib/terms.ts).
    // One instance is one block unless the caller passes a shared `seen`. A tap or
    // Enter/Space opens the TermCard and stops there, so a term inside a line's <summary>
    // explains itself without opening or closing the line.
    import { terms, markTerms, showTerm, type Term } from '$lib/terms';

    let { text, seen }: { text: string | null | undefined; seen?: Set<string> } = $props();

    const segments = $derived(markTerms(text ?? '', $terms, seen ?? new Set()));

    function open(e: Event, t: Term) {
        e.preventDefault();
        e.stopPropagation();
        showTerm(t, e.currentTarget as HTMLElement);
    }
</script>

{#each segments as s, i (i)}{#if s.term}{@const term = s.term}<span
            class="term"
            role="button"
            tabindex="0"
            data-term={term.id}
            onclick={(e) => open(e, term)}
            onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && open(e, term)}>{s.text}</span
        >{:else}{s.text}{/if}{/each}
