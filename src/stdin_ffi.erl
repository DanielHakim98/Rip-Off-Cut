-module(stdin_ffi).
-export([io_get_line/0]).

io_get_line() ->
    do_io_get_line(<<>>).


do_io_get_line(Line) ->
    case io:get_chars(standard_io, "", 1) of
        eof -> Line;
        {error, _} -> <<>>;
        Char ->
            case is_newline(Char) of
                true-> Line;
                false -> do_io_get_line(<<Line/binary, Char/binary>>)
            end
    end.

is_newline(<<10>>) -> true;
is_newline(_) -> false.