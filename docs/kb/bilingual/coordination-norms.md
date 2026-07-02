---
slug: kb.bilingual.coordination-norms
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Bilingual coordination norms — keeping a two-language, two-timezone family on the same plan

This doc owns the **communication-coordination pattern set** for a cross-border family purchase (Mode B — an AU-side buyer and a Vietnam-side funder/decision-maker sharing one plan). It grounds `family_context` (component 2) `coordination.*` (`bilingual_view_active`, `shared_dashboard_invited_parties`, `language_per_party`) and the `bilingual_coordination_required` field on the `family_funding_plan` outcome.

## What this doc owns — and what it does NOT

**Owns:** the *communication* coordination layer — who is invited to the shared plan, in which language each party reads it, and the norm that the plan surface is co-equally bilingual so a Vietnam-side participant is a first-class reader, not a translated afterthought.

**Does NOT own** the *settlement sequencing* layer — the two-country critical-path order and the 14-day buffer (VN outbound → transfer → AU ECDD → funds-in-trust) is single-owned by [`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md). That doc orders the *money/legal milestones*; this doc orders the *conversation*. A required decision or sign-off has a **timing** input (owned by [`kb.cross-border.decision-authority-cultural`](decision-authority-cultural.md)) and a **channel** input (owned here).

## The coordination patterns (→ the `coordination.*` parameters)

- **Bilingual-by-default, not translated-on-request** (`bilingual_view_active`) — the plan surface presents Vietnamese and English **co-equally** ({vi,en} at the source), so the VN-side funder reads the same figures and the same plan the AU member does, in their own language, at the same time. Vietnamese is a first-class output language, not a translation layer bolted on.
- **Per-party language** (`language_per_party`) — each invited party has a captured reading language; the plan renders to each in their language. Captured, not assumed (honest-partial — the plan does not guess a party's language from their location).
- **Shared, invited participation** (`shared_dashboard_invited_parties`) — the VN parent / family council are invited into the shared plan view with a named role and language, so decisions and documentation happen in one place rather than over fragmented private channels (which is where the source-of-funds paper trail gets lost).

## Why the bilingual norm is load-bearing, not cosmetic

If the VN-side funder can only see an ad-hoc translated summary, three things break: the **consultation** that decision-authority requires can't happen in time; the **source-of-funds** documentation the parent must supply gets coordinated over scattered messages instead of the shared plan; and the family makes a large, irreversible commitment on an asymmetric understanding of the figures. Co-equal bilingual output is what makes the cross-border family a single decision unit — hence `bilingual_coordination_required = true` whenever a non-English-reading party is a contributor or decision-maker.

This is the [`family_context`](../../blueprints/fhb-foreign-au.md) surface's reason to be **central** in the Mode-B UI (the `family-view-card` renderer, "Family view (central)"). The engine produces the bilingual content at the source (every localized field is `{vi,en}`); this doc supplies the *coordination norms* that decide when the bilingual view is active and who is in it — it does not itself carry copy (bilingual copy is produced by the `kb.copy.*` templates + engine, as for every KB doc).

## The timezone / cadence pattern

A VN–AU family spans up to a few hours' timezone offset plus asymmetric working hours; a required sign-off (an unconditional auction bid, a settlement authorisation) needs a **realistic response window** built in, not a same-day assumption. This is the *channel/cadence* half of the consultation-timing input — the settlement critical path ([`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md)) sizes the money buffer; this doc flags that the *human* sign-off also needs lead time on the bilingual channel.

## Relevance for the Vietnam-parent-funded buyer (Mode B)

- **Same plan, two languages, at once.** The differentiator is that the VN-side funder participates as a peer reader of the same figures — not a recipient of a translated recap. That is what lets consultation and documentation happen on time.
- **Capture the language, don't guess it.** Each party's reading language is captured; the plan renders per-party. Location is not language.
- **One place, not scattered channels.** Inviting the VN party into the shared plan is where the source-of-funds trail and the decision sign-off stay legible — a coordination norm with a regulated pay-off (owned by the AML source-of-funds docs, cross-referenced).

## Rules

Pure-reference (`fills: []`). `family_context` reasons over these norms to set `bilingual_view_active` / `bilingual_coordination_required`, to capture `language_per_party`, and to build the invited shared view. All parameters are `CONVENTION` (coordination norm), surfaced as decision-support; the settlement sequencing and the source-of-funds substance are owned elsewhere and cross-referenced.

```jsonc
{
  "fills": [],
  "parameters": {
    "bilingual_view_is_co_equal_not_translated": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the plan presents {vi,en} co-equally at the source so a VN-side party reads the same figures/plan as the AU member, in their language, at the same time — Vietnamese is a first-class output language, not a translation layer (engine produces {vi,en}; copy owned by kb.copy.*)." },
    "language_per_party_is_captured_not_assumed": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "each invited party's reading language is captured and the plan renders per-party; the plan does not infer language from location (honest-partial)." },
    "bilingual_coordination_required_when_non_english_party": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "bilingual_coordination_required = true whenever a non-English-reading party is a contributor or decision-maker — the condition co-equal bilingual output exists to satisfy." },
    "communication_layer_distinct_from_settlement_sequencing": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc owns the communication coordination (who/which language); the money/legal critical-path order + 14-day buffer is owned by kb.cross-border-settlement.coordination-best-practices — the conversation vs the sequence, single-owner split." },
    "cross_timezone_signoff_needs_lead_time": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a VN-side sign-off (auction bid, settlement authorisation) needs a realistic response window on the bilingual channel — the human half of the consultation timing input (authority owned by kb.cross-border.decision-authority-cultural)." }
  }
}
```

Notes:

- **No `fills`; a coordination-norm doc.** It owns the *communication* layer; settlement sequencing → [`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md); decision authority/timing → [`kb.cross-border.decision-authority-cultural`](decision-authority-cultural.md); source-of-funds substance → [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md).
- **Bilingual is load-bearing, not cosmetic.** Co-equal {vi,en} is what makes the cross-border family a single, timely decision unit — the norm carries the consultation and the documentation, not just the display.
- **Carries no copy.** Coordination norms only; the bilingual copy itself is produced by the `kb.copy.*` templates + engine, as for every KB doc.

## Sources

Behavioural / reference doc — no regulator publishes bilingual coordination norms. The related regulated/sequencing substance is sourced in its single owners:

- [`kb.cross-border-settlement.coordination-best-practices`](../cross-border-settlement/coordination-best-practices.md) — the two-country settlement critical path + buffer.
- [`kb.cross-border.decision-authority-cultural`](decision-authority-cultural.md) — decision authority / consultation timing.
- [`kb.au-aml-ctf.source-of-funds-documentation`](../au-aml-ctf/source-of-funds-documentation.md) — source-of-funds evidence (kept legible in one shared place).
