-module(fh_shell_h_guest).

%% POST /api/auth/guest — make this browser a guest before it creates a plan.
%%
%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> the guest is made before the create
%% Behavior 97 (Son 2026-10-16: a plan made while the phone locked was lost). Until
%% then a first-time guest was made inside the create, and its session cookie rode only
%% on the create's 202: a phone that locked after the POST left and before that reply
%% arrived lost the cookie, so the plan existed, the day's quota was spent, and the
%% plan was out of reach — and a retry made a second guest and a second plan. The
%% onboarding dialog now calls this when it opens; the create that follows carries the
%% cookie, so its create key can be matched to its owner (fh_shell_h_plan_cards once/3).
%%
%% A browser with any valid session (a guest, a signed-in user) gets 200 and nothing is
%% made. Otherwise the cap still runs before a guest is made (the block above
%% fh_shell_h_plan_cards guest_create): an address at its create cap gets the same 429
%% the create would give, and no guest; an address may start at most
%% fh_shell_guest:start_limit/0 guests a Sydney day, counted in guest_daily_creates
%% under kind 'addr' with the key "start:<addr>" (the table's kinds are guest | addr,
%% 005_guest_plans.sql; the prefix keeps it apart from the address's create count).
%% Starting a guest claims no create: the create claims the address and the guest.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> {ok, start(Req0), State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

start(Req0) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, Claims} ->
            fh_shell_http:reply_json(200,
                #{<<"guest">> => fh_shell_guest:is_guest(Claims), <<"new">> => false}, Req0);
        {error, 401, _} ->
            Limit = fh_shell_guest:daily_limit(),
            Addr = fh_shell_guest:client_addr(Req0),
            case fh_shell_store:guest_creates_today(addr, Addr) >= Limit of
                true ->
                    reply(fh_shell_guest:limited(Limit, next_reset()), Req0);
                false ->
                    case fh_shell_store:claim_guest_create(addr, <<"start:", Addr/binary>>,
                                                           fh_shell_guest:start_limit()) of
                        {limit, Resets} ->
                            reply(fh_shell_guest:limited(Limit, Resets), Req0);
                        {ok, _Day} ->
                            {_GuestId, Req1} = fh_shell_guest:start(Req0),
                            fh_shell_http:reply_json(200,
                                #{<<"guest">> => true, <<"new">> => true}, Req1)
                    end
            end
    end.

reply({Status, Body}, Req) -> fh_shell_http:reply_json(Status, Body, Req).

next_reset() -> fh_shell_store:next_reset().
