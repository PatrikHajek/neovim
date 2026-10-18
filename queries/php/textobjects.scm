;; extends

; Statements

[
  (property_declaration)
  (method_declaration)
] @statement.outer

; Conditionals

(if_statement
  condition: (parenthesized_expression
    _ @conditional.inner))

; Loops

(for_statement
  .
  "("
  _* @loop.inner
  ")")

(foreach_statement
  .
  "("
  _* @loop.inner
  ")")

; Parameters

(array_creation_expression
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(array_creation_expression
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

; Returns

(function_definition
  ":" @return.outer
  return_type: _ @return.inner @return.outer)

(method_declaration
  ":" @return.outer
  return_type: _ @return.inner @return.outer)

(return_statement
  "return" @return.outer
  _? @return.inner @return.outer
  ";")

; Calls

(function_call_expression
  function: _ @call.inner)

(member_call_expression
  object: _ @call.inner
  name: _ @call.inner)

(nullsafe_member_call_expression
  object: _ @call.inner
  name: _ @call.inner)

(scoped_call_expression
  scope: _ @call.inner
  name: _ @call.inner)

(exit_statement
  "exit" @call.inner
  .
  "(")

(exit_statement
  "exit" @call.outer
  _ @call.inner @call.outer
  ";")

(exit_statement
  .
  "("
  _* @call.inner
  ")")

(unset_statement
  "unset" @call.inner)

(unset_statement
  "unset" @call.outer
  "(" @call.outer
  _* @call.inner @call.outer
  ")" @call.outer
  ";")

(object_creation_expression
  "new"
  (name) @call.inner @call.outer
  (arguments) @call.outer)

(arguments
  "("
  _* @call.inner
  ")")

; Assignments

(property_declaration
  _* @assignment.outer
  ";")

(property_declaration
  type: _? @assignment.inner)

(property_element
  name: _ @assignment.inner @assignment.lhs)

(property_element
  default_value: _ @assignment.inner @assignment.rhs)

(assignment_expression
  left: _ @assignment.inner @assignment.lhs
  right: _ @assignment.rhs) @assignment.outer

(assignment_expression
  right: _ @assignment.inner)

(array_element_initializer
  .
  _ @assignment.inner @assignment.lhs
  _ @assignment.rhs
  .) @assignment.outer

(array_element_initializer
  _ @assignment.inner
  .)

(argument
  .
  _ @assignment.inner @assignment.lhs
  _ @assignment.rhs
  .) @assignment.outer

(argument
  _ @assignment.inner
  .)

; Add @yield.

(exit_statement
  "exit" @yield.outer
  _? @yield.inner @yield.outer
  ";")

(break_statement
  "break" @yield.outer
  _? @yield.inner @yield.outer
  ";")

(continue_statement
  "continue" @yield.outer
  _? @yield.inner @yield.outer
  ";")

; Add @expression.

(unary_op_expression
  _ @expression.inner
  .) @expression.outer

(throw_expression
  _ @expression.inner
  .) @expression.outer

(object_creation_expression
  "new"
  _+ @expression.inner) @expression.outer

(binary_expression
  left: _ @expression.inner) @expression.outer

(binary_expression
  right: _ @expression.inner)

(conditional_expression
  condition: _ @expression.inner) @expression.outer

(conditional_expression
  alternative: _ @expression.inner)
