-module(fh_shell_h_plan_card).

%% The single plan-card RESOURCE (/api/plan-cards/:id and .../messages, 8-S4) — the
%% projection's data source (GET) + the bilingual Q&A path (POST messages). One
%% handler, action per route opt ([] = read, [messages] = ask), mirroring
%% fh_shell_h_auth. The frontend never talks to the engine directly (§1): this mints
%% the tenant JWT and relays the engine's status + body verbatim, the same proxy
%% posture as fh_shell_h_suburbs — the engine owns the plan-card contract.
%%
%% AUTHORIZATION — the new posture this slice introduces. Unlike the public suburbs
%% proxy or the create seam (no pre-existing row), these touch an EXISTING card, so
%% the acting user must OWN it. Every action runs one gate — authenticate the user
%% JWT, then confirm the (user, card) binding in the shell DB (plan_card_views) —
%% BEFORE minting a tenant JWT. The engine independently scopes by the tenant the JWT
%% names but treats user_id as opaque, so the user→card mapping lives only shell-side
%% (§9.3, no cross-DB join). A malformed / unknown / unowned id is a uniform 404: we
%% never disclose whether a card exists across the ownership boundary.

-export([init/2]).

init(Req0, Opts) ->
    case {Opts, cowboy_req:method(Req0)} of
        {[], <<"GET">>}          -> with_owned_card(Req0, Opts, fun read/4);
        {[messages], <<"POST">>} -> with_owned_card(Req0, Opts, fun ask/4);
        {[simulate], <<"POST">>} -> with_owned_card(Req0, Opts, fun simulate/4);
        {[refine], <<"POST">>}   -> with_owned_card(Req0, Opts, fun refine/4);
        {[profile], <<"POST">>}  -> with_owned_card(Req0, Opts, fun profile/4);
        {[properties], <<"POST">>}  -> with_owned_card(Req0, Opts, fun properties/4);
        {[transaction], <<"POST">>} -> with_owned_card(Req0, Opts, fun transaction/4);
        {[documents], <<"POST">>}   -> with_owned_card(Req0, Opts, fun documents/4);
        {[checklist_status], <<"PATCH">>} ->
            with_owned_card(Req0, Opts, fun checklist_status/4);
        {[news], <<"GET">>}   -> with_owned_card(Req0, Opts, fun news/4);
        {[news], <<"PATCH">>} -> with_owned_card(Req0, Opts, fun dismiss_news/4);
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), Opts}
    end.

%% The shared gate: authenticate → validate the :id shape → confirm ownership, then
%% hand (UserId, PlanCardId, Req, Opts) to the action. is_uuid guards the $N::uuid
%% bind so a garbage id is a calm 404, not a pgo crash.
with_owned_card(Req0, Opts, Action) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case is_binary(PlanCardId)
                andalso fh_shell_util:is_uuid(PlanCardId)
                andalso fh_shell_store:owns_plan_card(UserId, PlanCardId)
            of
                true ->
                    Action(UserId, PlanCardId, Req0, Opts);
                false ->
                    {ok, fh_shell_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), Opts}
            end;
        {error, Status, ErrBody} ->
            {ok, fh_shell_http:reply_json(Status, ErrBody, Req0), Opts}
    end.

%% GET /api/plan-cards/:id — fetch the filled plan-card content (the projection's
%% typed outcomes). Relayed verbatim from the engine.
read(UserId, PlanCardId, Req0, Opts) ->
    {Status, Body} = fh_shell_engine_client:get_plan_card(UserId, PlanCardId),
    {ok, relay(Status, Body, Req0), Opts}.

