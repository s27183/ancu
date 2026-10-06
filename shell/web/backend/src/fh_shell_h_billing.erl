-module(fh_shell_h_billing).

%% Commerce HTTP surface (billing.md §9). One handler, action per route opt — the same
%% shape as fh_shell_h_auth. The browser never talks to Stripe through us beyond starting
%% checkout; Stripe calls the webhook server-to-server.
%%
%%   webhook   POST /api/billing/webhook   (8-S5e-2) Stripe-signed event → tier state
%%   subscribe POST /api/billing/subscribe (8-S5e-3) authed user → Stripe Checkout URL
%%   charge    POST /api/billing/charge    (8-S5f)   authed user → one-time add-on URL
%%   usage     GET  /api/billing/usage     (8-S5g)   authed user → this-period tokens/cost
%%
%% AUTH posture differs per action and is deliberate:
%%   * webhook is NOT user-authenticated — Stripe has no shell session. It is authenticated
%%     by the HMAC signature over the RAW body (fh_shell_billing:verify_signature), so the
%%     body must be read UNPARSED here (re-encoding would change the bytes and break the
%%     signature). That is why this does not reuse fh_shell_http:read_json_body.
%%   * subscribe IS user-authenticated (the user JWT) — it acts on the caller's account.

-export([init/2]).

init(Req0, [Action] = State) ->
    {ok, dispatch(Action, Req0), State}.

dispatch(webhook, Req)   -> post_only(Req, fun webhook/1);
dispatch(subscribe, Req) -> post_only(Req, fun subscribe/1);
dispatch(charge, Req)    -> post_only(Req, fun charge/1);
dispatch(usage, Req)     -> get_only(Req, fun usage/1);
dispatch(_, Req)         -> fh_shell_http:reply_json(404, #{<<"error">> => <<"not_found">>}, Req).

post_only(Req, Fun) ->
    case cowboy_req:method(Req) of
        <<"POST">> -> Fun(Req);
        _ -> fh_shell_http:reply_json(405, #{<<"error">> => <<"method_not_allowed">>}, Req)
    end.

get_only(Req, Fun) ->
    case cowboy_req:method(Req) of
        <<"GET">> -> Fun(Req);
        _ -> fh_shell_http:reply_json(405, #{<<"error">> => <<"method_not_allowed">>}, Req)
    end.

%% POST /api/billing/webhook — a Stripe-signed subscription-lifecycle event. Read the
%% raw bytes + the stripe-signature header and hand both to fh_shell_billing, which
%% verifies and routes. The reply is whatever it returns (200 ack on a valid signature,
%% 400 on a bad/absent one); see handle_webhook/2 for why we ack even an unparsable body.
webhook(Req0) ->
    {ok, RawBody, Req1} = read_raw_body(Req0, <<>>),
    Sig = cowboy_req:header(<<"stripe-signature">>, Req1, undefined),
    {Status, Body} = fh_shell_billing:handle_webhook(RawBody, Sig),
    fh_shell_http:reply_json(Status, Body, Req1).

%% POST /api/billing/subscribe — the authenticated user starts a Stripe Checkout for a
%% tier. Returns {url} for the SPA to redirect to. Only plus/pro are subscribable (free
%% is the default, no checkout). A config gap (missing key/price) is 503 (the operator
%% must wire Stripe), a Stripe/transport failure is 502, an unknown tier is 400.
subscribe(Req0) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            case fh_shell_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    subscribe_tier(UserId, maps:get(<<"tier">>, Body, undefined), Req1);
                {error, invalid_json} ->
                    fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_json">>}, Req0)
            end;
        {error, Status, ErrBody} ->
            fh_shell_http:reply_json(Status, ErrBody, Req0)
    end.

subscribe_tier(UserId, Tier, Req) when Tier =:= <<"plus">>; Tier =:= <<"pro">> ->
    case fh_shell_billing:create_checkout_session(UserId, Tier) of
        {ok, Url} ->
            fh_shell_http:reply_json(200, #{<<"url">> => Url}, Req);
        {error, secret_key_not_configured} -> unavailable(Req);
        {error, price_not_configured}      -> unavailable(Req);
        {error, _Reason} ->
            fh_shell_http:reply_json(502, #{<<"error">> => <<"stripe_unavailable">>}, Req)
    end;
subscribe_tier(_UserId, _Tier, Req) ->
    fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_tier">>}, Req).

%% POST /api/billing/charge — the authenticated user starts a Stripe Checkout for a
%% one-time add-on (billing.md §9). Body {kind, plan_card_id?}. Returns {url} to redirect
%% to. Only the BUYER self-serve kinds are accepted here (doc_review, timnha); success_fee
%% is REA-paid ledger, not a buyer checkout → invalid_kind. A kind with no configured price
%% (timnha until an operator/curator sets its amount) is a config gap → 503; a config gap on
%% the secret key → 503; a Stripe/transport failure → 502; an unknown kind → 400.
charge(Req0) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            case fh_shell_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    charge_kind(UserId,
                                maps:get(<<"kind">>, Body, undefined),
                                plan_card(maps:get(<<"plan_card_id">>, Body, undefined)),
                                Req1);
                {error, invalid_json} ->
                    fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_json">>}, Req0)
            end;
        {error, Status, ErrBody} ->
            fh_shell_http:reply_json(Status, ErrBody, Req0)
    end.

charge_kind(UserId, Kind, PlanCardId, Req)
  when Kind =:= <<"doc_review">>; Kind =:= <<"timnha">> ->
    case fh_shell_billing:create_addon_checkout(UserId, Kind, PlanCardId) of
        {ok, Url} ->
            fh_shell_http:reply_json(200, #{<<"url">> => Url}, Req);
        {error, secret_key_not_configured} -> unavailable(Req);
        {error, price_not_configured}      -> unavailable(Req);
        {error, _Reason} ->
            fh_shell_http:reply_json(502, #{<<"error">> => <<"stripe_unavailable">>}, Req)
    end;
charge_kind(_UserId, _Kind, _PlanCardId, Req) ->
    fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_kind">>}, Req).

%% GET /api/billing/usage — the authenticated user's current-period usage (the
%% account page's data source, 8-S5g): tier, tokens used/limit, shadow cost, period
%% bounds. `limit_tokens` is the JSON string "unlimited" for an admin (fh_shell_meter
%% exempts them from the §7 gate entirely) rather than a numeric cap that would
%% misreport what actually governs their usage.
usage(Req0) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            #{tier := Tier, used_tokens := Used, limit_tokens := Limit,
              shadow_cost := Cost, period_start := Start, period_end := Stop} =
                fh_shell_meter:usage_summary(UserId),
            fh_shell_http:reply_json(200, #{
                <<"tier">> => Tier,
                <<"used_tokens">> => Used,
                <<"limit_tokens">> => limit_json(Limit),
                <<"shadow_cost">> => Cost,
                <<"period_start">> => Start,
                <<"period_end">> => Stop
            }, Req0);
        {error, Status, ErrBody} ->
            fh_shell_http:reply_json(Status, ErrBody, Req0)
    end.

limit_json(unlimited) -> <<"unlimited">>;
limit_json(N) -> N.

plan_card(P) when is_binary(P) -> P;
plan_card(_) -> undefined.

unavailable(Req) ->
    fh_shell_http:reply_json(503, #{<<"error">> => <<"billing_not_configured">>}, Req).

%% Read the full body unparsed (the signature is over these exact bytes).
read_raw_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1}   -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_raw_body(Req1, <<Acc/binary, Data/binary>>)
    end.
