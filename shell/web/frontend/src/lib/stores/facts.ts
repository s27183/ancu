// Regulated figures are grounded -> P-6 -> The web frontend -> the home's one facts fetch (behavior 164)
// The Introduction sheet (Welcome.svelte) fetches GET /api/facts on the home for its own
// sections; it puts what it got here, and the home's demand card reads its rank and
// quarter from it — one request on the home, not two. Empty until the sheet's fetch lands
// (or for good if it fails): the card then shows its line without a figure.
import { writable } from 'svelte/store';
import type { FactDoc } from '$lib/facts';

export const homeFacts = writable<FactDoc[]>([]);
