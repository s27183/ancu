---
slug: kb.fx.rba-aud-vnd
effective_from: 2026-10-16
last_verified: 2026-10-18
sources:
  - url: https://www.rba.gov.au/statistics/frequency/exchange-rates.html
    retrieved: 2026-10-18
    path: docs/sources/rba/exchange-rates-2026-10-18.txt
    quotes:
      - "Units of Foreign Currencies per Australian Dollar 14 Oct 2026 15 Oct 2026 16 Oct 2026"
      - "Vietnamese dong 18131 17997 17970"
---

# AUD/VND — the RBA's reference rate, read weekly

This doc owns **one reading of the Reserve Bank of Australia's daily reference rate for the Vietnamese dong**: how many dong one Australian dollar bought on the latest date the RBA published when the weekly kb-watch routine last read it. It is the rate any VND display of a plan figure reads (VND conversion is shown nowhere yet: `format.ts`, `onboarding.ts`). The plan's own figures are AUD ranges and use no rate.

It does **not** own what a buyer pays to convert: the spread and transfer fees are owned by [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md). The RBA rate is a mid-market reference; no bank or transfer service converts at it.

## The reading

On **16 October 2026** the RBA's reference rate was **17,970 dong per Australian dollar** (14 Oct: 18,131; 15 Oct: 17,997). The RBA publishes these rates daily, except on public and bank holidays observed in New South Wales.

## Cadence

Behavior 85 (Son 2026-10-16): the rate moves daily, so the weekly kb-watch routine re-reads it every run (cadence `weekly` in `tests/kb_freshness.py`) and replaces this reading with the RBA's latest, quoting the page's row from its saved copy. A reading older than 8 days is overdue.

## Rules

Pure-reference. `vnd_per_aud` is the latest reading; a VND display multiplies an AUD figure by it and says it is the RBA reference rate on `as_of`, not a conversion price.

```jsonc
{
  "fills": [],
  "parameters": {
    "vnd_per_aud": { "type": "number", "value": 17970, "provenance": "REGULATED", "note": "RBA daily reference rate for the Vietnamese dong, VND per AUD, on as_of." },
    "as_of": { "type": "string", "value": "2026-10-16", "provenance": "REGULATED", "note": "the RBA's publication date of vnd_per_aud." }
  }
}
```

## Sources

- Reserve Bank of Australia — *Exchange Rates* (daily reference rates, Vietnamese dong row) — https://www.rba.gov.au/statistics/frequency/exchange-rates.html
