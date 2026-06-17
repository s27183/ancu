-module(fh_engine_h_suburbs).

%% GET /api/engine/suburbs?state=NSW — the shell map's raw-metric source
%% (suburb-data-foundation §2 "two readers": the map reads the raw metrics; the
%% resolver's coarse suburb.* band is a separate internal <from_suburb> path).
%%
%% AUTHENTICATE the tenant JWT (a registered shell mints it), but do NOT scope by
%% tenant: `suburbs` is GLOBAL reference data with no tenant_id (§1). This is the
%% one handler that authenticates a tenant then ignores it for row selection.
%%
%% `state` is the query grain (§4 "the map queries by state") and is REQUIRED.
%% `state=ALL` is the one explicit opt-in to the national scope (every state in one
%% payload — the map's "ALL" view). A viewport/bbox variant lands later if needed.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, _Claims} ->
            case state_param(Req0) of
                {ok, Scope} ->
                    {Label, Suburbs} = case Scope of
                        all -> {<<"ALL">>, fh_engine_store:list_all_suburbs()};
                        St  -> {St, fh_engine_store:list_suburbs_by_state(St)}
                    end,
                    Body = #{
                        <<"state">> => Label,
                        <<"suburbs">> => Suburbs,
                        <<"attribution">> => fh_engine_store:list_suburb_sources()
                    },
                    {ok, fh_engine_http:reply_json(200, Body, Req0), State};
                {error, Body} ->
                    {ok, fh_engine_http:reply_json(400, Body, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

%% `state` is required and must be one of the eight CHECK-constrained values
%% (003_suburbs.sql) — reject anything else with 400 rather than run a query that
%% can only return [].
state_param(Req) ->
    Qs = cowboy_req:parse_qs(Req),
    case proplists:get_value(<<"state">>, Qs) of
        undefined ->
            {error, #{<<"error">> => <<"missing_state">>,
                      <<"detail">> => <<"query param `state` is required">>}};
        <<"ALL">> ->
            {ok, all};
        St ->
            case lists:member(St, valid_states()) of
                true  -> {ok, St};
                false -> {error, #{<<"error">> => <<"invalid_state">>,
                                   <<"detail">> => St}}
            end
    end.

valid_states() ->
    [<<"NSW">>, <<"VIC">>, <<"QLD">>, <<"WA">>,
     <<"SA">>, <<"TAS">>, <<"ACT">>, <<"NT">>].
