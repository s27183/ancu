<script lang="ts">
    // Honest-partial -> the suburb data the goal names -> the web frontend -> the listings sheet
    // Goal:      behavior 150 — from a suburb's sheet, the homes for sale there on the listing
    //            sites a buyer already uses, behind one line saying they are other companies'
    //            sites with no tie to Mai An Cư (the goal's independence sentence).
    // Invariant: we link out only (listingLinks.ts builds every URL; "No property scraping"):
    //            nothing here frames or fetches those pages, and the opened page gets no
    //            handle on ours — window.opener null (noopener, noreferrer) both ways.
    //            Behavior 153: before the links, that their prices are in AUD (AudNote).
    // Capability: a phone (below 48rem, sheetMotion's WIDE) follows a plain <a target=_blank>
    //            to a new tab; a desktop opens a smaller popup window over the app through
    //            window.open's `popup` feature (Chrome 156, behavior 150 Expect 5); where a
    //            browser ignores `popup` it is still the same link in a tab.
    import Modal from '$lib/Modal.svelte';
    import AudNote from '$lib/AudNote.svelte';
    import { t } from '$lib/i18n';
    import { listingLinks, type ListingLink } from '$lib/listingLinks';
    import type { Suburb } from '$lib/api';

    let { suburb, onClose }: { suburb: Suburb; onClose: () => void } = $props();

    const links = $derived(listingLinks(suburb.name, suburb.state, suburb.facts?.postcode));
    const WIDE = '(min-width: 48rem)';

    function open(e: MouseEvent, l: ListingLink) {
        if (typeof matchMedia !== 'function' || !matchMedia(WIDE).matches) return; // phone: the <a>
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return; // the user's own tab choice
        e.preventDefault();
        const w = Math.min(1100, Math.round(window.outerWidth * 0.8));
        const h = Math.min(900, Math.round(window.outerHeight * 0.85));
        const left = Math.round(window.screenX + (window.outerWidth - w) / 2);
        const top = Math.round(window.screenY + (window.outerHeight - h) / 2);
        window.open(l.url, `ancu-${l.site}`, `noopener,noreferrer,popup,width=${w},height=${h},left=${left},top=${top}`);
    }
</script>

<Modal title={$t('listing.title')} {onClose}>
    <div class="listing">
        <p class="listing-place">{suburb.name} <span class="state-chip">{suburb.state}</span></p>
        <p class="listing-note">{$t('listing.note')}</p>
        <!-- Behavior 153: the prices behind these links are in AUD, with the RBA's rate. -->
        <AudNote />
        <div class="listing-links">
            {#each links as l (l.site)}
                <a class="listing-link" href={l.url} target="_blank" rel="noopener noreferrer" onclick={(e) => open(e, l)}
                    ><span>{l.name}</span><span class="listing-host">{l.host.replace(/^www\./, '')} ↗</span></a
                >
            {/each}
        </div>
        {#if links.length === 1}
            <p class="listing-only">{$t('listing.rea_only')}</p>
        {/if}
    </div>
</Modal>
