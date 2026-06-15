-module(fh_shell_provision).

%% DEV-ONLY tenant self-provisioning (the shell half of the shell↔engine handshake;
%% 8-S0b's manual-escript gap closed for local dev). Run once at boot.
%%
%% When SHELL_DEV_AUTOPROVISION is set AND no static SHELL_TENANT_PRIVKEY is present,
%% the shell mints its OWN ed25519 keypair, holds the private half in persistent_term
%% for the process lifetime (fh_shell_engine_jwt reads it), and POSTs the PUBLIC half
%% to the engine's dev-provision endpoint. Nothing is written to disk: a fresh keypair
%% per boot, the engine upserts it idempotently.
%%
%% In production this is a no-op: SHELL_DEV_AUTOPROVISION is unset and the real
%% SHELL_TENANT_PRIVKEY (registered out-of-band) drives minting. See
%% fh_engine_h_dev_provision for the matching engine-side gate + security boundary.

-export([maybe_autoprovision/0]).

%% A stable, well-known dev tenant id so re-runs reuse one tenant row (the engine
%% accumulates only the rotating keys, which all stay active and all verify).
-define(DEFAULT_DEV_TENANT, <<"11111111-1111-1111-1111-111111111111">>).

-spec maybe_autoprovision() -> ok.
maybe_autoprovision() ->
    case enabled() andalso not has_static_key() of
        true  -> do_provision();
        false -> ok
    end.

-spec do_provision() -> ok.
do_provision() ->
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    TenantId = tenant_id(),
    persistent_term:put({fh_shell, tenant_material},
                        #{tenant_id => TenantId, priv => Priv}),
    logger:info("[autoprovision] generated dev tenant key for ~s", [TenantId]),
    register_with_engine(TenantId, base64:encode(Pub)).

%% POST the public key to the engine. Fail-soft: a login-only dev session needs no
%% engine, so an unreachable engine logs a warning and does not abort shell boot.
%% (The minting material is already stashed; once the engine is up and the shell is
%% restarted, the next boot registers cleanly.)
-spec register_with_engine(binary(), binary()) -> ok.
register_with_engine(TenantId, PubB64) ->
    Url = engine_base_url() ++ "/dev/tenants",
    Body = fh_shell_util:json_encode(#{
        <<"tenant_id">>  => TenantId,
        <<"public_key">> => PubB64,
        <<"algo">>       => <<"ed25519">>,
        <<"name">>       => <<"dev-shell">>
    }),
    case httpc:request(post, {Url, [], "application/json", Body},
                       [], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, _}} ->
            logger:info("[autoprovision] registered with engine at ~s", [Url]);
        {ok, {{_, Status, _}, _, Resp}} ->
            logger:warning("[autoprovision] engine returned ~p: ~s "
                           "(is ENGINE_DEV_PROVISION=1 set on the engine?)",
                           [Status, Resp]);
        {error, Reason} ->
            logger:warning("[autoprovision] engine unreachable at ~s (~p) — "
                           "start the engine then restart the shell for plan-card "
                           "calls; login works without it", [Url, Reason])
    end,
    ok.

-spec tenant_id() -> binary().
tenant_id() ->
    case os:getenv("SHELL_TENANT_ID") of
        false -> ?DEFAULT_DEV_TENANT;
        ""    -> ?DEFAULT_DEV_TENANT;
        Val   -> list_to_binary(Val)
    end.

-spec engine_base_url() -> string().
engine_base_url() ->
    case os:getenv("ENGINE_BASE_URL") of
        false -> "http://localhost:8080/api/engine";
        Url   -> Url
    end.

-spec enabled() -> boolean().
enabled() ->
    case os:getenv("SHELL_DEV_AUTOPROVISION") of
        "1"    -> true;
        "true" -> true;
        _      -> false
    end.

-spec has_static_key() -> boolean().
has_static_key() ->
    case os:getenv("SHELL_TENANT_PRIVKEY") of
        false -> false;
        ""    -> false;
        _     -> true
    end.
