---
slug: kb.vn-pdp.cross-border-data-transfer
effective_from: 2026-01-01
last_verified: 2026-10-27
sources:
  - url: https://congbaocdn.chinhphu.vn/CongBaoCP/VanBan/2025/6/45578/57730-1-2025971-97291-2025-qh15.pdf
    retrieved: 2026-10-27
    path: docs/sources/vn-pdp/luat-91-2025-qh15-bao-ve-du-lieu-ca-nhan.txt
    note: "Luật Bảo vệ dữ liệu cá nhân, Luật số 91/2025/QH15 (Công báo số 971 + 972, 24-7-2025). Điều 38(1): \"Luật này có hiệu lực thi hành từ ngày 01 tháng 01 năm 2026.\" Điều 1(2)(c): applies to foreign bodies and individuals \"trực tiếp tham gia hoặc có liên quan\" to processing the personal data of Vietnamese citizens. Điều 20(1)(c): a cross-border transfer includes using a platform outside Vietnam \"để xử lý dữ liệu cá nhân được thu thập tại Việt Nam\"; Điều 20(2): the transferring party must prepare a cross-border transfer impact assessment dossier and send one original to the personal data protection authority \"trong thời gian 60 ngày kể từ ngày đầu tiên chuyển dữ\" liệu. Điều 39(2): impact-assessment dossiers under Decree 13/2023 received before the Law took effect stay valid."
  - url: https://congbaocdn.chinhphu.vn/180507251028987904/2026/1/17/356signed-1768638052103952849513.pdf
    retrieved: 2026-10-27
    path: docs/sources/vn-pdp/nghi-dinh-356-2025-nd-cp.txt
    note: "Nghị định số 356/2025/NĐ-CP ngày 31 tháng 12 năm 2025 (Công báo số 18, 18-01-2026). Điều 42(1): \"Nghị định này có hiệu lực thi hành từ ngày 01 tháng 01 năm 2026.\" Điều 42(2): \"Nghị định số 13/2023/NĐ-CP ngày 17 tháng 4 năm 2023 của Chính\" phủ về bảo vệ dữ liệu cá nhân hết hiệu lực kể từ ngày Nghị định này có hiệu lực thi hành."
---

# ⚠ PLACEHOLDER — Vietnamese Personal Data Protection Law (Law 91/2025/QH15) cross-border data transfer (platform application NOT SOURCE-GROUNDED)

**This doc's operational content is a labelled placeholder**, and it differs from its two `vn-capital-controls.*` siblings in one respect: the open question here is not only a *buyer-facing* fact but the **platform's own compliance posture** — a decision this project has already, explicitly, deferred. It grounds `cross_border_funding` (component 7)'s awareness of Vietnamese Personal Data Protection (PDP) law where a Vietnam-located party (the VN-side funder/parent) participates in the plan.

## The law in force (primary-sourced)

- **Decree 13/2023 is repealed.** Since **1 January 2026** Vietnam's personal data protection rules are the **Law on Personal Data Protection, Law No. 91/2025/QH15** ("Luật này có hiệu lực thi hành từ ngày 01 tháng 01 năm 2026", Art. 38(1)) and its implementing **Decree 356/2025/NĐ-CP**, which provides that Decree 13/2023/NĐ-CP "hết hiệu lực" from the day Decree 356 takes effect, also 1 January 2026 (Art. 42).
- **It reaches a foreign platform that processes a Vietnamese citizen's data.** The Law applies to Vietnamese bodies and individuals, foreign bodies and individuals in Vietnam, and foreign bodies and individuals "trực tiếp tham gia hoặc có liên quan" to processing the personal data of Vietnamese citizens (Art. 1(2)). A VN-side funder/parent who uploads identity documents or source-of-funds evidence to the platform is such a data subject.
- **Cross-border transfer needs an impact-assessment dossier, filed within 60 days.** A cross-border transfer includes moving personal data stored in Vietnam to storage abroad, a party in Vietnam sending personal data to a party abroad, and using a platform outside Vietnam "để xử lý dữ liệu cá nhân được thu thập tại Việt Nam" (Art. 20(1)). The transferring party must prepare a cross-border transfer impact assessment dossier and send one original to the personal data protection authority within 60 days of the first transfer (Art. 20(2)), done once for the life of the activity and updated as Art. 22 requires (Art. 20(3)).
- **Old Decree 13 dossiers carry over.** Impact-assessment dossiers accepted under Decree 13/2023 before the Law took effect stay usable (Art. 39(2)).

## What the project's standing constraint says

The project's governing document (CLAUDE.md, "Hard regulatory constraints" + "Don't") still names **Decree 13/2023**: do not store Vietnam-located user data outside Vietnam without a PDP compliance review, and plan VN-side data residency for Wedge 2. The constraint's substance carries over to Law 91/2025/QH15 — the instrument it names has been replaced. This doc does not change that scope; it surfaces the same deferral to the Mode-B KB layer.

## What is PENDING (the placeholder — and why it stays a placeholder, not an assertion)

- **Whether/how the current engine's handling of a VN-side funder's documents (identity, source-of-funds evidence, uploaded under `family_context`/`cross_border_funding`) is a "cross-border transfer" under Art. 20 of the Law**, and if so, what the platform's impact-assessment dossier and filing look like. This is a legal-compliance determination, not something a KB doc can assert.
- **The data-residency architecture** for VN-located user data (where it is collected, processed, and stored) — named as a Wedge-2 item in CLAUDE.md, not yet decided.
- Asserting "here is how the platform handles your data" before that review would **bury an unmade compliance decision** behind KB content ([[honest-deferral-not-rug]]) — this doc deliberately does not do that.

