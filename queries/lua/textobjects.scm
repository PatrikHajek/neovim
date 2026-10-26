; [[ Standard ]]

; Loops

(for_statement
  clause: _ @loop.inner)

; Parameters

(table_constructor
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(table_constructor
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

(variable_list
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(variable_list
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

(expression_list
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(expression_list
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

; Calls

(function_call
  name: _ @call.inner)

(bracket_index_expression
  table: _ @call.inner) @call.outer

(bracket_index_expression
  field: _ @call.inner)

; Assignments

(field
  name: _ @assignment.inner @assignment.lhs
  value: _ @assignment.rhs) @assignment.outer

(field
  name: _
  value: _ @assignment.inner)

(variable_declaration
  (assignment_statement
    (variable_list) @assignment.inner @assignment.lhs
    (expression_list) @assignment.rhs)) @assignment.outer

(variable_declaration
  (assignment_statement
    (expression_list) @assignment.inner))

; [[ Non-Standard ]]

; Add @yield.

(break_statement) @yield.outer
(goto_statement
  _ @yield.inner
  .) @yield.outer

; Add @expression.

(unary_expression
  _ @expression.inner
  .) @expression.outer

(binary_expression
  left: _ @expression.inner) @expression.outer

(binary_expression
  right: _ @expression.inner)

; [[ Default ]]

; block
(_
  (block) @block.inner) @block.outer

; call
(function_call) @call.outer

(function_call
  (arguments) @call.inner
  (#match? @call.inner "^[^\\(]"))

(function_call
  arguments: (arguments
    .
    "("
    _+ @call.inner
    ")"))

; class
; comment
(comment
  (comment_content) @comment.inner) @comment.outer

; conditional
(if_statement
  alternative: (_
    (_) @conditional.inner)?) @conditional.outer

(if_statement
  consequence: (block)? @conditional.inner)

(if_statement
  condition: (_) @conditional.inner)

; frame
; function
[
  (function_declaration)
  (function_definition)
] @function.outer

(function_declaration
  body: (_) @function.inner)

(function_definition
  body: (_) @function.inner)

; return
(return_statement
  (_)? @return.inner) @return.outer

; loop
[
  (while_statement)
  (for_statement)
  (repeat_statement)
] @loop.outer

(while_statement
  body: (_) @loop.inner)

(for_statement
  body: (_) @loop.inner)

(repeat_statement
  body: (_) @loop.inner)

; parameter
(arguments
  .
  (_) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(parameters
  .
  (_) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

; (table_constructor
;   (field) @parameter.inner @parameter.outer
;   ","? @parameter.outer)

(arguments
  "," @parameter.outer
  .
  (_) @parameter.inner @parameter.outer)

(parameters
  "," @parameter.outer
  .
  (_) @parameter.inner @parameter.outer)

; number
(number) @number.inner

(assignment_statement
  (variable_list) @assignment.lhs
  (expression_list) @assignment.inner @assignment.rhs) @assignment.outer

(assignment_statement
  (variable_list) @assignment.inner)

; scopename
; statement
(statement) @statement.outer

(return_statement) @statement.outer
