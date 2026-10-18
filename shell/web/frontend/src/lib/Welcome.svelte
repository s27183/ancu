<script lang="ts">
    // Bilingual -> P-6 · Shells reach the engine only through the contract -> The web frontend -> the first-visit introduction
    // Purpose:   says on its first screen what the product does and what it is not, so a
    //            visitor knows before opening a plan that it budgets the whole lifecycle and
    //            walks the journey step by step (Hành trình, behavior 107), and that both
    //            the budget and the journey follow current government rules, each cited.
    // Holds:     every item names a place the visitor can reach — the plan, Hành trình, the
    //            suburb data, the news, the assistant; the first screen lists four (plan,
    //            Hành trình, data, news) and claims grounding only for what cites it — every
    //            figure and every rule-bound step (behaviors 113, 114); the launcher reads "Giới thiệu" /
    //            "Introduction" (behavior 107, Son 2026-10-17: once "Vì sao Úc?"); the
    //            launcher never covers a home card (behavior 128): it sits fixed at the
    //            bottom-right where its box, grown by a 12px gap, meets none of the cards'
    //            column at any point of the home's scroll — a home that does not scroll
    //            included — and otherwise is drawn after the cards, right-aligned,
    //            scrolling with them — measured on load, on resize, on a language change, when
    //            fonts land and when the news band's height moves the cards.
    // Rests on:  i18n.ts intro.* keys, VI and EN side by side; the home (routes/+page.svelte)
    //            mounting this inside its scrolling .home, after nav.home-ways, and .home
    //            making no stacking context of its own (app.css), so the sheet still covers
    //            the header; the close's fly-back reads launchEl's rect wherever it sits.
    //
    // The first-visit sheet (behavior 42): opens by itself the first time this browser
    // visits, says on its first screen what the product does (plan a budget, the journey's
    // checklist — behavior 107 — suburb data, news) and what it is not (a listing site, an advice service — behavior 90, Son
    // 2026-10-16: many took it for a listing site), draws the KB's cited facts —
    // where Vietnamese buyers stand, then why Australian property — and what the product
    // adds on top of them. Closing it (✕, scrim, Escape or the CTA) flies the card into a
    // small animated launcher at the bottom-right, which reopens it (behavior 44: its first
    // screen leads to the position card and the facts in one tap each); the browser then
    // remembers it was seen (facts.ts, introSeen). Under prefers-reduced-motion nothing
    // flies or pulses — it simply closes and the launcher sits still. The launcher pulses
    // light green on every visit until it is tapped (behavior 50).
    import { onMount, tick } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { onContentChange } from '$lib/stores/content';
    import { t } from '$lib/i18n';
    import FactCards from '$lib/FactCards.svelte';
    import Sparkle from '$lib/Sparkle.svelte';
    import {
        type FactDoc,
        SECTION_ORDER,
        getFacts,
        introSeen,
        markIntroSeen,
        pick
    } from '$lib/facts';
    import { goto } from '$app/navigation';
    import { startTour } from '$lib/tour';
    import { introOpen } from '$lib/mapHint';

    let open = $state(false);
    // The map's finding pointer waits while this sheet is open (behavior 78, mapHint.ts).
    $effect(() => introOpen.set(open));
    let closing = $state(false);
    let arrived = $state(false);
    let docs = $state<FactDoc[]>([]);
    let cardEl = $state<HTMLElement | null>(null);
    let launchEl = $state<HTMLButtonElement | null>(null);
    // Behavior 50 (revised 2026-10-10): the launcher pulses light green on every page
    // load, whether or not this browser has seen the sheet, and stops once the visitor
    // taps it (reopen) — for that page view only; the next visit pulses again. The first
    // version pulsed only while introSeen() was false, and since the sheet opens by
    // itself on a first visit and its close marks it seen, nobody who had visited
    // before ever saw it (Son on prod, 2026-10-10: "did not see … pulse at all").
    let pulse = $state(true);
    // Behavior 52, moved by 81: the tour is the map page's, so closing this sheet on the
    // home starts nothing (the map page starts it on its own first visit, tour.ts);
    // "Show me around" at the sheet's foot goes to the map and replays it there.
    let tourAfter = false;

    // Behavior 128: where the launcher sits. Measured with it fixed (the class off for the
    // one synchronous read, the home's scroll put back after), against nav.home-ways over
    // the home's whole scroll range: the cards' top runs from top0 - range to top0 as the
    // home scrolls, so the fixed box meets them at some scroll s in [0, range] exactly
    // when top0 - b.bottom < s < bottom0 - b.top has a solution there — the open interval
    // (lo, hi) meets the closed [0, range] iff lo < range and hi > 0. The box is grown by
    // CLEAR first, so "not meeting" also leaves a visible gap. The first version tested
    // max(0, lo) < min(range, hi), which is never true when the home does not scroll
    // (range 0): Son's iPhone, 2026-10-18, 440×760 — fixed, over the fourth card's corner.
    const CLEAR = 12;
    let inline = $state(false);
    function placeLauncher() {
        const btn = launchEl;
        const home = btn?.closest<HTMLElement>('.home');
        const ways = home?.querySelector<HTMLElement>('.home-ways');
        if (!btn || !home || !ways) return;
        const kept = home.scrollTop;
        btn.classList.remove('inline');
        const b = btn.getBoundingClientRect();
        const w = ways.getBoundingClientRect();
        const range = Math.max(0, home.scrollHeight - home.clientHeight);
        const top0 = w.top + home.scrollTop;
        const bottom0 = w.bottom + home.scrollTop;
        const across = b.left - CLEAR < w.right && b.right + CLEAR > w.left;
        const lo = top0 - (b.bottom + CLEAR);
        const hi = bottom0 - (b.top - CLEAR);
        const meets = across && lo < range && hi > 0;
        btn.classList.toggle('inline', meets);
        home.scrollTop = kept;
        inline = meets;
    }
    $effect(() => {
        const home = launchEl?.closest<HTMLElement>('.home');
        if (!home) return;
        const ways = home.querySelector<HTMLElement>('.home-ways');
        const ro = new ResizeObserver(() => placeLauncher());
        ro.observe(home);
        if (ways) ro.observe(ways);
        window.addEventListener('resize', placeLauncher);
        // The news band's height reaches the home's top padding later, through
        // --home-news-h on the root's style (+layout.svelte): that moves the cards down
        // without resizing .home or the cards, so no ResizeObserver sees it (measured
        // 2026-10-18: 440×720 placed fixed over the fourth card). Fonts landing do the same.
        const mo = new MutationObserver(() => placeLauncher());
        mo.observe(document.documentElement, { attributes: true, attributeFilter: ['style'] });
        document.fonts?.ready.then(() => placeLauncher());
        return () => {
            mo.disconnect();
            ro.disconnect();
            window.removeEventListener('resize', placeLauncher);
        };
    });
    // The label's width changes with the language ("Giới thiệu" / "Introduction").
    $effect(() => {
        void $lang;
        tick().then(placeLauncher);
    });

    // The sheet draws its own three sections only: the facts page (/facts, behavior 122)
    // shows the KB's other fact docs (the economy, visa charges) and they stay off here.
    const ordered = $derived(
        docs.filter((d) => SECTION_ORDER.includes(d.slug)).sort((a, b) => SECTION_ORDER.indexOf(a.slug) - SECTION_ORDER.indexOf(b.slug))
    );

    const reduceMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

    // The facts can be briefly unreachable (a cold engine, or the site deployed ahead of
    // the API — measured 2026-10-09 on prod), and the sheet must not then lose two of its
    // three sections for good: an empty answer is retried a few times, and again on reopen.
    let loading = false;
    async function loadFacts(tries = 3) {
        if (loading || docs.length) return;
        loading = true;
        for (let i = 0; i < tries && !docs.length; i++) {
            if (i) await new Promise((r) => setTimeout(r, 1500 * i));
            docs = await getFacts();
        }
        loading = false;
    }

    onMount(() => {
        loadFacts();
        if (!introSeen()) open = true;
        // Behavior 135: a replaced KB re-reads the facts in place; an empty answer keeps them.
        return onContentChange(() => getFacts().then((d) => d.length && (docs = d)));
    });

    function closed() {
        open = false;
        arrived = true;
        const go = tourAfter;
        tourAfter = false;
        if (go) goto('/explore').then(startTour);
    }

    function replayTour() {
        tourAfter = true;
        collapse();
    }

    async function collapse() {
        if (!open || closing) return;
        markIntroSeen();
        if (reduceMotion() || !cardEl || !launchEl) return closed();
        // Drawn after the cards (behavior 128), the launcher may be scrolled out of view:
        // bring it in under the sheet first, so the card lands on a button one can see.
        if (inline) launchEl.scrollIntoView({ block: 'center' });
        // Fly the card's centre onto the launcher's centre while it shrinks and fades.
        const c = cardEl.getBoundingClientRect();
        const l = launchEl.getBoundingClientRect();
        cardEl.style.setProperty('--fly-x', `${l.left + l.width / 2 - (c.left + c.width / 2)}px`);
        cardEl.style.setProperty('--fly-y', `${l.top + l.height / 2 - (c.top + c.height / 2)}px`);
        closing = true;
        setTimeout(() => {
            closing = false;
            closed();
        }, 480);
    }

    async function reopen() {
        pulse = false;
        loadFacts();
        arrived = false;
        open = true;
        await tick();
        cardEl?.querySelector<HTMLElement>('.wl-close')?.focus();
    }

    // Smoothly bring a heading inside the sheet to its top (behavior 44); instant under
    // prefers-reduced-motion. Scrolls .wl-scroll itself, never the page behind it.
    function scrollToId(id: string) {
        const box = cardEl?.querySelector<HTMLElement>('.wl-scroll');
        const target = document.getElementById(id);
        if (!box || !target) return;
        const top = target.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop;
        box.scrollTo({ top, behavior: reduceMotion() ? 'auto' : 'smooth' });
    }

    function onKey(e: KeyboardEvent) {
        if (open && e.key === 'Escape') collapse();
    }
