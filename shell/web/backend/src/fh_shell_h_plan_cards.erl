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

%% GET /api/plan-cards — the signed-in user's own cards (the shell's views): display
%% handles (id + title + created), and since behavior 84 each card's state and last
%% update from the engine, for the planner's saved-plans list (one engine read for the
%% whole list; if it fails the handles go out alone, every engine field null). Behavior
%% 96: the list's cards also show what each plan is for and its cost figures (behavior
%% 98) — intent, mode, costs_buy, costs_own_per_year, passed through from the engine as
%% they come.
%% The projection for any one card is fetched per card by fh_shell_h_plan_card.
handle_get(Req0, State) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            Views = with_summaries(UserId, fh_shell_store:list_plan_card_views(UserId)),
            {ok, fh_shell_http:reply_json(200, #{<<"plan_cards">> => Views}, Req0), State};
        {error, Status, ErrBody} ->
            {ok, fh_shell_http:reply_json(Status, ErrBody, Req0), State}
    end.

with_summaries(UserId, Views) ->
    Ids = [Id || #{<<"plan_card_id">> := Id} <- Views],
    Sums = case fh_shell_engine_client:plan_card_summaries(UserId, Ids) of
               {ok, M} -> M;
               {error, Why} ->
                   logger:warning("[plan-cards] list without engine summaries: ~p", [Why]),
                   #{}
           end,
    Fields = [<<"state">>, <<"updated_at">>, <<"intent">>, <<"mode">>, <<"costs_buy">>,
              <<"costs_own_per_year">>],
    [maps:merge(V, maps:from_list([{F, maps:get(F, maps:get(Id, Sums, #{}), null)}
                                   || F <- Fields]))
     || #{<<"plan_card_id">> := Id} = V <- Views].

%% Signed out, the create still runs (behavior 45): the body is read first (so a
%% malformed request makes no guest), then the guest path below creates the plan under
%% this browser's guest. Since behavior 97 the onboarding dialog makes the guest first
%% (POST /api/auth/guest, fh_shell_h_guest), so a create normally arrives with a
%% session; a create with none (a client that did not start a guest) still makes one
%% here. A signed-in user's create has no daily cap; since behavior 111 every create is
%% held to the plans the visitor may hold (slot/3).
handle_post(Req0, State) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            case create_key(Req1) of
                invalid ->
                    {ok, fh_shell_http:reply_json(400,
                        #{<<"error">> => <<"invalid_create_key">>}, Req1), State};
                Key ->
                    case fh_shell_http:authenticate_user(Req1) of
                        {ok, #{<<"user_id">> := UserId} = Claims} ->
                            case fh_shell_guest:is_guest(Claims) of
                                false ->
                                    reply_create(once(UserId, Key, fun() ->
                                        slot(UserId, user, fun() -> create(UserId, Body, Key) end)
                                    end), Req1, State);
                                true -> guest_create(UserId, Body, Key, Req1, State)
                            end;
                        {error, 401, _} ->
                            guest_create(new, Body, Key, Req1, State)
                    end
            end;
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> a tap makes one plan, whatever the phone does
%% Behavior 97 (Son 2026-10-16: a plan lost when the phone locked mid-create). The
%% dialog sends a create key (header create-key) with each tap and sends the same key
%% again when the reply was lost: the phone locked after the POST left, the tab was
%% reloaded, the user tapped twice. once/3 runs the create under that key for that owner
%% (fh_shell_store:with_create_key/3): a key the owner already used returns the plan
%% it made — 202 with that plan_card_id and `repeat: true`, no engine call, no second
%% guest claim. No key (an older client): no check, as before behavior 97. A key with
%% no owner (a create that makes its guest) cannot repeat: the next try carries that
%% guest's cookie only if the reply reached the browser — which is why the dialog
%% makes its guest before the create.
once(_Owner, undefined, Fun) -> Fun();
once(Owner, Key, Fun) ->
    fh_shell_store:with_create_key(Owner, Key, fun() ->
        case fh_shell_store:plan_card_by_create_key(Owner, Key) of
            {ok, PlanCardId} ->
                logger:info("[plan-cards] repeat of create ~s by ~s -> ~s",
                            [Key, Owner, PlanCardId]),
                {202, #{<<"plan_card_id">> => PlanCardId, <<"repeat">> => true}};
            none -> Fun()
        end
    end).

%% The create key: absent -> undefined; 8-64 of [A-Za-z0-9_-] (the dialog sends a
%% UUID) -> the key; anything else -> invalid (400, nothing made).
create_key(Req) ->
    case cowboy_req:header(<<"create-key">>, Req, undefined) of
        undefined -> undefined;
        K when byte_size(K) >= 8, byte_size(K) =< 64 ->
            case re:run(K, <<"^[A-Za-z0-9_-]+$">>, [{capture, none}]) of
                match -> K;
                nomatch -> invalid
            end;
        _ -> invalid
    end.

%% Honest-partial -> P-5 · Metering, not gating -> The shell backend -> the cap runs before a guest is made
%% An existing guest's create is first held to the plans it may hold (slot/3,
%% fh_shell_guest:held_limit/1, behavior 111): at 7 it is 409 plans_full before any
%% daily claim, so a refused create spends none of the day's cap.
%% A guest's create is capped per guest and per client address each Sydney day
%% (fh_shell_store:claim_guest_create/3). The address is claimed first, so an address
%% over its cap makes no new guest row; a claim the engine then refuses is given back.
%% A guest made before the create (fh_shell_h_guest, behavior 97) is held to the same
%% rule there: it is refused while the address is at its create cap, and an address may
%% start only so many guests a day, so a guest made early opens no way past the
%% per-address cap — the create still claims the address here.
guest_create(new, Body, Key, Req0, State) ->
    {Limit, Addr} = guest_cap(Req0),
    case fh_shell_store:claim_guest_create(addr, Addr, Limit) of
        {limit, Resets} ->
            reply_create(fh_shell_guest:limited(Limit, Resets), Req0, State);
        {ok, AddrDay} ->
            {GuestId, Req1} = fh_shell_guest:start(Req0),
            reply_create(claimed_create(GuestId, Addr, AddrDay, Limit, Body, Key), Req1, State)
    end;
guest_create(GuestId, Body, Key, Req0, State) ->
    {Limit, Addr} = guest_cap(Req0),
    reply_create(once(GuestId, Key, fun() ->
        slot(GuestId, guest, fun() ->
            case fh_shell_store:claim_guest_create(addr, Addr, Limit) of
                {limit, Resets} -> fh_shell_guest:limited(Limit, Resets);
                {ok, AddrDay} -> claimed_create(GuestId, Addr, AddrDay, Limit, Body, Key)
            end
        end)
    end), Req0, State).

%% Behavior 111: a create runs only while the owner holds fewer plans than their cap
%% (fh_shell_guest's "the plans a visitor holds" block); at the cap it is 409 plans_full
%% and nothing is claimed or made. A new guest holds none, so its first create is not
%% checked.
slot(Owner, Kind, Fun) ->
    case fh_shell_store:with_plan_slot(Owner, fh_shell_guest:held_limit(Kind), Fun) of
        {full, Held} -> fh_shell_guest:full(Kind, Held);
        Reply -> Reply
    end.

guest_cap(Req) ->
    Addr = fh_shell_guest:client_addr(Req),
    logger:info("[guest] create from addr=~s xff=~p",
                [Addr, cowboy_req:header(<<"x-forwarded-for">>, Req, undefined)]),
    {fh_shell_guest:daily_limit(), Addr}.

%% The address is claimed; claim the guest, then create. Either refusal gives back
%% what was claimed.
claimed_create(GuestId, Addr, AddrDay, Limit, Body, Key) ->
    case fh_shell_store:claim_guest_create(guest, GuestId, Limit) of
        {limit, Resets} ->
            ok = fh_shell_store:release_guest_create(addr, Addr, AddrDay),
            fh_shell_guest:limited(Limit, Resets);
        {ok, GuestDay} ->
            case create(GuestId, Body, Key) of
                {202, _} = Created -> Created;
                Refused ->
                    ok = fh_shell_store:release_guest_create(guest, GuestId, GuestDay),
                    ok = fh_shell_store:release_guest_create(addr, Addr, AddrDay),
                    Refused
            end
    end.

%% Forward to the engine; on its 202 record the shell's view, with the tap's create
%% key. Returns the engine's status and decoded body.
create(UserId, Body, Key) ->
    {EngineStatus, EngineResp} = fh_shell_engine_client:create_plan_card(UserId, Body),
    Decoded = fh_shell_util:json_decode(EngineResp),
    case EngineStatus of
        202 ->
            #{<<"plan_card_id">> := PlanCardId} = Decoded,
            %% Record the shell's view AFTER the engine has committed the card, so a
            %% view never dangles without its engine counterpart. Idempotent on
            %% (user_id, engine_plan_card_id).
            ok = fh_shell_store:insert_plan_card_view(UserId, PlanCardId, title_of(Body), Key),
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
