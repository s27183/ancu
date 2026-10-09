-module(fh_shell_jwt).

%% User JWT (browser <-> shell-backend), shell-architecture.md §3. HS256, signed
%% with the shell's symmetric SHELL_JWT_SECRET — this token never leaves the shell's
%% trust domain (the engine never sees it; the engine only sees the ed25519 tenant
%% JWT, fh_shell_engine_jwt). Carries role + locale so route guards + middleware can
%% enforce RBAC and pick the display language without a DB hit per request.
%%
%% Issued by fh_shell_login after Resend magic-link / Google OAuth (login flow is a
%% later slice); 8-S0 builds the issue/verify primitive + proves the round-trip.

-export([issue/1, issue/2, verify/1]).

%% A day — the user session length. Refreshed by re-login; short enough that a
%% role revocation takes effect within a day without a server-side session store.
-define(TTL_SECONDS, 86400).

-spec issue(#{user_id := binary(), email := binary() | null,
              roles := [binary()], locale := binary()}) -> binary().
issue(Claims) ->
    issue(Claims, ?TTL_SECONDS).

%% A session of a given length: a guest's lasts as long as its plan is kept (7 days,
%% fh_shell_guest, behavior 45); a guest has no email (null).
-spec issue(#{user_id := binary(), email := binary() | null,
              roles := [binary()], locale := binary()}, pos_integer()) -> binary().
issue(#{user_id := UserId, email := Email, roles := Roles, locale := Locale}, Ttl) ->
    Now = erlang:system_time(second),
    Claims = #{
        <<"user_id">> => UserId,
        <<"email">>   => Email,
        <<"roles">>   => Roles,
        <<"locale">>  => Locale,
        <<"iat">>     => Now,
        <<"exp">>     => Now + Ttl
    },
    Header = fh_shell_util:b64url_encode(
        fh_shell_util:json_encode(#{<<"alg">> => <<"HS256">>, <<"typ">> => <<"JWT">>})),
    Payload = fh_shell_util:b64url_encode(fh_shell_util:json_encode(Claims)),
    SigningInput = <<Header/binary, ".", Payload/binary>>,
    Sig = fh_shell_util:b64url_encode(mac(SigningInput)),
    <<SigningInput/binary, ".", Sig/binary>>.

-spec verify(binary()) -> {ok, map()} | {error, atom()}.
verify(Token) ->
    case binary:split(Token, <<".">>, [global]) of
        [HeaderB64, PayloadB64, SigB64] ->
            SigningInput = <<HeaderB64/binary, ".", PayloadB64/binary>>,
            try
                Header = decode_segment(HeaderB64),
                check_alg(Header),
                Expected = mac(SigningInput),
                Got = fh_shell_util:b64url_decode(SigB64),
                %% constant-time compare — never branch on secret-derived bytes early
                case crypto:hash_equals(Expected, Got) of
                    true -> ok;
                    false -> throw(bad_signature)
                end,
                Claims = fh_shell_util:json_decode(
                    fh_shell_util:b64url_decode(PayloadB64)),
                check_exp(Claims),
                {ok, Claims}
            catch
                throw:Reason -> {error, Reason};
                _:_ -> {error, invalid_token}
            end;
        _ ->
            {error, malformed_jwt}
    end.

%% --- internals ---

-spec mac(binary()) -> binary().
mac(SigningInput) ->
    crypto:mac(hmac, sha256, secret(), SigningInput).

-spec secret() -> binary().
secret() ->
    case os:getenv("SHELL_JWT_SECRET") of
        false -> error({missing_env, "SHELL_JWT_SECRET"});
        ""    -> error({empty_env, "SHELL_JWT_SECRET"});
        Val   -> list_to_binary(Val)
    end.

decode_segment(Seg) ->
    fh_shell_util:json_decode(fh_shell_util:b64url_decode(Seg)).

check_alg(#{<<"alg">> := <<"HS256">>}) -> ok;
check_alg(_) -> throw(unsupported_alg).

check_exp(#{<<"exp">> := Exp}) when is_integer(Exp) ->
    case erlang:system_time(second) < Exp of
        true -> ok;
        false -> throw(token_expired)
    end;
check_exp(_) -> throw(missing_exp).
