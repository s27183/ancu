# Agentic Boundary — when the engine reasons vs computes

Every operation that responds to a user runs in one of two modes:

- **Resolver** — a deterministic function of structured inputs evaluated against a fixed rule set. Includes arithmetic, lookups, copies, *and* a rules engine (eligibility predicates, scheme-stacking constraints). Reproducible, free, auditable, no LLM.
- **Agent** — adaptive reasoning over context an LLM produces. Non-deterministic, metered, slower.

This document is the decision rule for which mode an operation belongs to. It governs the blueprint (`agent_reasoning_required` flag), the engine (`fill_path`, `usage` metering), and KB curation (what must be encoded as rules). For *how* the decision is encoded, see [architecture.md §11.9](architecture.md#119-blueprint-as-data-model--presentation-specification) and [engine-contract.md §4](engine-contract.md). This is a standalone test on purpose — the same rule is applied in three places and must not drift between them.

---

## The rule

> **Reserve agentic action for operations whose output cannot be produced by evaluating rules over structured inputs — operations that require adaptive reasoning over context. Everything else is the resolver, no matter how large the rule set.**

The default is resolver. The burden of proof is on making something an agent operation. *The agent earns its place only where the rules run out.*

## The test — three triggers

An operation is agent-path **iff** it clears at least one:

1. **Unstructured input** — it must interpret free text, a document, or a messy real-world artifact into structured meaning (the *significance* of a building-report defect; a free-text question). Note: extracting raw facts from a document is **input normalisation**, upstream of both paths (architecture.md §11.9) — what makes interpretation agent-path is judging *what the facts mean for this buyer*.
2. **Under-determined by rules** — the rules do not pin a unique answer; there is a genuine judgment or trade-off over soft criteria (is this asking price fair against noisy comps? which negotiation style fits this market?).
3. **Open-ended query** — the user asks something no component schema anticipated; the system must reason over current context to answer.

If none hold, it is resolver — *even if the rule set is large or intricate*. Eligibility criteria, scheme-stacking constraints, serviceability formulas, stamp-duty brackets, and settlement-date dependencies are all rules.

## Forcing-function question

Before flagging any operation agent-path, ask: **could a fixed set of rules over structured inputs produce this output?** If yes, it is resolver, and a flag is a bug. If the rules merely *aren't encoded yet*, that is a KB-curation gap, not an agent operation — see the fallback below.

---

## Boundary — worked categories (Mode A)

| Operation | Path | Why |
|---|---|---|
| Eligibility determination (`fhg.eligible`, FHSS, state concession, Help to Buy) | **Resolver** | published criteria are predicates over profile + property |
| Scheme stacking — which combination, what order | **Resolver** | constraint-satisfaction over a handful of encoded schemes |
| Cash position, stamp duty, LMI, borrowing capacity, bid ceiling, dates | **Resolver** | arithmetic / serviceability formula / date engine |
| Suburb factors, property basics, document facts | **Resolver** | copies / lookups (`<from_suburb>`, `<from_property_card>`, `<from_document>`) |
| Valuation read — is this price fair? | **Agent** | under-determined over noisy comparables |
| Lender fit — will this income be accepted, by whom? | **Agent** | lender overlays: messy, semi-public, under-determined |
| Negotiation style + decoding the agent's tactics | **Agent** | adaptive over live market context |
| Document significance — what in the S32 matters here | **Agent** | unstructured + under-determined |
| Free-text Q&A anywhere in the flow | **Agent** | open-ended |

---

## Two refinements

### Agent-as-fallback closes the KB-curation loop

When an encoded rule is **silent or ambiguous** on a predicate (e.g. does prior *overseas* property ownership break first-home status for a given scheme?), the resolver cannot answer and **escalates to the agent**. That is correct behaviour — but the resolution must then be **curated back into the KB as a rule**, so the next occurrence is deterministic. The agent is the fallback for un-encoded rules, not a substitute for encoding them. Over time the resolver's coverage grows and the agent's eligibility surface shrinks toward zero.

### Two agent roles — leaf fill vs conversation

The agent does two distinct things; both are agent-path but they are not the same operation:

- **Adaptive leaf fill** — producing the value of an `agent_reasoning_required` parameter during a turn (valuation, lender fit, negotiation style).
- **Open-ended Q&A over the filled card** — answering "why no FHOG?", "will my contractor income work?", "is $700k too much?". The card itself is a deterministic artifact; the conversation about it is adaptive.

Filling the plan card is mostly rules; *conversing about it* is the agent.

---

## Worked simulation — the validating case

This case was used to confirm the rule; keep it as the canonical end-to-end test (cf. the testing approach in CLAUDE.md).

**Linh, 29.** Vietnamese-Australian, PR since 2023. Software contractor, 18-month ABN (Melbourne). Co-buying with her partner (citizen, PAYG). HECS $24k, car loan $9k, $40k cash + $60k parental gift (landed 3 weeks ago). Established house in St Albans, asking $700k. Previously owned and sold an apartment in Saigon.

| Step | Path | Note |
|---|---|---|
| Onboarding, profile fields | **R** | form copy |
| Parse uploaded NOA / contractor financials | **E** | extraction (LLM upstream, meters) — not a fill path |
| `firb_status` (PR ⇒ not foreign) | **R** | `derived_from` predicate |
| FHG / FHSS / VIC duty eligibility; FHOG rejected (established) | **R** | predicates + bracket formula |
| Scheme stack + application order | **R** | constraint-satisfaction |
| Cash position, stamp duty after concession, totals, verdict | **R** | arithmetic |
| Settlement dates + milestone graph | **R** | date engine |
| Is $700k fair for this house? | **A** | valuation, under-determined |
| Will an 18-month-ABN contractor income be accepted, and by whom? | **A** | lender overlays |
| Auction vs offer; decode the agent | **A** | adaptive |
| What in the S32 / building report matters for Linh | **A** | unstructured + significance |

Two near-misses that **stay resolver** and prove the rule:

- **The $60k gift** — whether it counts as genuine savings is a rule (≈3-month seasoning); landed 3 weeks ago ⇒ "not yet". No reasoning. The agent enters only if Linh *asks why*.
- **The Saigon apartment** — whether prior *overseas* ownership breaks first-home status is a rule **if the KB encodes it per scheme**. If the KB is silent, the agent escalates (fallback), and we then encode the rule.

Conclusion: the agent surfaces at exactly four places — **valuation, lender fit, negotiation, document significance** — plus the cross-cutting **Q&A layer**. Everything else is rules.

---

## What this rules out

- Sending eligibility, scheme math, stamp duty, or any arithmetic through the LLM. Non-reproducible, costly, and — for money/eligibility figures — a compliance hazard (ASIC: figures must be computed, not asserted).
- Flagging a leaf `agent_reasoning_required` because it is "uncertain" or "needs filling". Uncertainty is not the test; *irreducibility to rules* is.
- Using the agent where a rule is merely **un-encoded**. Encode it. The agent is the fallback that triggers encoding, not the permanent home for the rule.
- Treating document extraction as agent reasoning. Extraction is input normalisation (architecture.md §11.9); only interpreting significance is agent-path.
