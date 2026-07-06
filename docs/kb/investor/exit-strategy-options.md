---
slug: kb.investor.exit-strategy-options
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-events
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
---

# Exit strategy options

An investment without a planned exit is a position without a thesis. This doc owns the **exit-strategy taxonomy** — the ways an investor realises (or deliberately defers realising) the return, the primary exit and its fallback, and what each implies for tax, cash, and the next move. It grounds `investment_strategy.exit_strategy.primary_exit` and `secondary_exit_if_primary_fails`, and informs the `disposition` component's dispose-phase reasoning. It is a **reference** doc — it asserts no figure; the tax consequence of an actual sale (CGT) is owned by the tax cluster and applied by `disposition`. Informational; not advice on when or whether to exit.

## Primary exit options

The blueprint enum is `sell_at_target_growth | hold_perpetually | leverage_into_next_property | rent_perpetually | transfer_to_family`:

- **`sell_at_target_growth`** — sell once the property hits a growth target, realising the gain. Triggers a CGT event (50% discount if held >12 months — [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md), applied by `disposition`) and selling costs. The cleanest realisation; the return is crystallised and taxed.
- **`hold_perpetually`** — never sell; the return is the compounding equity and (eventually) unencumbered rental income. No CGT event while held; estate/transfer planning becomes the eventual question.
- **`leverage_into_next_property`** — don't sell; **release equity** to fund the next deposit and scale the portfolio ([`kb.investor.scale-up-using-equity`](scale-up-using-equity.md)). No CGT event; the constraint is serviceability and LVR ([`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)), and the risk is over-leverage / cross-collateralisation.
- **`rent_perpetually`** — hold purely for income; the exit is "there isn't one, by design". Suits a `cash_flow` thesis where the property pays for itself indefinitely.
- **`transfer_to_family`** — pass to children/family (gift, sale, or via estate). A transfer is generally a **CGT event at market value** for the transferor (other than on death, where a different rollover may apply) — a nuance owned by the tax cluster and requiring a tax/legal adviser. A common intent for the Vietnamese-Australian intergenerational-wealth motive.

## Secondary (fallback) exits

When the primary exit doesn't materialise — growth stalls, cash flow tightens — the fallback matters. The enum is `sell_at_loss | hold_longer | convert_to_ppor | subdivide_or_renovate`:

- **`sell_at_loss`** — accept a capital loss to exit; the loss offsets other capital gains ([`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md) sibling rules). The capitulation option.
- **`hold_longer`** — extend the horizon and wait out the cycle; only viable if the household can keep funding any shortfall.
- **`convert_to_ppor`** — move in; changes the tax character (partial main-residence exemption may apply going forward — owned by [`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md)). Available only to a domestic (resident) investor, i.e. Mode C, not Mode D.
- **`subdivide_or_renovate`** — a `value_add` pivot to manufacture the value the market didn't deliver.

## Exit must match the thesis and the hold

The exit isn't chosen in isolation — it must agree with the archetype ([`kb.investor.strategy-archetypes`](strategy-archetypes.md)) and the hold period ([`kb.investor.hold-period-considerations`](hold-period-considerations.md)). A `cash_flow` thesis naturally pairs with `rent_perpetually`; a `capital_growth` thesis with `sell_at_target_growth` or `leverage_into_next_property`. The agent flags incoherent pairings.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Every plan names an exit.** The plan states the primary exit and a fallback, so the investor knows how the return is realised — not just how the property is acquired.
- **Intergenerational transfer is a first-class option.** "Transfer to family" is named explicitly, with the flag that a transfer is generally a CGT event (adviser needed) — matching a common Vietnamese-Australian motive.
- **Equity recycling is an exit, not just a sale.** The plan treats "leverage into the next property" as a deliberate exit path, pointing to scale-up and serviceability.
- **No advice on timing.** The plan lays out the options and their consequences; it does not advise when or whether to exit. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the exit enums are investor inputs informed by this taxonomy, and the tax consequence of an actual disposal is owned by the tax cluster and applied by `disposition`.

```jsonc
{
  "fills": [],
  "lookup": {
    "primary_exit_options": {
      "note": "the primary_exit enum and each option's realisation / tax / next-move implication",
      "entries": [
        { "exit": "sell_at_target_growth", "realises": "yes — crystallised gain", "tax": "CGT event (50% discount if >12mo) + selling costs", "owner": "disposition / kb.tax.cgt-50-percent-discount" },
        { "exit": "hold_perpetually", "realises": "no sale — compounding equity + eventual unencumbered income", "tax": "no CGT event while held", "owner": "estate/transfer planning later" },
        { "exit": "leverage_into_next_property", "realises": "no sale — equity release to scale", "tax": "no CGT event", "owner": "kb.investor.scale-up-using-equity; constraint kb.lender.serviceability-investment-loans" },
        { "exit": "rent_perpetually", "realises": "income only — no exit by design", "tax": "ongoing rental income", "owner": "cash_flow thesis" },
        { "exit": "transfer_to_family", "realises": "pass to family", "tax": "generally a CGT event at market value (death rollover differs) — adviser needed", "owner": "tax cluster" }
      ]
    },
    "secondary_exit_options": {
      "note": "fallback exits if the primary fails",
      "entries": [
        { "exit": "sell_at_loss", "implication": "capital loss offsets other capital gains; capitulation" },
        { "exit": "hold_longer", "implication": "extend horizon; viable only if shortfall fundable" },
        { "exit": "convert_to_ppor", "implication": "changes tax character (partial main-residence exemption); Mode C only — kb.tax.cgt-main-residence-exemption" },
        { "exit": "subdivide_or_renovate", "implication": "value_add pivot to manufacture value" }
      ]
    }
  },
  "parameters": {
    "exit_must_match_thesis_and_hold": { "type": "bool", "value": true, "note": "primary exit must cohere with the archetype (kb.investor.strategy-archetypes) and hold period (kb.investor.hold-period-considerations); the agent flags incoherent pairings" },
    "transfer_to_family_is_a_cgt_event": { "type": "bool", "value": true, "note": "a transfer to family is generally a CGT event at market value for the transferor (death rollover differs) — flagged, adviser required; detail owned by the tax cluster" }
  }
}
```

Notes:

- **No `fills`.** The exit enums are investor inputs informed by this taxonomy; the tax consequence of an actual disposal is owned by the tax cluster and applied by `disposition`.
- **Single-owner via cross-ref.** Sale CGT → `kb.tax.cgt-50-percent-discount` (applied by `disposition`); convert-to-PPOR → `kb.tax.cgt-main-residence-exemption`; equity scale-up → `kb.investor.scale-up-using-equity`; serviceability → `kb.lender.serviceability-investment-loans`. This doc owns the exit taxonomy.
- **No timing advice.** Options and consequences only; the plan does not advise when or whether to exit.

## Sources

- ATO — *CGT events* (a disposal — sale or transfer — is a CGT event; transfer at market value) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-events
- ASIC Moneysmart — *Investing in property* (having an exit plan; the costs of selling) — https://moneysmart.gov.au/property-investment/investing-in-property
