-module(fh_engine_h_attach_document).

%% POST /api/engine/plan-cards/:id/properties/:pid/documents — upload a due-diligence DOCUMENT
%% (the current lease) for an ALREADY-ATTACHED property and run a DOCUMENT-GATED two-path re-fill
%% that activates due_diligence's lease_interpretation leaf (due_diligence B; the `<from_document>`
%% input surface — the heaviest of the three per-property input layers, distinct from the
%% source-supplied property_card and the user-attested `<from_transaction>` dates).
%%
%% Body: {content_base64, mime_type?, filename?} — the inline lease (PDF or text). The bytes are
%% TRANSIENT: handed to the disposable sidecar on this one turn, extracted to text deterministically
%% (no LLM, no figure), and NEVER persisted (architecture §11.9 — only the resulting outcome is
%% snapshotted). The property must already be attached (else 409 — there is no addendum slot to
%% write into). No preview primitive. Returns {plan_card_id, property_id, turn_id}; the re-fill
%% streams component_filled{fill_path: two_path} + usage + turn_completed via the existing
%% .../events SSE (the lease_interpretation leaf is a metered LLM call, unlike the free transaction
%% submit). The engine METERS; the shell GATES on commerce (engine-contract §4).

-export([init/2]).

%% A base64 cap (~20 MB encoded ≈ 15 MB file): a lease is a few pages; this is an abuse backstop,
%% not a real-document limit. read_all/2 (fh_engine_http) accumulates the full chunked body.
-define(MAX_B64, 20 * 1024 * 1024).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T, user_id := U}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            PropertyId = cowboy_req:binding(pid, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} ->
                    read_and_submit(T, U, PlanCardId, PropertyId, Card, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_submit(T, U, PlanCardId, PropertyId, Card, Req0, State) ->
    Content = maps:get(<<"content">>, Card, #{}),
    Addenda = maps:get(<<"addenda">>, Content, #{}),
    case maps:find(PropertyId, Addenda) of
        error ->
            %% no addendum slot to write into — the property must be attached first.
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"property_not_attached">>,
                  <<"detail">> => <<"attach the property before uploading its documents">>},
                Req0), State};
        {ok, Addendum} ->
            case fh_engine_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    submit(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Body, Req1, State);
                {error, invalid_json} ->
                    {ok, fh_engine_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), State}
            end
    end.

submit(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Body, Req, State) ->
    case validate_document(Body) of
        {error, Code} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_document">>,
                  <<"code">> => Code}, Req), State};
        {ok, Document} ->
            start_refill(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Document,
                         Req, State)
    end.

start_refill(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Document, Req, State) ->
    TurnId = fh_engine_util:uuid4(),
    case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
        {error, in_flight} ->
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"turn_in_flight">>,
                  <<"detail">> => <<"a turn is already running for this card">>}, Req), State};
        ok ->
            Mode = maps:get(<<"mode">>, Card, <<"C">>),
            {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                tenant_id => T,
                user_id => U,
                plan_card_id => PlanCardId,
                turn_id => TurnId,
                blueprint_slug => maps:get(<<"blueprint_slug">>, Card),
                mode => Mode,
                intent => maps:get(<<"intent">>, Card, <<"investment">>),
                firb_required_any => false,
                kind => document,
                property_id => PropertyId,
                %% the inline lease rides Args → start_fill_port → the sidecar (transient bytes).
                document => Document,
                %% due_diligence reads base outcomes (profile, strategy_thesis) + the addendum's
                %% per-property outcomes (property_fit_investor) as upstream; the turn re-keys both
                %% by outcome_type at init.
                base_components_snapshot => maps:get(<<"components">>, Content, #{}),
                addendum_components_snapshot => maps:get(<<"components">>, Addendum, #{})
            }),
            Body = #{<<"plan_card_id">> => PlanCardId,
                     <<"property_id">> => PropertyId,
                     <<"turn_id">> => TurnId},
            {ok, fh_engine_http:reply_json(202, Body, Req), State}
    end.

%% content_base64 present, non-empty, within the cap; mime_type/filename optional (the sidecar
%% sniffs PDF-vs-text by mime, extension, AND the %PDF- magic). Returns the normalized document
%% map (binary keys — the shape start_fill_port + the sidecar expect).
validate_document(Body) when is_map(Body) ->
    case maps:get(<<"content_base64">>, Body, undefined) of
        B64 when is_binary(B64), byte_size(B64) > 0 ->
            case byte_size(B64) =< ?MAX_B64 of
                true ->
                    {ok, #{<<"content_base64">> => B64,
                           <<"mime_type">> => bin_or_null(maps:get(<<"mime_type">>, Body, null)),
                           <<"filename">>  => bin_or_null(maps:get(<<"filename">>, Body, null))}};
                false ->
                    {error, <<"document_too_large">>}
            end;
        _ ->
            {error, <<"content_base64_required">>}
    end;
validate_document(_) ->
    {error, <<"body_must_be_object">>}.

bin_or_null(B) when is_binary(B) -> B;
bin_or_null(_)                   -> null.
