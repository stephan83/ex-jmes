Definitions.

Whitespace = [\s\t\n\r]
Unquoted = [a-zA-Z_][0-9a-zA-Z_]*
Quoted = "([^"\\]*(\\.[^"\\]*)*)"
Raw = '([^'\\]*(\\.[^'\\]*)*)'
JSON = `([^`\\]*(\\.[^`\\]*)*)`
Integer = -?[0-9]+
LeftParen = \(
RightParen = \)
LeftBracket = \[
RightBracket = \]
BracketQuery = \[\?
LeftCurly = {
RightCurly = }
Wildcard = \*
At = @
Pipe = \|
Or = \|\|
And = &&
Eq = ==
Neq = !=
Lt = <
Gt = >
Lte = <=
Gte = >=
Not = !
Dot = \.
Colon = :
Comma = ,
Ampersand = &

Rules.

{Whitespace} : skip_token.
{Unquoted} : {token, {unquoted, TokenLine, list_to_binary(TokenChars)}}.
{Quoted} : handle_quoted(TokenLine,TokenChars,TokenLen).
{Raw} : {token, {raw, TokenLine, unescape_raw(TokenChars,TokenLen)}}.
{JSON} : {token, {json, TokenLine, unescape_json(TokenChars,TokenLen)}}.
{Integer} : {token, {integer, TokenLine, list_to_integer(TokenChars)}}.
{LeftParen} : {token, {'(', TokenLine, TokenChars}}.
{RightParen} : {token, {')', TokenLine, TokenChars}}.
{LeftBracket} : {token, {'[', TokenLine, TokenChars}}.
{RightBracket} : {token, {']', TokenLine, TokenChars}}.
{BracketQuery} : {token, {'[?', TokenLine, TokenChars}}.
{LeftCurly} : {token, {'{', TokenLine, TokenChars}}.
{RightCurly} : {token, {'}', TokenLine, TokenChars}}.
{Wildcard} : {token, {'*', TokenLine, TokenChars}}.
{At} : {token, {'@', TokenLine, TokenChars}}.
{Pipe} : {token, {'|', TokenLine, TokenChars}}.
{Or} : {token, {'||', TokenLine, TokenChars}}.
{And} : {token, {'&&', TokenLine, TokenChars}}.
{Eq} : {token, {'==', TokenLine, TokenChars}}.
{Neq} : {token, {'!=', TokenLine, TokenChars}}.
{Lt} : {token, {'<', TokenLine, TokenChars}}.
{Gt} : {token, {'>', TokenLine, TokenChars}}.
{Lte} : {token, {'<=', TokenLine, TokenChars}}.
{Gte} : {token, {'>=', TokenLine, TokenChars}}.
{Not} : {token, {'!', TokenLine, TokenChars}}.
{Dot} : {token, {'.', TokenLine, TokenChars}}.
{Colon} : {token, {':', TokenLine, TokenChars}}.
{Comma} : {token, {',', TokenLine, TokenChars}}.
{Ampersand} : {token, {'&', TokenLine, TokenChars}}.

Erlang code.

handle_quoted(TokenLine,TokenChars,TokenLen) ->
    try
        {token, {quoted, TokenLine, unescape_quoted(TokenChars,TokenLen)}}
    catch
        throw:Message -> {error, Message}
    end.

unescape_quoted(TokenChars,TokenLen) ->
    unescape(unicode:characters_to_binary(strip(TokenChars,TokenLen))).

unescape_raw(TokenChars,TokenLen) ->
    unescape_squote(unicode:characters_to_binary(strip(TokenChars,TokenLen))).

unescape_json(TokenChars,TokenLen) ->
    unescape_bquote(unicode:characters_to_binary(strip(TokenChars,TokenLen))).

strip(TokenChars,TokenLen) ->
    lists:sublist(TokenChars,2,TokenLen-2).

unescape(<<$\\,$\",T/binary>>) ->
    U = unescape(T),
    <<$\",U/binary>>;
unescape(<<$\\,$\\,T/binary>>) ->
    U = unescape(T),
    <<$\\,U/binary>>;
unescape(<<$\\,$\/,T/binary>>) ->
    U = unescape(T),
    <<$\/,U/binary>>;
unescape(<<$\\,$b,T/binary>>) ->
    U = unescape(T),
    <<$\b,U/binary>>;
unescape(<<$\\,$f,T/binary>>) ->
    U = unescape(T),
    <<$\f,U/binary>>;
unescape(<<$\\,$n,T/binary>>) ->
    U = unescape(T),
    <<$\n,U/binary>>;
unescape(<<$\\,$r,T/binary>>) ->
    U = unescape(T),
    <<$\r,U/binary>>;
unescape(<<$\\,$t,T/binary>>) ->
    U = unescape(T),
    <<$\t,U/binary>>;
% Deal with utf16 surrogate pairs.
unescape(<<$\\,$u,H0,H1,H2,H3,$\\,$u,H4,H5,H6,H7,T/binary>>)
when (H0 == $d orelse H0 == $D), (H4 == $d orelse H4 == $D),
(H1 == $8 orelse H1 == $9 orelse H1 == $a orelse H1 == $b orelse H1 == $A orelse H1 == $B),
((H5 >= $c andalso H5 =< $f) orelse (H5 >= $C andalso H5 =< $F)) ->
    Hi = dehex(H3) bor (dehex(H2) bsl 4) bor (dehex(H1) bsl 8) bor (dehex(H0) bsl 12),
    Lo = dehex(H7) bor (dehex(H6) bsl 4) bor (dehex(H5) bsl 8) bor (dehex(H4) bsl 12),
    C = 16#10000 + ((Hi band 16#03ff) bsl 10) + (Lo band 16#03ff),
    H = utf16(unicode:characters_to_binary([C], utf16, unicode)),
    U = unescape(T),
    <<H/binary,U/binary>>;
unescape(<<$\\,$u,H0,H1,H2,H3,T/binary>>) ->
    C = dehex(H3) bor (dehex(H2) bsl 4) bor (dehex(H1) bsl 8) bor (dehex(H0) bsl 12),
    H = utf16(unicode:characters_to_binary([C], utf16, unicode)),
    U = unescape(T),
    <<H/binary,U/binary>>;
unescape(<<H/utf8,T/binary>>) ->
    U = unescape(T),
    <<H/utf8,U/binary>>;
unescape(<<>>) -> <<>>.

unescape_squote(<<$\\,$',T/binary>>) ->
    U = unescape_squote(T),
    <<$',U/binary>>;
unescape_squote(<<H/utf8,T/binary>>) ->
    U = unescape_squote(T),
    <<H/utf8,U/binary>>;
unescape_squote(<<>>) -> <<>>.

unescape_bquote(<<$\\,$`,T/binary>>) ->
    U = unescape_bquote(T),
    <<$`,U/binary>>;
unescape_bquote(<<H/utf8,T/binary>>) ->
    U = unescape_bquote(T),
    <<H/utf8,U/binary>>;
unescape_bquote(<<>>) -> <<>>.

dehex(C) when C >= $0, C =< $9 -> C - $0;
dehex(C) when C >= $a, C =< $f -> C - $a + 10;
dehex(C) when C >= $A, C =< $F -> C - $A + 10;
dehex(_C) -> throw("invalid escape sequence").

utf16(S) when is_binary(S) -> S;
% Deal with invalid utf16 characters.
utf16(_S) -> unicode:characters_to_binary([65533], utf16, unicode).
