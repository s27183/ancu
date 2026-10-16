<script lang="ts">
    // A label/value row — the atom of the summary-card / calculator / data-table
    // shapes. An empty value renders nothing at all: the row, label included, is
    // left out rather than drawn with a placeholder.
    let { label, value }: { label: string; value: string | null | undefined } = $props();
</script>

{#if value}
    <div class="pp-field">
        <span class="pp-label">{label}</span>
        <span class="pp-value">{value}</span>
    </div>
{/if}
