// What a failed turn tells the user (behavior 20).
//
// Goal property: Bilingual — the shell owns every user-facing string; the engine's
//   turn_failed payload is machinery ({code, message, detail?}), never shown raw.
// Invariant: a turn the compliance gate blocked is not retryable — the same input
//   blocks again, so offering "Try again" would be a lie; any other failure (sidecar
//   crash, qa/sidecar error, unknown code) is transient and keeps "Try again".
// Component: PlanProjection (projection turn) and Chat (conversation turn) both call
//   describeFailure on the turn_failed payload planCardStream hands them.
// Capability: codes read from fh_engine_turn.erl fail/3 (measured 2026-10-07):
//   compliance_block, asic_block (message = the gate detail; the only block detail
//   emitted is asic_advice_crossing, fh_engine_compliance.erl:150), sidecar_crashed,
//   and the sidecar's own qa_error / sidecar_error passed through.
import type { MessageKey } from '$lib/i18n';

export type FailureView = { key: MessageKey; retry: boolean };

const BLOCK_CODES = new Set(['compliance_block', 'asic_block']);

export function describeFailure(failed: unknown): FailureView {
    const p = (failed && typeof failed === 'object' ? failed : {}) as Record<string, unknown>;
    const code = typeof p.code === 'string' ? p.code : '';
    if (!BLOCK_CODES.has(code)) return { key: 'plan.failed', retry: true };
    const detail = typeof p.detail === 'string' ? p.detail : typeof p.message === 'string' ? p.message : '';
    if (detail === 'asic_advice_crossing') return { key: 'turn.blocked.asic_advice', retry: false };
    return { key: 'turn.blocked', retry: false };
}
