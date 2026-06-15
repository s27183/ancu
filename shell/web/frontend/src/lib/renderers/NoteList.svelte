<script lang="ts">
    // A list of engine-authored prose notes (LocalizedText). We pick the display
    // locale here — these are CONTENT, never routed through $t. Renders nothing when
    // the list is null/empty (honest-partial), so callers can drop it in unguarded.
    import { pick, type LocalizedText } from '$lib/planCard';
    import { lang } from '$lib/stores/lang';

    let { heading, notes }: {
        heading?: string;
        notes: LocalizedText[] | null | undefined;
    } = $props();

    const items = $derived((notes ?? []).map((n) => pick(n, $lang)).filter(Boolean));
</script>

{#if items.length}
    <div class="pp-notes">
        {#if heading}<span class="pp-notes-head">{heading}</span>{/if}
        <ul>
            {#each items as item, i (i)}
                <li>{item}</li>
            {/each}
        </ul>
    </div>
{/if}
