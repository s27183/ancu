-module(fh_engine_h_refine).

%% POST /api/engine/plan-cards/:id/refine — the simulate COMMIT half (engine-contract
%% §10.2 / §10.3, lifecycle-simulation-model.md §4.3). Body:
%% {"overrides": {"target_price": <number>, "state": <"NSW"|...>}}.
%%
%% Saves a previewed structural what-if as the card's CURRENT scenario:
%%   1. persists the override INPUTS to the plan-target overlay (plan_cards.target_jsonb —
%%      target_* is a PLAN fact, so it lands on the card, never profiles), then
%%   2. runs a base_resolver turn that advances the single content_jsonb snapshot.
%%
%% Differs from /simulate (preview): this PERSISTS — a new plan_card_events row + snapshot
%% (deploy_commit_sha + resolved KB, the audit trail), and the full FIRB/ASIC/AML pipeline
%% runs at commit (§10.3). Differs from the dev-only /rerun: AUTHENTICATED + tenant-scoped
%% (get_plan_card(T, Id) before any read), and driven by the OVERRIDDEN onboarding.
%%
%% Resolver-only / no `usage` by construction: the shared base_resolver primitive
%% (fh_engine_refresh:start_base_resolver/4) re-runs the deterministic fills, SKIPS the
%% two-path sidecar, and re-attaches the stored agent leaves (the lender shortlist is
%% preserved, not re-billed). The override mapping + rejects are the SAME as /simulate
%% (fh_engine_simulate:apply_overrides/2 — one mapping, both paths); a `state` save STRIPS
%% target_sal/target_zone (the explicit save supersedes the pin — §4.3).

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            Id = cowboy_req:binding(id, Req0),
            %% Tenant-scope: confirm ownership before any read. The Card also carries the
            %% content snapshot we need for existing_outcomes (the stored agent leaves).
            case fh_engine_store:get_plan_card(T, Id) of
                {ok, Card} -> read_and_run(Id, Card, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_run(Id, Card, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> run(Id, Card, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

run(Id, Card, Body, Req, State) ->
    Overrides = maps:get(<<"overrides">>, Body, #{}),
    case fh_engine_store:get_card_rerun_context(Id) of
        {error, not_found} ->
            {ok, fh_engine_http:reply_json(404,
                #{<<"error">> => <<"not_found">>}, Req), State};
        {ok, Ctx} ->
            %% Onboarding0 is the card's CURRENT effective scenario (the overlay already
            %% applied by get_card_rerun_context), so overrides accumulate on a refined card.
            Onboarding0 = maps:get(<<"onboarding">>, maps:get(facts, Ctx), #{}),
            case fh_engine_simulate:apply_overrides(Overrides, Onboarding0) of
                {ok, Onboarding} -> commit(Id, Card, Ctx, Onboarding, Req, State);
                {error, Reason}  -> reject(Reason, Req, State)
            end
    end.

commit(Id, Card, Ctx, Onboarding, Req, State) ->
    Existing = fh_engine_refresh:existing_outcomes(Card),
    case fh_engine_refresh:start_base_resolver(Id, Ctx, Existing, Onboarding) of
        {ok, TurnId} ->
            %% Persist the saved scenario (the override INPUTS) only after the turn is
            %% reserved + started, so a 409 never mutates the target. The turn reads its
            %% onboarding from its start args, not this column — write order is immaterial.
            ok = fh_engine_store:set_card_target(Id, Onboarding),
            logger:notice("[refine] committed scenario for card ~s (turn ~s)", [Id, TurnId]),
            {ok, fh_engine_http:reply_json(202,
                #{<<"plan_card_id">> => Id, <<"turn_id">> => TurnId}, Req), State};
        {error, in_flight} ->
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"turn_in_flight">>,
                  <<"detail">> => <<"a turn is already running for this card">>},
                Req), State}
    end.

%% Override rejects — same atoms as /simulate (the shared apply_overrides/2).
reject(property_type_phase_b, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"override_not_supported">>,
          <<"field">> => <<"property_type">>,
          <<"detail">> => <<"property_type is a Phase-B (per-property) dimension; attach a "
                            "property to vary it. Base refine accepts target_price and state.">>},
        Req), State};
reject({unknown_override, K}, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"unknown_override">>, <<"field">> => K}, Req), State};
reject({invalid_override, K}, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"invalid_override">>, <<"field">> => K}, Req), State};
reject(not_a_map, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"invalid_overrides">>,
          <<"detail">> => <<"`overrides` must be an object">>}, Req), State}.
