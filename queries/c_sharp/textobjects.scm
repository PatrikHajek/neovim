;; extends

; [[ Standard ]]

; Statements

[
  (local_declaration_statement)
  (expression_statement)
  (property_declaration)
] @statement.outer

; Conditions

(if_statement
  condition: _ @conditional.inner)

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

(type_argument_list
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(type_argument_list
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

(initializer_expression
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(initializer_expression
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

; Functions

; FIX: Selects the whole brackets.
(lambda_expression
  body: _ @function.inner)

; Returns

(return_statement
  "return" @return.outer
  _ @return.inner @return.outer
  ";")

; Calls

(invocation_expression
  function: _ @call.inner)

(object_creation_expression
  "new"
  type: _ @call.inner @call.outer
  arguments: _ @call.outer)

(implicit_object_creation_expression
  "new" @call.inner) @call.outer

(argument_list
  .
  "("
  _* @call.inner
  ")")

; Assignments

(variable_declaration
  type: _ @assignment.inner
  (variable_declarator
    name: _ @assignment.lhs
    _ @assignment.rhs
    .)) @assignment.outer

(variable_declarator
  name: _ @assignment.inner)

(variable_declarator
  _ @assignment.inner
  .)

(assignment_expression
  left: _ @assignment.inner @assignment.lhs
  right: _ @assignment.rhs) @assignment.outer

(assignment_expression
  right: _ @assignment.inner)

; [[ Non-Standard ]]

; Include return types in @return.

(method_declaration
  returns: _ @return.inner)

; Add @expression.

(prefix_unary_expression
  _ @expression.inner
  .) @expression.outer

(object_creation_expression
  "new"
  _+ @expression.inner) @expression.outer

(implicit_object_creation_expression
  "new"
  _ @expression.inner) @expression.outer

(binary_expression
  left: _ @expression.inner) @expression.outer

(binary_expression
  right: _ @expression.inner) @expression.outer

(conditional_expression
  condition: _ @expression.inner) @expression.outer

(conditional_expression
  consequence: _ @expression.inner)

(conditional_expression
  alternative: _ @expression.inner)
