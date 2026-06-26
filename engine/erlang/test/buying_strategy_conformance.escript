#!/usr/bin/env escript
%%! -sname fh_buying_strategy_conformance
%%
%% Conformance suite for the `buying_strategy` investor-variant resolver + two-path merge
%% (fh_engine_buying / fh_engine_fill — Mode C, Phase B per-property, blueprint component 8; a
%% TWO-PATH component like tax_structure: a resolver scaffold + ONE negotiation agent leaf folded
%% by merge_agent/3). Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json)
%% and asserts what the bid plan relies on:
%%   1. SCAFFOLD — the resolver owns the buying-strategy-card renderer + the bid/yield/copy anchors,
%%      computes the yield-anchored price BAND (removed from the LLM's reach, §98) + thesis_alignment,
%%      emits the four standard bilingual conditions, places the red flags from key_concerns, and
%%      leaves negotiation_style null (agent slot) + max_bid_confidence null (honest-partial).
%%   2. THE YIELD ARITHMETIC — anchored_band = annual_rent × 100 ÷ target_gross_yield, a BAND
%%      because rent is a band; max_bid_value/walk_away = that band; thesis_alignment classifies the
%%      attached price against it (aligned/stretched/misaligned).
%%   3. HONEST-PARTIAL — no rent OR no yield → every anchored figure null; no price → alignment null;
%%      no figure is fabricated.
%%   4. LAYER-1 CONFORMANCE — scaffold + computed + merged all pass fh_engine_outcome:validate/3
%%      against the compiled bid_plan_investor schema (money_range band, null, bilingual copy).
%%   5. TWO-PATH MERGE — merge_agent/3 folds EXACTLY negotiation_style and leaves every resolver
%%      figure untouched (§98 — the agent authors no price); agent_values_from_outcome/2 round-trips.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/buying_strategy_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("buying_strategy conformance — fh_engine_buying (Mode-C two-path, Slice C)~n~n"),
    R = lists:flatten([scaffold_cases(), arithmetic_cases(), honest_partial_cases(),
                       alignment_cases(), layer1_cases(), two_path_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p buying_strategy anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the bid_plan_investor fields (the ten the registry declares).
fields() ->
    [<<"yield_anchored_max_price">>, <<"thesis_alignment">>, <<"max_bid_value">>,
     <<"max_bid_confidence">>, <<"max_bid_reasoning">>, <<"walk_away_price">>,
     <<"negotiation_style">>, <<"live_coach_armed">>, <<"conditions_to_request">>,
     <<"red_flags_to_monitor">>].

%% a real property_fit_investor: rent [620,720]/wk @ $920k, with bilingual concerns to place.
pf() ->
    #{<<"price">> => 920000,
      <<"property_type">> => <<"established_house">>,
      <<"estimated_weekly_rent_range">> => [620, 720],
      <<"key_concerns">> => [#{<<"vi">> => <<"rủi ro strata"/utf8>>,
                               <<"en">> => <<"strata risk">>}]}.

thesis() -> #{<<"target_gross_yield">> => 4.0}.

%% target 4.0% on [620,720]/wk: annual_rent [32240,37440] → band [806000,936000].
upstream() ->
    #{<<"property_fit_investor">> => pf(), <<"strategy_thesis">> => thesis()}.

scaffold(Upstream) -> fh_engine_fill:resolver(<<"buying_strategy">>, #{}, Upstream).

g(O, K) -> maps:get(K, O, undefined).

is_loc(M) -> is_map(M) andalso is_binary(maps:get(<<"vi">>, M, undefined))
                 andalso is_binary(maps:get(<<"en">>, M, undefined))
                 andalso maps:get(<<"vi">>, M) =/= <<>>.

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream()),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    Conds = g(O, <<"conditions_to_request">>),
    Flags = g(O, <<"red_flags_to_monitor">>),
    [check("renderer = buying-strategy-card", Rend, <<"buying-strategy-card">>),
     check("outcome has exactly the ten bid_plan_investor fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("has_resolver true (classified as resolver, two-path)",
           fh_engine_fill:has_resolver(<<"buying_strategy">>), true),
     check("negotiation_style null pre-merge (agent slot)",
           g(O, <<"negotiation_style">>), null),
     check("max_bid_confidence null (honest-partial — market depth not wired)",
           g(O, <<"max_bid_confidence">>), null),
     check("live_coach_armed false (feature not built)",
           g(O, <<"live_coach_armed">>), false),
     check("conditions_to_request = four bilingual entries",
           is_list(Conds) andalso length(Conds) =:= 4
               andalso lists:all(fun is_loc/1, Conds), true),
     check("red_flags_to_monitor places the bilingual key_concerns verbatim",
           Flags, maps:get(<<"key_concerns">>, pf())),
     check("kb_versions = bid-discipline + yield-anchored-pricing + the copy doc",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.investor.bid-discipline">>,
                       <<"kb.investor.yield-anchored-pricing">>,
                       <<"kb.copy.buying-strategy">>]))].

