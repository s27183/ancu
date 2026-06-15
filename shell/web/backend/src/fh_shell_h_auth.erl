-module(fh_shell_h_auth).

%% The login flow (shell-architecture.md §3 — the browser<->shell identity seam).
%% One handler module, five actions selected by the route's init opt:
%%
%%   magic_request   POST /api/auth/magic           {email} -> 202, mail a link
%%   magic_verify    GET  /api/auth/magic/verify?token=...  -> set cookie, 302 app
%%   logout          POST /api/auth/logout                  -> clear cookie
%%   google_start    GET  /api/auth/google                  -> 302 Google consent
%%   google_callback GET  /api/auth/google/callback?code&state -> set cookie, 302 app
%%
%% On success the shell issues the USER JWT (HS256, fh_shell_jwt) and sets it as an
%% httpOnly, SameSite=Lax session cookie (`fh_session`). The token is never exposed to
%% JS — XSS cannot read it, and the redirect-based magic-link / OAuth flows land the
%% browser back on the app already authenticated. (The engine never sees this token;
%% the shell mints a separate ed25519 tenant JWT per engine call, fh_shell_engine_jwt.)
%%
%% Identity model: a user is keyed by email (001_init_shell.sql UNIQUE). A magic link
%% proves control of the email; Google with email_verified proves the same — so both
%% paths upsert-by-email and converge on one user. First sign-in creates the row.

-export([init/2]).

-define(SESSION_COOKIE, <<"fh_session">>).
-define(OAUTH_STATE_COOKIE, <<"fh_oauth_state">>).
-define(SESSION_TTL, 86400).         %% must match fh_shell_jwt TTL (a day)
-define(OAUTH_STATE_TTL, 600).       %% the consent round-trip is short

-define(GOOGLE_AUTH_URL, "https://accounts.google.com/o/oauth2/v2/auth").
-define(GOOGLE_TOKEN_URL_DEFAULT, "https://oauth2.googleapis.com/token").

init(Req, [Action] = State) ->
    {ok, dispatch(Action, Req), State}.

%% --- dispatch + method guard ------------------------------------------------

dispatch(magic_request, Req)   -> post_only(Req, fun magic_request/1);
dispatch(magic_verify, Req)    -> get_only(Req, fun magic_verify/1);
dispatch(logout, Req)          -> post_only(Req, fun logout/1);
dispatch(google_start, Req)    -> get_only(Req, fun google_start/1);
dispatch(google_callback, Req) -> get_only(Req, fun google_callback/1).

post_only(Req, Fun) -> guard(<<"POST">>, Req, Fun).
get_only(Req, Fun)  -> guard(<<"GET">>, Req, Fun).

