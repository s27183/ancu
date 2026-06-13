# 03 — Strategy: positioning, risks, wedge sequence

> Part of the **Vietnamese Diaspora Property Platform — Research & Strategy** document set. See [README.md](README.md) for the full index.
>
> **This document covers:** Strategic positioning (the five moats + augmentation framing), REA partnership economics (two-tier complementary model), policy intelligence as secondary moat, hard truths and cross-border / FIRB-specific risks, and the 30-month four-wedge build sequence.
>
> **Related documents:** [02-competitive-landscape.md](02-competitive-landscape.md) (the channel chain analysis this strategy operationalises), [architecture/architecture.md](architecture/architecture.md) (technical strategy that enables this business strategy), [04-ux-model.md](04-ux-model.md) (user-facing instance of this strategy).

---

## 8. Strategic positioning

### Recommended positioning

**"Vietnamese property lifecycle planning service — AI-augmented planning for the Vietnamese diaspora investing in Australian property, with human-curated property search when buyers are ready. Independent. Paid by users."**

Critically, this is a **lifecycle planning service**, not a property tech platform. We do not compete on property data acquisition (REA / Domain / CoreLogic own that market and we have no leverage to acquire data at the scale they operate). We compete on **Vietnamese demand aggregation + cultural curation + agentic lifecycle planning** — where we have unique strength.

The product splits into:

- **Base plan** — property-agnostic, AI-augmented, available immediately to anyone matching one of the four user modes. Generates eligibility, scheme stacking (Mode A), FIRB compliance (Mode B / D), cross-border family coordination (Mode B), investment strategy (Mode C / D), tax structure, cash position against a *target price range* (not a specific price). Map view surfaces a **suburb-intelligence overlay** (investment grade, rental yield, family-friendly, Vietnamese-community proximity) sourced from public data feeds, not property listings.
- **Tìm Nhà** ("Find a Home") — human-curated property search **service**, agent-invoked when the user is ready for specific properties. Vietnamese-speaking curators manually search REA / Domain / partner REA inventory and return a shortlist matched to the user's plan. Paid per engagement ($200–500). See [§11.11 in architecture/architecture.md](architecture/architecture.md#1111-tìm-nhà-property-search-service--agent-invoked-human-curated).
- **Property addenda** — once a user attaches a specific property (via Tìm Nhà handoff, URL paste, or browser extension on REA / Domain), the plan card gains a property-specific addendum filled by the planning agent (property_assessment, buying_strategy, due_diligence, settlement_prep, ownership_planning).

Five defensible moats:

1. **Cultural + linguistic vertical.** Vietnamese-language, Vietnamese family financial pattern fluency, cross-border family coordination. Aussie cannot credibly replicate this. HTAG is English/professional. ChatGPT is generic. Nobody serves this segment with depth.
2. **No referral fees, no loan upsell.** Buyers (Vietnamese-Australian and Vietnam-located) are the customer. REAs are advertisers / distribution partners under independence-preserving fee structures (see §8.5). Every incumbent (Aussie, Lendi, brokers, comparison sites, bank apps) is conflicted by funnel economics.
3. **Lifecycle continuity.** Persistent agent from student-in-AU through PR through citizenship through FHB through investor — a 10–25 year customer relationship within one community. No incumbent does this.
4. **Cross-border family coordination.** An agent holding context simultaneously for the buyer / student in AU and the funding parents in Vietnam, coordinating the family financial decision across two jurisdictions, two languages, two regulatory regimes. Genuinely unique flow.
5. **Augmentation network effect.** Vietnamese-community REAs, mainstream REAs, Vietnamese-speaking lawyers, conveyancers, and FIRB-eligible developers all become more efficient through the platform. Each partner makes the platform more valuable to the next. Aussie cannot replicate this without committing to multi-decade Vietnamese-community partnership — and even then their broker-funnel incentive structure would conflict.

6. **Demand aggregation as primary asset.** The platform's data moat is *Vietnamese buyer demand* (rich profiles, plan cards, intent), not property listings. Buyer demand is something REAs cannot supply themselves and will pay to access. This inverts the usual platform problem: instead of paying for property data, we sell access to demand. The asset compounds with every Vietnamese buyer who completes a base plan, regardless of whether they ever attach a specific property.

