# First Home Buyer AI Agent — Research Findings & Strategic Brief

**Date:** May 2026
**Author:** Strategic research synthesis
**Scope:** Australian first home buyer (FHB) market — schemes, journey, competitive landscape, gap analysis, and recommended product wedge for an AI agent

---

## Executive summary

The Australian Vietnamese-diaspora property intelligence opportunity is structurally unserved. Vietnamese-Australian and Vietnam-located buyers, students, and investors are large and growing segments that no incumbent currently addresses with language + cultural fluency + agentic intelligence + lifecycle continuity.

**The market reality (verified May 2026):**

- **Vietnamese-Australian community: 318,760 Vietnam-born + 334,781 Vietnamese ancestry**; 6th largest migrant community; Vietnamese is the 4th most spoken non-English language at home ⁴⁹
- **Vietnamese are the 4th largest foreign buyers** of Australian residential property (behind China, Hong Kong, Singapore); 8–10% of all off-the-plan apartment purchases; 15% YoY growth in 2022–23 ⁵⁰
- **60% of Vietnamese property purchases in Australia are for accommodation/education, 30% investment, 10% migration** ⁵⁰
- **Federal FIRB ban on established dwellings for foreign persons (1 April 2025 – 30 June 2029)** — temporary residents (students, 485-visa holders) and Vietnam-located buyers are restricted to new builds only ⁵¹
- **First Home Guarantee expanded Oct 2025** — citizens can buy with 5% deposit, no LMI, up to $1M in QLD / $950k in VIC ¹ ²
- **First home buyer knowledge gap is dramatic** — 88% misunderstand LMI, 66% don't know what conveyancing means, 45% regret their purchase ¹⁵

**The opportunity:**

A **Vietnamese-language property intelligence platform with Australian focus, serving the Vietnamese diaspora globally** — from Vietnamese-Australian first home buyers through students-planning-to-settle through Vietnam-located parents-funding-children through Vietnam-located investors. One unified platform, multiple modes by user location and intent, shared knowledge base + agentic infrastructure, distinct UX surfaces per segment.

The product is **paid by users, not by REAs or lenders**. REAs partner for distribution and listing exposure under independence-preserving fee structures (flat connection fees, not commission share). Property data sourced via user-pasted URLs, browser extension on REA/Domain pages, and partner REA listings.

**Why this is defensible:**

