<script lang="ts">
    // A small reusable tab rail (the same pattern as PlanProjection's top-level .pp-subtabs,
    // factored out for the nested drill surfaces: the phase sheet and the budget calculator).
    // The parent owns the active id + state; this is a pure controlled switcher (reduces
    // surface area — one rail, two callers, no new renderers). Labels are pre-localized by
    // the caller (engine prose via pick() or chrome via $t); this never touches i18n itself.
    let { tabs, active, onSelect }: {
        tabs: { id: string; label: string }[];
        active: string;
        onSelect: (id: string) => void;
    } = $props();
</script>

<!-- Unique class (`tabrail`, not `tabs`) — there is a global `.sheet .tabs` rule for the
     map sheet's own nav, and both callers of this component live inside `.sheet`; a unique
     class avoids that collision entirely (self-contained, predictable cascade). -->
<div class="tabrail" role="tablist">
    {#each tabs as tb (tb.id)}
        <button
            type="button"
            role="tab"
            aria-selected={active === tb.id}
            class:active={active === tb.id}
            onclick={() => onSelect(tb.id)}>{tb.label}</button
        >
    {/each}
</div>

<style>
    .tabrail {
        display: flex;
        gap: 0.2rem;
        overflow-x: auto;
        margin: 0 0 0.85rem;
        padding: 0.2rem;
        background: var(--bg);
        border: 1px solid var(--border);
        border-radius: 0.55rem;
        scrollbar-width: none;
        /* Sticky like the top-level .pp-subtabs rail. top defaults to 0 (the phase-sheet
           rail, which sticks to the top of the modal's own scroll body). The Budget rail
           sets --tabrail-top to the .pp-subtabs height so it stacks just BELOW that rail in
           the shared .sheet .body scroll (z below it; the opaque --bg hides scrolled content). */
        position: sticky;
        top: var(--tabrail-top, 0);
        z-index: 4;
    }
    .tabrail::-webkit-scrollbar {
        display: none;
    }
    .tabrail button {
        flex: 1 0 auto;
        border: none;
        background: transparent;
        color: var(--muted);
        border-radius: 0.4rem;
        padding: 0.35rem 0.7rem;
        font-size: 0.78rem;
        font-weight: 600;
        white-space: nowrap;
        cursor: pointer;
        transition:
            background var(--t-fast) var(--ease),
            color var(--t-fast) var(--ease),
            box-shadow var(--t-fast) var(--ease);
    }
    .tabrail button:hover {
        color: var(--ink);
    }
    .tabrail button.active {
        background: var(--surface);
        color: var(--ink);
        box-shadow: 0 1px 2px rgba(15, 23, 42, 0.08);
    }
</style>
