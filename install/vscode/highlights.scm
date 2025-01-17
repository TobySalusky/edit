(ERROR) @error
(comment) @comment

(ident) @variable
; (ident) @parameter
; ((ident) @variable (#is-not? local))

(import_like_statement (ident) @module)

(parameter_declaration name: (ident) @parameter)
(function_declaration name: (ident) @function)

(member_access
  name: (ident) @variable.member)
(ptr_member_access
  name: (ident) @variable.member)

(invocation
 (member_access
  name: (ident) @method))
(invocation
 (ptr_member_access
  name: (ident) @method))
(invocation
 (static_access
  name: (ident) @method))

(invocation
 (global_ident_expr
  name: (ident) @method))

(invocation
 (ident) @method)


;(array_type) @type

(struct_declaration name: (ident) @type)
(choice_declaration name: (ident) @type)
(enum_declaration name: (ident) @type)
(interface_declaration name: (ident) @type)
(extend_declaration name: (ident) @type)

(struct_body
  (block
	 (var_declaration
	  name: (ident) @field)))

(object_initializer_label
 name: (ident) @field)

[
 "construct"
 "destruct"
] @keyword ; @function.builtin

[
 "struct"
 "interface"
 "choice"
 "enum"
 "extend"
 "match"
 "switch"
 "if"
 "else"
 "or"
 "is"
 "as"
 "for"
 "while"
 "instantiate"
 "let"
 "let!"
 "export"
 "import"
 "c:import"
 "open"
 "mut"
 "template"
 "type"
 "break"
 "with"
 "in"
 "defer"
 "sizeof"
 "static"
] @keyword

[
 "operator:^"
 "operator:unary*"
 "operator:!"
 "operator:unary-"
 "operator:unary+"
 "operator:#"
 "operator:()"
 "operator:[]"
 "operator:*"
 "operator:/"
 "operator:%"
 "operator:+"
 "operator:-"
 "operator:<="
 "operator:<"
 "operator:>="
 "operator:>"
 "operator:=="
 "operator:!="
 "operator:~&"
 "operator:~^"
 "operator:~|"
 "operator:&&"
 "operator:||"
] @function

[
 "this"
] @variable.builtin

[
 "return"
] @keyword.return

(type_ident) @type
(pointer_type) @type
(reference_type) @type
;(mutable_type) @type
(builtin_type) @type.builtin
(template_type name: (type_ident) @type)

(number) @number
(string) @string
; (interpolated_string) @string ---- (some clients will highlight with outter colour [VSCode {or rather, VSCode TS wrapper?}]), so we don't want that!
[
 "\""
 "f\""
 "t\""
 "$\""
] @string
(non_escape_interpolated_string_frag) @string
; ----------------------------------
(escape_sequence) @string.escape
(char) @character

[
 (true)
 (false)
] @boolean

[
 ","
 ":"
 ";"
 "#"
] @punctuation.delimiter

; TODO: highlight < & > diff. as operator vs in template_type
[
 "("
 ")"
 "{"
 "${"
 "}"
 "<"
 ">"
 "</" ; html
 "/>" ; html
 "["
 "]"
] @punctuation.bracket

[
 ; "_"

 "."
 "+"
 "-"
 "*"
 "/"
 "%"

 "++"
 "--"
 ".."
 ; "<<"
 ; ">>"
 ; ">>>"
 "^"
 "&"

 "+="
 "-="
 "*="
 "/="
 "%="

 "=="
 "!="
 "<="
 ">="
 "<"
 ">"

 "&&"
 "||"

 "~&"
 "~|"
 "~^"

 "!"
 "~"

 "="

 "->"

 ; "..."
] @operator


[
 "?"
 "|"
] @keyword.conditional.ternary

(debug_question "?" @punctuation.special)

; html
(html_statement opening_tag: (ident) @tag)
(html_statement closing_tag: (ident) @tag)
(html_attribute name: (html_attribute_ident) @tag.attribute)
(html_statement "<" @tag.delimiter)
(html_statement ">" @tag.delimiter)
(html_statement "/>" @tag.delimiter)
(html_statement "</" @tag.delimiter)

(doctype_html_statement "<" @tag.delimiter)
(doctype_html_statement "!" @tag.delimiter)
(doctype_html_statement "DOCTYPE" @constant)
(doctype_html_statement doc_type: (ident) @constant)
(doctype_html_statement ">" @tag.delimiter)

; @string.special.symbol  symbols or atoms
; @string.special.path    filenames
; @string.special.url     URIs (e.g. hyperlinks)

((ident) @_name @function.builtin (#eq? @_name "assert"))
((ident) @_name @function.builtin (#eq? @_name "panic"))

(html_attribute
  name: (html_attribute_ident) @_name
  value: (string) @string.special.url
  (#offset! @string.special.url 0 1 0 -1)
  (#eq? @_name "href"))

; (html_attribute
;   name: (html_attribute_ident) @_name
;   value: (interpolated_string) @string.special.url
;   (#offset! @string.special.url 0 1 0 -1)
;   (#eq? @_name "href"))

(html_attribute
  name: (html_attribute_ident) @_name
  value: (string) @string.special.url
  (#offset! @string.special.url 0 1 0 -1)
  (#eq? @_name "src"))

; (html_attribute
;   name: (html_attribute_ident) @_name
;   value: (interpolated_string) @string.special.url
;   (#offset! @string.special.url 0 1 0 -1)
;   (#eq? @_name "src"))

(c_text_statement "c:c:`" @string)
(c_text_statement "c:`" @string)
(c_text_statement "`" @string)

; @keyword                keywords not fitting into specific categories
; @keyword.coroutine      keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
; @keyword.function       keywords that define a function (e.g. `func` in Go, `def` in Python)
; @keyword.operator       operators that are English words (e.g. `and`, `or`)
; @keyword.import         keywords for including modules (e.g. `import`, `from` in Python)
; @keyword.type           keywords defining composite types (e.g. `struct`, `enum`)
; @keyword.modifier       keywords defining type modifiers (e.g. `const`, `static`, `public`)
; @keyword.repeat         keywords related to loops (e.g. `for`, `while`)
; @keyword.return         keywords like `return` and `yield`
; @keyword.debug          keywords related to debugging
; @keyword.exception      keywords related to exceptions (e.g. `throw`, `catch`)
;
; @keyword.conditional         keywords related to conditionals (e.g. `if`, `else`)
; @keyword.conditional.ternary ternary operator (e.g. `?`, `:`)

(interpolation_segment_format "%" @keyword.modifier)
(interpolation_segment_format (ident) @punctuation)
(interpolation_segment_content "=" @punctuation)

(annotation_ident) @attribute

(annotation "@" @attribute)
(annotation "[" @attribute)
(annotation (ident) @attribute)
(annotation "]" @attribute)

