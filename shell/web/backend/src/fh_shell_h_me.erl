-module(fh_shell_h_me).

%% GET /api/me — the current session, read straight from the validated user JWT
%% (fh_shell_http:authenticate_user/1, which accepts the fh_session cookie or a
%% Bearer header). No DB hit: the JWT carries email/roles/locale by design
%% (fh_shell_jwt), so the SPA can learn who it is and which language to show in one
%% cheap call. 401 (with the calm body) when there is no valid session — the SPA
%% renders the signed-out state, not an error.

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
            fh_shell_http:reply_json(200, #{
                <<"user_id">> => maps:get(<<"user_id">>, Claims),
                <<"email">>   => maps:get(<<"email">>, Claims),
                <<"roles">>   => maps:get(<<"roles">>, Claims, []),
                <<"locale">>  => maps:get(<<"locale">>, Claims, <<"vi">>),
                %% Behavior 45: a guest session (a plan built signed out) is not a
                %% sign-in — the SPA shows the signed-out header and the guest notice.
                <<"guest">>   => fh_shell_guest:is_guest(Claims)
            }, Req);
        {error, Status, Body} ->
            fh_shell_http:reply_json(Status, Body, Req)
    end.