## Named re-ground obligation

- The **Wedge-2 VN-side data-residency compliance review** already named in CLAUDE.md (identity-layer unification trigger) — this doc's operational content activates when that review lands, reading Law 91/2025/QH15 and Decree 356/2025/NĐ-CP.
- **VN legal/data-privacy counsel** — the same Mode-B counsel-gated blocker (strategy §9) as the capital-controls siblings, extended to data protection.

## Buyer / funder pointer (what the plan says today)

The plan discloses to a Vietnam-located participant (funder/parent) — in plain, bilingual language, not legalese — that: their personal data (identity, financial documents) may be collected and processed as part of the family's plan, some of that processing may occur outside Vietnam, and Vietnamese law (the Personal Data Protection Law, Law 91/2025/QH15) may give them rights over that data; the platform's specific cross-border data-handling practices are under active compliance review (Wedge 2) rather than finalised. It does not claim a specific data-residency guarantee it has not yet built.

## Rules

Pure-reference (`fills: []`), and — like `kb.fx.loan-currency-considerations` — largely **figure-free**: this doc's job is to state the boundary (a real law exists, a real obligation may attach, the platform's own answer is not yet built) rather than assert operational content that doesn't exist yet.

```jsonc
{
  "fills": [],
  "parameters": {
    "is_placeholder": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "PLACEHOLDER — this doc's operational content (whether/how the engine's VN-funder data handling is a cross-border transfer under Law 91/2025/QH15 Art. 20, and the resulting impact-assessment dossier) is not sourced; structure built, decision pending." },
    "decree_13_applies_to_vn_located_participants": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "Name kept for the engine; Decree 13/2023 is repealed from 1 January 2026 (Decree 356/2025/NĐ-CP Art. 42(2)). The Personal Data Protection Law, Law 91/2025/QH15 (in force 1 January 2026, Art. 38(1)), now governs and applies to foreign bodies that directly take part in or are involved in processing Vietnamese citizens' personal data (Art. 1(2)(c)) — including a VN-side funder/parent's data in a Mode-B plan." },
    "cross_border_transfer_requires_impact_assessment_and_notification": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "Law 91/2025/QH15 Art. 20(2): the transferring party prepares a cross-border transfer impact assessment dossier and sends one original to the personal data protection authority within 60 days of the first transfer; Art. 20(1)(c) counts using a platform outside Vietnam to process personal data collected in Vietnam as a transfer. Decree 356/2025/NĐ-CP implements the Law." },
    "vn_data_residency_is_a_wedge_2_item_not_built_now": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the platform's own compliance posture (data residency architecture, whether current handling is a cross-border transfer) is explicitly out of Wedge 1a scope per CLAUDE.md's Don't-list; this doc surfaces that deferral into the Mode-B KB layer rather than deciding it here." },
    "no_data_residency_guarantee_asserted_to_buyer": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the buyer-facing disclosure states that data-handling practices are under active compliance review, and never asserts a specific residency/handling guarantee the platform has not yet built — avoids burying an unmade compliance decision behind KB content." }
  }
}
```

Notes:

- **No `fills`; a labelled-placeholder + boundary doc.** The REGULATED-tier facts here (the Law is in force; it applies to foreign processors of Vietnamese citizens' data; a cross-border transfer needs an impact-assessment dossier filed within 60 days) are read from the Law's and Decree's own text in the Official Gazette (Công báo), archived 2026-10-27. The *application to this platform's specific data flows* is the pending piece.
- **The parameter name `decree_13_applies_to_vn_located_participants` is kept** because the compiled artifact carries it; its note says the Law now governs. Renaming it is an engine-side change.
- **This is the one VN-side placeholder that is also a platform-architecture deferral, not only a buyer-facing information gap.** Its re-ground trigger is explicitly the Wedge-2 data-residency review already named in CLAUDE.md — don't build ahead of that review by inventing a data-handling answer here.
- **Consumer:** `family_context` / `cross_border_funding` (component 7) — grounds the agent's data-handling disclosure to a VN-located participant; no specific outcome field consumes a value (a boundary/awareness doc, like `kb.fx.loan-currency-considerations`).

## Sources

- Quốc hội — *Luật Bảo vệ dữ liệu cá nhân*, Luật số 91/2025/QH15 (Công báo số 971 + 972, 24-7-2025): Art. 1 scope, Art. 20 cross-border transfer, Art. 38 effect (1 January 2026), Art. 39 transition — https://congbaocdn.chinhphu.vn/CongBaoCP/VanBan/2025/6/45578/57730-1-2025971-97291-2025-qh15.pdf (archived: `docs/sources/vn-pdp/luat-91-2025-qh15-bao-ve-du-lieu-ca-nhan.txt`)
- Chính phủ — *Nghị định số 356/2025/NĐ-CP* (31 December 2025; Công báo số 18, 18-01-2026): Art. 42 — in force 1 January 2026; Decree 13/2023/NĐ-CP ceases to have effect — https://congbaocdn.chinhphu.vn/180507251028987904/2026/1/17/356signed-1768638052103952849513.pdf (archived: `docs/sources/vn-pdp/nghi-dinh-356-2025-nd-cp.txt`)
