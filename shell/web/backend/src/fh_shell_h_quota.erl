-module(fh_shell_h_quota).

%% Honest-partial -> P-5 · Metering, not gating -> The shell backend -> GET /api/me/quota
%% What the visitor can still use for free, for the menu (behavior 62). One shape for
%% both kinds, so the menu shows the same three rows to everyone (Son 2026-10-11):
%%   plans_saved   the plans the visitor holds now (plan_card_views, as the list shows);
%%   plans_limit   how many they may hold (behavior 111: 7 signed out, 28 signed in;
%%                 fh_shell_guest:held_limit/1) — the menu reads "N / limit";
%%   plans_today   new plans today: {used, limit} signed out, from guest_daily_creates
%%                 for this guest and this address against GUEST_DAILY_CREATES (the
%%                 higher count governs, as guest_create/4 claims both); "unlimited"
%%                 signed in (no daily cap: the held cap, plans_limit, bounds them);
%%   keep_days     fh_shell_guest:ttl() in days signed out (the purge's age);
%%                 "until_deleted" signed in;
%%   questions_today  "sign_in" signed out (guests are refused the assistant); signed in
%%                 {used, limit} from qa_daily_asks against FH_QA_DAILY_LIMIT;
%%   allowance     signed in only: this period's token allowance as a used fraction and
%%                 its reset date (fh_shell_meter:usage_summary/1) — the menu names it
%%                 only from 80% (Son 2026-10-11: a hidden ceiling, warned near it).
%% An admin reads "unlimited" for questions and allowance, as the gates exempt them.
%% The counts are the rows the gates claim, never a second count.
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
    Saved = case GuestId of
        none -> 0;
        _    -> fh_shell_store:plans_saved(GuestId)
    end,
    fh_shell_http:reply_json(200, #{
        <<"kind">> => <<"guest">>,
        <<"plans_saved">> => Saved,
        <<"plans_limit">> => fh_shell_guest:held_limit(guest),
        <<"plans_today">> => #{<<"used">> => min(Used, Limit), <<"limit">> => Limit},
        <<"keep_days">> => fh_shell_guest:ttl() div 86400,
        <<"questions_today">> => <<"sign_in">>
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
        <<"plans_saved">> => fh_shell_store:plans_saved(UserId),
        <<"plans_limit">> => fh_shell_guest:held_limit(user),
        <<"plans_today">> => <<"unlimited">>,
        <<"keep_days">> => <<"until_deleted">>,
        <<"questions_today">> => Questions,
        <<"allowance">> => Allowance
    }, Req).
