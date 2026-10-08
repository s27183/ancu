#!/usr/bin/env escript
%%! -sname fh_shell_seam_roundtrip
%%
%% 8-S0b ablation: prove the shell's tenant-JWT MINT PATH verifies against the REAL
%% engine — the load-bearing identity seam (shell-architecture.md §3). This is the
%% shell-side mirror of engine/erlang/test/seam_smoke.escript (which seeds + mints
%% in-process via the engine's own helper); here the SHELL'S production code
%% (fh_shell_engine_jwt:mint/1 + fh_shell_engine_client) does the minting + calling.
%%
%% No engine changes (the green-light scope). The engine is booted as-is; the only
%% engine code used is fh_engine_store (the PROVISIONING fixture — register the
%% shell's ed25519 public key in tenant_signing_keys, exactly what seam_smoke:25-26
%% does and what a production provisioning step must do; the production MECHANISM
%% for that one-time write — an engine admin endpoint vs an ops escript — is a
%% deferred decision, not on this ablation's path).
%%
%% Needs BOTH build libs on the path + the engine's dev Postgres (5433):
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
%%   escript test/seam_roundtrip.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),

    %% --- provisioning fixture: the shell's tenant keypair, public half registered
    %%     engine-side (stands in for the one-time provisioning write) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"shell-web">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),

    %% --- the shell backend's runtime config (.env, never user-facing) ---
    os:putenv("SHELL_TENANT_ID", binary_to_list(TenantId)),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL", "http://localhost:8093/api/engine"),

    CreateBody = #{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [600000, 700000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"owner_occupier">>
    },

    %% --- POSITIVE: shell mints with the registered key -> engine accepts (202) ---
    {Status, Resp} = fh_shell_engine_client:create_plan_card(UserId, CreateBody),
    expect(Status =:= 202, "shell-minted tenant JWT accepted by engine (202)"),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := TurnId} =
        fh_shell_util:json_decode(Resp),
    expect(is_binary(PlanCardId) andalso is_binary(TurnId),
           "engine returns plan_card_id + turn_id"),
    io:format("  created plan_card_id=~s~n", [PlanCardId]),

    %% --- NEGATIVE: shell mints with an UNREGISTERED key -> engine rejects (403).
    %%     Proves the engine VERIFIES the signature against the registered public
    %%     key, not merely parses a well-formed token. ---
    {_, BadPriv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(BadPriv))),
    {BadStatus, _} = fh_shell_engine_client:create_plan_card(UserId, CreateBody),
    expect(BadStatus =:= 403, "unregistered-key token rejected (403 bad_signature)"),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    %% --- user JWT (HS256) self round-trip: issue -> verify, and tamper -> reject ---
    os:putenv("SHELL_JWT_SECRET", "test-shell-secret-0123456789"),
    UserTok = fh_shell_jwt:issue(#{user_id => UserId, email => <<"a@b.co">>,
                                   roles => [<<"buyer">>], locale => <<"vi">>}),
    {ok, UClaims} = fh_shell_jwt:verify(UserTok),
    expect(maps:get(<<"user_id">>, UClaims) =:= UserId andalso
           maps:get(<<"locale">>, UClaims) =:= <<"vi">>,
           "user JWT issue->verify round-trips claims"),
    %% Splice a well-formed-but-wrong signature (from a token over a DIFFERENT
    %% payload) onto this token's header.payload: it decodes cleanly but fails the
    %% mac -> bad_signature (proves the compare, not just base64 well-formedness).
    OtherTok = fh_shell_jwt:issue(#{user_id => fh_engine_util:uuid4(),
                                    email => <<"c@d.co">>,
                                    roles => [<<"buyer">>], locale => <<"vi">>}),
    [H1, P1, _S1] = binary:split(UserTok, <<".">>, [global]),
    [_, _, S2] = binary:split(OtherTok, <<".">>, [global]),
    Tampered = <<H1/binary, ".", P1/binary, ".", S2/binary>>,
    expect(fh_shell_jwt:verify(Tampered) =:= {error, bad_signature},
           "tampered user JWT rejected (constant-time mac compare)"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
