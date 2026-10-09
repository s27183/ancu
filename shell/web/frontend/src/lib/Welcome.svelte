<script lang="ts">
    // The first-visit sheet (behavior 42): opens by itself the first time this browser
    // visits, says in two sentences what the product does, draws the KB's cited facts —
    // where Vietnamese buyers stand, then why Australian property — and what the product
    // adds on top of them. Closing it (✕, scrim, Escape or the CTA) flies the card into a
    // small animated launcher at the bottom-right, which reopens it; the browser then
    // remembers it was seen (facts.ts, introSeen). Under prefers-reduced-motion nothing
    // flies or pulses — it simply closes and the launcher sits still.
    import { onMount, tick } from 'svelte';
    import { lang } from '$lib/stores/lang';
    import { t } from '$lib/i18n';
    import FactVisual from '$lib/FactVisual.svelte';
    import {
        type FactDoc,
        SECTION_ORDER,
        formatAsOf,
        getFacts,
        introSeen,
        markIntroSeen,
        pick,
        publisher
    } from '$lib/facts';

    let open = $state(false);
    let closing = $state(false);
    let arrived = $state(false);
    let docs = $state<FactDoc[]>([]);
    let cardEl = $state<HTMLElement | null>(null);
    let launchEl = $state<HTMLButtonElement | null>(null);

    const ordered = $derived(
        [...docs].sort((a, b) => SECTION_ORDER.indexOf(a.slug) - SECTION_ORDER.indexOf(b.slug))
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
    });

    async function collapse() {
        if (!open || closing) return;
        markIntroSeen();
        if (reduceMotion() || !cardEl || !launchEl) {
            open = false;
            arrived = true;
            return;
        }
        // Fly the card's centre onto the launcher's centre while it shrinks and fades.
        const c = cardEl.getBoundingClientRect();
        const l = launchEl.getBoundingClientRect();
        cardEl.style.setProperty('--fly-x', `${l.left + l.width / 2 - (c.left + c.width / 2)}px`);
        cardEl.style.setProperty('--fly-y', `${l.top + l.height / 2 - (c.top + c.height / 2)}px`);
        closing = true;
        setTimeout(() => {
            open = false;
            closing = false;
            arrived = true;
        }, 480);
    }

    async function reopen() {
        loadFacts();
        arrived = false;
        open = true;
        await tick();
        cardEl?.querySelector<HTMLElement>('.wl-close')?.focus();
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
                    <p class="wl-lede">{$t('intro.lede')}</p>
                    <button type="button" class="btn wl-cta" onclick={collapse}>{$t('intro.cta')} →</button>
                </header>

                {#if ordered.length}
                    <p class="wl-note">{$t('intro.sources.note')}</p>
                {/if}

                {#each ordered as doc (doc.slug)}
                    <section class="wl-section" aria-labelledby="wl-{doc.slug}">
                        <h3 id="wl-{doc.slug}">{pick(doc.title, $lang)}</h3>
                        <div class="wl-grid">
                            {#each doc.facts as fact (fact.id)}
                                {@const src = doc.sources[fact.source]}
                                <article
                                    class="wl-fact"
                                    class:wide={fact.visual === 'bars' || fact.visual === 'growth'}
                                    data-fact={fact.id}
                                >
                                    <h4>{pick(fact.headline, $lang)}</h4>
                                    <FactVisual {fact} />
                                    <p class="wl-caption">{pick(fact.caption, $lang)}</p>
                                    <p class="wl-src">
                                        {$t('intro.source')}:
                                        {#if src?.url}<a href={src.url} target="_blank" rel="noopener noreferrer"
                                                >{publisher(src, $lang)}</a
                                            >{/if}
                                        · {formatAsOf(fact.as_of, $lang)}
                                    </p>
                                </article>
                            {/each}
                        </div>
                    </section>
                {/each}

                <section class="wl-value" aria-labelledby="wl-value-title">
                    <h3 id="wl-value-title">{$t('intro.value.title')}</h3>
                    <ul>
                        <li>
                            <span class="wl-ico" aria-hidden="true">
                                <svg viewBox="0 0 24 24"><path d="M4 18h16M6 18V9l6-4 6 4v9M10 18v-5h4v5" /></svg>
                            </span>
                            <strong>{$t('intro.value.plan.title')}</strong>
                            <span>{$t('intro.value.plan.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true">
                                <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="3.5" /><path d="M5 20c.8-3.8 3.6-6 7-6s6.2 2.2 7 6" /></svg>
                            </span>
                            <strong>{$t('intro.value.you.title')}</strong>
                            <span>{$t('intro.value.you.body')}</span>
                        </li>
                        <li>
                            <span class="wl-ico" aria-hidden="true">
                                <svg viewBox="0 0 24 24"><path d="M5 12.5 10 17l9-10" /></svg>
                            </span>
                            <strong>{$t('intro.value.cited.title')}</strong>
                            <span>{$t('intro.value.cited.body')}</span>
                        </li>
                    </ul>
                </section>

                <footer class="wl-foot">
                    <span>{$t('intro.cta.hint')}</span>
                    <button type="button" class="btn btn-primary" onclick={collapse}>{$t('intro.cta')}</button>
                </footer>
            </div>
        </div>
    </div>
{/if}

<button
    type="button"
    class="wl-launch"
    class:waiting={open}
    class:arrived
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
        max-height: 94%;
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
    .wl-src a:focus-visible {
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
    .wl-lede {
        position: relative;
        margin: 0 0 var(--sp-5);
        max-width: 38rem;
        font-size: var(--fs-md);
        line-height: 1.6;
        color: var(--on-dark);
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
    .wl-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: var(--sp-3);
    }
    .wl-fact {
        display: flex;
        flex-direction: column;
        gap: var(--sp-3);
        padding: var(--sp-4);
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        box-shadow: var(--shadow-1);
    }
    .wl-fact h4 {
        margin: 0;
        font-size: var(--fs-md);
        font-weight: 700;
        line-height: 1.35;
        letter-spacing: -0.01em;
        color: var(--ink);
        text-wrap: balance;
    }
    .wl-caption {
        margin: 0;
        font-size: var(--fs-xs);
        color: var(--ink-2);
    }
    .wl-src {
        margin: auto 0 0;
        padding-top: var(--sp-2);
        border-top: 1px solid var(--border);
        font-size: var(--fs-2xs);
        color: var(--muted);
    }
    .wl-src a {
        color: var(--accent);
        font-weight: 600;
        text-decoration: none;
        border-radius: 2px;
    }
    .wl-src a:hover {
        text-decoration: underline;
        text-underline-offset: 2px;
    }

    /* --- value ------------------------------------------------------------- */
    .wl-value {
        margin: var(--sp-5) var(--sp-5) 0;
        padding: var(--sp-4) var(--sp-5) var(--sp-5);
        border-radius: var(--radius);
        background: var(--accent-soft);
        border: 1px solid var(--accent-soft-2);
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

    /* --- launcher ----------------------------------------------------------- */
    .wl-launch {
        position: fixed;
        right: 0.75rem;
        bottom: calc(3rem + env(safe-area-inset-bottom, 0px));
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
    .wl-launch-ico::after {
        content: '';
        position: absolute;
        inset: 0;
        border-radius: 50%;
        box-shadow: 0 0 0 0 var(--accent);
        animation: wl-ring 3.2s ease-out infinite;
    }
    @keyframes wl-ring {
        0% {
            box-shadow: 0 0 0 0 var(--accent-soft-2);
            opacity: 0.9;
        }
        45%,
        100% {
            box-shadow: 0 0 0 0.75rem var(--accent-soft-2);
            opacity: 0;
        }
    }
    .wl-launch-ico svg {
        width: 1.15rem;
        height: 1.15rem;
        fill: var(--ink-inverse);
    }
    .wl-launch-ico rect {
        transform-box: fill-box;
        transform-origin: bottom;
        animation: wl-bar 2.4s ease-in-out infinite;
    }
    .wl-launch-ico .b2 {
        animation-delay: 0.25s;
    }
    .wl-launch-ico .b3 {
        animation-delay: 0.5s;
        fill: var(--gold-mark);
    }
    @keyframes wl-bar {
        0%,
        100% {
            transform: scaleY(1);
        }
        50% {
            transform: scaleY(0.55);
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
        .wl-value ul {
            grid-template-columns: repeat(3, 1fr);
        }
        .wl-grid {
            grid-template-columns: repeat(2, 1fr);
        }
        .wl-fact.wide {
            grid-column: 1 / -1;
        }
    }

    @media (prefers-reduced-motion: reduce) {
        .wl-card,
        .wl-scrim,
        .wl-launch,
        .wl-launch.arrived,
        .wl-launch-ico::after,
        .wl-launch-ico rect {
            animation: none;
            transition: none;
        }
    }
</style>