- Zero direct competitor across the four core segments
- Cultural + linguistic moat compounds with accumulated user data
- Lifecycle continuity moat unique to a community-scoped platform (vs Aussie's transaction focus)
- Cross-border family coordination flow is genuinely novel
- Architectural separation of context (data) + flow (engineering) protects the IP from LLM commoditisation

---

## 1. Federal scheme landscape (verified May 2026)

### 1.1 First Home Guarantee (FHG) — overhauled 1 October 2025

The single biggest 2025 change to the Australian FHB landscape. ¹ ² ³

- **Income cap REMOVED** (was $125k single / $200k couple)
- **Place cap REMOVED** (was 35,000/year)
- **Property price caps raised substantially:**
  - Sydney + NSW regional centres: **$1,500,000**
  - Brisbane + QLD regional centres (Gold Coast, Sunshine Coast): **$1,000,000**
  - Melbourne + Geelong: **$950,000**
  - Perth: **$850,000**
  - Adelaide, Hobart, Canberra: lower capital-city tiers
  - Darwin: $750,000 (from 1 July 2026); rest of NT: $600,000
- **Mechanism:** 5% deposit, government guarantees up to 15% of property value (18% for single parents), borrower avoids LMI
- **Eligibility:** Must be Australian citizen (NZ Special Category Visa holders also eligible); permanent residency alone does NOT qualify
- **Application:** Via participating lender, not direct to Housing Australia

### 1.2 Help to Buy — launched December 2025

Federal shared-equity scheme. ⁴ ⁵

- **Income caps RETAIN:** $100,000 single, $160,000 couples / single parents
- **Deposit:** 2% minimum
- **Government equity stake:** up to 40% for new homes, 30% for existing
- **Places:** 10,000/year (capped)
- **Participating lenders at launch (Dec 2025):** Commonwealth Bank, Bank Australia
- **Coverage:** All states/territories except Tasmania (pending enabling legislation)
- **Restriction:** Owner-occupier only; not for investment

### 1.3 First Home Super Saver Scheme (FHSS) — unchanged

ATO-administered tax-effective deposit savings vehicle. ⁶

- **Annual contribution cap:** $15,000 (counts toward concessional cap)
- **Lifetime release cap:** $50,000 (raised from $30,000 on 1 July 2022)
- **Tax treatment:** Released amount appears as assessable income with 30% tax offset
- **Process:** Request determination → receive release → must sign contract within 12 months (extendable once)

---

## 2. State scheme landscape

### 2.1 Queensland — most generous in Australia (2026)

#### First home concession (established homes) ⁷

- **Under $700,000:** full exemption (saves up to $24,525)
- **$700,000 – $800,000:** sliding concession
- **Above $800,000:** general home concession applies (smaller benefit)

#### First home (new home) concession — effective 1 May 2025 ⁸

**Most significant 2025 change.** Full transfer duty concession on new homes or vacant land for new build, **with no price cap**. Combined with FHG, this unlocks the highest practical FHB purchase ceiling in Australia.

#### First Home Owner Grant

Currently $30,000 for eligible new builds (boosted from $15k base rate). ⁴

### 2.2 Victoria — middle of the pack

#### First home buyer duty exemption/concession ⁹

- **Under $600,000:** full exemption
- **$600,000 – $750,000:** sliding concession
- **Above $750,000:** no FHB concession (full duty applies)
- Thresholds unchanged since 2017

#### First Home Owner Grant

$10,000 for new builds under $750,000.

#### Other

VIC Homebuyer Fund (shared equity) effectively wound down following federal Help to Buy launch.

### 2.3 Combined scheme stacking — practical impact

For a Brisbane new-build buyer with a $50k cash deposit at $1.0M price:

- Federal FHG: 5% deposit, no LMI → $50k covers deposit
- QLD first home (new home) concession: $0 stamp duty
- Total cash needed at settlement: ~$50k deposit + ~$20k buffer = **~$70k**

For a Melbourne new-build buyer at $750k price:

- Federal FHG: 5% deposit, no LMI → $37.5k
- VIC FHB concession: sliding scale, partial duty
- $10k First Home Owner Grant
- Total cash needed: ~$55–65k

QLD provides materially better outcomes for FHBs willing to buy new builds in 2026, due to the uncapped new-home concession.

---

## 3. The temporal transaction flow (full lifecycle)

The home buying journey involves four primary actor groups across five phases. See the interactive HTML plan (`first_home_buyer_plan.html`) for the swimlane visualisation.

### Actors

- **Buyer (you)**
- **Government** — Housing Australia (federal), Queensland Revenue Office / State Revenue Office Victoria (state), local council, ATO
- **Lender** — FHG-panel bank
- **Other parties** — broker, conveyancer, real estate agent, building inspector, insurer, strata corporation, utilities

### Phases

1. **Prepare** (weeks 0–4): document gathering, FHSS contributions, credit cleanup, broker engagement
2. **Pre-approval** (weeks 4–8): lender application, FHG slot reservation, budget confirmation
3. **Contract** (weeks 8–12): offer + sign, deposit to trust, inspections, insurance arrangement
4. **Settle** (weeks 12–18): loan release via PEXA, title transfer, stamp duty payment, keys handed over
5. **Own** (month 4+, ongoing): mortgage repayments, rates, insurance, maintenance, eventual refinance

### Pre-purchase financial readiness

Cash requirement beyond the deposit itself:

| Item | Cost |
|---|---|
| Building & pest inspection | $500–700 |
| Conveyancing | $1,500–2,500 |
| Lender application/settlement fees | $500–1,000 |
| State registration fees | ~$400–700 |
| First-year building insurance | $800–1,500 |
| Utility connections | $200–500 |
| Moving costs | $500–3,000 |
| 3-month cash reserve | $15,000–18,000 |
| **Total buffer beyond deposit** | **$19,000–28,000** |

Lenders increasingly require evidence of post-settlement cash reserves as part of serviceability assessment.

### Ongoing obligations

- **Monthly:** mortgage P&I to lender; utilities
- **Quarterly:** council rates; water access charge; strata levies (if applicable)
- **Annually:** building insurance premium; mortgage statement review; tax return; land tax check (typically $0 for PPOR)
- **Event-driven:** refinancing (~every 2–4 years); the "graduation event" when LVR drops below 80% (FHG ends, free market refinance available)
- **Maintenance reserve:** ~1% of property value per year

---

## 4. First home buyer pain points — quantified

Finder's First Home Buyer Report 2025 ¹⁵ ¹⁶ provides the most current quantification of the knowledge gap:

### Knowledge gaps

| Misconception | Affected |
|---|---|
| Lenders Mortgage Insurance protects the borrower | **88%** |
| Don't know there's no cooling-off period after auction | **85%** |
| Don't know you pay the deposit on auction day | **78%** |
| Don't know what conveyancing means | **66%** |
| Don't know what an offset account is | **63%** |

### Behavioural and emotional patterns

- **47%** paid more than budgeted (up from 38% in 2022)
- **45%** regret their purchase
- **38%** bought because of FOMO ("worried prices would keep rising")
- **35.4%** cannot save deposit due to high rents and expenses absorbing income
- **20.4%** believe mortgage repayments would be unmanageable
- **12.1%** lack the borrowing capacity required

### Affordability backdrop

- Suburbs where the average Australian can afford the median house: **57% in 2017 → 16% in 2025**
- Equivalent for units: **66% → 28%**

### Implication for AI agent design

The knowledge gap is not a "nice to address" — it's the central product opportunity. An agent that closes these specific gaps (LMI, conveyancing, auction mechanics, offset accounts) at the right moment in the journey has strong intrinsic value before any other functionality is added.

---

## 5. Market sizing and demand trends (verified May 2026)

### 5.1 Annual transaction volumes

Australian first home buyer loan settlements by year ³⁷ ³⁸:

| Year | Approx FHB loans | Notes |
|---|---|---|
| 2021 | ~165k | Peak — COVID stimulus + record-low rates; FHB share of owner-occupiers hit ~35% |
| 2022 | ~110k | Sharp fall as rates rose |
| 2023 | ~95k | Trough year; $59B total lent |
| 2024 | ~120–135k | Slow recovery as rates plateaued |
| Q4 2025 | 31,783 (quarter) | +6.8% QoQ — biggest quarterly growth in 2 years |
| Q1 2026 | -4.3% QoQ, +5.0% YoY | Cooled but still up year-on-year |

The October 2025 FHG expansion is **measurably moving the market**. The ABS explicitly credits the December 2025 quarter result to the scheme overhaul ³⁷. Industry reporting confirms the entry-level segment is "heating up" with FHG-eligible properties seeing increased competition ³⁹.

### 5.2 Market share and demographic profile

- **First home buyers represent 29.6% of all owner-occupier lending** (Cotality, Q4 2025) ⁴⁰
- **Average FHB age: 33 years** (was ~29 a decade ago) ⁴¹
- **Average FHB loan size: ~$607k** in Q4 2025, up 8.5% in a single quarter — a record ³⁷
- **60% of FHBs purchase with someone else** (spouse, friends, family) — sole buyers are now a minority ⁴¹
- **75% buy in metropolitan areas** — steady since 2021 ⁴²
- **Average FHB deposit: ~16%** — above the 5% FHG minimum, suggesting many save more than required ⁴¹

### 5.3 Affordability context

- **Only 12% of Australian homes are affordable for the average first home buyer** (KPMG, December 2025) ⁴³
- **Suburbs where the average Australian can afford the median house: 57% in 2017 → 16% in 2025** ¹⁵
- Some analysts forecast the FHB market may not fully recover until 2030 absent further structural reform ⁴⁴

### 5.4 Implications for the product opportunity

**Total addressable market (TAM):**

- Active FHB transactions: ~120–135k/year
- Aspirational / preparation cohort (typically 3–5× active buyers): ~360–675k people at any time
- Adjacent segments (refinancers, second-home buyers, investors, renovators): adds millions

**Revenue sizing for an AI agent business:**

| Model | Per-user ARR | 5% capture | 10% capture |
|---|---|---|---|
| Subscription ($20/mo × 12 mo) | $240 | ~$1.5M ARR | ~$3M ARR |
| Success fee at settlement ($500–1,000) | $500–1,000 | ~$3–7M/yr | ~$6–13M/yr |
| Both (subscription + success) | $740–1,240 | ~$4.5–8M/yr | ~$9–16M/yr |

This sizes to a **small-to-mid-size SaaS opportunity** at FHB-only scope — a credible business, not a VC-blockbuster unless expanded to adjacent journeys. The October 2025 reform creating measurable demand growth provides favourable timing for entry.

### 5.5 Notable structural shifts to monitor

- **ABS shifted Lending Indicators from monthly to quarterly reporting in December 2024** ³⁸. Public-data granularity has *decreased* — a strategic gap an AI agent with real-time individual-journey data can fill (see §8.6).
- **Federal commitment to build 100,000 homes for FHB sale below market** (announced 2025, available from 2028 onwards) ⁴⁸. This will reshape the supply side and creates a future product surface.
- **"First home buyer stimulus runs dry"** narrative emerging in May 2026 commentary ⁴⁶ — political pressure mounting for further reform, suggesting more scheme churn ahead.

### 5.6 The Vietnamese-diaspora property segment

The platform's primary market is the Vietnamese diaspora globally, with Australian property as the focus. Four distinct customer segments share language, culture, and a unified knowledge substrate.

#### Vietnamese-Australian community (citizens + PRs)

- **318,760 Vietnam-born** people in Australia at June 2024; up 39.5% from 2014; 6th largest migrant community ⁴⁹
- **334,781 with Vietnamese ancestry** (2021 Census, 1.3% of Australian population) ⁴⁹
- **320,670 speak Vietnamese at home** — 4th most spoken language after English, Mandarin, Arabic ⁴⁹
- Geographic concentration: Sydney has the largest community; Melbourne has 90,552 Vietnam-born; Brisbane, Adelaide, Perth all have meaningful clusters
- Median age 47.4 (~9 years above general population) → first-generation parents now reaching peak property-decision wealth, second-generation children entering FHB age
- Strong cultural emphasis on home ownership; multi-generational financial pooling is common

#### Vietnamese international students (temporary residents)

- Australia's 2026 international student cap raised to **295,000** (+9%), with **explicit priority for Southeast Asian source countries including Vietnam** ⁵²
- Vietnam is consistently in the top 5 source countries for Australian student enrolments
- Many on 485 graduate visa pathway intending to convert to PR
- Subject to **FIRB foreign-person rules** — banned from purchasing established dwellings 1 April 2025 – 30 June 2029, but can buy new builds with FIRB approval ⁵¹
- A 3–5 year nurture cohort with low CAC and high conversion to FHB stack later

#### Vietnam-located parents funding AU children's property

- ~5 million overseas Vietnamese diaspora globally; significant capital flow from Vietnam to Australia for property funding children's accommodation and education
- 60% of Vietnamese property purchases in Australia are for accommodation/education purposes ⁵⁰
- Major family decision with crushing information asymmetry — parents in Hanoi or Saigon navigating Australian property markets through their child
- Subject to FIRB rules (foreign persons): banned from established, can buy new builds with FIRB approval, must register and pay FIRB fees (scale with property value)
- Highest-WTP segment on the platform — $500–2,000 per transaction is realistic given stakes

#### Vietnam-located investors

- **Vietnamese are the 4th largest foreign buyers** of Australian residential property (behind China, Hong Kong, Singapore) ⁵⁰
- **8–10% of all off-the-plan apartment purchases** in Australia are Vietnamese ⁵⁰
- 15% YoY growth in property purchases in 2022–23 ⁵⁰
- Sweet spot: $800,000–$1.2M apartments (US$ equivalent) ⁵⁰
- VIC alone saw 10–12% YoY growth in apartments sold to Vietnamese in 2024
- Subject to FIRB rules: new builds only, FIRB fees, vacancy fees if unoccupied
- 30% of Vietnamese AU property purchases are explicit investment plays ⁵⁰
- **Direct competitor: HTAG AI Copilot (English/professional)** — but no Vietnamese-language alternative exists

### 5.7 Implications for product opportunity

**Total addressable market (Vietnamese-diaspora property platform):**

| Segment | Active TAM | Aspirational/pipeline TAM | Per-customer LTV |
|---|---|---|---|
| Vietnamese-Australian FHB | ~5–8k/year | ~30–50k preparation cohort | $740–1,360 |
| Vietnamese international students | ~30–40k current + pipeline | Annual intake 8–12k+ | $200/yr × 3–5 yrs nurture + later FHB stack |
| Vietnam-located parents | ~3–5k transactions/yr | Tens of thousands considering | $500–2,000 per transaction |
| Vietnam-located investors | ~5–8k/year | Significant Vietnam wealth pipeline | $200–500/mo × 24 mo = $4,800–12,000 |

Combined SAM is materially larger than English-FHB-only TAM (~$30M ARR at 100% capture) and more defensible given competitive whitespace.

### 5.8 FIRB regime — the regulatory shape of the market

A defining constraint across non-citizen segments. The platform must treat FIRB status as a first-class user attribute that gates every product flow.

| User type | FIRB classification | Can buy established? | Can buy new build? | Must pay FIRB fees? |
|---|---|---|---|---|
| Australian citizen | Not foreign person | Yes | Yes | No |
| Permanent resident | Not foreign person | Yes | Yes | No |
| Temporary resident (student, 485 visa) | Foreign person | **No** (banned through 30 Jun 2029) | Yes with FIRB approval | Yes (scale with value) |
| Non-resident (Vietnam-located buyer) | Foreign person | **No** (banned through 30 Jun 2029) | Yes with FIRB approval | Yes (scale with value) |

The ban on established dwellings is in force from **1 April 2025 to 30 June 2029** ⁵¹. This pushes the entire non-citizen Vietnamese segment toward new-build product, which aligns with QLD's uncapped first-home (new-home) concession (citizens) and FIRB-approved foreign-buyer new dwellings.

The vacancy fee — double the original FIRB application fee for vacancies beginning 9 April 2024 — is a particular pain point for Vietnamese investor segment (often buying for future use, sometimes leaving properties unoccupied) and a product opportunity (proactive alerts, occupancy planning).

---

## 6. Competitive landscape

### 6.1 Government tools

- **firsthomebuyers.gov.au** ¹⁷ — official federal hub. Covers FHG, Help to Buy, FHSS. Per-scheme eligibility tools. Strengths: authoritative, free. Weaknesses: federal only (no state schemes), no lifecycle, no decision support beyond yes/no eligibility.
- **State revenue offices** (QRO, SRO, etc.) — own-jurisdiction scheme info. Fragmented across 8 jurisdictions.

### 6.2 Calculators

Stamp duty calculators are well covered across all 8 states/territories:

- stampdutycalcs.com.au ¹⁸
- money.com.au stamp duty calculator
- calculatorsaustralia.com.au
- WealthWorks, Property Investment Professionals, others

All are single-purpose (price in, duty out). None integrate FHG or planning.

### 6.3 Bank apps

- **CommBank "Buy a Home"** ¹⁹ — in-app journey tracking, borrowing power, application status. Strength: integrated with banking. Weakness: locked to CBA product.

### 6.4 Aggregators and broker platforms

- **Aussie "Find, Buy, Own" platform** ²⁰ ²¹ — explicit strategic pivot announced 2024 to become a "fully integrated property ecosystem." Mobile app with 11M property listings, value/equity tracking, broker connection. **The closest direct competitor.** ~1M customers.
- **Lendi "Guardian" agentic AI** ²² — production-ready AI system for personalised mortgage journey guidance. Lendi Group is Aussie's parent.
- **Canstar, Finder, Compare the Market** — comparison content + lead gen. Heavy SEO presence.

### 6.5 AI-native point tools (Australia)

- **HTAG AI Copilot** ²³ — launched February 2026. **First vertically integrated AI agent for Australian real estate.** Targets buyers' agents, investors, mortgage brokers. **Not first home buyers** — professional audience.
- **Proper Inspect** ²⁴ — AI review of building, pest, Section 32, contract documents. Covers all 8 states. PDF report output.
- **DocoCheck** ²⁵ — AI analysis of Contract of Sale, Section 32, vendor statements.
- **AI4Convey / triConvey AI Contract Review** ²⁶ ²⁷ — conveyancer-side AI tools.
- **AI Legal Assistant AU** ²⁸ — contract review highlighting settlement dates, conditions, red flags.

### 6.6 Fintech lending products

- **OwnHome** ²⁹ — CBA-backed deposit boost loan (up to 20% of property value). ~3,500 applications/month.
- **Tic:Toc** ³⁰ — fast online mortgage approval (22 minutes).

### 6.7 International benchmarks

- **Tomo (US)** ³¹ — AI-powered home search portal combined with mortgage. Active in ~16 US markets.
- **Habito (UK)** ³² ³³ — digital mortgage broker. £10B+ mortgages submitted, 500k customers. **Acquired by Monzo in December 2025** in Monzo's first-ever acquisition — signals the digital broker model has a ceiling without bank distribution.

### 6.8 The current Vietnamese buyer channel structure

Vietnamese are the 4th largest foreign buyers of Australian residential property (8–10% of all off-the-plan apartments). This implies established channels already connect Vietnamese capital to Australian property — channels that are functioning enough to enable thousands of transactions per year, but inefficient enough that buyers consistently overpay and under-optimise relative to what direct access would deliver.

#### Typical channel chain (Vietnam-located parent funding child's AU property)

Based on patterns observed in CALD-market property advisory and the Vietnamese community specifically:

1. Family asks community: *"Who knows about Australian property?"*
2. Referred to **Vietnamese-speaking immigration agent in Vietnam** (often handling student visa simultaneously)
3. Immigration agent introduces **Vietnamese-speaking education / migration consultant** (in Vietnam or AU-bridging)
4. Education consultant introduces **Vietnamese-speaking lawyer in Australia**
5. Lawyer introduces **Vietnamese-speaking buyer's agent in AU** (typically in Footscray, Cabramatta, Springvale, Bankstown, Inala)
6. Buyer's agent shows properties from **their network's inventory** — usually a handful of off-the-plan developments where they have established relationships with developer marketing
7. Selected property's **listing REA** (often Vietnamese-speaking in the same network) handles transaction
8. **Network conveyancer** handles settlement

Six to eight intermediaries, each adding fees, each pushing toward options inside their network rather than the optimal market choice.

#### Cost structure (estimated, validation needed)

| Cost layer | Typical fee | Captured by |
|---|---|---|
| Immigration agent (bundled with student visa) | $3,000–$8,000 | Vietnam-side intermediary |
| Education / migration consultant referral | $2,000–$5,000 | Vietnam-side or AU-bridging |
| Lawyer retainer | $3,000–$8,000 | AU lawyer |
| Buyer's agent commission | 1.5–2.5% of purchase ($15–30k on $1M) | Vietnamese-speaking buyer's agent |
| Listing REA commission (embedded in price) | 1.5–2.5% of purchase ($15–30k) | Listing REA (often same network) |
| Developer marketing margin on off-the-plan | 3–8% baked into price ($30–80k on $1M) | Developer + marketing agent |
| Conveyancing markup | $1,000–$3,000 above market | Network conveyancer |
| **Total estimated channel cost on $1M transaction** | **~$50,000–$150,000** | |

The cost is one dimension; the constraint is worse. The buyer never sees the broader market. The 5–10 properties considered are not the best 5–10 in their budget — they are the best 5–10 *within the network's inventory*. So they overpay AND under-optimise.

#### Chain comparison across the four user modes

The Mode B chain above is the most extreme case — longest chain, highest cost layers, most regulatory complexity. The other three modes have shorter chains but the same structural pattern of information-asymmetry-driven intermediation. Each mode's typical chain is mapped below.

##### Mode A — Vietnamese-Australian citizen / PR buying first home

Typical chain (4–5 steps):

1. Family and community network: *"Who's a good broker / agent?"*
2. **Vietnamese-speaking mortgage broker** (often through community referral)
3. Broker introduces **Vietnamese-speaking REA in community suburb** or works with mainstream REA where buyer has language confidence
4. Property selection from REA's network or off-the-plan partner developments
5. **Vietnamese-speaking conveyancer / lawyer** (often through broker or REA referral)

Cost layers (estimated, $1M established or $850k new build target):

| Cost layer | Typical fee | Captured by |
|---|---|---|
| Mortgage broker commission | Paid by lender (~0.5–0.7% upfront), but bias toward partner lenders | Broker |
| REA commission (embedded in price) | 1.5–2.5% of purchase ($15–25k) | Listing REA |
| Developer marketing margin (if off-the-plan) | 3–6% baked into price ($25–50k) | Developer + marketing agent |
| Conveyancing markup | $500–1,500 above market | Network conveyancer |
| **Total estimated channel cost** | **$25,000–$80,000** | |

Shorter chain than Mode B because: no immigration / education consultant needed (English-fluent and citizen / PR); no FIRB lawyer needed; no currency transfer needed; less information asymmetry overall (buyer can use REA.com.au and Domain natively, just prefers Vietnamese-speaking professionals for trust reasons).

The inefficiency here is narrower but still real: buyer sees limited inventory from the broker / REA network rather than the broader market; partner-lender bias may push to suboptimal loan terms; second-generation buyers especially may not know mainstream REA options would suit them better.

##### Mode C — Vietnamese-Australian investor (citizen / PR)

Typical chain (4–6 steps):

1. **Vietnamese-speaking accountant** (advises on entity structure, negative gearing, depreciation strategy — often the entry point because investor logic starts with tax)
2. Accountant introduces **Vietnamese-speaking buyer's agent (investment-focused)** OR investor approaches one directly
3. Buyer's agent identifies property — often new builds (depreciation), houses in growth corridors, sometimes interstate
4. **Listing REA** handles transaction (often mainstream, less Vietnamese-network constrained for investors)
5. **Tax accountant + lawyer** for entity setup if buying via trust / company / SMSF
6. Conveyancer

Cost layers (estimated, $700k investment property target):

| Cost layer | Typical fee | Captured by |
|---|---|---|
| Accountant fees (entity structuring + tax advice) | $2,000–$5,000 (legitimate work) | Accountant |
| Buyer's agent commission | $10,000–$20,000 flat OR 1.5–2.5% | Buyer's agent |
| REA commission (embedded in price) | 1.5–2.5% of purchase ($10–18k) | Listing REA |
| Developer marketing margin (if new build) | 3–6% baked into price ($20–40k) | Developer + marketing |
| Conveyancing | $1,500–$2,500 | Conveyancer |
| **Total estimated channel cost** | **$35,000–$80,000** | |

Investor chains are less culturally constrained than FHB chains because investors are typically more financially sophisticated and have been in Australia longer. Cultural fluency still helps for trust and negotiation but English-language professional services are more readily used. The buyer's agent fee is the largest discretionary cost — adds genuine value for sophisticated property selection but is often used as default rather than considered choice.

##### Mode D — Vietnam-located investor (foreign person)

Typical chain (6–9 steps) — similar length to Mode B but investor-focused intermediaries:

1. **Vietnamese investment advisor** in Vietnam (recommends Australia as destination)
2. Advisor refers to **Vietnamese-speaking AU buyer's agent** (often investment-focused, sometimes overlapping with Mode B network)
3. Buyer's agent identifies FIRB-eligible new builds (foreign persons banned from established 2025–2029)
4. **Developer marketing agent** handles off-the-plan sale (significant margin baked in for foreign-buyer-targeted developments)
5. **FIRB lawyer** mandatory for foreign person — application fees + legal fees
6. **Vietnamese-speaking AU tax accountant** for non-resident tax planning (withholding, CGT, no PPOR exemption)
7. **AU conveyancer**
8. **Currency conversion / transfer service** (Wise, OFX, or bank wire with FX spread)

Cost layers (estimated, $1M off-the-plan apartment target):

| Cost layer | Typical fee | Captured by |
|---|---|---|
| Vietnamese investment advisor fees | $2,000–$10,000 (varies widely) | Vietnam-side advisor |
| Buyer's agent commission | 1.5–3% ($15–30k) | AU buyer's agent |
| Developer marketing margin | 5–10% baked into price ($50–100k — higher for foreign-buyer-targeted inventory) | Developer + marketing |
| FIRB application fee | $15,500–$45,000+ (scales with property value; tier-based) | FIRB / ATO |
| Foreign-buyer stamp duty surcharge | 7–8% of value in NSW / VIC / QLD ($70–80k on $1M) | State revenue office |
| Non-resident tax planning fees | $2,000–$5,000 | AU tax accountant |
| Conveyancing | $1,500–$3,000 | Conveyancer |
| FX spread (typical bank wire vs interbank) | 1.5–3% ($15–30k on $1M) | Bank / FX provider |
| **Total estimated channel cost + foreign-buyer impost** | **$170,000–$300,000+** | |

Mode D has the highest total cost layers because foreign-buyer regulatory imposts (FIRB application + foreign-buyer stamp duty surcharge + non-resident tax) stack on top of normal channel costs. The platform cannot reduce the regulatory imposts (they are sovereign costs) but can dramatically reduce the *channel inefficiency* portion (better property selection, FX optimisation, FIRB workflow efficiency, transparent fee disclosure, accurate vacancy-fee planning).

##### Summary comparison

| Mode | Buyer | Chain length | Channel cost on representative transaction | Regulatory imposts | Platform value drivers |
|---|---|---|---|---|---|
| **A** | Vietnamese-AU FHB (citizen / PR) | 4–5 steps | $25–80k on $1M | None (FHG-eligible) | Broader inventory, FHG / scheme stacking, document review |
| **B** | Vietnam-parent + AU student / 485 | 6–8 steps | $50–150k on $1M | FIRB application + foreign-buyer surcharge | Cross-border family coordination, FIRB workflow, currency transfer, new-build filter |
| **C** | Vietnamese-AU investor (citizen / PR) | 4–6 steps | $35–80k on $700k | None (no foreign-person rules) | Investment analytics, tax structuring, broader inventory |
| **D** | Vietnam-located investor (foreign person) | 6–9 steps | $170–300k+ on $1M (incl. regulatory) | FIRB + foreign-buyer surcharge + non-resident tax + FX | All of Mode B + investment analytics + vacancy planning + FX optimisation |

The pattern across all four modes:

- **The longer the chain, the higher the channel cost.** Modes B and D have the most intermediaries and the highest costs.
- **Regulatory imposts amplify foreign-person costs.** Modes B and D pay 2–3× more in total when sovereign costs are included.
- **Information asymmetry is the underlying driver in all four.** The chain expands to bridge whatever gaps the buyer has — language, regulation, market familiarity, family-coordination complexity.
- **The platform's value increases with chain length.** Mode D buyers gain the most absolute dollar value from the platform; Mode A buyers gain less in dollar terms but still meaningfully improve property selection and avoid sub-optimal loan terms.

This is also why the wedge sequence (§10) matters in this specific order: Wedge 1 (Mode A — shortest chain, lowest regulatory complexity) validates the language / cultural product; Wedge 2 (Mode B — extreme cross-border chain) leverages that trust to handle the highest-value cross-border flow; Wedge 3 (Modes C + D — investor analytics + foreign-investor compliance) extends to the investment product surface; Wedge 4 (multi-CALD) replicates the playbook for other communities.

#### Why these chains persist

The chain is not a conspiracy — it is a rational response to severe information asymmetry. A Vietnamese parent in Hanoi or Saigon has:

- No fluency in English-language Australian property platforms (REA.com.au, Domain)
- No familiarity with the AU regulatory frame (FIRB, stamp duty, state schemes)
- No way to evaluate property quality in a foreign market
- Strong cultural preference for relationship-mediated decisions

Each intermediary in the chain provides genuine value — they bridge a specific information / language / trust gap. The collective inefficiency is structural, not malicious. The chain compresses naturally as the information asymmetry compresses.

#### What the platform changes — augmentation, not disintermediation

The platform does not replace participants in the chain. It gives each participant better tools, clearer roles, and access to a qualified Vietnamese buyer pool they could not previously reach individually:

- **Vietnamese buyers** gain: broader inventory visibility, real-time analysis in their language, transparent FIRB compliance, comparison across the actual market rather than only the chain's curation
- **Vietnamese-community REAs** gain: AI document / scheme / FIRB tools they cannot build alone, qualified buyer pipeline, focus on high-value cultural mediation rather than analytical work
- **Mainstream REAs** gain: Vietnamese-language interface to demand they currently cannot access, FIRB workflow pre-handled, cultural mediation already done
- **Vietnamese-speaking lawyers / conveyancers** gain: referrals with pre-vetted documentation, clearer professional role
- **Property developers with FIRB-eligible new builds** gain: direct access to Vietnamese foreign buyer demand at lower acquisition cost

The chain does not disappear — it transforms into a network where each participant has a more focused, more profitable role. See §8.4 for the positioning that follows from this analysis and §8.5 for the two-tier REA partnership model that operationalises it.

#### What naturally fades (and it is narrow)

Pure information-asymmetry arbitrageurs — referral middlemen who collect fees for introductions without value-add — see their function diminish naturally as buyers gain direct access. They can adapt (become trust-curators who refer to the platform and earn referral fees themselves) or quietly fade. Neither outcome requires platform adversarial action.

The platform's positioning is collaborative, not confrontational. Vietnamese business culture is reciprocal and relationship-based; the go-to-market strategy must match.

---

## 7. Gap analysis — full FHB journey

| # | Phase | Buyer pain | Existing tools | AI edge | Specific gap |
|---|---|---|---|---|---|
| 1 | Aspiration (–24 to –6 mo) | Affordability vs lifestyle; buy vs rent | Bank borrowing calcs (overstate); Frollo | High | No independent affordability + lifestyle synthesiser |
| 2 | Preparation (–12 to –3 mo) | HECS impact; card hygiene; FHSS timing; genuine savings; lender targeting | Brokers (conflicted); generic calcs | Very high | No "get-lender-ready" coach |
| 3 | Pre-approval + scheme stacking (–3 to –1 mo) | Doc chaos; scheme combinations; FHG slot timing | Govt scheme tools (siloed); broker work | High | No unified federal + state scheme stacker |
| 4 | Property search (–3 to settle) | Suburb risks; auction strategy; agent bluffing; strata building safety | REA / Domain (listings); CoreLogic (data); Tomo (US only) | Medium (listings dominance hard) | No buyer-side analytics layer over listings |
| 5 | Due diligence (1–2 wks post-offer) | Building/pest comprehension; strata; Section 32 / Contract of Sale | Proper Inspect, DocoCheck, AI4Convey (point tools) | Very high | No journey-aware document hub — current tools are one-shot |
| 6 | Negotiation (active) | "What to offer?"; auction nerves; conditions | Buyers' agents ($$$); blog advice | High | No real-time bid/negotiation coach |
| 7 | Settlement (4–8 wks) | PEXA opacity; conveyancer quality; insurance timing | Conveyancer admin | Medium | No transparency layer over PEXA |
| 8 | Move-in (settle to mo 3) | Utilities, council, water, strata onboarding | Direct Connect, Compare and Connect | Medium | Light gap |
| 9 | Ownership yr 1–3 | Refinance timing; rate review; offset strategy; maintenance | Aussie app (equity); bank apps; Frollo | High | No proactive refinance / rate optimiser |
| 10 | Lifecycle events (yr 3+) | 80% LVR graduation; reno vs move; investment property | Broker re-engagement | High | No agent that remembers your 5-year story |

### Where AI has real edge (recommended build focus)

1. **Document parsing in context** — not a single PDF, but your contract against your conditions against your state against your budget. Existing tools (Proper Inspect, DocoCheck) are excellent but one-shot.
2. **Cross-jurisdictional intelligence** — simultaneous modeling of QLD/VIC/NSW with full scheme stacking. No calculator does this.
3. **Lifecycle continuity** — same agent from "should I rent or buy" through "should I refinance at year 3."
4. **Personalised lender targeting** — synthesise across lender policy docs to predict approval likelihood for a specific profile.
5. **Knowledge gap closure on demand** — explain LMI, offset, cooling-off, Section 32 in user's context. Finder data confirms this is a billion-dollar education gap.
6. **Passive monitoring + proactive alerts** — scheme threshold changes, refinance windows, LVR graduation.
7. **Negotiation coaching** — real-time guidance during auctions and offer negotiations.

### Where AI does NOT have an edge (do not build)

- Property listings (REA / Domain monopoly with network effects)
- Property valuation data (CoreLogic / PropTrack own the feeds)
- Loan approval decisioning (regulated, lender-owned)
- Legal advice or formal financial advice (regulatory landmines without licensure)
- Settlement execution (PEXA, conveyancers — utility plumbing)

---

## 8. Strategic positioning

### Recommended positioning

**"Vietnamese-language property intelligence platform with Australian focus, serving the Vietnamese diaspora globally — independent, paid by users, no broker funnel."**

Five defensible moats:

1. **Cultural + linguistic vertical.** Vietnamese-language, Vietnamese family financial pattern fluency, cross-border family coordination. Aussie cannot credibly replicate this. HTAG is English/professional. ChatGPT is generic. Nobody serves this segment with depth.
2. **No referral fees, no loan upsell.** Buyers (Vietnamese-Australian and Vietnam-located) are the customer. REAs are advertisers / distribution partners under independence-preserving fee structures (see §8.5). Every incumbent (Aussie, Lendi, brokers, comparison sites, bank apps) is conflicted by funnel economics.
3. **Lifecycle continuity.** Persistent agent from student-in-AU through PR through citizenship through FHB through investor — a 10–25 year customer relationship within one community. No incumbent does this.
4. **Cross-border family coordination.** An agent holding context simultaneously for the buyer / student in AU and the funding parents in Vietnam, coordinating the family financial decision across two jurisdictions, two languages, two regulatory regimes. Genuinely unique flow.
5. **Augmentation network effect.** Vietnamese-community REAs, mainstream REAs, Vietnamese-speaking lawyers, conveyancers, and FIRB-eligible developers all become more efficient through the platform. Each partner makes the platform more valuable to the next. Aussie cannot replicate this without committing to multi-decade Vietnamese-community partnership — and even then their broker-funnel incentive structure would conflict.

### 8.4 The augmentation positioning — not disintermediation

The platform's role in the Vietnamese property ecosystem is **augmentation**, not disintermediation. Every participant in the current channel chain (§6.8) — community REAs, mainstream REAs, Vietnamese-speaking lawyers, conveyancers, immigration agents, developers — has a clearer, more profitable role with the platform than without it.

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

The platform's value to buyers includes showing them what they currently pay vs what they would pay direct. A typical Vietnamese parent funding a $1M apartment for their child currently pays $50–150k in cumulative channel fees (see §6.8). Platform-direct path with optional Tier 1 REA mediation is 30–60% of that. This is not disruptive marketing — it is information that buyers do not currently have.

#### Rough revenue sanity check (Year 2)

| Source | Volume | Per-unit | Annual |
|---|---|---|---|
| Vietnamese-AU FHB subscriptions (Wedge 1) | 2,000 active | $300 | $600k |
| Document review one-time fees | 5,000 reports | $40 | $200k |
| Settlement success fees | 200 settlements | $750 | $150k |
| Vietnam-parent transaction fees (Wedge 2) | 300 transactions | $1,000 | $300k |
| Tier 1 REA subscriptions | 40 agents | $200/mo | $96k |
| Tier 2 REA subscriptions | 20 offices | $800/mo | $192k |
| Co-marketing (both tiers) | 25 agents | $400/mo | $120k |
| Qualified connection fees (both tiers) | 800/yr blended | $150 | $120k |
| **Year-2 revenue mix** | | | **~$1.78M, REA = ~30%** |

REA share at ~30% reflects the two-tier model adding mainstream REA revenue. This sits at the upper edge of the "structural bias" threshold — manageable provided independence guardrails are enforced rigorously. If Tier 2 revenue grows disproportionately, deliberate de-emphasis required to preserve buyer-side positioning.

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

The product is built on a unified platform with mode-switching by user location and intent (Option A — see §13 UX model). All four segments share the same Layer 1 KB, Layer 2 schema, Layer 3 reasoning infrastructure (§11), and context-and-flow architecture (§12). What changes per segment is which flows are active and which user-state fields matter.

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

### 10.2 Wedge 1 — Vietnamese-Australian FHB property co-pilot (months 0–14)

**Target segment:** Vietnamese-Australian citizens and PRs buying their first home in Australia.

**What it does:** Property-first entry — paste a REA/Domain URL → get a Vietnamese-language property analysis covering suburb risks, comparable sales, scheme eligibility (FHG, state concessions, FHSS), Section 32 / Contract of Sale review when available, family-funding fit, decision support. Multi-property comparison view. Document workspace for deeper analysis.

**Why first:**

- Lowest regulatory risk (citizens/PRs are not foreign persons, no FIRB)
- Closest to the existing scheme-stacking knowledge base we already have
- Established Vietnamese-Australian community (~334k people) with clear marketing channels
- Validates language + cultural + product fit before adding cross-border complexity
- Browser extension on REA/Domain is the distribution wedge

**Pricing:** Property analysis $20–40 one-time; document review $50 one-time; subscription $25/month during active search; success fee $500–1,000 at settlement.

**Validation test:** SEO + browser extension targeting Vietnamese-Australian buyers in Cabramatta, Inala, Springvale, Bankstown, Footscray, Richmond. Measure URL-paste-to-paid conversion.

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

## 11. Architecture & interaction model

The product cleanly separates into three layers with different update cadences and engineering disciplines. Designing this separation correctly is the single biggest leverage point for build speed, operating cost, and product depth.

### 11.1 The three layers

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 3 — AGENTIC REASONING (live, per-session)        │
│  Document analysis · eligibility synthesis ·            │
│  property evaluation · negotiation coaching · alerts    │
└─────────────────────────────────────────────────────────┘
                          ↑ reads from
┌─────────────────────────────────────────────────────────┐
│  LAYER 2 — USER STATE (persistent, mutable)             │
│  Profile · savings · debt · property shortlist ·        │
│  document library · application status · decision trail │
└─────────────────────────────────────────────────────────┘
                          ↑ grounded in
┌─────────────────────────────────────────────────────────┐
│  LAYER 1 — STATIC KNOWLEDGE BASE (batch-updated)        │
│  Schemes · duty schedules · lender policies · process · │
│  templates. RAG index over verified sources.            │
└─────────────────────────────────────────────────────────┘
```

**Layer 1 — Static knowledge base.** Scheme rules, state stamp duty schedules, lender policies (where published), process knowledge, document templates, regulatory boundaries. Updated periodically by scripted jobs that re-fetch official sources, diff against current state, and flag changes for human review.

**Layer 2 — User state.** Per-user profile (income, savings, debt, location, preferences), property shortlist, document library, application status, and decision trail. CRUD over a relational store with append-only history for audit and "what did we conclude about X" recall.

**Layer 3 — Agentic reasoning.** Document analysis, eligibility synthesis, property evaluation, negotiation coaching, monitoring alerts. Built as discrete capability modes — each with its own prompt, tool set, and evaluation harness. Reads from Layers 1 and 2; never writes directly to Layer 1.

### 11.2 Update cadences

| Cadence | Content | Mechanism |
|---|---|---|
| Quarterly | Scheme structures (FHG, Help to Buy, FHSS), state duty schedules, FHOG amounts, process knowledge, document templates, HECS thresholds | Scripted re-fetch + diff + review |
| Monthly | Lender policy updates, RBA cash rate, FHG panel changes, participating lender lists | Scripted monitor + diff + alerts |
| Per-event | Federal Budget (May annually), State Budgets (June annually), Housing Australia rule changes, ABS quarterly releases, ASIC bulletins | Calendar-triggered + RSS/news watchers |
| Real-time | Buyer's situation, specific property, uploaded document, live negotiation | Never batchable — Layer 3 territory |

Almost nothing in this domain requires sub-day knowledge freshness. What needs to be real-time is **the buyer's situation against the knowledge**, not the knowledge itself. This is a structural cost advantage if architected correctly — Layer 1 ops are predictable scripts, not data engineering.

### 11.3 Agentic interaction intensity by phase

| Phase | Intensity | Pattern |
|---|---|---|
| Aspiration (–24 to –6 mo) | Low | Exploratory, occasional sessions |
| Preparation (–12 to –3 mo) | Medium, episodic | Q&A as new information arrives |
| Pre-approval + scheme stacking (–3 to –1 mo) | **High burst** | Concentrated 2–4 week window — docs gathered, schemes synthesised, lenders shortlisted |
| Property search (–3 to settle) | **Very high frequency** | 3–10 properties/week during active search |
| Due diligence (1–2 wks post-offer) | **Very high burst** | S32 + Contract of Sale + building + pest + strata, multiple sessions per property |
| Negotiation / auction (active days) | **Real-time critical** | Highest stakes, highest emotional load, often mobile |
| Settlement (4–8 wks) | Low | Process Q&A; conveyancer handles execution |
| Move-in (settle to mo 3) | Low | Checklist and reminders |
| Ownership yr 1–3 | Low background + spikes | Passive monitoring, alerts on rate / refi / graduation |
| Lifecycle events (yr 3+) | Event-driven spikes | On-demand questions + opportunistic alerts |

### 11.4 The five high-intensity moments

These are where agentic interaction creates the most value:

1. **Document upload and parse** — pre-approval and due diligence phases. Magic moment: 60-page report → 2-page summary.
2. **Per-property evaluation** during active search — comparative analysis, suburb risks, agent strategy decoding.
3. **Real-time negotiation coaching** during offers and auctions — highest stakes, most differentiating moment.
4. **Scheme-stacking synthesis** at pre-approval and when scheme rules change — personalised application of static knowledge.
5. **Opportunistic ownership alerts** — rate moves, refinance windows, LVR graduation events.

Everything else is informational or process — useful but not what defines the product.

### 11.5 Product modes follow interaction intensity

| Mode | Surface | Use cases |
|---|---|---|
| Quick question | Fast chat, low context, mobile-first | Aspiration, preparation, Q&A throughout |
| Document workspace | Upload-heavy, side-by-side annotation, multi-doc context | Pre-approval, due diligence |
| Property workbench | Per-property dashboards, comparison view, decision support | Property search |
| Live coach | Minimal UI, voice or one-line input, instant response | Auctions, negotiations — most differentiating, hardest to build |
| Background monitor | Async, alert-driven, low-touch | Ownership phase |

### 11.6 Pricing implications

Pricing should mirror interaction intensity:

- **One-time fees** for burst-intensity moments (document review, S32 parse): $20–50 each
- **Subscription during active period** (preparation through settlement): $20–30/month
- **Success fee at settlement:** $500–1,000
- **Low-cost long-tail subscription** during ownership: $5/month or free with paid alerts — keeps the lifecycle continuity moat alive cheaply

This structure captures value at each high-intensity moment without forcing committed subscription on aspirational users.

### 11.7 Claude Code fit by layer

| Layer | Fit | Why |
|---|---|---|
| L1 — Static KB | Excellent | Python scripts that fetch, diff, embed, index. ~2–4 weeks for v1; quarterly maintenance scripts thereafter. |
| L2 — User state | Excellent | Schema design + CRUD + auth + audit trail. Standard SaaS plumbing. |
| L3 — Agentic reasoning | Strong, *with discipline* | Each mode must be a self-contained capability with its own prompts, tools, and eval harness. The trap is building one mega-agent — Claude Code productivity drops sharply when evaluation gets fuzzy. |

**Practical implication for Wedge A:** shippable in 4–6 weeks with Claude Code:

- Layer 1 for document review is narrow (just contract conventions, building report patterns, state-specific terms): ~1–2 weeks
- Layer 2 is minimal (upload, store, surface previous uploads): few days
- Layer 3 is one focused prompt + one mode with eval set: ~1–2 weeks of iteration

### 11.8 The user state trap

Most teams underinvest in Layer 2 and regret it later. Specifically:

- **Document history** — every contract reviewed, every report parsed, every property shortlisted. Buyers will come back asking *"what did we conclude about that one in Indooroopilly?"*
- **Decision trail** — why an option was ruled out, what scheme combination was chosen, what borrowing capacity was on a given date. This becomes the agent's memory.
- **Change-impact tracking** — when a scheme threshold moves, you need to know which users' previous calculations were invalidated and alert them.

These aren't real-time concerns but they're not batch-updateable either — they're **transactional and append-only**. Worth designing for from day 1 or you build a goldfish, not a co-pilot.

---

## 12. Context and flow are the moats

§11 answered *what* we're building. This section is the *why* — the strategic framing that determines where engineering investment compounds and what makes the platform defensible.

### 12.1 The agentic platform formula

> **Quality(agent) = Quality(LLM) × Quality(Context) × Quality(Flow)**

Three observations follow:

1. **LLM quality is the thing you don't own.** It's commoditising — Claude, GPT, Gemini, Llama are converging on capability. Anything built on LLM capability alone is rented infrastructure.
2. **Context quality is your data moat.** Everything accumulated — curated KB, per-user state, decision trails, anonymised cross-user patterns. Hard to copy because it takes years.
3. **Flow quality is your engineering moat.** This is the IP. Most "agent failures" are flow failures, not LLM failures. Teams mistake LLM choice for product quality; it almost never is.

By 2027 every serious competitor has access to roughly the same LLMs as you. You compete on context and flow. Nothing else.

### 12.2 Layer mapping — same architecture, moat lens

| Layer (§11) | Moat-lens reading |
|---|---|
| Layer 1 — Static knowledge base | **Curated context** — team-decided facts, update cadence, source verification, change detection |
| Layer 2 — User state | **Accumulated context** — what each user brings to every interaction |
| Layer 3 — Agentic reasoning | **Flow** — orchestration over assembled context |

The vocabulary matters because it makes the defensibility visible. The three-layer diagram is a moat diagram in disguise.

### 12.3 Context engineering as a discipline

Context has a budget. At inference time you have ~200k tokens (or whatever the model allows). You cannot put everything in. Context engineering decisions:

- What's static vs retrieved per session
- What's summarised vs verbatim
- What's relevant for *this* query vs the user's full history
- What cross-user signal (anonymised) is worth surfacing — *"Sarah's situation looks like 47 prior users at this stage; here's how their outcomes informed her recommendations"*

This is where the **policy intelligence moat (§8.6) and product reasoning converge** — same accumulated dataset, two uses.

### 12.4 Flow is testable; context is auditable

Both are observable, which makes them improvable:

- Each flow gets an eval set (what % correctly identifies HECS-blocking-FHG cases? What % correctly flags a problematic Section 32 clause?)
- Each KB update gets a diff review (did this rule change invalidate any user's prior recommendation? Notify them.)
- Each user state mutation gets a log (the decision trail)

You can swap LLMs every six months without losing the IP. You cannot swap your eval sets, your KB curation discipline, or your user state schema. So investment goes there.

### 12.5 The context decay problem

User state grows linearly; relevance does not. Sarah's Day 7 contract is critical context at Day 365 for refi reasoning, but irrelevant for daily Q&A. Three context tiers:

- **Active context** — current session + recent state + flagged-relevant artifacts
- **Cold context** — archived but retrievable on demand
- **Summarised context** — rollups (*"user has reviewed 25 properties, 3 shortlisted, comparison ready"*)

Retrieval and summarisation strategy *is* context engineering. Under-invested teams find their agents getting weird once user state grows past 50k tokens.

### 12.6 Flow taxonomy

Flows are the testable unit. Six types worth distinguishing for this product:

| Flow type | Example | Pattern |
|---|---|---|
| Single-shot synthesis | "Should I clear my HECS?" | Retrieve context → reason → return |
| Document pipeline | Upload S32 → parse → extract → flag → format → save artifact | Multi-step with verification gates |
| State machine | Pre-approval (gather → verify → submit → track) | Explicit stages with progression rules |
| Event-driven | RBA cut → check user LVR → if graduated, alert | Triggered by external signals |
| Conversational | Quick chat Q&A | Multi-turn with shared state |
| Hybrid | Background monitor + user-initiated session | Async background + sync foreground |

Each flow type needs its own eval harness, its own context strategy, its own quality bar. The mistake is treating them all as "the agent" — they are six different products built on shared infrastructure (Layer 1 KB + Layer 2 state).

### 12.7 The flywheel

The two moats compound:

```
More users → more context → better flows possible
            ↑                              ↓
       More users    ←    Better outcomes
```

Neither moat works alone. Context without flow is a database; flow without context is generic AI. Both together is a defensible platform.

### 12.8 Implications for org structure

The engineering team should reflect the moats:

| Function | Owns |
|---|---|
| **Context engineering** | Layer 1 curation, Layer 2 schema, retrieval, summarisation, change-detection ops |
| **Flow engineering** | Layer 3 modes, prompt design, tool integration, eval harnesses |
| **Application engineering** | The surfaces (UX) on top of context + flow |

Many AI-first companies collapse this into "AI engineers" and end up with everyone doing everything badly. Splitting it gives faster iteration and clearer ownership of the moats.

### 12.9 The pitch implication

Not *"we have AI"* or *"we have prompts."* Anyone has those.

> *"We have N years of Australian first home buyer journey context, and a library of evaluated flows that operate on it."*

That is the asset. To investors, partners, hires — that is the asset. Everything else is replicable.

---

## 13. UX model

Two foundational decisions define the UX:

1. **Property-first entry** — the user enters via a specific property (paste URL or browser extension), not via "create your profile." Property cards become the central artifact; the plan canvas is the meta-view across them.
2. **Mode-switched by user context** — one unified platform, four modes by user location + FIRB status + intent. Each mode has different default flows, different artifact emphasis, but shares the same Layer 1 KB + Layer 2 schema infrastructure (Option A from architecture decision).

### 13.1 Core principle — artifacts are substance, chat is layer

A chat thread is the wrong persistent object — it makes the product indistinguishable from ChatGPT, kills the lifecycle continuity moat, and renders Layer 2 (user state) vestigial. The right persistent objects are **property cards on a plan canvas** with attached artifacts (document reports, decision trail entries, FIRB approvals, opportunity alerts) that accumulate over months and years.

Every agentic interaction should produce or update a structured artifact the user can return to.

| Interaction | Artifact produced or updated |
|---|---|
| Property URL paste | **Property card** (central artifact — Vietnamese-language analysis, FIRB filter, scheme eligibility) |
| Document upload | Document report artifact attached to a property card |
| Scheme/FIRB calc | Plan dashboard update (eligibility, cash needs, timeline) |
| Family-coordination session | Cross-border decision trail (parent + child view) |
| Negotiation session | Decision trail entry attached to property card |
| Refi alert | Opportunity card on plan dashboard |
| FIRB approval workflow | FIRB status artifact (gate for foreign-person flows) |

### 13.2 The four user modes

Same platform, four modes. Mode determined by FIRB status + intent at onboarding (a single key question: "Where do you live?" + "What's your intent?").

| Mode | User profile | FIRB status | Default flows | Acquisition channel |
|---|---|---|---|---|
| **A: Vietnamese-AU FHB** | Citizen or PR, owner-occupier, AU-resident | Not foreign person | FHG scheme stacking, document review, state concessions, FHSS | Browser extension, community SEO, REA referrals |
| **B: Vietnam-parent / student** | Parent in VN funding AU property OR student/485 in AU (temp resident) | Foreign person — FIRB applies | FIRB approval workflow, new-build filter, currency transfer, cross-border family view | VN education agents, immigration lawyers, AU-Vietnamese community |
| **C: Vietnamese-AU investor** | Citizen or PR, investment property | Not foreign person | Yield modelling, depreciation, negative gearing, portfolio analytics | Mode A graduates, Vietnamese-AU investment networks |
| **D: Vietnam-located investor** | Resident in VN, investing in AU | Foreign person — FIRB applies | FIRB-aware analytics, non-resident tax, vacancy fee planning, off-the-plan inventory | VN investment advisory, Vietnamese banks with AU relationships |

Mode switching can happen within one customer over time: student (Mode B) → graduates with PR → first home (Mode A) → equity builds → investment property (Mode C). The platform follows them; switching modes is automatic based on user-state attributes.

### 13.3 The seven UX surfaces

Six original surfaces (see §11.5) plus one new surface for foreign-person flows. Chat lives on every surface as a layer.

| Surface | Pattern | When used | Mode emphasis |
|---|---|---|---|
| **Plan dashboard (home)** | Persistent canvas — property cards, schemes, cash math, FIRB status, alerts | Every session start | All modes |
| **Property workbench** | Per-property cards, comparison view, suburb risk overlay, FIRB-aware filtering | Active search — primary entry | All modes; **central for Mode A** |
| **Document workspace** | Drag-drop, side-by-side viewer, Vietnamese-language risk summary | Pre-approval, due diligence | A, C |
| **FIRB workflow assistant** | Step-by-step foreign-person approval flow, fee calculator, documentation checklist | Before contract for foreign persons | **Central for B, D** |
| **Cross-border family view** | Parent + child shared dashboard, bilingual artifacts, currency conversion, AML documentation | Cross-border funding coordination | **Central for B** |
| **Live coach** | Minimal UI, voice or one-line input, mobile-first, sub-2s response | Auctions, negotiations | A primarily |
| **Background monitor** | Email/push alerts, weekly digest, annual review nudges, FIRB vacancy fee reminders | Ownership phase | All modes |
| **Quick question (chat)** | Threaded chat layered over plan + KB context | Throughout | All modes |

### 13.4 Entry point: property-first

Most users land on a specific property they're considering. Two entry mechanisms:

1. **Browser extension on REA.com.au and Domain** — installs once, shows "Phân tích bằng tiếng Việt" (Analyse in Vietnamese) button on every listing. Click → opens platform in side panel with property context already loaded.
2. **URL paste on landing page** — user copies any property URL (REA, Domain, partner REA inventory) and pastes into platform.

Once a property card is created, all subsequent agentic flows (scheme eligibility, document review, FIRB check, family coordination, comparison view) attach to it or read from it.

This is dramatically different from the chatbot-first or profile-first patterns that incumbents use. It maps directly to how Vietnamese buyers actually shop today (browsing REA/Domain) and meets them at their pain point (information asymmetry on a specific property).

### 13.5 Worked examples — two journeys across two modes

#### Mode A — Sarah's 365-day journey (Vietnamese-Australian FHB)

Sarah Nguyen, 32, lives in Brisbane, Vietnamese-Australian citizen (second-generation), has $50k cash, sole buyer, taxable income $145k. A representative end-to-end journey for the Vietnamese-Australian FHB mode.

**Day 0 — Discovery (5 minutes)**

- Lands from Google search "QLD Section 32 review AI"
- No signup required. Uploads a Section 32 for a $750k Coorparoo townhouse (established).
- Free preview shows 3 flagged items + scheme eligibility headline.
- Paywall: $30 for the full plain-English report. Pays. Creates account to save it.

→ Artifact created: **document report** linked to a **property card**.

**Day 7 — Returns and compares**

- Returns to the **plan dashboard**. Sees her profile placeholder, the Coorparoo property card, scheme eligibility (FHG qualified; QLD first home concession partial because established and >$700k).
- Dashboard flag: "*$15k short of recommended cash buffer.*"
- Uploads a second contract for a $680k apartment in Annerley.
- Agent shows side-by-side risk comparison + duty saving ($24k full exemption at <$700k vs partial above).

→ Artifacts: second **document report**, second **property card**, **comparison view**.

**Day 14 — Subscribes and decides on HECS**

- Subscribes ($25/month).
- Asks via chat: *"Should I clear my $8k HECS before applying for FHG?"*
- Agent runs math against her income, returns: *"Yes — boosts borrowing capacity by ~$42k. Trade-off: drops your cash buffer below recommended. Net positive given your $1M target ceiling."*

→ Artifact: **decision trail entry** — "HECS clearance, Day 14, recommendation: clear, reasoning: borrowing capacity +$42k."

**Day 30 — Lender selection**

- Plan dashboard shows pre-approval checklist with progress bars: NOAs ✓, payslips ✓, bank statements 2 of 3 months, employer letter missing.
- Agent prompts upload of missing items.
- Chat: *"Which FHG lenders should I consider?"* — agent surfaces personalised shortlist of 3 most-likely-to-approve lenders for her profile.
- Sarah picks one. Pre-approval initiated.

→ Artifacts: **lender comparison card**, **application status** entry on dashboard.

**Days 45–75 — Active search**

- Sarah inspects ~6 properties per week.
- Adds each by URL into the **property workbench**. Agent auto-fills suburb data (flood, planning, schools), comparable sales, body corporate red flags (for strata).
- Each weekend a quick chat exchange: *"What should I look out for at 14 Beech St?"*

→ Artifacts: ~25 **property cards**, most archived as "ruled out"; 3 active shortlist.

**Day 75 — Auction Saturday (Live coach mode)**

- Sarah opens **Live coach mode** on her phone before the 10:30am auction at her top-pick.
- Pre-brief: max budget $920k (already calculated against finalised scheme stacking), strategy notes, agent-tactics watch.
- Live during auction: *"Other bidder at $895k, vendor said reserve not met, what do I do?"*
- Agent: *"Likely reserve is $910–930k based on comparables. You have headroom to $920k. Counter at $905k to test the room."*
- Won at $915k.

→ Artifact: **negotiation log** — minute-by-minute decision trail.

**Days 75–135 — Settlement coordination**

- Mostly background. Agent sends a reminder calendar: building insurance to bind by [date], conveyancer payment due, mortgage docs to sign.
- Chat handles sporadic process Q&A ("What is PEXA?", "When do I get the keys?").

→ Plan dashboard updates to settlement view; checklist auto-populates.

**Day 135 onwards — Move-in and ownership**

- Plan dashboard shifts to ownership view. Quick checklist for utilities, council registration, address updates.
- Subscription auto-drops to $5/month or "alerts only" free tier (Sarah's choice).

**Day 365 — Refinance opportunity (1-year mark)**

- Email arrives: *"RBA just cut rates 25bp. Your loan is currently 6.1% — your LVR is now 78% (graduated), so the FHG no longer applies. Three lenders would offer you 5.65% today. Savings: ~$3,200/year. Want to model the refinance?"*
- Sarah taps through to the dashboard, models refinance, decides to proceed.

→ Artifact: **opportunity card** (refinance modelled, action taken).

#### Mode B — An's family journey (Vietnam-parent + AU-student cross-border)

An Tran, 24, Vietnamese international student on 485 graduate visa in Melbourne (recently graduated from UniMelb). Parents Mr. Tran (in Saigon) want to buy An a property in Melbourne where she's working. Family has ~$800k VND-equivalent available; An has saved AUD $30k. This journey demonstrates the cross-border family coordination flow that no incumbent currently supports.

**Day 0 — An discovers the platform**

- An is browsing realestate.com.au looking at apartments in Footscray (Vietnamese-heavy area, walkable to her job).
- Sees the platform's browser extension button on a $720k established 2BR apartment listing: "Phân tích bằng tiếng Việt" (Analyse in Vietnamese).
- Clicks. Side panel opens. **Critical FIRB check fires first:** "An, as a 485 visa holder you're classified as a foreign person. Foreign persons cannot purchase established dwellings (1 April 2025 – 30 June 2029). This $720k property is established. Here's what you CAN buy →"
- Agent suggests new-build alternatives in the same suburb with comparable price points.
- An signs up to save the search. Pays $40 for full Vietnamese-language analysis of three new-build alternatives.

→ Artifacts: property card with FIRB-blocked status; three new-build comparison cards.

**Day 3 — An invites parents to family view**

- An shares the platform with her father in Saigon via WhatsApp link.
- Father logs in (Vietnamese UI default based on geo-IP); platform invites him to "Family view" — shared dashboard with An's property cards, Vietnamese-language summaries, translation toggles.
- Father reviews the new-build options on his Vietnamese-language dashboard. Comments. An sees comments. Bilingual coordination begins.

→ Artifact: **cross-border family view** with shared property cards.

**Day 14 — Family decision + FIRB workflow**

- Family agrees on a $780k off-the-plan apartment in Footscray (new build, FIRB-eligible for foreign persons).
- Platform initiates **FIRB workflow assistant** for An: walks her through ATO Online services for foreign investors, calculates FIRB application fee (~$15,500 for $780k property), generates application checklist.
- Father uses platform's currency-transfer guidance: integrated with Wise partner, shows current VND/AUD rate, projects transfer cost, SBV documentation requirements (Vietnamese capital control compliance).

→ Artifacts: FIRB application status card; currency-transfer plan card.

**Day 30 — FIRB approved + contract**

- FIRB approval received. Platform unlocks "ready to contract" status on the property card.
- An connects with a Vietnamese-speaking partner REA from Footscray who handles the off-the-plan contract. Platform charges REA a $150 qualified-connection fee. An pays REA nothing extra.
- Contract signed. Conveyancer engaged.

**Day 60 — Currency transfer**

- Father initiates $750k transfer via Wise (integrated partner). Platform pre-prepared SBV documentation (tuition+living expenses category + family remittance, properly attributed).
- Bank-side AML enhanced due diligence flagged — platform's pre-prepared source-of-funds documentation passes review smoothly.

→ Artifact: AML compliance trail on the transaction.

**Day 120 — Settlement**

- Off-the-plan settles. An receives keys.
- Platform shifts to ownership mode for An: foreign-person stamp duty surcharge (VIC 8% = ~$62k extra) was modelled correctly upfront. No surprises.
- Vacancy-fee alert set: "Property must be occupied or actively offered for rent ≥183 days/year to avoid vacancy fee. Configure your occupancy tracker?"

**Day 365 — An gets PR**

- An's PR application succeeds. Platform detects status change via user-state update.
- Mode auto-switches from B → C (now eligible to buy established as PR; CGT main residence exemption now available).
- Platform suggests refinance opportunities (rate review, FIRB no longer applies, broader lender pool available).
- Father's involvement transitions to advisory mode (no longer FIRB-controlled).

→ Artifact: mode-switch event, refinance opportunity card.

This journey demonstrates: FIRB compliance gating, cross-border family coordination, currency-transfer + AML support, partner REA routing, mode-switching on status change. None of these flows exist in any incumbent product.

### 13.6 What this UX accomplishes

| Outcome | How |
|---|---|
| Lifecycle continuity moat | Plan canvas persists for years; chat history alone would not |
| Switching cost | Sarah's document library, property history, decision trail can't be reproduced elsewhere |
| Per-user LTV beyond settlement | Free or low-cost ownership tier keeps her returnable for refi, second home, investment |
| Distinct from ChatGPT | The product is a workspace, not a conversation |
| Distinct from Aussie | No loan funnel; Sarah owns her own data and decisions |
| Natural pricing structure | Burst-intensity moments → one-time fees; active period → subscription; ownership → low-cost retention |
| **Cross-border uniqueness** | Vietnamese-language Mode B family-coordination flow is genuinely unduplicated anywhere |
| **Mode-switching continuity** | Customer follows their own lifecycle within one platform; data accumulates across modes |

### 13.7 MVP scope (Wedge 1) — what's actually built in 8–12 weeks

Day-1 scope for Wedge 1 (Vietnamese-Australian FHB mode):

- Browser extension on REA.com.au and Domain (Vietnamese-language analysis button)
- URL paste landing page
- **Property card** as the first-class artifact — Vietnamese-language analysis, FIRB filter (citizen/PR for Wedge 1), scheme eligibility check, comparable sales
- Optional account creation
- Bare-bones plan dashboard — saved property cards, FIRB status, scheme stack summary
- Document workspace (upload S32 / Contract of Sale → Vietnamese-language risk summary)
- Chat layered over the dashboard
- REA partner directory (initial 10–20 Vietnamese-speaking agents in target suburbs)

What's protected by getting the UX shape right from day 1:

- Property card as first-class object in Layer 2 (not as a chat artifact)
- FIRB status as a foundational user attribute (set up for Wedge 2 expansion)
- User state schema designed for multi-property accumulation
- Mode-switching architecture in place (only Mode A active in Wedge 1, but Mode B/C/D enabled by config)
- Plan dashboard exists as a real page, not a generated chat message
- New surfaces (FIRB workflow, cross-border family view, live coach, background monitor) can be added as views over the same persistent state

### 13.8 Three traps to avoid (plus three new ones for Vietnamese diaspora)

**Original traps:**

1. **The chatbot trap** — UX is a conversation; product is indistinguishable from ChatGPT once past first novelty.
2. **The calculator trap** — UX is a form → static output; product is a fancy stamp duty calculator.
3. **The PDF-output trap** — agent generates a 20-page report once; nothing persists or evolves.

**New traps specific to Vietnamese diaspora platform:**

4. **The translation trap** — assuming "Vietnamese" means "translate the English UI." Vietnamese diaspora needs cultural fluency (family pooling patterns, parent involvement norms, formal vs informal register) — not just word-for-word translation.
5. **The mode-confusion trap** — treating all four user modes the same. A Vietnam-located parent has fundamentally different concerns from a Vietnamese-Australian FHB. Default flows must differ.
6. **The cross-border-glossover trap** — building cross-border features without FIRB / AML / VN PDP / capital-control awareness baked in. Wrong advice across jurisdictions has real legal consequences.

The property-first + mode-switched + Vietnamese-cultural architecture avoids these by making each segment's specific reality first-class, not an afterthought.

---

## 14. Next steps

For a builder pursuing this:

1. **User research.** Interview 10 active or recent FHBs. Ask what they actually used vs what they wished existed. The Finder data is directional; conversation surfaces the moments where confusion was acute and willingness-to-pay is real.
2. **Regulatory scoping.** 2-hour call with a financial services lawyer to clarify what "decision support" can and cannot say without an AFSL/ACL.
3. **MVP scope (Wedge A).** Build a single page: upload Contract of Sale + state selector + buyer profile (income, deposit, target price) → AI produces a plain-English risk summary + scheme eligibility check + next steps. Target $20 one-time price point. Ship in 6 weeks.
4. **Distribution test.** Single SEO landing page targeting "[State] Section 32 review" and "[State] contract of sale checklist" queries. Measure conversion before broader build.
5. **Partnership exploration.** Conversations with: Housing Australia (public-good positioning), one or two super funds (corporate benefit play), one or two FHG-panel non-bank lenders (white-label).

---

## References

### Federal schemes (2026)

¹ **First Home Guarantee 2026 updated changes** — Felix Finance. <https://felixfinance.com.au/guide/first-home-guarantee-scheme>

² **First Home Buyer Guarantee 2026: $1M Brisbane Income Cap** — Tora Finance. <https://torafinance.com.au/first-home-buyer-guarantee-2026/>

³ **First Home Guarantee Scheme 2026 Guide** — Hunter Galloway. <https://www.huntergalloway.com.au/home-guarantee-scheme/>

⁴ **Help to Buy Scheme Australia (Updated Guide for 2026)** — Money.com.au. <https://www.money.com.au/home-loans/help-to-buy-scheme>

⁵ **Australian Government Help to Buy Scheme — Official** — firsthomebuyers.gov.au. <https://firsthomebuyers.gov.au/australian-government-help-buy-scheme>

⁶ **First Home Super Saver Scheme — Official ATO** — Australian Taxation Office. <https://www.ato.gov.au/individuals-and-families/super-for-individuals-and-families/super/withdrawing-and-using-your-super/early-access-to-super/first-home-super-saver-scheme>

### State schemes

⁷ **QRO First Home Concession (established homes)** — Queensland Revenue Office. <https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home/>

⁸ **QRO First Home (New Home) Concession** — Queensland Revenue Office (effective 1 May 2025). <https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home-new-home/>

⁹ **SRO Victoria First Home Buyer Duty Exemption or Concession** — State Revenue Office Victoria. <https://www.sro.vic.gov.au/buying-property/land-transfer-stamp-duty/concessions-exemptions-and-waivers/first-home-buyers/first-home-buyer-duty-exemption-or-concession>

¹⁰ **First Home Buyer Stamp Duty Victoria 2026** — Tick Box Conveyancing. <https://www.tickboxconveyancing.com.au/2026/05/05/first-home-buyer-stamp-duty-victoria-2026/>

¹¹ **Victoria Stamp Duty Concessions 2026** — Lagos Financial. <https://lagosfinancial.com.au/victoria-stamp-duty-concessions-2026/>

¹² **Stamp Duty Exemption QLD 2026 Eligibility & Thresholds** — Tora Finance. <https://torafinance.com.au/stamp-duty-exemption-qld/>

¹³ **First Home Buyer Schemes Australia 2026** — Sandcastle Finance. <https://sandcastlefinance.com.au/first-home-buyer-schemes-australia-2026/>

¹⁴ **First-Home Buyer Grants & Government Schemes 2026** — Money.com.au. <https://www.money.com.au/home-loans/first-home-buyer/grants>

### Buyer pain points and market data

¹⁵ **Finder First Home Buyer Report 2025 (full PDF)** — Finder. <https://cdn.finder.com.au/finder-au/wp-uploads/2025/06/Finder-First-Home-Buyer-Report-2025.pdf>

¹⁶ **Finder's First Home Buyer Report: Blown budgets, buyer remorse** — Finder summary. <https://www.finder.com.au/news/finders-first-home-buyer-report-2025>

### Government information platforms

¹⁷ **firsthomebuyers.gov.au** — official federal information hub. <https://firsthomebuyers.gov.au/>

### Calculators

¹⁸ **Stamp Duty Calculator Australia (2025–26) — All States + FHB Savings** — stampdutycalcs.com.au. <https://www.stampdutycalcs.com.au/>

### Bank tools

¹⁹ **First Home Buyers — CommBank Buy a Home** — Commonwealth Bank. <https://www.commbank.com.au/home-loans/buying-your-first-home.html>

### Aggregators and broker platforms

²⁰ **Aussie pivots to 'fully integrated property ecosystem'** — The Adviser. <https://www.theadviser.com.au/broker/46859-aussie-pivots-to-become-fully-integrated-property-ecosystem>

²¹ **Aussie mobile app unlocks property potential** — Mortgage Professional Australia. <https://www.mpamag.com/au/mortgage-industry/technology/aussie-mobile-app-unlocks-property-potential/490720>

²² **Lendi Group launches Australia's first agentic AI home loan experience** — Mantel Group. <https://mantelgroup.com.au/case-studies/lendi-group-launches-australias-first-agentic-ai-home-loan-experience/>

### AI-native tools — Australia

²³ **HTAG launches first vertically integrated AI copilot for real estate investment** — National Law Review (Feb 2026). <https://natlawreview.com/press-releases/htag-launches-first-vertically-integrated-ai-copilot-real-estate-investment>

²⁴ **Proper Inspect — AI property due diligence** — Proper Inspect. <https://proper-inspect-web-1037493061643.australia-southeast1.run.app/>

²⁵ **DocoCheck — AI-powered property document analysis** — DocoCheck. <https://dococheck.com.au/>

²⁶ **AI Contract Review — triSearch** — triConvey. <https://www.trisearch.com.au/triconvey/ai-contract-review/>

²⁷ **AI4Convey — AI-powered contract review for VIC conveyancing** — AI4Convey. <https://ai4convey.com.au/ai-powered-contract-review-tools/>

²⁸ **AI for Property Law — AI Legal Assistant AU** — Legal Assistant AU. <https://legalassistant.au/ai-for-property-law/>

### Fintech lending products

²⁹ **What is OwnHome and how does it work?** — Savings.com.au. <https://www.savings.com.au/home-loans/ownhome-ins-and-outs>

³⁰ **Tic:Toc First Home Buyers** — Tic:Toc Home Loans. <https://tictoc.com.au/home-loans/first-home-buyers>

### International benchmarks

³¹ **New home search engine uses AI to play matchmaker (Tomo)** — Axios (Feb 2024). <https://www.axios.com/2024/02/20/ai-home-search-tools-tomo>

³² **Monzo buys digital mortgage broker Habito** — Tech.eu (Dec 2025). <https://tech.eu/2025/12/16/monzo-buys-digital-mortgage-broker-habito-in-first-ever-acquisition/>

³³ **Habito Iron Man of Mortgages** — The Fintech Times. <https://thefintechtimes.com/iron-man-of-mortgages-habitos-tech-driven-mission-to-transform-home-buying/>

### Broader AI in Australian real estate

³⁴ **AI for Real Estate in Australia: 10 Key Applications [2026]** — Appinventiv. <https://appinventiv.com/blog/ai-in-real-estate-australia/>

³⁵ **AI Property Due Diligence Australia: 8-Step Checklist (2026)** — Property Investment Professionals. <https://propertyinvestmentprofessionals.com.au/blog/ai-property-due-diligence-australia-checklist>

³⁶ **AI Real Estate Agent vs Human: Pros and Cons 2026** — PropertyChat.ai. <https://www.propertychat.ai/buyers-agent/ai-real-estate-agent-vs-human-what-property-buyers-need-to-know-in-2026/>

### Vietnamese diaspora and cross-border property

⁴⁹ **Department of Home Affairs — Vietnam Country Profile** (June 2024 data). <https://www.homeaffairs.gov.au/research-and-statistics/statistics/country-profiles/profiles/vietnam>

⁵⁰ **Vietnamese 4th biggest foreign buyers of Australian housing** — VnExpress International. <https://e.vnexpress.net/news/business/property/vietnamese-4th-biggest-foreign-buyers-of-australian-housing-4877697.html>

⁵¹ **Changes to foreign purchases of established dwellings (ban 1 Apr 2025 – 30 Jun 2029)** — Foreign Investment in Australia (Treasury). <https://foreigninvestment.gov.au/news-and-reports/news/changes-foreign-purchases-established-dwellings>

⁵² **Australia raises international student cap to 295,000 for 2026 (Southeast Asia priority)** — Study Australia / IDP Vietnam. <https://www.studyaustralia.gov.au/en/tools-and-resources/news/increased-student-intake-for-australia-in-2026>

⁵³ **FIRB Fees for Foreign Investors Buying Australian Real Estate (2025–2026)** — My Australian Property. <https://en.myaustralianproperty.com/australian-real-estate-and-firb-fee/>

⁵⁴ **Vietnamese Australians — Wikipedia overview (community profile, demographics, geographic distribution)** — Wikipedia. <https://en.wikipedia.org/wiki/Vietnamese_Australians>

### Market sizing and demand trends

³⁷ **ABS — First home buyer loans rise by 6.8 per cent (Q4 2025)** — Australian Bureau of Statistics. <https://www.abs.gov.au/media-centre/media-releases/first-home-buyer-loans-rise-68-cent>

³⁸ **ABS Lending Indicators — March Quarter 2026** — Australian Bureau of Statistics. <https://www.abs.gov.au/statistics/economy/finance/lending-indicators/latest-release>

³⁹ **First-home buyer scheme heats up competition at entry level** — Australian Broker News. <https://www.brokernews.com.au/news/breaking-news/firsthome-buyer-scheme-heats-up-competition-at-entry-level-289235.aspx>

⁴⁰ **First-home buyers priced out of most of the housing market — KPMG analysis** — Australian Broker News. <https://www.brokernews.com.au/news/breaking-news/firsthome-buyers-priced-out-of-most-of-the-housing-market--kpmg-288626.aspx>

⁴¹ **First home buyers taking new steps to get on the property ladder** — Commonwealth Bank Newsroom (March 2026). <https://www.commbank.com.au/articles/newsroom/2026/03/first-home-buyers-taking-new-steps-to-get-on-property-ladder.html>

⁴² **Australia First-Home Buyer Demand 2026** — BuyerInsight. <https://buyerinsight.com.au/australia-first-home-buyer-demand-2026/>

⁴³ **Twelve per cent of homes in Australia affordable for the average first home buyer** — KPMG (December 2025). <https://kpmg.com/au/en/media/media-releases/2025/12/twelve-per-cent-of-homes-in-australia-affordable.html>

⁴⁴ **First-Home Buyer market could take until 2030 to recover** — Property Update. <https://propertyupdate.com.au/first-home-buyer-market-could-take-until-2030-to-recover-new-data-reveals/>

⁴⁵ **Housing Data — Lending commitments to first home buyers** — housingdata.gov.au. <https://www.housingdata.gov.au/visualisation/financial-market/lending-commitments-to-first-home-buyers>

⁴⁶ **First home buyer stimulus runs dry** — MacroBusiness (May 2026). <https://www.macrobusiness.com.au/2026/05/first-home-buyer-stimulus-runs-dry/>

⁴⁷ **Expanded Home Guarantee Scheme boosts first-home buyer choices** — Australian Broker News. <https://www.brokernews.com.au/news/breaking-news/expanded-home-guarantee-scheme-boosts-firsthome-buyer-choices-288000.aspx>

⁴⁸ **Federal Budget 2026: What First Home Buyers Need to Know** — Lendology. <https://www.lendology.com.au/blog/federal-budget-2026-first-home-buyers>

---

## Document control

- **Verified through:** May 2026
- **Source recency target:** All scheme rules and statistics drawn from sources dated 2025 or 2026 wherever possible
- **Maintenance need:** Scheme rules change frequently; recommend quarterly re-verification of sections 1 and 2
- **Companion artefact:** `first_home_buyer_plan.html` (interactive plan with calculator and swimlane diagram)
- **Disclaimer:** This document is general information only, not financial, legal, or mortgage advice. All scheme eligibility and stamp duty calculations should be confirmed with a licensed broker, the relevant state revenue office, and a qualified conveyancer before commitment.
