-module(fh_engine_h_dev_provision).

%% POST /api/engine/dev/tenants — DEV-ONLY tenant self-registration (the shell↔engine
%% provisioning handshake, 8-S0b's gap closed for local dev only).
%%
%% SECURITY BOUNDARY: this endpoint trusts whoever calls it to register a tenant +
%% its public signing key. Because the engine treats user_id as opaque and trusts
%% the tenant a JWT names (fh_engine_auth), an open registration path is a forge-any-
%% user hole in production. So it is GATED on ENGINE_DEV_PROVISION: unset → the route
%% replies 404 as if it does not exist. In production, tenant provisioning is a
%% deliberate out-of-band admin action, never this handler.
%%
%% Body: {"tenant_id": uuid, "public_key": base64(ed25519 pub), "algo": "ed25519",
%%        "name": "..."}. Idempotent: re-posting the same key is a no-op.

-export([init/2]).

init(Req0, State) ->
    case enabled() of
        false ->
            {ok, fh_engine_http:reply_json(404,
                #{<<"error">> => <<"not_found">>}, Req0), State};
        true ->
            handle(Req0, State)
    end.

handle(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            TenantId = maps:get(<<"tenant_id">>, Body, undefined),
            PubKey   = maps:get(<<"public_key">>, Body, undefined),
            Algo     = maps:get(<<"algo">>, Body, <<"ed25519">>),
            Name     = maps:get(<<"name">>, Body, <<"dev-shell">>),
            case lists:member(undefined, [TenantId, PubKey]) of
                true ->
                    {ok, fh_engine_http:reply_json(400,
                        #{<<"error">> => <<"missing_fields">>,
                          <<"detail">> => <<"tenant_id and public_key are required">>},
                        Req1), State};
                false ->
                    ok = fh_engine_store:upsert_tenant(TenantId, Name),
                    ok = fh_engine_store:ensure_signing_key(TenantId, Algo, PubKey),
                    logger:notice("[dev-provision] registered tenant ~s (~s)",
                                  [TenantId, Algo]),
                    {ok, fh_engine_http:reply_json(200,
                        #{<<"ok">> => true, <<"tenant_id">> => TenantId}, Req1), State}
            end;
        {error, _} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

-spec enabled() -> boolean().
enabled() ->
    case os:getenv("ENGINE_DEV_PROVISION") of
        "1"    -> true;
        "true" -> true;
        _      -> false
    end.
