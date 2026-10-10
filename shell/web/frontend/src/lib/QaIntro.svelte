<script lang="ts">
    // What the plan's AI assistant is, shown before the first question (behavior 55): one
    // line on what it does and three example questions. A tap on an example only hands
    // its text to `onpick` — Chat puts it in the input, the guest view opens sign-in —
    // so it never sends, and never spends the day's one question (behavior 36).
    //
    //   goal property: the buyer reasons over their own plan, every figure cited
    //   invariant: information, not advice — chat.disclaimer stays under the input
    //   component: this + Chat.svelte + PlanProjection's Q&A tab, foot bar
    //   capability: name the assistant, show what to ask; never post on its own
    import { t, type MessageKey } from '$lib/i18n';
    import Sparkle from '$lib/Sparkle.svelte';

    let { onpick }: { onpick: (text: string) => void } = $props();

    const EXAMPLES: MessageKey[] = ['chat.ex1', 'chat.ex2', 'chat.ex3'];
</script>

<div class="qa-intro">
    <p class="qa-intro-line"><Sparkle />{$t('chat.intro')}</p>
    <p class="qa-intro-label">{$t('chat.examples')}</p>
    <div class="qa-intro-chips">
        {#each EXAMPLES as k (k)}
            <button type="button" class="qa-chip" onclick={() => onpick($t(k))}>{$t(k)}</button>
        {/each}
    </div>
</div>

<style>
    .qa-intro {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin: 0.75rem 0 0.25rem;
    }
    .qa-intro-line {
        display: flex;
        gap: 0.5rem;
        align-items: flex-start;
        margin: 0;
        padding: 0.65rem 0.75rem;
        border-radius: 10px;
        background: var(--accent-soft);
        color: var(--ink);
        font-size: var(--fs-sm);
        line-height: 1.45;
    }
    .qa-intro-line :global(.sparkle) {
        flex: 0 0 auto;
        margin-top: 0.1rem;
        color: var(--accent);
    }
    .qa-intro-label {
        margin: 0.25rem 0 0;
        font-size: var(--fs-xs);
        font-weight: 600;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        color: var(--muted);
    }
    .qa-intro-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
    }
    .qa-chip {
        border: 1px solid var(--accent-line);
        background: var(--surface);
        color: var(--accent);
        border-radius: 999px;
        padding: 0.35rem 0.8rem;
        font: inherit;
        font-size: var(--fs-sm);
        text-align: left;
        cursor: pointer;
    }
    .qa-chip:hover {
        background: var(--accent-soft);
    }
    .qa-chip:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }
</style>
