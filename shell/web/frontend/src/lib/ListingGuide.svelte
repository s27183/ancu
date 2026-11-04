<script lang="ts">
    // Bilingual -> a buyer new to Australian listing sites reads one in Vietnamese -> the web
    // frontend -> the listing sheet's reading guide
    // Goal:      behavior 154 (Son 2026-11-04: «many vietnamese clients are new to listing
    //            sites in Australia … where to look for key info (property type, price, selling
    //            option like offer/auction, bathrooms, bedrooms, garage)»): under the listing
    //            sheet's links, two example listing cards with red arrows to each part, a
    //            numbered explanation of each, then the property types.
    // Invariant: the cards are our own drawings, never a site's screenshot, logo, photo or
    //            colours, and are marked as examples with invented addresses ("No property
    //            scraping"; the independence sentence). Their words stay in English, as the
    //            sites show them; the labels and explanations follow the visitor's language.
    //            The auction example is in Victoria, where a price range within 10% is what an
    //            agent advertises (kb.facts.listing-transparency); a price line claims no more
    //            than "the agent's advertised price; each state sets its own rules". The type
    //            lines are kb.property.types' copy word for word (unit/listingGuide.test.ts).
    // Capability: each card is one SVG (viewBox 340 × 254) that scales to the sheet's width;
    //            its text is SVG text in fixed positions, so every label fits at any width.
    import { t, type MessageKey } from '$lib/i18n';
    import Termed from '$lib/Termed.svelte';

    type Part = 'method' | 'price' | 'address' | 'beds' | 'baths' | 'cars' | 'type' | 'inspect';
    const PARTS: Part[] = ['method', 'price', 'address', 'beds', 'baths', 'cars', 'type', 'inspect'];

    // The card's lines, at fixed positions: each part's arrow ends at its point (tx, ty).
    interface Card {
        id: 'a' | 'b';
        heading: MessageKey;
        lines: { text: string; x: number; y: number; bold?: boolean; size?: number }[];
        icons: { beds: string; baths: string; cars: string };
        target: Record<Part, [number, number]>;
        explain: Record<Part, MessageKey>;
    }
    const ICON_Y = 186;
    // Each tip ends just past its text, or on top of its icon, so no arrow covers a word or
    // crosses another icon; the car's comes in from the right to its count.
    const ICON_TIPS = { beds: [21, ICON_Y - 17], baths: [61, ICON_Y - 17], cars: [124, ICON_Y - 3] } as Record<'beds' | 'baths' | 'cars', [number, number]>;
    const shared = { beds: 'guide.beds', baths: 'guide.baths', cars: 'guide.cars', type: 'guide.type', inspect: 'guide.inspect' } as const;
    const CARDS: Card[] = [
        {
            id: 'a',
            heading: 'guide.auction',
            lines: [
                { text: 'Auction Sat 14 Nov', x: 14, y: 98, bold: true },
                { text: 'Price guide $620,000 – $680,000', x: 14, y: 118, size: 10.5 },
                { text: '12/34 Example Street,', x: 14, y: 140 },
                { text: 'Richmond VIC 3121', x: 14, y: 154 },
                { text: 'Apartment', x: 14, y: 210 },
                { text: 'Inspection Sat 10:00am', x: 14, y: 230 }
            ],
            icons: { beds: '2', baths: '1', cars: '1' },
            target: { method: [126, 94], price: [184, 114], address: [130, 136], ...ICON_TIPS, type: [72, 206], inspect: [140, 226] },
            explain: { method: 'guide.a.method', price: 'guide.a.price', address: 'guide.a.address', ...shared }
        },
        {
            id: 'b',
            heading: 'guide.offers',
            lines: [
                { text: 'Offers from $825,000', x: 14, y: 100, bold: true, size: 12 },
                { text: '56 Sample Road,', x: 14, y: 122 },
                { text: 'Sunnybank QLD 4109', x: 14, y: 136 },
                { text: 'Townhouse', x: 14, y: 210 },
                { text: 'Inspection Sat 10:00am', x: 14, y: 230 }
            ],
            icons: { beds: '3', baths: '2', cars: '2' },
            target: { method: [34, 87], price: [148, 97], address: [102, 118], ...ICON_TIPS, type: [74, 206], inspect: [140, 226] },
            explain: { method: 'guide.b.method', price: 'guide.b.price', address: 'guide.b.address', ...shared }
        }
    ];
    // The labels' column at the right, top to bottom; each arrow runs from its label to its part.
    const LABEL_X = 222;
    const LABEL_Y: Record<Part, number> = { method: 84, price: 108, address: 134, beds: 152, baths: 170, cars: 196, type: 216, inspect: 236 };

    const TYPES = ['house', 'attached', 'apartment', 'land'] as const;
</script>

