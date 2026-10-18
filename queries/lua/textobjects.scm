;; extends

; For-Loops

(for_statement
  clause: _ @loop.inner)

; Functions

(function_call
  name: _ @call.inner)

; Parameters

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

; Assignments

(field
  name: _ @assignment.inner @assignment.lhs
  value: _ @assignment.rhs) @assignment.outer

(field
  name: _
  value: _ @assignment.inner)

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
