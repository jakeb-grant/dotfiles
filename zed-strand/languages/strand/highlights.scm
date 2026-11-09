; Zed's copy of crates/strand-dev/tree-sitter-strand/queries/highlights.scm
; (Strand bd96eabf). Two differences: Zed lets a later pattern win where
; the original puts specific patterns first, so the order is reversed in
; blocks (general first); and captures take the names Zed's themes use
; (@type for @module, @variable.special for @variable.builtin).

; ---- Everything else --------------------------------------------------------

(identifier) @variable
(token) @variable.special

; ---- Operators and punctuation --------------------------------------------

[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket
[ "," ";" "." ":" ] @punctuation.delimiter

[
  "=" "+=" "-=" "*=" "/="
  "==" "!=" "<" "<=" ">" ">="
  "&&" "||" "!" "??" "?" "?."
  "+" "-" "*" "/" "%"
  "=>" "->" "<->" "~"
] @operator

(ternary_expression "?" @keyword.conditional)
(ternary_expression ":" @keyword.conditional)

; ---- Keywords ---------------------------------------------------------------

[
  "component"
  "bar"
  "panel"
  "osd"
  "window"
  "lock"
  "state"
  "let"
  "export"
  "enum"
  "type"
  "tokens"
  "extends"
  "override"
  "use"
  "palette"
  "service"
  "from"
  "dbus"
  "system"
  "session"
  "dir"
  "file"
  "listen"
  "poll"
  "permit"
  "action"
  "keyframes"
  "rw"
  "persist"
  "key"
  "when"
  "enter"
  "exit"
  "set"
  "play"
  "on"
  "change"
  "after"
  "every"
  "while"
  "ok"
  (slot)
] @keyword

"fn" @keyword.function

[
  "if"
  "else"
  "match"
] @keyword.conditional

[
  "for"
  "in"
] @keyword.repeat

"await" @keyword.coroutine

; ---- Names ------------------------------------------------------------------

(state name: (identifier) @variable)
(let name: (identifier) @variable)

(member_expression field: (field_name) @property)
(call_expression function: (identifier) @function.call)
(call_expression
  function: (member_expression field: (field_name) @function.method.call))

(element name: (identifier) @tag)
(element file: (identifier) @type)
(prop name: (identifier) @property)
(field name: (identifier) @property)
(named_argument name: (identifier) @variable.parameter)
(parameter name: (identifier) @variable.parameter)
(lambda_parameter) @variable.parameter
(lambda_parameter name: (identifier) @variable.parameter)
(event_name (identifier) @function.method)

(component name: (identifier) @type)
(surface name: (identifier) @type)
(enum name: (identifier) @type)
(variant) @constant
(type name: (identifier) @type)
(type_name (identifier) @type)
(tokens name: (identifier) @type)
(tokens extends: (identifier) @type)
(keyframes name: (identifier) @function)
(service name: (identifier) @type)
(function name: (identifier) @function)
(action name: (identifier) @function)
(action method: (identifier) @function.method)
(permit kind: (identifier) @keyword)

(selector name: (selector_name) @tag)

(attribute_name) @attribute

(token_key (token) @property)
(token_key (identifier) @property)
(token_key (integer) @property)

; ---- Literals ---------------------------------------------------------------

(string) @string
(escape_sequence) @string.escape
(number) @number
(color) @constant
(boolean) @boolean
(null) @constant

(comment) @comment
