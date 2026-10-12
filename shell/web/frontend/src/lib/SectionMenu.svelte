<script lang="ts">
    // The plan sheet's floating section menu on a phone (behavior 68; registry and the
    // why in sections.svelte.ts). A pill at the sheet's foot names where you are; a
    // tap opens the sections grouped as the rails group them, the current one marked;
    // picking one goes there and closes the menu (Esc or a tap outside closes it too).
    // Hidden at ≥48rem, where the rails are shown instead (app.css .sec-*).
    //
    // How it is found (behavior 72; Son 2026-10-12: visitors did not know it was there):
    // until the visitor first opens the menu in this browser (SEEN_KEY, like the tour's
    // flag), the pill pulses — a ring, 2 × 1.4 s, on transform/opacity only — each time a
    // sheet opens or its section changes, and on the area data section (`hint`) a small
    // bubble above it says the plan is in here. Neither shows while the tour runs (the tour
    // rings the pill itself) nor after the first open; reduced motion drops the pulse only.
    //
    // Inside a shown plan (`inPlan`, behavior 75) the menu holds the plan's many sections,
    // which a visitor who opened it once on the area data never saw: the pulse and a plan
    // bubble come back there until the menu is opened while the plan is shown (PLAN_KEY).
    import { fly, fade } from 'svelte/transition';
    import { cubicOut } from 'svelte/easing';
    import { t } from '$lib/i18n';
    import { tourStep } from '$lib/tour';
    import type { SectionGroup, SectionIcon } from '$lib/sections.svelte';

    let { groups, current, onpick, hint = false, inPlan = false }: {
        groups: SectionGroup[];
        current: string;
        /** After a section is picked (the sheet scrolls its body to the top). */
        onpick?: () => void;
        /** May show the "the plan is in here" bubble (the area data section). */
        hint?: boolean;
        /** The plan's sections are listed (behavior 75): its own flag and bubble. */
        inPlan?: boolean;
    } = $props();

    const SEEN_KEY = 'ancu-sections-seen';
    const PLAN_KEY = 'ancu-sections-plan-seen';
    function readSeen(key: string): boolean {
        try {
            return localStorage.getItem(key) === '1';
        } catch {
            return false;
        }
    }
    function markSeen(key: string) {
        try {
            localStorage.setItem(key, '1');
        } catch {
            /* storage blocked: the pulse simply comes back next visit */
        }
    }
    let seen = $state(readSeen(SEEN_KEY));
    let seenPlan = $state(readSeen(PLAN_KEY));
    const noticing = $derived((inPlan ? !seenPlan : !seen) && $tourStep === 0);

    let open = $state(false);
    function toggle() {
        open = !open;
        if (open && !seen) {
            seen = true;
            markSeen(SEEN_KEY);
        }
        if (open && inPlan && !seenPlan) {
            seenPlan = true;
            markSeen(PLAN_KEY);
        }
    }
    let menuEl: HTMLDivElement | undefined = $state();

    function pick(select: () => void) {
        select();
        open = false;
        onpick?.();
    }

    function onKey(e: KeyboardEvent) {
        if (open && e.key === 'Escape') open = false;
    }

    $effect(() => {
        if (open) menuEl?.querySelector<HTMLButtonElement>('.sec-item.active, .sec-item')?.focus();
    });

    const reduce =
        typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
    const dur = reduce ? 0 : 200;

    // 18px line icons, drawn like the app's other inline svgs (no icon library).
    const PATHS: Record<SectionIcon, string> = {
        zone: 'M12 21s-6-5.4-6-10a6 6 0 0 1 12 0c0 4.6-6 10-6 10z M12 13a2 2 0 1 0 0-4 2 2 0 0 0 0 4z',
        overview: 'M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z',
        flow: 'M5 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M19 9a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M7 17h6a3 3 0 0 0 0-6h-2a3 3 0 0 1 0-6h6',
        budget: 'M3 7h18v12H3z M3 7l3-3h12l3 3 M16 13h2',
        portfolio: 'M4 8h16v11H4z M9 8V5h6v3 M4 13h16',
        family: 'M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M3 20a6 6 0 0 1 12 0 M17 11a2.5 2.5 0 1 0 0-5 M17 14a5 5 0 0 1 4 6',
        qa: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z M19 16l.8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8z',
        sub: ''
    };
</script>

<svelte:window onkeydown={onKey} />

{#if open}
    <button
        type="button"
        class="sec-scrim"
        aria-label={$t('sheet.close')}
        onclick={() => (open = false)}
        transition:fade={{ duration: dur }}
    ></button>
    <div
        class="sec-menu"
        role="menu"
        aria-label={$t('sheet.sections')}
        bind:this={menuEl}
        transition:fly={{ y: 16, duration: dur, easing: cubicOut }}
    >
        {#each groups as g (g.id)}
            {#if g.label}<p class="sec-group">{g.label}</p>{/if}
            {#each g.items as it (it.id)}
                <button
                    type="button"
                    role="menuitemradio"
                    aria-checked={it.active}
                    class="sec-item"
                    class:active={it.active}
                    class:accent={it.accent}
                    class:nested={it.nested}
                    data-tour={it.tour}
                    onclick={() => pick(it.select)}
                >
                    {@render icon(it.icon)}<span class="sec-label">{it.label}</span>{#if it.active && !it.parent}<span
                            class="sec-check"
                            aria-hidden="true">✓</span
                        >{/if}
                </button>
            {/each}
        {/each}
    </div>
{/if}

<button
    type="button"
    class="sec-pill"
    data-tour="sections"
    aria-haspopup="menu"
    aria-expanded={open}
    onclick={toggle}
>
    {#if noticing && !reduce}
        {#key current}<span class="sec-pill-ring" aria-hidden="true"></span>{/key}
    {/if}
    <span class="sec-pill-text">{current}</span>
    <svg class="sec-pill-caret" viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"
        ><path
            d="M4 6l4 4 4-4"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
        /></svg
    >
</button>

{#if noticing && (hint || inPlan) && !open}
    <p class="sec-hint" aria-hidden="true">
        {$t(inPlan ? 'sheet.sections.hint_plan' : 'sheet.sections.hint')}
    </p>
{/if}

{#snippet icon(name: SectionIcon)}
    {#if name === 'sub'}
        <span class="sec-icon sec-icon-sub" aria-hidden="true"></span>
    {:else}
        <svg class="sec-icon" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"
            ><path
                d={PATHS[name]}
                fill="none"
                stroke="currentColor"
                stroke-width="1.7"
                stroke-linecap="round"
                stroke-linejoin="round"
            /></svg
        >
    {/if}
{/snippet}
