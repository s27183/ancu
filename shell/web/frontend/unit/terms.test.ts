// Bilingual -> P-7 · The KB -> The web frontend -> the term matcher's rules, proven on a stub list
// Behavior 102, step 1: whole words only, acronyms as written, longest form first, once
// per block, both languages' forms in either language, and never inside <a>/<code>/<pre>
// in markdown's HTML. lib/termMatch.ts has no imports, so Node's runner takes it as is.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { markTerms, markTermsHtml, type Term } from '../src/lib/termMatch.ts';

const L = (vi: string, en: string) => ({ vi, en });
const TERMS: Term[] = [
    { id: 'lmi', abbr: 'LMI', name: L('Bảo hiểm khoản vay', 'Lenders mortgage insurance'),
      forms: ['LMI', 'bảo hiểm khoản vay', 'lenders mortgage insurance'],
      meaning: L('m', 'm'), why: L('w', 'w'), source: { slug: 'kb.lmi.calculation' } },
    { id: 'fhg', abbr: 'FHG', name: L('Bảo lãnh mua nhà lần đầu', 'First Home Guarantee'),
      forms: ['FHG', 'Bảo lãnh mua nhà lần đầu', 'First Home Guarantee'],
      meaning: L('m', 'm'), why: L('w', 'w'), source: { slug: 'kb.scheme.fhg' } },
    { id: 'help', abbr: 'HELP', name: L('Nợ học phí HECS/HELP', 'HECS/HELP debt'),
      forms: ['HECS/HELP', 'HECS', 'HELP'],
      meaning: L('m', 'm'), why: L('w', 'w'), source: { slug: 'kb.lender.hecs-treatment-by-lender' } }
];
const marked = (text: string) =>
    markTerms(text, TERMS).filter((s) => s.term).map((s) => `${s.term!.id}:${s.text}`);

test('vi copy: Vietnamese form and the English acronym both resolve, marked once', () => {
    assert.deepEqual(
        marked('Dưới 20% thì có bảo hiểm khoản vay (LMI) trong Phí mua; Bảo lãnh mua nhà lần đầu miễn LMI.'),
        ['lmi:bảo hiểm khoản vay', 'fhg:Bảo lãnh mua nhà lần đầu']
    );
});

test('the text is kept whole around the marks', () => {
    const text = 'With the First Home Guarantee there is no LMI.';
    assert.equal(markTerms(text, TERMS).map((s) => s.text).join(''), text);
});

test('an acronym matches only as written; an ordinary word is not a term', () => {
    assert.deepEqual(marked('Ask for help with the lmi quote'), []);
    assert.deepEqual(marked('Your HELP balance'), ['help:HELP']);
});

test('whole words only: no hit inside a longer word', () => {
    assert.deepEqual(marked('LMIX and FHGs'), []);
});

test('the longest form wins', () => {
    assert.deepEqual(marked('HECS/HELP debt'), ['help:HECS/HELP']);
});

test('a shared seen set marks a term once across a block of several runs', () => {
    const seen = new Set<string>();
    markTerms('LMI here', TERMS, seen);
    assert.deepEqual(markTerms('LMI again', TERMS, seen).filter((s) => s.term), []);
});

test('no list, no marks', () => {
    assert.deepEqual(markTerms('LMI', []), [{ text: 'LMI' }]);
});

test('HTML: text between tags only, never inside a link or code', () => {
    const html = '<p><a href="https://x">LMI</a> and <code>FHG</code> then LMI and FHG</p>';
    const out = markTermsHtml(html, TERMS);
    assert.equal(
        out,
        '<p><a href="https://x">LMI</a> and <code>FHG</code> then ' +
            '<span class="term" role="button" tabindex="0" data-term="lmi">LMI</span> and ' +
            '<span class="term" role="button" tabindex="0" data-term="fhg">FHG</span></p>'
    );
});

test('HTML: a term in an attribute is never touched', () => {
    const html = '<a href="https://x/LMI">x</a> <strong title="FHG">y</strong>';
    assert.equal(markTermsHtml(html, TERMS), html);
});
