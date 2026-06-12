# 05 — UX model

> Part of the **Vietnamese Diaspora Property Platform — Research & Strategy** document set. See [README.md](README.md) for the full index.
>
> **This document covers:** Plan-first entry as foundational decision (property granularity added when the user is ready), the four user modes (A/B/C/D), the seven UX surfaces, two worked examples (Sarah's 365-day Vietnamese-Australian FHB journey + An Tran's cross-border family journey demonstrating Mode B), MVP scope for Wedge 1, and six product traps to avoid.
>
> **Related documents:** [03-strategy.md](03-strategy.md) (the wedge sequence and modes this UX implements), [architecture/architecture.md](architecture/architecture.md) (the technical infrastructure underneath the UX), [first_home_buyer_plan.html](first_home_buyer_plan.html) (the working Mode A prototype demonstrating these surfaces).

---

## 13. UX model

Three foundational decisions define the UX:

1. **Plan-first onboarding** — the user enters by telling us their situation (mode, state, target price range in VND auto-converted to AUD, target zone via map click or address), NOT by selecting a specific property. The base plan generates immediately. Specific properties are added later via Tìm Nhà property search service, URL paste, or browser extension — when (and if) the user is ready.
2. **Base plan + property addenda** — every user has one persistent base plan (property-agnostic) and zero or more property addenda (one per attached property). Components have `scope: base | per-property | both` — the base plan runs immediately with no property data; addenda activate per-property as the user adds them.
3. **Mode is derived, not picked** — one unified platform; *mode* is a **derived view** over the applicant set + intent (each applicant's FIRB status + owner-occupier/investment intent), not a fixed label the user chooses at signup. A plan can be **mixed-status** (a domestic lead applicant with a foreign co-applicant routes that interest to the FIRB path) and a person's mode can **change over time** (student → PR → investor). All modes share the same Layer 1 KB + Layer 2 fact model; what varies is which pipeline runs and which fields matter (Option A). See [`architecture/fact-model-unification.md`](architecture/fact-model-unification.md).

The platform is a **lifecycle planning service**, not a property tech platform. We do not operate a property listing scraping pipeline. Property data flows only via narrow, demand-driven paths (suburb enrichment from public feeds, user URL paste, browser extension, and eventually partner REA push). See [§11.10 in architecture/architecture.md](architecture/architecture.md#1110-property-data-pipeline--narrow-and-demand-driven) and [§11.11 in architecture/architecture.md](architecture/architecture.md#1111-tìm-nhà-property-search-service--agent-invoked-human-curated).

### 13.1 Core principle — artifacts are substance, chat is layer

A chat thread is the wrong persistent object — it makes the product indistinguishable from ChatGPT, kills the lifecycle continuity moat, and renders Layer 2 (user state) vestigial. The right persistent objects are a persistent **user/household fact base** (the applicant set + facts that accumulate across journeys and modes — the lifecycle-continuity moat) and, over it, one **plan card per purchase journey** (1..N per user; one in Wedge 1), holding the base plan plus any property addenda. **Mode is derived** — per plan and per applicant — never the key (see [`architecture/fact-model-unification.md`](architecture/fact-model-unification.md)). Document reports, decision trail entries, FIRB approvals, and opportunity alerts attach and accumulate over months and years. Properties are inputs to the plan card via addenda, not the central object themselves.

Every agentic interaction should produce or update a structured artifact the user can return to.

| Interaction | Artifact produced or updated |
|---|---|
| Property URL paste | **Property addendum** on the plan card (Vietnamese-language analysis, FIRB filter, scheme eligibility) |
| Document upload | Document report artifact attached to the relevant property addendum |
| Scheme/FIRB calc | Plan card update (eligibility, cash needs, timeline) |
| Family-coordination session | Cross-border decision trail (parent + child view) |
| Negotiation session | Decision trail entry attached to the property addendum |
| Refi alert | Opportunity card on the plan projection |
| FIRB approval workflow | FIRB status artifact (gate for foreign-person flows) |

### 13.2 The four user modes

Same platform, four modes — but a **mode is a derived label, not a per-user choice.** It is computed from the **applicant set** (who is on title and/or the loan, and each person's FIRB status) plus intent (owner-occupier vs investment). The four modes below name the **default flows** a plan runs; the onboarding questions ("Where does each buyer live / what's their status?" + "What's your intent?") are *inputs to that derivation*, not a menu the user picks from.

| Mode | User profile | FIRB status | Default flows | Acquisition channel |
|---|---|---|---|---|
| **A: Vietnamese-AU FHB** | Citizen or PR, owner-occupier, AU-resident | Not foreign person | FHG scheme stacking, document review, state concessions, FHSS | Browser extension, community SEO, REA referrals |
| **B: Vietnam-parent / student** | Parent in VN funding AU property OR student/485 in AU (temp resident) | Foreign person — FIRB applies | FIRB approval workflow, new-build filter, currency transfer, cross-border family view | VN education agents, immigration lawyers, AU-Vietnamese community |
| **C: Vietnamese-AU investor** | Citizen or PR, investment property | Not foreign person | Yield modelling, depreciation, negative gearing, portfolio analytics | Mode A graduates, Vietnamese-AU investment networks |
| **D: Vietnam-located investor** | Resident in VN, investing in AU | Foreign person — FIRB applies | FIRB-aware analytics, non-resident tax, vacancy fee planning, off-the-plan inventory | VN investment advisory, Vietnamese banks with AU relationships |

**Mode is derived per applicant, so a single plan can be mixed-status.** The labels above describe the *lead* applicant's pipeline, but FIRB status is a **per-applicant** fact (constraint #10). A domestic lead applicant (Mode A/C) buying jointly with a foreign co-applicant routes that co-applicant's interest through the FIRB path (Mode B/D machinery) *within the same plan* — the gate fires on **any** foreign applicant, not just the primary buyer. A non-buying spouse's ownership is likewise folded into the eligibility test even though they take no legal interest (couple-as-one). So the four labels are default-flow selectors, **not a partition over users** — a plan can straddle them.

**Mode also changes over time.** Within one customer the derivation re-runs as facts change: student (Mode B) → graduates with PR → first home (Mode A) → equity builds → investment (Mode C). The platform follows them automatically — a mode-switch is just the derivation producing a new result over the same accumulating fact model, not a new account or plan. (The fact base is **per user/household**; plan cards are keyed per purchase journey, with mode derived — see [`architecture/fact-model-unification.md`](architecture/fact-model-unification.md).)

### 13.3 The seven UX surfaces

Six original surfaces (see [§11.5 in architecture/architecture.md](architecture/architecture.md#115-product-modes-follow-interaction-intensity)) plus one new surface for foreign-person flows. Chat lives on every surface as a layer.

| Surface | Pattern | When used | Mode emphasis |
|---|---|---|---|
| **Suburb-intelligence map (home)** | Full-bleed zone map is the home. The base plan is **engine state, not a rendered canvas** — it surfaces *on* the map as a **plan projection** (zone-default → per-suburb): the invariant core (eligibility, cash math, scheme stack) plus a per-suburb overlay. Its only no-map form is an on-demand **export dossier**. No standalone base-plan dashboard. | Every session start | All modes |
| **Property workbench** | Per-property cards, comparison view, suburb risk overlay, FIRB-aware filtering | Active search — after a property is attached | All modes; **central for Mode A** |
| **Document workspace** | Drag-drop, side-by-side viewer, Vietnamese-language risk summary | Pre-approval, due diligence | A, C |
| **FIRB workflow assistant** | Step-by-step foreign-person approval flow, fee calculator, documentation checklist | Before contract for foreign persons | **Central for B, D** |
| **Cross-border family view** | Parent + child shared dashboard, bilingual artifacts, currency conversion, AML documentation | Cross-border funding coordination | **Central for B** |
| **Live coach** | Minimal UI, voice or one-line input, mobile-first, sub-2s response | Auctions, negotiations | A primarily |
| **Background monitor** | Email/push alerts, weekly digest, annual review nudges, FIRB vacancy fee reminders | Ownership phase | All modes |
| **Quick question (chat)** | Threaded chat layered over plan + KB context | Throughout | All modes |

### 13.4 Entry point: plan-first onboarding (with property added later)

Users enter the platform by describing their situation, not by selecting a specific property. The base plan generates immediately. Specific properties are added later, when the user is ready, via one of three paths.

#### Onboarding flow (5–10 minutes)

```
1. Who's buying + intent  (inputs to the mode derivation — the user does not pick a mode)
   - Applicant set — each person who will be on title and/or the loan; per applicant:
       · citizenship / visa status (drives THAT applicant's FIRB classification)
       · owner-occupier vs investment intent
   - Non-buying spouse / de-facto partner? — if so, their ownership history
     (couple-as-one tests can disqualify even a partner who takes no legal interest)
   - Where each buyer lives (Australia / Vietnam)
   → mode is DERIVED from the applicant set + intent, and may be mixed-status (see §13.2)

2. Situation capture
   - State (NSW / VIC / QLD / WA / SA / TAS / ACT / NT)
   - Target price range, in VND → auto-converted to AUD via daily FX feed
   - Family-funding context — an off-title funder, e.g. a parent in Vietnam (optional)
   - Investment goals (for investment intent — yield / growth / balanced)

3. Target zone selection
   - Map view zoom-in → click suburb (returns lat/lon + suburb name)
   - OR address entry / suburb search
   - Multiple zones supported (target shortlist)

4. Optional intent tags
   - Investment grade focus
   - Rental yield priority
   - Long-term family living
   - Young family vs mature family
   - Close to Vietnamese community
   - Public transport priority
   - Other

→ Base plan generates immediately:
  - Eligibility (FHG, FHSS, state concessions for Mode A; FIRB workflow for Mode B/D)
  - Cash math against target price range
  - Scheme stack
  - Family-funding capacity (Modes B)
  - Investment strategy + yield framework (Modes C/D)
  - Tax structure (Modes C/D)
  - Cross-border funding capacity (Modes B/D)
  - Target criteria refined ("focus on new builds in QLD because of new-home concession")
```

The base plan is **fully agentic** — each component is filled by the planning agent reasoning over the user's situation, the static KB, and suburb-level data. No property data required.

#### Map view as suburb intelligence (not property listings)

After base plan generation, the map view shows a **suburb-intelligence overlay** rather than property pins. The user can toggle layers and explore:

| Layer | What it shows | Source |
|---|---|---|
| Investment grade | Combined yield + growth score per suburb | CoreLogic suburb stats (low tier) |
| Rental yield | Heat map by gross rental yield | ABS + CoreLogic |
| Capital growth outlook | Heat map by projected 5-year growth | CoreLogic + AHURI / KPMG |
| Long-term family living | Composite score: school catchment quality + transport + amenity | Education open data + public transport feeds |
| Young family / mature family | Demographic suitability | ABS demographics |
| Vietnamese-community proximity | Highlight suburbs with significant Vietnamese ancestry % | ABS Census |
| FHG-eligible price band | Filter to suburbs where median is within user's range | ABS median + scheme caps from KB |
| Foreign-buyer-eligible suburbs | For Mode B/D — highlight new-build-rich areas | Public planning data |

Clicking a suburb opens the **plan projection** for that suburb — the base plan's invariant core (eligibility, cash math, scheme stack) plus a suburb overlay (median prices, demographics, schools, transport, flood risk, Vietnamese-community %, stamp duty at this price, FHG price-cap check). With no suburb selected, the projection shows its **zone-default** state over the onboarding target zone (e.g. "5 of the 8 suburbs in your zone sit within your FHG cap"). This *is* the base plan, viewed through a place — there is no separate base-plan canvas. The full property-agnostic dossier is reachable only as an on-demand **export** (the `first_home_buyer_plan.html` deliverable), not a navigation surface.

This is dramatically different from the property-pin browsing pattern. Vietnamese users get **strategic exploration** of where to look — something they cannot get on REA / Domain (English-language, no Vietnamese-community highlighting, no investor-grade composite scoring).

#### Three paths to attach a specific property (when ready)

| Path | When | Mechanism |
|---|---|---|
| **Tìm Nhà property search service** | User completes base plan; wants curated specific suggestions | Agent generates search brief → human curator team returns 3–5 properties → user picks one |
| **User URL paste** | User has already found a property on REA / Domain / elsewhere | Paste URL → synchronous fetch + normalise → property addendum created |
| **Browser extension** | User is actively browsing REA / Domain | Click "Phân tích bằng tiếng Việt" button on a listing → captures context → property addendum created |

When ANY of these paths fires, the planning agent creates a **property addendum** on the user's plan card and fills the property-specific components (property_assessment, buying_strategy, due_diligence, settlement_prep, ownership_planning). The base plan persists alongside.

This is the **plan-first, property-when-ready** pattern — the base plan is the entry point at suburb/price granularity; property granularity is layered on later, as an addendum, when the user is ready. It replaces the previously-documented property-first-as-entry pattern.

### 13.5 Worked examples — two journeys across two modes

#### Mode A — Sarah's 365-day journey (Vietnamese-Australian FHB)

Sarah Nguyen, 32, lives in Brisbane, Vietnamese-Australian citizen (second-generation), has $50k cash, sole buyer, taxable income $145k. A representative end-to-end journey for the Vietnamese-Australian FHB mode.

**Day 0 — Discovery (5 minutes)**

- Lands from Google search "Vietnamese first home buyer plan Brisbane" (community SEO).
- Onboards **plan-first — no property required**: mode (Vietnamese-AU FHB), state (QLD), target price range (set in AUD), target zone (taps her preferred Brisbane suburbs on the map).
- The **base plan generates immediately** and surfaces as the zone-default **plan projection** on the map: FHG/FHSS eligibility, cash math against her range, scheme stack. Free.
- Creates an account to save it.

→ Artifact created: her **plan card** (base plan), surfaced as the map projection.

**Day 7 — Attaches a property and compares**

- Returns to the map. Her **plan projection**, narrowed to the Coorparoo suburb she's been eyeing, shows scheme eligibility (FHG qualified; QLD first home concession partial because established and >$700k) and the flag "*$15k short of recommended cash buffer.*"
- She's considering a $750k Coorparoo townhouse (established). Uploads its Section 32 → a **property addendum** is created on her plan card, with a $40 plain-English **document report** (3 flagged items).
- Uploads a second contract for a $680k Annerley apartment → a second addendum.
- Agent shows side-by-side risk comparison + duty saving ($24k full exemption at <$700k vs partial above).

→ Artifacts: second **document report**, second **property addendum**, **comparison view**.

**Day 14 — Subscribes and decides on HECS**

- Subscribes ($25/month).
- Asks via chat: *"Should I clear my $8k HECS before applying for FHG?"*
- Agent runs math against her income, returns: *"Yes — boosts borrowing capacity by ~$42k. Trade-off: drops your cash buffer below recommended. Net positive given your $1M target ceiling."*

→ Artifact: **decision trail entry** — "HECS clearance, Day 14, recommendation: clear, reasoning: borrowing capacity +$42k."

**Day 30 — Lender selection**

- Her plan projection's finance section shows a pre-approval checklist with progress bars: NOAs ✓, payslips ✓, bank statements 2 of 3 months, employer letter missing.
- Agent prompts upload of missing items.
- Chat: *"Which FHG lenders should I consider?"* — agent surfaces personalised shortlist of 3 most-likely-to-approve lenders for her profile.
- Sarah picks one. Pre-approval initiated.

→ Artifacts: **lender comparison card**, **application status** entry on her plan.

**Days 45–75 — Active search**

- Sarah inspects ~6 properties per week.
- Adds each by URL into the **property workbench** (each becomes an addendum). Agent auto-fills suburb data (flood, planning, schools), comparable sales, body corporate red flags (for strata).
- Each weekend a quick chat exchange: *"What should I look out for at 14 Beech St?"*

→ Artifacts: ~25 **property addenda**, most archived as "ruled out"; 3 active shortlist.

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

→ Her plan enters its settlement view (on the won property's addendum); checklist auto-populates.

**Day 135 onwards — Move-in and ownership**

- Her plan shifts to its ownership view. Quick checklist for utilities, council registration, address updates.
- Subscription auto-drops to $5/month or "alerts only" free tier (Sarah's choice).

**Day 365 — Refinance opportunity (1-year mark)**

- Email arrives: *"RBA just cut rates 25bp. Your loan is currently 6.1% — your LVR is now 78% (graduated), so the FHG no longer applies. Three lenders would offer you 5.65% today. Savings: ~$3,200/year. Want to model the refinance?"*
- Sarah taps through to her plan, models refinance, decides to proceed.

→ Artifact: **opportunity card** (refinance modelled, action taken).

#### Mode B — An's family journey (Vietnam-parent + AU-student cross-border)

An Tran, 24, Vietnamese international student on 485 graduate visa in Melbourne (recently graduated from UniMelb). Parents Mr. Tran (in Saigon) want to buy An a property in Melbourne where she's working. Family has ~$800k VND-equivalent available; An has saved AUD $30k. This journey demonstrates the cross-border family coordination flow that no incumbent currently supports.

**Day 0 — An discovers the platform**

- An is browsing realestate.com.au looking at apartments in Footscray (Vietnamese-heavy area, walkable to her job).
- Sees the platform's browser extension button on a $720k established 2BR apartment listing: "Phân tích bằng tiếng Việt" (Analyse in Vietnamese).
- Clicks. Side panel opens. **Critical FIRB check fires first:** "An, as a 485 visa holder you're classified as a foreign person. Foreign persons cannot purchase established dwellings (1 April 2025 – 30 June 2029). This $720k property is established. Here's what you CAN buy →"
- Agent suggests new-build alternatives in the same suburb with comparable price points.
- An signs up to save the search. Pays $40 for full Vietnamese-language analysis of three new-build alternatives.

→ Artifacts: property addendum with FIRB-blocked status; three new-build comparison addenda.

**Day 3 — An invites parents to family view**

- An shares the platform with her father in Saigon via WhatsApp link.
- Father logs in (Vietnamese UI default based on geo-IP); platform invites him to "Family view" — a shared view of An's plan with its property addenda, Vietnamese-language summaries, translation toggles.
- Father reviews the new-build options on his Vietnamese-language family view. Comments. An sees comments. Bilingual coordination begins.

→ Artifact: **cross-border family view** with shared property addenda.

**Day 14 — Family decision + FIRB workflow**

- Family agrees on a $780k off-the-plan apartment in Footscray (new build, FIRB-eligible for foreign persons).
- Platform initiates **FIRB workflow assistant** for An: walks her through ATO Online services for foreign investors, calculates FIRB application fee (~$15,500 for $780k property), generates application checklist.
- Father uses platform's currency-transfer guidance: integrated with Wise partner, shows current VND/AUD rate, projects transfer cost, SBV documentation requirements (Vietnamese capital control compliance).

→ Artifacts: FIRB application status card; currency-transfer plan card.

**Day 30 — FIRB approved + contract**

- FIRB approval received. Platform unlocks "ready to contract" status on the property addendum.
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

#### Mode-derivation in practice — a mixed-status couple

Linh (Australian citizen, born here) buys her first home **jointly** with her partner Đức, on a 482 temporary-skill visa — a **foreign person** under FIRB. They onboard as one household; the platform captures *two applicants with different statuses*, not a single buyer. The derivation does not collapse them to one mode: Linh's interest runs the Mode A FHB pipeline (FHG, state concessions) while Đức's foreign-person interest is routed to the FIRB path — **within one plan**. The FIRB gate fires on Đức even though Linh, the lead applicant, is domestic; eligibility resolves over *both* applicants (a scheme applies only if every applicant qualifies). This mixed-status case — common in the diaspora — is exactly why mode is derived from the applicant set rather than picked at signup: reading it as a clean Mode A plan (the gate never firing) is the highest-harm failure the model exists to prevent (constraint #10).

### 13.6 What this UX accomplishes

| Outcome | How |
|---|---|
| Lifecycle continuity moat | The plan card persists for years; chat history alone would not |
| Switching cost | Sarah's document library, property history, decision trail can't be reproduced elsewhere |
| Per-user LTV beyond settlement | Free or low-cost ownership tier keeps her returnable for refi, second home, investment |
| Distinct from ChatGPT | The product is a workspace, not a conversation |
| Distinct from Aussie | No loan funnel; Sarah owns her own data and decisions |
| Natural pricing structure | Burst-intensity moments → one-time fees; active period → subscription; ownership → low-cost retention |
| **Cross-border uniqueness** | Vietnamese-language Mode B family-coordination flow is genuinely unduplicated anywhere |
| **Mode-switching continuity** | Customer follows their own lifecycle within one platform; data accumulates across modes |

### 13.7 MVP scope (Wedge 1a) — what's actually built in 4–6 weeks

Day-1 scope for Wedge 1a (Vietnamese-Australian FHB mode):

- **Plan-first onboarding** — mode (Vietnamese-AU FHB), state, target price range (VND→AUD), target zone (map click / address); no property required
- **Plan card** as the first-class artifact — base plan (FHG/FHSS eligibility, cash math, scheme stack), property-agnostic; properties attach later as addenda
- **Suburb-intelligence map (home)** with overlays (Vietnamese-community proximity first), where the base plan surfaces as the zone→suburb **plan projection** — no standalone dashboard
- On-demand **export dossier** (the base plan as a deliverable)
- Optional account creation
- Chat layered on the map / projection
- Document workspace (upload S32 / Contract of Sale → Vietnamese-language risk summary → property addendum) — activated once a property is attached
- Property-attach paths: URL paste + browser extension on REA.com.au / Domain (Vietnamese-language analysis button) → property addendum
- REA partner directory (initial 10–20 Vietnamese-speaking agents in target suburbs)

What's protected by getting the UX shape right from day 1:

- **Plan card** as the first-class object in Layer 2 (not the property card, not a chat artifact) — properties are inputs via addenda
- The base plan is **engine state**, surfaced only as the map projection + export — never a standalone dashboard page
- FIRB status as a foundational **per-applicant** attribute — the applicant set (each buyer's status) captured from day 1, so a foreign co-applicant trips the gate even in an otherwise-domestic plan (set up for Wedge 2 expansion)
- User state schema designed for multi-property accumulation (addenda over one base plan)
- Mode-switching architecture in place (only Mode A active in Wedge 1a, but Mode B/C/D enabled by config)
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

The plan-first + mode-switched + Vietnamese-cultural architecture avoids these by making each segment's specific reality first-class, not an afterthought.

### 13.9 Agent / user flow + plan card lifecycle

This subsection captures the end-to-end flow from user landing on the platform through agent reasoning to persistent plan card state. The flow grounds the abstract UX surfaces (§13.3) in a concrete sequence and ties them to the blueprint architecture ([§11.9 in architecture/architecture.md](architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)).

#### Two parallel processes

The platform runs two distinct agent processes that meet at the plan card:

**Offline KB agent process** (Claude Code + maintainer, runs ahead of any user session):

1. **Curate domain KB** — schemes, FIRB regs, state duty schedules, lender policies, process knowledge. Re-fetched and verified periodically (quarterly / monthly / per-event per §11.2 cadences).
2. **Ingest property data** — REA partner uploads, user URL pastes (cached), council data, developer feeds (no scraping, §11.10). Normalised into a unified property record in the `properties` table (OPTIONAL in v1).
3. **Curate blueprints** — when laws or transaction mechanisms change, the FHB or investor blueprint is updated and redeployed. Git holds the history; old plan cards stay reproducible from the deploy commit SHA + KB snapshot recorded when they were filled, and offer an opt-in refresh.

This process is the **batch / asynchronous lane**. It produces curated KB, normalised property data, and the current deployed blueprints — all available to the user-facing agent at session time.

**User-facing planning agent process** (runs per user session):

1. User onboards → mode + state + target price range + target zone → base plan card created
2. Agent loads blueprint + KB + profile + uploads → reasons → fills base components → returns structured output
3. Later, user attaches a property → per-property components fill as an addendum → plan refines
4. System fills/refines plan card → renders to user → persists

This process is the **synchronous / real-time lane**. It reads from offline-curated KB (and property data only once a property is attached); it writes to filled plan cards and session logs.

#### The user-facing flow (sequence)

```
USER ACTION                          SYSTEM RESPONSE                      PERSISTENCE
═══════════                          ════════════════                     ════════════

1. Onboards: mode, state,            Planning agent activates.            INSERT plan_card row
   target price range (VND→AUD),     Loads the mode's blueprint             (blueprint_id, mode,
   target zone (map click /          (`fhb-domestic-au` or                  deploy_commit_sha,
   address). No property.            `investor-domestic-au`).               user_id, content_jsonb
                                     Base plan card created;                with base params
                                     base params = `<initial>`.             = <initial>)

2. Lands on the map (home);          `scope: base|both` components fill
   plan projection in its            from profile + target zone +
   zone-default state                suburb medians + KB. The base plan
                                     is engine state; it surfaces as the
                                     zone→suburb plan projection (NOT a
                                     separate dashboard), over a
                                     suburb-intelligence map (NOT pins).

3. User chats (text/voice)           Agent constructs system prompt:      INSERT session row
   or uploads docs                   - Blueprint components + params         (session_id =
                                     - Current parameter values            user_id × plan_card_id)
                                     - KB anchors                          Conversation log
                                     - Property addendum data (if any)      appended per message
                                     - Uploaded doc summaries
                                     - User's current query
                                     (No conversation history — only
                                     current context)

4. (agent reasons)                   Returns structured output:
                                       { updates: [ { component_id: "buying",
                                           parameters: { max_bid: { value: 925000,
                                             confidence: 0.82, reasoning: "..." } } } ],
                                         questions_for_user: [...],
                                         artifacts_created: [...] }

5. User attaches a property          Per-property components
   (Tìm Nhà / URL paste /            (property_assessment, buying_strategy,
    browser extension)               due_diligence, …) fill as an         UPSERT addendum into
                                     addendum; base plan refines.          plan_card content_jsonb
                                                                           (one addendum per property)

6. System fills/refines plan card,   Plan card UI re-renders.             UPDATE plan_card
   renders updated view              User sees filled components,           content_jsonb with
                                     can refine via chat or accept.        new parameter values

7. User refines / accepts            Loop back to step 3 with             Each refinement writes
                                     updated context.                      a new plan_card
                                                                           revision (or upserts)
```

#### Property data — narrow, demand-driven (no scraping)

The suburb-intelligence map is fed by **suburb-level public data** (ABS Census, state feeds), not property listings. Individual property data is **not** load-bearing (OPTIONAL in v1, §11.10) and enters only when a user attaches a specific property, via narrow demand-driven paths — all normalised into the `properties` table by the offline KB agent:

| Source | Trigger | Coverage |
|---|---|---|
| User URL paste (cached) | User pastes a REA / Domain link | Any single listing the user is considering |
| Browser extension | User browses a listing | Same, in-context |
| Tìm Nhà human curation | User requests a curated shortlist | Culturally-curated, Vietnamese-community focus |
| Partner REA push (later) | Partner REA submits inventory | High quality, Vietnamese-community focus |

There is **no listing scraper** (§11.10): legally fraught, operationally fragile, and not where the platform's value lies. The user-facing agent reads property data from the `properties` cache only after a property is attached; the base plan never depends on it.

#### System prompt construction — always reflect current plan card state

Critically, the system prompt is **dynamically constructed at every request** from the current plan card state. Parameters always show their latest values; `<initial>` marks unfilled parameters; richer signals (`<pending: user>`, `<pending: agent>`, `<stale: 90d>`, `<conflict: user_override>`) can be added as the system matures.

Conversation history is **not** appended to the system prompt. Planning is grounded in:

- Current plan card state (all filled parameters in their latest values)
- Current property addendum (property context, if a property is attached)
- Uploaded document summaries (if any)
- Current user query (the message just sent)

This bounds token consumption (no growing conversation tail) and prevents the agent from drifting on stale conversational context. The session log preserves the full conversation for user re-reading and audit, but the planning agent grounds in *state*, not *history*.

#### Re-fill triggers

The plan card is updated (re-filled) on these events:

- **User interaction adds context** — uploaded a document, answered an agent question, updated a profile field
- **User attaches a property** — a property addendum is added to the plan card and its per-property components fill (base plan persists; one addendum per attached property)
- **System event invalidates parameters** — blueprint updated, scheme rule changed in KB, property data refreshed, FIRB regime change
- **Time-based stale check** — parameters older than threshold (e.g., 90 days) flagged for re-fill on next session

Confirmed scope: blueprint template never changes per user; only the filled instance does.

#### Persistence summary

| What | Where | Lifetime |
|---|---|---|
| Blueprint templates | `blueprints` table, jsonb, keyed by slug | Redeployed in place; git holds prior states |
| Filled plan card | `plan_cards` table, jsonb, records deploy commit SHA + KB snapshot | Permanent; one **per purchase journey** (1..N per user) over a persistent user/household fact base — mode derived, not keyed; holds base plan + property addenda. (Fact-base ↔ plan table split decided at the PG-schema step.) |
| Session conversation log | `sessions` table, append-only, keyed by `session_id = user_id × plan_card_id` | Permanent; for user re-reading + audit |
| Normalised property data | `properties` table, jsonb | Persistent; updated by offline ingestion |
| KB anchors | Embedded in blueprint via `kb_anchors` references | Updated quarterly/monthly per §11.2 |

A user returning to a plan they previously started sees the persisted filled plan card immediately (base plan plus any property addenda), with conversation history available alongside, and can resume refinement or trigger a refresh if the blueprint or KB has changed since.

#### Mapping to UX surfaces (§13.3)

The flow operationalises four of the seven UX surfaces simultaneously:

| Surface | Activated when |
|---|---|
| Suburb-intelligence map (home) + plan projection | Onboarding completes — base plan generates as engine state and surfaces as the zone-default projection on the map (no standalone dashboard); export dossier available on demand |
| Property workbench | User attaches / explores a specific property (addendum) |
| Document workspace | User uploads contract / Section 32 / strata report |
| Quick question (chat) | The chat interface itself, layered on any surface |

The remaining three surfaces (FIRB workflow assistant, cross-border family view, live coach, background monitor) activate on mode-specific triggers — FIRB workflow for Mode B/D, family view when buyer invites parent, live coach when buyer signals "I'm at the auction," background monitor in ownership phase.

#### Why this flow design holds up

- **Plan-first entry beats property-first** — the base plan delivers value immediately with zero property data, so the user is never blocked on finding a listing; property granularity layers on as an addendum when they're ready.
- **Plan card per purchase journey — over a persistent per-user/household fact base, mode derived — is the right unit** — the base plan (eligibility, cash math, scheme stack) is property-agnostic and reused across every property the user considers; per-property reasoning lives in addenda, not duplicated plan cards. Keying on mode is rejected: mode is mutable (PR granted mid-plan) and heterogeneous (mixed-status couple), so it cannot be a partition key without severing the lifecycle fact base — see [`architecture/fact-model-unification.md`](architecture/fact-model-unification.md).
- **System prompt grounded in state, not history** — keeps tokens bounded, keeps reasoning clean, makes evaluation tractable.
- **Two parallel processes (offline KB + user-facing agent) decouple update cadence from session latency** — the user-facing agent is fast because the heavy lifting (KB curation, property ingestion, blueprint authoring) happens offline.
- **Deploy-time snapshots make evolution safe** — laws change, blueprints are redeployed, old plan cards survive as historical artifacts (reproducible from their commit SHA + KB snapshot), users opt-in to refresh.

---

