-module(fh_shell_mail).

%% Transactional email delivery for the shell (login flow, shell-architecture.md §3).
%% A delivery ADAPTER, not a mail server: one function the auth handler calls to send
%% a magic-link email. Two backends, chosen at call time by whether RESEND_API_KEY is
%% present in the env:
%%
%%   * RESEND_API_KEY set  -> POST https://api.resend.com/emails (the production path).
%%   * not set (local dev) -> log the link at notice level so the developer can click
%%     it without an email account. The handler can ALSO surface the link in its JSON
%%     response under AUTH_DEV_EXPOSE_LINK for a zero-inbox dev loop + the smoke test.
%%
%% Deliberately tiny: the shell never queues or retries mail here — a failed Resend
%% call is logged and the request still answers 202 (no account enumeration: the
%% caller's reply does not depend on whether delivery succeeded). HTTP via inets httpc
%% + ssl (both started by the shell app).

-export([send_magic_link/2]).

-define(RESEND_ENDPOINT, "https://api.resend.com/emails").

%% Deliver the magic-link email to Email. Returns ok regardless of backend outcome —
%% delivery is best-effort and must not leak whether an address exists.
-spec send_magic_link(binary(), binary()) -> ok.
send_magic_link(Email, Url) ->
    case os:getenv("RESEND_API_KEY") of
        false -> log_link(Email, Url);
        ""    -> log_link(Email, Url);
        Key   -> resend_send(list_to_binary(Key), Email, Url)
    end.

%% --- dev backend ---

-spec log_link(binary(), binary()) -> ok.
log_link(Email, Url) ->
    logger:notice("[dev magic-link] ~s -> ~s", [Email, Url]),
    ok.

%% --- Resend backend ---

-spec resend_send(binary(), binary(), binary()) -> ok.
resend_send(Key, Email, Url) ->
    Body = fh_shell_util:json_encode(#{
        <<"from">>    => from_address(),
        <<"to">>      => [Email],
        <<"subject">> => <<"Sign in to Rau / Đăng nhập Rau"/utf8>>,
        <<"html">>    => html_body(Url),
        <<"text">>    => text_body(Url)
    }),
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Key)}],
    Request = {?RESEND_ENDPOINT, Headers, "application/json", Body},
    case httpc:request(post, Request, [], [{body_format, binary}]) of
        {ok, {{_, Status, _}, _, _Resp}} when Status >= 200, Status < 300 ->
            logger:info("Resend accepted magic-link email for ~s (~B)", [Email, Status]),
            ok;
        {ok, {{_, Status, _}, _, Resp}} ->
            logger:warning("Resend rejected magic-link email for ~s (~B): ~s",
                           [Email, Status, Resp]),
            ok;
        {error, Reason} ->
            logger:warning("Resend transport error for ~s: ~p", [Email, Reason]),
            ok
    end.

%% Sender, from EMAIL_FROM (+ optional EMAIL_FROM_NAME) — the aleap/atp convention,
%% so one .env serves every platform. EMAIL_FROM is the verified address (e.g.
%% login@mail.firsthomey.com); EMAIL_FROM_NAME, when set, composes "Name <addr>".
%% A dev default keeps the call well-formed; Resend rejects an unverified domain,
%% which is logged, not fatal.
-spec from_address() -> binary().
from_address() ->
    case os:getenv("EMAIL_FROM") of
        false -> <<"Rau <onboarding@resend.dev>">>;
        ""    -> <<"Rau <onboarding@resend.dev>">>;
        Addr  -> with_name(list_to_binary(Addr))
    end.

-spec with_name(binary()) -> binary().
with_name(Addr) ->
    case os:getenv("EMAIL_FROM_NAME") of
        false -> Addr;
        ""    -> Addr;
        Name  -> <<(list_to_binary(Name))/binary, " <", Addr/binary, ">">>
    end.

%% Bilingual (VI-first, bilingual-content.md): the product is VI-first, so the email
%% leads in Vietnamese with the English line beneath.
-spec html_body(binary()) -> binary().
html_body(Url) ->
    <<"<p>Nhấp vào liên kết bên dưới để đăng nhập vào Rau "
      "(liên kết hết hạn sau 15 phút):</p>"
      "<p><a href=\""/utf8, Url/binary,
      "\">Đăng nhập / Sign in</a></p>"
      "<p style=\"color:#666;font-size:13px\">Click the link above to sign in to "
      "Rau. The link expires in 15 minutes. If you did not request this, "
      "you can ignore this email.</p>"/utf8>>.

-spec text_body(binary()) -> binary().
text_body(Url) ->
    <<"Đăng nhập vào Rau / Sign in to Rau:\n"/utf8, Url/binary,
      "\n\nLiên kết hết hạn sau 15 phút. / The link expires in 15 minutes."/utf8>>.
