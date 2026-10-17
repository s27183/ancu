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
-export([client_addr/1, daily_limit/0, limited/2, start_limit/0]).
-export([held_limit/1, full/2]).

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

%% The client's address for the per-address cap: the first X-Forwarded-For entry (the
%% app sits behind DigitalOcean's proxy), else the socket peer (local dev). Logged with
%% the raw header on each guest create, so prod shows what the proxy sends before the
%% cap is trusted (behavior 45's Assumes).
-spec client_addr(cowboy_req:req()) -> binary().
client_addr(Req) ->
    case cowboy_req:header(<<"x-forwarded-for">>, Req, undefined) of
        undefined -> peer(Req);
        Xff ->
            case string:trim(hd(binary:split(Xff, <<",">>))) of
                <<>> -> peer(Req);
                First -> First
            end
    end.

peer(Req) ->
    {Ip, _Port} = cowboy_req:peer(Req),
    list_to_binary(inet:ntoa(Ip)).

%% Plans a guest — and one address — may build a Sydney day (GUEST_DAILY_CREATES,
%% default 3, Son 2026-10-10; 14 since behavior 111: twice the held cap below, so the
%% held cap is the limit a visitor meets and a guest who fills 7 and deletes one can
%% make another the same day — at 7 the freed slot waited for tomorrow).
-spec daily_limit() -> pos_integer().
daily_limit() ->
    case os:getenv("GUEST_DAILY_CREATES") of
        false -> 14;
        V -> try list_to_integer(V) of N when N >= 1 -> N; _ -> 14 catch _:_ -> 14 end
    end.

%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> the plans a visitor holds
%% Purpose:   behavior 111 (Son 2026-10-17: "increase the number of saved plan for
%%            non-signed in user to 7. for the signed in user, it's 28"): a visitor holds
%%            at most this many plans at once — a guest 7, a signed-in visitor 28 — and
%%            makes room by deleting one (DELETE /api/plan-cards/:id) or, a guest, by
%%            signing in.
%% Holds:     the count is plan_card_views not archived (fh_shell_store:plans_saved/1, the
%%            rows the list shows), checked in the create under a per-owner lock in the
%%            create's transaction (fh_shell_store:with_plan_slot/3), so two creates at
%%            once cannot both take the last slot; a repeat of a create key returns its
%%            plan before the check. A guest's plans claimed at sign-in may take an
%%            account past 28: it keeps them and only cannot make another.
%% Rests on:  the guest purge still takes a guest's plans after 7 days (ttl/0).
-spec held_limit(guest | user) -> pos_integer().
held_limit(guest) -> 7;
held_limit(user)  -> 28.

%% The reply to a create at the held cap: 409 with the cap, what is held and who holds
%% it, so the page names the way out (delete a plan; a guest: sign in for 28).
-spec full(guest | user, non_neg_integer()) -> {409, map()}.
full(Kind, Held) ->
    {409, #{<<"error">> => <<"plans_full">>,
            <<"limit">> => held_limit(Kind),
            <<"held">> => Held,
            <<"kind">> => atom_to_binary(Kind)}}.

%% Guests one address may start a Sydney day before any create (fh_shell_h_guest,
%% behavior 97): three times the create cap — a browser keeps its guest for 7 days, so
%% only a cleared cookie or another device on the same network starts another; the
%% bound stops a script filling the users table with plan-less guests (the purge takes
%% them after 7 days).
-spec start_limit() -> pos_integer().
start_limit() -> 3 * daily_limit().

%% The reply to a capped guest: 429 with the cap and when it resets (the dialog asks
%% the visitor to sign in, behavior 45).
-spec limited(pos_integer(), binary()) -> {429, map()}.
limited(Limit, Resets) ->
    {429, #{<<"error">> => <<"guest_daily_limit">>,
            <<"limit">> => Limit,
            <<"resets_at">> => Resets}}.
