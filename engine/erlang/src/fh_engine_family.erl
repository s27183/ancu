-module(fh_engine_family).

%% The base-turn `family_context` fill (blueprint fhb-foreign-au.md component 2, NEW for
%% Mode B — mode-b-wedge.md P2 slice 6, the last P2 unit). No shared-name collision — a
%% wholly new component, wholly new module. Reads only `buyer_profile`'s outcome
%% (Inputs: buyer_profile.outcome).
%%
%% EVERY leaf in this component's params (contributors, decision_authority, coordination)
%% is genuinely USER-INPUT — captured via chat on a refine turn, never resolver-derived
%% from a formula (unlike mortgage/cash's regulated figures). So the base-turn job is NOT
%% "compute a value" but "aggregate + score what IS captured" — at base, with
%% profile.off_title_parties = [] (buyer_profile_foreign's honest-partial default, no
%% funder revealed yet), every family-specific fact is honestly empty/null, and the
%% funding_complexity_score sits at its floor (1) rather than guessing a family pattern
%% (kb.vietnamese-family.financial-patterns: "patterns are prompts, never predictions" —
%% [[kb-doc-authoring]]'s sixth reference/decision-support regime, applied here to the
%% RESOLVER side, not just the KB doc).
%%
%% bilingual_coordination_required is COMPUTED from profile.off_title_parties (any funder
%% whose residence_country is not AU), not assumed true just because this is Mode B — a
%% confirmed cross-border party is a data fact, not a mode-level guess
%% (kb.bilingual.coordination-norms: "required whenever a non-English party is a
%% contributor/decision-maker").

-export([fill/2]).
%% exported for the conformance suite:
-export([funding_complexity_score/1, bilingual_coordination_required/1,
         contribution_breakdown/1, documentation_gaps/1]).

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    OffTitleParties = maps:get(<<"off_title_parties">>, Profile, []),
    Funders = funders(OffTitleParties),
    Breakdown = contribution_breakdown(Funders),
    Outcome = #{
        %% no funder captured yet (base default []) -> honestly unknown, never 0
        %% (0 would assert "no money", null means "not yet known").
        <<"total_capacity_aud">> => total_capacity(Funders),
        <<"contribution_breakdown">> => Breakdown,
        %% no primary_decision_maker captured at base — genuinely undetermined
        %% (kb.cross-border.decision-authority-cultural: "prompt, don't profile").
        <<"decision_authority">> => null,
        <<"bilingual_coordination_required">> => bilingual_coordination_required(Funders),
        <<"funding_complexity_score">> => funding_complexity_score(Funders),
        <<"documentation_gaps">> => documentation_gaps(Funders)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.vietnamese-family.financial-patterns">>,
         <<"kb.cross-border.decision-authority-cultural">>,
         <<"kb.bilingual.coordination-norms">>]),
    {Outcome, <<"family-view-card">>, KbVersions}.

%% off_title_parties[] filtered by the funder role flag (architecture §11.9
%% off_title.* namespace — read BY ROLE FLAG, not position; mirrors
%% fh_engine_firb:has_funder/1's filter but keeps the full party map, not just a bool).
funders(OffTitleParties) ->
    lists:filter(
        fun(P) ->
            Funder = maps:get(<<"funder">>, P, #{}),
            maps:get(<<"expected_to_fund">>, Funder, false) =:= true
        end, OffTitleParties).

%% sum of captured funder contribution_capacity_aud; null (not 0) when no funder is
%% captured yet or any captured funder's capacity is itself unset (honest-partial —
%% never a partial sum, mirrors fh_engine_cash:sum_or_null/1's discipline).
total_capacity([]) -> null;
total_capacity(Funders) ->
    Amounts = [maps:get(<<"contribution_capacity_aud">>, maps:get(<<"funder">>, P, #{}), null)
               || P <- Funders],
    case lists:any(fun(A) -> A =:= null end, Amounts) of
        true  -> null;
        false -> lists:sum(Amounts)
    end.

%% one breakdown line per captured funder (party/amount/source/currency_origin) — []
%% when none captured yet, never a fabricated placeholder row.
-spec contribution_breakdown([map()]) -> [map()].
contribution_breakdown(Funders) ->
    [#{<<"party">> => maps:get(<<"relationship">>, P, null),
       <<"amount_aud">> => maps:get(<<"contribution_capacity_aud">>, maps:get(<<"funder">>, P, #{}), null),
       <<"source">> => null,   %% pending: contribution_source is captured on a refine turn (chat)
       <<"currency_origin">> => residence_currency(maps:get(<<"funder">>, P, #{}))}
     || P <- Funders].

residence_currency(#{<<"residence_country">> := <<"VN">>}) -> <<"VND">>;
residence_currency(#{<<"residence_country">> := <<"AU">>}) -> <<"AUD">>;
residence_currency(_) -> null.

%% kb.bilingual.coordination-norms: required whenever a non-English-reading (non-AU-
%% resident) party is a contributor — COMPUTED from confirmed off_title_parties data,
%% never assumed true just because this is Mode B (a mode-level guess would violate the
%% same "prompt, don't profile" discipline the KB doc itself states).
-spec bilingual_coordination_required([map()]) -> boolean().
bilingual_coordination_required(Funders) ->
    lists:any(
        fun(P) ->
            maps:get(<<"residence_country">>, maps:get(<<"funder">>, P, #{}), <<"AU">>) =/= <<"AU">>
        end, Funders).

%% kb.vietnamese-family.financial-patterns: "resolver-scored, never LLM-invented" —
%% floor 1 (nothing captured yet); +1 per additional funder beyond the first
%% (many_contributor_pool_raises_complexity), +1 if any captured funder's origin is
%% non-AU with documentation not yet addressed (vn_leg_origin_is_the_under_evidenced_
%% pinch_point) — capped at 10. At base (Funders=[]) this floors to 1, never guesses a
%% family's actual funding complexity.
-spec funding_complexity_score([map()]) -> integer().
funding_complexity_score(Funders) ->
    Base = 1,
    ExtraFunders = max(0, length(Funders) - 1),
    NonAuOrigin = length([P || P <- Funders,
                          maps:get(<<"residence_country">>, maps:get(<<"funder">>, P, #{}), <<"AU">>) =/= <<"AU">>]),
    min(10, Base + ExtraFunders + min(1, NonAuOrigin)).

%% one gap when any funder is captured but its source/documentation isn't yet addressed
%% (contribution_source is always pending until a refine turn); [] when no funder is
%% captured (nothing to flag yet, not "all clear" — an empty family plan is not a
%% documentation success).
-spec documentation_gaps([map()]) -> [binary()].
documentation_gaps([]) -> [];
documentation_gaps(_Funders) -> [<<"funding_source_and_documentation_pending">>].
