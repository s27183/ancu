<script lang="ts">
    // An enum-value chip. The engine emits the enum single-valued; the shell maps it
    // to a display label (the caller passes the already-$t'd label) + a calm tone.
    type Tone = 'neutral' | 'good' | 'warn' | 'info';
    let { label, tone = 'neutral' }: { label: string; tone?: Tone } = $props();
</script>

<span class="pp-chip pp-chip-{tone}">{label}</span>
