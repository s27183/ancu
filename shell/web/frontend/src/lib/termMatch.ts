// Bilingual -> P-7 · The KB -> The web frontend -> the term matcher (pure; see lib/terms.ts)
// No imports, so unit/terms.test.ts runs it under Node's own test runner.

export interface Localized {
    vi: string;
    en: string;
}

export interface Term {
    id: string;
    abbr?: string | null;
    name: Localized;
    /** Every way the copy writes it, in either language (e.g. "LMI", "bảo hiểm khoản vay"). */
    forms: string[];
    meaning: Localized;
    why: Localized;
    /** The KB doc the explanation rests on, and its primary source page. */
    source: { slug: string; url?: string | null };
}

interface Matcher {
    re: RegExp;
    byForm: Map<string, Term>; // lowercased form → term
    exact: Set<string>; // all-capitals forms, matched case-sensitively
}

let cache: { list: Term[]; m: Matcher | null } = { list: [], m: null };

function escapeRe(s: string): string {
    return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const ACRONYM = /^[A-Z0-9/]+$/;

function matcher(list: Term[]): Matcher | null {
    if (cache.list === list) return cache.m;
    const byForm = new Map<string, Term>();
    const exact = new Set<string>();
    for (const t of list) {
        for (const f of t.forms) {
            const form = f.trim();
            if (!form) continue;
            byForm.set(form.toLowerCase(), t);
            if (ACRONYM.test(form)) exact.add(form);
        }
    }
    const forms = [...byForm.keys()].sort((a, b) => b.length - a.length);
    const m = forms.length
        ? {
              re: new RegExp(`(?<![\\p{L}\\p{N}])(?:${forms.map(escapeRe).join('|')})(?![\\p{L}\\p{N}])`, 'giu'),
              byForm,
              exact
          }
        : null;
    cache = { list, m };
    return m;
}

function termAt(m: Matcher, hit: string): Term | null {
    const t = m.byForm.get(hit.toLowerCase());
    if (!t) return null;
    // an acronym form only matches as written: "Lmi" or "lmi" is not LMI.
    const isAcronymForm = [...m.exact].some((f) => f.toLowerCase() === hit.toLowerCase());
    if (isAcronymForm && !m.exact.has(hit)) return null;
    return t;
}

export type Segment = { text: string; term?: Term };

/** Split plain text into runs, the first hit of each term not yet in `seen` marked. */
export function markTerms(text: string, list: Term[], seen: Set<string> = new Set()): Segment[] {
    const m = matcher(list);
    if (!m || !text) return [{ text }];
    const out: Segment[] = [];
    let at = 0;
    for (const hit of text.matchAll(m.re)) {
        const t = termAt(m, hit[0]);
        if (!t || seen.has(t.id)) continue;
        seen.add(t.id);
        const i = hit.index ?? 0;
        if (i > at) out.push({ text: text.slice(at, i) });
        out.push({ text: hit[0], term: t });
        at = i + hit[0].length;
    }
    if (at < text.length) out.push({ text: text.slice(at) });
    return out;
}

/** The same over HTML that lib/markdown.ts wrote (already escaped): text between tags
 *  only, never inside <a>, <code> or <pre>. Adds one tag, a span this function writes. */
export function markTermsHtml(html: string, list: Term[], seen: Set<string> = new Set()): string {
    const m = matcher(list);
    if (!m || !html) return html;
    let skip = 0;
    return html
        .split(/(<[^>]+>)/)
        .map((part) => {
            if (part.startsWith('<')) {
                const open = /^<(a|code|pre)[\s>]/i.test(part);
                const close = /^<\/(a|code|pre)>/i.test(part);
                if (open) skip++;
                else if (close && skip > 0) skip--;
                return part;
            }
            if (skip > 0) return part;
            return markTerms(part, list, seen)
                .map((s) =>
                    s.term
                        ? `<span class="term" role="button" tabindex="0" data-term="${s.term.id}">${s.text}</span>`
                        : s.text
                )
                .join('');
        })
        .join('');
}

export function pickL(l: Localized, lang: 'vi' | 'en'): string {
    return (lang === 'vi' ? l.vi : l.en) || l.en || l.vi;
}
