-module(fh_engine_auth).

%% Identity-token validation (engine-contract §3). The engine VALIDATES shell-minted
%% JWTs; it never originates them (principle 4). EdDSA/ed25519: the shell signs with a
%% private key whose public half is registered per tenant in tenant_signing_keys; the
%% engine verifies the signature with built-in crypto (no jose dep) and scopes every
%% downstream row/registration on the validated tenant_id/user_id.
%%
%% Per-user authorization (RBAC, suspension) is the shell's job — the engine treats
%% user_id as opaque and only proves the token is authentic and unexpired.

-export([verify_bearer/1, sign/2]).

-spec verify_bearer(binary() | undefined) -> {ok, map()} | {error, atom()}.
verify_bearer(undefined) ->
    {error, missing_authorization};
verify_bearer(<<"Bearer ", Token/binary>>) ->
    verify_token(Token);
verify_bearer(_) ->
    {error, malformed_authorization}.

verify_token(Token) ->
    case binary:split(Token, <<".">>, [global]) of
        [HeaderB64, PayloadB64, SigB64] ->
            SigningInput = <<HeaderB64/binary, ".", PayloadB64/binary>>,
            try
                Header = decode_segment(HeaderB64),
                check_alg(Header),
                Payload = decode_segment(PayloadB64),
                Claims = require_claims(Payload),
                check_exp(Claims),
                Sig = fh_engine_util:b64url_decode(SigB64),
                verify_sig(maps:get(tenant_id, Claims), SigningInput, Sig),
                {ok, Claims}
            catch
                throw:Reason -> {error, Reason};
                _:_ -> {error, invalid_token}
            end;
        _ ->
            {error, malformed_jwt}
    end.

decode_segment(Seg) ->
    fh_engine_util:json_decode(fh_engine_util:b64url_decode(Seg)).

check_alg(#{<<"alg">> := <<"EdDSA">>}) -> ok;
check_alg(_) -> throw(unsupported_alg).

require_claims(Payload) ->
    Tenant = maps:get(<<"tenant_id">>, Payload, undefined),
    User = maps:get(<<"user_id">>, Payload, undefined),
    Exp = maps:get(<<"exp">>, Payload, undefined),
    case lists:member(undefined, [Tenant, User, Exp]) of
        true -> throw(missing_claims);
        false -> #{tenant_id => Tenant, user_id => User, exp => Exp}
    end.

check_exp(#{exp := Exp}) ->
    case erlang:system_time(second) < Exp of
        true -> ok;
        false -> throw(token_expired)
    end.

%% Verify against ANY active key for the tenant (key rotation: old+new both active).
verify_sig(TenantId, SigningInput, Sig) ->
    Keys = fh_engine_store:tenant_active_keys(TenantId),
    case Keys of
        [] -> throw(no_signing_key);
        _ ->
            Ok = lists:any(
                fun({<<"ed25519">>, PubB64}) ->
                        PubKey = base64:decode(PubB64),
                        crypto:verify(eddsa, none, SigningInput, Sig,
                                      [PubKey, ed25519]);
                   (_) -> false
                end, Keys),
            case Ok of
                true -> ok;
                false -> throw(bad_signature)
            end
    end.

%% Mint a token (dev/test helper; in production the SHELL signs, not the engine).
%% PrivKey is the raw ed25519 private key.
-spec sign(map(), binary()) -> binary().
sign(Claims, PrivKey) ->
    Header = fh_engine_util:b64url_encode(
        fh_engine_util:json_encode(#{<<"alg">> => <<"EdDSA">>, <<"typ">> => <<"JWT">>})),
    Payload = fh_engine_util:b64url_encode(fh_engine_util:json_encode(Claims)),
    SigningInput = <<Header/binary, ".", Payload/binary>>,
    Sig = fh_engine_util:b64url_encode(
        crypto:sign(eddsa, none, SigningInput, [PrivKey, ed25519])),
    <<SigningInput/binary, ".", Sig/binary>>.
