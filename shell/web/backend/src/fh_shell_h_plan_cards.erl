-module(fh_shell_h_plan_cards).

%% The plan-card COLLECTION (/api/plan-cards). GET lists the signed-in user's cards
%% (the shell's views — so a returning user reaches a card to project/chat, 8-S4);
%% POST creates one (the onboarding seam, 8-S3). The single-card resource (read /
%% messages, by :id) is fh_shell_h_plan_card.
%%
%% POST /api/plan-cards — the onboarding seam (8-S3, shell-architecture.md §5/§7).
%% Authenticate the USER (HS256 user JWT), forward the onboarding payload to the
%% engine's POST /api/engine/plan-cards with a freshly minted tenant JWT scoped to
%% that user (fh_shell_engine_client), and on the engine's 202 record the shell's
%% VIEW of the new plan card (plan_card_views). The engine OWNS onboarding-field
%% validation (one source of truth, §1) — the shell is a proxy + identity/view
%% layer, not a re-validator: a non-202 engine reply relays through verbatim.
%%
%% Plan-first (constraint #1): the body carries mode-derived inputs (state, target
%% price range, target zone, intent), NEVER a property. Mode A is the engine's
%% default blueprint for Wedge 1a.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">>  -> handle_get(Req0, State);
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

%% GET /api/plan-cards — the signed-in user's own cards (the shell's views). Pure
%% shell-DB read, no engine call: the list is display handles (id + title + created);
%% the projection for any one card is fetched per card by fh_shell_h_plan_card.
handle_get(Req0, State) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            Views = fh_shell_store:list_plan_card_views(UserId),
            {ok, fh_shell_http:reply_json(200, #{<<"plan_cards">> => Views}, Req0), State};
        {error, Status, ErrBody} ->
            {ok, fh_shell_http:reply_json(Status, ErrBody, Req0), State}
    end.

%% Signed out, the create still runs (behavior 45): the body is read first (so a
%% malformed request makes no guest), then the guest path below makes this browser a
%% guest (fh_shell_guest:start/1) and creates the plan under it. A signed-in user's
%% create is not capped.
handle_post(Req0, State) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            case fh_shell_http:authenticate_user(Req1) of
                {ok, #{<<"user_id">> := UserId} = Claims} ->
                    case fh_shell_guest:is_guest(Claims) of
                        false -> reply_create(create(UserId, Body), Req1, State);
                        true -> guest_create(UserId, Body, Req1, State)
                    end;
                {error, 401, _} ->
                    guest_create(new, Body, Req1, State)
            end;
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> the cap runs before a guest is made
%% A guest's create is capped per guest and per client address each Sydney day
%% (fh_shell_store:claim_guest_create/3). The address is claimed first, so an address
%% over its cap makes no new guest row; a claim the engine then refuses is given back.
guest_create(Who, Body, Req0, State) ->
    Limit = fh_shell_guest:daily_limit(),
    Addr = fh_shell_guest:client_addr(Req0),
    logger:info("[guest] create from addr=~s xff=~p",
                [Addr, cowboy_req:header(<<"x-forwarded-for">>, Req0, undefined)]),
    case fh_shell_store:claim_guest_create(addr, Addr, Limit) of
        {limit, Resets} ->
            {ok, limited(Limit, Resets, Req0), State};
        {ok, AddrDay} ->
            {GuestId, Req1} = case Who of
                new -> fh_shell_guest:start(Req0);
                Id -> {Id, Req0}
            end,
            case fh_shell_store:claim_guest_create(guest, GuestId, Limit) of
                {limit, Resets} ->
                    ok = fh_shell_store:release_guest_create(addr, Addr, AddrDay),
                    {ok, limited(Limit, Resets, Req1), State};
                {ok, GuestDay} ->
                    case create(GuestId, Body) of
                        {202, _} = Created ->
                            reply_create(Created, Req1, State);
                        Refused ->
                            ok = fh_shell_store:release_guest_create(guest, GuestId, GuestDay),
                            ok = fh_shell_store:release_guest_create(addr, Addr, AddrDay),
                            reply_create(Refused, Req1, State)
                    end
            end
    end.

limited(Limit, Resets, Req) ->
    fh_shell_http:reply_json(429, #{<<"error">> => <<"guest_daily_limit">>,
                                    <<"limit">> => Limit,
                                    <<"resets_at">> => Resets}, Req).

%% Forward to the engine; on its 202 record the shell's view. Returns the engine's
%% status and decoded body.
create(UserId, Body) ->
    {EngineStatus, EngineResp} = fh_shell_engine_client:create_plan_card(UserId, Body),
    Decoded = fh_shell_util:json_decode(EngineResp),
    case EngineStatus of
        202 ->
            #{<<"plan_card_id">> := PlanCardId} = Decoded,
            %% Record the shell's view AFTER the engine has committed the card, so a
            %% view never dangles without its engine counterpart. Idempotent on
            %% (user_id, engine_plan_card_id).
            ok = fh_shell_store:insert_plan_card_view(UserId, PlanCardId, title_of(Body)),
            {202, Decoded};
        _ ->
            {EngineStatus, Decoded}
    end.

%% A non-202 engine reply relays verbatim (it owns the onboarding contract).
reply_create({Status, Decoded}, Req, State) ->
    {ok, fh_shell_http:reply_json(Status, Decoded, Req), State}.

%% A best-effort display title for the shell's plan-card view. The plan pins to a
%% zone (map-first, §7), so the first target-zone label is the natural title; fall
%% back to the state, then a generic label. Display only — never load-bearing.
-spec title_of(map()) -> binary().
title_of(Body) ->
    case maps:get(<<"target_zone">>, Body, []) of
        [Zone | _] when is_binary(Zone) -> Zone;
        _ ->
            case maps:get(<<"state">>, Body, undefined) of
                S when is_binary(S) -> S;
                _ -> <<"Plan">>
            end
    end.
