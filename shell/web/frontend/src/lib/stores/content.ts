// Regulated figures are grounded -> P-7 -> The web frontend -> each view re-reads the KB when it is replaced (behavior 135)
// `contentRevision` counts the times the layout's watch (lib/contentWatch.ts) saw the
// engine's KB hash move. A view that fetched news or facts registers its re-fetch with
// `onContentChange`; it runs on each move after the view mounted, never at mount (the
// view fetches on its own then). The view keeps what it shows until the new answer
// arrives, and keeps it if the answer is empty (a cold engine): nothing blanks under
// the reader.
import { writable } from 'svelte/store';

export const contentRevision = writable(0);

/** Call `fn` on every KB change after now; returns the unsubscribe (an onMount return). */
export function onContentChange(fn: () => void): () => void {
    let first = true;
    return contentRevision.subscribe(() => {
        if (first) {
            first = false;
            return;
        }
        fn();
    });
}