guard(Method, Req, Fun) ->
    case cowboy_req:method(Req) of
        Method -> Fun(Req);
        _ -> fh_shell_http:reply_json(405, #{<<"error">> => <<"method_not_allowed">>}, Req)
    end.

%% --- magic link -------------------------------------------------------------

%% Always answer 202 when an email is present, whether or not it maps to an account:
%% the reply must not reveal which addresses exist (account enumeration). Delivery is
%% best-effort (fh_shell_mail). In dev (AUTH_DEV_EXPOSE_LINK) the link is echoed back
%% so the loop works with no inbox.
magic_request(Req0) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            case email_of(Body) of
                {ok, Email} ->
                    Raw = new_token(),
                    ok = fh_shell_store:insert_magic_token(Email, token_hash(Raw)),
                    Url = app_url(<<"/api/auth/magic/verify?token=", Raw/binary>>),
                    ok = fh_shell_mail:send_magic_link(Email, Url),
                    fh_shell_http:reply_json(202, sent_body(Url), Req1);
                error ->
                    fh_shell_http:reply_json(400, #{<<"error">> => <<"email_required">>}, Req1)
            end;
        {error, invalid_json} ->
            fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_json">>}, Req0)
    end.

%% Redeem the link: hash the raw token, atomically consume it (single-use), and on
%% success issue a session. A bad/expired/used link is NOT an error page — it redirects
%% back to the app with a calm flag the SPA renders (§7.1).
magic_verify(Req) ->
    case qs(<<"token">>, Req) of
        undefined ->
            redirect_app(<<"/?signin=invalid">>, Req);
        Raw ->
            case fh_shell_store:redeem_magic_token(token_hash(Raw)) of
                {ok, Email} ->
                    {UserId, Role, Locale, Extra} = fh_shell_store:upsert_user_by_email(Email),
                    Jwt = issue_jwt(UserId, Email, Role, Extra, Locale),
                    Req1 = set_session_cookie(Jwt, Req),
                    redirect_app(<<"/?signin=ok">>, Req1);
                not_found ->
                    redirect_app(<<"/?signin=expired">>, Req)
            end
    end.

logout(Req) ->
    Req1 = clear_session_cookie(Req),
    fh_shell_http:reply_json(200, #{<<"ok">> => true}, Req1).

%% --- Google OAuth (authorization-code flow) ---------------------------------

google_start(Req) ->
    case google_config() of
        {ok, ClientId, _Secret} ->
            StateTok = new_token(),
            AuthUrl = ?GOOGLE_AUTH_URL ++ "?" ++ uri_string:compose_query([
                {"client_id", binary_to_list(ClientId)},
                {"redirect_uri", binary_to_list(google_redirect_uri())},
                {"response_type", "code"},
                {"scope", "openid email"},
                {"access_type", "online"},
                {"state", binary_to_list(StateTok)}
            ]),
            Req1 = set_oauth_state_cookie(StateTok, Req),
            redirect(list_to_binary(AuthUrl), Req1);
        not_configured ->
            redirect_app(<<"/?signin=google_unavailable">>, Req)
    end.

google_callback(Req) ->
    %% CSRF: the state we set in a short-lived cookie must echo back in the query.
    CookieState = cookie(?OAUTH_STATE_COOKIE, Req),
    case {qs(<<"state">>, Req), CookieState} of
        {S, S} when is_binary(S) ->
            google_exchange(qs(<<"code">>, Req), clear_oauth_state_cookie(Req));
        _ ->
            redirect_app(<<"/?signin=error">>, clear_oauth_state_cookie(Req))
    end.

google_exchange(undefined, Req) ->
    redirect_app(<<"/?signin=error">>, Req);
google_exchange(Code, Req) ->
    case google_config() of
        {ok, ClientId, Secret} ->
            case exchange_code(Code, ClientId, Secret) of
                {ok, Email, Subject} ->
                    {UserId, Role, Locale, Extra} = fh_shell_store:upsert_user_by_email(Email),
                    ok = fh_shell_store:link_oauth(UserId, <<"google">>, Subject),
                    Jwt = issue_jwt(UserId, Email, Role, Extra, Locale),
                    Req1 = set_session_cookie(Jwt, Req),
                    redirect_app(<<"/?signin=ok">>, Req1);
                error ->
                    redirect_app(<<"/?signin=error">>, Req)
            end;
        not_configured ->
            redirect_app(<<"/?signin=google_unavailable">>, Req)
    end.

%% POST the code to Google's token endpoint, then read the verified email + subject
%% from the returned id_token. The id_token comes straight from Google over TLS in a
%% server-to-server exchange, so its claims are trusted without re-verifying the
%% signature (the standard code-flow shortcut). We still require email_verified.
-spec exchange_code(binary(), binary(), binary()) ->
    {ok, binary(), binary()} | error.
exchange_code(Code, ClientId, Secret) ->
    FormBody = uri_string:compose_query([
        {"code", binary_to_list(Code)},
        {"client_id", binary_to_list(ClientId)},
        {"client_secret", binary_to_list(Secret)},
        {"redirect_uri", binary_to_list(google_redirect_uri())},
        {"grant_type", "authorization_code"}
    ]),
    Request = {google_token_url(), [], "application/x-www-form-urlencoded", FormBody},
    case httpc:request(post, Request, [], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Resp}} ->
            claims_from_token_response(Resp);
        {ok, {{_, Status, _}, _, Resp}} ->
            logger:warning("Google token exchange failed (~B): ~s", [Status, Resp]),
            error;
        {error, Reason} ->
            logger:warning("Google token exchange transport error: ~p", [Reason]),
            error
    end.

-spec claims_from_token_response(binary()) -> {ok, binary(), binary()} | error.
claims_from_token_response(Resp) ->
    try
        #{<<"id_token">> := IdToken} = fh_shell_util:json_decode(Resp),
        [_Header, Payload, _Sig] = binary:split(IdToken, <<".">>, [global]),
        Claims = fh_shell_util:json_decode(fh_shell_util:b64url_decode(Payload)),
        #{<<"email">> := Email, <<"sub">> := Subject} = Claims,
        case maps:get(<<"email_verified">>, Claims, false) of
            true -> {ok, Email, Subject};
            <<"true">> -> {ok, Email, Subject};
            _ -> logger:warning("Google sign-in with unverified email rejected"), error
        end
    catch
        Class:Reason ->
            logger:warning("Google id_token parse failed: ~p:~p", [Class, Reason]),
            error
    end.

-spec google_config() -> {ok, binary(), binary()} | not_configured.
google_config() ->
    case {env(<<"GOOGLE_CLIENT_ID">>), env(<<"GOOGLE_CLIENT_SECRET">>)} of
        {{ok, Id}, {ok, Secret}} -> {ok, Id, Secret};
        _ -> not_configured
    end.

-spec google_redirect_uri() -> binary().
google_redirect_uri() ->
    app_url(<<"/api/auth/google/callback">>).

%% The token endpoint defaults to Google's; overridable via env so a test can point
%% the server-to-server exchange at a stub (the same pattern as ENGINE_BASE_URL).
-spec google_token_url() -> string().
google_token_url() ->
    case os:getenv("GOOGLE_TOKEN_URL") of
        false -> ?GOOGLE_TOKEN_URL_DEFAULT;
        ""    -> ?GOOGLE_TOKEN_URL_DEFAULT;
        Val   -> Val
    end.

%% --- session issuance + cookies ---------------------------------------------

-spec issue_jwt(binary(), binary(), binary(), [binary()], binary()) -> binary().
issue_jwt(UserId, Email, Role, Extra, Locale) ->
    fh_shell_jwt:issue(#{
        user_id => UserId,
        email   => Email,
        roles   => [Role | Extra],
        locale  => Locale
    }).

set_session_cookie(Jwt, Req) ->
    cowboy_req:set_resp_cookie(?SESSION_COOKIE, Jwt, Req, session_cookie_opts(?SESSION_TTL)).

clear_session_cookie(Req) ->
    cowboy_req:set_resp_cookie(?SESSION_COOKIE, <<>>, Req, session_cookie_opts(0)).

set_oauth_state_cookie(Tok, Req) ->
    cowboy_req:set_resp_cookie(?OAUTH_STATE_COOKIE, Tok, Req, session_cookie_opts(?OAUTH_STATE_TTL)).

clear_oauth_state_cookie(Req) ->
    cowboy_req:set_resp_cookie(?OAUTH_STATE_COOKIE, <<>>, Req, session_cookie_opts(0)).

%% httpOnly + SameSite=Lax: the cookie is never readable by JS and rides only on
%% same-site navigations/requests (the SPA is same-origin in prod, vite-proxied in
%% dev). Secure is on in prod (COOKIE_SECURE) and off in dev so http://localhost works.
session_cookie_opts(MaxAge) ->
    Base = #{
        http_only => true,
        same_site => lax,
        path => <<"/">>,
        max_age => MaxAge
    },
    case cookie_secure() of
        true -> Base#{secure => true};
        false -> Base
    end.

