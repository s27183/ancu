<script lang="ts">
    // The plan-card Q&A chat (8-S4d): ask a question about THIS plan; the engine runs a
    // kind:qa turn over the FILLED card and streams a bilingual answer. Two engine facts
    // shape this:
    //   - The answer is engine-authored {vi,en} (bilingual-content.md) — we pick() the
    //     display language, never route it through chrome i18n. Labels/status are $t.
    //   - Past turns hydrate from GET .../conversation (session_turns; 8-S4e) on mount —
    //     bilingual, oldest→newest. Live turns still arrive over subscribeConversation,
    //     attributed to the turn_id returned by postMessage.
    import { onMount } from 'svelte';
    import { t, type MessageKey } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { postMessage, getConversation } from '$lib/api';
    import { subscribeConversation, type PlanCardStream } from '$lib/planCardStream';
    import { pick, type LocalizedText } from '$lib/planCard';
    import { describeFailure } from '$lib/turnFailure';

    let { planCardId }: { planCardId: string } = $props();

    type Assistant = {
        role: 'assistant';
        turnId: string | null;
        phase: 'thinking' | 'looking' | 'done' | 'error' | 'busy';
        answer: LocalizedText | null;
        // A gate-blocked turn's localized reason (turnFailure.ts); null = generic error.
        blocked?: MessageKey | null;
    };
    type Msg = { role: 'user'; text: string } | Assistant;

    let messages = $state<Msg[]>([]);
    let input = $state('');
    // A turn is in flight → block another send (the engine 409s a concurrent turn anyway).
    let sending = $state(false);
    let logEl = $state<HTMLDivElement | null>(null);

    let stream: PlanCardStream | null = null;
    // Race guard: an answer can in principle arrive before postMessage's 202 registers
    // the bubble's turn_id. Stash by turn_id and reconcile when the id is known. A PLAIN
    // Map (not SvelteMap) on purpose — internal plumbing, never read in the template, so
    // it needs no reactivity (the autofixer's SvelteMap advisory doesn't apply here).
    const early = new Map<string, { answer: LocalizedText | null; failed: unknown }>();

    // Only a gate block gets its own reason in chat; anything else keeps chat.error.
    function blockedKey(failed: unknown): MessageKey | null {
        const f = describeFailure(failed);
        return f.retry ? null : f.key;
    }

    function indexOfTurn(turnId: string): number {
        return messages.findIndex((m) => m.role === 'assistant' && m.turnId === turnId);
    }

    function applyAnswer(turnId: string, answer: LocalizedText | null, failed: unknown) {
        const i = indexOfTurn(turnId);
        if (i < 0) {
            early.set(turnId, { answer, failed });
            return;
        }
        const empty = !answer || (!answer.vi && !answer.en);
        messages[i] = {
            role: 'assistant',
            turnId,
            phase: failed || empty ? 'error' : 'done',
            answer: failed || empty ? null : answer,
            blocked: failed ? blockedKey(failed) : null
        };
        sending = false;
    }

    async function send(e: Event) {
        e.preventDefault();
        const text = input.trim();
        if (!text || sending) return;
        input = '';
        sending = true;
        messages = [
            ...messages,
            { role: 'user', text },
            { role: 'assistant', turnId: null, phase: 'thinking', answer: null }
        ];
        const idx = messages.length - 1; // the assistant placeholder just pushed

        const out = await postMessage(planCardId, text);
        if (out.kind === 'accepted') {
            messages[idx] = { role: 'assistant', turnId: out.turnId, phase: 'thinking', answer: null };
            const stashed = early.get(out.turnId);
            if (stashed) {
                early.delete(out.turnId);
                applyAnswer(out.turnId, stashed.answer, stashed.failed);
            }
        } else {
            messages[idx] = {
                role: 'assistant',
                turnId: null,
                phase: out.kind === 'busy' ? 'busy' : 'error',
                answer: null,
                blocked: out.kind === 'daily_limit' ? 'chat.daily_limit' : null
            };
            sending = false;
        }
    }

    onMount(() => {
        // History hydration races nothing: Chat only mounts once turnDone (no turn can
        // be in flight), and a hydrated bubble's turnId simply won't match any later
        // live turn_id, so the two never collide.
        (async () => {
            const hist = await getConversation(planCardId);
            if (hist.kind === 'ok' && hist.turns.length > 0 && messages.length === 0) {
                messages = hist.turns.flatMap((turn) => [
                    { role: 'user', text: turn.userText },
                    { role: 'assistant', turnId: turn.turnId, phase: 'done', answer: turn.answer }
                ]);
            }
        })();

        stream = subscribeConversation(planCardId, {
            onTool: (turnId) => {
                const i = indexOfTurn(turnId);
                if (i < 0) return;
                const m = messages[i];
                if (m.role === 'assistant' && (m.phase === 'thinking' || m.phase === 'looking')) {
                    messages[i] = { ...m, phase: 'looking' };
                }
            },
            onAnswer: (turnId, answer, failed) => applyAnswer(turnId, answer, failed)
            // onTurnActive: the bubble already shows "thinking"; no change needed.
            // onError: EventSource auto-reconnects + replays; stay calm (no banner).
        });
        return () => stream?.close();
    });

    // The log is a fixed-height scroll region (CSS); pin it to the newest message on
    // every push AND on in-place phase/answer updates (thinking → looking → done).
    $effect(() => {
        for (const m of messages) if (m.role === 'assistant') void m.phase;
        if (logEl) logEl.scrollTop = logEl.scrollHeight;
    });
</script>

<section class="chat" aria-label={$t('chat.title')}>
    <h3 class="chat-title">{$t('chat.title')}</h3>

    {#if messages.length > 0}
        <div class="chat-log" bind:this={logEl}>
            {#each messages as m, i (i)}
                {#if m.role === 'user'}
                    <div class="chat-msg user"><p>{m.text}</p></div>
                {:else if m.phase === 'done'}
                    <div class="chat-msg assistant"><p>{pick(m.answer, $lang)}</p></div>
                {:else if m.phase === 'thinking' || m.phase === 'looking'}
                    <div class="chat-msg assistant">
                        <p class="chat-status">
                            <span class="pp-spinner" aria-hidden="true"></span>
                            {m.phase === 'looking' ? $t('chat.looking') : $t('chat.thinking')}
                        </p>
                    </div>
                {:else}
                    <div class="chat-msg assistant">
                        <p class="chat-err">{m.phase === 'busy' ? $t('chat.busy') : m.blocked ? $t(m.blocked) : $t('chat.error')}</p>
                    </div>
                {/if}
            {/each}
        </div>
    {/if}

    <form class="chat-input" onsubmit={send}>
        <input
            type="text"
            bind:value={input}
            placeholder={$t('chat.placeholder')}
            disabled={sending}
            aria-label={$t('chat.title')}
        />
        <button type="submit" class="primary" disabled={sending || !input.trim()}>
            {$t('chat.send')}
        </button>
    </form>

    <p class="chat-disclaimer">{$t('chat.disclaimer')}</p>
</section>
