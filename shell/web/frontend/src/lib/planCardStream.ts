// The live plan-card event stream consumer (8-S4c), reused by the chat layer (8-S4d).
// It opens an EventSource on the shell's SSE proxy, which relays the engine's stream
// verbatim (events_proxy keystone). Two facts make EventSource the right client:
//   - the stream is cookie-authed (fh_session, httpOnly) and EventSource sends the
//     same-origin cookie automatically — it cannot set an Authorization header, but
//     it does not need to;
//   - the engine replays past events on connect (subscribe→replay→live, pg fan-out),
//     so a late subscriber reconstructs full state, and re-delivery is idempotent when
//     callers merge by component_id / event id.
// The first connect passes `lastEventId` (the GET snapshot's event_cursor) as
// ?last_event_id= so the replay carries only events AFTER the snapshot. Without it a
// FULL replay (from 0) re-applies OLD turns over the fresh snapshot — a card can have
// many turns (re-runs/refreshes) in the append-only log, and the stream closes on the
// FIRST (oldest) terminal, so the projection would render the stalest turn. EventSource
// sets Last-Event-ID itself across its own auto-reconnects; the caller closes the stream
// on a terminal event so the browser doesn't auto-reconnect after a turn ends.
import type { ComponentEntry, LocalizedText } from '$lib/planCard';

/** A streamed bilingual answer chunk (kind:qa turns) — consumed by the chat layer. */
export interface TextDelta {
    text: string;
    lang: 'vi' | 'en';
}

export interface PlanCardStreamHandlers {
    onTurnStarted?: (data: unknown) => void;
    onComponentFilled?: (entry: ComponentEntry) => void;
    onComplianceGate?: (gate: unknown) => void;
    /** Chat answer chunks (8-S4d). */
    onTextDelta?: (delta: TextDelta) => void;
    onUsage?: (usage: unknown) => void;
    /** A terminal event arrived (turn_completed | turn_failed). The stream is closed
     *  before this fires; `failed` carries the engine's failure payload when present. */
    onDone?: (failed: unknown | null) => void;
    /** A transport-level error (the EventSource errored before a terminal event). */
    onError?: () => void;
}

export interface PlanCardStream {
    close: () => void;
}

function parse(e: MessageEvent): unknown {
    try {
        return JSON.parse(e.data);
    } catch {
        return null;
    }
}

/** Subscribe to a plan card's live turn stream. Returns a handle; call close() on
 *  unmount (the projection also closes on the terminal event). Safe in the browser
 *  only — guard with `browser` at the call site. */
export function subscribePlanCard(
    planCardId: string,
    handlers: PlanCardStreamHandlers,
    lastEventId?: number
): PlanCardStream {
    const q = typeof lastEventId === 'number' && lastEventId > 0 ? `?last_event_id=${lastEventId}` : '';
    const es = new EventSource(`/api/plan-cards/${encodeURIComponent(planCardId)}/events${q}`, {
        withCredentials: true
    });
    let closed = false;
    const close = () => {
        if (!closed) {
            closed = true;
            es.close();
        }
    };

    es.addEventListener('turn_started', (e) => handlers.onTurnStarted?.(parse(e as MessageEvent)));
    es.addEventListener('component_filled', (e) => {
        const entry = parse(e as MessageEvent);
        if (entry) handlers.onComponentFilled?.(entry as ComponentEntry);
    });
    es.addEventListener('compliance_gate', (e) => handlers.onComplianceGate?.(parse(e as MessageEvent)));
    es.addEventListener('text_delta', (e) => {
        const d = parse(e as MessageEvent);
        if (d) handlers.onTextDelta?.(d as TextDelta);
    });
    es.addEventListener('usage', (e) => handlers.onUsage?.(parse(e as MessageEvent)));

    // Terminal events: close FIRST so the browser doesn't auto-reconnect on the
    // upstream's stream end, then notify.
    es.addEventListener('turn_completed', () => {
        close();
        handlers.onDone?.(null);
    });
    es.addEventListener('turn_failed', (e) => {
        const failed = parse(e as MessageEvent);
        close();
        handlers.onDone?.(failed);
    });

    // EventSource auto-reconnects on a dropped connection; surface it once. If we have
    // already closed (terminal), this is the expected post-close tick — ignore it.
    es.onerror = () => {
        if (!closed) handlers.onError?.();
    };

    return { close };
}

