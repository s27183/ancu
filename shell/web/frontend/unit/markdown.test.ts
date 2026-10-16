// Bilingual -> P-4 · The engine is coupled to no shell -> The web frontend -> markdown text renders as formatted HTML, escape-first
// Behavior 99, Expect 2: the renderer's shapes, and its safety proven the way the design
// rules ask of a fail-closed check — by planted violations: hostile inputs whose output
// must hold only the tags and attributes markdown.ts itself writes. Runs under Node's own
// test runner with its built-in type stripping (Node 26, the CI toolchain): no dependency.
// It lives in unit/, not tests/: SvelteKit's tsconfig type-checks tests/ (measured
// 2026-10-16, .svelte-kit/tsconfig.json include), where node:test has no types without
// @types/node and a .ts import path is refused — npm test runs it, npm run check does not.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderMarkdown, renderInlineMarkdown } from '../src/lib/markdown.ts';

const TAGS = new Set([
    'p', 'br', 'strong', 'em', 'code', 'pre', 'a', 'ul', 'ol', 'li', 'hr', 'blockquote',
    'div', 'table', 'thead', 'tbody', 'tr', 'th', 'td'
]);

// Every tag is allowlisted; every attribute is one this file writes, with a safe value.
function assertSafe(html: string) {
    for (const m of html.matchAll(/<\/?([a-zA-Z][a-zA-Z0-9]*)([^>]*)>/g)) {
        const [, tag, attrs] = m;
        assert.ok(TAGS.has(tag.toLowerCase()), `tag <${tag}> in ${html}`);
        for (const a of attrs.matchAll(/\s([a-zA-Z-]+)(?:="([^"]*)")?/g)) {
            const [, name, value = ''] = a;
            if (name === 'href') assert.match(value, /^https?:\/\//, `href ${value}`);
            else if (name === 'target') assert.equal(value, '_blank');
            else if (name === 'rel') assert.equal(value, 'noopener noreferrer');
            else if (name === 'start') assert.match(value, /^\d+$/);
            else if (name === 'class') assert.match(value, /^md-(h|table)$/);
            else assert.fail(`attribute ${name} on <${tag}> in ${html}`);
        }
    }
}

test('paragraphs: blank line separates, single newline breaks', () => {
    assert.equal(renderMarkdown('One\ntwo\n\nThree'), '<p>One<br>two</p><p>Three</p>');
});

test('bold, italic, code', () => {
    assert.equal(
        renderMarkdown('**Stamp duty** is *about* `$31,090`'),
        '<p><strong>Stamp duty</strong> is <em>about</em> <code>$31,090</code></p>'
    );
    // arithmetic stars and code contents are left alone
    assert.equal(renderMarkdown('2 * 3 * 4'), '<p>2 * 3 * 4</p>');
    assert.equal(renderMarkdown('`a**b**c`'), '<p><code>a**b**c</code></p>');
});

test('bulleted list', () => {
    assert.equal(
        renderMarkdown('Costs:\n- **Duty**: $31k\n- Fees\n* Rates'),
        '<p>Costs:</p><ul><li><strong>Duty</strong>: $31k</li><li>Fees</li><li>Rates</li></ul>'
    );
});

test('numbered list, start number, loose items, continuation', () => {
    assert.equal(
        renderMarkdown('1. Apply\n\n2. Sign\n   the contract\n\nAfter.'),
        '<ol><li>Apply</li><li>Sign the contract</li></ol><p>After.</p>'
    );
    assert.equal(renderMarkdown('3. Third\n4. Fourth'), '<ol start="3"><li>Third</li><li>Fourth</li></ol>');
});

test('nested list', () => {
    assert.equal(
        renderMarkdown('- Buy\n  - duty\n  - fees\n- Hold'),
        '<ul><li>Buy<ul><li>duty</li><li>fees</li></ul></li><li>Hold</li></ul>'
    );
    assert.equal(
        renderMarkdown('1. Buy\n   - duty\n2. Hold'),
        '<ol><li>Buy<ul><li>duty</li></ul></li><li>Hold</li></ol>'
    );
});

test('headings are bold lines', () => {
    assert.equal(
        renderMarkdown('## Chi phí khi mua\nText'),
        '<p class="md-h"><strong>Chi phí khi mua</strong></p><p>Text</p>'
    );
    assert.equal(renderMarkdown('#hashtag'), '<p>#hashtag</p>');
});

test('links open in a new tab, http(s) only', () => {
    assert.equal(
        renderMarkdown('See [Revenue NSW](https://www.revenue.nsw.gov.au/a?b=1&c=2)'),
        '<p>See <a href="https://www.revenue.nsw.gov.au/a?b=1&amp;c=2" target="_blank" rel="noopener noreferrer">Revenue NSW</a></p>'
    );
});

test('table, rule, quote, fence', () => {
    assert.equal(
        renderMarkdown('| Item | Cost |\n|---|---:|\n| Duty | **$31k** |'),
        '<div class="md-table"><table><thead><tr><th>Item</th><th>Cost</th></tr></thead>' +
            '<tbody><tr><td>Duty</td><td><strong>$31k</strong></td></tr></tbody></table></div>'
    );
    assert.equal(renderMarkdown('a\n\n---\n\nb'), '<p>a</p><hr><p>b</p>');
    assert.equal(renderMarkdown('> note'), '<blockquote><p>note</p></blockquote>');
    assert.equal(renderMarkdown('```\n**x** <b>\n```'), '<pre><code>**x** &lt;b&gt;</code></pre>');
});

test('no raw marks survive a typical answer', () => {
    const html = renderMarkdown(
        '## Costs when you buy\n\n**Upfront:**\n- Stamp duty: *$31,090*\n- Fees — see [NSW](https://revenue.nsw.gov.au)\n\n1. Deposit\n2. Settlement'
    );
    const text = html.replace(/<[^>]+>/g, '');
    for (const mark of ['**', '##', '](', '- ']) assert.ok(!text.includes(mark), `${mark} in ${text}`);
    assertSafe(html);
});

const HOSTILE = [
    '<script>alert(1)</script>',
    '<img src=x onerror=alert(1)>',
    '**<img src=x onerror=alert(1)>**',
    '[click](javascript:alert(1))',
    '[click](data:text/html,<script>alert(1)</script>)',
    '[x](https://a.b/"onmouseover="alert(1))',
    '[x](https://a.b/) onclick="alert(1)"',
    '<a href="javascript:alert(1)">x</a>',
    '<iframe src="https://evil"></iframe>',
    '- <svg onload=alert(1)>\n- `<script>`',
    '| <b>h</b> | x |\n|---|---|\n| <img src=x> | y |',
    '> <style>body{display:none}</style>',
    '```\n</code></pre><script>alert(1)</script>\n```',
    '## <h1 onclick=x>t</h1>',
    '\u00000\u0000 `x` \u00000\u0000',
    '&lt;script&gt; &amp; &#60;img&#62;'
];

test('hostile input comes out escaped or dropped', () => {
    for (const input of HOSTILE) {
        for (const html of [renderMarkdown(input), renderInlineMarkdown(input)]) {
            assertSafe(html);
            assert.ok(!/<script|<img|<svg|<iframe|<style|javascript:[^<]*<\/a>/i.test(html), html);
        }
    }
    assert.equal(
        renderMarkdown('<script>alert(1)</script>'),
        '<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>'
    );
    assert.equal(renderMarkdown('[click](javascript:alert(1))'), '<p>[click](javascript:alert(1))</p>');
});

test('inline renderer keeps its single-line contract', () => {
    assert.equal(
        renderInlineMarkdown('**A** and [b](https://x.y)'),
        '<strong>A</strong> and <a href="https://x.y" target="_blank" rel="noopener noreferrer">b</a>'
    );
});
