-module(fh_engine_i18n).

%% Bilingual content for engine outputs (bilingual-content.md). A user-facing FREE-TEXT
%% field is a {vi, en} pair — Vietnamese is first-class, NOT a translation of the English
%% (trap #4). Figures/enums/bools stay single-valued; the shell localizes labels + formats
%% numbers (bilingual-content.md §1, §8).
%%
%% `loc/2` is the convention constructor. `subst/2` (2g-4) does {param} substitution into a
%% bilingual template pair using binary replacement — NEVER io:format ~s, which crashes on
%% any >255 codepoint (Vietnamese is saturated with them: ầ ư ọ ễ …). That UTF-8 trap is
%% exactly why the resolver's Vietnamese copy lives in KB templates read as binaries, not in
%% Erlang literals (bilingual-content.md §3b).
%%
%% Bilingual -> R-4 · Reasoning within its runtime -> The engine -> utf8 binary literal flag
%% Any non-ASCII Erlang binary literal needs `/utf8`, or it truncates each codepoint to a
%% byte and crashes json:encode ({invalid_byte,…}) as well as io:format ~s. Measured 2026-06:
%% it broke fh_shell_mail sign-in and an fh_shell_billing label. Re-checked 2026-10-06 with
%% `rg -n '<<"[^"]*[^\x00-\x7F][^"]*"(>>|,)' engine/erlang/src shell/web/backend/src`: none.

-export([loc/2, subst/2]).

-export_type([localized/0, param/0]).

-type localized() :: #{binary() => binary()}.   %% #{<<"vi">> => binary(), <<"en">> => binary()}
%% A {param} value: a scalar (same in both languages — e.g. a money figure, per the
%% figure/locale boundary) OR a bilingual value (interpolated per-language — e.g. a label
%% fragment). bilingual-content.md §3b "subst/2 param kinds".
-type param() :: binary() | integer() | float() | localized().

%% loc(Vi, En) -> a {vi, en} content value. Both halves are required and authored/curated
%% for register; an English string in the vi slot is a bug the eval catches (2g-5).
-spec loc(binary(), binary()) -> localized().
loc(Vi, En) when is_binary(Vi), is_binary(En) ->
    #{<<"vi">> => Vi, <<"en">> => En}.

%% subst(Template, Params) -> a {vi, en} content value with every `{key}` replaced.
%% Binary substitution on each half independently — NEVER io:format ~s (which crashes on
%% any >255 codepoint; Vietnamese is saturated with them). A scalar param fills both halves
%% identically; a bilingual param fills each half from its matching language.
-spec subst(localized(), #{binary() => param()}) -> localized().
subst(#{<<"vi">> := Vi, <<"en">> := En}, Params) ->
    #{<<"vi">> => render(Vi, <<"vi">>, Params),
      <<"en">> => render(En, <<"en">>, Params)}.

render(Bin, Lang, Params) ->
    maps:fold(
        fun(K, V, Acc) ->
            binary:replace(Acc, <<"{", K/binary, "}">>, to_bin(V, Lang), [global])
        end, Bin, Params).

to_bin(V, _Lang) when is_binary(V)  -> V;
to_bin(V, _Lang) when is_integer(V) -> integer_to_binary(V);
to_bin(V, _Lang) when is_float(V)   -> float_to_binary(V, [short]);
to_bin(#{<<"vi">> := Vi, <<"en">> := En}, Lang) ->
    case Lang of <<"vi">> -> Vi; _ -> En end.
