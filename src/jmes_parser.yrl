Nonterminals
expr
id
int
child
index
slice
filter
list
itemv
dict
keyvalv
keyval
call
argv
type
.

Terminals
unquoted
quoted
raw
json
integer
'('
')'
'['
'[?'
']'
'{'
'}'
'*'
'@'
'|'
'||'
'&&'
'=='
'!='
'<'
'>'
'<='
'>='
'!'
'.'
','
':'
'&'
.

Rootsymbol expr.

Left 100 '|'.
Left 200 '||'.
Left 300 '&&'.
Left 400 '=='.
Left 400 '!='.
Left 600 '<'.
Left 600 '>'.
Left 600 '<='.
Left 600 '>='.
Unary 700 '!'.
Left 800 '.'.

expr -> id : '$1'.
expr -> '@' : node.

expr -> raw : {string, value_of('$1')}.
expr -> json : {json, value_of('$1')}.

expr -> expr '|' expr : {pipe, ['$1', '$3']}.
expr -> expr '||' expr : {'or', ['$1', '$3']}.
expr -> expr '&&' expr : {'and', ['$1', '$3']}.
expr -> expr '==' expr : {'eq', ['$1', '$3']}.
expr -> expr '!=' expr : {'neq', ['$1', '$3']}.
expr -> expr '<' expr : {'lt', ['$1', '$3']}.
expr -> expr '<=' expr : {'lte', ['$1', '$3']}.
expr -> expr '>' expr : {'gt', ['$1', '$3']}.
expr -> expr '>=' expr : {'gte', ['$1', '$3']}.
expr -> '!' expr : {'not', '$2'}.

expr -> '*' : wildcard.
expr -> expr '[' '*' ']': {wildcard, '$1'}.
expr -> expr '.' child : {child, ['$1', '$3']}.
expr -> expr '[' ']': {flatten, '$1'}.
expr -> '[' ']': flatten.
expr -> expr index: {index, ['$1', '$2']}.
expr -> index: {index, [nil, '$1']}.
expr -> expr slice : {slice, ['$1', '$2']}.
expr -> slice : {slice, [nil, '$1']}.
expr -> expr filter : {filter, ['$1', '$2']}.
expr -> filter : {filter, [nil, '$1']}.

expr -> list : '$1'.
expr -> dict : '$1'.
expr -> call : '$1'.

expr -> '(' expr ')' : '$2'.

id -> unquoted : {id, value_of('$1')}.
id -> quoted : {id, value_of('$1')}.
int -> integer : value_of('$1').

child -> id : '$1'.
child -> '*' : wildcard.
child -> list : '$1'.
child -> dict : '$1'.
child -> call : '$1'.

index -> '[' int ']' : '$2'.

slice -> '[' ':' ']' : [nil, nil, nil].
slice -> '[' ':' int ']' : [nil, '$3', nil].
slice -> '[' int ':' ']' : ['$2', nil, nil].
slice -> '[' int ':' int ']' : ['$2', '$4', nil].
slice -> '[' ':' ':' ']' : [nil, nil, nil].
slice -> '[' ':' ':' int ']' : [nil, nil, '$4'].
slice -> '[' ':' int ':' ']' : [nil, '$3', nil].
slice -> '[' ':' int ':' int ']' : [nil, '$3', '$5'].
slice -> '[' int ':' ':' ']' : ['$2', nil, nil].
slice -> '[' int ':' ':' int ']' : ['$2', nil, '$5'].
slice -> '[' int ':' int ':' ']' : ['$2', '$4', nil].
slice -> '[' int ':' int ':' int ']' : ['$2', '$4', '$6'].

filter -> '[?' expr ']' : '$2'.

list -> '[' itemv ']': {list, '$2'}.
itemv -> expr : ['$1'].
itemv -> expr ',' itemv : ['$1' | '$3'].

dict -> '{' keyvalv '}': {dict, '$2'}.
keyvalv -> keyval : ['$1'].
keyvalv -> keyval ',' keyvalv : ['$1' | '$3'].
keyval -> unquoted ':' expr: [value_of('$1'), '$3'].
keyval -> quoted ':' expr: [value_of('$1'), '$3'].

call -> unquoted '(' ')' : {call, [value_of('$1'), []]}.
call -> unquoted '(' argv ')' : {call, [value_of('$1'), '$3']}.
argv -> expr : ['$1'].
argv -> type : ['$1'].
argv -> expr ',' argv : ['$1' | '$3'].
argv -> type ',' argv : ['$1' | '$3'].
type -> '&' expr : {quote, '$2'}.

Erlang code.

value_of(Token) ->
    element(3, Token).
