<script lang="ts">
    // The AI assistant's mark (behavior 55): a four-point sparkle in currentColor, sized
    // to the text beside it. Decorative — the label carries the meaning.
    let { size = '1em' }: { size?: string } = $props();
</script>

<svg class="sparkle" width={size} height={size} viewBox="0 0 16 16" aria-hidden="true">
    <path
        fill="currentColor"
        d="M8 0c.4 3.9 2.1 5.6 6 6-3.9.4-5.6 2.1-6 6-.4-3.9-2.1-5.6-6-6 3.9-.4 5.6-2.1 6-6Zm5.5 10c.2 1.8 1 2.6 2.5 2.8-1.5.2-2.3 1-2.5 2.7-.2-1.7-1-2.5-2.5-2.7 1.5-.2 2.3-1 2.5-2.8Z"
    />
</svg>

<style>
    .sparkle {
        display: inline-block;
        vertical-align: -0.125em;
    }
</style>
