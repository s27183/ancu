// An investor's strategy_archetype → its label key (behavior 28). The set is the union
// of the strategy_archetype options in docs/blueprints/investor-domestic-au.md and
// investor-foreign-au.md; a value outside it is shown verbatim rather than dropped
// (the renderers' honest-unknown rule), so a new blueprint option is visible, not lost.
import type { MessageKey } from '$lib/i18n';

const ARCHETYPES = new Set([
    'cash_flow',
    'capital_growth',
    'balanced',
    'dual_income',
    'value_add',
    'land_banking',
    'wealth_diversification',
    'future_migration_pathway',
    'child_education_property'
]);

export function archetypeLabel(value: string, t: (key: MessageKey) => string): string {
    return ARCHETYPES.has(value) ? t(`plan.archetype.${value}` as MessageKey) : value;
}