</script>

<svelte:window onkeydown={onKey} />

{#if open}
    <div class="wl-root" class:closing>
        <button type="button" class="wl-scrim" aria-label={$t('intro.close')} onclick={collapse}></button>
        <div class="wl-card" role="dialog" aria-modal="true" aria-labelledby="wl-title" bind:this={cardEl}>
            <button type="button" class="wl-close" aria-label={$t('intro.close')} onclick={collapse}>✕</button>
            <div class="wl-scroll">
                <header class="wl-hero">
                    <svg class="wl-stars" viewBox="0 0 32 32" aria-hidden="true">
                        <path d="M16 .5Q16 5.5 21 5.5Q16 5.5 16 10.5Q16 5.5 11 5.5Q16 5.5 16 .5Z" />
                        <path d="M25.5 10.3Q25.5 14.5 29.7 14.5Q25.5 14.5 25.5 18.7Q25.5 14.5 21.3 14.5Q25.5 14.5 25.5 10.3Z" />
                        <path d="M6.5 11.8Q6.5 16 10.7 16Q6.5 16 6.5 20.2Q6.5 16 2.3 16Q6.5 16 6.5 11.8Z" />
                        <path d="M16 21.5Q16 26.5 21 26.5Q16 26.5 16 31.5Q16 26.5 11 26.5Q16 26.5 16 21.5Z" />
                        <path class="gold" d="M20 17.2Q20 20 22.8 20Q20 20 20 22.8Q20 20 17.2 20Q20 20 20 17.2Z" />
                    </svg>
                    <span class="wl-eyebrow">{$t('intro.eyebrow')}</span>
                    <h2 id="wl-title">{$t('intro.title')}</h2>
                    <!-- Behavior 90: what it does and what it is not, on the first screen,
                         before any scroll; behavior 113: four things it does, Hành trình
                         second, and under them the line on whose rules both rest. -->
                    <div class="wl-is">
                        <div class="wl-is-col">
                            <p class="wl-is-head">{$t('intro.does')}</p>
                            <ul>
                                <li class="yes">{$t('intro.does.plan')}</li>
                                <li class="yes">{$t('intro.does.journey')}</li>
                                <li class="yes">{$t('intro.does.data')}</li>
                                <li class="yes">{$t('intro.does.news')}</li>
                            </ul>
                            <p class="wl-grounded">{$t('intro.does.grounded')}</p>
                        </div>
                        <div class="wl-is-col">
                            <p class="wl-is-head">{$t('intro.isnt')}</p>
                            <ul>
                                <li class="no">{$t('intro.isnt.listing')}</li>
                                <li class="no">{$t('intro.isnt.advice')}</li>
                            </ul>
                        </div>
                    </div>
                    <!-- The first screen leads to the platform's position in one tap and
                         invites the facts before the map (behavior 44). -->
                    <div class="wl-actions">
                        <button type="button" class="btn wl-what" onclick={() => scrollToId('wl-value-title')}
                            >{$t('intro.what')}</button
                        >
                        <button type="button" class="btn wl-cta" onclick={collapse}>{$t('intro.cta')} →</button>
                    </div>
                    <button
                        type="button"
                        class="wl-arrow"
                        onclick={() => scrollToId('wl-kb.facts.vietnamese-in-australia')}
                    >
                        <span>{$t('intro.facts.arrow')}</span>
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v15M5.5 12.5 12 19l6.5-6.5" /></svg>
                    </button>
                </header>

                {#if ordered.length}
                    <p class="wl-note">{$t('intro.sources.note')}</p>
                {/if}

                {#each ordered as doc (doc.slug)}
                    <section class="wl-section" aria-labelledby="wl-{doc.slug}">
                        <h3 id="wl-{doc.slug}">{pick(doc.title, $lang)}</h3>
                        <FactCards {doc} />
                    </section>
                {/each}

                <!-- Behavior 90: the long form of the first screen — what you can do here
                     (two-up on a wide screen), then what it is not. -->
                <section class="wl-value" aria-labelledby="wl-value-title">
                    <h3 id="wl-value-title">{$t('intro.value.title')}</h3>
                    <h4 class="wl-value-sub">{$t('intro.value.does')}</h4>
                    <ul>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 18h16M6 18V9l6-4 6 4v9M10 18v-5h4v5" /></svg></span>
                            <strong>{$t('intro.value.plan.title')}</strong>
                            <span>{$t('intro.value.plan.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="m4 6 1.5 1.5L8 5M4 12l1.5 1.5L8 11M4 18l1.5 1.5L8 17M11 6h9M11 12h9M11 18h9" /></svg></span>
                            <strong>{$t('intro.value.journey.title')}</strong>
                            <span>{$t('intro.value.journey.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Z" /><path d="M9 4v14M15 6v14" /></svg></span>
                            <strong>{$t('intro.value.data.title')}</strong>
                            <span>{$t('intro.value.data.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="4" y="5" width="16" height="14" rx="2" /><path d="M8 9h8M8 13h8M8 16.5h5" /></svg></span>
                            <strong>{$t('intro.value.news.title')}</strong>
                            <span>{$t('intro.value.news.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico wl-ico-ai" aria-hidden="true"><Sparkle size="1.1rem" /></span>
                            <strong>{$t('intro.value.ai.title')}</strong>
                            <span>{$t('intro.value.ai.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="3.5" /><path d="M5 20c.8-3.8 3.6-6 7-6s6.2 2.2 7 6" /></svg></span>
                            <strong>{$t('intro.value.you.title')}</strong>
                            <span>{$t('intro.value.you.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M5 12.5 10 17l9-10" /></svg></span>
                            <strong>{$t('intro.value.cited.title')}</strong>
                            <span>{$t('intro.value.cited.body')}</span>
                        </li>
                    </ul>
                    <h4 class="wl-value-sub">{$t('intro.value.isnt')}</h4>
                    <ul class="wl-value-not">
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 11 12 4l8 7M6 9.5V20h12V9.5" /><path d="m4 20 16-16" /></svg></span>
                            <strong>{$t('intro.value.listing.title')}</strong>
                            <span>{$t('intro.value.listing.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5" /><path d="M12 11v5.5M12 7.6v.1" /></svg></span>
                            <strong>{$t('intro.value.info.title')}</strong>
                            <span>{$t('intro.value.info.body')}</span>
                        </li>
                    </ul>
                </section>

                <footer class="wl-foot">
                    <span>{$t('intro.cta.hint')}</span>
                    <button type="button" class="btn btn-primary" onclick={collapse}>{$t('intro.cta')}</button>
                    <button type="button" class="wl-replay" onclick={replayTour}>{$t('tour.replay')}</button>
                </footer>
                <p class="wl-disclaimer">{$t('disclaimer.asic')}</p>
            </div>
        </div>
    </div>
{/if}

<button
    type="button"
    class="wl-launch"
    class:waiting={open}
    class:inline
    class:arrived
    class:pulse
    aria-label={$t('intro.button.aria')}
    aria-hidden={open}
    tabindex={open ? -1 : 0}
    bind:this={launchEl}
    onclick={reopen}
>
    <span class="wl-launch-ico" aria-hidden="true">
        <svg viewBox="0 0 24 24">
            <rect class="b1" x="4" y="12" width="4" height="8" rx="1" />
            <rect class="b2" x="10" y="8" width="4" height="12" rx="1" />
            <rect class="b3" x="16" y="4" width="4" height="16" rx="1" />
        </svg>
    </span>
    <span class="wl-launch-label">{$t('intro.button')}</span>
</button>

<style>
    .wl-root {
        position: fixed;
        inset: 0;
        z-index: 80;
        display: flex;
        align-items: flex-end;
        justify-content: center;
    }
    .wl-scrim {
        position: absolute;
        inset: 0;
        border: none;
        padding: 0;
        background: var(--scrim);
        backdrop-filter: blur(3px);
        -webkit-backdrop-filter: blur(3px);
        cursor: default;
        animation: wl-fade var(--t-med) var(--ease);
        transition: opacity 0.4s var(--ease);
    }
    .wl-card {
        --fly-x: 0px;
        --fly-y: 0px;
        position: relative;
        width: 100%;
        max-height: var(--sheet-h); /* the one sheet height (app.css, behavior 66) */
        display: flex;
        flex-direction: column;
        background: var(--bg);
        border-radius: var(--radius-lg) var(--radius-lg) 0 0;
        box-shadow: var(--shadow-3);
        overflow: hidden;
        animation: wl-rise 0.42s cubic-bezier(0.2, 0.8, 0.2, 1);
        transition:
            transform 0.46s cubic-bezier(0.6, 0, 0.3, 1),
            opacity 0.46s ease-in,
            border-radius 0.46s ease;
    }
    .closing .wl-card {
        transform: translate(var(--fly-x), var(--fly-y)) scale(0.04);
        opacity: 0;
        border-radius: 50%;
    }
    .closing .wl-scrim {
        opacity: 0;
    }
    @keyframes wl-rise {
        from {
            opacity: 0;
            transform: translateY(2rem) scale(0.98);
        }
    }
    @keyframes wl-fade {
        from {
            opacity: 0;
        }
    }
    .wl-scroll {
        overflow-y: auto;
        overscroll-behavior: contain;
    }
    .wl-close {
        position: absolute;
        top: var(--sp-3);
        right: var(--sp-3);
        z-index: 2;
        display: grid;
        place-items: center;
        width: 2.25rem;
        height: 2.25rem;
        border: none;
        border-radius: var(--radius-pill);
        /* Readable over the green hero and, once that scrolls away, the light facts. */
        background: var(--scrim);
        backdrop-filter: blur(6px);
        color: var(--on-dark);
        font-size: var(--fs-sm);
        cursor: pointer;
        transition: background var(--t-fast) var(--ease);
    }
    .wl-close:hover {
        background: var(--ink);
    }
    .wl-close:focus-visible,
    .wl-cta:focus-visible,
    .wl-what:focus-visible,
    .wl-arrow:focus-visible {
        outline: none;
        box-shadow: var(--ring);
    }

    /* --- hero -------------------------------------------------------------- */
    .wl-hero {
        position: relative;
        overflow: hidden;
        padding: var(--sp-6) var(--sp-5) var(--sp-6);
        background: var(--brand-gradient);
        color: var(--on-dark);
    }
    .wl-stars {
        position: absolute;
        right: -2.5rem;
        top: -2.5rem;
        width: 9rem;
        height: 9rem;
        opacity: 0.7;
        fill: var(--on-dark-faint);
        pointer-events: none;
    }
    .wl-stars .gold {
        fill: var(--gold-mark);
        opacity: 0.85;
    }
    .wl-eyebrow {
        display: inline-block;
        font-size: var(--fs-2xs);
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: var(--gold-mark);
    }
    .wl-hero h2 {
        position: relative;
        margin: var(--sp-2) 0 var(--sp-3);
        max-width: 32rem;
        font-size: clamp(1.6rem, 4.6vw, 2.3rem);
        font-weight: 800;
        line-height: 1.12;
        letter-spacing: -0.03em;
        text-wrap: balance;
        color: var(--ink-inverse);
    }
    .wl-is {
        position: relative;
        display: grid;
        gap: var(--sp-3);
        margin: 0 0 var(--sp-5);
        max-width: 44rem;
    }
    .wl-is-head {
        margin: 0 0 var(--sp-1);
        font-size: var(--fs-xs);
        font-weight: 700;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        color: var(--gold-mark);
    }
    .wl-is ul {
        list-style: none;
        margin: 0;
        padding: 0;
        display: grid;
        gap: 0.2rem;
    }
    .wl-is li {
        position: relative;
        padding-left: 1.5rem;
        font-size: var(--fs-md);
        line-height: 1.4;
        color: var(--ink-inverse);
    }
    .wl-is li::before {
        position: absolute;
        left: 0;
        top: 0;
        font-weight: 800;
    }
    .wl-is li.yes::before {
        content: '✓';
        color: var(--gold-mark);
    }
    .wl-grounded {
        margin: var(--sp-2) 0 0;
        max-width: 38rem;
        font-size: var(--fs-sm);
        line-height: 1.45;
        color: var(--on-dark);
    }
    .wl-is li.no::before {
        content: '✕';
        color: var(--on-dark);
    }
    .wl-actions {
        position: relative;
        display: flex;
        flex-wrap: wrap;
        gap: var(--sp-3);
    }
    .wl-what {
        background: transparent;
        color: var(--ink-inverse);
        font-weight: 700;
        border: 1px solid var(--on-dark-faint);
    }
    .wl-what:hover {
        background: var(--on-dark-faint);
    }
    .wl-arrow {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--sp-1);
        margin: var(--sp-5) auto 0;
        padding: var(--sp-2) var(--sp-3);
        border: none;
        border-radius: var(--radius-sm);
        background: transparent;
        color: var(--on-dark);
        font: inherit;
        font-size: var(--fs-xs);
        font-weight: 600;
        text-align: center;
        cursor: pointer;
    }
    .wl-arrow:hover {
        color: var(--ink-inverse);
    }
    .wl-arrow svg {
        width: 1.5rem;
        height: 1.5rem;
        fill: none;
        stroke: var(--gold-mark);
        stroke-width: 2.2;
        stroke-linecap: round;
        stroke-linejoin: round;
        animation: wl-nudge 1.6s ease-in-out infinite;
    }
    @keyframes wl-nudge {
        0%,
        100% {
            transform: translateY(0);
        }
        50% {
            transform: translateY(0.4rem);
        }
    }
    .wl-cta {
        position: relative;
        background: var(--surface);
        color: var(--accent-press);
        font-weight: 700;
        box-shadow: var(--shadow-2);
    }
    .wl-cta:hover {
        background: var(--accent-soft);
    }

    /* --- facts ------------------------------------------------------------- */
    .wl-note {
        margin: var(--sp-5) var(--sp-5) 0;
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .wl-section {
        padding: var(--sp-4) var(--sp-5) 0;
    }
    .wl-section h3,
    .wl-value h3 {
        margin: var(--sp-3) 0 var(--sp-3);
        font-size: var(--fs-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--ink);
    }
    /* --- value ------------------------------------------------------------- */
    .wl-value {
        margin: var(--sp-5) var(--sp-5) 0;
        padding: var(--sp-4) var(--sp-5) var(--sp-5);
        border-radius: var(--radius);
        background: var(--accent-soft);
        border: 1px solid var(--accent-soft-2);
    }
    .wl-value-sub {
        margin: var(--sp-4) 0 var(--sp-3);
        font-size: var(--fs-xs);
        font-weight: 700;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        color: var(--accent-press);
    }
    .wl-value ul {
        list-style: none;
        margin: 0;
        padding: 0;
        display: grid;
        gap: var(--sp-4);
    }
    .wl-value li {
        display: grid;
        grid-template-columns: 2.5rem 1fr;
        column-gap: var(--sp-3);
        row-gap: 0.15rem;
        align-content: start;
        font-size: var(--fs-sm);
        color: var(--ink-2);
        line-height: 1.5;
    }
    .wl-value strong {
        color: var(--ink);
        font-size: var(--fs-md);
    }
    .wl-value li > span:last-child {
        grid-column: 2;
    }
    .wl-ico {
        grid-row: span 2;
        display: grid;
        place-items: center;
        width: 2.5rem;
        height: 2.5rem;
        border-radius: var(--radius-sm);
        background: var(--surface);
        box-shadow: var(--shadow-1);
    }
    /* Behavior 59: the assistant's sparkle is filled (Sparkle.svelte), not stroked. */
    .wl-ico-ai {
        color: var(--accent);
    }
    .wl-ico svg {
        width: 1.35rem;
        height: 1.35rem;
        fill: none;
        stroke: var(--accent);
        stroke-width: 2;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
    .wl-foot {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: var(--sp-3);
        padding: var(--sp-5);
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    /* "Show me around" (behavior 52): a quiet link on its own line under the CTA. */
    .wl-replay {
        flex-basis: 100%;
        padding: 0;
        border: none;
        background: none;
        font: inherit;
        color: var(--accent);
        text-align: left;
        text-decoration: underline;
        text-underline-offset: 2px;
        cursor: pointer;
    }
    .wl-replay:hover {
        color: var(--accent-hover);
    }

    /* The standing disclaimer closes the sheet (behavior 44). */
    .wl-disclaimer {
        margin: 0;
        padding: 0 var(--sp-5) var(--sp-5);
        font-size: var(--fs-xs);
        line-height: 1.5;
        color: var(--muted);
    }

    /* --- launcher ----------------------------------------------------------- */
    .wl-launch {
        position: fixed;
        right: 0.75rem;
        bottom: calc(4.5rem + env(safe-area-inset-bottom, 0px));
        z-index: 20;
        display: inline-flex;
        align-items: center;
        gap: var(--sp-2);
        padding: 0.3rem 0.85rem 0.3rem 0.3rem;
        border: none;
        border-radius: var(--radius-pill);
        background: var(--surface);
        color: var(--ink);
        font-size: var(--fs-sm);
        font-weight: 700;
        box-shadow: var(--shadow-2);
        cursor: pointer;
        transition:
            transform var(--t-fast) var(--ease),
            box-shadow var(--t-fast) var(--ease);
    }
    /* Behavior 128: after the cards, at the right edge of their column (64rem, centred),
       in the home's flow and its scroll; z-index auto keeps it under the header and band. */
    .wl-launch.inline {
        position: relative;
        right: auto;
        bottom: auto;
        z-index: auto;
        display: flex;
        width: fit-content;
        margin: var(--sp-4) max(0px, calc((100% - 64rem) / 2)) 0 auto;
    }
    .wl-launch:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-3);
    }
    .wl-launch:focus-visible {
        outline: none;
        box-shadow: var(--ring), var(--shadow-2);
    }
    .wl-launch.waiting {
        visibility: hidden;
    }
    .wl-launch.arrived {
        animation: wl-pop 0.5s cubic-bezier(0.3, 1.6, 0.5, 1);
    }
    @keyframes wl-pop {
        from {
            transform: scale(0.4);
        }
    }
    .wl-launch-ico {
        position: relative;
        display: grid;
        place-items: center;
        width: 2.1rem;
        height: 2.1rem;
        border-radius: 50%;
        background: var(--brand-gradient);
        box-shadow: var(--brand-glow);
    }
    .wl-launch-ico svg {
        width: 1.15rem;
        height: 1.15rem;
        fill: var(--ink-inverse);
    }
    .wl-launch-ico .b3 {
        fill: var(--gold-mark);
    }
    /* The pulse (behavior 50) fades a light-green layer behind the label in and out.
       Only its opacity animates, so the compositor runs it without repainting the
       button each frame (behavior 51); the old box-shadow ring repainted every frame. */
    .wl-launch::before {
        content: '';
        position: absolute;
        inset: 0;
        border-radius: inherit;
        background: var(--accent-soft-2);
        opacity: 0;
        pointer-events: none;
    }
    .wl-launch > * {
        position: relative;
    }
    .wl-launch.pulse::before {
        animation: wl-pulse 2.4s ease-in-out infinite;
    }
    @keyframes wl-pulse {
        0%,
        100% {
            opacity: 0;
        }
        50% {
            opacity: 1;
        }
    }

    /* --- wider screens: a centred card, facts two-up ------------------------ */
    @media (min-width: 48rem) {
        .wl-root {
            align-items: center;
        }
        .wl-card {
            width: min(94%, 62rem);
            max-height: 90%;
            border-radius: var(--radius-lg);
        }
        .wl-hero {
            padding: var(--sp-8) var(--sp-6) var(--sp-6);
        }
        .wl-stars {
            width: 18rem;
            height: 18rem;
            right: 1rem;
            top: -2rem;
            opacity: 1;
        }
        .wl-note,
        .wl-section,
        .wl-disclaimer,
        .wl-foot {
            padding-left: var(--sp-6);
            padding-right: var(--sp-6);
        }
        .wl-note {
            margin-left: 0;
            margin-right: 0;
        }
        .wl-value {
            margin-left: var(--sp-6);
            margin-right: var(--sp-6);
        }
        /* Behavior 90: six things you can do, two-up; the two it is not, two-up. */
        .wl-value ul {
            grid-template-columns: repeat(2, 1fr);
        }
        .wl-is {
            grid-template-columns: 1.2fr 1fr;
            gap: var(--sp-6);
        }
    }

    @media (prefers-reduced-motion: reduce) {
        .wl-card,
        .wl-scrim,
        .wl-launch,
        .wl-launch.arrived,
        .wl-launch.pulse::before,
        .wl-arrow svg {
            animation: none;
            transition: none;
        }
    }
</style>
