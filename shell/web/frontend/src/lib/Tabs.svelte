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

    // Edge-fade overflow cue (2026-08, NewsListSheet's category tabs — 7 tabs overflow a
    // 420px rail with no hint the rest are reachable by swipe). Tracked explicitly via
    // scroll metrics rather than a pure-CSS scroll-shadow trick: this component is reused
    // by 3 callers with different container backgrounds (Modal body vs PlanProjection's
    // .pp-subcontent), and an explicit boolean is easier to reason about/verify than a
    // background-gradient mask tuned to one caller's colors.
    let railEl: HTMLDivElement | undefined = $state();
    let canScrollLeft = $state(false);
    let canScrollRight = $state(false);

    function updateOverflow() {
        if (!railEl) return;
        canScrollLeft = railEl.scrollLeft > 1;
        canScrollRight = railEl.scrollLeft + railEl.clientWidth < railEl.scrollWidth - 1;
    }

    // Re-check whenever the tab set itself changes shape (e.g. a note count changes a
    // label's width) — `tabs` read here just to make the effect depend on it.
    $effect(() => {
        tabs;
        updateOverflow();
    });
</script>

<!-- Unique class (`tabrail`, not `tabs`) — there is a global `.sheet .tabs` rule for the
     map sheet's own nav, and both callers of this component live inside `.sheet`; a unique
     class avoids that collision entirely (self-contained, predictable cascade). -->
<div class="tabrail-wrap">
    <div
        class="tabrail"
        role="tablist"
        bind:this={railEl}
        onscroll={updateOverflow}
    >
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
    <div class="tabrail-fade tabrail-fade-left" class:visible={canScrollLeft} aria-hidden="true"></div>
    <div class="tabrail-fade tabrail-fade-right" class:visible={canScrollRight} aria-hidden="true"></div>
</div>

<style>
    .tabrail-wrap {
        position: relative;
        margin: 0 0 0.85rem;
        /* Sticky like the top-level .pp-subtabs rail. top defaults to 0 (the phase-sheet
           rail, which sticks to the top of the modal's own scroll body). The Budget rail
           sets --tabrail-top to the .pp-subtabs height so it stacks just BELOW that rail in
           the shared .sheet .body scroll (z below it; the opaque --bg hides scrolled content).
           Moved here from .tabrail itself so the fade overlays (also absolutely positioned
           against this wrapper) scroll/stick together with the rail. */
        position: sticky;
        top: var(--tabrail-top, 0);
        z-index: 4;
    }
    .tabrail {
        display: flex;
        gap: 0.2rem;
        overflow-x: auto;
        padding: 0.2rem;
        background: var(--bg);
        border: 1px solid var(--border);
        border-radius: 0.55rem;
        scrollbar-width: none;
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
    /* Fades toward the rail's OWN background (var(--bg), the pill fill), not whatever sits
       behind the wrap — the overlay masks scrolled-under button edges inside the rail's own
       box, so it has to match that box's fill to read as "fading out" rather than a stray tint. */
    .tabrail-fade {
        position: absolute;
        top: 1px;
        bottom: 1px;
        width: 1.75rem;
        pointer-events: none;
        opacity: 0;
        transition: opacity var(--t-fast) var(--ease);
    }
    .tabrail-fade.visible {
        opacity: 1;
    }
    .tabrail-fade-left {
        left: 1px;
        border-radius: 0.55rem 0 0 0.55rem;
        background: linear-gradient(to right, var(--bg), transparent);
    }
    .tabrail-fade-right {
        right: 1px;
        border-radius: 0 0.55rem 0.55rem 0;
        background: linear-gradient(to left, var(--bg), transparent);
    }
</style>