<section class="guide" aria-labelledby="guide-title">
    <h3 id="guide-title" class="guide-title">{$t('guide.title')}</h3>
    {#each CARDS as c (c.id)}
        <figure class="guide-card" data-card={c.id}>
            <figcaption class="guide-cap"><strong>{$t(c.heading)}</strong> · {$t('guide.example')}</figcaption>
            <svg viewBox="0 0 340 254" role="img" aria-label={`${$t(c.heading)} · ${$t('guide.example')}`}>
                <defs>
                    <marker id="guide-arrow-{c.id}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                        <path d="M0 0 10 5 0 10z" class="guide-red-fill" />
                    </marker>
                </defs>
                <rect x="4" y="4" width="186" height="238" rx="8" class="guide-sheet" />
                <!-- a plain picture block: no site's photo -->
                <rect x="10" y="10" width="174" height="66" rx="5" class="guide-photo" />
                <path d="M78 56 97 40 116 56 M84 51v15h26V51" class="guide-photo-glyph" />
                {#each c.lines as l, i (i)}
                    <text x={l.x} y={l.y} class="guide-line" class:bold={l.bold} font-size={l.size ?? 11}>{l.text}</text>
                {/each}
                <!-- bed, bath, car, each with its count -->
                <g class="guide-icon" transform="translate(14 {ICON_Y - 12})">
                    <path d="M1 12V3M1 9h14v3M15 9V7a2 2 0 0 0-2-2H7v4" />
                    <circle cx="4" cy="6" r="1.6" />
                </g>
                <text x="34" y={ICON_Y} class="guide-line bold">{c.icons.beds}</text>
                <g class="guide-icon" transform="translate(54 {ICON_Y - 12})">
                    <path d="M1 7h14v2a4 4 0 0 1-4 4H5a4 4 0 0 1-4-4V7M3 7V3a2 2 0 0 1 4 0" />
                </g>
                <text x="74" y={ICON_Y} class="guide-line bold">{c.icons.baths}</text>
                <g class="guide-icon" transform="translate(94 {ICON_Y - 12})">
                    <path d="M1 10V7l2-4h10l2 4v3H1zM3 10v2M13 10v2" />
                    <circle cx="4.5" cy="7.5" r="0.8" /><circle cx="11.5" cy="7.5" r="0.8" />
                </g>
                <text x="114" y={ICON_Y} class="guide-line bold">{c.icons.cars}</text>
                {#each PARTS as p, k (p)}
                    <line
                        x1={LABEL_X - 3}
                        y1={LABEL_Y[p] - 4}
                        x2={c.target[p][0]}
                        y2={c.target[p][1]}
                        class="guide-arrow"
                        marker-end="url(#guide-arrow-{c.id})"
                    />
                    <circle cx={LABEL_X + 6} cy={LABEL_Y[p] - 4} r="6" class="guide-red-fill" />
                    <text x={LABEL_X + 6} y={LABEL_Y[p] - 0.6} class="guide-num" text-anchor="middle">{k + 1}</text>
                    <text x={LABEL_X + 16} y={LABEL_Y[p]} class="guide-label" data-part={p}>{$t(`guide.label.${p}`)}</text>
                {/each}
            </svg>
            <ol class="guide-explain">
                {#each PARTS as p (p)}
                    <li>{$t(c.explain[p])}</li>
                {/each}
            </ol>
        </figure>
    {/each}
    <a class="guide-market" href="/market">{$t('guide.market')} →</a>

    <h3 class="guide-title">{$t('types.title')}</h3>
    <dl class="types">
        {#each TYPES as k (k)}
            <div class="type">
                <dt lang="en">{$t(`types.${k}.names`)}</dt>
                <dd>{$t(`types.${k}`)}</dd>
            </div>
        {/each}
    </dl>
    <p class="types-note"><Termed text={$t('types.strata')} /></p>
    <p class="types-src">
        {$t('types.source')}
        <a href="https://www.abs.gov.au/census/guide-census-data/census-dictionary/2026/variables-topic/housing/dwelling-structure-strd" target="_blank" rel="noopener noreferrer">ABS ↗</a>
    </p>
</section>

<style>
    .guide {
        display: flex;
        flex-direction: column;
        gap: var(--sp-3);
        margin-top: var(--sp-2);
        padding-top: var(--sp-3);
        border-top: 1px solid var(--border);
    }
    .guide-title {
        margin: 0;
        font-size: var(--fs-md);
        font-weight: 700;
        color: var(--ink);
    }
    .guide-card {
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: var(--sp-2);
    }
    .guide-cap {
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .guide-cap strong {
        color: var(--ink);
    }
    svg {
        display: block;
        width: 100%;
        max-width: 26rem;
        height: auto;
    }
    .guide-sheet {
        fill: var(--surface);
        stroke: var(--border);
    }
    .guide-photo {
        fill: var(--surface-2, var(--accent-soft));
    }
    .guide-photo-glyph,
    .guide-icon {
        fill: none;
        stroke: var(--muted);
        stroke-width: 1.4;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
    .guide-line {
        fill: var(--ink);
        font-family: inherit;
    }
    .guide-line.bold {
        font-weight: 700;
    }
    .guide-arrow {
        stroke: var(--danger);
        stroke-width: 1.3;
    }
    .guide-red-fill {
        fill: var(--danger);
    }
    .guide-num {
        fill: #fff;
        font-size: 8px;
        font-weight: 700;
    }
    .guide-label {
        fill: var(--danger);
        font-size: 10.5px;
        font-weight: 700;
    }
    .guide-explain {
        margin: 0;
        padding-left: 1.4rem;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    .guide-explain li::marker {
        color: var(--danger);
        font-weight: 700;
    }
    .guide-market {
        font-size: var(--fs-sm);
        font-weight: 600;
        color: var(--accent);
    }
    .types {
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: var(--sp-2);
    }
    .type dt {
        font-weight: 700;
        color: var(--ink);
    }
    .type dd {
        margin: 0;
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    .types-note,
    .types-src {
        margin: 0;
        font-size: var(--fs-sm);
        color: var(--ink-2);
    }
    .types-src {
        font-size: var(--fs-xs);
        color: var(--muted);
    }
    .types-src a {
        color: var(--accent);
    }
</style>
