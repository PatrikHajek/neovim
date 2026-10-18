;; extends

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

; Assignments

(assignment_expression
  left: _ @assignment.inner @assignment.lhs
  right: _ @assignment.rhs) @assignment.outer

(assignment_expression
  right: _ @assignment.inner)

; Add @yield.

(exit_statement
  "exit" @yield.outer
  _? @yield.inner @yield.outer
  ";")

(break_statement
  "break" @yield.outer
  _? @yield.inner @yield.outer
  ";")

; Add @expression.

(unary_op_expression
  _ @expression.inner
  .) @expression.outer

(binary_expression
  left: _ @expression.inner) @expression.outer

(binary_expression
  right: _ @expression.inner)
