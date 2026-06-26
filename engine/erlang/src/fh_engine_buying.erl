-module(fh_engine_buying).

%% The `buying_strategy` investor-variant resolver half (Mode C, Phase B per-property). It
%% produces the bid_plan_investor outcome's RESOLVER figures — the yield-anchored discipline
%% line (the price BAND at which the property meets the investor's target gross yield) and the
%% thesis-alignment verdict — plus the standard investor offer conditions and the red flags
%% PLACED from property_fit_investor.key_concerns. The ONE agent leaf (negotiation_style,
%% reasoning_domain negotiation) is folded in by fh_engine_fill:merge_agent/3.
%%
%% FIGURE POSTURE (§98, [[verify-regulated-figures-by-postcondition]]). Every money figure is
%% resolver-computed and removed from the LLM's reach: the agent schema (NegotiationLeaves) has
%% no price slot. max_bid_value / walk_away_price ARE the yield-anchored band (the discipline
%% line, NOT "bid this"); banded because the rent input is a band (Slice B0). Property price is
%% NOT a financial product (the ASIC/AFSL personal-liability line governs finance/credit —
%% mortgage_finance / eligibility); the constraint here is ACL misleading-conduct, met by
%% KB-methodology computation + the bilingual decision-support framing (kb.copy.buying-strategy).
%% buying_strategy is nonetheless marked advice_adjacent (fh_engine_compliance) as a consistent
%% decision-support hedge.
%%
%% HONEST-PARTIAL ([[base-turn-honest-partial-output]]). The anchor needs the rent band (from
%% property_fit_investor, agent-authored at attach) AND target_gross_yield (from strategy_thesis,
%% a base outcome seeded into the per-property turn). Absent either → the anchored figures,
%% max_bid_*, walk_away, reasoning, and thesis_alignment are null; the conditions + the
%% (possibly empty) red flags still surface. No figure is ever fabricated.

-export([fill/2]).

-define(BID,   <<"kb.investor.bid-discipline">>).
-define(YIELD, <<"kb.investor.yield-anchored-pricing">>).
-define(COPY,  <<"kb.copy.buying-strategy">>).

-spec fill(map(), map()) -> {map(), binary(), map()}.
fill(_Args, Upstream) ->
    Pf       = maps:get(<<"property_fit_investor">>, Upstream, #{}),
    Thesis   = maps:get(<<"strategy_thesis">>, Upstream, #{}),
    Rent     = maps:get(<<"estimated_weekly_rent_range">>, Pf, null),
    Price    = maps:get(<<"price">>, Pf, null),
    Concerns = maps:get(<<"key_concerns">>, Pf, null),
    Yield    = maps:get(<<"target_gross_yield">>, Thesis, null),
    Anchor   = anchored_band(Rent, Yield),
    Outcome  = #{
        <<"yield_anchored_max_price">> => Anchor,
        <<"thesis_alignment">>         => thesis_alignment(Price, Anchor),
        <<"max_bid_value">>            => Anchor,
        <<"max_bid_confidence">>       => null,
        <<"max_bid_reasoning">>        => reasoning(Anchor, Yield),
        <<"walk_away_price">>          => Anchor,
        <<"negotiation_style">>        => null,
        <<"live_coach_armed">>         => false,
        <<"conditions_to_request">>    => conditions(),
        <<"red_flags_to_monitor">>     => red_flags(Concerns)
    },
    KbVersions = fh_engine_kb:kb_anchors([?BID, ?YIELD, ?COPY]),
    {Outcome, <<"buying-strategy-card">>, KbVersions}.

%% the yield-anchored price BAND: price = annual_rent × 100 / target_yield, across the rent
%% band [RLo, RHi]. A band because the rent estimate is a band — the price at which THIS rent
%% delivers the target gross yield. Removed from the LLM's reach (computed here, §98).
anchored_band([RLo, RHi], Yield)
  when is_number(RLo), is_number(RHi), is_number(Yield), Yield > 0 ->
    [round(RLo * 52 * 100 / Yield), round(RHi * 52 * 100 / Yield)];
anchored_band(_, _) -> null.

%% the attached price vs the anchored band: at/below the low end beats target even at the low
%% rent (aligned); within the band meets target only at higher achieved rent (stretched); above
%% it exceeds the target-yield price even at the high rent (misaligned).
thesis_alignment(Price, [ALo, AHi]) when is_number(Price) ->
    if Price =< ALo -> <<"aligned">>;
       Price =< AHi -> <<"stretched">>;
       true         -> <<"misaligned">>
    end;
thesis_alignment(_, _) -> null.

%% the bilingual yield-anchor frame (only when the anchor computed → a yield is known).
reasoning([_, _], Yield) when is_number(Yield) ->
    copy(<<"reasoning_yield_anchor">>, #{<<"yield">> => Yield});
reasoning(_, _) -> null.

%% the standard investor offer conditions — a fixed, non-property-specific bilingual list.
conditions() ->
    [copy(<<"cond_subject_to_finance">>, #{}),
     copy(<<"cond_subject_to_building_pest">>, #{}),
     copy(<<"cond_subject_to_strata">>, #{}),
     copy(<<"cond_subject_to_rental_appraisal">>, #{})].

%% PLACE the property_fit_investor concerns verbatim ({vi,en} already) — place-don't-recompute.
red_flags(Concerns) when is_list(Concerns) -> Concerns;
red_flags(_)                               -> [].

%% subst a kb.copy.buying-strategy template into a bilingual {vi,en} value (no Vietnamese
%% literal in Erlang, no io:format ~s — bilingual-content.md §3b).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).
