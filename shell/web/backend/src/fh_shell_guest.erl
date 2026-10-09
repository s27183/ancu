-module(fh_shell_guest).

%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> a guest session, claimed on sign-in
%% Behavior 45 (Son, 2026-10-10): a visitor who is not signed in builds a full plan.
%% Their first signed-out create makes a guest — a users row with guest = true and no
%% email (fh_shell_store:create_guest/0) — and sets the ordinary fh_session cookie for
%% it with the role "guest", lasting as long as the plan is kept (7 days, the notice's
%% promise). Everything a signed-in user does then works for the guest unchanged
%% (ownership by plan_card_views, metering by usage_records), except what spends an
%% assistant turn on their behalf (refuse/1). Signing in from the same browser
%% claims the guest (claim/2): its plans move into the account, with no rebuild.

-export([is_guest/1, start/1, claim/2, refuse/1, ttl/0]).

-define(SESSION_COOKIE, <<"fh_session">>).
-define(TTL, 7 * 86400).

-spec ttl() -> pos_integer().
ttl() -> ?TTL.

-spec is_guest(map()) -> boolean().
is_guest(Claims) ->
    lists:member(<<"guest">>, maps:get(<<"roles">>, Claims, [])).

%% A new guest for this browser: the users row and its session cookie. Returns the
%% guest's user_id and the request carrying the Set-Cookie.
-spec start(cowboy_req:req()) -> {binary(), cowboy_req:req()}.
start(Req) ->
    {UserId, Locale} = fh_shell_store:create_guest(),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => null,
                               roles => [<<"guest">>], locale => Locale}, ?TTL),
    Req1 = cowboy_req:set_resp_cookie(?SESSION_COOKIE, Jwt, Req,
                                      fh_shell_h_auth:session_cookie_opts(?TTL)),
    logger:info("[guest] new guest ~s", [UserId]),
    {UserId, Req1}.

%% Called by sign-in (magic link, Google) before the new session replaces the cookie:
%% if this browser still carries a guest session, its plans move to UserId and the
%% guest row is deleted. Anything else (no session, a real user's) is left alone.
-spec claim(cowboy_req:req(), binary()) -> ok.
claim(Req, UserId) ->
    case fh_shell_http:authenticate_user(Req) of
        {ok, #{<<"user_id">> := GuestId} = Claims} when GuestId =/= UserId ->
            case is_guest(Claims) of
                true ->
                    Moved = fh_shell_store:claim_guest(GuestId, UserId),
                    logger:info("[guest] ~s claimed by ~s: ~B plan(s)", [GuestId, UserId, Moved]),
                    ok;
                false -> ok
            end;
        _ -> ok
    end.

%% The refusal a guest gets where a signed-in account is required (the assistant, an
%% agent turn, billing): 403 with a reason the SPA turns into its sign-in prompt.
-spec refuse(cowboy_req:req()) -> cowboy_req:req().
refuse(Req) ->
    fh_shell_http:reply_json(403, #{<<"error">> => <<"sign_in_required">>}, Req).
