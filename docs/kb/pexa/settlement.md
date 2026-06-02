---
slug: kb.pexa.settlement
effective_from: 2023-02-20
last_verified: 2026-06-02
---

# Electronic settlement (PEXA / e-conveyancing) — mechanics

Property settlement in Australia is now **electronic**. Instead of parties meeting to exchange paper title documents and bank cheques, the buyer's and seller's representatives and the lenders collaborate in a shared online **workspace** operated by an **Electronic Lodgment Network Operator (ELNO)** — **PEXA** is the dominant one, **Sympli** the other approved operator. At the agreed settlement time, **funds transfer (through the Reserve Bank's settlement infrastructure) and the title/mortgage instruments lodge for registration simultaneously** — title and money move together, atomically, and the buyer's name appears on title within minutes. This doc owns **the electronic-settlement mechanism, the ECNL/ARNECC regulatory framework, the per-state e-conveyancing mandate, and the buyer-facing prerequisite (Verification of Identity + Client Authorisation)**; it grounds the `settlement_prep` milestones `settlement_funds_released` and `title_registered` (which are one simultaneous event electronically). The **surrounding timeline and per-state settlement periods** are owned by `kb.settlement.process-by-state`.

## How electronic settlement works

- **A shared workspace.** The buyer's conveyancer/solicitor, the seller's representative, and the incoming and outgoing lenders all join one online workspace for the transaction. They are **Subscribers** to the ELN; the buyer themselves does not operate it.
- **Digital instruments.** The registry instruments — **transfer**, **mortgage**, **discharge/release of mortgage** — are prepared and **digitally signed** by the Subscribers on their clients' behalf (under a Client Authorisation, below).
- **Pre-settlement verification.** Before settlement the documents are checked and verified as ready for registration at the land titles office; funds figures and the settlement statement are balanced in the workspace.
- **Simultaneous funds + lodgment.** At the agreed date and time, provided everything is in order, the **balance of the purchase money is paid and disbursed, and the instruments lodge for registration — at the same moment**. Funds settle through the Reserve Bank of Australia's settlement system. There is **no gap** in which the buyer has paid but is not yet on title.
- **Title within minutes.** Registration follows almost immediately; the buyer's name appears on the title shortly after settlement, far faster than the paper process.

## Regulatory framework (ECNL + ARNECC)

- **The Electronic Conveyancing National Law (ECNL)** governs e-conveyancing, adopted by separate legislation in each state — NSW *Electronic Conveyancing (Adoption of National Law) Act 2012*, VIC *Electronic Conveyancing (Adoption of National Law) Act 2013*, QLD *Electronic Conveyancing National Law (Queensland) Act 2013*.
- **ARNECC** (the Australian Registrars' National Electronic Conveyancing Council — the land titles Registrars of each state/territory) develops the **Model Operating Requirements (MOR)**, which apply to **ELNOs** (PEXA, Sympli), and the **Model Participation Rules (MPR)**, which apply to **Subscribers** (the conveyancers, solicitors and lenders). The Registrar in each state then determines the binding Operating Requirements and Participation Rules from those models.

## Per-state mandate

Electronic lodgment of mainstream dealings is now **mandatory** in all three Mode-A states (with narrow exemptions for instruments that cannot be lodged electronically):

- **NSW — 100% electronic from 11 October 2021** (paper lodgment of land dealings, caveats and priority notices no longer permitted), under the Conveyancing Rules made by the Registrar General (Real Property Act 1900). Phased in from 2018.
- **VIC — required from 1 August 2019** for residual document types (most dealings already earlier), under the Registrar's Requirements (Transfer of Land Act 1958 s106A), with a Generic Residual Document path for the narrow exempt cases.
- **QLD — e-conveyancing mandate commenced 20 February 2023** for prescribed instruments dealing with freehold land, unless a valid exemption applies (Titles Queensland).

## Verification of Identity + Client Authorisation — the buyer's prerequisite

- **Verification of Identity (VOI).** Before acting, the buyer's conveyancer/solicitor must verify the buyer's identity to the **VOI Standard in Schedule 8 of the ARNECC Model Participation Rules** (taking reasonable steps — typically documentary identity evidence checked in person). **Note: this VOI Standard is *not* the same as the AML/CTF "100-point check"** — it is its own prescribed standard, even though both involve identity documents.
- **Client Authorisation.** The buyer must sign an **ARNECC-prescribed Client Authorisation form**, which authorises their conveyancer/solicitor (the Subscriber) to sign and lodge the electronic instruments on their behalf. Without a valid VOI and Client Authorisation, the representative cannot act in the workspace — so these are early, blocking steps.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The buyer doesn't choose or operate PEXA — but must enable it.** The conveyancer/lender are the Subscribers and pick the ELNO; the buyer's job is to complete **VOI and the Client Authorisation early** so settlement isn't held up. The plan surfaces these as blocking milestones, not afterthoughts.
- **VOI is in person with documents — plan for it.** For a first-home buyer, the plan flags that identity verification (passport/ID, checked by the conveyancer) is required up front. (A buyer or funder located **overseas** uses a separate identity process — relevant to Modes B/D, not Mode A, who is onshore.)
- **Simultaneous settlement removes a class of risk.** Because funds and title move together, the old "paid but not yet registered" gap is gone — reassurance worth stating for an anxious first-time buyer.
- **Information, not advice, and no provider steer.** The plan describes the mechanism and the two approved ELNOs as the landscape; it does not recommend a provider (the buyer doesn't choose one) and does not give legal advice — the conveyancer/solicitor runs the settlement.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. It grounds the `settlement_prep` `settlement_funds_released` and `title_registered` milestones (one simultaneous electronic event) and the VOI/Client-Authorisation prerequisites the resolver surfaces as early blocking milestones.

```jsonc
{
  "fills": [],
  "parameters": {
    "settlement_funds_and_title_transfer_simultaneously": { "type": "bool", "value": true, "note": "REGULATED (ECNL e-settlement) — at electronic settlement the balance is paid (via RBA settlement) and the instruments lodge for registration at the same moment; no gap between payment and the buyer being on title" },
    "buyer_must_complete_voi_and_client_authorisation": { "type": "bool", "value": true, "note": "REGULATED (ARNECC MPR — VOI Standard, Schedule 8; ARNECC-prescribed Client Authorisation form) — LOAD-BEARING: the conveyancer/solicitor cannot act in the ELN until the buyer's identity is verified to the VOI Standard and a Client Authorisation is signed; both are early blocking milestones. The VOI Standard is NOT the AML/CTF 100-point check" },
    "buyer_does_not_choose_or_operate_the_elno": { "type": "bool", "value": true, "note": "FACTUAL / independence — the Subscribers (conveyancer/solicitor, lenders) join and operate the workspace and choose the ELNO; the buyer does not. The plan describes the ELNO landscape, never recommends a provider" },
    "approved_elnos": { "type": "array<string>", "value": ["PEXA", "Sympli"], "note": "FACTUAL — the two approved Electronic Lodgment Network Operators; PEXA is dominant. Landscape, not a recommendation" }
  },
  "lookup": {
    "econveyancing_mandate_by_state": {
      "_note": "REGULATED — date electronic lodgment of mainstream dealings became mandatory, and the state ECNL-adopting Act. Narrow exemptions exist for instruments that cannot be lodged electronically.",
      "NSW": { "mandatory_from": "2021-10-11", "basis": "Conveyancing Rules (Registrar General, Real Property Act 1900); ECNL via Electronic Conveyancing (Adoption of National Law) Act 2012" },
      "VIC": { "mandatory_from": "2019-08-01", "basis": "Registrar's Requirements (Transfer of Land Act 1958 s106A); ECNL via Electronic Conveyancing (Adoption of National Law) Act 2013" },
      "QLD": { "mandatory_from": "2023-02-20", "basis": "Titles Queensland eConveyancing mandate; ECNL via Electronic Conveyancing National Law (Queensland) Act 2013" }
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. This doc grounds two `settlement_prep` milestones (which collapse to one simultaneous electronic event) plus the VOI/Client-Authorisation blocking steps. Pure-reference, same shape as the other `settlement_prep` anchors.
- **Provenance is REGULATED (framework) + FACTUAL (landscape).** The ECNL/ARNECC framework, the per-state mandate dates, the simultaneous-settlement mechanism and the VOI/Client-Authorisation requirement are regulated. PEXA/Sympli as the approved ELNOs is a factual landscape statement, deliberately **not** a recommendation (the buyer doesn't choose) — keeping the independence line clean.
- **Verification honesty.** Mandate dates and the ECNL-adopting Acts are verified against ARNECC and the state registries (NSW Registrar General, Land Use Victoria, Titles Queensland). The MOR→ELNO / MPR→Subscriber split and the VOI Standard (MPR Schedule 8) + Client Authorisation are from ARNECC. The QLD mandate date (20 Feb 2023) was corrected against the Titles Queensland primary after a secondary source asserted QLD had not mandated — confirm against the primary.
- **Single-owner.** This doc owns the **electronic mechanism, the ECNL/ARNECC framework, the mandate dates, and VOI/Client Authorisation**. The **surrounding timeline, settlement periods and milestone sequence** → `kb.settlement.process-by-state`. The **lender's document workflow** → `kb.lender-docs.standard-timeline`. Cross-ref, not duplicated.

## Sources

**Canonical (regulator / registry / national framework):**

- ARNECC — *Electronic Conveyancing National Law* (the ECNL; per-state adopting Acts — NSW 2012, VIC 2013, QLD 2013; MOR apply to ELNOs, MPR to Subscribers) — https://www.arnecc.gov.au/regulation/electronic_conveyancing_national_law/
- ARNECC — *Model Participation Rules* (the VOI Standard is Schedule 8; Client Authorisation is an ARNECC-prescribed form) — https://www.arnecc.gov.au/regulation/
- NSW Registrar General — *100% eConveyancing in NSW* (electronic lodgment mandatory; paper not permitted from 11 October 2021) — https://www.registrargeneral.nsw.gov.au/property-and-conveyancing/eConveyancing/eConveyancing
- Land Use Victoria — *Electronic lodgment legal framework* (electronic lodgment required; Transfer of Land Act 1958 s106A Registrar's Requirements; from 1 August 2019 for residual documents) — https://www.land.vic.gov.au/land-registration/for-professionals/our-electronic-lodgment-program/electronic-lodgment-legal-framework
- Titles Queensland — *eConveyancing* (eConveyancing mandate commenced 20 February 2023 for prescribed freehold instruments unless exempt; PEXA and Sympli are the approved ELNOs) — https://www.titlesqld.com.au/econveyancing/
