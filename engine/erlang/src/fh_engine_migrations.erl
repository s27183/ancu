-module(fh_engine_migrations).

%% Boot-time, forward-only migration runner for the engine's runtime-state DB.
%%
%% Borrowed from ATP mcp_db: split_sql_statements/1 — a context-aware SQL splitter
%% (respects '...' / "..." / $tag$...$tag$ / -- and /* */), which is what lets us
%% apply a multi-statement file over pgo's EXTENDED query protocol (pgo:query takes
%% one statement at a time; you cannot send a whole semicolon-delimited script).
%%
%% Reshaped for FirstHomey (the migrations README convention + the "verifiable
%% properties" principle), deliberately stronger than ATP's runner:
%%   * Version tracking — a schema_migrations row per applied file; pending files
%%     are detected by version, not by re-running everything and swallowing
%%     duplicate-object errors. (ATP re-runs all files each boot and ignores
%%     42P07/42710; that conflates "already applied" with "DDL error".)
%%   * Per-file transaction — each file's statements + its schema_migrations row
%%     commit atomically via pgo:transaction, or roll back together. Files carry NO
%%     in-file BEGIN/COMMIT (the runner owns the transaction).
%%   * Checksum guard — an already-applied file whose bytes changed aborts boot
%%     (forward-only: you add a new migration, you never edit an applied one).
%%   * Fail-closed — any error raises, so application start aborts rather than
%%     serving on a half-migrated schema.

-export([run/0]).

-spec run() -> ok.  %% or raises -> boot aborts
run() ->
    ensure_schema_migrations(),
    Applied = applied_versions(),
    Files = migration_files(),
    lists:foreach(fun(Path) -> consider(Path, Applied) end, Files),
    ok.

%% --- planning ---

-spec migration_files() -> [file:filename()].
migration_files() ->
    Dir = filename:join(code:priv_dir(fh_engine), "migrations"),
    case file:list_dir(Dir) of
        {ok, Files} ->
            Sql = [F || F <- Files, filename:extension(F) =:= ".sql"],
            [filename:join(Dir, F) || F <- lists:sort(Sql)];
        {error, Reason} ->
            error({migrations_dir_unreadable, Dir, Reason})
    end.

-spec consider(file:filename(), #{binary() => binary()}) -> ok.
consider(Path, Applied) ->
    Filename = list_to_binary(filename:basename(Path)),
    Version = version_of(Filename),
    {ok, Bin} = file:read_file(Path),
    Checksum = checksum(Bin),
    case maps:find(Version, Applied) of
        {ok, Checksum} ->
            logger:info("Migration ~s already applied", [Filename]);
        {ok, Other} ->
            %% Forward-only violation: an applied migration's content changed.
            error({migration_checksum_mismatch, Filename,
                   #{applied => Other, current => Checksum}});
        error ->
            apply_file(Filename, Version, Checksum, Bin)
    end.

-spec apply_file(binary(), binary(), binary(), binary()) -> ok.
apply_file(Filename, Version, Checksum, Bin) ->
    Statements = split_sql_statements(Bin),
    Result = pgo:transaction(fun() ->
        lists:foreach(fun exec/1, Statements),
        record(Version, Filename, Checksum),
        ok
    end),
    case Result of
        ok ->
            logger:info("Migration applied: ~s (~B statements)",
                        [Filename, length(Statements)]);
        Other ->
            error({migration_failed, Filename, Other})
    end.

-spec exec(binary()) -> ok.
exec(SQL) ->
    case pgo:query(SQL, []) of
        #{command := _} -> ok;
        #{rows := _}    -> ok;
        {error, Err}    -> error({statement_failed, Err})
    end.

%% --- schema_migrations bookkeeping ---

-spec ensure_schema_migrations() -> ok.
ensure_schema_migrations() ->
    exec(<<"CREATE TABLE IF NOT EXISTS schema_migrations ("
           "  version    text PRIMARY KEY,"
           "  filename   text NOT NULL,"
           "  checksum   text NOT NULL,"
           "  applied_at timestamptz NOT NULL DEFAULT now())">>).

-spec applied_versions() -> #{binary() => binary()}.
applied_versions() ->
    case pgo:query(<<"SELECT version, checksum FROM schema_migrations">>, []) of
        #{rows := Rows} ->
            maps:from_list([{V, C} || {V, C} <- Rows]);
        {error, Err} ->
            error({schema_migrations_unreadable, Err})
    end.

-spec record(binary(), binary(), binary()) -> ok.
record(Version, Filename, Checksum) ->
    case pgo:query(<<"INSERT INTO schema_migrations (version, filename, checksum) "
                     "VALUES ($1, $2, $3)">>, [Version, Filename, Checksum]) of
        #{command := insert} -> ok;
        #{command := _}      -> ok;
        {error, Err}         -> error({record_migration_failed, Filename, Err})
    end.

-spec version_of(binary()) -> binary().
version_of(Filename) ->
    case binary:split(Filename, <<"_">>) of
        [Version, _Rest] -> Version;
        [Whole]          -> Whole   %% no underscore — use the whole name
    end.

%% Reproducible -> P-2 · The database is the single source of truth -> The engine database -> uppercase migration checksum
%% binary:encode_hex/1 is UPPERCASE, so a hand-applied schema_migrations row must use this
%% function, not `shasum` (lowercase), or boot aborts with migration_checksum_mismatch.
%% Measured 2026-08: a hand-applied lowercase row aborted boot; re-measured 2026-10-06
%% (OTP 29): `erl -noshell -eval 'io:format("~s~n",[binary:encode_hex(<<171,205>>)]),halt().'` -> ABCD.
-spec checksum(binary()) -> binary().
checksum(Bin) ->
    binary:encode_hex(crypto:hash(sha256, Bin)).

%% =====================================================================
%% SQL statement splitter — borrowed verbatim from ATP mcp_db.
%% Splits a script into statements, respecting single-quoted strings (with ''
%% escape), dollar-quoted strings ($tag$...$tag$), line comments (-- to EOL) and
%% block comments (/* ... */). Only a top-level `;` ends a statement.
%% =====================================================================

-spec split_sql_statements(binary()) -> [binary()].
split_sql_statements(Bin) ->
    split_sql(Bin, 0, byte_size(Bin), 0, normal, []).

split_sql(Bin, Start, End, Pos, normal, Acc) when Pos >= End ->
    finish_statements(Bin, Start, Pos, Acc);
split_sql(Bin, Start, End, Pos, _State, Acc) when Pos >= End ->
    %% Unterminated construct — emit remainder as-is, let the server error clearly.
    finish_statements(Bin, Start, Pos, Acc);
split_sql(Bin, Start, End, Pos, normal, Acc) ->
    case binary:at(Bin, Pos) of
        $; ->
            Stmt = binary:part(Bin, Start, Pos - Start),
            case string:trim(Stmt) of
                <<>> -> split_sql(Bin, Pos + 1, End, Pos + 1, normal, Acc);
                Trimmed -> split_sql(Bin, Pos + 1, End, Pos + 1, normal, [Trimmed | Acc])
            end;
        $' -> split_sql(Bin, Start, End, Pos + 1, squote, Acc);
        $" -> split_sql(Bin, Start, End, Pos + 1, dquote, Acc);
        $- ->
            case peek(Bin, Pos + 1, End) of
                $- -> split_sql(Bin, Start, End, Pos + 2, line_comment, Acc);
                _  -> split_sql(Bin, Start, End, Pos + 1, normal, Acc)
            end;
        $/ ->
            case peek(Bin, Pos + 1, End) of
                $* -> split_sql(Bin, Start, End, Pos + 2, block_comment, Acc);
                _  -> split_sql(Bin, Start, End, Pos + 1, normal, Acc)
            end;
        $$ ->
            case read_dollar_tag(Bin, Pos, End) of
                {ok, Tag, NextPos} ->
                    split_sql(Bin, Start, End, NextPos, {dollar, Tag}, Acc);
                none ->
                    split_sql(Bin, Start, End, Pos + 1, normal, Acc)
            end;
        _ -> split_sql(Bin, Start, End, Pos + 1, normal, Acc)
    end;
split_sql(Bin, Start, End, Pos, squote, Acc) ->
    case binary:at(Bin, Pos) of
        $' ->
            case peek(Bin, Pos + 1, End) of
                $' -> split_sql(Bin, Start, End, Pos + 2, squote, Acc);  %% escaped ''
                _  -> split_sql(Bin, Start, End, Pos + 1, normal, Acc)
            end;
        _ -> split_sql(Bin, Start, End, Pos + 1, squote, Acc)
    end;
split_sql(Bin, Start, End, Pos, dquote, Acc) ->
    case binary:at(Bin, Pos) of
        $" ->
            case peek(Bin, Pos + 1, End) of
                $" -> split_sql(Bin, Start, End, Pos + 2, dquote, Acc);
                _  -> split_sql(Bin, Start, End, Pos + 1, normal, Acc)
            end;
        _ -> split_sql(Bin, Start, End, Pos + 1, dquote, Acc)
    end;
split_sql(Bin, Start, End, Pos, {dollar, Tag}, Acc) ->
    TagLen = byte_size(Tag),
    case Pos + TagLen =< End andalso binary:part(Bin, Pos, TagLen) =:= Tag of
        true  -> split_sql(Bin, Start, End, Pos + TagLen, normal, Acc);
        false -> split_sql(Bin, Start, End, Pos + 1, {dollar, Tag}, Acc)
    end;
split_sql(Bin, Start, End, Pos, line_comment, Acc) ->
    case binary:at(Bin, Pos) of
        $\n -> split_sql(Bin, Start, End, Pos + 1, normal, Acc);
        _   -> split_sql(Bin, Start, End, Pos + 1, line_comment, Acc)
    end;
split_sql(Bin, Start, End, Pos, block_comment, Acc) ->
    case binary:at(Bin, Pos) of
        $* ->
            case peek(Bin, Pos + 1, End) of
                $/ -> split_sql(Bin, Start, End, Pos + 2, normal, Acc);
                _  -> split_sql(Bin, Start, End, Pos + 1, block_comment, Acc)
            end;
        _ -> split_sql(Bin, Start, End, Pos + 1, block_comment, Acc)
    end.

finish_statements(Bin, Start, Pos, Acc) ->
    Tail = string:trim(binary:part(Bin, Start, Pos - Start)),
    Final = case Tail of
        <<>> -> Acc;
        T -> [T | Acc]
    end,
    lists:reverse(Final).

peek(_Bin, Pos, End) when Pos >= End -> -1;
peek(Bin, Pos, _End) -> binary:at(Bin, Pos).

%% Dollar-quoted literal opener: $tag$ where tag matches [A-Za-z_][A-Za-z0-9_]*
%% or is empty ($$). Returns {ok, <<"$tag$">>, NextPos} or none.
read_dollar_tag(Bin, Pos, End) ->
    case scan_tag(Bin, Pos + 1, End) of
        {ok, TagEnd} when TagEnd < End ->
            case binary:at(Bin, TagEnd) of
                $$ -> {ok, binary:part(Bin, Pos, TagEnd - Pos + 1), TagEnd + 1};
                _  -> none
            end;
        _ -> none
    end.

scan_tag(_Bin, Pos, End) when Pos >= End -> {ok, Pos};
scan_tag(Bin, Pos, End) ->
    C = binary:at(Bin, Pos),
    IsStart = Pos > 0 andalso binary:at(Bin, Pos - 1) =:= $$,
    Valid =
        (C >= $A andalso C =< $Z) orelse
        (C >= $a andalso C =< $z) orelse
        C =:= $_ orelse
        ((not IsStart) andalso (C >= $0 andalso C =< $9)),
    case Valid of
        true  -> scan_tag(Bin, Pos + 1, End);
        false -> {ok, Pos}
    end.
