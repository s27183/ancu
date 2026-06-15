<script lang="ts">
    // A label/value row — the atom of the summary-card / calculator / data-table
    // shapes. An empty value renders the calm Pending marker, not a blank.
    import Pending from './Pending.svelte';

    let { label, value }: { label: string; value: string | null | undefined } = $props();
</script>

<div class="pp-field">
    <span class="pp-label">{label}</span>
    {#if value}
        <span class="pp-value">{value}</span>
    {:else}
        <Pending />
    {/if}
</div>
