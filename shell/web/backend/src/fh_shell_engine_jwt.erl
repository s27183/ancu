-module(fh_shell_engine_jwt).

%% Mints the tenant JWT the engine verifies (shell-architecture.md §3 — THE
%% load-bearing identity seam). The shell holds an ed25519 PRIVATE key; the engine
%% holds only the public half in tenant_signing_keys and verifies the signature
%% (fh_engine_auth:verify_bearer/1). This module is the production minter — the
%% counterpart to the engine's fh_engine_auth:sign/2, which is a dev/test helper
%% (its own comment: "in production the SHELL signs, not the engine").
%%
%% Deliberately NOT shared code with the engine. The engine and shell are separate
%% deployables; the contract between them is the JWT WIRE FORMAT (alg EdDSA, claims
%% {tenant_id, user_id, exp, iat}), not an Erlang library. A shared module would
%% couple the two deploys (engine-contract §9). So this is a faithful re-expression
%% of that wire format, signed with the shell's key.
%%
%% Config (the shell backend's .env — never user-facing, engine-contract §6):
%%   SHELL_TENANT_ID       the shell's tenant_id (uuid), registered in the engine
%%   SHELL_TENANT_PRIVKEY  base64 of the raw ed25519 private key (public half is
%%                         registered engine-side at provisioning)
%% The keypair is generated and the public half registered ONCE at provisioning
%% (not per request); minting is per request, short-lived.

-export([mint/1]).

%% Short TTL: the tenant JWT is minted fresh per request to /api/engine/* and is in
%% flight for seconds. A tight expiry bounds replay if a token leaks (engine checks
%% exp). 120s covers clock skew + a slow request without being a standing credential.
-define(TTL_SECONDS, 120).

-spec mint(#{user_id := binary()}) -> binary().
mint(#{user_id := UserId}) when is_binary(UserId) ->
    TenantId = require_env("SHELL_TENANT_ID"),
    Priv = base64:decode(require_env("SHELL_TENANT_PRIVKEY")),
    Now = erlang:system_time(second),
    Claims = #{
        <<"tenant_id">> => TenantId,
        <<"user_id">>   => UserId,
        <<"iat">>       => Now,
        <<"exp">>       => Now + ?TTL_SECONDS
    },
    sign(Claims, Priv).

%% Identical wire format to fh_engine_auth:sign/2: b64url(header).b64url(payload)
%% signed with ed25519, signature b64url-appended.
-spec sign(map(), binary()) -> binary().
sign(Claims, Priv) ->
    Header = fh_shell_util:b64url_encode(
        fh_shell_util:json_encode(#{<<"alg">> => <<"EdDSA">>, <<"typ">> => <<"JWT">>})),
    Payload = fh_shell_util:b64url_encode(fh_shell_util:json_encode(Claims)),
    SigningInput = <<Header/binary, ".", Payload/binary>>,
    Sig = fh_shell_util:b64url_encode(
        crypto:sign(eddsa, none, SigningInput, [Priv, ed25519])),
    <<SigningInput/binary, ".", Sig/binary>>.

-spec require_env(string()) -> binary().
require_env(Name) ->
    case os:getenv(Name) of
        false -> error({missing_env, Name});
        ""    -> error({empty_env, Name});
        Val   -> list_to_binary(Val)
    end.
