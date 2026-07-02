---
slug: kb.cross-border.decision-authority-cultural
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Cross-border decision authority — who decides, who owns, who is exposed to FIRB (three things families conflate)

This doc owns the **decision-authority pattern set** for a cross-border family purchase (Mode B — an AU-side buyer funded from Vietnam). It grounds `family_context` (component 2) `decision_authority.primary_decision_maker` and `decision_authority.consultation_required_for_purchase`, and the `decision_authority` field on the `family_funding_plan` outcome.

Like the funding-pattern doc, it supplies **prompts, never a prediction** — the plan surfaces the authority question and captures the family's answer; it never asserts who holds authority in a given family.

## The patterns (→ the decision-authority enums)

The common cross-border decision structures map onto the component's enums:

- **AU member decides** (`au_member`) — the buyer runs the decision; the VN contribution is a gift with no strings.
- **VN parent decides / must be consulted** (`vn_parent`, `consultation_required = vn_parent_only` or `both_required`) — the funding parent expects authority proportional to their contribution; a purchase may not proceed without their sign-off. Common where the parent funds the majority.
- **Joint / family council** (`joint`, `family_council`) — the decision is made collectively across the family, sometimes with a senior relative as the deciding voice.

The plan offers these and asks the family to specify who decides and who must be consulted — it does not assume a hierarchy from the contribution split.

## The load-bearing distinction: decision authority ≠ legal title ≠ FIRB exposure

The pattern that most often causes harm is **conflating three separate things** a cross-border family treats as one:

1. **Who decides** (cultural / this doc) — the funding parent may hold decision authority by family custom.
2. **Who owns** (legal title) — the person(s) *on the title* are the legal owners, regardless of who funded or who decided. Cultural authority confers **no** legal interest.
3. **Who is exposed to FIRB** (regulatory) — a VN parent who goes **on title** is a **foreign person** acquiring an interest, with **their own** FIRB approval obligation and foreign-buyer duty surcharge, and (post-1 Apr 2025) caught by the established-dwelling ban. A parent who funds but stays **off** title is a **funder**, not an owner — no separate FIRB exposure for them.

So the culturally-natural instinct ("Dad paid, put Dad on the title") can silently **add a second foreign person, a second FIRB application, and a second surcharge** — or, worse, breach the ban. The plan's job is to **disentangle the three** and make the title decision explicit and informed.

This doc owns only the **cultural-authority pattern and the disentanglement prompt.** The regulated pieces are single-owned and cross-referenced:

- **The funder-vs-owner role** on the identity model → `profile.off_title_parties[].funder` (the VN funding parent as a funder role; read by `family_context` / `cross_border_funding`) — architecture §11.9 off-title namespace.
- **Foreign-person classification / the ban** → [`kb.firb.status-determination`](../firb/status-determination.md) and [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md).
- **The foreign-buyer duty surcharge** (per on-title foreign person) → [`kb.foreign-buyer-surcharge.by-state`](../foreign-buyer-surcharge/by-state.md).

## The consultation dimension

`consultation_required_for_purchase` is the *process* fact distinct from the *authority* fact: even where the AU member formally decides, a large VN contribution often carries an expectation of consultation before committing (e.g. before an unconditional auction bid). The plan surfaces this so the coordination surface ([`kb.bilingual.coordination-norms`](../bilingual/coordination-norms.md)) can build in the time and the bilingual channel for that sign-off — a held consultation must not blow a settlement or bid deadline.

## Relevance for the Vietnam-parent-funded buyer (Mode B)

- **Authority is not ownership.** The single most valuable clarification: the person who decides (culturally) and the person on the title (legally) need not be the same, and putting the funder on title has regulatory cost. Surface it before the contract, not at settlement.
- **Prompt, don't profile.** The plan asks who decides and who must be consulted — it never states that "the Vietnamese parent decides."
- **Information, not advice.** The plan names the authority patterns and the title/FIRB consequence and points to the FIRB owners + a conveyancer for the title decision; it never advises who should be on title.

## Rules

Pure-reference (`fills: []`). `family_context` reasons over these patterns to capture `primary_decision_maker` / `consultation_required_for_purchase` and to raise the disentanglement prompt (authority ≠ title ≠ FIRB). All parameters are `CONVENTION` (behavioural pattern), surfaced as decision-support prompts; the FIRB/title consequences are owned elsewhere and cross-referenced.

```jsonc
{
  "fills": [],
  "parameters": {
    "decision_authority_is_prompt_not_prediction": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the plan captures who decides / who is consulted from user input; it never asserts a hierarchy from the contribution split (honest-partial)." },
    "authority_is_not_legal_title": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the load-bearing distinction — cultural decision authority confers no legal ownership; the person(s) ON TITLE are the legal owners regardless of who funded or decided." },
    "funder_on_title_becomes_a_second_foreign_person": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "putting the VN funding parent on title makes them a foreign person acquiring an interest — a SECOND FIRB obligation + foreign-buyer surcharge, and caught by the ban. Owned by kb.firb.status-determination / kb.firb.established-dwelling-ban / kb.foreign-buyer-surcharge.by-state; a funder OFF title carries no separate FIRB exposure." },
    "consultation_is_a_timing_input_to_coordination": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "consultation_required_for_purchase is a process fact — a required VN sign-off must be built into the bilingual coordination timeline (kb.bilingual.coordination-norms) so it does not blow a settlement/bid deadline." }
  }
}
```

Notes:

- **No `fills`; a behavioural-pattern doc.** It owns the *authority pattern + the disentanglement prompt*; the funder-vs-owner role, FIRB classification/ban, and the surcharge are single-owned elsewhere and cross-referenced.
- **Authority ≠ title ≠ FIRB is the keeper.** The three-way conflation that silently adds a foreign person is lifted to a parameter and routed to its regulated owners.
- **Prompt, don't profile.** Every parameter is a decision-support prompt, not an assertion about the family.

## Sources

Behavioural / reference doc — no regulator publishes family decision-authority patterns. The regulated consequences are sourced in their single owners:

- [`kb.firb.status-determination`](../firb/status-determination.md) — foreign-person classification (on-title parties).
- [`kb.firb.established-dwelling-ban`](../firb/established-dwelling-ban.md) — the established-dwelling prohibition.
- [`kb.foreign-buyer-surcharge.by-state`](../foreign-buyer-surcharge/by-state.md) — foreign-buyer duty surcharge per on-title foreign person.
