-module(fh_shell_h_saved_suburbs).

%% Whole lifecycle -> P-2 -> The shell backend -> the saved-suburbs API (behavior 84)
%% GET    /api/saved-suburbs         the signed-in user's saved suburbs, newest first
%% PUT    /api/saved-suburbs/:sal    save one ({"name", "state"}: its map label)
%% DELETE /api/saved-suburbs/:sal    unsave it
%% A guest (or no session) gets 401 sign_in_required: saving is for a signed-in user.
%%
%% The first GET for a user seeds the table from their older plans, which were each
%% titled by a suburb (made from the map before behavior 81): each title that names
%% exactly one suburb in the engine's national list is saved; a title that names none
%% is skipped and logged, never guessed. The seed runs once (users.saved_seeded_at);
%% if the engine cannot answer, it is not marked and runs on the next GET.

-export([init/2]).
-export([seed_rows/2]).  % pure, for the test

-define(STATES, [<<"NSW">>, <<"VIC">>, <<"QLD">>, <<"WA">>,
                 <<"SA">>, <<"TAS">>, <<"ACT">>, <<"NT">>]).

init(Req0, State) ->
    case signed_in(Req0) of
        {ok, UserId} ->
            Method = cowboy_req:method(Req0),
            Sal = cowboy_req:binding(sal, Req0),
            {ok, handle(Method, Sal, UserId, Req0), State};
        {error, Status, Body} ->
            {ok, fh_shell_http:reply_json(Status, Body, Req0), State}
    end.

signed_in(Req) ->
    case fh_shell_http:authenticate_user(Req) of
        {ok, #{<<"user_id">> := UserId} = Claims} ->
            case fh_shell_guest:is_guest(Claims) of
                false -> {ok, UserId};
                true -> {error, 401, #{<<"error">> => <<"sign_in_required">>}}
            end;
        {error, 401, _} ->
            {error, 401, #{<<"error">> => <<"sign_in_required">>}};
        {error, Status, Body} ->
            {error, Status, Body}
    end.

handle(<<"GET">>, undefined, UserId, Req) ->
    seed(UserId),
    list(UserId, Req);
handle(<<"PUT">>, Sal, UserId, Req0) when is_binary(Sal) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, #{<<"name">> := Name, <<"state">> := St}, Req1} ->
            case valid(Sal, Name, St) of
                true ->
                    ok = fh_shell_store:save_suburb(UserId, Sal, Name, St),
                    list(UserId, Req1);
                false ->
                    fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_suburb">>}, Req1)
            end;
        {ok, _, Req1} ->
            fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_suburb">>}, Req1);
        {error, invalid_json} ->
            fh_shell_http:reply_json(400, #{<<"error">> => <<"invalid_json">>}, Req0)
    end;
handle(<<"DELETE">>, Sal, UserId, Req) when is_binary(Sal) ->
    ok = fh_shell_store:unsave_suburb(UserId, Sal),
    list(UserId, Req);
handle(_, _, _, Req) ->
    fh_shell_http:reply_json(405, #{<<"error">> => <<"method_not_allowed">>}, Req).

list(UserId, Req) ->
    fh_shell_http:reply_json(200,
        #{<<"saved_suburbs">> => fh_shell_store:list_saved_suburbs(UserId)}, Req).

%% The label is the client's; the key's shape and the state are checked here, and the
%% table's CHECKs hold the same line.
valid(Sal, Name, St) ->
    is_binary(Name) andalso byte_size(Name) >= 1 andalso byte_size(Name) =< 120
        andalso lists:member(St, ?STATES)
        andalso re:run(Sal, <<"^SAL[0-9]{5}$">>, [{capture, none}]) =:= match.

seed(UserId) ->
    case fh_shell_store:saved_seeded(UserId) of
        true -> ok;
        false ->
            Titles = lists:usort([T || #{<<"title">> := T}
                                       <- fh_shell_store:list_plan_card_views(UserId),
                                   not lists:member(T, ?STATES)]),
            case suburbs_for(Titles) of
                {ok, Suburbs} ->
                    {Rows, Skipped} = seed_rows(Titles, Suburbs),
                    New = fh_shell_store:seed_saved_suburbs(UserId, Rows),
                    logger:info("[saved-suburbs] seeded user ~s: ~B new from ~B plan titles; "
                                "skipped ~p", [UserId, New, length(Titles), Skipped]);
                {error, Why} ->
                    logger:warning("[saved-suburbs] seed for ~s deferred: ~p", [UserId, Why])
            end
    end.

%% No suburb-titled plan: nothing to ask the engine.
suburbs_for([]) -> {ok, []};
suburbs_for(_) ->
    case fh_shell_engine_client:list_suburbs(<<"ALL">>) of
        {200, Body} ->
            #{<<"suburbs">> := Suburbs} = fh_shell_util:json_decode(Body),
            {ok, Suburbs};
        {Status, _} ->
            {error, {engine_suburbs, Status}}
    end.

%% Each title that names exactly one suburb → {Sal, Name, State}; the rest are skipped.
-spec seed_rows([binary()], [map()]) -> {[{binary(), binary(), binary()}], [binary()]}.
seed_rows(Titles, Suburbs) ->
    lists:foldr(
        fun(T, {Rows, Skipped}) ->
            case [S || #{<<"name">> := N} = S <- Suburbs, N =:= T] of
                [#{<<"sal_code">> := Sal, <<"state">> := St}] -> {[{Sal, T, St} | Rows], Skipped};
                _ -> {Rows, [T | Skipped]}
            end
        end, {[], []}, Titles).
