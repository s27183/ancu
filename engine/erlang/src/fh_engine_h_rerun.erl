-module(fh_engine_h_rerun).

%% POST /api/engine/plan-cards/:id/rerun — DEV-ONLY base-turn re-run.
%%
%% Recomputes a saved card's BASE plan against the CURRENT engine code + KB artifact +
%% profile facts, replacing the base-component snapshots in place (plan-card-refresh.md).
%% Same plan_card_id — identity, per-property addenda, and conversation are preserved
%% (a base turn commits only the base components). Audit-preserving: the new turn appends
%% plan_card_events (append-only) stamped with the current deploy_commit_sha + kb_versions;
%% content_jsonb updates to the latest. Concurrency-safe: the turn registry rejects a
%% second in-flight turn (409).
%%
%% SECURITY BOUNDARY: like POST /dev/tenants, this TRUSTS the caller — it looks the card
%% up by id alone (no JWT, no tenant filter) and recomputes it. A recompute-any-card
%% surface that must never be open in production. So it is GATED on ENGINE_DEV_PROVISION:
%% unset → 404 as if absent. The recompute itself is correctly tenant-scoped (the turn
%% runs under the card's real tenant_id/user_id from the row). Production refresh is a
%% controlled, authenticated trigger reusing the SAME store + turn primitive
%% (plan-card-refresh.md §production refresh policy).

-export([init/2]).

init(Req0, State) ->
    case enabled() of
        false ->
            {ok, fh_engine_http:reply_json(404,
                #{<<"error">> => <<"not_found">>}, Req0), State};
        true ->
            case cowboy_req:method(Req0) of
                <<"POST">> -> handle(Req0, State);
                _ ->
                    {ok, fh_engine_http:reply_json(405,
                        #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
            end
    end.

handle(Req0, State) ->
    PlanCardId = cowboy_req:binding(id, Req0),
    case fh_engine_store:get_card_rerun_context(PlanCardId) of
        {error, not_found} ->
            {ok, fh_engine_http:reply_json(404,
                #{<<"error">> => <<"plan_card_not_found">>}, Req0), State};
        {ok, Ctx} ->
            rerun(PlanCardId, Ctx, Req0, State)
    end.

rerun(PlanCardId, Ctx, Req0, State) ->
    TurnId = fh_engine_util:uuid4(),
    case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
        {error, in_flight} ->
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"turn_in_flight">>,
                  <<"detail">> => <<"a turn is already running for this card">>},
                Req0), State};
        ok ->
            Facts = maps:get(facts, Ctx),
            Onboarding = maps:get(<<"onboarding">>, Facts, #{}),
            Firb = maps:get(<<"firb_required_any">>,
                            maps:get(<<"derived">>, Facts, #{}), false),
            %% IC3: the enriched household financials from the profiles SOT (the canonical
            %% facts_jsonb.household_financials key).
            Financials = maps:get(<<"household_financials">>, Facts, #{}),
            {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                tenant_id => maps:get(tenant_id, Ctx),
                user_id => maps:get(user_id, Ctx),
                plan_card_id => PlanCardId,
                turn_id => TurnId,
                mode => maps:get(mode, Ctx),
                intent => maps:get(intent, Ctx),
                firb_required_any => Firb,
                onboarding => Onboarding,
                household_financials => Financials
            }),
            logger:notice("[dev-rerun] re-ran base turn for card ~s (turn ~s)",
                          [PlanCardId, TurnId]),
            Body = #{<<"plan_card_id">> => PlanCardId,
                     <<"turn_id">> => TurnId,
                     <<"previous_deploy_commit_sha">> => maps:get(deploy_commit_sha, Ctx),
                     <<"current_deploy_commit_sha">> => fh_engine_store:deploy_commit_sha()},
            {ok, fh_engine_http:reply_json(202, Body, Req0), State}
    end.

-spec enabled() -> boolean().
enabled() ->
    case os:getenv("ENGINE_DEV_PROVISION") of
        "1"    -> true;
        "true" -> true;
        _      -> false
    end.
