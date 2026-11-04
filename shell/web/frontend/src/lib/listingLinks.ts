// Honest-partial -> the suburb data the goal names -> the web frontend -> the listing sites' links
// Goal:      behavior 150 — a suburb's sheet leads, in one tap, to the homes for sale there on
//            realestate.com.au, Domain and Allhomes; Mai An Cư links out and never frames,
//            fetches or copies their pages ("No property scraping", invariants.md).
// Invariant: every link is https://<one of three fixed hosts>/<path> — a suburb name can shape
//            only the path: Domain and Allhomes get a slug of [a-z0-9-] only, REA a
//            percent-encoded segment. Domain and Allhomes links exist only where the suburb
//            has a stored postcode (facts.postcode, abs_poa.py); without one, REA alone.
// Capability: the three URL forms measured 2026-11-04 in Chrome (behavior 150, probe 2/9):
//            REA  /buy/in-box+hill,+vic/list-1  (no postcode; apostrophe kept: in-o'connor,+act)
//            Domain   /sale/box-hill-vic-3128/   Allhomes /sale/box-hill-vic-3128/
//            (both not-found without the postcode, or with the wrong one; o-connor-act-2602).
//            ABS names carry a state qualifier ("Box Hill (Vic.)") that the sites do not:
//            it is dropped before building.

export type ListingSite = 'rea' | 'domain' | 'allhomes';

export interface ListingLink {
    site: ListingSite;
    name: string;
    host: string;
    url: string;
}

export const LISTING_HOSTS: Record<ListingSite, string> = {
    rea: 'www.realestate.com.au',
    domain: 'www.domain.com.au',
    allhomes: 'www.allhomes.com.au'
};

const SITE_NAMES: Record<ListingSite, string> = {
    rea: 'realestate.com.au',
    domain: 'Domain',
    allhomes: 'Allhomes'
};

const STATES = new Set(['NSW', 'VIC', 'QLD', 'SA', 'WA', 'TAS', 'NT', 'ACT']);

/** "Box Hill (Vic.)" → "Box Hill": ABS's disambiguating qualifier, which the sites do not use.
 *  Every parenthesised group goes, wherever it sits, so none can reach a link. */
export function plainSuburbName(name: string): string {
    return String(name ?? '')
        .replace(/\([^()]*\)/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

/** Domain/Allhomes slug: lower case, every run of other characters one '-'. */
export function slug(s: string): string {
    return s
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

function reaSegment(name: string): string {
    return encodeURIComponent(name.toLowerCase()).replace(/%20/g, '+');
}

/** The links for one suburb, REA first; [] when nothing safe can be built. */
export function listingLinks(name: string, state: string, postcode?: string | null): ListingLink[] {
    const plain = plainSuburbName(name);
    const st = String(state ?? '').toUpperCase();
    if (!STATES.has(st)) return [];
    const nameSlug = slug(plain);
    if (!nameSlug) return [];
    const links: ListingLink[] = [];
    const make = (site: ListingSite, path: string) => links.push({ site, name: SITE_NAMES[site], host: LISTING_HOSTS[site], url: `https://${LISTING_HOSTS[site]}${path}` });
    make('rea', `/buy/in-${reaSegment(plain)},+${st.toLowerCase()}/list-1`);
    if (typeof postcode === 'string' && /^[0-9]{4}$/.test(postcode)) {
        const tail = `${nameSlug}-${st.toLowerCase()}-${postcode}`;
        make('domain', `/sale/${tail}/`);
        make('allhomes', `/sale/${tail}/`);
    }
    return links;
}