%% POST /api/plan-cards/:id/messages — ask a question (the kind:qa turn). The engine
%% owns the message contract (non-empty, in-flight serialization); a bad body relays
%% through. The bilingual answer arrives later as text_delta frames on the SSE stream
%% (proxied in 8-S4b), not in this reply — the engine answers 202 here.
%%
%% The §7 pre-call token-limit GATE runs FIRST (8-S5d, billing.md §7): a Q&A turn is
%% always an agent turn, so a user already over their tier's period token limit is
%% blocked with a 402 BEFORE any tenant JWT is minted or the engine is touched —
%% metering-not-gating, the engine would happily run it; the shell decides. (The
%% base-plan create turn is the free offering and is deliberately NOT gated; only
%% this chat/refresh surface is — billing.md §5 "capped chat/refresh".)
ask(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_meter:gate(UserId) of
        allow ->
            case fh_shell_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    {Status, Resp} =
                        fh_shell_engine_client:post_message(UserId, PlanCardId, Body),
                    {ok, relay(Status, Resp, Req1), Opts};
                {error, invalid_json} ->
                    {ok, fh_shell_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
            end;
        {block, #{tier := Tier, used := Used, limit := Limit}} ->
            {ok, fh_shell_http:reply_json(402,
                #{<<"error">> => <<"quota_exceeded">>,
                  <<"tier">> => Tier,
                  <<"used_tokens">> => Used,
                  <<"limit_tokens">> => Limit}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/simulate — preview a structural what-if (W9) → the engine
%% recomputes the base plan resolver-only and returns the outcomes in the body. NO meter
%% gate (unlike `ask`): a simulate is resolver-only and emits zero usage — it is free
%% decision-support, the same posture as the base-plan create (billing.md §5). Just
%% authenticate → own → relay; the engine validates the overrides (400 on a rejected one).
simulate(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:simulate(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/refine — SAVE a previewed structural what-if (W8) as the
%% card's current scenario → the engine persists the overrides + runs a base_resolver turn
%% that advances the snapshot, answering 202; the recomputed components stream over /events.
%% NO meter gate (like simulate, unlike `ask`): a refine is resolver-only and emits zero
%% usage — the saved scenario re-runs deterministic fills and re-attaches the stored agent
%% leaves, not re-billed (billing.md §5; metering-not-gating). The engine validates the
%% overrides (400) and serializes turns (409); both relay through.
refine(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:refine(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/profile — write the household financial facts (income/debts)
%% to the engine's profiles SOT (IC4) → the engine validates (400), full-replaces the
%% canonical household_financials key, and re-derives every card on the profile; the
%% recomputed capacity streams over each card's /events. NO meter gate (like simulate/
%% refine, unlike `ask`): the recompute is resolver-only and emits zero usage. The engine
%% owns the financials contract — relay verbatim.
profile(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:set_profile_financials(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% PATCH /api/plan-cards/:id/checklist-status — toggle one phase action's status in the
%% card user-set layer (task 7). USER-ATTESTED state, NOT a computed figure: a small jsonb
%% patch with no recompute and no `usage`, so — like simulate/refine, unlike `ask` — it
%% carries NO meter gate (zero-cost attestation; the engine would run it regardless, the
%% shell does not gate it). Just authenticate → own → relay; the engine validates the
%% closed enums (phase, status) and returns the authoritative checklist_status map (400 on
%% a bad field). The acting client renders that map, not its optimistic guess.
checklist_status(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:set_checklist_status(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% GET /api/plan-cards/:id/news — the KB news notes relevant to the card, minus its own
%% dismissed set (kb-news-feature.md). Zero-cost read (no usage, no turn); the engine
%% computes relevance over kb_versions provenance already stamped on the card's fills.
%% Just authenticate → own → relay.
news(UserId, PlanCardId, Req0, Opts) ->
    {Status, Body} = fh_shell_engine_client:get_news(UserId, PlanCardId),
    {ok, relay(Status, Body, Req0), Opts}.

%% PATCH /api/plan-cards/:id/news — dismiss one news note (the card's dismissed_news
%% user-set layer, migration 007). USER-ATTESTED, NOT a computed figure: no recompute,
%% no usage — like checklist-status, NO meter gate. The engine returns the AUTHORITATIVE
%% dismissed_news map (400 on a missing news_slug); relay verbatim.
dismiss_news(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:dismiss_news(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/properties — attach a normalized property_card → the engine
%% writes the addendum and runs the Phase-B per-property turn (engine-contract §12). Unlike
%% simulate/refine/transaction this is an AGENT turn (property_assessment's two-path fill
%% invokes the LLM → emits usage), so — like `ask` — it runs the §7 token-limit GATE FIRST:
%% a user over their tier's period limit is blocked 402 BEFORE any tenant JWT is minted
%% (metering-not-gating; the engine would run it, the shell decides). The engine owns the
%% property_card contract (400 invalid_property_card / 400 phase_b_not_supported_for_blueprint
%% / 409 turn_in_flight); relay verbatim. 202 {plan_card_id, property_id, turn_id}; the
%% per-property components stream over /events.
properties(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_meter:gate(UserId) of
        allow ->
            case fh_shell_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    {Status, Resp} =
                        fh_shell_engine_client:attach_property(UserId, PlanCardId, Body),
                    {ok, relay(Status, Resp, Req1), Opts};
                {error, invalid_json} ->
                    {ok, fh_shell_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
            end;
        {block, #{tier := Tier, used := Used, limit := Limit}} ->
            {ok, fh_shell_http:reply_json(402,
                #{<<"error">> => <<"quota_exceeded">>,
                  <<"tier">> => Tier,
                  <<"used_tokens">> => Used,
                  <<"limit_tokens">> => Limit}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/properties/:pid/transaction — submit the user-attested
%% contract_signed_date + settlement_date for an already-attached property → a RESOLVER-ONLY
%% re-fill that activates settlement_prep's dated path (engine-contract §11). Resolver-only ⇒
%% NO usage ⇒ NO meter gate (like simulate/refine/checklist, unlike `ask`/properties). The
%% :pid is a sub-resource of the already-owned card (with_owned_card confirmed the card); the
%% engine re-validates the addendum exists (409 property_not_attached) and the dates (400 with
%% a typed `code`). Relay verbatim — the engine owns the transaction contract. 202
%% {plan_card_id, property_id, turn_id}; the recomputed settlement_checklist streams over /events.
transaction(UserId, PlanCardId, Req0, Opts) ->
    PropertyId = cowboy_req:binding(pid, Req0),
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} =
                fh_shell_engine_client:set_transaction_dates(
                    UserId, PlanCardId, PropertyId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% POST /api/plan-cards/:id/properties/:pid/documents — upload a due-diligence document (the
%% current lease) for an already-attached property → a DOCUMENT-GATED two-path re-fill that
%% activates due_diligence's lease_interpretation leaf (due_diligence B, the `<from_document>`
%% surface). UNLIKE transaction (resolver-only, free) this fires the LLM leaf → emits usage, so —
%% like `ask`/properties — it runs the §7 token-limit GATE FIRST: a user over their tier's period
%% limit is blocked 402 BEFORE any tenant JWT is minted (metering-not-gating). The :pid is a
%% sub-resource of the already-owned card; the engine re-validates the addendum exists (409
%% property_not_attached) and the document (400 invalid_document with a typed `code`). The bytes
%% are transient (never persisted, engine-side). Relay verbatim. 202 {plan_card_id, property_id,
%% turn_id}; the reviewed risk_assessment_investor streams over /events.
documents(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_meter:gate(UserId) of
        allow ->
            PropertyId = cowboy_req:binding(pid, Req0),
            case fh_shell_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    {Status, Resp} =
                        fh_shell_engine_client:upload_document(
                            UserId, PlanCardId, PropertyId, Body),
                    {ok, relay(Status, Resp, Req1), Opts};
                {error, invalid_json} ->
                    {ok, fh_shell_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
            end;
        {block, #{tier := Tier, used := Used, limit := Limit}} ->
            {ok, fh_shell_http:reply_json(402,
                #{<<"error">> => <<"quota_exceeded">>,
                  <<"tier">> => Tier,
                  <<"used_tokens">> => Used,
                  <<"limit_tokens">> => Limit}, Req0), Opts}
    end.

%% Relay the engine's already-encoded JSON body + status verbatim (same as the
%% suburbs proxy) — the engine is the source of truth for the plan-card contract, so
%% the shell does not re-decode/re-encode and cannot drift from it.
relay(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>}, Body, Req).
