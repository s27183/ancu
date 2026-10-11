-module(fh_shell_h_quota).

%% Visitor quota -> P-5 · Metering, not gating -> The shell backend -> GET /api/me/quota
%% What the visitor can still use for free, for the menu (behavior 62). It reads the
%% counters the gates themselves claim, never a second count:
%%   signed out (no session, or a guest session): new plans left today, from
%%     guest_daily_creates for this guest and this address against GUEST_DAILY_CREATES
%%     (the lower of the two governs, as guest_create/4 claims both); plans kept
%%     fh_shell_guest:ttl() seconds; the assistant needs sign-in.
%%   signed in: questions left today, from qa_daily_asks against FH_QA_DAILY_LIMIT; this
%%     period's token allowance as a used fraction and its reset date
%%     (fh_shell_meter:usage_summary/1). An admin reads `unlimited` for both, as the
%%     gates exempt them.
%% Tokens stay internal: the reply carries a fraction, never a token count or a cost.
%% Read-only and never 401: a visitor with no session is a guest-to-be.

-export([init/2]).

init(Req, State) ->
    case cowboy_req:method(Req) of
        <<"GET">> -> {ok, handle(Req), State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req), State}
    end.

handle(Req) ->
    case fh_shell_http:authenticate_user(Req) of
        {ok, Claims} ->
            case fh_shell_guest:is_guest(Claims) of
                true  -> guest(maps:get(<<"user_id">>, Claims), Req);
                false -> user(maps:get(<<"user_id">>, Claims), Req)
            end;
        {error, _Status, _Body} ->
            guest(none, Req)
    end.

guest(GuestId, Req) ->
    Limit = fh_shell_guest:daily_limit(),
    ByAddr = fh_shell_store:guest_creates_today(addr, fh_shell_guest:client_addr(Req)),
    ByGuest = case GuestId of
        none -> 0;
        _    -> fh_shell_store:guest_creates_today(guest, GuestId)
    end,
    Used = max(ByAddr, ByGuest),
    fh_shell_http:reply_json(200, #{
        <<"kind">> => <<"guest">>,
        <<"plans_today">> => #{<<"used">> => min(Used, Limit), <<"limit">> => Limit},
        <<"keep_days">> => fh_shell_guest:ttl() div 86400
    }, Req).

user(UserId, Req) ->
    #{used_tokens := UsedT, limit_tokens := LimitT, period_end := Reset} =
        fh_shell_meter:usage_summary(UserId),
    {Questions, Allowance} = case LimitT of
        unlimited ->
            {<<"unlimited">>, <<"unlimited">>};
        N when is_integer(N), N > 0 ->
            QLimit = fh_shell_meter:daily_question_limit(),
            QUsed = min(fh_shell_store:questions_today(UserId), QLimit),
            {#{<<"used">> => QUsed, <<"limit">> => QLimit},
             #{<<"used_fraction">> => min(1.0, UsedT / N), <<"resets_at">> => Reset}}
    end,
    fh_shell_http:reply_json(200, #{
        <<"kind">> => <<"user">>,
        <<"questions_today">> => Questions,
        <<"allowance">> => Allowance
    }, Req).
