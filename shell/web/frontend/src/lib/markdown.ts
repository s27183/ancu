// Bilingual -> P-4 · The engine is coupled to no shell -> The web frontend -> markdown text renders as formatted HTML, escape-first
// Two readers, one escape-first renderer, no markdown library (package.json has none;
// behavior 99 kept it so):
//   - renderInlineMarkdown: KB-authored single-paragraph prose (news summaries) —
//     **bold**/*italic*/`code`/[text](url), the docs/kb convention.
//   - renderMarkdown: the assistant's answer (Chat.svelte). The model writes markdown —
//     paragraphs, - and 1. lists, # headings, tables — and the buyer saw the marks raw
//     (behavior 99, Son 2026-10-16). The engine stays shell-agnostic: it sends the text
//     as written and this shell decides how it looks. Headings render as bold lines, not
//     <h1>…<h6>: an answer in a chat bubble has no document outline.
// Safety, for {@html}: the WHOLE input is HTML-escaped before any pattern runs, so every
// tag in the output is one this file writes (p, br, strong, em, code, pre, a, ul, ol, li,
// hr, blockquote, table parts) and no text can close an attribute (" is escaped). Link
// hrefs are http(s) only, so a javascript: or data: URL stays text. Proven by
// unit/markdown.test.ts (a tag allowlist over hostile inputs).

export function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// Inline patterns over ALREADY-ESCAPED text. Code spans are set aside first so their
// contents never turn bold; \u0000 cannot occur in the input (stripped by the callers).
function inline(escaped: string): string {
    const codes: string[] = [];
    let s = escaped.replace(/`([^`\n]+)`/g, (_m, c: string) => {
        codes.push(c);
        return `\u0000${codes.length - 1}\u0000`;
    });
    s = s
        .replace(
            /\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)/g,
            '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
        )
        .replace(/\*\*(?=\S)([^\n]*?\S)\*\*/g, '<strong>$1</strong>')
        .replace(/__(?=\S)([^\n_]*?\S)__/g, '<strong>$1</strong>')
        .replace(/(?<![*\w])\*(?=[^\s*])([^*\n]*?[^\s*])\*(?![*\w])/g, '<em>$1</em>');
    return s.replace(/\u0000(\d+)\u0000/g, (_m, i: string) => `<code>${codes[Number(i)]}</code>`);
}

export function renderInlineMarkdown(text: string): string {
    return inline(escapeHtml(text.replace(/\u0000/g, '')));
}

const FENCE = /^\s*```/;
const HEADING = /^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$/;
const RULE = /^\s{0,3}([-*_])(\s*\1){2,}\s*$/;
const ITEM = /^(\s*)([-*+]|\d{1,9}[.)])\s+(.*)$/;
const QUOTE = /^\s{0,3}&gt;\s?(.*)$/;
const TABLE_SEP = /^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$/;

function cells(row: string): string[] {
    return row.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => inline(c.trim()));
}

type List = { tag: 'ul' | 'ol'; indent: number; start: number; items: string[] };

function closeList(l: List): string {
    const start = l.tag === 'ol' && l.start !== 1 ? ` start="${l.start}"` : '';
    return `<${l.tag}${start}>${l.items.map((i) => `<li>${i}</li>`).join('')}</${l.tag}>`;
}

// One list block (its lines already gathered), nested by marker indentation.
function renderList(lines: string[]): string {
    const stack: List[] = [];
    let out = '';
    const pop = () => {
        const html = closeList(stack.pop()!);
        if (stack.length) stack[stack.length - 1].items[stack[stack.length - 1].items.length - 1] += html;
        else out += html;
    };
    for (const line of lines) {
        const m = ITEM.exec(line);
        if (!m) {
            const top = stack[stack.length - 1];
            if (top && line.trim()) top.items[top.items.length - 1] += ' ' + inline(line.trim());
            continue;
        }
        const indent = m[1].length;
        const tag = /\d/.test(m[2]) ? 'ol' : 'ul';
        while (stack.length && indent < stack[stack.length - 1].indent) pop();
        let top = stack[stack.length - 1];
        if (top && indent === top.indent && top.tag !== tag) {
            pop();
            top = stack[stack.length - 1];
        }
        if (!top || indent > top.indent || top.tag !== tag) {
            stack.push({ tag, indent, start: tag === 'ol' ? parseInt(m[2], 10) : 1, items: [] });
            top = stack[stack.length - 1];
        }
        top.items.push(inline(m[3]));
    }
    while (stack.length) pop();
    return out;
}

export function renderMarkdown(text: string): string {
    return blocks(escapeHtml(text.replace(/\u0000/g, '').replace(/\r\n?/g, '\n')).split('\n'));
}

// Block structure over ALREADY-ESCAPED lines.
function blocks(lines: string[]): string {
    const out: string[] = [];
    let para: string[] = [];
    const flush = () => {
        if (para.length) out.push(`<p>${para.map(inline).join('<br>')}</p>`);
        para = [];
    };

    let i = 0;
    while (i < lines.length) {
        const line = lines[i];
        if (!line.trim()) {
            flush();
            i++;
        } else if (FENCE.test(line)) {
            flush();
            const code: string[] = [];
            i++;
            while (i < lines.length && !FENCE.test(lines[i])) code.push(lines[i++]);
            i++; // the closing fence (or the end)
            out.push(`<pre><code>${code.join('\n')}</code></pre>`);
        } else if (HEADING.test(line)) {
            flush();
            out.push(`<p class="md-h"><strong>${inline(HEADING.exec(line)![1])}</strong></p>`);
            i++;
        } else if (RULE.test(line)) {
            flush();
            out.push('<hr>');
            i++;
        } else if (ITEM.test(line)) {
            flush();
            const block: string[] = [];
            // A list runs through its items, indented continuation lines, and blank
            // lines that are followed by another item or an indented line.
            while (i < lines.length) {
                const l = lines[i];
                if (ITEM.test(l) || (l.trim() && /^\s+/.test(l))) block.push(lines[i++]);
                else if (!l.trim()) {
                    let j = i;
                    while (j < lines.length && !lines[j].trim()) j++;
                    if (j < lines.length && (ITEM.test(lines[j]) || /^\s+\S/.test(lines[j]))) i = j;
                    else break;
                } else break;
            }
            out.push(renderList(block));
        } else if (QUOTE.test(line)) {
            flush();
            const q: string[] = [];
            while (i < lines.length && QUOTE.test(lines[i])) q.push(QUOTE.exec(lines[i++])![1]);
            out.push(`<blockquote>${blocks(q)}</blockquote>`);
        } else if (line.includes('|') && i + 1 < lines.length && TABLE_SEP.test(lines[i + 1]) && lines[i + 1].includes('-')) {
            flush();
            const head = cells(line);
            i += 2;
            const rows: string[][] = [];
            while (i < lines.length && lines[i].includes('|') && lines[i].trim()) rows.push(cells(lines[i++]));
            out.push(
                '<div class="md-table"><table><thead><tr>' +
                    head.map((c) => `<th>${c}</th>`).join('') +
                    '</tr></thead><tbody>' +
                    rows.map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join('')}</tr>`).join('') +
                    '</tbody></table></div>'
            );
        } else {
            para.push(line);
            i++;
        }
    }
    flush();
    return out.join('');
}
