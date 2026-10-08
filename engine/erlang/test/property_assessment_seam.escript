#!/usr/bin/env escript
%%! -sname fh_property_assessment_seam
%%
%% Full-stack LIVE smoke for the Mode-C Phase-B property_assessment keystone (Slice A).
%% Boots the engine, seeds a tenant + ed25519 key, mints a JWT, creates an investor plan
%% card (the base turn runs to completion), then ATTACHES a hand-fed property via
%% POST /plan-cards/:id/properties and drives the real per-property turn end-to-end against
%% live PG and the real planner.py sidecar. Asserts: the Phase-B event sequence (one two-path
%% fill), the persisted log, the per-property compliance audit, the addendum snapshot under
%% content.addenda.<pid> (the base content.components untouched — addenda is a sibling), and
%% the genuine keystone proof — the LIVE property_fit_investor outcome: facts COPIED from the
%% card, the agent's rent BAND present, and the gross yield RESOLVER-COMPUTED from band ÷ price
%% (§98 — the only derived figure is not agent-authored). Proves the attach→Phase-B-turn glue.
%%
%% Run LIVE (real Opus sidecar fill — metered) from engine/erlang:
%%
%%   FH_PLANNER_SCRIPT=$(pwd)/../python/planner.py \
%%   FH_SIDECAR_PYTHON=$(pwd)/../../.venv/bin/python3 \
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/property_assessment_seam.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",

    %% --- seed tenant + ed25519 signing key ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"property-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- create an investor plan card; run the base turn to completion ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [800000, 1000000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"investment">>,
        %% the investor's intended hold horizon → profile.hold_horizon_years → disposition's H,
        %% so the dispose figures (sale_proceeds etc.) compute per-property (Slice B3c).
        <<"hold_horizon_years">> => 10
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId} = fh_engine_util:json_decode(CreateResp),
    io:format("created investor plan_card_id=~s~n", [PlanCardId]),
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    BaseTypes = collect_sse(EvUrl, Auth),
    expect(lists:last(BaseTypes) =:= <<"turn_completed">>, "base turn completed"),
    BaseLen = length(BaseTypes),
    io:format("base turn: ~p events~n", [BaseLen]),
    %% The base cursor: a reconnect from 0 would replay the base turn_completed (a terminal
    %% → the SSE handler closes immediately), so the Phase-B stream resumes FROM here
    %% (Last-Event-ID) to replay only the per-property tail — exactly the real SSE reconnect.
    Cursor = scalar("SELECT COALESCE(MAX(event_id),0) FROM plan_card_events "
                    "WHERE plan_card_id = $1", [PlanCardId]),

    %% --- attach a property → run the Phase-B per-property turn ---
    PropBody = fh_engine_util:json_encode(#{
        <<"address">> => <<"12 Park Road, Cabramatta NSW 2166">>,
        <<"suburb">> => <<"Cabramatta">>,
        <<"state">> => <<"NSW">>,
        <<"price">> => 920000,
        <<"property_type">> => <<"established_house">>,
        <<"year_built">> => 1995,
        <<"land_size_sqm">> => 580,
        <<"internal_area_sqm">> => 140,
        <<"bedrooms">> => 3,
        <<"bathrooms">> => 1,
        <<"car_spaces">> => 2
    }),
    {202, AttachResp} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId)
                            ++ "/properties", [Auth], PropBody),
    #{<<"plan_card_id">> := PlanCardId, <<"property_id">> := PropertyId,
      <<"turn_id">> := PhaseBTurn} = fh_engine_util:json_decode(AttachResp),
    expect(is_binary(PropertyId) andalso is_binary(PhaseBTurn), "attach returns property_id + turn_id"),
    io:format("attached property_id=~s~n", [PropertyId]),

    %% --- SSE resumed from the base cursor: the Phase-B turn's events only (property_assessment
    %%     two-path + yield_modelling resolver), wrapped by turn_started/turn_completed. ---
    PhaseBUrl = EvUrl ++ "?last_event_id=" ++ integer_to_list(Cursor),
    PhaseB = collect_sse(PhaseBUrl, Auth),
    io:format("phase-B event sequence: ~p~n", [PhaseB]),
    expect(PhaseB =:= expected_phase_b(), "Phase-B event sequence matches (two-path + resolver)"),

    %% --- persisted log is the SOT: base + 11 Phase-B events ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= BaseLen + 36,
           "Phase-B added 36 events (1 + PA[3+1+usage] + yield[3+1] + tax[3+1] + cash[3+1] + disposition[3+1] + buying[3+1+usage] + due_diligence[3+1] + settlement[3+1] + 1)"),

    %% --- per-property compliance audit: 3 rows for property_assessment, all clear, two_path,
    %%     ASIC boundary_held (property_assessment is advice_adjacent — it carries a viability verdict) ---
    PaAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                     "AND component_id = 'property_assessment'", [PlanCardId]),
    expect(PaAudit =:= 3, "3 audit rows for property_assessment (3 gates)"),
    PaClear = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                     "AND component_id = 'property_assessment' "
                     "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(PaClear =:= 3, "all 3 property_assessment audit rows disposition=clear"),
    PaTwoPath = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                       "AND component_id = 'property_assessment' AND fill_path = 'two_path'",
                       [PlanCardId]),
    expect(PaTwoPath =:= 3, "property_assessment audit rows are two_path"),
    PaAsic = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                    "AND component_id = 'property_assessment' "
                    "AND compliance_jsonb->>'gate' = 'asic' "
                    "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                    [PlanCardId]),
    expect(PaAsic =:= 1, "property_assessment ASIC records boundary_held (advice_adjacent)"),

    %% --- content snapshot: the base components are UNTOUCHED; the addendum holds the
    %%     property_card + the property_assessment outcome under content.addenda.<pid> ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := Content} = fh_engine_util:json_decode(CardResp),
    BaseComponents = maps:get(<<"components">>, Content, #{}),
    expect(map_size(BaseComponents) =:= 8, "base content.components still 8 (addenda is a sibling)"),
    Addenda = maps:get(<<"addenda">>, Content, #{}),
    Addendum = maps:get(PropertyId, Addenda, undefined),
    expect(is_map(Addendum), "addendum present under content.addenda.<property_id>"),
    AttachedCard = maps:get(<<"property_card">>, Addendum, undefined),
    expect(is_map(AttachedCard) andalso maps:get(<<"suburb">>, AttachedCard) =:= <<"Cabramatta">>,
           "addendum carries the attached property_card"),
    PaEntry = maps:get(<<"property_assessment">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(PaEntry), "property_assessment snapshotted under the addendum"),
    expect(maps:get(<<"scope">>, PaEntry) =:= <<"per-property">>, "snapshot scope=per-property"),
    expect(maps:get(<<"fill_path">>, PaEntry) =:= <<"two_path">>, "snapshot fill_path=two_path"),

    %% --- the keystone proof: the LIVE property_fit_investor outcome ---
    Out = maps:get(<<"outcome">>, PaEntry),
    %% RESOLVER copied the neutral facts verbatim from the attached card.
    expect(maps:get(<<"state">>, Out) =:= <<"NSW">>, "state copied from card"),
    expect(maps:get(<<"suburb">>, Out) =:= <<"Cabramatta">>, "suburb copied from card"),
    expect(maps:get(<<"price">>, Out) =:= 920000, "price copied from card"),
    expect(maps:get(<<"property_type">>, Out) =:= <<"established_house">>, "property_type copied"),
    %% AGENT authored the rent BAND (the one irreducible market estimate) — a [lo, hi] list.
    [Lo, Hi] = maps:get(<<"estimated_weekly_rent_range">>, Out),
    expect(is_number(Lo) andalso is_number(Hi) andalso Lo =< Hi,
           "estimated_weekly_rent_range is a live [lo,hi] band, lo=<hi"),
    %% AGENT verdicts/scores in their enums / 0-10 bounds.
    expect(lists:member(maps:get(<<"viability_verdict">>, Out),
                        [<<"strong_investment">>, <<"acceptable_investment">>,
                         <<"marginal">>, <<"reconsider">>]), "viability_verdict in enum (live)"),
    expect(lists:member(maps:get(<<"capital_growth_outlook">>, Out),
                        [<<"strong">>, <<"moderate">>, <<"flat">>, <<"declining">>]),
           "capital_growth_outlook in enum (live)"),
    expect(lists:member(maps:get(<<"depreciation_attractiveness">>, Out),
                        [<<"strong">>, <<"moderate">>, <<"weak">>]),
           "depreciation_attractiveness in enum (live)"),
    Grade = maps:get(<<"investor_grade_overall">>, Out),
    expect(is_integer(Grade) andalso Grade >= 0 andalso Grade =< 10, "investor_grade_overall 0-10"),
    Land = maps:get(<<"land_quality_score">>, Out),
    expect(is_integer(Land) andalso Land >= 0 andalso Land =< 10, "land_quality_score 0-10"),
    %% bilingual strengths/concerns ({vi,en} arrays).
    Strengths = maps:get(<<"key_strengths">>, Out),
    expect(is_list(Strengths) andalso Strengths =/= [] andalso
           lists:all(fun(S) -> is_map(S) andalso maps:is_key(<<"vi">>, S)
                                   andalso maps:is_key(<<"en">>, S) end, Strengths),
           "key_strengths bilingual {vi,en} (live)"),
    %% §98 PROOF: the gross yield is RESOLVER-COMPUTED from the agent's band ÷ price, NOT
    %% agent-authored — it must equal round1(mid × 52 ÷ price × 100) exactly.
    Yield = maps:get(<<"rental_yield_gross_estimate">>, Out),
    ExpectedYield = round((Lo + Hi) / 2 * 52 / 920000 * 100 * 10) / 10,
    expect(Yield =:= ExpectedYield,
           "rental_yield_gross_estimate = resolver-computed mid-band ÷ price (§98)"),
    io:format("live property_fit: rent=[~p,~p]/wk yield=~p% verdict=~s grade=~p growth=~s~n",
              [Lo, Hi, Yield, maps:get(<<"viability_verdict">>, Out), Grade,
               maps:get(<<"capital_growth_outlook">>, Out)]),

    %% --- Slice B1: yield_modelling re-filled per-property in the SAME Phase-B turn, the
    %%     banded cash_flow_projection (the §B0 banded money surface, resolver-computed) ---
    YmEntry = maps:get(<<"yield_modelling">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(YmEntry), "yield_modelling snapshotted under the addendum (Slice B1)"),
    expect(maps:get(<<"scope">>, YmEntry) =:= <<"both">>, "yield_modelling snapshot scope=both"),
    expect(maps:get(<<"fill_path">>, YmEntry) =:= <<"resolver">>,
           "yield_modelling fill_path=resolver (pure figure-owner)"),
    Cfp = maps:get(<<"outcome">>, YmEntry),
    %% effective income band (rent×52×(1−vacancy)) — a well-formed [lo,hi].
    [IncLo, IncHi] = maps:get(<<"annual_rental_income_year_1">>, Cfp),
    expect(is_number(IncLo) andalso IncLo =< IncHi andalso IncLo > 0,
           "annual_rental_income_year_1 banded [lo,hi] effective income"),
    %% opex band — established_house → computed (the levy-clean case).
    [OpLo, OpHi] = maps:get(<<"annual_operating_expenses_year_1">>, Cfp),
    expect(is_number(OpLo) andalso OpLo =< OpHi andalso OpLo > 0,
           "annual_operating_expenses_year_1 banded (house opex)"),
    %% §B0/§98 PROOF: gross_yield is a RESOLVER-COMPUTED band off the SAME rent ÷ price —
    %% must equal [rent_lo, rent_hi] × 52 ÷ price × 100, one-decimal, exactly.
    GrossYield = maps:get(<<"gross_yield">>, Cfp),
    ExpectedGross = [round(Lo * 52 / 920000 * 100 * 10) / 10,
                     round(Hi * 52 / 920000 * 100 * 10) / 10],
    expect(GrossYield =:= ExpectedGross,
           "gross_yield = resolver-computed band [rent_lo,rent_hi]×52÷price (§98 banded)"),
    %% the two gross-yield figures agree: property_fit's mid-band scalar sits inside the band.
    [GyLo, GyHi] = GrossYield,
    expect(GyLo =< Yield andalso Yield =< GyHi,
           "gross_yield band brackets property_fit rental_yield_gross_estimate (coherent)"),
    %% net pre-loan yield banded.
    [_, _] = maps:get(<<"net_yield_pre_loan">>, Cfp),
    %% --- Slice B3a: the POST-loan cluster, computed at the representative leverage ---
    %% interest = price × 80% LVR × 6.35% (KB-read), interest-only — a scalar point.
    Interest = maps:get(<<"annual_interest_year_1">>, Cfp),
    ExpectedInterest = round(920000 * 0.80 * 6.35 / 100),
    expect(Interest =:= ExpectedInterest,
           "annual_interest_year_1 = price×80%×6.35% (resolver-computed point, §98)"),
    %% before-tax cash flow band = income − opex − interest (interval), SIGNED.
    [CfLo, CfHi] = maps:get(<<"cash_flow_before_tax_year_1">>, Cfp),
    expect(CfLo =:= IncLo - OpHi - Interest andalso CfHi =:= IncHi - OpLo - Interest,
           "cash_flow_before_tax_year_1 = income − opex − interest (interval, resolver-computed)"),
    %% per-week band = CF ÷ 52.
    [PwLo, PwHi] = maps:get(<<"cash_flow_before_tax_per_week">>, Cfp),
    expect(PwLo =:= round(CfLo / 52) andalso PwHi =:= round(CfHi / 52),
           "cash_flow_before_tax_per_week = CF ÷ 52 band"),
    %% geared position is one of the enum values, consistent with the CF band sign.
    Geared = maps:get(<<"is_positive_neutral_or_negative_geared_pre_tax">>, Cfp),
    expect(lists:member(Geared, [<<"positive">>, <<"neutral">>, <<"negative">>]),
           "geared position in enum"),
    expect((CfHi < 0) =:= (Geared =:= <<"negative">>) orelse Geared =/= <<"negative">>,
           "geared=negative iff the whole CF band is negative"),
    %% the year-5/10 projections are well-formed bands that improve over time (rent growth).
    [Y5Lo, _] = maps:get(<<"year_5_projected_cash_flow">>, Cfp),
    [Y10Lo, _] = maps:get(<<"year_10_projected_cash_flow">>, Cfp),
    expect(is_integer(Y5Lo) andalso is_integer(Y10Lo) andalso Y10Lo > Y5Lo,
           "year_10 projected cash flow > year_5 (rent growth over fixed interest)"),
    %% provenance: the post-loan cluster adds the four financing anchors (9 total).
    YmKb = [maps:get(<<"slug">>, E) || E <- maps:get(<<"kb_versions">>, YmEntry, [])],
    expect(lists:member(<<"kb.lender.serviceability-investment-loans">>, YmKb),
           "yield_modelling kb_versions carries the financing provenance (post-loan)"),
    %% base yield_modelling untouched (the per-property fill went to the addendum, not base).
    BaseYm = maps:get(<<"yield_modelling">>, BaseComponents, #{}),
    expect(maps:get(<<"annual_rental_income_year_1">>,
                    maps:get(<<"outcome">>, BaseYm, #{}), null) =:= null,
           "base yield_modelling still null (addendum did not leak into base)"),
    io:format("live cash_flow_projection: income=[~p,~p] opex=[~p,~p] gross_yield=~p net_pre_loan=~p~n",
              [IncLo, IncHi, OpLo, OpHi, GrossYield,
               maps:get(<<"net_yield_pre_loan">>, Cfp)]),

    %% --- Slice B2: tax_structure re-filled per-property in the SAME Phase-B turn — RESOLVER-ONLY
    %%     (the entity agent leaf reused from the base seed, NO sidecar/LLM/usage), refreshing the
    %%     rent/income-dependent tax figures off the per-property cash_flow_projection ---
    TxEntry = maps:get(<<"tax_structure">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(TxEntry), "tax_structure snapshotted under the addendum (Slice B2)"),
    expect(maps:get(<<"fill_path">>, TxEntry) =:= <<"two_path">>,
           "tax_structure fill_path=two_path (resolver-only refresh, entity re-attached)"),
    Tx = maps:get(<<"outcome">>, TxEntry),
    %% the entity is REUSED from the base (decided at base, not re-derived per-property → no usage).
    BaseTax = maps:get(<<"tax_structure">>, BaseComponents, #{}),
    BaseEntity = maps:get(<<"recommended_entity">>, maps:get(<<"outcome">>, BaseTax, #{}), undefined),
    expect(maps:get(<<"recommended_entity">>, Tx) =:= BaseEntity,
           "recommended_entity reused from the base seed (no sidecar re-derivation)"),
    %% negative gearing lights up off the per-property cash flow (true when geared at a loss; null
    %% never false — depreciation is QS-deferred). Live cash-flow sign varies → accept true|null.
    expect(lists:member(maps:get(<<"negative_gearing_active">>, Tx), [true, null]),
           "negative_gearing_active ∈ {true, null} (placed off yield's gearing; never asserted false)"),
    %% the money figures stay null — onboarding carries no income, so the marginal rate is uncaptured
    %% (the same honest-partial as borrowing capacity; they light up on a refine turn with income).
    expect(maps:get(<<"cgt_marginal_rate">>, Tx) =:= null,
           "cgt_marginal_rate null (no income at onboarding → refine turn)"),
    expect(maps:get(<<"annual_tax_refund_year_1">>, Tx) =:= null,
           "annual_tax_refund_year_1 null (marginal rate uncaptured)"),
    expect(maps:get(<<"after_tax_cash_flow_year_1">>, Tx) =:= null,
           "after_tax_cash_flow_year_1 null (marginal rate uncaptured)"),
    expect(maps:get(<<"cgt_discount_eligible">>, Tx) =:= true,
           "cgt_discount_eligible = true (resolver constant, recomputed on the refresh)"),
    %% base tax_structure untouched (the per-property fill went to the addendum, not base).
    expect(maps:get(<<"negative_gearing_active">>, maps:get(<<"outcome">>, BaseTax, #{}), null) =:= null,
           "base tax_structure still null (addendum did not leak into base)"),
    io:format("live tax_structure: entity=~p negative_gearing=~p cgt_marginal_rate=~p~n",
              [maps:get(<<"recommended_entity">>, Tx),
               maps:get(<<"negative_gearing_active">>, Tx),
               maps:get(<<"cgt_marginal_rate">>, Tx)]),

    %% --- Slice B3b: cash_position re-filled per-property in the SAME Phase-B turn — the
    %%     cash-to-complete POINT figures off the exact price (scalar money, not banded) ---
    CpEntry = maps:get(<<"cash_position">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(CpEntry), "cash_position snapshotted under the addendum (Slice B3b)"),
    expect(maps:get(<<"fill_path">>, CpEntry) =:= <<"resolver">>,
           "cash_position fill_path=resolver (pure figure-owner)"),
    Bdg = maps:get(<<"outcome">>, CpEntry),
    expect(maps:get(<<"actual_property_price">>, Bdg) =:= 920000, "actual_property_price = attached price"),
    expect(maps:get(<<"loan_amount">>, Bdg) =:= 736000, "loan_amount = price × 80% LVR baseline"),
    expect(maps:get(<<"lvr">>, Bdg) =:= 80, "lvr = 80 (the no-LMI baseline)"),
    expect(maps:get(<<"lmi_payable">>, Bdg) =:= 0, "lmi_payable = 0 at the 80% baseline"),
    TotalCash = maps:get(<<"total_cash_required">>, Bdg),
    expect(is_integer(TotalCash) andalso TotalCash > 920000 - 736000,
           "total_cash_required = deposit + duty + acquisition adders (scalar point)"),
    expect(maps:get(<<"max_property_price_supported">>, Bdg) =:= null,
           "max_property_price_supported null (capacity → income, refine)"),
    expect(maps:get(<<"verdict">>, Bdg) =:= null, "verdict null (HAVE-side → refine)"),
    io:format("live budget_envelope_investor: price=~p loan=~p lvr=~p total_cash=~p~n",
              [maps:get(<<"actual_property_price">>, Bdg), maps:get(<<"loan_amount">>, Bdg),
               maps:get(<<"lvr">>, Bdg), TotalCash]),

    %% --- Slice B3c: disposition re-filled per-property — the dispose figures use the ATTACHED
    %%     price; cgt/net/full-horizon stay to_verify-null (the regulated conservative posture) ---
    DpEntry = maps:get(<<"disposition">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(DpEntry), "disposition snapshotted under the addendum (Slice B3c)"),
    Disp = maps:get(<<"outcome">>, DpEntry),
    %% sale_proceeds uses the attached 920k (price × growth^H) — a band off the property, not the
    %% profile range. The base ceiling (800k) gives lo=1075133; the 920k property gives
    %% lo = 920k × 1.03^10 = 1236403 (the ABS-sourced 3–6% band, behavior 12).
    [SaleLo, SaleHi] = maps:get(<<"sale_proceeds">>, Disp),
    expect(SaleLo =:= 1236403 andalso SaleLo =< SaleHi,
           "sale_proceeds uses the attached 920k (lo = 1236403, banded growth projection)"),
    %% loan_payout now computes (cash_position supplied loan_amount=736k, B3b).
    expect(is_list(maps:get(<<"loan_payout">>, Disp)),
           "loan_payout computes (amortised off the per-property loan_amount)"),
    expect(is_list(maps:get(<<"taxable_gain">>, Disp)),
           "taxable_gain computes (indicative pre-clawback band)"),
    %% cgt/net/full-horizon are to_verify-null — the regulated posture (clawback + no marginal rate).
    expect(maps:get(<<"cgt_status">>, Disp) =:= <<"to_verify">>,
           "cgt_status = to_verify (regulated: clawback true + marginal rate uncaptured)"),
    expect(maps:get(<<"full_horizon_net_position">>, Disp) =:= null,
           "full_horizon_net_position null (correctly regulated-gated, not computed)"),
    io:format("live disposition: sale_proceeds=[~p,~p] cgt_status=~s full_horizon=~p~n",
              [SaleLo, SaleHi, maps:get(<<"cgt_status">>, Disp),
               maps:get(<<"full_horizon_net_position">>, Disp)]),

    %% --- Slice C: buying_strategy re-filled per-property in the SAME Phase-B turn — TWO-PATH
    %%     (the one negotiation_style leaf via the sidecar). The RESOLVER half computes the
    %%     yield-anchored discipline band (removed from the LLM's reach) + thesis_alignment + the
    %%     bilingual conditions; every money figure is the resolver's (§98) ---
    BsEntry = maps:get(<<"buying_strategy">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(BsEntry), "buying_strategy snapshotted under the addendum (Slice C)"),
    expect(maps:get(<<"fill_path">>, BsEntry) =:= <<"two_path">>,
           "buying_strategy fill_path=two_path (resolver figures + negotiation leaf)"),
    Bs = maps:get(<<"outcome">>, BsEntry),
    %% the yield-anchored band is a [lo,hi] off the live rent ÷ target_gross_yield (null only if
    %% the live rent band itself is null — the same degraded-env tolerance as the figures above).
    Anchor = maps:get(<<"yield_anchored_max_price">>, Bs),
    expect(is_list(Anchor) orelse Anchor =:= null,
           "yield_anchored_max_price is a band (or null if live rent absent)"),
    %% max_bid_value / walk_away ARE the yield-anchored band by construction (the discipline line).
    expect(maps:get(<<"max_bid_value">>, Bs) =:= Anchor,
           "max_bid_value = the yield-anchored band (resolver-computed, never agent-authored §98)"),
    expect(maps:get(<<"walk_away_price">>, Bs) =:= Anchor,
           "walk_away_price = the yield-anchored band"),
    expect(lists:member(maps:get(<<"thesis_alignment">>, Bs),
                        [<<"aligned">>, <<"stretched">>, <<"misaligned">>, null]),
           "thesis_alignment in enum (or null if no anchor)"),
    %% the conditions are resolver-emitted bilingual copy, independent of the rent → always four.
    Conds = maps:get(<<"conditions_to_request">>, Bs),
    expect(is_list(Conds) andalso length(Conds) =:= 4,
           "conditions_to_request = four (resolver bilingual copy, rent-independent)"),
    %% the agent leaf: an enum style (or null if the live agent declined — degraded-env tolerance).
    expect(lists:member(maps:get(<<"negotiation_style">>, Bs),
                        [<<"assertive">>, <<"patient">>, <<"early_offer">>, <<"low_anchor">>,
                         <<"thesis_walk_away">>, null]),
           "negotiation_style in enum (the one agent leaf; null tolerated if live agent declined)"),
    %% buying_strategy is advice_adjacent → ASIC records boundary_held (the ACL decision-support hedge).
    BsAsic = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                    "AND component_id = 'buying_strategy' "
                    "AND compliance_jsonb->>'gate' = 'asic' "
                    "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                    [PlanCardId]),
    expect(BsAsic =:= 1, "buying_strategy ASIC records boundary_held (advice_adjacent)"),
    io:format("live buying_strategy: anchor=~p alignment=~s style=~p~n",
              [Anchor, maps:get(<<"thesis_alignment">>, Bs),
               maps:get(<<"negotiation_style">>, Bs)]),

    %% --- Slice C-settle: settlement_prep re-filled per-property in the SAME Phase-B turn —
    %%     RESOLVER-ONLY (zero agent leaves → no sidecar, no usage). HONEST-PARTIAL: the dated
    %%     critical path needs contract dates (not built — settlement_prep B), so it fills the
    %%     milestone STRUCTURE + the state-conditional insurance RULE now, every date PENDING ---
    SpEntry = maps:get(<<"settlement_prep">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(SpEntry), "settlement_prep snapshotted under the addendum (Slice C-settle)"),
    expect(maps:get(<<"fill_path">>, SpEntry) =:= <<"resolver">>,
           "settlement_prep fill_path=resolver (zero agent leaves, no sidecar)"),
    Sp = maps:get(<<"outcome">>, SpEntry),
    expect(maps:get(<<"dates_status">>, Sp) =:= <<"pending_contract">>,
           "dates_status=pending_contract (honest-partial — no contract dates)"),
    expect(maps:get(<<"settlement_date">>, Sp) =:= null, "settlement_date null (PENDING)"),
    CpMils = maps:get(<<"critical_path_milestones">>, Sp),
    expect(is_list(CpMils) andalso length(CpMils) =:= 9,
           "critical_path_milestones = nine (KB-grounded structure)"),
    expect(lists:all(fun(M) -> maps:get(<<"due_date">>, M) =:= null end, CpMils),
           "every critical-path due_date null (dates PENDING)"),
    InvMils = maps:get(<<"investor_milestones">>, Sp),
    expect(is_list(InvMils) andalso length(InvMils) =:= 5, "investor_milestones = five"),
    %% NSW established_house → the regulated NSW insurance rule, bilingual (no strata note).
    InsRule = maps:get(<<"insurance_timing_rule">>, Sp),
    expect(is_map(InsRule) andalso is_binary(maps:get(<<"vi">>, InsRule, undefined))
               andalso is_binary(maps:get(<<"en">>, InsRule, undefined)),
           "insurance_timing_rule is the bilingual NSW rule (state-conditional)"),
    %% settlement_prep is NOT advice_adjacent → ASIC records no_advice_surface, never boundary_held.
    SpNoAdvice = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND component_id = 'settlement_prep' "
                        "AND compliance_jsonb->>'gate' = 'asic' "
                        "AND compliance_jsonb->>'detail' = 'no_advice_surface'",
                        [PlanCardId]),
    expect(SpNoAdvice =:= 1, "settlement_prep ASIC records no_advice_surface (process, not advice)"),
    SpBoundary = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND component_id = 'settlement_prep' "
                        "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                        [PlanCardId]),
    expect(SpBoundary =:= 0, "settlement_prep never records an advice boundary (not advice_adjacent)"),
    io:format("live settlement_prep: dates=~s milestones=~p+~p insurance=~ts~n",
              [maps:get(<<"dates_status">>, Sp), length(CpMils), length(InvMils),
               maps:get(<<"en">>, InsRule)]),

    %% --- Slice C-dd: due_diligence re-filled per-property in the SAME Phase-B turn —
    %%     RESOLVER-ONLY AT A (its lease_interpretation leaf needs the uploaded lease → due_diligence
    %%     B; no sidecar, no usage). HONEST-PARTIAL: document-risk surfacing needs uploaded documents
    %%     (upload pipeline not built — due_diligence B), so it fills the procurement checklist + the
    %%     COMPUTABLE yield-vs-thesis flag now, document fields PENDING ---
    DdEntry = maps:get(<<"due_diligence">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(DdEntry), "due_diligence snapshotted under the addendum (Slice C-dd)"),
    expect(maps:get(<<"fill_path">>, DdEntry) =:= <<"resolver">>,
           "due_diligence fill_path=resolver (resolver-only at A, no sidecar)"),
    Dd = maps:get(<<"outcome">>, DdEntry),
    expect(maps:get(<<"docs_status">>, Dd) =:= <<"pending_upload">>,
           "docs_status=pending_upload (honest-partial — no uploaded documents)"),
    expect(maps:get(<<"high_severity_flags">>, Dd) =:= [],
           "high_severity_flags empty (needs uploaded documents — B)"),
    DocChecklist = maps:get(<<"document_checklist">>, Dd),
    expect(is_list(DocChecklist) andalso length(DocChecklist) =:= 4,
           "document_checklist = four procurement documents (KB-grounded structure)"),
    %% the computable yield-vs-thesis flag: a valid bool|null (the live yield/target vary per run),
    %% with the surfaced concern consistent with it (nothing fabricated).
    DdFlag = maps:get(<<"rental_yield_below_thesis_threshold">>, Dd),
    expect(lists:member(DdFlag, [true, false, null]),
           "rental_yield_below_thesis_threshold is a valid bool|null (resolver-computed, §98)"),
    DdConcerns = maps:get(<<"investor_specific_concerns">>, Dd),
    expect((DdFlag =:= true) =:= (length(DdConcerns) =:= 1),
           "the yield-below-thesis concern fires iff the flag is true (consistent, nothing fabricated)"),
    %% due_diligence IS advice_adjacent → ASIC records boundary_held (the ACL decision-support hedge).
    DdAsic = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                    "AND component_id = 'due_diligence' "
                    "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                    [PlanCardId]),
    expect(DdAsic =:= 1, "due_diligence ASIC records boundary_held (advice_adjacent)"),
    io:format("live due_diligence: docs=~s checklist=~p yield_below_thesis=~p concerns=~p~n",
              [maps:get(<<"docs_status">>, Dd), length(DocChecklist), DdFlag, length(DdConcerns)]),

    %% --- auth: missing token -> 401; wrong key -> 403 (attach surface too) ---
    {401, _} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/properties",
                   [], PropBody),
    {_, BadPriv} = crypto:generate_key(eddsa, ed25519),
    BadAuth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, BadPriv))},
    {403, _} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/properties",
                   [BadAuth], PropBody),

    io:format("~n==== PROPERTY_ASSESSMENT SEAM (Slice A + B1/B3a yield + B3b cash + B3c disposition + C buying + C-dd + C-settle): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The Phase-B turn (Slice A + B1/B3a + B2 + B3b + B3c + C + C-dd + C-settle): eight components, DAG order.
%%   property_assessment (two_path) → 3 gate, 1 filled, 1 usage (the sidecar fill)
%%   yield_modelling     (resolver) → 3 gate, 1 filled       (no sidecar, no usage — §98 figure-owner)
%%   tax_structure       (two_path) → 3 gate, 1 filled       (resolver-only refresh — entity reused
%%                                                            from the seed, NO sidecar/LLM/usage)
%%   cash_position       (resolver) → 3 gate, 1 filled       (no sidecar, no usage)
%%   disposition         (resolver) → 3 gate, 1 filled       (no sidecar, no usage)
%%   buying_strategy     (two_path) → 3 gate, 1 filled, 1 usage (the negotiation leaf via sidecar)
%%   due_diligence       (resolver) → 3 gate, 1 filled       (RESOLVER-ONLY AT A — zero agent leaves,
%%                                                            no sidecar/usage; honest-partial checklist)
%%   settlement_prep     (resolver) → 3 gate, 1 filled       (RESOLVER-ONLY — zero agent leaves, no
%%                                                            sidecar/usage; honest-partial structure)
%% wrapped by turn_started/turn_completed.
%% 1 + (3+1+1) + (3+1) + (3+1) + (3+1) + (3+1) + (3+1+1) + (3+1) + (3+1) + 1 = 36.
expected_phase_b() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF, <<"usage">>,   %% property_assessment (two_path)
       Gates, CF,                %% yield_modelling     (resolver — banded cash_flow_projection)
       Gates, CF,                %% tax_structure       (two_path resolver-only — tax figures refresh)
       Gates, CF,                %% cash_position       (resolver — cash-to-complete)
       Gates, CF,                %% disposition         (resolver — price-aware dispose figures)
       Gates, CF, <<"usage">>,   %% buying_strategy     (two_path fresh — negotiation leaf via sidecar)
       Gates, CF,                %% due_diligence       (resolver-only at A — honest-partial checklist)
       Gates, CF,                %% settlement_prep     (resolver-only — honest-partial checklist)
       <<"turn_completed">>]).

%% --- helpers (identical to investor_seam_smoke) ------------------------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

collect_sse(Url, Auth) ->
    {ok, ReqId} = httpc:request(get, {Url, [Auth]}, [],
                                [{sync, false}, {stream, self}]),
    Raw = sse_loop(ReqId, <<>>),
    parse_event_types(Raw).

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _Headers}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _Headers}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 30000 ->
        error(sse_timeout)
    end.

parse_event_types(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    Pairs = lists:filtermap(fun parse_frame/1, Frames),
    {_, Rev} = lists:foldl(fun({Id, Type}, {Seen, Acc}) ->
        case sets:is_element(Id, Seen) of
            true -> {Seen, Acc};
            false -> {sets:add_element(Id, Seen), [Type | Acc]}
        end
    end, {sets:new(), []}, Pairs),
    lists:reverse(Rev).

parse_frame(Frame) ->
    case re:run(Frame, <<"event: (.+)">>, [{capture, [1], binary}]) of
        {match, [Type]} ->
            Id = case re:run(Frame, <<"id: (\\d+)">>, [{capture, [1], binary}]) of
                     {match, [I]} -> binary_to_integer(I);
                     nomatch -> 0
                 end,
            {true, {Id, Type}};
        nomatch -> false
    end.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