### 8.4 The augmentation positioning — not disintermediation

The platform's role in the Vietnamese property ecosystem is **augmentation**, not disintermediation. Every participant in the current channel chain ([§6.8 in 02-competitive-landscape.md](02-competitive-landscape.md#68-the-current-vietnamese-buyer-channel-structure)) — community REAs, mainstream REAs, Vietnamese-speaking lawyers, conveyancers, immigration agents, developers — has a clearer, more profitable role with the platform than without it.

The mental model:

- The current chain is not broken because participants extract rent. It is inefficient because each participant has to do everything (community trust + cultural translation + document expertise + inventory channel + transaction execution) without scale or AI-native tools.
- The platform does not replace participants — it gives each participant better tools and a more focused role.
- The chain transforms into a network. The network is more efficient. Everyone earns more by doing less, more often.

Why this matters for positioning:

1. **Community trust requires it.** Vietnamese business culture is reciprocal and relationship-based. Adversarial framing toward Vietnamese-community REAs would trigger community resistance no marketing budget could overcome.
2. **Vietnamese-community REAs are first-tier partners, not displaced incumbents** (see §8.5). They have the most acute pain in the current model and the most to gain from platform partnership.
3. **Mainstream REAs gain access to demand they cannot currently reach.** They want to transact with Vietnamese buyers but lack the language / cultural / FIRB interface. The platform provides it.
4. **Naturally squeezed participants are narrow** — pure information-asymmetry arbitrageurs (introduction-fee-only middlemen). These adapt or fade as buyers gain direct access. No platform action required.
5. **The pitch is not "we disrupt the chain"** — it is *"we give every participant in the Vietnamese property journey better tools and clearer roles. The chain becomes a network. The network becomes more efficient. Everyone earns more by doing what they're best at."*

This positioning enables partner-led growth (which scales faster than confrontation-led growth) and avoids the trap of looking like another foreign-VC-funded disruptor entering a tight-knit cultural community.

### Monetisation paths that preserve independence

- **Subscription** during active period: $15–30/month for 12–24 months
- **One-time success fee** at settlement: $500–1,000
- **B2B white-label** for super funds, credit unions, employer benefits programmes
- *Avoid* affiliate/lead-gen revenue — destroys the independence story

### Differentiation vs incumbents

| vs | Their position | Your edge |
|---|---|---|
| Aussie | Broker funnel | Independent, no loan upsell |
| Lendi Guardian | Mortgage-app-centric | Full lifecycle, broader scope |
| HTAG | Investors / professionals | Consumer first home buyers |
| Proper Inspect / DocoCheck | Point document tools | Continuous companion with journey context |
| Bank apps (CBA Buy a Home) | Product-locked | Lender-agnostic |
| ChatGPT (generic) | No domain depth, no state | Current Australian data, persistent state |
| firsthomebuyers.gov.au | Federal only, informational | State + federal, action-oriented |

### 8.5 REA partnership economics — two-tier complementary model

REAs are partners and platform users, not customers. Vietnamese buyers are the customer. The fee structure enforces this separation while creating genuine value for both REA tiers.

The two tiers serve complementary roles. A single transaction may involve a Tier 1 REA (for cultural mediation and high-touch settlement support) and a Tier 2 REA (for the actual listing inventory). Three distinct value layers — community trust, broader inventory, platform intelligence — three earning participants, no zero-sum.

#### Tier 1 — Vietnamese-community REAs (cultural specialists)

**Who:** Vietnamese-speaking REAs based in Vietnamese-community suburbs (Cabramatta, Inala, Springvale, Bankstown, Footscray, Richmond, Sunshine).

**Their refined role:** Community trust, family dynamics mediation, in-language negotiation, high-touch settlement support, in-language presence at auctions / inspections.

**What they currently struggle with:**
- ~12–30 transactions/year per agent
- ~60% of time on activities that don't directly produce commissions (document explanations, scheme questions, FIRB hand-holding, family coordination)
- Limited inventory beyond their personal network
- Earning purely from network gatekeeping commission

**What the platform provides them:**
- Vietnamese-language qualified buyer pipeline (scaled demand)
- AI document review, scheme stacking, FIRB workflow tools they cannot build alone
- Broader inventory access through platform aggregation
- Co-marketing in Vietnamese-language editorial content
- Focus shift from "do everything yourself" to "do what only you can do"