%% --- 2. the yield arithmetic (removed from the LLM's reach, §98) -------------

arithmetic_cases() ->
    {O, _, _} = scaffold(upstream()),
    Anchor = [806000, 936000],
    Reason = g(O, <<"max_bid_reasoning">>),
    [check("yield_anchored_max_price = annual_rent × 100 ÷ yield, banded",
           g(O, <<"yield_anchored_max_price">>), Anchor),
     check("max_bid_value = the yield-anchored band (the discipline line, not 'bid this')",
           g(O, <<"max_bid_value">>), Anchor),
     check("walk_away_price = the yield-anchored band",
           g(O, <<"walk_away_price">>), Anchor),
     check("thesis_alignment = stretched ($920k within [806k,936k])",
           g(O, <<"thesis_alignment">>), <<"stretched">>),
     check("max_bid_reasoning is a bilingual {vi,en} frame (via kb.copy)", is_loc(Reason), true)].

%% --- 3. honest-partial (no fabrication) -------------------------------------

honest_partial_cases() ->
    %% no rent → no anchor.
    {ONoRent, _, _} = scaffold(#{<<"property_fit_investor">> => #{<<"price">> => 920000},
                                <<"strategy_thesis">> => thesis()}),
    %% no yield → no anchor.
    {ONoYield, _, _} = scaffold(#{<<"property_fit_investor">> => pf(),
                                 <<"strategy_thesis">> => #{}}),
    %% rent+yield but no price → anchor computes, alignment can't.
    {ONoPrice, _, _} = scaffold(
        #{<<"property_fit_investor">> => maps:remove(<<"price">>, pf()),
          <<"strategy_thesis">> => thesis()}),
    [check("no rent: yield_anchored_max_price null", g(ONoRent, <<"yield_anchored_max_price">>), null),
     check("no rent: max_bid_value null", g(ONoRent, <<"max_bid_value">>), null),
     check("no rent: walk_away_price null", g(ONoRent, <<"walk_away_price">>), null),
     check("no rent: max_bid_reasoning null", g(ONoRent, <<"max_bid_reasoning">>), null),
     check("no rent: thesis_alignment null", g(ONoRent, <<"thesis_alignment">>), null),
     check("no rent: conditions still present (not rent-dependent)",
           length(g(ONoRent, <<"conditions_to_request">>)), 4),
     check("no yield: yield_anchored_max_price null", g(ONoYield, <<"yield_anchored_max_price">>), null),
     check("no yield: max_bid_reasoning null", g(ONoYield, <<"max_bid_reasoning">>), null),
     check("no price: anchor still computes off rent+yield",
           g(ONoPrice, <<"yield_anchored_max_price">>), [806000, 936000]),
     check("no price: thesis_alignment null (can't classify an absent price)",
           g(ONoPrice, <<"thesis_alignment">>), null),
     check("no rent: Layer-1 still conforms (all-null anchored figures)", validate(ONoRent), ok)].

%% --- 4. alignment classification --------------------------------------------

alignment_cases() ->
    A = fun(Price) ->
            {O, _, _} = scaffold(#{<<"property_fit_investor">> => (pf())#{<<"price">> => Price},
                                  <<"strategy_thesis">> => thesis()}),
            g(O, <<"thesis_alignment">>)
        end,
    [check("price $700k ≤ low end → aligned", A(700000), <<"aligned">>),
     check("price $920k within band → stretched", A(920000), <<"stretched">>),
     check("price $1.0M > high end → misaligned", A(1000000), <<"misaligned">>),
     check("price = the low end ($806k) → aligned (boundary)", A(806000), <<"aligned">>),
     check("price = the high end ($936k) → stretched (boundary)", A(936000), <<"stretched">>)].

%% --- 5. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(upstream()),
    Merged = fh_engine_fill:merge_agent(<<"buying_strategy">>, O,
                                        #{<<"negotiation_style">> => <<"thesis_walk_away">>}),
    [check("Layer-1 conforms: scaffold (banded money_range + nulls + bilingual copy)",
           validate(O), ok),
     check("Layer-1 conforms: merged outcome (negotiation_style folded)",
           validate(Merged), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"bid_plan_investor">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 6. two-path merge (the one negotiation leaf; §98 figure-tight) ----------

two_path_cases() ->
    {O, _, _} = scaffold(upstream()),
    %% the agent reply carries the style AND (adversarially) a stray price key; merge_agent must
    %% fold ONLY negotiation_style and leave every resolver figure untouched (§98).
    Agent = #{<<"negotiation_style">> => <<"low_anchor">>,
              <<"max_bid_value">> => [1, 1],          %% a price the agent must NOT be able to set
              <<"yield_anchored_max_price">> => [2, 2]},
    Merged = fh_engine_fill:merge_agent(<<"buying_strategy">>, O, Agent),
    AV = fh_engine_fill:agent_values_from_outcome(
           <<"buying_strategy">>, Merged#{<<"negotiation_style">> => <<"low_anchor">>}),
    [check("merge folds negotiation_style",
           g(Merged, <<"negotiation_style">>), <<"low_anchor">>),
     check("merge leaves max_bid_value untouched (§98 — agent can't author a price)",
           g(Merged, <<"max_bid_value">>), [806000, 936000]),
     check("merge leaves yield_anchored_max_price untouched",
           g(Merged, <<"yield_anchored_max_price">>), [806000, 936000]),
     check("merge does not add stray keys (field set unchanged)",
           lists:sort(maps:keys(Merged)), lists:sort(fields())),
     check("agent_values_from_outcome round-trips the style",
           maps:get(<<"negotiation_style">>, AV), <<"low_anchor">>)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
