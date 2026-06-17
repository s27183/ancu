// Cross-component UI state. `loginOpen` lets the global header (in +layout) open the
// Login modal that the map page renders — without threading a callback through the
// layout→page boundary.
import { writable } from 'svelte/store';

export const loginOpen = writable<boolean>(false);
