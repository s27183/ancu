// Bilingual -> a buyer new to Australian listing sites reads one in Vietnamese -> the web
// frontend -> the property types (behavior 154; ListingGuide.svelte): the types the sheet
// shows are kb.property.types' copy word for word, so the ABS-grounded text has one owner.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const kb = readFileSync(new URL('../../../../docs/kb/property/types.md', import.meta.url), 'utf8');
const i18n = readFileSync(new URL('../src/lib/i18n.ts', import.meta.url), 'utf8');
const copy = JSON.parse(kb.split('```jsonc')[1].split('```')[0]).copy as Record<string, { vi: string; en: string }>;

test('every kb.property.types copy entry is the i18n types.<key> text, in both languages', () => {
    assert.deepEqual(Object.keys(copy).sort(), ['apartment', 'attached', 'house', 'land', 'source', 'strata']);
    for (const [k, v] of Object.entries(copy)) {
        const line = i18n.split('\n').find((l) => l.startsWith(`    'types.${k}': `));
        assert.ok(line, `types.${k} missing from i18n.ts`);
        assert.equal(line, `    'types.${k}': { vi: ${JSON.stringify(v.vi)}, en: ${JSON.stringify(v.en)} },`);
    }
});