**Pricing:**

| Component | Fee |
|---|---|
| Basic platform access + tools | $100–300/month subscription |
| Qualified buyer connection (buyer-initiated) | $50–150 per connection |
| Vietnamese co-marketing featured placement | Optional $200–500/month (with sponsored disclosure) |

**Why they are first-tier partners:** Tier 1 REAs have the most acute pain in the current model. They are also the platform's most credible community-trust ambassadors. Their endorsement opens the Vietnamese-Australian community in a way no marketing budget can. They become the early adopters in months 0–6 of Wedge 1.

#### Tier 2 — Mainstream REAs (inventory + institutional discipline)

**Who:** Established Australian REAs with broader inventory and process discipline — Ray White, McGrath, Belle, Place, Jellis Craig, LJ Hooker, Barry Plant, Stockdale & Leggo, Marshall White, and similar.

**Their refined role:** Inventory channel, market making, institutional transaction discipline, scale.

**What they currently struggle with:**
- Vietnamese buyers feel "high friction" — language gap, longer transaction times, FIRB complexity, cultural unfamiliarity
- Many agents avoid CALD buyers because of perceived friction cost
- They cannot build a Vietnamese-language buyer pipeline on their own (their offices are not Vietnamese-speaking; their marketing is English; their CRM doesn't capture cultural-mediation needs)
- They lose Vietnamese buyer demand to Tier 1 niche networks even when their inventory is the better fit

**What the platform provides them:**
- Vietnamese-language interface to qualified buyer demand they currently cannot reach
- FIRB workflow pre-handled (foreign-person status confirmed, approval already underway, fees calculated)
- Cultural mediation already done by the platform or a Tier 1 partner — they receive a buyer who is ready to transact
- Documentation pre-vetted (Vietnamese-language plain-English summaries of contracts, building reports, strata reports)
- Family coordination handled — they deal with one decision-maker, not a fragmented family

**Pricing:**

| Component | Fee |
|---|---|
| Office subscription | $500–1,500/month per office |
| Qualified buyer connection (buyer-initiated) | $100–250 per connection |
| Featured listing placement in suburb pages | Optional $300–800/month (with sponsored disclosure) |

**Why they come second:** Tier 2 onboarding starts at month 6–9 of Wedge 1 once buyer-side traction is visible. They will not subscribe until the platform demonstrates Vietnamese buyer volume.

#### Independence guardrails (apply to both tiers)

- **Buyer chooses; REA pays when chosen.** Never "REA pays to be recommended" or "REA pays per-property-sold."
- **Flat fees, not percentage of sale.** Platform incentive does not bend toward higher-price properties.
- **All listings shown on equal footing.** Partner REA listings get badge / featured treatment but never exclusive recommendation. Non-partner listings remain analyzable.
- **Disclosure mandatory.** Sponsored placement always labelled.

These guardrails enforce the buyer-trust relationship that is the actual moat. REA revenue is channel + cost-recovery (~20% of total revenue target), not primary monetisation.

#### Channel-cost transparency for buyers

The platform's value to buyers includes showing them what they currently pay vs what they would pay direct. A typical Vietnamese parent funding a $1M apartment for their child currently pays $50–150k in cumulative channel fees (see [§6.8 in 02-competitive-landscape.md](02-competitive-landscape.md#68-the-current-vietnamese-buyer-channel-structure)). Platform-direct path with optional Tier 1 REA mediation is 30–60% of that. This is not disruptive marketing — it is information that buyers do not currently have.

#### Rough revenue sanity check (Year 2)

| Source | Volume | Per-unit | Annual |
|---|---|---|---|
| Vietnamese-AU FHB base plan subscriptions (Wedge 1) | 2,000 paying | $300 blended ARPU | $600k |
| **Tìm Nhà property search service** (Mode A users → Phase B) | 800 engagements | $350 | $280k |
| Document review one-time fees (per property addendum) | 5,000 reports | $40 | $200k |
| Settlement success fees | 200 settlements | $750 | $150k |
| Vietnam-parent transaction fees (Wedge 2) | 300 transactions | $1,000 | $300k |
| Tier 1 REA subscriptions | 40 agents | $200/mo | $96k |
| Tier 2 REA subscriptions | 20 offices | $800/mo | $192k |
| Co-marketing (both tiers) | 25 agents | $400/mo | $120k |
| Qualified connection fees (both tiers) | 800/yr blended | $150 | $120k |
| **Year-2 revenue mix** | | | **~$2.06M, REA = ~26%** |

The **Tìm Nhà property search service** (~$280k) is a meaningful new revenue line — high-margin (human curation cost ~$50–100/hour × ~2 hours per engagement), defensible (Vietnamese cultural fluency in curation), and naturally bridges base-plan users into property addenda. REA share at ~26% sits comfortably below the structural-bias threshold. The model becomes less REA-dependent and more user-pay, which strengthens the independent positioning.

#### Distribution flywheel

Tier 1 REAs become community-trust ambassadors in Vietnamese-community suburbs. Tier 2 REAs gain access to demand they cannot reach alone. Both refer the platform forward to their professional networks (Vietnamese-speaking lawyers, conveyancers, developers with FIRB-eligible new builds). The network compounds.

This is what Aussie cannot replicate — their broker-funnel incentive structure prevents the cooperative two-tier model. They would have to choose between Tier 1 (commission share) and Tier 2 (institutional partnerships) and would lose the cultural-vertical positioning either way.

### 8.6 Policy intelligence as a secondary moat

A unique consequence of building an AI agent that touches every step of the journey at individual-buyer granularity: **the agent generates a dataset that no policymaker, bank, or broker currently has access to**.

What this dataset uniquely contains:

- **Case-level friction events** — where scheme rules conflict, confuse, or compound for specific buyer profiles
- **Real-time policy response data** — how buyer behaviour shifts the day a threshold moves (compare with ABS quarterly data lagged 3–6 months)
- **Scheme combinations actually used** — vs. designed-for usage patterns
- **Cognitive gap data** — what buyers misunderstand at each phase, with frequency and stake-level
- **Lender selection patterns** — which institutions actually approve which buyer profiles in the wild

This contrasts with what aggregate sources provide. The ABS, RBA, Treasury, and consultancy researchers (KPMG, Cotality, PropTrack) operate on directional, lagged, aggregated data. Notably the **ABS moved from monthly to quarterly Lending Indicators reporting in December 2024** ³⁸ — public-data granularity has actively decreased.

**Commercial implications:**

1. **Annual "State of First Home Buying" report** — public, branded, becomes a reference document. Finder's annual FHB report (cited throughout this brief) drives significant earned PR and authority.
2. **Productivity Commission / Treasury / Senate submissions** — establishes the agent as the authoritative voice on journey-level data.
3. **Paid research access** for super funds (member outcomes), large employers (benefits design), state revenue offices (scheme design feedback), banks (product-market fit signals).
4. **Op-ed and PR pipeline** — positions the brand as "the journey expert," driving organic acquisition for the core product.
5. **Policy partnership opportunities** with Housing Australia and state agencies wanting to model scheme interactions before designing new ones.

**Strategic framing:** the value proposition to policymakers is **not** "we know things you don't" (which ages poorly and risks burning bridges). It is **"we have a real-time, case-level data feed of the buyer journey that no other source provides."** Position as collaborator, not critic.

This is a moat and a brand strategy, not merely a product feature. It is lower-friction to build than competing head-on with Aussie on broker funnel economics, and aligns naturally with the independent-co-pilot positioning.

---

## 9. Hard truths and risks

### 9.1 Original FHB-scope risks (still apply)

1. **Distribution is harder than product.** Aussie has 1M customers and brand. Lendi has scale. CBA touches every Australian. A startup's distribution path is content + SEO + word-of-mouth + REA partnerships — slow build over 2–3 years. Vietnamese community channels help but don't eliminate this.

2. **One-time customer problem.** Individual buyers go through FHB once. The Vietnamese-diaspora expansion *mitigates* this (lifecycle continuity across student → FHB → investor → cross-border) but doesn't eliminate per-segment one-shot dynamics.

3. **Scheme rules change constantly.** Eight jurisdictions × federal × bank-specific policies × FIRB regime × Vietnamese-side regulations. Keeping the agent current requires RAG over official sources + monthly verification scripts + change alerting on AU + VN sides.

4. **AU regulatory boundary.** Under ASIC, cannot give "financial advice" or "credit advice" without an AFSL or ACL. Stay strictly informational ("decision support, not advice") or get licensed (~6–12 months, six figures of legal/compliance cost). The line is real and crossing it carries personal liability.

5. **AI hallucination cost is high.** Wrong FHG eligibility advice, wrong FIRB status determination, wrong scheme-stacking math = real-world damage. Need strong grounding, verification steps, and "confirm with broker / state revenue office / FIRB / immigration lawyer" patterns baked in.

6. **The Aussie pivot is the existential threat (English segment).** They've stated the strategy publicly, have capital, brand, and broker distribution. Window is probably 2–3 years before they figure out the UX. The Vietnamese-diaspora positioning is the defense — Aussie cannot credibly serve this segment.

### 9.2 Cross-border and FIRB-specific risks (new, critical)

The expansion to Vietnam-located buyers and foreign-person flows materially increases regulatory complexity. These are not theoretical risks; they're operational realities the platform must handle correctly or face serious consequences.

**FIRB compliance for foreign persons:**

- The platform must accurately determine each user's FIRB status (citizen / PR / temporary resident / non-resident) on first interaction
- **From 1 April 2025 to 30 June 2029, foreign persons cannot purchase established dwellings** ⁵¹. Misadvising a Vietnamese student or Vietnam-located parent that they can buy an established home = penalty risk, real harm.
- New-build purchases by foreign persons require **FIRB approval BEFORE contract** with fees that scale by property value. The platform must integrate this into product flows (don't let users sign contracts without confirming FIRB compliance).
- Vacancy fees apply (double the original FIRB application fee for vacancies starting 9 April 2024) — relevant for investor segment.

**AML/CTF on cross-border funds:**

- Helping coordinate $500k–$2M of capital flow from Vietnam into Australian property touches Anti-Money Laundering and Counter-Terrorism Financing rules on both jurisdictions.
- The platform is not a money-transmission service — but advising on transfer mechanisms, account structures, and source-of-funds documentation requires care.
- AUSTRAC (AU) and SBV (Vietnam State Bank) regimes intersect here.
- Banks will conduct enhanced due diligence on Vietnamese-source funds for AU property; platform should pre-educate users to prepare proper documentation rather than discover the gap at settlement.

**Vietnamese data sovereignty:**

- Vietnam's **Personal Data Protection Decree (Decree 13/2023/ND-CP)**, effective 1 July 2023, regulates collection, processing, storage, and cross-border transfer of personal data of Vietnamese citizens.
- If the platform serves users physically in Vietnam, this regime applies. Cross-border data transfer requires Impact Assessment + government notification.
- Practically: this may require Vietnamese-side data residency (Vietnam-based servers for VN-located user data) and Vietnamese-language consent flows.

**Vietnamese capital controls:**

- Vietnam has strict outbound currency rules. Sending large sums abroad to fund property requires SBV approval thresholds and documentation.
- The platform must guide users through legitimate transfer mechanisms (international student tuition fees, family remittance, FDI declarations) rather than informal routes.
- Wrong guidance = breaches of Vietnamese law for users.

**AU tax for non-residents:**

- Non-resident buyers face higher stamp duty (foreign-buyer surcharge varies by state: NSW 8%, VIC 8%, QLD 8%, etc. on top of standard duty)
- Different CGT treatment, withholding tax on rental income
- No CGT main residence exemption for non-residents
- These need accurate modelling in property analysis flows for foreign-person segments

### 9.3 Recommended mitigations

| Risk | Mitigation |
|---|---|
| FIRB misadvice | First-class user attribute "FIRB status" gates every property recommendation flow; mandatory FIRB-approval-confirmed checkpoint before any contract action |
| AML/CTF | Stay in advisory/education lane; never custodian of funds; integrate with reputable money-transfer partners (Wise, OFX, partner banks) rather than building transfer functionality |
| VN PDP | Vietnam-located data residency for VN-located users; Vietnamese-language consent flows; legal review by Vietnam-licensed counsel |
| VN capital controls | Educate users on legitimate channels; refer to Vietnamese banks/SBV for definitive guidance; never recommend informal transfer routes |
| Non-resident tax | Integrate non-resident stamp duty surcharge into all property analysis for foreign-person flows; flag CGT main-residence implications |
| Advisory positioning | Bilingual disclaimers; "decision support" framing; partnership with Vietnam-licensed legal counsel for high-stakes guidance |
| HTAG investor competition | Vietnamese-language + family-pattern fluency + cross-border integration. Don't compete head-on on portfolio analytics depth; compete on cultural-vertical fit. |

### 9.4 What this changes for the build

These regulatory realities have product implications:

- **FIRB status as foundational user attribute** (not optional, not late-added). Every property analysis flow branches on it.
- **Vietnam-side legal counsel partnership** from day 1 of Wedge 2 (parent funding). Not optional.
- **Geographic data residency capability** in user state schema from Wedge 2 launch.
- **Established vs new-build segmentation** in property data — foreign-person flows automatically filter to new builds only (until 30 June 2029).
- **Bilingual disclaimers and consent flows** as L1 KB content.
- **Money-transfer partnership** (Wise/OFX equivalent) integrated as Layer 3 flow before launching Wedge 2.

None of this is insurmountable, but it explains why **Wedge 2 (Vietnam-parent) follows Wedge 1 (Vietnamese-AU FHB), not parallel.** Wedge 1 proves the language/cultural product; Wedge 2 adds the regulatory machinery on top.

---

## 10. Build strategy & wedge sequence

The goal is end-to-end coverage of the Vietnamese diaspora property journey across four core segments (Vietnamese-Australian FHBs, Vietnamese students in AU, Vietnam-located parents funding AU property, Vietnam-located investors). The risk is launching too broad and trying to serve all four segments simultaneously. The discipline is to be 10× better at one segment + one entry point, build trust, and let users pull the product into adjacent segments.

The product is built on a unified platform with mode-switching by user location and intent (Option A — see [§13 in 04-ux-model.md](04-ux-model.md)). All four segments share the same Layer 1 KB, Layer 2 schema, Layer 3 reasoning infrastructure ([§11 in architecture/architecture.md](architecture/architecture.md#11-architecture--interaction-model)), and context-and-flow architecture ([§12 in architecture/architecture.md](architecture/architecture.md#12-context-and-flow-are-the-moats)). What changes per segment is which flows are active and which user-state fields matter.

### 10.1 The 30-month wedge sequence

```
                          0─────6─────12────18────24────30+ months
                          │     │     │     │     │     │
Wedge 1: Vietnamese-AU    ████████████████              
         FHB property                                    
         analysis                                        
                                                          
Wedge 2: Vietnam-parent          ████████████████        
         funding flow                                    
                                                          
Wedge 3: AU + VN investor                  ████████████████  
         platform                                        
                                                          
Wedge 4: Multi-CALD                              ████████████  
         expansion                                       
```

Each wedge layers on cultural + linguistic + product trust earned by the previous. By month 30 the Vietnamese diaspora platform is mature; multi-CALD extension begins.

### 10.2 Wedge 1 — Vietnamese-Australian FHB lifecycle planning (months 0–14)

**Target segment:** Vietnamese-Australian citizens and PRs buying their first home in Australia.

Wedge 1 is **sub-phased** to match the property-data-light architecture. The base plan ships fast because it has no property data dependency; specific-property features layer on as REA partnerships and user-facing tooling mature.

#### Wedge 1a — Base plan (months 0–6)

**What it does:** Plan-first onboarding — user selects mode, state, target price range (VND with AUD auto-conversion), and target zone (map click or address). Agent generates the **base plan**: eligibility (FHG / FHSS / state concessions), cash math against target price range, scheme stack, target criteria refined, optional family-funding context. Map view shows **suburb-intelligence overlay** (investment grade, rental yield, family-friendly, Vietnamese-community proximity) sourced from public data feeds. Zero property data dependency.

**Ships in 4–6 weeks with Claude Code** because the offline KB agent only needs to curate scheme rules + suburb enrichment + FX feed — no property scraping pipeline.

**Pricing:** Free base plan (maximises demand aggregation, which IS the asset), with tiered subscriptions — **Plus $25/month** (decision-trail history, comparison views) and **Pro $49/month** (Tìm Nhà priority, higher quota). Per-tier token limits bound compute cost; the tier table and the measured cost basis are in [`architecture/billing.md`](architecture/billing.md).

#### Wedge 1b — Tìm Nhà property search service (months 3–6)

**What it does:** Vietnamese-speaking curator team manually searches REA / Domain / Vietnamese-community REA networks based on the user's base plan criteria. Returns a shortlist of 3–5 matched properties. Agent generates the search brief from base plan state; agent processes returned shortlist into ranked recommendations against plan.

**Why this timing:** Base plan demand needs ~3 months to aggregate before Tìm Nhà has a queue to serve. Launching parallel to Wedge 1a would burn the human team on too few engagements.

**Pricing:** $200–500 per engagement. See [§11.11 in architecture/architecture.md](architecture/architecture.md#1111-tìm-nhà-property-search-service--agent-invoked-human-curated).

#### Wedge 1c — User URL paste + browser extension (months 6–12)

**What it does:** Phase B property addendum activation for users who already have a specific property in mind. URL paste handler fetches a single page synchronously; browser extension on REA / Domain captures listing context with one click. Agent runs property-specific components (property_assessment, buying_strategy, due_diligence) and adds the addendum to the user's plan card.

**Why this timing:** Once base plan demand is real, individual users start bringing their own properties from REA / Domain. The URL-paste path is foundational for these users — they don't need Tìm Nhà because they've already found something.

**Pricing:** Document review $40 one-time per property addendum (Section 32 / Contract of Sale); success fee $500–1,000 at settlement.

#### Wedge 1d — REA partner inbound push (months 9–18)

**What it does:** Tier 1 + Tier 2 partner REAs push inventory directly to the platform via API or batch upload. Properties surface in the user's base plan map view ("matching your criteria from partner REAs") and in the Tìm Nhà curator's search universe. This is the eventual property data path — when partnership economics are visible enough to attract Tier 1 community REAs.

**Why this timing:** Partner REAs only commit inventory when they see qualified Vietnamese buyer demand. Months 6+ have demonstrable demand; this is when the partner pitch lands.

**Pricing for REAs:** §8.5 two-tier structure ($100–300/mo Tier 1, $500–1,500/mo Tier 2, $50–250 per qualified connection).

#### Why this sub-phasing matters

- **Wedge 1a ships in 4–6 weeks** (vs the original 8–12 weeks for property-first). Base plan is unblocked by property data complexity.
- **Tìm Nhà becomes a profitable bridge** between base plan and property addenda — high-margin service that grows with base-plan adoption.
- **No load-bearing property pipeline** — by the time we need partner REA inventory (1d), we have demand traction to attract it.
- **Validates demand aggregation** as the primary asset before committing to expensive data infrastructure.

**Validation test:** SEO + community partnerships (Vietnamese-Australian community organisations, immigration lawyers, education agents in Vietnam) targeting Vietnamese buyers in Cabramatta, Inala, Springvale, Bankstown, Footscray, Richmond. Measure base-plan completion → Tìm Nhà conversion → settlement.

### 10.3 Wedge 2 — Vietnam-parent funding AU property (months 8–22)

**Target segment:** Vietnamese parents in Vietnam funding their student/PR child's first home or apartment in Australia.

**What it does:** Cross-border family coordination — agent simultaneously holds context for the parent in Vietnam and the child in Australia, navigates FIRB approval (mandatory for foreign persons), explains the established-dwelling ban (1 April 2025 – 30 June 2029), models new-build options that comply with FIRB, coordinates the funding flow (Vietnamese banking, currency transfer, AML/CTF compliance), produces Vietnamese-language analysis for parents and English/Vietnamese for child.

**Why second (not first):**

- Highest-WTP segment (parents will pay $500–1,500 per transaction)
- Zero competition (nobody serves Vietnamese-language cross-border family property coordination)
- But adds regulatory complexity (FIRB, AML, VN PDP) that benefits from Wedge 1 having proven the language/cultural fit first
- Plus, Wedge 1 customers (Vietnamese-AU students/PRs) often have parents who become Wedge 2 customers → built-in cross-sell

**Pricing:** Cross-border transaction guidance $500–1,500 per family event; FIRB approval workflow assistance bundled.

**Distribution channels:**

- Vietnamese-Australian student communities (refer parents)
- Vietnamese-language education agents (in Vietnam) — natural cross-sell from student-visa advisory
- Vietnamese-language immigration lawyers
- Vietnam-side Facebook parent groups
- Vietnamese diaspora media (Tuoi Tre, Thanh Nien diaspora editions)

### 10.4 Wedge 3 — Vietnamese investor platform (months 14–28)

**Target segment:** Vietnamese investors in Australia (citizen/PR investors graduating from FHB) AND Vietnam-located investors buying AU property as investment.

**What it does:** Property investment analytics in Vietnamese (yield modelling, depreciation, negative gearing, capital growth projections). FIRB-aware (for Vietnam-located investors, foreign-buyer rules and fees integrated). Tax planning for Vietnamese-Australian residents AND Vietnamese non-residents. Portfolio dashboard. Off-the-plan new-build inventory featuring partner REA listings (where Vietnamese are already 8–10% of buyers).

**Why third:**

- Different product surface (portfolio analytics, not FHB scheme stacking)
- Different team competence required (yield modelling, tax planning, depreciation schedules)
- Direct competition exists (HTAG AI Copilot, launched Feb 2026, English-focused for investors)
- But Vietnamese is the 4th largest foreign buyer cohort with no Vietnamese-language alternative
- Customer lifecycle continuity — Wedge 1 FHB graduates and Wedge 2 parents become Wedge 3 investors

**Pricing:** Subscription $200–500/month; transaction-based fees for property analysis at $100–300 per property; partner REA featured listings ($300–800/month from REAs, see §8.5).

**Competitive position vs HTAG:** Vietnamese language + Vietnamese family financial pattern fluency + cross-border tax planning. HTAG is English/professional/AU-resident-focused.

### 10.5 Wedge 4 — Multi-CALD expansion (months 22–30+)

**Target segments:** Other large CALD communities in Australia using the proven Vietnamese playbook — Mandarin (largest, but most competitive), Cantonese, Punjabi, Hindi, Arabic, Filipino.

**What it does:** Same product framework, additional language + cultural layers. Each CALD expansion is incremental — same Layer 1 KB, additional translation + cultural curation, additional community-specific flows.

**Why last:**

- Vietnamese playbook must be proven first
- Each CALD addition requires significant cultural curation (not just translation)
- Different communities have different financial patterns, family structures, regulatory exposures
- Brand positioning needs to extend from "Vietnamese diaspora" to "CALD diaspora" deliberately

**Recommended sequence within Wedge 4:**

1. Mandarin (largest TAM but most competitive — Chinese investors are #1 foreign buyers)
2. Punjabi / Hindi (large communities, growing student volumes, less competition)
3. Arabic, Filipino, Cantonese
4. Long tail of smaller communities

### 10.6 Full lifecycle vision (year 3+)

Once Wedges 1–4 are proven, the lifecycle continuity moat fully compounds. A single Vietnamese-Australian customer might pass through:

- Student in AU (Wedge 1 lite — content + free tier)
- 485 graduate + first home (Wedge 1 paid)
- Refinance graduate (Wedge 1 background tier)
- Investment property (Wedge 3 paid)
- Multi-property portfolio (Wedge 3 premium)
- Wealth transfer back to family in Vietnam (cross-border Wedge 2 inversion)

10–25 year customer relationships within one cultural community, with cross-segment customer flows (Wedge 1 customers refer Wedge 2 parents; Wedge 1 graduates become Wedge 3 investors).

### 10.7 Why this sequence (and not another)

- **Vietnamese-AU FHB first** — lowest regulatory exposure, established community, validates the language/cultural play before adding cross-border complexity. Best place to fail cheaply if the cultural product fit isn't there.
- **Vietnam-parent second** — highest-WTP but adds FIRB/AML/cross-border complexity. Best built on top of proven Wedge 1 customers who naturally refer their parents.
- **Investor third** — different product surface, direct competition, requires deeper financial sophistication. Built on top of Wedge 1 graduates who naturally become investors.
- **Multi-CALD last** — extends the proven playbook to adjacent communities only after Vietnamese version works.

Launching all four simultaneously fails because: (a) regulatory complexity multiplies, (b) product surfaces diverge too much, (c) marketing/distribution channels split attention, (d) no single segment is excellent. The wedge sequence is the discipline that protects focus while building toward the full vision.

> See `first_home_buyer_plan.html` (Strategy tab) for an interactive visualisation of the wedge timeline alongside the differentiation matrix and REA partnership economics.

---

