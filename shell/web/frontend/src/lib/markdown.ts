// Minimal, safe inline-markdown renderer for KB-authored prose (news summaries, etc.).
// KB docs are written with **bold**/*italic*/`code`/[text](url) (docs/kb convention), but
// consumers that render that text as plain content (e.g. NewsDetailSheet) were showing the
// literal asterisks. Deliberately NOT a full markdown library: these fields are single-
// paragraph prose, never block-level content (headers, lists, code fences) — pulling in
// marked/markdown-it for four inline patterns is more surface area than the input shape
// justifies. HTML-escapes first, so the output is safe to pass to {@html}; link hrefs are
// restricted to http(s) so a KB doc can't inject a javascript: URL.
export function renderInlineMarkdown(text: string): string {
    const escaped = text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');

    return escaped
        .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
        .replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<em>$1</em>')
        .replace(/`([^`]+)`/g, '<code>$1</code>')
        .replace(
            /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
            '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
        );
}