// --- conversation stream (8-S4d) --------------------------------------------
// A SECOND consumer over the same /events endpoint, shaped for the chat layer — not a
// reuse of subscribePlanCard, because chat's needs genuinely differ (verified against
// fh_engine_turn): (1) it consumes tool_use/tool_result machinery (the projection does
// not); (2) it is LONG-LIVED across many qa turns (the projection closes on the first
// terminal); (3) it scopes events to ONE turn by turn_id — replay re-delivers prior
// turns' terminals, which would mis-finalize a snapshotless chat.
//
// The wire reality (fh_engine_turn:emit_answer) is that text_delta is NOT token-by-token
// — the engine buffers-then-gates and emits the WHOLE answer as one frame per language
// (vi, then en) just before turn_completed. So we accumulate per language and deliver the
// complete {vi,en} answer on the terminal, rather than pretending to stream tokens.
//
// turn_started / turn_completed / turn_failed carry turn_id; text_delta / tool_use do
// NOT. We attribute the latter to the current turn via the turn_started→terminal window,
// which is unambiguous because the engine serializes one in-flight turn per card.

export interface ConversationHandlers {
    /** A turn began (its turn_id from turn_started). */
    onTurnActive?: (turnId: string) => void;
    /** The agent is consulting the KB (tool_use) — show "looking up…". Already sanitized
     *  engine-side (no raw KB / slug); we surface only that a lookup is happening. */
    onTool?: (turnId: string) => void;
    /** The turn ended. On success `answer` is the buffered bilingual answer and `failed`
     *  is null; on a gate block / error `answer` is null and `failed` carries the
     *  turn_failed payload (code is machinery — the caller shows calm chrome, not it). */
    onAnswer?: (turnId: string, answer: LocalizedText | null, failed: unknown | null) => void;
    onError?: () => void;
}

/** Subscribe to a card's conversation stream. Long-lived: it does NOT close on a
 *  terminal (a chat spans many turns) — the caller closes it on unmount. */
export function subscribeConversation(
    planCardId: string,
    handlers: ConversationHandlers
): PlanCardStream {
    const es = new EventSource(`/api/plan-cards/${encodeURIComponent(planCardId)}/events`, {
        withCredentials: true
    });
    let closed = false;
    const close = () => {
        if (!closed) {
            closed = true;
            es.close();
        }
    };

    // The active turn window. `buf` accumulates the answer for `cur` by language.
    let cur: string | null = null;
    let buf: { vi: string; en: string } = { vi: '', en: '' };

    es.addEventListener('turn_started', (e) => {
        const d = parse(e as MessageEvent) as { turn_id?: string } | null;
        if (!d?.turn_id) return;
        cur = d.turn_id;
        buf = { vi: '', en: '' };
        handlers.onTurnActive?.(cur);
    });
    es.addEventListener('tool_use', () => {
        if (cur) handlers.onTool?.(cur);
    });
    // tool_result needs no action — the answer or terminal clears the indicator.
    es.addEventListener('text_delta', (e) => {
        const d = parse(e as MessageEvent) as TextDelta | null;
        if (!d || !cur) return;
        if (d.lang === 'vi' || d.lang === 'en') buf[d.lang] += d.text;
    });
    es.addEventListener('turn_completed', (e) => {
        const d = parse(e as MessageEvent) as { turn_id?: string } | null;
        const tid = d?.turn_id ?? cur;
        if (tid) handlers.onAnswer?.(tid, { vi: buf.vi, en: buf.en }, null);
        cur = null;
    });
    es.addEventListener('turn_failed', (e) => {
        const d = parse(e as MessageEvent) as { turn_id?: string } | null;
        const tid = d?.turn_id ?? cur;
        if (tid) handlers.onAnswer?.(tid, null, d);
        cur = null;
    });

    es.onerror = () => {
        if (!closed) handlers.onError?.();
    };

    return { close };
}
