// A small Svelte action: call `onOutside` when a pointerdown/click lands outside the
// node. Used to collapse the map controls cluster (a backdrop would block the map, so
// we listen on the document instead). Capture phase + node.contains means the click
// that OPENS the panel (a descendant) never triggers a close, so no toggle race.
export function clickOutside(node: HTMLElement, onOutside: () => void) {
    let cb = onOutside;
    const handler = (e: MouseEvent) => {
        if (!node.contains(e.target as Node)) cb();
    };
    document.addEventListener('click', handler, true);
    return {
        update(next: () => void) {
            cb = next;
        },
        destroy() {
            document.removeEventListener('click', handler, true);
        }
    };
}