cookie_secure() ->
    case os:getenv("COOKIE_SECURE") of
        "1" -> true;
        "true" -> true;
        _ -> false
    end.

%% --- redirects --------------------------------------------------------------

%% Redirect to a path on the app origin (APP_BASE_URL). The magic-link/OAuth flows are
%% browser navigations, so the response is a 302 the browser follows back to the SPA.
redirect_app(Path, Req) ->
    redirect(app_url(Path), Req).

redirect(Url, Req) ->
    cowboy_req:reply(302, #{<<"location">> => Url}, <<>>, Req).

%% --- small helpers ----------------------------------------------------------

-spec sent_body(binary()) -> map().
sent_body(Url) ->
    Base = #{<<"sent">> => true},
    case os:getenv("AUTH_DEV_EXPOSE_LINK") of
        false -> Base;
        ""    -> Base;
        _     -> Base#{<<"dev_link">> => Url}
    end.

-spec email_of(map()) -> {ok, binary()} | error.
email_of(#{<<"email">> := Email}) when is_binary(Email) ->
    Trimmed = string:trim(Email),
    case {byte_size(Trimmed), binary:match(Trimmed, <<"@">>)} of
        {N, {_, _}} when N >= 3 -> {ok, Trimmed};
        _ -> error
    end;
email_of(_) -> error.

%% A 256-bit random token, base64url (no padding) — the raw value for the email link
%% or the OAuth state. Only its hash is ever persisted (magic_tokens.token_hash).
-spec new_token() -> binary().
new_token() ->
    fh_shell_util:b64url_encode(crypto:strong_rand_bytes(32)).

-spec token_hash(binary()) -> binary().
token_hash(Raw) ->
    binary:encode_hex(crypto:hash(sha256, Raw), lowercase).

-spec qs(binary(), cowboy_req:req()) -> binary() | undefined.
qs(Key, Req) ->
    proplists:get_value(Key, cowboy_req:parse_qs(Req)).

-spec cookie(binary(), cowboy_req:req()) -> binary() | undefined.
cookie(Name, Req) ->
    proplists:get_value(Name, cowboy_req:parse_cookies(Req)).

%% APP_BASE_URL is the origin the user's browser uses (dev: the vite server :5173,
%% which proxies /api to the backend; prod: the same origin that serves the bundle).
%% Links + redirects are built against it so the session cookie lands on that origin.
-spec app_url(binary()) -> binary().
app_url(Path) ->
    Base = case os:getenv("APP_BASE_URL") of
        false -> <<"http://localhost:5173">>;
        ""    -> <<"http://localhost:5173">>;
        Val   -> list_to_binary(Val)
    end,
    <<Base/binary, Path/binary>>.

-spec env(binary()) -> {ok, binary()} | error.
env(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> error;
        ""    -> error;
        Val   -> {ok, list_to_binary(Val)}
    end.
